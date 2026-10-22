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

    var body: some Commands {
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
            .keyboardShortcut("l", modifiers: [.command, .option])
            .disabled(workspace?.lastLog == nil)
        }

        CommandGroup(after: .sidebar) {
            Button(workspace?.showsPreview == false ? "PDF-Vorschau einblenden" : "PDF-Vorschau ausblenden") {
                workspace?.showsPreview.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])
            .disabled(workspace == nil)

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
}
