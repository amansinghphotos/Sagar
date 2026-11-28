// The faint fill that shows how far a page is read.
import SwiftUI

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
