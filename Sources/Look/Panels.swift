// The surfaces things are laid on: a panel with a title and a foot, a card, a dividing rule and a small caption.
import SwiftUI

/// A panel that floats over the page: its title and a close button, what it holds, and a foot below a rule. Shown as
/// a tab of its own, it lies flat on the page instead.
package struct Plate<Content: View, Foot: View>: View {
    private let title: String
    private let width: CGFloat
    private let close: (() -> Void)?
    private let content: () -> Content
    private let foot: () -> Foot
    @Environment(\.asTab) private var asTab

    package init(
        _ title: String, width: CGFloat, close: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder foot: @escaping () -> Foot
    ) {
        self.title = title
        self.width = width
        self.close = close
        self.content = content
        self.foot = foot
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.panel.rawValue, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .type(.title)
                .foregroundStyle(Role.ink)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    if let close {
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Role.muted)
                                .frame(width: 26, height: 26)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.cancelAction)
                        .accessibilityLabel("Close")
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 21)
                .padding(.bottom, 17)
            VStack(alignment: .leading, spacing: 0, content: content)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            if Foot.self != EmptyView.self {
                Rule(inset: 0)
                HStack(spacing: 10) { foot() }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
            }
        }
        .frame(width: asTab ? nil : width, alignment: .leading)
        .frame(maxWidth: asTab ? .infinity : nil, alignment: .leading)
        .background(Role.ground)
        .clipShape(asTab ? AnyShape(Rectangle()) : AnyShape(shape))
        .overlay { if !asTab { shape.strokeBorder(Role.hairline) } }
        .background { if !asTab { shape.fill(Role.ground).elevation(.panel) } }
    }
}

extension Plate where Foot == EmptyView {
    /// A panel with nothing at its foot.
    package init(
        _ title: String, width: CGFloat, close: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title, width: width, close: close, content: content) { EmptyView() }
    }
}

/// Rows grouped on the page inside a thin rounded edge.
package struct Card<Content: View>: View {
    private let content: () -> Content

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous)
        VStack(alignment: .leading, spacing: 0, content: content)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Role.hairline))
    }
}

/// A thin line between rows, set in from the leading edge by `inset`, or by the inset where it lies.
package struct Rule: View {
    private let inset: CGFloat?
    @Environment(\.ruleInset) private var standard

    package init(inset: CGFloat? = nil) {
        self.inset = inset
    }

    package var body: some View {
        Rectangle()
            .fill(Role.hairline)
            .frame(height: 1)
            .padding(.leading, inset ?? standard)
            .accessibilityHidden(true)
    }
}

/// A small quiet heading over a group of things.
package struct Caption: View {
    private let text: String

    package init(_ text: String) { self.text = text }

    package var body: some View {
        Text(text)
            .type(.caption)
            .foregroundStyle(Role.muted)
            .padding(.leading, 2)
            .accessibilityAddTraits(.isHeader)
    }
}

nonisolated private struct AsTabKey: EnvironmentKey {
    static let defaultValue = false
}

nonisolated private struct RuleInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 14
}

extension EnvironmentValues {
    /// Whether a panel is shown as a tab of its own, flat on the page, rather than floating over it.
    nonisolated package var asTab: Bool {
        get { self[AsTabKey.self] }
        set { self[AsTabKey.self] = newValue }
    }

    /// How far a rule is set in from the leading edge where no inset is given.
    nonisolated package var ruleInset: CGFloat {
        get { self[RuleInsetKey.self] }
        set { self[RuleInsetKey.self] = newValue }
    }
}

extension View {
    /// Lays a popover's contents on the page's own ground, out to its edges.
    package func popoverGround() -> some View {
        background(Role.ground)
    }
}
