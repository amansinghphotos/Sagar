// Small marks for moving things: the handle on an edge that can be dragged, a folder's arrow, and a list that fades
// at its foot while more of it lies below.
import SwiftUI

/// The handle's measures, in points.
nonisolated package enum Grip {
    /// How wide the handle is.
    package static let width: CGFloat = 4
    /// How long it is at rest.
    package static let rest: CGFloat = 28
    /// How long it grows under the pointer or while it is dragged.
    package static let lit: CGFloat = 40
}

/// The handle on an edge that can be dragged. Lit, it is long and darker; at rest it is short and faint, and it
/// shows at all only when `resting` asks for it. It is only drawn: clicks go through it, and VoiceOver passes it by.
package struct EdgeGrip: View {
    @Environment(\.motion) private var motion
    private let lit: Bool
    private let resting: Bool

    package init(lit: Bool, resting: Bool = false) {
        self.lit = lit
        self.resting = resting
    }

    package var body: some View {
        Capsule(style: .continuous)
            .fill(lit ? Role.muted : Role.faint)
            .frame(width: Grip.width, height: lit ? Grip.lit : Grip.rest)
            .opacity(lit || resting ? 1 : 0)
            .animation(motion.quick, value: lit)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A folder's arrow: pointing at the folder's name while it is shut, and down while it is open.
package struct DisclosureArrow: View {
    private let open: Bool

    package init(open: Bool) {
        self.open = open
    }

    package var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Role.faint)
            .rotationEffect(.degrees(open ? 90 : 0))
            .frame(width: 10, height: 10)
    }
}

/// A scroll whose foot fades while more lies below it, less as the end comes up, and not at all once the end is in
/// view. Its head does the same once scrolled, so a line going under the top edge is not cut across.
package struct FadingScroll<Content: View>: View {
    /// How far the fade reaches in from the foot or the head, in points.
    nonisolated private static var fade: CGFloat { 24 }
    /// The scroll's own place, where the content's end is measured.
    private static var space: String { "fading.list" }

    private let content: () -> Content
    /// How far the foot has come past the point a fade's height above the content's end. Until it is measured,
    /// the foot fades in full.
    @State private var over: CGFloat = 0
    /// The same at the head: how far the top lies short of a fade's height below the content's start. A fade's
    /// height until it is scrolled, so the head does not fade.
    @State private var top: CGFloat = Self.fade

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    /// How strongly the foot fades, from 1 while the end lies a fade's height or more below it to 0 once the end is
    /// in view. The head is measured the same way from the content's start.
    nonisolated static func strength(over: CGFloat) -> CGFloat {
        min(1, max(0, 1 - over / fade))
    }

    package var body: some View {
        GeometryReader { scroll in
            ScrollView {
                content()
                    .background {
                        GeometryReader { inner in
                            let place = inner.frame(in: .named(Self.space))
                            Color.clear
                                .onChange(of: place.maxY, initial: true) {
                                    over = scroll.size.height + Self.fade - place.maxY
                                }
                                .onChange(of: place.minY, initial: true) { top = Self.fade + place.minY }
                        }
                    }
            }
            .coordinateSpace(.named(Self.space))
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black.opacity(1 - Self.strength(over: top)), .black], startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Self.fade)
                    Rectangle()
                    LinearGradient(
                        colors: [.black, .black.opacity(1 - Self.strength(over: over))], startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Self.fade)
                }
            }
        }
    }
}
