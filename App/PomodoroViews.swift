import PomopomoCore
import SwiftUI

/// A Task's Estimate as one slot per estimated Pomodoro, ticked off like Cirillo's paper sheet.
///
/// Pomodoros appear in the order they started. Completed ones fill the slots; Voided, Paused and
/// Running ones show between them without filling one. Pomodoros beyond the Estimate follow a divider.
struct PomodoroHistory: View {
    let pomodoros: [Pomodoro]
    let estimate: Int
    let isPast: Bool

    var body: some View {
        FlowLayout(spacing: 5) {
            ForEach(items) { item in
                switch item {
                case .pomodoro(let pomodoro):
                    PomodoroChip(pomodoro: pomodoro, isPast: isPast)
                case .emptySlot:
                    EmptySlot()
                case .divider:
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: 1, height: 12)
                        .help("Beyond the Estimate")
                }
            }
        }
    }

    private enum Item: Identifiable {
        case pomodoro(Pomodoro)
        case emptySlot(Int)
        case divider

        var id: String {
            switch self {
            case .pomodoro(let pomodoro): pomodoro.id.uuidString
            case .emptySlot(let index): "empty-\(index)"
            case .divider: "divider"
            }
        }
    }

    private var items: [Item] {
        // A Pomodoro gets its Overrun Mark when it starts beyond the Estimate, so the Mark splits the two groups.
        let within = pomodoros.filter { !$0.marks.contains(.overrun) }
        let beyond = pomodoros.filter { $0.marks.contains(.overrun) }
        let filled = within.filter(\.isCompleted).count
        var items = within.map(Item.pomodoro)
        items += (0..<max(0, estimate - filled)).map(Item.emptySlot)
        if !beyond.isEmpty {
            items.append(.divider)
            items += beyond.map(Item.pomodoro)
        }
        return items
    }
}

/// A slot of the Estimate that no Completed Pomodoro has filled yet.
struct EmptySlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .strokeBorder(.secondary, lineWidth: 1)
            .frame(width: 12, height: 12)
            .help("Not yet Completed")
    }
}

/// One Pomodoro with its Marks. A Completed one is a filled slot; the others are small symbols.
struct PomodoroChip: View {
    let pomodoro: Pomodoro
    /// On a past Day a Paused Pomodoro is Paused for good.
    let isPast: Bool

    var body: some View {
        HStack(spacing: 1) {
            if pomodoro.isCompleted {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.green)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
            } else {
                Image(systemName: stateSymbol)
                    .foregroundStyle(.secondary)
            }
            ForEach(Mark.allCases.filter(pomodoro.marks.contains), id: \.self) { mark in
                MarkSymbol(mark: mark)
            }
        }
        .font(.caption)
        .help(helpText)
    }

    private var stateSymbol: String {
        switch pomodoro.state {
        case .running: "circle.dotted"
        case .paused: isPast ? "pause.circle.fill" : "pause.circle"
        case .completed: "checkmark.circle.fill"
        case .voided: "xmark.circle"
        }
    }

    private var helpText: String {
        let state = switch pomodoro.state {
        case .running: "Running"
        case .paused: isPast ? "Paused for good" : "Paused"
        case .completed: "Completed"
        case .voided: "Voided"
        }
        let marks = Mark.allCases.filter(pomodoro.marks.contains).map(\.title)
        return ([state] + marks).joined(separator: " · ")
    }
}

/// Every kind of Mark has its own symbol and colour, so they can't be confused.
struct MarkSymbol: View {
    let mark: Mark

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(color)
            .help(mark.title)
    }

    private var symbol: String {
        switch mark {
        case .pause: "pause.fill"
        case .overrun: "plus.circle.fill"
        case .skippedBreak: "cup.and.saucer.fill"
        }
    }

    /// Marks are only information, so none is red: red is kept for destructive actions and errors.
    private var color: Color {
        switch mark {
        case .pause: .blue
        case .overrun: .orange
        case .skippedBreak: .purple
        }
    }
}

extension Mark {
    var title: String {
        switch self {
        case .pause: "Pause Mark"
        case .overrun: "Overrun Mark"
        case .skippedBreak: "Skipped-Break Mark"
        }
    }
}

extension Pomodoro {
    var isPaused: Bool {
        if case .paused = state { true } else { false }
    }
}
