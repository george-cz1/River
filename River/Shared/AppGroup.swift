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
        if let state = state, let encoded = try? JSONEncoder().encode(state) {
            AppGroup.userDefaults?.set(encoded, forKey: SharedDataKey.timerState)
        } else {
            AppGroup.userDefaults?.removeObject(forKey: SharedDataKey.timerState)
        }
    }

    func getTimerState() -> TimerState? {
        guard let data = AppGroup.userDefaults?.data(forKey: SharedDataKey.timerState),
              let state = try? JSONDecoder().decode(TimerState.self, from: data) else {
            return nil
        }
        return state
    }
}
