import SwiftUI
import Testing

@testable import Look

/// Search's motion, as its `Motion` at commit c92ea7c has it when nothing asks for less.
@Test func searchsMotionAsItIs() {
    let motion = Motion(reduceMotion: false)
    #expect(motion.glide == .spring(response: 0.34, dampingFraction: 0.82))
    #expect(motion.settle == .spring(response: 0.30, dampingFraction: 0.86))
    #expect(motion.quick == .easeOut(duration: 0.14))
    #expect(Motion.give == 0.97)
    #expect(motion.folding(out: true) == .spring(response: 0.14, dampingFraction: 0.86))
    #expect(motion.folding(out: false) == .spring(response: 0.13, dampingFraction: 1))
}

/// With Reduce Motion on, every movement is at once.
@Test func underReduceMotionEverythingIsAtOnce() {
    let motion = Motion(reduceMotion: true)
    #expect(motion.glide == nil && motion.settle == nil && motion.quick == nil)
    #expect(motion.folding(out: true) == nil && motion.folding(out: false) == nil)
    #expect(motion.columnAway == 0)
}

/// With the column set to slide, Reduce Motion fades it in place instead, as Apple's own sidebars do.
@Test func aSlidingColumnFadesUnderReduceMotion() {
    #expect(Motion(reduceMotion: true, slides: true).fadesColumn)
    #expect(!Motion(reduceMotion: false, slides: true).fadesColumn)
    #expect(!Motion(reduceMotion: true).fadesColumn)
    #expect(Motion(reduceMotion: false, slides: true).folding(out: true) == .easeOut(duration: 0.26))
}

/// Reduce animations, the app's own setting, makes every movement at once, the column's fade included.
@Test func reduceAnimationsMakesEverythingAtOnce() {
    let motion = Motion(reduceMotion: true, slides: true, instant: true)
    #expect(motion.glide == nil && motion.quick == nil && motion.folding(out: true) == nil)
    #expect(!motion.fadesColumn)
    #expect(motion.seconds(0.2) == 0 && motion.timed(.easeOut(duration: 0.2)) == nil)
    #expect(Motion(reduceMotion: false).seconds(0.2) == 0.2)
}
