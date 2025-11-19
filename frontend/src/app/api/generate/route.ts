import { NextRequest, NextResponse } from 'next/server'
import { demoStore } from '@/lib/demo-store'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8787'
const IS_DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === 'true'

export async function POST(request: NextRequest) {
  const body = await request.json()

  // 演示模式
  if (IS_DEMO_MODE) {
    const { prompt, provider, model, size = '1024x1024', baseUrl, apiKey } = body

    // 检测是否为ModelScope
    const isModelScope = baseUrl && baseUrl.includes('modelscope.cn')

    // 创建任务
    const task = demoStore.createTask({
      prompt,
      provider,
      model,
      status: 'processing'
    })

    // 模拟异步处理，ModelScope需要更长时间
    const delay = isModelScope ?
      8000 + Math.random() * 7000 : // ModelScope: 8-15秒
      2000 + Math.random() * 3000  // 其他: 2-5秒

    setTimeout(async () => {
      // 使用随机图片作为演示结果
      const imageUrl = `https://picsum.photos/seed/${encodeURIComponent(prompt)}/1024/1024.jpg`

      if (isModelScope) {
        // ModelScope格式：模拟异步任务完成
        demoStore.updateTask(task.id, {
          status: 'SUCCEED', // ModelScope使用SUCCEED状态
          imageUrl,
          completedAt: new Date().toISOString(),
          output_images: [imageUrl] // ModelScope格式
        })
      } else {
        // 标准格式
        demoStore.updateTask(task.id, {
          status: 'completed',
          imageUrl,
          completedAt: new Date().toISOString()
        })
      }
    }, delay)

    // 返回符合ModelScope格式的响应
    if (isModelScope) {
      return NextResponse.json({
        task_id: task.id,
        message: '图像生成任务已创建（ModelScope演示模式）'
      })
    }

    return NextResponse.json({
      success: true,
      task_id: task.id,
      message: '图像生成任务已创建（演示模式）'
    })
  }

  // 正常模式调用后端API
  try {
    const response = await fetch(`${API_BASE_URL}/v1/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      return NextResponse.json(
        { error: errorData.detail || '创建生成任务失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('创建生成任务时出错:', error)
    return NextResponse.json(
      { error: '服务器错误' },
      { status: 500 }
    )
  }
}