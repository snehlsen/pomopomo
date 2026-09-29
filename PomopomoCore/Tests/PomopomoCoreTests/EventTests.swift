import Foundation
import Testing
@testable import PomopomoCore

/// What the Logbook reports as time passes, with what the app needs to tell you about it.
@Suite struct EventTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 8, now: sept28(9))
    }

    @Test mutating func completionCarriesItsTaskAndTheLongBreakAtTheEndOfASet() throws {
        let email = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9))
        for start in [sept28(9), sept28(9, 30), sept28(10)] {
            try logbook.startPomodoro(on: task, now: start)
            logbook.advance(to: start + 25 * minute)
        }
        try logbook.startPomodoro(on: email, now: sept28(10, 30))
        #expect(logbook.advance(to: sept28(10, 55)) == [.pomodoroCompleted(task: logbook.task(email)!, breakDue: .long)])
    }

    @Test mutating func completionAfterMidnightOffersNoBreak() throws {
        let late = try logbook.addTask(name: "Plan", estimate: 1, now: sept28(23))
        try logbook.startPomodoro(on: late, now: sept28(23, 50))
        #expect(logbook.advance(to: sept29(0, 15)) == [.pomodoroCompleted(task: logbook.task(late)!, breakDue: nil)])
    }

    @Test mutating func breakEndsWithTheTaskItFollowedAsItIsNow() throws {
        let email = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9))
        try logbook.startPomodoro(on: email, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        try logbook.startBreak(now: sept28(9, 25))
        try logbook.markDone(email, now: sept28(9, 27))

        #expect(logbook.advance(to: sept28(9, 30)) == [.breakEnded(after: logbook.task(email)!)])
        #expect(logbook.task(email)?.isDone == true)
    }

    @Test mutating func breakEndingAfterMidnightFollowsATaskThatCanNoLongerStart() throws {
        let late = try logbook.addTask(name: "Plan", estimate: 2, now: sept28(23))
        try logbook.startPomodoro(on: late, now: sept28(23, 30))
        logbook.advance(to: sept28(23, 55))
        try logbook.startBreak(now: sept28(23, 58))

        #expect(logbook.advance(to: sept29(0, 3)) == [.breakEnded(after: logbook.task(late)!)])
        #expect(logbook.options(for: late, now: sept29(0, 3)).start == .refused(.dayIsPast))
    }
}
