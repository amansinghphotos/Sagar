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
            Mark(icon: icon, letter: letter, size: 15)
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(ink)
                .lineLimit(1)
        }
        .padding(.horizontal, Space.gap.rawValue)
        .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28, alignment: .leading)
        // The title keeps its length under the pointer and fades out before the close button, so its end stays put.
        .mask { fade }
        .overlay(alignment: .trailing) { closer }
        .contentShape(shape)
        .background { ground.animation(motion.quick, value: live) }
        .overlay {
            if selected { shape.strokeBorder(Role.ink.opacity(0.35), lineWidth: 1).allowsHitTesting(false) }
        }
        .animation(nil, value: hovering)
        .onHover { hovering = $0 }
        .transition(.scale(scale: 0.94, anchor: .leading).combined(with: .opacity))
    }

    /// Ink for the one in front, a little darker under the pointer, quiet otherwise.
    private var ink: AnyShapeStyle {
        if live { return AnyShapeStyle(Role.ink) }
        return hovering ? AnyShapeStyle(Role.ink.opacity(0.7)) : AnyShapeStyle(greys.muted)
    }

    /// All of the row, but for the room the close button takes while it shows.
    private var fade: some View {
        HStack(spacing: 0) {
            Rectangle()
            if hovering && close != nil {
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 16)
                Color.clear.frame(width: 26)
            }
        }
    }

    /// A small cross in a faint circle, reachable a little beyond what it draws.
    @ViewBuilder private var closer: some View {
        if hovering, let close {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Role.muted)
                    .frame(width: 15, height: 15)
                    .background(Role.ink.opacity(0.07), in: Circle())
                    .frame(width: 29, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    /// The row's fill: washed when in front or chosen, a lighter grey under the pointer, else clear.
    private var ground: some View {
        shape.fill(live || selected ? greys.wash : greys.hover.opacity(hovering ? 1 : 0))
    }
}
