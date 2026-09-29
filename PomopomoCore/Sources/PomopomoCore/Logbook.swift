import Foundation

public enum PomopomoError: Error, Equatable {
    case invalidEstimate
    case invalidName
    case nameLocked
    case noSuchTask
    case pomodoroAlreadyRunning
    case noRunningPomodoro
    case noPausedPomodoro
    case noUnfinishedPomodoro
    case estimateLocked
    case taskIsDone
    case taskHasUnfinishedPomodoro
    case taskHasPomodoros
    case noBreakDue
    case noRunningBreak
    case invalidSettings
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
    public private(set) var settings = Settings()
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

    /// The Days you can look back through: every earlier Day with something on it, then today.
    public func browsableDates(now: Date) -> [DayDate] {
        let today = openDate(now: now)
        return days.map(\.date).filter { $0 < today }.sorted() + [today]
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
        guard case .running(let running, _) = breakStatus, running.endsAt > now else { return nil }
        return running
    }

    /// Today's current Set. A full Set stays current until its Long Break is over or skipped;
    /// then the next Set begins.
    public func setProgress(now: Date) -> SetProgress {
        let total = today(now: now).completedCount
        let size = settings.setSize
        let longBreakPending = dueBreak(now: now) == .long || runningBreak(now: now)?.kind == .long
        if total > 0, total % size == 0, longBreakPending {
            return SetProgress(number: total / size, completed: size, size: size, completedToday: total)
        }
        return SetProgress(number: total / size + 1, completed: total % size, size: size, completedToday: total)
    }

    /// The Marks a Pomodoro started on the Task at `now` would carry, so you can know before starting it.
    public func marksIfStarted(on taskID: Task.ID, now: Date) -> Set<Mark> {
        let day = today(now: now)
        var marks: Set<Mark> = []
        if let task = day.task(taskID), day.completedCount(of: taskID) >= task.estimate {
            marks.insert(.overrun)
        }
        if isSkippingBreak(on: day.date) {
            marks.insert(.skippedBreak)
        }
        return marks
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

    /// Renames a Task, which is only allowed until the first Pomodoro on it starts, like changing its Estimate.
    public mutating func renameTask(_ taskID: Task.ID, to name: String, now: Date) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PomopomoError.invalidName }
        let locked = today(now: now).hasStartedPomodoro(on: taskID)
        try updateTask(taskID, now: now) { task in
            guard !locked else { throw PomopomoError.nameLocked }
            task.name = trimmed
        }
    }

    /// Marks the Task finished. Done is final, so it isn't allowed while a Pomodoro on the Task is Running or Paused.
    public mutating func markDone(_ taskID: Task.ID, now: Date) throws {
        let unfinished = activePomodoro(now: now)?.taskID == taskID
        try updateTask(taskID, now: now) { task in
            guard !unfinished else { throw PomopomoError.taskHasUnfinishedPomodoro }
            task.isDone = true
        }
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

        let length = settings.pomodoroLength
        var pomodoro = Pomodoro(id: UUID(), taskID: taskID, length: length, state: .running(endsAt: now + length))
        pomodoro.marks = marksIfStarted(on: taskID, now: now)
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

    /// The Mac is going to sleep: a Running Pomodoro is Paused, keeping its remaining time.
    /// Breaks follow the real clock and aren't affected. Returns what was settled on the way.
    @discardableResult
    public mutating func sleep(now: Date) -> [Event] {
        let events = advance(to: now)
        if case .running = activePomodoro(now: now)?.state {
            try? pausePomodoro(now: now)
        }
        return events
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
        breakStatus = .running(Break(kind: kind, length: length, endsAt: now + length), on: today(now: now).date)
    }

    /// Ends the running Break before its time is up. The next Pomodoro gets a Skipped-Break Mark.
    public mutating func endBreak(now: Date) throws {
        advance(to: now)
        guard case .running(let running, let date) = breakStatus, running.endsAt > now else {
            throw PomopomoError.noRunningBreak
        }
        breakStatus = .endedEarly(on: date)
    }

    // MARK: Settings

    /// Changes the lengths and Set size. A Pomodoro or Break keeps the length it started with,
    /// so new lengths apply from the next one; a new Set size applies to today's count straight away.
    public mutating func changeSettings(_ newSettings: Settings) throws {
        guard newSettings.isValid else { throw PomopomoError.invalidSettings }
        settings = newSettings
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
        if case .running(let running, _) = breakStatus, running.endsAt <= now {
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

    /// Whether starting a Pomodoro on `date` skips that Day's Break: one is due, running, or was ended early.
    private func isSkippingBreak(on date: DayDate) -> Bool {
        switch breakStatus {
        case .due(let day), .running(_, let day), .endedEarly(let day): day == date
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
