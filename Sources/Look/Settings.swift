// The parts a settings page is made of: a group under a small heading, a row with its control, and a stepper.
import SwiftUI

/// A group of settings under a small heading in capitals, with its symbol beside it.
package struct GroupBlock<Content: View>: View {
    private let title: String
    private let icon: String
    private let content: () -> Content

    package init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        (self.title, self.icon, self.content) = (title, icon, content)
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heading
            content()
        }
    }

    /// The small heading: the symbol, which VoiceOver passes over, then the title in spaced capitals.
    private var heading: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).accessibilityHidden(true)
            Text(title.uppercased()).tracking(0.5)
        }
        .font(.system(size: 10.5, weight: .semibold))
        .foregroundStyle(Role.ink.opacity(0.62))
        .padding(.leading, 2)
    }
}

/// One setting: its symbol in a small tile, its name and a line on what it does, and its control at the end, or under
/// the words when the control is `wide`. A lit row stands out from the rest. `more`, when given, is a longer
/// explanation kept behind a small (i) beside the name.
package struct SettingRow<Control: View>: View {
    private let icon: String
    private let title: String
    private let detail: String
    private let more: String?
    private let wide: Bool
    private let lit: Bool
    private let control: () -> Control
    @State private var open = false
    @Environment(\.motion) private var motion

    /// How far a wide control sits in, so it lines up with the words: the tile and the gap after it.
    private let underWords: CGFloat = 26 + 12

    package init(
        icon: String, title: String, detail: String, more: String? = nil, wide: Bool = false, lit: Bool = false,
        @ViewBuilder control: @escaping () -> Control
    ) {
        (self.icon, self.title, self.detail, self.more) = (icon, title, detail, more)
        (self.wide, self.lit, self.control) = (wide, lit, control)
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            firstLine
            if wide { control().padding(.leading, underWords) }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Role.hover.opacity(lit ? 1 : 0))
    }

    /// The tile, the words, and the control at the end unless it goes under them.
    private var firstLine: some View {
        HStack(spacing: 12) {
            tile
            words
            Spacer(minLength: 8)
            if !wide { control() }
        }
    }

    /// The row's symbol on a soft rounded tile. VoiceOver passes over it and reads the name.
    private var tile: some View {
        let symbol = Image(systemName: icon).font(.system(size: 12, weight: .medium))
        return RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Role.wash)
            .frame(width: 26, height: 26)
            .overlay { symbol.foregroundStyle(Role.ink.opacity(0.78)) }
            .accessibilityHidden(true)
    }

    /// The name with its (i), the line under it when there is one, and the longer explanation while it is open.
    private var words: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text(title).type(.body).foregroundStyle(Role.ink).fixedSize(horizontal: false, vertical: true)
                if let more { info(more) }
            }
            if !detail.isEmpty { quiet(detail).lineLimit(2) }
            if open, let more { quiet(more).padding(.top, 3).transition(.opacity) }
        }
    }

    /// Words in the row's quieter voice, as tall as they need.
    private func quiet(_ words: String) -> some View {
        Text(words).type(.detail).foregroundStyle(Role.muted).fixedSize(horizontal: false, vertical: true)
    }

    /// The (i) that opens and closes the longer explanation. Its tooltip already holds the whole of it.
    private func info(_ more: String) -> some View {
        Button {
            withAnimation(motion.quick) { open.toggle() }
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(Role.muted.opacity(0.8))
                .font(.system(size: 10.5))
                .symbolVariant(open ? .fill : .none)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(more)
        .accessibilityLabel("More about \(title)")
    }
}

/// A value chosen from a few stops, one step at a time: minus, the value in words, plus, in an outlined capsule.
/// Pressing the words goes back to `home`.
package struct Steps: View {
    private let stops: [Double]
    @Binding private var value: Double
    private let home: Double
    private let label: (Double) -> String

    package init(stops: [Double], value: Binding<Double>, home: Double, label: @escaping (Double) -> String) {
        (self.stops, self.home, self.label) = (stops, home, label)
        _value = value
    }

    /// How near two values may be and still be the same stop.
    private static let sameStop = 0.001

    /// The nearest stop below `value` and the nearest above it, if there are any. A value between stops steps to
    /// the stop on either side of it.
    static func neighbours(of value: Double, in stops: [Double]) -> (below: Double?, above: Double?) {
        let below = stops.last(where: { $0 < value - sameStop })
        let above = stops.first(where: { $0 > value + sameStop })
        return (below, above)
    }

    package var body: some View {
        let near = Self.neighbours(of: value, in: stops)
        HStack(spacing: 0) {
            End(symbol: "minus", stop: near.below, take: take)
            current
            End(symbol: "plus", stop: near.above, take: take)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .frame(height: 24)
        .background { Capsule().fill(Role.ground) }
        .overlay { Capsule().strokeBorder(Role.hairline, lineWidth: 1) }
    }

    private func take(_ stop: Double) { value = stop }

    /// The value in words. Pressing it goes back home, and its tooltip says to what.
    private var current: some View {
        Button {
            take(home)
        } label: {
            Text(label(value)).foregroundStyle(Role.ink)
                .type(.detail)
                .monospacedDigit()
                .frame(minWidth: 36)
                .contentShape(Rectangle())
        }
        .help("Back to \(label(home))")
    }

    /// One end of the stepper: a small circle lit under the pointer, and faint, doing nothing, when no stop lies
    /// that way.
    private struct End: View {
        @Environment(\.motion) private var motion
        @State private var pointed = false
        let symbol: String
        let stop: Double?
        let take: (Double) -> Void

        var body: some View {
            Button {
                stop.map(take)
            } label: {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(stop == nil ? Role.faint : Role.ink)
                    .frame(width: 20, height: 20)
                    .background(Role.hover.opacity(pointed && stop != nil ? 1 : 0), in: Circle())
                    .contentShape(Circle())
            }
            .disabled(stop == nil)
            .onHover { pointed = $0 }
            .animation(motion.quick, value: pointed)
        }
    }
}
