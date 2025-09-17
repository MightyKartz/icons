//
//  InteractiveFeedbackView.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI

/// 动画控制面板 - 集中管理应用动画设置
struct AnimationControlPanel: View {
    @EnvironmentObject private var interactionService: InteractionService
    @EnvironmentObject private var themeService: ThemeService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("动画设置")
                .font(.headline)
                .fontWeight(.medium)

            // 动画开关
            Toggle("启用动画效果", isOn: $interactionService.isAnimationEnabled)
                .toggleStyle(SwitchToggleStyle())

            // 动画速度控制
            if interactionService.isAnimationEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("动画速度")
                        .font(.subheadline)

                    Picker("动画速度", selection: $interactionService.animationSpeed) {
                        ForEach(AnimationSpeed.allCases) { speed in
                            Text(speed.displayLabel).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            // 反馈设置
            VStack(alignment: .leading, spacing: 8) {
                Text("交互反馈")
                    .font(.subheadline)

                Toggle("启用触觉反馈", isOn: $interactionService.hapticFeedbackEnabled)
                Toggle("启用音效", isOn: $interactionService.soundEffectsEnabled)
            }

            // 动画预览
            VStack(alignment: .leading, spacing: 12) {
                Text("效果预览")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Divider()

                HStack(spacing: 20) {
                    // 按钮按压效果预览
                    InteractiveFeedbackView(
                        feedbackType: .buttonPress,
                        label: "按钮",
                        action: {
                            interactionService.buttonPressed()
                        }
                    )

                    // 悬停效果预览
                    InteractiveFeedbackView(
                        feedbackType: .hover,
                        label: "悬停",
                        action: {
                            // 悬停效果在 onMouseInside 中处理
                        }
                    )

                    // 加载动画预览
                    InteractiveFeedbackView(
                        feedbackType: .loading,
                        label: "加载",
                        action: {
                            // 加载状态由 isLoading 控制
                        }
                    )
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

/// 交互动效视图 - 提供按钮按压、悬停、加载动画等效果
struct InteractiveFeedbackView: View {
    enum FeedbackType {
        case buttonPress
        case hover
        case loading
    }

    let feedbackType: FeedbackType
    let label: String
    let action: () -> Void

    @EnvironmentObject private var interactionService: InteractionService
    @EnvironmentObject private var themeService: ThemeService
    @State private var isHovered = false
    @State private var isLoading = false

    var body: some View {
        Button(action: {
            // 根据反馈类型执行相应操作
            switch feedbackType {
            case .buttonPress:
                withAnimation(interactionService.cardHoverAnimation()) {
                    action()
                }
                interactionService.buttonPressed()
            case .loading:
                isLoading.toggle()
                action()
            default:
                action()
            }
        }) {
            VStack(spacing: 6) {
                // 根据反馈类型显示不同图标
                switch feedbackType {
                case .buttonPress:
                    Image(systemName: "hand.tap")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeService.accentColor.color)
                case .hover:
                    Image(systemName: "cursor.rays")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeService.accentColor.color)
                case .loading:
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeService.accentColor.color)
                    }
                }

                Text(label)
                    .font(.caption2)
                    .foregroundColor(textColor)
            }
            .frame(width: 60, height: 60)
            .background(backgroundView)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if feedbackType == .hover {
                withAnimation(interactionService.cardHoverAnimation()) {
                    isHovered = hovering
                }
            }
        }
        .scaleEffect(scaleEffect)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        switch feedbackType {
        case .buttonPress:
            return isHovered ? themeService.accentColor.color.opacity(0.1) : Color.clear
        case .hover:
            return isHovered ? themeService.accentColor.color.opacity(0.15) : Color.clear
        case .loading:
            return isLoading ? themeService.accentColor.color.opacity(0.1) : Color.clear
        }
    }

    private var borderColor: Color {
        switch feedbackType {
        case .buttonPress:
            return isHovered ? themeService.accentColor.color : Color.secondary.opacity(0.5)
        case .hover:
            return isHovered ? themeService.accentColor.color : Color.secondary.opacity(0.5)
        case .loading:
            return isLoading ? themeService.accentColor.color : Color.secondary.opacity(0.5)
        }
    }

    private var textColor: Color {
        switch feedbackType {
        case .buttonPress:
            return isHovered ? themeService.accentColor.color : Color.primary
        case .hover:
            return isHovered ? themeService.accentColor.color : Color.primary
        case .loading:
            return isLoading ? themeService.accentColor.color : Color.primary
        }
    }

    private var scaleEffect: CGFloat {
        switch feedbackType {
        case .buttonPress:
            return isHovered ? 1.05 : 1.0
        case .hover:
            return isHovered ? 1.1 : 1.0
        case .loading:
            return isLoading ? 0.95 : 1.0
        }
    }
}

// MARK: - AnimationSpeed 显示名称
extension AnimationSpeed {
    var displayLabel: String {
        switch self {
        case .slow: return "慢速"
        case .normal: return "标准"
        case .fast: return "快速"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("交互动效组件")
            .font(.title2)
            .fontWeight(.bold)

        // 动画控制面板预览
        AnimationControlPanel()
            .environmentObject(InteractionService.shared)
            .environmentObject(ThemeService.shared)
            .frame(height: 350)

        // 交互动效预览
        HStack(spacing: 20) {
            InteractiveFeedbackView(
                feedbackType: .buttonPress,
                label: "按钮",
                action: {
                    print("按钮按压效果")
                }
            )
            .environmentObject(InteractionService.shared)
            .environmentObject(ThemeService.shared)

            InteractiveFeedbackView(
                feedbackType: .hover,
                label: "悬停",
                action: {
                    print("悬停效果")
                }
            )
            .environmentObject(InteractionService.shared)
            .environmentObject(ThemeService.shared)

            InteractiveFeedbackView(
                feedbackType: .loading,
                label: "加载",
                action: {
                    print("加载动画")
                }
            )
            .environmentObject(InteractionService.shared)
            .environmentObject(ThemeService.shared)
        }
    }
    .frame(width: 400, height: 300)
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}