# 部署指南

本指南详细说明如何在不同平台部署Icons项目。

## 🌐 部署选项

### 1. Vercel + Railway（推荐）
- **前端**: Vercel（免费）
- **后端**: Railway（免费额度）
- **数据库**: Supabase（免费）
- **总成本**: $0/月

### 2. 完全免费
- **前端**: Vercel Pages
- **后端**: Render（免费）
- **存储**: 本地存储
- **总成本**: $0/月

### 3. 自托管
- **服务器**: 自己的VPS
- **数据库**: PostgreSQL/MySQL
- **存储**: 本地文件系统
- **总成本**: 服务器费用

---

## 🚀 快速部署（Vercel + Railway）

### 前置准备
- GitHub账号
- Railway账号
- 可选：自定义域名

### 步骤1：部署前端到Vercel

1. **访问Vercel**
   ```
   https://vercel.com/new
   ```

2. **导入项目**
   - 点击"Import Project"
   - 连接GitHub账号
   - 选择`icons`仓库
   - 选择`frontend`目录

3. **配置环境变量**
   ```
   NEXT_PUBLIC_API_URL=https://your-backend.railway.app
   NEXT_PUBLIC_APP_NAME=Icons
   ```

4. **部署**
   - 点击"Deploy"
   - 等待部署完成
   - 记录部署URL

### 步骤2：部署后端到Railway

1. **访问Railway**
   ```
   https://railway.app/new
   ```

2. **导入项目**
   - 选择"Deploy from GitHub repo"
   - 选择`icons`仓库
   - 选择服务类型：Python

3. **配置环境变量**
   ```bash
   PORT=8787
   CORS_ORIGINS=https://your-vercel-app.vercel.app

   # AI提供商配置（可选）
   DEFAULT_PROVIDER=modelscope
   DEFAULT_API_KEY=your-api-key
   ```

4. **设置启动命令**
   ```bash
   cd backend && pip install -r requirements.txt && python server.py
   ```

5. **部署**
   - 点击"Deploy Now"
   - 等待部署完成
   - 记录Railway URL

### 步骤3：配置跨域

在后端添加Vercel域名到CORS允许列表：
```bash
CORS_ORIGINS=https://your-app.vercel.app,http://localhost:3000
```

---

## 🔧 详细配置

### 前端配置（Next.js）

#### package.json
```json
{
  "name": "icons-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "axios": "^1.6.0",
    "typescript": "^5.0.0"
  }
}
```

#### next.config.js
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['your-backend.railway.app'],
  },
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
};

module.exports = nextConfig;
```

#### 环境变量
```bash
# .env.local
NEXT_PUBLIC_API_URL=https://your-backend.railway.app
NEXT_PUBLIC_APP_NAME=Icons
NEXT_PUBLIC_VERSION=1.0.0
```

### 后端配置（FastAPI）

#### requirements.txt
```txt
fastapi>=0.104.0
uvicorn>=0.24.0
pydantic>=2.5.0
python-multipart>=0.0.6
httpx>=0.25.0
python-jose>=3.3.0
passlib>=1.7.4
```

#### Dockerfile（可选）
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8787

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8787"]
```

#### server.py
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(title="Icons API", version="1.0.0")

# CORS配置
origins = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8787))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

---

## 🐳 Docker部署

### Docker Compose配置

#### docker-compose.yml
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8787
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8787:8787"
    environment:
      - PORT=8787
      - CORS_ORIGINS=http://localhost:3000
    volumes:
      - ./backend:/app

  database:
    image: postgres:15
    environment:
      - POSTGRES_DB=icons
      - POSTGRES_USER=icons
      - POSTGRES_PASSWORD=icons123
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

### 前端Dockerfile

```dockerfile
# frontend/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

### 后端Dockerfile

```dockerfile
# backend/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8787

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8787"]
```

### 部署命令
```bash
# 构建和启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## 🌐 CDN和静态资源

### Vercel配置

#### vercel.json
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/api/$1"
    }
  ],
  "env": {
    "NEXT_PUBLIC_API_URL": "@api_url"
  }
}
```

### 图片优化

```javascript
// next.config.js
const nextConfig = {
  images: {
    domains: ['your-backend.com'],
    formats: ['image/webp', 'image/avif'],
    minimumCacheTTL: 60 * 60 * 24 * 7, // 7天
  },
};
```

---

## 🔒 安全配置

### HTTPS证书

#### Vercel（自动）
- Vercel自动提供HTTPS证书
- 无需额外配置

#### Railway（自动）
- Railway自动提供HTTPS证书
- 使用`.railway.app`子域名

#### 自定义域名
```bash
# DNS配置
A记录：your-domain.com -> 负载均衡器IP
CNAME：www -> your-domain.com
```

### 安全头配置

```python
# backend/middleware.py
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["yourdomain.com", "*.yourdomain.com"]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
```

---

## 📊 监控和日志

### Vercel Analytics

1. **启用分析**
   - 访问Vercel Dashboard
   - 进入项目设置
   - 启用Web Analytics

2. **查看指标**
   - 页面访问量
   - Web Vitals
   - 错误率

### Railway Logs

```bash
# 查看实时日志
railway logs

# 查看特定服务日志
railway logs <service-name>
```

### 自定义监控

```python
# backend/monitoring.py
import logging
import time
from functools import wraps

# 日志配置
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def monitor_performance(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            duration = time.time() - start_time
            logger.info(f"{func.__name__} completed in {duration:.2f}s")
            return result
        except Exception as e:
            duration = time.time() - start_time
            logger.error(f"{func.__name__} failed after {duration:.2f}s: {e}")
            raise
    return wrapper
```

---

## 🔄 CI/CD自动化

### GitHub Actions

#### .github/workflows/deploy.yml
```yaml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      run: |
        cd frontend && npm ci
        cd ../backend && pip install -r requirements.txt

    - name: Run tests
      run: |
        cd frontend && npm test
        cd ../backend && python -m pytest

  deploy-frontend:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to Vercel
      uses: amondnet/vercel-action@v20
      with:
        vercel-token: ${{ secrets.VERCEL_TOKEN }}
        vercel-org-id: ${{ secrets.ORG_ID }}
        vercel-project-id: ${{ secrets.PROJECT_ID }}
        working-directory: ./frontend

  deploy-backend:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to Railway
      uses: railway-app/railway-action@v1
      with:
        railway-token: ${{ secrets.RAILWAY_TOKEN }}
        service: backend
```

### 环境变量配置

在GitHub仓库设置中添加：
- `VERCEL_TOKEN`: Vercel API Token
- `RAILWAY_TOKEN`: Railway API Token
- `ORG_ID`: Vercel组织ID
- `PROJECT_ID`: Vercel项目ID

---

## 🚨 故障排除

### 常见问题

#### 1. CORS错误
```
Access to fetch at '...' has been blocked by CORS policy
```
**解决方案**:
- 检查后端CORS配置
- 确保前端域名在允许列表中
- 检查API URL是否正确

#### 2. 环境变量未生效
**解决方案**:
- 重新部署应用
- 检查变量名拼写
- 确认平台环境变量格式

#### 3. 构建失败
**解决方案**:
- 检查依赖版本兼容性
- 查看构建日志
- 本地测试构建

#### 4. 数据库连接失败
**解决方案**:
- 检查数据库URL
- 确认网络连接
- 验证凭据

### 调试工具

#### 本地调试
```bash
# 前端调试
cd frontend && npm run dev

# 后端调试
cd backend && python -m uvicorn server:app --reload --log-level debug
```

#### 远程调试
```bash
# 查看Vercel日志
vercel logs

# 查看Railway日志
railway logs
```

---

## 📞 获取帮助

如果在部署过程中遇到问题：

1. **查看文档**: [API配置指南](API_CONFIGURATION.md)
2. **提交Issue**: [GitHub Issues](https://github.com/MightyKartz/icons/issues)
3. **社区讨论**: [GitHub Discussions](https://github.com/MightyKartz/icons/discussions)

---

部署完成后，您就拥有了一个完全可用的AI图标生成平台！🎉