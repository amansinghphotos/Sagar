// The capsule is taken from Search at commit c92ea7c: LinkBubble (StatusLine.swift), which shows a link's
// address at the page's foot. Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md). Changed
// only where this repository's rules require: Search's colours and motion are read from Look. Search has no
// toast, so the queue, and how long each stays, are written fresh.
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
        .allowsHitTesting(false)
        .animation(motion.timed(.easeOut(duration: 0.12)), value: queue.current == nil)
    }
}
