import Foundation

extension TimeInterval {
    /// Minutes and seconds, like 24:59. Rounds up so a countdown never shows 00:00 early.
    var countdown: String {
        let seconds = Int(self.rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    /// Whole minutes left, like "25 min". Rounds up like `countdown`, so it never shows 0 while time is left.
    var minutesLeft: String {
        let seconds = Int(self.rounded(.up))
        return "\((seconds + 59) / 60) min"
    }

    /// The same time for VoiceOver, like "24 minutes, 59 seconds".
    var spokenCountdown: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: rounded(.up)) ?? countdown
    }
}
