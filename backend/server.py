#!/usr/bin/env python3
"""
Icons AI Icon Generation Backend
免费开源版本的AI图标生成API服务
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Any

from fastapi import FastAPI, HTTPException, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse
import httpx
import logging
from cryptography.fernet import Fernet

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 初始化FastAPI应用
app = FastAPI(
    title="Icons AI API",
    description="免费开源AI图标生成API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS配置
origins = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 静态文件服务
static_dir = Path("static")
static_dir.mkdir(exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# 加密密钥（在生产环境中应该从环境变量获取）
ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", Fernet.generate_key().decode())
cipher_suite = Fernet(ENCRYPTION_KEY.encode())

# 内存存储（生产环境应使用数据库）
user_configs: Dict[str, Dict] = {}
generation_tasks: Dict[str, Dict] = {}

# Pydantic模型定义
class APIConfig(BaseModel):
    provider: str = Field(..., description="AI提供商")
    apiKey: str = Field(..., description="API密钥")
    model: str = Field(..., description="模型名称")
    baseUrl: Optional[str] = Field(None, description="自定义基础URL")
    maxTokens: Optional[int] = Field(1000, description="最大token数")
    temperature: Optional[float] = Field(0.7, description="随机性参数")

class GenerationRequest(BaseModel):
    prompt: str = Field(..., description="图标生成提示词")
    style: Optional[str] = Field("icon", description="生成风格")
    size: Optional[str] = Field("1024x1024", description="图像尺寸")
    quality: Optional[str] = Field("standard", description="图像质量")
    negativePrompt: Optional[str] = Field("", description="负面提示词")

class TaskResponse(BaseModel):
    taskId: str
    status: str
    message: str

class ConfigResponse(BaseModel):
    success: bool
    message: str

# AI提供商适配器
class AIProviderAdapter:
    """AI提供商适配器基类"""

    def __init__(self, config: APIConfig):
        self.config = config
        self.client = httpx.AsyncClient(timeout=60.0)

    async def generate_image(self, request: GenerationRequest) -> Dict[str, Any]:
        """生成图像的抽象方法"""
        raise NotImplementedError

    async def test_connection(self) -> bool:
        """测试连接的抽象方法"""
        raise NotImplementedError

    async def close(self):
        """关闭客户端连接"""
        await self.client.aclose()

class OpenAIAdapter(AIProviderAdapter):
    """OpenAI适配器"""

    async def generate_image(self, request: GenerationRequest) -> Dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.config.apiKey}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": self.config.model or "dall-e-3",
            "prompt": request.prompt,
            "n": 1,
            "size": request.size,
            "quality": request.quality,
            "response_format": "url"
        }

        if request.negativePrompt:
            payload["prompt"] = f"{request.prompt}. Avoid: {request.negativePrompt}"

        try:
            response = await self.client.post(
                f"{self.config.baseUrl or 'https://api.openai.com'}/v1/images/generations",
                headers=headers,
                json=payload
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"OpenAI API错误: {e.response.status_code} - {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail=f"OpenAI API错误: {e.response.text}")

    async def test_connection(self) -> bool:
        try:
            response = await self.client.get(
                f"{self.config.baseUrl or 'https://api.openai.com'}/v1/models",
                headers={"Authorization": f"Bearer {self.config.apiKey}"}
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"OpenAI连接测试失败: {e}")
            return False

class AnthropicAdapter(AIProviderAdapter):
    """Anthropic适配器"""

    async def generate_image(self, request: GenerationRequest) -> Dict[str, Any]:
        # Anthropic目前主要支持文本生成，图像功能有限制
        # 这里提供基础实现框架
        raise HTTPException(status_code=501, detail="Anthropic图像生成功能暂未实现")

    async def test_connection(self) -> bool:
        try:
            headers = {
                "x-api-key": self.config.apiKey,
                "content-type": "application/json",
                "anthropic-version": "2023-06-01"
            }
            response = await self.client.post(
                f"{self.config.baseUrl or 'https://api.anthropic.com'}/v1/messages",
                headers=headers,
                json={
                    "model": self.config.model or "claude-3-opus-20240229",
                    "max_tokens": 100,
                    "messages": [{"role": "user", "content": "Hello"}]
                }
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Anthropic连接测试失败: {e}")
            return False

class ModelScopeAdapter(AIProviderAdapter):
    """ModelScope适配器"""

    async def generate_image(self, request: GenerationRequest) -> Dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.config.apiKey}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": self.config.model or "Qwen/Qwen-Image",
            "input": {
                "prompt": request.prompt,
                "negative_prompt": request.negativePrompt,
                "width": int(request.size.split("x")[0]),
                "height": int(request.size.split("x")[1]),
                "num_inference_steps": 50
            }
        }

        try:
            response = await self.client.post(
                f"{self.config.baseUrl or 'https://api-inference.modelscope.cn'}/v1/images/generations",
                headers=headers,
                json=payload
            )
            response.raise_for_status()
            result = response.json()

            # ModelScope可能返回任务ID，需要轮询结果
            if "task_id" in result:
                return await self._poll_task_result(result["task_id"])

            return result
        except httpx.HTTPStatusError as e:
            logger.error(f"ModelScope API错误: {e.response.status_code} - {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail=f"ModelScope API错误: {e.response.text}")

    async def _poll_task_result(self, task_id: str, max_attempts: int = 30) -> Dict[str, Any]:
        """轮询任务结果"""
        for attempt in range(max_attempts):
            try:
                response = await self.client.get(
                    f"{self.config.baseUrl or 'https://api-inference.modelscope.cn'}/v1/tasks/{task_id}",
                    headers={"Authorization": f"Bearer {self.config.apiKey}"}
                )

                if response.status_code == 200:
                    result = response.json()
                    if result.get("status") == "succeeded":
                        return result
                    elif result.get("status") == "failed":
                        raise HTTPException(status_code=500, detail=f"图像生成失败: {result.get('error', '未知错误')}")

                await asyncio.sleep(2)
            except Exception as e:
                logger.error(f"轮询任务结果失败: {e}")
                if attempt == max_attempts - 1:
                    raise HTTPException(status_code=500, detail="获取生成结果超时")

        raise HTTPException(status_code=500, detail="任务超时")

    async def test_connection(self) -> bool:
        try:
            headers = {"Authorization": f"Bearer {self.config.apiKey}"}
            response = await self.client.get(
                f"{self.config.baseUrl or 'https://api-inference.modelscope.cn'}/v1/models",
                headers=headers
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"ModelScope连接测试失败: {e}")
            return False

# 提供商工厂
def create_provider(provider: str, config: APIConfig) -> AIProviderAdapter:
    """创建AI提供商实例"""
    providers = {
        "openai": OpenAIAdapter,
        "anthropic": AnthropicAdapter,
        "modelscope": ModelScopeAdapter,
    }

    if provider not in providers:
        raise HTTPException(status_code=400, detail=f"不支持的AI提供商: {provider}")

    return providers[provider](config)

# 加密工具
def encrypt_api_key(api_key: str) -> str:
    """加密API密钥"""
    return cipher_suite.encrypt(api_key.encode()).decode()

def decrypt_api_key(encrypted_key: str) -> str:
    """解密API密钥"""
    return cipher_suite.decrypt(encrypted_key.encode()).decode()

# 用户管理
def get_user_id(request: Request) -> str:
    """获取用户ID（基于IP和User-Agent的简单实现）"""
    ip = request.client.host
    user_agent = request.headers.get("user-agent", "")
    user_hash = hashlib.md5(f"{ip}:{user_agent}".encode()).hexdigest()
    return f"anon_{user_hash[:16]}"

# API端点
@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}

@app.post("/v1/config", response_model=ConfigResponse)
async def save_config(request: Request, config: APIConfig):
    """保存用户API配置"""
    user_id = get_user_id(request)

    try:
        # 加密API密钥
        encrypted_key = encrypt_api_key(config.apiKey)

        # 保存配置（不包含明文密钥）
        user_configs[user_id] = {
            "provider": config.provider,
            "encryptedApiKey": encrypted_key,
            "model": config.model,
            "baseUrl": config.baseUrl,
            "maxTokens": config.maxTokens,
            "temperature": config.temperature,
            "createdAt": datetime.now(timezone.utc).isoformat()
        }

        logger.info(f"用户 {user_id} 保存了 {config.provider} 配置")
        return ConfigResponse(success=True, message="配置保存成功")

    except Exception as e:
        logger.error(f"保存配置失败: {e}")
        raise HTTPException(status_code=500, detail="配置保存失败")

@app.get("/v1/config")
async def get_config(request: Request):
    """获取用户API配置"""
    user_id = get_user_id(request)

    if user_id not in user_configs:
        raise HTTPException(status_code=404, detail="未找到配置，请先配置API密钥")

    config = user_configs[user_id].copy()
    # 不返回加密的密钥
    config.pop("encryptedApiKey", None)

    return config

@app.delete("/v1/config", response_model=ConfigResponse)
async def delete_config(request: Request):
    """删除用户API配置"""
    user_id = get_user_id(request)

    if user_id in user_configs:
        del user_configs[user_id]
        logger.info(f"用户 {user_id} 删除了配置")
        return ConfigResponse(success=True, message="配置删除成功")

    return ConfigResponse(success=True, message="配置不存在")

@app.post("/v1/config/test", response_model=ConfigResponse)
async def test_config(request: Request, config: APIConfig):
    """测试API配置"""
    try:
        provider = create_provider(config.provider, config)
        is_valid = await provider.test_connection()
        await provider.close()

        if is_valid:
            return ConfigResponse(success=True, message="API连接测试成功")
        else:
            return ConfigResponse(success=False, message="API连接测试失败")

    except Exception as e:
        logger.error(f"测试配置失败: {e}")
        return ConfigResponse(success=False, message=f"测试失败: {str(e)}")

@app.post("/v1/generate", response_model=TaskResponse)
async def create_generation_task(request: Request, gen_request: GenerationRequest, background_tasks: BackgroundTasks):
    """创建图标生成任务"""
    user_id = get_user_id(request)

    # 检查用户配置
    if user_id not in user_configs:
        raise HTTPException(status_code=401, detail="请先配置API密钥")

    try:
        # 解密API密钥
        config_data = user_configs[user_id]
        decrypted_key = decrypt_api_key(config_data["encryptedApiKey"])

        # 创建配置对象
        config = APIConfig(
            provider=config_data["provider"],
            apiKey=decrypted_key,
            model=config_data["model"],
            baseUrl=config_data.get("baseUrl"),
            maxTokens=config_data.get("maxTokens", 1000),
            temperature=config_data.get("temperature", 0.7)
        )

        # 创建任务
        task_id = str(uuid.uuid4())
        generation_tasks[task_id] = {
            "id": task_id,
            "user_id": user_id,
            "status": "pending",
            "request": gen_request.dict(),
            "config": config.dict(exclude={"apiKey"}),
            "createdAt": datetime.now(timezone.utc).isoformat(),
            "result": None,
            "error": None
        }

        # 后台执行生成任务
        background_tasks.add_task(execute_generation_task, task_id)

        logger.info(f"用户 {user_id} 创建了生成任务 {task_id}")
        return TaskResponse(taskId=task_id, status="pending", message="任务创建成功")

    except Exception as e:
        logger.error(f"创建生成任务失败: {e}")
        raise HTTPException(status_code=500, detail="创建任务失败")

async def execute_generation_task(task_id: str):
    """执行图像生成任务"""
    if task_id not in generation_tasks:
        return

    task = generation_tasks[task_id]

    try:
        # 更新任务状态
        task["status"] = "processing"

        # 重新创建配置对象（包含解密的API密钥）
        config_data = user_configs[task["user_id"]]
        decrypted_key = decrypt_api_key(config_data["encryptedApiKey"])

        config = APIConfig(
            provider=config_data["provider"],
            apiKey=decrypted_key,
            model=config_data["model"],
            baseUrl=config_data.get("baseUrl"),
            maxTokens=config_data.get("maxTokens", 1000),
            temperature=config_data.get("temperature", 0.7)
        )

        # 创建提供商并执行生成
        provider = create_provider(config.provider, config)
        request_data = GenerationRequest(**task["request"])

        result = await provider.generate_image(request_data)
        await provider.close()

        # 保存结果
        task["status"] = "completed"
        task["result"] = result
        task["completedAt"] = datetime.now(timezone.utc).isoformat()

        logger.info(f"任务 {task_id} 生成完成")

    except Exception as e:
        task["status"] = "failed"
        task["error"] = str(e)
        task["failedAt"] = datetime.now(timezone.utc).isoformat()
        logger.error(f"任务 {task_id} 生成失败: {e}")

@app.get("/v1/task/{task_id}")
async def get_task_status(task_id: str):
    """获取任务状态"""
    if task_id not in generation_tasks:
        raise HTTPException(status_code=404, detail="任务不存在")

    task = generation_tasks[task_id]

    # 返回任务信息（不包含敏感配置）
    response = {
        "id": task["id"],
        "status": task["status"],
        "createdAt": task["createdAt"],
        "result": task.get("result"),
        "error": task.get("error")
    }

    if "completedAt" in task:
        response["completedAt"] = task["completedAt"]
    if "failedAt" in task:
        response["failedAt"] = task["failedAt"]

    return response

@app.get("/v1/providers")
async def get_supported_providers():
    """获取支持的AI提供商列表"""
    return {
        "providers": [
            {
                "id": "openai",
                "name": "OpenAI",
                "models": ["dall-e-3", "dall-e-2"],
                "description": "高质量的AI图像生成",
                "pricing": "付费"
            },
            {
                "id": "anthropic",
                "name": "Anthropic",
                "models": ["claude-3-opus-20240229", "claude-3-sonnet-20240229"],
                "description": "强大的多模态AI",
                "pricing": "付费"
            },
            {
                "id": "modelscope",
                "name": "ModelScope",
                "models": ["Qwen/Qwen-Image"],
                "description": "免费的图像生成服务",
                "pricing": "免费"
            }
        ]
    }

@app.get("/v1/models/{provider}")
async def get_provider_models(provider: str):
    """获取特定提供商的可用模型"""
    models = {
        "openai": ["dall-e-3", "dall-e-2"],
        "anthropic": ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"],
        "modelscope": ["Qwen/Qwen-Image", "AI-ModelScope/stable-diffusion-v1-5"]
    }

    if provider not in models:
        raise HTTPException(status_code=404, detail="提供商不存在")

    return {"provider": provider, "models": models[provider]}

# 启动事件
@app.on_event("startup")
async def startup_event():
    logger.info("Icons AI API服务启动")
    logger.info(f"支持的CORS源: {origins}")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Icons AI API服务关闭")

# 运行服务器
if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8787))
    host = os.getenv("HOST", "0.0.0.0")

    uvicorn.run(
        "server:app",
        host=host,
        port=port,
        reload=True,
        log_level="info"
    )