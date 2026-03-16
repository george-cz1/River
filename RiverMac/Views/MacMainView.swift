//
//  MacMainView.swift
//  RiverMac
//
//  Main window view with navigation split view layout
//

import SwiftUI

struct MacMainView: View {
    @State private var selectedView: SidebarItem? = .focus
    @Bindable private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationSplitView {
            // Sidebar
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
            // Detail view
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
    case focus
    case tasks
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .tasks: return "Tasks"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .focus: return "timer"
        case .tasks: return "list.bullet"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .focus:
            MacFocusView()
        case .tasks:
            MacTaskListView()
        case .history:
            MacHistoryView()
        case .settings:
            MacSettingsView()
        }
    }
}

#Preview {
    MacMainView()
}
