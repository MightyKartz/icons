//
//  SettingsView.swift
//  Icons
//
//  Created by Icons App on 2024/01/15.
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeService: ThemeService

    @EnvironmentObject private var layoutService: LayoutService
    @EnvironmentObject private var interactionService: InteractionService

    // MARK: - 状态属性

    @State private var selectedTab: SettingsTab = .general
    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""
    @State private var selectedProvider: AIProvider = .openAI
    // 新增：订阅与配额相关状态
    @StateObject private var apiService = APIService.shared
    @State private var quota: QuotaResponse?
    @State private var isLoadingQuota: Bool = false
    @State private var quotaError: String?
    // 新增：中间层连接相关状态
    @State private var baseURLInput: String = APIService.shared.baseURLString
    @State private var isTestingConnection: Bool = false
    @State private var healthMessage: String?
    @State private var healthIsOK: Bool?
    @AppStorage("defaultIconSize") private var defaultIconSize: Int = 1024
    @AppStorage("defaultQuality") private var defaultQuality: String = "hd"
    @AppStorage("autoRemoveBackground") private var autoRemoveBackground: Bool = true
    @AppStorage("saveToHistory") private var saveToHistory: Bool = true
    
    // 导出设置
    @AppStorage("defaultExportFormat") private var defaultExportFormat: String = "png"
    @AppStorage("exportLocation") private var exportLocation: String = ""
    @AppStorage("createSubfolders") private var createSubfolders: Bool = true
    @AppStorage("includeMetadata") private var includeMetadata: Bool = true
    
    // 界面设置
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("showPreviewInSidebar") private var showPreviewInSidebar: Bool = true
    @AppStorage("gridColumns") private var gridColumns: Int = 4
    @AppStorage("showThumbnails") private var showThumbnails: Bool = true
    
    // MARK: - 视图主体
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航按钮
            tabButtons

            // 内容区域
            settingsContent
        }
        .alert("配置 API 密钥", isPresented: $showingAPIKeyAlert) {
            apiKeyAlert
        }
    }
    
    // MARK: - 顶部导航按钮

    private var tabButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.title)
                                .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                        }
                        .frame(width: 80, height: 60)
                        .background(selectedTab == tab ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }

    // MARK: - 设置内容

    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch selectedTab {
                case .general:
                    generalSettings
                case .ai:
                    aiSettings
                case .export:
                    exportSettings
                case .interface:
                    InterfaceSettingsPanel()
                        .environmentObject(themeService)
                        .environmentObject(layoutService)
                        .environmentObject(interactionService)
                case .advanced:
                    advancedSettings
                case .about:
                    aboutSettings
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - 通用设置
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("通用设置")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            // 默认图标尺寸
            VStack(alignment: .leading, spacing: 8) {
                Text("默认图标尺寸")
                    .font(.headline)
                
                Picker("尺寸", selection: $defaultIconSize) {
                    Text("512x512").tag(512)
                    Text("1024x1024").tag(1024)
                    Text("2048x2048").tag(2048)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 默认质量
            VStack(alignment: .leading, spacing: 8) {
                Text("默认生成质量")
                    .font(.headline)

                Picker("质量", selection: $defaultQuality) {
                    Text("标准").tag("standard")
                    Text("高清").tag("hd")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 自动移除背景
            Toggle("自动移除背景", isOn: $autoRemoveBackground)
            
            // 保存到历史记录
            Toggle("自动保存到历史记录", isOn: $saveToHistory)

            // 开发者测试选项 - 仅在DEBUG模式下可见
            DeveloperOptionsView()
        }
    }
    
    // MARK: - AI 设置
    
    private var aiSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 服务配置")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            // 新增：订阅与配额展示
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("订阅与配额")
                        .font(.headline)
                    Spacer()
                    Button(action: { Task { await loadQuota() } }) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            
                Group {
                    if isLoadingQuota {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("正在加载配额...")
                                .foregroundColor(.secondary)
                        }
                    } else if let error = quotaError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.secondary)
                        }
                    } else if let q = quota {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Label(q.plan.uppercased(), systemImage: q.plan.lowercased() == "pro" ? "star.fill" : "person")
                                    .font(.subheadline)
                                    .foregroundColor(q.plan.lowercased() == "pro" ? .yellow : .secondary)
                                if let limit = q.limit {
                                    Text("剩余: \(q.remaining)/\(limit) 次")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("剩余: \(q.remaining) 次")
                                        .foregroundColor(.secondary)
                                }
                            }
                            if let resetAt = q.resetAt, !resetAt.isEmpty {
                                Text("重置时间: \(formatResetAt(resetAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text("暂无配额信息")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task { await loadQuota() }

            // 新增：中间层 API 配置（Base URL + 测试连接）
            VStack(alignment: .leading, spacing: 12) {
                Text("中间层 API")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("基础地址（Base URL）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        TextField("例如 http://127.0.0.1:8787/v1", text: $baseURLInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minWidth: 320)

                        Button(action: { Task { await testConnection() } }) {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.horizontal, 8)
                            } else {
                                Label("测试连接", systemImage: "link.badge.plus")
                            }
                        }
                        .disabled(isTestingConnection || baseURLInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.bordered)

                        Button("保存") {
                            saveBaseURL()
                        }
                        .disabled(baseURLInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button("恢复默认") {
                            resetBaseURL()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let message = healthMessage, let ok = healthIsOK {
                        HStack(spacing: 6) {
                            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundColor(ok ? .green : .red)
                            Text(message)
                                .foregroundColor(ok ? .green : .red)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("当前生效: ")
                            .foregroundColor(.secondary)
                        Text(apiService.baseURLString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            // 原有：AI 服务提供商列表（保留，但将逐步下线密钥直连）
            VStack(alignment: .leading, spacing: 12) {
                Text("AI 服务提供商")
                    .font(.headline)

                ForEach(AIProvider.allCases, id: \.self) { provider in
                    providerCard(provider)
                }
            }

            // 原有：默认生成参数
            VStack(alignment: .leading, spacing: 12) {
                Text("默认生成参数")
                    .font(.headline)

                HStack {
                    Text("推理步数")
                    Spacer()
                    Stepper("\(getSteps())", value: Binding(
                        get: { getSteps() },
                        set: { setSteps($0) }
                    ), in: 20...100, step: 10)
                }

                HStack {
                    Text("CFG Scale")
                    Spacer()
                    Slider(value: Binding(
                        get: { getCFGScale() },
                        set: { setCFGScale($0) }
                    ), in: 1...20, step: 0.5) {
                        Text("CFG Scale")
                    }
                    Text(String(format: "%.1f", getCFGScale()))
                        .frame(width: 40)
                }
            }
        }
    }
    
    // MARK: - 导出设置
    
    private var exportSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("导出设置")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            // 默认导出格式
            VStack(alignment: .leading, spacing: 8) {
                Text("默认导出格式")
                    .font(.headline)
                
                Picker("格式", selection: $defaultExportFormat) {
                    Text("PNG").tag("png")
                    Text("SVG").tag("svg")
                    Text("PDF").tag("pdf")
                    Text("ICNS").tag("icns")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 导出位置
            VStack(alignment: .leading, spacing: 8) {
                Text("默认导出位置")
                    .font(.headline)
                
                HStack {
                    TextField("选择文件夹", text: $exportLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("浏览") {
                        selectExportLocation()
                    }
                }
            }
            
            // 导出选项
            VStack(alignment: .leading, spacing: 8) {
                Text("导出选项")
                    .font(.headline)
                
                Toggle("创建子文件夹", isOn: $createSubfolders)
                Toggle("包含元数据", isOn: $includeMetadata)
            }
        }
    }
    
    // MARK: - 导出设置面板
    struct ExportSettingsPanel: View {
        @EnvironmentObject private var appState: AppState
        @EnvironmentObject private var interactionService: InteractionService
        @State private var showingFolderPicker = false
        
        // 本地状态变量
        @State private var localDefaultExportFormat: ExportFormat = .png
        @State private var localDefaultExportSize: ExportSize = .size1024
        @State private var localCustomExportWidth: Int = 1024
        @State private var localCustomExportHeight: Int = 1024
        @State private var localAutoCreateSubfolders: Bool = true
        @State private var localIncludeMetadata: Bool = true
        @State private var localGenerateThumbnails: Bool = false
        @State private var localPreserveOriginalNames: Bool = false
        @State private var localFilenameTemplate: String = "icon_{name}_{size}"
        @State private var localPngCompressionLevel: Double = 0.8
        @State private var localJpegQuality: Double = 0.9
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("导出设置")
                    .font(.headline)
                
                // 默认格式设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("默认格式")
                        .font(.subheadline)
                        .fontWeight(.medium)
                
                    Picker("默认格式", selection: $localDefaultExportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            HStack {
                                Image(systemName: format.icon)
                                VStack(alignment: .leading) {
                                    Text(format.displayName)
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 300)
                    .onChange(of: localDefaultExportFormat) { newValue in
                        Task { @MainActor in
                            appState.defaultExportFormat = newValue
                        }
                    }
                }
                
                Divider()
                
                // 尺寸设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("默认尺寸")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("默认尺寸", selection: $localDefaultExportSize) {
                        ForEach(ExportSize.allCases) { size in
                            VStack(alignment: .leading) {
                                Text(size.displayName)
                                Text(size.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 300)
                    .onChange(of: localDefaultExportSize) { newValue in
                        Task { @MainActor in
                            appState.defaultExportSize = newValue
                        }
                    }
                    
                    if localDefaultExportSize == .custom {
                        HStack {
                            Text("自定义尺寸:")
                            TextField("宽度", value: $localCustomExportWidth, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onChange(of: localCustomExportWidth) { newValue in
                                    Task { @MainActor in
                                        appState.customExportWidth = newValue
                                    }
                                }
                            Text("×")
                            TextField("高度", value: $localCustomExportHeight, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onChange(of: localCustomExportHeight) { newValue in
                                    Task { @MainActor in
                                        appState.customExportHeight = newValue
                                    }
                                }
                            Text("px")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                }
                
                Divider()
                
                // 保存位置
                VStack(alignment: .leading, spacing: 12) {
                    Text("保存位置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("当前位置:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appState.exportFolderPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        Spacer()
                        
                        Button("选择文件夹") {
                            showingFolderPicker = true
                            interactionService.buttonPressed()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                // 导出选项
                VStack(alignment: .leading, spacing: 12) {
                    Text("导出选项")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Toggle("自动创建子文件夹", isOn: $localAutoCreateSubfolders)
                        .onChange(of: localAutoCreateSubfolders) { newValue in
                            Task { @MainActor in
                                appState.autoCreateSubfolders = newValue
                            }
                        }
                    Toggle("导出时包含元数据", isOn: $localIncludeMetadata)
                        .onChange(of: localIncludeMetadata) { newValue in
                            Task { @MainActor in
                                appState.includeMetadata = newValue
                            }
                        }
                    Toggle("生成缩略图", isOn: $localGenerateThumbnails)
                        .onChange(of: localGenerateThumbnails) { newValue in
                            Task { @MainActor in
                                appState.generateThumbnails = newValue
                            }
                        }
                    Toggle("保留原始文件名", isOn: $localPreserveOriginalNames)
                        .onChange(of: localPreserveOriginalNames) { newValue in
                            Task { @MainActor in
                                appState.preserveOriginalNames = newValue
                            }
                        }
                    
                    HStack {
                        Text("文件名格式:")
                        TextField("例如: icon_{name}_{size}", text: $localFilenameTemplate)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 250)
                            .onChange(of: localFilenameTemplate) { newValue in
                                Task { @MainActor in
                                    appState.filenameTemplate = newValue
                                }
                            }
                        Spacer()
                    }
                }
                
                Divider()
                
                // 质量设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("质量设置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("PNG 压缩:")
                        Slider(value: $localPngCompressionLevel, in: 0...1, step: 0.1)
                            .onChange(of: localPngCompressionLevel) { newValue in
                                Task { @MainActor in
                                    appState.pngCompressionLevel = newValue
                                }
                            }
                        Text("\(Int(localPngCompressionLevel * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Text("JPEG 质量:")
                        Slider(value: $localJpegQuality, in: 0...1, step: 0.1)
                            .onChange(of: localJpegQuality) { newValue in
                                Task { @MainActor in
                                    appState.jpegQuality = newValue
                                }
                            }
                        Text("\(Int(localJpegQuality * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                }
                
                Spacer()
            }
            .padding()
            .fileImporter(
                isPresented: $showingFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        appState.setExportFolder(url.path)
                    }
                case .failure(let error):
                    print("文件夹选择失败: \(error.localizedDescription)")
                }
            }
            .onAppear {
                // 初始化本地状态变量
                localDefaultExportFormat = appState.defaultExportFormat
                localDefaultExportSize = appState.defaultExportSize
                localCustomExportWidth = appState.customExportWidth
                localCustomExportHeight = appState.customExportHeight
                localAutoCreateSubfolders = appState.autoCreateSubfolders
                localIncludeMetadata = appState.includeMetadata
                localGenerateThumbnails = appState.generateThumbnails
                localPreserveOriginalNames = appState.preserveOriginalNames
                localFilenameTemplate = appState.filenameTemplate
                localPngCompressionLevel = appState.pngCompressionLevel
                localJpegQuality = appState.jpegQuality
            }
        }
    }
    
    // MARK: - 生成设置面板
    struct GenerationSettingsPanel: View {
        @EnvironmentObject private var appState: AppState
        @EnvironmentObject private var interactionService: InteractionService
        
        // 本地状态变量，避免在视图更新期间直接修改AppState
        @State private var localImageQuality: ImageQuality = .high
        @State private var localGenerationCount: Int = 1
        @State private var localEnableBatchGeneration: Bool = false
        @State private var localBatchSize: Int = 2

        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                Text("生成设置")
                    .font(.title2)
                    .fontWeight(.semibold)

                // AI服务说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI 服务")
                        .font(.headline)
                        .fontWeight(.medium)

                    Text("模型调度由后端根据订阅等级与负载自动选择，不再提供本地切换。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                // 图像质量设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("图像质量")
                        .font(.headline)
                        .fontWeight(.medium)

                    Picker("图片质量", selection: $localImageQuality) {
                        ForEach(ImageQuality.allCases) { quality in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(quality.rawValue)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text(quality.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(quality)
                            .padding(.vertical, 6)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    .onChange(of: localImageQuality) { newValue in
                        Task { @MainActor in
                            appState.imageQuality = newValue
                        }
                    }
                }
                .padding(.vertical, 4)

                // 生成参数
                VStack(alignment: .leading, spacing: 16) {
                    Text("生成参数")
                        .font(.headline)
                        .fontWeight(.medium)

                    HStack(alignment: .center) {
                        Text("生成数量:")
                            .frame(width: 100, alignment: .leading)
                            .font(.callout)
                        Stepper("\(localGenerationCount) 个",
                               value: $localGenerationCount,
                               in: 1...10) { _ in
                            interactionService.buttonPressed()
                            Task { @MainActor in
                                appState.generationCount = localGenerationCount
                            }
                        }
                        .frame(maxWidth: 200)
                        .controlSize(.regular)
                        Spacer()
                    }
                }
                .padding(.vertical, 4)

                // 高级功能
                VStack(alignment: .leading, spacing: 16) {
                    Text("高级功能")
                        .font(.headline)
                        .fontWeight(.medium)

                    Toggle("启用批量生成", isOn: $localEnableBatchGeneration)
                        .font(.callout)
                        .padding(.vertical, 2)
                        .onChange(of: localEnableBatchGeneration) { newValue in
                            Task { @MainActor in
                                appState.enableBatchGeneration = newValue
                            }
                        }

                    HStack(alignment: .center) {
                        Text("批量数量:")
                            .frame(width: 100, alignment: .leading)
                            .font(.callout)
                        Stepper("\(localBatchSize) 个",
                               value: $localBatchSize,
                               in: 2...10) { _ in
                            interactionService.buttonPressed()
                            Task { @MainActor in
                                appState.batchSize = localBatchSize
                            }
                        }
                        .frame(maxWidth: 200)
                        .controlSize(.regular)
                        .disabled(!localEnableBatchGeneration)
                        Spacer()
                    }
                    .opacity(localEnableBatchGeneration ? 1.0 : 0.6)
                    .padding(.vertical, 2)
                }
                .padding(.vertical, 4)

                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                // 初始化本地状态变量
                localImageQuality = appState.imageQuality
                localGenerationCount = appState.generationCount
                localEnableBatchGeneration = appState.enableBatchGeneration
                localBatchSize = appState.batchSize
            }
        }
    }
    
    // MARK: - 界面设置面板
    struct InterfaceSettingsPanel: View {
        @EnvironmentObject private var themeService: ThemeService
        @EnvironmentObject private var layoutService: LayoutService
        @EnvironmentObject private var interactionService: InteractionService
        @State private var customAccentColor: Color? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("界面设置")
                    .font(.headline)

                // 主题设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("主题")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // 使用新的主题切换组件
                    ThemeToggleView()
                        .environmentObject(themeService)
                        .environmentObject(interactionService)
                }

                Divider()

                // 强调色设置
                ColorPickerView(
                    selectedColor: $themeService.accentColor,
                    customColor: $customAccentColor
                )
                .environmentObject(themeService)
                .environmentObject(interactionService)
                .onChange(of: customAccentColor) { newValue in
                    themeService.setCustomAccentColor(newValue)
                }
                .onAppear {
                    // 初始化自定义颜色
                    if let hex = themeService.customColors.customAccentColor,
                       let color = try? Color(hex: hex) {
                        customAccentColor = color
                    }
                }
                
                Divider()
                
                // 布局设置
                SpacingControlView()
                    .environmentObject(layoutService)
                    .environmentObject(interactionService)
                
                Divider()
                
                // 动画设置
                AnimationControlPanel()
                    .environmentObject(interactionService)
                    .environmentObject(themeService)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - 界面设置

    // MARK: - 高级设置
    
    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("高级设置")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            // 缓存管理
            VStack(alignment: .leading, spacing: 8) {
                Text("缓存管理")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("图像缓存")
                        Text("约 125 MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("清除缓存") {
                        clearImageCache()
                    }
                    .buttonStyle(.bordered)
                    #if os(iOS)
                    .hoverEffect(style: .subtle)
                    #endif
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("模板缓存")
                        Text("约 2.3 MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("清理") {
                        clearTemplateCache()
                    }
                }
            }
            
            // 数据管理
            VStack(alignment: .leading, spacing: 8) {
                Text("数据管理")
                    .font(.headline)
                
                Button("导出用户数据") {
                    exportUserData()
                }
                
                Button("重置所有设置") {
                    resetAllSettings()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - 关于设置
    
    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("关于")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "app.badge")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Icons")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("版本 1.0.0 (Build 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("AI 驱动的图标设计工具")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("开发信息")
                        .font(.headline)
                    
                    Text("© 2024 Icons App. All rights reserved.")
                        .font(.caption)
                    
                    Link("隐私政策", destination: URL(string: "https://example.com/privacy")!)
                    Link("使用条款", destination: URL(string: "https://example.com/terms")!)
                    Link("技术支持", destination: URL(string: "https://example.com/support")!)
                }
            }
        }
    }
    
    // MARK: - 辅助视图
    
    private func providerCard(_ provider: AIProvider) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(provider.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("配置") {
                    selectedProvider = provider
                    showingAPIKeyAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text(getProviderStatus(provider))
                .font(.caption)
                .foregroundColor(hasAPIKey(for: provider) ? .green : .orange)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    private var apiKeyAlert: some View {
        VStack {
            SecureField("API 密钥", text: $tempAPIKey)
            
            HStack {
                Button("取消") {
                    tempAPIKey = ""
                }
                
                Button("保存") {
                    saveAPIKey(tempAPIKey, for: selectedProvider)
                    tempAPIKey = ""
                }
                .disabled(tempAPIKey.isEmpty)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func hasAPIKey(for provider: AIProvider) -> Bool {
        let key = getAPIKey(for: provider)
        return !key.isEmpty
    }
    
    private func getAPIKey(for provider: AIProvider) -> String {
        switch provider {
        case .openAI:
            return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        case .stability:
            return ProcessInfo.processInfo.environment["STABILITY_API_KEY"] ?? ""
        case .midjourney:
            return ProcessInfo.processInfo.environment["MIDJOURNEY_API_KEY"] ?? ""
        case .replicate:
            return ProcessInfo.processInfo.environment["REPLICATE_API_TOKEN"] ?? ""
        }
    }
    
    private func getProviderStatus(_ provider: AIProvider) -> String {
        return hasAPIKey(for: provider) ? "已配置" : "需要配置 API 密钥"
    }
    
    private func saveAPIKey(_ key: String, for provider: AIProvider) {
        // 在实际应用中，应该安全地存储 API 密钥
        // 这里只是示例实现
        print("保存 \(provider.displayName) API 密钥")
    }
    
    private func selectExportLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            exportLocation = panel.url?.path ?? ""
        }
    }
    
    private func getSteps() -> Int {
        return UserDefaults.standard.integer(forKey: "defaultSteps") == 0 ? 50 : UserDefaults.standard.integer(forKey: "defaultSteps")
    }
    
    private func setSteps(_ value: Int) {
        UserDefaults.standard.set(value, forKey: "defaultSteps")
    }
    
    private func getCFGScale() -> Double {
        let value = UserDefaults.standard.double(forKey: "defaultCFGScale")
        return value == 0 ? 7.5 : value
    }
    
    private func setCFGScale(_ value: Double) {
        UserDefaults.standard.set(value, forKey: "defaultCFGScale")
    }
    
    private func clearImageCache() {
        // TODO: 实现图像缓存清理
        print("清理图像缓存")
    }
    
    private func clearTemplateCache() {
        // TODO: 实现模板缓存清理
        print("清理模板缓存")
    }
    
    private func exportUserData() {
        // TODO: 实现用户数据导出
        print("导出用户数据")
    }
    
    private func resetAllSettings() {
        // TODO: 实现设置重置
        print("重置所有设置")
    }
}

// MARK: - 设置标签页

enum SettingsTab: String, CaseIterable {
    case general = "general"
    case ai = "ai"
    case export = "export"
    case interface = "interface"
    case advanced = "advanced"
    case about = "about"
    
    var title: String {
        switch self {
        case .general: return "通用"
        case .ai: return "AI 服务"
        case .export: return "导出"
        case .interface: return "界面"
        case .advanced: return "高级"
        case .about: return "关于"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .ai: return "brain"
        case .export: return "square.and.arrow.up"
        case .interface: return "paintbrush"
        case .advanced: return "wrench.and.screwdriver"
        case .about: return "info.circle"
        }
    }
}

// MARK: - 预览

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
        .frame(width: 800, height: 600)
}

// MARK: - 加载配额
extension SettingsView {
private func loadQuota() async {
    await MainActor.run {
        isLoadingQuota = true
        quotaError = nil
    }
    do {
        let q: QuotaResponse = try await apiService.getQuota()
        await MainActor.run {
            self.quota = q
            self.isLoadingQuota = false
        }
    } catch {
        await MainActor.run {
            self.quotaError = (error as? LocalizedError)?.errorDescription ?? "获取配额失败"
            self.isLoadingQuota = false
        }
    }
}
}

// MARK: - 格式化重置时间

// 新增：中间层健康检查/保存/重置
extension SettingsView {
private func testConnection() async {
    if isTestingConnection { return }
    isTestingConnection = true
    healthMessage = nil
    healthIsOK = nil
    let input = baseURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
        let resp = try await apiService.healthCheck(overrideBaseURL: input)
        if resp.ok {
            healthMessage = "连接正常 · " + resp.time
            healthIsOK = true
        } else {
            healthMessage = "连接失败"
            healthIsOK = false
        }
    } catch {
        healthMessage = error.localizedDescription
        healthIsOK = false
    }
    isTestingConnection = false
}

private func saveBaseURL() {
    let input = baseURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
    apiService.setBaseURLOverride(input.isEmpty ? nil : input)
    // 同步展示最新生效地址
    baseURLInput = apiService.baseURLString
    healthMessage = "已保存"
    healthIsOK = true
}

private func resetBaseURL() {
    apiService.setBaseURLOverride(nil)
    baseURLInput = apiService.baseURLString
    healthMessage = "已恢复默认"
    healthIsOK = true
}

private func formatResetAt(_ isoString: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: isoString) {
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .short
        return out.string(from: date)
    }
    return isoString
}
}