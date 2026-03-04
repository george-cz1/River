import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .today

    enum Tab {
        case today, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView()
                .tabItem {
                    Label("Today", systemImage: "scope")
                }
                .tag(Tab.today)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(AppColors.focusBlue)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    // MARK: - Deep Links (Dynamic Island controls)

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "river" else { return }

        let timerService = FocusTimerService.shared

        switch url.host {
        case "pomodoro":
            switch url.pathComponents.dropFirst().first {
            case "start":
                timerService.startTimer()
            case "pause":
                timerService.pauseTimer()
            case "skip":
                timerService.skipPhase()
            default:
                break
            }
        default:
            break
        }
    }
}
