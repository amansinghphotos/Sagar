// Ways to turn a thing on or off, or to pick one of a few: a switch, a row of ticks and a segmented choice.
import SwiftUI

/// A small switch: a dark pill with its knob at the end when on, a pale one with its knob at the start when off.
package struct Switch: View {
    @Environment(\.motion) private var motion
    @Binding private var on: Bool

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
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                    .padding(2)
            }
            .contentShape(Capsule())
            .onTapGesture { withAnimation(motion.settle) { on.toggle() } }
            .animation(motion.settle, value: on)
            .accessibilityRepresentation { Toggle("", isOn: $on) }
    }
}

/// A row of check boxes, each with its words: the Mac's own, so they read as every other check box does.
package struct Ticks: View {
    private let items: [(String, Binding<Bool>)]

    package init(items: [(String, Binding<Bool>)]) {
        self.items = items
    }

    package var body: some View {
        HStack(spacing: Space.wide.rawValue) {
            ForEach(items.indices, id: \.self) { index in
                Toggle(isOn: items[index].1) { Text(items[index].0) }
                    .toggleStyle(.checkbox)
            }
        }
        .font(.system(size: 12.5))
    }
}

/// One of a few choices, side by side on a pale track. The chosen one is lifted onto a white tile that slides
/// to whichever is chosen next. Each is as wide as its words, or, when `wide`, they share the width.
package struct Segmented<Option: Hashable>: View {
    @Environment(\.motion) private var motion
    @Namespace private var tile
    private let options: [(Option, String)]
    @Binding private var selection: Option
    private let wide: Bool

    package init(options: [(Option, String)], selection: Binding<Option>, wide: Bool = false) {
        self.options = options
        _selection = selection
        self.wide = wide
    }

    package var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { index in
                let (option, name) = options[index]
                let chosen = option == selection
                Text(name)
                    .type(.detail)
                    .fontWeight(chosen ? .medium : .regular)
                    .foregroundStyle(chosen ? Role.ink : Role.muted)
                    .lineLimit(1)
                    .padding(.horizontal, Space.gap.rawValue)
                    .frame(maxWidth: wide ? .infinity : nil)
                    .frame(height: 24)
                    .background {
                        if chosen {
                            RoundedRectangle(cornerRadius: Radius.control.rawValue, style: .continuous)
                                .fill(Role.ground)
                                .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "tile", in: tile)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: Radius.row.rawValue - 2, style: .continuous))
                    .onTapGesture {
                        withAnimation(motion.settle) { selection = option }
                    }
                    .accessibilityElement()
                    .accessibilityLabel(Text(name))
                    .accessibilityAddTraits(chosen ? [.isButton, .isSelected] : .isButton)
                    .accessibilityAction { withAnimation(motion.settle) { selection = option } }
            }
        }
        .padding(2)
        .background(Role.wash, in: RoundedRectangle(cornerRadius: Radius.row.rawValue, style: .continuous))
        .animation(motion.settle, value: selection)
    }
}
