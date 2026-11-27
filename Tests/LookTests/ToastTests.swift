import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// A toast wears Search's floating capsule of words, at the foot of what it stands over. Search's capsule, from
/// its code at commit c92ea7c with these words, was pictured by a scratch copy that uses this repository's
/// picture harness into `Fixtures/Search Bubble Light.png` and `Dark.png`.
@Test(arguments: [false, true])
func aToastLooksAsSearchsCapsuleDoes(dark: Bool) throws {
    let file = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "Fixtures/Search Bubble \(dark ? "Dark" : "Light").png")
    let search = try #require(approvedPicture(at: file))
    var queue = ToastQueue()
    queue.show("Copied. Press ⌘V to paste.")
    let shown = Rectangle().fill(Role.wash).toasts(.constant(queue)).frame(width: 360, height: 90)
    #expect(differingPixels(try picture(of: shown, width: 360, height: 90, dark: dark), search) <= tolerance)
}

/// Toasts show one at a time, in the order they came.
@Test func toastsWaitTheirTurn() {
    var queue = ToastQueue()
    queue.show("Copied.")
    queue.show("Pasted.")
    #expect(queue.current == "Copied.")
    queue.next()
    #expect(queue.current == "Pasted.")
    queue.next()
    #expect(queue.current == nil)
}

/// The same words twice in a row show once.
@Test func theSameToastTwiceShowsOnce() {
    var queue = ToastQueue()
    queue.show("Copied.")
    queue.show("Copied.")
    queue.next()
    #expect(queue.current == nil)
}
