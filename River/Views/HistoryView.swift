import SwiftUI

/// View displaying focus session history and statistics
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyService = SessionHistoryService.shared
    @State private var selectedRange: DateRange = .thisWeek

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statsSection
                    rangePickerSection
                    sessionsListSection
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.textSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
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
                            SessionRowView(session: session)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))

            Text("No sessions yet")
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textSecondary)

            Text("Complete your first focus session to see it here")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Stat Card

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

// MARK: - Session Row

struct SessionRowView: View {
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

// MARK: - Preview

#Preview {
    HistoryView()
}
