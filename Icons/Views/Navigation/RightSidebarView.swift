//
//  RightSidebarView.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI
import Foundation

/// 右侧侧边栏视图 - 包含生成风格、基础符号和参数设置
struct RightSidebarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var interactionService: InteractionService
    @State private var selectedTab: BottomTab = .templates
    @State private var selectedSFSymbol: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // 标签内容（纵向排列显示）
            VStack(spacing: 0) {
                styleContent(selectedStyle: $appState.selectedStyle)
                Divider()
                sfSymbolsContent
                Divider()
                parametersContent(
                    imageQuality: $appState.imageQuality,
                    removeBackground: $appState.removeBackground,
                    autoOptimizePrompts: $appState.autoOptimizePrompts,
                    enableBatchGeneration: $appState.enableBatchGeneration,
                    batchSize: $appState.batchSize
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var sidebarHeader: some View {
        EmptyView()
    }

    private var sfSymbolsContent: some View {
        VStack(spacing: 0) {
            // 基础符号标题
            HStack {
                Text("基础符号")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // SF符号内容（按分类显示）
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(symbolCategories, id: \.self) { category in
                        if let symbols = symbolsByCategory[category], !symbols.isEmpty {
                            // 分类符号网格 (不显示类别名称)
                            let columns = Array(repeating: GridItem(.adaptive(minimum: 50, maximum: 50), spacing: 8), count: 4)
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(symbols, id: \.name) { symbol in
                                        Button(action: {
                                            // 实现SF符号选择功能（单选模式）
                                            selectedSFSymbol = symbol.name
                                            // 使用异步更新避免在视图更新期间发布状态变化
                                            Task { @MainActor in
                                                // 单选模式：每次只选择一个符号
                                                if appState.selectedSFSymbols.contains(symbol.name) {
                                                    // 如果已选中则取消选中
                                                    appState.selectedSFSymbols.removeAll(where: { $0 == symbol.name })
                                                } else {
                                                    // 只选择当前符号，取消其他所有选中
                                                    appState.selectedSFSymbols = [symbol.name]
                                                }
                                            }
                                            print("Selected SF Symbol: \(symbol.name)")
                                        }) {
                                            VStack {
                                                Image(systemName: symbol.name)
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.accentColor)
                                                    .frame(width: 32, height: 32)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(NSColor.windowBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(appState.selectedSFSymbols.contains(symbol.name) ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                        .help("点击使用 \(symbol.name) 符号")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }

    private func styleContent(selectedStyle: Binding<IconStyle>) -> some View {
        VStack(spacing: 0) {
            // 风格选择标题
            HStack {
                Text("生成风格")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // 风格选择器
            StylePickerView(selectedStyle: selectedStyle)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    private func parametersContent(
        imageQuality: Binding<ImageQuality>,
        removeBackground: Binding<Bool>,
        autoOptimizePrompts: Binding<Bool>,
        enableBatchGeneration: Binding<Bool>,
        batchSize: Binding<Int>
    ) -> some View {
        VStack(spacing: 0) {
            // 参数设置标题
            HStack {
                Text("参数设置")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // 参数设置
            VStack(alignment: .leading, spacing: 16) {
                // 基础设置
                VStack(alignment: .leading, spacing: 12) {
                    Picker("图像质量", selection: imageQuality) {
                        ForEach(ImageQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality as ImageQuality)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .onChangeCompat(of: imageQuality.wrappedValue as ImageQuality) { newValue in
                        print("Selected quality changed to: \(newValue)")
                    }

                    Toggle("移除背景", isOn: removeBackground)
                    .onChangeCompat(of: removeBackground.wrappedValue as Bool) { newValue in
                        print("Remove background setting changed to: \(newValue)")
                    }
                }

                // 优化选项
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("自动优化提示词", isOn: autoOptimizePrompts)
                    .onChangeCompat(of: autoOptimizePrompts.wrappedValue as Bool) { newValue in
                        print("Auto optimize prompts setting changed to: \(newValue)")
                    }
                }

                // 批量生成
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("启用批量生成", isOn: enableBatchGeneration)
                    .onChangeCompat(of: enableBatchGeneration.wrappedValue as Bool) { newValue in
                        print("Batch generation setting changed to: \(newValue)")
                    }

                    if enableBatchGeneration.wrappedValue {
                        HStack {
                            Text("生成数量")
                            Spacer()
                            Stepper("\(batchSize.wrappedValue)", value: batchSize, in: 2...4)
                                .frame(width: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .onChangeCompat(of: batchSize.wrappedValue as Int) { newValue in
                            print("Batch size changed to: \(newValue)")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)

            Spacer()
        }
    }


    // 按分类组织的符号数据
    private var symbolsByCategory: [SFSymbolCategory: [SFSymbolInfo]] {
        let categories: [SFSymbolCategory] = [
            .communication, .objects, .devices, .connectivity, .human,
            .media, .shapes, .nature, .commerce, .health, .time,
            .gaming, .editing, .arrows, .indices
        ]

        var groupedSymbols: [SFSymbolCategory: [SFSymbolInfo]] = [:]

        for category in categories {
            groupedSymbols[category] = sampleSFSymbols.filter { $0.category == category }
        }

        return groupedSymbols
    }

    // 分类显示顺序
    private var symbolCategories: [SFSymbolCategory] {
        return [
            .communication, .objects, .devices, .connectivity, .human,
            .media, .shapes, .nature, .commerce, .health, .time,
            .gaming, .editing, .arrows, .indices
        ]
    }

    // 分类显示名称映射 (设置为空字符串以隐藏类别名称)
    private var categoryDisplayName: [SFSymbolCategory: String] {
        return [
            .communication: "",
            .objects: "",
            .devices: "",
            .connectivity: "",
            .human: "",
            .media: "",
            .shapes: "",
            .nature: "",
            .commerce: "",
            .health: "",
            .time: "",
            .gaming: "",
            .editing: "",
            .arrows: "",
            .indices: ""
        ]
    }

    // 示例SF符号数据
    private var sampleSFSymbols: [SFSymbolInfo] {
        [
            // 通讯类符号
            SFSymbolInfo(name: "message.fill", category: .communication),
            SFSymbolInfo(name: "envelope.fill", category: .communication),
            SFSymbolInfo(name: "phone.fill", category: .communication),
            SFSymbolInfo(name: "video.fill", category: .communication),

            // 物品类符号
            SFSymbolInfo(name: "house.fill", category: .objects),
            SFSymbolInfo(name: "bag.fill", category: .objects),
            SFSymbolInfo(name: "cart.fill", category: .objects),
            SFSymbolInfo(name: "gift.fill", category: .objects),

            // 设备类符号
            SFSymbolInfo(name: "iphone", category: .devices),
            SFSymbolInfo(name: "laptopcomputer", category: .devices),
            SFSymbolInfo(name: "applewatch", category: .devices),
            SFSymbolInfo(name: "airpods", category: .devices),

            // 连接类符号
            SFSymbolInfo(name: "wifi", category: .connectivity),
            SFSymbolInfo(name: "bluetooth", category: .connectivity),
            SFSymbolInfo(name: "personalhotspot", category: .connectivity),
            SFSymbolInfo(name: "network", category: .connectivity),

            // 人物类符号
            SFSymbolInfo(name: "person.fill", category: .human),
            SFSymbolInfo(name: "person.2.fill", category: .human),
            SFSymbolInfo(name: "person.3.fill", category: .human),
            SFSymbolInfo(name: "figure.walk", category: .human),

            // 媒体类符号
            SFSymbolInfo(name: "play.fill", category: .media),
            SFSymbolInfo(name: "pause.fill", category: .media),
            SFSymbolInfo(name: "stop.fill", category: .media),
            SFSymbolInfo(name: "music.note", category: .media),

            // 形状类符号
            SFSymbolInfo(name: "circle.fill", category: .shapes),
            SFSymbolInfo(name: "square.fill", category: .shapes),
            SFSymbolInfo(name: "triangle.fill", category: .shapes),
            SFSymbolInfo(name: "star.fill", category: .shapes),

            // 自然类符号
            SFSymbolInfo(name: "leaf.fill", category: .nature),
            SFSymbolInfo(name: "flame.fill", category: .nature),
            SFSymbolInfo(name: "drop.fill", category: .nature),
            SFSymbolInfo(name: "sun.max.fill", category: .nature),

            // 商务类符号
            SFSymbolInfo(name: "dollarsign.circle.fill", category: .commerce),
            SFSymbolInfo(name: "creditcard.fill", category: .commerce),
            SFSymbolInfo(name: "briefcase.fill", category: .commerce),
            SFSymbolInfo(name: "building.2.fill", category: .commerce),

            // 健康类符号
            SFSymbolInfo(name: "heart.fill", category: .health),
            SFSymbolInfo(name: "cross.fill", category: .health),
            SFSymbolInfo(name: "pills.fill", category: .health),
            SFSymbolInfo(name: "bandage.fill", category: .health),

            // 时间类符号
            SFSymbolInfo(name: "clock.fill", category: .time),
            SFSymbolInfo(name: "calendar.circle.fill", category: .time),
            SFSymbolInfo(name: "alarm.fill", category: .time),
            SFSymbolInfo(name: "timer", category: .time),

            // 游戏类符号
            SFSymbolInfo(name: "gamecontroller.fill", category: .gaming),
            SFSymbolInfo(name: "dice.fill", category: .gaming),
            SFSymbolInfo(name: "suit.heart.fill", category: .gaming),
            SFSymbolInfo(name: "suit.club.fill", category: .gaming),

            // 编辑类符号
            SFSymbolInfo(name: "pencil", category: .editing),
            SFSymbolInfo(name: "eraser.fill", category: .editing),
            SFSymbolInfo(name: "scissors", category: .editing),
            SFSymbolInfo(name: "paintbrush.fill", category: .editing),

            // 箭头类符号
            SFSymbolInfo(name: "arrow.up", category: .arrows),
            SFSymbolInfo(name: "arrow.down", category: .arrows),
            SFSymbolInfo(name: "arrow.left", category: .arrows),
            SFSymbolInfo(name: "arrow.right", category: .arrows),

            // 指示类符号
            SFSymbolInfo(name: "checkmark.circle.fill", category: .indices),
            SFSymbolInfo(name: "xmark.circle.fill", category: .indices),
            SFSymbolInfo(name: "exclamationmark.triangle.fill", category: .indices),
            SFSymbolInfo(name: "questionmark.circle.fill", category: .indices)
        ]
    }

// MARK: - Style Picker View
/// 风格选择器视图
struct StylePickerView: View {
    @Binding var selectedStyle: IconStyle
    @State private var selectedCategory: StyleCategory = .basic

    private var filteredStyles: [IconStyle] {
        return selectedCategory.styles
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 分类选择 - 删除"分类"文字
            Picker("", selection: $selectedCategory) {
                ForEach(StyleCategory.allCases, id: \.self) { category in
                    Text(category.displayName.replacingOccurrences(of: "风格", with: ""))
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .frame(height: 24)

            // 风格网格 - 缩小显示大小
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filteredStyles, id: \.self) { style in
                        StyleChipView(
                            style: style,
                            isSelected: selectedStyle == style
                        ) {
                            // Log style selection with clear section markers
                            print("=== Style Selection Changed ===")
                            print("Style selected: \(style.rawValue) - \(style.displayName)")
                            print("Style category: \(style.category.displayName)")
                            print("Style description: \(style.description)")
                            print("Style recommended use: \(style.recommendedUse.joined(separator: ", "))")
                            print("Style suggested colors: \(style.suggestedColors.joined(separator: ", "))")
                            print("Style prompt modifier: \(style.promptModifier)")
                            print("================================")

                            selectedStyle = style
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 50)
        }
    }
}

/// 风格选项芯片视图
struct StyleChipView: View {
    let style: IconStyle
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(style.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(width: 60, height: 40)
            .contentShape(Rectangle()) // Make the entire area clickable
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.2) : Color(NSColor.windowBackgroundColor)))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(4)
        .onHover { hovering in
            isHovered = hovering
        }
        .help("\(style.displayName)\n\(style.description)\n推荐用途: \(style.recommendedUse.joined(separator: ", "))")
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    RightSidebarView()
        .environmentObject(AppState.shared)
        .environmentObject(InteractionService.shared)
        .frame(width: 300, height: 600)
}