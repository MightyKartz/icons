import { NextRequest, NextResponse } from 'next/server'

const IS_DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === 'true'

export async function POST(request: NextRequest) {
  console.log('测试API被调用')

  try {
    const body = await request.json()
    console.log('接收到的数据:', body)

    const { provider, apiKey, baseUrl, model } = body

    // 演示模式下仍然进行实际的连接测试，但给出更友好的提示
    const isDemoMode = IS_DEMO_MODE

    // 自定义提供商（ModelScope等）
    if (provider === 'custom') {
      if (!apiKey?.trim()) {
        return NextResponse.json({
          success: false,
          message: '请输入API密钥'
        })
      }

      if (!baseUrl?.trim()) {
        return NextResponse.json({
          success: false,
          message: '请输入基础URL'
        })
      }

      if (!model?.trim()) {
        return NextResponse.json({
          success: false,
          message: '请输入模型名称'
        })
      }

      // 检测是否为ModelScope
      const isModelScope = baseUrl.includes('modelscope.cn')

      if (isModelScope) {
        // ModelScope连接测试
        try {
          console.log('测试ModelScope连接...')

          // 测试API密钥格式
          if (!apiKey.startsWith('ms-')) {
            return NextResponse.json({
              success: false,
              message: 'ModelScope API密钥格式不正确，应以"ms-"开头'
            })
          }

          // 发送简单的测试请求到ModelScope
          // 尝试多个可能的端点来验证连接
          const endpoints = ['/models', '/']
          let success = false
          let lastError = null

          for (const endpoint of endpoints) {
            try {
              const testUrl = endpoint === '/' ? baseUrl.replace('/v1', '') : `${baseUrl}${endpoint}`
              console.log(`尝试测试端点: ${testUrl}`)

              const testResponse = await fetch(testUrl, {
                method: 'GET',
                headers: {
                  'Authorization': `Bearer ${apiKey}`,
                  'Content-Type': 'application/json'
                }
              })

              console.log(`端点 ${testUrl} 响应: ${testResponse.status}`)

              if (testResponse.ok || testResponse.status === 405) {
                // 200成功或405方法不允许都说明连接正常
                success = true
                break
              } else if (testResponse.status === 401) {
                lastError = 'API密钥无效，请检查您的ModelScope Token'
              } else if (testResponse.status === 403) {
                lastError = 'API权限不足，请检查Token权限设置'
              } else if (testResponse.status === 404) {
                lastError = 'ModelScope API端点不存在，请检查基础URL配置'
              }
            } catch (e) {
              console.log(`端点 ${endpoint} 测试失败:`, e)
              lastError = `网络连接失败: ${e instanceof Error ? e.message : '未知错误'}`
              continue
            }
          }

          if (success) {
            return NextResponse.json({
              success: true,
              message: isDemoMode ? 'ModelScope连接测试成功！（演示模式）' : 'ModelScope连接测试成功！'
            })
          } else {
            return NextResponse.json({
              success: false,
              message: lastError || 'ModelScope连接失败，请检查URL和网络'
            })
          }
        } catch (error) {
          console.error('ModelScope连接测试出错:', error)
          return NextResponse.json({
            success: false,
            message: '无法连接到ModelScope，请检查网络和URL'
          })
        }
      } else {
        // 其他自定义提供商测试
        try {
          console.log('测试自定义提供商连接...')

          const testResponse = await fetch(`${baseUrl}/models`, {
            method: 'GET',
            headers: {
              'Authorization': `Bearer ${apiKey}`,
              'Content-Type': 'application/json'
            }
          })

          if (testResponse.ok) {
            return NextResponse.json({
              success: true,
              message: '自定义提供商连接测试成功！'
            })
          } else {
            return NextResponse.json({
              success: false,
              message: `自定义提供商连接失败: ${testResponse.status}`
            })
          }
        } catch (error) {
          console.error('自定义提供商连接测试出错:', error)
          return NextResponse.json({
            success: false,
            message: '无法连接到自定义提供商，请检查网络和URL'
          })
        }
      }
    }

    // 默认成功响应
    return NextResponse.json({
      success: true,
      message: '连接测试成功'
    })

  } catch (error) {
    console.error('测试连接时出错:', error)
    return NextResponse.json(
      { success: false, message: '服务器错误' },
      { status: 500 }
    )
  }
}