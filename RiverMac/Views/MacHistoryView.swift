//
//  MacHistoryView.swift
//  RiverMac
//
//  Session history view for macOS - iOS-consistent design
//

import SwiftUI

struct MacHistoryView: View {
    @State private var historyService = SessionHistoryService.shared
    @State private var selectedRange: DateRange = .thisWeek
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Spacer()
                Text("Session History")
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
                    statsSection
                    rangePickerSection
                    sessionsListSection
                    Spacer(minLength: 32)
                }
                .padding(24)
            }
        }
        .background(AppColors.background)
        .frame(width: 560, height: 600)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "checkmark.circle.fill",
                    color: AppColors.success
                )

                StatCard(
                    title: "Streak",
                    value: "\(historyService.getCurrentStreak())",
                    icon: "flame.fill",
                    color: AppColors.river
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "Focus Time",
                    value: stats.formattedFocusTime,
                    icon: "clock.fill",
                    color: AppColors.workPhase
                )

                StatCard(
                    title: "Completion",
                    value: "\(Int(stats.completionRate * 100))%",
                    icon: "star.fill",
                    color: AppColors.breakPhase
                )
            }
        }
    }

    // MARK: - Range Picker

    private var rangePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Period")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Picker("Range", selection: $selectedRange) {
                Text("Today").tag(DateRange.today)
                Text("This Week").tag(DateRange.thisWeek)
                Text("This Month").tag(DateRange.thisMonth)
                Text("All Time").tag(DateRange.allTime)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Sessions List

    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            if filteredSessions.isEmpty {
                emptyStateView
            } else {
                ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatDateHeader(date))
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.top, 8)

                        ForEach(groupedSessions[date] ?? []) { session in
                            SessionRow(session: session)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "clock.badge.questionmark",
            title: "No sessions yet",
            subtitle: "Complete your first focus session to see it here",
            iconSize: 48
        )
        .padding(.vertical, 48)
    }

    // MARK: - Computed Properties

    private var stats: SessionStats {
        historyService.getStats(for: selectedRange)
    }

    private var filteredSessions: [SessionRecord] {
        historyService.getSessions(for: selectedRange)
    }

    private var groupedSessions: [Date: [SessionRecord]] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let taskName = session.taskName, !taskName.isEmpty {
                    Text(taskName)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                } else {
                    Text("Untitled Session")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .italic()
                }

                HStack(spacing: 8) {
                    Text(formatTime(session.date))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Text("•")
                        .foregroundStyle(AppColors.textSecondary)

                    Text("\(session.workDuration) min")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    if session.completedFully {
                        Text("•")
                            .foregroundStyle(AppColors.textSecondary)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppColors.success)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .cardStyle()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MacHistoryView()
}
