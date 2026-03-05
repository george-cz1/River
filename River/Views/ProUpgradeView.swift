import SwiftUI

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Feature list
                    featureSection

                    // CTA
                    ctaSection
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle("River Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.sageSoft)
                    .frame(width: 80, height: 80)

                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.sage)
            }

            VStack(spacing: 8) {
                Text("Unlock Everything")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("One-time purchase, no subscription")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Features

    private var featureSection: some View {
        VStack(spacing: 0) {
            ForEach(proFeatures, id: \.title) { feature in
                FeatureRow(icon: feature.icon, color: feature.color, title: feature.title, description: feature.description)

                if feature.title != proFeatures.last?.title {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            if purchaseManager.isPro {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.breakPhase)
                    Text("You have Pro!")
                        .font(AppFonts.headline)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.breakPhase.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    Task { await purchaseManager.purchasePro() }
                } label: {
                    if purchaseManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Unlock Pro · $4.99")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(purchaseManager.isLoading)

                Button {
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                }
                .buttonStyle(GhostButtonStyle())

                if let error = purchaseManager.error {
                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.destructive)
                        .multilineTextAlignment(.center)
                }
            }

            Text("Secure payment via Apple. No subscription — yours forever.")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Feature Data

    private struct ProFeature {
        let icon: String
        let color: Color
        let title: String
        let description: String
    }

    private var proFeatures: [ProFeature] {
        [
            ProFeature(icon: "slider.horizontal.3", color: AppColors.sage,
                       title: "Custom Timer Durations",
                       description: "Set your own work and break lengths"),
            ProFeature(icon: "checklist", color: AppColors.breakPhase,
                       title: "Unlimited Tasks",
                       description: "Add as many tasks as you need"),
            ProFeature(icon: "chart.bar.fill", color: AppColors.sand,
                       title: "Session History",
                       description: "Track your completed pomodoros over time"),
            ProFeature(icon: "paintpalette.fill", color: AppColors.sage,
                       title: "Additional Themes",
                       description: "Customize the look of your focus sessions"),
            ProFeature(icon: "speaker.wave.2.fill", color: AppColors.sand,
                       title: "Custom Sounds & Haptics",
                       description: "Personalize phase transition alerts"),
            ProFeature(icon: "hand.raised.circle.fill", color: AppColors.workPhase,
                       title: "Block Distracting Apps",
                       description: "Stay focused by blocking apps during sessions"),
        ]
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text(description)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
