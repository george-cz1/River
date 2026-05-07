//
//  RiverMacApp.swift
//  RiverMac
//
//  macOS native entry point for River Pomodoro Timer
//

import SwiftUI
import SwiftData

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
                .onAppear {
                    SessionHistoryService.shared.configure(with: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            RiverCommands()
        }
        .defaultSize(width: 900, height: 700)

        Settings {
            MacSettingsView()
                .environment(purchaseManager)
        }
    }
}

// MARK: - Menu Bar Label

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
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        CommandGroup(replacing: .newItem) {
            Button("New Task...") {
                // TODO: Implement new task action
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
