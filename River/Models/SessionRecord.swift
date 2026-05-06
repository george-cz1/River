import Foundation
import SwiftData

/// Represents a completed focus session for history tracking
@Model
final class SessionRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var taskName: String?
    var workDuration: Int  // minutes
    var completedFully: Bool
    var deviceIdentifier: String  // For tracking which device created the session

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        taskName: String?,
        workDuration: Int,
        completedFully: Bool,
        deviceIdentifier: String? = nil
    ) {
        self.id = id
        self.date = date
        self.taskName = taskName
        self.workDuration = workDuration
        self.completedFully = completedFully
        self.deviceIdentifier = deviceIdentifier ?? PlatformCapabilities.deviceIdentifier
    }
}

// MARK: - Date Range Helper

enum DateRange: Hashable, Sendable {
    case today
    case thisWeek
    case thisMonth
    case allTime
    case custom(start: Date, end: Date)

    var dates: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return (start, end)

        case .thisWeek:
            let start = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
            return (start, end)

        case .thisMonth:
            let start = calendar.dateComponents([.year, .month], from: now).date ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return (start, end)

        case .allTime:
            return (Date.distantPast, Date.distantFuture)

        case .custom(let start, let end):
            return (start, end)
        }
    }
}
