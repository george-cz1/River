import SwiftUI

/// Pomodoro cycle progress indicator dot
struct CycleDot: View {
    let isFilled: Bool
    let isInProgress: Bool
    let color: Color
    let size: CGFloat

    init(
        isFilled: Bool,
        isInProgress: Bool = false,
        color: Color,
        size: CGFloat = 10
    ) {
        self.isFilled = isFilled
        self.isInProgress = isInProgress
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Base empty circle
            Circle()
                .fill(AppColors.border)

            // Half-fill for in-progress (left half)
            if isInProgress && !isFilled {
                Circle()
                    .fill(color)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                            Color.clear
                        }
                    )
            }

            // Full fill for completed
            if isFilled {
                Circle()
                    .fill(color)
            }
        }
        .frame(width: size, height: size)
    }
}
