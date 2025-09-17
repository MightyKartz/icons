//
//  ResponsiveContainerView.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI

/// 响应式容器视图 - 栚据屏幕尺寸自动调整布局
struct ResponsiveContainerView<Content: View>: View {
    @EnvironmentObject private var layoutService: LayoutService
    @EnvironmentObject private var interactionService: InteractionService

    let content: () -> Content
    let breakpoints: Breakpoints
    let alignment: Alignment
    let animation: Animation?

    init(
        breakpoints: Breakpoints = Breakpoints(),
        alignment: Alignment = .center,
        animation: Animation? = .easeInOut(duration: 0.3),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.breakpoints = breakpoints
        self.alignment = alignment
        self.animation = animation
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(layoutService.padding)
            .animation(animation, value: layoutService.layoutMode)
            .animation(animation, value: layoutService.padding)
            .onChangeCompat(of: layoutService.windowSize) { size in
                // 可以在这里添加窗口尺寸变化的处理逻辑
            }
            .onAppear {
                // 初始化时的处理逻辑
            }
    }
}

/// 布局断点配置 - 定义不同屏幕尺寸的布局断点
struct Breakpoints {
    let compact: CGFloat
    let comfortable: CGFloat
    let spacious: CGFloat

    init(
        compact: CGFloat = 768,
        comfortable: CGFloat = 1024,
        spacious: CGFloat = 1440
    ) {
        self.compact = compact
        self.comfortable = comfortable
        self.spacious = spacious
    }

    /// 根据屏幕宽度确定布局模式
    func layoutMode(for width: CGFloat) -> LayoutMode {
        if width < compact {
            return .compact
        } else if width < comfortable {
            return .comfortable
        } else {
            return .spacious
        }
    }

    /// 获取当前断点的名称
    var breakpointName: String {
        "紧凑: <\(compact)px, 舒适: \(compact)px-\(comfortable)px, 宽松: >\(comfortable)px"
    }
}

/// 间距控制视图 - 统一管理应用内间距
struct SpacingControlView: View {
    @EnvironmentObject private var layoutService: LayoutService
    @EnvironmentObject private var interactionService: InteractionService
    @EnvironmentObject private var themeService: ThemeService
    @Environment(\.colorScheme) var colorScheme

    @State private var isExpanded = false
    @State private var customPaddingTop: CGFloat = 0
    @State private var customPaddingLeading: CGFloat = 0
    @State private var customPaddingBottom: CGFloat = 0
    @State private var customPaddingTrailing: CGFloat = 0
    @State private var isCustomPadding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题区域
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(themeService.getCurrentAccentColor())
                Text("间距与布局设置")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    withAnimation(interactionService.cardHoverAnimation()) {
                        isExpanded.toggle()
                    }
                    interactionService.buttonPressed()
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                // 布局模式选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("布局模式")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("布局模式", selection: $layoutService.layoutMode) {
                        ForEach(LayoutMode.allCases) { mode in
                            HStack {
                                Text(mode.displayName)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .transaction { transaction in
                        transaction.animation = interactionService.slideAnimation()
                    }
                }

                // 侧边栏宽度控制
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("侧边栏宽度")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(layoutService.sidebarWidth))px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { layoutService.sidebarWidth },
                            set: { layoutService.setSidebarWidth($0) }
                        ),
                        in: 0...400,
                        step: 10
                    )
                    .accentColor(themeService.getCurrentAccentColor())
                }

                // 间距控制选项
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("间距设置")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Toggle("自定义间距", isOn: $isCustomPadding)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                    }

                    if isCustomPadding {
                        // 自定义间距输入
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            SpacingInputView(title: "顶部", value: $customPaddingTop)
                            SpacingInputView(title: "底部", value: $customPaddingBottom)
                            SpacingInputView(title: "左侧", value: $customPaddingLeading)
                            SpacingInputView(title: "右侧", value: $customPaddingTrailing)
                        }
                        .padding(.top, 4)

                        HStack {
                            Spacer()
                            Button("应用自定义间距") {
                                // 这里可以添加应用自定义间距的逻辑
                                interactionService.actionCompleted()
                            }
                            .buttonStyle(.borderedProminent)
                            .hoverEffect()
                        }
                    } else {
                        // 预设间距控制
                        HStack {
                            Text("预设间距")
                            Spacer()
                            Picker("预设间距", selection: Binding(
                                get: { layoutService.layoutMode },
                                set: { layoutService.setLayoutMode($0) }
                            )) {
                                Text("紧凑").tag(LayoutMode.compact)
                                Text("舒适").tag(LayoutMode.comfortable)
                                Text("宽松").tag(LayoutMode.spacious)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                            .transaction { transaction in
                                transaction.animation = interactionService.slideAnimation()
                            }
                        }
                    }
                }

                // 当前间距预览
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前设置预览")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        Text("窗口尺寸: \(Int(layoutService.windowSize.width)) × \(Int(layoutService.windowSize.height))")
                        Spacer()
                        Text("模式: \(layoutService.layoutMode.displayName)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    HStack {
                        Text("间距: H \(Int(layoutService.padding.leading))px, V \(Int(layoutService.padding.top))px")
                        Spacer()
                        Button("重置") {
                            // 这里可以添加重置间距的逻辑
                            interactionService.buttonPressed()
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundColor(themeService.getCurrentAccentColor())
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }

            // 简化版间距信息（收起时显示）
            if !isExpanded {
                HStack {
                    Text("当前模式: \(layoutService.layoutMode.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("间距: H\(Int(layoutService.padding.leading))px V\(Int(layoutService.padding.top))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .dark ?
                        Material.thin :
                        Material.regular
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            // 初始化自定义间距值
            customPaddingTop = layoutService.padding.top
            customPaddingLeading = layoutService.padding.leading
            customPaddingBottom = layoutService.padding.bottom
            customPaddingTrailing = layoutService.padding.trailing
        }
    }
}

/// 间距输入视图
struct SpacingInputView: View {
    let title: String
    @Binding var value: CGFloat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("", value: $value, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .background(
                        colorScheme == .dark ?
                            Material.thin :
                            Material.regular
                    )

                Text("px")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("响应式布局组件")
            .font(.title2)
            .fontWeight(.bold)

        // 响应式容器预览
        ResponsiveContainerView {
            VStack {
                Text("响应式内容")
                    .font(.headline)
                Text("当前布局模式: \(LayoutService.shared.layoutMode.displayName)")
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
        }
        .frame(height: 150)
        .environmentObject(LayoutService.shared)
        .environmentObject(InteractionService.shared)
        .environmentObject(ThemeService.shared)

        // 间距控制预览
        SpacingControlView()
            .environmentObject(LayoutService.shared)
            .environmentObject(InteractionService.shared)
            .environmentObject(ThemeService.shared)
    }
    .frame(width: 450, height: 600)
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}