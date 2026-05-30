import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\FocusTask.sortOrder)]) private var existingTasks: [FocusTask]
    @Environment(PurchaseManager.self) private var purchaseManager

    @State private var planningService = AIPlanningService.shared
    @State private var recordingService = AudioRecordingService()
    @State private var viewState: ViewState = .idle
    @State private var showingTextInput = false
    @State private var textInput = ""
    @State private var planResult: PlanResult?
    @State private var proposedTasks: [ProposedTask] = []
    @State private var expandedTaskID: UUID?
    @State private var showingProUpgrade = false
    @State private var errorMessage: String?

    let onTasksAdded: () -> Void

    enum ViewState {
        case idle
        case recording
        case transcribing
        case planning
        case reviewing
        case added
    }

    var body: some View {
        Group {
            if !purchaseManager.isPro {
                planProGate
            } else {
                planContent
            }
        }
        .sheet(isPresented: $showingProUpgrade) {
            ProUpgradeView()
                .environment(purchaseManager)
        }
    }

    // MARK: - Pro Gate

    private var planProGate: some View {
        VStack(spacing: 24) {
            Image(systemName: "wand.and.sparkles")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.sage)

            VStack(spacing: 8) {
                Text("AI Planning")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Brain dump your thoughts — River structures them into an ADHD-friendly task list.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Unlock with Pro") { showingProUpgrade = true }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.sage)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var planContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch viewState {
                case .idle:
                    idleView
                case .recording:
                    recordingView
                case .transcribing:
                    processingView(icon: "waveform", label: "Listening…")
                case .planning:
                    processingView(icon: "brain", label: "Thinking through your day…")
                case .reviewing:
                    reviewView
                case .added:
                    addedView
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil; viewState = .idle }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("What's on your mind?")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Speak or type — River will sort it out.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if showingTextInput {
                textInputCard
            } else {
                micButton
                Button("Type instead") { withAnimation { showingTextInput = true } }
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.sage)
            }
        }
        .padding(.top, 32)
    }

    private var micButton: some View {
        Button {
            Task { await startRecording() }
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.sageSoft)
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(AppColors.sage, lineWidth: 2)
                    .frame(width: 120, height: 120)
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.sage)
            }
        }
        .buttonStyle(.plain)
    }

    private var textInputCard: some View {
        VStack(spacing: 16) {
            TextEditor(text: $textInput)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textPrimary)
                .frame(minHeight: 140)
                .padding(12)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .overlay(
                    Group {
                        if textInput.isEmpty {
                            Text("Tell me what you need to do today — don't filter, just dump…")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(20)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                )

            HStack {
                Button("Cancel") {
                    withAnimation { showingTextInput = false; textInput = "" }
                }
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Button("Plan this") {
                    Task { await runPlanningFromText() }
                }
                .font(AppFonts.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(textInput.trimmingCharacters(in: .whitespaces).isEmpty ? AppColors.border : AppColors.sage)
                .clipShape(Capsule())
                .disabled(textInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 28) {
            Text(formatElapsed(recordingService.elapsedSeconds))
                .font(AppFonts.timerDisplay(size: 48))
                .foregroundStyle(AppColors.sage)
                .monospacedDigit()

            WaveformView(levels: recordingService.levels)
                .frame(height: 60)

            Text("Tap to stop")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button {
                recordingService.stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColors.sageSoft)
                        .frame(width: 80, height: 80)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.sage)
                        .frame(width: 28, height: 28)
                }
            }
            .buttonStyle(.plain)

            Button("Cancel") {
                recordingService.cancel()
                viewState = .idle
            }
            .font(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 48)
        .onChange(of: recordingStateFinishedURL) { _, url in
            guard let url else { return }
            Task { await runPlanningFromAudio(url: url) }
        }
    }

    private var recordingStateFinishedURL: URL? {
        if case .finished(let url) = recordingService.state { return url }
        return nil
    }

    // MARK: - Processing spinner

    private func processingView(icon: String, label: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.sage)
                .symbolEffect(.pulse)

            Text(label)
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.top, 80)
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your plan for today")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                if let ack = planResult?.acknowledged {
                    Text(ack)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                if let deferred = planResult?.deferredCount, deferred > 0 {
                    Text("\(deferred) item\(deferred == 1 ? "" : "s") set aside for later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            VStack(spacing: 12) {
                ForEach($proposedTasks) { $task in
                    ProposedTaskRow(
                        task: $task,
                        isExpanded: expandedTaskID == task.id,
                        onToggleExpand: { expandedTaskID = expandedTaskID == task.id ? nil : task.id },
                        onDelete: { proposedTasks.removeAll { $0.id == task.id } }
                    )
                }
            }

            VStack(spacing: 12) {
                Button("Add all to Today") {
                    addTasksToToday()
                }
                .font(AppFonts.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(proposedTasks.isEmpty ? AppColors.border : AppColors.sage)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(proposedTasks.isEmpty)

                Button("Discard") {
                    withAnimation { proposedTasks = []; viewState = .idle; showingTextInput = false; textInput = "" }
                }
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Added

    private var addedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.sage)
                .transition(.scale.combined(with: .opacity))

            Text("Added to Today")
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.top, 80)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onTasksAdded()
            }
        }
    }

    // MARK: - Actions

    private func startRecording() async {
        let granted = await recordingService.requestPermission()
        guard granted else {
            errorMessage = "Microphone access is required for voice planning. Enable it in Settings."
            return
        }
        do {
            try recordingService.startRecording()
            withAnimation { viewState = .recording }
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }

    private func runPlanningFromAudio(url: URL) async {
        withAnimation { viewState = .transcribing }
        do {
            let transcript = try await planningService.transcribe(audioFileURL: url)
            try FileManager.default.removeItem(at: url)
            withAnimation { viewState = .planning }
            let result = try await planningService.plan(brainDump: transcript, context: makePlanningContext())
            applyPlanResult(result)
        } catch {
            handlePlanningError(error)
        }
    }

    private func runPlanningFromText() async {
        let dump = textInput.trimmingCharacters(in: .whitespaces)
        guard !dump.isEmpty else { return }
        withAnimation { showingTextInput = false; viewState = .planning }
        do {
            let result = try await planningService.plan(brainDump: dump, context: makePlanningContext())
            applyPlanResult(result)
        } catch {
            handlePlanningError(error)
        }
    }

    private func applyPlanResult(_ result: PlanResult) {
        planResult = result
        proposedTasks = result.tasks
        withAnimation { viewState = .reviewing }
    }

    private func handlePlanningError(_ error: Error) {
        if let planError = error as? AIPlanningService.PlanningError {
            errorMessage = planError.errorDescription
        } else {
            errorMessage = "Something went wrong. Please try again."
        }
        withAnimation { viewState = .idle }
    }

    private func addTasksToToday() {
        let nextSortOrder = (existingTasks.map(\.sortOrder).max() ?? 0) + 1
        for (index, proposed) in proposedTasks.enumerated() {
            let task = FocusTask(title: proposed.title, sortOrder: nextSortOrder + index)
            modelContext.insert(task)
        }
        withAnimation { viewState = .added }
    }

    private func makePlanningContext() -> PlanningContext {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        default: timeOfDay = "evening"
        }
        return PlanningContext(
            existingTaskCount: existingTasks.filter { !$0.isCompleted }.count,
            timeOfDay: timeOfDay
        )
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Proposed Task Row

private struct ProposedTaskRow: View {
    @Binding var task: ProposedTask
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                categoryDot
                    .frame(width: 10, height: 10)

                TextField("Task title", text: $task.title)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(task.estimatedMinutes)m")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()

                Button(action: onToggleExpand) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            if isExpanded {
                Text(task.rationale)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Remove", systemImage: "trash")
            }
        }
        .animation(.spring(response: 0.3), value: isExpanded)
    }

    @ViewBuilder
    private var categoryDot: some View {
        switch task.category {
        case .warmup:
            Circle().fill(AppColors.breakPhase)
        case .deepWork:
            Circle().fill(AppColors.workPhase)
        case .admin:
            Circle().fill(AppColors.sage)
        case .creative:
            Circle().fill(AppColors.river)
        }
    }
}

// MARK: - Waveform

private struct WaveformView: View {
    let levels: [Float]

    var body: some View {
        Canvas { context, size in
            let count = levels.count
            guard count > 0 else { return }
            let spacing: CGFloat = 2
            let barWidth = (size.width - spacing * CGFloat(count - 1)) / CGFloat(count)

            for (i, level) in levels.enumerated() {
                let normalized = CGFloat(max(0.05, (level + 60) / 60))
                let barHeight = max(4, normalized * size.height)
                let x = CGFloat(i) * (barWidth + spacing)
                let y = (size.height - barHeight) / 2
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth / 2),
                    with: .color(AppColors.sage.opacity(0.3 + Double(normalized) * 0.7))
                )
            }
        }
    }
}

#Preview {
    PlanView(onTasksAdded: {})
        .environment(PurchaseManager.shared)
        .modelContainer(for: [FocusTask.self, DeletedTask.self], inMemory: true)
}
