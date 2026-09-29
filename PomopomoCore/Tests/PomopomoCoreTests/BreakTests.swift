import Foundation
import Testing
@testable import PomopomoCore

@Suite struct BreakTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    var writeReport: PomopomoCore.Task { logbook.task(task)! }

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 8, now: sept28(9))
    }

    /// Starts a Pomodoro at `start` and lets it run to Completed.
    mutating func complete(_ task: PomopomoCore.Task.ID, at start: Date) throws {
        try logbook.startPomodoro(on: task, now: start)
        logbook.advance(to: start + 25 * minute)
    }

    @Test mutating func completedPomodoroOffersAShortBreakWithoutStartingIt() throws {
        #expect(logbook.dueBreak(now: sept28(9)) == nil)
        try complete(task, at: sept28(9))
        #expect(logbook.dueBreak(now: sept28(9, 25)) == .short)
        #expect(logbook.runningBreak(now: sept28(9, 30)) == nil)
    }

    @Test mutating func takenBreakCountsDownAndEndsWithAnEvent() throws {
        try complete(task, at: sept28(9))
        try logbook.startBreak(now: sept28(9, 26))

        #expect(logbook.dueBreak(now: sept28(9, 26)) == nil)
        #expect(logbook.runningBreak(now: sept28(9, 26)) == Break(kind: .short, length: 5 * minute, endsAt: sept28(9, 31)))
        #expect(logbook.advance(to: sept28(9, 30)) == [])
        #expect(logbook.advance(to: sept28(9, 31)) == [.breakEnded(after: writeReport)])
        #expect(logbook.runningBreak(now: sept28(9, 31)) == nil)
        #expect(logbook.dueBreak(now: sept28(9, 31)) == nil)
    }

    @Test mutating func everyFourthCompletedPomodoroIsFollowedByALongBreak() throws {
        try complete(task, at: sept28(9))
        try complete(task, at: sept28(9, 30))
        try complete(task, at: sept28(10))
        #expect(logbook.dueBreak(now: sept28(10, 25)) == .short)
        try complete(task, at: sept28(10, 30))
        #expect(logbook.dueBreak(now: sept28(10, 55)) == .long)

        try logbook.startBreak(now: sept28(11))
        #expect(logbook.runningBreak(now: sept28(11))?.endsAt == sept28(11, 15))

        logbook.advance(to: sept28(11, 15))
        try complete(task, at: sept28(11, 15))
        #expect(logbook.dueBreak(now: sept28(11, 40)) == .short)
    }

    @Test mutating func setCountsAcrossTasksAndGapsButNotVoidedPomodoros() throws {
        let other = try logbook.addTask(name: "Email", estimate: 4, now: sept28(9))
        try complete(task, at: sept28(9))
        try complete(other, at: sept28(9, 30))
        try logbook.startPomodoro(on: task, now: sept28(10))
        try logbook.voidPomodoro(now: sept28(10, 10))
        try complete(other, at: sept28(13)) // a long gap
        #expect(logbook.dueBreak(now: sept28(13, 25)) == .short)

        try complete(task, at: sept28(15))
        #expect(logbook.dueBreak(now: sept28(15, 25)) == .long)
    }

    @Test mutating func breakCanOnlyStartWhenOneIsDue() throws {
        #expect(throws: PomopomoError.noBreakDue) { try logbook.startBreak(now: sept28(9)) }
        try complete(task, at: sept28(9))
        try logbook.startBreak(now: sept28(9, 25))
        #expect(throws: PomopomoError.noBreakDue) { try logbook.startBreak(now: sept28(9, 26)) }
    }

    @Test mutating func breakFollowsTheRealClock() throws {
        try complete(task, at: sept28(9))
        try logbook.startBreak(now: sept28(9, 25))
        // No ticks at all while the Mac sleeps: the Break is still over when it wakes.
        #expect(logbook.advance(to: sept28(12)) == [.breakEnded(after: writeReport)])
    }
}
