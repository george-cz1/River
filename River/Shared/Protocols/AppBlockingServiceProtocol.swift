//
//  AppBlockingServiceProtocol.swift
//  River
//
//  Protocol for abstracting app blocking functionality (Family Controls on iOS)
//

import Foundation

/// Protocol for managing app blocking during focus sessions
@MainActor
protocol AppBlockingServiceProtocol {
    /// Start blocking apps for a focus session
    func startBlocking()

    /// Stop blocking apps (end of focus session)
    func stopBlocking()

    /// Check if app blocking is currently active
    var isBlocking: Bool { get }

    /// Check if any apps are configured for blocking
    var hasAppsConfigured: Bool { get }
}

/// No-op implementation for platforms without app blocking support
@MainActor
class NoOpAppBlockingService: AppBlockingServiceProtocol {
    func startBlocking() {
        // No-op
    }

    func stopBlocking() {
        // No-op
    }

    var isBlocking: Bool { false }

    var hasAppsConfigured: Bool { false }
}
