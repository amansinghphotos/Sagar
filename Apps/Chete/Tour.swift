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
        XCTAssert(app.windows.firstMatch.waitForExistence(timeout: 10), "Chete opened no window.")
        XCTAssertEqual(app.windows.count, 1)
        // Each finding is kept with the element it is about, so a failure says where to look.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast)) { issue in
            self.add(XCTAttachment(string: "\(issue.compactDescription)\n\(issue.element?.debugDescription ?? "")"))
            return false
        }
    }

    /// It lives in the menu bar. Its item there opens its window again after it was closed, and offers
    /// Check for Updates…, since an app with no Dock icon shows no menus of its own.
    @MainActor
    func testItsItemInTheMenuBarOpensIt() throws {
        let app = XCUIApplication()
        app.launch()
        let window = app.windows.firstMatch
        XCTAssert(window.waitForExistence(timeout: 10), "Chete opened no window.")
        window.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssert(window.waitForNonExistence(timeout: 5), "Chete's window did not close.")

        let item = app.statusItems["Chete"]
        if !item.waitForExistence(timeout: 10) { add(XCTAttachment(string: app.debugDescription)) }
        item.click()
        XCTAssert(app.menuItems["Check for Updates…"].exists, "The menu offers no Check for Updates…")
        XCTAssert(app.menuItems["Quit Chete"].exists, "The menu offers no way to quit.")
        app.menuItems["Open Chete"].click()
        XCTAssert(app.windows.firstMatch.waitForExistence(timeout: 10), "The menu-bar item did not open Chete.")
    }
}
