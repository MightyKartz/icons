import { NextRequest, NextResponse } from 'next/server'
import { demoStore } from '@/lib/demo-store'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8787'
const IS_DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === 'true'

export async function GET(request: NextRequest) {
  if (IS_DEMO_MODE) {
    // 演示模式下，从demoStore获取配置
    const config = demoStore.getConfig()

    if (config) {
      return NextResponse.json({
        ...config,
        apiKey: '' // 不返回实际的API密钥
      })
    }

    // 返回默认的演示配置
    return NextResponse.json({
      provider: 'openai',
      model: 'dall-e-3',
      apiKey: 'demo-key',
      configured: true
    })
  }

  try {
    const response = await fetch(`${API_BASE_URL}/v1/config`, {
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      return NextResponse.json(
        { error: '获取配置失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('获取配置时出错:', error)
    return NextResponse.json(
      { error: '服务器错误' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  const body = await request.json()

  // 演示模式保存到demoStore
  if (IS_DEMO_MODE) {
    demoStore.saveConfig(body)
    return NextResponse.json({ success: true })
  }

  try {
    const response = await fetch(`${API_BASE_URL}/v1/config`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      return NextResponse.json(
        { error: errorData.detail || '保存配置失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('保存配置时出错:', error)
    return NextResponse.json(
      { error: '服务器错误' },
      { status: 500 }
    )
  }
}

export async function DELETE(request: NextRequest) {
  // 演示模式清除demoStore中的配置
  if (IS_DEMO_MODE) {
    demoStore.clearConfig()
    return NextResponse.json({ success: true })
  }

  try {
    const response = await fetch(`${API_BASE_URL}/v1/config`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      return NextResponse.json(
        { error: errorData.detail || '删除配置失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('删除配置时出错:', error)
    return NextResponse.json(
      { error: '服务器错误' },
      { status: 500 }
    )
  }
}