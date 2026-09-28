import PomopomoCore
import SwiftUI

/// The four adjustable settings. Lengths apply from the next Pomodoro or Break;
/// the Set size applies to today's count straight away.
struct SettingsView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings").font(.subheadline.bold())
            minutesStepper("Pomodoro", \.pomodoroLength, in: 1...90)
            minutesStepper("Short Break", \.shortBreakLength, in: 1...30)
            minutesStepper("Long Break", \.longBreakLength, in: 1...60)
            Stepper("Set: \(model.logbook.settings.setSize) Pomodoros", value: binding(\.setSize), in: 1...12)
            Button("Restore Default Values") {
                model.perform { logbook, _ in try logbook.changeSettings(PomopomoCore.Settings()) }
            }
            .disabled(model.logbook.settings == PomopomoCore.Settings())
            Text("A Pomodoro or Break keeps the length it started with.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func minutesStepper(
        _ title: String,
        _ keyPath: WritableKeyPath<PomopomoCore.Settings, TimeInterval>,
        in range: ClosedRange<Int>
    ) -> some View {
        let minutes = Binding<Int>(
            get: { Int(model.logbook.settings[keyPath: keyPath] / 60) },
            set: { binding(keyPath).wrappedValue = TimeInterval($0) * 60 }
        )
        return Stepper("\(title): \(minutes.wrappedValue) min", value: minutes, in: range)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<PomopomoCore.Settings, Value>) -> Binding<Value> {
        Binding(
            get: { model.logbook.settings[keyPath: keyPath] },
            set: { newValue in
                var settings = model.logbook.settings
                settings[keyPath: keyPath] = newValue
                model.perform { logbook, _ in try logbook.changeSettings(settings) }
            }
        )
    }
}
