# Icons - 免费开源AI图标生成工具

<div align="center">

![Icons Logo](https://img.shields.io/badge/Icons-AI%20Icon%20Generator-blue?style=for-the-badge&logo=artstation)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/MightyKartz/icons.svg?style=social&label=Star)](https://github.com/MightyKartz/icons)
[![GitHub forks](https://img.shields.io/github/forks/MightyKartz/icons.svg?style=social&label=Fork)](https://github.com/MightyKartz/icons)

**🎨 多平台AI图标生成工具 - 支持多种AI提供商，完全免费开源**

[功能特点](#功能特点) • [快速开始](#快速开始) • [配置指南](#配置指南) • [部署说明](#部署说明)

</div>

## ✨ 功能特点

### 🤖 多AI提供商支持
- **OpenAI**: DALL-E 3, GPT-4 Vision
- **Anthropic**: Claude 3 Vision
- **ModelScope**: Qwen-Image (免费)
- **Stability AI**: Stable Diffusion
- **Google**: Gemini Vision
- **Hugging Face**: 开源模型
- **自定义端点**: 支持任何兼容API

### 🖥️ 全平台支持
- **Web应用**: React + TypeScript，响应式设计
- **macOS应用**: 原生Swift应用，完整功能
- **API服务**: FastAPI后端，高性能

### 🎯 核心功能
- 智能图标生成和优化
- 多种生成模式（标准、Apple HIG、高对比度等）
- 实时预览和编辑
- 批量导出支持
- SF Symbols集成
- 本地配置存储

### 🔒 隐私保护
- 完全匿名使用，无需注册
- API密钥本地加密存储
- 数据不上传到我们的服务器
- 开源透明，可自部署

## 🚀 快速开始

### Web版本（推荐）

1. **访问在线演示**
   ```
   https://icons-demo.vercel.app
   ```

2. **配置API密钥**
   - 点击设置按钮
   - 选择AI提供商
   - 输入API密钥
   - 测试连接

3. **开始生成**
   - 输入图标描述
   - 选择风格和尺寸
   - 点击生成按钮

### 本地部署

#### 前置要求
- Node.js 18+
- Python 3.8+
- 可选：Xcode 14+（macOS应用）

#### 1. 克隆仓库
```bash
git clone https://github.com/MightyKartz/icons.git
cd icons
```

#### 2. 启动后端
```bash
cd backend
pip install -r requirements.txt
python server.py
```

#### 3. 启动前端
```bash
cd frontend
npm install
npm run dev
```

#### 4. 打开macOS应用（可选）
```bash
open Icons.xcodeproj
# 在Xcode中运行
```

## ⚙️ 配置指南

### API提供商配置

#### OpenAI
```json
{
  "provider": "openai",
  "apiKey": "sk-...",
  "model": "dall-e-3",
  "baseUrl": "https://api.openai.com/v1"
}
```

#### Anthropic
```json
{
  "provider": "anthropic",
  "apiKey": "sk-ant-...",
  "model": "claude-3-opus-20240229"
}
```

#### ModelScope（免费）
```json
{
  "provider": "modelscope",
  "apiKey": "ms-f051cff4-82df-494a-9460-c30275e685b9",
  "model": "Qwen/Qwen-Image"
}
```

### 环境变量

```bash
# 后端配置
PORT=8787
CORS_ORIGINS=http://localhost:3000

# 可选：默认API配置
DEFAULT_PROVIDER=modelscope
DEFAULT_API_KEY=your-api-key
```

## 🌐 部署说明

### Vercel部署（前端）

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/MightyKartz/icons)

1. 点击上面的按钮
2. 连接GitHub账号
3. 配置环境变量
4. 部署完成

### Railway部署（后端）

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template?template=https://github.com/MightyKartz/icons)

1. 点击上面的按钮
2. 连接GitHub账号
3. 配置环境变量
4. 部署完成

### Docker部署

```bash
# 构建镜像
docker build -t icons .

# 运行容器
docker run -p 8787:8787 -e API_KEY=your-key icons
```

## 📁 项目结构

```
icons/
├── frontend/              # React前端应用
│   ├── src/
│   │   ├── components/    # UI组件
│   │   ├── pages/         # 页面
│   │   ├── services/      # API服务
│   │   └── utils/         # 工具函数
│   ├── public/
│   └── package.json
├── backend/               # FastAPI后端
│   ├── app/
│   │   ├── api/          # API路由
│   │   ├── core/         # 核心配置
│   │   ├── models/       # 数据模型
│   │   └── services/     # 业务逻辑
│   ├── requirements.txt
│   └── server.py
├── Icons/                 # macOS应用
│   ├── Sources/
│   │   ├── Views/        # SwiftUI视图
│   │   ├── Services/     # 服务层
│   │   ├── Models/       # 数据模型
│   │   └── Utilities/    # 工具类
│   └── Package.swift
├── docs/                  # 文档
└── docker/               # Docker配置
```

## 🎨 使用示例

### 基础图标生成
```typescript
const config = {
  prompt: "一个现代简约的相机图标，线条风格",
  provider: "openai",
  model: "dall-e-3",
  size: "1024x1024",
  style: "icon"
};

const result = await generateIcon(config);
```

### 批量生成
```typescript
const prompts = [
  "设置齿轮图标",
  "用户头像图标",
  "消息通知图标"
];

const results = await batchGenerate(prompts);
```

## 🔧 开发指南

### 本地开发环境

1. **安装依赖**
   ```bash
   # 前端
   npm install

   # 后端
   pip install -r requirements.txt

   # macOS应用（可选）
   swift package resolve
   ```

2. **启动开发服务器**
   ```bash
   # 后端（终端1）
   cd backend && python server.py

   # 前端（终端2）
   cd frontend && npm run dev
   ```

3. **运行测试**
   ```bash
   # 前端测试
   npm test

   # 后端测试
   cd backend && python -m pytest

   # Swift测试
   cd Icons && swift test
   ```

### 贡献指南

我们欢迎所有形式的贡献！

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m '添加某个功能'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

请确保：
- 遵循代码规范
- 添加适当的测试
- 更新相关文档

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 致谢

- 感谢所有AI提供商提供的优秀服务
- 感谢开源社区的支持和贡献
- 特别感谢所有测试用户和反馈者

## 📞 联系我们

- 项目主页: [https://github.com/MightyKartz/icons](https://github.com/MightyKartz/icons)
- 问题反馈: [GitHub Issues](https://github.com/MightyKartz/icons/issues)
- 讨论交流: [GitHub Discussions](https://github.com/MightyKartz/icons/discussions)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给我们一个Star！**

Made with ❤️ by [MightyKartz](https://github.com/MightyKartz)

</div>