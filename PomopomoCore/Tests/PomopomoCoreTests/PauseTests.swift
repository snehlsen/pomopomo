import Foundation
import Testing
@testable import PomopomoCore

@Suite struct PauseTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 2, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
    }

    @Test mutating func pausedPomodoroKeepsItsRemainingTime() throws {
        try logbook.pausePomodoro(now: sept28(9, 10))
        #expect(logbook.activePomodoro(now: sept28(9, 10))?.state == .paused(remaining: 15 * minute))

        // Time passing while Paused doesn't complete it.
        #expect(logbook.advance(to: sept28(11)) == [])

        try logbook.resumePomodoro(now: sept28(11))
        #expect(logbook.activePomodoro(now: sept28(11))?.state == .running(endsAt: sept28(11, 15)))
    }

    @Test mutating func pomodoroCanBePausedAndResumedSeveralTimes() throws {
        try logbook.pausePomodoro(now: sept28(9, 10))
        try logbook.resumePomodoro(now: sept28(9, 30))
        try logbook.pausePomodoro(now: sept28(9, 40))
        try logbook.resumePomodoro(now: sept28(10))

        #expect(logbook.advance(to: sept28(10, 4)) == [])
        #expect(logbook.advance(to: sept28(10, 5)) == [.pomodoroCompleted])
        #expect(logbook.today(now: sept28(10, 5)).pomodoros.map(\.state) == [.completed(at: sept28(10, 5))])
    }

    @Test mutating func completedPomodoroThatWasPausedCarriesAPauseMark() throws {
        try logbook.pausePomodoro(now: sept28(9, 10))
        try logbook.resumePomodoro(now: sept28(9, 20))
        logbook.advance(to: sept28(10))
        try logbook.startPomodoro(on: task, now: sept28(10))
        logbook.advance(to: sept28(11))

        let day = logbook.today(now: sept28(11))
        #expect(day.pomodoros.map { $0.marks.contains(.pause) } == [true, false])
        #expect(day.completedCount(of: task) == 2)
    }

    @Test mutating func onlyARunningPomodoroCanBePausedAndOnlyAPausedOneResumed() throws {
        #expect(throws: PomopomoError.noPausedPomodoro) { try logbook.resumePomodoro(now: sept28(9, 5)) }
        try logbook.pausePomodoro(now: sept28(9, 5))
        #expect(throws: PomopomoError.noRunningPomodoro) { try logbook.pausePomodoro(now: sept28(9, 6)) }
    }
}
