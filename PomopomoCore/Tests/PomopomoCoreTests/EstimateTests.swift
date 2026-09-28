import Foundation
import Testing
@testable import PomopomoCore

@Suite struct EstimateTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 1, now: sept28(9))
    }

    var today: Day { logbook.day(containing: sept28(9)) }

    @Test mutating func estimateCanChangeUntilTheFirstPomodoroStarts() throws {
        try logbook.changeEstimate(of: task, to: 3, now: sept28(9))
        #expect(today.task(task)?.estimate == 3)

        try logbook.startPomodoro(on: task, now: sept28(9))
        #expect(throws: PomopomoError.estimateLocked) {
            try logbook.changeEstimate(of: task, to: 4, now: sept28(9, 1))
        }
    }

    @Test mutating func estimateStaysLockedAfterTheFirstPomodoroIsVoided() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.voidPomodoro(now: sept28(9, 1))
        #expect(throws: PomopomoError.estimateLocked) {
            try logbook.changeEstimate(of: task, to: 4, now: sept28(9, 2))
        }
        #expect(today.task(task)?.estimate == 1)
    }

    @Test mutating func changedEstimateMustBeAtLeastOne() {
        #expect(throws: PomopomoError.invalidEstimate) {
            try logbook.changeEstimate(of: task, to: 0, now: sept28(9))
        }
    }

    @Test mutating func pomodorosBeyondTheEstimateCarryAnOverrunMark() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9, 30))
        try logbook.startPomodoro(on: task, now: sept28(10))
        logbook.advance(to: sept28(10, 30))

        #expect(today.pomodoros.map(\.marks) == [[], [.overrun], [.overrun]])
        #expect(today.completedCount(of: task) == 3)
    }

    @Test mutating func voidedPomodorosDontUseUpTheEstimate() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.voidPomodoro(now: sept28(9, 5))
        try logbook.startPomodoro(on: task, now: sept28(9, 10))
        logbook.advance(to: sept28(10))

        #expect(today.pomodoros.map(\.marks) == [[], []])
    }

    @Test mutating func pomodoroCanCarryBothAPauseAndAnOverrunMark() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9, 30))
        try logbook.pausePomodoro(now: sept28(9, 40))
        try logbook.resumePomodoro(now: sept28(9, 45))
        logbook.advance(to: sept28(11))

        #expect(today.pomodoros.map(\.marks) == [[], [.overrun, .pause]])
    }
}
