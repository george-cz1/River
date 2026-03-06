import SwiftUI

/// View for selecting app color theme
struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var themeManager = ThemeManager.shared

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    descriptionSection
                    themeGridSection
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DismissToolbarButton()
                }
            }
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
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
    }

    // MARK: - Theme Grid

    private var themeGridSection: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                ThemeCard(
                    theme: theme,
                    isSelected: themeManager.currentTheme == theme,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.currentTheme = theme
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Color preview
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
                        .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 3)
                )

                // Theme name
                VStack(spacing: 4) {
                    Text(theme.displayName)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)

                    if isSelected {
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
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ThemePickerView()
}
