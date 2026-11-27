// The pages an app shows the first time it opens: the frame that steps through them, their heading, their big
// buttons and their choice rows.
import SwiftUI

/// Pages shown the first time an app opens, one at a time: the page in the middle, and along the foot a dot for each
/// page, then Back, Skip and a filled button that goes on, or finishes on the last page.
package struct Welcome<Page: View>: View {
    private let count: Int
    private let lastTitle: String
    private let finish: () -> Void
    private let content: (Int) -> Page

    @Environment(\.motion) private var motion
    @State private var shown: Int
    /// Whether the last step went on rather than back, so the pages slide the way the person went.
    @State private var onward = true

    package init(
        pages: Int, last: String, startPage: Int = 0,
        finish: @escaping () -> Void, @ViewBuilder page: @escaping (Int) -> Page
    ) {
        (count, lastTitle, self.finish, content) = (pages, last, finish, page)
        _shown = State(initialValue: min(max(startPage, 0), max(pages - 1, 0)))
    }

    private var onLast: Bool { shown >= count - 1 }

    package var body: some View {
        VStack(spacing: .zero) {
            Spacer(minLength: .zero)
            current
            Spacer(minLength: .zero)
            foot
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Role.ground, ignoresSafeAreaEdges: .all)
        .animation(motion.glide, value: shown)
        .transition(.opacity)
    }

    /// The page in view. It slides in from the side the person is heading to, and out the other.
    private var current: some View {
        let travel: CGFloat = onward ? 40 : -40
        return content(shown)
            .frame(maxWidth: 520)
            .id(shown)
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .offset(x: travel)),
                    removal: .opacity.combined(with: .offset(x: -travel))))
    }

    /// A dot for each page, then Back once past the first, Skip until the last, and the button that goes on.
    private var foot: some View {
        HStack(spacing: Space.wide.rawValue) {
            dots
            Spacer()
            if shown > 0 { quiet("Back", act: back) }
            if !onLast { quiet("Skip", act: finish) }
            Big(onLast ? lastTitle : "Continue", filled: true, act: onLast ? finish : next)
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: 520)
    }

    private var dots: some View {
        HStack(spacing: Space.snug.rawValue) {
            ForEach(0..<count, id: \.self) { page in
                Circle().fill(tint(ofDot: page)).frame(width: 6, height: 6)
            }
        }
    }

    /// The dot of the page in view is in ink; the others are faint.
    private func tint(ofDot page: Int) -> AnyShapeStyle {
        if page == shown { return AnyShapeStyle(Role.ink) }
        return AnyShapeStyle(Role.faint.opacity(0.6))
    }

    /// Back and Skip: words only, in the quieter grey.
    private func quiet(_ title: String, act: @escaping () -> Void) -> some View {
        Button(action: act) { Text(title).type(.body).foregroundStyle(Role.muted) }
            .buttonStyle(.plain)
    }

    private func back() {
        onward = false
        shown -= 1
    }

    private func next() {
        onward = true
        shown += 1
    }
}

/// The big line a first-open page opens with, and the quieter sentence under it.
package struct WelcomeHeading: View {
    private let title: String
    private let line: String

    package init(_ title: String, _ line: String) {
        (self.title, self.line) = (title, line)
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: Space.near.rawValue) {
            Text(title).type(.display).foregroundStyle(Role.ink)
            Text(line).font(.system(size: 14)).lineSpacing(2).foregroundStyle(Role.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A first-open page's large button.
package struct Big: View {
    @State private var underPointer = false
    private let title: String
    private let filled: Bool
    private let act: () -> Void

    package init(_ title: String, filled: Bool = false, act: @escaping () -> Void) {
        (self.title, self.filled, self.act) = (title, filled, act)
    }

    package var body: some View {
        Button(action: act) { label }
            .buttonStyle(.plain)
            .onHover { inside in underPointer = inside }
    }

    /// The title in a capsule: ground on ink when filled, otherwise ink on a soft grey that lightens under the
    /// pointer.
    private var label: some View {
        Text(title)
            .type(.body)
            .fontWeight(.medium)
            .padding(.horizontal, Space.page.rawValue)
            .padding(.vertical, 9)
            .foregroundStyle(filled ? Role.ground : Role.ink)
            .background(fill, in: Capsule())
            .contentShape(Capsule())
    }

    private var fill: Role {
        if filled { return .ink }
        return underPointer ? .hover : .wash
    }
}

/// A row a first-open page offers: what it is, a line on what it does, and a switch.
package struct Choice: View {
    private let title: String
    private let detail: String
    private let plain: Bool
    @Binding private var on: Bool

    package init(_ title: String, _ detail: String, on: Binding<Bool>, plain: Bool = false) {
        (self.title, self.detail, self.plain) = (title, detail, plain)
        _on = on
    }

    package var body: some View {
        HStack(spacing: Space.apart.rawValue) {
            labels
            Spacer()
            Switch(on: $on)
        }
    }

    /// What the choice is, and the line under it: faint, or the darker grey when plain, for a line that must be read.
    private var labels: some View {
        VStack(alignment: .leading, spacing: Space.hair.rawValue) {
            Text(title).foregroundStyle(Role.ink).font(.system(size: 13.5))
            Text(detail).type(.detail).foregroundStyle(plain ? Role.muted : Role.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
