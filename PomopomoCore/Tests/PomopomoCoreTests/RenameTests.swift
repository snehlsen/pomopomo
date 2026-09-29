import Foundation
import Testing
@testable import PomopomoCore

@Suite struct RenameTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    init() throws {
        task = try logbook.addTask(name: "Wirte report", estimate: 1, now: sept28(9))
    }

    var today: Day { logbook.today(now: sept28(9)) }

    @Test mutating func taskCanBeRenamedBeforeItsFirstPomodoro() throws {
        try logbook.renameTask(task, to: "  Write report ", now: sept28(9, 1))
        #expect(today.task(task)?.name == "Write report")
    }

    @Test mutating func nameThatIsEmptyAfterTrimmingIsRefused() throws {
        #expect(throws: PomopomoError.invalidName) { try logbook.renameTask(task, to: " \n ", now: sept28(9, 1)) }
        #expect(today.task(task)?.name == "Wirte report")
    }

    @Test mutating func nameLocksWhenTheFirstPomodoroStarts() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.voidPomodoro(now: sept28(9, 1))
        #expect(throws: PomopomoError.nameLocked) { try logbook.renameTask(task, to: "Write report", now: sept28(9, 2)) }
        #expect(today.task(task)?.name == "Wirte report")
    }

    @Test mutating func taskOnAPastDayCannotBeRenamed() throws {
        #expect(throws: PomopomoError.noSuchTask) { try logbook.renameTask(task, to: "Write report", now: sept29(9)) }
        #expect(logbook.day(on: sept28Date).task(task)?.name == "Wirte report")
    }
}
