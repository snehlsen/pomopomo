import Foundation
import Testing
@testable import PomopomoCore

@Suite struct SetProgressTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 8, now: sept28(9))
    }

    /// Starts a Pomodoro at `start` and lets it run to Completed.
    mutating func complete(at start: Date) throws {
        try logbook.startPomodoro(on: task, now: start)
        logbook.advance(to: start + 25 * minute)
    }

    @Test func newDayStartsTheFirstSetEmpty() {
        #expect(logbook.setProgress(now: sept28(9)) == SetProgress(number: 1, completed: 0, size: 4, completedToday: 0))
    }

    @Test mutating func onlyCompletedPomodorosCount() throws {
        try complete(at: sept28(9))
        try complete(at: sept28(9, 30))
        try logbook.startPomodoro(on: task, now: sept28(10))
        try logbook.voidPomodoro(now: sept28(10, 5))
        try logbook.startPomodoro(on: task, now: sept28(10, 10))
        try logbook.pausePomodoro(now: sept28(10, 15))
        #expect(logbook.setProgress(now: sept28(10, 20)) == SetProgress(number: 1, completed: 2, size: 4, completedToday: 2))
    }

    @Test mutating func fullSetShowsUntilItsLongBreakIsOver() throws {
        for start in [sept28(9), sept28(9, 30), sept28(10), sept28(10, 30)] { try complete(at: start) }
        #expect(logbook.setProgress(now: sept28(10, 55)) == SetProgress(number: 1, completed: 4, size: 4, completedToday: 4))

        try logbook.startBreak(now: sept28(11))
        #expect(logbook.setProgress(now: sept28(11, 5)) == SetProgress(number: 1, completed: 4, size: 4, completedToday: 4))

        logbook.advance(to: sept28(11, 15))
        #expect(logbook.setProgress(now: sept28(11, 15)) == SetProgress(number: 2, completed: 0, size: 4, completedToday: 4))
    }

    @Test mutating func skippedLongBreakStartsTheNextSet() throws {
        for start in [sept28(9), sept28(9, 30), sept28(10), sept28(10, 30)] { try complete(at: start) }
        try logbook.startPomodoro(on: task, now: sept28(11))
        #expect(logbook.setProgress(now: sept28(11, 5)) == SetProgress(number: 2, completed: 0, size: 4, completedToday: 4))

        logbook.advance(to: sept28(11, 25))
        #expect(logbook.setProgress(now: sept28(11, 25)) == SetProgress(number: 2, completed: 1, size: 4, completedToday: 5))
    }

    @Test mutating func changedSetSizeAppliesStraightAway() throws {
        for start in [sept28(9), sept28(9, 30), sept28(10)] { try complete(at: start) }
        var settings = Settings()
        settings.setSize = 3
        try logbook.changeSettings(settings)
        #expect(logbook.setProgress(now: sept28(10, 30)) == SetProgress(number: 1, completed: 3, size: 3, completedToday: 3))
    }
}
