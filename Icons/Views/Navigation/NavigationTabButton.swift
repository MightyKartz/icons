//
//  NavigationTabButton.swift
//  Icons
//
//  Created by Icons App on 2024/01/15.
//

import SwiftUI

struct NavigationTabButton: View {
    @EnvironmentObject private var themeService: ThemeService
    @EnvironmentObject private var interactionService: InteractionService
    
    let tab: NavigationTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, height: 20)
                    .foregroundColor(iconColor)
                
                Text(tab.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(themeService.accentColor.color)
                        .frame(width: 6, height: 6)
                        .scaleIn(isVisible: isSelected)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundView)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(interactionService.cardHoverAnimation()) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(interactionService.cardHoverAnimation(), value: isHovered)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 1 : 0)
            )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return themeService.accentColor.color.opacity(0.15)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.08)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        isSelected ? themeService.accentColor.color.opacity(0.3) : Color.clear
    }
    
    private var iconColor: Color {
        if isSelected {
            return themeService.accentColor.color
        } else if isHovered {
            return Color(NSColor.labelColor)
        } else {
            return Color(NSColor.secondaryLabelColor)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return Color(NSColor.labelColor)
        } else if isHovered {
            return Color(NSColor.labelColor)
        } else {
            return Color(NSColor.secondaryLabelColor)
        }
    }
}

// MARK: - Preview
struct NavigationTabButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            NavigationTabButton(
                tab: .editor,
                isSelected: true
            ) {
                print("Editor selected")
            }
            
            NavigationTabButton(
                tab: .templates,
                isSelected: false
            ) {
                print("Templates selected")
            }
            
            NavigationTabButton(
                tab: .sfSymbols,
                isSelected: false
            ) {
                print("SF Symbols selected")
            }
        }
        .padding()
        .frame(width: 250)
        .background(Color(NSColor.windowBackgroundColor))
        .environmentObject(ThemeService.shared)
        .environmentObject(InteractionService.shared)
    }
}