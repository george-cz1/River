import Foundation

/// Persisted state for the Pomodoro timer, shared between app and widget via App Group
struct TimerState: Codable, Equatable, Sendable {

    // MARK: - State Properties

    let taskTitle: String
    var timerPhase: TimerPhase
    var isTimerRunning: Bool
    var phaseEndDate: Date?
    var totalSeconds: Int
    var completedPomodoros: Int

    // MARK: - Configurable Durations (seconds)
    var workDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int
    var pomodorosBeforeLongBreak: Int

    // MARK: - Init

    init(
        taskTitle: String,
        workDuration: Int = TimerDefaults.workDuration,
        shortBreakDuration: Int = TimerDefaults.shortBreakDuration,
        longBreakDuration: Int = TimerDefaults.longBreakDuration,
        pomodorosBeforeLongBreak: Int = TimerDefaults.pomodorosBeforeLongBreak
    ) {
        self.taskTitle = taskTitle
        self.timerPhase = .idle
        self.isTimerRunning = false
        self.phaseEndDate = nil
        self.totalSeconds = workDuration
        self.completedPomodoros = 0
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.pomodorosBeforeLongBreak = pomodorosBeforeLongBreak
    }

    // MARK: - Computed Properties

    var remainingSeconds: Int {
        guard isTimerRunning, let endDate = phaseEndDate else {
            return totalSeconds
        }
        return max(0, Int(endDate.timeIntervalSinceNow))
    }

    var contentState: FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            isTimerRunning: isTimerRunning,
            timerPhase: timerPhase,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            completedPomodoros: completedPomodoros,
            isCompleted: false,
            phaseEndDate: phaseEndDate
        )
    }

    // MARK: - Timer Control

    mutating func startWorkPhase() {
        timerPhase = .work
        totalSeconds = workDuration
        isTimerRunning = true
        phaseEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
    }

    mutating func startShortBreak() {
        timerPhase = .shortBreak
        totalSeconds = shortBreakDuration
        isTimerRunning = true
        phaseEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
    }

    mutating func startLongBreak() {
        timerPhase = .longBreak
        totalSeconds = longBreakDuration
        isTimerRunning = true
        phaseEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
    }

    mutating func pause() {
        guard isTimerRunning else { return }
        totalSeconds = remainingSeconds
        isTimerRunning = false
        phaseEndDate = nil
    }

    mutating func resume() {
        guard !isTimerRunning, totalSeconds > 0 else { return }
        isTimerRunning = true
        phaseEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
    }

    mutating func skipToNextPhase() {
        completeCurrentPhase()
    }

    mutating func completeCurrentPhase() {
        switch timerPhase {
        case .idle:
            startWorkPhase()
        case .work:
            completedPomodoros += 1
            if completedPomodoros % pomodorosBeforeLongBreak == 0 {
                startLongBreak()
            } else {
                startShortBreak()
            }
        case .shortBreak, .longBreak:
            startWorkPhase()
        }
    }

    mutating func resetToIdle() {
        timerPhase = .idle
        isTimerRunning = false
        phaseEndDate = nil
        totalSeconds = 0
    }
}
