import Foundation
import UserNotifications

/// Service for managing the Pomodoro timer lifecycle
@MainActor
@Observable
final class FocusTimerService {
    static let shared = FocusTimerService()

    /// Current timer state (nil = not in a focus session)
    private(set) var state: TimerState?

    /// Tick counter to force observation updates on computed properties
    private(set) var tickCount: Int = 0

    private var timer: Timer?
    private var persistCounter: Int = 0
    private let persistInterval: Int = 10

    private init() {
        restoreState()
        setupNotificationObserver()
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    // MARK: - Focus Session Control

    func startFocus(taskTitle: String) {
        endFocus()

        let workDuration = UserDefaults.standard.integer(forKey: "workDuration").nonZero(default: 25 * 60)
        let shortBreakDuration = UserDefaults.standard.integer(forKey: "shortBreakDuration").nonZero(default: 5 * 60)
        let longBreakDuration = UserDefaults.standard.integer(forKey: "longBreakDuration").nonZero(default: 15 * 60)
        let pomodorosBeforeLongBreak = UserDefaults.standard.integer(forKey: "pomodorosBeforeLongBreak").nonZero(default: 4)

        state = TimerState(
            taskTitle: taskTitle,
            workDuration: workDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            pomodorosBeforeLongBreak: pomodorosBeforeLongBreak
        )

        persistState()
        updateLiveActivity()
    }

    func endFocus() {
        stopCountdownTimer()
        cancelNotifications()
        state = nil
        SharedDataManager.shared.saveTimerState(nil)
        LiveActivityService.shared.endActivity()

        // Disable app blocking when focus ends
        AppBlockingService.shared.disableBlocking()
    }

    // MARK: - Timer Control

    func startTimer() {
        guard var currentState = state else { return }

        if currentState.timerPhase == .idle || !currentState.isTimerRunning {
            currentState.startWorkPhase()
            state = currentState
        }

        startCountdownTimer()
        schedulePhaseNotification()
        persistState()
        updateLiveActivity()

        // Enable app blocking if Pro user
        if PurchaseManager.shared.isPro {
            AppBlockingService.shared.enableBlocking()
        }
    }

    func pauseTimer() {
        guard var currentState = state, currentState.isTimerRunning else { return }

        currentState.pause()
        state = currentState

        stopCountdownTimer()
        cancelNotifications()
        persistState()
        updateLiveActivity()

        // Disable app blocking when paused
        AppBlockingService.shared.disableBlocking()
    }

    func resumeTimer() {
        guard var currentState = state, !currentState.isTimerRunning, currentState.totalSeconds > 0 else { return }

        currentState.resume()
        state = currentState

        startCountdownTimer()
        schedulePhaseNotification()
        persistState()
        updateLiveActivity()

        // Enable app blocking if Pro user
        if PurchaseManager.shared.isPro {
            AppBlockingService.shared.enableBlocking()
        }
    }

    func toggleTimer() {
        guard let currentState = state else { return }

        if currentState.isTimerRunning {
            pauseTimer()
        } else if currentState.timerPhase == .idle {
            startTimer()
        } else {
            resumeTimer()
        }
    }

    func skipPhase() {
        guard var currentState = state else { return }

        stopCountdownTimer()
        cancelNotifications()

        // Save session history when work phase is skipped
        if currentState.timerPhase == .work {
            SessionHistoryService.shared.saveSession(
                taskName: currentState.taskTitle,
                workDuration: currentState.workDuration / 60, // Convert to minutes
                completedFully: false
            )
        }

        currentState.skipToNextPhase()
        state = currentState

        startCountdownTimer()
        schedulePhaseNotification()
        persistState()
        updateLiveActivity()
    }

    func resetTimer() {
        guard var currentState = state else { return }

        stopCountdownTimer()
        cancelNotifications()

        currentState.resetToIdle()
        state = currentState

        persistState()
        updateLiveActivity()
    }

    // MARK: - Private Timer

    private func startCountdownTimer() {
        stopCountdownTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopCountdownTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let currentState = state, currentState.isTimerRunning else { return }

        tickCount += 1

        if currentState.remainingSeconds <= 0 {
            // Save session history when work phase completes
            if currentState.timerPhase == .work {
                SessionHistoryService.shared.saveSession(
                    taskName: currentState.taskTitle,
                    workDuration: currentState.workDuration / 60, // Convert to minutes
                    completedFully: true
                )
            }

            // Play sound and haptic feedback
            SoundService.shared.playTransitionFeedback()

            var mutated = currentState
            mutated.completeCurrentPhase()
            state = mutated

            schedulePhaseNotification()
            persistState()
            updateLiveActivity()
            return
        }

        persistCounter += 1
        if persistCounter >= persistInterval {
            persistState()
            persistCounter = 0
        }

        updateLiveActivity()
    }

    // MARK: - Persistence

    private func persistState() {
        SharedDataManager.shared.saveTimerState(state)
    }

    private func restoreState() {
        state = SharedDataManager.shared.getTimerState()

        if let currentState = state, currentState.isTimerRunning, currentState.remainingSeconds > 0 {
            startCountdownTimer()
            LiveActivityService.shared.restoreActivityIfNeeded()
        }
    }

    // MARK: - Live Activity

    private func updateLiveActivity() {
        guard let state = state else { return }
        LiveActivityService.shared.updateActivity(with: state)
    }

    // MARK: - Notifications

    private func schedulePhaseNotification() {
        guard let currentState = state, currentState.isTimerRunning else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.userInfo = ["type": "focus_phase"]

        switch currentState.timerPhase {
        case .work:
            content.title = "Work Session Complete"
            content.body = "Time for a break! You've completed \(currentState.completedPomodoros + 1) pomodoro(s)."
        case .shortBreak:
            content.title = "Break Over"
            content.body = "Ready to get back to \"\(currentState.taskTitle)\"?"
        case .longBreak:
            content.title = "Long Break Over"
            content.body = "Refreshed? Let's continue with \"\(currentState.taskTitle)\"!"
        case .idle:
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(currentState.remainingSeconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "focus_phase_\(currentState.timerPhase.rawValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "focus_phase_work",
            "focus_phase_shortBreak",
            "focus_phase_longBreak"
        ])
    }

    // MARK: - Notification Handling

    private func setupNotificationObserver() {
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let service = Unmanaged<FocusTimerService>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    service.syncStateFromSharedStorage()
                }
            },
            "com.george.evolve.timerStateChanged" as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func syncStateFromSharedStorage() {
        guard let sharedState = SharedDataManager.shared.getTimerState() else { return }

        // Only sync if the state actually changed to avoid unnecessary updates
        guard state?.isTimerRunning != sharedState.isTimerRunning ||
              state?.remainingSeconds != sharedState.remainingSeconds else {
            return
        }

        let wasRunning = state?.isTimerRunning ?? false
        state = sharedState

        // Restart or stop timer based on new state
        if sharedState.isTimerRunning && !wasRunning {
            startCountdownTimer()
            schedulePhaseNotification()
        } else if !sharedState.isTimerRunning && wasRunning {
            stopCountdownTimer()
            cancelNotifications()
        }

        updateLiveActivity()
    }

    // MARK: - App Lifecycle

    func handleAppForeground() {
        guard var currentState = state else { return }

        if currentState.isTimerRunning {
            if currentState.remainingSeconds <= 0 {
                currentState.completeCurrentPhase()
                state = currentState
            }
            startCountdownTimer()
            updateLiveActivity()
        }
    }

    func handleAppBackground() {
        persistState()
    }
}

// MARK: - Convenience Properties

extension FocusTimerService {
    var isFocusing: Bool { state != nil }
    var isTimerRunning: Bool { state?.isTimerRunning ?? false }
    var timerPhase: TimerPhase { state?.timerPhase ?? .idle }

    var remainingSeconds: Int { state?.remainingSeconds ?? 0 }

    var formattedTime: String {
        let s = remainingSeconds
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    var completedPomodoros: Int { state?.completedPomodoros ?? 0 }
    var progress: Double { state?.contentState.progress ?? 0 }
    var focusedTaskTitle: String? { state?.taskTitle }
}

// MARK: - Int Helper

private extension Int {
    func nonZero(default defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
