// The split view: a column of a fixed width beside the page, the page laid as a card on the window's frame.
import SwiftUI

/// A column beside a page. The column keeps its width; the page takes the rest of the window as a card.
package struct SideSplit<Side: View, Page: View>: View {
    private let side: () -> Side
    private let page: () -> Page

    package init(@ViewBuilder side: @escaping () -> Side, @ViewBuilder page: @escaping () -> Page) {
        self.side = side
        self.page = page
    }

    package var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Space.hair.rawValue) { side() }
                .padding(.horizontal, Space.gap.rawValue)
                .padding(.top, Space.near.rawValue)
                .frame(width: 232, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .top)
            page()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(CardEdge(on: true, insets: EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8)))
        }
        .background(Role.frame)
    }
}

/// Lays what it wraps as a card: the page's ground, a rounded edge and a faint shadow, inset from the frame.
/// Off, the content lies flat and fills its place. `scale` shrinks the card by that fraction of its size.
package struct CardEdge: ViewModifier {
    private let on: Bool
    private let insets: EdgeInsets
    private let corner: CGFloat
    private let scale: CGFloat

    /// How dark the card's shadow is.
    static let shadow: Double = 0.07
    /// How strong the card's edge is.
    static let edge: Double = 0.08

    package init(on: Bool, insets: EdgeInsets = EdgeInsets(), corner: CGFloat = 10, scale: CGFloat = 0) {
        self.on = on
        self.insets = insets
        self.corner = corner
        self.scale = scale
    }

    package func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: on ? corner : 0, style: .continuous)
        content
            .background(Role.ground)
            .clipShape(shape)
            .overlay { shape.strokeBorder(Role.ink.opacity(on ? Self.edge : 0), lineWidth: 1) }
            .shadow(color: .black.opacity(on ? Self.shadow : 0), radius: 6, y: 1)
            .scaleEffect(1 - scale)
            .padding(on ? insets : EdgeInsets())
    }
}
