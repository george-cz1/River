import ActivityKit
import Foundation

/// Service for managing Focus Live Activities in Dynamic Island and Lock Screen
@MainActor
@Observable
final class LiveActivityService {
    static let shared = LiveActivityService()

    private(set) var currentActivity: Activity<FocusActivityAttributes>?

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private init() {}

    // MARK: - Activity Lifecycle

    @discardableResult
    func startActivity(for state: TimerState) -> Bool {
        guard isSupported else { return false }

        if currentActivity != nil {
            endActivity()
        }

        let attributes = FocusActivityAttributes(taskTitle: state.taskTitle)
        let contentState = state.contentState

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: contentState,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                ),
                pushType: nil
            )
            currentActivity = activity
            return true
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
            return false
        }
    }

    func updateActivity(with state: TimerState) {
        guard let activity = currentActivity else {
            startActivity(for: state)
            return
        }

        let contentState = state.contentState
        Task {
            await activity.update(
                ActivityContent(
                    state: contentState,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
                )
            )
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }

        currentActivity = nil

        Task {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: Date()),
                dismissalPolicy: .immediate
            )
        }
    }

    func restoreActivityIfNeeded() {
        for activity in Activity<FocusActivityAttributes>.activities {
            currentActivity = activity
            return
        }

        if let state = SharedDataManager.shared.getTimerState() {
            startActivity(for: state)
        }
    }

    var hasActiveActivity: Bool { currentActivity != nil }
}
