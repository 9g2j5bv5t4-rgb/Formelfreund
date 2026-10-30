import LaTeXKit
import SwiftUI

/// Register der Format-Seitenleiste.
enum InspectorTab: String, CaseIterable, Identifiable {
    case text
    case formula
    case layout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text"
        case .formula: return "Formel"
        case .layout: return "Layout"
        }
    }
}

/// Format-Seitenleiste rechts – wie „Format“ in Pages und Keynote.
///
/// Oben wählt ein Segmentschalter das Register; darunter stehen die passenden
/// Einstellungen in Gruppen. Alles wirkt sofort und lässt sich mit ⌘Z
/// rückgängig machen. Jede Funktion ist zusätzlich über die Menüleiste erreichbar.
struct FormatInspector: View {
    let workspace: DocumentWorkspace

    var body: some View {
        VStack(spacing: 0) {
            Picker("Register", selection: Binding(
                get: { workspace.inspectorTab },
                set: { workspace.inspectorTab = $0 }
            )) {
                ForEach(InspectorTab.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()
            Group {
                switch workspace.inspectorTab {
                case .text: TextInspector(workspace: workspace)
                case .formula: FormulaInspector(workspace: workspace)
                case .layout: LayoutInspector(workspace: workspace)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Text

/// Schrift, Absatz und Block-Werkzeuge an der Cursorposition.
struct TextInspector: View {
    let workspace: DocumentWorkspace

    private var state: FormatState { workspace.formatState }
    private var currentSize: FontSize { state.inline.fontSize ?? .normalsize }
    private var conversions: [String] {
        state.environment.map { BlockEditor.conversions(for: $0) } ?? []
    }

    var body: some View {
        Form {
            Section("Schrift") {
                LabeledContent("Stil") {
                    ControlGroup {
                        styleToggle(.bold, shortcut: "⌘B")
                        styleToggle(.italic, shortcut: "⌘I")
                        styleToggle(.underline, shortcut: "⌘U")
                    }
                    .toggleStyle(.button)
                    .fixedSize()
                }
                LabeledContent("Weitere") {
                    ControlGroup {
                        styleToggle(.emphasis)
                        styleToggle(.sansSerif)
                        styleToggle(.monospace)
                        styleToggle(.smallCaps)
                    }
                    .toggleStyle(.button)
                    .fixedSize()
                }
                LabeledContent("Grösse") {
                    HStack(spacing: 6) {
                        Picker("Grösse", selection: Binding(
                            get: { currentSize },
                            set: { workspace.setFontSize($0) }
                        )) {
                            ForEach(FontSize.allCases) { size in
                                Text(size.title).tag(size)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                        ControlGroup {
                            Button {
                                stepFontSize(by: -1)
                            } label: {
                                Label("Schrift kleiner", systemImage: "textformat.size.smaller")
                            }
                            .help("Schrift kleiner")
                            Button {
                                stepFontSize(by: 1)
                            } label: {
                                Label("Schrift grösser", systemImage: "textformat.size.larger")
                            }
                            .help("Schrift grösser")
                        }
                        .labelStyle(.iconOnly)
                        .fixedSize()
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Farbe")
                    ColorSwatchRow(current: state.inline.color) { workspace.setColor($0) }
                }
            }

            Section("Absatz") {
                Picker("Ausrichtung", selection: Binding(
                    get: { state.paragraph.alignment },
                    set: { workspace.align($0) }
                )) {
                    ForEach(LaTeXKit.TextAlignment.allCases) { alignment in
                        Label(alignment.title, systemImage: alignment.symbol)
                            .labelStyle(.iconOnly)
                            .help(alignment.title)
                            .tag(alignment)
                    }
                }
                .pickerStyle(.segmented)
                LabeledContent("Liste") {
                    ControlGroup {
                        ForEach(ListKind.allCases) { kind in
                            Toggle(isOn: Binding(
                                get: { state.paragraph.list == kind },
                                set: { _ in workspace.toggleList(kind) }
                            )) {
                                Label(kind.title, systemImage: kind.symbol)
                            }
                            .help(kind.title)
                        }
                    }
                    .toggleStyle(.button)
                    .labelStyle(.iconOnly)
                    .fixedSize()
                }
                LabeledContent("Einzug") {
                    ControlGroup {
                        Button {
                            workspace.shiftIndentation(outdent: true)
                        } label: {
                            Label("Ausrücken", systemImage: "decrease.indent")
                        }
                        .help("Ausrücken (⌘[)")
                        Button {
                            workspace.shiftIndentation(outdent: false)
                        } label: {
                            Label("Einrücken", systemImage: "increase.indent")
                        }
                        .help("Einrücken (⌘])")
                    }
                    .labelStyle(.iconOnly)
                    .fixedSize()
                }
            }

            Section {
                LabeledContent("Umgebung") {
                    Text(state.environment.map { BlockEditor.displayName(for: $0) } ?? "keine")
                        .foregroundStyle(.secondary)
                }
                Button("Block auswählen") { workspace.expandSelection() }
                    .help("Wählt die Umgebung am Cursor aus; nochmals wählt die nächstgrössere (⌥⌘A)")
                Menu("Umwandeln in") {
                    ForEach(conversions, id: \.self) { target in
                        Button(BlockEditor.displayName(for: target)) { workspace.convertEnvironment(to: target) }
                    }
                }
                .disabled(conversions.isEmpty)
                Menu("In Umgebung einpacken") {
                    ForEach(DocumentWorkspace.wrappableEnvironments, id: \.self) { name in
                        Button(BlockEditor.displayName(for: name)) { workspace.wrapSelection(inEnvironment: name) }
                    }
                }
                Button("Umgebung auflösen") { workspace.unwrapEnvironment() }
                    .disabled(state.environment == nil)
                Toggle("Formel nummerieren", isOn: Binding(
                    get: { state.canToggleNumbering && state.environment?.hasSuffix("*") == false },
                    set: { _ in workspace.toggleNumbering() }
                ))
                .disabled(!state.canToggleNumbering)
                Button("Formel abgesetzt ↔ im Text") { workspace.toggleDisplayMath() }
                    .disabled(!state.inMath)
            } header: {
                Text("Block")
            } footer: {
                Text("Wirkt auf die Umgebung am Cursor, z. B. eine Aufzählung oder eine Formel.")
            }

            Section("Zeilen") {
                LabeledContent("Verschieben") {
                    ControlGroup {
                        Button {
                            workspace.moveLines(up: true)
                        } label: {
                            Label("Nach oben", systemImage: "arrow.up")
                        }
                        .help("Zeilen nach oben verschieben (⌥⌘↑)")
                        Button {
                            workspace.moveLines(up: false)
                        } label: {
                            Label("Nach unten", systemImage: "arrow.down")
                        }
                        .help("Zeilen nach unten verschieben (⌥⌘↓)")
                    }
                    .labelStyle(.iconOnly)
                    .fixedSize()
                }
                Button("Auskommentieren ein/aus") { workspace.toggleComment() }
                    .help("Zeilen mit % auskommentieren oder wieder aktivieren (⌘/)")
                Button("Suchen und Ersetzen …") { workspace.showFindBar() }
            }
        }
        .formStyle(.grouped)
    }

    private func stepFontSize(by step: Int) {
        let sizes = FontSize.allCases
        guard let index = sizes.firstIndex(of: currentSize) else { return }
        let next = min(max(index + step, 0), sizes.count - 1)
        if next != index { workspace.setFontSize(sizes[next]) }
    }

    private func styleToggle(_ style: InlineStyle, shortcut: String? = nil) -> some View {
        let keys = shortcut.map { " (\($0))" } ?? ""
        return Toggle(isOn: Binding(
            get: { state.inline.styles.contains(style) },
            set: { _ in workspace.toggle(style) }
        )) {
            Label(style.title, systemImage: style.symbol)
                .labelStyle(.iconOnly)
        }
        .help("\(style.title)\(keys) – LaTeX: \\\(style.command){…}")
    }
}

// MARK: - Formel

/// Formel-Bausteine, Strukturen in freier Grösse und alle Zeichen.
struct FormulaInspector: View {
    let workspace: DocumentWorkspace
    @AppStorage("inspectorSymbolGroup") private var symbolGroup: MathSymbolGroup = .greekLowercase

    private let tileColumns = [GridItem(.adaptive(minimum: 56), spacing: 6)]
    private let symbolColumns = [GridItem(.adaptive(minimum: 30), spacing: 4)]

    var body: some View {
        Form {
            Section("Bausteine") {
                LazyVGrid(columns: tileColumns, spacing: 6) {
                    ForEach(SnippetCatalog.snippets(in: .formulas)) { snippet in
                        ItemTile(title: shortTitle(snippet), icon: SnippetIcon.icon(for: snippet), help: snippet.help) {
                            workspace.insert(snippet)
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Section {
                LazyVGrid(columns: tileColumns, spacing: 6) {
                    ItemTile(title: "Im Text", icon: .symbol("function"), help: InsertCommands.inlineFormula.help) {
                        workspace.insert(InsertCommands.inlineFormula)
                    }
                    .disabled(workspace.formatState.inMath)
                    snippetTile("display.unnumbered", title: "Abgesetzt")
                    snippetTile("display.equation", title: "Nummeriert")
                    StructureTile(title: "Rechnung", icon: .symbol("equal"), structure: .counted(.alignedEquations), workspace: workspace)
                    StructureTile(title: "System", icon: .symbol("equal.square"), structure: .counted(.equationSystem), workspace: workspace)
                    StructureTile(title: "Fälle", icon: .symbol("curlybraces"), structure: .counted(.cases), workspace: workspace)
                    StructureTile(title: "Matrix", icon: .symbol("square.grid.3x3"), structure: .matrix, workspace: workspace)
                    StructureTile(title: "Vektor", icon: .symbol("arrow.right"), structure: .counted(.vector), workspace: workspace)
                }
                .padding(.vertical, 2)
            } header: {
                Text("Abgesetzte Formeln und Strukturen")
            } footer: {
                Text("Matrizen, Systeme, Fälle und Rechnungen in beliebiger Grösse.")
            }

            Section("Zeichen") {
                Picker("Gruppe", selection: $symbolGroup) {
                    ForEach(MathSymbolGroup.allCases) { Text($0.title).tag($0) }
                }
                LazyVGrid(columns: symbolColumns, spacing: 4) {
                    ForEach(symbolGroup.symbols) { symbol in
                        SymbolTile(symbol: symbol) { workspace.insert($0) }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .formStyle(.grouped)
    }

    private func snippetTile(_ id: String, title: String) -> some View {
        Group {
            if let snippet = SnippetCatalog.snippet(withID: id) {
                ItemTile(title: title, icon: SnippetIcon.icon(for: snippet), help: snippet.help) {
                    workspace.insert(snippet)
                }
            }
        }
    }

    /// Kurze Titel für die Kacheln („Hochgestellt (Potenz)“ → „Potenz“).
    private func shortTitle(_ snippet: Snippet) -> String {
        switch snippet.id {
        case "formula.superscript": return "Potenz"
        case "formula.subscript": return "Index"
        case "formula.squareRoot": return "Wurzel"
        case "formula.nthRoot": return "n-te Wurzel"
        case "formula.binomial": return "Binomial"
        case "formula.parentheses": return "Klammern"
        case "formula.partialDerivative": return "Partiell"
        case "formula.text": return "Text"
        case "formula.realNumbers": return "ℝ"
        case "formula.naturalNumbers": return "ℕ"
        default: return snippet.title
        }
    }
}

/// Kachel, die ein Auswahlfenster für eine Struktur in freier Grösse öffnet.
struct StructureTile: View {
    let title: String
    let icon: ItemIcon
    let structure: StructureSheet
    let workspace: DocumentWorkspace
    @State private var isPresented = false

    var body: some View {
        ItemTile(title: title, icon: icon, help: "\(title) in beliebiger Grösse …") {
            isPresented = true
        }
        .popover(isPresented: $isPresented, arrowEdge: .leading) {
            StructurePickerView(structure: structure, workspace: workspace)
        }
    }
}

/// Das passende Auswahlfenster zu einer Struktur.
struct StructurePickerView: View {
    let structure: StructureSheet
    let workspace: DocumentWorkspace

    var body: some View {
        switch structure {
        case .table: TablePicker(workspace: workspace)
        case .matrix: MatrixPicker(workspace: workspace)
        case .counted(let counted): CountedStructurePicker(structure: counted, workspace: workspace)
        }
    }
}

// MARK: - Layout

/// Ränder, Zeilenabstand, Schrift und Papier – für das ganze Dokument oder nur diese Seite.
/// Regler wirken beim Loslassen, Eingabefelder mit ↩.
struct LayoutInspector: View {
    let workspace: DocumentWorkspace
    @State private var margins = MarginSizes(uniform: 2.5)
    @State private var separateSides = false
    @State private var stretch = 1.0

    private var settings: DocumentSettings { workspace.documentSettings }
    private var hasPreamble: Bool { settings.documentClass != nil }
    private var isPageScope: Bool { workspace.layoutScope == .page }

    var body: some View {
        Form {
            Section {
                Picker("Gilt für", selection: Binding(
                    get: { workspace.layoutScope },
                    set: { workspace.layoutScope = $0 }
                )) {
                    ForEach(LayoutScope.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            } footer: {
                Text(isPageScope
                     ? "Ränder und Zeilenabstand gelten für die Absätze der Seite mit dem Cursor (bzw. die Auswahl). Andere Ränder beginnen auf einer neuen Seite."
                     : "Einstellungen stehen in der Präambel und gelten im ganzen Dokument.")
            }

            Section("Ränder") {
                Picker("Voreinstellung", selection: Binding<PageMargins?>(
                    get: { isPageScope ? nil : PageMargins.presets.first { $0 == settings.margins } },
                    set: { preset in if let preset { workspace.applyMargins(preset) } }
                )) {
                    ForEach(PageMargins.presets) { preset in
                        Text(preset.title).tag(PageMargins?.some(preset))
                    }
                    Text("Eigene").tag(PageMargins?.none)
                }
                HStack(alignment: .top, spacing: 14) {
                    MarginsPreview(sizes: margins, width: 56)
                    VStack(alignment: .leading, spacing: 8) {
                        if separateSides {
                            marginRow("Oben", \.top)
                            marginRow("Unten", \.bottom)
                            marginRow("Links", \.left)
                            marginRow("Rechts", \.right)
                        } else {
                            marginRow("Alle Seiten", nil)
                        }
                    }
                }
                .padding(.vertical, 2)
                Toggle("Jede Seite einzeln", isOn: $separateSides)
                    .onChange(of: separateSides) { _, separate in
                        if !separate {
                            margins = MarginSizes(uniform: margins.left)
                            applyMargins()
                        }
                    }
            }

            Section("Zeilenabstand") {
                Picker("Voreinstellung", selection: Binding<LineSpacing?>(
                    get: { isPageScope ? nil : LineSpacing.presets.first { $0 == settings.lineSpacing } },
                    set: { preset in if let preset { workspace.applyLineSpacing(preset) } }
                )) {
                    ForEach(LineSpacing.presets) { preset in
                        Text(preset.title).tag(LineSpacing?.some(preset))
                    }
                }
                .pickerStyle(.segmented)
                HStack(alignment: .center, spacing: 14) {
                    SpacingPreview(stretch: stretch, width: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eigener Faktor (1 = einfach)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Slider(value: $stretch, in: LineSpacing.stretchRange, step: 0.05, onEditingChanged: { editing in
                                if !editing { workspace.applyLineSpacing(LineSpacing(stretch: stretch)) }
                            })
                            .controlSize(.small)
                            .accessibilityLabel("Zeilenabstand")
                            TextField("Faktor", value: $stretch, format: .number.precision(.fractionLength(0...2)))
                                .labelsHidden()
                                .multilineTextAlignment(.trailing)
                                .frame(width: 44)
                                .onSubmit { workspace.applyLineSpacing(LineSpacing(stretch: clampedStretch)) }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Section {
                Picker("Schriftart", selection: Binding(
                    get: { settings.font },
                    set: { font in update { $0.font = font } }
                )) {
                    ForEach(DocumentFont.allCases) { Text($0.title).tag($0) }
                }
                Picker("Grundgrösse", selection: Binding(
                    get: { settings.baseFontSize },
                    set: { size in update { $0.baseFontSize = size } }
                )) {
                    Text("Standard (10 pt)").tag(Int?.none)
                    Text("10 pt").tag(Int?.some(10))
                    Text("11 pt").tag(Int?.some(11))
                    Text("12 pt").tag(Int?.some(12))
                }
                Picker("Papier", selection: Binding(
                    get: { settings.paperSize },
                    set: { paper in update { $0.paperSize = paper } }
                )) {
                    Text("Standard").tag(PaperSize?.none)
                    ForEach(PaperSize.allCases) { Text($0.title).tag(PaperSize?.some($0)) }
                }
            } header: {
                Text("Schrift und Papier")
            } footer: {
                Text(isPageScope ? "Schrift und Papier gelten immer für das ganze Dokument." : settings.font.subtitle)
            }
            .disabled(isPageScope || !hasPreamble)

            Section {
                LabeledContent("Dokumentklasse") {
                    Text(verbatim: settings.documentClass ?? "–")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    insertButton("heading.tableOfContents", title: "Inhaltsverzeichnis")
                    insertButton("text.newPage", title: "Neue Seite")
                    insertButton("heading.appendix", title: "Anhang")
                }
            } header: {
                Text("Dokument")
            } footer: {
                Text(hasPreamble
                     ? "Änderungen landen als einzelne Zeilen in der Präambel und lassen sich mit ⌘Z rückgängig machen."
                     : "Dieses Dokument hat keine Präambel mit \\documentclass – Schrift und Seite lassen sich hier nicht einstellen.")
            }
        }
        .formStyle(.grouped)
        .disabled(!isPageScope && !hasPreamble)
        .onAppear(perform: loadCurrentValues)
        .onChange(of: settings) { _, _ in loadCurrentValues() }
        .onChange(of: workspace.layoutScope) { _, _ in loadCurrentValues() }
    }

    private var clampedStretch: Double {
        min(max(stretch, LineSpacing.stretchRange.lowerBound), LineSpacing.stretchRange.upperBound)
    }

    /// Regler und Feld zeigen die aktuellen Werte des Dokuments (bzw. Startwerte für „Diese Seite“).
    private func loadCurrentValues() {
        if !isPageScope, let sizes = settings.margins.sizes {
            margins = sizes
            separateSides = !sizes.isUniform
        } else if isPageScope {
            margins = MarginSizes(uniform: 2)
        }
        stretch = isPageScope ? 1.5 : settings.lineSpacing.approximateStretch
    }

    private func applyMargins() {
        workspace.applyMargins(PageMargins(sizes: margins))
    }

    /// Regler und Eingabefeld für einen Rand (`nil` = alle vier gleich).
    private func marginRow(_ title: String, _ side: WritableKeyPath<MarginSizes, Double>?) -> some View {
        let binding = Binding<Double>(
            get: { side.map { margins[keyPath: $0] } ?? margins.left },
            set: { newValue in
                let value = min(max((newValue * 10).rounded() / 10, MarginSizes.range.lowerBound), MarginSizes.range.upperBound)
                if let side { margins[keyPath: side] = value } else { margins = MarginSizes(uniform: value) }
            }
        )
        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Slider(value: binding, in: MarginSizes.range, step: 0.1, onEditingChanged: { editing in
                    if !editing { applyMargins() }
                })
                .controlSize(.small)
                .accessibilityLabel("Rand \(title)")
                TextField(title, value: binding, format: .number.precision(.fractionLength(0...2)))
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                    .onSubmit(applyMargins)
                Text("cm")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func insertButton(_ id: String, title: String) -> some View {
        Button(title) {
            if let snippet = SnippetCatalog.snippet(withID: id) { workspace.insert(snippet) }
        }
        .controlSize(.small)
    }

    private func update(_ change: (inout DocumentSettings) -> Void) {
        var updated = workspace.documentSettings
        change(&updated)
        workspace.applyDocumentSettings(updated)
    }
}
