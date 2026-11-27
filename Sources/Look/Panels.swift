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
        (self.title, self.width, self.close) = (title, width, close)
        (self.content, self.foot) = (content, foot)
    }

    /// How far the panel's words sit in from its sides.
    private let side: CGFloat = 22

    private var hasFoot: Bool { Foot.self != EmptyView.self }

    package var body: some View {
        if asTab { flat } else { floating }
    }

    /// Over the page: the title with its cross, what the panel holds, then the foot or a little room, on a lifted
    /// rounded ground.
    private var floating: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content().padding(.horizontal, side)
            if hasFoot { footing(sides: side) } else { Color.clear.frame(height: 20) }
        }
        .frame(width: width, alignment: .leading)
        .onGround(.panel)
        .elevation(.panel)
    }

    /// The title, and at the far end the cross that closes the panel.
    private var header: some View {
        HStack(spacing: 10) {
            Text(title).type(.title).foregroundStyle(Role.ink)
            Spacer(minLength: 0)
            Door(icon: "xmark", help: "Done   esc", act: close)
        }
        .padding(EdgeInsets(top: 18, leading: side, bottom: 14, trailing: side))
    }

    /// The rule, a little below what the panel holds, and the foot under it, set in by `sides`.
    @ViewBuilder private func footing(sides: CGFloat) -> some View {
        Rule(inset: 0).padding(.top, 18)
        foot().padding(EdgeInsets(top: 14, leading: sides, bottom: 14, trailing: sides))
    }

    /// In a tab: a larger title, and what the panel holds no wider than the panel was, down the middle of the page.
    private var flat: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 22, weight: .semibold)).foregroundStyle(Role.ink)
                .padding(EdgeInsets(top: 44, leading: 0, bottom: 20, trailing: 0))
            content()
            if hasFoot { footing(sides: 0) }
            Color.clear.frame(height: 12)
        }
        .padding(.horizontal, side)
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
        VStack(spacing: 0, content: content).onGround(.card)
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
        Rectangle().fill(Role.hairline).frame(height: 1)
            .padding(.leading, inset ?? standard)
    }
}

/// A small quiet heading over a group of things.
package struct Caption: View {
    private let text: String

    package init(_ text: String) { self.text = text }

    package var body: some View {
        Text(text).type(.caption).foregroundStyle(Role.muted).padding(.leading, 2)
    }
}

extension View {
    /// Lays a panel or a card on the page's ground, clipped to its rounded shape as one, so a shadow falls only outside
    /// it, with a hairline round its edge.
    fileprivate func onGround(_ radius: Radius) -> some View {
        let edge = RoundedRectangle(cornerRadius: radius.rawValue, style: .continuous)
        return background(Role.ground, in: edge)
            .clipShape(edge)
            .overlay { edge.strokeBorder(Role.hairline) }
    }
}

nonisolated extension EnvironmentValues {
    /// Whether a panel is shown as a tab of its own, flat on the page, rather than floating over it.
    @Entry package var asTab = false
    /// How far a rule is set in from the leading edge where no inset is given.
    @Entry package var ruleInset: CGFloat = 14
}

extension View {
    /// Lays a popover's contents on the page's own ground, out to its edges.
    package func popoverGround() -> some View {
        background(Role.ground)
    }
}
