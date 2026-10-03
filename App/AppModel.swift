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
    /// What went wrong last, and where, so it can show next to the control that caused it.
    private(set) var error: PlacedError?
    /// Saving has no single control, so this shows on its own until saving works again.
    private(set) var saveErrorMessage: String?
    /// What happened to a Logbook that couldn't be read at launch. Shows until the app quits.
    private(set) var loadMessage: String?

    /// Whether a sound plays when a Pomodoro or Break ends. Stored on this Mac.
    var playsSound: Bool {
        didSet { UserDefaults.standard.set(playsSound, forKey: "playsSound") }
    }

    /// How the menu bar shows the time left. Stored on this Mac.
    var menuBarDisplay: MenuBarDisplay {
        didSet { UserDefaults.standard.set(menuBarDisplay.rawValue, forKey: "menuBarDisplay") }
    }

    @ObservationIgnored private let store: LogbookStore
    /// Off when the stored Logbook couldn't be read or set aside, so saving can't overwrite it.
    @ObservationIgnored private var savesToStore = true
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var activity: NSObjectProtocol?
    @ObservationIgnored private let notificationHandler = NotificationHandler()

    init(store: LogbookStore = .standard) {
        self.store = store
        logbook = Logbook()
        playsSound = UserDefaults.standard.object(forKey: "playsSound") as? Bool ?? true
        menuBarDisplay = UserDefaults.standard.string(forKey: "menuBarDisplay")
            .flatMap(MenuBarDisplay.init(rawValue:)) ?? .minutesAndSeconds
        load()
        // Keep App Nap from delaying the countdown; the Mac may still sleep.
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Counting down Pomodoros and Breaks"
        )
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        observeSleepAndWake()
        notificationHandler.model = self
        notificationHandler.register()
        tick()
    }

    /// How long an error stays next to its control.
    private static let errorDuration: TimeInterval = 6

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

    var setProgress: SetProgress { logbook.setProgress(now: now) }

    func options(for taskID: PomopomoCore.Task.ID) -> TaskOptions {
        logbook.options(for: taskID, now: now)
    }

    var isPomodoroRunning: Bool {
        if case .running = activePomodoro?.state { true } else { false }
    }

    func tick() {
        now = Date()
        if let error, now.timeIntervalSince(error.shownAt) >= Self.errorDuration {
            self.error = nil
        }
        let events = logbook.advance(to: now)
        guard !events.isEmpty else { return }
        save()
        events.forEach(announce)
    }

    /// The Mac is going to sleep: a Running Pomodoro is Paused.
    func willSleep() {
        now = Date()
        let events = logbook.sleep(now: now)
        save()
        events.forEach(announce)
    }

    /// Runs a command on the Logbook at the current time, then saves. If it fails, the message
    /// shows at `place` until the next command or for a few seconds.
    func perform(at place: ErrorPlace, _ command: (inout Logbook, Date) throws -> Void) {
        now = Date()
        do {
            try command(&logbook, now)
            error = nil
        } catch let failure as PomopomoError {
            error = PlacedError(place: place, message: failure.message, shownAt: now)
        } catch let failure {
            error = PlacedError(place: place, message: failure.localizedDescription, shownAt: now)
        }
        save()
    }

    /// The message to show at `place`, if the last command failed there.
    func errorMessage(at place: ErrorPlace) -> String? {
        error?.place == place ? error?.message : nil
    }

    /// Starts a Pomodoro, and the first time one starts asks whether notifications may tell you it's over.
    func startPomodoro(on taskID: PomopomoCore.Task.ID) {
        perform(at: .task(taskID)) { logbook, now in try logbook.startPomodoro(on: taskID, now: now) }
        guard error == nil else { return }
        // Only asks if you haven't decided yet.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    func remaining(of pomodoro: Pomodoro) -> TimeInterval {
        switch pomodoro.state {
        case .running(let endsAt): max(0, endsAt.timeIntervalSince(now))
        case .paused(let remaining): remaining
        case .completed, .voided: 0
        }
    }

    // MARK: Private

    private func observeSleepAndWake() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.willSleep() }
        }
        // Waking may land on a new date; the next tick would notice too, but don't wait for it.
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func save() {
        guard savesToStore else { return }
        do {
            try store.save(logbook)
            saveErrorMessage = nil
        } catch {
            saveErrorMessage = "Couldn't save: \(error.localizedDescription)"
        }
    }

    private func announce(_ event: Event) {
        let content = UNMutableNotificationContent()
        switch event {
        case .pomodoroCompleted(let task, let breakDue):
            content.title = "Pomodoro Completed"
            let breakMessage = switch breakDue {
            case .long: "Time for a Long Break."
            case .short: "Time for a Short Break."
            case nil: "A new Day has begun."
            }
            content.body = "\(task.name) · \(breakMessage)"
            if breakDue != nil {
                content.categoryIdentifier = NotificationHandler.Category.breakDue
            }
        case .breakEnded(let task):
            content.title = "Break Over"
            if case .start = logbook.options(for: task.id, now: now).start {
                content.body = "Start the next Pomodoro on \(task.name) when you're ready."
                content.categoryIdentifier = NotificationHandler.Category.breakOver
                content.userInfo = [NotificationHandler.taskIDKey: task.id.uuidString]
            } else if task.isDone {
                content.body = "\(task.name) is Done. Start the next Pomodoro on another Task when you're ready."
            } else {
                content.body = "Start the next Pomodoro when you're ready."
            }
        }
        post(content)
        if playsSound {
            NSSound(named: "Glass")?.play()
        }
    }

    private func post(_ content: UNNotificationContent) {
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    /// A button on a notification was pressed. If its action is no longer possible, a notification says why.
    func performNotificationAction(_ action: String, taskID: PomopomoCore.Task.ID?) {
        switch action {
        case NotificationHandler.Action.startBreak:
            perform(at: .breaks) { logbook, now in try logbook.startBreak(now: now) }
        case NotificationHandler.Action.startPomodoro:
            guard let taskID else { return }
            now = Date()
            switch logbook.options(for: taskID, now: now).start {
            case .start:
                startPomodoro(on: taskID)
            case .voidAndStart, .resume:
                // Starting would Void a Paused Pomodoro, which only the popover warns about, so leave that choice there.
                postCouldNotDo("A Pomodoro is Paused. Open Pomopomo to resume or Void it.")
                return
            case .refused(let reason):
                postCouldNotDo(reason.message)
                return
            }
        default:
            return
        }
        if let message = error?.message {
            postCouldNotDo(message)
        }
    }

    private func postCouldNotDo(_ reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Couldn't Do That"
        content.body = reason
        post(content)
    }

    /// Loads the stored Logbook. A file that can't be read is set aside rather than overwritten;
    /// if even that fails, nothing is saved this session.
    private func load() {
        do {
            logbook = try store.load()
        } catch let loadError {
            do {
                let setAside = try store.setAsideUnreadableFile()
                loadMessage = "Couldn't read your Logbook, so it was moved to \(setAside.lastPathComponent) and a new one started."
            } catch {
                savesToStore = false
                loadMessage = "Couldn't read your Logbook (\(loadError.localizedDescription)). Nothing will be saved, so it isn't overwritten."
            }
        }
    }
}

/// Offers the next step as buttons on notifications, and shows notifications while the popover is open.
@MainActor
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    enum Category {
        static let breakDue = "breakDue"
        static let breakOver = "breakOver"
    }

    enum Action {
        static let startBreak = "startBreak"
        static let startPomodoro = "startPomodoro"
    }

    nonisolated static let taskIDKey = "taskID"

    weak var model: AppModel?

    func register() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: Category.breakDue,
                actions: [UNNotificationAction(identifier: Action.startBreak, title: "Start Break")],
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: Category.breakOver,
                actions: [UNNotificationAction(identifier: Action.startPomodoro, title: "Start Next Pomodoro")],
                intentIdentifiers: []
            ),
        ])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let action = response.actionIdentifier
        let taskID = (response.notification.request.content.userInfo[Self.taskIDKey] as? String).flatMap(UUID.init)
        await MainActor.run {
            model?.performNotificationAction(action, taskID: taskID)
        }
    }
}

/// How the menu bar shows the time left. The method discourages watching the clock,
/// so it can show less than every second.
enum MenuBarDisplay: String, CaseIterable, Identifiable {
    case minutesAndSeconds, minutesOnly, iconOnly

    var id: Self { self }

    var title: String {
        switch self {
        case .minutesAndSeconds: "Minutes and seconds"
        case .minutesOnly: "Minutes only"
        case .iconOnly: "Icon only"
        }
    }
}

/// Where a command was given from, so its error can show next to that control.
enum ErrorPlace: Hashable {
    case pomodoro
    case breaks
    case task(PomopomoCore.Task.ID)
    case addTask
    case settings
}

struct PlacedError {
    let place: ErrorPlace
    let message: String
    let shownAt: Date
}

extension PomopomoError {
    var message: String {
        switch self {
        case .invalidEstimate: "An Estimate must be at least 1 Pomodoro."
        case .invalidName: "A Task needs a name."
        case .nameLocked: "A Task can't be renamed once a Pomodoro on it has started."
        case .noSuchTask: "That Task isn't on today's list."
        case .pomodoroAlreadyRunning: "A Pomodoro is already Running."
        case .noRunningPomodoro: "No Pomodoro is Running."
        case .noPausedPomodoro: "No Pomodoro is Paused."
        case .noUnfinishedPomodoro: "No Pomodoro is Running or Paused."
        case .estimateLocked: "The Estimate is locked once a Pomodoro on the Task has started."
        case .taskIsDone: "That Task is Done. Add a new Task for extra work."
        case .taskHasUnfinishedPomodoro: "A Task can't be marked Done while its Pomodoro is Running or Paused."
        case .taskHasPomodoros: "A Task can't be deleted once a Pomodoro on it has started."
        case .noBreakDue: "No Break is due."
        case .noRunningBreak: "No Break is running."
        case .invalidSettings: "Lengths and the Set size must be at least 1."
        case .dayIsPast: "A past Day can't be changed."
        }
    }
}
