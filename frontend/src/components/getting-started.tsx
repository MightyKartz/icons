'use client'

import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Settings, Type, Download, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

const steps = [
  {
    number: '1',
    icon: Settings,
    title: '配置API密钥',
    description: '选择您喜欢的AI提供商，输入API密钥并测试连接。支持多种主流AI服务。',
    tips: ['选择免费提供商开始', 'API密钥本地加密存储', '支持多个提供商']
  },
  {
    number: '2',
    icon: Type,
    title: '输入生成描述',
    description: '用简单的文字描述您想要的图标样式和内容。越详细描述，生成效果越好。',
    tips: ['描述图标内容和风格', '指定颜色和尺寸', '参考设计风格']
  },
  {
    number: '3',
    icon: Download,
    title: '生成和下载',
    description: '点击生成按钮，等待几秒钟即可获得高质量的图标。支持多种格式下载。',
    tips: ['支持PNG/SVG格式', '批量生成功能', '实时预览效果']
  }
]

export function GettingStarted() {
  return (
    <section className="py-16 bg-muted/30">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center space-y-3 mb-12">
          <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            快速开始
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            简单三步，轻松生成专业图标
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {steps.map((step, index) => (
            <div key={index} className="relative">
              {/* Step Number */}
              <div className="absolute -top-3 -left-3 w-6 h-6 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-xs font-bold z-10">
                {step.number}
              </div>

              {/* Step Card */}
              <Card className="relative h-full border-0 shadow-md hover:shadow-lg transition-all duration-300">
                <CardContent className="p-5 pt-6">
                  {/* Icon */}
                  <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-primary/10 text-primary mb-4">
                    <step.icon className="h-5 w-5" />
                  </div>

                  {/* Content */}
                  <div className="space-y-3">
                    <div>
                      <h3 className="text-base font-semibold text-foreground mb-2">
                        {step.title}
                      </h3>
                      <p className="text-xs text-muted-foreground leading-relaxed">
                        {step.description}
                      </p>
                    </div>

                    {/* Tips */}
                    <div className="space-y-2">
                      <div className="text-xs font-medium text-foreground">小贴士：</div>
                      <ul className="space-y-1">
                        {step.tips.map((tip, tipIndex) => (
                          <li key={tipIndex} className="text-xs text-muted-foreground flex items-start gap-2">
                            <div className="w-1 h-1 rounded-full bg-primary mt-1.5 flex-shrink-0" />
                            {tip}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Arrow Connector */}
              {index < steps.length - 1 && (
                <div className="hidden md:block absolute top-1/2 -right-3 transform -translate-y-1/2 z-20">
                  <ArrowRight className="h-5 w-5 text-muted-foreground" />
                </div>
              )}
            </div>
          ))}
        </div>

        {/* CTA Section - 优化间距 */}
        <div className="text-center mt-12 space-y-3">
          <p className="text-sm text-muted-foreground">
            准备好开始创建您的第一个AI图标了吗？
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Button size="lg" className="px-6 py-2.5 text-base font-medium" asChild>
              <Link href="/config">
                <Settings className="mr-2 h-4 w-4" />
                立即开始
              </Link>
            </Button>
            <Button variant="outline" size="lg" className="px-6 py-2.5 text-base font-medium" asChild>
              <Link href="/docs">
                查看详细文档
              </Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}