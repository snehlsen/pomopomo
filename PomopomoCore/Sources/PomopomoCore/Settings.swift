import Foundation

/// The lengths the method uses. The book's values are the defaults.
public struct Settings: Hashable, Codable, Sendable {
    public var pomodoroLength: TimeInterval = 25 * 60
    public var shortBreakLength: TimeInterval = 5 * 60
    public var longBreakLength: TimeInterval = 15 * 60
    /// How many Completed Pomodoros make a Set, after which a Long Break is due.
    public var setSize = 4

    public init() {}
}
