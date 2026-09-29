import PomopomoCore
import SwiftUI

/// What shows in the menu bar: the time left while something is timing, shown as the settings say,
/// otherwise just the icon.
struct MenuBarLabel: View {
    let model: AppModel

    /// Each state has its own icon, so they can be told apart even when the menu bar shows no time.
    var body: some View {
        if let pomodoro = model.activePomodoro {
            if pomodoro.isPaused {
                Image(systemName: "pause.circle").accessibilityLabel("Pomodoro Paused")
            } else {
                Image(systemName: "timer.circle.fill").accessibilityLabel("Pomodoro Running")
            }
            time(model.remaining(of: pomodoro))
        } else if let running = model.runningBreak {
            Image(systemName: "cup.and.saucer").accessibilityLabel("\(running.kind.title) running")
            time(max(0, running.endsAt.timeIntervalSince(model.now)))
        } else if let due = model.dueBreak {
            Image(systemName: "cup.and.heat.waves.fill").accessibilityLabel("\(due.title) due")
        } else {
            Image(systemName: "timer").accessibilityLabel("Pomopomo")
        }
    }

    @ViewBuilder
    private func time(_ remaining: TimeInterval) -> some View {
        switch model.menuBarDisplay {
        case .minutesAndSeconds: Text(remaining.countdown).monospacedDigit()
        case .minutesOnly: Text(remaining.minutesLeft).monospacedDigit()
        case .iconOnly: EmptyView()
        }
    }
}
