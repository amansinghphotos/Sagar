import XCTest

/// On a clean Mac with the previous release installed: ask for updates as a person would, and take
/// what is offered. `Scripts/release` runs this on GitHub's runner after every release but an app's first.
final class UpdateTour: XCTestCase {
    @MainActor
    func testThePreviousVersionTakesTheUpdate() throws {
        let environment = ProcessInfo.processInfo.environment
        let app = XCUIApplication(bundleIdentifier: try XCTUnwrap(environment["IDENTIFIER"]))
        app.launch()
        app.menuBars.menuBarItems[try XCTUnwrap(environment["APP"])].click()
        app.menuBars.menuItems["Check for Updates…"].click()

        let install = app.buttons["Install Update"]
        if !install.waitForExistence(timeout: 60) { add(XCTAttachment(string: app.debugDescription)) }
        // An update is offered, never forced: the person can also wait, or skip this version.
        XCTAssert(app.buttons["Remind Me Later"].exists, "The update window gives no way to wait.")
        XCTAssert(app.buttons["Skip This Version"].exists, "The update window gives no way to skip.")
        install.click()
        let relaunch = app.buttons["Install and Relaunch"]
        if !relaunch.waitForExistence(timeout: 180) { add(XCTAttachment(string: app.debugDescription)) }
        relaunch.click()

        XCTAssert(app.wait(for: .notRunning, timeout: 60), "The old version did not quit.")
        XCTAssert(app.wait(for: .runningForeground, timeout: 120), "The new version did not open.")
    }
}
