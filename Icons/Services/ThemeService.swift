//
//  ThemeService.swift
//  Icons
//
//  Created by Icons App on 2024/01/15.
//

import SwiftUI
import Combine

// MARK: - Theme Service
class ThemeService: ObservableObject {
    static let shared = ThemeService()
    
    @Published var currentTheme: AppTheme = .system
    @Published var accentColor: AccentColor = .blue
    @Published var customColors: CustomColorScheme = CustomColorScheme()
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme"
    private let accentColorKey = "accent_color"
    private let customColorsKey = "custom_colors"
    
    private init() {
        loadThemeSettings()
    }
    
    // MARK: - Public Methods
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveThemeSettings()
    }
    
    func setAccentColor(_ color: AccentColor) {
        accentColor = color
        saveThemeSettings()
    }
    
    func updateCustomColors(_ colors: CustomColorScheme) {
        customColors = colors
        saveThemeSettings()
    }
    
    func getColorScheme() -> ColorScheme? {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func loadThemeSettings() {
        // Load theme
        if let themeRawValue = userDefaults.object(forKey: themeKey) as? String,
           let theme = AppTheme(rawValue: themeRawValue) {
            currentTheme = theme
        }
        
        // Load accent color
        if let accentRawValue = userDefaults.object(forKey: accentColorKey) as? String,
           let accent = AccentColor(rawValue: accentRawValue) {
            accentColor = accent
        }
        
        // Load custom colors
        if let customColorsData = userDefaults.data(forKey: customColorsKey),
           let colors = try? JSONDecoder().decode(CustomColorScheme.self, from: customColorsData) {
            customColors = colors
        }
    }
    
    private func saveThemeSettings() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
        userDefaults.set(accentColor.rawValue, forKey: accentColorKey)
        
        if let customColorsData = try? JSONEncoder().encode(customColors) {
            userDefaults.set(customColorsData, forKey: customColorsKey)
        }
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Accent Color
enum AccentColor: String, CaseIterable, Identifiable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case mint = "mint"
    case teal = "teal"
    case cyan = "cyan"
    case indigo = "indigo"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blue: return "蓝色"
        case .purple: return "紫色"
        case .pink: return "粉色"
        case .red: return "红色"
        case .orange: return "橙色"
        case .yellow: return "黄色"
        case .green: return "绿色"
        case .mint: return "薄荷绿"
        case .teal: return "青色"
        case .cyan: return "青蓝色"
        case .indigo: return "靛蓝色"
        }
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .indigo: return .indigo
        }
    }
}

// MARK: - Custom Color Scheme
struct CustomColorScheme: Codable {
    var primaryColor: String = "#007AFF"
    var secondaryColor: String = "#5856D6"
    var backgroundColor: String = "#F2F2F7"
    var surfaceColor: String = "#FFFFFF"
    var textColor: String = "#000000"
    var secondaryTextColor: String = "#8E8E93"
    var customAccentColor: String? = nil
    
    // Convert hex string to Color
    func color(from hex: String) -> Color {
        // 使用ColorPickerView中定义的扩展方法
        if let color = try? Color(hex: hex) {
            return color
        }
        return Color.primary // fallback color
    }
    
    var primary: Color { color(from: primaryColor) }
    var secondary: Color { color(from: secondaryColor) }
    var background: Color { color(from: backgroundColor) }
    var surface: Color { color(from: surfaceColor) }
    var text: Color { color(from: textColor) }
    var secondaryText: Color { color(from: secondaryTextColor) }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeService.shared
}

// MARK: - ThemeService Extensions
extension ThemeService {
    /// Get appropriate material based on current theme and color scheme
    func getAppropriateMaterial() -> Material {
        switch (currentTheme, getColorScheme()) {
        case (.dark, _), (_, .dark):
            return Material.thin
        default:
            return Material.regular
        }
    }

    /// Get appropriate background color based on current theme
    func getBackgroundColor() -> Color {
        switch (currentTheme, getColorScheme()) {
        case (.dark, _), (_, .dark):
            return Color(NSColor.windowBackgroundColor)
        default:
            return Color(NSColor.windowBackgroundColor)
        }
    }

    /// Get appropriate text color based on current theme
    func getPrimaryTextColor() -> Color {
        switch (currentTheme, getColorScheme()) {
        case (.dark, _), (_, .dark):
            return Color(NSColor.labelColor)
        default:
            return Color(NSColor.labelColor)
        }
    }

    /// Get appropriate secondary text color
    func getSecondaryTextColor() -> Color {
        switch (currentTheme, getColorScheme()) {
        case (.dark, _), (_, .dark):
            return Color(NSColor.secondaryLabelColor)
        default:
            return Color(NSColor.secondaryLabelColor)
        }
    }
}

extension EnvironmentValues {
    var themeService: ThemeService {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func themedBackground() -> some View {
        self.background(Color(NSColor.windowBackgroundColor))
    }

    func themedForeground() -> some View {
        self.foregroundColor(Color(NSColor.labelColor))
    }

    func themedSecondaryForeground() -> some View {
        self.foregroundColor(Color(NSColor.secondaryLabelColor))
    }

    func themedCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.regular)
            )
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    func accentColor(_ themeService: ThemeService) -> some View {
        self.accentColor(themeService.getCurrentAccentColor())
    }
}

extension ThemeService {
    func getCurrentAccentColor() -> Color {
        if let customHex = customColors.customAccentColor,
           let customColor = try? Color(hex: customHex) {
            return customColor
        }
        return accentColor.color
    }

    func setCustomAccentColor(_ color: Color?) {
        if let color = color,
           let hex = color.toHex() {
            customColors.customAccentColor = hex
        } else {
            customColors.customAccentColor = nil
        }
        saveThemeSettings()
    }
}