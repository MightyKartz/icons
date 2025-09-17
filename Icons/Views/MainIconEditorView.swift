//
//  MainIconEditorView.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI
import Foundation
import AppKit

/// 主图标编辑器视图 - 实现新的UI布局要求
struct MainIconEditorView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeService: ThemeService
    @EnvironmentObject private var layoutService: LayoutService
    @EnvironmentObject private var interactionService: InteractionService
    @State private var isRightSidebarVisible = false

    var body: some View {
        HStack(spacing: 0) {
            // 主内容区域
            VStack(spacing: 0) {
                // 主编辑区域
                VStack(spacing: 8) {
                    // 对话框和生成按钮区域（居中显示）
                    PromptEditorSection(isRightSidebarVisible: $isRightSidebarVisible)

                    // 图标生成区域
                    IconGenerationArea()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: 700, maxHeight: .infinity)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)

            // 右侧侧边栏
            if isRightSidebarVisible {
                RightSidebarView()
                    .frame(width: 300)
                    .background(Color(NSColor.windowBackgroundColor))
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}



// MARK: - Preview
/// 图标生成区域 - 显示生成的图标
struct IconGenerationArea: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedIcon: GeneratedIcon?
    @State private var showExportOptions = false

    var body: some View {
        VStack(spacing: 16) {
            if appState.currentSessionIcons.isEmpty {
                // 空状态 - 显示提示信息
                VStack(spacing: 12) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("生成的图标将显示在这里")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("输入提示词并点击生成按钮开始创建图标")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // 显示生成的图标网格（居中显示）
                ScrollView {
                    VStack {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
                        ], spacing: 20) {
                            ForEach(appState.currentSessionIcons) { icon in
                                GeneratedIconView(icon: icon, isSelected: icon.id == selectedIcon?.id) {
                                    selectedIcon = icon
                                    showExportOptions = true
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20) // Add some padding for better centering
            }
        }
        .frame(maxHeight: 400)
        .cornerRadius(12)
        .sheet(isPresented: $showExportOptions) {
            if let icon = selectedIcon {
                ExportOptionsView(icon: icon, isPresented: $showExportOptions)
            }
        }
    }
}

/// 生成的图标视图 - 显示图标、生成风格、提示词和基础符号
struct GeneratedIconView: View {
    let icon: GeneratedIcon
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 12) {
            // 图标图像（居中显示）
            AsyncImage(url: URL(string: icon.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : (isHovered ? Color.accentColor.opacity(0.5) : Color.clear), lineWidth: 2)
            )

            // 生成风格
            if let style = getIconStyle(from: icon.tags) {
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(Color.accentColor)
                    .cornerRadius(6)
            }

            // 提示词
            Text(icon.prompt)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // 基础符号 (如果有的话)
            if let symbols = icon.parameters["symbols"] {
                Text("_symbols: \(symbols)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else if !icon.tags.filter({ $0.hasPrefix("symbol:") }).isEmpty {
                let symbolTags = icon.tags.filter({ $0.hasPrefix("symbol:") }).compactMap({ $0.replacingOccurrences(of: "symbol:", with: "") }).joined(separator: ", ")
                Text("_symbols: \(symbolTags)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // 基础信息
            HStack(spacing: 8) {
                Text(icon.model)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\(Int(icon.size.width))×\(Int(icon.size.height))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.textBackgroundColor))
        .cornerRadius(12)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
    }

    // Helper function to get IconStyle from tags
    private func getIconStyle(from tags: [String]) -> IconStyle? {
        // Look for exact matches first
        for tag in tags {
            if let style = IconStyle(rawValue: tag) {
                return style
            }
        }

        // If no exact match found, try to find a style by checking if any tag contains a valid style name
        // This handles cases where tags might have extra whitespace or formatting
        for tag in tags {
            let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            if let style = IconStyle(rawValue: trimmedTag) {
                return style
            }
        }

        return nil
    }
}

/// 导出选项视图
struct ExportOptionsView: View {
    let icon: GeneratedIcon
    @Binding var isPresented: Bool
    @EnvironmentObject private var appState: AppState
    @State private var selectedFormat: ExportFormat = .png
    @State private var selectedSize: ExportSize = .size1024
    @State private var customWidth = 1024
    @State private var customHeight = 1024
    @State private var isSaving = false
    @State private var saveSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("导出图标")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            // 图标预览
            AsyncImage(url: URL(string: icon.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 提示词
            Text(icon.prompt)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            // 导出选项
            VStack(spacing: 16) {
                // 格式选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("格式")
                        .font(.headline)
                        .fontWeight(.medium)

                    HStack {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: {
                                selectedFormat = format
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: format.icon)
                                        .font(.title3)
                                    Text(format.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedFormat == format ? Color.accentColor : Color(.controlBackgroundColor))
                                .foregroundColor(selectedFormat == format ? .white : .primary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 尺寸选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("尺寸")
                        .font(.headline)
                        .fontWeight(.medium)

                    Picker("尺寸", selection: $selectedSize) {
                        ForEach(ExportSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 自定义尺寸（当选择自定义时显示）
                if selectedSize == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自定义尺寸")
                            .font(.headline)
                            .fontWeight(.medium)

                        HStack {
                            TextField("宽度", value: $customWidth, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)

                            Text("×")
                                .foregroundColor(.secondary)

                            TextField("高度", value: $customHeight, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                }
            }
            .padding(.horizontal)

            Divider()

            // 操作按钮
            HStack {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("保存到文件") {
                    saveIcon()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding(.horizontal)

            // 状态提示
            if isSaving {
                HStack {
                    ProgressView()
                    Text("正在保存...")
                }
                .foregroundColor(.secondary)
            } else if saveSuccess {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("保存成功!")
                }
                .foregroundColor(.green)
            }
        }
        .padding(.vertical)
        .frame(minWidth: 400, minHeight: 500)
    }

    private func saveIcon() {
        isSaving = true
        saveSuccess = false

        // 模拟保存过程
        Task {
            // 实际应用中，这里会下载图片并保存到指定路径
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟

            await MainActor.run {
                isSaving = false
                saveSuccess = true

                // 2秒后自动关闭
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainIconEditorView()
        .environmentObject(AppState.shared)
        .environmentObject(ThemeService.shared)
        .environmentObject(LayoutService.shared)
        .environmentObject(InteractionService.shared)
        .frame(width: 1200, height: 800)
}
