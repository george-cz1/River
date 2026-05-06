//
//  LiveActivityServiceProtocol.swift
//  River
//
//  Protocol for abstracting Live Activities (iOS-specific)
//

import Foundation

/// Protocol for managing Live Activities
@MainActor
protocol LiveActivityServiceProtocol {
    /// Start or update a Live Activity with current timer state
    /// - Parameters:
    ///   - phase: Current timer phase
    ///   - remainingSeconds: Seconds remaining in current phase
    ///   - isRunning: Whether the timer is actively running
    ///   - currentTaskTitle: Title of the current task (optional)
    func startOrUpdateActivity(
        phase: TimerPhase,
        remainingSeconds: Int,
        isRunning: Bool,
        currentTaskTitle: String?
    )

    /// End the current Live Activity
    func endActivity()

    /// Check if Live Activities are currently active
    var hasActiveActivity: Bool { get }
}

/// No-op implementation for platforms without Live Activity support
@MainActor
class NoOpLiveActivityService: LiveActivityServiceProtocol {
    func startOrUpdateActivity(
        phase: TimerPhase,
        remainingSeconds: Int,
        isRunning: Bool,
        currentTaskTitle: String?
    ) {
        // No-op
    }

    func endActivity() {
        // No-op
    }

    var hasActiveActivity: Bool { false }
}
