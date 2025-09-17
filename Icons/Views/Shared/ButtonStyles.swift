import SwiftUI

/// Native SwiftUI button styles aligned with macOS 26 design guidelines
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlSize) var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView(configuration: configuration))
            .foregroundColor(foregroundColor(configuration: configuration))
            .font(.body.weight(.medium))
            .cornerRadius(cornerRadius)
    }

    private var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 12
        case .small:
            return 16
        case .large:
            return 24
        case .regular:
            fallthrough
        default:
            return 20
        }
    }

    private var verticalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 14
        case .regular:
            fallthrough
        default:
            return 10
        }
    }

    private var cornerRadius: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 10
        case .regular:
            fallthrough
        default:
            return 8
        }
    }

    private func backgroundView(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(configuration.isPressed ?
                Color.accentColor.opacity(colorScheme == .dark ? 0.8 : 0.9) :
                Color.accentColor)
            .shadow(color: Color.black.opacity(0.1), radius: configuration.isPressed ? 1 : 2, x: 0, y: configuration.isPressed ? 0 : 1)
    }

    private func foregroundColor(configuration: Configuration) -> Color {
        return colorScheme == .dark ? .black : .white
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlSize) var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView(configuration: configuration))
            .foregroundColor(foregroundColor(configuration: configuration))
            .font(.body.weight(.medium))
            .cornerRadius(cornerRadius)
    }

    private var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 12
        case .small:
            return 16
        case .large:
            return 24
        case .regular:
            fallthrough
        default:
            return 20
        }
    }

    private var verticalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 14
        case .regular:
            fallthrough
        default:
            return 10
        }
    }

    private var cornerRadius: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 10
        case .regular:
            fallthrough
        default:
            return 8
        }
    }

    private func backgroundView(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(configuration.isPressed ?
                Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2) :
                Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
    }

    private func foregroundColor(configuration: Configuration) -> Color {
        return configuration.isPressed ?
            Color.accentColor.opacity(colorScheme == .dark ? 0.8 : 0.7) :
            Color.accentColor
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlSize) var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView(configuration: configuration))
            .foregroundColor(foregroundColor(configuration: configuration))
            .font(.body.weight(.medium))
            .cornerRadius(cornerRadius)
    }

    private var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 12
        case .small:
            return 16
        case .large:
            return 24
        case .regular:
            fallthrough
        default:
            return 20
        }
    }

    private var verticalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 14
        case .regular:
            fallthrough
        default:
            return 10
        }
    }

    private var cornerRadius: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 10
        case .regular:
            fallthrough
        default:
            return 8
        }
    }

    private func backgroundView(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(configuration.isPressed ?
                Color.red.opacity(colorScheme == .dark ? 0.8 : 0.9) :
                Color.red)
            .shadow(color: Color.black.opacity(0.1), radius: configuration.isPressed ? 1 : 2, x: 0, y: configuration.isPressed ? 0 : 1)
    }

    private func foregroundColor(configuration: Configuration) -> Color {
        return colorScheme == .dark ? .black : .white
    }
}

struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlSize) var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView(configuration: configuration))
            .foregroundColor(foregroundColor(configuration: configuration))
            .font(.body.weight(.medium))
            .cornerRadius(cornerRadius)
    }

    private var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 12
        case .small:
            return 16
        case .large:
            return 24
        case .regular:
            fallthrough
        default:
            return 20
        }
    }

    private var verticalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 14
        case .regular:
            fallthrough
        default:
            return 10
        }
    }

    private var cornerRadius: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 10
        case .regular:
            fallthrough
        default:
            return 8
        }
    }

    private func backgroundView(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(configuration.isPressed ?
                        Color.accentColor.opacity(0.7) :
                        Color.primary.opacity(colorScheme == .dark ? 0.5 : 0.3),
                        lineWidth: 1)
            )
    }

    private func foregroundColor(configuration: Configuration) -> Color {
        return configuration.isPressed ?
            Color.accentColor.opacity(colorScheme == .dark ? 0.8 : 0.7) :
            Color.accentColor
    }
}

struct GhostButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlSize) var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView(configuration: configuration))
            .foregroundColor(foregroundColor(configuration: configuration))
            .font(.body.weight(.medium))
            .cornerRadius(cornerRadius)
    }

    private var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 12
        case .small:
            return 16
        case .large:
            return 24
        case .regular:
            fallthrough
        default:
            return 20
        }
    }

    private var verticalPadding: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 14
        case .regular:
            fallthrough
        default:
            return 10
        }
    }

    private var cornerRadius: CGFloat {
        switch controlSize {
        case .mini:
            return 4
        case .small:
            return 6
        case .large:
            return 10
        case .regular:
            fallthrough
        default:
            return 8
        }
    }

    private func backgroundView(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(configuration.isPressed ?
                Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1) :
                Color.clear)
    }

    private func foregroundColor(configuration: Configuration) -> Color {
        return configuration.isPressed ?
            Color.accentColor.opacity(colorScheme == .dark ? 0.8 : 0.7) :
            Color.accentColor
    }
}

// Extension to make it easier to apply button styles
extension Button {
    func primaryStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    func secondaryStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }

    func destructiveStyle() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }

    func outlineStyle() -> some View {
        self.buttonStyle(OutlineButtonStyle())
    }

    func ghostStyle() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }
}