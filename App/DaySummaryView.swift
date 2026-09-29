import PomopomoCore
import SwiftUI

/// A past Day at a glance, like "8 Completed · 1 Voided" and "⏸2 ＋1 · 4/5 Tasks Done".
struct DaySummaryView: View {
    let summary: DaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(counts)
            HStack(spacing: 8) {
                if givenMarks.isEmpty {
                    Text("No Marks")
                }
                ForEach(givenMarks, id: \.self) { mark in
                    let count = summary.marks[mark, default: 0]
                    HStack(spacing: 2) {
                        MarkSymbol(mark: mark)
                        Text("\(count)")
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(count) \(mark.title)\(count == 1 ? "" : "s")")
                }
                Text("·")
                Text("\(summary.tasksDone)/\(summary.tasks) Tasks Done")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var counts: String {
        var parts = ["\(summary.completed) Completed", "\(summary.voided) Voided"]
        if summary.pausedForGood > 0 {
            parts.append("\(summary.pausedForGood) Paused for good")
        }
        return parts.joined(separator: " · ")
    }

    private var givenMarks: [Mark] {
        Mark.allCases.filter { summary.marks[$0] != nil }
    }
}
