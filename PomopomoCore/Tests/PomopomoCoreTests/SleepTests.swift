import Foundation
import Testing
@testable import PomopomoCore

@Suite struct SleepTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 4, now: sept28(9))
    }

    @Test mutating func sleepPausesARunningPomodoroWithItsRemainingTime() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.sleep(now: sept28(9, 10))

        // Waking later: still Paused, ready to resume or void.
        #expect(logbook.advance(to: sept28(12)) == [])
        #expect(logbook.activePomodoro(now: sept28(12))?.state == .paused(remaining: 15 * minute))
    }

    @Test mutating func pomodoroPausedBySleepCarriesAPauseMarkOnceCompleted() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.sleep(now: sept28(9, 10))
        try logbook.resumePomodoro(now: sept28(12))
        logbook.advance(to: sept28(12, 15))

        let pomodoro = logbook.today(now: sept28(12, 15)).pomodoros[0]
        #expect(pomodoro.state == .completed(at: sept28(12, 15)))
        #expect(pomodoro.marks == [.pause])
    }

    @Test mutating func sleepDoesNotPauseARunningBreak() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        try logbook.startBreak(now: sept28(9, 25))
        logbook.sleep(now: sept28(9, 27))

        #expect(logbook.runningBreak(now: sept28(9, 28))?.endsAt == sept28(9, 30))
        #expect(logbook.advance(to: sept28(9, 30)) == [.breakEnded])
    }

    @Test mutating func sleepLeavesAPausedPomodoroAlone() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.pausePomodoro(now: sept28(9, 5))
        logbook.sleep(now: sept28(9, 10))
        #expect(logbook.activePomodoro(now: sept28(9, 10))?.state == .paused(remaining: 20 * minute))
    }

    @Test mutating func pomodoroThatFinishedBeforeSleepIsCompletedNotPaused() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        // No tick happened between 9:25 and 9:30.
        #expect(logbook.sleep(now: sept28(9, 30)) == [.pomodoroCompleted])
        #expect(logbook.today(now: sept28(9, 30)).pomodoros.map(\.state) == [.completed(at: sept28(9, 25))])
    }
}
