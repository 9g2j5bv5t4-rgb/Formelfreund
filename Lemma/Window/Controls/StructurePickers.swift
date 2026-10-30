import LaTeXKit
import SwiftUI

// Auswahlfenster für Bausteine in freier Grösse (Tabellen, Matrizen,
// Gleichungen, Listen): mit der Maus über ein Raster fahren und klicken –
// oder die Werte genau einstellen. Sie erscheinen als Popover an Knöpfen der
// Symbolleiste und Seitenleiste oder als Dialog aus der Menüleiste.

extension EnvironmentValues {
    /// Das Auswahlfenster ist ein Dialog (aus der Menüleiste) und braucht „Abbrechen“.
    @Entry var pickerIsSheet = false
}

// MARK: - Raster zum Aufziehen

/// Raster aus Kästchen: Mit der Maus die Grösse aufziehen, mit einem Klick übernehmen.
struct GridSizePicker: View {
    let maxRows: Int
    let maxColumns: Int
    @Binding var rows: Int
    @Binding var columns: Int
    /// Beschriftung über dem Raster, z. B. „3 × 4“.
    let label: String
    let pick: () -> Void

    private let cell: CGFloat = 17
    private let spacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .contentTransition(.numericText())
            VStack(spacing: spacing) {
                ForEach(0..<maxRows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<maxColumns, id: \.self) { column in
                            let isOn = row < rows && column < columns
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(isOn ? Color.accentColor.opacity(0.8) : Color.primary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .strokeBorder(isOn ? Color.accentColor : Color.primary.opacity(0.14), lineWidth: 1)
                                )
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                guard case .active(let location) = phase else { return }
                let column = min(maxColumns, max(1, Int(location.x / (cell + spacing)) + 1))
                let row = min(maxRows, max(1, Int(location.y / (cell + spacing)) + 1))
                if row != rows { rows = row }
                if column != columns { columns = column }
            }
            .onTapGesture(perform: pick)
            .accessibilityElement()
            .accessibilityLabel("Grösse wählen")
            .accessibilityValue(label)
        }
    }
}

/// Überschrift eines Auswahlfensters.
struct PickerHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// „Einfügen“ unten rechts – im Dialog zusätzlich „Abbrechen“.
private struct InsertButton: View {
    let action: () -> Void
    @Environment(\.pickerIsSheet) private var isSheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Spacer()
            if isSheet {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            Button("Einfügen", action: action)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Tabelle

struct TablePicker: View {
    let workspace: DocumentWorkspace
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tableStyle") private var style: TableLineStyle = .grid
    @AppStorage("tableAlignment") private var alignment: TableCellAlignment = .center
    @AppStorage("tableHeader") private var hasHeader = true
    @AppStorage("tableCaption") private var hasCaption = true
    @State private var rows = 3
    @State private var columns = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PickerHeader(title: "Tabelle einfügen", subtitle: "Grösse mit der Maus aufziehen und klicken – oder unten genau einstellen.")
            GridSizePicker(
                maxRows: 8, maxColumns: 10, rows: $rows, columns: $columns,
                label: "\(rows) Zeilen × \(columns) Spalten", pick: insert
            )
            Divider()
            HStack(spacing: 16) {
                Stepper("Zeilen: \(rows)", value: $rows, in: 1...StructureGenerator.maximumSize)
                Stepper("Spalten: \(columns)", value: $columns, in: 1...StructureGenerator.maximumSize)
            }
            .monospacedDigit()
            Picker("Linien", selection: $style) {
                ForEach(TableLineStyle.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Inhalt", selection: $alignment) {
                ForEach(TableCellAlignment.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Toggle("Erste Zeile als Kopfzeile (fett)", isOn: $hasHeader)
            Toggle("Mit Beschriftung („Tabelle 1: …“)", isOn: $hasCaption)
            InsertButton(action: insert)
        }
        .padding(14)
        .frame(width: 330)
    }

    private func insert() {
        dismiss()
        workspace.insert(StructureGenerator.table(LaTeXKit.TableOptions(
            rows: rows, columns: columns, style: style, alignment: alignment, hasHeader: hasHeader, hasCaption: hasCaption
        )))
    }
}

// MARK: - Matrix

struct MatrixPicker: View {
    let workspace: DocumentWorkspace
    @Environment(\.dismiss) private var dismiss
    @AppStorage("matrixDelimiter") private var delimiter: MatrixDelimiter = .parentheses
    @State private var rows = 2
    @State private var columns = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PickerHeader(
                title: delimiter == .bars ? "Determinante einfügen" : "Matrix einfügen",
                subtitle: workspace.formatState.inMath
                    ? "Kommt kompakt in die Formel am Cursor."
                    : "Kommt als abgesetzte Formel auf eigene Zeilen."
            )
            GridSizePicker(
                maxRows: 8, maxColumns: 8, rows: $rows, columns: $columns,
                label: "\(rows) × \(columns)", pick: insert
            )
            Divider()
            HStack(spacing: 16) {
                Stepper("Zeilen: \(rows)", value: $rows, in: 1...StructureGenerator.maximumSize)
                Stepper("Spalten: \(columns)", value: $columns, in: 1...StructureGenerator.maximumSize)
            }
            .monospacedDigit()
            VStack(alignment: .leading, spacing: 6) {
                Text("Klammern")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(MatrixDelimiter.allCases) { option in
                        DelimiterChip(delimiter: option, isSelected: option == delimiter) {
                            delimiter = option
                        }
                    }
                }
            }
            InsertButton(action: insert)
        }
        .padding(14)
        .frame(width: 320)
    }

    private func insert() {
        dismiss()
        workspace.insert(StructureGenerator.matrix(
            rows: rows, columns: columns, delimiter: delimiter, displayed: !workspace.formatState.inMath
        ))
    }
}

/// Kachel mit der Klammerart einer Matrix, z. B. „( ⋯ )“.
private struct DelimiterChip: View {
    let delimiter: MatrixDelimiter
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 1) {
                Text(verbatim: delimiter.glyphs.open)
                Text(verbatim: "⋯").foregroundStyle(.secondary)
                Text(verbatim: delimiter.glyphs.close)
            }
            .font(.system(size: 15, design: .serif))
            .frame(width: 38, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(isHovered ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(delimiter.title)
        .accessibilityLabel(delimiter.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Gleichungen, Fälle, Listen, Vektoren

/// Bausteine, bei denen man nur die Anzahl wählt.
enum CountedStructure {
    case equationSystem
    case cases
    case alignedEquations
    case list
    case vector

    var title: String {
        switch self {
        case .equationSystem: return "Gleichungssystem einfügen"
        case .cases: return "Fallunterscheidung einfügen"
        case .alignedEquations: return "Mehrzeilige Rechnung einfügen"
        case .list: return "Liste einfügen"
        case .vector: return "Vektor einfügen"
        }
    }

    var subtitle: String {
        switch self {
        case .equationSystem: return "Gleichungen untereinander, links mit geschweifter Klammer."
        case .cases: return "Für stückweise definierte Funktionen; der letzte Fall heisst „sonst“."
        case .alignedEquations: return "Zeilen werden an den Gleichheitszeichen ausgerichtet."
        case .list: return "Aufzählung mit Punkten oder Nummern."
        case .vector: return "Spaltenvektor – kommt in die Formel am Cursor."
        }
    }

    func label(_ count: Int) -> String {
        switch self {
        case .equationSystem: return count == 1 ? "1 Gleichung" : "\(count) Gleichungen"
        case .cases: return count == 1 ? "1 Fall" : "\(count) Fälle"
        case .alignedEquations: return count == 1 ? "1 Zeile" : "\(count) Zeilen"
        case .list: return count == 1 ? "1 Punkt" : "\(count) Punkte"
        case .vector: return count == 1 ? "1 Eintrag" : "\(count) Einträge"
        }
    }

    var defaultCount: Int {
        switch self {
        case .equationSystem, .cases: return 2
        case .alignedEquations, .list, .vector: return 3
        }
    }
}

struct CountedStructurePicker: View {
    let structure: CountedStructure
    let workspace: DocumentWorkspace
    @Environment(\.dismiss) private var dismiss
    @AppStorage("alignedNumbered") private var numbered = false
    @AppStorage("listKind") private var listKind: ListKind = .itemize
    @State private var count: Int
    @State private var unused = 1

    init(structure: CountedStructure, workspace: DocumentWorkspace) {
        self.structure = structure
        self.workspace = workspace
        _count = State(initialValue: structure.defaultCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PickerHeader(title: structure.title, subtitle: structure.subtitle)
            // Eine Reihe Kästchen: Anzahl mit der Maus wählen.
            GridSizePicker(
                maxRows: 1, maxColumns: 10, rows: $unused, columns: $count,
                label: structure.label(count), pick: insert
            )
            Divider()
            Stepper("Anzahl: \(count)", value: $count, in: 1...StructureGenerator.maximumSize)
                .monospacedDigit()
            switch structure {
            case .alignedEquations:
                Toggle("Jede Zeile nummerieren", isOn: $numbered)
            case .list:
                Picker("Art", selection: $listKind) {
                    ForEach(ListKind.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            default:
                EmptyView()
            }
            InsertButton(action: insert)
        }
        .padding(14)
        .frame(width: 300)
    }

    private func insert() {
        dismiss()
        let snippet: Snippet
        switch structure {
        case .equationSystem: snippet = StructureGenerator.equationSystem(equations: count)
        case .cases: snippet = StructureGenerator.cases(count)
        case .alignedEquations: snippet = StructureGenerator.alignedEquations(count, numbered: numbered)
        case .list: snippet = StructureGenerator.list(listKind, items: count)
        case .vector: snippet = StructureGenerator.vector(components: count)
        }
        workspace.insert(snippet)
    }
}

// MARK: - Vorschauen für Ränder und Zeilenabstand

/// Kleine Seite mit gestricheltem Satzspiegel – zeigt die Ränder massstäblich (A4).
struct MarginsPreview: View {
    /// `nil` = Standard der Dokumentklasse (etwa 4 cm links/rechts bei article).
    let sizes: MarginSizes?
    let width: CGFloat

    var body: some View {
        let scale = width / 21
        let margins = sizes ?? MarginSizes(top: 4.2, bottom: 4.5, left: 4.4, right: 4.4)
        let top = margins.top * scale, bottom = margins.bottom * scale
        let left = margins.left * scale, right = margins.right * scale
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            VStack(alignment: .leading, spacing: max(1.5, width / 30)) {
                ForEach(0..<12, id: \.self) { index in
                    // Jede vierte Zeile kürzer – wie das Ende eines Absatzes.
                    Capsule()
                        .fill(Color.gray.opacity(0.45))
                        .frame(height: max(1, width / 60))
                        .padding(.trailing, index % 4 == 3 ? width * 0.15 : 0)
                }
            }
            .padding(EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right))
            .frame(width: width, height: width * 1.414, alignment: .top)
            .clipped()
            Rectangle()
                .strokeBorder(Color.accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 0.75, dash: [2, 2]))
                .padding(EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right))
        }
        .frame(width: width, height: width * 1.414)
        .animation(.easeInOut(duration: 0.12), value: sizes)
        .accessibilityHidden(true)
    }
}

/// Ein paar Textzeilen mit dem gewählten Abstand.
struct SpacingPreview: View {
    let stretch: Double
    let width: CGFloat

    var body: some View {
        let lineHeight = max(1.5, width / 26)
        VStack(alignment: .leading, spacing: lineHeight * 1.6 * stretch) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: index == 4 ? width * 0.45 : width * 0.8, height: lineHeight)
            }
        }
        .frame(width: width, height: width * 0.62, alignment: .top)
        .padding(.top, width * 0.1)
        .background(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                .frame(width: width, height: width * 0.72)
                .frame(maxHeight: .infinity, alignment: .top)
        )
        .clipped()
        .animation(.easeInOut(duration: 0.12), value: stretch)
        .accessibilityHidden(true)
    }
}
