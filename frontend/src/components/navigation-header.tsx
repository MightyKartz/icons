'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Sparkles, Settings, Menu, X, Github, ExternalLink, Apple, Download } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

export function NavigationHeader() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  const navigation = [
    { name: '首页', href: '/' },
    { name: '文档', href: '/docs' },
    { name: '配置', href: '/config' },
    { name: '生成', href: '/generate' }
  ]

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-16 max-w-screen-2xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Logo */}
        <div className="flex items-center space-x-3">
          <Link href="/" className="flex items-center space-x-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-primary-foreground">
              <Sparkles className="h-6 w-6" />
            </div>
            <div className="flex flex-col">
              <span className="text-xl font-bold text-foreground">
                XIconAI
              </span>
              <Badge variant="secondary" className="w-fit text-xs">
                v2.0.1
              </Badge>
            </div>
          </Link>
        </div>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center space-x-6">
          {navigation.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
            >
              {item.name}
            </Link>
          ))}
        </nav>

        {/* Actions */}
        <div className="flex items-center space-x-4">
          <Link href="https://github.com/MightyKartz/icons" target="_blank" rel="noopener noreferrer">
            <Button variant="ghost" size="icon">
              <Github className="h-4 w-4" />
            </Button>
          </Link>

          <Button
            variant="default"
            size="sm"
            className="bg-black hover:bg-gray-800 text-white hidden sm:flex"
            asChild
          >
            <a
              href="https://apps.apple.com/cn/app/xiconai-studio/id6754810915?mt=12"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center"
            >
              <Apple className="mr-2 h-4 w-4" />
              <span className="hidden lg:inline">App Store</span>
              <span className="lg:hidden">下载</span>
            </a>
          </Button>

          <Button variant="outline" size="sm" asChild>
            <Link href="/config">
              <Settings className="mr-2 h-4 w-4" />
              配置
            </Link>
          </Button>

          {/* Mobile Menu Button */}
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          >
            {isMobileMenuOpen ? (
              <X className="h-4 w-4" />
            ) : (
              <Menu className="h-4 w-4" />
            )}
          </Button>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMobileMenuOpen && (
        <div className="border-t border-border/40 bg-background md:hidden">
          <nav className="container mx-auto px-4 py-4 sm:px-6 lg:px-8">
            <div className="space-y-3">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className="block text-sm font-medium text-muted-foreground transition-colors hover:text-foreground py-2"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  {item.name}
                </Link>
              ))}

              {/* App Store Download Link */}
              <a
                href="https://apps.apple.com/cn/app/xiconai-studio/id6754810915?mt=12"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center text-sm font-medium text-black hover:text-gray-700 py-2 transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <Apple className="mr-2 h-4 w-4" />
                App Store 下载
                <ExternalLink className="ml-1 h-3 w-3" />
              </a>
            </div>
          </nav>
        </div>
      )}
    </header>
  )
}