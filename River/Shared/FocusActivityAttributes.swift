import ActivityKit
import Foundation

/// Live Activity attributes for focused task display in Dynamic Island and Lock Screen
struct FocusActivityAttributes: ActivityAttributes {
    let taskTitle: String

    struct ContentState: Codable, Hashable {
        let isTimerRunning: Bool
        let timerPhase: TimerPhase
        let remainingSeconds: Int
        let totalSeconds: Int
        let completedPomodoros: Int
        let isCompleted: Bool
        let phaseEndDate: Date?

        static var idle: ContentState {
            ContentState(
                isTimerRunning: false,
                timerPhase: .idle,
                remainingSeconds: 0,
                totalSeconds: 0,
                completedPomodoros: 0,
                isCompleted: false,
                phaseEndDate: nil
            )
        }

        var progress: Double {
            guard totalSeconds > 0 else { return 0 }
            return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
        }

        var formattedTime: String {
            TimeFormatter.format(seconds: remainingSeconds)
        }
    }
}
