import AppKit
import SwiftUI

/// Sees the keys pressed in its own window before the window handles them.
/// `handler` returns whether it used the key; a used key goes no further.
struct KeyMonitor: NSViewRepresentable {
    let handler: @MainActor (NSEvent) -> Bool

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.handler = handler
        return view
    }

    func updateNSView(_ view: MonitorView, context: Context) {
        view.handler = handler
    }

    final class MonitorView: NSView {
        var handler: (@MainActor (NSEvent) -> Bool)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let used = MainActor.assumeIsolated {
                    guard let self, event.window === self.window, let handler = self.handler else { return false }
                    return handler(event)
                }
                return used ? nil : event
            }
        }
    }
}
