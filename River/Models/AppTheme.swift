import SwiftUI

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
        if let savedTheme = UserDefaults.standard.string(forKey: storageKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .river
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: storageKey)
    }
}
