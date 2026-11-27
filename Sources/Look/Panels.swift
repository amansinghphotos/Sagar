// Taken from Search at commit c92ea7c: Plate, Card, Rule and Caption (Plate.swift), the environment's asTab
// (InternalPages.swift) and ruleInset (Plate.swift), and popoverGround (Design.swift). Copyright (c) 2026
// Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's rules require:
// Search's colours are read from Look.
import SwiftUI

/// The plate: a rounded card with a title, a cross, whatever the panel is
/// about, and — when there is one — a foot below a hairline.
package struct Plate<Content: View, Foot: View>: View {
    let title: String
    var width: CGFloat = 560
    let close: () -> Void
    @ViewBuilder let content: () -> Content
    @ViewBuilder let foot: () -> Foot

    package init(
        _ title: String,
        width: CGFloat = 560,
        close: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder foot: @escaping () -> Foot
    ) {
        self.title = title
        self.width = width
        self.close = close
        self.content = content
        self.foot = foot
    }

    @Environment(\.asTab) private var asTab

    package var body: some View {
        if asTab { page } else { card }
    }

    /// In a tab of its own: the same title and
    /// content, as wide as the card was, down the middle of the page. No
    /// card, no shadow, no cross — the tab is what closes.
    private var page: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Role.ink)
                .padding(.top, 44)
                .padding(.bottom, 20)

            content()

            if Foot.self != EmptyView.self {
                Rectangle().fill(Role.hairline).frame(height: 1)
                    .padding(.top, 18)
                foot()
                    .padding(.vertical, 14)
            }
            Color.clear.frame(height: 12)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: width, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Role.ink)
                Spacer(minLength: 0)
                Door(icon: "xmark", help: "Done   esc", act: close)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 14)

            content()
                .padding(.horizontal, 22)

            if Foot.self != EmptyView.self {
                Rectangle().fill(Role.hairline).frame(height: 1)
                    .padding(.top, 18)
                foot()
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
            } else {
                Color.clear.frame(height: 20)
            }
        }
        .frame(width: width, alignment: .leading)
        .background(Role.ground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Role.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 34, y: 12)
    }
}

extension Plate where Foot == EmptyView {
    /// A plate with no foot.
    package init(
        _ title: String, width: CGFloat = 560, close: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title, width: width, close: close, content: content, foot: { EmptyView() })
    }
}

/// A group of lines in one hairline box.
package struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content

    package init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    package var body: some View {
        VStack(spacing: 0) { content() }
            .background(Role.ground)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Role.hairline, lineWidth: 1)
            )
    }
}

/// The hairline between two lines of a card, inset like the text unless
/// the card says otherwise (see EnvironmentValues.ruleInset).
package struct Rule: View {
    var inset: CGFloat? = nil
    @Environment(\.ruleInset) private var standard

    package init(inset: CGFloat? = nil) {
        self.inset = inset
    }

    package var body: some View {
        Rectangle().fill(Role.hairline).frame(height: 1).padding(.leading, inset ?? standard)
    }
}

/// A small heading over a card, for when a panel has more than one.
package struct Caption: View {
    let text: String
    package init(_ text: String) { self.text = text }
    package var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(Role.muted)
            .padding(.leading, 2)
    }
}

nonisolated private struct AsTabKey: EnvironmentKey {
    static let defaultValue = false
}

nonisolated private struct RuleInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 14
}

extension EnvironmentValues {
    /// True when a panel is drawn as a page in a tab of its own rather than
    /// as a card over the page: the plate gives up its card, its shadow and
    /// its cross, and its lists take the height the window gives them.
    nonisolated package var asTab: Bool {
        get { self[AsTabKey.self] }
        set { self[AsTabKey.self] = newValue }
    }

    /// Where a Rule without an inset of its own starts. Settings sets 0, so
    /// every hairline in its cards runs from edge to edge, those drawn by
    /// the lists it borrows from other panels too. A list drawn further in
    /// sets minus its own indent, so its hairlines still reach the edge.
    nonisolated package var ruleInset: CGFloat {
        get { self[RuleInsetKey.self] }
        set { self[RuleInsetKey.self] = newValue }
    }
}

extension View {
    /// The ground a popover's content lies on. Since macOS 26 a popover
    /// fills its arrow too, so the content is handed the ground; before,
    /// the popover was handed it to fill its own shape with.
    package func popoverGround() -> some View {
        modifier(PopoverGround())
    }
}

private struct PopoverGround: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.background(Role.ground)
        } else {
            content.presentationBackground(Role.ground)
        }
    }
}
