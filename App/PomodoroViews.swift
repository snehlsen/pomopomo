import PomopomoCore
import SwiftUI

/// A Task's Pomodoros in the order they started, each with its state and Marks.
struct PomodoroHistory: View {
    let pomodoros: [Pomodoro]

    var body: some View {
        if !pomodoros.isEmpty {
            HStack(spacing: 6) {
                ForEach(pomodoros) { pomodoro in
                    PomodoroChip(pomodoro: pomodoro)
                }
            }
        }
    }
}

struct PomodoroChip: View {
    let pomodoro: Pomodoro

    var body: some View {
        HStack(spacing: 1) {
            Image(systemName: stateSymbol)
                .foregroundStyle(stateColor)
            ForEach(Mark.allCases.filter(pomodoro.marks.contains), id: \.self) { mark in
                MarkBadge(mark: mark)
            }
        }
        .font(.caption)
        .help(helpText)
    }

    private var stateSymbol: String {
        switch pomodoro.state {
        case .running: "circle.dotted"
        case .paused: "pause.circle"
        case .completed: "checkmark.circle.fill"
        case .voided: "xmark.circle"
        }
    }

    private var stateColor: Color {
        switch pomodoro.state {
        case .running, .paused: .secondary
        case .completed: .green
        case .voided: .secondary
        }
    }

    private var helpText: String {
        let state = switch pomodoro.state {
        case .running: "Running"
        case .paused: "Paused"
        case .completed: "Completed"
        case .voided: "Voided"
        }
        let marks = Mark.allCases.filter(pomodoro.marks.contains).map(\.title)
        return ([state] + marks).joined(separator: " · ")
    }
}

/// Every kind of Mark has its own symbol and colour, so they can't be confused.
struct MarkBadge: View {
    let mark: Mark

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(color)
            .help(mark.title)
    }

    private var symbol: String {
        switch mark {
        case .pause: "pause.fill"
        }
    }

    private var color: Color {
        switch mark {
        case .pause: .orange
        }
    }
}

extension Mark {
    var title: String {
        switch self {
        case .pause: "Pause Mark"
        }
    }
}

extension Pomodoro {
    var isPaused: Bool {
        if case .paused = state { true } else { false }
    }
}
