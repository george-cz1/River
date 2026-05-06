import SwiftUI
import SwiftData

@main
struct RiverApp: App {
    @State private var purchaseManager = PurchaseManager.shared
    @State private var cloudSettingsManager = CloudSettingsManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FocusTask.self, DeletedTask.self, SessionRecord.self])

        // For development: Start with local storage
        // TODO: Enable CloudKit sync once properly provisioned (.automatic)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // cloudKitDatabase: .automatic  // Enable this once CloudKit is set up
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ RiverApp: ModelContainer created successfully")
            return container
        } catch {
            print("⚠️ RiverApp: Failed to create persistent ModelContainer - \(error)")
            print("⚠️ Error details: \(error.localizedDescription)")
            print("⚠️ Falling back to in-memory storage (data will not persist)")

            // Fallback to in-memory storage to prevent app crash
            do {
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                print("✅ RiverApp: In-memory ModelContainer created")
                return container
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
                .onAppear {
                    // Configure SessionHistoryService with ModelContext
                    let context = sharedModelContainer.mainContext
                    SessionHistoryService.shared.configure(with: context)
                }
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
