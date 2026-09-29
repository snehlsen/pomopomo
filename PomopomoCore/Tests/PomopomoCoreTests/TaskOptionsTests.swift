import Foundation
import Testing
@testable import PomopomoCore

/// Knowing before pressing anything what a Task allows, and which Marks a new Pomodoro on it would carry.
@Suite struct TaskOptionsTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 1, now: sept28(9))
    }

    @Test func untouchedTaskAllowsEverything() {
        #expect(logbook.options(for: task, now: sept28(9)) == TaskOptions(
            start: .start(marks: []),
            changeEstimate: .allowed,
            rename: .allowed,
            delete: .allowed,
            markDone: .allowed
        ))
    }

    @Test mutating func startedTaskLocksItsEstimateAndNameAndCannotBeDeleted() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.voidPomodoro(now: sept28(9, 1))
        let options = logbook.options(for: task, now: sept28(9, 2))
        #expect(options.changeEstimate == .refused(.estimateLocked))
        #expect(options.rename == .refused(.nameLocked))
        #expect(options.delete == .refused(.taskHasPomodoros))
        #expect(options.markDone == .allowed)
        #expect(options.start == .start(marks: []))
    }

    @Test mutating func doneTaskAllowsNothing() throws {
        try logbook.markDone(task, now: sept28(9))
        #expect(logbook.options(for: task, now: sept28(9, 1)) == TaskOptions(refusingAllWith: .taskIsDone))
    }

    @Test func taskOnAPastDayAllowsNothing() {
        #expect(logbook.options(for: task, now: sept29(9)) == TaskOptions(refusingAllWith: .dayIsPast))
    }

    @Test func unknownTaskAllowsNothing() {
        #expect(logbook.options(for: UUID(), now: sept28(9)) == TaskOptions(refusingAllWith: .noSuchTask))
    }

    @Test mutating func runningPomodoroRefusesEveryStartAndMarkingItsTaskDone() throws {
        let other = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        #expect(logbook.options(for: task, now: sept28(9, 5)).start == .refused(.pomodoroAlreadyRunning))
        #expect(logbook.options(for: task, now: sept28(9, 5)).markDone == .refused(.taskHasUnfinishedPomodoro))
        #expect(logbook.options(for: other, now: sept28(9, 5)).start == .refused(.pomodoroAlreadyRunning))
        #expect(logbook.options(for: other, now: sept28(9, 5)).markDone == .allowed)
    }

    @Test mutating func pausedPomodoroIsResumedOnItsOwnTaskAndVoidedToStartAnother() throws {
        let other = try logbook.addTask(name: "Email", estimate: 1, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.pausePomodoro(now: sept28(9, 5))
        #expect(logbook.options(for: task, now: sept28(9, 6)).start == .resume)
        #expect(logbook.options(for: task, now: sept28(9, 6)).markDone == .refused(.taskHasUnfinishedPomodoro))
        #expect(logbook.options(for: other, now: sept28(9, 6)).start == .voidAndStart(marks: []))
    }

    @Test mutating func dueBreakAndReachedEstimateAreForeseen() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        #expect(logbook.options(for: task, now: sept28(9, 26)).start == .start(marks: [.overrun, .skippedBreak]))

        try logbook.startPomodoro(on: task, now: sept28(9, 26))
        #expect(logbook.activePomodoro(now: sept28(9, 27))?.marks == [.overrun, .skippedBreak])
    }

    @Test mutating func runningBreakIsForeseen() throws {
        let other = try logbook.addTask(name: "Email", estimate: 2, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        try logbook.startBreak(now: sept28(9, 25))
        #expect(logbook.options(for: other, now: sept28(9, 27)).start == .start(marks: [.skippedBreak]))
    }
}
