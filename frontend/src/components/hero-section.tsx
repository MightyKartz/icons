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
        console.log('配置检查:', err.message)
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
    <section className="relative overflow-hidden py-20 sm:py-32">
      {/* Background Gradient - 匹配功能卡片颜色 */}
      <div className="absolute inset-0 bg-gradient-to-br from-white via-gray-50 to-white dark:from-background dark:via-gray-900/20 dark:to-background" />

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div className="text-center space-y-8">
          {/* Version Badge */}
          <div className="flex justify-center">
            <Badge variant="secondary" className="animate-pulse">
              <Sparkles className="mr-2 h-3 w-3" />
              全新 v2.0.1 版本
            </Badge>
          </div>

          {/* Main Heading */}
          <div className="space-y-4">
            <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-6xl lg:text-7xl animate-fade-in">
              AI图标生成
              <span className="block text-primary gradient-text">创意工具</span>
            </h1>
            <p className="mx-auto max-w-2xl text-xl text-muted-foreground sm:text-2xl">
              支持多种AI提供商，完全免费开源，数据本地存储，保护您的隐私。
              一键生成高质量图标，让创意变为现实。
            </p>
          </div>

          {/* App Store Promotion */}
          <div className="bg-gradient-to-br from-white via-gray-50 to-white border border-gray-200 rounded-2xl p-8 max-w-5xl mx-auto shadow-xl hover:shadow-2xl transition-all duration-500">
            <div className="grid md:grid-cols-2 gap-8 items-center">
              {/* Left: App Info */}
              <div className="flex flex-col items-center space-y-6">
                {/* App Icon and Title */}
                <div className="flex flex-col items-center space-y-4">
                  <div className="bg-gradient-to-br from-black via-gray-800 to-black p-4 rounded-3xl shadow-2xl hover:shadow-3xl transition-all duration-300 hover:scale-105">
                    <Apple className="h-8 w-8 text-white" />
                  </div>
                  <div className="text-center space-y-2">
                    <h2 className="text-3xl font-bold text-gray-900 tracking-tight">XIconAI Studio</h2>
                    <p className="text-lg text-gray-600 font-medium">专业级macOS图标生成应用</p>
                  </div>
                </div>

                {/* Features List */}
                <div className="w-full max-w-sm">
                  <div className="space-y-3">
                    {[
                      { icon: Zap, text: "原生Swift开发，极致性能体验", color: "blue" },
                      { icon: Shield, text: "离线本地生成，数据隐私安全", color: "green" },
                      { icon: Star, text: "批量导出功能，高级定制选项", color: "purple" },
                      { icon: Globe, text: "App Store官方认证应用", color: "orange" }
                    ].map((feature, index) => (
                      <div key={index} className="flex items-center gap-3 group text-left">
                        <div className={`bg-gradient-to-br from-${feature.color}-50 to-${feature.color}-100 rounded-xl p-2 flex-shrink-0 shadow-md group-hover:shadow-lg transition-all duration-300 group-hover:scale-110`}>
                          <feature.icon className={`h-4 w-4 text-${feature.color}-600`} />
                        </div>
                        <span className="text-gray-700 text-sm font-semibold group-hover:text-gray-900 transition-colors duration-300">{feature.text}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Download Button */}
                <div className="w-full max-w-sm">
                  <Button
                    className="w-full bg-gradient-to-r from-black via-gray-800 to-black hover:from-gray-800 hover:via-gray-700 hover:to-black text-white px-8 py-4 text-sm font-bold rounded-2xl shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105"
                    asChild
                  >
                    <a
                      href="https://apps.apple.com/cn/app/xiconai-studio/id6754810915?mt=12"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center"
                    >
                      <Download className="mr-2 h-5 w-5" />
                      App Store下载
                    </a>
                  </Button>
                </div>
              </div>

              {/* Right: Features Grid */}
              <div className="space-y-6">
                <div className="grid grid-cols-2 gap-4">
                  {[
                    { icon: Smartphone, color: "blue", title: "原生性能", desc: "Swift原生开发", bg: "from-blue-50 to-blue-100" },
                    { icon: Shield, color: "green", title: "离线安全", desc: "数据不外传", bg: "from-green-50 to-green-100" },
                    { icon: Zap, color: "purple", title: "专业功能", desc: "高级定制", bg: "from-purple-50 to-purple-100" },
                    { icon: Star, color: "orange", title: "用户好评", desc: "高评分推荐", bg: "from-orange-50 to-orange-100" }
                  ].map((item, index) => (
                    <div key={index} className={`bg-gradient-to-br ${item.bg} rounded-2xl p-6 text-center space-y-3 border border-${item.color}-200 hover:border-${item.color}-300 transition-all duration-300 hover:shadow-lg hover:scale-105`}>
                      <div className={`bg-${item.color}-100 w-12 h-12 rounded-2xl flex items-center justify-center mx-auto shadow-md`}>
                        <item.icon className={`h-6 w-6 text-${item.color}-600`} />
                      </div>
                      <h4 className="font-bold text-gray-900 text-base">{item.title}</h4>
                      <p className="text-gray-600 text-sm font-medium">{item.desc}</p>
                    </div>
                  ))}
                </div>

                {/* Rating */}
                <div className="bg-gradient-to-br from-yellow-50 via-orange-50 to-yellow-50 rounded-2xl p-6 text-center space-y-3 border-2 border-yellow-300 shadow-lg">
                  <div className="flex items-center justify-center gap-1">
                    {[1,2,3,4,5].map((star) => (
                      <Star key={star} className="h-6 w-6 text-yellow-500 fill-current drop-shadow-sm" />
                    ))}
                  </div>
                  <p className="text-lg font-bold text-gray-800">App Store官方认证</p>
                  <p className="text-base text-gray-600 font-medium">用户信赖的专业应用</p>
                  <div className="flex items-center justify-center gap-2 text-sm text-gray-500">
                    <Globe className="h-4 w-4" />
                    <span>全球可用</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            {isConfigured ? (
              <Button size="lg" className="text-base px-8 py-3" asChild>
                <Link href="/generate">
                  <Sparkles className="mr-2 h-5 w-5" />
                  开始生成图标
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
            ) : (
              <Button size="lg" className="text-base px-8 py-3" asChild>
                <Link href="/config">
                  <Settings className="mr-2 h-5 w-5" />
                  配置API密钥
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
            )}

            <Button variant="outline" size="lg" className="text-base px-8 py-3" asChild>
              <Link href="/docs">
                查看文档
                <ArrowRight className="ml-2 h-5 w-5" />
              </Link>
            </Button>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto mt-16">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl font-bold text-primary">{stat.value}</div>
                <div className="text-sm text-muted-foreground">{stat.label}</div>
              </div>
            ))}
          </div>

          {/* Feature Cards */}
          <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto mt-20">
            {features.map((feature, index) => (
              <Card key={index} className="relative overflow-hidden border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
                <CardContent className="p-6">
                  <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-primary/10 text-primary mb-4 mx-auto">
                    <feature.icon className="h-6 w-6" />
                  </div>
                  <h3 className="text-lg font-semibold mb-2 text-foreground">
                    {feature.title}
                  </h3>
                  <p className="text-muted-foreground text-sm">
                    {feature.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Trust Indicators */}
          <div className="flex flex-wrap justify-center items-center gap-8 mt-16 text-muted-foreground text-sm">
            <div className="flex items-center gap-2">
              <Shield className="h-4 w-4" />
              <span>隐私优先</span>
            </div>
            <div className="flex items-center gap-2">
              <Globe className="h-4 w-4" />
              <span>全球可用</span>
            </div>
            <div className="flex items-center gap-2">
              <Star className="h-4 w-4" />
              <span>开源免费</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}