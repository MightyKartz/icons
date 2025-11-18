'use client'

import { useState, useEffect } from 'react'
import { Sparkles, Settings, Download, Zap, Shield, Globe } from 'lucide-react'
import Link from 'next/link'

export default function HomePage() {
  const [isConfigured, setIsConfigured] = useState(false)

  useEffect(() => {
    // 检查用户是否已配置API
    const checkConfig = async () => {
      try {
        const response = await fetch('/api/config')
        if (response.ok) {
          setIsConfigured(true)
        }
      } catch (error) {
        console.log('未配置API')
      }
    }

    checkConfig()
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-purple-900">
      {/* 导航栏 */}
      <nav className="sticky top-0 z-50 glass border-b border-white/20 dark:border-gray-700/20">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-white">
                <Sparkles className="h-6 w-6" />
              </div>
              <span className="text-xl font-bold text-gray-900 dark:text-white">
                Icons
              </span>
            </div>

            <div className="flex items-center space-x-4">
              <Link
                href="/docs"
                className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                文档
              </Link>
              <Link
                href="/config"
                className="btn btn-outline btn-sm"
              >
                <Settings className="mr-2 h-4 w-4" />
                配置
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* 主要内容 */}
      <main className="container mx-auto px-4 py-16 sm:px-6 lg:px-8">
        <div className="text-center">
          {/* 标题区域 */}
          <div className="mb-12">
            <h1 className="responsive-heading font-bold text-gray-900 dark:text-white mb-6">
              免费AI图标生成工具
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto mb-8">
              支持多种AI提供商，包括OpenAI、Anthropic、ModelScope等。
              完全免费开源，数据本地存储，保护您的隐私。
            </p>

            {/* 行动按钮 */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              {isConfigured ? (
                <Link
                  href="/generate"
                  className="btn btn-primary btn-lg"
                >
                  <Sparkles className="mr-2 h-5 w-5" />
                  开始生成图标
                </Link>
              ) : (
                <Link
                  href="/config"
                  className="btn btn-primary btn-lg"
                >
                  <Settings className="mr-2 h-5 w-5" />
                  配置API密钥
                </Link>
              )}

              <Link
                href="/docs"
                className="btn btn-outline btn-lg"
              >
                查看文档
              </Link>
            </div>
          </div>

          {/* 特性展示 */}
          <div className="grid md:grid-cols-3 gap-8 mb-16">
            <div className="card p-6 hover-lift">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900 mb-4 mx-auto">
                <Zap className="h-6 w-6 text-blue-600 dark:text-blue-300" />
              </div>
              <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-white">
                多AI提供商
              </h3>
              <p className="text-gray-600 dark:text-gray-300">
                支持OpenAI、Anthropic、ModelScope、Stability AI等主流AI服务
              </p>
            </div>

            <div className="card p-6 hover-lift">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900 mb-4 mx-auto">
                <Shield className="h-6 w-6 text-green-600 dark:text-green-300" />
              </div>
              <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-white">
                隐私保护
              </h3>
              <p className="text-gray-600 dark:text-gray-300">
                完全匿名使用，API密钥本地加密存储，数据不上传服务器
              </p>
            </div>

            <div className="card p-6 hover-lift">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900 mb-4 mx-auto">
                <Globe className="h-6 w-6 text-purple-600 dark:text-purple-300" />
              </div>
              <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-white">
                开源免费
              </h3>
              <p className="text-gray-600 dark:text-gray-300">
                完全开源，MIT许可证，可自由部署和修改
              </p>
            </div>
          </div>

          {/* 支持的AI提供商 */}
          <div className="mb-16">
            <h2 className="text-2xl font-bold text-center mb-8 text-gray-900 dark:text-white">
              支持的AI提供商
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="card p-4 text-center">
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  OpenAI
                </div>
                <div className="text-xs text-gray-500 dark:text-gray-400">
                  DALL-E 3
                </div>
              </div>
              <div className="card p-4 text-center">
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  Anthropic
                </div>
                <div className="text-xs text-gray-500 dark:text-gray-400">
                  Claude 3
                </div>
              </div>
              <div className="card p-4 text-center">
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  ModelScope
                </div>
                <div className="text-xs text-green-600 dark:text-green-400">
                  免费使用
                </div>
              </div>
              <div className="card p-4 text-center">
                <div className="text-sm font-medium text-gray-900 dark:text-white">
                  Stability AI
                </div>
                <div className="text-xs text-gray-500 dark:text-gray-400">
                  Stable Diffusion
                </div>
              </div>
            </div>
          </div>

          {/* 快速开始指南 */}
          <div className="text-left max-w-4xl mx-auto">
            <h2 className="text-2xl font-bold mb-8 text-center text-gray-900 dark:text-white">
              快速开始
            </h2>
            <div className="space-y-6">
              <div className="flex items-start space-x-4">
                <div className="flex-shrink-0 w-8 h-8 bg-primary text-white rounded-full flex items-center justify-center text-sm font-bold">
                  1
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 dark:text-white mb-1">
                    配置API密钥
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300">
                    选择您喜欢的AI提供商，输入API密钥并测试连接。
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="flex-shrink-0 w-8 h-8 bg-primary text-white rounded-full flex items-center justify-center text-sm font-bold">
                  2
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 dark:text-white mb-1">
                    输入生成描述
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300">
                    用简单的文字描述您想要的图标样式和内容。
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="flex-shrink-0 w-8 h-8 bg-primary text-white rounded-full flex items-center justify-center text-sm font-bold">
                  3
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 dark:text-white mb-1">
                    生成和下载
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300">
                    点击生成按钮，等待几秒钟即可获得高质量的图标。
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* 页脚 */}
      <footer className="border-t border-gray-200 dark:border-gray-700 mt-20">
        <div className="container mx-auto px-4 py-8 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="flex items-center space-x-2 mb-4 md:mb-0">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-white">
                <Sparkles className="h-4 w-4" />
              </div>
              <span className="text-sm text-gray-600 dark:text-gray-300">
                Icons - 免费AI图标生成工具
              </span>
            </div>

            <div className="flex space-x-6">
              <Link
                href="/docs"
                className="text-sm text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                文档
              </Link>
              <Link
                href="https://github.com/MightyKartz/icons"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                GitHub
              </Link>
              <Link
                href="/privacy"
                className="text-sm text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                隐私政策
              </Link>
            </div>
          </div>

          <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
            <p className="text-center text-sm text-gray-500 dark:text-gray-400">
              © 2024 Icons. 基于 MIT 许可证开源。
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}