import SwiftUI

/// Native SwiftUI card component aligned with macOS 26 design guidelines
/// Uses standard GroupBox with proper material design and system colors
struct CardView<Content: View>: View {
    var title: String?
    var description: String?
    var footer: String?
    var content: Content

    @Environment(\.colorScheme) var colorScheme

    init(
        title: String? = nil,
        description: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Title and description section
                if title != nil || description != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = title {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let description = description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // Main content
                content
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Footer
                if let footer = footer {
                    Text(footer)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .groupBoxStyle(CardGroupBoxStyle())
    }
}

/// Custom GroupBox style for cards using native macOS materials
struct CardGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label (if provided)
            configuration.label
                .font(.headline)
                .foregroundStyle(Color(NSColor.labelColor))

            // Content with proper styling
            configuration.content
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            colorScheme == .dark ?
                                Material.thin :
                                Material.regular
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            colorScheme == .dark ?
                                Color.white.opacity(0.1) :
                                Color.black.opacity(0.05),
                            lineWidth: 1
                        )
                )
        }
    }
}

/// Extension to create cards with predefined styles
extension GroupBox {
    func cardStyle() -> some View {
        self.groupBoxStyle(CardGroupBoxStyle())
    }
}

// Preview
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CardView(
                title: "Card Title",
                description: "This is a card description",
                footer: "Card footer"
            ) {
                Text("Card content goes here")
                    .font(.body)
            }

            CardView(
                title: "Custom Content Card",
                description: "This card has custom content"
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This is custom content inside the card.")
                        .font(.body)

                    Button("Card Button") {
                        print("Button tapped!")
                    }
                    .primaryStyle()
                }
            }

            CardView {
                Text("Simple card with no title or description")
                    .font(.body)
            }
        }
        .padding()
        .frame(width: 400)
    }
}