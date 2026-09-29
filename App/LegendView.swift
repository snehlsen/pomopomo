import PomopomoCore
import SwiftUI

/// The key to the task list: every Pomodoro state and Mark, and the rules that can't be undone.
struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            section("Pomodoros") {
                row(EmptyBox(), "Estimate box", "One per Pomodoro in the Estimate, filled as Pomodoros are Completed.")
                row(PomodoroStateSymbol(look: .completed), "Completed", "Its full length of work is done. Only Completed Pomodoros count.")
                row(PomodoroStateSymbol(look: .running), "Running", "The countdown is ticking.")
                row(PomodoroStateSymbol(look: .paused), "Paused", "Stopped, and can be resumed from where it stopped.")
                row(PomodoroStateSymbol(look: .pausedForGood), "Paused for good", "Still Paused when its Day ended. Counts toward nothing.")
                row(PomodoroStateSymbol(look: .voided), "Voided", "Abandoned before its full length was done. Counts toward nothing.")
                row(EstimateDivider(), "Beyond the Estimate", "Pomodoros after the divider went beyond the Task's Estimate.")
            }
            section("Marks") {
                row(MarkSymbol(mark: .pause), Mark.pause.title, "Paused at least once before it was Completed.")
                row(MarkSymbol(mark: .overrun), Mark.overrun.title, "Went beyond its Task's Estimate.")
                row(MarkSymbol(mark: .skippedBreak), Mark.skippedBreak.title, "Started when a Break was due and that Break was skipped or ended early.")
                Text("Marks are only information. They never change what counts.")
                    .foregroundStyle(.secondary)
            }
            section("Rules") {
                Text("• Starting a Pomodoro while another is Paused Voids the Paused one.")
                Text("• Done is final: no more Pomodoros can start on a Done Task.")
                Text("• A Task's Estimate and name lock when its first Pomodoro starts.")
            }
        }
        .font(.caption)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .frame(width: 320)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline.bold())
            content()
        }
    }

    private func row(_ symbol: some View, _ name: String, _ meaning: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            symbol
                .frame(width: 16)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).bold()
                Text(meaning).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
