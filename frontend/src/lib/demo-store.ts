// 演示模式的任务存储
export interface DemoTask {
  id: string
  prompt: string
  provider: string
  model: string
  status: 'processing' | 'completed' | 'failed' | 'SUCCEED' | 'FAILED' // 支持ModelScope状态
  imageUrl?: string
  output_images?: string[] // ModelScope格式
  error?: string
  createdAt: string
  completedAt?: string
}

export interface DemoConfig {
  provider: string
  apiKey: string
  model: string
  baseUrl?: string
  maxTokens?: number
  temperature?: number
}

class DemoStore {
  private tasks: Map<string, DemoTask> = new Map()
  private config: DemoConfig | null = null

  // 任务管理
  createTask(task: Omit<DemoTask, 'id' | 'createdAt'>): DemoTask {
    const newTask: DemoTask = {
      ...task,
      id: `demo_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: new Date().toISOString()
    }
    this.tasks.set(newTask.id, newTask)
    return newTask
  }

  getTask(taskId: string): DemoTask | undefined {
    return this.tasks.get(taskId)
  }

  updateTask(taskId: string, updates: Partial<DemoTask>): DemoTask | null {
    const task = this.tasks.get(taskId)
    if (task) {
      const updatedTask = { ...task, ...updates }
      this.tasks.set(taskId, updatedTask)
      return updatedTask
    }
    return null
  }

  getAllTasks(): DemoTask[] {
    return Array.from(this.tasks.values())
  }

  // 配置管理
  saveConfig(config: DemoConfig): void {
    this.config = { ...config, apiKey: '***demo***' }
  }

  getConfig(): DemoConfig | null {
    return this.config
  }

  clearConfig(): void {
    this.config = null
  }

  // 清理旧任务（保留最近50个）
  cleanup(): void {
    const allTasks = Array.from(this.tasks.values())
    if (allTasks.length > 50) {
      // 按创建时间排序，保留最新的50个
      const sortedTasks = allTasks.sort((a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )
      const tasksToKeep = sortedTasks.slice(0, 50)

      // 重建Map
      this.tasks.clear()
      tasksToKeep.forEach(task => this.tasks.set(task.id, task))
    }
  }
}

// 创建单例实例
export const demoStore = new DemoStore()

// 定期清理
setInterval(() => {
  demoStore.cleanup()
}, 60000) // 每分钟清理一次