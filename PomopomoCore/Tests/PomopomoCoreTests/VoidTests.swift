import Foundation
import Testing
@testable import PomopomoCore

@Suite struct VoidTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 2, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
    }

    var today: Day { logbook.day(containing: sept28(12)) }

    @Test mutating func runningPomodoroCanBeVoided() throws {
        try logbook.voidPomodoro(now: sept28(9, 10))
        #expect(today.pomodoros.map(\.state) == [.voided(at: sept28(9, 10))])
        #expect(logbook.advance(to: sept28(10)) == [])
        #expect(today.completedCount(of: task) == 0)
    }

    @Test mutating func pausedPomodoroCanBeVoided() throws {
        try logbook.pausePomodoro(now: sept28(9, 10))
        try logbook.voidPomodoro(now: sept28(9, 20))
        #expect(today.pomodoros.map(\.state) == [.voided(at: sept28(9, 20))])
        #expect(logbook.activePomodoro(now: sept28(9, 20)) == nil)
    }

    @Test mutating func startingWhilePausedVoidsThePausedPomodoro() throws {
        try logbook.pausePomodoro(now: sept28(9, 10))
        try logbook.startPomodoro(on: task, now: sept28(9, 30))
        #expect(today.pomodoros.map(\.state) == [.voided(at: sept28(9, 30)), .running(endsAt: sept28(9, 55))])

        logbook.advance(to: sept28(10))
        #expect(today.completedCount(of: task) == 1)
    }

    @Test mutating func cannotStartWhileAnotherIsRunning() throws {
        let other = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9, 5))
        #expect(throws: PomopomoError.pomodoroAlreadyRunning) {
            try logbook.startPomodoro(on: other, now: sept28(9, 5))
        }
        #expect(today.pomodoros.count == 1)
    }

    @Test mutating func nothingToVoidWithoutAnUnfinishedPomodoro() throws {
        logbook.advance(to: sept28(10))
        #expect(throws: PomopomoError.noUnfinishedPomodoro) { try logbook.voidPomodoro(now: sept28(10)) }
    }
}
