//
//  ColorPickerView.swift
//  Icons
//
//  Created by Icons Team
//

import SwiftUI

/// 颜色选择器视图 - 提供直观的颜色选择体验
struct ColorPickerView: View {
    @EnvironmentObject private var themeService: ThemeService
    @EnvironmentObject private var interactionService: InteractionService

    @Binding var selectedColor: AccentColor
    @Binding var customColor: Color?

    let colorOptions: [AccentColor] = AccentColor.allCases
    @State private var showingCustomColorPicker = false
    @State private var tempCustomColor: Color = .blue
    @State private var isCustomSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("强调色")
                .font(.headline)
                .fontWeight(.medium)

            // 预定义颜色选项
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(colorOptions) { color in
                    ColorOptionView(
                        color: color.color,
                        isSelected: selectedColor == color && !isCustomSelected,
                        label: color.displayName
                    ) {
                        withAnimation(interactionService.cardHoverAnimation()) {
                            selectedColor = color
                            isCustomSelected = false
                            customColor = nil
                        }
                        interactionService.buttonPressed()
                    }
                }

                // 自定义颜色选项
                CustomColorOptionView(
                    customColor: customColor,
                    isSelected: isCustomSelected,
                    isCustomSelected: $isCustomSelected,
                    showingCustomColorPicker: $showingCustomColorPicker
                )
            }

            // 自定义颜色选择器（展开时显示）
            if showingCustomColorPicker {
                CustomColorPickerView(
                    tempCustomColor: $tempCustomColor,
                    customColor: $customColor,
                    isCustomSelected: $isCustomSelected,
                    selectedColor: $selectedColor,
                    showingCustomColorPicker: $showingCustomColorPicker
                )
                .environmentObject(themeService)
                .environmentObject(interactionService)
            }

            // 当前选中颜色预览
            if let currentColor = getCurrentColor() {
                SelectedColorPreview(
                    color: currentColor,
                    name: getCurrentColorName()
                )
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            // 检查是否有自定义颜色
            if customColor != nil {
                isCustomSelected = true
            }
        }
    }

    private func getCurrentColor() -> Color? {
        if isCustomSelected, let color = customColor {
            return color
        } else if !isCustomSelected {
            return selectedColor.color
        }
        return nil
    }

    private func getCurrentColorName() -> String {
        if isCustomSelected {
            return "自定义颜色"
        } else {
            return selectedColor.displayName
        }
    }
}

/// 颜色选项视图 - 单个颜色选项的展示
struct ColorOptionView: View {
    let color: Color
    let isSelected: Bool
    let label: String
    let action: () -> Void

    @EnvironmentObject private var interactionService: InteractionService
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color(NSColor.labelColor), lineWidth: isSelected ? 2 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(Color(NSColor.windowBackgroundColor), lineWidth: isSelected ? 3 : 0)
                        .padding(2)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .shadow(color: isSelected ? color.opacity(0.5) : Color.clear, radius: isSelected ? 8 : 0, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(interactionService.cardHoverAnimation()) {
                isHovered = hovering
            }
        }
        .help(label)
    }
}

/// 自定义颜色选项视图
struct CustomColorOptionView: View {
    let customColor: Color?
    let isSelected: Bool
    @Binding var isCustomSelected: Bool
    @Binding var showingCustomColorPicker: Bool

    @EnvironmentObject private var interactionService: InteractionService
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            withAnimation(interactionService.bounceAnimation()) {
                isCustomSelected = true
                showingCustomColorPicker.toggle()
            }
            interactionService.buttonPressed()
        }) {
            ZStack {
                Circle()
                    .fill(customColor ?? Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                if customColor == nil {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }

                Circle()
                    .strokeBorder(Color(NSColor.labelColor), lineWidth: isSelected ? 2 : 0)

                Circle()
                    .strokeBorder(Color(NSColor.windowBackgroundColor), lineWidth: isSelected ? 3 : 0)
                    .padding(2)
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .shadow(color: isSelected ? (customColor ?? Color.gray).opacity(0.5) : Color.clear,
                   radius: isSelected ? 8 : 0, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(interactionService.cardHoverAnimation()) {
                isHovered = hovering
            }
        }
        .help("自定义颜色")
    }
}

/// 自定义颜色选择器视图
struct CustomColorPickerView: View {
    @Binding var tempCustomColor: Color
    @Binding var customColor: Color?
    @Binding var isCustomSelected: Bool
    @Binding var selectedColor: AccentColor
    @Binding var showingCustomColorPicker: Bool

    @EnvironmentObject private var themeService: ThemeService
    @EnvironmentObject private var interactionService: InteractionService
    @Environment(\.colorScheme) var colorScheme
    @State private var hexString: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自定义颜色")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                // 颜色选择器
                ColorPicker("选择颜色", selection: $tempCustomColor, supportsOpacity: false)
                    .labelsHidden()

                Spacer()

                // HEX输入框
                VStack(alignment: .leading, spacing: 4) {
                    Text("HEX")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("#FFFFFF", text: $hexString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                        .onChange(of: hexString) { newValue in
                            if let color = Color(hex: newValue) {
                                tempCustomColor = color
                            }
                        }
                }
            }

            // 颜色预览
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tempCustomColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary, lineWidth: 1)
                    )

                VStack(alignment: .leading) {
                    Text("预览")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("所选颜色将应用于界面元素")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 操作按钮
                HStack(spacing: 8) {
                    Button("取消") {
                        withAnimation(interactionService.slideAnimation()) {
                            showingCustomColorPicker = false
                        }
                        interactionService.buttonPressed()
                    }
                    .secondaryStyle()

                    Button("应用") {
                        customColor = tempCustomColor
                        isCustomSelected = true
                        hexString = tempCustomColor.toHex() ?? ""

                        withAnimation(interactionService.slideAnimation()) {
                            showingCustomColorPicker = false
                        }
                        interactionService.actionCompleted()
                    }
                    .primaryStyle()
                }
            }
        }
        .padding()
        .background(
            colorScheme == .dark ?
                Material.thin :
                Material.regular
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            if let color = customColor {
                tempCustomColor = color
                hexString = color.toHex() ?? ""
            } else {
                hexString = tempCustomColor.toHex() ?? ""
            }
        }
    }
}

/// 当前选中颜色预览
struct SelectedColorPreview: View {
    let color: Color
    let name: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary, lineWidth: 1)
                )

            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            colorScheme == .dark ?
                Material.thin :
                Material.regular
        )
        .cornerRadius(8)
    }
}

// MARK: - Color 扩展
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red, green, blue: Double
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (red, green, blue) = (
                Double((rgb >> 8) * 17) / 255.0,
                Double(((rgb >> 4) & 0xF) * 17) / 255.0,
                Double((rgb & 0xF) * 17) / 255.0
            )
        case 6: // RGB (24-bit)
            (red, green, blue) = (
                Double((rgb >> 16) & 0xFF) / 255.0,
                Double((rgb >> 8) & 0xFF) / 255.0,
                Double(rgb & 0xFF) / 255.0
            )
        default:
            return nil
        }

        self.init(red: red, green: green, blue: blue)
    }

    func toHex() -> String? {
        let components = self.cgColor?.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0

        return String(format: "#%02X%02X%02X",
                     Int(r * 0xFF),
                     Int(g * 0xFF),
                     Int(b * 0xFF))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("颜色选择器组件")
            .font(.title2)
            .fontWeight(.bold)

        ColorPickerView(
            selectedColor: .constant(.blue),
            customColor: .constant(nil)
        )
        .environmentObject(ThemeService.shared)
        .environmentObject(InteractionService.shared)
    }
    .frame(width: 350, height: 400)
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
}