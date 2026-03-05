import FamilyControls
import ManagedSettings
import Foundation

@MainActor
@Observable
class AppBlockingService {
    static let shared = AppBlockingService()

    private let store = ManagedSettingsStore(named: .focus)
    private let sharedDefaults: UserDefaults?

    var selectedApps = FamilyActivitySelection() {
        didSet {
            saveSelectedApps()
        }
    }

    private init() {
        sharedDefaults = UserDefaults(suiteName: AppGroup.identifier)
        loadSelectedApps()
    }

    func enableBlocking() {
        guard AppBlockingAuthorizationService.shared.isAuthorized else {
            print("Cannot enable blocking: not authorized")
            return
        }

        // Apply shields directly to selected apps
        store.shield.applications = selectedApps.applicationTokens
        store.shield.applicationCategories = .specific(selectedApps.categoryTokens)

        print("App blocking enabled for \(selectedApps.applicationTokens.count) apps and \(selectedApps.categoryTokens.count) categories")
    }

    func disableBlocking() {
        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        print("App blocking disabled")
    }

    private func saveSelectedApps() {
        do {
            let data = try JSONEncoder().encode(selectedApps)
            sharedDefaults?.set(data, forKey: AppGroup.Keys.selectedAppsForBlocking)
            print("Saved \(selectedApps.applicationTokens.count) selected apps")
        } catch {
            print("Failed to save selected apps: \(error)")
        }
    }

    private func loadSelectedApps() {
        guard let data = sharedDefaults?.data(forKey: AppGroup.Keys.selectedAppsForBlocking) else {
            print("No saved app selection found")
            return
        }

        do {
            selectedApps = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            print("Loaded \(selectedApps.applicationTokens.count) selected apps")
        } catch {
            print("Failed to load selected apps: \(error)")
        }
    }

    var hasSelectedApps: Bool {
        !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty
    }

    var selectedAppsCount: Int {
        selectedApps.applicationTokens.count + selectedApps.categoryTokens.count
    }
}

extension ManagedSettingsStore.Name {
    nonisolated(unsafe) static let focus = Self("focus")
}
