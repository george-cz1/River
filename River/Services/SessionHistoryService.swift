import Foundation
import SwiftData

/// Service for tracking and managing completed focus sessions
@MainActor
@Observable
final class SessionHistoryService {
    static let shared = SessionHistoryService()

    private var modelContext: ModelContext?
    private let legacyStorageKey = UserDefaultsKeys.sessionHistory
    private var hasAttemptedMigration = false

    private init() {}

    /// Initialize with a ModelContext for SwiftData operations
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext

        // Attempt migration from UserDefaults to SwiftData on first run
        if !hasAttemptedMigration {
            migrateFromUserDefaults()
            hasAttemptedMigration = true
        }
    }

    // MARK: - Save Session

    /// Save a completed focus session
    func saveSession(taskName: String?, workDuration: Int, completedFully: Bool) {
        guard let modelContext = modelContext else {
            print("⚠️ SessionHistoryService: ModelContext not configured")
            return
        }

        let session = SessionRecord(
            taskName: taskName,
            workDuration: workDuration,
            completedFully: completedFully
        )

        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            print("⚠️ SessionHistoryService: Failed to save session - \(error.localizedDescription)")
        }
    }

    // MARK: - Get Sessions

    /// Get sessions within a specific date range
    func getSessions(for dateRange: DateRange) -> [SessionRecord] {
        guard let modelContext = modelContext else {
            print("⚠️ SessionHistoryService: ModelContext not configured")
            return []
        }

        let (start, end) = dateRange.dates

        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { session in
                session.date >= start && session.date < end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("⚠️ SessionHistoryService: Failed to fetch sessions - \(error.localizedDescription)")
            return []
        }
    }

    /// Get all sessions sorted by date (newest first)
    func getAllSessions() -> [SessionRecord] {
        guard let modelContext = modelContext else {
            print("⚠️ SessionHistoryService: ModelContext not configured")
            return []
        }

        let descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("⚠️ SessionHistoryService: Failed to fetch sessions - \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Statistics

    /// Get statistics for a specific date range
    func getStats(for dateRange: DateRange = .allTime) -> SessionStats {
        let filteredSessions = getSessions(for: dateRange)

        let totalSessions = filteredSessions.count
        let completedSessions = filteredSessions.filter { $0.completedFully }.count
        let totalMinutes = filteredSessions.reduce(0) { $0 + $1.workDuration }

        return SessionStats(
            totalSessions: totalSessions,
            completedSessions: completedSessions,
            totalFocusMinutes: totalMinutes
        )
    }

    /// Get current streak (consecutive days with at least one session)
    func getCurrentStreak() -> Int {
        let allSessions = getAllSessions()
        guard !allSessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedSessions = allSessions

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check if there's a session today
        let hasSessionToday = sortedSessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: currentDate)
        }

        // If no session today, check if there was one yesterday (grace period)
        if !hasSessionToday {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                let hasSessionYesterday = sortedSessions.contains { session in
                    calendar.isDate(session.date, inSameDayAs: yesterday)
                }
                if !hasSessionYesterday {
                    return 0
                }
                currentDate = yesterday
            }
        }

        // Count consecutive days
        while true {
            let hasSession = sortedSessions.contains { session in
                calendar.isDate(session.date, inSameDayAs: currentDate)
            }

            if hasSession {
                streak += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = previousDay
                } else {
                    break
                }
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Delete Sessions

    /// Delete a specific session
    func deleteSession(_ session: SessionRecord) {
        guard let modelContext = modelContext else {
            print("⚠️ SessionHistoryService: ModelContext not configured")
            return
        }

        modelContext.delete(session)

        do {
            try modelContext.save()
        } catch {
            print("⚠️ SessionHistoryService: Failed to delete session - \(error.localizedDescription)")
        }
    }

    /// Delete all sessions
    func deleteAllSessions() {
        guard let modelContext = modelContext else {
            print("⚠️ SessionHistoryService: ModelContext not configured")
            return
        }

        do {
            try modelContext.delete(model: SessionRecord.self)
            try modelContext.save()
        } catch {
            print("⚠️ SessionHistoryService: Failed to delete all sessions - \(error.localizedDescription)")
        }
    }

    // MARK: - Migration from UserDefaults

    /// Migrate existing sessions from UserDefaults to SwiftData
    private func migrateFromUserDefaults() {
        guard let modelContext = modelContext else { return }

        // Check if migration is needed
        guard let data = UserDefaults.standard.data(forKey: legacyStorageKey) else {
            print("ℹ️ SessionHistoryService: No legacy data to migrate")
            return
        }

        do {
            // Define a legacy struct for decoding old data
            struct LegacySessionRecord: Codable {
                let id: UUID
                let date: Date
                let taskName: String?
                let workDuration: Int
                let completedFully: Bool
            }

            let legacySessions = try JSONDecoder().decode([LegacySessionRecord].self, from: data)

            print("ℹ️ SessionHistoryService: Migrating \(legacySessions.count) sessions from UserDefaults to SwiftData")

            // Insert each legacy session into SwiftData
            for legacy in legacySessions {
                let session = SessionRecord(
                    id: legacy.id,
                    date: legacy.date,
                    taskName: legacy.taskName,
                    workDuration: legacy.workDuration,
                    completedFully: legacy.completedFully
                )
                modelContext.insert(session)
            }

            try modelContext.save()

            // Backup and remove legacy data
            let backupKey = legacyStorageKey + "_migrated_backup"
            UserDefaults.standard.set(data, forKey: backupKey)
            UserDefaults.standard.removeObject(forKey: legacyStorageKey)

            print("✅ SessionHistoryService: Successfully migrated \(legacySessions.count) sessions")
        } catch {
            print("⚠️ SessionHistoryService: Failed to migrate sessions - \(error.localizedDescription)")
        }
    }
}

// MARK: - Session Stats

struct SessionStats {
    let totalSessions: Int
    let completedSessions: Int
    let totalFocusMinutes: Int

    var totalFocusHours: Double {
        Double(totalFocusMinutes) / 60.0
    }

    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }

    var formattedFocusTime: String {
        let hours = totalFocusMinutes / 60
        let minutes = totalFocusMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
