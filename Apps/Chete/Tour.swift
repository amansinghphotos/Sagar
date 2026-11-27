import XCTest

/// Chete, opened and used as a person would, on GitHub's Mac. It takes the screen, so it never runs on the owner's.
final class CheteTour: XCTestCase {
    /// Its settings are audited, and keep what you choose: clips kept for a month
    /// instead of a year, still chosen the next time Chete opens, when they are opened from its menu-bar card.
    @MainActor
    func testItsSettingsPassTheAuditAndKeepWhatYouChoose() throws {
        let app = XCUIApplication()
        app.launch()
        app.typeKey(",", modifierFlags: .command)
        let month = app.buttons["A month"]
        XCTAssert(month.waitForExistence(timeout: 10), "Chete's settings did not open.")
        try audit(app, "Settings")
        month.click()
        close(settingsOf: app)
        app.terminate()
        app.launch()
        let item = app.statusItems["Chete"]
        XCTAssert(item.waitForExistence(timeout: 10), "Chete has no item in the menu bar.")
        item.click()
        let settings = app.buttons["Settings"]
        XCTAssert(settings.waitForExistence(timeout: 5), "The menu-bar card has no way to Settings.")
        settings.click()
        XCTAssert(app.buttons["A month"].waitForExistence(timeout: 10), "The card did not open Chete's settings.")
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
    /// Then it shows one window, which is audited.
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
        try audit(app, "Window")
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

extension CheteTour {
    /// Runs Apple's accessibility audit, but for contrast (see SPEC.md). Each finding is reported, naming its element,
    /// and written into the run's summary, but does not fail the tour, as the owner decided (decision 9) until he
    /// brings that back (#252). Bringing it back is replacing `XCTExpectFailure` here with the `XCTFail` inside it.
    @MainActor
    func audit(_ app: XCUIApplication, _ place: String) throws {
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast)) { issue in
            let element = issue.element?.debugDescription.split(whereSeparator: \.isNewline).joined(separator: " ")
            let finding = "\(place): \(issue.compactDescription): \(element ?? "no element named")"
            XCTExpectFailure("Accessibility audit, reported, not failing (decision 9): \(finding)", strict: false) {
                XCTFail(finding)
            }
            return true
        }
    }

    /// Its shortcut, Shift-Command-C at first, opens Chete from another app after its window was closed.
    @MainActor
    func testItsShortcutOpensItFromAnotherApp() throws {
        let app = XCUIApplication()
        app.launch()
        let window = app.windows["Chete"]
        XCTAssert(window.waitForExistence(timeout: 10), "Chete opened no window.")
        window.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssert(window.waitForNonExistence(timeout: 5), "Chete's window did not close.")
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
        finder.typeKey("c", modifierFlags: [.command, .shift])
        XCTAssert(window.waitForExistence(timeout: 10), "Shift-Command-C did not open Chete.")
    }
}
