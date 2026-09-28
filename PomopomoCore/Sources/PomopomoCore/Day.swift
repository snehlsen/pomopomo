import Foundation

/// One item on a Day's task list, worked on in Pomodoros.
public struct Task: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var estimate: Int
}

/// One block of focused work on a single Task.
public struct Pomodoro: Identifiable, Hashable, Codable, Sendable {
    public enum State: Hashable, Codable, Sendable {
        case running(endsAt: Date)
        case paused(remaining: TimeInterval)
        case completed(at: Date)
        case voided(at: Date)
    }

    public let id: UUID
    public let taskID: Task.ID
    /// The length it started with; it keeps this even if the setting changes.
    public let length: TimeInterval
    public var state: State
    /// Rules of the method this Pomodoro bent, for information only.
    public internal(set) var marks: Set<Mark> = []
}

/// A visible label on a Pomodoro recording that one of the method's rules was bent.
public enum Mark: String, Hashable, Codable, Sendable, CaseIterable {
    /// Paused at least once.
    case pause
    /// Went beyond its Task's Estimate.
    case overrun
}

/// One calendar day, with its task list and the history of its Pomodoros.
public struct Day: Hashable, Codable, Sendable {
    public let date: DayDate
    public internal(set) var tasks: [Task] = []
    /// Every Pomodoro started on this Day, oldest first.
    public internal(set) var pomodoros: [Pomodoro] = []

    public init(date: DayDate) {
        self.date = date
    }

    public func task(_ id: Task.ID) -> Task? {
        tasks.first { $0.id == id }
    }

    public func pomodoros(on task: Task.ID) -> [Pomodoro] {
        pomodoros.filter { $0.taskID == task }
    }

    /// Whether any Pomodoro on the Task has started, even one later Voided.
    /// From then on the Task's Estimate is locked and the Task can't be deleted.
    public func hasStartedPomodoro(on task: Task.ID) -> Bool {
        pomodoros.contains { $0.taskID == task }
    }

    /// How many Completed Pomodoros the Task has, which is what counts against its Estimate.
    public func completedCount(of task: Task.ID) -> Int {
        pomodoros(on: task).filter(\.isCompleted).count
    }
}

extension Pomodoro {
    public var isCompleted: Bool {
        if case .completed = state { true } else { false }
    }

    /// Running or Paused: not yet Completed or Voided.
    public var isUnfinished: Bool {
        switch state {
        case .running, .paused: true
        case .completed, .voided: false
        }
    }
}
