import Foundation

public enum PomopomoError: Error, Equatable {
    case invalidEstimate
    case noSuchTask
    case pomodoroAlreadyRunning
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

    /// The Pomodoro that is Running at `now`, if any.
    public func activePomodoro(now: Date) -> Pomodoro? {
        day(containing: now).pomodoros.first { pomodoro in
            if case .running = pomodoro.state { true } else { false }
        }
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
