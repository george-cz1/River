import AppIntents
import ActivityKit

struct ToggleFocusTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Toggle Focus Timer"
    static let description = IntentDescription("Pauses or resumes the focus timer")

    func perform() async throws -> some IntentResult {
        guard var state = SharedDataManager.shared.getTimerState() else {
            return .result()
        }

        if state.isTimerRunning {
            state.pause()
        } else if state.totalSeconds > 0 {
            state.resume()
        }

        SharedDataManager.shared.saveTimerState(state)

        // Notify the main app to sync its state
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(NotificationNames.timerStateChanged as CFString),
            nil,
            nil,
            true
        )

        let contentState = state.contentState
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.update(
                ActivityContent(
                    state: contentState,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                )
            )
        }

        return .result()
    }
}
