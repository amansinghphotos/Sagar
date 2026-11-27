// The parts a list is made of: a line with its control, a quiet row, a mark, an always-on badge and a key cap.
import SwiftUI

/// A line in a list: its name, a line under it if there is one, and its control at the end.
package struct Line<Control: View>: View {
    private let title: String
    private let detail: String?
    private let control: () -> Control

    package init(_ title: String, _ detail: String? = nil, @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.detail = detail
        self.control = control
    }

    package var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).type(.body).foregroundStyle(Role.ink)
                if let detail {
                    Text(detail).type(.detail).foregroundStyle(Role.muted)
                }
            }
            Spacer(minLength: 0)
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

/// A row that waits quietly until the pointer comes to it: a symbol and words, faint at rest.
package struct Quiet: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    private let icon: String
    private let title: String
    private let act: () -> Void
    @State private var hovering = false

    package init(icon: String, title: String, act: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.act = act
    }

    package var body: some View {
        Button(action: act) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 10)).frame(width: 11)
                Text(title).font(.system(size: 12.5))
                Spacer(minLength: 0)
            }
            .foregroundStyle(hovering ? greys.muted : greys.faint)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                greys.hover.opacity(hovering ? 1 : 0), in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(motion.quick, value: hovering)
    }
}

/// What stands for a page or a thing in a list: its own picture when it has one, or else its first letter on a
/// small tile. A template picture is drawn in ink, a little softened; a dim mark steps back.
package struct Mark: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    private let icon: Image?
    private let template: Bool
    private let letter: String
    private let size: CGFloat
    private let dim: Bool

    package init(icon: Image?, template: Bool = false, letter: String, size: CGFloat = 16, dim: Bool = false) {
        self.icon = icon
        self.template = template
        self.letter = letter
        self.size = size
        self.dim = dim
    }

    package var body: some View {
        ZStack {
            Group {
                if let icon {
                    if template {
                        icon.resizable().scaledToFit()
                            .foregroundStyle(Role.ink.opacity(0.75))
                            .frame(width: size * 0.875, height: size * 0.875)
                    } else {
                        icon.resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    }
                } else {
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .fill(greys.pinLive.opacity(0.5))
                        .overlay {
                            Text(letter.prefix(1).uppercased())
                                .font(.system(size: size * 0.56, weight: .medium))
                                .foregroundStyle(greys.muted)
                        }
                }
            }
            .transition(.opacity)
        }
        .frame(width: size, height: size)
        .opacity(dim ? 0.5 : 1)
        .animation(motion.quick, value: icon == nil)
        .animation(motion.quick, value: dim)
        .accessibilityHidden(true)
    }
}

/// A small badge for a setting that cannot be turned off.
package struct Always: View {
    private let text: String

    package init(text: String = "Always on") {
        self.text = text
    }

    package var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(Role.muted)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Role.wash, in: Capsule())
    }
}

/// A key cap and what pressing it does.
package struct Key: View {
    private let keys: String
    private let what: String

    package init(_ keys: String, _ what: String) {
        self.keys = keys
        self.what = what
    }

    package var body: some View {
        HStack(spacing: 10) {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Role.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Role.wash, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .frame(minWidth: 44)
            Text(what)
                .type(.body)
                .foregroundStyle(Role.muted)
        }
        .accessibilityElement(children: .combine)
    }
}
