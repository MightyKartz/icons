'use client'

import Link from 'next/link'
import { Sparkles, Github, Mail, Heart } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'

const footerLinks = {
  product: [
    { name: '首页', href: '/' },
    { name: '生成', href: '/generate' },
    { name: '配置', href: '/config' },
    { name: '文档', href: '/docs' }
  ],
  resources: [
    { name: 'API文档', href: '/docs/api' },
    { name: '使用指南', href: '/docs/guide' },
    { name: '示例', href: '/docs/examples' },
    { name: '更新日志', href: '/docs/changelog' }
  ],
  company: [
    { name: '关于我们', href: '/about' },
    { name: 'GitHub', href: 'https://github.com/MightyKartz/icons' },
    { name: '隐私政策', href: '/privacy' },
    { name: '使用条款', href: '/terms' }
  ]
}

export function Footer() {
  return (
    <footer className="border-t border-border/40 bg-background">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* Main Footer Content */}
        <div className="py-12">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8">
            {/* Brand */}
            <div className="lg:col-span-2">
              <div className="flex items-center space-x-3 mb-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                  <Sparkles className="h-6 w-6" />
                </div>
                <span className="text-xl font-bold text-foreground">
                  XIconAI
                </span>
              </div>

              <p className="text-muted-foreground mb-6 max-w-sm">
                免费开源的AI图标生成工具，支持多种AI提供商，保护您的隐私安全。
              </p>

              <div className="flex space-x-4">
                <Button variant="ghost" size="icon" asChild>
                  <Link href="https://github.com/MightyKartz/icons" target="_blank" rel="noopener noreferrer">
                    <Github className="h-4 w-4" />
                  </Link>
                </Button>
                <Button variant="ghost" size="icon" asChild>
                  <Link href="mailto:support@xiconai.com">
                    <Mail className="h-4 w-4" />
                  </Link>
                </Button>
              </div>
            </div>

            {/* Links */}
            <div>
              <h3 className="text-sm font-semibold text-foreground mb-4">产品</h3>
              <ul className="space-y-3">
                {footerLinks.product.map((link) => (
                  <li key={link.name}>
                    <Link
                      href={link.href}
                      className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-foreground mb-4">资源</h3>
              <ul className="space-y-3">
                {footerLinks.resources.map((link) => (
                  <li key={link.name}>
                    <Link
                      href={link.href}
                      className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-foreground mb-4">公司</h3>
              <ul className="space-y-3">
                {footerLinks.company.map((link) => (
                  <li key={link.name}>
                    <Link
                      href={link.href}
                      className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        <Separator />

        {/* Bottom Footer */}
        <div className="py-6">
          <div className="flex flex-col sm:flex-row justify-between items-center space-y-4 sm:space-y-0">
            <div className="text-sm text-muted-foreground">
              © 2024 XIconAI. 基于 MIT 许可证开源。
            </div>

            <div className="flex items-center space-x-1 text-sm text-muted-foreground">
              <span>Made with</span>
              <Heart className="h-4 w-4 text-red-500 fill-current" />
              <span>by the XIconAI team</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}