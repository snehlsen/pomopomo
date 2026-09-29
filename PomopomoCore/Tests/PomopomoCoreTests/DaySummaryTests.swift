import Foundation
import Testing
@testable import PomopomoCore

@Suite struct DaySummaryTests {
    @Test func emptyDaySummary() {
        #expect(Day(date: sept28Date).summary == DaySummary(
            completed: 0, voided: 0, pausedForGood: 0, marks: [:], tasksDone: 0, tasks: 0
        ))
    }

    @Test func pastDaySummaryCountsPomodorosMarksAndDoneTasks() throws {
        var logbook = newLogbook()
        let report = try logbook.addTask(name: "Write report", estimate: 1, now: sept28(9))
        let email = try logbook.addTask(name: "Email", estimate: 2, now: sept28(9))
        try logbook.addTask(name: "Plan", estimate: 1, now: sept28(9))

        try logbook.startPomodoro(on: report, now: sept28(9))
        try logbook.startPomodoro(on: report, now: sept28(9, 30)) // Overrun, skipped Break
        try logbook.startPomodoro(on: email, now: sept28(10)) // skipped Break
        try logbook.voidPomodoro(now: sept28(10, 5))
        try logbook.startPomodoro(on: email, now: sept28(10, 10))
        try logbook.pausePomodoro(now: sept28(10, 15))
        try logbook.resumePomodoro(now: sept28(10, 20))
        try logbook.markDone(report, now: sept28(10, 45))
        try logbook.startPomodoro(on: email, now: sept28(11)) // skipped Break
        try logbook.pausePomodoro(now: sept28(11, 5)) // left Paused when the Day ends

        let summary = logbook.day(on: sept28Date).summary
        #expect(summary == DaySummary(
            completed: 3,
            voided: 1,
            pausedForGood: 1,
            marks: [.overrun: 1, .skippedBreak: 3, .pause: 2],
            tasksDone: 1,
            tasks: 3
        ))
    }
}
