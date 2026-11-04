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
/// - Mitte: Einfügen (Formel, Tabelle, Matrix, Bild, Liste, Bausteine).
/// - Rechts: Status, Kompilieren, Vorschau, Format-Seitenleiste.
/// Jeder Knopf hat einen Befehl in der Menüleiste.
///
/// Bewusst *nicht* anpassbar (`.toolbar(id:)`): macOS gleicht anpassbare
/// Symbolleisten zwischen allen Fenstern ab, und beim Öffnen eines zweiten
/// Dokuments stürzte AppKit dabei ab (NSToolbar fügte Knöpfe an einer Stelle
/// ein, die es im anderen Fenster nicht gab).
struct DocumentToolbar: ToolbarContent {
    let workspace: DocumentWorkspace

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Menu {
                FormulaMenuItems(workspace: workspace)
            } label: {
                Label("Formel", systemImage: "function")
            }
            .help("Formel einfügen")
            ToolbarPopoverButton(title: "Tabelle", systemImage: "tablecells", help: "Tabelle in beliebiger Grösse einfügen") {
                TablePicker(workspace: workspace)
            }
            ToolbarPopoverButton(title: "Matrix", systemImage: "square.grid.3x3", help: "Matrix oder Determinante in beliebiger Grösse einfügen") {
                MatrixPicker(workspace: workspace)
            }
            Button {
                workspace.insertImageFromFile()
            } label: {
                Label("Bild", systemImage: "photo.badge.plus")
            }
            .help("Bild aus einer Datei einfügen")
            Menu {
                ListMenuItems(workspace: workspace)
            } label: {
                Label("Liste", systemImage: "list.bullet")
            }
            .help("Aufzählung oder nummerierte Liste einfügen")
            Menu {
                InsertMenuItems(workspace: workspace)
            } label: {
                Label("Bausteine", systemImage: "square.stack.3d.up")
            }
            .help("Überschriften, Sätze, Verweise, Seitenumbruch und mehr")
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
