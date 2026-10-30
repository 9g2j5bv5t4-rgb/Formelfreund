import LaTeXKit
import SwiftUI

/// Inhalt des Menüs „Format“ in der Menüleiste.
///
/// Dieselben Aktionen wie in der Format-Leiste, ergänzt um Tastaturkürzel.
struct FormatMenuContent: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        Group {
            content
        }
        .disabled(workspace == nil)
    }

    @ViewBuilder
    private var content: some View {
        Menu("Absatzstil") {
            ForEach(Array(ParagraphStyle.allCases.enumerated()), id: \.element) { index, style in
                Button(style.title) { workspace?.applyParagraphStyle(style) }
                    .keyboardShortcut(KeyEquivalent(Character(String(index))), modifiers: [.command, .option])
            }
        }

        Divider()

        Button("Fett") { workspace?.toggle(.bold) }
            .keyboardShortcut("b", modifiers: .command)
        Button("Kursiv") { workspace?.toggle(.italic) }
            .keyboardShortcut("i", modifiers: .command)
        Button("Unterstrichen") { workspace?.toggle(.underline) }
            .keyboardShortcut("u", modifiers: .command)

        Menu("Schriftstil") {
            ForEach([InlineStyle.emphasis, .sansSerif, .monospace, .smallCaps]) { style in
                Button(style.title) { workspace?.toggle(style) }
            }
        }
        Menu("Schriftgrösse") {
            ForEach(FontSize.allCases) { size in
                Button(size.title) { workspace?.setFontSize(size) }
            }
        }
        Menu("Textfarbe") {
            ColorMenuItems(workspace: workspace)
        }

        Divider()

        Menu("Ausrichtung") {
            ForEach(TextAlignment.allCases) { alignment in
                Button(alignment.title) { workspace?.align(alignment) }
            }
        }
        Menu("Liste") {
            ForEach(ListKind.allCases) { kind in
                Button(kind.title) { workspace?.toggleList(kind) }
            }
        }
        Button("Einrücken") { workspace?.shiftIndentation(outdent: false) }
            .keyboardShortcut("]", modifiers: .command)
        Button("Ausrücken") { workspace?.shiftIndentation(outdent: true) }
            .keyboardShortcut("[", modifiers: .command)

        Divider()

        Menu("Block") {
            Button("Block auswählen") { workspace?.expandSelection() }
                .keyboardShortcut("a", modifiers: [.command, .option])
            Button("Formel nummerieren ein/aus") { workspace?.toggleNumbering() }
            // ⌥⌘M ist unter macOS „Alle Fenster im Dock ablegen“ – daher ⇧⌘M.
            Button("Formel abgesetzt ↔ im Text") { workspace?.toggleDisplayMath() }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            Button("Umgebung auflösen (Inhalt behalten)") { workspace?.unwrapEnvironment() }
            WrapMenuItems(workspace: workspace)
            Divider()
            Button("Zeilen nach oben") { workspace?.moveLines(up: true) }
                .keyboardShortcut(.upArrow, modifiers: [.command, .option])
            Button("Zeilen nach unten") { workspace?.moveLines(up: false) }
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
        }
        Button("Auskommentieren ein/aus") { workspace?.toggleComment() }
            .keyboardShortcut("/", modifiers: .command)

        Divider()

        // Seite und Dokument (Register „Layout“ der Format-Seitenleiste).
        Picker("Ränder und Abstand gelten für", selection: Binding(
            get: { workspace?.layoutScope ?? .document },
            set: { workspace?.layoutScope = $0 }
        )) {
            ForEach(LayoutScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        Button("Seitenränder …") { workspace?.showInspector(.layout) }
        Button("Zeilenabstand …") { workspace?.showInspector(.layout) }
        Button("Schrift und Papier …") { workspace?.showInspector(.layout) }
    }
}
