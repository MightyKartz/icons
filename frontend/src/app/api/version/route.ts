import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    version: "2.0.1",
    buildTime: "2025-11-18T03:25:00Z",
    commit: "03455ee",
    mode: "demo",
    features: {
      demoMode: true,
      fullAPI: true,
      aiGeneration: true
    },
    message: "XIconAI 完整演示模式 - 已修复显示问题",
    timestamp: new Date().toISOString()
  })
}