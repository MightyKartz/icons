'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Sparkles, Settings, ArrowRight, Zap, Shield, Globe, Star, Download, Apple, Monitor, Smartphone } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

export function HeroSection() {
  const [isConfigured, setIsConfigured] = useState(false)

  useEffect(() => {
    // 简化的配置检查，避免阻塞渲染
    const checkConfig = async () => {
      try {
        const response = await fetch('/api/config')
        if (response.ok) {
          setIsConfigured(true)
        }
      } catch (err) {
        // 静默处理错误，不影响页面渲染
        console.log('配置检查:', err instanceof Error ? err.message : String(err))
      }
    }

    checkConfig()
  }, [])

  const features = [
    {
      icon: Zap,
      title: "多AI提供商",
      description: "支持OpenAI、Anthropic、Stability AI等主流AI服务"
    },
    {
      icon: Shield,
      title: "隐私保护",
      description: "完全匿名使用，API密钥本地加密存储，数据不上传服务器"
    },
    {
      icon: Globe,
      title: "开源免费",
      description: "完全开源，MIT许可证，可自由部署和修改"
    }
  ]

  const stats = [
    { label: "AI提供商", value: "3+" },
    { label: "图标样式", value: "∞" },
    { label: "用户数量", value: "1000+" },
    { label: "开源协议", value: "MIT" }
  ]

  return (
    <section className="relative overflow-hidden py-16 sm:py-24">
      {/* Background Gradient - 匹配功能卡片颜色 */}
      <div className="absolute inset-0 bg-gradient-to-br from-white via-gray-50 to-white dark:from-background dark:via-gray-900/20 dark:to-background" />

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div className="text-center space-y-6">
          {/* Version Badge */}
          <div className="flex justify-center">
            <Badge variant="secondary" className="animate-pulse">
              <Sparkles className="mr-2 h-3 w-3" />
              全新 v2.0.1 版本
            </Badge>
          </div>

          {/* Main Heading */}
          <div className="space-y-3">
            <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-5xl lg:text-6xl animate-fade-in">
              AI图标生成
              <span className="block text-primary gradient-text">创意工具</span>
            </h1>
            <p className="mx-auto max-w-2xl text-lg text-muted-foreground sm:text-xl leading-relaxed">
              支持多种AI提供商，完全免费开源，数据本地存储，保护您的隐私。
              一键生成高质量图标，让创意变为现实。
              <span className="text-red-500 font-bold">[VERCEL SYNC TEST - COMMIT: a9b1d4d]</span>
            </p>
          </div>

          {/* App Store Promotion - 优化后更紧凑的布局 */}
          <div className="bg-gradient-to-br from-white via-gray-50 to-white border border-gray-200 rounded-2xl p-6 max-w-4xl mx-auto shadow-lg hover:shadow-xl transition-all duration-500">
            <div className="grid md:grid-cols-2 gap-6 items-center">
              {/* Left: App Info - 紧凑布局 */}
              <div className="flex flex-col items-center space-y-4">
                {/* App Icon and Title */}
                <div className="flex items-center gap-4">
                  <div className="bg-gradient-to-br from-black to-gray-800 p-3 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105">
                    <Apple className="h-6 w-6 text-white" />
                  </div>
                  <div className="text-left">
                    <h2 className="text-2xl font-bold text-gray-900 tracking-tight">XIconAI Studio</h2>
                    <p className="text-sm text-gray-600 font-medium">专业级macOS图标生成应用</p>
                  </div>
                </div>

                {/* Features List - 优化间距和文字大小 */}
                <div className="w-full flex justify-center">
                  <div className="space-y-2">
                    {[
                      { icon: Zap, text: "原生Swift开发，极致性能", color: "blue" },
                      { icon: Shield, text: "离线本地生成，隐私安全", color: "green" },
                      { icon: Star, text: "批量导出，高级定制", color: "purple" },
                      { icon: Globe, text: "App Store官方认证", color: "orange" }
                    ].map((feature, index) => (
                      <div key={index} className="flex items-center gap-3 text-left">
                        <div className={`bg-gradient-to-br from-${feature.color}-50 to-${feature.color}-100 rounded-lg p-1.5 flex-shrink-0 shadow-sm`}>
                          <feature.icon className={`h-3.5 w-3.5 text-${feature.color}-600`} />
                        </div>
                        <span className="text-gray-700 text-sm font-medium">{feature.text}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Download Button - 调整宽度与文字大小 */}
                <Button
                  size="sm"
                  className="bg-gradient-to-r from-black to-gray-800 hover:from-gray-800 hover:to-black text-white px-4 py-2 text-base font-medium rounded-lg shadow-md hover:shadow-lg transition-all duration-300 hover:scale-105"
                  asChild
                >
                  <a
                    href="https://apps.apple.com/cn/app/xiconai-studio/id6754810915?mt=12"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center"
                  >
                    <Download className="mr-2 h-4 w-4" />
                    App Store 下载
                  </a>
                </Button>
              </div>

              {/* Right: Features Grid - 紧凑布局 */}
              <div className="grid grid-cols-2 gap-3">
                {[
                  { icon: Smartphone, color: "blue", title: "原生性能", desc: "Swift开发", bg: "from-blue-50 to-blue-100" },
                  { icon: Shield, color: "green", title: "离线安全", desc: "数据不外传", bg: "from-green-50 to-green-100" },
                  { icon: Zap, color: "purple", title: "专业功能", desc: "高级定制", bg: "from-purple-50 to-purple-100" },
                  { icon: Star, color: "orange", title: "用户好评", desc: "高评分推荐", bg: "from-orange-50 to-orange-100" }
                ].map((item, index) => (
                  <div key={index} className={`bg-gradient-to-br ${item.bg} rounded-xl p-4 text-center space-y-2 border border-${item.color}-200 hover:border-${item.color}-300 transition-all duration-300 hover:shadow-md hover:scale-105`}>
                    <div className={`bg-${item.color}-100 w-10 h-10 rounded-xl flex items-center justify-center mx-auto shadow-sm`}>
                      <item.icon className={`h-5 w-5 text-${item.color}-600`} />
                    </div>
                    <h4 className="font-bold text-gray-900 text-sm">{item.title}</h4>
                    <p className="text-gray-600 text-xs font-medium">{item.desc}</p>
                  </div>
                ))}

                {/* Rating - 紧凑的评分展示 */}
                <div className="col-span-2 bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl p-4 text-center space-y-2 border border-yellow-300 shadow-md">
                  <div className="flex items-center justify-center gap-1">
                    {[1,2,3,4,5].map((star) => (
                      <Star key={star} className="h-5 w-5 text-yellow-500 fill-current" />
                    ))}
                  </div>
                  <p className="text-base font-bold text-gray-800">App Store官方认证</p>
                  <p className="text-sm text-gray-600">用户信赖的专业应用</p>
                </div>
              </div>
            </div>
          </div>

          {/* CTA Buttons - 优化间距和布局 */}
          <div className="flex flex-col sm:flex-row gap-3 justify-center items-center mt-8">
            {isConfigured ? (
              <Button size="lg" className="text-base px-6 py-2.5 font-medium" asChild>
                <Link href="/generate">
                  <Sparkles className="mr-2 h-4 w-4" />
                  开始生成图标
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Link>
              </Button>
            ) : (
              <Button size="lg" className="text-base px-6 py-2.5 font-medium" asChild>
                <Link href="/config">
                  <Settings className="mr-2 h-4 w-4" />
                  配置API密钥
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Link>
              </Button>
            )}

            <Button variant="outline" size="lg" className="text-base px-6 py-2.5 font-medium" asChild>
              <Link href="/docs">
                查看文档
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
          </div>

          {/* Stats - 优化间距和字体大小 */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 max-w-3xl mx-auto mt-12">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-2xl font-bold text-primary">{stat.value}</div>
                <div className="text-xs text-muted-foreground font-medium">{stat.label}</div>
              </div>
            ))}
          </div>

          {/* Feature Cards - 优化间距和布局 */}
          <div className="grid md:grid-cols-3 gap-5 max-w-4xl mx-auto mt-16">
            {features.map((feature, index) => (
              <Card key={index} className="relative overflow-hidden border-0 shadow-md hover:shadow-lg transition-all duration-300 hover:-translate-y-1">
                <CardContent className="p-5">
                  <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-primary/10 text-primary mb-3 mx-auto">
                    <feature.icon className="h-5 w-5" />
                  </div>
                  <h3 className="text-base font-semibold mb-2 text-foreground">
                    {feature.title}
                  </h3>
                  <p className="text-muted-foreground text-xs leading-relaxed">
                    {feature.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Trust Indicators - 优化间距 */}
          <div className="flex flex-wrap justify-center items-center gap-6 mt-12 text-muted-foreground text-xs">
            <div className="flex items-center gap-1.5">
              <Shield className="h-3.5 w-3.5" />
              <span>隐私优先</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Globe className="h-3.5 w-3.5" />
              <span>全球可用</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Star className="h-3.5 w-3.5" />
              <span>开源免费</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}