//
//  MainNavigationView.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI

struct MainNavigationView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeService: ThemeService
    @EnvironmentObject private var layoutService: LayoutService
    @EnvironmentObject private var interactionService: InteractionService
    // Removed local selectedTab to avoid state desync
    // @State private var selectedTab: NavigationTab = .editor
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 侧边栏 - 确保在主界面默认显示
                if layoutService.isSidebarVisible || layoutService.sidebarWidth > 1 {
                    sidebarView
                        .frame(width: layoutService.sidebarWidth)
                        .background(Color(NSColor.windowBackgroundColor))
                }

                // 主内容区域
                mainContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
            }
            .onAppear {
                layoutService.updateWindowSize(geometry.size)
                // 确保侧边栏在主界面默认显示
                if layoutService.sidebarWidth <= 1 {
                    layoutService.forceShowSidebar()
                }
            }
            .onChangeCompat(of: geometry.size) { size in
                layoutService.updateWindowSize(size)
            }
        }
        .themedBackground()
    }
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Logo 区域
            HStack {
                Image(systemName: "app.badge")
                    .font(.title2)
                    .foregroundColor(themeService.accentColor.color)
                Text("Icons")
                    .font(.title)  // 增大 Icons 字号
                    .fontWeight(.semibold)
                    .themedForeground()
                Spacer()
            }
            .padding()

            Divider()

            // 导航列表（只保留必要选项）
            ScrollView {
                LazyVStack(spacing: 4) {
                    // 只显示必要的导航选项
                    ForEach([NavigationTab.generate, NavigationTab.history, NavigationTab.settings], id: \.self) { tab in
                        NavigationTabButton(
                            tab: tab,
                            isSelected: appState.selectedTab == tab
                        ) {
                            withAnimation(interactionService.slideAnimation()) {
                                // 使用异步更新避免在视图更新期间发布状态变化
                                Task { @MainActor in
                                    appState.selectedTab = tab
                                }
                            }
                            interactionService.buttonPressed()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }

            Spacer()

            // 底部信息 - 将版本信息放在右下角
            HStack {
                Spacer()
                Text("版本 1.0.0")
                    .font(.caption)
                    .themedSecondaryForeground()
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // 顶部工具栏（始终显示）
            topToolbar

            // 内容区域
            Group {
                switch appState.selectedTab {
                case .generate:
                    MainIconEditorView()
                case .editor:
                    MainIconEditorView()
                case .templates:
                    TemplateLibraryView()
                case .sfSymbols:
                    SFSymbolsView()
                case .results:
                    IconResultsView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fadeInOut(isVisible: true)
        }
    }
    
    private var topToolbar: some View {
        Group {
            if [NavigationTab.generate, NavigationTab.history, NavigationTab.settings].contains(appState.selectedTab) {
                // 为生成、历史和设置页面移除标题栏
                HStack {
                    Button(action: {
                        layoutService.toggleSidebar()
                        interactionService.buttonPressed()
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    #if os(iOS)
                    .hoverEffect()
                    #endif

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            } else {
                // 其他页面保持原有标题栏
                HStack {
                    Button(action: {
                        layoutService.toggleSidebar()
                        interactionService.buttonPressed()
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    #if os(iOS)
                    .hoverEffect()
                    #endif

                    Spacer()

                    Text(appState.selectedTab.title)
                        .font(.headline)
                        .themedForeground()

                    Spacer()
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                .overlay(
                    Divider(),
                    alignment: .bottom
                )
            }
        }
    }
}

/// 侧边栏视图
struct SidebarView: View {
    @Binding var selectedTab: NavigationTab
    
    var body: some View {
        List(NavigationTab.allCases, id: \.self, selection: $selectedTab) { tab in
            NavigationLink(value: tab) {
                Label {
                    Text(tab.title)
                        .font(.system(size: 14, weight: .medium))
                } icon: {
                    Image(systemName: tab.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                }
            }
            .tag(tab)
        }
        .listStyle(.sidebar)
        .navigationTitle("Icons")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("新建模板") {
                        // TODO: 实现新建模板功能
                    }
                    Button("导入模板") {
                        // TODO: 实现导入模板功能
                    }
                    Divider()
                    Button("设置") {
                        selectedTab = .settings
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .help("更多操作")
            }
        }
    }
}

/// 详情视图
struct DetailView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            switch appState.selectedTab {
            case .generate:
                PromptEditorView()
            case .templates:
                TemplateLibraryView()
            case .editor:
                PromptEditorView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            case .sfSymbols:
                // SF Symbols 浏览视图
                SFSymbolsView()
            case .results:
                IconResultsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 加载覆盖层
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("正在生成图标...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
}

// 占位符视图已移除，使用实际的视图文件

// MARK: - Preview

#Preview {
    MainNavigationView()
        .frame(width: 1000, height: 700)
}