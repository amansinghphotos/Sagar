// Taken from Search at commit c92ea7c: Pill (Settings.swift), Quick (Plate.swift), Door (Side.swift) and
// Give (TabBar.swift). Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only
// where this repository's rules require: Search's colours and motion are read from Look, and the door's
// held menu and the key in its tooltip arrive with their own parts.
import SwiftUI

/// A small capsule that does one thing. Outlined by default; filled in ink
/// when it is the thing you came here to press.
package struct Pill: View {
    let title: String
    var filled = false
    var tint: Role = .ink
    let action: () -> Void

    @Environment(\.motion) private var motion
    @State private var hovering = false

    package init(_ title: String, filled: Bool = false, tint: Role = .ink, action: @escaping () -> Void) {
        self.title = title
        self.filled = filled
        self.tint = tint
        self.action = action
    }

    package var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11.5))
                .foregroundStyle(filled ? Role.ground : tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(filled ? Role.ink : (hovering ? Role.hover : Role.ground), in: Capsule())
                .overlay(
                    Capsule().strokeBorder(filled ? AnyShapeStyle(.clear) : AnyShapeStyle(Role.hairline), lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
    }
}

/// A small text action inside a row — Show, Copy, Remove.
package struct Quick: View {
    let title: String
    var tint: Role = .ink
    let act: () -> Void

    package init(_ title: String, tint: Role = .ink, act: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.act = act
    }

    package var body: some View {
        Button(action: act) {
            // On one line, whatever room is left: in the narrow downloads
            // card, Resume, Retry and Remove broke in the middle of a word.
            Text(title)
                .font(.system(size: 11.5))
                .foregroundStyle(tint)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Role.wash, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A small square holding one symbol. Lit when what it opens is open.
package struct Door: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    let icon: String
    var on = false
    var help = ""
    /// Moves the symbol sideways in its button, for one whose ink isn't
    /// centred in its own box: the puzzle's weighs almost a point left.
    var nudge: CGFloat = 0
    let act: () -> Void

    @State private var hovering = false

    package init(icon: String, on: Bool = false, help: String = "", nudge: CGFloat = 0, act: @escaping () -> Void) {
        self.icon = icon
        self.on = on
        self.help = help
        self.nudge = nudge
        self.act = act
    }

    package var body: some View {
        Button {
            act()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                // At rest in the ground's own grey, as a tab's title is: the
                // plain ground's Palette.muted, but black or white let
                // through, so it stands off whatever it lies on. An opaque
                // mid grey vanished on glass with Transparency up, where the
                // ground is whatever is behind the window.
                .foregroundStyle(
                    on
                        ? AnyShapeStyle(Role.ink)
                        : (hovering ? AnyShapeStyle(Role.ink.opacity(0.7)) : AnyShapeStyle(greys.muted))
                )
                .offset(x: nudge)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            on
                                ? AnyShapeStyle(greys.wash)
                                : (hovering ? AnyShapeStyle(greys.hover) : AnyShapeStyle(.clear)))
                )
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help)
        .animation(motion.quick, value: hovering)
        .animation(motion.quick, value: on)
    }
}

/// A tab gives a little under the button and springs back when it is let
/// go, the life Arc's tabs have when clicked. Going down is quick, so the
/// click is answered at once; coming back is the settle spring. Only the
/// scale is animated, so the selection the press makes isn't slowed with
/// it. Nothing moves with Reduce Motion on.
package struct Give: ViewModifier {
    let pressed: Bool
    @Environment(\.motion) private var motion

    package init(pressed: Bool) {
        self.pressed = pressed
    }

    package func body(content: Content) -> some View {
        content.animation(pressed ? motion.quick : motion.settle) {
            $0.scaleEffect(Self.scale(pressed: pressed, motion: motion))
        }
    }

    /// How far a thing gives: Search's `pressed && !Motion.reduced ? Motion.give : 1`.
    static func scale(pressed: Bool, motion: Motion) -> CGFloat {
        pressed && !motion.reduced ? Motion.give : 1
    }
}
