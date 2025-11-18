import './globals.css'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Icons - 免费AI图标生成工具',
  description: '多平台AI图标生成工具，支持OpenAI、Anthropic、ModelScope等多种AI提供商',
  keywords: 'AI图标生成,图标设计,OpenAI,Anthropic,ModelScope,免费工具',
  authors: [{ name: 'MightyKartz' }],
  creator: 'MightyKartz',
  publisher: 'Icons',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://icons-demo.vercel.app'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'Icons - 免费AI图标生成工具',
    description: '多平台AI图标生成工具，支持多种AI提供商',
    url: 'https://icons-demo.vercel.app',
    siteName: 'Icons',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Icons AI图标生成工具',
      },
    ],
    locale: 'zh_CN',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Icons - 免费AI图标生成工具',
    description: '多平台AI图标生成工具，支持多种AI提供商',
    images: ['/og-image.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  viewport: {
    width: 'device-width',
    initialScale: 1,
    maximumScale: 1,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <body className={inter.className}>
        <div className="min-h-screen bg-background text-foreground">
          {children}
        </div>
      </body>
    </html>
  )
}