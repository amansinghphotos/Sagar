// Taken from Search at commit c92ea7c: Switch, Ticks and Segmented (Settings.swift). Copyright (c) 2026 Office
// Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require: Search's
// colours and motion are read from Look.
import SwiftUI

/// On or off, in ink rather than in blue.
package struct Switch: View {
    @Binding var on: Bool
    @Environment(\.motion) private var motion

    package init(on: Binding<Bool>) {
        _on = on
    }

    package var body: some View {
        Capsule()
            .fill(on ? Role.ink : Role.faint)
            .frame(width: 30, height: 18)
            .overlay(alignment: on ? .trailing : .leading) {
                Circle()
                    .fill(Role.ground)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
                    .padding(2)
            }
            .contentShape(Capsule())
            .onTapGesture { withAnimation(motion.settle) { on.toggle() } }
            .animation(motion.settle, value: on)
    }
}

/// A few things each shown or not, side by side: a tick for each
/// (Back, Forward, Reload…).
package struct Ticks: View {
    let items: [(String, Binding<Bool>)]

    package init(items: [(String, Binding<Bool>)]) {
        self.items = items
    }

    package var body: some View {
        HStack(spacing: 14) {
            ForEach(items.indices, id: \.self) { index in
                Toggle(items[index].0, isOn: items[index].1)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12.5))
            }
        }
    }
}

/// A choice of a few, side by side, the chosen one on a white plate that slides.
package struct Segmented<Option: Hashable>: View {
    let options: [(Option, String)]
    @Binding var selection: Option
    /// True when the control has the whole width to itself, so the choices
    /// share it evenly instead of each taking only what its word needs.
    var wide = false

    @Environment(\.motion) private var motion
    @Namespace private var slide

    package init(options: [(Option, String)], selection: Binding<Option>, wide: Bool = false) {
        self.options = options
        _selection = selection
        self.wide = wide
    }

    package var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.0) { option, title in
                Text(title)
                    .font(.system(size: 11.5, weight: option == selection ? .medium : .regular))
                    .foregroundStyle(option == selection ? Role.ink : Role.muted)
                    .lineLimit(1)
                    .fixedSize(horizontal: !wide, vertical: false)
                    .frame(maxWidth: wide ? .infinity : nil)
                    .padding(.horizontal, wide ? 4 : 10)
                    .padding(.vertical, 5)
                    .background {
                        if option == selection {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Role.ground)
                                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "chosen", in: slide)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .onTapGesture {
                        withAnimation(motion.settle) { selection = option }
                    }
            }
        }
        .padding(2)
        .background(Role.wash, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .animation(motion.settle, value: selection)
    }
}
