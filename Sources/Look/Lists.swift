// The parts a list is made of: a line with its control, a quiet row, a mark, an always-on badge and a key cap.
import SwiftUI

/// A line in a list: its name, a line under it if there is one, and its control at the end.
package struct Line<Control: View>: View {
    private let title: String
    private let detail: String?
    private let control: () -> Control

    package init(_ title: String, _ detail: String? = nil, @ViewBuilder control: @escaping () -> Control) {
        (self.title, self.detail, self.control) = (title, detail, control)
    }

    package var body: some View {
        HStack(spacing: 16) {
            words
            Spacer(minLength: 8)
            control()
        }
        .padding(EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14))
    }

    /// The name, and under it the detail, which wraps to at most three lines.
    private var words: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).type(.body).foregroundStyle(Role.ink)
            if let detail {
                Text(detail).type(.detail).foregroundStyle(Role.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
    }
}

/// A row that waits quietly until the pointer comes to it: a symbol and words, faint at rest. A `centred` row shows
/// its symbol alone, in the middle, for a narrow column of symbols.
package struct Quiet: View {
    private let icon: String
    private let title: String
    private let height: CGFloat
    private let size: CGFloat
    private let centred: Bool
    private let act: () -> Void
    @State private var hovering = false
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion

    package init(
        icon: String, title: String, height: CGFloat = 28, size: CGFloat = 12.5, centred: Bool = false,
        act: @escaping () -> Void
    ) {
        (self.icon, self.title, self.act) = (icon, title, act)
        (self.height, self.size, self.centred) = (height, size, centred)
    }

    package var body: some View {
        Button(action: act) { face }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
            .animation(motion.quick, value: hovering)
    }

    /// Faint at rest, soft ink under the pointer.
    private var tint: AnyShapeStyle { hovering ? AnyShapeStyle(Role.ink.opacity(0.7)) : AnyShapeStyle(greys.faint) }

    /// The rounded shape the row lights up in, and answers clicks in.
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 9, style: .continuous) }

    /// The symbol and the words, faint at rest and in soft ink under the pointer, which also lights the row.
    private var face: some View {
        HStack(spacing: 8) {
            if centred { Spacer(minLength: 0) }
            Image(systemName: icon).font(.system(size: 10, weight: .medium)).frame(width: 15)
            if !title.isEmpty { Text(title).font(.system(size: size)) }
            Spacer(minLength: 0)
        }
        .padding(.leading, centred ? 0 : 10)
        .foregroundStyle(tint)
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(greys.hover.opacity(hovering ? 1 : 0), in: shape)
        .contentShape(shape)
    }
}

/// What stands for a page or a thing in a list: its own picture when it has one, or else its letter on a faint
/// tile. A template picture is drawn in ink, a little softened; a dim mark steps back. A `contrast` letter is in
/// full ink rather than the soft grey, so it still reads on glass.
package struct Mark: View {
    private let icon: Image?
    private let template: Bool
    private let letter: String
    private let size: CGFloat
    private let dim: Bool
    private let contrast: Bool
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion

    package init(
        icon: Image?, template: Bool = false, letter: String, size: CGFloat = 16, dim: Bool = false,
        contrast: Bool = false
    ) {
        (self.icon, self.template, self.letter) = (icon, template, letter)
        (self.size, self.dim, self.contrast) = (size, dim, contrast)
    }

    package var body: some View {
        face
            .opacity(dim ? 0.45 : 1).transition(.opacity)
            .animation(motion.quick, value: icon == nil)
            .animation(motion.quick, value: dim)
    }

    /// The symbol, the picture, or the letter, whichever the mark has.
    @ViewBuilder private var face: some View {
        if let icon, template {
            symbol(icon)
        } else if let icon {
            picture(icon)
        } else {
            tile
        }
    }

    /// One of the app's own symbols, in soft ink, light or dark, a little in from the edges.
    private func symbol(_ icon: Image) -> some View {
        icon.renderingMode(.template).resizable().scaledToFit()
            .foregroundStyle(Role.ink.opacity(0.75))
            .padding(size * 0.06)
            .frame(width: size, height: size)
    }

    /// A picture of the thing's own, smoothed, with its corners rounded.
    private func picture(_ icon: Image) -> some View {
        icon.resizable().interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }

    /// The letter, as given, on a faint rounded tile.
    private var tile: some View {
        let ink = contrast ? AnyShapeStyle(Role.ink) : AnyShapeStyle(greys.muted)
        return RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).fill(Role.ink.opacity(0.06))
            .frame(width: size, height: size)
            .overlay { Text(letter).foregroundStyle(ink).font(.system(size: size * 0.56, weight: .medium)) }
    }
}

/// A small badge for a setting that cannot be turned off.
package struct Always: View {
    private let text: String

    package init(text: String = "Always on") {
        self.text = text
    }

    package var body: some View {
        Text(text).font(.system(size: 11)).foregroundStyle(Role.muted)
            .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
            .background(Role.wash, in: Capsule())
    }
}

/// A key cap and what pressing it does.
package struct Key: View {
    private let keys: String
    private let what: String

    package init(_ keys: String, _ what: String) {
        (self.keys, self.what) = (keys, what)
    }

    package var body: some View {
        HStack(spacing: 10) {
            cap
            Text(what).type(.body).foregroundStyle(Role.muted)
        }
    }

    /// The keys in rounded type on a soft rounded cap, at least wide enough for a short word.
    private var cap: some View {
        Text(keys).foregroundStyle(Role.ink)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 7))
            .background(Role.wash, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(minWidth: 44)
    }
}
