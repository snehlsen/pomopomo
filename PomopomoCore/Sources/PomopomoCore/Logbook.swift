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
/// Commands only ever change today; past Days are read-only.
public struct Logbook: Codable, Equatable, Sendable {
    /// Every Day that has something on it, oldest first.
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

    /// The Day that is open at `now`, empty if nothing has happened on it yet.
    ///
    /// That is the calendar date of `now`, unless a Pomodoro was Running at midnight:
    /// then its Day stays open until that Pomodoro is Completed, Voided or Paused.
    public func today(now: Date) -> Day {
        day(on: openDate(now: now))
    }

    /// The Day on `date`, empty if nothing happened on it.
    public func day(on date: DayDate) -> Day {
        days.first { $0.date == date } ?? Day(date: date)
    }

    /// Today's Running or Paused Pomodoro, if any. A Day has at most one.
    public func activePomodoro(now: Date) -> Pomodoro? {
        today(now: now).pomodoros.first(where: \.isUnfinished)
    }

    /// The Break that is due at `now` but hasn't been started, if any.
    public func dueBreak(now: Date) -> Break.Kind? {
        let day = today(now: now)
        guard breakStatus == .due(on: day.date) else { return nil }
        return day.completedCount % settings.setSize == 0 ? .long : .short
    }

    /// The Break counting down at `now`, if any.
    public func runningBreak(now: Date) -> Break? {
        guard case .running(let running) = breakStatus, running.endsAt > now else { return nil }
        return running
    }

    // MARK: Tasks

    @discardableResult
    public mutating func addTask(name: String, estimate: Int, now: Date) throws -> Task.ID {
        guard estimate >= 1 else { throw PomopomoError.invalidEstimate }
        advance(to: now)
        let task = Task(id: UUID(), name: name, estimate: estimate)
        updateToday(now: now) { $0.tasks.append(task) }
        return task.id
    }

    /// Changes a Task's Estimate, which is only allowed until the first Pomodoro on it starts.
    public mutating func changeEstimate(of taskID: Task.ID, to estimate: Int, now: Date) throws {
        guard estimate >= 1 else { throw PomopomoError.invalidEstimate }
        let locked = today(now: now).hasStartedPomodoro(on: taskID)
        try updateTask(taskID, now: now) { task in
            guard !locked else { throw PomopomoError.estimateLocked }
            task.estimate = estimate
        }
    }

    /// Marks the Task finished. Done is final.
    public mutating func markDone(_ taskID: Task.ID, now: Date) throws {
        try updateTask(taskID, now: now) { $0.isDone = true }
    }

    /// Removes a Task, which is only allowed until the first Pomodoro on it starts.
    public mutating func deleteTask(_ taskID: Task.ID, now: Date) throws {
        advance(to: now)
        let day = today(now: now)
        guard day.task(taskID) != nil else { throw PomopomoError.noSuchTask }
        guard !day.hasStartedPomodoro(on: taskID) else { throw PomopomoError.taskHasPomodoros }
        updateToday(now: now) { day in day.tasks.removeAll { $0.id == taskID } }
    }

    // MARK: Pomodoros

    /// Starts a Pomodoro on one of today's Tasks. A Paused Pomodoro is Voided to make way for it.
    public mutating func startPomodoro(on taskID: Task.ID, now: Date) throws {
        advance(to: now)
        guard let task = today(now: now).task(taskID) else { throw PomopomoError.noSuchTask }
        guard !task.isDone else { throw PomopomoError.taskIsDone }
        switch activePomodoro(now: now)?.state {
        case .running: throw PomopomoError.pomodoroAlreadyRunning
        case .paused: try voidPomodoro(now: now)
        default: break
        }

        let day = today(now: now)
        let length = settings.pomodoroLength
        var pomodoro = Pomodoro(id: UUID(), taskID: taskID, length: length, state: .running(endsAt: now + length))
        if day.completedCount(of: taskID) >= task.estimate {
            pomodoro.marks.insert(.overrun)
        }
        if isSkippingBreak(on: day.date) {
            pomodoro.marks.insert(.skippedBreak)
        }
        updateToday(now: now) { $0.pomodoros.append(pomodoro) }
        breakStatus = nil
    }

    public mutating func pausePomodoro(now: Date) throws {
        try updateActivePomodoro(now: now, orThrow: .noRunningPomodoro) { pomodoro in
            guard case .running(let endsAt) = pomodoro.state else { throw PomopomoError.noRunningPomodoro }
            pomodoro.state = .paused(remaining: endsAt.timeIntervalSince(now))
            pomodoro.marks.insert(.pause)
        }
    }

    public mutating func resumePomodoro(now: Date) throws {
        try updateActivePomodoro(now: now, orThrow: .noPausedPomodoro) { pomodoro in
            guard case .paused(let remaining) = pomodoro.state else { throw PomopomoError.noPausedPomodoro }
            pomodoro.state = .running(endsAt: now + remaining)
        }
    }

    /// Abandons today's Running or Paused Pomodoro. It stays in the Day's history but counts toward nothing.
    public mutating func voidPomodoro(now: Date) throws {
        try updateActivePomodoro(now: now, orThrow: .noUnfinishedPomodoro) { pomodoro in
            pomodoro.state = .voided(at: now)
        }
    }

    // MARK: Breaks

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
        breakStatus = .endedEarly(on: today(now: now).date)
    }

    // MARK: Time

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

    private func openDate(now: Date) -> DayDate {
        let carriedOver = days.first { day in
            day.pomodoros.contains { pomodoro in
                if case .running(let endsAt) = pomodoro.state { endsAt > now } else { false }
            }
        }
        return carriedOver?.date ?? DayDate(now, in: calendar)
    }

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
        advance(to: now)
        guard let index = today(now: now).pomodoros.firstIndex(where: \.isUnfinished) else { throw missing }
        try updateToday(now: now) { day in try change(&day.pomodoros[index]) }
    }

    /// Changes one of today's Tasks, or throws if it isn't on today's list.
    private mutating func updateTask(_ taskID: Task.ID, now: Date, _ change: (inout Task) throws -> Void) throws {
        advance(to: now)
        guard let index = today(now: now).tasks.firstIndex(where: { $0.id == taskID }) else {
            throw PomopomoError.noSuchTask
        }
        try updateToday(now: now) { day in try change(&day.tasks[index]) }
    }

    private mutating func updateToday(now: Date, _ change: (inout Day) throws -> Void) rethrows {
        let date = openDate(now: now)
        if let index = days.firstIndex(where: { $0.date == date }) {
            try change(&days[index])
        } else {
            var day = Day(date: date)
            try change(&day)
            days.append(day)
        }
    }
}
