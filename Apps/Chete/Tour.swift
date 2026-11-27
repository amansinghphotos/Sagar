import XCTest

/// Chete, opened and used as a person would, on GitHub's Mac. It takes the screen, so it never runs on the owner's.
final class CheteTour: XCTestCase {
    /// Its settings pass Apple's accessibility audit, and keep what you choose: clips kept for a month
    /// instead of a year, still chosen the next time Chete opens.
    @MainActor
    func testItsSettingsPassTheAuditAndKeepWhatYouChoose() throws {
        let app = XCUIApplication()
        app.launch()
        app.typeKey(",", modifierFlags: .command)
        let month = app.buttons["A month"]
        XCTAssert(month.waitForExistence(timeout: 10), "Chete's settings did not open.")
        // Each finding names its element in the failure itself, so the summary says where to look.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast)) { issue in
            XCTFail("Settings: \(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
            return true
        }
        month.click()
        close(settingsOf: app)
        app.terminate()
        app.launch()
        app.typeKey(",", modifierFlags: .command)
        XCTAssert(app.buttons["A month"].waitForExistence(timeout: 10), "Chete's settings did not open again.")
        XCTAssert(app.buttons["A month"].isSelected, "A month was not kept.")
        app.buttons["A year"].click()
        close(settingsOf: app)
    }

    /// Closes the settings and waits until they are gone, so that macOS does not open them again with
    /// Chete's window the next time it opens.
    @MainActor
    private func close(settingsOf app: XCUIApplication) {
        app.typeKey("w", modifierFlags: .command)
        XCTAssert(app.buttons["A month"].waitForNonExistence(timeout: 5), "Chete's settings did not close.")
    }

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

    /// It lives in the menu bar. Its item there drops a card with Settings, Check for Updates and Quit, since an
    /// app with no Dock icon shows no menus of its own, so none of them is kept in one. The card opens Chete's
    /// window again after it was closed.
    @MainActor
    func testItsItemInTheMenuBarDropsItsCard() throws {
        let app = XCUIApplication()
        app.launch()
        let window = app.windows.firstMatch
        XCTAssert(window.waitForExistence(timeout: 10), "Chete opened no window.")
        window.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssert(window.waitForNonExistence(timeout: 5), "Chete's window did not close.")

        let item = app.statusItems["Chete"]
        if !item.waitForExistence(timeout: 10) { add(XCTAttachment(string: app.debugDescription)) }
        item.click()
        let open = app.buttons["Open Chete"]
        XCTAssert(open.waitForExistence(timeout: 5), "The menu-bar item dropped no card.")
        XCTAssert(app.buttons["Settings"].exists, "The card has no way to Settings.")
        XCTAssert(app.buttons["Check for Updates"].exists, "The card offers no Check for Updates.")
        XCTAssertFalse(
            app.menuItems["Check for Updates…"].exists, "Check for Updates… is still in a menu that never shows.")
        XCTAssert(app.buttons["Quit Chete"].exists, "The card has no way to quit.")
        open.click()
        XCTAssert(app.windows["Chete"].waitForExistence(timeout: 10), "The card did not open Chete.")
    }
}
