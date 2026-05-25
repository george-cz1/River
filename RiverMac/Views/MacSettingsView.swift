import SwiftUI

struct MacSettingsView: View {
    @AppStorage(UserDefaultsKeys.workDuration) private var workDuration: Int = TimerDefaults.workDuration
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreakDuration: Int = TimerDefaults.shortBreakDuration
    @AppStorage(UserDefaultsKeys.longBreakDuration) private var longBreakDuration: Int = TimerDefaults.longBreakDuration
    @AppStorage(UserDefaultsKeys.pomodorosBeforeLongBreak) private var pomodorosBeforeLongBreak: Int = TimerDefaults.pomodorosBeforeLongBreak

    @Environment(PurchaseManager.self) private var purchaseManager

    @State private var showingUpgrade = false
    @State private var showingHistory = false
    @State private var showingThemePicker = false
    @State private var showingDeletedTasks = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                timerSection
                cycleSection
                proFeaturesSection
                dataSection
                accountSection
            }
            .padding(24)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingUpgrade) {
            MacProUpgradeView()
                .environment(purchaseManager)
        }
        .sheet(isPresented: $showingHistory) {
            MacHistoryView()
        }
        .sheet(isPresented: $showingThemePicker) {
            MacThemePickerSheet()
        }
        .sheet(isPresented: $showingDeletedTasks) {
            MacDeletedTasksView()
        }
    }

    // MARK: - Timer Durations Section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Durations")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            if purchaseManager.isPro {
                VStack(spacing: 8) {
                    MacDurationRow(
                        label: "Work",
                        iconName: "timer",
                        iconColor: AppColors.workPhase,
                        value: $workDuration,
                        range: 1...60,
                        unit: "min",
                        presets: [15, 25, 45, 50]
                    )

                    Divider().padding(.leading, 40)

                    MacDurationRow(
                        label: "Short Break",
                        iconName: "cup.and.saucer",
                        iconColor: AppColors.breakPhase,
                        value: $shortBreakDuration,
                        range: 1...30,
                        unit: "min",
                        presets: [5, 10, 15]
                    )

                    Divider().padding(.leading, 40)

                    MacDurationRow(
                        label: "Long Break",
                        iconName: "leaf",
                        iconColor: AppColors.breakPhase,
                        value: $longBreakDuration,
                        range: 5...60,
                        unit: "min",
                        presets: [15, 20, 30, 45]
                    )
                }
                .padding(16)
                .cardStyle()
            } else {
                lockedSection(title: "Timer Durations", description: "Custom work and break lengths")
            }
        }
    }

    // MARK: - Cycle Section

    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            HStack {
                Label {
                    Text("Sessions before long break")
                        .font(AppFonts.body)
                        .foregroundStyle(purchaseManager.isPro ? AppColors.textPrimary : AppColors.textSecondary)
                } icon: {
                    Image(systemName: "repeat")
                        .foregroundStyle(purchaseManager.isPro ? AppColors.sage : AppColors.completed)
                }

                Spacer()

                if purchaseManager.isPro {
                    Stepper(value: $pomodorosBeforeLongBreak, in: 1...10) {
                        Text("\(pomodorosBeforeLongBreak)")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(minWidth: 20)
                    }
                } else {
                    HStack(spacing: 8) {
                        Text("4")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textSecondary)

                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(AppColors.sage)
                    }
                }
            }
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Pro Features Section

    private var proFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pro Features")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                if purchaseManager.isPro {
                    settingsRow(
                        label: "Session History",
                        icon: "clock.arrow.circlepath",
                        action: { showingHistory = true }
                    )

                    Divider().padding(.leading, 40)

                    settingsRow(
                        label: "Themes",
                        icon: "paintbrush.fill",
                        action: { showingThemePicker = true }
                    )
                } else {
                    lockedRow(label: "Session History", icon: "clock.arrow.circlepath")
                    Divider().padding(.leading, 40)
                    lockedRow(label: "Themes", icon: "paintbrush.fill")
                }
            }
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            settingsRow(
                label: "Deleted Tasks",
                icon: "trash",
                action: { showingDeletedTasks = true }
            )
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                if purchaseManager.isPro {
                    HStack {
                        Label("River Pro", systemImage: "star.fill")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text("Unlocked")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.breakPhase)
                    }

                    if !purchaseManager.isSync {
                        Divider().padding(.leading, 40)
                        Button {
                            showingUpgrade = true
                        } label: {
                            HStack {
                                Label("Add Cross-Device Sync", systemImage: "arrow.triangle.2.circlepath")
                                    .font(AppFonts.body)
                                    .foregroundStyle(AppColors.sage)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        showingUpgrade = true
                    } label: {
                        HStack {
                            Label("Upgrade to Pro", systemImage: "star")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.sage)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 40)

                    Button {
                        Task { await purchaseManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.sage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Helpers

    private func settingsRow(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func lockedRow(label: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(AppColors.sage)
        }
    }

    private func lockedSection(title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text(description)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button("Unlock") { showingUpgrade = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    MacSettingsView()
        .environment(PurchaseManager.shared)
}
