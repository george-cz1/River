import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity widget for Focus/Pomodoro display in Dynamic Island and Lock Screen
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Compact Views

private struct CompactLeadingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "scope")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(phaseColor)

            Text(context.attributes.taskTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private var phaseColor: Color { phaseColorFor(context.state.timerPhase) }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        if let endDate = context.state.phaseEndDate, context.state.isTimerRunning {
            Text(timerInterval: Date()...endDate, countsDown: true)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .monospacedDigit()
                .foregroundStyle(phaseColor)
        } else if context.state.totalSeconds > 0 {
            Text(context.state.formattedTime)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundStyle(phaseColor)
        } else {
            Text("🎯")
                .font(.system(size: 14))
        }
    }

    private var phaseColor: Color { phaseColorFor(context.state.timerPhase) }
}

// MARK: - Minimal View

private struct MinimalView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "5A7A8C").opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: context.state.progress)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "scope")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(phaseColor)
        }
        .frame(width: 24, height: 24)
    }

    private var phaseColor: Color { phaseColorFor(context.state.timerPhase) }
}

// MARK: - Expanded Views

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: "scope")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(phaseColor)

            Text(context.state.timerPhase.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var phaseColor: Color { phaseColorFor(context.state.timerPhase) }
}

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                ForEach(0..<min(context.state.completedPomodoros, 4), id: \.self) { _ in
                    Circle().fill(Color(hex: "2D5A6B")).frame(width: 6, height: 6)
                }
                ForEach(0..<max(0, 4 - context.state.completedPomodoros), id: \.self) { _ in
                    Circle().stroke(Color(hex: "5A7A8C").opacity(0.3), lineWidth: 1).frame(width: 6, height: 6)
                }
            }
            Text("\(context.state.completedPomodoros)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExpandedCenterView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        Text(context.attributes.taskTitle)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(.white)
    }
}

private struct ExpandedBottomView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Left side: Timer and progress
            VStack(alignment: .leading, spacing: 4) {
                if context.state.isTimerRunning || context.state.totalSeconds > 0 {
                    if let endDate = context.state.phaseEndDate, context.state.isTimerRunning {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    } else {
                        Text(context.state.formattedTime)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "5A7A8C").opacity(0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(phaseColor)
                                .frame(width: geo.size.width * context.state.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }

            Spacer()

            // Right side: Hollow play/pause button
            Button(intent: ToggleFocusTimerIntent()) {
                Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(phaseColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .stroke(phaseColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    private var phaseColor: Color { phaseColorFor(context.state.timerPhase) }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Left: Phase and title
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(phaseColor)
                    Text(context.state.timerPhase.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(phaseColor)
                }
                Text(context.attributes.taskTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()

            // Center: Timer and progress
            VStack(alignment: .trailing, spacing: 4) {
                if context.state.isTimerRunning || context.state.totalSeconds > 0 {
                    if let endDate = context.state.phaseEndDate, context.state.isTimerRunning {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    } else {
                        Text(context.state.formattedTime)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundStyle(.primary)
                    }
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                        .tint(phaseColor)
                        .frame(width: 60)
                }
            }

            // Right: Play/Pause button
            Button(intent: ToggleFocusTimerIntent()) {
                Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(phaseColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .stroke(phaseColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground).opacity(0.9))
    }

    private var phaseColor: Color { phaseColorFor(context.state.timerPhase) }
}

// MARK: - Phase Color Helper

private func phaseColorFor(_ phase: TimerPhase) -> Color {
    switch phase {
    case .idle: return Color(hex: "2D5A6B")
    case .work: return Color(hex: "2D5A6B")
    case .shortBreak, .longBreak: return Color(hex: "4A8B9C")
    }
}

// MARK: - Color Hex (duplicated for widget target)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Preview

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: FocusActivityAttributes(
    taskTitle: "Build landing page"
)) {
    FocusLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(
        isTimerRunning: true,
        timerPhase: .work,
        remainingSeconds: 1245,
        totalSeconds: 1500,
        completedPomodoros: 2,
        isCompleted: false,
        phaseEndDate: Date().addingTimeInterval(1245)
    )
}

#Preview("Lock Screen", as: .content, using: FocusActivityAttributes(
    taskTitle: "Build landing page"
)) {
    FocusLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(
        isTimerRunning: true,
        timerPhase: .work,
        remainingSeconds: 1245,
        totalSeconds: 1500,
        completedPomodoros: 2,
        isCompleted: false,
        phaseEndDate: Date().addingTimeInterval(1245)
    )
}
