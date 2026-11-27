// Toasts and banners: a line of words that shows for a moment at the foot of a screen, and a question with its answers.
import SwiftUI

/// Words waiting to be shown as toasts: one at a time, first come first shown.
nonisolated package struct ToastQueue: Equatable, Sendable {
    /// How long each toast stays, in seconds.
    package static let stays = 2.5

    /// The words in line, the one showing first.
    private var line: [String] = []

    package init() {}

    /// The words showing now, if any.
    package var current: String? { line.first }

    /// Puts words in line, unless the same words are already last in line.
    package mutating func show(_ words: String) {
        if line.last == words { return }
        line.append(words)
    }

    /// Lets the words showing now go, and the next in line show.
    package mutating func next() {
        line = Array(line.dropFirst())
    }
}

extension View {
    /// Shows the queue's words over this view, at its foot, each for `ToastQueue.stays` seconds.
    package func toasts(_ queue: Binding<ToastQueue>) -> some View {
        overlay { ToastLayer(queue: queue) }
    }
}

/// The layer a toast lies in: its foot-left corner, through which every click passes to what lies under it.
private struct ToastLayer: View {
    @Binding var queue: ToastQueue
    @Environment(\.motion) private var motion

    var body: some View {
        GeometryReader { room in
            ZStack(alignment: .bottomLeading) {
                Color.clear
                if let words = queue.current {
                    // A long line is cut in its middle, so it never covers more than part of the view.
                    Toast(words: words, widest: min(room.size.width * 0.6, 640))
                        .padding(Space.gap.rawValue)
                        .transition(.opacity)
                        .task(id: words) { await wait() }
                }
            }
        }
        .allowsHitTesting(false)
        .animation(motion.timed(.easeOut(duration: 0.12)), value: queue.current == nil)
    }

    /// Lets the toast have its moment, then the next in line its own. A toast whose view goes away is let go too.
    private func wait() async {
        try? await Task.sleep(for: .seconds(ToastQueue.stays))
        queue.next()
    }
}

/// One toast: its words in a small floating capsule, never wider than `widest`.
private struct Toast: View {
    let words: String
    let widest: CGFloat

    var body: some View {
        let capsule = Capsule()
        Text(words)
            .type(.row)
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(Role.ink)
            .frame(height: Self.height)
            .padding(.horizontal, Self.inset)
            .background(capsule.fill(Role.ground))
            .overlay(capsule.strokeBorder(Role.hairline, lineWidth: 1))
            .elevation(.status)
            .frame(maxWidth: widest, alignment: .leading)
    }

    /// How tall the capsule stands, and how far its words keep from its ends, in points.
    static let height: CGFloat = 26
    static let inset: CGFloat = 11
}

/// A question over the page: an icon and its words, then a main answer, perhaps another, and one to say no.
/// Where it is too narrow for one line, its answers go under its words, and then under each other.
package struct Banner: View {
    private let icon: String
    private let question: String
    private let answers: [Answer]

    package init(
        icon: String, question: String, yes: (String, () -> Void), maybe: (String, () -> Void)? = nil,
        no: (String, () -> Void)
    ) {
        var answers = [Answer(kind: .main, words: yes.0, act: yes.1)]
        if let maybe { answers.append(Answer(kind: .other, words: maybe.0, act: maybe.1)) }
        answers.append(Answer(kind: .no, words: no.0, act: no.1))
        self.answers = answers
        self.question = question
        self.icon = icon
    }

    package var body: some View {
        // The first arrangement whose width fits is drawn: all on one line, the answers in a row under the
        // words, or the answers one under another.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.apart.rawValue) {
                asked
                answerLine(stacked: false)
            }
            .fixedSize()
            under(answerLine(stacked: false).fixedSize())
            under(answerLine(stacked: true))
        }
        .padding(.vertical, 9)
        .padding(.leading, Space.page.rawValue)
        .padding(.trailing, Space.gap.rawValue)
        .background(plate.fill(Role.ground))
        .overlay(plate.strokeBorder(Role.hairline, lineWidth: 1))
        .elevation(.banner)
    }

    /// The banner's outline.
    private var plate: RoundedRectangle { RoundedRectangle(cornerRadius: 20) }

    /// The icon, then the question, which wraps when it must.
    private var asked: some View {
        HStack(spacing: Space.apart.rawValue) {
            Image(systemName: icon)
                .type(.label)
                .foregroundStyle(Role.muted)
            Text(question)
                .foregroundStyle(Role.ink)
                .font(.system(size: 12.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The words above, the answers below. The words ask for no width of their own when the arrangements are
    /// weighed, so only the answers decide which of the two below fits; drawn, they wrap to the width there is.
    private func under(_ answers: some View) -> some View {
        VStack(alignment: .leading, spacing: Space.apart.rawValue) {
            asked.frame(idealWidth: 0)
            answers
        }
    }

    /// The answers side by side, or one under another.
    private func answerLine(stacked: Bool) -> some View {
        let layout =
            stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.gap.rawValue))
            : AnyLayout(HStackLayout(spacing: Space.apart.rawValue))
        return layout {
            ForEach(answers.indices, id: \.self) { answers[$0] }
        }
    }
}

/// One of a banner's answers: the main one in a filled capsule, the others as plain words.
private struct Answer: View {
    enum Kind { case main, other, no }

    let kind: Kind
    let words: String
    let act: () -> Void

    var body: some View {
        Button(action: act) { label }
            .buttonStyle(.plain)
    }

    @ViewBuilder private var label: some View {
        let text = Text(words).type(.row)
        switch kind {
        case .main:
            text
                .foregroundStyle(Role.ground)
                .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
                .background(Capsule().fill(Role.ink))
        case .other:
            text.foregroundStyle(Role.ink)
        case .no:
            text.foregroundStyle(Role.muted)
        }
    }
}
