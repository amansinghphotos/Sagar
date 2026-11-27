import SwiftUI
import Testing

@testable import Look

/// Search's motion, as its `Motion` at commit c92ea7c has it when nothing asks for less.
@Test func searchsMotionAsItIs() {
    let motion = Motion(reduced: false)
    #expect(motion.glide == .spring(response: 0.34, dampingFraction: 0.82))
    #expect(motion.settle == .spring(response: 0.30, dampingFraction: 0.86))
    #expect(motion.quick == .easeOut(duration: 0.14))
    #expect(Motion.give == 0.97)
    #expect(motion.folding(out: true) == .spring(response: 0.14, dampingFraction: 0.86))
    #expect(motion.folding(out: false) == .spring(response: 0.13, dampingFraction: 1))
}

/// With Reduce Motion on, every movement is at once.
@Test func underReduceMotionEverythingIsAtOnce() {
    let motion = Motion(reduced: true)
    #expect(motion.glide == nil && motion.settle == nil && motion.quick == nil)
    #expect(motion.folding(out: true) == nil && motion.folding(out: false) == nil)
    #expect(motion.columnAway == 0)
}

/// With the column set to slide, Reduce Motion fades it in place instead, as Apple's own sidebars do.
@Test func aSlidingColumnFadesUnderReduceMotion() {
    #expect(Motion(reduced: true, slides: true).fadesColumn)
    #expect(!Motion(reduced: false, slides: true).fadesColumn)
    #expect(!Motion(reduced: true).fadesColumn)
    #expect(Motion(reduced: false, slides: true).folding(out: true) == .easeOut(duration: 0.26))
}
