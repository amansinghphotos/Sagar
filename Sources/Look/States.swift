// The states a page can be in other than showing its content: nothing here yet, something went wrong, and work
// under way.
import SwiftUI

/// A quiet line where a list would be, when there is nothing in it yet.
package struct Nothing: View {
    private let text: String

    package init(_ text: String) { self.text = text }

    package var body: some View {
        Text(text).type(.body).foregroundStyle(Role.muted)
            .padding(EdgeInsets(top: 18, leading: Space.wide.rawValue, bottom: 18, trailing: Space.wide.rawValue))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// What went wrong, centred on the page: the first line in ink, a hint under it if the message has a second, and
/// a way to try again.
package struct Trouble: View {
    private let message: String
    private let retry: () -> Void

    package init(message: String, retry: @escaping () -> Void) {
        (self.message, self.retry) = (message, retry)
    }

    package var body: some View {
        VStack(spacing: Space.gap.rawValue) {
            wording
            again
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Role.ground)
    }

    /// The message: its first line, and what follows the first break as a quieter hint.
    private var wording: some View {
        let lines = message.split(separator: "\n", maxSplits: 1)
        return VStack(spacing: Space.tight.rawValue) {
            Text(lines.first.map(String.init) ?? message).font(.system(size: 14)).foregroundStyle(Role.ink)
            if let hint = lines.dropFirst().first {
                Text(hint).type(.row).foregroundStyle(Role.muted)
            }
        }
    }

    private var again: some View {
        Button(action: retry) { Text(verbatim: "Try again").type(.row).foregroundStyle(Role.muted) }
            .buttonStyle(.plain)
    }
}

/// A card for long work under way: what it is, what it is doing, a bar for how far it has come, the count, and
/// a way to stop. With no total known, the bar stays empty and there is no count. Once asked to stop, the button
/// says so and can't be pressed again. VoiceOver reads it as one thing: the name and what it is doing.
package struct ProgressCard: View {
    private let filename: String
    private let message: String
    private let completed: Int
    private let total: Int?
    private let cancelling: Bool
    private let cancel: () -> Void

    package init(
        filename: String, message: String, completed: Int, total: Int?,
        cancelling: Bool = false, cancel: @escaping () -> Void
    ) {
        (self.filename, self.message) = (filename, message)
        (self.completed, self.total) = (completed, total)
        (self.cancelling, self.cancel) = (cancelling, cancel)
    }

    /// The whole the count is out of, when one is known.
    private var whole: Int? { total.flatMap { $0 > 0 ? $0 : nil } }

    package var body: some View {
        let outline = RoundedRectangle(cornerRadius: 12, style: .continuous)
        VStack(alignment: .leading, spacing: 7) {
            heading
            bar
            footing
        }
        .padding(Space.wide.rawValue)
        .frame(width: 250, alignment: .leading)
        .background(Role.ground, in: outline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(filename), \(message)")
        .overlay(outline.strokeBorder(Role.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 5)
        .padding(20)
        .transition(.opacity)
    }

    /// The name of what is being worked on, cut in its middle, and what is being done to it, on one line each.
    @ViewBuilder private var heading: some View {
        Text(filename).type(.body).fontWeight(.medium).foregroundStyle(Role.ink).lineLimit(1).truncationMode(.middle)
        Text(message).type(.row).foregroundStyle(Role.muted).lineLimit(1)
    }

    /// How far the work has come, as a filled part of a thin track; an empty track while the whole is unknown.
    private var bar: some View {
        Capsule()
            .foregroundStyle(Role.hairline)
            .overlay(alignment: .leading) {
                if let whole {
                    GeometryReader { track in
                        Capsule().fill(Role.ink.opacity(0.7))
                            .frame(width: track.size.width * min(1, Double(completed) / Double(whole)))
                    }
                }
            }
            .frame(height: 3)
    }

    /// The count, when the whole is known, and the button to stop at the far end.
    private var footing: some View {
        HStack {
            if let whole {
                Text("\(completed.formatted()) of \(whole.formatted())")
                    .font(.system(size: 11))
                    .foregroundStyle(Role.muted)
            }
            Spacer(minLength: .zero)
            stopButton
        }
    }

    /// Cancel, in a faint capsule; once pressed, it says it is cancelling and can't be pressed again.
    private var stopButton: some View {
        Button(action: cancel) {
            Text(verbatim: cancelling ? "Cancelling…" : "Cancel").type(.row).foregroundStyle(Role.ink)
                .padding(.horizontal, Space.gap.rawValue)
                .frame(height: 22)
                .background { Capsule().fill(Role.ink.opacity(0.07)) }
        }
        .disabled(cancelling)
        .buttonStyle(.plain)
    }
}
