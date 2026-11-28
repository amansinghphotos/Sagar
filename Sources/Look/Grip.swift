// Small marks for moving things: the handle on an edge that can be dragged, and a folder's arrow.
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
        Capsule()
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
