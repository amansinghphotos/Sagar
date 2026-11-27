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
/// shows at all only when `resting` asks for it.
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
/// view.
package struct FadingScroll<Content: View>: View {
    /// How far the fade reaches up from the foot, in points.
    nonisolated private static var fade: CGFloat { 24 }
    /// The scroll's own place, where the content's end is measured.
    private static var space: String { "fading.list" }

    private let content: () -> Content
    /// How far the foot has come past the point a fade's height above the content's end. Until it is measured,
    /// the foot fades in full.
    @State private var over: CGFloat = 0

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    /// How strongly the foot fades, from 1 while the end lies a fade's height or more below it to 0 once the end is
    /// in view.
    nonisolated static func strength(over: CGFloat) -> CGFloat {
        min(1, max(0, 1 - over / fade))
    }

    package var body: some View {
        GeometryReader { scroll in
            ScrollView {
                content()
                    .background {
                        GeometryReader { inner in
                            let end = inner.frame(in: .named(Self.space)).maxY
                            Color.clear.onChange(of: end, initial: true) {
                                over = scroll.size.height + Self.fade - end
                            }
                        }
                    }
            }
            .coordinateSpace(.named(Self.space))
            .mask {
                VStack(spacing: 0) {
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
