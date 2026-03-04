import SwiftUI
import SwiftData

struct DeletedTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\DeletedTask.deletedAt, order: .reverse)])
    private var deletedTasks: [DeletedTask]

    var body: some View {
        NavigationStack {
            Group {
                if deletedTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Deleted Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.focusBlue)
                }
                if !deletedTasks.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All", role: .destructive) {
                            clearAll()
                        }
                        .foregroundStyle(AppColors.destructive)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.border)

            Text("No deleted tasks")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)

            Text("Tasks you delete will appear here")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private var taskList: some View {
        List {
            ForEach(deletedTasks) { deletedTask in
                VStack(alignment: .leading, spacing: 4) {
                    Text(deletedTask.title)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Deleted \(deletedTask.deletedAt, style: .relative) ago")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(deletedTask)
                    } label: {
                        Label("Remove", systemImage: "xmark")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        restoreTask(deletedTask)
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                    .tint(AppColors.focusBlue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
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
