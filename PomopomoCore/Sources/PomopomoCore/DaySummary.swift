/// How a Day went, at a glance.
public struct DaySummary: Hashable, Sendable {
    public let completed: Int
    public let voided: Int
    /// Pomodoros still Paused. On a past Day they are Paused for good and count toward nothing.
    public let pausedForGood: Int
    /// How many of each kind of Mark the Day's Pomodoros carry. Kinds never given are left out.
    public let marks: [Mark: Int]
    public let tasksDone: Int
    public let tasks: Int

    public init(completed: Int, voided: Int, pausedForGood: Int, marks: [Mark: Int], tasksDone: Int, tasks: Int) {
        self.completed = completed
        self.voided = voided
        self.pausedForGood = pausedForGood
        self.marks = marks
        self.tasksDone = tasksDone
        self.tasks = tasks
    }
}

extension Day {
    public var summary: DaySummary {
        var completed = 0, voided = 0, paused = 0
        var marks: [Mark: Int] = [:]
        for pomodoro in pomodoros {
            switch pomodoro.state {
            case .completed: completed += 1
            case .voided: voided += 1
            case .paused: paused += 1
            case .running: break
            }
            for mark in pomodoro.marks {
                marks[mark, default: 0] += 1
            }
        }
        return DaySummary(
            completed: completed,
            voided: voided,
            pausedForGood: paused,
            marks: marks,
            tasksDone: tasks.filter(\.isDone).count,
            tasks: tasks.count
        )
    }
}
