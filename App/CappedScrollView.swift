import SwiftUI

/// Scrolls its content once it grows taller than `maxHeight`, and is no taller than the content otherwise.
struct CappedScrollView<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = 0

    /// Room for the active row's highlight, which is drawn just outside the row.
    private let inset: CGFloat = 6

    var body: some View {
        ScrollView {
            content
                .padding(inset)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(contentHeight, maxHeight))
        .padding(-inset)
    }
}
