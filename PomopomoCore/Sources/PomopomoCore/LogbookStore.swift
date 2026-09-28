import Foundation

/// Keeps the Logbook in a JSON file on this Mac.
public struct LogbookStore: Sendable {
    public let fileURL: URL

    public init(directory: URL) {
        fileURL = directory.appending(path: "logbook.json")
    }

    /// The store in the user's Application Support folder.
    public static var standard: LogbookStore {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LogbookStore(directory: support.appending(path: "Pomopomo"))
    }

    public func load(calendar: Calendar = .current) throws -> Logbook {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return Logbook(calendar: calendar)
        }
        var logbook = try JSONDecoder().decode(Logbook.self, from: Data(contentsOf: fileURL))
        logbook.calendar = calendar
        return logbook
    }

    public func save(_ logbook: Logbook) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(logbook).write(to: fileURL, options: .atomic)
    }
}
