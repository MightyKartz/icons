'use client'

import { useState, useEffect } from 'react'
import { Sparkles, Download, RefreshCw, Settings, Image as ImageIcon, Loader2 } from 'lucide-react'
import Link from 'next/link'

interface GenerationRequest {
  prompt: string
  style: string
  size: string
  quality: string
  negativePrompt: string
}

interface TaskStatus {
  id: string
  status: string
  result?: any
  error?: string
  createdAt: string
  completedAt?: string
}

export default function GeneratePage() {
  const [isConfigured, setIsConfigured] = useState(false)
  const [request, setRequest] = useState<GenerationRequest>({
    prompt: '',
    style: 'icon',
    size: '1024x1024',
    quality: 'standard',
    negativePrompt: '',
  })
  const [currentTask, setCurrentTask] = useState<TaskStatus | null>(null)
  const [generatedImages, setGeneratedImages] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    checkConfig()
  }, [])

  const checkConfig = async () => {
    try {
      const response = await fetch('/api/config')
      if (response.ok) {
        setIsConfigured(true)
      } else {
        setIsConfigured(false)
      }
    } catch (error) {
      setIsConfigured(false)
    }
  }

  const handleGenerate = async () => {
    if (!request.prompt.trim()) {
      alert('请输入图标描述')
      return
    }

    setLoading(true)
    setCurrentTask(null)

    try {
      // 获取配置信息
      const configResponse = await fetch('/api/config')
      const config = configResponse.ok ? await configResponse.json() : {}

      const requestBody = {
        ...request,
        provider: config.provider || 'openai',
        model: config.model || 'dall-e-3',
        baseUrl: config.baseUrl,
        apiKey: config.apiKey
      }

      const response = await fetch('/api/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      })

      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.detail || '生成失败')
      }

      const taskResponse = await response.json()
      setCurrentTask(taskResponse)

      // 轮询任务状态，支持两种响应格式
      const taskId = taskResponse.task_id || taskResponse.taskId
      pollTaskStatus(taskId)
    } catch (error) {
      alert(`生成失败: ${error instanceof Error ? error.message : '未知错误'}`)
      setLoading(false)
    }
  }

  const pollTaskStatus = async (taskId: string) => {
    const maxAttempts = 180 // 最多轮询180次（约15分钟），ModelScope需要更长时间
    let attempts = 0

    const poll = async () => {
      attempts++

      try {
        const response = await fetch(`/api/task/${taskId}`)
        if (!response.ok) {
          throw new Error('获取任务状态失败')
        }

        const taskStatus = await response.json()
        setCurrentTask(taskStatus)

        // 检查状态字段（支持标准格式和ModelScope格式）
        const status = taskStatus.task_status || taskStatus.status

        if (status === 'completed' || status === 'SUCCEED') {
          setLoading(false)

          // 处理不同格式的响应
          if (taskStatus.output_images && Array.isArray(taskStatus.output_images)) {
            // ModelScope格式
            const images = taskStatus.output_images.map((url: string) => ({ url }))
            setGeneratedImages(prev => [...images, ...prev])
          } else if (taskStatus.image_url) {
            // 简单格式
            setGeneratedImages(prev => [{ url: taskStatus.image_url }, ...prev])
          } else if (taskStatus.result) {
            // 标准格式
            setGeneratedImages(prev => [taskStatus.result, ...prev])
          }
        } else if (status === 'failed' || status === 'FAILED') {
          setLoading(false)
          alert(`生成失败: ${taskStatus.error}`)
        } else if (status === 'pending' || status === 'processing' || status === 'RUNNING') {
          if (attempts < maxAttempts) {
            setTimeout(poll, 5000) // ModelScope建议每5秒轮询一次
          } else {
            setLoading(false)
            alert('生成超时，请重试')
          }
        }
      } catch (error) {
        console.error('轮询任务状态失败:', error)
        if (attempts < maxAttempts) {
          setTimeout(poll, 5000) // 每5秒轮询一次
        } else {
          setLoading(false)
          alert('获取任务状态失败，请重试')
        }
      }
    }

    poll()
  }

  const downloadImage = (imageUrl: string, index: number) => {
    const link = document.createElement('a')
    link.href = imageUrl
    link.download = `icon-${Date.now()}-${index}.png`
    link.click()
  }

  const clearImages = () => {
    setGeneratedImages([])
  }

  if (!isConfigured) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-purple-900 flex items-center justify-center">
        <div className="card p-8 max-w-md mx-4">
          <div className="text-center">
            <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h2 className="text-xl font-bold mb-2 text-gray-900 dark:text-white">
              需要配置API密钥
            </h2>
            <p className="text-gray-600 dark:text-gray-300 mb-6">
              请先配置AI提供商的API密钥才能开始生成图标
            </p>
            <Link href="/config" className="btn btn-primary">
              <Settings className="mr-2 h-4 w-4" />
              配置API密钥
            </Link>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-purple-900">
      {/* 导航栏 */}
      <nav className="sticky top-0 z-50 glass border-b border-white/20 dark:border-gray-700/20">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center space-x-3">
              <Sparkles className="h-6 w-6 text-gray-600 dark:text-gray-300" />
              <span className="text-lg font-semibold text-gray-900 dark:text-white">
                图标生成
              </span>
            </div>

            <div className="flex items-center space-x-4">
              <Link
                href="/config"
                className="btn btn-outline btn-sm"
              >
                <Settings className="mr-2 h-4 w-4" />
                配置
              </Link>
              <Link
                href="/"
                className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                首页
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* 主要内容 */}
      <main className="container mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-8">
          {/* 左侧：输入表单 */}
          <div>
            <div className="card p-6">
              <h2 className="text-xl font-bold mb-6 text-gray-900 dark:text-white">
                创建图标
              </h2>

              {/* 提示词 */}
              <div className="mb-4">
                <label className="label mb-2">图标描述</label>
                <textarea
                  value={request.prompt}
                  onChange={(e) => setRequest(prev => ({ ...prev, prompt: e.target.value }))}
                  placeholder="描述您想要的图标，例如：一个现代简约的相机图标，线条风格，蓝色主题"
                  className="textarea w-full h-24 resize-none"
                />
              </div>

              {/* 风格选择 */}
              <div className="mb-4">
                <label className="label mb-2">风格</label>
                <select
                  value={request.style}
                  onChange={(e) => setRequest(prev => ({ ...prev, style: e.target.value }))}
                  className="select w-full"
                >
                  <option value="icon">图标风格</option>
                  <option value="flat">扁平化</option>
                  <option value="3d">3D效果</option>
                  <option value="minimal">极简</option>
                  <option value="detailed">详细</option>
                </select>
              </div>

              {/* 尺寸选择 */}
              <div className="mb-4">
                <label className="label mb-2">尺寸</label>
                <select
                  value={request.size}
                  onChange={(e) => setRequest(prev => ({ ...prev, size: e.target.value }))}
                  className="select w-full"
                >
                  <option value="512x512">512x512</option>
                  <option value="1024x1024">1024x1024</option>
                </select>
              </div>

              {/* 质量选择 */}
              <div className="mb-4">
                <label className="label mb-2">质量</label>
                <select
                  value={request.quality}
                  onChange={(e) => setRequest(prev => ({ ...prev, quality: e.target.value }))}
                  className="select w-full"
                >
                  <option value="standard">标准</option>
                  <option value="hd">高清</option>
                </select>
              </div>

              {/* 负面提示词 */}
              <div className="mb-6">
                <label className="label mb-2">负面提示词（可选）</label>
                <textarea
                  value={request.negativePrompt}
                  onChange={(e) => setRequest(prev => ({ ...prev, negativePrompt: e.target.value }))}
                  placeholder="描述不想要的元素，例如：文字、复杂的背景、低质量的细节"
                  className="textarea w-full h-16 resize-none"
                />
              </div>

              {/* 生成按钮 */}
              <button
                onClick={handleGenerate}
                disabled={loading || !request.prompt.trim()}
                className="btn btn-primary w-full"
              >
                <Sparkles className="mr-2 h-4 w-4" />
                {loading ? '生成中...' : '生成图标'}
              </button>

              {/* 任务状态 */}
              {currentTask && (
                <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-md">
                  <div className="flex items-center space-x-2">
                    <div className="flex items-center space-x-2">
                      {currentTask.status === 'processing' && (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      )}
                      <span className="text-sm text-gray-600 dark:text-gray-300">
                        任务状态: {
                          (() => {
                            const status = currentTask.status
                            switch (status) {
                              case 'pending': return '等待中'
                              case 'processing': return '处理中'
                              case 'RUNNING': return '运行中'
                              case 'completed': return '已完成'
                              case 'SUCCEED': return '已完成'
                              case 'failed': return '失败'
                              case 'FAILED': return '失败'
                              default: return status || '未知状态'
                            }
                          })()
                        }
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* 右侧：生成结果 */}
          <div>
            <div className="card p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                  生成结果
                </h2>
                {generatedImages.length > 0 && (
                  <button
                    onClick={clearImages}
                    className="btn btn-outline btn-sm"
                  >
                    清空
                  </button>
                )}
              </div>

              {generatedImages.length === 0 ? (
                <div className="text-center py-12">
                  <ImageIcon className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500 dark:text-gray-400">
                    还没有生成的图标
                  </p>
                  <p className="text-sm text-gray-400 dark:text-gray-500 mt-2">
                    输入描述并点击生成按钮开始创建
                  </p>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {generatedImages.map((image, index) => (
                    <div key={index} className="relative group">
                      <div className="aspect-square bg-gray-100 dark:bg-gray-800 rounded-lg overflow-hidden">
                        <img
                          src={image.data?.[0]?.url || image.url}
                          alt={`生成的图标 ${index + 1}`}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition-all duration-200 rounded-lg flex items-center justify-center opacity-0 group-hover:opacity-100">
                        <button
                          onClick={() => downloadImage(image.data?.[0]?.url || image.url, index)}
                          className="btn btn-primary btn-sm"
                        >
                          <Download className="mr-2 h-4 w-4" />
                          下载
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* 使用提示 */}
        <div className="mt-8">
          <div className="card p-6">
            <h3 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
              💡 使用提示
            </h3>
            <div className="grid md:grid-cols-2 gap-6 text-sm text-gray-600 dark:text-gray-300">
              <div>
                <h4 className="font-medium mb-2 text-gray-900 dark:text-white">提示词技巧</h4>
                <ul className="space-y-1 list-disc list-inside">
                  <li>使用简洁明了的描述</li>
                  <li>指定颜色、形状和风格</li>
                  <li>添加"线条风格"、"扁平化"等修饰词</li>
                  <li>参考Apple HIG图标规范</li>
                </ul>
              </div>
              <div>
                <h4 className="font-medium mb-2 text-gray-900 dark:text-white">最佳实践</h4>
                <ul className="space-y-1 list-disc list-inside">
                  <li>图标尺寸建议使用1024x1024</li>
                  <li>使用负面提示词避免不需要的元素</li>
                  <li>多次尝试微调提示词</li>
                  <li>保存喜欢的生成结果</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}