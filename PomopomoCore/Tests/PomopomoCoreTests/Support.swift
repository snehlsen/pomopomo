import Foundation
@testable import PomopomoCore

let minute: TimeInterval = 60

var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

/// 2026-09-28 at the given UTC time.
func sept28(_ hour: Int, _ minute: Int = 0, second: Int = 0) -> Date {
    utc.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: hour, minute: minute, second: second))!
}

func newLogbook() -> Logbook {
    Logbook(calendar: utc)
}

/// 2026-09-29 at the given UTC time: the day after `sept28`.
func sept29(_ hour: Int, _ minute: Int = 0) -> Date {
    utc.date(from: DateComponents(year: 2026, month: 9, day: 29, hour: hour, minute: minute))!
}

let sept28Date = DayDate(year: 2026, month: 9, day: 28)
let sept29Date = DayDate(year: 2026, month: 9, day: 29)

extension Logbook {
    /// The Task with this ID, on whichever Day it is.
    func task(_ id: PomopomoCore.Task.ID) -> PomopomoCore.Task? {
        days.lazy.compactMap { $0.task(id) }.first
    }
}
