// The parts a settings page is made of: a group under a small heading, a row with its control, and a stepper.
import SwiftUI

/// A group of settings under a small heading in capitals, with its symbol beside it.
package struct GroupBlock<Content: View>: View {
    private let title: String
    private let icon: String
    private let content: () -> Content

    package init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                Text(title.uppercased()).tracking(0.5)
            }
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(Role.ink.opacity(0.62))
            .padding(.leading, 2)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            content()
        }
    }
}

/// One setting: its symbol in a small tile, its name and a line on what it does, and its control at the end, or under
/// the words when the control is `wide`. A lit row stands out from the rest. `more`, when given, is a longer
/// explanation kept behind a small (i) beside the name.
package struct SettingRow<Control: View>: View {
    @Environment(\.motion) private var motion
    private let icon: String
    private let title: String
    private let detail: String
    private let more: String?
    private let wide: Bool
    private let lit: Bool
    private let control: () -> Control
    @State private var open = false

    package init(
        icon: String, title: String, detail: String, more: String? = nil, wide: Bool = false, lit: Bool = false,
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.more = more
        self.wide = wide
        self.lit = lit
        self.control = control
    }

    /// How far a wide control sits in, so it lines up with the words: the tile and the gap after it.
    private let underWords: CGFloat = 26 + 12

    package var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Role.ink.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Role.wash, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
                words
                Spacer(minLength: 12)
                if !wide { control() }
            }
            if wide { control().padding(.leading, underWords) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Role.hover.opacity(lit ? 1 : 0))
    }

    /// The name with its (i), the line under it when there is one, and the longer explanation while it is open.
    private var words: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text(title).type(.body).foregroundStyle(Role.ink)
                if let more { info(more) }
            }
            if !detail.isEmpty {
                Text(detail).type(.detail).foregroundStyle(Role.muted).lineLimit(2)
            }
            if open, let more {
                Text(more)
                    .type(.detail)
                    .foregroundStyle(Role.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
    }

    /// The (i) that opens and closes the longer explanation. Its tooltip already holds the whole of it.
    private func info(_ more: String) -> some View {
        Button {
            withAnimation(motion.quick) { open.toggle() }
        } label: {
            Image(systemName: "info.circle")
                .symbolVariant(open ? .fill : .none)
                .font(.system(size: 10.5))
                .foregroundStyle(Role.muted.opacity(0.8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(more)
        .accessibilityLabel("More about \(title)")
    }
}

/// A value chosen from a few stops, one step at a time: minus, the value in words, plus. Pressing the words goes back
/// to `home`.
package struct Steps: View {
    private let stops: [Double]
    @Binding private var value: Double
    private let home: Double
    private let label: (Double) -> String

    package init(stops: [Double], value: Binding<Double>, home: Double, label: @escaping (Double) -> String) {
        self.stops = stops
        _value = value
        self.home = home
        self.label = label
    }

    /// The nearest stop below `value` and the nearest above it, if there are any. A value between stops steps to
    /// the stop on either side of it.
    static func neighbours(of value: Double, in stops: [Double]) -> (below: Double?, above: Double?) {
        let close = 0.000_1
        let below = stops.filter { $0 < value - close }.max()
        let above = stops.filter { $0 > value + close }.min()
        return (below, above)
    }

    package var body: some View {
        let near = Self.neighbours(of: value, in: stops)
        HStack(spacing: 0) {
            Step(symbol: "minus", name: "Smaller", to: near.below) { value = $0 }
            Button {
                value = home
            } label: {
                Text(label(value))
                    .type(.detail)
                    .monospacedDigit()
                    .foregroundStyle(Role.ink)
                    .fixedSize()
                    .frame(width: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Back to \(label(home))")
            Step(symbol: "plus", name: "Larger", to: near.above) { value = $0 }
        }
        .frame(height: 24)
        .overlay(Capsule().strokeBorder(Role.hairline, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    /// One end of the stepper, lit under the pointer, and quiet when there is no stop further that way.
    private struct Step: View {
        @Environment(\.motion) private var motion
        let symbol: String
        let name: String
        let to: Double?
        let go: (Double) -> Void
        @State private var hovering = false

        var body: some View {
            Button {
                if let to { go(to) }
            } label: {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Capsule())
                    .background(Role.hover.opacity(hovering && to != nil ? 1 : 0), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(to == nil ? Role.faint : Role.ink)
            .disabled(to == nil)
            .onHover { hovering = $0 }
            .animation(motion.quick, value: hovering)
            .accessibilityLabel(name)
        }
    }
}
