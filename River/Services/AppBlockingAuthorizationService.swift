import FamilyControls
import Foundation

@MainActor
@Observable
class AppBlockingAuthorizationService {
    static let shared = AppBlockingAuthorizationService()

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    private init() {
        updateAuthorizationStatus()
    }

    func requestAuthorization() async throws {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            updateAuthorizationStatus()
        } catch {
            print("Failed to request Screen Time authorization: \(error)")
            throw error
        }
    }

    func updateAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
}
