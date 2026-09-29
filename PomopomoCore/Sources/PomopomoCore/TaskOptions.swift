/// Whether a command can be given now, and if not, why. The command throws that same reason.
public enum Availability: Hashable, Sendable {
    case allowed
    case refused(PomopomoError)
}

/// What starting a Pomodoro on a Task would do now.
public enum StartOutcome: Hashable, Sendable {
    /// Starts a Pomodoro carrying these Marks.
    case start(marks: Set<Mark>)
    /// Voids another Task's Paused Pomodoro, then starts one carrying these Marks.
    case voidAndStart(marks: Set<Mark>)
    /// Picks up this Task's own Paused Pomodoro, with `resumePomodoro`.
    case resume
    case refused(PomopomoError)
}

/// What can be done to a Task at a given moment. The Logbook's commands follow these same answers.
public struct TaskOptions: Hashable, Sendable {
    public let start: StartOutcome
    public let changeEstimate: Availability
    public let rename: Availability
    public let delete: Availability
    public let markDone: Availability

    init(start: StartOutcome, changeEstimate: Availability, rename: Availability, delete: Availability, markDone: Availability) {
        self.start = start
        self.changeEstimate = changeEstimate
        self.rename = rename
        self.delete = delete
        self.markDone = markDone
    }

    /// Nothing can be done, for the same reason throughout: the Task is Done, its Day is past, or it doesn't exist.
    init(refusingAllWith reason: PomopomoError) {
        self.init(
            start: .refused(reason),
            changeEstimate: .refused(reason),
            rename: .refused(reason),
            delete: .refused(reason),
            markDone: .refused(reason)
        )
    }
}

extension Availability {
    /// Throws the reason it was refused.
    func check() throws {
        if case .refused(let reason) = self { throw reason }
    }
}

extension StartOutcome {
    /// The Marks the new Pomodoro would carry; none when nothing would start.
    public var marks: Set<Mark> {
        switch self {
        case .start(let marks), .voidAndStart(let marks): marks
        case .resume, .refused: []
        }
    }
}
