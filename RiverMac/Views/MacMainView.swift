import SwiftUI

struct MacMainView: View {
    @State private var selectedView: SidebarItem? = .today
    @Environment(PurchaseManager.self) private var purchaseManager

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedView) { item in
                Label {
                    Text(item.title)
                        .font(AppFonts.body)
                } icon: {
                    Image(systemName: item.icon)
                        .foregroundStyle(selectedView == item ? AppColors.river : AppColors.textSecondary)
                }
                .tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
        } detail: {
            if let selectedView = selectedView {
                selectedView.destination
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.border)
                    Text("Select an item")
                        .font(AppFonts.headline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
            }
        }
    }
}

// MARK: - Sidebar Items

enum SidebarItem: String, CaseIterable, Identifiable {
    case today
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: return "scope"
        case .settings: return "gearshape"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .today:
            MacTaskListView()
        case .settings:
            MacSettingsView()
        }
    }
}

#Preview {
    MacMainView()
        .environment(PurchaseManager.shared)
}
