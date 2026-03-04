import SwiftUI
import UIKit

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        r = CGFloat((int >> 16) & 0xFF) / 255
        g = CGFloat((int >> 8) & 0xFF) / 255
        b = CGFloat(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - App Colors

enum AppColors {
    // Primary - Dynamic based on selected theme
    @MainActor static var river: Color {
        ThemeManager.shared.currentTheme.accentColor
    }

    static let stone = Color(hex: "6B7B7C")

    // Adaptive colors - Dynamic based on selected theme
    @MainActor static var riverSoft: Color {
        ThemeManager.shared.currentTheme.softColor
    }

    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "0F1E24")
            : UIColor(hex: "F4F8F9")
    })

    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1A2F38")
            : UIColor(hex: "FFFEFB")
    })

    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "E8F4F7")
            : UIColor(hex: "1E3A4C")
    })

    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "8BA5B5")
            : UIColor(hex: "5A7A8C")
    })

    static let border = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "2D4A55")
            : UIColor(hex: "D8E4E8")
    })

    // States (same in both modes - accent colors)
    static let completed = Color(hex: "8E8E93")
    static let destructive = Color(hex: "C97064")
    static let success = Color(hex: "4A8B9C")
    static let breakPhase = Color(hex: "4A8B9C")
    @MainActor static var workPhase: Color { river }

    // Legacy aliases
    @MainActor static var sage: Color { river }
    @MainActor static var sageSoft: Color { riverSoft }
    @MainActor static var focusBlue: Color { river }
    @MainActor static var focusBlueSoft: Color { riverSoft }
    static let sand = stone
}

// MARK: - App Typography

enum AppFonts {
    // Timer display - Cormorant Garamond for elegant, flowing zen aesthetic
    static func timerDisplay(size: CGFloat = 64) -> Font {
        .custom("CormorantGaramond-Light", size: size)
    }

    // Body typography - Nunito for warm, approachable UI
    static let title = Font.custom("Nunito-SemiBold", size: 22)
    static let headline = Font.custom("Nunito-Medium", size: 17)
    static let body = Font.custom("Nunito-Regular", size: 17)
    static let caption = Font.custom("Nunito-Regular", size: 12)
    static let caption2 = Font.custom("Nunito-Regular", size: 11)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppColors.sage
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundStyle(AppColors.surface)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GhostButtonStyle: ButtonStyle {
    var color: Color = AppColors.sage

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(color.opacity(configuration.isPressed ? 0.06 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
