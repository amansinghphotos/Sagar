// Taken from Search at commit c92ea7c: its sidebar row's look (SideRow, Side.swift) and its title at rest
// (TitleAtRest, AtRestLine.swift). Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md).
// Changed only where this repository's rules require: Search's colours and motion are read from Look; what is a
// browser's own (loading, sound, pins, peeks, groups, editing, the address at rest) is left out; and the row's
// title, mark, and whether it is in front or chosen, are given.
import SwiftUI

/// A row of a sidebar: its mark, its title, and a cross under the pointer. The
/// one in front sits on the wash; a chosen one has a ring.
package struct SideItem: View {
    @Environment(\.greys) private var greys
    @Environment(\.motion) private var motion
    let title: String
    let letter: String
    var icon: Image? = nil
    var live = false
    var selected = false
    var close: (() -> Void)? = nil

    @State private var hovering = false

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

    private var closable: Bool { close != nil }

    package var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Mark(icon: icon, letter: letter, size: 15)
                Text(title)
                    .font(.system(size: 12.5))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(colour)
            }
            // Pushed to the leading edge by its frame, not a Spacer: the
            // row's spacing before a Spacer kept the title 8 points further
            // from the right edge than the icon is from the left.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .frame(height: 28)
            .contentShape(Rectangle())
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The title keeps its length under the pointer and fades out
        // beneath the cross, rather than being cut shorter, so its end
        // doesn't jump on each row the pointer passes.
        .mask {
            ZStack {
                Rectangle().opacity(hovering && closable ? 0 : 1)
                HStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 16)
                    Color.clear.frame(width: 26)
                }
            }
        }
        .overlay(alignment: .trailing) {
            ZStack {
                if hovering && closable {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Role.muted)
                        .frame(width: 15, height: 15)
                        .background(Role.ink.opacity(0.07), in: Circle())
                        .transition(.opacity)
                }
            }
            .frame(width: 15, height: 15)
            .overlay {
                Color.clear
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
                    .onTapGesture { if hovering, let close { close() } }
            }
            .padding(.trailing, 7)
        }
        .background { ground.animation(motion.quick, value: live) }
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Role.ink.opacity(0.35), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .onHover { hovering = $0 }
        .animation(nil, value: hovering)
        .transition(.scale(scale: 0.94, anchor: .leading).combined(with: .opacity))
    }

    @ViewBuilder
    private var ground: some View {
        if live {
            Rectangle().fill(greys.wash)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        } else if selected {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(greys.wash)
        } else if hovering {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(greys.hover)
        }
    }

    private var colour: AnyShapeStyle {
        if live { return AnyShapeStyle(Role.ink) }
        return hovering ? AnyShapeStyle(Role.ink.opacity(0.7)) : AnyShapeStyle(greys.muted)
    }
}
