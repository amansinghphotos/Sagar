import Foundation
import SwiftUI
import Testing

@testable import Look

/// How Search's motion moves, recorded from its code at commit c92ea7c with the scratch recorder's
/// `Record motion`: each movement from 0 to 1 at every 120th of a second for a second, the launcher's
/// shiver in points for its half second, and how far a pressed thing gives.
private let search: [String: [Double]] = {
    let file = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures/Search Motion.json")
    return try! JSONDecoder().decode([String: [Double]].self, from: Data(contentsOf: file))
}()

/// The most any frame of ours may stand from Search's: two hundredths of the way.
private let hair = 0.02

/// Each of ours stays within a hair of Search's at every frame.
@Test(arguments: [
    ("glide", Motion(reduceMotion: false).glide), ("settle", Motion(reduceMotion: false).settle),
    ("quick", Motion(reduceMotion: false).quick),
    ("fold out", Motion(reduceMotion: false).folding(out: true)),
    ("fold in", Motion(reduceMotion: false).folding(out: false)),
    ("slide out", Motion(reduceMotion: false, slides: true).folding(out: true)),
    ("slide in", Motion(reduceMotion: false, slides: true).folding(out: false)),
])
func movesWithinAHairOfSearch(name: String, animation: Animation?) throws {
    let ours = try trace(#require(animation))
    let theirs = try #require(search[name])
    #expect(ours.count == theirs.count)
    let furthest = zip(ours, theirs).map { abs($0 - $1) }.max() ?? 1
    #expect(furthest <= hair, "\(name) stands \(furthest) from Search's")
}

/// The launcher's shiver, over the half second it runs, stays within a hair of its 7-point swing.
@Test func theShiverIsWithinAHairOfSearch() throws {
    let ours = trace(.easeOut(duration: 0.5), seconds: 0.5).map {
        Double(Shake(travel: $0).effectValue(size: .zero).m31)
    }
    let theirs = try #require(search["shake"])
    #expect(ours.count == theirs.count)
    #expect(zip(ours, theirs).allSatisfy { abs($0 - $1) <= hair * 7 })
    #expect(Shake(travel: 0.3, reduced: true).effectValue(size: .zero).m31 == 0)
}

/// A pressed thing gives as far as Search's does.
@Test func aPressGivesAsFarAsSearchs() throws {
    #expect(try abs(Double(Motion.give) - #require(search["give"]?.first)) <= 0.005)
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
    #expect(Motion(reduceMotion: false, slides: true).folding(out: true) != nil)
}

/// Reduce animations, the app's own setting, makes every movement at once, the column's fade included.
@Test func reduceAnimationsMakesEverythingAtOnce() {
    let motion = Motion(reduceMotion: true, slides: true, instant: true)
    #expect(motion.glide == nil && motion.quick == nil && motion.folding(out: true) == nil)
    #expect(!motion.fadesColumn)
    #expect(motion.seconds(0.2) == 0 && motion.timed(.easeOut(duration: 0.2)) == nil)
    #expect(Motion(reduceMotion: false).seconds(0.2) == 0.2)
}

/// Where an animation is, 0 to 1, at each 120th of a second: read from the animation itself, a spring's
/// response and damping or a curve's Bézier, through reflection, then worked out with Apple's own Spring
/// or the curve. Fails loudly if SwiftUI ever stores them differently.
func trace(_ animation: Animation, seconds: Double = 1) -> [Double] {
    guard let base = Mirror(reflecting: animation).children.first(where: { $0.label == "base" })?.value else {
        return []
    }
    let fields = Dictionary(
        Mirror(reflecting: base).children.compactMap { child in child.label.map { ($0, child.value) } },
        uniquingKeysWith: { first, _ in first })
    let times = (0...Int(seconds * 120)).map { Double($0) / 120 }
    if let response = fields["response"] as? Double, let damping = fields["dampingFraction"] as? Double {
        let spring = Spring(response: response, dampingRatio: damping)
        return times.map { spring.value(target: 1.0, time: $0) }
    }
    guard let duration = fields["duration"] as? Double, let curve = fields["curve"] else { return [] }
    let c = Dictionary(
        Mirror(reflecting: curve).children.compactMap { child in child.label.map { ($0, child.value as? Double ?? 0) }
        },
        uniquingKeysWith: { first, _ in first })
    func along(_ s: Double, _ axis: String) -> Double {
        ((c["a" + axis, default: 0] * s + c["b" + axis, default: 0]) * s + c["c" + axis, default: 0]) * s
    }
    return times.map { time in
        let goal = min(time / duration, 1)
        var low = 0.0
        var high = 1.0
        for _ in 0..<60 {
            let middle = (low + high) / 2
            if along(middle, "x") < goal { low = middle } else { high = middle }
        }
        return along((low + high) / 2, "y")
    }
}
