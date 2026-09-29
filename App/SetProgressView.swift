import PomopomoCore
import SwiftUI

/// How far through the current Set you are, like `●●○○  Set 2 · 6 Completed today`.
struct SetProgressView: View {
    let progress: SetProgress

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<progress.size, id: \.self) { index in
                    if index < progress.completed {
                        Circle().fill(.green)
                    } else {
                        Circle().strokeBorder(.secondary, lineWidth: 1)
                    }
                }
                .frame(width: 7, height: 7)
            }
            Text("Set \(progress.number) · \(progress.completedToday) Completed today")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Set \(progress.number): \(progress.completed) of \(progress.size) Completed. \(progress.completedToday) Completed today."
        )
    }
}
