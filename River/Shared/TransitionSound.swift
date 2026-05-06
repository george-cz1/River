//
//  TransitionSound.swift
//  River
//
//  Available transition sounds for timer phase changes
//

import Foundation

/// Available transition sounds
enum TransitionSound: String, CaseIterable, Codable {
    case chime = "gentle-chime"
    case singingBowl = "singing-bowl"
    case templeBell = "temple-bell"
    case none

    var displayName: String {
        switch self {
        case .chime:
            return "Gentle Chime"
        case .singingBowl:
            return "Singing Bowl"
        case .templeBell:
            return "Temple Bell"
        case .none:
            return "None"
        }
    }

    var icon: String {
        switch self {
        case .chime:
            return "bell.fill"
        case .singingBowl:
            return "circle.circle"
        case .templeBell:
            return "bell.and.waves.left.and.right"
        case .none:
            return "speaker.slash.fill"
        }
    }
}
