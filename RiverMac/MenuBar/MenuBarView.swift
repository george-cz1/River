//
//  MenuBarView.swift
//  RiverMac
//
//  Menu bar popover view for quick timer control
//

import SwiftUI

struct MenuBarView: View {
    private var timerService = FocusTimerService.shared

    var body: some View {
        VStack(spacing: 16) {
            if timerService.isFocusing {
                // Active timer display
                VStack(spacing: 8) {
                    if let taskTitle = timerService.focusedTaskTitle {
                        Text(taskTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }

                    Text(timerService.formattedTime)
                        .font(.system(size: 32, weight: .light, design: .monospaced))

                    Text(timerService.timerPhase.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Timer controls
                    HStack(spacing: 12) {
                        Button {
                            timerService.toggleTimer()
                        } label: {
                            Image(systemName: timerService.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        Button {
                            timerService.skipPhase()
                        } label: {
                            Image(systemName: "forward.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        Button {
                            timerService.endFocus()
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // No active timer
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("No Active Session")
                        .font(.headline)

                    Button("Start Focus") {
                        timerService.startFocus(taskTitle: "Quick Session")
                        timerService.startTimer()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Divider()

            // Quick actions
            HStack {
                Button("Open River") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.link)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.link)
            }
            .font(.caption)
        }
        .padding()
        .frame(width: 240)
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: [FocusTask.self, SessionRecord.self])
}
