import PomopomoCore
import SwiftUI

/// What shows in the menu bar: the time left while something is timing, shown as the settings say,
/// otherwise just the icon.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        if let pomodoro = model.activePomodoro {
            Image(systemName: pomodoro.isPaused ? "pause.circle" : "timer")
            time(model.remaining(of: pomodoro))
        } else if let running = model.runningBreak {
            Image(systemName: "cup.and.saucer")
            time(max(0, running.endsAt.timeIntervalSince(model.now)))
        } else {
            Image(systemName: "timer")
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
