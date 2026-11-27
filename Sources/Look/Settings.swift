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

/// One setting: its symbol in a small tile, its name and a line on what it does, and its control at the end. A lit
/// row stands out from the rest.
package struct SettingRow<Control: View>: View {
    @Environment(\.motion) private var motion
    private let icon: String
    private let title: String
    private let detail: String
    private let more: String?
    private let lit: Bool
    private let control: () -> Control
    @State private var open = false

    /// `more`, when given, is a longer explanation the row shows when its name is clicked.
    package init(
        icon: String, title: String, detail: String, more: String? = nil, lit: Bool = false,
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.more = more
        self.lit = lit
        self.control = control
    }

    package var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Role.ink.opacity(0.8))
                .frame(width: 26, height: 26)
                .background(Role.wash, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                name
                Text(detail).type(.detail).foregroundStyle(Role.muted)
                if open, let more {
                    Text(more)
                        .type(.detail)
                        .foregroundStyle(Role.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
            Spacer(minLength: 12)
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Role.hover.opacity(lit ? 1 : 0))
    }

    /// The row's name, which opens and closes its longer explanation when it has one.
    @ViewBuilder private var name: some View {
        let words = Text(title).type(.body).foregroundStyle(Role.ink)
        if more == nil {
            words
        } else {
            Button {
                withAnimation(motion.quick) { open.toggle() }
            } label: {
                words
            }
            .buttonStyle(.plain)
            .accessibilityHint(open ? "Hides more" : "Shows more")
        }
    }
}

/// A value chosen from a few stops, one step at a time: minus, the value in words, plus. Double-clicking the words
/// goes back to `home`.
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
            Text(label(value))
                .type(.detail)
                .monospacedDigit()
                .foregroundStyle(Role.ink)
                .fixedSize()
                .frame(width: 32)
                .onTapGesture(count: 2) { value = home }
                .accessibilityLabel(label(value))
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
