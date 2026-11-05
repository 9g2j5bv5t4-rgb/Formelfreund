import AppKit
import LaTeXKit
import SwiftUI

/// Damit Menübefehle wissen, welches Dokumentfenster gerade vorne ist.
extension FocusedValues {
    @Entry var workspace: DocumentWorkspace?
}

/// Menüs und Tastaturkürzel.
struct AppCommands: Commands {
    @FocusedValue(\.workspace) private var workspace
    @AppStorage(AppSettings.Keys.autoCompile) private var autoCompile = AppSettings.Defaults.autoCompile
    @AppStorage(AppSettings.Keys.editorFontSize) private var fontSize = AppSettings.Defaults.editorFontSize
    @AppStorage(AppSettings.Keys.showWordCount) private var showWordCount = AppSettings.Defaults.showWordCount
    @AppStorage(AppSettings.Keys.mathPreview) private var mathPreview = AppSettings.Defaults.mathPreview
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Neu aus Vorlage …") {
                openWindow(id: TemplateGallery.windowID)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(after: .textEditing) {
            Button("Vorschläge zeigen") {
                workspace?.showCompletions()
            }
            .disabled(workspace == nil)
        }

        // „Speichern“ statt „Sichern“ – mit Bestätigung im Fenster.
        CommandGroup(replacing: .saveItem) {
            Button("Speichern") { workspace?.saveDocument() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(workspace == nil)
            Button("Speichern unter …") { workspace?.saveDocument(asNewFile: true) }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(workspace == nil)
            Button("Duplizieren") { send("duplicateDocument:") }
                .disabled(workspace == nil)
            Button("Umbenennen …") { send("renameDocument:") }
                .disabled(workspace == nil)
            Button("Bewegen nach …") { send("moveDocument:") }
                .disabled(workspace == nil)
            Divider()
            Button("Zurück zur zuletzt gespeicherten Version") { send("revertDocumentToSaved:") }
                .disabled(workspace == nil)
            Button("Alle Versionen durchsuchen …") { send("browseDocumentVersions:") }
                .disabled(workspace == nil)
        }

        CommandMenu("Dokument") {
            Button("Kompilieren") {
                workspace?.compile()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(workspace == nil)

            Toggle("Automatisch kompilieren", isOn: $autoCompile)

            Divider()

            Button("Position im PDF zeigen") {
                workspace?.showCursorInPDF()
            }
            .keyboardShortcut("j", modifiers: [.command, .shift])
            .disabled(workspace?.canSynchronize != true)

            Button("PDF exportieren …") {
                workspace?.exportPDF()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(workspace?.pdfData == nil)

            Divider()

            Button("Protokoll anzeigen") {
                workspace?.isShowingLog = true
            }
            // ⌥⌘L gehört „Quelltext formatieren“ (wie in IntelliJ).
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .disabled(workspace?.lastLog == nil)
        }

        CommandMenu("Format") {
            FormatMenuContent(workspace: workspace)
        }

        // Alles, was Symbolleiste und Format-Seitenleiste einfügen können.
        CommandMenu("Einfügen") {
            Group {
                FormulaMenuItems(workspace: workspace)
                Divider()
                Button("Tabelle …") { workspace?.presentStructure(.table) }
                Menu("Liste") {
                    ListMenuItems(workspace: workspace)
                }
                Divider()
                InsertMenuItems(workspace: workspace)
            }
            .disabled(workspace == nil)
        }

        // Eigene Anpassung statt der von macOS (Begründung in ToolbarCustomization.swift).
        CommandGroup(replacing: .toolbar) {
            Button("Symbolleiste ein-/ausblenden") {
                NSApp.sendAction(#selector(NSWindow.toggleToolbarShown(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("t", modifiers: [.command, .option])
            .disabled(workspace == nil)

            Button("Symbolleiste anpassen …") {
                workspace?.isCustomizingToolbar = true
            }
            .disabled(workspace == nil)
        }

        CommandGroup(after: .sidebar) {
            Button(workspace?.showsInspector == true ? "Format-Seitenleiste ausblenden" : "Format-Seitenleiste einblenden") {
                workspace?.showsInspector.toggle()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            .disabled(workspace == nil)

            Menu("Format-Seitenleiste zeigen") {
                ForEach(InspectorTab.allCases) { tab in
                    Button(tab.title) { workspace?.showInspector(tab) }
                }
            }
            .disabled(workspace == nil)

            Button(workspace?.showsPreview == false ? "PDF-Vorschau einblenden" : "PDF-Vorschau ausblenden") {
                workspace?.showsPreview.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])
            .disabled(workspace == nil)

            Divider()

            // Wie in Xcode: ⌥⌘← / ⌥⌘→, mit ⇧ für alles.
            Menu("Einklappen") {
                Button("Abschnitt einklappen") { workspace?.foldAtCursor() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                Button("Abschnitt aufklappen") { workspace?.unfoldAtCursor() }
                    .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                Divider()
                Button("Alle einklappen") { workspace?.foldAll() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command, .option, .shift])
                Button("Alle aufklappen") { workspace?.unfoldAll() }
                    .keyboardShortcut(.rightArrow, modifiers: [.command, .option, .shift])
            }
            .disabled(workspace == nil)

            Toggle("Wortanzahl zeigen", isOn: $showWordCount)
            Toggle("Formelvorschau beim Tippen", isOn: $mathPreview)

            Divider()

            Button("Schrift vergrössern") {
                fontSize = min(fontSize + 1, AppSettings.fontSizeRange.upperBound)
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Schrift verkleinern") {
                fontSize = max(fontSize - 1, AppSettings.fontSizeRange.lowerBound)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Originalgrösse") {
                fontSize = AppSettings.Defaults.editorFontSize
            }
            .keyboardShortcut("0", modifiers: .command)

            Divider()
        }
    }

    /// Schickt eine Aktion von NSDocument an das vorderste Dokument.
    private func send(_ action: String) {
        NSApp.sendAction(NSSelectorFromString(action), to: nil, from: nil)
    }
}
