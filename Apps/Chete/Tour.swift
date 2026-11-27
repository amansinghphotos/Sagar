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

        let field = app.windows["Chete"].textFields.firstMatch
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
        // A list of clips is audited too, not only an empty one, before anything is typed and after a pick.
        try audit(app, "The list as it opens")

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
            failed("Return picked \(String(describing: field.value)), not the clip the arrow key chose", nil, in: app)
        }
        try audit(app, "The list after a pick")
    }

    /// Fails with everything needed to see why, in the failure itself: the element, the app's windows and dialogs,
    /// what holds the keyboard and the top of what the app shows. A picture of the screen goes in the record.
    @MainActor
    func failed(_ what: String, _ element: XCUIElement?, in app: XCUIApplication) {
        let screen = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screen.name = what
        screen.lifetime = .keepAlways
        add(screen)
        let named = { (found: XCUIElementQuery) in
            found.allElementsBoundByIndex.map { "\($0.elementType.rawValue) “\($0.title)” “\($0.label)”" }
        }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == true"))
        let tree = app.debugDescription.split(separator: "\n").prefix(12).map { String($0.prefix(160)) }
        XCTFail(
            """
            \(what)
            element: \(element?.debugDescription ?? "none named")
            windows: \(named(app.windows)); dialogs: \(named(app.dialogs) + named(app.sheets))
            keyboard: \(named(focused).first ?? "nothing in Chete")
            \(tree.joined(separator: "\n"))
            """)
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
