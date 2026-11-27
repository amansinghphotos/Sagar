// Toasts and banners: a line of words that shows for a moment at the foot of a screen, and a question with its answers.
import SwiftUI

/// Words waiting to be shown as toasts: one at a time, first come first shown.
nonisolated package struct ToastQueue: Equatable, Sendable {
    /// How long each toast stays, in seconds.
    package static let stays: Double = 2.5

    private var waiting: [String] = []

    package init() {}

    /// The words showing now, if any.
    package var current: String? { waiting.first }

    /// Puts words in line, unless the same words are already last in line.
    package mutating func show(_ words: String) {
        guard waiting.last != words else { return }
        waiting.append(words)
    }

    /// Lets the words showing now go, and the next in line show.
    package mutating func next() {
        guard !waiting.isEmpty else { return }
        waiting.removeFirst()
    }
}

extension View {
    /// Shows the queue's words over this view, at its foot, each for `ToastQueue.stays` seconds.
    package func toasts(_ queue: Binding<ToastQueue>) -> some View {
        modifier(Toasting(queue: queue))
    }
}

/// Lays the current toast over a view, and moves the queue on when its time is up.
private struct Toasting: ViewModifier {
    @Environment(\.motion) private var motion
    @Binding var queue: ToastQueue

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomLeading) {
                if let words = queue.current {
                    Toast(words: words)
                        .padding(Space.gap.rawValue)
                        .transition(.opacity)
                        .task(id: words) {
                            try? await Task.sleep(for: .seconds(ToastQueue.stays))
                            guard !Task.isCancelled else { return }
                            queue.next()
                        }
                }
            }
            .animation(motion.timed(.easeOut(duration: 0.12)), value: queue.current == nil)
    }
}

/// One toast: its words in a small floating capsule.
private struct Toast: View {
    let words: String

    var body: some View {
        Text(words)
            .type(.row)
            .foregroundStyle(Role.ink)
            .padding(.horizontal, 11)
            .frame(height: 26)
            .background(Capsule().fill(Role.ground))
            .overlay(Capsule().strokeBorder(Role.hairline, lineWidth: 1))
            .elevation(.status)
    }
}

/// A question over the page: an icon and its words, then a main answer, another, and one to say no.
package struct Banner: View {
    private let icon: String
    private let question: String
    private let yes: (String, () -> Void)
    private let maybe: (String, () -> Void)
    private let no: (String, () -> Void)

    package init(
        icon: String, question: String, yes: (String, () -> Void), maybe: (String, () -> Void),
        no: (String, () -> Void)
    ) {
        self.icon = icon
        self.question = question
        self.yes = yes
        self.maybe = maybe
        self.no = no
    }

    package var body: some View {
        HStack(spacing: Space.apart.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Role.muted)
            Text(question)
                .font(.system(size: 12.5))
                .foregroundStyle(Role.ink)
            Answer(words: yes.0, ink: .ground, filled: true, act: yes.1)
            Answer(words: maybe.0, ink: .ink, act: maybe.1)
            Answer(words: no.0, ink: .muted, act: no.1)
        }
        .padding(.leading, Space.page.rawValue)
        .padding(.trailing, Space.gap.rawValue)
        .frame(height: 43)
        .background(Capsule().fill(Role.ground))
        .overlay(Capsule().strokeBorder(Role.hairline, lineWidth: 1))
        .elevation(.banner)
    }
}

/// One of a banner's answers: plain words, or words on a filled capsule for the main one.
private struct Answer: View {
    let words: String
    let ink: Role
    var filled = false
    let act: () -> Void

    var body: some View {
        Button(action: act) {
            Text(words)
                .type(.row)
                .foregroundStyle(ink)
                .padding(.horizontal, filled ? 11 : 0)
                .frame(height: 25)
                .background {
                    if filled { Capsule().fill(Role.ink) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
