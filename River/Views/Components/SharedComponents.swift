import SwiftUI

// MARK: - CircleButton

/// Reusable circular button with icon
struct CircleButton: View {
    let systemName: String
    let size: CGFloat
    let color: Color
    let backgroundColor: Color
    let action: () -> Void

    init(
        systemName: String,
        size: CGFloat = 48,
        color: Color = .primary,
        backgroundColor: Color = .secondary,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyStateView

/// Reusable empty state view with icon, title, and subtitle
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconSize: CGFloat = 48

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(AppColors.border)

            Text(title)
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - DismissToolbarButton

/// Reusable dismiss button for toolbars
struct DismissToolbarButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
