'use client'
// Version: 2.0.1 - shadcn/ui UI Enhancement - 2025-11-18
// Modern UI with shadcn/ui components

import { NavigationHeader } from '@/components/navigation-header'
import { HeroSection } from '@/components/hero-section'
import { AIProviders } from '@/components/ai-providers'
import { GettingStarted } from '@/components/getting-started'
import { Footer } from '@/components/footer'
import ErrorBoundary from '@/components/error-boundary'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-background">
      <NavigationHeader />
      <main>
        <ErrorBoundary>
          <HeroSection />
        </ErrorBoundary>
        <ErrorBoundary>
          <AIProviders />
        </ErrorBoundary>
        <ErrorBoundary>
          <GettingStarted />
        </ErrorBoundary>
      </main>
      <Footer />
    </div>
  )
}