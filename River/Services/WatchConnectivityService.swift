import Foundation
import WatchConnectivity

/// Manages real-time communication between the iOS app and Apple Watch.
/// Sends timer state on every persist cycle and receives control commands from the watch.
@MainActor
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send State

    /// Called by FocusTimerService.persistState() to push the latest state to the watch.
    func sendTimerState(_ state: TimerState?) {
        guard WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(state) else { return }
        let payload: [String: Any] = ["timerState": data]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                // Fall back to applicationContext for delivery guarantee
                try? WCSession.default.updateApplicationContext(payload)
                print("⌚ WatchConnectivity: sendMessage failed (\(error.localizedDescription)), used applicationContext")
            }
        } else {
            do {
                try WCSession.default.updateApplicationContext(payload)
            } catch {
                print("⌚ WatchConnectivity: updateApplicationContext failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error { print("⌚ WatchConnectivity iOS: activation failed: \(error.localizedDescription)") }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let command = message["command"] as? String else { return }
        Task { @MainActor in
            switch command {
            case "pause":   FocusTimerService.shared.pauseTimer()
            case "resume":  FocusTimerService.shared.resumeTimer()
            case "skip":    FocusTimerService.shared.skipPhase()
            case "stop":    FocusTimerService.shared.endFocus()
            default:        break
            }
        }
    }
}
