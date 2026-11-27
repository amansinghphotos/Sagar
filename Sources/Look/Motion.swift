// Taken from Search, Sources/Search/Design.swift at commit c92ea7c (github.com/driceroland/Search).
// Copyright (c) 2026 Office Commun. Used under the MIT licence, whose notice is in ACKNOWLEDGEMENTS.md.
// Changed only where this repository's rules require: Reduce Motion is read from SwiftUI rather than AppKit,
// so the motion is a value a screen reads from its environment; the lighter motion when power is short and
// the test switches are not carried over; and Reduce animations and sliding the column are values given
// here instead of read from Search's settings.
import SwiftUI

// One set of springs for the whole app, so every panel, tab and page moves
// like a single piece of software rather than a pile of views.
// When macOS Reduce Motion is on in System Settings, or Reduce animations in
// the app's own, transitions become immediate so the interface does not jump
// or slide.
nonisolated package struct Motion: Equatable, Sendable {
    /// The Mac's own Reduce Motion.
    package var reduceMotion: Bool

    /// Reduce animations, for the app alone: every transition is immediate,
    /// as under Reduce Motion, and so are the fades Reduce Motion keeps.
    package var instant = false

    /// Slide the column in and out: the column comes out on an ease-out and
    /// goes back on an ease-in, as Arc's does, rather than on the short
    /// springs below.
    package var slides = false

    package init(reduceMotion: Bool, slides: Bool = false, instant: Bool = false) {
        self.reduceMotion = reduceMotion
        self.slides = slides
        self.instant = instant
    }

    /// Whether interface transitions should be immediate, following the
    /// Mac's own accessibility setting or the app's Reduce animations.
    package var reduced: Bool {
        instant || reduceMotion
    }

    /// `seconds`, or none with Reduce animations on: for the fades that run
    /// on a length of their own rather than on the animations below.
    package func seconds(_ seconds: TimeInterval) -> TimeInterval {
        instant ? 0 : seconds
    }

    /// `animation`, or none with Reduce animations on, the same way.
    package func timed(_ animation: Animation) -> Animation? {
        instant ? nil : animation
    }

    package var glide: Animation? {
        reduced ? nil : .spring(response: 0.34, dampingFraction: 0.82)
    }

    package var settle: Animation? {
        reduced ? nil : .spring(response: 0.30, dampingFraction: 0.86)
    }

    package var quick: Animation? {
        reduced ? nil : .easeOut(duration: 0.14)
    }

    /// How far a tab gives while it is pressed (see Give): enough to feel
    /// under the pointer, about 3 points on a pill and 7 on a column row.
    package static let give: CGFloat = 0.97

    /// The folded column or strip coming out over the page, and going back.
    /// On glide it was slow both ways, next to Arc and Dia timed frame by
    /// frame on the same Mac: each slides its sidebar 90% of the way out in
    /// about 95ms and back in about 70ms, where glide took over 200ms. These
    /// match them. Going in is damped all the way, since nothing is arriving
    /// to settle.
    package static func fold(out: Bool) -> (response: Double, damping: Double) {
        out ? (0.14, 0.86) : (0.13, 1)
    }

    /// How long the folded column takes to slide back in, or fade, and
    /// is still over the page: the spring's response (Motion.fold) runs a
    /// little past it.
    package var columnAway: TimeInterval {
        if reduced { return 0 }
        if fadesColumn { return Self.fade }
        return slide(out: false) ?? 0.2
    }

    package func folding(out: Bool) -> Animation? {
        if reduced { return nil }
        if let slide = slide(out: out) {
            return out ? .easeOut(duration: slide) : .easeIn(duration: slide)
        }
        let spring = Self.fold(out: out)
        return .spring(response: spring.response, dampingFraction: spring.damping)
    }

    /// The column comes out on an ease-out and goes back on an ease-in, over
    /// this long, as Arc's does, rather than on the short springs above. Nil
    /// when off.
    package func slide(out: Bool) -> TimeInterval? {
        guard slides else { return nil }
        return out ? 0.26 : 0.22
    }

    /// Slide the column in and out with the Mac's Reduce Motion on: the
    /// column fades in place where it would slide, as Apple's own sidebars
    /// do under Reduce Motion, rather than doing nothing at all, which read
    /// as a switch that does nothing. The app's own Reduce animations still
    /// means at once (see `instant`).
    package var fadesColumn: Bool {
        !instant && slide(out: true) != nil && reduceMotion
    }

    /// That fade's length.
    package static let fade: TimeInterval = 0.2
}

extension EnvironmentValues {
    /// The motion for where a screen sits: Search's, at once under the Mac's Reduce Motion.
    package var motion: Motion { Motion(reduceMotion: accessibilityReduceMotion) }
}
