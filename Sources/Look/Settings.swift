// Taken from Search at commit c92ea7c: GroupBlock, SettingRow and Steps (Settings.swift). Copyright (c) 2026
// Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require:
// Search's colours and motion are read from Look; the stepper's nearest stops are one function a test reads; icons
// beside words are hidden from VoiceOver, which reads the words.
import SwiftUI

/// A group of a section: its small heading with an icon, then its card.
/// No line under the heading: the rows say what they do.
package struct GroupBlock<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    package init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10.5, weight: .semibold))
                    .accessibilityHidden(true)
                Text(title.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.5)
            }
            .foregroundStyle(Role.ink.opacity(0.62))
            .padding(.leading, 2)
            content()
        }
    }
}

/// One setting: its icon in a soft tile, what it is, one line on what it
/// does (the rest behind the (i)), and its control. A wide control goes
/// under the words.
package struct SettingRow<Control: View>: View {
    let icon: String
    let title: String
    let detail: String
    var more: String? = nil
    var wide = false
    var lit = false
    @ViewBuilder let control: () -> Control

    @Environment(\.motion) private var motion
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

    package var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Role.ink.opacity(0.78))
                    .frame(width: 26, height: 26)
                    .background(Role.wash, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(title)
                            .font(.system(size: 13))
                            .foregroundStyle(Role.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if more != nil {
                            Button {
                                withAnimation(motion.quick) { open.toggle() }
                            } label: {
                                Image(systemName: open ? "info.circle.fill" : "info.circle")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Role.muted.opacity(0.8))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help(more ?? "")
                            .accessibilityLabel("More about \(title)")
                        }
                    }
                    if !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Role.muted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if open, let more {
                        Text(more)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Role.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 3)
                            .transition(.opacity)
                    }
                }
                Spacer(minLength: 8)
                if !wide { control() }
            }
            if wide {
                control()
                    .padding(.leading, 38)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .background(lit ? AnyShapeStyle(Role.hover) : AnyShapeStyle(.clear))
    }
}

/// A value moved one stop at a time: − and + either side of it, in the same
/// outlined capsule as a pill. Pressing the value itself takes it home.
package struct Steps: View {
    let stops: [Double]
    @Binding var value: Double
    let home: Double
    let label: (Double) -> String

    package init(stops: [Double], value: Binding<Double>, home: Double, label: @escaping (Double) -> String) {
        self.stops = stops
        _value = value
        self.home = home
        self.label = label
    }

    /// The nearest stop either way — a value between stops, from before
    /// there were stops, still moves to a round one.
    static func neighbours(of value: Double, in stops: [Double]) -> (below: Double?, above: Double?) {
        (stops.last { $0 < value - 0.001 }, stops.first { $0 > value + 0.001 })
    }

    private var below: Double? { Self.neighbours(of: value, in: stops).below }
    private var above: Double? { Self.neighbours(of: value, in: stops).above }

    package var body: some View {
        HStack(spacing: 0) {
            Step(icon: "minus", to: below) { value = $0 }
            Button {
                value = home
            } label: {
                Text(label(value))
                    .font(.system(size: 11.5))
                    .monospacedDigit()
                    .foregroundStyle(Role.ink)
                    .frame(minWidth: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Back to \(label(home))")
            Step(icon: "plus", to: above) { value = $0 }
        }
        .padding(.horizontal, 2)
        .frame(height: 24)
        .background(Role.ground, in: Capsule())
        .overlay(Capsule().strokeBorder(Role.hairline, lineWidth: 1))
    }

    private struct Step: View {
        let icon: String
        let to: Double?
        let act: (Double) -> Void
        @Environment(\.motion) private var motion
        @State private var hovering = false

        var body: some View {
            Button {
                if let to { act(to) }
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(to == nil ? Role.faint : Role.ink)
                    .frame(width: 20, height: 20)
                    .background(hovering && to != nil ? AnyShapeStyle(Role.hover) : AnyShapeStyle(.clear), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(to == nil)
            .onHover { hovering = $0 }
            .animation(motion.quick, value: hovering)
        }
    }
}
