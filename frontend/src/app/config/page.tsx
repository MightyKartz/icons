'use client'

import { useState, useEffect } from 'react'
import { Settings, Check, X, Eye, EyeOff, TestTube, Save, Trash2 } from 'lucide-react'

interface APIConfig {
  provider: string
  apiKey: string
  model: string
  baseUrl?: string
  maxTokens?: number
  temperature?: number
}

interface Provider {
  id: string
  name: string
  models: string[]
  description: string
  pricing: string
  baseUrl?: string
}

export default function ConfigPage() {
  const [config, setConfig] = useState<APIConfig>({
    provider: 'openai',
    apiKey: '',
    model: 'dall-e-3',
    baseUrl: '',
    maxTokens: 1000,
    temperature: 0.7,
  })

  const [savedConfig, setSavedConfig] = useState<APIConfig | null>(null)
  const [testing, setTesting] = useState(false)
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null)
  const [saving, setSaving] = useState(false)
  const [showApiKey, setShowApiKey] = useState(false)
  const [providers, setProviders] = useState<Provider[]>([])

  useEffect(() => {
    // 加载支持的提供商
    fetchProviders()
    // 加载已保存的配置
    loadSavedConfig()
  }, [])

  const fetchProviders = async () => {
    try {
      const response = await fetch('/api/providers')
      if (response.ok) {
        const data = await response.json()
        setProviders(data.providers)
      }
    } catch (error) {
      console.error('获取提供商列表失败:', error)
    }
  }

  const loadSavedConfig = async () => {
    try {
      const response = await fetch('/api/config')
      if (response.ok) {
        const data = await response.json()
        setSavedConfig(data)
        setConfig({
          ...data,
          apiKey: '', // 不显示已保存的API密钥
        })
      }
    } catch (error) {
      console.log('未找到已保存的配置')
    }
  }

  const handleProviderChange = (provider: string) => {
    const selectedProvider = providers.find(p => p.id === provider)
    if (selectedProvider) {
      setConfig(prev => ({
        ...prev,
        provider,
        model: provider === 'custom' ? '' : (selectedProvider.models[0] || ''),
        baseUrl: selectedProvider.baseUrl || '',
      }))
      setTestResult(null)
    }
  }

  const handleModelChange = async (provider: string) => {
    try {
      const response = await fetch(`/api/models/${provider}`)
      if (response.ok) {
        const data = await response.json()
        if (data.models.length > 0) {
          setConfig(prev => ({
            ...prev,
            model: data.models[0],
          }))
        }
      }
    } catch (error) {
      console.error('获取模型列表失败:', error)
    }
  }

  const testConnection = async () => {
    if (!config.apiKey.trim()) {
      setTestResult({ success: false, message: '请输入API密钥' })
      return
    }

    if (config.provider === 'custom' && !config.baseUrl?.trim()) {
      setTestResult({ success: false, message: '自定义提供商需要填写基础URL' })
      return
    }

    if (config.provider === 'custom' && !config.model?.trim()) {
      setTestResult({ success: false, message: '自定义提供商需要填写模型名称' })
      return
    }

    setTesting(true)
    setTestResult(null)

    try {
      const response = await fetch('/api/config/test', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      })

      const result = await response.json()
      setTestResult(result)
    } catch (error) {
      setTestResult({ success: false, message: '连接测试失败' })
    } finally {
      setTesting(false)
    }
  }

  const saveConfig = async () => {
    if (!config.apiKey.trim()) {
      alert('请输入API密钥')
      return
    }

    if (config.provider === 'custom' && !config.baseUrl?.trim()) {
      alert('自定义提供商需要填写基础URL')
      return
    }

    if (config.provider === 'custom' && !config.model?.trim()) {
      alert('自定义提供商需要填写模型名称')
      return
    }

    setSaving(true)

    try {
      const response = await fetch('/api/config', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      })

      const result = await response.json()
      if (result.success) {
        setSavedConfig(config)
        alert('配置保存成功！')
      } else {
        alert('配置保存失败')
      }
    } catch (error) {
      alert('配置保存失败')
    } finally {
      setSaving(false)
    }
  }

  const deleteConfig = async () => {
    if (!confirm('确定要删除已保存的配置吗？')) {
      return
    }

    try {
      const response = await fetch('/api/config', {
        method: 'DELETE',
      })

      const result = await response.json()
      if (result.success) {
        setSavedConfig(null)
        setConfig(prev => ({ ...prev, apiKey: '' }))
        setTestResult(null)
        alert('配置删除成功')
      }
    } catch (error) {
      alert('配置删除失败')
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-purple-900">
      {/* 导航栏 */}
      <nav className="sticky top-0 z-50 glass border-b border-white/20 dark:border-gray-700/20">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center space-x-3">
              <Settings className="h-6 w-6 text-gray-600 dark:text-gray-300" />
              <span className="text-lg font-semibold text-gray-900 dark:text-white">
                API配置
              </span>
            </div>

            <div className="flex items-center space-x-4">
              <a
                href="/"
                className="text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors"
              >
                返回首页
              </a>
            </div>
          </div>
        </div>
      </nav>

      {/* 主要内容 */}
      <main className="container mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="max-w-2xl mx-auto">
          <div className="card p-6 mb-6">
            <h2 className="text-2xl font-bold mb-6 text-gray-900 dark:text-white">
              配置AI提供商
            </h2>

            {/* 提供商选择 */}
            <div className="mb-6">
              <label className="label mb-2">AI提供商</label>
              <select
                value={config.provider}
                onChange={(e) => handleProviderChange(e.target.value)}
                className="select w-full"
              >
                {providers.map((provider) => (
                  <option key={provider.id} value={provider.id}>
                    {provider.name} - {provider.pricing}
                  </option>
                ))}
              </select>
            </div>

            {/* API密钥 */}
            <div className="mb-6">
              <label className="label mb-2">API密钥</label>
              <form onSubmit={(e) => { e.preventDefault(); testConnection(); }}>
                <div className="relative">
                  <input
                    type={showApiKey ? 'text' : 'password'}
                    value={config.apiKey}
                    onChange={(e) => setConfig(prev => ({ ...prev, apiKey: e.target.value }))}
                    placeholder="输入您的API密钥"
                    className="input pr-10 w-full"
                  />
                  <button
                    type="button"
                    onClick={() => setShowApiKey(!showApiKey)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                  >
                    {showApiKey ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </form>
            </div>

            {/* 模型选择 */}
            <div className="mb-6">
              <label className="label mb-2">
                模型
                {config.provider === 'custom' && <span className="text-red-500 ml-1">*</span>}
              </label>
              {config.provider === 'custom' ? (
                <div>
                  <input
                    type="text"
                    value={config.model}
                    onChange={(e) => setConfig(prev => ({ ...prev, model: e.target.value }))}
                    placeholder="输入模型ID，如：Qwen/Qwen-Image, AI-ModelScope/flux-schnell"
                    className={`input w-full ${
                      !config.model?.trim() ? 'border-red-300 focus:border-red-500' : ''
                    }`}
                    required
                  />
                  <div className="mt-2">
                    <p className="text-xs text-gray-500 mb-1">常用模型示例：</p>
                    <div className="flex flex-wrap gap-1">
                      {['Qwen/Qwen-Image', 'AI-ModelScope/flux-schnell', 'AI-ModelScope/stable-diffusion-v1-5', 'gpt-4', 'dall-e-3'].map((model) => (
                        <button
                          key={model}
                          type="button"
                          onClick={() => setConfig(prev => ({ ...prev, model }))}
                          className="text-xs px-2 py-1 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 rounded transition-colors"
                        >
                          {model}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <select
                  value={config.model}
                  onChange={(e) => setConfig(prev => ({ ...prev, model: e.target.value }))}
                  className="select w-full"
                >
                  {providers
                    .find(p => p.id === config.provider)
                    ?.models.map((model) => (
                      <option key={model} value={model}>
                        {model}
                      </option>
                    )) || []}
                </select>
              )}
              {config.provider === 'custom' && (
                <p className="text-xs text-gray-500 mt-1">
                  自定义提供商需要手动指定模型名称
                </p>
              )}
            </div>

            {/* 高级配置 */}
            <div className="mb-6">
              <h3 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
                高级配置
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* 自定义基础URL */}
                <div>
                  <label className="label mb-2">
                    自定义基础URL
                    {config.provider === 'custom' && <span className="text-red-500 ml-1">*</span>}
                  </label>
                  <input
                    type="url"
                    value={config.baseUrl || ''}
                    onChange={(e) => setConfig(prev => ({ ...prev, baseUrl: e.target.value }))}
                    placeholder={
                      config.provider === 'custom'
                        ? "https://api-inference.modelscope.cn/v1"
                        : "留空使用默认URL"
                    }
                    className={`input w-full ${
                      config.provider === 'custom' && !config.baseUrl?.trim()
                        ? 'border-red-300 focus:border-red-500'
                        : ''
                    }`}
                    required={config.provider === 'custom'}
                  />
                  {config.provider === 'custom' && (
                    <p className="text-xs text-gray-500 mt-1">
                      ModelScope: https://api-inference.modelscope.cn/v1
                    </p>
                  )}
                </div>

                {/* 最大Token数 */}
                <div>
                  <label className="label mb-2">最大Token数</label>
                  <input
                    type="number"
                    value={config.maxTokens}
                    onChange={(e) => setConfig(prev => ({ ...prev, maxTokens: parseInt(e.target.value) || 1000 }))}
                    min="1"
                    max="8000"
                    className="input w-full"
                  />
                </div>

                {/* 温度 */}
                <div>
                  <label className="label mb-2">温度 (0-2)</label>
                  <input
                    type="number"
                    value={config.temperature}
                    onChange={(e) => setConfig(prev => ({ ...prev, temperature: parseFloat(e.target.value) || 0.7 }))}
                    min="0"
                    max="2"
                    step="0.1"
                    className="input w-full"
                  />
                </div>
              </div>
            </div>

            {/* 测试连接 */}
            <div className="mb-6">
              <button
                onClick={testConnection}
                disabled={testing || !config.apiKey.trim()}
                className="btn btn-outline w-full"
              >
                <TestTube className="mr-2 h-4 w-4" />
                {testing ? '测试中...' : '测试连接'}
              </button>

              {testResult && (
                <div
                  className={`mt-4 p-3 rounded-md flex items-center space-x-2 ${
                    testResult.success
                      ? 'bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-300'
                      : 'bg-red-50 text-red-700 dark:bg-red-900/20 dark:text-red-300'
                  }`}
                >
                  {testResult.success ? (
                    <Check className="h-5 w-5" />
                  ) : (
                    <X className="h-5 w-5" />
                  )}
                  <span>{testResult.message}</span>
                </div>
              )}
            </div>

            {/* 操作按钮 */}
            <div className="flex space-x-4">
              <button
                onClick={saveConfig}
                disabled={saving || !config.apiKey.trim()}
                className="btn btn-primary flex-1"
              >
                <Save className="mr-2 h-4 w-4" />
                {saving ? '保存中...' : '保存配置'}
              </button>

              {savedConfig && (
                <button
                  onClick={deleteConfig}
                  className="btn btn-outline"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              )}
            </div>

            {savedConfig && (
              <div className="mt-6 p-4 bg-green-50 dark:bg-green-900/20 rounded-md">
                <div className="flex items-center space-x-2 text-green-700 dark:text-green-300">
                  <Check className="h-5 w-5" />
                  <span>
                    已配置 {providers.find(p => p.id === savedConfig.provider)?.name}
                    {' - '}
                    {savedConfig.model}
                  </span>
                </div>
              </div>
            )}
          </div>

          
          {/* 提供商信息 */}
          <div className="card p-6">
            <h3 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
              支持的AI提供商
            </h3>
            <div className="space-y-4">
              {providers.map((provider) => (
                <div key={provider.id} className="border-l-4 border-primary pl-4">
                  <div className="flex items-center justify-between mb-1">
                    <h4 className="font-medium text-gray-900 dark:text-white">
                      {provider.name}
                    </h4>
                    <span className={`text-xs px-2 py-1 rounded ${
                      provider.pricing === '免费'
                        ? 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-300'
                        : 'bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-300'
                    }`}>
                      {provider.pricing}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">
                    {provider.description}
                  </p>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    支持模型: {provider.models.join(', ')}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}