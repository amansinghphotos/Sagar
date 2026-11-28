import Foundation
import Testing

@testable import Shell

/// Posts what the release command posts, the way it posts it.
private func ask(_ identifier: String) throws {
    let post = try Process.run(URL(filePath: "/usr/bin/notifyutil"), arguments: ["-p", "\(identifier).new-build"])
    post.waitUntilExit()
}

/// Lets the main queue run until `done`, or for five seconds.
@MainActor private func wait(until done: () -> Bool) async {
    for _ in 0..<50 where !done() { try? await Task.sleep(for: .milliseconds(100)) }
}

/// The app quits the normal way when the release command asks for its place: here, the quitting is told instead.
@Test @MainActor func anAppQuitsWhenTheReleaseCommandAsksForItsPlace() async throws {
    let identifier = "com.example.swap-\(UUID())"
    var asked = false
    let swap = Swap(identifier) { asked = true }
    try ask(identifier)
    await wait { asked }
    #expect(asked)
    withExtendedLifetime(swap) {}
}

@Test @MainActor func anAppIsNotAskedForAnotherAppsPlace() async throws {
    let identifier = "com.example.swap-\(UUID())"
    var asked = false
    let swap = Swap(identifier) { asked = true }
    try ask("com.example.another-\(UUID())")
    await wait { false }
    #expect(!asked)
    withExtendedLifetime(swap) {}
}
