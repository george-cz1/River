import SwiftUI
import SwiftData

struct MacTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\FocusTask.sortOrder), SortDescriptor(\FocusTask.createdAt)])
    private var tasks: [FocusTask]

    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var timerService = FocusTimerService.shared

    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var showingProUpgrade = false
    @State private var isCompletedSectionExpanded = false
    @FocusState private var isTextFieldFocused: Bool

    private let freeTaskLimit = 2

    var incompleteTasks: [FocusTask] { tasks.filter { !$0.isCompleted } }
    var completedTasks: [FocusTask] { tasks.filter { $0.isCompleted } }
    var focusedTask: FocusTask? {
        incompleteTasks.first { timerService.focusedTaskTitle == $0.title }
    }
    var unfocusedTasks: [FocusTask] {
        incompleteTasks.filter { timerService.focusedTaskTitle != $0.title }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                focusCard

                HStack {
                    Text("Tasks")
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    addButton
                }

                if unfocusedTasks.isEmpty && !isAddingTask {
                    emptyTasksState
                } else {
                    taskList
                }

                if !completedTasks.isEmpty {
                    completedSection
                }

                Spacer(minLength: 32)
            }
            .padding(24)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingProUpgrade) {
            MacProUpgradeView()
                .environment(purchaseManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            timerService.handleAppForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            timerService.handleAppBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: .riverNewTask)) { _ in
            openAddTask()
        }
    }

    // MARK: - Focus Card

    @ViewBuilder
    private var focusCard: some View {
        if let focused = focusedTask {
            MacFocusCard(
                task: focused,
                timerService: timerService,
                onUnfocus: { unfocusTask(focused) },
                onComplete: { completeTask(focused) }
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.sage)

                Text("No task in focus")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Double-click a task to start focusing")
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
                MacInlineAddCard(
                    title: $newTaskTitle,
                    isFocused: $isTextFieldFocused,
                    onAdd: addTask,
                    onDone: {
                        withAnimation { isAddingTask = false; newTaskTitle = "" }
                    }
                )
            }

            ForEach(unfocusedTasks) { task in
                MacTaskRow(
                    task: task,
                    onComplete: { completeTask(task) },
                    onFocus: { focusTask(task) },
                    onDelete: { deleteTask(task) }
                )
            }
        }
    }

    private var emptyTasksState: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All caught up!",
            subtitle: "Add a task to get started",
            iconSize: 48
        )
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isCompletedSectionExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .rotationEffect(.degrees(isCompletedSectionExpanded ? 90 : 0))

                    Text("Completed (\(completedTasks.count))")
                        .font(AppFonts.headline)
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isCompletedSectionExpanded {
                ForEach(completedTasks) { task in
                    MacCompletedTaskRow(
                        task: task,
                        onUncomplete: { uncompleteTask(task) },
                        onDelete: { deleteTask(task) }
                    )
                }
            }
        }
        .padding(.top, 8)
    }

    private var addButton: some View {
        Button {
            openAddTask()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.sage)
        }
        .buttonStyle(.plain)
    }

    private func openAddTask() {
        let isAtLimit = !purchaseManager.isPro && incompleteTasks.count >= freeTaskLimit
        if isAtLimit {
            showingProUpgrade = true
        } else {
            newTaskTitle = ""
            withAnimation { isAddingTask = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Actions

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1
        let task = FocusTask(title: trimmed, sortOrder: sortOrder)
        modelContext.insert(task)
        newTaskTitle = ""

        let newCount = incompleteTasks.count + 1
        let isAtLimit = !purchaseManager.isPro && newCount >= freeTaskLimit
        if isAtLimit {
            withAnimation { isAddingTask = false }
        } else {
            isTextFieldFocused = true
        }
    }

    private func focusTask(_ task: FocusTask) {
        timerService.startFocus(taskTitle: task.title)
    }

    private func unfocusTask(_ task: FocusTask) {
        timerService.endFocus()
    }

    private func deleteTask(_ task: FocusTask) {
        let deletedTask = DeletedTask(from: task)
        modelContext.insert(deletedTask)
        if timerService.focusedTaskTitle == task.title { timerService.endFocus() }
        modelContext.delete(task)
    }

    private func completeTask(_ task: FocusTask) {
        task.isCompleted = true
        if timerService.focusedTaskTitle == task.title { timerService.endFocus() }
    }

    private func uncompleteTask(_ task: FocusTask) {
        task.isCompleted = false
    }
}

// MARK: - Mac Focus Card

private struct MacFocusCard: View {
    let task: FocusTask
    @Bindable var timerService: FocusTimerService
    let onUnfocus: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Upper: task card
            HStack(spacing: 12) {
                Button(action: onComplete) {
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

                Button(action: onUnfocus) {
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

            // Lower: timer controls
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timerService.formattedTime)
                            .font(AppFonts.timerDisplay(size: 48))
                            .foregroundStyle(AppColors.sage)
                            .id(timerService.tickCount)

                        Text(timerService.timerPhase.displayName.uppercased())
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundStyle(AppColors.sage)
                            .tracking(1)
                    }

                    Spacer()

                    Button(action: { timerService.toggleTimer() }) {
                        Image(systemName: timerService.isTimerRunning ? "pause" : "play")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColors.sage)
                            .frame(width: 72, height: 72)
                            .contentShape(Circle())
                            .overlay(Circle().stroke(AppColors.sage, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                let total = timerService.pomodorosBeforeLongBreak
                let completed = timerService.completedPomodoros % total
                let isWorkPhase = timerService.timerPhase == .work

                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { index in
                        CycleDot(
                            isFilled: index < completed,
                            isInProgress: index == completed && isWorkPhase,
                            color: AppColors.sage,
                            size: 8
                        )
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(16)
        .background(AppColors.sageSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Mac Task Row

private struct MacTaskRow: View {
    let task: FocusTask
    let onComplete: () -> Void
    let onFocus: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
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
            Button("Focus") { onFocus() }
            Button("Complete") { onComplete() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
        .onTapGesture(count: 2) { onFocus() }
    }
}

// MARK: - Mac Completed Task Row

private struct MacCompletedTaskRow: View {
    let task: FocusTask
    let onUncomplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onUncomplete) {
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
            Button("Uncomplete") { onUncomplete() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Mac Inline Add Card

private struct MacInlineAddCard: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    let onAdd: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(AppColors.sage, lineWidth: 2)
                .frame(width: 20, height: 20)

            TextField("What do you need to do?", text: $title)
                .font(AppFonts.body)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    let trimmed = title.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { onAdd() } else { onDone() }
                }

            Button(action: onDone) {
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
}

#Preview {
    MacTaskListView()
        .environment(PurchaseManager.shared)
}
