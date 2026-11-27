// Taken from Search at commit c92ea7c: Grip and EdgeGrip (Design.swift), and its bookmark rows' folder arrow
// (Bookmarks.swift) as DisclosureArrow. Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md).
// Changed only where this repository's rules require: Search's colours and motion are read from Look. The edge's
// resizing cursor is AppKit's, and is Shell's to bring.
import SwiftUI

/// A dragged edge's pill: faint and short at rest, it grows a little and
/// darkens under the pointer and while it is held. What takes the pointer is
/// still the whole edge; only the drawing is small.
nonisolated package enum Grip {
    package static let width: CGFloat = 4
    /// Its length at rest, and under the pointer or held.
    package static let rest: CGFloat = 28
    package static let lit: CGFloat = 40
}

/// The pill itself (see Grip). `resting`: drawn, faint, before the pointer
/// comes; otherwise it is only there once the pointer is on the edge.
package struct EdgeGrip: View {
    let lit: Bool
    var resting = false
    @Environment(\.motion) private var motion

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

/// The arrow before a folder's row: pointing at it shut, down at it open.
package struct DisclosureArrow: View {
    let open: Bool

    package init(open: Bool) {
        self.open = open
    }

    package var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Role.faint)
            .rotationEffect(.degrees(open ? 90 : 0))
            .frame(width: 10)
    }
}
