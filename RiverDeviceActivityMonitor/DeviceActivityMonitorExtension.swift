import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore(named: .focus)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load the selected apps from App Group shared storage
        if let selection = loadSelectedApps() {
            // Apply shields to selected apps
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Clear all shields when interval ends
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    private func loadSelectedApps() -> FamilyActivitySelection? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.george.evolve") else {
            return nil
        }

        guard let data = sharedDefaults.data(forKey: "selectedAppsForBlocking") else {
            return nil
        }

        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            return selection
        } catch {
            print("Failed to decode FamilyActivitySelection: \(error)")
            return nil
        }
    }
}

extension ManagedSettingsStore.Name {
    nonisolated(unsafe) static let focus = Self("focus")
}
