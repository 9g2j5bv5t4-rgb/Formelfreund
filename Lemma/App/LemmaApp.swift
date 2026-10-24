import SwiftUI

/// Einstiegspunkt der App.
///
/// `DocumentGroup` liefert alles, was eine Mac-Dokument-App braucht:
/// Ablage-Menü, Sichern, Versionen, zuletzt benutzte Dokumente, Fenster-Tabs.
@main
struct LemmaApp: App {
    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        DocumentGroup(newDocument: { TeXDocument() }) { file in
            DocumentWindow(document: file.document, fileURL: file.fileURL)
        }
        // Neue Fenster öffnen gross genug für Seitenleiste, Editor und Vorschau
        // (macOS verkleinert das automatisch auf kleinen Bildschirmen) und lassen
        // sich nie kleiner ziehen als ihr Inhalt – sonst würde er abgeschnitten.
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}
