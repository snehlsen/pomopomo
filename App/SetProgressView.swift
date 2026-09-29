import PomopomoCore
import SwiftUI

/// How far through the current Set you are, like `●●○○  Set 2 · 6 Completed today`.
struct SetProgressView: View {
    let progress: SetProgress

    var body: some View {
        HStack(spacing: 6) {
            SetCircles(completed: progress.completed, size: progress.size)
            Text("Set \(progress.number) · \(progress.completedToday) Completed today")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .help(explanation)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(explanation) \(progress.completedToday) Completed today.")
    }

    private var explanation: String {
        let count = "Set \(progress.number): \(progress.completed) of \(progress.size) Pomodoros Completed."
        return progress.completed == progress.size
            ? "\(count) The Set is full, so a Long Break is due."
            : "\(count) A Long Break is due once all \(progress.size) are Completed."
    }
}

/// One circle per Pomodoro in a Set, filled as Pomodoros are Completed. Shared with the key.
struct SetCircles: View {
    let completed: Int
    let size: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<size, id: \.self) { index in
                if index < completed {
                    Circle().fill(.green)
                } else {
                    Circle().strokeBorder(.secondary, lineWidth: 1)
                }
            }
            .frame(width: 7, height: 7)
        }
    }
}
