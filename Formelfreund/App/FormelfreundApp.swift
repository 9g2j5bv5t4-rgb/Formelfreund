import SwiftUI

/// Einstiegspunkt der App.
///
/// `DocumentGroup` liefert alles, was eine Mac-Dokument-App braucht:
/// Ablage-Menü, Sichern, Versionen, zuletzt benutzte Dokumente, Fenster-Tabs.
@main
struct FormelfreundApp: App {
    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        DocumentGroup(newDocument: { TeXDocument() }) { file in
            DocumentWindow(document: file.document, fileURL: file.fileURL)
        }
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
