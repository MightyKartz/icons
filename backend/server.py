# Backend PoC for Icons Middle Layer
# FastAPI app providing /v1/generate, /v1/task/{id}, /v1/quota endpoints
# Security: no secrets stored or logged. Prompts are hashed for logging.

import asyncio
import hashlib
import json
import os
import random
import string
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, Optional

from fastapi import FastAPI, BackgroundTasks, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import base64
import urllib.request as urllib_request
import urllib.error as urllib_error
from PIL import Image, ImageStat
import io
import numpy as np
from numpy import mean
from dataclasses import dataclass

# 尝试导入cv2，如果不可用则定义轻量实现
try:
    import cv2
except ImportError:
    print("Warning: opencv-python not found. Install with 'pip install opencv-python' for optimal image quality assessment.")
    cv2 = None

APP_HOST = os.environ.get("ICONS_POC_HOST", "127.0.0.1")
APP_PORT = int(os.environ.get("ICONS_POC_PORT", "8787"))
BASE_PATH = Path(__file__).parent
STATIC_DIR = BASE_PATH / "static"
STATIC_DIR.mkdir(parents=True, exist_ok=True)

# DashScope (Alibaba Cloud) configuration - Pro users
DASHSCOPE_BASE_URL = os.environ.get("DASHSCOPE_BASE_URL", "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation").rstrip("/")
DASHSCOPE_T2I_MODEL = os.environ.get("DASHSCOPE_T2I_MODEL", "qwen-image")
# NEVER set real keys in code. Read from environment only.
DASHSCOPE_API_KEY = os.environ.get("DASHSCOPE_API_KEY", "").strip()

# ModelScope API-Inference configuration (Free users)
MODELSCOPE_API_BASE = os.environ.get("MODELSCOPE_API_BASE", "https://api-inference.modelscope.cn/v1").rstrip("/")
# NEVER set real keys in code. Read from environment only.
MODELSCOPE_API_KEY = os.environ.get("MODELSCOPE_API_KEY", "").strip()
MODELSCOPE_T2I_MODEL = os.environ.get("MODELSCOPE_T2I_MODEL", "Qwen/Qwen-Image").strip()
FREE_DAILY_LIMIT = int(os.environ.get("ICONS_FREE_DAILY_LIMIT", "2"))
_PRO_LIMIT_RAW = os.environ.get("ICONS_PRO_DAILY_LIMIT", "").strip()
try:
    PRO_DAILY_LIMIT = int(_PRO_LIMIT_RAW) if _PRO_LIMIT_RAW else None
except Exception:
    PRO_DAILY_LIMIT = None
# NEW: developer bypass flag
_BYPASS_RAW = os.environ.get("ICONS_BYPASS_QUOTA", "").strip().lower()
BYPASS_QUOTA = _BYPASS_RAW in ("1", "true", "yes", "y", "on")

IP_RPM_LIMIT = int(os.environ.get("ICONS_IP_RPM_LIMIT", "30"))

# In-memory stores (PoC only)
TASKS: Dict[str, dict] = {}
USAGE: Dict[str, dict] = {}  # { user_id: {"count": int, "reset": date_str, "plan": "free"|"pro"} }
CONCURRENCY_SEMAPHORE = asyncio.Semaphore(3)
USER_SEMAPHORES: Dict[str, asyncio.Semaphore] = {}
IP_REQUEST_LOG: Dict[str, list] = {}

class GenerateRequest(BaseModel):
    prompt: str
    style: Optional[str] = None
    parameters: Dict[str, object] = Field(default_factory=dict)

class GenerateTaskResponse(BaseModel):
    taskId: str

class TaskStatusResponse(BaseModel):
    taskId: str
    status: str
    progress: Optional[float] = None
    resultURL: Optional[str] = None
    error: Optional[str] = None

class QuotaResponse(BaseModel):
    remaining: int
    plan: str
    limit: Optional[int] = None
    resetAt: Optional[str] = None

class ReceiptVerifyRequest(BaseModel):
    receipt: str

class ReceiptVerifyResponse(BaseModel):
    success: bool
    plan: Optional[str] = None
    expiresAt: Optional[str] = None


# 图标质量评估相关数据模型
@dataclass
class IconQualityMetrics:
    resolution_score: float  # 分辨率质量分数 (0-1)
    clarity_score: float     # 清晰度质量分数 (0-1)
    contrast_score: float    # 对比度质量分数 (0-1)
    color_balance_score: float # 色彩平衡分数 (0-1)
    overall_score: float     # 总体质量分数 (0-1)
    is_acceptable: bool      # 是否达到接受标准
    recommendations: list     # 改进建议


class QualityAssessmentRequest(BaseModel):
    imageUrl: str              # 待评估的图像URL
    min_resolution: Optional[int] = 512  # 最小分辨率要求
    min_contrast: Optional[float] = 0.2  # 最小对比度要求
    min_clarity: Optional[float] = 0.5   # 最小清晰度要求
    expected_aspect_ratio: Optional[str] = "1:1"  # 期望的宽高比，格式如 "1:1", "16:9"


class QualityAssessmentResponse(BaseModel):
    taskId: str
    isAcceptable: bool
    qualityScore: float
    metrics: IconQualityMetrics
    error: Optional[str] = None

app = FastAPI(title="Icons Middle Layer PoC", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# Unified error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    # Normalize detail
    detail = exc.detail
    if isinstance(detail, dict):
        error = str(detail.get("error") or "http_error")
        message = str(detail.get("message") or error)
    else:
        error = "http_error"
        message = str(detail)
    payload = {"error": error, "message": message, "code": exc.status_code}
    return JSONResponse(status_code=exc.status_code, content=payload)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    payload = {"error": "invalid_request", "message": "Request validation failed", "code": 400}
    return JSONResponse(status_code=400, content=payload)

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    # Do not leak details; map to 500 with generic message
    payload = {"error": "internal_error", "message": "Internal server error", "code": 500}
    return JSONResponse(status_code=500, content=payload)

def _today_str():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def _prompt_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def _gen_task_id() -> str:
    return "tsk_" + "".join(random.choices(string.ascii_lowercase + string.digits, k=22))


def calculate_resolution_score(width: int, height: int, min_resolution: int = 512) -> float:
    """
    计算图像分辨率质量分数
    """
    # 计算基于分辨率的分数：最低512x512 (0.5分) 到最高1440x1440 (1.0分)
    max_resolution = 1440
    actual_resolution = min(width, height)

    if actual_resolution < min_resolution:
        return 0.0
    elif actual_resolution >= max_resolution:
        return 1.0
    else:
        # 线性缩放到满分区间
        score = 0.5 + (actual_resolution - min_resolution) / (max_resolution - min_resolution) * 0.5
        return min(1.0, max(0.0, score))


def calculate_clarity_score(image: Image.Image) -> float:
    """
    计算图像清晰度分数，通过计算拉普拉斯方差
    """
    # 转换为灰度图像用于分析
    gray = image.convert('L')

    # 转换为numpy数组以计算拉普拉斯方差
    img_array = np.array(gray)

    # 检查cv2是否可用
    if cv2 is not None:
        # 使用opencv进行清晰度分析
        laplacian_var = cv2.Laplacian(img_array, cv2.CV_64F).var()
        # Cast to float to ensure division works properly
        laplacian_var = float(laplacian_var)

        # 分数标准化到[0, 1]范围
        # 简化的拉普拉斯方差标准：强度<100为模糊，>500为清晰
        clarity_score = min(1.0, laplacian_var / 500.0)
    else:
        # 如果cv2不可用，使用替代方法来估算清晰度
        # 通过计算图像梯度的方差来估算清晰度
        try:
            from scipy import ndimage
            # 计算图像梯度
            grad_x = ndimage.sobel(img_array, axis=0)
            grad_y = ndimage.sobel(img_array, axis=1)
            gradient_magnitude = np.sqrt(grad_x**2 + grad_y**2)
            variance_val = float(np.var(gradient_magnitude))
            clarity_score = min(1.0, variance_val / 1000.0)
        except ImportError:
            # 如果scipy也不可用，则使用较简单的方法
            # 通过图像的局部方差来估算清晰度
            # 将图像分为小块并计算每个块的方差
            # 这是一个简化的清晰度估算
            block_size = min(8, img_array.shape[0], img_array.shape[1])
            height, width = img_array.shape
            blocks = []

            for i in range(0, height - block_size, block_size):
                for j in range(0, width - block_size, block_size):
                    block = img_array[i:i+block_size, j:j+block_size]
                    blocks.append(np.var(block))

            avg_block_variance = float(np.mean(blocks)) if blocks else 0.0
            clarity_score = min(1.0, avg_block_variance / 100.0)  # 调整分母以适应范围[0,1]

    return clarity_score


def calculate_contrast_score(image: Image.Image) -> float:
    """
    计算图像对比度分数
    """
    # 使用图像统计信息计算对比度
    stat = ImageStat.Stat(image)

    # 如果有多个通道，计算所有通道的平均对比度
    if hasattr(stat, 'rms'):
        # 计算RMS对比度（大值表示高对比度）
        if isinstance(stat.rms, dict):
            # RGB图像
            rms_values = list(stat.rms.values())
            if rms_values:
                avg_rms = sum(rms_values) / len(rms_values)
            else:
                avg_rms = 128.0  # 默认中间值
        elif isinstance(stat.rms, (list, tuple)):
            # 如果 rms is a list/tuple, calculate average
            if stat.rms:
                avg_rms = sum(stat.rms) / len(stat.rms)
            else:
                avg_rms = 128.0  # 默认中间值
        elif isinstance(stat.rms, (int, float)):
            # If it's already a scalar number
            avg_rms = stat.rms
        else:
            # If it's any other type, use default value
            avg_rms = 128.0  # 默认中间值

        # 将对比度标准化到[0, 1]范围
        # 基准值为图像的比率
        avg_rms = float(avg_rms)  # Ensure it's a float for division
        contrast_score = min(1.0, avg_rms / 128.0)  # 基于128的中等对比度
        return contrast_score
    else:
        return 0.5  # 默认值


def calculate_color_balance_score(image: Image.Image) -> float:
    """
    计算图像色彩平衡分数
    """
    # 检查是否有 alpha 通道
    num_channels = len(image.getbands())

    if num_channels == 1:  # 灰度图
        return 1.0  # 灰度图无色彩平衡问题
    elif num_channels >= 3:  # RGB或RGBA图像
        # 转换为numpy数组用于计算
        img_array = np.array(image)

        # 如果是RGBA，只考虑RGB通道
        if num_channels == 4:
            img_array = img_array[:, :, :3]

        # 提取每个颜色通道并计算平均值
        r_channel = img_array[:, :, 0]
        g_channel = img_array[:, :, 1]
        b_channel = img_array[:, :, 2]

        r_mean = float(np.mean(r_channel))
        g_mean = float(np.mean(g_channel))
        b_mean = float(np.mean(b_channel))

        # 计算各通道间的差异，差异越小表示色彩越平衡
        means = [r_mean, g_mean, b_mean]
        max_mean = max(means)
        min_mean = min(means)

        # 颜色平衡分数：差异越小，分数越高
        # 计算标准差的倒数来衡量平衡
        variance = float(np.var(means))
        avg_mean = float(np.mean(means))
        if avg_mean == 0:
            # 如果平均值为0，避免除零错误
            normalized_variance = 0
        else:
            normalized_variance = variance / (max(avg_mean, 128.0) ** 2)
        color_balance_score = 1 / (1 + normalized_variance)

        return min(1.0, color_balance_score)

    return 0.5  # 默认值


def calculate_aspect_ratio_score(width: int, height: int, expected_aspect_ratio: str = "1:1") -> float:
    """
    计算宽高比分数
    """
    if expected_aspect_ratio == "1:1":
        # 期望正方形：宽高比越接近1.0得分越高
        actual_ratio = float(width) / float(height) if height != 0 else 1.0
        ideal_ratio = 1.0

        # 基于对外观比例的容忍度
        diff_ratio = abs(actual_ratio - ideal_ratio)
        aspect_score = max(0.0, 1.0 - 2 * diff_ratio)  # 最多容忍50%的比例差异
    else:
        # 解析期望的宽高比
        try:
            parts = expected_aspect_ratio.split(':')
            exp_r_w, exp_r_h = int(parts[0]), int(parts[1])
            expected_ratio = float(exp_r_w) / float(exp_r_h)
            actual_ratio = float(width) / float(height) if height != 0 else float(exp_r_w) / float(exp_r_h)
            diff_ratio = abs(actual_ratio - expected_ratio) / expected_ratio if expected_ratio != 0 else abs(actual_ratio)
            aspect_score = max(0.0, 1.0 - diff_ratio)
        except:
            aspect_score = 0.5  # 无法解析时的默认值

    return aspect_score


def assess_icon_quality(image_path: str, min_resolution: int = 512, min_contrast: float = 0.2,
                       min_clarity: float = 0.5, expected_aspect_ratio: str = "1:1") -> IconQualityMetrics:
    """
    综合评估图标质量
    """
    try:
        with Image.open(image_path) as image:
            width, height = image.size

            # 计算各项指标
            resolution_score = calculate_resolution_score(width, height, min_resolution)
            clarity_score = calculate_clarity_score(image)
            contrast_score = calculate_contrast_score(image)
            color_balance_score = calculate_color_balance_score(image)
            aspect_score = calculate_aspect_ratio_score(width, height, expected_aspect_ratio)

            # 计算总体质量分数（加权平均）
            overall_score = (
                resolution_score * 0.2 +
                clarity_score * 0.25 +
                contrast_score * 0.2 +
                color_balance_score * 0.15 +
                aspect_score * 0.2
            )

            # 判断各项指标是否满足最低要求
            resolution_acceptable = resolution_score >= 0.5
            clarity_acceptable = clarity_score >= min_clarity
            contrast_acceptable = contrast_score >= min_contrast

            # 总体接受标准
            is_acceptable = (
                resolution_acceptable and
                clarity_acceptable and
                contrast_acceptable and
                overall_score >= 0.6  # 总体分数需达到0.6或以上
            )

            # 生成改进建议
            recommendations = []
            if not resolution_acceptable:
                recommendations.append(f"Image resolution may be blurry, should not be lower than {min_resolution}x{min_resolution}. For better quality, recommend using higher resolution images (e.g. > 1024x1024).")
            if not clarity_acceptable:
                recommendations.append(f"Image might be blurry, low clarity (<{min_clarity}), try improving clarity parameters.")
            if not contrast_acceptable:
                recommendations.append(f"Image contrast is low (<{min_contrast}), consider enhancing image contrast.")
            if overall_score < 0.6:
                recommendations.append(f"Overall quality insufficient, consider regenerating or applying improvements. Current overall score: {overall_score:.2f}/1.0")

            if not recommendations:
                recommendations.append("Icon quality is excellent, meets all quality standards.")

            return IconQualityMetrics(
                resolution_score=resolution_score,
                clarity_score=clarity_score,
                contrast_score=contrast_score,
                color_balance_score=color_balance_score,
                overall_score=overall_score,
                is_acceptable=is_acceptable,
                recommendations=recommendations
            )
    except Exception as e:
        print(f"[quality] Error loading image for assessment: {e}")
        # 返回默认的低质量指标
        return IconQualityMetrics(
            resolution_score=0.0,
            clarity_score=0.0,
            contrast_score=0.0,
            color_balance_score=0.0,
            overall_score=0.0,
            is_acceptable=False,
            recommendations=[f"Unable to assess image quality: {str(e)}"]
        )


def _get_user_and_plan(request: Request) -> tuple[str, str]:
    # PoC: derive user from header X-User-Id or fallback to "anon"
    user_id = request.headers.get("X-User-Id", "anon")
    plan = request.headers.get("X-Plan", "free").lower()
    if plan not in ("free", "pro"):
        plan = "free"
    return user_id, plan

def _is_developer_bypass(request: Request) -> bool:
    """检查是否应该绕过配额限制（开发者模式）"""
    # 全局环境变量绕过
    if BYPASS_QUOTA:
        return True
    
    # 检查开发者请求头（以dev-开头的用户ID表示开发者模式）
    user_id = request.headers.get("X-User-Id", "")
    if user_id.startswith("dev-"):
        return True
    
    return False



def _get_client_ip(request: Request) -> str:
    xfwd = request.headers.get("x-forwarded-for") or request.headers.get("X-Forwarded-For")
    if xfwd:
        return xfwd.split(",")[0].strip()
    return request.client.host if request.client else "0.0.0.0"


def _get_user_semaphore(user_id: str) -> asyncio.Semaphore:
    sem = USER_SEMAPHORES.get(user_id)
    if sem is None:
        sem = asyncio.Semaphore(3)
        USER_SEMAPHORES[user_id] = sem
    return sem


def _touch_usage(user_id: str, plan: str) -> dict:
    rec = USAGE.get(user_id)
    today = _today_str()
    if not rec or rec.get("reset") != today:
        rec = {"count": 0, "reset": today, "plan": plan}
        USAGE[user_id] = rec
    else:
        # keep existing count, but always update plan to match current request
        rec["plan"] = plan
    return rec


async def _generate_image_file(task_id: str, text: str, size: int = 1024, seed: Optional[int] = None) -> str:
    """Generate a PNG image with Pillow and save to static directory, return file URL path."""
    from PIL import Image, ImageDraw, ImageFont

    rng = random.Random(seed)
    img = Image.new("RGBA", (size, size), (240, 243, 248, 255))
    draw = ImageDraw.Draw(img)

    # random colored rectangle background accent
    accent = tuple(rng.randint(80, 200) for _ in range(3)) + (255,)
    draw.rounded_rectangle([(64, 64), (size - 64, size - 64)], radius=128, fill=accent)

    # text overlay
    overlay = (255, 255, 255, 245)
    msg = (text[:30] + "…") if len(text) > 30 else text
    # try to use a default font, fallback to simple
    try:
        font = ImageFont.truetype("Arial.ttf", 56)
    except Exception:
        font = ImageFont.load_default()
    # use textbbox for width/height to support newer Pillow versions
    try:
        bbox = draw.textbbox((0, 0), msg, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    except Exception:
        # ultimate fallback: approximate using length
        tw, th = (min(size - 128, 20 * len(msg)), 56)
    draw.text(((size - tw) / 2, (size - th) / 2), msg, fill=overlay, font=font)

    file_path = STATIC_DIR / f"{task_id}.png"
    img.save(file_path, format="PNG")
    return f"/static/{task_id}.png"


async def _resize_image_to_size(image_path: Path, target_size: int) -> None:
    """Resize an image to the target size while maintaining aspect ratio and center cropping."""
    from PIL import Image, ImageOps

    with Image.open(image_path) as img:
        # 首先调整图像尺寸以填充目标尺寸（保持宽高比）
        img = ImageOps.fit(img, (target_size, target_size), Image.Resampling.LANCZOS)

        # 保存调整后的图像
        img.save(image_path, format="PNG")


def _log_image_alpha_state(image_path: Path, *, source: str) -> None:
    """Inspect saved image and输出透明度信息，用于调试背景移除效果。"""
    try:
        from PIL import Image
    except Exception:
        print(f"[image] Pillow unavailable, skip alpha check for {image_path.name}")
        return

    try:
        with Image.open(image_path) as img:
            mode = img.mode
            has_alpha_channel = "A" in img.getbands()
            alpha_range = None
            if has_alpha_channel:
                alpha_band = img.getchannel("A")
                alpha_range = alpha_band.getextrema()
            print(
                f"[image] saved={image_path.name} mode={mode} has_alpha_channel={has_alpha_channel} "
                f"alpha_range={alpha_range} source={source}"
            )
    except Exception as exc:
        print(f"[image] Failed to inspect {image_path.name}: {exc}")


# ---------- DashScope adapter (async) ----------
async def _http_post_json(url: str, payload: dict, headers: dict) -> dict:
    retries = 3
    backoff = 0.8
    last_err = None
    print(f"About to send request to {url}")
    print(f"Headers: {headers}")
    print(f"Payload: {payload}")
    print("Starting retry loop")
    for attempt in range(retries):
        try:
            def _do_post():
                req = urllib_request.Request(url, method="POST")
                for k, v in headers.items():
                    req.add_header(k, v)
                data = json.dumps(payload).encode("utf-8")
                with urllib_request.urlopen(req, data=data, timeout=30) as resp:
                    return json.loads(resp.read().decode("utf-8"))
            return await asyncio.to_thread(_do_post)
        except urllib_error.HTTPError as e:
            last_err = e
            code = getattr(e, 'code', 0)
            print(f"HTTPError: code={code}, reason={e.reason}")
            # Try to read the error response body
            try:
                error_body = e.read().decode('utf-8')
                print(f"Error response body: {error_body}")
            except Exception as err:
                print(f"Failed to read error response: {err}")
            if code in (429, 500, 502, 503, 504) and attempt < retries - 1:
                await asyncio.sleep(backoff * (2 ** attempt))
                continue
            raise
        except urllib_error.URLError as e:
            last_err = e
            print(f"URLError: {e.reason}")
            if attempt < retries - 1:
                await asyncio.sleep(backoff * (2 ** attempt))
                continue
            raise
    if last_err:
        raise last_err

async def _http_get_json(url: str, headers: dict) -> dict:
    retries = 3
    backoff = 0.8
    last_err = None
    for attempt in range(retries):
        try:
            def _do_get():
                req = urllib_request.Request(url, method="GET")
                for k, v in headers.items():
                    req.add_header(k, v)
                with urllib_request.urlopen(req, timeout=30) as resp:
                    return json.loads(resp.read().decode("utf-8"))
            return await asyncio.to_thread(_do_get)
        except urllib_error.HTTPError as e:
            last_err = e
            code = getattr(e, 'code', 0)
            if code in (429, 500, 502, 503, 504) and attempt < retries - 1:
                await asyncio.sleep(backoff * (2 ** attempt))
                continue
            raise
        except urllib_error.URLError as e:
            last_err = e
            if attempt < retries - 1:
                await asyncio.sleep(backoff * (2 ** attempt))
                continue
            raise
    if last_err:
        raise last_err

def _coerce_bool(value: object, default: bool = False) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        lowered = value.strip().lower()
        return lowered in {"1", "true", "yes", "y", "on"}
    return default


async def _dashscope_generate_image_sync(prompt: str, negative_prompt: Optional[str], size: int, *, background: Optional[str]) -> Optional[str]:
    """Generate image using DashScope's Qwen-Image multimodal-generation API (sync mode)."""
    if not DASHSCOPE_API_KEY:
        raise RuntimeError("dashscope_key_missing")
    
    # Use the correct DashScope multimodal-generation endpoint
    url = f"{DASHSCOPE_BASE_URL}/generation"
    headers = {
        "Authorization": f"Bearer {DASHSCOPE_API_KEY}",
        "Content-Type": "application/json"
    }
    
    # Map requested size to supported DashScope sizes
    # Supported sizes: 1328*1328 (default), 1664*928, 1472*1140, 1140*1472, 928*1664
    dashscope_size = "1328*1328"  # Use the default square size
    
    # Format request according to DashScope Qwen-Image multimodal-generation API specification
    body = {
        "model": DASHSCOPE_T2I_MODEL,
        "input": {
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "text": prompt
                        }
                    ]
                }
            ]
        },
        "parameters": {
            "size": dashscope_size,
            "prompt_extend": True,
            "watermark": False
        }
    }

    if negative_prompt:
        body["parameters"]["negative_prompt"] = negative_prompt

    if background:
        body["parameters"]["background"] = background
        # DashScope 仅在 PNG 输出时保留透明通道
        body["parameters"]["image_format"] = "png"
    
    print(f"DashScope Qwen-Image API request URL: {url}")
    safe_headers = {k: ("***" if k.lower() == "authorization" else v) for k, v in headers.items()}
    print(f"DashScope Qwen-Image API request headers: {safe_headers}")
    print(f"DashScope Qwen-Image API request body: {body}")
    
    # Make synchronous request
    resp = await _http_post_json(url, body, headers)
    print(f"DashScope Qwen-Image API response: {resp}")
    
    # Parse synchronous response for Qwen-Image format
    try:
        output = (resp or {}).get("output", {})
        choices = output.get("choices", [])
        
        if choices and isinstance(choices[0], dict):
            message = choices[0].get("message", {})
            content = message.get("content", [])
            
            if content and isinstance(content[0], dict):
                image_url = content[0].get("image")
                if image_url:
                    print(f"DashScope Qwen-Image API completed successfully, image URL: {image_url}")
                    return image_url
        
        print(f"No image URL found in DashScope response: {resp}")
        return None
                
    except Exception as e:
        print(f"Error processing DashScope Qwen-Image API response: {e}")
        return None

    raise RuntimeError(f"dashscope_unexpected_response:{resp}")


# Legacy functions for backward compatibility (now unused)
async def _dashscope_create_task(prompt: str, negative_prompt: Optional[str], size: int) -> str:
    # This function is now deprecated, use _dashscope_generate_image_sync instead
    raise RuntimeError("dashscope_async_mode_deprecated")


async def _dashscope_fetch_task(task_id: str) -> dict:
    # This function is now deprecated
    raise RuntimeError("dashscope_async_mode_deprecated")


async def _dashscope_wait_for_result(task_id: str, timeout_sec: float = 90.0, interval_sec: float = 2.0) -> Optional[str]:
    # This function is now deprecated
    raise RuntimeError("dashscope_async_mode_deprecated")


async def _download_to_static(url: str, dest_path: Path) -> None:
    def _do_download():
        with urllib_request.urlopen(url, timeout=60) as resp, open(dest_path, "wb") as f:
            f.write(resp.read())
    await asyncio.to_thread(_do_download)


class QualityAssessmentService:
    """
    质量评估服务，负责处理图标质量和质量重试逻辑
    """

    def __init__(self):
        self.quality_threshold = 0.6  # 质量阈值

    async def assess_quality_and_generate_retry(self, generated_image_path: Path,
                                              task_params: dict,
                                              max_retries: int = 2,
                                              session_id: str = None) -> tuple[bool, int, str]:
        """
        评估质量并根据质量重新生成

        :param generated_image_path: 已生成图像的路径
        :param task_params: 任务参数
        :param max_retries: 最大重试次数
        :param session_id: 会话ID用于追踪重试
        :return: (是否满足质量, 重试次数, 最终图像路径)
        """
        retry_count = 0

        while retry_count <= max_retries:
            # 评估当前图像质量
            quality_metrics = assess_icon_quality(
                str(generated_image_path),
                min_resolution=task_params.get("size", 1024),
                min_contrast=task_params.get("min_contrast", 0.2),
                min_clarity=task_params.get("min_clarity", 0.5),
                expected_aspect_ratio=task_params.get("aspect_ratio", "1:1")
            )

            print(f"[quality] Attempt {retry_count}, overall score: {quality_metrics.overall_score}, acceptable: {quality_metrics.is_acceptable}")

            if quality_metrics.is_acceptable:
                print(f"[quality] Quality assessment passed on attempt {retry_count}")
                return True, retry_count, str(generated_image_path)

            # 质量不达标，进行重试
            if retry_count < max_retries:
                retry_count += 1
                print(f"[quality] Quality not acceptable, attempting retry {retry_count}/{max_retries}")

                # 增强参数以提高生成质量
                enhanced_params = self._enhance_quality_parameters(task_params, retry_count)

                # 重新生成图像
                try:
                    # 创建新文件名
                    new_filename = generated_image_path.with_name(
                        generated_image_path.stem + f"_retry_{retry_count}.png"
                    )

                    # 使用更好的模型或参数重新生成
                    # 从original参数重新生成
                    original_task_id = task_params.get("original_task_id", "temp_task")
                    prompt = task_params.get("prompt", "default prompt")

                    # 重新生成图像高质量
                    remote_url = await _generate_via_provider(original_task_id,
                                                            task_params.get("provider", "modelscope"),
                                                            prompt,
                                                            enhanced_params)
                    print(f"[quality] Generated retry {retry_count} with enhanced parameters")

                    # 检查是否是本地生成的URL并更新路径
                    if remote_url and remote_url.startswith("/static/"):
                        new_remote_url = remote_url.replace("/static/", str(STATIC_DIR) + "/")
                        generated_image_path = Path(new_remote_url)
                    else:
                        # 下载重新生成的图像
                        if remote_url:
                            await _download_to_static(remote_url, new_filename)
                            await _resize_image_to_size(new_filename, task_params.get("size", 1024))
                            _log_image_alpha_state(new_filename, source=f"retry_{retry_count}")
                            generated_image_path = new_filename

                except Exception as e:
                    print(f"[quality] Retry {retry_count} failed with error: {e}")
                    # 继续尝试，因为仍然可以返回最后一次的图像
                    continue

        # 耗尽所有重试次数后，返回最后一次尝试的评估结果
        print(f"[quality] All {max_retries} retries exhausted. Returning anyway.")
        return quality_metrics.is_acceptable, retry_count, str(generated_image_path)

    def _enhance_quality_parameters(self, original_params: dict, retry_count: int) -> dict:
        """
        根据重试次数增强参数以提高生成质量
        """
        enhanced_params = original_params.copy()

        # 根据重试次数调整质量参数
        if retry_count >= 1:
            # 第一次重试，提高分辨率请求
            current_size = enhanced_params.get("size", 1024)
            enhanced_params["size"] = min(1440, current_size * 1.2 if current_size < 1400 else current_size)

            # 根据生成模式设置不同的增强策略
            generation_mode = enhanced_params.get("generationMode", "standard")
            if generation_mode == "high_contrast_clip":
                # 对于High Contrast Clip模式，增加对比度和清晰度要求
                enhanced_params["quality_setting"] = 1.2  # 假设有质量设置参数
            elif generation_mode == "universal":
                # 对于通用模式，综合应用多种优化
                enhanced_params["quality_setting"] = 1.3  # 增强质量设置
                enhanced_params["hig_compliance"] = True  # 强制遵循HIG

        if retry_count >= 2:
            # 第二次重试，进行更强的参数增强
            generation_mode = enhanced_params.get("generationMode", "standard")
            if generation_mode == "universal":
                # 通用模式的特殊优化
                enhanced_params["multi_aspect_optimization"] = True
                enhanced_params["hig_and_contrast_compliance"] = True

            # 添加更多细节描述以提升质量
            enhanced_params["quality_focused"] = True

        return enhanced_params


# 全局质量评估服务实例
quality_assessment_service = QualityAssessmentService()


# startup diagnostics (no secrets)
@app.on_event("startup")
async def _startup_diag():
    dashscope_ok = bool(DASHSCOPE_API_KEY)
    modelscope_ok = bool(MODELSCOPE_API_KEY and MODELSCOPE_T2I_MODEL)
    print("[startup] providers:")
    print(f"  - dashscope: {'configured' if dashscope_ok else 'not-configured'}; base={DASHSCOPE_BASE_URL}; model={DASHSCOPE_T2I_MODEL}")
    print(f"  - modelscope: {'configured' if modelscope_ok else 'not-configured'}; base={MODELSCOPE_API_BASE}; model={MODELSCOPE_T2I_MODEL}")
    print(f"[startup] quotas: free={FREE_DAILY_LIMIT}, pro={'unlimited' if PRO_DAILY_LIMIT is None else PRO_DAILY_LIMIT}")
    if BYPASS_QUOTA:
        print("[Developer] Free unlimited usage enabled - bypassing quota check")


def _choose_provider(plan: str) -> str:
    """Simple provider router. Free -> modelscope if configured, Pro -> dashscope if configured; otherwise local."""
    dashscope_ok = bool(DASHSCOPE_API_KEY and DASHSCOPE_T2I_MODEL)
    modelscope_ok = bool(MODELSCOPE_API_KEY and MODELSCOPE_T2I_MODEL)
    if plan == "pro" and dashscope_ok:
        return "dashscope"
    if modelscope_ok:
        return "modelscope"
    return "local"


def _adapt_modelscope_size(width: int, height: int) -> tuple[int, int]:
    """
    Adapt the requested size to the closest supported ModelScope Qwen-Image size.

    Supported aspect ratios and sizes:
    - 1:1: (1328, 1328)
    - 16:9: (1664, 928)
    - 9:16: (928, 1664)
    - 4:3: (1472, 1140)
    - 3:4: (1140, 1472)
    - 3:2: (1584, 1056)
    - 2:3: (1056, 1584)
    """
    # Define supported sizes with their aspect ratios
    supported_sizes = {
        (1328, 1328): 1.0,      # 1:1
        (1664, 928): 16/9,      # 16:9
        (928, 1664): 9/16,      # 9:16
        (1472, 1140): 4/3,      # 4:3
        (1140, 1472): 3/4,      # 3:4
        (1584, 1056): 3/2,      # 3:2
        (1056, 1584): 2/3,      # 2:3
    }

    # Calculate the aspect ratio of the requested size
    requested_ratio = width / height if height != 0 else 1.0

    # Find the closest supported size based on aspect ratio
    closest_size = min(supported_sizes.keys(), key=lambda size: abs(supported_sizes[size] - requested_ratio))

    return closest_size


def _enhance_modelscope_size(width: int, height: int, enhancement_factor: float = 1.5) -> tuple[int, int]:
    """
    Enhance the requested size by multiplying with enhancement factor,
    then adapt to the closest supported ModelScope Qwen-Image size.

    This generates larger images for better quality when downscaled.

    Args:
        width: Requested width
        height: Requested height
        enhancement_factor: Factor to multiply the dimensions (default 1.5)

    Returns:
        tuple[int, int]: Enhanced and adapted size compatible with ModelScope
    """
    # Enhance the requested size
    enhanced_width = int(width * enhancement_factor)
    enhanced_height = int(height * enhancement_factor)

    # Ensure enhanced size doesn't exceed maximum supported size
    max_size = 1664  # Maximum supported size from ModelScope
    if enhanced_width > max_size or enhanced_height > max_size:
        # Scale down proportionally to fit within max size
        scale_factor = max_size / max(enhanced_width, enhanced_height)
        enhanced_width = int(enhanced_width * scale_factor)
        enhanced_height = int(enhanced_height * scale_factor)

    # Use the existing adaptation function to get the closest supported size
    return _adapt_modelscope_size(enhanced_width, enhanced_height)


async def _generate_via_provider(task_id: str, provider: str, prompt: str, params: dict) -> str:
    """Provider adapter shim. Calls real APIs when configured; fallback to local generation."""
    # 整合SF Symbols到提示词中（如果提供）
    enhanced_prompt = prompt
    symbols = params.get("symbols")
    if symbols:
        # 处理不同格式的symbols参数（字符串或列表）
        symbol_list = []
        if isinstance(symbols, str):
            # 如果是逗号分隔的字符串
            symbol_list = [s.strip() for s in symbols.split(",") if s.strip()]
        elif isinstance(symbols, list):
            # 如果是列表
            symbol_list = [str(s) for s in symbols if s]

        if symbol_list:
            # 转换符号名称为英文描述，避免直接注入符号名称，减少文字出现在图像中的可能性
            symbols_descriptions = []
            for symbol_name in symbol_list:
                # 仅使用符号的设计意向，避免直接包含可能在图标中渲染为文本的符号名称
                symbols_descriptions.append(f"symbolic elements inspired by {symbol_name}")

            symbols_description_text = ", ".join(symbols_descriptions)
            # 创建仅使用英文的prompt以避免中文混入，专注于设计原则而非符号命名
            enhanced_prompt = f"{prompt}, following Apple SF Symbols design principles, incorporating {symbols_description_text}, with clean lines, balanced proportions, symbolic meaning, geometric shapes and clear visual hierarchy suitable for app icons"
            print(f"Enhanced prompt with SF Symbols (English-focused): {enhanced_prompt}")

    # normalize size
    try:
        size = int(params.get("size", 1024))
    except Exception:
        size = 1024
    size = max(512, min(1440, size))

    # check generation mode to determine background handling
    generation_mode = params.get("generationMode", "standard")
    print(f"[_generate_via_provider] generation_mode={generation_mode}")

    remove_background = _coerce_bool(params.get("removeBackground"), default=False)

    # 根据生成模式设置背景处理方式
    if generation_mode == "apple":
        # Apple平台模式：允许透明背景以符合HIG设计规范
        background_mode = None  # 透明背景，符合Apple图标设计指南
        print(f"[_generate_via_provider] Apple platform mode: using transparent background")
    elif generation_mode == "high_contrast_clip":
        # High Contrast Clip模式：使用白色背景以增强对比度，优化抠图效果
        background_mode = "white"  # 使用纯白色背景最大化对比度
        print(f"[_generate_via_provider] High contrast clip mode: using white background for contrast")
    elif generation_mode == "universal":
        # 通用模式：根据Apple HIG指南和质量评估最佳实践进行平衡设置
        # 同时启用质量评估增强整个生成流程
        background_mode = "white"  # 使用白色/高对比度背景以便于抠图，但同时确保符合Apple HIG
        print(f"[_generate_via_provider] Universal mode: using high contrast background with HIG compliance")
    else:
        # 标准模式：使用对比背景以改善抠图效果
        background_mode = None  # 始终使用对比背景而非透明背景，改善抠图效果
        print(f"[_generate_via_provider] Standard mode: using contrast background")

    if provider == "dashscope" and DASHSCOPE_API_KEY:
        # Use DashScope multimodal generation API
        try:
            remote_url = await _dashscope_generate_image_sync(enhanced_prompt, None, size=size, background=background_mode)
            if not remote_url:
                raise RuntimeError("dashscope_no_result")
            if (
                background_mode
                and isinstance(remote_url, str)
                and remote_url.lower().endswith((".jpg", ".jpeg"))
            ):
                print(
                    f"[info] DashScope returned JPEG for contrast background: {remote_url}"
                )
            dest = STATIC_DIR / f"{task_id}.png"
            # Handle both URL and base64 data URI
            if isinstance(remote_url, str) and remote_url.startswith("data:image/"):
                try:
                    b64 = remote_url.split(",", 1)[1]
                except Exception:
                    raise RuntimeError("dashscope_invalid_data_uri")
                with open(dest, "wb") as f:
                    f.write(base64.b64decode(b64))
                # 调整图像尺寸以匹配用户选择的尺寸
                await _resize_image_to_size(dest, size)
                _log_image_alpha_state(dest, source="dashscope:data-uri")
            else:
                await _download_to_static(remote_url, dest)
                # 调整图像尺寸以匹配用户选择的尺寸
                await _resize_image_to_size(dest, size)
                _log_image_alpha_state(dest, source=str(remote_url))
            return f"/static/{task_id}.png"
        except Exception:
            # propagate to fallback (handled by caller)
            raise

    if provider == "modelscope" and MODELSCOPE_API_KEY and MODELSCOPE_T2I_MODEL:
        print(f"Calling _modelscope_generate_image with prompt: {enhanced_prompt}")
        import sys
        sys.stdout.flush()
        try:
            # Extract size from parameters for ModelScope
            size = 1024
            try:
                size = int(params.get("size", 1024))
            except Exception:
                pass
            # For ModelScope, we need to pass both width and height
            # If only one size is provided, assume square
            remote_url = await _modelscope_generate_image(enhanced_prompt, size, size, background=background_mode)
            if not remote_url:
                raise RuntimeError("modelscope_no_result")
            if (
                background_mode
                and isinstance(remote_url, str)
                and remote_url.lower().endswith((".jpg", ".jpeg"))
            ):
                print(
                    f"[info] ModelScope returned JPEG for contrast background: {remote_url}"
                )
            dest = STATIC_DIR / f"{task_id}.png"
            # NEW: handle base64 data URI directly
            if isinstance(remote_url, str) and remote_url.startswith("data:image/"):
                try:
                    b64 = remote_url.split(",", 1)[1]
                except Exception:
                    raise RuntimeError("modelscope_invalid_data_uri")
                with open(dest, "wb") as f:
                    f.write(base64.b64decode(b64))
                # 调整图像尺寸以匹配用户选择的尺寸
                await _resize_image_to_size(dest, size)
                _log_image_alpha_state(dest, source="modelscope:data-uri")
            else:
                await _download_to_static(remote_url, dest)
                # 调整图像尺寸以匹配用户选择的尺寸
                await _resize_image_to_size(dest, size)
                _log_image_alpha_state(dest, source=str(remote_url))
            return f"/static/{task_id}.png"
        except Exception:
            # propagate to fallback
            raise

    # default: local fallback
    rel_url = await _generate_image_file(task_id, prompt, size=size, seed=7)
    return rel_url


async def _process_task(task_id: str):
    task = TASKS.get(task_id)
    if not task:
        return
    prompt = task["prompt"]
    params = task.get("parameters", {})
    provider = task.get("provider", "modelscope")

    # Simulate queueing and processing with concurrency control
    await asyncio.sleep(0.3)
    task["status"] = "processing"
    task["progress"] = 0.1

    async with CONCURRENCY_SEMAPHORE:
        async with _get_user_semaphore(task.get("user", "anon")):
            try:
                # simulate progressive updates
                for p in [0.25, 0.5, 0.7, 0.9]:
                    await asyncio.sleep(0.4)
                    task["progress"] = p
                # provider generation (with graceful fallback chain)
                try:
                    rel_url = await _generate_via_provider(task_id, provider, prompt, params)
                except Exception as e:
                    # record first failure and try modelscope only if dashscope failed; otherwise go local
                    task["error"] = f"provider_failed:{provider}:{e}"
                    try:
                        if provider == "dashscope":
                            rel_url = await _generate_via_provider(task_id, "modelscope", prompt, params)
                        else:
                            # provider is modelscope or others, skip escalating to dashscope for free users
                            raise RuntimeError("skip_escalation")
                    except Exception as e2:
                        task["error"] = f"{task['error']}; fallback_failed:{'modelscope' if provider == 'dashscope' else 'local'}:{e2}"
                        # final guaranteed local fallback
                        rel_url = await _generate_via_provider(task_id, "local", prompt, params)

                # 特别为 high_contrast_clip 生成模式和质量要求启用质量评估
                generation_mode = params.get("generationMode", "standard")

                # 如果是特定模式，在返回之前评估图像质量
                should_assess_quality = (
                    generation_mode == "high_contrast_clip" or
                    generation_mode == "universal" or  # 通用模式也需要质量评估
                    params.get("evaluateQuality", False) or
                    # 在参数中明确请求质量评估
                    params.get('qualityAssessment', {}).get('enabled', False)
                )

                if should_assess_quality:
                    print(f"[quality] Quality assessment needed for task {task_id}, mode: {generation_mode}")

                    # 获取生成的本地文件路径
                    relative_path = rel_url.replace("/static/", "")
                    file_path = STATIC_DIR / relative_path

                    # 做质量评估并需要进行重试（如果质量不达标），添加错误处理
                    print(f"[quality] Assessing quality for file: {file_path}")

                    try:
                        assessment_result = await quality_assessment_service.assess_quality_and_generate_retry(
                            generated_image_path=file_path,
                            task_params={**params, "prompt": prompt, "original_task_id": task_id, "provider": provider},
                            max_retries=params.get("maxQualityRetries", 2)
                        )

                        is_acceptable, retry_count, final_image_path = assessment_result

                        print(f"[quality] Quality assessment complete. Acceptable: {is_acceptable}, Retries: {retry_count}")

                        # 更新返回的URL为最终的图片路径
                        if final_image_path != str(file_path):
                            # 使用相对路径
                            final_rel_path = "/static/" + Path(final_image_path).name
                            rel_url = final_rel_path
                    except Exception as quality_error:
                        print(f"[quality] Quality assessment failed with error: {quality_error}. Proceeding with original image to maintain reliability.")
                        # 质量评估服务失败时，降级到不进行质量评估，使用原始生成的图像，确保流程继续
                        pass  # 继续使用原有的rel_url，不进行质量重试

                task["progress"] = 1.0
                task["status"] = "completed"
                task["resultURL"] = f"http://{APP_HOST}:{APP_PORT}{rel_url}"

                # 添加质量评估元数据
                if should_assess_quality:
                    task["qualityAssessment"] = {
                        "acceptable": is_acceptable,
                        "retries": retry_count,
                        "finalImagePath": rel_url
                    }

            except Exception as final_e:
                # If even local generation fails, mark as failed
                task["status"] = "failed"
                task["error"] = f"all_providers_failed:{final_e}"


@app.get("/v1/quota", response_model=QuotaResponse)
async def get_quota(request: Request):
    user_id, plan = _get_user_and_plan(request)
    rec = _touch_usage(user_id, plan)
    # developer bypass: always unlimited
    if _is_developer_bypass(request):
        print("[Developer] Free unlimited usage enabled - bypassing quota check")
        # 在开发者模式下，返回当前请求头中的plan，而不是数据库中的plan
        return QuotaResponse(remaining=999999, plan=plan, limit=None, resetAt=None)
    # compute limit/remaining
    # 使用请求头中的plan来计算配额，确保与API调用保持一致
    if plan == "free":
        limit = FREE_DAILY_LIMIT
    else:
        limit = PRO_DAILY_LIMIT
    if limit is None:
        remaining = 999999
    else:
        remaining = max(0, limit - rec["count"])
    # next reset at midnight UTC
    today = datetime.now(timezone.utc).date()
    reset_at = datetime.combine(today + timedelta(days=1), datetime.min.time(), tzinfo=timezone.utc)
    # 返回请求头中的plan，确保与前端显示一致
    return QuotaResponse(remaining=remaining, plan=plan, limit=limit, resetAt=reset_at.isoformat())


@app.get("/v1/task/{task_id}", response_model=TaskStatusResponse)
async def get_task(task_id: str):
    task = TASKS.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="task not found")
    return TaskStatusResponse(
        taskId=task["taskId"],
        status=task["status"],
        progress=task.get("progress"),
        resultURL=task.get("resultURL"),
        error=task.get("error"),
    )


@app.post("/v1/generate", response_model=GenerateTaskResponse)
async def create_task(req: GenerateRequest, request: Request, bg: BackgroundTasks):
    user_id, plan = _get_user_and_plan(request)
    # IP rate limiting (per minute)
    ip = _get_client_ip(request)
    now_ts = time.time()
    recent = [t for t in IP_REQUEST_LOG.get(ip, []) if now_ts - t < 60]
    if len(recent) >= IP_RPM_LIMIT:
        raise HTTPException(status_code=429, detail={"error": "rate_limited", "message": "Too many requests from IP"})
    recent.append(now_ts)
    IP_REQUEST_LOG[ip] = recent

    rec = _touch_usage(user_id, plan)
    # Quota enforcement by plan (skip when developer bypass is enabled)
    if not _is_developer_bypass(request):
        if rec["plan"] == "free":
            if rec["count"] >= FREE_DAILY_LIMIT:
                raise HTTPException(status_code=402, detail={"error": "quota_exceeded", "message": "Daily free quota exceeded"})
        else:
            if PRO_DAILY_LIMIT is not None and rec["count"] >= PRO_DAILY_LIMIT:
                raise HTTPException(status_code=402, detail={"error": "quota_exceeded", "message": "Daily pro quota exceeded"})
    else:
        print("[Developer] Free unlimited usage enabled - bypassing quota check")

    # Use frontend-provided size without plan-based caps
    parameters = dict(req.parameters or {})
    remove_background = _coerce_bool(parameters.get("removeBackground"), default=False)
    parameters["removeBackground"] = remove_background
    print(f"removeBackground requested: {remove_background}")
    try:
        requested_size = int(parameters.get("size", 1024))
    except Exception:
        requested_size = 1024

    # Apply safe bounds handled by provider shim (256-1440) for all users
    parameters["size"] = max(256, min(1440, requested_size))
    print(f"Using requested size: {parameters['size']} (requested: {requested_size})")

    task_id = _gen_task_id()
    # 在开发者模式下，使用请求头中的plan来选择提供商，确保API路由正确
    effective_plan = plan if _is_developer_bypass(request) else rec["plan"]
    provider = _choose_provider(effective_plan)  # route by plan
    TASKS[task_id] = {
        "taskId": task_id,
        "status": "pending",
        "progress": 0.0,
        "resultURL": None,
        "error": None,
        "createdAt": time.time(),
        "prompt": req.prompt,
        "prompt_hash": _prompt_hash(req.prompt),
        "parameters": parameters,
        "style": req.style,
        "user": user_id,
        "provider": provider,
    }
    # increment usage on task creation
    rec["count"] += 1

    bg.add_task(_process_task, task_id)
    return GenerateTaskResponse(taskId=task_id)


@app.post("/v1/receipt/verify", response_model=ReceiptVerifyResponse)
async def verify_receipt(req: ReceiptVerifyRequest, request: Request):
    """
    PoC receipt verification.
    - Accepts base64-encoded receipt string in {"receipt": "..."}
    - If decodable and non-empty, marks user as Pro until +30 days
    - Never logs or returns raw receipt
    """
    user_id, _plan = _get_user_and_plan(request)
    # basic validation
    if not req.receipt or not isinstance(req.receipt, str):
        raise HTTPException(status_code=400, detail={"error": "invalid_receipt", "message": "missing receipt"})
    try:
        decoded = base64.b64decode(req.receipt, validate=True)
    except Exception:
        raise HTTPException(status_code=400, detail={"error": "invalid_receipt", "message": "malformed base64"})

    if len(decoded) < 16:
        # treat too-short as invalid
        return ReceiptVerifyResponse(success=False, plan="free", expiresAt=None)

    # mark user as pro for 30 days in usage store
    rec = _touch_usage(user_id, "pro")
    rec["plan"] = "pro"
    expires_at = datetime.now(timezone.utc) + timedelta(days=30)
    return ReceiptVerifyResponse(success=True, plan="pro", expiresAt=expires_at.isoformat())


@app.post("/v1/quality/assess", response_model=QualityAssessmentResponse)
async def assess_icon_quality_api(req: QualityAssessmentRequest):
    """
    评估图标质量的API端点
    """
    task_id = _gen_task_id()

    try:
        # 首先下载图像到本地进行评估
        image_url = req.imageUrl
        image_path = STATIC_DIR / f"{task_id}_assessment.png"

        if image_url.startswith("http://") or image_url.startswith("https://"):
            # 远程URL，需要下载
            await _download_to_static(image_url, image_path)
        elif image_url.startswith("/static/"):
            # 服务器内部静态文件引用
            local_path = str(STATIC_DIR / image_url[len("/static/"):])
            image_path = Path(local_path)
            # 验证文件路径安全
            if not local_path.startswith(str(STATIC_DIR)):
                raise HTTPException(status_code=400, detail="Invalid file path")
        else:
            # 本地相对路径
            local_path = str(STATIC_DIR / image_url)
            image_path = Path(local_path)

        if not image_path.exists():
            raise HTTPException(status_code=404, detail="Image not found")

        # 进行质量评估
        quality_metrics = assess_icon_quality(
            str(image_path),
            min_resolution=req.min_resolution,
            min_contrast=req.min_contrast,
            min_clarity=req.min_clarity,
            expected_aspect_ratio=req.expected_aspect_ratio
        )

        return QualityAssessmentResponse(
            taskId=task_id,
            isAcceptable=quality_metrics.is_acceptable,
            qualityScore=quality_metrics.overall_score,
            metrics=quality_metrics,
            error=None
        )

    except Exception as e:
        print(f"[quality-api] Error assessing quality: {e}")
        return QualityAssessmentResponse(
            taskId=task_id,
            isAcceptable=False,
            qualityScore=0.0,
            metrics=IconQualityMetrics(
                resolution_score=0.0,
                clarity_score=0.0,
                contrast_score=0.0,
                color_balance_score=0.0,
                overall_score=0.0,
                is_acceptable=False,
                recommendations=["图像质量评估失败: " + str(e)]
            ),
            error=str(e)
        )


@app.post("/v1/generate/quality-optimized", response_model=GenerateTaskResponse)
async def create_quality_optimized_task(req: GenerateRequest, request: Request, bg: BackgroundTasks):
    """
    创建质量优化的任务 - 在生成后自动评估质量并进行重试（如果需要）
    """
    # 添加质量评估参数到请求
    if req.parameters is None:
        req.parameters = {}

    # 默认启用质量评估，特别是对于high_contrast_clip模式
    if req.parameters.get("generationMode") == "high_contrast_clip" or req.parameters.get("evaluateQuality",True):
        req.parameters["qualityAssessment"] = {"enabled": True}
        req.parameters["maxQualityRetries"] = req.parameters.get("maxQualityRetries", 2)

    # 与其他生成任务类似，但确保评估质量
    user_id, plan = _get_user_and_plan(request)

    # IP rate limiting (per minute)
    ip = _get_client_ip(request)
    now_ts = time.time()
    recent = [t for t in IP_REQUEST_LOG.get(ip, []) if now_ts - t < 60]
    if len(recent) >= IP_RPM_LIMIT:
        raise HTTPException(status_code=429, detail={"error": "rate_limited", "message": "Too many requests from IP"})
    recent.append(now_ts)
    IP_REQUEST_LOG[ip] = recent

    rec = _touch_usage(user_id, plan)
    # Quota enforcement (skip when developer bypass is enabled)
    if not _is_developer_bypass(request):
        if rec["plan"] == "free":
            if rec["count"] >= FREE_DAILY_LIMIT:
                raise HTTPException(status_code=402, detail={"error": "quota_exceeded", "message": "Daily free quota exceeded"})
        else:
            if PRO_DAILY_LIMIT is not None and rec["count"] >= PRO_DAILY_LIMIT:
                raise HTTPException(status_code=402, detail={"error": "quota_exceeded", "message": "Daily pro quota exceeded"})
    else:
        print("[Developer] Free unlimited usage enabled - bypassing quota check")

    # Use frontend-provided size without plan-based caps
    parameters = dict(req.parameters or {})
    remove_background = _coerce_bool(parameters.get("removeBackground"), default=False)
    parameters["removeBackground"] = remove_background
    print(f"removeBackground requested: {remove_background}")
    try:
        requested_size = int(parameters.get("size", 1024))
    except Exception:
        requested_size = 1024

    # Apply safe bounds handled by provider shim (256-1440) for all users
    parameters["size"] = max(256, min(1440, requested_size))
    print(f"Using requested size: {parameters['size']} (requested: {requested_size})")

    task_id = _gen_task_id()
    # 在开发者模式下，使用请求头中的plan来选择提供商，确保API路由正确
    effective_plan = plan if _is_developer_bypass(request) else rec["plan"]
    provider = _choose_provider(effective_plan)  # route by plan
    TASKS[task_id] = {
        "taskId": task_id,
        "status": "pending",
        "progress": 0.0,
        "resultURL": None,
        "error": None,
        "createdAt": time.time(),
        "prompt": req.prompt,
        "prompt_hash": _prompt_hash(req.prompt),
        "parameters": parameters,
        "style": req.style,
        "user": user_id,
        "provider": provider,
    }
    # increment usage on task creation
    rec["count"] += 1

    bg.add_task(_process_task, task_id)
    return GenerateTaskResponse(taskId=task_id)


@app.get("/health")
async def health():
    return {"ok": True, "time": datetime.now(timezone.utc).isoformat()}


@app.get("/v1/generation-modes")
async def get_generation_modes():
    """
    获取所有支持的生成模式及其描述
    """
    modes = {
        "standard": {
            "name": "Standard",
            "description": "Standard generation mode, using high contrast background to improve clipping effect",
            "features": ["High contrast background", "Optimized clipping", "Vector quality"]
        },
        "apple": {
            "name": "Apple Platform",
            "description": "Transparent background mode following Apple Human Interface Guidelines",
            "features": ["Transparent background", "Apple HIG compliant", "Small scale optimization"]
        },
        "high_contrast_clip": {
            "name": "High Contrast Clip",
            "description": "High contrast background mode optimized specifically for clipping",
            "features": ["Maximum contrast", "Optimized clipping", "Clear boundaries"]
        },
        "universal": {
            "name": "Universal",
            "description": "Universal generation mode: Combining best practices from Apple HIG guidelines, high contrast backgrounds, and quality assessment",
            "features": ["Apple HIG compliant", "High contrast background", "Quality assessment", "Scalable design"]
        }
    }
    return modes


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host=APP_HOST, port=APP_PORT, reload=False)

# ---------- DashScope adapter (OpenAI-compatible mode) ----------
async def _dashscope_generate_image_compatible(prompt: str, size: int = 1024) -> Optional[str]:
    """Generate image using DashScope's OpenAI-compatible API."""
    if not DASHSCOPE_API_KEY:
        raise RuntimeError("dashscope_key_missing")

    url = f"{DASHSCOPE_BASE_URL}/images/generations"
    headers = {
        "Authorization": f"Bearer {DASHSCOPE_API_KEY}",
        "Content-Type": "application/json",
    }
    # Size formatting for DashScope compatible mode
    size_str = f"{size}x{size}"
    body = {
        "model": DASHSCOPE_T2I_MODEL,
        "prompt": prompt,
        "size": size_str,
        "n": 1,
    }

    resp = await _http_post_json(url, body, headers)

    # Handle response in OpenAI format
    try:
        data = (resp or {}).get("data") or []
        first = data[0] if data else None
        if isinstance(first, dict):
            # Check for URL (newer format)
            if first.get("url"):
                return first["url"]
            # Check for b64_json (base64 encoded image)
            elif first.get("b64_json"):
                return f"data:image/png;base64,{first['b64_json']}"
    except Exception:
        pass

    raise RuntimeError(f"dashscope_compatible_unexpected_response:{resp}")


# ---------- ModelScope adapter (async mode with task polling) ----------
async def _modelscope_generate_image(prompt: str, width: int = 1024, height: int = 1024, *, background: Optional[str]) -> Optional[str]:
    """Generate image using ModelScope API-Inference (asynchronous mode with polling)."""
    print("Entering _modelscope_generate_image function")
    if not (MODELSCOPE_API_KEY and MODELSCOPE_T2I_MODEL):
        print("ModelScope not configured")
        raise RuntimeError("modelscope_not_configured")
    print("ModelScope configured correctly")

    # Use enhanced size for better quality - generate larger image then downscale
    enhanced_width, enhanced_height = _enhance_modelscope_size(width, height)
    print(f"ModelScope requested size: {width}x{height}, enhanced size: {enhanced_width}x{enhanced_height}")

    # Use asynchronous mode for ModelScope API-Inference
    url = f"{MODELSCOPE_API_BASE}/images/generations"
    headers = {
        "Authorization": f"Bearer {MODELSCOPE_API_KEY}",
        "Content-Type": "application/json",
        "X-ModelScope-Async-Mode": "true"
    }

    # Request body for image generation with size parameters
    # ModelScope Qwen-Image supports width and height parameters
    # For square images, we use the same value for both dimensions
    # For rectangular images, we need to calculate appropriate width/height values
    # Supported aspect ratios include 1:1, 16:9, 9:16, 4:3, 3:4, 3:2, 2:3, etc.

    parameters = {
        "width": enhanced_width,
        "height": enhanced_height,
    }

    if background:
        parameters["background"] = background
        # ModelScope Qwen-Image 需要显式指定输出 PNG 以保留透明度
        parameters["image_format"] = "png"

    body = {
        "model": MODELSCOPE_T2I_MODEL,
        "prompt": prompt,
        "parameters": parameters
    }

    print(f"ModelScope request: url={url}")
    safe_headers = {k: ("***" if k.lower() == "authorization" else v) for k, v in headers.items()}
    print(f"ModelScope headers: {safe_headers}")
    print(f"ModelScope body: {body}")
    print("About to call _http_post_json for image generation")

    try:
        # Submit async task
        resp = await _http_post_json(url, body, headers)
        print(f"ModelScope response: {resp}")

        # Extract task ID from response
        task_id = resp.get("task_id")
        if not task_id:
            raise RuntimeError(f"modelscope_no_task_id:{resp}")

        print(f"ModelScope task_id: {task_id}")

        # Poll for task completion
        max_attempts = 30
        poll_interval = 5
        task_result_url = f"{MODELSCOPE_API_BASE}/tasks/{task_id}"
        task_headers = {
            "Authorization": f"Bearer {MODELSCOPE_API_KEY}",
            "Content-Type": "application/json",
            "X-ModelScope-Task-Type": "image_generation"
        }

        for attempt in range(max_attempts):
            print(f"Polling task status (attempt {attempt + 1}/{max_attempts})")
            try:
                task_resp = await _http_get_json(task_result_url, task_headers)
                print(f"Task status response: {task_resp}")

                task_status = task_resp.get("task_status")
                if task_status == "SUCCEED":
                    # Extract image URL from response
                    output_images = task_resp.get("output_images", [])
                    if output_images and len(output_images) > 0:
                        image_url = output_images[0]
                        print(f"ModelScope image generated successfully: {image_url}")
                        return image_url
                    else:
                        raise RuntimeError(f"modelscope_no_image_url:{task_resp}")
                elif task_status == "FAILED":
                    raise RuntimeError(f"modelscope_task_failed:{task_resp.get('message', 'Unknown error')}")
                elif task_status not in ["RUNNING", "QUEUING"]:
                    print(f"Unexpected task status: {task_status}")

            except urllib_error.HTTPError as e:
                print(f"HTTP error while polling task: {e}")
                # Continue polling for transient errors

            # Wait before next poll
            if attempt < max_attempts - 1:
                await asyncio.sleep(poll_interval)

        raise RuntimeError("modelscope_task_timeout")

    except urllib_error.HTTPError as e:
        # Extract detailed error information from response
        try:
            error_body = e.read().decode('utf-8')
            print(f"ModelScope API Error Response: {error_body}")
        except:
            pass
        raise
    except Exception as e:
        print(f"Unexpected error in _modelscope_generate_image: {e}")
        raise
