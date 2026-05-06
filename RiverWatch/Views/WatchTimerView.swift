//
//  WatchTimerView.swift
//  RiverWatch
//
//  Main timer view for watchOS
//

import SwiftUI

struct WatchTimerView: View {
    @ObservedObject private var timerService = FocusTimerService.shared

    var body: some View {
        VStack(spacing: 8) {
            if timerService.isFocusing {
                // Active timer display
                VStack(spacing: 4) {
                    if let taskTitle = timerService.focusedTaskTitle {
                        Text(taskTitle)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }

                    Text(timerService.formattedTime)
                        .font(.system(size: 40, weight: .light, design: .monospaced))
                        .monospacedDigit()

                    Text(timerService.timerPhase.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Progress ring
                    ProgressView(value: timerService.progress)
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)

                    // Pomodoros
                    Text("\(timerService.completedPomodoros)/\(timerService.pomodorosBeforeLongBreak)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Timer controls
                    HStack(spacing: 12) {
                        Button {
                            timerService.toggleTimer()
                        } label: {
                            Image(systemName: timerService.isTimerRunning ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            timerService.skipPhase()
                        } label: {
                            Image(systemName: "forward.fill")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            timerService.endFocus()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.borderless)
                        .tint(.red)
                    }
                }
                .padding()
            } else {
                // No active timer
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("No Active Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Start on iPhone") {
                        // Timer should be started from iPhone
                    }
                    .font(.caption2)
                    .disabled(true)
                }
                .padding()
            }
        }
        .navigationTitle("River")
    }
}

#Preview {
    WatchTimerView()
}
