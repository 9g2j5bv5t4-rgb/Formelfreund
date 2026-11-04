import LaTeXKit
import SwiftUI

// Eigene Anpassung der Symbolleiste („Darstellung → Symbolleiste anpassen …“).
//
// Warum nicht die eingebaute Anpassung von macOS? Sie gleicht die Symbolleisten
// aller offenen Fenster miteinander ab. Mit SwiftUI-Fenstern stürzte AppKit
// dabei ab, sobald ein zweites Dokument aufging: Die neue Leiste meldete den
// anderen Fenstern Knöpfe, die dort schon vorhanden waren. Deshalb ist die
// Symbolleiste für macOS fest, und Lemma merkt sich selbst, welche Knöpfe in der
// Mitte stehen. Alle diese Knöpfe stecken in *einem* Element der Leiste. Beim
// Anpassen ändert sich nur dessen Inhalt, macOS muss nichts einfügen oder
// entfernen.

/// Ein Knopf, der in der Mitte der Symbolleiste stehen kann.
enum DocumentToolbarButton: String, CaseIterable, Identifiable {
    case formula, inlineFormula, table, matrix, image, list, blocks, symbols
    case bold, italic, underline, comment, find
    case showInPDF, exportPDF, log

    var id: String { rawValue }

    /// So sieht die Leiste aus, bevor jemand etwas ändert.
    static let standard: [DocumentToolbarButton] = [.formula, .table, .matrix, .image, .list, .blocks]

    var title: String {
        switch self {
        case .formula: return "Formel"
        case .inlineFormula: return "Formel im Text"
        case .table: return "Tabelle"
        case .matrix: return "Matrix"
        case .image: return "Bild"
        case .list: return "Liste"
        case .blocks: return "Bausteine"
        case .symbols: return "Zeichen"
        case .bold: return "Fett"
        case .italic: return "Kursiv"
        case .underline: return "Unterstrichen"
        case .comment: return "Kommentar"
        case .find: return "Suchen"
        case .showInPDF: return "Im PDF zeigen"
        case .exportPDF: return "PDF exportieren"
        case .log: return "Protokoll"
        }
    }

    var systemImage: String {
        switch self {
        case .formula: return "function"
        case .inlineFormula: return "x.squareroot"
        case .table: return "tablecells"
        case .matrix: return "square.grid.3x3"
        case .image: return "photo.badge.plus"
        case .list: return "list.bullet"
        case .blocks: return "square.stack.3d.up"
        case .symbols: return "character"
        case .bold: return InlineStyle.bold.symbol
        case .italic: return InlineStyle.italic.symbol
        case .underline: return InlineStyle.underline.symbol
        case .comment: return "percent"
        case .find: return "magnifyingglass"
        case .showInPDF: return "doc.text.magnifyingglass"
        case .exportPDF: return "square.and.arrow.up"
        case .log: return "doc.plaintext"
        }
    }

    /// Kurze Erklärung – als Tooltip und im Fenster „Symbolleiste anpassen“.
    var help: String {
        switch self {
        case .formula: return "Formel einfügen: im Text, abgesetzt, Rechnungen, Matrizen …"
        case .inlineFormula: return "Formel mitten im Satz ($…$), eine Auswahl wird zur Formel"
        case .table: return "Tabelle in beliebiger Grösse einfügen"
        case .matrix: return "Matrix oder Determinante in beliebiger Grösse einfügen"
        case .image: return "Bild aus einer Datei einfügen"
        case .list: return "Aufzählung oder nummerierte Liste einfügen"
        case .blocks: return "Überschriften, Sätze, Verweise, Seitenumbruch und mehr"
        case .symbols: return "Griechische Buchstaben, Vergleiche, Pfeile, Mengen …"
        case .bold: return "Fett (⌘B)"
        case .italic: return "Kursiv (⌘I)"
        case .underline: return "Unterstrichen (⌘U)"
        case .comment: return "Zeilen auskommentieren oder wieder aktivieren (⌘K)"
        case .find: return "Suchen und Ersetzen (⌘F)"
        case .showInPDF: return "Stelle am Cursor im PDF zeigen (⇧⌘J)"
        case .exportPDF: return "PDF exportieren (⇧⌘E)"
        case .log: return "LaTeX-Protokoll anzeigen (⌥⌘L)"
        }
    }
}

/// Welche Knöpfe in welcher Reihenfolge – gespeichert als Text, z. B. „formula,table,image“.
enum DocumentToolbarLayout {
    static let storageKey = "toolbarButtons"
    static let standardValue = value(for: DocumentToolbarButton.standard)

    /// Unbekannte Namen (etwa aus einer neueren Version) und doppelte werden übergangen.
    static func buttons(from value: String) -> [DocumentToolbarButton] {
        var seen = Set<DocumentToolbarButton>()
        return value.split(separator: ",")
            .compactMap { DocumentToolbarButton(rawValue: String($0)) }
            .filter { seen.insert($0).inserted }
    }

    static func value(for buttons: [DocumentToolbarButton]) -> String {
        buttons.map(\.rawValue).joined(separator: ",")
    }
}

// MARK: - Knöpfe in der Symbolleiste

/// Die Knöpfe in der Mitte der Symbolleiste, wie unter „Symbolleiste anpassen“ gewählt.
struct DocumentToolbarButtonBar: View {
    let workspace: DocumentWorkspace
    @AppStorage(DocumentToolbarLayout.storageKey) private var layout = DocumentToolbarLayout.standardValue

    var body: some View {
        let buttons = DocumentToolbarLayout.buttons(from: layout)
        HStack(spacing: 2) {
            if buttons.isEmpty {
                // Ganz leer wäre die Anpassung kaum wiederzufinden.
                Button {
                    workspace.isCustomizingToolbar = true
                } label: {
                    Label("Knöpfe wählen", systemImage: "plus")
                }
                .help("Symbolleiste anpassen …")
            } else {
                ForEach(buttons) { button in
                    DocumentToolbarButtonView(button: button, workspace: workspace)
                }
            }
        }
        .labelStyle(.iconOnly)
        .contextMenu {
            Button("Symbolleiste anpassen …") {
                workspace.isCustomizingToolbar = true
            }
        }
    }
}

/// Ein einzelner Knopf – jeder ruft denselben Befehl auf wie die Menüleiste.
struct DocumentToolbarButtonView: View {
    let button: DocumentToolbarButton
    let workspace: DocumentWorkspace

    var body: some View {
        switch button {
        case .formula:
            Menu {
                FormulaMenuItems(workspace: workspace)
            } label: {
                label
            }
            .help(button.help)
        case .inlineFormula:
            action { workspace.insert(InsertCommands.inlineFormula) }
        case .table:
            ToolbarPopoverButton(title: button.title, systemImage: button.systemImage, help: button.help) {
                TablePicker(workspace: workspace)
            }
        case .matrix:
            ToolbarPopoverButton(title: button.title, systemImage: button.systemImage, help: button.help) {
                MatrixPicker(workspace: workspace)
            }
        case .image:
            action { workspace.insertImageFromFile() }
        case .list:
            Menu {
                ListMenuItems(workspace: workspace)
            } label: {
                label
            }
            .help(button.help)
        case .blocks:
            Menu {
                InsertMenuItems(workspace: workspace)
            } label: {
                label
            }
            .help(button.help)
        case .symbols:
            action { workspace.showInspector(.formula) }
        case .bold:
            styleToggle(.bold)
        case .italic:
            styleToggle(.italic)
        case .underline:
            styleToggle(.underline)
        case .comment:
            action { workspace.toggleComment() }
        case .find:
            action { workspace.showFindBar() }
        case .showInPDF:
            action { workspace.showCursorInPDF() }
                .disabled(!workspace.canSynchronize)
        case .exportPDF:
            action { workspace.exportPDF() }
                .disabled(workspace.pdfData == nil)
        case .log:
            action { workspace.isShowingLog = true }
                .disabled(workspace.lastLog == nil)
        }
    }

    private var label: some View {
        Label(button.title, systemImage: button.systemImage)
    }

    private func action(_ perform: @escaping @MainActor () -> Void) -> some View {
        Button {
            perform()
        } label: {
            label
        }
        .help(button.help)
    }

    private func styleToggle(_ style: InlineStyle) -> some View {
        Toggle(isOn: Binding(
            get: { workspace.formatState.inline.styles.contains(style) },
            set: { _ in workspace.toggle(style) }
        )) {
            label
        }
        .toggleStyle(.button)
        .help(button.help)
    }
}

// MARK: - Fenster „Symbolleiste anpassen“

/// Knöpfe hinzufügen, entfernen und per Ziehen ordnen. Änderungen gelten sofort in allen Fenstern.
struct ToolbarCustomizationSheet: View {
    @AppStorage(DocumentToolbarLayout.storageKey) private var layout = DocumentToolbarLayout.standardValue
    @Environment(\.dismiss) private var dismiss

    private var shown: [DocumentToolbarButton] { DocumentToolbarLayout.buttons(from: layout) }
    private var available: [DocumentToolbarButton] { DocumentToolbarButton.allCases.filter { !shown.contains($0) } }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Symbolleiste anpassen")
                    .font(.title3.weight(.semibold))
                Text("Wähle die Knöpfe für die Mitte der Symbolleiste. Die Reihenfolge änderst du durch Ziehen. Status, Kompilieren, Vorschau und Format stehen immer rechts.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            List {
                Section("In der Symbolleiste") {
                    if shown.isEmpty {
                        Text("Noch keine Knöpfe – füge unten welche hinzu.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(shown) { button in
                        row(button, isShown: true)
                    }
                    .onMove { source, destination in
                        var buttons = shown
                        buttons.move(fromOffsets: source, toOffset: destination)
                        layout = DocumentToolbarLayout.value(for: buttons)
                    }
                }
                Section("Weitere Knöpfe") {
                    if available.isEmpty {
                        Text("Alle Knöpfe sind in der Symbolleiste.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(available) { button in
                        row(button, isShown: false)
                    }
                }
            }
            .listStyle(.inset)

            Divider()
            HStack {
                Button("Standard wiederherstellen") {
                    withAnimation { layout = DocumentToolbarLayout.standardValue }
                }
                .disabled(layout == DocumentToolbarLayout.standardValue)
                Spacer()
                Button("Fertig") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 440, height: 560)
    }

    private func row(_ button: DocumentToolbarButton, isShown: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: button.systemImage)
                .font(.system(size: 15))
                .frame(width: 24)
                .foregroundStyle(isShown ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(button.title)
                Text(button.help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation { toggle(button) }
            } label: {
                Image(systemName: isShown ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isShown ? Color.red : Color.green)
            }
            .buttonStyle(.borderless)
            .help(isShown ? "Aus der Symbolleiste entfernen" : "Zur Symbolleiste hinzufügen")
            .accessibilityLabel(isShown ? "\(button.title) entfernen" : "\(button.title) hinzufügen")
        }
        .padding(.vertical, 3)
    }

    private func toggle(_ button: DocumentToolbarButton) {
        var buttons = shown
        if let index = buttons.firstIndex(of: button) {
            buttons.remove(at: index)
        } else {
            buttons.append(button)
        }
        layout = DocumentToolbarLayout.value(for: buttons)
    }
}
