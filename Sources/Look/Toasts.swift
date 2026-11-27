// The capsule is taken from Search at commit c92ea7c: LinkBubble (StatusLine.swift), which shows a link's
// address at the page's foot. Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed
// only where this repository's rules require: Search's colours and motion are read from Look. Search has no
// toast, so the queue, and how long each stays, are written fresh. The banner is Search's CaptureQuestion
// (PageQuestions.swift), its icon, words and answers given.
import SwiftUI

/// Words that show for a moment, one at a time, in the order they came.
nonisolated package struct ToastQueue: Equatable, Sendable {
    /// How long each stays, in seconds.
    package static let stays: Double = 2.5

    private var waiting: [String] = []

    package init() {}

    /// What shows now, if anything.
    package var current: String? { waiting.first }

    /// Words to show after any before them. The same words twice in a row show once.
    package mutating func show(_ words: String) {
        guard waiting.last != words else { return }
        waiting.append(words)
    }

    /// The one showing has had its moment.
    package mutating func next() {
        if !waiting.isEmpty { waiting.removeFirst() }
    }
}

extension View {
    /// Shows the queue's toasts at this view's foot, one at a time, each for `ToastQueue.stays`.
    package func toasts(_ queue: Binding<ToastQueue>) -> some View {
        overlay { ToastStand(queue: queue) }
    }
}

private struct ToastStand: View {
    @Binding var queue: ToastQueue
    @Environment(\.motion) private var motion

    var body: some View {
        GeometryReader { space in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                if let words = queue.current {
                    HStack(spacing: 0) {
                        Text(words)
                            .font(.system(size: 12))
                            .foregroundStyle(Role.ink)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 11)
                            .frame(height: 26)
                            .background(Role.ground, in: Capsule())
                            .overlay(Capsule().strokeBorder(Role.hairline, lineWidth: 1))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 3)
                            .frame(maxWidth: min(space.size.width * 0.6, 640), alignment: .leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
                    .transition(.opacity)
                    .task(id: words) {
                        try? await Task.sleep(for: .seconds(ToastQueue.stays))
                        queue.next()
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .animation(motion.timed(.easeOut(duration: 0.12)), value: queue.current == nil)
    }
}

/// A question over the page, as Search asks one: its icon and words, then a
/// filled answer, an optional second, and No. It stacks when it is narrow.
/// Taken from Search's CaptureQuestion (PageQuestions.swift), its icon, words and answers given.
package struct Banner: View {
    let icon: String
    let question: String
    let yes: (String, () -> Void)
    var maybe: (String, () -> Void)? = nil
    let no: (String, () -> Void)

    package init(
        icon: String, question: String, yes: (String, () -> Void), maybe: (String, () -> Void)? = nil,
        no: (String, () -> Void)
    ) {
        self.icon = icon
        self.question = question
        self.yes = yes
        self.maybe = maybe
        self.no = no
    }

    package var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                words
                actions
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: 12) {
                words
                ViewThatFits(in: .horizontal) {
                    actions.fixedSize()
                    VStack(alignment: .leading, spacing: 10) { buttons }
                }
            }
        }
        .font(.system(size: 12))
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .padding(.vertical, 9)
        .background(Role.ground, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Role.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 6)
    }

    private var words: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Role.muted)
            Text(question)
                .font(.system(size: 12.5))
                .foregroundStyle(Role.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        HStack(spacing: 12) { buttons }
    }

    @ViewBuilder
    private var buttons: some View {
        Button(action: yes.1) {
            Text(yes.0)
                .foregroundStyle(Role.ground)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Role.ink, in: Capsule())
        }
        if let maybe {
            Button(maybe.0, action: maybe.1)
                .foregroundStyle(Role.ink)
        }
        Button(no.0, action: no.1)
            .foregroundStyle(Role.muted)
    }
}
