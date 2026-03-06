import Foundation

/// App Group configuration for sharing data between app and widget
enum AppGroup {
    /// App Group identifier — update this to match your provisioning profile
    static let identifier = "group.com.george.evolve"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    /// Keys for storing data in App Group UserDefaults
    enum Keys {
        static let selectedAppsForBlocking = "selectedAppsForBlocking"
    }
}

enum SharedDataKey {
    static let timerState = "timerState"
    static let selectedTheme = "selectedTheme"
}

/// Manager for sharing data between app and widget
final class SharedDataManager: Sendable {
    static let shared = SharedDataManager()
    private init() {}

    func saveTimerState(_ state: TimerState?) {
        guard let state = state else {
            AppGroup.userDefaults?.removeObject(forKey: SharedDataKey.timerState)
            return
        }

        do {
            let encoded = try JSONEncoder().encode(state)
            AppGroup.userDefaults?.set(encoded, forKey: SharedDataKey.timerState)
        } catch {
            print("⚠️ SharedDataManager: Failed to encode timer state - \(error.localizedDescription)")
            // Data loss risk: Widget may not sync properly
        }
    }

    func getTimerState() -> TimerState? {
        guard let data = AppGroup.userDefaults?.data(forKey: SharedDataKey.timerState) else {
            return nil
        }

        do {
            let state = try JSONDecoder().decode(TimerState.self, from: data)
            return state
        } catch {
            print("⚠️ SharedDataManager: Failed to decode timer state - \(error.localizedDescription)")
            print("⚠️ Clearing corrupted timer state")

            // Clear corrupted data to prevent repeated errors
            AppGroup.userDefaults?.removeObject(forKey: SharedDataKey.timerState)
            return nil
        }
    }
}
