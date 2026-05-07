//
//  MacSettingsView.swift
//  RiverMac
//
//  Settings view for macOS - iOS-consistent design
//

import SwiftUI

struct MacSettingsView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @Environment(PurchaseManager.self) private var purchaseManager

    @State private var workDuration = UserDefaults.standard.integer(forKey: UserDefaultsKeys.workDuration).nonZero(default: TimerDefaults.workDuration)
    @State private var shortBreakDuration = UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortBreakDuration).nonZero(default: TimerDefaults.shortBreakDuration)
    @State private var longBreakDuration = UserDefaults.standard.integer(forKey: UserDefaultsKeys.longBreakDuration).nonZero(default: TimerDefaults.longBreakDuration)
    @State private var pomodorosBeforeLongBreak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodorosBeforeLongBreak).nonZero(default: TimerDefaults.pomodorosBeforeLongBreak)
    @State private var showingUpgrade = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if purchaseManager.isPro {
                    timerDurationsSection
                } else {
                    lockedSection(title: "Timer Durations", description: "Custom work and break lengths")
                }
                cycleSection
                if purchaseManager.isPro {
                    appearanceSection
                } else {
                    lockedSection(title: "Appearance", description: "Color themes for your focus sessions")
                }
                upgradeSection
            }
            .padding(24)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingUpgrade) {
            MacProUpgradeView()
                .environment(purchaseManager)
        }
    }

    // MARK: - Timer Durations Section

    private var timerDurationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Durations")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                durationRow(
                    label: "Work Duration",
                    iconName: "timer",
                    iconColor: AppColors.workPhase,
                    value: $workDuration,
                    key: UserDefaultsKeys.workDuration
                )

                Divider()
                    .padding(.leading, 40)

                durationRow(
                    label: "Short Break",
                    iconName: "cup.and.saucer",
                    iconColor: AppColors.breakPhase,
                    value: $shortBreakDuration,
                    key: UserDefaultsKeys.shortBreakDuration
                )

                Divider()
                    .padding(.leading, 40)

                durationRow(
                    label: "Long Break",
                    iconName: "leaf",
                    iconColor: AppColors.breakPhase,
                    value: $longBreakDuration,
                    key: UserDefaultsKeys.longBreakDuration
                )
            }
            .padding(16)
            .cardStyle()
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
                    Text("Pomodoros before long break")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                } icon: {
                    Image(systemName: "repeat")
                        .foregroundStyle(AppColors.sage)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        if pomodorosBeforeLongBreak > 1 {
                            pomodorosBeforeLongBreak -= 1
                            UserDefaults.standard.setAndSync(pomodorosBeforeLongBreak, forKey: UserDefaultsKeys.pomodorosBeforeLongBreak)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(pomodorosBeforeLongBreak)")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(minWidth: 20)

                    Button {
                        if pomodorosBeforeLongBreak < 10 {
                            pomodorosBeforeLongBreak += 1
                            UserDefaults.standard.setAndSync(pomodorosBeforeLongBreak, forKey: UserDefaultsKeys.pomodorosBeforeLongBreak)
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.sage)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 16) {
                // Theme grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        themeCard(theme)
                    }
                }
            }
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - Duration Row

    private func durationRow(
        label: String,
        iconName: String,
        iconColor: Color,
        value: Binding<Int>,
        key: String
    ) -> some View {
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

            HStack(spacing: 8) {
                Button {
                    if value.wrappedValue > 1 {
                        value.wrappedValue -= 1
                        UserDefaults.standard.setAndSync(value.wrappedValue, forKey: key)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue) min")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(minWidth: 60)

                Button {
                    if value.wrappedValue < 60 {
                        value.wrappedValue += 1
                        UserDefaults.standard.setAndSync(value.wrappedValue, forKey: key)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.sage)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Theme Card

    private func themeCard(_ theme: AppTheme) -> some View {
        Button {
            themeManager.currentTheme = theme
        } label: {
            VStack(spacing: 8) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundStyle(theme.accentColor)
                    .frame(height: 32)

                Text(theme.displayName)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme == theme ? theme.accentColor.opacity(0.15) : AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                themeManager.currentTheme == theme ? theme.accentColor : AppColors.border,
                                lineWidth: themeManager.currentTheme == theme ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Locked Section

    private func lockedSection(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

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

    // MARK: - Upgrade Section

    private var upgradeSection: some View {
        Group {
            if !purchaseManager.isPro {
                Button("Upgrade to Pro →") { showingUpgrade = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            } else if !purchaseManager.isSync {
                Button("Add Cross-Device Sync →") { showingUpgrade = true }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private extension Int {
    func nonZero(default defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}

#Preview {
    MacSettingsView()
        .environment(PurchaseManager.shared)
}
