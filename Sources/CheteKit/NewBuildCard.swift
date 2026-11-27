import Look
import Shell
import SwiftUI

/// Chete's card for what is new in a build: its version, and the lines the build was made with.
struct NewBuildCard: View {
    let version: String
    let lines: [(String, String)]
    let close: () -> Void

    var body: some View {
        NewCard(title: "New in Chete \(version)", lines: lines, close: close)
    }
}

extension View {
    /// Shows what is new, once, the first time a new build's window opens.
    func showingWhatIsNew() -> some View {
        onAppear {
            WhatIsNew.showIfNew { version, lines, close in
                NewBuildCard(version: version, lines: lines.map { ($0.kind, $0.line) }, close: close)
            }
        }
    }
}
