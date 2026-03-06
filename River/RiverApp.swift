import SwiftUI
import SwiftData

@main
struct RiverApp: App {
    @State private var purchaseManager = PurchaseManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FocusTask.self, DeletedTask.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("⚠️ RiverApp: Failed to create persistent ModelContainer - \(error.localizedDescription)")
            print("⚠️ Falling back to in-memory storage (data will not persist)")

            // Fallback to in-memory storage to prevent app crash
            let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfiguration])
            } catch {
                print("❌ RiverApp: Fatal error - Could not create in-memory ModelContainer: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .task {
                    await requestNotificationPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }
}
