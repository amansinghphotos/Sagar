// Buttons: the pill with words, the small one beside a row, the square one with an icon, and the give of a press.
import SwiftUI

/// A capsule with words: drawn round in a thin line, or filled solid with `filled`.
package struct Pill: View {
    @Environment(\.motion) private var motion
    @State private var hovering = false
    private let title: String
    private let filled: Bool
    private let tint: Role
    private let action: () -> Void

    package init(_ title: String, filled: Bool = false, tint: Role = .ink, action: @escaping () -> Void) {
        self.title = title
        self.filled = filled
        self.tint = tint
        self.action = action
    }

    package var body: some View {
        Button(action: action) {
            Text(title)
                .type(.detail)
                .foregroundStyle(filled ? Role.ground : tint)
                .padding(.horizontal, Space.gap.rawValue)
                .frame(height: Self.height)
                .background {
                    if filled {
                        Capsule().fill(Role.ink)
                    } else {
                        Capsule().fill(hovering ? Role.hover : Role.ground)
                        Capsule().strokeBorder(Role.hairline, lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
    }

    /// How tall a pill stands, in points.
    static let height: CGFloat = 24
}

/// A small filled capsule for a quick thing to do beside a row, such as showing a file.
package struct Quick: View {
    private let title: String
    private let tint: Role
    private let act: () -> Void

    package init(_ title: String, tint: Role = .ink, act: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.act = act
    }

    package var body: some View {
        Button(action: act) {
            Text(title)
                .type(.detail)
                .foregroundStyle(tint)
                // Kept whole on one line, however narrow the row it sits in.
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, Space.near.rawValue)
                .frame(height: Self.height)
                .background(Capsule().fill(Role.wash))
        }
        .buttonStyle(.plain)
    }

    /// A little lower than a pill, so it sits quietly inside a row.
    static let height: CGFloat = 22
}

/// A square button with one icon, washed in grey while what it opens is open.
package struct Door: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    @State private var hovering = false
    private let icon: String
    private let on: Bool
    private let help: String
    private let nudge: CGFloat
    private let act: () -> Void

    package init(icon: String, on: Bool = false, help: String = "", nudge: CGFloat = 0, act: @escaping () -> Void) {
        self.icon = icon
        self.on = on
        self.help = help
        self.nudge = nudge
        self.act = act
    }

    package var body: some View {
        Button(action: act) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ink)
                .offset(x: nudge)
                .frame(width: Self.side, height: Self.side)
                .background {
                    let square = RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                    if on {
                        square.fill(greys.wash)
                    } else if hovering {
                        square.fill(greys.hover)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: Self.corner, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
        .animation(motion.quick, value: on)
    }

    /// The symbol's colour: full ink while open, nearly so under the pointer, else the ground's own grey.
    private var ink: AnyShapeStyle {
        if on { return AnyShapeStyle(Role.ink) }
        return hovering ? AnyShapeStyle(Role.ink.opacity(0.7)) : AnyShapeStyle(greys.muted)
    }

    /// The square's side, and how round its corners are, in points.
    static let side: CGFloat = 26
    static let corner: CGFloat = 8
}

/// Shrinks a thing a little while it is held down, and lets it spring back when let go.
package struct Give: ViewModifier {
    @Environment(\.motion) private var motion
    private let pressed: Bool

    package init(pressed: Bool) {
        self.pressed = pressed
    }

    package func body(content: Content) -> some View {
        content.animation(pressed ? motion.quick : motion.settle) {
            $0.scaleEffect(Self.scale(pressed: pressed, motion: motion))
        }
    }

    /// How large a thing is drawn: a little smaller while pressed, unless motion is reduced.
    static func scale(pressed: Bool, motion: Motion) -> CGFloat {
        pressed && !motion.reduced ? Motion.give : 1
    }
}
