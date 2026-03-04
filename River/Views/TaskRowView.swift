import SwiftUI

struct TaskRowView: View {
    let task: FocusTask
    let isFocused: Bool
    let onToggleComplete: () -> Void
    let onFocus: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? AppColors.completed : AppColors.focusBlue)
                    .animation(.spring(duration: 0.2), value: task.isCompleted)
            }
            .buttonStyle(.plain)

            // Task title
            Text(task.title)
                .font(AppFonts.body)
                .foregroundStyle(task.isCompleted ? AppColors.completed : AppColors.textPrimary)
                .strikethrough(task.isCompleted, color: AppColors.completed)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Focus button (only show if not completed)
            if !task.isCompleted {
                Button(action: onFocus) {
                    HStack(spacing: 4) {
                        Image(systemName: isFocused ? "scope" : "play.circle")
                            .font(.system(size: 16))
                        if isFocused {
                            Text("Focusing")
                                .font(AppFonts.caption)
                        }
                    }
                    .foregroundStyle(isFocused ? AppColors.breakPhase : AppColors.focusBlue)
                    .padding(.horizontal, isFocused ? 10 : 6)
                    .padding(.vertical, 5)
                    .background(
                        (isFocused ? AppColors.breakPhase : AppColors.focusBlue).opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
}
