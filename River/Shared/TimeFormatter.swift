import Foundation

/// Utility for formatting time durations
enum TimeFormatter {
    /// Format seconds as MM:SS string
    static func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    /// Format minutes as human-readable string (e.g., "1h 30m" or "45m")
    static func formatMinutes(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
