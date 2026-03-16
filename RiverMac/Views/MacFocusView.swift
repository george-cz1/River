//
//  MacFocusView.swift
//  RiverMac
//
//  Focus timer view for macOS - iOS-consistent design
//

import SwiftUI

struct MacFocusView: View {
    @State private var timerService = FocusTimerService.shared
    @State private var timerScale: CGFloat = 1.0

    var body: some View {
        Group {
            if timerService.isFocusing {
                activeTimerView
            } else {
                noFocusState
            }
        }
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Phase label
                phaseLabel

                // Circular timer
                CircularTimerView(
                    progress: timerService.progress,
                    formattedTime: timerService.formattedTime,
                    phaseColor: phaseColor,
                    tickCount: timerService.tickCount,
                    timerScale: timerScale,
                    showStartPrompt: timerService.timerPhase == .idle
                )

                // Task title
                if let title = timerService.focusedTaskTitle {
                    VStack(spacing: 4) {
                        Text("Focusing on")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        Text(title)
                            .font(AppFonts.title)
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 32)
                }

                // Pomodoro progress dots
                pomodoroProgressDots

                // Controls
                controlButtons

                // End focus
                Button("End Focus") {
                    timerService.endFocus()
                }
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.destructive)
                .padding(.top, 8)

                Spacer(minLength: 32)
            }
            .padding(.top, 24)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        Text(timerService.timerPhase.displayName.uppercased())
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(phaseColor)
            .tracking(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(phaseColor.opacity(0.08))
            .clipShape(Capsule())
    }

    // MARK: - Pomodoro Dots

    private var pomodoroProgressDots: some View {
        let total = timerService.pomodorosBeforeLongBreak
        let completed = timerService.completedPomodoros % total
        let isWorkPhase = timerService.timerPhase == .work

        return HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                CycleDot(
                    isFilled: index < completed,
                    isInProgress: index == completed && isWorkPhase,
                    color: phaseColor,
                    size: 10
                )
                .animation(.spring(duration: 0.3), value: timerService.completedPomodoros)
            }
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset
            CircleButton(
                systemName: "arrow.counterclockwise",
                size: 48,
                color: AppColors.textSecondary,
                backgroundColor: AppColors.border.opacity(0.5)
            ) {
                timerService.resetTimer()
            }

            // Play / Pause — main button
            CircleButton(
                systemName: timerService.isTimerRunning ? "pause.fill" : "play.fill",
                size: 72,
                color: .white,
                backgroundColor: phaseColor
            ) {
                timerService.toggleTimer()
            }

            // Skip
            CircleButton(
                systemName: "forward.fill",
                size: 48,
                color: AppColors.textSecondary,
                backgroundColor: AppColors.border.opacity(0.5)
            ) {
                timerService.skipPhase()
            }
        }
    }

    // MARK: - No Focus State

    private var noFocusState: some View {
        EmptyStateView(
            icon: "scope",
            title: "No active focus session",
            subtitle: "Start a focus session from the Tasks view",
            iconSize: 56
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    // MARK: - Helpers

    private var phaseColor: Color {
        timerService.timerPhase.isBreak ? AppColors.breakPhase : AppColors.workPhase
    }
}

#Preview {
    MacFocusView()
}
