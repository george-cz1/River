import SwiftUI
import SwiftData

struct MacDeletedTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\DeletedTask.deletedAt, order: .reverse)])
    private var deletedTasks: [DeletedTask]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Done") { dismiss() }
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.sage)
                    .buttonStyle(.plain)

                Spacer()

                Text("Deleted Tasks")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if !deletedTasks.isEmpty {
                    Button("Clear All") { clearAll() }
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.destructive)
                        .buttonStyle(.plain)
                } else {
                    // Balance the layout
                    Text("Clear All")
                        .font(AppFonts.body)
                        .hidden()
                }
            }
            .padding(16)

            Divider()

            if deletedTasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .background(AppColors.background)
        .frame(width: 480, height: 480)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "trash",
            title: "No deleted tasks",
            subtitle: "Tasks you delete will appear here",
            iconSize: 56
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var taskList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(deletedTasks) { deletedTask in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deletedTask.title)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textPrimary)

                            Text("Deleted \(deletedTask.deletedAt, style: .relative) ago")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .contextMenu {
                        Button("Restore") { restoreTask(deletedTask) }
                        Divider()
                        Button("Delete Forever", role: .destructive) {
                            modelContext.delete(deletedTask)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func restoreTask(_ deletedTask: DeletedTask) {
        let newTask = FocusTask(title: deletedTask.title, sortOrder: 0)
        modelContext.insert(newTask)
        modelContext.delete(deletedTask)
    }

    private func clearAll() {
        for task in deletedTasks {
            modelContext.delete(task)
        }
    }
}

#Preview {
    MacDeletedTasksView()
}
