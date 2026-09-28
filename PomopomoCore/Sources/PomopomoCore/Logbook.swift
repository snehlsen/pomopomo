import Foundation

public enum PomopomoError: Error, Equatable {
    case invalidEstimate
    case noSuchTask
    case pomodoroAlreadyRunning
    case noRunningPomodoro
    case noPausedPomodoro
    case noUnfinishedPomodoro
    case estimateLocked
    case taskIsDone
    case taskHasPomodoros
    case noBreakDue
    case noRunningBreak
}

/// Something that happened as time passed, which the app should tell you about.
public enum Event: Equatable, Sendable {
    case pomodoroCompleted
    case breakEnded
}

/// Every Day you have worked, and the rules for changing them.
///
/// Every command takes the current time explicitly, so callers (and tests) control the clock.
public struct Logbook: Codable, Equatable, Sendable {
    public private(set) var days: [Day] = []
    public var settings = Settings()
    private var breakStatus: BreakStatus?

    /// Used to work out which Day a moment belongs to. Not stored.
    public var calendar: Calendar = .current

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private enum CodingKeys: String, CodingKey {
        case days, settings, breakStatus
    }

    // MARK: Queries

    /// The Day shown as today at `now`, empty if nothing has happened on it yet.
    public func day(containing now: Date) -> Day {
        let date = DayDate(now, in: calendar)
        return days.first { $0.date == date } ?? Day(date: date)
    }

    /// The Pomodoro that is Running or Paused at `now`, if any. A Day has at most one.
    public func activePomodoro(now: Date) -> Pomodoro? {
        day(containing: now).pomodoros.first(where: \.isUnfinished)
    }

    /// The Break that is due at `now` but hasn't been started, if any.
    public func dueBreak(now: Date) -> Break.Kind? {
        let today = day(containing: now)
        guard breakStatus == .due(on: today.date) else { return nil }
        return today.completedCount % settings.setSize == 0 ? .long : .short
    }

    /// The Break counting down at `now`, if any.
    public func runningBreak(now: Date) -> Break? {
        if case .running(let running) = breakStatus { running } else { nil }
    }

    // MARK: Commands

    @discardableResult
    public mutating func addTask(name: String, estimate: Int, now: Date) throws -> Task.ID {
        guard estimate >= 1 else { throw PomopomoError.invalidEstimate }
        let task = Task(id: UUID(), name: name, estimate: estimate)
        updateDay(containing: now) { $0.tasks.append(task) }
        return task.id
    }

    public mutating func changeEstimate(of taskID: Task.ID, to estimate: Int, now: Date) throws {
        guard estimate >= 1 else { throw PomopomoError.invalidEstimate }
        let today = day(containing: now)
        guard today.task(taskID) != nil else { throw PomopomoError.noSuchTask }
        guard !today.hasStartedPomodoro(on: taskID) else { throw PomopomoError.estimateLocked }
        updateTask(taskID, now: now) { $0.estimate = estimate }
    }

    /// Marks the Task finished. Done is final.
    public mutating func markDone(_ taskID: Task.ID, now: Date) throws {
        guard day(containing: now).task(taskID) != nil else { throw PomopomoError.noSuchTask }
        updateTask(taskID, now: now) { $0.isDone = true }
    }

    /// Removes a Task, which is only allowed until the first Pomodoro on it starts.
    public mutating func deleteTask(_ taskID: Task.ID, now: Date) throws {
        let today = day(containing: now)
        guard today.task(taskID) != nil else { throw PomopomoError.noSuchTask }
        guard !today.hasStartedPomodoro(on: taskID) else { throw PomopomoError.taskHasPomodoros }
        updateDay(containing: now) { day in day.tasks.removeAll { $0.id == taskID } }
    }

    public mutating func startPomodoro(on taskID: Task.ID, now: Date) throws {
        advance(to: now)
        guard let task = day(containing: now).task(taskID) else { throw PomopomoError.noSuchTask }
        guard !task.isDone else { throw PomopomoError.taskIsDone }
        switch activePomodoro(now: now)?.state {
        case .running: throw PomopomoError.pomodoroAlreadyRunning
        case .paused: try voidPomodoro(now: now)
        default: break
        }
        let length = settings.pomodoroLength
        var pomodoro = Pomodoro(id: UUID(), taskID: taskID, length: length, state: .running(endsAt: now + length))
        let today = day(containing: now)
        if today.completedCount(of: taskID) >= task.estimate {
            pomodoro.marks.insert(.overrun)
        }
        if isSkippingBreak(on: today.date) {
            pomodoro.marks.insert(.skippedBreak)
        }
        updateDay(containing: now) { $0.pomodoros.append(pomodoro) }
        breakStatus = nil
    }

    public mutating func pausePomodoro(now: Date) throws {
        advance(to: now)
        try updateActivePomodoro(now: now, orThrow: .noRunningPomodoro) { pomodoro in
            guard case .running(let endsAt) = pomodoro.state else { throw PomopomoError.noRunningPomodoro }
            pomodoro.state = .paused(remaining: endsAt.timeIntervalSince(now))
            pomodoro.marks.insert(.pause)
        }
    }

    public mutating func resumePomodoro(now: Date) throws {
        advance(to: now)
        try updateActivePomodoro(now: now, orThrow: .noPausedPomodoro) { pomodoro in
            guard case .paused(let remaining) = pomodoro.state else { throw PomopomoError.noPausedPomodoro }
            pomodoro.state = .running(endsAt: now + remaining)
        }
    }

    /// Abandons today's Running or Paused Pomodoro. It stays in the Day's history but counts toward nothing.
    public mutating func voidPomodoro(now: Date) throws {
        advance(to: now)
        try updateActivePomodoro(now: now, orThrow: .noUnfinishedPomodoro) { pomodoro in
            pomodoro.state = .voided(at: now)
        }
    }

    /// Starts the Break that is due: a Short Break, or a Long Break when the last Pomodoro ended a Set.
    public mutating func startBreak(now: Date) throws {
        advance(to: now)
        guard let kind = dueBreak(now: now) else { throw PomopomoError.noBreakDue }
        let length = kind == .long ? settings.longBreakLength : settings.shortBreakLength
        breakStatus = .running(Break(kind: kind, length: length, endsAt: now + length))
    }

    /// Ends the running Break before its time is up. The next Pomodoro gets a Skipped-Break Mark.
    public mutating func endBreak(now: Date) throws {
        advance(to: now)
        guard runningBreak(now: now) != nil else { throw PomopomoError.noRunningBreak }
        breakStatus = .endedEarly(on: day(containing: now).date)
    }

    /// Settles everything whose time is up by `now`.
    @discardableResult
    public mutating func advance(to now: Date) -> [Event] {
        var events: [Event] = []
        for dayIndex in days.indices {
            for pomodoroIndex in days[dayIndex].pomodoros.indices {
                if case .running(let endsAt) = days[dayIndex].pomodoros[pomodoroIndex].state, endsAt <= now {
                    days[dayIndex].pomodoros[pomodoroIndex].state = .completed(at: endsAt)
                    breakStatus = .due(on: days[dayIndex].date)
                    events.append(.pomodoroCompleted)
                }
            }
        }
        if case .running(let running) = breakStatus, running.endsAt <= now {
            breakStatus = nil
            events.append(.breakEnded)
        }
        return events
    }

    // MARK: Helpers

    /// Whether starting a Pomodoro now skips a Break: one is due, running, or was ended early.
    private func isSkippingBreak(on date: DayDate) -> Bool {
        switch breakStatus {
        case .due(let day), .endedEarly(let day): day == date
        case .running: true
        case nil: false
        }
    }

    /// Changes today's Running or Paused Pomodoro, or throws `missing` if there is none.
    private mutating func updateActivePomodoro(
        now: Date,
        orThrow missing: PomopomoError,
        _ change: (inout Pomodoro) throws -> Void
    ) throws {
        let date = DayDate(now, in: calendar)
        guard let dayIndex = days.firstIndex(where: { $0.date == date }),
              let index = days[dayIndex].pomodoros.firstIndex(where: \.isUnfinished)
        else { throw missing }
        try change(&days[dayIndex].pomodoros[index])
    }

    private mutating func updateTask(_ taskID: Task.ID, now: Date, _ change: (inout Task) -> Void) {
        updateDay(containing: now) { day in
            if let index = day.tasks.firstIndex(where: { $0.id == taskID }) {
                change(&day.tasks[index])
            }
        }
    }

    private mutating func updateDay(containing now: Date, _ change: (inout Day) -> Void) {
        let date = DayDate(now, in: calendar)
        if let index = days.firstIndex(where: { $0.date == date }) {
            change(&days[index])
        } else {
            var day = Day(date: date)
            change(&day)
            days.append(day)
        }
    }
}
