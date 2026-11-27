import Look
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
                    icon: "calendar", title: "Keep clips for", detail: "Older clips are deleted as they pass it."
                ) {
                    Segmented(
                        options: [(.week, "A week"), (.month, "A month"), (.year, "A year"), (.forever, "Forever")],
                        selection: $choices.settings.keeping)
                }
                SettingRow(
                    icon: "iphone", title: "Copies from your other devices",
                    detail: "What you copy on your iPhone or another Mac."
                ) {
                    Switch(on: $choices.settings.keepsCopiesFromOtherDevices).accessibilityLabel(
                        "Copies from your other devices")
                }
                SettingRow(
                    icon: "trash", title: "Delete everything", detail: "Every clip, at once. This cannot be undone."
                ) {
                    Pill("Delete All…", tint: .unsafe) { deleting = true }
                }
            }
            GroupBlock(title: "Your history in one file", icon: "doc") {
                SettingRow(
                    icon: "square.and.arrow.up", title: "Save your history to a file",
                    detail: "Every clip, passwords too, in a plain file any Mac opens. Keep it somewhere safe."
                ) {
                    Pill("Export…") { choices.attempt { exported = ExportedHistory(data: try choices.exported()) } }
                }
                SettingRow(
                    icon: "square.and.arrow.down", title: "Bring back a saved history",
                    detail: "Puts a saved file's clips and settings in place of what is here."
                ) { Pill("Bring Back…") { choosing = true } }
            }
            GroupBlock(title: "Chete", icon: "gearshape") {
                SettingRow(icon: "power", title: "Open at login", detail: "Ready from the moment you log in.") {
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
        .confirmationDialog("Delete every clip?", isPresented: $deleting) {
            Button("Delete Everything", role: .destructive) { choices.attempt { try choices.deleteAll() } }
        } message: {
            Text("This cannot be undone. A file you exported is not touched.")
        }
        .fileExporter(
            isPresented: Binding {
                exported != nil
            } set: {
                if !$0 { exported = nil }
            }, document: exported,
            contentType: .json, defaultFilename: "Chete History"
        ) { result in
            if case .failure(let error) = result {
                choices.failure = "That did not work: \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $choosing, allowedContentTypes: [.json]) { result in
            bringing = try? result.get()
        }
        .confirmationDialog(
            "Replace your history with this file?",
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
            Text("Every clip here is put in place of the file's. Export first to keep them.")
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
