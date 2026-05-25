import SwiftUI
import SwiftData
#if DEBUG
import DebugBridgeCore
import DebugBridgeUI
#endif

@main
struct RiverApp: App {
    @State private var purchaseManager = PurchaseManager.shared
    @State private var cloudSettingsManager = CloudSettingsManager.shared

    var sharedModelContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.george.river"))
            let container = try ModelContainer(for: FocusTask.self, DeletedTask.self, SessionRecord.self, configurations: config)
            print("✅ RiverApp: CloudKit ModelContainer created successfully")
            return container
        } catch {
            print("⚠️ RiverApp: CloudKit failed (\(error)), trying local storage")
            do {
                return try ModelContainer(for: FocusTask.self, DeletedTask.self, SessionRecord.self)
            } catch {
                print("⚠️ RiverApp: Local storage failed (\(error)), using in-memory")
                do {
                    return try ModelContainer(for: FocusTask.self, DeletedTask.self, SessionRecord.self,
                                              configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                } catch {
                    fatalError("In-memory ModelContainer failed: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    SessionHistoryService.shared.configure(with: context)
                    #if DEBUG
                    DebugBridgeUIWiring.installAll()
                    StateServer.shared.start()
                    #endif
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
