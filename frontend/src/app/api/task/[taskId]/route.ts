import { NextRequest, NextResponse } from 'next/server'
import { demoStore } from '@/lib/demo-store'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8787'
const IS_DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === 'true'

export async function GET(
  request: NextRequest,
  { params }: { params: { taskId: string } }
) {
  try {
    const { taskId } = params

    // 演示模式
    if (IS_DEMO_MODE) {
      const task = demoStore.getTask(taskId)

      if (!task) {
        return NextResponse.json(
          { error: '任务未找到' },
          { status: 404 }
        )
      }

      // 检测是否为ModelScope任务
      const isModelScope = task.provider === 'custom' &&
        (task.model?.includes('Qwen/') || task.model?.includes('AI-ModelScope/'))

      if (isModelScope) {
        // ModelScope格式响应
        return NextResponse.json({
          task_id: task.id,
          task_status: task.status, // ModelScope使用task_status
          output_images: task.output_images || (task.imageUrl ? [task.imageUrl] : []),
          error: task.error,
          created_at: task.createdAt,
          completed_at: task.completedAt,
          prompt: task.prompt,
          model: task.model
        })
      } else {
        // 标准格式响应
        return NextResponse.json({
          task_id: task.id,
          status: task.status,
          image_url: task.imageUrl,
          error: task.error,
          created_at: task.createdAt,
          completed_at: task.completedAt,
          prompt: task.prompt,
          provider: task.provider,
          model: task.model
        })
      }
    }

    const response = await fetch(`${API_BASE_URL}/v1/task/${taskId}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      return NextResponse.json(
        { error: errorData.detail || '获取任务状态失败' },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('获取任务状态时出错:', error)
    return NextResponse.json(
      { error: '服务器错误' },
      { status: 500 }
    )
  }
}