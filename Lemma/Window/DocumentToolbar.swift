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
///   Diese Knöpfe lassen sich über „Darstellung → Symbolleiste anpassen“
///   ändern; Fett, Kursiv, Suchen u. a. stehen dort zusätzlich zur Wahl.
/// - Rechts, immer sichtbar: Status, Kompilieren, Vorschau, Format-Seitenleiste.
/// Jeder Knopf hat einen Befehl in der Menüleiste.
struct DocumentToolbar: CustomizableToolbarContent {
    let workspace: DocumentWorkspace

    var body: some CustomizableToolbarContent {
        insertItems
        optionalItems
        trailingItems
    }

    /// Mitte: Einfügen.
    @ToolbarContentBuilder
    private var insertItems: some CustomizableToolbarContent {
        ToolbarItem(id: "insert.formula", placement: .principal) {
            Menu {
                FormulaMenuItems(workspace: workspace)
            } label: {
                Label("Formel", systemImage: "function")
            }
            .help("Formel einfügen")
        }
        ToolbarItem(id: "insert.table", placement: .principal) {
            ToolbarPopoverButton(title: "Tabelle", systemImage: "tablecells", help: "Tabelle in beliebiger Grösse einfügen") {
                TablePicker(workspace: workspace)
            }
        }
        ToolbarItem(id: "insert.matrix", placement: .principal) {
            ToolbarPopoverButton(title: "Matrix", systemImage: "square.grid.3x3", help: "Matrix oder Determinante in beliebiger Grösse einfügen") {
                MatrixPicker(workspace: workspace)
            }
        }
        ToolbarItem(id: "insert.image", placement: .principal) {
            Button {
                workspace.insertImageFromFile()
            } label: {
                Label("Bild", systemImage: "photo.badge.plus")
            }
            .help("Bild aus einer Datei einfügen")
        }
        ToolbarItem(id: "insert.list", placement: .principal) {
            Menu {
                ListMenuItems(workspace: workspace)
            } label: {
                Label("Liste", systemImage: "list.bullet")
            }
            .help("Aufzählung oder nummerierte Liste einfügen")
        }
        ToolbarItem(id: "insert.blocks", placement: .principal) {
            Menu {
                InsertMenuItems(workspace: workspace)
            } label: {
                Label("Bausteine", systemImage: "square.stack.3d.up")
            }
            .help("Überschriften, Sätze, Verweise, Seitenumbruch und mehr")
        }

    }

    /// Zur Auswahl beim Anpassen der Symbolleiste.
    @ToolbarContentBuilder
    private var optionalItems: some CustomizableToolbarContent {
        ToolbarItem(id: "format.bold", placement: .principal, showsByDefault: false) {
            styleToggle(.bold)
        }
        ToolbarItem(id: "format.italic", placement: .principal, showsByDefault: false) {
            styleToggle(.italic)
        }
        ToolbarItem(id: "format.underline", placement: .principal, showsByDefault: false) {
            styleToggle(.underline)
        }
        ToolbarItem(id: "insert.symbols", placement: .principal, showsByDefault: false) {
            Button {
                workspace.showInspector(.formula)
            } label: {
                Label("Zeichen", systemImage: "character")
            }
            .help("Griechische Buchstaben, Vergleiche, Pfeile, Mengen …")
        }
        ToolbarItem(id: "edit.find", placement: .principal, showsByDefault: false) {
            Button {
                workspace.showFindBar()
            } label: {
                Label("Suchen", systemImage: "magnifyingglass")
            }
            .help("Suchen und Ersetzen (⌘F)")
        }
        ToolbarItem(id: "edit.comment", placement: .principal, showsByDefault: false) {
            Button {
                workspace.toggleComment()
            } label: {
                Label("Kommentar", systemImage: "percent")
            }
            .help("Zeilen auskommentieren oder wieder aktivieren (⌘/)")
        }

    }

    /// Rechts, immer sichtbar: Status, Kompilieren, Ansicht.
    @ToolbarContentBuilder
    private var trailingItems: some CustomizableToolbarContent {
        ToolbarItem(id: "status", placement: .primaryAction) {
            CompileStatusView(workspace: workspace)
        }
        ToolbarItem(id: "compile", placement: .primaryAction) {
            Button {
                workspace.compile()
            } label: {
                Label("Kompilieren", systemImage: "play.fill")
            }
            .help("Dokument kompilieren (⌘↩)")
        }
        ToolbarItem(id: "view.preview", placement: .primaryAction) {
            Toggle(isOn: Binding(
                get: { workspace.showsPreview },
                set: { workspace.showsPreview = $0 }
            )) {
                Label("Vorschau", systemImage: "doc.richtext")
            }
            .help("PDF-Vorschau ein- oder ausblenden (⌥⌘P)")
        }
        ToolbarItem(id: "view.format", placement: .primaryAction) {
            Toggle(isOn: Binding(
                get: { workspace.showsInspector },
                set: { workspace.showsInspector = $0 }
            )) {
                Label("Format", systemImage: "paintbrush")
            }
            .help("Format-Seitenleiste: Text, Formeln und Layout (⌥⌘I)")
        }
    }

    private func styleToggle(_ style: InlineStyle) -> some View {
        Toggle(isOn: Binding(
            get: { workspace.formatState.inline.styles.contains(style) },
            set: { _ in workspace.toggle(style) }
        )) {
            Label(style.title, systemImage: style.symbol)
        }
        .help(style.title)
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
