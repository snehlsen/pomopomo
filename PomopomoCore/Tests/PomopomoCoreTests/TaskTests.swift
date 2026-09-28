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
        #expect(logbook.day(containing: sept28(9)).pomodoros.isEmpty)
    }
}
