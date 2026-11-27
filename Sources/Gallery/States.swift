import Look
import SwiftUI

/// The States page: the first-open pages, built from Search's welcome on a stand-in page, and the About window.
struct States: View {
    @State private var keep = true
    @State private var login = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Welcome(
                pages: 3, last: "Start", startPage: 1, finish: {},
                page: { _ in
                    VStack(alignment: .leading, spacing: 22) {
                        WelcomeHeading(
                            "Keep what you copy.", "Everything you copy stays on this Mac. Find it again any time.")
                        VStack(alignment: .leading, spacing: 14) {
                            Choice("Paste for you", "Your Mac asks once.", on: $keep, plain: true)
                            Rule(inset: 0)
                            Choice("Open at login", "Chete starts when you log in.", on: $login)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Role.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            )
            .frame(width: 500, height: 400)
            .overlay(Rectangle().stroke(Role.hairline))
            .padding(Space.page.rawValue)
            AboutBox(
                icon: Image(systemName: "doc.on.clipboard"), name: "Chete", version: "Version 1.1",
                copyright: "© Sagar",
                whatsNew: {}
            )
            .overlay(Rectangle().stroke(Role.hairline))
            .padding(Space.page.rawValue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
