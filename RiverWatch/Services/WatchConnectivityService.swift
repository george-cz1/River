import Foundation
import WatchConnectivity

/// Manages communication between the Apple Watch and companion iPhone app.
/// Receives timer state from iPhone and sends control commands back.
@MainActor
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send Command

    func sendCommand(_ command: String) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("⌚ WatchConnectivity: iPhone not reachable, command '\(command)' dropped")
            return
        }
        WCSession.default.sendMessage(["command": command], replyHandler: nil) { error in
            print("⌚ WatchConnectivity: command '\(command)' failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Apply Received State

    private func applyState(from data: Data) {
        let state = try? JSONDecoder().decode(TimerState?.self, from: data)
        FocusTimerService.shared.applyRemoteState(state)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error { print("⌚ WatchConnectivity Watch: activation failed: \(error.localizedDescription)") }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message["timerState"] as? Data else { return }
        Task { @MainActor in self.applyState(from: data) }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = applicationContext["timerState"] as? Data else { return }
        Task { @MainActor in self.applyState(from: data) }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        guard let data = userInfo["timerState"] as? Data else { return }
        Task { @MainActor in self.applyState(from: data) }
    }
}
