import XCTest

/// Chete, opened and used as a person would, on GitHub's Mac. It takes the screen, so it never runs on the owner's.
final class CheteTour: XCTestCase {
    /// Apple's own launch metric, three times; the rules take the fastest.
    @MainActor
    func testItOpensQuickly() {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            XCUIApplication().launch()
        }
    }

    /// It opens one window, which passes Apple's accessibility audit. Contrast is left out: see SPEC.md.
    @MainActor
    func testItOpensOneWindowThatPassesTheAudit() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.windows.firstMatch.waitForExistence(timeout: 10), "Chete opened no window.")
        XCTAssertEqual(app.windows.count, 1)
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast))
    }
}
