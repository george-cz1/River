//
//  MacTaskListView.swift
//  RiverMac
//
//  Task list view for macOS - iOS-consistent design
//

import SwiftUI

struct MacTaskListView: View {
    @State private var tasks: [SimpleTask] = []
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false
    @State private var timerService = FocusTimerService.shared

    var incompleteTasks: [SimpleTask] { tasks.filter { !$0.isCompleted } }
    var completedTasks: [SimpleTask] { tasks.filter { $0.isCompleted } }
    var focusedTask: SimpleTask? {
        incompleteTasks.first { $0.title == timerService.focusedTaskTitle }
    }
    var unfocusedTasks: [SimpleTask] {
        incompleteTasks.filter { $0.title != timerService.focusedTaskTitle }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Focus card
                focusCard

                // Header with add button
                HStack {
                    Text("Tasks")
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Button {
                        isAddingTask = true
                        newTaskTitle = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.sage)
                    }
                    .buttonStyle(.plain)
                }

                // Task list
                if unfocusedTasks.isEmpty && !isAddingTask {
                    emptyState
                } else {
                    taskList
                }

                // Completed tasks
                if !completedTasks.isEmpty {
                    completedSection
                }

                Spacer(minLength: 32)
            }
            .padding(24)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Focus Card

    @ViewBuilder
    private var focusCard: some View {
        if let focused = focusedTask {
            VStack(alignment: .leading, spacing: 12) {
                Text("Task in focus")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 12) {
                    Circle()
                        .stroke(AppColors.sage, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    Text(focused.title)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)

                    Spacer()

                    Button {
                        timerService.endFocus()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .padding(16)
            .background(AppColors.sageSoft)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.sage)

                Text("No task in focus")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Right-click a task and select Focus to begin")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(AppColors.sageSoft)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        VStack(spacing: 12) {
            if isAddingTask {
                addTaskCard
            }

            ForEach(unfocusedTasks) { task in
                taskRow(task)
            }
        }
    }

    private var addTaskCard: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(AppColors.sage, lineWidth: 2)
                .frame(width: 20, height: 20)

            TextField("What do you need to do?", text: $newTaskTitle)
                .font(AppFonts.body)
                .textFieldStyle(.plain)
                .onSubmit {
                    addTask()
                }

            Button {
                if !newTaskTitle.isEmpty {
                    addTask()
                } else {
                    isAddingTask = false
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.sage)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.sage, lineWidth: 2)
        )
    }

    private func taskRow(_ task: SimpleTask) -> some View {
        HStack(spacing: 12) {
            Button {
                completeTask(task)
            } label: {
                Circle()
                    .stroke(AppColors.sage, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .contextMenu {
            Button("Focus") {
                focusTask(task)
            }
            Button("Complete") {
                completeTask(task)
            }
            Divider()
            Button("Delete", role: .destructive) {
                deleteTask(task)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All caught up!",
            subtitle: "Add a task to get started",
            iconSize: 48
        )
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed (\(completedTasks.count))")
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textSecondary)

            ForEach(completedTasks) { task in
                completedRow(task)
            }
        }
    }

    private func completedRow(_ task: SimpleTask) -> some View {
        HStack(spacing: 12) {
            Button {
                uncompleteTask(task)
            } label: {
                Circle()
                    .fill(AppColors.sage)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .strikethrough(color: AppColors.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .opacity(0.7)
        .contextMenu {
            Button("Uncomplete") {
                uncompleteTask(task)
            }
            Button("Delete", role: .destructive) {
                deleteTask(task)
            }
        }
    }

    // MARK: - Actions

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let task = SimpleTask(title: trimmed)
        tasks.append(task)
        newTaskTitle = ""
    }

    private func focusTask(_ task: SimpleTask) {
        timerService.startFocus(taskTitle: task.title)
    }

    private func completeTask(_ task: SimpleTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            if timerService.focusedTaskTitle == task.title {
                timerService.endFocus()
            }
        }
    }

    private func uncompleteTask(_ task: SimpleTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = false
        }
    }

    private func deleteTask(_ task: SimpleTask) {
        if timerService.focusedTaskTitle == task.title {
            timerService.endFocus()
        }
        tasks.removeAll { $0.id == task.id }
    }
}

// MARK: - Simple Task Model

struct SimpleTask: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

#Preview {
    MacTaskListView()
}
