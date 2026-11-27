// Taken from Search at commit c92ea7c: its welcome's frame, heading, foot, Big and Choice (Welcome.swift).
// Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed only where this repository's
// rules require: Search's colours and motion are read from Look; its pages, which are Search's own, are given
// by whoever uses it; and the page to open at is set when the welcome is made, not when it appears.
import SwiftUI

/// The pages a person sees the first time an app opens: one at a time, on the
/// ground, with dots for where they are, Back, Skip, and Continue until the last.
package struct Welcome<Page: View>: View {
    let pages: Int
    /// What the last page's button says, such as "Start browsing".
    let last: String
    let finish: () -> Void
    @ViewBuilder let page: (Int) -> Page

    @Environment(\.motion) private var motion
    @State private var index: Int
    @State private var forward = true

    package init(
        pages: Int, last: String, startPage: Int = 0, finish: @escaping () -> Void,
        @ViewBuilder page: @escaping (Int) -> Page
    ) {
        self.pages = pages
        self.last = last
        self.finish = finish
        self.page = page
        _index = State(initialValue: min(startPage, pages - 1))
    }

    package var body: some View {
        ZStack {
            Rectangle().fill(Role.ground).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack {
                    page(index)
                }
                .frame(maxWidth: 520)
                .id(index)
                .transition(
                    .asymmetric(
                        insertion: .offset(x: forward ? 40 : -40).combined(with: .opacity),
                        removal: .offset(x: forward ? -40 : 40).combined(with: .opacity)
                    ))
                Spacer(minLength: 0)
                foot
            }
            .padding(40)
        }
        .animation(motion.glide, value: index)
        .transition(.opacity)
    }

    private var foot: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0..<pages, id: \.self) { i in
                    Circle()
                        .fill(i == index ? AnyShapeStyle(Role.ink) : AnyShapeStyle(Role.faint.opacity(0.6)))
                        .frame(width: 6, height: 6)
                }
            }
            Spacer()
            if index > 0 {
                Button("Back") {
                    forward = false
                    index -= 1
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Role.muted)
            }
            if index < pages - 1 {
                Button("Skip") { finish() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Role.muted)
            }
            Big(index < pages - 1 ? "Continue" : last, filled: true) {
                if index < pages - 1 {
                    forward = true
                    index += 1
                } else {
                    finish()
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: 520)
    }
}

/// A welcome page's heading: what it is about, and a line on it.
package struct WelcomeHeading: View {
    let title: String
    let line: String

    package init(_ title: String, _ line: String) {
        self.title = title
        self.line = line
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Role.ink)
            Text(line)
                .font(.system(size: 14))
                .foregroundStyle(Role.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A welcome's large button.
package struct Big: View {
    let title: String
    var filled = false
    let act: () -> Void
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
                .padding(.vertical, 9)
                .background(filled ? Role.ink : (hovering ? Role.hover : Role.wash), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// A choice on a welcome page: what it is, a line on it, and its switch.
package struct Choice: View {
    let title: String
    let detail: String
    @Binding var on: Bool
    /// The line under in the darker grey, for one that must be read.
    var plain = false

    package init(_ title: String, _ detail: String, on: Binding<Bool>, plain: Bool = false) {
        self.title = title
        self.detail = detail
        _on = on
        self.plain = plain
    }

    package var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13.5)).foregroundStyle(Role.ink)
                Text(detail).font(.system(size: 11.5)).foregroundStyle(plain ? Role.muted : Role.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Switch(on: $on)
        }
    }
}
