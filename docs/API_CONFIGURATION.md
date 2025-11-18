# API配置指南

本指南详细说明如何配置各种AI提供商的API密钥和参数。

## 🔧 支持的AI提供商

### 1. OpenAI

#### 获取API密钥
1. 访问 [OpenAI Platform](https://platform.openai.com/)
2. 注册/登录账号
3. 进入API密钥页面：https://platform.openai.com/account/api-keys
4. 创建新的API密钥

#### 配置参数
```json
{
  "provider": "openai",
  "apiKey": "sk-...",
  "model": "dall-e-3",
  "baseUrl": "https://api.openai.com/v1",
  "maxTokens": 1000,
  "temperature": 0.7
}
```

#### 支持的模型
- `dall-e-3` - 最佳质量，较慢
- `dall-e-2` - 较快，质量稍低

#### 费用参考
- DALL-E 3: $0.04/图 (1024×1024)
- DALL-E 2: $0.02/图 (1024×1024)

---

### 2. Anthropic Claude

#### 获取API密钥
1. 访问 [Anthropic Console](https://console.anthropic.com/)
2. 注册/登录账号
3. 在API Keys页面创建密钥

#### 配置参数
```json
{
  "provider": "anthropic",
  "apiKey": "sk-ant-...",
  "model": "claude-3-opus-20240229",
  "baseUrl": "https://api.anthropic.com",
  "maxTokens": 4096
}
```

#### 支持的模型
- `claude-3-opus-20240229` - 最强性能
- `claude-3-sonnet-20240229` - 平衡性能
- `claude-3-haiku-20240307` - 最快响应

#### 费用参考
- Claude 3 Opus: $15/百万输入token
- Claude 3 Sonnet: $3/百万输入token
- Claude 3 Haiku: $0.25/百万输入token

---

### 3. ModelScope（免费）

#### 获取API密钥
1. 访问 [ModelScope](https://modelscope.cn/)
2. 注册账号
3. 创建工作空间并获取API密钥

#### 配置参数
```json
{
  "provider": "modelscope",
  "apiKey": "ms-f051cff4-82df-494a-9460-c30275e685b9",
  "model": "Qwen/Qwen-Image",
  "baseUrl": "https://api-inference.modelscope.cn/v1"
}
```

#### 支持的模型
- `Qwen/Qwen-Image` - 免费图像生成
- `AI-ModelScope/stable-diffusion-v1-5` - Stable Diffusion

#### 费用
- 完全免费（有限额）

---

### 4. Stability AI

#### 获取API密钥
1. 访问 [Stability AI](https://platform.stability.ai/)
2. 注册/登录账号
3. 创建API密钥

#### 配置参数
```json
{
  "provider": "stability",
  "apiKey": "sk-...",
  "model": "stable-diffusion-xl-1024-v1-0",
  "baseUrl": "https://api.stability.ai/v1",
  "steps": 30,
  "cfg_scale": 7.0
}
```

#### 支持的模型
- `stable-diffusion-xl-1024-v1-0` - SDXL 1024×1024
- `stable-diffusion-512-v2-1` - SD 2.1 512×512

#### 费用参考
- SDXL: $0.04/图
- SD 2.1: $0.01/图

---

### 5. Google Gemini

#### 获取API密钥
1. 访问 [Google AI Studio](https://makersuite.google.com/app/apikey)
2. 创建项目并生成API密钥

#### 配置参数
```json
{
  "provider": "google",
  "apiKey": "AIza...",
  "model": "gemini-pro-vision",
  "baseUrl": "https://generativelanguage.googleapis.com/v1beta"
}
```

#### 支持的模型
- `gemini-pro-vision` - 多模态理解
- `imagen-3` - 图像生成

#### 费用参考
- Gemini Pro: 免费（有限额）
- Imagen 3: $0.02/图

---

### 6. Hugging Face

#### 获取API密钥
1. 访问 [Hugging Face](https://huggingface.co/)
2. 注册账号
3. 在设置中创建访问令牌

#### 配置参数
```json
{
  "provider": "huggingface",
  "apiKey": "hf_...",
  "model": "runwayml/stable-diffusion-v1-5",
  "baseUrl": "https://api-inference.huggingface.co/models"
}
```

#### 支持的模型
- `runwayml/stable-diffusion-v1-5`
- `stabilityai/stable-diffusion-2-1`
- 任何Hugging Face上的图像生成模型

#### 费用
- 大部分模型免费使用
- 部分推理API收费

---

## ⚙️ 高级配置

### 通用参数

| 参数 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `temperature` | float | 随机性，0-2之间 | 1.0 |
| `maxTokens` | int | 最大生成token数 | 1000 |
| `topP` | float | 核采样概率 | 1.0 |
| `frequencyPenalty` | float | 频率惩罚 | 0.0 |
| `presencePenalty` | float | 存在惩罚 | 0.0 |

### 图像生成参数

| 参数 | 类型 | 说明 | 范围 |
|------|------|------|------|
| `width` | int | 图像宽度 | 256-2048 |
| `height` | int | 图像高度 | 256-2048 |
| `steps` | int | 推理步数 | 10-150 |
| `cfgScale` | float | 引导强度 | 1.0-20.0 |
| `seed` | int | 随机种子 | 任意整数 |

## 🔒 安全配置

### API密钥安全
- **不要**在代码中硬编码API密钥
- **使用**环境变量或加密存储
- **定期**轮换API密钥
- **监控**API使用量和费用

### 环境变量配置
```bash
# OpenAI
OPENAI_API_KEY=sk-your-openai-key

# Anthropic
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key

# ModelScope
MODELSCOPE_API_KEY=ms-your-modelscope-key

# Stability AI
STABILITY_API_KEY=sk-your-stability-key

# Google
GOOGLE_API_KEY=AIza-your-google-key

# Hugging Face
HUGGINGFACE_API_KEY=hf-your-huggingface-key
```

### 加密存储配置
```javascript
// 前端加密存储示例
import CryptoJS from 'crypto-js';

const encryptApiKey = (apiKey, password) => {
  return CryptoJS.AES.encrypt(apiKey, password).toString();
};

const decryptApiKey = (encryptedKey, password) => {
  const bytes = CryptoJS.AES.decrypt(encryptedKey, password);
  return bytes.toString(CryptoJS.enc.Utf8);
};
```

## 🚀 性能优化

### 缓存策略
- **本地缓存**: 生成的图标本地缓存
- **CDN缓存**: 静态资源CDN加速
- **API缓存**: 相同请求结果缓存

### 批量处理
```javascript
// 批量生成示例
const batchGenerate = async (prompts, provider) => {
  const promises = prompts.map(prompt =>
    generateIcon({ prompt, provider })
  );

  return Promise.allSettled(promises);
};
```

### 重试机制
```javascript
const generateWithRetry = async (config, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await generateIcon(config);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await delay(Math.pow(2, i) * 1000); // 指数退避
    }
  }
};
```

## 🐛 故障排除

### 常见错误

#### 1. API密钥无效
```
Error: Invalid API key
```
**解决方案**: 检查API密钥是否正确，是否有足够的权限和余额

#### 2. 请求频率限制
```
Error: Rate limit exceeded
```
**解决方案**: 实施请求限流，添加重试机制

#### 3. 模型不支持
```
Error: Model not supported
```
**解决方案**: 检查模型名称是否正确，是否在支持的列表中

#### 4. 内容过滤
```
Error: Content policy violation
```
**解决方案**: 调整提示词，避免敏感内容

### 调试工具

#### API测试
```bash
# 测试OpenAI API
curl -X POST https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A simple icon", "n": 1, "size": "1024x1024"}'
```

#### 日志记录
```javascript
const logger = {
  info: (message, data) => console.log(`[INFO] ${message}`, data),
  error: (message, error) => console.error(`[ERROR] ${message}`, error),
  debug: (message, data) => console.debug(`[DEBUG] ${message}`, data)
};
```

## 📞 获取帮助

如果在配置过程中遇到问题：

1. **查看文档**: [项目文档](../README.md)
2. **提交Issue**: [GitHub Issues](https://github.com/MightyKartz/icons/issues)
3. **社区讨论**: [GitHub Discussions](https://github.com/MightyKartz/icons/discussions)

---

更多详细信息请参考各AI提供商的官方文档。