import Foundation

/// Represents a completed focus session for history tracking
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let taskName: String?
    let workDuration: Int  // minutes
    let completedFully: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        taskName: String?,
        workDuration: Int,
        completedFully: Bool
    ) {
        self.id = id
        self.date = date
        self.taskName = taskName
        self.workDuration = workDuration
        self.completedFully = completedFully
    }
}

// MARK: - Date Range Helper

enum DateRange: Hashable {
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
