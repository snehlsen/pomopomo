import Foundation

/// Keeps the Logbook in a JSON file on this Mac, with a copy of it from each of the last few days.
public struct LogbookStore: Sendable {
    public let fileURL: URL
    /// Holds `logbook-YYYY-MM-DD.json`: the file as it stood before the first save on that date.
    public let backupsURL: URL

    /// How many daily backups are kept; older ones are deleted.
    public static let backupsKept = 14

    public init(directory: URL) {
        fileURL = directory.appending(path: "logbook.json")
        backupsURL = directory.appending(path: "Backups")
    }

    /// The store in the user's Application Support folder.
    public static var standard: LogbookStore {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LogbookStore(directory: support.appending(path: "Pomopomo"))
    }

    public func load(calendar: Calendar = .current) throws -> Logbook {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return Logbook(calendar: calendar)
        }
        return try Self.decode(contentsOf: fileURL, calendar: calendar)
    }

    /// Saves the Logbook, first backing up the file as it stood if this is the first save on `now`'s date.
    public func save(_ logbook: Logbook, now: Date = Date()) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try backUp(on: DayDate(now, in: logbook.calendar))
        try JSONEncoder().encode(logbook).write(to: fileURL, options: .atomic)
    }

    /// Moves a file that `load` couldn't read out of the way, so saving can't overwrite it.
    /// Returns where it went.
    public func setAsideUnreadableFile(now: Date = Date()) throws -> URL {
        let destination = fileURL.deletingPathExtension()
            .appendingPathExtension("unreadable-\(Int(now.timeIntervalSince1970)).json")
        try FileManager.default.moveItem(at: fileURL, to: destination)
        return destination
    }

    // MARK: Backups

    /// The dates there is a backup from, oldest first.
    public func backupDates() throws -> [DayDate] {
        try backupFiles().compactMap { Self.date(ofBackup: $0) }
    }

    public func loadBackup(from date: DayDate, calendar: Calendar = .current) throws -> Logbook {
        try Self.decode(contentsOf: backupURL(on: date), calendar: calendar)
    }

    private func backUp(on date: DayDate) throws {
        let backup = backupURL(on: date)
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)),
              !FileManager.default.fileExists(atPath: backup.path(percentEncoded: false)) else { return }
        try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fileURL, to: backup)
        for old in try backupFiles().dropLast(Self.backupsKept) {
            try FileManager.default.removeItem(at: old)
        }
    }

    private func backupURL(on date: DayDate) -> URL {
        backupsURL.appending(path: String(format: "logbook-%04d-%02d-%02d.json", date.year, date.month, date.day))
    }

    /// The backup files, oldest first: their names sort by date.
    private func backupFiles() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: backupsURL.path(percentEncoded: false)) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: backupsURL, includingPropertiesForKeys: nil)
            .filter { Self.date(ofBackup: $0) != nil }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func date(ofBackup url: URL) -> DayDate? {
        let name = url.lastPathComponent
        guard name.hasPrefix("logbook-"), name.hasSuffix(".json") else { return nil }
        let parts = name.dropFirst("logbook-".count).dropLast(".json".count).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return DayDate(year: parts[0], month: parts[1], day: parts[2])
    }

    private static func decode(contentsOf url: URL, calendar: Calendar) throws -> Logbook {
        var logbook = try JSONDecoder().decode(Logbook.self, from: Data(contentsOf: url))
        logbook.calendar = calendar
        return logbook
    }
}
