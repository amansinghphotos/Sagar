// Taken from Search at commit c92ea7c: Nothing (Plate.swift), Trouble (Stage.swift) and ImportProgress
// (App.swift), the last as ProgressCard. Copyright (c) 2026 Office Commun, MIT licence (ACKNOWLEDGEMENTS.md).
// Changed only where this repository's rules require: Search's colours are read from Look, and the progress
// card's file name, message, count and Cancel are given instead of read from Search's own import.
import SwiftUI

/// What a panel says when its list is empty.
package struct Nothing: View {
    let text: String
    package init(_ text: String) { self.text = text }
    package var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Role.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
    }
}

/// What there is to say when the page never came. One line, and the only thing
/// worth offering — another go. A second line in the message is a hint,
/// drawn smaller under it.
package struct Trouble: View {
    let message: String
    let retry: () -> Void

    package init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    package var body: some View {
        let lines = message.split(separator: "\n", maxSplits: 1).map(String.init)
        VStack(spacing: 10) {
            VStack(spacing: 4) {
                Text(lines.first ?? message)
                    .font(.system(size: 14))
                    .foregroundStyle(Role.ink)
                if lines.count > 1 {
                    Text(lines[1])
                        .font(.system(size: 12))
                        .foregroundStyle(Role.muted)
                }
            }
            Button("Try again", action: retry)
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Role.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Role.ground)
    }
}

/// Something long being done in the background: its name, how far it
/// has got, and Cancel — in the corner, in the quiet grey of everything
/// else that floats over the page.
package struct ProgressCard: View {
    let filename: String
    let message: String
    let completed: Int
    let total: Int?
    var cancelling = false
    let cancel: () -> Void

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

    private var fraction: CGFloat? {
        guard let total, total > 0 else { return nil }
        return min(1, CGFloat(completed) / CGFloat(total))
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(filename)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Role.ink)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Role.muted)
                .lineLimit(1)
            bar
            footer
        }
        .padding(14)
        .frame(width: 250, alignment: .leading)
        .background(Role.ground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Role.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 5)
        .padding(20)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(filename), \(message)")
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Role.hairline)
                if let fraction {
                    Capsule().fill(Role.ink.opacity(0.7)).frame(width: geo.size.width * fraction)
                }
            }
        }
        .frame(height: 3)
    }

    private var footer: some View {
        HStack {
            if let total, total > 0 {
                Text("\(completed.formatted()) of \(total.formatted())")
                    .font(.system(size: 11))
                    .foregroundStyle(Role.muted)
            }
            Spacer(minLength: 0)
            Button(action: cancel) {
                Text(cancelling ? "Cancelling…" : "Cancel")
                    .font(.system(size: 12))
                    .foregroundStyle(Role.ink)
                    .padding(.horizontal, 10)
                    .frame(height: 22)
                    .background(Role.ink.opacity(0.07), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(cancelling)
        }
    }
}
