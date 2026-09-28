import Foundation

/// Timed rest after a Completed Pomodoro, started by you.
public struct Break: Hashable, Codable, Sendable {
    public enum Kind: String, Hashable, Codable, Sendable {
        case short, long
    }

    public let kind: Kind
    /// The length it started with; it keeps this even if the setting changes.
    public let length: TimeInterval
    public let endsAt: Date
}

/// Where the Logbook stands with Breaks. A Break belongs to the Day of the Pomodoro before it
/// and never carries over into a new Day.
enum BreakStatus: Hashable, Codable, Sendable {
    /// A Pomodoro on this Day was just Completed and its Break hasn't started.
    case due(on: DayDate)
    case running(Break, on: DayDate)
    /// The Break on this Day was ended before its time was up.
    case endedEarly(on: DayDate)
}
