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
        // Each finding names its element in the failure itself, so the summary says where to look.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast)) { issue in
            XCTFail("Window: \(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
            return true
        }
    }

    /// It lives in the menu bar. Its item there drops a card with Settings, Check for Updates and Quit, since an
    /// app with no Dock icon shows no menus of its own, and the card opens Chete's window again after it was closed.
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
        XCTAssert(app.buttons["Quit Chete"].exists, "The card has no way to quit.")
        open.click()
        XCTAssert(app.windows["Chete"].waitForExistence(timeout: 10), "The card did not open Chete.")
    }
}

extension CheteTour {
    /// It finds as you type, on a history of made-up clips: a word narrows the list, the arrow keys move,
    /// and Return picks. What was picked is then pasted into the field, as a person would, to see which clip it was.
    @MainActor
    func testItFindsAsYouTypeAndReturnPicks() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
        try Data(madeUpHistory.utf8).write(to: file)
        addTeardownBlock { try? FileManager.default.removeItem(at: file) }
        let app = XCUIApplication()
        app.launchEnvironment["CHETE_TOUR_HISTORY"] = file.path
        app.launch()

        let field = app.textFields["Find a clip"]
        // Without the list, the keys below would be typed into whatever is open instead, so the tour stops here.
        guard field.waitForExistence(timeout: 10) else { return XCTFail("Chete opened no field to find a clip.") }
        let row = { (title: String) in
            // Each row reads as one piece of text: its first line, then what it is and when it was copied.
            app.staticTexts.matching(NSPredicate(format: "value BEGINSWITH %@", title)).firstMatch
        }
        if !row("https://example.com/tickets").waitForExistence(timeout: 10) {
            add(XCTAttachment(string: app.debugDescription))
        }
        XCTAssert(row("Dinner at eight on Friday").exists, "The newest made-up clip is not in the list.")
        XCTAssert(row("https://example.com/tickets").exists, "The made-up link is not in the list.")
        XCTAssert(row("The parcel comes on Tuesday").exists, "The oldest made-up clip is not in the list.")

        // The field is ready as Chete opens, so a person only types. Two clips hold "day"; the link does not.
        app.typeText("day")
        XCTAssert(row("https://example.com/tickets").waitForNonExistence(timeout: 5), "Typing did not narrow the list.")
        XCTAssert(row("Dinner at eight on Friday").exists, "Typing hid a clip that holds the word.")
        // Down moves from the newest clip found to the one under it, and Return picks that one.
        app.typeKey(.downArrow, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])
        app.typeKey("a", modifierFlags: .command)
        app.typeKey("v", modifierFlags: .command)
        let picked = NSPredicate(format: "value == %@", "The parcel comes on Tuesday")
        if XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: picked, object: field)], timeout: 5)
            != .completed
        {
            XCTFail("Return picked \(String(describing: field.value)), not the clip the arrow key chose.")
        }
    }
}

/// A made-up history, as Export writes it, newest first: two notes with a link between them. It is kept forever,
/// so that it is never too old to keep, however long after it was written the tour runs.
private let madeUpHistory = """
    {
      "settings": { "keeping": "forever" },
      "clips": [
        {
          "id": "00000000-0000-4000-8000-000000000001",
          "copied": 815000300,
          "kinds": [{ "text": { "_0": "Dinner at eight on Friday" } }]
        },
        {
          "id": "00000000-0000-4000-8000-000000000002",
          "copied": 815000200,
          "kinds": [{ "link": { "_0": "https://example.com/tickets" } }]
        },
        {
          "id": "00000000-0000-4000-8000-000000000003",
          "copied": 815000100,
          "kinds": [{ "text": { "_0": "The parcel comes on Tuesday" } }]
        }
      ]
    }
    """
