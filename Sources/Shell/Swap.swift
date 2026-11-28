import AppKit
import notify

/// Lets the release command ask an open app for its place, so that a build to try can take it. The command posts a
/// system notification named for the app, which any process may post and none needs a permission for, and the app
/// quits the normal way, as if chosen from its menu. The command then opens the new build behind other windows.
@MainActor
package final class Swap {
    private var token = NOTIFY_TOKEN_INVALID

    /// Listens for as long as it is kept, for the app with this identifier, and runs `quit` when asked.
    package init(
        _ identifier: String = Bundle.main.bundleIdentifier ?? "", quit: @escaping @MainActor () -> Void = Swap.quit
    ) {
        notify_register_dispatch("\(identifier).new-build", &token, .main) { _ in
            MainActor.assumeIsolated { quit() }
        }
    }

    isolated deinit { notify_cancel(token) }

    private static func quit() { NSApp.terminate(nil) }

    /// Listens for the app's whole life.
    package static func listen() { kept = kept ?? Swap() }
    private static var kept: Swap?
}
