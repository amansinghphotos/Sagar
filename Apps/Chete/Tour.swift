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
        XCTAssert(field.waitForExistence(timeout: 10), "Chete opened no field to find a clip.")
        let row = { (title: String) in
            app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
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

/// A made-up history, as Export writes it, newest first: two notes with a link between them.
private let madeUpHistory = """
    {
      "settings": {},
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
