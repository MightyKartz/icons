//
//  SharedComponents.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI

// Import custom components
import Foundation

/// 分类芯片
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// 主题切换视图 - 提供直观的主题切换体验
struct ThemeToggleView: View {
    @EnvironmentObject private var themeService: ThemeService
    @EnvironmentObject private var interactionService: InteractionService
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.allCases) { theme in
                ThemeToggleButton(
                    theme: theme,
                    isSelected: themeService.currentTheme == theme
                ) {
                    withAnimation(interactionService.buttonPressAnimation()) {
                        themeService.setTheme(theme)
                    }
                    interactionService.buttonPressed()
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .dark ?
                        Material.thin :
                        Material.regular
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

/// 主题切换按钮 - 单个主题选项按钮 (使用 SwiftCN-UI)
struct ThemeToggleButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject private var interactionService: InteractionService
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    private var iconColor: Color {
        switch theme {
        case .light:
            return .orange
        case .dark:
            return .indigo
        case .system:
            return .blue
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)

                Text(theme.displayName)
                    .font(.caption2)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 50, height: 50)
        .background(backgroundView)
        .cornerRadius(8)
        .accessibilityLabel(theme.displayName)
        .accessibilityHint("选择\(theme.displayName)主题")
        .accessibilityValue(isSelected ? "已选择" : "未选择")
        .onHover { hovering in
            withAnimation(interactionService.scaleAnimation()) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 0)
            )
    }

    private var backgroundColor: Color {
        if isSelected {
            return iconColor.opacity(colorScheme == .dark ? 0.3 : 0.25)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(colorScheme == .dark ? 0.15 : 0.12)
        } else {
            return colorScheme == .dark ?
                Material.thin :
                Material.regular
        }
    }

    private var borderColor: Color {
        isSelected ? iconColor : Color.clear
    }
}

// MARK: - SwiftCN-UI 示例组件

/// 简单卡片示例 - 展示如何使用 SwiftCN-UI 的 CardView 组件
struct SimpleCardExample: View {
    var body: some View {
        CardView(
            title: "SwiftCN-UI 卡片示例",
            description: "这是一个使用 SwiftCN-UI CardView 组件创建的示例卡片。",
            footer: "卡片底部信息"
        ) {
            Text("CardView 组件支持标题、描述和自定义内容区域，非常适合展示各种类型的信息。")
        }
    }
}

/// 自定义内容卡片示例
struct CustomContentCardExample: View {
    var body: some View {
        CardView(
            title: "自定义内容卡片",
            description: "这个卡片展示了如何使用自定义内容视图。"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("自定义内容区域")
                        .font(.headline)
                    Spacer()
                }

                Text("在这个区域，您可以添加任何自定义的 SwiftUI 视图内容。")
                    .font(.body)
                    .foregroundColor(.secondary)

                HStack {
                    Button("操作按钮") {
                        print("按钮被点击")
                    }
                    .primaryStyle()

                    Spacer()
                }
            }
        }
    }
}