import XCTest
import notify

/// Chete, opened and used as a person would, on GitHub's Mac. It takes the screen, so it never runs on the owner's.
final class CheteTour: XCTestCase {
    /// On GitHub's new Mac, the welcome comes first, and is walked as a person would: every page, the pasting
    /// page's own button opening System Settings with the card in front, then Start, which shows Chete. The welcome
    /// never shows again. Named to run first, as
    /// XCTest runs a class's steps in the order of their names.
    @MainActor
    func testAFirstOpenWelcomesYouAndSetsCheteUp() throws {
        let app = XCUIApplication()
        app.launch()
        let welcome = app.windows["Welcome to Chete"]
        XCTAssert(welcome.waitForExistence(timeout: 10), "There was no welcome on a new Mac.")
        try audit(app, "Welcome")
        welcome.buttons["Continue"].click()
        welcome.buttons["Continue"].click()
        welcome.buttons["Continue"].click()
        welcome.buttons["Open System Settings"].click()
        let settings = XCUIApplication(bundleIdentifier: "com.apple.systempreferences")
        XCTAssert(settings.wait(for: .runningForeground, timeout: 15), "System Settings did not open.")
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "value CONTAINS %@", "Chete only uses it to paste")).firstMatch
        XCTAssert(card.waitForExistence(timeout: 10), "The card was not in front of System Settings.")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "The card in front of System Settings"
        shot.lifetime = .keepAlways
        add(shot)
        settings.terminate()
        XCTAssert(welcome.waitForExistence(timeout: 20), "The welcome did not come back once System Settings closed.")
        welcome.buttons["Continue"].click()
        welcome.buttons["Start"].click()
        XCTAssert(welcome.waitForNonExistence(timeout: 5), "Start did not end the welcome.")
        let window = app.windows["Chete"]
        XCTAssert(window.waitForExistence(timeout: 10), "Start did not show Chete.")
        app.terminate()
        app.launch()
        XCTAssert(app.windows["Chete"].waitForExistence(timeout: 10), "Chete opened no window.")
        XCTAssertFalse(welcome.exists, "The welcome showed again.")
    }

    /// Launches Chete, and finishes the welcome with Skip if it shows, as on a new Mac.
    @MainActor
    private func launchPastTheWelcome(_ app: XCUIApplication) {
        app.launch()
        let welcome = app.windows["Welcome to Chete"]
        guard welcome.waitForExistence(timeout: 3) else { return }
        welcome.buttons["Skip"].click()
        _ = welcome.waitForNonExistence(timeout: 5)
    }

    /// Its settings are audited, and keep what you choose: clips kept for a month
    /// instead of a year, still chosen the next time Chete opens, when they are opened from its menu-bar card.
    @MainActor
    func testItsSettingsPassTheAuditAndKeepWhatYouChoose() throws {
        let app = XCUIApplication()
        launchPastTheWelcome(app)
        app.typeKey(",", modifierFlags: .command)
        let month = app.buttons["A month"]
        XCTAssert(month.waitForExistence(timeout: 10), "Chete's settings did not open.")
        try audit(app, "Settings")
        month.click()
        close(settingsOf: app)
        app.terminate()
        launchPastTheWelcome(app)
        // Chete opens its window as it starts; the card is asked for once that window is in front, or the window
        // coming forward would close the card as it drops.
        XCTAssert(app.windows["Chete"].waitForExistence(timeout: 10), "Chete opened no window.")
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
        launchPastTheWelcome(app)
        XCTAssert(app.windows.firstMatch.waitForExistence(timeout: 10), "Chete opened no window.")
        XCTAssertEqual(app.windows.count, 1)
        try audit(app, "Window")
    }

    /// When a build to try takes its place, the release command asks Chete for it by the notification it posts, which
    /// needs no permission, and Chete quits the normal way.
    @MainActor
    func testItQuitsWhenTheReleaseCommandAsksForItsPlace() throws {
        let app = XCUIApplication()
        launchPastTheWelcome(app)
        XCTAssert(app.statusItems["Chete"].waitForExistence(timeout: 10), "Chete did not open.")
        notify_post("com.amansingh.chete.new-build")
        XCTAssert(app.wait(for: .notRunning, timeout: 10), "Chete did not quit when asked for its place.")
    }

    /// It lives in the menu bar. Its item there drops a card with Settings, Check for Updates and Quit, since an
    /// app with no Dock icon shows no menus of its own, so none of them is kept in one. The card opens Chete's
    /// window again after it was closed.
    @MainActor
    func testItsItemInTheMenuBarDropsItsCard() throws {
        let app = XCUIApplication()
        launchPastTheWelcome(app)
        let window = app.windows["Chete"]
        XCTAssert(window.waitForExistence(timeout: 10), "Chete opened no window.")
        window.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssert(window.waitForNonExistence(timeout: 5), "Chete's window did not close.")

        let item = app.statusItems["Chete"]
        if !item.waitForExistence(timeout: 10) { add(XCTAttachment(string: app.debugDescription)) }
        item.click()
        let open = app.buttons["Open Chete"]
        guard open.waitForExistence(timeout: 5) else {
            return failed("The menu-bar item dropped no card", nil, in: app)
        }
        XCTAssert(app.buttons["Settings"].exists, "The card has no way to Settings.")
        XCTAssert(app.buttons["Check for Updates"].exists, "The card offers no Check for Updates.")
        XCTAssertFalse(
            app.menuItems["Check for Updates…"].exists, "Check for Updates… is still in a menu that never shows.")
        XCTAssert(app.buttons["Quit Chete"].exists, "The card has no way to quit.")
        open.click()
        XCTAssert(app.windows["Chete"].waitForExistence(timeout: 10), "The card did not open Chete.")
    }

    /// The first time a new build opens, it shows what is new, once. Told it last saw another build, Chete shows
    /// the line this build was made with; opened again, it does not.
    @MainActor
    func testANewBuildShowsWhatIsNewOnce() throws {
        let app = XCUIApplication()
        let line = app.staticTexts["A line the tour looks for."]
        app.launchArguments = ["-Shell.LastBuildSeen", "an older build"]
        launchPastTheWelcome(app)
        XCTAssert(line.waitForExistence(timeout: 10), "A new build did not show what is new.")
        try audit(app, "What is new")
        line.click()  // once clicked, the card takes the keyboard, and Escape closes it
        app.typeKey(.escape, modifierFlags: [])
        XCTAssert(line.waitForNonExistence(timeout: 5), "The card for what is new did not close.")
        app.terminate()
        app.launchArguments = []
        launchPastTheWelcome(app)
        XCTAssert(app.statusItems["Chete"].waitForExistence(timeout: 10), "Chete did not open.")
        XCTAssertFalse(line.waitForExistence(timeout: 5), "What is new showed a second time.")
    }

    /// Each address Chete opens System Settings at lands on the place it names: Paste from Other Apps, and
    /// Accessibility, which macOS 27 calls Device Control and Data Access. A screenshot of each is kept.
    @MainActor
    func testSystemSettingsOpensWhereCheteSendsYou() throws {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.systempreferences")
        let places = [
            ("Privacy_Pasteboard", ["Paste from Other Apps"]),
            ("Privacy_Accessibility", ["Device Control and Data Access", "Accessibility"]),
        ]
        for (pane, names) in places {
            settings.open(
                try XCTUnwrap(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")))
            XCTAssert(settings.wait(for: .runningForeground, timeout: 15), "System Settings did not open.")
            // The place's name is the window's title: the sidebar names Accessibility whatever is open.
            let window = settings.windows.firstMatch
            let titled = expectation(for: NSPredicate(format: "title IN %@", names), evaluatedWith: window)
            _ = XCTWaiter.wait(for: [titled], timeout: 10)
            let found = names.first { $0 == window.title }
            let shot = XCTAttachment(screenshot: settings.screenshot())
            shot.name = "\(pane): \(found ?? "none of \(names)")"
            shot.lifetime = .keepAlways
            add(shot)
            XCTAssertNotNil(found, "\(pane) did not land on \(names.joined(separator: " or ")).")
        }
        settings.terminate()
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
        launchPastTheWelcome(app)

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
