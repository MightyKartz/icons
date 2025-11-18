'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Sparkles, Settings, ArrowRight, Zap, Shield, Globe, Star } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

export function HeroSection() {
  const [isConfigured, setIsConfigured] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [error, setError] = useState(false)

  useEffect(() => {
    setMounted(true)
    const checkConfig = async () => {
      try {
        const response = await fetch('/api/config')
        const data = await response.json()
        if (response.ok && (!data.error)) {
          setIsConfigured(true)
        }
      } catch (err) {
        console.error('配置检查失败:', err)
        // 在生产环境中即使API调用失败也继续渲染，不中断页面
        setError(true)
        setIsConfigured(false)
      }
    }
    // 防止在服务端渲染时执行API调用
    if (typeof window !== 'undefined') {
      checkConfig()
    }
  }, [])

  const features = [
    {
      icon: Zap,
      title: "多AI提供商",
      description: "支持OpenAI、Anthropic、ModelScope、Stability AI等主流AI服务"
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
    { label: "AI提供商", value: "4+" },
    { label: "图标样式", value: "∞" },
    { label: "用户数量", value: "1000+" },
    { label: "开源协议", value: "MIT" }
  ]

  // 即使未挂载也返回默认内容，避免页面空白
  if (!mounted && typeof window !== 'undefined') {
    return (
      <section className="relative overflow-hidden py-20 sm:py-32">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-blue-950/20 dark:via-background dark:to-purple-950/20" />
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="text-center space-y-8">
            <div className="flex justify-center">
              <div className="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80 animate-pulse">
                <Sparkles className="mr-2 h-3 w-3" />
                全新 v2.0.1 版本
              </div>
            </div>
            <div className="space-y-4">
              <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-6xl lg:text-7xl">
                AI图标生成
                <span className="block text-primary bg-gradient-to-r from-primary to-purple-600 bg-clip-text text-transparent">创意工具</span>
              </h1>
              <p className="mx-auto max-w-2xl text-xl text-muted-foreground sm:text-2xl">
                支持多种AI提供商，完全免费开源，数据本地存储，保护您的隐私。
                一键生成高质量图标，让创意变为现实。
              </p>
            </div>
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <button className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-11 px-8 py-3 text-base">
                <Settings className="mr-2 h-5 w-5" />
                配置API密钥
                <ArrowRight className="ml-2 h-5 w-5" />
              </button>
              <button className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-11 px-8 py-3 text-base">
                查看文档
                <ArrowRight className="ml-2 h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </section>
    )
  }

  return (
    <section className="relative overflow-hidden py-20 sm:py-32">
      {/* Background Gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-blue-950/20 dark:via-background dark:to-purple-950/20" />

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