// The first-open pages: the frame that steps through them, their heading, big buttons and choice rows.
import SwiftUI

/// Pages shown the first time an app opens, one at a time: the page in the middle, and along the foot a dot for each
/// page, then Back, Skip and a filled button that goes on, or finishes on the last page.
package struct Welcome<Page: View>: View {
    @Environment(\.motion) private var motion
    private let pages: Int
    private let last: String
    private let finish: () -> Void
    private let page: (Int) -> Page
    @State private var index: Int
    /// Whether the last step went on rather than back, so the pages slide the way the person went.
    @State private var forward = true

    package init(
        pages: Int, last: String, startPage: Int = 0, finish: @escaping () -> Void,
        @ViewBuilder page: @escaping (Int) -> Page
    ) {
        self.pages = pages
        self.last = last
        self.finish = finish
        self.page = page
        _index = State(initialValue: min(max(startPage, 0), max(pages - 1, 0)))
    }

    private var onLast: Bool { index >= pages - 1 }

    package var body: some View {
        VStack(spacing: 0) {
            ZStack {
                page(index)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(index)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(x: forward ? 40 : -40)),
                            removal: .opacity.combined(with: .offset(x: forward ? -40 : 40))))
            }
            .frame(maxHeight: .infinity)
            foot
        }
        .frame(maxWidth: 520)
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Role.ground)
        .animation(motion.glide, value: index)
        .transition(.opacity)
    }

    private var foot: some View {
        HStack(spacing: 14) {
            dots
            Spacer(minLength: 0)
            if index > 0 {
                quiet("Back") {
                    forward = false
                    index -= 1
                }
            }
            if !onLast { quiet("Skip", act: finish) }
            Big(onLast ? last : "Continue", filled: true) {
                if onLast {
                    finish()
                } else {
                    forward = true
                    index += 1
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(height: 34)
    }

    /// Back and Skip: words only, in the quieter grey.
    private func quiet(_ title: String, act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(title).type(.body).foregroundStyle(Role.muted)
        }
        .buttonStyle(.plain)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages, id: \.self) { dot in
                Circle()
                    .fill(dot == index ? AnyShapeStyle(Role.ink) : AnyShapeStyle(Role.faint.opacity(0.6)))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(index + 1) of \(pages)")
    }
}

/// The big line a first-open page opens with, and the quieter sentence under it.
package struct WelcomeHeading: View {
    private let title: String
    private let line: String

    package init(_ title: String, _ line: String) {
        self.title = title
        self.line = line
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .type(.display)
                .foregroundStyle(Role.ink)
                .accessibilityAddTraits(.isHeader)
            Text(line)
                .font(.system(size: 14))
                .lineSpacing(2)
                .foregroundStyle(Role.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A first-open page's large button: a capsule in ink when filled, otherwise a soft grey one that lightens under the
/// pointer.
package struct Big: View {
    private let title: String
    private let filled: Bool
    private let act: () -> Void
    @State private var hovering = false

    package init(_ title: String, filled: Bool = false, act: @escaping () -> Void) {
        self.title = title
        self.filled = filled
        self.act = act
    }

    package var body: some View {
        Button(action: act) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(filled ? Role.ground : Role.ink)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(filled ? Role.ink : hovering ? Role.hover : Role.wash, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// A row a first-open page offers: what it is, a line on what it does, and a switch. The line is faint, or in the
/// darker grey when the row is plain, for a line that must be read.
package struct Choice: View {
    private let title: String
    private let detail: String
    @Binding private var on: Bool
    private let plain: Bool

    package init(_ title: String, _ detail: String, on: Binding<Bool>, plain: Bool = false) {
        self.title = title
        self.detail = detail
        _on = on
        self.plain = plain
    }

    package var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Role.ink)
                Text(detail)
                    .type(.detail)
                    .foregroundStyle(plain ? Role.muted : Role.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Switch(on: $on)
                .accessibilityLabel(title)
        }
    }
}
