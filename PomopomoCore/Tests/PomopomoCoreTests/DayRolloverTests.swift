import Foundation
import Testing
@testable import PomopomoCore

@Suite struct DayRolloverTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 3, now: sept28(23))
    }

    var yesterday: Day { logbook.day(on: sept28Date) }

    @Test mutating func newDateStartsAnEmptyDay() throws {
        try logbook.startPomodoro(on: task, now: sept28(23))
        logbook.advance(to: sept29(8)) // waking the Mac on a new date

        #expect(logbook.today(now: sept29(8)).date == sept29Date)
        #expect(logbook.today(now: sept29(8)).tasks.isEmpty)
        #expect(yesterday.tasks.map(\.id) == [task])
        #expect(yesterday.completedCount(of: task) == 1)
    }

    @Test mutating func pomodoroRunningAtMidnightKeepsItsDayOpenUntilCompleted() throws {
        try logbook.startPomodoro(on: task, now: sept28(23, 50))

        #expect(logbook.today(now: sept29(0, 10)).date == sept28Date)
        #expect(logbook.advance(to: sept29(0, 15)) == [.pomodoroCompleted])
        #expect(yesterday.pomodoros.map(\.state) == [.completed(at: sept29(0, 15))])
        #expect(yesterday.completedCount(of: task) == 1)
        #expect(yesterday.completedCount == 1)
        #expect(logbook.today(now: sept29(0, 15)).date == sept29Date)
    }

    @Test mutating func pausingAfterMidnightEndsTheDayAndThePomodoroStaysPausedForGood() throws {
        try logbook.startPomodoro(on: task, now: sept28(23, 50))
        try logbook.pausePomodoro(now: sept29(0, 5))

        #expect(logbook.today(now: sept29(0, 5)).date == sept29Date)
        #expect(logbook.activePomodoro(now: sept29(0, 5)) == nil)
        #expect(throws: PomopomoError.noPausedPomodoro) { try logbook.resumePomodoro(now: sept29(0, 6)) }
        #expect(throws: PomopomoError.noUnfinishedPomodoro) { try logbook.voidPomodoro(now: sept29(0, 6)) }
        #expect(yesterday.pomodoros.map(\.state) == [.paused(remaining: 10 * minute)])
    }

    @Test mutating func pomodoroPausedBeforeMidnightStaysPausedForGood() throws {
        try logbook.startPomodoro(on: task, now: sept28(23, 30))
        try logbook.pausePomodoro(now: sept28(23, 40))

        let newTask = try logbook.addTask(name: "Write report", estimate: 2, now: sept29(9))
        try logbook.startPomodoro(on: newTask, now: sept29(9))
        logbook.advance(to: sept29(10))

        #expect(yesterday.pomodoros.map(\.state) == [.paused(remaining: 15 * minute)])
        #expect(yesterday.completedCount == 0)
        #expect(logbook.today(now: sept29(10)).completedCount(of: newTask) == 1)
    }

    @Test mutating func nothingOnAPastDayCanBeChanged() throws {
        let unstarted = try logbook.addTask(name: "Email", estimate: 1, now: sept28(23))
        let now = sept29(9)
        #expect(throws: PomopomoError.noSuchTask) { try logbook.startPomodoro(on: task, now: now) }
        #expect(throws: PomopomoError.noSuchTask) { try logbook.markDone(task, now: now) }
        #expect(throws: PomopomoError.noSuchTask) { try logbook.changeEstimate(of: unstarted, to: 2, now: now) }
        #expect(throws: PomopomoError.noSuchTask) { try logbook.deleteTask(unstarted, now: now) }
        #expect(yesterday.tasks.map(\.estimate) == [3, 1])
        #expect(yesterday.tasks.map(\.isDone) == [false, false])
    }

    @Test mutating func breakDueOnThePreviousDayIsNotOfferedOnTheNewDay() throws {
        try logbook.startPomodoro(on: task, now: sept28(23, 50))
        logbook.advance(to: sept29(0, 15))
        #expect(logbook.dueBreak(now: sept29(0, 15)) == nil)

        let newTask = try logbook.addTask(name: "Email", estimate: 1, now: sept29(9))
        try logbook.startPomodoro(on: newTask, now: sept29(9))
        #expect(logbook.today(now: sept29(9)).pomodoros[0].marks.isEmpty)
    }
}

@Suite struct BrowsingTests {
    @Test func browsableDaysArePastDaysWithSomethingOnThemThenToday() throws {
        var logbook = newLogbook()
        let sept26 = utc.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 9))!
        try logbook.addTask(name: "Plan", estimate: 1, now: sept26)
        try logbook.addTask(name: "Write report", estimate: 1, now: sept28(9))

        #expect(logbook.browsableDates(now: sept29(9)) == [
            DayDate(year: 2026, month: 9, day: 26), sept28Date, sept29Date,
        ])
        #expect(logbook.browsableDates(now: sept28(10)) == [DayDate(year: 2026, month: 9, day: 26), sept28Date])
    }
}
