import Look
import SwiftUI

/// The Gallery: the test window where each part of the look, in every state, is checked against Search.
/// It is never shipped.
@main
struct GalleryApp: App {
    var body: some Scene {
        Window("Gallery", id: "gallery") { Gallery() }
            .windowResizability(.contentSize)
    }
}

/// The Gallery's pages, in the order they are listed.
enum Page: String, CaseIterable, Identifiable {
    case tokens = "Tokens"
    case controls = "Controls"
    case choices = "Choices"
    case lists = "Lists"
    case overlays = "Overlays"
    case states = "States"

    var id: Self { self }
}

/// Light or dark, as the Gallery shows it.
enum Appearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"

    var scheme: ColorScheme { self == .light ? .light : .dark }
}

/// The Gallery's window: a bar to choose the page, the theme, light or dark, and the window's size, over
/// the page. The pages move to Look's own sidebar once it is built: a Mac's sidebar selection cannot be
/// pictured from a hidden window.
struct Gallery: View {
    @State var page = Page.tokens
    @State var theme = Theme.modern
    @State var appearance = Appearance.light
    @State var size = WindowSize.standard

    var body: some View {
        VStack(spacing: 0) {
            bar
            Divider()
            Group {
                switch page {
                case .tokens: Tokens()
                case .controls: Controls()
                case .choices: Choices()
                case .lists: Lists()
                case .overlays: Overlays()
                case .states: States()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(Role.ink)
        .background(Role.ground)
        .environment(\.theme, theme)
        .frame(width: size.width, height: size.height)
        .preferredColorScheme(appearance.scheme)
    }

    private var bar: some View {
        VStack(alignment: .leading) {
            choice("Page", of: Page.allCases, $page)
            HStack {
                choice("Theme", of: Theme.allCases, $theme)
                choice("Appearance", of: Appearance.allCases, $appearance)
                choice("Size", of: WindowSize.allCases, $size)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private func choice<Option: RawRepresentable<String> & Hashable>(
        _ title: String, of options: [Option], _ selection: Binding<Option>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }
}
