import SwiftUI
import AppKit

/// 对比度检查工具，用于确保文本在背景上有足够的可读性
struct ContrastChecker {
    /// 计算两种颜色之间的对比度比率
    /// - Parameters:
    ///   - textColor: 文本颜色
    ///   - backgroundColor: 背景颜色
    /// - Returns: 对比度比率 (通常 4.5:1 为最小可接受值，7:1 为增强可读性)
    static func contrastRatio(between textColor: Color, and backgroundColor: Color) -> Double {
        let textLuminance = relativeLuminance(of: textColor)
        let backgroundLuminance = relativeLuminance(of: backgroundColor)

        let lighter = max(textLuminance, backgroundLuminance)
        let darker = min(textLuminance, backgroundLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// 计算颜色的相对亮度
    /// - Parameter color: 要计算亮度的颜色
    /// - Returns: 相对亮度值 (0-1)
    static func relativeLuminance(of color: Color) -> Double {
        // 将 SwiftUI Color 转换为 RGB 组件
        let components = color.components
        let r = components.red
        let g = components.green
        let b = components.blue

        // 转换为线性 RGB 值
        let rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
        let bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)

        // 计算相对亮度
        return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear
    }

    /// 检查对比度是否满足 WCAG 标准
    /// - Parameters:
    ///   - textColor: 文本颜色
    ///   - backgroundColor: 背景颜色
    ///   - isLargeText: 是否为大号文本 (通常 ≥18pt 或 ≥14pt 粗体)
    /// - Returns: 是否满足对比度要求
    static func meetsWCAGStandards(textColor: Color, backgroundColor: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(between: textColor, and: backgroundColor)
        let minimumRatio = isLargeText ? 3.0 : 4.5  // 大号文本 3:1，普通文本 4.5:1
        return ratio >= minimumRatio
    }

    /// 获取推荐的文本颜色以确保足够的对比度
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - preferredColor: 首选文本颜色
    ///   - isLargeText: 是否为大号文本
    /// - Returns: 满足对比度要求的文本颜色
    static func recommendedTextColor(for backgroundColor: Color, preferredColor: Color, isLargeText: Bool = false) -> Color {
        // 如果首选颜色已经满足对比度要求，直接返回
        if meetsWCAGStandards(textColor: preferredColor, backgroundColor: backgroundColor, isLargeText: isLargeText) {
            return preferredColor
        }

        // 否则，尝试黑色和白色，选择对比度更好的
        let blackContrast = contrastRatio(between: .black, and: backgroundColor)
        let whiteContrast = contrastRatio(between: .white, and: backgroundColor)

        let minimumRatio = isLargeText ? 3.0 : 4.5
        if blackContrast >= minimumRatio && blackContrast >= whiteContrast {
            return .black
        } else if whiteContrast >= minimumRatio {
            return .white
        } else {
            // 如果黑白都不满足要求，返回对比度更好的那个
            return blackContrast >= whiteContrast ? .black : .white
        }
    }
}

// 扩展 Color 以获取 RGB 组件
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        // 使用更安全的方法从 SwiftUI.Color 创建 NSColor
        let nsColor = NSColor(self)
        // 确保颜色在 RGB 颜色空间中，以防止 getRed:green:blue:alpha: 崩溃
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            // 如果转换失败，尝试通过 CGColor 创建 NSColor
            if let cgColor = self.cgColor {
                let fallbackNSColor = NSColor(cgColor: cgColor)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var opacity: CGFloat = 0

                // 尝试从回退颜色获取组件
                if fallbackNSColor.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &opacity) ?? false {
                    return (Double(red), Double(green), Double(blue), Double(opacity))
                }

                // 如果上面的方法失败，直接使用原始颜色
                fallbackNSColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
                return (Double(red), Double(green), Double(blue), Double(opacity))
            }

            // 最后的回退方案
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var opacity: CGFloat = 0

            nsColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
            return (Double(red), Double(green), Double(blue), Double(opacity))
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0

        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)

        return (Double(red), Double(green), Double(blue), Double(opacity))
    }
}

// 扩展 View 以添加对比度检查修饰符
extension View {
    /// 确保文本在 Liquid Glass 背景上有足够的对比度
    /// - Parameters:
    ///   - textColor: 原始文本颜色
    ///   - backgroundColor: 背景颜色
    ///   - isLargeText: 是否为大号文本
    /// - Returns: 具有适当对比度的视图
    func ensureContrast(textColor: Color, backgroundColor: Color, isLargeText: Bool = false) -> some View {
        let recommendedColor = ContrastChecker.recommendedTextColor(
            for: backgroundColor,
            preferredColor: textColor,
            isLargeText: isLargeText
        )

        return self.foregroundColor(recommendedColor)
    }
}