import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\FocusTask.sortOrder), SortDescriptor(\FocusTask.createdAt)])
    private var tasks: [FocusTask]

    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var showingProUpgrade = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var isCompletedSectionExpanded: Bool = false

    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var timerService = FocusTimerService.shared

    private let freeTaskLimit = 2

    var incompleteTasks: [FocusTask] { tasks.filter { !$0.isCompleted } }
    var focusedTask: FocusTask? {
        incompleteTasks.first { task in
            timerService.focusedTaskTitle == task.title
        }
    }
    var unfocusedTasks: [FocusTask] {
        incompleteTasks.filter { task in
            timerService.focusedTaskTitle != task.title
        }
    }
    var completedTasks: [FocusTask] { tasks.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Focus Card (always visible)
                    focusCard

                    // Task List Header
                    HStack {
                        Text("Tasks")
                            .font(AppFonts.title)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        addButton
                    }
                    .padding(.horizontal, 20)

                    // Task List
                    if unfocusedTasks.isEmpty && !isAddingTask {
                        emptyTasksState
                    } else {
                        taskList
                    }

                    // Completed Tasks Section
                    if !completedTasks.isEmpty {
                        completedSection
                    }
                }
                .padding(.top, 20)
            }
            .background(AppColors.background)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeView()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                timerService.handleAppForeground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                timerService.handleAppBackground()
            }
        }
    }

    // MARK: - Focus Card

    @ViewBuilder
    private var focusCard: some View {
        if let focused = focusedTask {
            VStack(alignment: .leading, spacing: 12) {
                Text("Task in focus")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 20)

                SwipeableFocusCard(
                    task: focused,
                    timerService: timerService,
                    onUnfocus: { unfocusTask(focused) },
                    onComplete: { completeTask(focused) }
                )
            }
        } else {
            // Empty focus state
            VStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.sage)

                Text("No task in focus")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Double tap a task to start focusing")
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
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        VStack(spacing: 12) {
            // Inline add task card
            if isAddingTask {
                InlineAddTaskCard(
                    title: $newTaskTitle,
                    isFocused: $isTextFieldFocused,
                    onAdd: {
                        addTask()
                    },
                    onDone: {
                        withAnimation {
                            isAddingTask = false
                            newTaskTitle = ""
                        }
                    }
                )
            }

            ForEach(unfocusedTasks) { task in
                SwipeableTaskRow(
                    task: task,
                    onComplete: { completeTask(task) },
                    onFocus: { focusTask(task) },
                    onDelete: { deleteTask(task) }
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyTasksState: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All caught up!",
            subtitle: "Add a task to get started",
            iconSize: 40
        )
    }

    private var completedSection: some View {
        VStack(spacing: 12) {
            // Collapsible header
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

            // Completed tasks list (when expanded)
            if isCompletedSectionExpanded {
                ForEach(completedTasks) { task in
                    CompletedTaskRow(
                        task: task,
                        onUncomplete: { uncompleteTask(task) },
                        onDelete: { deleteTask(task) }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var addButton: some View {
        Button {
            let isAtLimit = !purchaseManager.isPro && incompleteTasks.count >= freeTaskLimit
            if isAtLimit {
                showingProUpgrade = true
            } else {
                newTaskTitle = ""
                withAnimation {
                    isAddingTask = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.sage)
        }
    }

    // MARK: - Actions

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1
        let task = FocusTask(title: trimmed, sortOrder: sortOrder)
        modelContext.insert(task)

        // Clear title but keep card open
        newTaskTitle = ""

        // Check if at free tier limit after adding
        let newCount = incompleteTasks.count + 1  // +1 because SwiftData may not have updated yet
        let isAtLimit = !purchaseManager.isPro && newCount >= freeTaskLimit

        if isAtLimit {
            withAnimation {
                isAddingTask = false
            }
        } else {
            // Re-focus for next task
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
        // Store in deleted tasks
        let deletedTask = DeletedTask(from: task)
        modelContext.insert(deletedTask)

        // End focus if this task was focused
        if timerService.focusedTaskTitle == task.title {
            timerService.endFocus()
        }

        // Delete the task
        modelContext.delete(task)
    }

    private func completeTask(_ task: FocusTask) {
        // Mark task as completed
        task.isCompleted = true

        // End focus if this task was focused
        if timerService.focusedTaskTitle == task.title {
            timerService.endFocus()
        }
    }

    private func uncompleteTask(_ task: FocusTask) {
        task.isCompleted = false
    }

    private var phaseColor: Color {
        timerService.timerPhase.isBreak ? AppColors.breakPhase : AppColors.workPhase
    }
}

// MARK: - Swipeable Task Row

private struct SwipeableTaskRow: View {
    let task: FocusTask
    let onComplete: () -> Void
    let onFocus: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var dragStartOffset: CGFloat = 0
    @State private var isHorizontalGesture: Bool? = nil

    private enum SwipeDirection { case left, right }

    private let actionButtonWidth: CGFloat = 80

    var body: some View {
        ZStack {
            // Left action (Focus) - revealed on swipe right
            if offset > 0 {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onFocus()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "scope")
                                .font(.system(size: 20))
                            Text("Focus")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: actionButtonWidth)
                    }
                    Spacer()
                }
                .frame(height: 56)
                .background(AppColors.sage)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Right action (Delete) - revealed on swipe left
            if offset < 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDelete()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20))
                            Text("Delete")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: actionButtonWidth)
                    }
                }
                .frame(height: 56)
                .background(AppColors.destructive)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Task card (center, slides both directions)
            HStack(spacing: 12) {
                Button(action: onComplete) {
                    Circle()
                        .stroke(task.isCompleted ? AppColors.sage : AppColors.sage, lineWidth: 2)
                        .background(
                            Circle()
                                .fill(task.isCompleted ? AppColors.sage : Color.clear)
                        )
                        .frame(width: 20, height: 20)
                        .overlay(
                            task.isCompleted ?
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                : nil
                        )
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
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        // PERMANENT LOCK: Once determined not horizontal, stay locked out
                        if isHorizontalGesture == false { return }

                        // VELOCITY CHECK: Ignore if started with high velocity (scroll momentum)
                        if isHorizontalGesture == nil {
                            let speed = sqrt(pow(gesture.velocity.width, 2) + pow(gesture.velocity.height, 2))
                            if speed > 800 {
                                return
                            }
                        }

                        // DIRECTION DETECTION: Lock direction on first significant movement
                        if isHorizontalGesture == nil {
                            let w = abs(gesture.translation.width)
                            let h = abs(gesture.translation.height)
                            if w > 15 || h > 15 {
                                // Require CLEAR horizontal dominance (1.3x ratio)
                                isHorizontalGesture = w > h * 1.3
                                if isHorizontalGesture == false { return }
                            }
                        }

                        guard isHorizontalGesture == true else { return }

                        isSwiping = true
                        let translation = gesture.translation.width

                        // Capture starting offset on first movement
                        if swipeDirection == nil {
                            dragStartOffset = offset
                        }

                        // Lock direction once past threshold (20pt)
                        let lockThreshold: CGFloat = 20
                        if swipeDirection == nil && abs(translation) > lockThreshold {
                            swipeDirection = translation > 0 ? .right : .left
                        }

                        // Calculate new offset from drag start
                        let newOffset = dragStartOffset + translation

                        // Clamp based on locked direction (or allow both if not locked yet)
                        switch swipeDirection {
                        case .right:
                            offset = max(0, min(actionButtonWidth, newOffset))
                        case .left:
                            offset = min(0, max(-actionButtonWidth, newOffset))
                        case nil:
                            offset = max(-actionButtonWidth, min(actionButtonWidth, newOffset))
                        }
                    }
                    .onEnded { gesture in
                        let velocity = gesture.velocity.width
                        let velocityThreshold: CGFloat = 300

                        withAnimation(.spring(response: 0.3)) {
                            // Check if swiping back from an open position
                            let swipingBackFromRight = dragStartOffset > actionButtonWidth * 0.5 && swipeDirection == .left
                            let swipingBackFromLeft = dragStartOffset < -actionButtonWidth * 0.5 && swipeDirection == .right

                            if swipingBackFromRight {
                                // Swiping left from a right-open position
                                if velocity < -velocityThreshold {
                                    // Fast swipe back to left, close it
                                    offset = 0
                                } else if abs(offset) > actionButtonWidth * 0.7 {
                                    // Still very close to open position, keep it open
                                    offset = actionButtonWidth
                                } else {
                                    // Swiped back enough, close it
                                    offset = 0
                                }
                            } else if swipingBackFromLeft {
                                // Swiping right from a left-open position
                                if velocity > velocityThreshold {
                                    // Fast swipe back to right, close it
                                    offset = 0
                                } else if abs(offset) > actionButtonWidth * 0.7 {
                                    // Still very close to open position, keep it open
                                    offset = -actionButtonWidth
                                } else {
                                    // Swiped back enough, close it
                                    offset = 0
                                }
                            } else {
                                // Normal swipe from closed position
                                if velocity > velocityThreshold && swipeDirection == .right {
                                    offset = actionButtonWidth
                                } else if velocity < -velocityThreshold && swipeDirection == .left {
                                    offset = -actionButtonWidth
                                }
                                // Position-based snap (50% threshold)
                                else if offset > actionButtonWidth * 0.5 {
                                    offset = actionButtonWidth
                                } else if offset < -actionButtonWidth * 0.5 {
                                    offset = -actionButtonWidth
                                } else {
                                    offset = 0
                                }
                            }
                        }

                        // Reset state
                        swipeDirection = nil
                        dragStartOffset = 0
                        isHorizontalGesture = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSwiping = false
                        }
                    }
            )
            .onTapGesture(count: 2) {
                // Double tap to focus
                if !isSwiping {
                    onFocus()
                }
            }
            .onTapGesture {
                // Single tap to close swipe
                if offset != 0 {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
            }
        }
        .clipped()
    }
}

// MARK: - Swipeable Focus Card

private struct SwipeableFocusCard: View {
    let task: FocusTask
    @Bindable var timerService: FocusTimerService
    let onUnfocus: () -> Void
    let onComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isHorizontalGesture: Bool? = nil
    private let unfocusButtonWidth: CGFloat = 80

    var body: some View {
        // Focus card with blue background container
        VStack(spacing: 16) {
            // UPPER SECTION: Swipeable white task card
            ZStack(alignment: .leading) {
                // Unfocus button (revealed on swipe right) - only behind task card
                if offset > 0 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onUnfocus()
                        }
                    }) {
                        HStack {
                            VStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Unfocus")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white)
                            .frame(width: unfocusButtonWidth)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .background(AppColors.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // White task card (swipeable)
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
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { gesture in
                            // PERMANENT LOCK: Once determined not horizontal, stay locked out
                            if isHorizontalGesture == false { return }

                            // VELOCITY CHECK: Ignore if started with high velocity (scroll momentum)
                            if isHorizontalGesture == nil {
                                let speed = sqrt(pow(gesture.velocity.width, 2) + pow(gesture.velocity.height, 2))
                                if speed > 800 {
                                    return
                                }
                            }

                            // DIRECTION DETECTION: Lock direction on first significant movement
                            if isHorizontalGesture == nil {
                                let w = abs(gesture.translation.width)
                                let h = abs(gesture.translation.height)
                                if w > 15 || h > 15 {
                                    // Require CLEAR horizontal dominance (1.3x ratio)
                                    isHorizontalGesture = w > h * 1.3
                                    if isHorizontalGesture == false { return }
                                }
                            }

                            guard isHorizontalGesture == true else { return }

                            let translation = gesture.translation.width
                            // Only allow right swipe (positive offset)
                            if translation > 0 {
                                offset = min(translation, unfocusButtonWidth)
                            } else if offset > 0 {
                                // Allow swiping back to close
                                offset = max(0, offset + translation)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(response: 0.3)) {
                                // Snap to unfocus button if swiped far enough
                                if offset > unfocusButtonWidth / 2 {
                                    offset = unfocusButtonWidth
                                } else {
                                    offset = 0
                                }
                            }
                            // Reset direction tracking
                            isHorizontalGesture = nil
                        }
                )
                .onTapGesture {
                    // Tap to close swipe
                    if offset != 0 {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                    }
                }
            }
            .clipped()

            // LOWER SECTION: Timer controls (fixed, non-swipeable)
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    // Left: Timer + Phase badge
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

                    // Right: Play/Pause button
                    Button(action: { timerService.toggleTimer() }) {
                        Image(systemName: timerService.isTimerRunning ? "pause" : "play")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColors.sage)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.sage, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Cycle dots (centered at bottom)
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
        .padding(.horizontal, 20)
    }
}

// MARK: - Completed Task Row

private struct CompletedTaskRow: View {
    let task: FocusTask
    let onUncomplete: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isHorizontalGesture: Bool? = nil
    private let deleteButtonWidth: CGFloat = 80

    var body: some View {
        ZStack {
            // Delete action (swipe left)
            if offset < 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { offset = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDelete()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20))
                            Text("Delete")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: deleteButtonWidth)
                    }
                }
                .frame(height: 56)
                .background(AppColors.destructive)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Task card
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
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        // PERMANENT LOCK: Once determined not horizontal, stay locked out
                        if isHorizontalGesture == false { return }

                        // VELOCITY CHECK: Ignore if started with high velocity (scroll momentum)
                        if isHorizontalGesture == nil {
                            let speed = sqrt(pow(gesture.velocity.width, 2) + pow(gesture.velocity.height, 2))
                            if speed > 800 {
                                return
                            }
                        }

                        // DIRECTION DETECTION: Lock direction on first significant movement
                        if isHorizontalGesture == nil {
                            let w = abs(gesture.translation.width)
                            let h = abs(gesture.translation.height)
                            if w > 15 || h > 15 {
                                // Require CLEAR horizontal dominance (1.3x ratio)
                                isHorizontalGesture = w > h * 1.3
                                if isHorizontalGesture == false { return }
                            }
                        }

                        guard isHorizontalGesture == true else { return }

                        let translation = gesture.translation.width
                        if translation < 0 {
                            offset = max(-deleteButtonWidth, translation)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3)) {
                            offset = offset < -deleteButtonWidth / 2 ? -deleteButtonWidth : 0
                        }
                        // Reset direction tracking
                        isHorizontalGesture = nil
                    }
            )
            .onTapGesture {
                if offset != 0 {
                    withAnimation(.spring(response: 0.3)) { offset = 0 }
                }
            }
        }
        .clipped()
    }
}

// MARK: - Inline Add Task Card

private struct InlineAddTaskCard: View {
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
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    let trimmed = title.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        onAdd()
                    }
                }

            // Always-visible checkmark to close
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
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Cycle Dot Component

private struct CycleDot: View {
    let isFilled: Bool
    let isInProgress: Bool
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            // Base empty circle
            Circle()
                .fill(AppColors.border)

            // Half-fill for in-progress (left half)
            if isInProgress && !isFilled {
                Circle()
                    .fill(color)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                            Color.clear
                        }
                    )
            }

            // Full fill for completed
            if isFilled {
                Circle()
                    .fill(color)
            }
        }
        .frame(width: size, height: size)
    }
}
