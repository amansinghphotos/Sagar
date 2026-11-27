// Taken from Search at commit c92ea7c: Grip and EdgeGrip (Design.swift), and its bookmark rows' folder arrow
// (Bookmarks.swift) as DisclosureArrow, and FadingScroll (Recall.swift). Copyright (c) 2026 Office Commun, MIT
// licence (ACKNOWLEDGEMENTS.md).
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

/// A list's scroll, fading out at its foot while more lies below rather than
/// cutting a line in half; less as the end comes up, and not at all once it is
/// in view. Its head does the same once scrolled, so a caption going under the
/// title line isn't sliced across. A mask, so it is the same in light and dark
/// and over whatever the list is drawn on. Taken from Search's FadingScroll
/// (Recall.swift), its fade worked out in one function a test reads.
package struct FadingScroll<Content: View>: View {
    @ViewBuilder let content: () -> Content
    /// Where the list ends, and how tall the scroll is: the end lies
    /// below the foot by the difference.
    @State private var end: CGFloat = 0
    /// Where the list starts: above the scroll's top by as much as it
    /// has been scrolled.
    @State private var start: CGFloat = 0
    @State private var height: CGFloat = 0
    private static var fade: CGFloat { 24 }
    private static var space: String { "fading.list" }

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    /// How much of an edge shows, with `over` points of the list beyond it.
    nonisolated static func strength(over: CGFloat) -> CGFloat {
        1 - min(1, max(0, over) / 24)
    }

    package var body: some View {
        ScrollView {
            content()
                // Read where it is rather than sent up as a preference:
                // one from inside the scroll never came out of it here.
                .background(
                    GeometryReader { list in
                        let frame = list.frame(in: .named(Self.space))
                        Color.clear
                            .onAppear {
                                end = frame.maxY
                                start = frame.minY
                            }
                            .onChange(of: frame.maxY) { _, new in end = new }
                            .onChange(of: frame.minY) { _, new in start = new }
                    })
        }
        .coordinateSpace(name: Self.space)
        // Measured beside the scroll, not around it, so it sizes itself
        // as it always has.
        .background(
            GeometryReader { view in
                Color.clear
                    .onAppear { height = view.size.height }
                    .onChange(of: view.size.height) { _, new in height = new }
            }
        )
        .mask {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(Self.strength(over: -start)), .black],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: Self.fade)
                Rectangle()
                LinearGradient(
                    colors: [.black, .black.opacity(Self.strength(over: end - height))],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: Self.fade)
            }
        }
    }
}
