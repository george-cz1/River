import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.9),
            icon: UIImage(systemName: "hand.raised.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Focus Time",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session",
                color: .white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.9),
            icon: UIImage(systemName: "hand.raised.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Category Blocked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This category is blocked during your focus session",
                color: .white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.9),
            icon: UIImage(systemName: "hand.raised.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This website is blocked during your focus session",
                color: .white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.9),
            icon: UIImage(systemName: "hand.raised.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Website Category Blocked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This website category is blocked during your focus session",
                color: .white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)
        )
    }
}
