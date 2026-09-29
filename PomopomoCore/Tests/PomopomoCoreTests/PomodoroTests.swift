import Foundation
import Testing
@testable import PomopomoCore

@Suite struct PomodoroTests {
    @Test func runningPomodoroCompletesWhenItsLengthIsUp() throws {
        var logbook = newLogbook()
        let start = sept28(9)
        let task = try logbook.addTask(name: "Write report", estimate: 2, now: start)
        try logbook.startPomodoro(on: task, now: start)

        #expect(logbook.advance(to: sept28(9, 24, second: 59)) == [])
        #expect(logbook.activePomodoro(now: sept28(9, 24, second: 59))?.state == .running(endsAt: sept28(9, 25)))

        let events = logbook.advance(to: sept28(9, 26))
        #expect(events == [.pomodoroCompleted(task: logbook.task(task)!, breakDue: .short)])
        let today = logbook.today(now: sept28(9, 26))
        #expect(today.pomodoros.map(\.state) == [.completed(at: sept28(9, 25))])
        #expect(today.completedCount(of: task) == 1)
        #expect(today.task(task)?.estimate == 2)
    }
}
