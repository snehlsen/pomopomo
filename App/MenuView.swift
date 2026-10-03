import PomopomoCore
import SwiftUI

/// The window that opens from the menu bar.
struct MenuView: View {
    let model: AppModel
    @Environment(\.openSettings) private var openSettings
    @State private var showsLegend = false
    @FocusState private var newTaskFocused: Bool

    /// Keeps the popover on screen with many Tasks; the countdown card, Add Task and the footer stay visible.
    private static let taskListMaxHeight: CGFloat = 380

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let message = model.loadMessage ?? model.saveErrorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.isShowingPastDay {
                if !model.shownDay.tasks.isEmpty {
                    DaySummaryView(summary: model.shownDay.summary)
                }
                CappedScrollView(maxHeight: Self.taskListMaxHeight) {
                    TaskListView(model: model, day: model.shownDay, isPast: true)
                }
            } else {
                SetProgressView(progress: model.setProgress)
                if let pomodoro = model.activePomodoro {
                    ActivePomodoroView(model: model, pomodoro: pomodoro)
                }
                BreakView(model: model)
                CappedScrollView(maxHeight: Self.taskListMaxHeight) {
                    TaskListView(model: model, day: model.today, isPast: false)
                }
                AddTaskView(model: model, focused: $newTaskFocused)
            }
            Divider()
            footer
        }
        .padding()
        .frame(width: 340)
        .background(KeyMonitor(handler: handleKey))
    }

    /// Space pauses and resumes, ← and → move between Days, ⌘N starts a new Task and ⌘T goes back to today.
    /// Keys without ⌘ are left alone while a text field is being edited.
    private func handleKey(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function, .capsLock])
        if modifiers == .command {
            switch event.charactersIgnoringModifiers {
            case "n":
                model.browsedDate = nil
                // The field only exists on today, which may appear with this same update.
                DispatchQueue.main.async { newTaskFocused = true }
                return true
            case "t":
                model.browsedDate = nil
                return true
            default:
                return false
            }
        }
        guard modifiers.isEmpty, !(event.window?.firstResponder is NSText) else { return false }
        switch event.specialKey {
        case .leftArrow?:
            model.browse(by: -1)
            return true
        case .rightArrow?:
            model.browse(by: 1)
            return true
        default:
            guard event.charactersIgnoringModifiers == " ", !model.isShowingPastDay,
                  let pomodoro = model.activePomodoro else { return false }
            model.perform(at: .pomodoro) { logbook, now in
                if pomodoro.isPaused {
                    try logbook.resumePomodoro(now: now)
                } else {
                    try logbook.pausePomodoro(now: now)
                }
            }
            return true
        }
    }

    private var footer: some View {
        HStack {
            Menu {
                Button("Settings…", action: showSettings)
                    .keyboardShortcut(",")
                Button("About Pomopomo", action: showAbout)
                Divider()
                Button("Quit Pomopomo", action: quit)
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Settings, About and Quit")
            .accessibilityLabel("Pomopomo menu")
            Button {
                showsLegend.toggle()
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .help("What the symbols mean")
            .accessibilityLabel("Key to the symbols")
            .popover(isPresented: $showsLegend, arrowEdge: .bottom) {
                LegendView()
            }
            Spacer()
        }
        .background {
            // The menu's shortcuts only work while it is open, so these keep ⌘, and ⌘Q working.
            Group {
                Button("Settings", action: showSettings).keyboardShortcut(",")
                Button("Quit Pomopomo", action: quit).keyboardShortcut("q")
            }
            .opacity(0)
            .accessibilityHidden(true)
        }
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    /// Opens the Settings window in front: a menu-bar app isn't active on its own.
    private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openSettings()
    }

    private var header: some View {
        HStack {
            Button { model.browse(by: -1) } label: { Image(systemName: "chevron.left") }
                .disabled(!model.canBrowseBack)
                .help("Previous Day (←)")
                .accessibilityLabel("Previous Day")
            Text(model.shownDay.date.start(in: model.logbook.calendar), format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.headline)
            Button { model.browse(by: 1) } label: { Image(systemName: "chevron.right") }
                .disabled(!model.isShowingPastDay)
                .help("Next Day (→)")
                .accessibilityLabel("Next Day")
            Spacer()
            if model.isShowingPastDay {
                Button("Today") { model.browsedDate = nil }
                    .help("Back to today (⌘T)")
            }
        }
        .buttonStyle(.borderless)
    }
}

struct TaskListView: View {
    let model: AppModel
    let day: Day
    /// A past Day is shown exactly as it was left, and can't be changed.
    let isPast: Bool

    var body: some View {
        if day.tasks.isEmpty {
            if isPast {
                Text("No Tasks on this Day.").foregroundStyle(.secondary)
            } else {
                firstRunHelp
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // Open Tasks first, in the order they were added, then Done ones out of the way.
                ForEach(day.tasks.filter { !$0.isDone } + day.tasks.filter(\.isDone)) { task in
                    TaskRow(model: model, day: day, task: task, isPast: isPast)
                }
            }
        }
    }

    /// Today's empty list says how to get going.
    private var firstRunHelp: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No Tasks yet today.")
                .font(.subheadline.bold())
            Text("Add a Task below with its Estimate: how many Pomodoros you expect it to take. Then press Start on it to begin a Pomodoro.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

/// How far the Estimate steppers go. Not a rule of the method, just where the stepper stops.
private let estimateRange = 1...20

struct TaskRow: View {
    let model: AppModel
    let day: Day
    let task: PomopomoCore.Task
    let isPast: Bool
    @State private var confirmingDone = false
    @State private var draftName: String?
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        let options = model.options(for: task.id)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    if draftName != nil {
                        nameField
                    } else {
                        Text(task.name)
                            .strikethrough(task.isDone)
                            .foregroundStyle(task.isDone ? .secondary : .primary)
                            .onTapGesture(count: 2) { if options.rename == .allowed { startRenaming() } }
                    }
                    HStack(spacing: 6) {
                        PomodoroHistory(pomodoros: day.pomodoros(on: task.id), estimate: task.estimate, isPast: isPast)
                        if options.changeEstimate == .allowed {
                            // Next to the boxes it adds and removes, so it needs no word of its own.
                            Stepper("Estimate", value: estimate, in: estimateRange)
                                .labelsHidden()
                                .controlSize(.mini)
                                .help("Change the Estimate. It locks when the first Pomodoro starts.")
                                .accessibilityLabel("Estimate")
                                .accessibilityValue("\(task.estimate) Pomodoros")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if options.changeEstimate == .allowed {
                        SplitHint(estimate: task.estimate)
                    }
                    if options.start.marks.contains(.overrun) {
                        Text("Estimate reached: the next one gets an Overrun Mark.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if task.isDone {
                    // Neutral, so Done (for Tasks) never looks like Completed (green, for Pomodoros).
                    Label("Done", systemImage: "flag.checkered")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                startButton(options.start)
                actions(options)
            }
            if confirmingDone && options.markDone != .refused(.taskIsDone) {
                doneConfirmation(options.markDone)
            }
            ErrorText(model: model, place: .task(task.id))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Drawn outside the row's frame, so highlighting it doesn't move anything.
            if model.activePomodoro?.taskID == task.id {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.12))
                    .padding(-6)
            }
        }
    }

    /// Says what pressing it will do: resume this Task's Paused Pomodoro, void another Task's Paused one,
    /// or start a Pomodoro, showing the Marks it will carry.
    @ViewBuilder
    private func startButton(_ outcome: StartOutcome) -> some View {
        switch outcome {
        case .resume:
            Button("Resume") {
                model.perform(at: .task(task.id)) { logbook, now in try logbook.resumePomodoro(now: now) }
            }
            .help("Resume this Task's Paused Pomodoro.")
        case .start(let marks), .voidAndStart(let marks):
            let voidsPaused = outcome == .voidAndStart(marks: marks)
            Button {
                model.startPomodoro(on: task.id)
            } label: {
                HStack(spacing: 3) {
                    Text(voidsPaused ? "Void & Start" : "Start")
                    ForEach(Mark.allCases.filter(marks.contains), id: \.self) { mark in
                        MarkSymbol(mark: mark)
                    }
                }
            }
            .help(startHelp(voidsPaused: voidsPaused, marks: marks))
        case .refused(.pomodoroAlreadyRunning):
            // While a Pomodoro Runs no Start can be used; hide it but keep its space so rows don't jump.
            Button("Start") {}
                .disabled(true)
                .opacity(0)
                .accessibilityHidden(true)
        case .refused:
            EmptyView()
        }
    }

    private func startHelp(voidsPaused: Bool, marks: Set<Mark>) -> String {
        var lines = ["Start a Pomodoro on this Task."]
        if voidsPaused {
            lines.append("The Paused Pomodoro will be Voided and count toward nothing.")
        }
        if marks.contains(.skippedBreak) {
            lines.append("It skips the Break, so it gets a Skipped-Break Mark.")
        }
        if marks.contains(.overrun) {
            lines.append("The Estimate is reached, so it gets an Overrun Mark.")
        }
        return lines.joined(separator: " ")
    }

    private var nameField: some View {
        TextField("Task name", text: Binding(get: { draftName ?? "" }, set: { draftName = $0 }))
            .textFieldStyle(.roundedBorder)
            .focused($nameFieldFocused)
            .onSubmit(finishRenaming)
            .onExitCommand { draftName = nil }
            // Focus once the field is on screen; the ⋯ menu may still be closing.
            .onAppear { DispatchQueue.main.async { nameFieldFocused = true } }
            .onChange(of: nameFieldFocused) { _, focused in
                if !focused { finishRenaming() }
            }
    }

    private func startRenaming() {
        draftName = task.name
    }

    /// Saves the new name, unless it's empty after trimming: then the old name stays.
    private func finishRenaming() {
        guard let name = draftName else { return }
        draftName = nil
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name != task.name else { return }
        model.perform(at: .task(task.id)) { logbook, now in try logbook.renameTask(task.id, to: name, now: now) }
    }

    /// Only what the Task allows now. Mark Done stays in view while its Pomodoro is unfinished, saying what to do.
    @ViewBuilder
    private func actions(_ options: TaskOptions) -> some View {
        let waitsForPomodoro = options.markDone == .refused(.taskHasUnfinishedPomodoro)
        if options.markDone == .allowed || waitsForPomodoro || options.rename == .allowed || options.delete == .allowed {
            Menu {
                if waitsForPomodoro {
                    Button("Mark Done…") {}
                        .disabled(true)
                    Text("Wait until its Pomodoro is Completed, or Void it")
                } else if options.markDone == .allowed {
                    Button("Mark Done…") { confirmingDone = true }
                }
                if options.rename == .allowed {
                    Button("Rename…", action: startRenaming)
                }
                if options.delete == .allowed {
                    Button("Delete Task", role: .destructive) {
                        model.perform(at: .task(task.id)) { logbook, now in try logbook.deleteTask(task.id, now: now) }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Task actions")
            .accessibilityLabel("Actions for \(task.name)")
        }
    }

    /// Done is final, so it takes a second, deliberate click.
    private func doneConfirmation(_ markDone: Availability) -> some View {
        HStack {
            Text("Mark Done? No more Pomodoros can start on it.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Cancel") { confirmingDone = false }
            Button("Mark Done") {
                model.perform(at: .task(task.id)) { logbook, now in try logbook.markDone(task.id, now: now) }
                confirmingDone = false
            }
            .disabled(markDone != .allowed)
        }
        .controlSize(.small)
        .padding(6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
    }

    private var estimate: Binding<Int> {
        Binding(
            get: { task.estimate },
            set: { newValue in
                model.perform(at: .task(task.id)) { logbook, now in try logbook.changeEstimate(of: task.id, to: newValue, now: now) }
            }
        )
    }
}

struct AddTaskView: View {
    let model: AppModel
    var focused: FocusState<Bool>.Binding
    @State private var name = ""
    @State private var estimate = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("New Task", text: $name)
                    .focused(focused)
                    .onSubmit(add)
                    .help("New Task (⌘N)")
                Button("Add", action: add)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            // The Estimate as the boxes the new row will show, so it reads the same before and after adding.
            HStack(spacing: 6) {
                Text("Estimate")
                PomodoroHistory(pomodoros: [], estimate: estimate, isPast: false)
                    .fixedSize()
                    .accessibilityHidden(true)
                Stepper("Estimate", value: $estimate, in: estimateRange)
                    .labelsHidden()
                    .controlSize(.mini)
                    .accessibilityValue("\(estimate) Pomodoros")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .help("Estimate: how many Pomodoros you expect it to take")
            ErrorText(model: model, place: .addTask)
            SplitHint(estimate: estimate)
            Text("The Estimate and name lock when the Task's first Pomodoro starts.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func add() {
        // Add is disabled for an empty name anyway; the Logbook trims it and refuses a blank one.
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        model.perform(at: .addTask) { logbook, now in try logbook.addTask(name: name, estimate: estimate, now: now) }
        name = ""
        estimate = 1
    }
}

/// The method says a Task of more than about 5–7 Pomodoros should be split. Large Estimates are
/// still allowed; this only suggests it.
struct SplitHint: View {
    let estimate: Int

    var body: some View {
        if estimate > 5 {
            Label("More than 5 Pomodoros? Consider splitting it into smaller Tasks.", systemImage: "lightbulb")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
