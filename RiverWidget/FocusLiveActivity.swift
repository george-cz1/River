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

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "scope")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accentColor)

            Text(context.attributes.taskTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }

    var body: some View {
        Group {
            if let endDate = context.state.phaseEndDate, context.state.isTimerRunning {
                Text(timerInterval: Date()...endDate, countsDown: true, showsHours: false)
            } else if context.state.totalSeconds > 0 {
                Text(context.state.formattedTime)
            } else {
                Text("--:--")
            }
        }
        .font(.custom("CormorantGaramond-Light", size: 14))
        .monospacedDigit()
        .foregroundStyle(accentColor)
        .frame(minWidth: 40, alignment: .trailing)
    }
}

// MARK: - Minimal View

private struct MinimalView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: context.state.progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "scope")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accentColor)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Stable Timer Helper

/// Helper view that maintains consistent width to prevent layout shifts
private struct StableTimerText: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    let fontSize: CGFloat

    var body: some View {
        ZStack {
            // Invisible placeholder to maintain consistent width
            Text("00:00")
                .font(.custom("CormorantGaramond-Light", size: fontSize))
                .monospacedDigit()
                .opacity(0)

            // Actual timer content
            if let endDate = context.state.phaseEndDate, context.state.isTimerRunning {
                Text(timerInterval: Date()...endDate, countsDown: true, showsHours: false)
                    .contentTransition(.numericText())
                    .font(.custom("CormorantGaramond-Light", size: fontSize))
                    .monospacedDigit()
            } else {
                Text(context.state.formattedTime)
                    .font(.custom("CormorantGaramond-Light", size: fontSize))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Expanded Views

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: "scope")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(accentColor)

            Text(context.state.timerPhase.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                ForEach(0..<min(context.state.completedPomodoros, 4), id: \.self) { _ in
                    Circle().fill(accentColor).frame(width: 6, height: 6)
                }
                ForEach(0..<max(0, 4 - context.state.completedPomodoros), id: \.self) { _ in
                    Circle().stroke(accentColor.opacity(0.3), lineWidth: 1).frame(width: 6, height: 6)
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

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                StableTimerText(context: context, fontSize: 32)
                    .foregroundStyle(.white)

                Text(context.state.timerPhase.displayName.uppercased())
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .tracking(1)
            }

            Spacer()

            Button(intent: ToggleFocusTimerIntent()) {
                Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().stroke(accentColor, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var theme: AppTheme { SharedTheme.current() }
    private var accentColor: Color { theme.accentColor }
    private var softColor: Color { theme.softColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Task title only
            Text(context.attributes.taskTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Row 2: Timer + Phase (left) and Button (right)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    StableTimerText(context: context, fontSize: 32)
                        .foregroundStyle(accentColor)

                    Text(context.state.timerPhase.displayName.uppercased())
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .tracking(1)
                }

                Spacer()

                Button(intent: ToggleFocusTimerIntent()) {
                    Image(systemName: context.state.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 48, height: 48)
                        .background(Circle().stroke(accentColor, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(softColor)
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
