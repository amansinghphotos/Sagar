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
                // The column lies on the window's frame, so its rows take the greys made for that ground.
                .environment(\.greys, Greys.frame)
            page()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(CardEdge(on: true))
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
        }
        .background(Role.frame)
    }
}

/// Lays what it wraps as a card: the page's ground, a rounded edge and a faint shadow. Off, the content lies
/// flat with nothing drawn around it, and the clip reaches far past it.
package struct CardEdge: ViewModifier {
    private let on: Bool
    /// Where the card lies inside the view, for a card smaller than the page laid out under it: the clip, the
    /// ground and the edge follow these, and animate when they change; the content keeps its own layout.
    private let insets: EdgeInsets
    private let corner: CGFloat
    /// The screen's scale, for a card that must meet the frame on a sharp line: its sides on whole pixels, an
    /// edge one pixel wide and no shadow. Zero keeps the soft card.
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
        let outline = CardOutline(on: on, insets: insets, corner: corner, scale: scale)
        let sharp = scale > 0
        content
            .clipShape(outline)
            .background {
                outline
                    .fill(on ? AnyShapeStyle(Role.ground) : AnyShapeStyle(Color.clear))
                    .shadow(color: .black.opacity(on && !sharp ? Self.shadow : 0), radius: 6, y: 1)
            }
            .overlay {
                outline
                    .strokeBorder(Role.ink.opacity(on && corner > 0 ? Self.edge : 0), lineWidth: sharp ? 1 / scale : 1)
                    .allowsHitTesting(false)
            }
    }
}

/// The card's outline within the view. Off, a rectangle far larger than the view, so clipping to it cuts nothing.
nonisolated private struct CardOutline: InsettableShape {
    let on: Bool
    var insets: EdgeInsets
    var corner: CGFloat
    let scale: CGFloat
    var inward: CGFloat = 0

    var animatableData: AnimatablePair<EdgeInsets.AnimatableData, CGFloat> {
        get { AnimatablePair(insets.animatableData, corner) }
        set {
            insets.animatableData = newValue.first
            corner = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard on else { return Path(rect.insetBy(dx: -10_000, dy: -10_000)) }
        func whole(_ x: CGFloat) -> CGFloat { scale > 0 ? (x * scale).rounded() / scale : x }
        let left = whole(rect.minX + insets.leading)
        let top = whole(rect.minY + insets.top)
        let right = whole(rect.maxX - insets.trailing)
        let bottom = whole(rect.maxY - insets.bottom)
        let card = CGRect(x: left, y: top, width: right - left, height: bottom - top).insetBy(dx: inward, dy: inward)
        return Path(roundedRect: card, cornerRadius: max(0, corner), style: .continuous)
    }

    func inset(by amount: CGFloat) -> CardOutline {
        var outline = self
        outline.inward += amount
        return outline
    }
}
