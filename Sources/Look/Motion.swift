// How Look moves: a few springs and curves that every part shares, and what Reduce Motion makes of them.
import SwiftUI

/// The motion a screen reads from its environment. Springs are given as Apple gives them, by how long
/// they take and how much they bounce; curves by their two control points.
nonisolated package struct Motion: Equatable, Sendable {
    /// The Mac's Reduce Motion, from System Settings.
    package var reduceMotion: Bool

    /// The column slides out and back on curves, rather than on its springs.
    package var slides = false

    /// The app's own Reduce animations: nothing moves at all, not even the fades Reduce Motion keeps.
    package var instant = false

    package init(reduceMotion: Bool, slides: Bool = false, instant: Bool = false) {
        self.reduceMotion = reduceMotion
        self.slides = slides
        self.instant = instant
    }

    /// True when every movement happens at once.
    package var reduced: Bool { reduceMotion || instant }

    /// The long, soft spring a panel or page arrives on.
    package var glide: Animation? { moving(.spring(Self.glideSpring)) }

    /// The firmer spring a control comes to rest on.
    package var settle: Animation? { moving(.spring(Self.settleSpring)) }

    /// A short ease for what answers the pointer: a hover, a press going down.
    package var quick: Animation? { moving(.timingCurve(Self.easingOut, duration: 0.14)) }

    /// How small a thing grows while it is held down.
    package static let give: CGFloat = 0.97

    /// The folded column coming out over the page, or going back.
    package func folding(out: Bool) -> Animation? {
        guard !reduced else { return nil }
        guard slides else { return .spring(out ? Self.foldOut : Self.foldIn) }
        return out ? .timingCurve(Self.easingOut, duration: 0.26) : .timingCurve(Self.easingIn, duration: 0.22)
    }

    /// How long the folded column is still over the page once it starts back.
    package var columnAway: TimeInterval {
        guard !reduced else { return 0 }
        return slides ? 0.22 : 0.2
    }

    /// Under the Mac's Reduce Motion, a column set to slide fades where it stands instead, as Apple's own
    /// sidebars do, so the switch still visibly does something. Reduce animations stops even that.
    package var fadesColumn: Bool { slides && reduceMotion && !instant }

    /// How long that fade lasts.
    package static let fade: TimeInterval = 0.2

    /// A length of time for a fade that runs by the clock, or none under Reduce animations.
    package func seconds(_ seconds: TimeInterval) -> TimeInterval { instant ? 0 : seconds }

    /// An animation for such a fade, or none under Reduce animations.
    package func timed(_ animation: Animation) -> Animation? { instant ? nil : animation }

    private func moving(_ animation: Animation) -> Animation? { reduced ? nil : animation }

    private static let glideSpring = Spring(duration: 0.35, bounce: 0.2)
    private static let settleSpring = Spring(duration: 0.3, bounce: 0.15)
    private static let foldOut = Spring(duration: 0.14, bounce: 0.15)
    private static let foldIn = Spring(duration: 0.13, bounce: 0.02)
    private static let easingOut = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0, y: 0), endControlPoint: UnitPoint(x: 0.6, y: 1))
    private static let easingIn = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.4, y: 0), endControlPoint: UnitPoint(x: 1, y: 1))
}

extension EnvironmentValues {
    /// The motion where a screen sits, following the Mac's Reduce Motion.
    package var motion: Motion { Motion(reduceMotion: accessibilityReduceMotion) }
}
