import SwiftUI
import SwiftData

extension Notification.Name {
    static let riverNewTask = Notification.Name("com.george.river.newTask")
}

@main
struct RiverMacApp: App {
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
            print("✅ RiverMacApp: CloudKit ModelContainer created successfully")
            return container
        } catch {
            print("⚠️ RiverMacApp: CloudKit ModelContainer failed (\(error.localizedDescription)), falling back to local storage")
            do {
                let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup("River") {
            MacMainView()
                .frame(minWidth: 800, minHeight: 600)
                .environment(purchaseManager)
                .environment(cloudSettingsManager)
                .onAppear {
                    SessionHistoryService.shared.configure(with: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            RiverCommands()
        }
        .defaultSize(width: 900, height: 700)
    }
}

// MARK: - Menu Bar Label (defined but not wired — future menu bar feature)

struct MenuBarLabel: View {
    private var timerService = FocusTimerService.shared

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: timerService.isTimerRunning ? "timer" : "timer.circle")
                .font(.system(size: 14))
            if timerService.isFocusing {
                Text(timerService.formattedTime)
                    .font(.system(size: 12, design: .monospaced))
            }
        }
    }
}

// MARK: - App Commands

struct RiverCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Preferences...") {
                // Settings are now accessed via the sidebar — this is a no-op on Mac
                // since we dropped the Settings scene in favor of the sidebar tab.
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        CommandGroup(replacing: .newItem) {
            Button("New Task...") {
                NotificationCenter.default.post(name: .riverNewTask, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
