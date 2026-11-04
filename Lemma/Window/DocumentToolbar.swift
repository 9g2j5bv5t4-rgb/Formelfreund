import LaTeXKit
import SwiftUI

/// Bausteine, die nicht im Katalog stehen, aber an mehreren Stellen gebraucht werden.
enum InsertCommands {
    /// `$…$` um die Auswahl bzw. mit Platzhalter – eine Formel mitten im Satz.
    static let inlineFormula = Snippet(
        id: "insert.inlineFormula",
        title: "Formel im Text",
        category: .formulas,
        body: "$\(Snippet.selectionToken)$",
        placement: .inline,
        help: "Formel mitten im Satz, z. B. $a^2 + b^2 = c^2$. Eine Auswahl wird zur Formel."
    )
}

/// Symbolleiste des Dokumentfensters – wie in Pages und Keynote.
///
/// - Mitte: frei wählbare Knöpfe, ab Werk Formel, Tabelle, Matrix, Bild, Liste
///   und Bausteine. Anpassbar über „Darstellung → Symbolleiste anpassen …“ oder
///   einen Rechtsklick (siehe `ToolbarCustomization.swift`).
/// - Rechts: Status, Kompilieren, Vorschau, Format-Seitenleiste.
/// Jeder Knopf hat einen Befehl in der Menüleiste.
///
/// Für macOS ist die Leiste bewusst fest (kein `.toolbar(id:)`): Die eingebaute
/// Anpassung gleicht die Leisten aller Fenster ab, und dabei stürzte AppKit beim
/// Öffnen eines zweiten Dokuments ab. Die Elemente hier sind in jedem Fenster
/// dieselben und ändern sich nie, nur der Inhalt der Knopfreihe in der Mitte.
struct DocumentToolbar: ToolbarContent {
    let workspace: DocumentWorkspace

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            DocumentToolbarButtonBar(workspace: workspace)
        }

        ToolbarItem(placement: .status) {
            CompileStatusView(workspace: workspace)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                workspace.compile()
            } label: {
                Label("Kompilieren", systemImage: "play.fill")
            }
            .help("Dokument kompilieren (⌘↩)")
            Toggle(isOn: Binding(
                get: { workspace.showsPreview },
                set: { workspace.showsPreview = $0 }
            )) {
                Label("Vorschau", systemImage: "doc.richtext")
            }
            .help("PDF-Vorschau ein- oder ausblenden (⌥⌘P)")
            Toggle(isOn: Binding(
                get: { workspace.showsInspector },
                set: { workspace.showsInspector = $0 }
            )) {
                Label("Format", systemImage: "paintbrush")
            }
            .help("Format-Seitenleiste: Text, Formeln und Layout (⌥⌘I)")
        }
    }
}

/// Knopf der Symbolleiste, der ein Auswahlfenster öffnet.
struct ToolbarPopoverButton<Content: View>: View {
    let title: String
    let systemImage: String
    let help: String
    @ViewBuilder let content: () -> Content
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label(title, systemImage: systemImage)
        }
        .help(help)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            content()
        }
    }
}

// MARK: - Menüs (Symbolleiste und Menüleiste)

/// Einträge für „Formel“ – in der Symbolleiste und im Menü „Einfügen“.
struct FormulaMenuItems: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        Button {
            workspace?.insert(InsertCommands.inlineFormula)
        } label: {
            Label("Formel im Text", systemImage: "function")
        }
        snippetButton("display.unnumbered", title: "Abgesetzte Formel")
        snippetButton("display.equation", title: "Nummerierte Formel")
        Divider()
        Button("Mehrzeilige Rechnung …") { workspace?.presentStructure(.counted(.alignedEquations)) }
        Button("Gleichungssystem …") { workspace?.presentStructure(.counted(.equationSystem)) }
        Button("Fallunterscheidung …") { workspace?.presentStructure(.counted(.cases)) }
        Button("Matrix …") { workspace?.presentStructure(.matrix) }
        Button("Vektor …") { workspace?.presentStructure(.counted(.vector)) }
        Divider()
        Menu("Bausteine") {
            ForEach(SnippetCatalog.snippets(in: .formulas)) { snippet in
                Button {
                    workspace?.insert(snippet)
                } label: {
                    if let symbol = snippet.symbol {
                        Label(snippet.title, systemImage: symbol)
                    } else {
                        Text(snippet.title)
                    }
                }
            }
        }
        Button("Zeichen …") { workspace?.showInspector(.formula) }
    }

    @ViewBuilder
    private func snippetButton(_ id: String, title: String) -> some View {
        if let snippet = SnippetCatalog.snippet(withID: id) {
            Button {
                workspace?.insert(snippet)
            } label: {
                if let symbol = snippet.symbol {
                    Label(title, systemImage: symbol)
                } else {
                    Text(title)
                }
            }
        }
    }
}

/// Einträge für „Liste“ – in der Symbolleiste und im Menü „Einfügen“.
struct ListMenuItems: View {
    let workspace: DocumentWorkspace?

    var body: some View {
        ForEach(SnippetCatalog.snippets(in: .lists)) { snippet in
            Button {
                workspace?.insert(snippet)
            } label: {
                if let symbol = snippet.symbol {
                    Label(snippet.title, systemImage: symbol)
                } else {
                    Text(snippet.title)
                }
            }
        }
        Divider()
        Button("Liste mit mehreren Punkten …") { workspace?.presentStructure(.counted(.list)) }
    }
}
