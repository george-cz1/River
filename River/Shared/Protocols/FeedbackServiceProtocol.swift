//
//  FeedbackServiceProtocol.swift
//  River
//
//  Protocol for abstracting platform-specific haptic and sound feedback
//

import Foundation

/// Platform-agnostic haptic style enum
enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

/// Protocol for providing haptic and sound feedback across platforms
@MainActor
protocol FeedbackServiceProtocol {
    /// Play a transition sound with optional haptic feedback
    /// - Parameter soundName: Name of the sound to play (e.g., "gentle-chime", "singing-bowl")
    func playTransitionSound(_ soundName: String?)

    /// Play a simple haptic feedback
    /// - Parameter style: The style of haptic (light, medium, heavy)
    func playHaptic(style: HapticStyle)
}

/// No-op implementation for platforms without haptic/sound support
@MainActor
class NoOpFeedbackService: FeedbackServiceProtocol {
    func playTransitionSound(_ soundName: String?) {
        // No-op
    }

    func playHaptic(style: HapticStyle) {
        // No-op
    }
}
