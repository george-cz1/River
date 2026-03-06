import SwiftUI

struct SettingsView: View {
    @AppStorage(UserDefaultsKeys.workDuration) private var workDuration: Int = TimerDefaults.workDuration
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreakDuration: Int = TimerDefaults.shortBreakDuration
    @AppStorage(UserDefaultsKeys.longBreakDuration) private var longBreakDuration: Int = TimerDefaults.longBreakDuration
    @AppStorage(UserDefaultsKeys.pomodorosBeforeLongBreak) private var pomodorosBeforeLongBreak: Int = TimerDefaults.pomodorosBeforeLongBreak

    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var showingProUpgrade = false
    @State private var showingDeletedTasks = false
    @State private var showingHistory = false
    @State private var showingThemePicker = false
    @State private var showingSoundSettings = false
    @State private var showingAppBlocking = false

    var body: some View {
        NavigationStack {
            List {
                timerSection
                cycleSection
                proFeaturesSection
                dataSection
                proSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showingDeletedTasks) {
                DeletedTasksView()
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
            .sheet(isPresented: $showingSoundSettings) {
                SoundSettingsView()
            }
            .sheet(isPresented: $showingAppBlocking) {
                AppBlockingSettingsView()
            }
        }
    }

    // MARK: - Pro Features Section

    private var proFeaturesSection: some View {
        Section {
            if purchaseManager.isPro {
                Button {
                    showingHistory = true
                } label: {
                    HStack {
                        Label("Session History", systemImage: "clock.arrow.circlepath")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingThemePicker = true
                } label: {
                    HStack {
                        Label("Themes", systemImage: "paintbrush.fill")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingSoundSettings = true
                } label: {
                    HStack {
                        Label("Sounds & Haptics", systemImage: "speaker.wave.2.fill")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingAppBlocking = true
                } label: {
                    HStack {
                        Label("Focus Blocking", systemImage: "hand.raised.circle.fill")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Label("Session History", systemImage: "clock.arrow.circlepath")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.sage)
                }

                HStack {
                    Label("Themes", systemImage: "paintbrush.fill")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.sage)
                }

                HStack {
                    Label("Sounds & Haptics", systemImage: "speaker.wave.2.fill")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.sage)
                }

                HStack {
                    Label("Focus Blocking", systemImage: "hand.raised.circle.fill")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.sage)
                }
            }
        } header: {
            Text("Pro Features")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            Button {
                showingDeletedTasks = true
            } label: {
                HStack {
                    Label("Deleted Tasks", systemImage: "trash")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Data")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Timer Durations Section

    private var timerSection: some View {
        Section {
            if purchaseManager.isPro {
                DurationRow(
                    label: "Work",
                    iconName: "timer",
                    iconColor: AppColors.workPhase,
                    value: $workDuration,
                    range: 1...60,
                    unit: "min",
                    presets: [15, 25, 45, 50]
                )

                DurationRow(
                    label: "Short Break",
                    iconName: "cup.and.saucer",
                    iconColor: AppColors.breakPhase,
                    value: $shortBreakDuration,
                    range: 1...30,
                    unit: "min",
                    presets: [5, 10, 15]
                )

                DurationRow(
                    label: "Long Break",
                    iconName: "leaf",
                    iconColor: AppColors.breakPhase,
                    value: $longBreakDuration,
                    range: 5...60,
                    unit: "min",
                    presets: [15, 20, 30, 45]
                )
            } else {
                lockedDurationRow(label: "Work", value: 25, iconName: "timer", iconColor: AppColors.workPhase)
                lockedDurationRow(label: "Short Break", value: 5, iconName: "cup.and.saucer", iconColor: AppColors.breakPhase)
                lockedDurationRow(label: "Long Break", value: 15, iconName: "leaf", iconColor: AppColors.breakPhase)

                ProFeatureLock(feature: "Custom timer durations") {
                    showingProUpgrade = true
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        } header: {
            Text("Timer Durations")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Cycle Section

    private var cycleSection: some View {
        Section {
            if purchaseManager.isPro {
                HStack {
                    Label {
                        Text("Sessions before long break")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                    } icon: {
                        Image(systemName: "repeat")
                            .foregroundStyle(AppColors.sage)
                    }

                    Spacer()

                    Stepper("\(pomodorosBeforeLongBreak)", value: $pomodorosBeforeLongBreak, in: 1...10)
                        .labelsHidden()
                        .font(AppFonts.body)
                }
            } else {
                HStack {
                    Label {
                        Text("Sessions before long break")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textSecondary)
                    } icon: {
                        Image(systemName: "repeat")
                            .foregroundStyle(AppColors.completed)
                    }

                    Spacer()

                    Text("4")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.sage)
                }
            }
        } header: {
            Text("Cycle")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Pro Section

    private var proSection: some View {
        Section {
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
            } else {
                Button {
                    showingProUpgrade = true
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

                Button {
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.sage)
                }
            }
        } header: {
            Text("Account")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Locked Row

    private func lockedDurationRow(label: String, value: Int, iconName: String, iconColor: Color) -> some View {
        HStack {
            Label {
                Text(label)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
            } icon: {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor.opacity(0.5))
            }

            Spacer()

            Text("\(value) min")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - Duration Row

struct DurationRow: View {
    let label: String
    let iconName: String
    let iconColor: Color
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let presets: [Int]

    @State private var showingPicker = false

    // Value is stored in seconds, displayed in minutes
    private var minutes: Int {
        get { value / 60 }
    }

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Label {
                    Text(label)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                } icon: {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                }

                Spacer()

                Text("\(minutes) \(unit)")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            DurationPickerSheet(
                label: label,
                iconName: iconName,
                iconColor: iconColor,
                value: $value,
                range: range,
                unit: unit,
                presets: presets
            )
        }
    }
}
