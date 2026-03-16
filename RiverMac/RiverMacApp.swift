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
    @State private var cloudSettingsManager = CloudSettingsManager.shared

    var body: some Scene {
        // Main window - this will open on launch
        WindowGroup("River") {
            MacMainView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            RiverCommands()
        }
        .defaultSize(width: 900, height: 700)

        // Settings window
        Settings {
            MacSettingsView()
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
