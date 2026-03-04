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
            fatalError("Could not create ModelContainer: \(error)")
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
