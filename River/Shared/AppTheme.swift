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

// MARK: - App Theme

/// Available color themes for the app
enum AppTheme: String, CaseIterable, Codable {
    case river
    case forest
    case sunset
    case ocean
    case stone

    var displayName: String {
        switch self {
        case .river:
            return "River"
        case .forest:
            return "Forest"
        case .sunset:
            return "Sunset"
        case .ocean:
            return "Ocean"
        case .stone:
            return "Stone"
        }
    }

    var accentColor: Color {
        switch self {
        case .river:
            return Color(hex: "2D5A6B")
        case .forest:
            return Color(hex: "4A6B4A")
        case .sunset:
            return Color(hex: "8B5A3C")
        case .ocean:
            return Color(hex: "3A5A8B")
        case .stone:
            return Color(hex: "5A5A5A")
        }
    }

    var softColor: Color {
        switch self {
        case .river:
            return Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: "1A3A48")
                    : UIColor(hex: "E8F4F7")
            })
        case .forest:
            return Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: "2A3A2A")
                    : UIColor(hex: "E8F4E8")
            })
        case .sunset:
            return Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: "3A2A1C")
                    : UIColor(hex: "FFF4E8")
            })
        case .ocean:
            return Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: "1A2A3A")
                    : UIColor(hex: "E8F0FF")
            })
        case .stone:
            return Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: "2A2A2A")
                    : UIColor(hex: "F0F0F0")
            })
        }
    }

    var icon: String {
        switch self {
        case .river:
            return "drop.fill"
        case .forest:
            return "leaf.fill"
        case .sunset:
            return "sun.horizon.fill"
        case .ocean:
            return "water.waves"
        case .stone:
            return "circle.fill"
        }
    }
}

// MARK: - Theme Manager

@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let storageKey = "selectedTheme"

    var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }

    private init() {
        // Try App Group first, then local UserDefaults
        if let savedTheme = AppGroup.userDefaults?.string(forKey: SharedDataKey.selectedTheme),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else if let savedTheme = UserDefaults.standard.string(forKey: storageKey),
                  let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .river
        }
    }

    private func saveTheme() {
        // Save to both local and App Group
        UserDefaults.standard.set(currentTheme.rawValue, forKey: storageKey)
        AppGroup.userDefaults?.set(currentTheme.rawValue, forKey: SharedDataKey.selectedTheme)
    }
}

// MARK: - Shared Theme Helper

/// Helper for reading theme in widget (non-MainActor)
enum SharedTheme {
    static func current() -> AppTheme {
        if let rawValue = AppGroup.userDefaults?.string(forKey: SharedDataKey.selectedTheme),
           let theme = AppTheme(rawValue: rawValue) {
            return theme
        }
        return .river // default
    }
}
