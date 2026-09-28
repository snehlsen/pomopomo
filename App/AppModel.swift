import AppKit
import Observation
import PomopomoCore
import UserNotifications

/// Connects the Logbook to the real clock, the file on disk and the system's notifications.
@MainActor
@Observable
final class AppModel {
    private(set) var logbook: Logbook
    private(set) var now = Date()
    private(set) var errorMessage: String?

    @ObservationIgnored private let store: LogbookStore
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var activity: NSObjectProtocol?

    init(store: LogbookStore = .standard) {
        self.store = store
        logbook = Self.load(from: store)
        // Keep App Nap from delaying the countdown; the Mac may still sleep.
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Counting down Pomodoros and Breaks"
        )
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
        tick()
    }

    var today: Day { logbook.today(now: now) }

    /// The Day being looked at: today, or a past Day while browsing. Nil means today.
    var browsedDate: DayDate?

    var shownDay: Day {
        guard let browsedDate, browsedDate < today.date else { return today }
        return logbook.day(on: browsedDate)
    }

    var isShowingPastDay: Bool { shownDay.date < today.date }

    /// Moves `offset` Days back (negative) or forward (positive) among the Days with something on them.
    func browse(by offset: Int) {
        let dates = logbook.browsableDates(now: now)
        let current = dates.firstIndex(of: shownDay.date) ?? dates.count - 1
        let target = min(max(current + offset, 0), dates.count - 1)
        browsedDate = target == dates.count - 1 ? nil : dates[target]
    }

    var canBrowseBack: Bool { logbook.browsableDates(now: now).first != shownDay.date }

    var activePomodoro: Pomodoro? { logbook.activePomodoro(now: now) }

    var dueBreak: Break.Kind? { logbook.dueBreak(now: now) }

    var runningBreak: Break? { logbook.runningBreak(now: now) }

    var isPomodoroRunning: Bool {
        if case .running = activePomodoro?.state { true } else { false }
    }

    func tick() {
        now = Date()
        let events = logbook.advance(to: now)
        guard !events.isEmpty else { return }
        save()
        events.forEach(announce)
    }

    /// Runs a command on the Logbook at the current time, then saves.
    func perform(_ command: (inout Logbook, Date) throws -> Void) {
        now = Date()
        do {
            try command(&logbook, now)
            errorMessage = nil
        } catch let error as PomopomoError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
        save()
    }

    func remaining(of pomodoro: Pomodoro) -> TimeInterval {
        switch pomodoro.state {
        case .running(let endsAt): max(0, endsAt.timeIntervalSince(now))
        case .paused(let remaining): remaining
        case .completed, .voided: 0
        }
    }

    // MARK: Private

    private func save() {
        do {
            try store.save(logbook)
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
        }
    }

    private func announce(_ event: Event) {
        let content = UNMutableNotificationContent()
        switch event {
        case .pomodoroCompleted:
            content.title = "Pomodoro Completed"
            content.body = dueBreak == .long ? "Time for a Long Break." : "Time for a Short Break."
        case .breakEnded:
            content.title = "Break Over"
            content.body = "Start the next Pomodoro when you're ready."
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        NSSound(named: "Glass")?.play()
    }

    /// Loads the stored Logbook. A file that can't be read is moved aside rather than overwritten.
    private static func load(from store: LogbookStore) -> Logbook {
        do {
            return try store.load()
        } catch {
            let backup = store.fileURL.deletingPathExtension()
                .appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: store.fileURL, to: backup)
            return Logbook()
        }
    }
}

extension PomopomoError {
    var message: String {
        switch self {
        case .invalidEstimate: "An Estimate must be at least 1 Pomodoro."
        case .noSuchTask: "That Task isn't on today's list."
        case .pomodoroAlreadyRunning: "A Pomodoro is already Running."
        case .noRunningPomodoro: "No Pomodoro is Running."
        case .noPausedPomodoro: "No Pomodoro is Paused."
        case .noUnfinishedPomodoro: "No Pomodoro is Running or Paused."
        case .estimateLocked: "The Estimate is locked once a Pomodoro on the Task has started."
        case .taskIsDone: "That Task is Done. Add a new Task for extra work."
        case .taskHasPomodoros: "A Task can't be deleted once a Pomodoro on it has started."
        case .noBreakDue: "No Break is due."
        case .noRunningBreak: "No Break is running."
        }
    }
}
