import Foundation
import Testing
@testable import PomopomoCore

/// Knowing before pressing Start which Marks the new Pomodoro will carry.
@Suite struct NextPomodoroMarksTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 1, now: sept28(9))
    }

    @Test func noMarksWithinTheEstimateAndNoBreakDue() {
        #expect(logbook.marksIfStarted(on: task, now: sept28(9)) == [])
    }

    @Test mutating func dueBreakAndReachedEstimateAreForeseen() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        #expect(logbook.marksIfStarted(on: task, now: sept28(9, 26)) == [.overrun, .skippedBreak])

        try logbook.startPomodoro(on: task, now: sept28(9, 26))
        #expect(logbook.activePomodoro(now: sept28(9, 27))?.marks == [.overrun, .skippedBreak])
    }

    @Test mutating func runningBreakIsForeseen() throws {
        let other = try logbook.addTask(name: "Email", estimate: 2, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        try logbook.startBreak(now: sept28(9, 25))
        #expect(logbook.marksIfStarted(on: other, now: sept28(9, 27)) == [.skippedBreak])
    }
}
