// A row of the sidebar: a letter or an icon in a small tile, a title, and a close button under the pointer.
import SwiftUI

/// One thing in the sidebar. The one in front is washed and written in ink; a chosen one is ringed; the rest
/// are quiet. Under the pointer it lightens, and a close button shows if it can be closed.
package struct SideItem: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    @State private var hovering = false

    private let title: String
    private let letter: String
    private let icon: Image?
    private let live: Bool
    private let selected: Bool
    private let close: (() -> Void)?

    package init(
        title: String, letter: String, icon: Image? = nil, live: Bool = false, selected: Bool = false,
        close: (() -> Void)? = nil
    ) {
        self.title = title
        self.letter = letter
        self.icon = icon
        self.live = live
        self.selected = selected
        self.close = close
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous) }

    package var body: some View {
        HStack(spacing: Space.near.rawValue) {
            mark
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(live ? AnyShapeStyle(Role.ink) : AnyShapeStyle(greys.muted))
                .lineLimit(1)
            Spacer(minLength: 0)
            if hovering, let close {
                Button(action: close) {
                    Image(systemName: "xmark").font(.system(size: 9, weight: .semibold))
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(greys.muted)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Space.gap.rawValue)
        .frame(height: 28)
        .contentShape(shape)
        .background { ground.animation(motion.quick, value: live) }
        .overlay {
            if selected { shape.strokeBorder(Role.ink.opacity(0.35), lineWidth: 1) }
        }
        .animation(nil, value: hovering)
        .onHover { hovering = $0 }
        .transition(.scale(scale: 0.94, anchor: .leading).combined(with: .opacity))
    }

    /// The row's fill: washed when in front or chosen, a lighter grey under the pointer, else clear.
    private var ground: some View {
        shape.fill(live || selected ? greys.wash : greys.hover.opacity(hovering ? 1 : 0))
    }

    /// The icon if there is one, else the letter, in a small tile.
    @ViewBuilder private var mark: some View {
        if let icon {
            icon.resizable().scaledToFit().frame(width: 15, height: 15)
        } else {
            Text(letter)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(greys.muted)
                .frame(width: 15, height: 15)
                .background(Role.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }
}
