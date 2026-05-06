import SwiftUI

struct MacProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.river)

                Text("Upgrade River")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Choose the plan that works for you")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Tier cards
            HStack(alignment: .top, spacing: 16) {
                tierCard(
                    title: "River for Mac",
                    price: "$4.99",
                    subtitle: "One-time purchase",
                    features: [
                        "Custom timer durations",
                        "All color themes",
                        "Session history on this Mac",
                    ],
                    isHighlighted: false,
                    isCurrent: purchaseManager.tier == .devicePro,
                    action: { Task { await purchaseManager.purchaseDevicePro() } }
                )

                tierCard(
                    title: "River Everywhere",
                    price: "$7.99",
                    subtitle: "All devices + iCloud sync",
                    features: [
                        "Everything in River for Mac",
                        "iOS & watchOS Pro features",
                        "Session history syncs across devices",
                        "Settings sync across devices",
                    ],
                    isHighlighted: true,
                    isCurrent: purchaseManager.tier == .sync,
                    action: { Task { await purchaseManager.purchaseSync() } }
                )
            }
            .padding(.horizontal, 24)

            if let error = purchaseManager.error {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 12)
            }

            HStack(spacing: 24) {
                Button("Restore Purchases") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .buttonStyle(.plain)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

                Button("Not Now") { dismiss() }
                    .buttonStyle(.plain)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, 20)
        }
        .frame(width: 560)
        .background(AppColors.background)
    }

    private func tierCard(
        title: String,
        price: String,
        subtitle: String,
        features: [String],
        isHighlighted: Bool,
        isCurrent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(price)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(isHighlighted ? AppColors.river : AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppColors.breakPhase)
                        Text(feature)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }

            Spacer()

            if isCurrent {
                Label("Current Plan", systemImage: "checkmark.circle.fill")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.breakPhase)
                    .frame(maxWidth: .infinity)
            } else {
                Button(action: action) {
                    if purchaseManager.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(isHighlighted ? "Get River Everywhere" : "Get River for Mac")
                            .font(AppFonts.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isHighlighted ? AppColors.river : .secondary)
                .disabled(purchaseManager.isLoading)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isHighlighted ? AppColors.river : AppColors.border,
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )
        )
    }
}
