// The split view: a column of a fixed width beside the page, the page laid as a card on the window's frame.
import SwiftUI

/// A column beside a page. The column keeps its width; the page takes the rest of the window as a card.
package struct SideSplit<Side: View, Page: View>: View {
    private let side: () -> Side
    private let page: () -> Page

    package init(@ViewBuilder side: @escaping () -> Side, @ViewBuilder page: @escaping () -> Page) {
        (self.side, self.page) = (side, page)
    }

    package var body: some View {
        HStack(spacing: .zero) {
            column
            pageCard
        }
        .background(Role.frame)
    }

    /// The column's rows from the top, on the window's frame, so they take the greys made for that ground.
    private var column: some View {
        VStack(alignment: .leading, spacing: Space.hair.rawValue) { side() }
            .environment(\.greys, Greys.frame)
            .padding(.horizontal, Space.gap.rawValue)
            .padding(.vertical, Space.near.rawValue)
            .frame(minWidth: 232, maxWidth: 232, maxHeight: .infinity, alignment: .topLeading)
    }

    /// The page as a card, held off the window's edges on all sides but the column's.
    private var pageCard: some View {
        let gap = Space.near.rawValue
        return page()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(CardEdge(on: true))
            .padding(EdgeInsets(top: gap, leading: 0, bottom: gap, trailing: gap))
    }
}

/// Lays what it wraps as a card: the page's ground, a rounded edge and a faint shadow. Off, the content lies
/// flat with nothing drawn around it, and the clip reaches far past it.
package struct CardEdge: ViewModifier {
    /// The outline the card is clipped to, filled and edged along.
    private let outline: CardOutline

    /// The insets say where the card lies inside the view, for a card smaller than the page laid out under it: the
    /// clip, the ground and the edge follow them, and animate when they change; the content keeps its layout. The
    /// scale is the screen's, for a card that must meet the frame on a sharp line: its sides on whole pixels, an
    /// edge one pixel wide and no shadow. Zero keeps the soft card.
    package init(on: Bool, insets: EdgeInsets = EdgeInsets(), corner: CGFloat = 10, scale: CGFloat = 0) {
        outline = CardOutline(on: on, insets: insets, corner: corner, scale: scale)
    }

    package func body(content: Content) -> some View {
        let sharp = outline.scale > 0
        let edged = outline.on && outline.corner > 0
        content
            .clipShape(outline)
            .background {
                let ground = outline.fill(outline.on ? AnyShapeStyle(Role.ground) : AnyShapeStyle(Color.clear))
                if sharp {
                    ground
                } else {
                    ground.shadow(color: .black.opacity(outline.on ? Self.shadow : 0), radius: 6, y: 1)
                }
            }
            .overlay {
                outline
                    .strokeBorder(
                        Color.primary.opacity(edged ? Self.edge : 0), lineWidth: sharp ? 1 / outline.scale : 1
                    )
                    .allowsHitTesting(false)
            }
    }

    /// How dark the card's shadow is.
    static let shadow = 0.07
    /// How strong the card's edge is.
    static let edge = 0.08
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
        if !on {
            let far: CGFloat = 10_000
            return Path(
                CGRect(
                    x: rect.minX - far, y: rect.minY - far, width: rect.width + 2 * far, height: rect.height + 2 * far))
        }
        let origin = CGPoint(x: snapped(rect.minX + insets.leading), y: snapped(rect.minY + insets.top))
        let size = CGSize(
            width: snapped(rect.width - insets.leading - insets.trailing),
            height: snapped(rect.height - insets.top - insets.bottom))
        let card = CGRect(origin: origin, size: size).insetBy(dx: inward, dy: inward)
        return Path(roundedRect: card, cornerRadius: max(0, corner), style: .continuous)
    }

    /// A length laid on the screen's whole pixels, when the card is sharp; as it is, when not.
    private func snapped(_ length: CGFloat) -> CGFloat {
        guard scale > 0 else { return length }
        let pixels = (length * scale).rounded(.toNearestOrAwayFromZero)
        return pixels / scale
    }

    func inset(by amount: CGFloat) -> CardOutline {
        var outline = self
        outline.inward += amount
        return outline
    }
}
