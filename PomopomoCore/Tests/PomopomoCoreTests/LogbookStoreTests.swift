import Foundation
import Testing
@testable import PomopomoCore

@Suite struct LogbookStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    @Test func startsEmptyWhenNothingIsStored() throws {
        let store = LogbookStore(directory: directory)
        #expect(try store.load(calendar: utc) == Logbook(calendar: utc))
    }

    @Test func tasksAndPomodorosSurviveRelaunch() throws {
        var logbook = newLogbook()
        let task = try logbook.addTask(name: "Write report", estimate: 3, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        try LogbookStore(directory: directory).save(logbook)

        var relaunched = try LogbookStore(directory: directory).load(calendar: utc)
        #expect(relaunched == logbook)
        #expect(relaunched.advance(to: sept28(10)) == [.pomodoroCompleted])
        #expect(relaunched.today(now: sept28(10)).completedCount(of: task) == 1)
    }
}
