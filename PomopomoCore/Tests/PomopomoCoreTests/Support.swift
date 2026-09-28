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
