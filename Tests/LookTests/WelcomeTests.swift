import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// The second of four pages of Search's welcome: a heading, two choices in a card, and the foot with its dots,
/// Back, Skip and Continue. The same page was pictured from Search's own code at commit c92ea7c, lifted out of
/// its welcome by a scratch copy that uses this repository's picture harness, into
/// `Fixtures/Search Welcome Light.png` and `Dark.png`.
private struct Showcase: View {
    @State var a = true
    @State var b = false

    var body: some View {
        Welcome(
            pages: 4, last: "Start browsing", startPage: 1, finish: {},
            page: { _ in
                VStack(alignment: .leading, spacing: 22) {
                    WelcomeHeading(
                        "Bring things over.",
                        "Passwords go into your keychain, bookmarks into the menu, and history means the address field already knows where you go."
                    )
                    VStack(alignment: .leading, spacing: 14) {
                        Choice("Passwords", "Into your keychain.", on: $a, plain: true)
                        Rule(inset: 0)
                        Choice("History", "So the address field knows where you go.", on: $b)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Role.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            })
    }
}

@Test(arguments: [false, true])
func theWelcomeLooksAsSearchsDoes(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Welcome \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    let ours = try picture(of: Showcase(), width: 640, height: 480, dark: dark)
    #expect(differingPixels(ours, search) <= tolerance)
}
