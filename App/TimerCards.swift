import PomopomoCore
import SwiftUI

/// The layout shared by the Pomodoro and Break cards: what is timing, the countdown,
/// a bar showing progress through its length, and the controls.
struct TimerCard<Controls: View>: View {
    let title: String
    let remaining: TimeInterval
    let length: TimeInterval
    let tint: Color
    var isPaused = false
    @ViewBuilder let controls: Controls

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text(remaining.countdown)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isPaused ? AnyShapeStyle(.secondary) : AnyShapeStyle(tint))
                .accessibilityLabel("\(remaining.spokenCountdown) left\(isPaused ? ", Paused" : "")")
            ProgressBar(fraction: progress, fill: isPaused ? AnyShapeStyle(.secondary) : AnyShapeStyle(tint))
                .accessibilityElement()
                .accessibilityLabel(isPaused ? "Progress, Paused" : "Progress")
                .accessibilityValue("\(Int(progress * 100)) percent")
            controls
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private var progress: Double {
        guard length > 0 else { return 0 }
        return min(1, max(0, (length - remaining) / length))
    }
}

/// A thin bar filled to `fraction`, drawn by hand so it keeps its colour when the window isn't key.
struct ProgressBar: View {
    let fraction: Double
    let fill: AnyShapeStyle

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(fill).frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: 4)
    }
}

struct ActivePomodoroView: View {
    let model: AppModel
    let pomodoro: Pomodoro
    /// Voiding can't be undone, so it takes a second, deliberate click.
    @State private var confirmingVoid = false

    var body: some View {
        TimerCard(
            title: model.today.task(pomodoro.taskID)?.name ?? "",
            remaining: model.remaining(of: pomodoro),
            length: pomodoro.length,
            tint: .accentColor,
            isPaused: pomodoro.isPaused
        ) {
            if confirmingVoid {
                voidConfirmation
            } else {
                HStack {
                    if pomodoro.isPaused {
                        Button("Resume") {
                            model.perform(at: .pomodoro) { logbook, now in try logbook.resumePomodoro(now: now) }
                        }
                        .keyboardShortcut(.defaultAction)
                        .help("Resume (Space or Return)")
                    } else {
                        Button("Pause") {
                            model.perform(at: .pomodoro) { logbook, now in try logbook.pausePomodoro(now: now) }
                        }
                        .help("Pause (Space)")
                    }
                    Spacer().frame(width: 16)
                    Button("Void…") { confirmingVoid = true }
                        .help("Abandon this Pomodoro. It stays in the history but counts toward nothing.")
                }
            }
            ErrorText(model: model, place: .pomodoro)
        }
        .onChange(of: pomodoro.id) { confirmingVoid = false }
    }

    private var voidConfirmation: some View {
        VStack(spacing: 4) {
            Text("Void this Pomodoro? Its work won't count, and this can't be undone.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Keep It") { confirmingVoid = false }
                    .keyboardShortcut(.cancelAction)
                Button("Void", role: .destructive) {
                    model.perform(at: .pomodoro) { logbook, now in try logbook.voidPomodoro(now: now) }
                    confirmingVoid = false
                }
            }
        }
    }
}

struct BreakView: View {
    let model: AppModel

    var body: some View {
        if let running = model.runningBreak {
            TimerCard(
                title: running.kind.title,
                remaining: max(0, running.endsAt.timeIntervalSince(model.now)),
                length: running.length,
                tint: .teal
            ) {
                Button("End Break Early") {
                    model.perform(at: .breaks) { logbook, now in try logbook.endBreak(now: now) }
                }
                Text("Ending it early or starting a Pomodoro now gives that Pomodoro a Skipped-Break Mark.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ErrorText(model: model, place: .breaks)
            }
        } else if let due = model.dueBreak {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "cup.and.saucer").foregroundStyle(.teal)
                    Text("\(due.title) due")
                    Spacer()
                    Button("Start \(due.title)") {
                        model.perform(at: .breaks) { logbook, now in try logbook.startBreak(now: now) }
                    }
                    .keyboardShortcut(.defaultAction)
                }
                Text("Starting a Pomodoro instead skips it and gives that Pomodoro a Skipped-Break Mark.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ErrorText(model: model, place: .breaks)
            }
        }
    }
}

extension Break.Kind {
    var title: String {
        switch self {
        case .short: "Short Break"
        case .long: "Long Break"
        }
    }
}
