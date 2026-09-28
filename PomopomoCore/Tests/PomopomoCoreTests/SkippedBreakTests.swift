import Foundation
import Testing
@testable import PomopomoCore

@Suite struct SkippedBreakTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 8, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
    }

    var today: Day { logbook.today(now: sept28(9)) }

    @Test mutating func startingAPomodoroInsteadOfTheDueBreakGivesASkippedBreakMark() throws {
        try logbook.startPomodoro(on: task, now: sept28(9, 26))
        #expect(today.pomodoros.map(\.marks) == [[], [.skippedBreak]])
        #expect(logbook.dueBreak(now: sept28(9, 26)) == nil)
    }

    @Test mutating func endingABreakEarlyGivesTheNextPomodoroASkippedBreakMark() throws {
        try logbook.startBreak(now: sept28(9, 25))
        try logbook.endBreak(now: sept28(9, 27))
        #expect(logbook.runningBreak(now: sept28(9, 27)) == nil)
        #expect(logbook.dueBreak(now: sept28(9, 27)) == nil)

        try logbook.startPomodoro(on: task, now: sept28(9, 40))
        #expect(today.pomodoros.map(\.marks) == [[], [.skippedBreak]])
    }

    @Test mutating func startingAPomodoroDuringABreakEndsItEarly() throws {
        try logbook.startBreak(now: sept28(9, 25))
        try logbook.startPomodoro(on: task, now: sept28(9, 27))
        #expect(logbook.runningBreak(now: sept28(9, 27)) == nil)
        #expect(logbook.advance(to: sept28(9, 31)) == [])
        #expect(today.pomodoros.map(\.marks) == [[], [.skippedBreak]])
    }

    @Test mutating func takingTheFullBreakGivesNoMark() throws {
        try logbook.startBreak(now: sept28(9, 25))
        logbook.advance(to: sept28(9, 30))
        try logbook.startPomodoro(on: task, now: sept28(9, 45))
        #expect(today.pomodoros.map(\.marks) == [[], []])
    }

    @Test mutating func skippedLongBreakIsNotOwedLater() throws {
        for start in [sept28(10), sept28(10, 30), sept28(11)] {
            try logbook.startPomodoro(on: task, now: start)
            logbook.advance(to: start + 25 * minute)
        }
        #expect(logbook.dueBreak(now: sept28(11, 25)) == .long)

        try logbook.startPomodoro(on: task, now: sept28(11, 30))
        logbook.advance(to: sept28(11, 55))
        #expect(logbook.dueBreak(now: sept28(11, 55)) == .short)
    }

    @Test mutating func pomodoroCanCarryAllThreeMarks() throws {
        let small = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9, 25))
        try logbook.startPomodoro(on: small, now: sept28(9, 25))
        logbook.advance(to: sept28(9, 50))
        try logbook.startPomodoro(on: small, now: sept28(9, 50))
        try logbook.pausePomodoro(now: sept28(10))
        try logbook.resumePomodoro(now: sept28(10, 5))
        logbook.advance(to: sept28(11))

        #expect(today.pomodoros(on: small).last?.marks == [.pause, .overrun, .skippedBreak])
    }

    @Test mutating func onlyARunningBreakCanBeEnded() throws {
        #expect(throws: PomopomoError.noRunningBreak) { try logbook.endBreak(now: sept28(9, 26)) }
    }
}
