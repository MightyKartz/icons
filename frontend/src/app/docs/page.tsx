'use client'

import Link from 'next/link'
import { ArrowLeft, Book, Settings, Zap, Shield, HelpCircle } from 'lucide-react'

export default function DocsPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto px-4 py-8">
        {/* 导航栏 */}
        <nav className="mb-8">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            返回首页
          </Link>
        </nav>

        {/* 页面标题 */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full mb-4">
            <Book className="w-8 h-8 text-blue-600 dark:text-blue-400" />
          </div>
          <h1 className="text-4xl font-bold text-slate-900 dark:text-slate-100 mb-4">
            使用文档
          </h1>
          <p className="text-xl text-slate-600 dark:text-slate-400 max-w-3xl mx-auto">
            详细了解如何使用 XIconAI 生成高质量图标
          </p>
        </div>

        <div className="grid lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {/* 侧边栏导航 */}
          <div className="lg:col-span-1">
            <div className="sticky top-8 space-y-2">
              <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-4">快速导航</h3>
              <nav className="space-y-1">
                <a href="#getting-started" className="block px-4 py-2 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                  快速开始
                </a>
                <a href="#configuration" className="block px-4 py-2 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                  配置指南
                </a>
                <a href="#generation" className="block px-4 py-2 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                  图标生成
                </a>
                <a href="#api-reference" className="block px-4 py-2 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                  API 参考
                </a>
                <a href="#faq" className="block px-4 py-2 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                  常见问题
                </a>
              </nav>
            </div>
          </div>

          {/* 主要内容 */}
          <div className="lg:col-span-2 space-y-12">
            {/* 快速开始 */}
            <section id="getting-started" className="scroll-mt-8">
              <div className="flex items-center gap-3 mb-6">
                <div className="flex items-center justify-center w-10 h-10 bg-green-100 dark:bg-green-900 rounded-full">
                  <Zap className="w-5 h-5 text-green-600 dark:text-green-400" />
                </div>
                <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                  快速开始
                </h2>
              </div>

              <div className="bg-white dark:bg-slate-800 rounded-xl p-6 shadow-sm border border-slate-200 dark:border-slate-700">
                <div className="space-y-6">
                  <div className="flex gap-4">
                    <div className="flex-shrink-0 w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center text-sm font-semibold text-blue-600 dark:text-blue-400">
                      1
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                        配置 API 密钥
                      </h3>
                      <p className="text-slate-600 dark:text-slate-400">
                        前往配置页面，选择您喜欢的 AI 提供商，输入 API 密钥并测试连接。
                      </p>
                    </div>
                  </div>

                  <div className="flex gap-4">
                    <div className="flex-shrink-0 w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center text-sm font-semibold text-blue-600 dark:text-blue-400">
                      2
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                        输入生成描述
                      </h3>
                      <p className="text-slate-600 dark:text-slate-400">
                        用简单的文字描述您想要的图标样式和内容，例如"一个简约的相机图标"。
                      </p>
                    </div>
                  </div>

                  <div className="flex gap-4">
                    <div className="flex-shrink-0 w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center text-sm font-semibold text-blue-600 dark:text-blue-400">
                      3
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                        生成和下载
                      </h3>
                      <p className="text-slate-600 dark:text-slate-400">
                        点击生成按钮，等待几秒钟即可获得高质量的图标，支持多种格式下载。
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* 配置指南 */}
            <section id="configuration" className="scroll-mt-8">
              <div className="flex items-center gap-3 mb-6">
                <div className="flex items-center justify-center w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full">
                  <Settings className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                </div>
                <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                  配置指南
                </h2>
              </div>

              <div className="bg-white dark:bg-slate-800 rounded-xl p-6 shadow-sm border border-slate-200 dark:border-slate-700">
                <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-4">
                  支持的 AI 提供商
                </h3>

                <div className="space-y-4">
                  <div className="border-l-4 border-blue-500 pl-4">
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100">OpenAI</h4>
                    <p className="text-slate-600 dark:text-slate-400 mb-2">高质量的 AI 图像生成服务</p>
                    <ul className="text-sm text-slate-500 dark:text-slate-500 space-y-1">
                      <li>• 模型：DALL-E 3, DALL-E 2</li>
                      <li>• 特点：质量高，理解能力强</li>
                      <li>• 获取 API 密钥：<a href="https://platform.openai.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 dark:text-blue-400 hover:underline">OpenAI Platform</a></li>
                    </ul>
                  </div>

                  <div className="border-l-4 border-purple-500 pl-4">
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100">Anthropic</h4>
                    <p className="text-slate-600 dark:text-slate-400 mb-2">强大的多模态 AI</p>
                    <ul className="text-sm text-slate-500 dark:text-slate-500 space-y-1">
                      <li>• 模型：Claude 3 Opus, Claude 3 Sonnet</li>
                      <li>• 特点：多模态理解，逻辑推理强</li>
                      <li>• 获取 API 密钥：<a href="https://console.anthropic.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 dark:text-blue-400 hover:underline">Anthropic Console</a></li>
                    </ul>
                  </div>

                  <div className="border-l-4 border-green-500 pl-4">
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100">Stability AI</h4>
                    <p className="text-slate-600 dark:text-slate-400 mb-2">开源图像生成模型</p>
                    <ul className="text-sm text-slate-500 dark:text-slate-500 space-y-1">
                      <li>• 模型：Stable Diffusion XL, Stable Diffusion 3</li>
                      <li>• 特点：开源灵活，风格多样</li>
                      <li>• 获取 API 密钥：<a href="https://platform.stability.ai" target="_blank" rel="noopener noreferrer" className="text-blue-600 dark:text-blue-400 hover:underline">Stability AI Platform</a></li>
                    </ul>
                  </div>
                </div>
              </div>
            </section>

            {/* 图标生成 */}
            <section id="generation" className="scroll-mt-8">
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-6">
                图标生成
              </h2>

              <div className="bg-white dark:bg-slate-800 rounded-xl p-6 shadow-sm border border-slate-200 dark:border-slate-700">
                <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-4">
                  最佳实践
                </h3>

                <div className="space-y-4">
                  <div>
                    <h4 className="font-medium text-slate-900 dark:text-slate-100 mb-2">描述技巧</h4>
                    <ul className="text-slate-600 dark:text-slate-400 space-y-2">
                      <li>• 使用简洁明了的语言描述图标内容</li>
                      <li>• 指定风格：简约、扁平、线条、彩色等</li>
                      <li>• 可以参考："一个简约的相机图标，扁平设计，蓝色"</li>
                    </ul>
                  </div>

                  <div>
                    <h4 className="font-medium text-slate-900 dark:text-slate-100 mb-2">风格建议</h4>
                    <ul className="text-slate-600 dark:text-slate-400 space-y-2">
                      <li>• <strong>简约风格</strong>：适合现代界面设计</li>
                      <li>• <strong>扁平设计</strong>：清晰易识别</li>
                      <li>• <strong>线条图标</strong>：轻量优雅</li>
                      <li>• <strong>彩色图标</strong>：活泼生动</li>
                    </ul>
                  </div>
                </div>
              </div>
            </section>

            {/* API 参考 */}
            <section id="api-reference" className="scroll-mt-8">
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-6">
                API 参考
              </h2>

              <div className="bg-white dark:bg-slate-800 rounded-xl p-6 shadow-sm border border-slate-200 dark:border-slate-700">
                <div className="space-y-6">
                  <div>
                    <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-3">
                      获取版本信息
                    </h3>
                    <div className="bg-slate-900 text-slate-100 p-4 rounded-lg font-mono text-sm">
                      <div>GET /api/version</div>
                    </div>
                  </div>

                  <div>
                    <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-3">
                      获取 AI 提供商列表
                    </h3>
                    <div className="bg-slate-900 text-slate-100 p-4 rounded-lg font-mono text-sm">
                      <div>GET /api/providers</div>
                    </div>
                  </div>

                  <div>
                    <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-3">
                      生成图标
                    </h3>
                    <div className="bg-slate-900 text-slate-100 p-4 rounded-lg font-mono text-sm">
                      <div>POST /api/generate</div>
                      <div className="mt-2 text-slate-400">
                        {`{"provider": "openai", "model": "dall-e-3", "prompt": "相机图标"}`}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* 常见问题 */}
            <section id="faq" className="scroll-mt-8">
              <div className="flex items-center gap-3 mb-6">
                <div className="flex items-center justify-center w-10 h-10 bg-purple-100 dark:bg-purple-900 rounded-full">
                  <HelpCircle className="w-5 h-5 text-purple-600 dark:text-purple-400" />
                </div>
                <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                  常见问题
                </h2>
              </div>

              <div className="bg-white dark:bg-slate-800 rounded-xl p-6 shadow-sm border border-slate-200 dark:border-slate-700">
                <div className="space-y-6">
                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                      API 密钥会被上传到服务器吗？
                    </h4>
                    <p className="text-slate-600 dark:text-slate-400">
                      不会。所有 API 密钥都在本地加密存储，直接发送到对应的 AI 服务商，我们不会保存或传输您的密钥。
                    </p>
                  </div>

                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                      支持哪些图片格式？
                    </h4>
                    <p className="text-slate-600 dark:text-slate-400">
                      目前支持 PNG 和 JPEG 格式下载，分辨率通常为 1024x1024 像素。
                    </p>
                  </div>

                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                      生成一个图标需要多长时间？
                    </h4>
                    <p className="text-slate-600 dark:text-slate-400">
                      通常需要 5-15 秒，具体时间取决于 AI 提供商的响应速度和网络状况。
                    </p>
                  </div>

                  <div>
                    <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                      为什么生成失败了？
                    </h4>
                    <p className="text-slate-600 dark:text-slate-400">
                      可能的原因包括：API 密钥无效、网络连接问题、描述内容违反使用政策等。请检查配置并重试。
                    </p>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  )
}