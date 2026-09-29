import Foundation
import Testing
@testable import PomopomoCore

@Suite struct TaskTests {
    @Test func estimateMustBeAtLeastOne() {
        var logbook = newLogbook()
        #expect(throws: PomopomoError.invalidEstimate) {
            try logbook.addTask(name: "Nothing", estimate: 0, now: sept28(9))
        }
    }

    @Test func pomodoroCanOnlyStartOnATaskOfToday() {
        var logbook = newLogbook()
        #expect(throws: PomopomoError.noSuchTask) {
            try logbook.startPomodoro(on: UUID(), now: sept28(9))
        }
        #expect(logbook.today(now: sept28(9)).pomodoros.isEmpty)
    }
}

@Suite struct DoneAndDeletionTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 1, now: sept28(9))
    }

    var today: Day { logbook.today(now: sept28(9)) }

    @Test mutating func taskCanBeMarkedDoneBeforeReachingItsEstimate() throws {
        try logbook.markDone(task, now: sept28(9))
        #expect(today.task(task)?.isDone == true)
    }

    @Test mutating func taskNeverBecomesDoneOnItsOwn() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9, 30))
        logbook.advance(to: sept28(10))
        #expect(today.completedCount(of: task) == 2)
        #expect(today.task(task)?.isDone == false)
    }

    @Test mutating func taskCannotBeMarkedDoneWhileItsPomodoroIsRunningOrPaused() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        #expect(throws: PomopomoError.taskHasUnfinishedPomodoro) { try logbook.markDone(task, now: sept28(9, 5)) }
        try logbook.pausePomodoro(now: sept28(9, 10))
        #expect(throws: PomopomoError.taskHasUnfinishedPomodoro) { try logbook.markDone(task, now: sept28(9, 15)) }
        #expect(today.task(task)?.isDone == false)

        try logbook.voidPomodoro(now: sept28(9, 20))
        try logbook.markDone(task, now: sept28(9, 21))
        #expect(today.task(task)?.isDone == true)
    }

    @Test mutating func taskCanBeMarkedDoneWhileAnotherTasksPomodoroIsRunning() throws {
        let other = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9))
        try logbook.startPomodoro(on: other, now: sept28(9))
        try logbook.markDone(task, now: sept28(9, 5))
        #expect(today.task(task)?.isDone == true)
    }

    @Test mutating func noPomodoroCanStartOnADoneTask() throws {
        try logbook.markDone(task, now: sept28(9))
        #expect(throws: PomopomoError.taskIsDone) { try logbook.startPomodoro(on: task, now: sept28(9, 1)) }
        #expect(today.pomodoros.isEmpty)
    }

    @Test mutating func taskWithoutStartedPomodorosCanBeDeleted() throws {
        let other = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9))
        try logbook.deleteTask(task, now: sept28(9, 1))
        #expect(today.tasks.map(\.id) == [other])
    }

    @Test mutating func taskWithAVoidedPomodoroCannotBeDeleted() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.voidPomodoro(now: sept28(9, 1))
        #expect(throws: PomopomoError.taskHasPomodoros) { try logbook.deleteTask(task, now: sept28(9, 2)) }
        #expect(today.task(task) != nil)
    }
}
