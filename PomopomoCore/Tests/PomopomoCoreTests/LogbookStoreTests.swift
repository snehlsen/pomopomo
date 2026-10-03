import Foundation
import Testing
@testable import PomopomoCore

@Suite struct LogbookStoreTests {
    /// Has a space in it, like the real `Application Support`.
    let directory = FileManager.default.temporaryDirectory.appending(path: "Application Support/\(UUID().uuidString)")

    @Test func startsEmptyWhenNothingIsStored() throws {
        let store = LogbookStore(directory: directory)
        #expect(try store.load(calendar: utc) == Logbook(calendar: utc))
    }

    @Test func tasksAndPomodorosSurviveRelaunch() throws {
        var logbook = newLogbook()
        let task = try logbook.addTask(name: "Write report", estimate: 3, now: sept28(9))
        try logbook.startPomodoro(on: task, now: sept28(9))
        try LogbookStore(directory: directory).save(logbook, now: sept28(9))

        var relaunched = try LogbookStore(directory: directory).load(calendar: utc)
        #expect(relaunched == logbook)
        #expect(relaunched.advance(to: sept28(10)) == [.pomodoroCompleted(task: logbook.task(task)!, breakDue: .short)])
        #expect(relaunched.today(now: sept28(10)).completedCount(of: task) == 1)
    }

    @Test func firstSaveOfADayBacksUpTheFileAsItStood() throws {
        let store = LogbookStore(directory: directory)
        var logbook = newLogbook()
        _ = try logbook.addTask(name: "Write report", estimate: 3, now: sept28(9))
        try store.save(logbook, now: sept28(9))
        let endOfSept28 = logbook

        _ = try logbook.addTask(name: "Review", estimate: 1, now: sept29(9))
        try store.save(logbook, now: sept29(9))
        try store.save(newLogbook(), now: sept29(10))

        #expect(try store.backupDates() == [sept29Date])
        #expect(try store.loadBackup(from: sept29Date, calendar: utc) == endOfSept28)
    }

    @Test func nothingIsBackedUpBeforeThereIsAFile() throws {
        let store = LogbookStore(directory: directory)
        try store.save(newLogbook(), now: sept28(9))
        #expect(try store.backupDates() == [])
    }

    @Test func keepsOnlyTheLatestBackups() throws {
        let store = LogbookStore(directory: directory)
        let days = LogbookStore.backupsKept + 3
        for offset in 0..<days {
            try store.save(newLogbook(), now: sept28(9) + Double(offset) * 24 * 60 * minute)
        }

        let dates = try store.backupDates()
        #expect(dates.count == LogbookStore.backupsKept)
        #expect(dates.last == DayDate(sept28(9) + Double(days - 1) * 24 * 60 * minute, in: utc))
    }

    @Test func unreadableFileIsSetAsideUnchanged() throws {
        let store = LogbookStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not a logbook".utf8).write(to: store.fileURL)
        #expect(throws: (any Error).self) { try store.load(calendar: utc) }

        let setAside = try store.setAsideUnreadableFile(now: sept28(9))

        #expect(try Data(contentsOf: setAside) == Data("not a logbook".utf8))
        #expect(try store.load(calendar: utc) == newLogbook())
    }
}
