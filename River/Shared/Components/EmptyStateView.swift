import SwiftUI

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
