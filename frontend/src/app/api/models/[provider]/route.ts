import { NextRequest, NextResponse } from 'next/server'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8787'

export async function GET(
  request: NextRequest,
  { params }: { params: { provider: string } }
) {
  try {
    const { provider } = params

    // 自定义提供商返回预定义的模型列表
    if (provider === 'custom') {
      return NextResponse.json({
        models: [
          "gpt-4o",
          "gpt-4",
          "gpt-3.5-turbo",
          "claude-3-opus",
          "claude-3-sonnet",
          "stable-diffusion-xl",
          "stable-diffusion-3",
          "dall-e-3",
          "dall-e-2",
          "Qwen/Qwen-Image",
          "AI-ModelScope/stable-diffusion-v1-5",
          "AI-ModelScope/stable-diffusion-xl-base-1.0",
          "AI-ModelScope/flux-schnell",
          "AI-ModelScope/flux-dev",
          "qwen-vl-plus",
          "qwen-vl-max",
          "wanx-v1"
        ]
      })
    }

    const response = await fetch(`${API_BASE_URL}/v1/models/${provider}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      return NextResponse.json(
        { error: '获取模型列表失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('获取模型列表时出错:', error)
    return NextResponse.json(
      { error: '服务器错误' },
      { status: 500 }
    )
  }
}