import SwiftUI

/// Statistics card component displaying a metric with icon
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text(title)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .cardStyle()
        .frame(maxWidth: .infinity)
    }
}
