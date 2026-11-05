import SwiftUI

/// Einstiegspunkt der App.
///
/// `DocumentGroup` liefert alles, was eine Mac-Dokument-App braucht:
/// Ablage-Menü, Sichern, Versionen, zuletzt benutzte Dokumente, Fenster-Tabs.
@main
struct LemmaApp: App {
    init() {
        AppSettings.registerDefaults()
        SelfTest.startWatchdog()
    }

    var body: some Scene {
        // Neue Dokumente beginnen leer – oder mit der in der Vorlagen-Galerie gewählten Vorlage.
        DocumentGroup(newDocument: { TeXDocument(text: PendingTemplate.shared.take() ?? TeXDocument.starterText) }) { file in
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

        // „Ablage → Neu aus Vorlage …“
        Window("Neues Dokument", id: TemplateGallery.windowID) {
            TemplateGallery()
        }
        .defaultSize(width: 780, height: 620)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled)

        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}
