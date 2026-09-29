import PomopomoCore
import SwiftUI

/// The window that opens from the menu bar.
struct MenuView: View {
    let model: AppModel
    @State private var showsSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if model.isShowingPastDay {
                if !model.shownDay.tasks.isEmpty {
                    DaySummaryView(summary: model.shownDay.summary)
                }
                TaskListView(model: model, day: model.shownDay, isPast: true)
            } else {
                SetProgressView(progress: model.setProgress)
                if let pomodoro = model.activePomodoro {
                    ActivePomodoroView(model: model, pomodoro: pomodoro)
                }
                BreakView(model: model)
                TaskListView(model: model, day: model.today, isPast: false)
                AddTaskView(model: model)
            }
            if let message = model.errorMessage {
                Text(message).font(.caption).foregroundStyle(.red)
            }
            Divider()
            if showsSettings {
                SettingsView(model: model)
                Divider()
            }
            HStack {
                Button {
                    showsSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
                Spacer()
                Button("Quit Pomopomo") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 340)
    }

    private var header: some View {
        HStack {
            Button { model.browse(by: -1) } label: { Image(systemName: "chevron.left") }
                .disabled(!model.canBrowseBack)
                .help("Previous Day")
            Text(model.shownDay.date.start(in: model.logbook.calendar), format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.headline)
            Button { model.browse(by: 1) } label: { Image(systemName: "chevron.right") }
                .disabled(!model.isShowingPastDay)
                .help("Next Day")
            Spacer()
            if model.isShowingPastDay {
                Button("Today") { model.browsedDate = nil }
            }
        }
        .buttonStyle(.borderless)
    }
}

struct ActivePomodoroView: View {
    let model: AppModel
    let pomodoro: Pomodoro
    /// Voiding can't be undone, so it takes a second, deliberate click.
    @State private var confirmingVoid = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.today.task(pomodoro.taskID)?.name ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(model.remaining(of: pomodoro).countdown)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(pomodoro.isPaused ? .secondary : .primary)
            if confirmingVoid {
                voidConfirmation
            } else {
                HStack {
                    if pomodoro.isPaused {
                        Button("Resume") {
                            model.perform { logbook, now in try logbook.resumePomodoro(now: now) }
                        }
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button("Pause") {
                            model.perform { logbook, now in try logbook.pausePomodoro(now: now) }
                        }
                    }
                    Spacer().frame(width: 16)
                    Button("Void…") { confirmingVoid = true }
                        .help("Abandon this Pomodoro. It stays in the history but counts toward nothing.")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .onChange(of: pomodoro.id) { confirmingVoid = false }
    }

    private var voidConfirmation: some View {
        VStack(spacing: 4) {
            Text("Void this Pomodoro? Its work won't count, and this can't be undone.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Keep It") { confirmingVoid = false }
                    .keyboardShortcut(.cancelAction)
                Button("Void", role: .destructive) {
                    model.perform { logbook, now in try logbook.voidPomodoro(now: now) }
                    confirmingVoid = false
                }
            }
        }
        .padding(.horizontal)
    }
}

struct BreakView: View {
    let model: AppModel

    var body: some View {
        if let running = model.runningBreak {
            VStack(spacing: 4) {
                Text(running.kind.title).font(.subheadline).foregroundStyle(.secondary)
                Text(max(0, running.endsAt.timeIntervalSince(model.now)).countdown)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.teal)
                Button("End Break Early") {
                    model.perform { logbook, now in try logbook.endBreak(now: now) }
                }
                Text("Ending it early or starting a Pomodoro now gives that Pomodoro a Skipped-Break Mark.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        } else if let due = model.dueBreak {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "cup.and.saucer").foregroundStyle(.teal)
                    Text("\(due.title) due")
                    Spacer()
                    Button("Start \(due.title)") {
                        model.perform { logbook, now in try logbook.startBreak(now: now) }
                    }
                    .keyboardShortcut(.defaultAction)
                }
                Text("Starting a Pomodoro instead skips it and gives that Pomodoro a Skipped-Break Mark.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension Break.Kind {
    var title: String {
        switch self {
        case .short: "Short Break"
        case .long: "Long Break"
        }
    }
}

struct TaskListView: View {
    let model: AppModel
    let day: Day
    /// A past Day is shown exactly as it was left, and can't be changed.
    let isPast: Bool

    var body: some View {
        if day.tasks.isEmpty {
            Text(isPast ? "No Tasks on this Day." : "No Tasks yet today.").foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(day.tasks) { task in
                    TaskRow(model: model, day: day, task: task, isPast: isPast)
                }
            }
        }
    }
}

struct TaskRow: View {
    let model: AppModel
    let day: Day
    let task: PomopomoCore.Task
    let isPast: Bool
    @State private var confirmingDone = false
    @State private var draftName: String?
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    if draftName != nil {
                        nameField
                    } else {
                        Text(task.name)
                            .strikethrough(task.isDone)
                            .foregroundStyle(task.isDone ? .secondary : .primary)
                            .onTapGesture(count: 2) { if canRename { startRenaming() } }
                    }
                    HStack(spacing: 6) {
                        PomodoroHistory(pomodoros: day.pomodoros(on: task.id), estimate: task.estimate, isPast: isPast)
                        if !isPast && !day.hasStartedPomodoro(on: task.id) && !task.isDone {
                            Stepper("Estimate", value: estimate, in: 1...20)
                                .controlSize(.mini)
                                .help("Change the Estimate. It locks when the first Pomodoro starts.")
                                .accessibilityLabel("Estimate")
                                .accessibilityValue("\(task.estimate) Pomodoros")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if !isPast && !day.hasStartedPomodoro(on: task.id) && !task.isDone {
                        SplitHint(estimate: task.estimate)
                    }
                    if !isPast && !task.isDone && !hasActivePomodoro && nextMarks.contains(.overrun) {
                        Text("Estimate reached: the next one gets an Overrun Mark.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if task.isDone {
                    // Neutral, so Done (for Tasks) never looks like Completed (green, for Pomodoros).
                    Label("Done", systemImage: "seal")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !isPast {
                    startButton
                    actions
                }
            }
            if confirmingDone && !task.isDone {
                doneConfirmation
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Drawn outside the row's frame, so highlighting it doesn't move anything.
            if hasActivePomodoro && !isPast {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.12))
                    .padding(-6)
            }
        }
    }

    /// Says what pressing it will do: resume this Task's Paused Pomodoro, void another Task's Paused one,
    /// or start a Pomodoro, showing the Marks it will carry.
    @ViewBuilder
    private var startButton: some View {
        if let active = model.activePomodoro, active.isPaused, active.taskID == task.id {
            Button("Resume") {
                model.perform { logbook, now in try logbook.resumePomodoro(now: now) }
            }
            .help("Resume this Task's Paused Pomodoro.")
        } else {
            let voidsPaused = model.activePomodoro?.isPaused == true
            Button {
                model.startPomodoro(on: task.id)
            } label: {
                HStack(spacing: 3) {
                    Text(voidsPaused ? "Void & Start" : "Start")
                    ForEach(Mark.allCases.filter(nextMarks.contains), id: \.self) { mark in
                        MarkSymbol(mark: mark)
                    }
                }
            }
            // While a Pomodoro Runs no Start can be used; hide it but keep its space so rows don't jump.
            .disabled(model.isPomodoroRunning)
            .opacity(model.isPomodoroRunning ? 0 : 1)
            .accessibilityHidden(model.isPomodoroRunning)
            .help(startHelp(voidsPaused: voidsPaused))
        }
    }

    private var nextMarks: Set<Mark> {
        model.marksIfStarted(on: task.id)
    }

    private func startHelp(voidsPaused: Bool) -> String {
        var lines = ["Start a Pomodoro on this Task."]
        if voidsPaused {
            lines.append("The Paused Pomodoro will be Voided and count toward nothing.")
        }
        if nextMarks.contains(.skippedBreak) {
            lines.append("It skips the Break, so it gets a Skipped-Break Mark.")
        }
        if nextMarks.contains(.overrun) {
            lines.append("The Estimate is reached, so it gets an Overrun Mark.")
        }
        return lines.joined(separator: " ")
    }

    /// Like the Estimate, the name can change until the first Pomodoro on the Task starts.
    private var canRename: Bool {
        !isPast && !task.isDone && !day.hasStartedPomodoro(on: task.id)
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
        model.perform { logbook, now in try logbook.renameTask(task.id, to: name, now: now) }
    }

    /// Whether this Task's Pomodoro is Running or Paused, which rules out marking it Done.
    private var hasActivePomodoro: Bool {
        model.activePomodoro?.taskID == task.id
    }

    private var actions: some View {
        Menu {
            if hasActivePomodoro {
                Button("Mark Done…") {}
                    .disabled(true)
                Text("Finish or Void its Pomodoro first")
            } else {
                Button("Mark Done…") { confirmingDone = true }
            }
            if canRename {
                Button("Rename…", action: startRenaming)
            }
            if !day.hasStartedPomodoro(on: task.id) {
                Button("Delete Task", role: .destructive) {
                    model.perform { logbook, now in try logbook.deleteTask(task.id, now: now) }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Task actions")
    }

    /// Done is final, so it takes a second, deliberate click.
    private var doneConfirmation: some View {
        HStack {
            Text("Mark Done? No more Pomodoros can start on it.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Cancel") { confirmingDone = false }
            Button("Mark Done") {
                model.perform { logbook, now in try logbook.markDone(task.id, now: now) }
                confirmingDone = false
            }
            .disabled(hasActivePomodoro)
        }
        .controlSize(.small)
        .padding(6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
    }

    private var estimate: Binding<Int> {
        Binding(
            get: { task.estimate },
            set: { newValue in
                model.perform { logbook, now in try logbook.changeEstimate(of: task.id, to: newValue, now: now) }
            }
        )
    }
}

struct AddTaskView: View {
    let model: AppModel
    @State private var name = ""
    @State private var estimate = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("New Task", text: $name)
                    .onSubmit(add)
                Stepper("Estimate \(estimate)", value: $estimate, in: 1...20)
                    .fixedSize()
                    .help("Estimate: how many Pomodoros you expect it to take")
                    .accessibilityLabel("Estimate")
                    .accessibilityValue("\(estimate) Pomodoros")
                Button("Add", action: add)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            SplitHint(estimate: estimate)
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        model.perform { logbook, now in try logbook.addTask(name: trimmed, estimate: estimate, now: now) }
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
