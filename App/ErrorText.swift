import SwiftUI

/// The error from a command given at `place`, shown right next to it.
struct ErrorText: View {
    let model: AppModel
    let place: ErrorPlace

    var body: some View {
        if let message = model.errorMessage(at: place) {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
        }
    }
}
