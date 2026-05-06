//
//  PlatformCapabilities.swift
//  River
//
//  Platform feature detection and capability checking
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

/// Provides compile-time and runtime checks for platform-specific features
struct PlatformCapabilities {
    /// Whether the current platform supports Live Activities (Dynamic Island, Lock Screen)
    static var supportsLiveActivities: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform supports Family Controls (Screen Time) app blocking
    static var supportsFamilyControls: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform supports haptic feedback
    static var supportsHaptics: Bool {
        #if os(iOS)
        return true
        #elseif os(watchOS)
        return true
        #elseif os(macOS)
        return true  // macOS has NSHapticFeedbackManager
        #else
        return false
        #endif
    }

    /// Whether the current platform supports audio playback
    static var supportsAudio: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        return true
        #elseif os(watchOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform supports CloudKit sync
    static var supportsCloudKit: Bool {
        #if os(iOS) || os(macOS) || os(watchOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform supports App Groups for data sharing
    static var supportsAppGroups: Bool {
        #if os(iOS) || os(macOS) || os(watchOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform supports NSUbiquitousKeyValueStore for settings sync
    static var supportsKeyValueStore: Bool {
        #if os(iOS) || os(macOS) || os(watchOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the current platform supports Darwin notifications for cross-process communication
    static var supportsDarwinNotifications: Bool {
        #if os(watchOS)
        return false  // watchOS doesn't support CFNotificationCenter
        #else
        return true
        #endif
    }

    /// The current platform name for logging and debugging
    static var platformName: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(visionOS)
        return "visionOS"
        #else
        return "Unknown"
        #endif
    }

    /// Device identifier for tracking which device created records
    static var deviceIdentifier: String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-ios"
        #elseif os(macOS)
        // macOS doesn't have identifierForVendor, use host name
        return ProcessInfo.processInfo.hostName
        #elseif os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor?.uuidString ?? "unknown-watchos"
        #else
        return "unknown-device"
        #endif
    }
}
