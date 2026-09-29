import PomopomoCore
import SwiftUI

/// A Task's Estimate as one box per estimated Pomodoro, ticked off like Cirillo's paper sheet.
///
/// Pomodoros appear in the order they started. Completed ones fill the boxes; Voided, Paused and
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
                case .emptyBox:
                    EmptyBox()
                case .divider:
                    EstimateDivider()
                }
            }
        }
    }

    private enum Item: Identifiable {
        case pomodoro(Pomodoro)
        case emptyBox(Int)
        case divider

        var id: String {
            switch self {
            case .pomodoro(let pomodoro): pomodoro.id.uuidString
            case .emptyBox(let index): "empty-\(index)"
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
        items += (0..<max(0, estimate - filled)).map(Item.emptyBox)
        if !beyond.isEmpty {
            items.append(.divider)
            items += beyond.map(Item.pomodoro)
        }
        return items
    }
}

/// Separates the Pomodoros within the Estimate from those beyond it.
struct EstimateDivider: View {
    var body: some View {
        Rectangle()
            .fill(.secondary)
            .frame(width: 1, height: 12)
            .help("Beyond the Estimate")
            .accessibilityLabel("Beyond the Estimate")
    }
}

/// A box of the Estimate that no Completed Pomodoro has filled yet.
struct EmptyBox: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .strokeBorder(.secondary, lineWidth: 1)
            .frame(width: 12, height: 12)
            .help("Not yet Completed")
            .accessibilityLabel("Empty box, not yet Completed")
    }
}

/// One Pomodoro with its Marks. A Completed one is a filled box; the others are small symbols.
struct PomodoroChip: View {
    let pomodoro: Pomodoro
    /// On a past Day a Paused Pomodoro is Paused for good.
    let isPast: Bool

    var body: some View {
        HStack(spacing: 1) {
            PomodoroStateSymbol(look: look)
            ForEach(Mark.allCases.filter(pomodoro.marks.contains), id: \.self) { mark in
                MarkSymbol(mark: mark)
            }
        }
        .font(.caption)
        .help(description.joined(separator: " · "))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(description.joined(separator: ", "))
    }

    private var look: PomodoroLook {
        switch pomodoro.state {
        case .running: .running
        case .paused: isPast ? .pausedForGood : .paused
        case .completed: .completed
        case .voided: .voided
        }
    }

    /// Its state and Marks in the words of the glossary, like ["Completed", "Pause Mark"].
    private var description: [String] {
        [look.title] + Mark.allCases.filter(pomodoro.marks.contains).map(\.title)
    }
}

/// How a Pomodoro's state is shown, in the task list and in the key alike.
enum PomodoroLook: CaseIterable {
    case completed, running, paused, pausedForGood, voided

    var title: String {
        switch self {
        case .completed: "Completed"
        case .running: "Running"
        case .paused: "Paused"
        case .pausedForGood: "Paused for good"
        case .voided: "Voided"
        }
    }
}

struct PomodoroStateSymbol: View {
    let look: PomodoroLook

    var body: some View {
        switch look {
        case .completed:
            RoundedRectangle(cornerRadius: 3)
                .fill(.green)
                .frame(width: 12, height: 12)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .running: symbol("circle.dotted")
        case .paused: symbol("pause.circle")
        case .pausedForGood: symbol("pause.circle.fill")
        case .voided: symbol("xmark.circle")
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name).foregroundStyle(.secondary)
    }
}

/// Every kind of Mark has its own symbol and colour, so they can't be confused.
struct MarkSymbol: View {
    let mark: Mark

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(color)
            .help(mark.title)
            .accessibilityLabel(mark.title)
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
