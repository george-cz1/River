import SwiftUI

/// Circular progress ring timer display
struct CircularTimerView: View {
    let progress: Double
    let formattedTime: String
    let phaseColor: Color
    let tickCount: Int
    let timerScale: CGFloat
    let showStartPrompt: Bool

    private let diameter: CGFloat = 220
    private let lineWidth: CGFloat = 6

    init(
        progress: Double,
        formattedTime: String,
        phaseColor: Color,
        tickCount: Int = 0,
        timerScale: CGFloat = 1.0,
        showStartPrompt: Bool = false
    ) {
        self.progress = progress
        self.formattedTime = formattedTime
        self.phaseColor = phaseColor
        self.tickCount = tickCount
        self.timerScale = timerScale
        self.showStartPrompt = showStartPrompt
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(AppColors.border, lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)
                .animation(.linear(duration: 1), value: tickCount)

            // Timer display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(AppFonts.timerDisplay())
                    .foregroundStyle(AppColors.textPrimary)
                    .id(tickCount)
                    .scaleEffect(timerScale)

                if showStartPrompt {
                    Text("Tap to start")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }
}
