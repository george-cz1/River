import SwiftUI

struct FocusView: View {
    @State private var timerService = FocusTimerService.shared
    @State private var timerScale: CGFloat = 1.0
    @State private var previousCompletedCount = 0

    var body: some View {
        NavigationStack {
            Group {
                if timerService.isFocusing {
                    activeTimerView
                } else {
                    noFocusState
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            timerService.handleAppForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            timerService.handleAppBackground()
        }
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Phase label
                phaseLabel

                // Circular timer
                circularTimer

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

    // MARK: - Circular Timer

    private var circularTimer: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(AppColors.border, lineWidth: 6)
                .frame(width: 220, height: 220)

            // Progress arc
            Circle()
                .trim(from: 0, to: timerService.progress)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .animation(.linear(duration: 1), value: timerService.tickCount)

            // Timer display
            VStack(spacing: 4) {
                Text(timerService.formattedTime)
                    .font(AppFonts.timerDisplay())
                    .foregroundStyle(AppColors.textPrimary)
                    .id(timerService.tickCount)
                    .scaleEffect(timerScale)

                if timerService.timerPhase == .idle {
                    Text("Tap to start")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .onChange(of: timerService.completedPomodoros) { oldValue, newValue in
            if newValue > previousCompletedCount && newValue > 0 {
                onPhaseComplete()
            }
            previousCompletedCount = newValue
        }
    }

    // MARK: - Completion Celebration

    private func onPhaseComplete() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            timerScale = 1.05
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
            timerScale = 1.0
        }
    }

    // MARK: - Pomodoro Dots

    private var pomodoroProgressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < timerService.completedPomodoros % 4
                          ? phaseColor
                          : AppColors.border)
                    .frame(width: 10, height: 10)
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
            subtitle: "Go to Tasks and tap the focus button on a task to begin",
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
