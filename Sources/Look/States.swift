// The states a page can be in besides full: nothing here yet, something went wrong, and work under way.
import SwiftUI

/// A quiet line where a list would be, when there is nothing in it yet.
package struct Nothing: View {
    private let text: String

    package init(_ text: String) { self.text = text }

    package var body: some View {
        Text(text)
            .type(.body)
            .foregroundStyle(Role.muted)
            .padding(.horizontal, Space.wide.rawValue)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// What went wrong, centred: the first line in ink, the rest quieter, and a way to try again.
package struct Trouble: View {
    private let message: String
    private let retry: () -> Void

    package init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    package var body: some View {
        let lines = message.split(separator: "\n", maxSplits: 1).map(String.init)
        VStack(spacing: Space.tight.rawValue) {
            Text(lines.first ?? "").font(.system(size: 14)).foregroundStyle(Role.ink)
            if lines.count > 1 {
                Text(lines[1]).type(.row).foregroundStyle(Role.muted)
            }
            Button(action: retry) {
                Text(verbatim: "Try again").type(.row).foregroundStyle(Role.muted)
            }
            .buttonStyle(.plain)
            .padding(.top, Space.snug.rawValue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Role.ground)
    }
}

/// A card for long work under way: what it is, what it is doing, a bar for how far it has come, the count, and
/// a way to stop. With no total known, the bar stays empty and there is no count. Once asked to stop, the button
/// says so and can't be pressed again. VoiceOver reads it as one thing: the name and what it is doing.
package struct ProgressCard: View {
    @Environment(\.greys) private var greys
    private let filename: String
    private let message: String
    private let completed: Int
    private let total: Int?
    private let cancelling: Bool
    private let cancel: () -> Void

    package init(
        filename: String, message: String, completed: Int, total: Int?, cancelling: Bool = false,
        cancel: @escaping () -> Void
    ) {
        self.filename = filename
        self.message = message
        self.completed = completed
        self.total = total
        self.cancelling = cancelling
        self.cancel = cancel
    }

    /// The whole the count is out of, when one is known.
    private var whole: Int? { total.flatMap { $0 > 0 ? $0 : nil } }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card.rawValue, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            Text(filename).type(.body).fontWeight(.medium).foregroundStyle(Role.ink)
                .lineLimit(1).truncationMode(.middle)
            Text(message).type(.row).foregroundStyle(Role.muted).lineLimit(1).padding(.top, 7)
            bar.padding(.top, 7)
            HStack {
                if let whole {
                    Text("\(completed.formatted()) of \(whole.formatted())")
                        .font(.system(size: 11)).foregroundStyle(Role.muted)
                }
                Spacer(minLength: 0)
                Button(action: cancel) {
                    Text(verbatim: cancelling ? "Cancelling…" : "Cancel").type(.row).foregroundStyle(Role.ink)
                        .padding(.horizontal, Space.gap.rawValue)
                        .frame(height: 22)
                        .background(greys.wash, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(cancelling)
            }
            .padding(.top, 7)
        }
        .padding(Space.wide.rawValue)
        .frame(width: 250)
        .background(Role.ground, in: shape)
        .overlay(shape.strokeBorder(Role.hairline, lineWidth: 1))
        .elevation(.status)
        .padding(20)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(filename), \(message)")
    }

    /// How far the work has come, as a filled part of a thin track; an empty track while the whole is unknown.
    private var bar: some View {
        Capsule()
            .fill(Role.hairline)
            .overlay(alignment: .leading) {
                if let whole {
                    GeometryReader { space in
                        Capsule().fill(Role.ink.opacity(0.7))
                            .frame(width: space.size.width * min(1, max(0, Double(completed) / Double(whole))))
                    }
                }
            }
            .frame(height: 3)
    }
}
