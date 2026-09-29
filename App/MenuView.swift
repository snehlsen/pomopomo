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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.today.task(pomodoro.taskID)?.name ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(model.remaining(of: pomodoro).countdown)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(pomodoro.isPaused ? .secondary : .primary)
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
                Button("Void", role: .destructive) {
                    model.perform { logbook, now in try logbook.voidPomodoro(now: now) }
                }
                .help("Abandon this Pomodoro. It stays in the history but counts toward nothing.")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
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
                .help("The next Pomodoro will carry a Skipped-Break Mark.")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        } else if let due = model.dueBreak {
            HStack {
                Image(systemName: "cup.and.saucer").foregroundStyle(.teal)
                Text("\(due.title) due")
                Spacer()
                Button("Start \(due.title)") {
                    model.perform { logbook, now in try logbook.startBreak(now: now) }
                }
                .keyboardShortcut(.defaultAction)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .strikethrough(task.isDone)
                        .foregroundStyle(task.isDone ? .secondary : .primary)
                    HStack(spacing: 4) {
                        Text("\(day.completedCount(of: task.id)) of \(task.estimate) Pomodoros")
                        if !isPast && !day.hasStartedPomodoro(on: task.id) && !task.isDone {
                            Stepper("Estimate", value: estimate, in: 1...20)
                                .labelsHidden()
                                .controlSize(.mini)
                                .help("Change the Estimate. It locks when the first Pomodoro starts.")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    PomodoroHistory(pomodoros: day.pomodoros(on: task.id), isPast: isPast)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if task.isDone {
                    Label("Done", systemImage: "checkmark.seal.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if !isPast {
                    Button("Start") {
                        model.startPomodoro(on: task.id)
                    }
                    .disabled(model.isPomodoroRunning)
                    .help(model.activePomodoro?.isPaused == true ? "Starting a new Pomodoro voids the Paused one." : "")
                    actions
                }
            }
            if confirmingDone && !task.isDone {
                doneConfirmation
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack {
            TextField("New Task", text: $name)
                .onSubmit(add)
            Stepper("\(estimate)", value: $estimate, in: 1...20)
                .help("Estimate: how many Pomodoros you expect it to take")
            Button("Add", action: add)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
