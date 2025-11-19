'use client'

import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Check, Star, Zap } from 'lucide-react'

const providers = [
  {
    name: 'OpenAI',
    model: 'DALL-E 3',
    description: '业界领先的图像生成模型',
    badge: '推荐',
    badgeVariant: 'default' as const,
    features: ['高质量', '多风格', '快速生成']
  },
  {
    name: 'Anthropic',
    model: 'Claude 3',
    description: '先进的AI助手图像生成',
    badge: '智能',
    badgeVariant: 'secondary' as const,
    features: ['理解力强', '细节丰富', '创意独特']
  },
  {
    name: 'Stability AI',
    model: 'Stable Diffusion',
    description: '开源的图像生成模型',
    badge: '开源',
    badgeVariant: 'secondary' as const,
    features: ['可定制', '社区支持', '风格多样']
  },
  {
    name: '自定义',
    model: '自定义API',
    description: '支持OpenAI、ModelScope等兼容格式的API服务',
    badge: '自定义',
    badgeVariant: 'outline' as const,
    features: ['灵活配置', '兼容性强', '支持ModelScope']
  }
]

export function AIProviders() {
  return (
    <section className="py-16 bg-background">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center space-y-3 mb-12">
          <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            支持的AI提供商
          </h2>
          <p className="mx-auto max-w-2xl text-lg text-muted-foreground">
            选择您喜欢的AI服务，我们支持主流的AI图像生成提供商
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {providers.map((provider, index) => (
            <Card
              key={index}
              className="relative overflow-hidden border-0 shadow-md hover:shadow-lg transition-all duration-300 hover:-translate-y-1 group"
            >
              <CardContent className="p-5">
                {/* Badge */}
                <div className="absolute top-3 right-3">
                  <Badge variant={provider.badgeVariant} className="text-xs px-2 py-0.5">
                    {provider.badge}
                  </Badge>
                </div>

                {/* Provider Info */}
                <div className="space-y-3">
                  <div>
                    <h3 className="text-base font-semibold text-foreground mb-1">
                      {provider.name}
                    </h3>
                    <p className="text-xs text-muted-foreground font-medium">
                      {provider.model}
                    </p>
                  </div>

                  <p className="text-xs text-muted-foreground leading-relaxed">
                    {provider.description}
                  </p>

                  {/* Features */}
                  <div className="space-y-1.5">
                    {provider.features.map((feature, featureIndex) => (
                      <div key={featureIndex} className="flex items-center gap-2">
                        <Check className="h-3 w-3 text-green-500" />
                        <span className="text-xs text-muted-foreground">{feature}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </CardContent>

              {/* Hover Effect */}
              <div className="absolute inset-0 bg-gradient-to-r from-primary/5 to-purple-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            </Card>
          ))}
        </div>

        {/* CTA Section - 优化间距 */}
        <div className="text-center mt-12">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-primary/10 rounded-full">
            <Zap className="h-3.5 w-3.5 text-primary" />
            <span className="text-xs font-medium text-primary">
              更多AI提供商正在开发中
            </span>
          </div>
        </div>
      </div>
    </section>
  )
}