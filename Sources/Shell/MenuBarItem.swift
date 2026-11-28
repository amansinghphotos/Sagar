import SwiftUI

/// An app's item in the menu bar, for an app that lives there and has no Dock icon. Clicking it drops the
/// card the app hands over, as Control Center's items do.
package struct MenuBarItem<Card: View>: Scene {
    let app: String
    let symbol: String
    let card: () -> Card

    package init(app: String, symbol: String, @ViewBuilder card: @escaping () -> Card) {
        self.app = app
        self.symbol = symbol
        self.card = card
    }

    package var body: some Scene {
        MenuBarExtra {
            card()
        } label: {
            // Named for the app, so VoiceOver says the app, not what the symbol shows.
            Image(systemName: symbol).accessibilityLabel(app)
        }
        .menuBarExtraStyle(.window)
    }
}
