// Taken from Search at commit c92ea7c: UnreadBadge and unreadBadge(_:icon:ring:) (UnreadBadge.swift), and ReadingFill
// (Tab.swift). Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this
// repository's rules require: the ring, the ink and Search's motion are read from Look, the access is this
// repository's, and the fill is given how far along it is rather than Search's Reading object.
import SwiftUI

/// The count, hung from the top right of a pin's icon as an app's hangs from
/// its icon in the Dock: centred on the icon's corner, wherever the icon sits
/// in its square. Hung from the square's corner instead, it floated off on
/// its own over a wide square, far from the icon it spoke for. Red, so a
/// glance along the pins finds it; ringed in the square's own grey, so it
/// stands clear of the icon it overlaps; drawn only, so a click on it is a
/// click on the pin.
///
/// Hung with `.unreadBadge(_:icon:ring:)` on the icon's frame.
package struct UnreadBadge: View {
    let count: String
    /// The icon it hangs from, which it is drawn to.
    var icon: CGFloat = 16
    /// The square's ground, for the ring; none, a soft shadow instead.
    var ring: Role? = nil

    package init(count: String, icon: CGFloat = 16, ring: Role? = nil) {
        self.count = count
        self.icon = icon
        self.ring = ring
    }

    package var body: some View {
        Text(count)
            .font(.system(size: max(7, icon * 0.45), weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, icon * 0.14)
            .frame(minWidth: icon * 0.7, minHeight: icon * 0.7)
            // Its own size, whatever it is offered: hung from a point, it
            // was offered none, and "97" spilled out of a one-digit circle.
            .fixedSize()
            .background(Capsule().fill(Color(red: 0.93, green: 0.24, blue: 0.21)))
            .background {
                if let ring { Capsule().fill(ring).padding(-1.5) }
            }
            .shadow(color: .black.opacity(ring == nil ? 0.2 : 0), radius: 1, y: 0.5)
            .allowsHitTesting(false)
            .accessibilityLabel(Text("\(count) unread"))
    }
}

extension View {
    /// `count`'s badge with its middle on this view's top right corner, a
    /// touch outside it: hung from a point there, not by alignment guides,
    /// which an overlay here ignored and so drew the badge over the middle
    /// of the icon, hiding it. Nil, none.
    package func unreadBadge(_ count: String?, icon: CGFloat, ring: Role?) -> some View {
        modifier(Hung(count: count, icon: icon, ring: ring))
    }
}

/// The badge hung, moving as Look's motion says.
private struct Hung: ViewModifier {
    let count: String?
    let icon: CGFloat
    let ring: Role?

    @Environment(\.motion) private var motion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if let count {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .overlay { UnreadBadge(count: count, icon: icon, ring: ring) }
                        .offset(x: icon * 0.15, y: -icon * 0.12)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(motion.quick, value: count)
    }
}

/// The fill itself: the grey that grows from the left of the tab you are on
/// as you read down its page, in a width it is given.
package struct ReadingFill: View {
    let value: Double
    let width: CGFloat

    @Environment(\.motion) private var motion

    package init(value: Double, width: CGFloat) {
        self.value = value
        self.width = width
    }

    package var body: some View {
        Rectangle()
            .fill(Role.ink.opacity(0.055))
            .frame(width: width * value)
            .animation(motion.timed(.easeOut(duration: 0.15)), value: value)
    }
}
