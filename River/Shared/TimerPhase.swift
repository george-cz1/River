import Foundation

/// Pomodoro timer phase
enum TimerPhase: String, Codable, Hashable, Sendable {
    case idle
    case work
    case shortBreak
    case longBreak

    var displayName: String {
        switch self {
        case .idle: return "Focus"
        case .work: return "Working"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var isBreak: Bool {
        self == .shortBreak || self == .longBreak
    }
}
