import Foundation

/// Service for tracking and managing completed focus sessions
@MainActor
@Observable
final class SessionHistoryService {
    static let shared = SessionHistoryService()

    private let storageKey = UserDefaultsKeys.sessionHistory
    private(set) var sessions: [SessionRecord] = []

    private init() {
        loadSessions()
    }

    // MARK: - Save Session

    /// Save a completed focus session
    func saveSession(taskName: String?, workDuration: Int, completedFully: Bool) {
        let session = SessionRecord(
            taskName: taskName,
            workDuration: workDuration,
            completedFully: completedFully
        )

        sessions.append(session)
        persistSessions()
    }

    // MARK: - Get Sessions

    /// Get sessions within a specific date range
    func getSessions(for dateRange: DateRange) -> [SessionRecord] {
        let (start, end) = dateRange.dates

        return sessions.filter { session in
            session.date >= start && session.date < end
        }.sorted { $0.date > $1.date }
    }

    /// Get all sessions sorted by date (newest first)
    func getAllSessions() -> [SessionRecord] {
        return sessions.sorted { $0.date > $1.date }
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
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.date > $1.date }

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
        sessions.removeAll { $0.id == session.id }
        persistSessions()
    }

    /// Delete all sessions
    func deleteAllSessions() {
        sessions.removeAll()
        persistSessions()
    }

    // MARK: - Persistence

    private func persistSessions() {
        do {
            let encoded = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            print("⚠️ SessionHistoryService: Failed to encode sessions - \(error.localizedDescription)")
            // Data loss risk: Unable to save session history
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            // No saved data, starting fresh
            sessions = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([SessionRecord].self, from: data)
            sessions = decoded
        } catch {
            print("⚠️ SessionHistoryService: Failed to decode sessions - \(error.localizedDescription)")
            print("⚠️ Attempting recovery by clearing corrupted data")

            // Backup corrupted data for debugging
            let backupKey = storageKey + "_corrupted_\(Date().timeIntervalSince1970)"
            UserDefaults.standard.set(data, forKey: backupKey)

            // Clear corrupted data and start fresh
            UserDefaults.standard.removeObject(forKey: storageKey)
            sessions = []
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
