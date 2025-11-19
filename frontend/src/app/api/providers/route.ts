import { NextRequest, NextResponse } from 'next/server'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8787'
const IS_DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === 'true'

// 演示模式的模拟数据
const mockProviders = [
  {
    id: "openai",
    name: "OpenAI",
    models: ["dall-e-3", "dall-e-2"],
    description: "高质量的AI图像生成",
    pricing: "付费"
  },
  {
    id: "anthropic",
    name: "Anthropic",
    models: ["claude-3-opus-20240229", "claude-3-sonnet-20240229"],
    description: "强大的多模态AI",
    pricing: "付费"
  },
  {
    id: "stability",
    name: "Stability AI",
    models: ["stable-diffusion-xl", "stable-diffusion-3"],
    description: "开源图像生成模型",
    pricing: "付费"
  },
  {
    id: "custom",
    name: "自定义",
    models: ["gpt-4o", "gpt-4", "qwen-vl-plus", "wanx-v1", "flux-schnell"],
    description: "支持OpenAI、ModelScope等兼容格式的API服务",
    pricing: "自定义"
  }
]

export async function GET(request: NextRequest) {
  // 演示模式直接返回模拟数据
  if (IS_DEMO_MODE) {
    return NextResponse.json({ providers: mockProviders })
  }

  try {
    const response = await fetch(`${API_BASE_URL}/v1/providers`, {
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      return NextResponse.json(
        { error: '获取提供商列表失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('获取提供商列表时出错:', error)
    // 如果后端不可用，返回演示数据
    console.log('后端不可用，使用演示数据')
    return NextResponse.json({ providers: mockProviders })
  }
}