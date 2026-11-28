import Foundation
import Pictures
import SwiftUI
import Testing

@testable import Look

/// A toast wears Search's floating capsule of words, at the foot of what it stands over.
@Test(arguments: [false, true])
func aToastLooksAsSearchsCapsuleDoes(dark: Bool) throws {
    var queue = ToastQueue()
    queue.show("Copied. Press ⌘V to paste.")
    let shown = Rectangle().fill(Role.wash).toasts(.constant(queue)).frame(width: 360, height: 90)
    try expectSearchPicture(of: shown, width: 360, height: 90, named: "Bubble", dark: dark)
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

/// Each stays two and a half seconds.
@Test func eachStaysTwoAndAHalfSeconds() {
    #expect(ToastQueue.stays == 2.5)
}

/// A question over the page, as Search asks one: its icon and words, then its answers.
@Test(arguments: [false, true])
func aBannerLooksAsSearchsQuestionDoes(dark: Bool) throws {
    let banner = Banner(
        icon: "bell", question: "Chete wants to paste for you", yes: ("Allow once", {}),
        maybe: ("Always allow", {}), no: ("Don't allow", {})
    )
    .padding(30).frame(width: 600, height: 120).background(Role.wash)
    try expectSearchPicture(of: banner, width: 600, height: 120, named: "Banner", dark: dark)
}
