import ManagedSettings
import ManagedSettingsUI

class ShieldActionExtension: ShieldActionDelegate {
    func handle(action: ShieldAction, for application: Application) async -> ShieldActionResponse {
        // Close the blocked app when user taps the shield button
        return .close
    }

    func handle(action: ShieldAction, for webDomain: WebDomain) async -> ShieldActionResponse {
        // Close the browser when user taps the shield button
        return .close
    }

    func handle(action: ShieldAction, for category: ActivityCategory) async -> ShieldActionResponse {
        // Close the app when user taps the shield button
        return .close
    }
}
