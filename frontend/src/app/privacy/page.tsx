'use client'

import Link from 'next/link'
import { ArrowLeft, Shield, Lock, Database, Eye, Server } from 'lucide-react'

export default function PrivacyPage() {
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
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 dark:bg-green-900 rounded-full mb-4">
            <Shield className="w-8 h-8 text-green-600 dark:text-green-400" />
          </div>
          <h1 className="text-4xl font-bold text-slate-900 dark:text-slate-100 mb-4">
            隐私政策
          </h1>
          <p className="text-xl text-slate-600 dark:text-slate-400 max-w-3xl mx-auto">
            我们重视您的隐私，本政策说明我们如何收集、使用和保护您的信息
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-500 mt-4">
            最后更新时间：2024年11月18日
          </p>
        </div>

        <div className="max-w-4xl mx-auto space-y-8">
          {/* 隐私承诺 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="flex items-center gap-3 mb-6">
              <Lock className="w-6 h-6 text-green-600 dark:text-green-400" />
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                我们的隐私承诺
              </h2>
            </div>
            <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6">
              <p className="text-slate-700 dark:text-slate-300 leading-relaxed">
                XIconAI 承诺保护您的隐私。我们采用隐私优先的设计理念，确保您的数据安全。
                我们不会收集、存储或传输您的个人信息，所有 API 密钥都在本地加密存储。
              </p>
            </div>
          </section>

          {/* 数据收集 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="flex items-center gap-3 mb-6">
              <Database className="w-6 h-6 text-blue-600 dark:text-blue-400" />
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                数据收集与使用
              </h2>
            </div>

            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-3">
                  我们不收集的信息
                </h3>
                <ul className="space-y-2 text-slate-600 dark:text-slate-400">
                  <li className="flex items-start gap-3">
                    <span className="text-green-500 mt-1">✓</span>
                    <span>不收集个人身份信息（姓名、邮箱、电话等）</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="text-green-500 mt-1">✓</span>
                    <span>不收集使用习惯或行为数据</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="text-green-500 mt-1">✓</span>
                    <span>不收集地理位置信息</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="text-green-500 mt-1">✓</span>
                    <span>不收集设备指纹或唯一标识符</span>
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-3">
                  本地存储的数据
                </h3>
                <ul className="space-y-2 text-slate-600 dark:text-slate-400">
                  <li className="flex items-start gap-3">
                    <span className="text-blue-500 mt-1">🔧</span>
                    <span><strong>API 密钥：</strong>在本地浏览器中加密存储，仅用于 API 调用</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="text-blue-500 mt-1">⚙️</span>
                    <span><strong>用户设置：</strong>AI 提供商偏好、模型选择等配置</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="text-blue-500 mt-1">🎨</span>
                    <span><strong>生成历史：</strong>本地存储的图标生成记录（可选）</span>
                  </li>
                </ul>
              </div>
            </div>
          </section>

          {/* API 密钥安全 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="flex items-center gap-3 mb-6">
              <Shield className="w-6 h-6 text-purple-600 dark:text-purple-400" />
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                API 密钥安全
              </h2>
            </div>

            <div className="space-y-6">
              <div className="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
                  安全保障措施
                </h3>
                <ul className="space-y-3 text-slate-600 dark:text-slate-400">
                  <li className="flex items-start gap-3">
                    <Lock className="w-5 h-5 text-purple-500 mt-0.5 flex-shrink-0" />
                    <div>
                      <strong>本地加密存储：</strong>
                      API 密钥使用 AES-256 加密算法在本地浏览器中存储
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <Server className="w-5 h-5 text-purple-500 mt-0.5 flex-shrink-0" />
                    <div>
                      <strong>直接传输：</strong>
                      密钥直接发送到对应的 AI 服务商，不经过我们的服务器
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <Eye className="w-5 h-5 text-purple-500 mt-0.5 flex-shrink-0" />
                    <div>
                      <strong>零知识架构：</strong>
                      我们无法访问、查看或恢复您的 API 密钥
                    </div>
                  </li>
                </ul>
              </div>

              <div className="grid md:grid-cols-2 gap-4">
                <div className="border border-slate-200 dark:border-slate-700 rounded-lg p-4">
                  <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                    OpenAI API 密钥
                  </h4>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    直接传输至 api.openai.com，符合 OpenAI 安全标准
                  </p>
                </div>
                <div className="border border-slate-200 dark:border-slate-700 rounded-lg p-4">
                  <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                    Anthropic API 密钥
                  </h4>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    直接传输至 api.anthropic.com，符合 Anthropic 安全标准
                  </p>
                </div>
                <div className="border border-slate-200 dark:border-slate-700 rounded-lg p-4">
                  <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                    Stability AI API 密钥
                  </h4>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    直接传输至 api.stability.ai，符合 Stability AI 安全标准
                  </p>
                </div>
                <div className="border border-slate-200 dark:border-slate-700 rounded-lg p-4">
                  <h4 className="font-semibold text-slate-900 dark:text-slate-100 mb-2">
                    ModelScope API 密钥
                  </h4>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    直接传输至 modelscope.cn，符合 ModelScope 安全标准
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* 数据传输 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="flex items-center gap-3 mb-6">
              <Server className="w-6 h-6 text-orange-600 dark:text-orange-400" />
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">
                数据传输与第三方服务
              </h2>
            </div>

            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-3">
                  数据流向
                </h3>
                <div className="bg-slate-50 dark:bg-slate-900 rounded-lg p-6">
                  <div className="space-y-4 text-sm">
                    <div className="flex items-center gap-4">
                      <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                      <span className="font-medium">您的浏览器</span>
                      <span className="text-slate-500">→</span>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="w-3 h-3 bg-green-500 rounded-full ml-8"></div>
                      <span className="font-medium">AI 服务商 API</span>
                      <span className="text-slate-500">（直接连接）</span>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="w-3 h-3 bg-purple-500 rounded-full ml-8"></div>
                      <span className="font-medium">生成的图标</span>
                      <span className="text-slate-500">→ 返回您的浏览器</span>
                    </div>
                  </div>
                </div>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-3">
                  第三方 AI 服务商
                </h3>
                <p className="text-slate-600 dark:text-slate-400 mb-4">
                  当您使用 XIconAI 时，您的生成请求会发送到以下第三方服务：
                </p>
                <ul className="space-y-2 text-slate-600 dark:text-slate-400">
                  <li>• <strong>OpenAI</strong> - 用于 DALL-E 图像生成</li>
                  <li>• <strong>Anthropic</strong> - 用于 Claude 多模态生成</li>
                  <li>• <strong>Stability AI</strong> - 用于 Stable Diffusion 生成</li>
                  <li>• <strong>ModelScope</strong> - 用于开源模型生成</li>
                </ul>
                <p className="text-sm text-slate-500 dark:text-slate-500 mt-4">
                  这些服务的使用受其各自的隐私政策约束。我们建议您查看相关服务的隐私政策。
                </p>
              </div>
            </div>
          </section>

          {/* Cookie 政策 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-6">
              Cookie 与跟踪
            </h2>

            <div className="space-y-4 text-slate-600 dark:text-slate-400">
              <p>
                XIconAI 尽量减少使用 Cookie 和跟踪技术：
              </p>
              <ul className="space-y-2">
                <li className="flex items-start gap-3">
                  <span className="text-red-500 mt-1">✗</span>
                  <span>不使用分析 Cookie 或跟踪 Cookie</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-500 mt-1">✗</span>
                  <span>不使用第三方跟踪服务（如 Google Analytics）</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-yellow-500 mt-1">⚠</span>
                  <span>仅使用必要的本地存储来保存用户设置</span>
                </li>
              </ul>
            </div>
          </section>

          {/* 用户权利 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-6">
              您的权利
            </h2>

            <div className="grid md:grid-cols-2 gap-6">
              <div className="border border-slate-200 dark:border-slate-700 rounded-lg p-6">
                <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-3">
                  数据控制权
                </h3>
                <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
                  <li>• 随时清除本地存储的数据</li>
                  <li>• 导出您的配置和设置</li>
                  <li>• 删除所有本地数据</li>
                  <li>• 选择不保存生成历史</li>
                </ul>
              </div>
              <div className="border border-slate-200 dark:border-slate-700 rounded-lg p-6">
                <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-3">
                  透明度
                </h3>
                <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
                  <li>• 查看源代码（开源项目）</li>
                  <li>• 了解数据处理流程</li>
                  <li>• 获取技术支持</li>
                  <li>• 报告隐私问题</li>
                </ul>
              </div>
            </div>
          </section>

          {/* 联系信息 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-6">
              联系我们
            </h2>

            <div className="space-y-4 text-slate-600 dark:text-slate-400">
              <p>
                如果您对本隐私政策有任何疑问或关注，请通过以下方式联系我们：
              </p>
              <div className="space-y-2">
                <p><strong>GitHub:</strong> <a href="https://github.com/MightyKartz/icons" target="_blank" rel="noopener noreferrer" className="text-blue-600 dark:text-blue-400 hover:underline">github.com/MightyKartz/icons</a></p>
                <p><strong>项目主页:</strong> <a href="https://frontend-nu-six-29.vercel.app/" target="_blank" rel="noopener noreferrer" className="text-blue-600 dark:text-blue-400 hover:underline">frontend-nu-six-29.vercel.app</a></p>
              </div>
            </div>
          </section>

          {/* 政策更新 */}
          <section className="bg-white dark:bg-slate-800 rounded-xl p-8 shadow-sm border border-slate-200 dark:border-slate-700">
            <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-6">
              政策更新
            </h2>

            <div className="space-y-4 text-slate-600 dark:text-slate-400">
              <p>
                我们可能会不时更新本隐私政策。任何重大变更都会通过以下方式通知您：
              </p>
              <ul className="space-y-2">
                <li>• 在网站首页显著位置发布通知</li>
                <li>• 更新本页面顶部的"最后更新时间"</li>
                <li>• 在 GitHub 仓库中发布更新说明</li>
              </ul>
              <p className="text-sm text-slate-500 dark:text-slate-500">
                建议您定期查看本政策以了解最新信息。
              </p>
            </div>
          </section>
        </div>

        {/* 页脚 */}
        <div className="text-center mt-12 pt-8 border-t border-slate-200 dark:border-slate-700">
          <p className="text-slate-600 dark:text-slate-400">
            XIconAI 致力于保护您的隐私和数据安全
          </p>
          <div className="flex justify-center gap-6 mt-4">
            <Link href="/docs" className="text-blue-600 dark:text-blue-400 hover:underline">
              使用文档
            </Link>
            <Link href="/" className="text-blue-600 dark:text-blue-400 hover:underline">
              返回首页
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}