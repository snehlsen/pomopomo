import PomopomoCore
import SwiftUI

/// What shows in the menu bar: the countdown while something is timing, otherwise just the icon.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        if let pomodoro = model.activePomodoro {
            Image(systemName: pomodoro.isPaused ? "pause.circle" : "timer")
            Text(model.remaining(of: pomodoro).countdown).monospacedDigit()
        } else if let running = model.runningBreak {
            Image(systemName: "cup.and.saucer")
            Text(max(0, running.endsAt.timeIntervalSince(model.now)).countdown).monospacedDigit()
        } else {
            Image(systemName: "timer")
        }
    }
}
