//
//  CloudSettingsManager.swift
//  River
//
//  Manages syncing of user settings across devices via NSUbiquitousKeyValueStore
//

import Foundation

/// Settings that should be synced across devices via iCloud
@MainActor
@Observable
final class CloudSettingsManager {
    static let shared = CloudSettingsManager()

    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let localStore = UserDefaults.standard

    // Settings keys that should be synced
    private let syncedKeys: Set<String> = [
        UserDefaultsKeys.workDuration,
        UserDefaultsKeys.shortBreakDuration,
        UserDefaultsKeys.longBreakDuration,
        UserDefaultsKeys.pomodorosBeforeLongBreak,
        UserDefaultsKeys.selectedTheme,
        UserDefaultsKeys.transitionSound,
        UserDefaultsKeys.hapticsEnabled
    ]

    private init() {
        setupNotifications()
        syncFromCloud()
    }

    // MARK: - Setup

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )

        // Synchronize on init
        cloudStore.synchronize()
    }

    // MARK: - Cloud Change Handler

    @objc private func cloudStoreDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }

        print("☁️ CloudSettingsManager: Settings changed externally: \(changedKeys)")

        // Update local UserDefaults with cloud values
        for key in changedKeys where syncedKeys.contains(key) {
            if let value = cloudStore.object(forKey: key) {
                localStore.set(value, forKey: key)
            }
        }

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .cloudSettingsDidChange,
            object: nil,
            userInfo: ["changedKeys": changedKeys]
        )
    }

    // MARK: - Sync Operations

    /// Sync a setting to the cloud
    func syncSetting(key: String, value: Any) {
        guard syncedKeys.contains(key) else {
            print("⚠️ CloudSettingsManager: Key '\(key)' is not configured for cloud sync")
            return
        }

        // Set in local UserDefaults
        localStore.set(value, forKey: key)

        // Set in cloud store
        cloudStore.set(value, forKey: key)
        cloudStore.synchronize()

        print("☁️ CloudSettingsManager: Synced '\(key)' to cloud")
    }

    /// Sync all settings to the cloud from local UserDefaults
    func syncAllToCloud() {
        for key in syncedKeys {
            if let value = localStore.object(forKey: key) {
                cloudStore.set(value, forKey: key)
            }
        }
        cloudStore.synchronize()
        print("☁️ CloudSettingsManager: Synced all settings to cloud")
    }

    /// Sync all settings from cloud to local UserDefaults
    func syncFromCloud() {
        for key in syncedKeys {
            // Only sync if value exists in cloud
            if let cloudValue = cloudStore.object(forKey: key) {
                // Only overwrite local if local doesn't exist
                // This prevents cloud from overwriting newly set local values
                if localStore.object(forKey: key) == nil {
                    localStore.set(cloudValue, forKey: key)
                    print("☁️ CloudSettingsManager: Synced '\(key)' from cloud")
                }
            }
        }
    }

    /// Force sync from cloud (overwrites local values)
    func forceSyncFromCloud() {
        for key in syncedKeys {
            if let cloudValue = cloudStore.object(forKey: key) {
                localStore.set(cloudValue, forKey: key)
            }
        }
        print("☁️ CloudSettingsManager: Force synced all settings from cloud")

        NotificationCenter.default.post(
            name: .cloudSettingsDidChange,
            object: nil,
            userInfo: ["changedKeys": Array(syncedKeys)]
        )
    }

    // MARK: - Helper Methods

    /// Get a setting value (checks cloud first, then local)
    func getSetting<T>(key: String, defaultValue: T) -> T {
        // Check cloud first
        if let cloudValue = cloudStore.object(forKey: key) as? T {
            return cloudValue
        }

        // Fall back to local
        if let localValue = localStore.object(forKey: key) as? T {
            return localValue
        }

        return defaultValue
    }

    /// Check if cloud sync is available
    var isCloudSyncAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudSettingsDidChange = Notification.Name("cloudSettingsDidChange")
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    /// Save a setting and sync to cloud
    @MainActor
    func setAndSync(_ value: Any?, forKey key: String) {
        self.set(value, forKey: key)
        CloudSettingsManager.shared.syncSetting(key: key, value: value ?? NSNull())
    }
}
