// Taken from Search at commit c92ea7c: Line (Plate.swift), Quiet (Side.swift), Mark (Icons.swift), Always
// (Settings.swift) and Welcome's Key (Welcome.swift). Copyright (c) 2026 Office Commun, MIT licence
// (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require: Search's colours and motion are
// read from Look, and a mark's icon is a SwiftUI image, told whether it is a template, instead of an AppKit one.
import SwiftUI

/// One thing to set or do: what it is on the left, the control on the right.
package struct Line<Control: View>: View {
    let title: String
    let detail: String?
    @ViewBuilder let control: () -> Control

    package init(_ title: String, _ detail: String? = nil, @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.detail = detail
        self.control = control
    }

    package var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Role.ink)
                if let detail {
                    Text(detail)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Role.muted)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

/// A row that is an action rather than a page. Quiet until the pointer is on it.
package struct Quiet: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    let icon: String
    let title: String
    var height: CGFloat = 28
    var size: CGFloat = 12.5
    /// The icon alone, in the middle: the column of icons' new tab.
    var centred = false
    let act: () -> Void

    @State private var hovering = false

    package init(
        icon: String, title: String, height: CGFloat = 28, size: CGFloat = 12.5, centred: Bool = false,
        act: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.height = height
        self.size = size
        self.centred = centred
        self.act = act
    }

    package var body: some View {
        Button(action: act) {
            HStack(spacing: 8) {
                if centred { Spacer(minLength: 0) }
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 15)
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: size))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(hovering ? AnyShapeStyle(Role.ink.opacity(0.7)) : AnyShapeStyle(greys.faint))
            .padding(.leading, centred ? 0 : 10)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(hovering ? AnyShapeStyle(greys.hover) : AnyShapeStyle(.clear))
            )
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
    }
}

/// What stands for a page when there is no room for its title: the site's
/// icon if there is one, and a letter in a faint square until there is.
package struct Mark: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    let icon: Image?
    /// Whether the icon is a symbol to draw in the row's ink, as Search's own pages' are.
    var template = false
    let letter: String
    var size: CGFloat = 16
    var dim = false
    /// Full ink for the letter, instead of the soft grey a resting mark usually wears: the
    /// ground's own, as the doors' (see Door), so it still reads on glass.
    var contrast = false

    package init(
        icon: Image?, template: Bool = false, letter: String, size: CGFloat = 16, dim: Bool = false,
        contrast: Bool = false
    ) {
        self.icon = icon
        self.template = template
        self.letter = letter
        self.size = size
        self.dim = dim
        self.contrast = contrast
    }

    package var body: some View {
        Group {
            if let icon, template {
                // One of the app's own pages: its symbol, in the row's ink, light or dark.
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Role.ink.opacity(0.75))
                    .padding(size * 0.06)
                    .frame(width: size, height: size)
            } else if let icon {
                icon
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            } else {
                Text(letter)
                    .font(.system(size: size * 0.56, weight: .medium))
                    .foregroundStyle(contrast ? AnyShapeStyle(Role.ink) : AnyShapeStyle(greys.muted))
                    .frame(width: size, height: size)
                    .background(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .fill(Role.ink.opacity(0.06))
                    )
            }
        }
        .opacity(dim ? 0.45 : 1)
        .transition(.opacity)
        .animation(motion.quick, value: icon == nil)
        .animation(motion.quick, value: dim)
    }
}

/// For a feature that is simply there: no switch, a quiet word.
package struct Always: View {
    var text = "Always on"

    package init(text: String = "Always on") {
        self.text = text
    }

    package var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(Role.muted)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Role.wash, in: Capsule())
    }
}

/// A key, or keys, in a cap, and what they do: Search's welcome's.
package struct Key: View {
    let keys: String
    let what: String

    package init(_ keys: String, _ what: String) {
        self.keys = keys
        self.what = what
    }

    package var body: some View {
        HStack(spacing: 10) {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Role.ink)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Role.wash, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .frame(minWidth: 44)
            Text(what).font(.system(size: 13)).foregroundStyle(Role.muted)
        }
    }
}
