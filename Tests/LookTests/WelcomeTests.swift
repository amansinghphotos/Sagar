import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// Search's welcome frame, heading, foot, big button and choice rows, on a stand-in page: a heading and two
/// choices in a card, on the second of four pages. The same stand-in page, built from Search's own code for those
/// parts at commit c92ea7c by a scratch copy that uses this repository's picture harness, was pictured into
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

// How the welcome moves. A still picture cannot show it, so each movement is recorded through time.

/// Each movement, recorded every 120th of a second: it starts where it was, comes to rest within its time, and
/// never swings further than a fifth past where it ends.
@Test(arguments: [("arrival", 0.6), ("turn", 0.6), ("leaving", 0.2)])
func eachMovementComesToRestInItsTime(name: String, seconds: Double) throws {
    let moves = WelcomeMoves(motion: Motion(reduceMotion: false))
    let animation = try #require(["arrival": moves.arrival, "turn": moves.turn, "leaving": moves.leaving][name] ?? nil)
    let record = trace(animation, seconds: seconds)
    #expect(try abs(#require(record.first)) <= 0.01)
    #expect(try abs(#require(record.last) - 1) <= 0.02, "\(name) is not at rest after \(seconds) s")
    #expect(record.allSatisfy { $0 <= 1.2 }, "\(name) swings too far")
}

/// Leaving is quicker than arriving, and the app's own touch on the first page comes a beat after its page.
@Test func itLeavesQuickerThanItArrivesAndTheTouchComesABeatLater() {
    let moves = WelcomeMoves(motion: Motion(reduceMotion: false))
    #expect(moves.away > 0 && moves.away < 0.35)
    #expect(moves.touchWaits > 0 && moves.touchWaits < moves.away + 0.1)
}

/// Under Reduce Motion, and under the app's own Reduce animations, nothing moves and nothing waits.
@Test(arguments: [Motion(reduceMotion: true), Motion(reduceMotion: false, instant: true)])
func underReduceMotionEachIsAtOnce(motion: Motion) {
    let moves = WelcomeMoves(motion: motion)
    #expect(moves.arrival == nil && moves.turn == nil && moves.leaving == nil)
    #expect(moves.away == 0 && moves.touchWaits == 0)
}
