import SwiftUI
import SwiftData

@main
struct RiverApp: App {
    @State private var purchaseManager = PurchaseManager.shared
    @State private var cloudSettingsManager = CloudSettingsManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FocusTask.self, DeletedTask.self, SessionRecord.self])
        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.george.river")
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ RiverApp: CloudKit ModelContainer created successfully")
            return container
        } catch {
            print("⚠️ RiverApp: CloudKit ModelContainer failed (\(error.localizedDescription)), falling back to local storage")
            do {
                let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
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
