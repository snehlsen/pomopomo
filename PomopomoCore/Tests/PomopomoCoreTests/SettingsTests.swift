import Foundation
import Testing
@testable import PomopomoCore

@Suite struct SettingsTests {
    var logbook = newLogbook()
    let task: PomopomoCore.Task.ID

    var writeReport: PomopomoCore.Task { logbook.task(task)! }

    init() throws {
        task = try logbook.addTask(name: "Write report", estimate: 8, now: sept28(9))
    }

    func settings(pomodoro: Double = 25, short: Double = 5, long: Double = 15, setSize: Int = 4) -> Settings {
        var settings = Settings()
        settings.pomodoroLength = pomodoro * minute
        settings.shortBreakLength = short * minute
        settings.longBreakLength = long * minute
        settings.setSize = setSize
        return settings
    }

    @Test func defaultsAreTheBooksValues() {
        #expect(Settings() == settings(pomodoro: 25, short: 5, long: 15, setSize: 4))
    }

    @Test mutating func runningPomodoroKeepsItsLengthAndTheNextUsesTheNewOne() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.changeSettings(settings(pomodoro: 50))
        #expect(logbook.advance(to: sept28(9, 25)) == [.pomodoroCompleted(task: writeReport, breakDue: .short)])

        try logbook.startPomodoro(on: task, now: sept28(10))
        #expect(logbook.activePomodoro(now: sept28(10))?.state == .running(endsAt: sept28(10, 50)))
    }

    @Test mutating func pausedPomodoroKeepsItsLength() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        try logbook.pausePomodoro(now: sept28(9, 20))
        try logbook.changeSettings(settings(pomodoro: 10))
        try logbook.resumePomodoro(now: sept28(10))
        #expect(logbook.activePomodoro(now: sept28(10))?.state == .running(endsAt: sept28(10, 5)))
        #expect(logbook.activePomodoro(now: sept28(10))?.length == 25 * minute)
    }

    @Test mutating func runningBreakKeepsItsLengthAndTheNextUsesTheNewOne() throws {
        try logbook.startPomodoro(on: task, now: sept28(9))
        logbook.advance(to: sept28(9, 25))
        try logbook.startBreak(now: sept28(9, 25))
        try logbook.changeSettings(settings(short: 10))
        #expect(logbook.advance(to: sept28(9, 30)) == [.breakEnded(after: writeReport)])

        try logbook.startPomodoro(on: task, now: sept28(9, 30))
        logbook.advance(to: sept28(9, 55))
        try logbook.startBreak(now: sept28(9, 55))
        #expect(logbook.runningBreak(now: sept28(9, 55))?.endsAt == sept28(10, 5))
    }

    @Test mutating func changingTheSetSizeAffectsTheDueBreakStraightAway() throws {
        for start in [sept28(9), sept28(9, 30), sept28(10)] {
            try logbook.startPomodoro(on: task, now: start)
            logbook.advance(to: start + 25 * minute)
        }
        #expect(logbook.dueBreak(now: sept28(10, 25)) == .short)

        try logbook.changeSettings(settings(setSize: 3))
        #expect(logbook.dueBreak(now: sept28(10, 25)) == .long)
    }

    @Test mutating func settingsMustBePositive() {
        for invalid in [settings(pomodoro: 0), settings(short: 0), settings(long: -1), settings(setSize: 0)] {
            #expect(throws: PomopomoError.invalidSettings) { try logbook.changeSettings(invalid) }
        }
        #expect(logbook.settings == Settings())
    }

    @Test mutating func settingsSurviveRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try logbook.changeSettings(settings(pomodoro: 30, short: 6, long: 20, setSize: 3))
        try LogbookStore(directory: directory).save(logbook, now: sept28(9))

        #expect(try LogbookStore(directory: directory).load(calendar: utc).settings == settings(pomodoro: 30, short: 6, long: 20, setSize: 3))
    }
}
