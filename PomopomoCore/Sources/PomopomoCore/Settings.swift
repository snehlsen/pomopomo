import Foundation

/// The lengths the method uses. The book's values are the defaults.
public struct Settings: Hashable, Codable, Sendable {
    public var pomodoroLength: TimeInterval = 25 * 60

    public init() {}
}
