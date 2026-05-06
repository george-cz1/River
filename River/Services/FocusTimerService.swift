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

    // MARK: - Platform-specific services

    private let feedbackService: FeedbackServiceProtocol
    private let liveActivityService: LiveActivityServiceProtocol
    private let appBlockingService: AppBlockingServiceProtocol

    private init(
        feedbackService: FeedbackServiceProtocol? = nil,
        liveActivityService: LiveActivityServiceProtocol? = nil,
        appBlockingService: AppBlockingServiceProtocol? = nil
    ) {
        #if os(iOS)
        self.feedbackService = feedbackService ?? SoundService.shared
        self.liveActivityService = liveActivityService ?? LiveActivityService.shared
        self.appBlockingService = appBlockingService ?? AppBlockingService.shared
        #else
        self.feedbackService = feedbackService ?? NoOpFeedbackService()
        self.liveActivityService = liveActivityService ?? NoOpLiveActivityService()
        self.appBlockingService = appBlockingService ?? NoOpAppBlockingService()
        #endif

        restoreState()
        #if !os(watchOS)
        setupNotificationObserver()
        #endif
    }

    deinit {
        #if !os(watchOS)
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
        #endif
    }

    // MARK: - Focus Session Control

    func startFocus(taskTitle: String) {
        endFocus()

        let workDuration = UserDefaults.standard.integer(forKey: UserDefaultsKeys.workDuration).nonZero(default: TimerDefaults.workDuration)
        let shortBreakDuration = UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortBreakDuration).nonZero(default: TimerDefaults.shortBreakDuration)
        let longBreakDuration = UserDefaults.standard.integer(forKey: UserDefaultsKeys.longBreakDuration).nonZero(default: TimerDefaults.longBreakDuration)
        let pomodorosBeforeLongBreak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodorosBeforeLongBreak).nonZero(default: TimerDefaults.pomodorosBeforeLongBreak)

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
        liveActivityService.endActivity()

        // Disable app blocking when focus ends
        appBlockingService.stopBlocking()
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
        #if os(iOS)
        if PurchaseManager.shared.isPro {
            appBlockingService.startBlocking()
        }
        #endif
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
        appBlockingService.stopBlocking()
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
        #if os(iOS)
        if PurchaseManager.shared.isPro {
            appBlockingService.startBlocking()
        }
        #endif
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
            let soundName = UserDefaults.standard.string(forKey: UserDefaultsKeys.transitionSound)
            feedbackService.playTransitionSound(soundName)
            feedbackService.playHaptic(style: .medium)

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
            #if os(iOS)
            // Only iOS has the restoreActivityIfNeeded method
            if let liveActivityService = liveActivityService as? LiveActivityService {
                liveActivityService.restoreActivityIfNeeded()
            }
            #endif
        }
    }

    // MARK: - Live Activity

    private func updateLiveActivity() {
        guard let state = state else { return }
        #if os(iOS)
        // Use the iOS-specific method if available
        if let liveActivityService = liveActivityService as? LiveActivityService {
            liveActivityService.updateActivity(with: state)
        } else {
            liveActivityService.startOrUpdateActivity(
                phase: state.timerPhase,
                remainingSeconds: state.remainingSeconds,
                isRunning: state.isTimerRunning,
                currentTaskTitle: state.taskTitle
            )
        }
        #else
        liveActivityService.startOrUpdateActivity(
            phase: state.timerPhase,
            remainingSeconds: state.remainingSeconds,
            isRunning: state.isTimerRunning,
            currentTaskTitle: state.taskTitle
        )
        #endif
    }

    // MARK: - Notifications

    private func schedulePhaseNotification() {
        guard let currentState = state, currentState.isTimerRunning else { return }

        // Guard against invalid notification scheduling
        guard currentState.remainingSeconds > 0 else {
            print("⚠️ FocusTimerService: Cannot schedule notification with remainingSeconds <= 0")
            return
        }

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

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ FocusTimerService: Failed to schedule notification - \(error.localizedDescription)")
            }
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "focus_phase_work",
            "focus_phase_shortBreak",
            "focus_phase_longBreak"
        ])
    }

    // MARK: - Notification Handling

    #if !os(watchOS)
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
            NotificationNames.timerStateChanged as CFString,
            nil,
            .deliverImmediately
        )
    }
    #endif

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
        TimeFormatter.format(seconds: remainingSeconds)
    }

    var completedPomodoros: Int { state?.completedPomodoros ?? 0 }
    var pomodorosBeforeLongBreak: Int { state?.pomodorosBeforeLongBreak ?? TimerDefaults.pomodorosBeforeLongBreak }
    var progress: Double {
        guard let state = state, state.totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(state.remainingSeconds) / Double(state.totalSeconds))
    }
    var focusedTaskTitle: String? { state?.taskTitle }
}

// MARK: - Int Helper

private extension Int {
    func nonZero(default defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
