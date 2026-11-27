// The surfaces things are laid on: a panel with a title and a foot, a card, a dividing rule and a small caption.
import SwiftUI

/// A panel that floats over the page: its title and a close button, what it holds, and, when it has one, a foot below
/// a rule. Shown as a tab of its own, it lies flat on the page instead, with no close button: the tab closes it.
package struct Plate<Content: View, Foot: View>: View {
    private let title: String
    private let width: CGFloat
    private let close: () -> Void
    private let content: () -> Content
    private let foot: () -> Foot
    @Environment(\.asTab) private var asTab

    package init(
        _ title: String, width: CGFloat = 560, close: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content, @ViewBuilder foot: @escaping () -> Foot
    ) {
        self.title = title
        self.width = width
        self.close = close
        self.content = content
        self.foot = foot
    }

    private var hasFoot: Bool { Foot.self != EmptyView.self }

    package var body: some View {
        if asTab { flat } else { floating }
    }

    private var floating: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.panel.rawValue, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .type(.title)
                .foregroundStyle(Role.ink)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    Door(icon: "xmark", help: "Done   esc", act: close).accessibilityLabel("Close")
                }
                .padding(.horizontal, 22)
                .padding(.top, 21)
                .padding(.bottom, 17)
            VStack(alignment: .leading, spacing: 0, content: content)
                .padding(.horizontal, 22)
                .padding(.bottom, hasFoot ? 18 : 20)
            if hasFoot {
                Rule(inset: 0)
                foot()
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
            }
        }
        .frame(width: width, alignment: .leading)
        .background(Role.ground)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Role.hairline) }
        .background { shape.fill(Role.ground).elevation(.panel) }
    }

    /// In a tab: a larger title, and what the panel holds no wider than the panel was, down the middle of the page.
    private var flat: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Role.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 44)
                .padding(.bottom, 20)
            VStack(alignment: .leading, spacing: 0, content: content)
            if hasFoot {
                Rule(inset: 0).padding(.top, 18)
                foot().padding(.vertical, 14)
            }
            Spacer().frame(height: 12)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: width, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension Plate where Foot == EmptyView {
    /// A panel with nothing at its foot.
    package init(
        _ title: String, width: CGFloat = 560, close: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
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
            .background(Role.ground)
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
