import Foundation
import Testing

/// Before a tried build takes an app's place, the release command asks the app to quit the normal way, and opens
/// the new build again only if it did. These ask the real script, about real processes: a stand-in that quits when
/// asked, as the app does, and one that does not. Nothing here is an app, so nothing shows on the screen.
private func quitting(_ identifier: String, _ executable: String) throws -> String {
    let environment = ProcessInfo.processInfo.environment.merging(["WAIT": "1"]) { $1 }
    return try Script.run(
        Script.release, ["quitting", identifier, executable], environment: environment, errors: .hidden
    ).words
}

/// Starts a process and gives it a moment to be listening.
private func running(_ path: String, _ arguments: [String]) throws -> Process {
    let process = try Process.run(URL(filePath: path), arguments: arguments)
    Thread.sleep(forTimeInterval: 0.5)
    return process
}

@Test func anAppThatIsNotOpenIsLeftClosed() throws {
    #expect(
        try quitting("com.example.closed", "/Applications/No Such App \(UUID()).app/Contents/MacOS/App") == "closed\n")
}

@Test func anOpenAppIsAskedToQuitAndDoes() throws {
    let identifier = "com.example.quits-\(UUID())"
    // It waits for the one notification the release command posts, and quits on it.
    let app = try running("/usr/bin/notifyutil", ["-1", "\(identifier).new-build"])
    defer { if app.isRunning { app.terminate() } }
    #expect(try quitting(identifier, "/usr/bin/notifyutil -1 \(identifier).new-build") == "quit\n")
    #expect(!app.isRunning)
}

@Test func anOpenAppThatWillNotQuitIsLeftOpen() throws {
    let seconds = "29.\(Int.random(in: 100_000...999_999))"  // a number no other sleeping process has
    let app = try running("/bin/sleep", [seconds])
    defer { app.terminate() }
    #expect(try quitting("com.example.stays", "/bin/sleep \(seconds)") == "stayed\n")
    #expect(app.isRunning)
}
