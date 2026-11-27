import XCTest

/// Chete, opened and used as a person would, on GitHub's Mac. It takes the screen, so it never runs on the owner's.
final class CheteTour: XCTestCase {
    /// It opens quickly, by Apple's own launch metric taken three times, of which the rules judge the fastest.
    /// Then it shows one window, which passes Apple's accessibility audit. Contrast is left out: see SPEC.md.
    @MainActor
    func testItOpensQuicklyToOneWindowThatPassesTheAudit() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            XCUIApplication().launch()
        }
        let app = XCUIApplication()
        app.launch()
        // GitHub's Mac is new, so the first open comes first: audited, then walked through as a person would,
        // asking for nothing.
        let welcome = app.windows["Welcome to Chete"]
        XCTAssert(welcome.waitForExistence(timeout: 10), "The first open did not show on a new Mac.")
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast))
        welcome.buttons["Continue"].click()
        welcome.buttons["Continue"].click()
        welcome.buttons["Start"].click()
        XCTAssert(welcome.waitForNonExistence(timeout: 5), "The first open did not close.")
        XCTAssert(app.windows.firstMatch.waitForExistence(timeout: 10), "Chete opened no window.")
        XCTAssertEqual(app.windows.count, 1)
        // Each finding is kept with the element it is about, so a failure says where to look.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast)) { issue in
            self.add(XCTAttachment(string: "\(issue.compactDescription)\n\(issue.element?.debugDescription ?? "")"))
            return false
        }
    }
}
