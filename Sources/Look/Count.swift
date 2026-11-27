// A count of unread things hung on an icon's corner, and the faint fill that shows how far a page is read.
import SwiftUI

/// The red of a count that wants attention, the same in the light look and the dark.
private let countRed = Color(.sRGB, red: 0.93, green: 0.24, blue: 0.21)

/// A count in white on a red pill. With a ring, the pill is cut out of what lies behind it by a band of
/// `ring`; without, it lifts off on a small shadow.
package struct UnreadBadge: View {
    private let count: String
    private let icon: CGFloat
    private let ring: Role?

    package init(count: String, icon: CGFloat = 16, ring: Role? = nil) {
        self.count = count
        self.icon = icon
        self.ring = ring
    }

    package var body: some View {
        // Measured for a 16-point icon and grown or shrunk with it. The pill stands 11.2 tall and is never
        // narrower, so a single figure makes a round dot. The figures get a little more room after than
        // before, which sets them in the middle to the eye. The figures are never under 7 points, and the ring and
        // the shadow keep their size whatever the icon's.
        let scale = icon / 16
        let height = 11.2 * scale
        let pill = Text(count)
            .font(.system(size: max(7, 7.2 * scale), weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.leading, 2 * scale)
            .padding(.trailing, 2.5 * scale)
            .frame(minWidth: height)
            .frame(height: height)
            .fixedSize()
            .background(countRed, in: Capsule())
        if let ring {
            pill.padding(1.5).background(ring, in: Capsule())
        } else {
            pill.shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
        }
    }
}

extension View {
    /// Hangs `count` from the top trailing corner of an icon `icon` points square, or nothing when there is no
    /// count. A count comes and goes by growing from a little smaller as it fades in.
    package func unreadBadge(_ count: String?, icon: CGFloat, ring: Role?) -> some View {
        modifier(Hanging(count: count, icon: icon, ring: ring))
    }
}

/// Lays the count's middle a little out past the icon's top trailing corner: beyond its trailing edge by 0.15
/// of the icon's side and above its top by 0.12. Drawn only: a click on it is a click on what it hangs from.
private struct Hanging: ViewModifier {
    let count: String?
    let icon: CGFloat
    let ring: Role?
    @Environment(\.motion) private var motion

    func body(content: Content) -> some View {
        content.overlay {
            ZStack {
                if let count {
                    UnreadBadge(count: count, icon: icon, ring: ring)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .offset(x: icon * (0.5 + 0.15), y: -icon * (0.5 + 0.12))
            .animation(motion.quick, value: count)
            .allowsHitTesting(false)
        }
    }
}

/// How far down a page has been read: a faint fill from the leading edge, `value` of `width` across.
package struct ReadingFill: View {
    @Environment(\.motion) private var motion
    private let value: Double
    private let width: CGFloat

    package init(value: Double, width: CGFloat) {
        self.value = value
        self.width = width
    }

    package var body: some View {
        Rectangle()
            .fill(Shade(light: 0.055, dark: 0.055))
            .frame(width: width * min(max(value, 0), 1))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .animation(motion.timed(.easeOut(duration: 0.15)), value: value)
    }
}
