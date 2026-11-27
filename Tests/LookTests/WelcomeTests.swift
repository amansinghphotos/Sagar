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

nonisolated private let moving = WelcomeMoves(motion: Motion(reduceMotion: false))

/// When a record, taken every 120th of a second, comes within two hundredths of rest and stays there.
private func settles(_ record: [Double]) -> TimeInterval {
    Double((record.lastIndex { abs($0 - 1) > 0.02 } ?? -1) + 1) / 120
}

/// Each movement starts where it was, comes to rest within its time, and never swings a fifth past rest.
@Test(arguments: [("arrival", moving.arrival, 0.6), ("turn", moving.turn, 0.6), ("leaving", moving.leaving, 0.2)])
func eachMovementComesToRestInItsTime(name: String, animation: Animation?, seconds: Double) throws {
    let record = try trace(#require(animation), seconds: seconds)
    #expect(try abs(#require(record.first)) <= 0.01)
    #expect(settles(record) < seconds, "\(name) is not at rest after \(seconds) s")
    #expect(record.allSatisfy { $0 <= 1.2 }, "\(name) swings too far")
}

/// Leaving comes to rest sooner than arriving does, and the app is told only once the fade has run.
@Test func itLeavesQuickerThanItArrives() throws {
    let leaving = try settles(trace(#require(moving.leaving), seconds: 0.6))
    #expect(leaving < settles(trace(try #require(moving.arrival), seconds: 0.6)))
    #expect(moving.away >= leaving - 1.0 / 120)
}

/// The app's touch arrives as its page does, a beat later: still clear when the page is a third of the way in.
@Test func theTouchComesABeatAfterItsPage() throws {
    #expect(moving.touchArrival == moving.arrival?.delay(moving.touchWaits))
    let page = try trace(#require(moving.arrival), seconds: 0.6)
    let touch = page.indices.map { $0 < Int(moving.touchWaits * 120) ? 0 : page[$0 - Int(moving.touchWaits * 120)] }
    let third = try #require(page.firstIndex { $0 >= 1.0 / 3 })
    #expect(touch[third] == 0)
    #expect(settles(touch) < 0.6 + moving.touchWaits)
}

/// The touch shows on the first page, and nowhere else.
@Test @MainActor func theTouchShowsOnTheFirstPageOnly() throws {
    func welcome(on page: Int, touch: Bool) throws -> CGImage {
        try picture(
            of: Welcome(
                pages: 2, last: "Start", startPage: page, finish: {}, page: { _ in Text("A page") },
                touch: { if touch { Text("ਚੇਤੇ").font(.largeTitle) } }),
            width: 640, height: 480)
    }
    #expect(try differingPixels(welcome(on: 0, touch: true), welcome(on: 0, touch: false)) > tolerance)
    #expect(try differingPixels(welcome(on: 1, touch: true), welcome(on: 1, touch: false)) <= tolerance)
}

/// Under Reduce Motion, and under the app's own Reduce animations, nothing moves and nothing waits.
@Test(arguments: [Motion(reduceMotion: true), Motion(reduceMotion: false, instant: true)])
func underReduceMotionEachIsAtOnce(motion: Motion) {
    let moves = WelcomeMoves(motion: motion)
    #expect(moves.arrival == nil && moves.turn == nil && moves.leaving == nil && moves.touchArrival == nil)
    #expect(moves.away == 0 && moves.touchWaits == 0)
}
