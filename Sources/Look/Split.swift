// Taken from Search at commit c92ea7c: CardEdge and its CardShape (Design.swift), and the measures of its column
// beside the page as a card: the column 232 wide (Metrics.side) with 10 of padding, on the frame's grey with the
// greys for that ground, and the card 8 in from the window (Metrics.cardGap) with corners of 10
// (Metrics.cardRadius). Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where
// this repository's rules require: Search's colours are read from Look; and its column, a browser's own, gives
// way to whatever rows an app puts in it.
import SwiftUI

/// A sidebar beside a page, as Search lays its column beside the page as a card.
package struct SideSplit<Side: View, Page: View>: View {
    @ViewBuilder let side: () -> Side
    @ViewBuilder let page: () -> Page

    package init(@ViewBuilder side: @escaping () -> Side, @ViewBuilder page: @escaping () -> Page) {
        self.side = side
        self.page = page
    }

    package var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                side()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .environment(\.greys, Greys.frame)
            .frame(width: 232)
            page()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(CardEdge(on: true))
                .padding(.vertical, 8)
                .padding(.trailing, 8)
        }
        .background(Role.frame)
    }
}

/// The page as a card in the window, with the tabs down the side: round
/// corners, a hairline edge and a soft shadow under it.
package struct CardEdge: ViewModifier {
    let on: Bool
    /// Where the card lies in the view, for a card drawn over a page laid
    /// out larger than it: the clip, ground and edge follow these, animated,
    /// and the page doesn't.
    var insets = EdgeInsets()
    var corner: CGFloat = 10
    /// The screen's scale, for the window's page: its edges on whole
    /// pixels, a hairline one pixel wide and no soft shadow around it, so
    /// the white of the page meets the window's grey on a sharp line. Zero
    /// keeps the soft card other cards are (the side panel, downloads).
    var scale: CGFloat = 0

    package init(on: Bool, insets: EdgeInsets = EdgeInsets(), corner: CGFloat = 10, scale: CGFloat = 0) {
        self.on = on
        self.insets = insets
        self.corner = corner
        self.scale = scale
    }

    // One shape of view, on or off. Off, the clip reaches far past the page
    // and cuts nothing, and the edge and shadow are clear.
    package func body(content: Content) -> some View {
        let shape = CardShape(on: on, insets: insets, corner: corner, scale: scale)
        let crisp = scale > 0
        content
            .clipShape(shape)
            .background {
                if crisp {
                    shape.fill(on ? AnyShapeStyle(Role.ground) : AnyShapeStyle(.clear))
                } else {
                    shape
                        .fill(on ? AnyShapeStyle(Role.ground) : AnyShapeStyle(.clear))
                        .shadow(color: .black.opacity(on ? CardEdge.shadow : 0), radius: 6, y: 1)
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        Color.primary.opacity(on && corner > 0 ? CardEdge.edge : 0),
                        lineWidth: crisp ? 1 / scale : 1
                    )
                    .allowsHitTesting(false)
            }
    }

    /// How dark the shadow and the edge are, for the stage's own cards too.
    static let shadow: Double = 0.07
    static let edge: Double = 0.08
}

/// The card's outline: round at its corners, or, off, a rectangle reaching
/// far past the page on every side.
nonisolated private struct CardShape: InsettableShape {
    let on: Bool
    var insets = EdgeInsets()
    var corner: CGFloat = 10
    var scale: CGFloat = 0
    var inset: CGFloat = 0

    var animatableData:
        AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat>>
    {
        get { .init(.init(insets.top, insets.leading), .init(.init(insets.bottom, insets.trailing), corner)) }
        set {
            insets = EdgeInsets(
                top: newValue.first.first, leading: newValue.first.second,
                bottom: newValue.second.first.first, trailing: newValue.second.first.second)
            corner = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard on else { return Path(rect.insetBy(dx: -10_000, dy: -10_000)) }
        func pixel(_ x: CGFloat) -> CGFloat { scale > 0 ? (x * scale).rounded() / scale : x }
        let card = CGRect(
            x: pixel(rect.minX + insets.leading), y: pixel(rect.minY + insets.top),
            width: pixel(rect.width - insets.leading - insets.trailing),
            height: pixel(rect.height - insets.top - insets.bottom))
        return RoundedRectangle(cornerRadius: max(0, corner), style: .continuous)
            .path(in: card.insetBy(dx: inset, dy: inset))
    }

    func inset(by amount: CGFloat) -> CardShape {
        var shape = self
        shape.inset += amount
        return shape
    }
}
