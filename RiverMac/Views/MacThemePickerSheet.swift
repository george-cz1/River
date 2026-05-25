import SwiftUI

struct MacThemePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = ThemeManager.shared

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Spacer()
                Text("Themes")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Your Color")
                            .font(AppFonts.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Select an accent color theme. Your choice works with both light and dark mode.")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            themeCard(theme)
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(AppColors.background)
        .frame(width: 480, height: 520)
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.currentTheme = theme
            }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.softColor)

                    Image(systemName: theme.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(theme.accentColor)
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            themeManager.currentTheme == theme ? theme.accentColor : Color.clear,
                            lineWidth: 3
                        )
                )

                VStack(spacing: 4) {
                    Text(theme.displayName)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)

                    if themeManager.currentTheme == theme {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Active")
                                .font(AppFonts.caption)
                        }
                        .foregroundStyle(theme.accentColor)
                    }
                }
            }
            .padding(12)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MacThemePickerSheet()
}
