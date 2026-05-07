//
//  WatchTimerView.swift
//  RiverWatch
//
//  Main timer view for watchOS
//

import SwiftUI

struct WatchTimerView: View {
    @Environment(FocusTimerService.self) private var timerService

    var body: some View {
        VStack(spacing: 8) {
            if timerService.isFocusing {
                activeTimerView
            } else {
                idleView
            }
        }
        .navigationTitle("River")
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
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

            ProgressView(value: timerService.progress)
                .progressViewStyle(.circular)
                .scaleEffect(0.8)

            Text("\(timerService.completedPomodoros)/\(timerService.pomodorosBeforeLongBreak)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    WatchConnectivityService.shared.sendCommand(
                        timerService.isTimerRunning ? "pause" : "resume"
                    )
                } label: {
                    Image(systemName: timerService.isTimerRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderless)

                Button {
                    WatchConnectivityService.shared.sendCommand("skip")
                } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.borderless)

                Button {
                    WatchConnectivityService.shared.sendCommand("stop")
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.borderless)
                .tint(.red)
            }
        }
        .padding()
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Active Session")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Start from iPhone")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}
