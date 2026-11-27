import Look
import Shell
import SwiftUI
import UniformTypeIdentifiers

/// Chete's settings window, as the app opens it from Chete › Settings….
package struct CheteSettings: View {
    @State private var choices = Choices.onThisMac()
    @State private var opensAtLogin = LoginItem.isOn

    package init() {}

    package var body: some View {
        let login = Binding {
            opensAtLogin
        } set: { on in
            choices.attempt { try LoginItem.set(on) }
            opensAtLogin = LoginItem.isOn
        }
        SettingsScreen(choices: choices, opensAtLogin: login)
            .frame(width: SettingsScreen.width)
            .fixedSize(horizontal: false, vertical: true)
            .windowName("Chete's settings")
    }
}

/// How long clips are kept, copies from other devices, deleting everything, the history in one file, and
/// opening at login: Look's setting rows, in three groups.
package struct SettingsScreen: View {
    /// The window's width, the narrowest window's. It is as tall as what is in it.
    package static let width = WindowSize.narrow.width

    @Bindable var choices: Choices
    @Binding var opensAtLogin: Bool
    @State private var deleting = false
    @State private var exported: ExportedHistory?
    @State private var choosing = false
    @State private var bringing: URL?

    package init(choices: Choices, opensAtLogin: Binding<Bool>) {
        self.choices = choices
        _opensAtLogin = opensAtLogin
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: Space.page.rawValue) {
            GroupBlock(title: "Your clips", icon: "list.clipboard") {
                SettingRow(
                    icon: "calendar", title: "Keep clips for", detail: "Older clips are deleted."
                ) {
                    Segmented(
                        options: [(.week, "A week"), (.month, "A month"), (.year, "A year"), (.forever, "Forever")],
                        selection: $choices.settings.keeping)
                }
                SettingRow(
                    icon: "iphone", title: "Keep copies from other devices",
                    detail: "Like your iPhone, iPad or another Mac."
                ) {
                    Switch(on: $choices.settings.keepsCopiesFromOtherDevices).accessibilityLabel(
                        "Keep copies from other devices")
                }
                SettingRow(
                    icon: "trash", title: "Delete all clips", detail: "You can’t undo this."
                ) {
                    Pill("Delete All…", tint: .unsafe) { deleting = true }
                }
            }
            GroupBlock(title: "Back up", icon: "doc") {
                SettingRow(
                    icon: "square.and.arrow.up", title: "Export your clips",
                    detail: "Saves every clip to one file, passwords too. Keep it somewhere safe."
                ) {
                    Pill("Export…") { choices.attempt { exported = ExportedHistory(data: try choices.exported()) } }
                }
                SettingRow(
                    icon: "square.and.arrow.down", title: "Bring back clips",
                    detail: "Replaces your clips and settings with a file you exported."
                ) { Pill("Bring Back…") { choosing = true } }
            }
            GroupBlock(title: "General", icon: "gearshape") {
                SettingRow(icon: "power", title: "Open at login", detail: "Chete’s ready as soon as you log in.") {
                    Switch(on: $opensAtLogin).accessibilityLabel("Open at login")
                }
            }
            if let failure = choices.failure {
                Text(failure).type(.detail).foregroundStyle(Role.unsafe)
            }
        }
        .padding(Space.page.rawValue)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Role.ground)
        .confirmationDialog("Delete all clips?", isPresented: $deleting) {
            Button("Delete All", role: .destructive) { choices.attempt { try choices.deleteAll() } }
        } message: {
            Text("You can’t undo this. Files you’ve exported are kept.")
        }
        .fileExporter(
            isPresented: Binding {
                exported != nil
            } set: {
                if !$0 { exported = nil }
            }, document: exported,
            contentType: .json, defaultFilename: "Chete Clips"
        ) { result in
            if case .failure(let error) = result {
                choices.failure = "That didn’t work. \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $choosing, allowedContentTypes: [.json]) { result in
            bringing = try? result.get()
        }
        .confirmationDialog(
            "Replace your clips and settings?",
            isPresented: Binding {
                bringing != nil
            } set: {
                if !$0 { bringing = nil }
            }
        ) {
            Button("Replace", role: .destructive) {
                if let file = bringing { choices.attempt { try choices.bringBack(from: file) } }
            }
        } message: {
            Text("Your clips and settings here will be replaced. Export first to keep them.")
        }
    }
}

/// The plain file an export saves, made when you choose Export.
private struct ExportedHistory: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
