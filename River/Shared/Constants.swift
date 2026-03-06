import Foundation

// MARK: - Timer Defaults

/// Default durations and settings for the Pomodoro timer
enum TimerDefaults {
    /// Default work duration in seconds (25 minutes)
    static let workDuration = 25 * 60

    /// Default short break duration in seconds (5 minutes)
    static let shortBreakDuration = 5 * 60

    /// Default long break duration in seconds (15 minutes)
    static let longBreakDuration = 15 * 60

    /// Default number of pomodoros before a long break
    static let pomodorosBeforeLongBreak = 4
}

// MARK: - UserDefaults Keys

/// Centralized UserDefaults storage keys
enum UserDefaultsKeys {
    // Timer Settings
    static let workDuration = "workDuration"
    static let shortBreakDuration = "shortBreakDuration"
    static let longBreakDuration = "longBreakDuration"
    static let pomodorosBeforeLongBreak = "pomodorosBeforeLongBreak"

    // Sound Settings
    static let transitionSound = "transitionSound"
    static let hapticsEnabled = "hapticsEnabled"

    // Theme
    static let selectedTheme = "selectedTheme"

    // History
    static let sessionHistory = "sessionHistory"
}

// MARK: - Darwin Notification Names

/// Cross-process notification names for App Group communication
enum NotificationNames {
    /// Posted when timer state changes (app <-> widget sync)
    static let timerStateChanged = "com.george.evolve.timerStateChanged"
}
