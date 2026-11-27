import Look
import SwiftUI

/// The States page: the first-open pages, as Search's welcome has them.
struct States: View {
    @State private var keep = true
    @State private var login = false

    var body: some View {
        Welcome(
            pages: 3, last: "Start", startPage: 1, finish: {},
            page: { _ in
                VStack(alignment: .leading, spacing: 22) {
                    WelcomeHeading(
                        "Keep what you copy.", "Everything you copy is kept on this Mac, so you can find it again.")
                    VStack(alignment: .leading, spacing: 14) {
                        Choice("Paste for you", "Asks once, in System Settings.", on: $keep, plain: true)
                        Rule(inset: 0)
                        Choice("Open at login", "So it is there from the start.", on: $login)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Role.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        )
        .frame(width: 640, height: 400)
        .overlay(Rectangle().stroke(Role.hairline))
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
