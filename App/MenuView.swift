import PomopomoCore
import SwiftUI

/// The window that opens from the menu bar.
struct MenuView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let pomodoro = model.activePomodoro {
                ActivePomodoroView(model: model, pomodoro: pomodoro)
            }
            BreakView(model: model)
            TaskListView(model: model, day: model.today)
            AddTaskView(model: model)
            if let message = model.errorMessage {
                Text(message).font(.caption).foregroundStyle(.red)
            }
            Divider()
            HStack {
                Spacer()
                Button("Quit Pomopomo") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 340)
    }

    private var header: some View {
        Text(model.today.date.start(in: model.logbook.calendar), format: .dateTime.weekday(.wide).day().month(.wide))
            .font(.headline)
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

    var body: some View {
        if day.tasks.isEmpty {
            Text("No Tasks yet today.").foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(day.tasks) { task in
                    TaskRow(model: model, day: day, task: task)
                }
            }
        }
    }
}

struct TaskRow: View {
    let model: AppModel
    let day: Day
    let task: PomopomoCore.Task

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                HStack(spacing: 4) {
                    Text("\(day.completedCount(of: task.id)) of \(task.estimate) Pomodoros")
                    if !day.hasStartedPomodoro(on: task.id) && !task.isDone {
                        Stepper("Estimate", value: estimate, in: 1...20)
                            .labelsHidden()
                            .controlSize(.mini)
                            .help("Change the Estimate. It locks when the first Pomodoro starts.")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                PomodoroHistory(pomodoros: day.pomodoros(on: task.id))
            }
            Spacer()
            if task.isDone {
                Label("Done", systemImage: "checkmark.seal.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button("Start") {
                    model.perform { logbook, now in try logbook.startPomodoro(on: task.id, now: now) }
                }
                .disabled(model.isPomodoroRunning)
                .help(model.activePomodoro?.isPaused == true ? "Starting a new Pomodoro voids the Paused one." : "")
                actions
            }
        }
    }

    private var actions: some View {
        Menu {
            Button("Mark Done") {
                model.perform { logbook, now in try logbook.markDone(task.id, now: now) }
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
        .help("Mark Done is final: no more Pomodoros can start on a Done Task.")
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
