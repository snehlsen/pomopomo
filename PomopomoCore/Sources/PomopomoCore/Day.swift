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
        case completed(at: Date)
    }

    public let id: UUID
    public let taskID: Task.ID
    /// The length it started with; it keeps this even if the setting changes.
    public let length: TimeInterval
    public var state: State
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

    /// How many Completed Pomodoros the Task has, which is what counts against its Estimate.
    public func completedCount(of task: Task.ID) -> Int {
        pomodoros(on: task).filter(\.isCompleted).count
    }
}

extension Pomodoro {
    public var isCompleted: Bool {
        if case .completed = state { true } else { false }
    }
}
