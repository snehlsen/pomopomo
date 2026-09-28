import Foundation

public enum PomopomoError: Error, Equatable {
    case invalidEstimate
    case noSuchTask
    case pomodoroAlreadyRunning
    case noRunningPomodoro
    case noPausedPomodoro
}

/// Something that happened as time passed, which the app should tell you about.
public enum Event: Equatable, Sendable {
    case pomodoroCompleted
}

/// Every Day you have worked, and the rules for changing them.
///
/// Every command takes the current time explicitly, so callers (and tests) control the clock.
public struct Logbook: Codable, Equatable, Sendable {
    public private(set) var days: [Day] = []
    public var settings = Settings()

    /// Used to work out which Day a moment belongs to. Not stored.
    public var calendar: Calendar = .current

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private enum CodingKeys: String, CodingKey {
        case days, settings
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

    // MARK: Commands

    @discardableResult
    public mutating func addTask(name: String, estimate: Int, now: Date) throws -> Task.ID {
        guard estimate >= 1 else { throw PomopomoError.invalidEstimate }
        let task = Task(id: UUID(), name: name, estimate: estimate)
        updateDay(containing: now) { $0.tasks.append(task) }
        return task.id
    }

    public mutating func startPomodoro(on taskID: Task.ID, now: Date) throws {
        advance(to: now)
        guard day(containing: now).task(taskID) != nil else { throw PomopomoError.noSuchTask }
        guard activePomodoro(now: now) == nil else { throw PomopomoError.pomodoroAlreadyRunning }
        let length = settings.pomodoroLength
        let pomodoro = Pomodoro(id: UUID(), taskID: taskID, length: length, state: .running(endsAt: now + length))
        updateDay(containing: now) { $0.pomodoros.append(pomodoro) }
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

    /// Settles everything whose time is up by `now`.
    @discardableResult
    public mutating func advance(to now: Date) -> [Event] {
        var events: [Event] = []
        for dayIndex in days.indices {
            for pomodoroIndex in days[dayIndex].pomodoros.indices {
                if case .running(let endsAt) = days[dayIndex].pomodoros[pomodoroIndex].state, endsAt <= now {
                    days[dayIndex].pomodoros[pomodoroIndex].state = .completed(at: endsAt)
                    events.append(.pomodoroCompleted)
                }
            }
        }
        return events
    }

    // MARK: Helpers

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
