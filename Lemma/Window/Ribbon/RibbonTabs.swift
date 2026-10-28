import LaTeXKit
import SwiftUI

// Inhalt der fünf Registerkarten. Jeder Knopf ruft nur eine Methode des
// Arbeitsbereichs auf; die LaTeX-Logik steckt in LaTeXKit.

// MARK: - Start

/// Formatvorlagen, Schrift und Absatz – das Wichtigste beim Schreiben.
struct StartTab: View {
    let workspace: DocumentWorkspace
    @Environment(\.ribbonDensity) private var density

    private var state: FormatState { workspace.formatState }
    private var currentSize: FontSize { state.inline.fontSize ?? .normalsize }

    var body: some View {
        HStack(spacing: 0) {
            RibbonGroup("Formatvorlagen") {
                if density == .full {
                    ForEach(ParagraphStyle.allCases) { style in
                        ParagraphStyleTile(
                            style: style,
                            isSelected: state.paragraph.style == style,
                            help: styleHelp(style)
                        ) {
                            workspace.applyParagraphStyle(style)
                        }
                    }
                } else {
                    RibbonMenuButton(state.paragraph.style.title, icon: .symbol("textformat.size")) {
                        RibbonMenu(minWidth: 220) {
                            ForEach(ParagraphStyle.allCases) { style in
                                RibbonMenuRow(isChecked: state.paragraph.style == style, help: styleHelp(style)) {
                                    workspace.applyParagraphStyle(style)
                                } title: {
                                    Text(style.title).font(ParagraphStyleTile.sampleFont(for: style))
                                }
                            }
                        }
                    }
                }
            }
            RibbonSeparator()
            RibbonGroup("Schrift") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 1) {
                        styleButton(.bold, shortcut: "⌘B")
                        styleButton(.italic, shortcut: "⌘I")
                        styleButton(.underline, shortcut: "⌘U")
                        RibbonRowDivider()
                        styleButton(.emphasis)
                        styleButton(.sansSerif)
                        styleButton(.monospace)
                        styleButton(.smallCaps)
                    }
                    HStack(spacing: 1) {
                        fontSizeMenu
                        RibbonSmallButton(title: "Schrift grösser", systemImage: "textformat.size.larger") {
                            stepFontSize(by: 1)
                        }
                        RibbonSmallButton(title: "Schrift kleiner", systemImage: "textformat.size.smaller") {
                            stepFontSize(by: -1)
                        }
                        RibbonRowDivider()
                        colorMenu
                    }
                }
            }
            RibbonSeparator()
            RibbonGroup("Absatz") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 1) {
                        ForEach(LaTeXKit.TextAlignment.allCases) { alignment in
                            RibbonSmallButton(
                                title: alignment.title,
                                systemImage: alignment.symbol,
                                isOn: state.paragraph.alignment == alignment
                            ) {
                                workspace.align(alignment)
                            }
                        }
                    }
                    HStack(spacing: 1) {
                        ForEach(ListKind.allCases) { kind in
                            RibbonSmallButton(title: kind.title, systemImage: kind.symbol, isOn: state.paragraph.list == kind) {
                                workspace.toggleList(kind)
                            }
                        }
                        RibbonRowDivider()
                        RibbonSmallButton(title: "Ausrücken", systemImage: "decrease.indent", help: "Ausrücken (⌘[)") {
                            workspace.shiftIndentation(outdent: true)
                        }
                        RibbonSmallButton(title: "Einrücken", systemImage: "increase.indent", help: "Einrücken (⌘])") {
                            workspace.shiftIndentation(outdent: false)
                        }
                    }
                }
            }
        }
    }

    private func styleHelp(_ style: ParagraphStyle) -> String {
        if let command = workspace.headingScheme.command(for: style) {
            return "\(style.title) – LaTeX: \\\(command){…}"
        }
        return "\(style.title) – normaler Fliesstext"
    }

    private func styleButton(_ style: InlineStyle, shortcut: String? = nil) -> some View {
        let keys = shortcut.map { " (\($0))" } ?? ""
        return RibbonSmallButton(
            title: style.title,
            systemImage: style.symbol,
            isOn: state.inline.styles.contains(style),
            help: "\(style.title)\(keys) – LaTeX: \\\(style.command){…}"
        ) {
            workspace.toggle(style)
        }
    }

    private func stepFontSize(by step: Int) {
        let sizes = FontSize.allCases
        guard let index = sizes.firstIndex(of: currentSize) else { return }
        let next = min(max(index + step, 0), sizes.count - 1)
        if next != index { workspace.setFontSize(sizes[next]) }
    }

    private var fontSizeMenu: some View {
        RibbonSmallMenuButton(help: "Schriftgrösse – wirkt auf die Auswahl") {
            Text(currentSize.title)
                .font(.system(size: 11.5))
                .lineLimit(1)
                .frame(width: 92, alignment: .leading)
        } content: {
            RibbonMenu(minWidth: 210) {
                ForEach(FontSize.allCases) { size in
                    RibbonMenuRow(isChecked: currentSize == size, help: "LaTeX: \\\(size.command)") {
                        workspace.setFontSize(size)
                    } title: {
                        Text(size.title)
                            .font(.system(size: 12 * CGFloat(min(max(size.relativeScale, 0.75), 1.8))))
                    }
                }
            }
        }
    }

    private var colorMenu: some View {
        RibbonSmallMenuButton(help: "Textfarbe") {
            VStack(spacing: 1) {
                Text(verbatim: "A")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                RoundedRectangle(cornerRadius: 1)
                    .fill(state.inline.color.map(\.swiftUIColor) ?? Color.primary)
                    .frame(width: 14, height: 3)
            }
            .frame(width: 18)
        } content: {
            ColorPalette(current: state.inline.color) { color in
                workspace.setColor(color)
            }
        }
    }
}

/// Kachel einer Formatvorlage mit Vorschau, wie die Formatvorlagen-Galerie in Word.
struct ParagraphStyleTile: View {
    let style: ParagraphStyle
    let isSelected: Bool
    let help: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(verbatim: "AaBb")
                    .font(Self.sampleFont(for: style))
                    .foregroundStyle(.primary)
                    .frame(height: 26)
                Text(style.title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .padding(.top, 2)
        .onHover { isHovered = $0 }
        .help(help)
        .accessibilityLabel(style.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var borderColor: Color {
        if isSelected { return .accentColor }
        return Color.primary.opacity(isHovered ? 0.3 : 0.12)
    }

    /// Schrift der Vorschau – mit Serifen, wie im fertigen PDF.
    static func sampleFont(for style: ParagraphStyle) -> Font {
        switch style {
        case .body: return .system(size: 13, design: .serif)
        case .heading1: return .system(size: 18, weight: .bold, design: .serif)
        case .heading2: return .system(size: 16, weight: .bold, design: .serif)
        case .heading3: return .system(size: 14, weight: .bold, design: .serif)
        case .heading4: return .system(size: 13, weight: .semibold, design: .serif)
        }
    }
}

/// Farbkreise zum Auswählen der Textfarbe.
private struct ColorPalette: View {
    let current: TextColor?
    let choose: (TextColor?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Textfarbe")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 6), count: 6), alignment: .leading, spacing: 6) {
                ForEach(TextColor.allCases) { color in
                    Button {
                        dismiss()
                        choose(color)
                    } label: {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.2)))
                            .padding(3)
                            .overlay(
                                Circle().strokeBorder(current == color ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(color.title)
                    .accessibilityLabel(color.title)
                }
            }
            RibbonMenuDivider()
            RibbonMenuRow("Keine Farbe", icon: .symbol("circle.slash"), isChecked: current == nil) {
                choose(nil)
            }
        }
        .padding(10)
        .frame(width: 230)
    }
}

extension TextColor {
    var swiftUIColor: Color {
        let value = rgb
        return Color(red: value.red, green: value.green, blue: value.blue)
    }
}

/// Kurzer senkrechter Strich zwischen kleinen Knöpfen einer Zeile.
struct RibbonRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 16)
            .padding(.horizontal, 3)
    }
}

// MARK: - Einfügen

/// Formeln, Bilder, Tabellen, Überschriften, Verweise – alles zum Einfügen.
struct InsertTab: View {
    let workspace: DocumentWorkspace

    /// `$…$` um die Auswahl bzw. mit Platzhalter – eine Formel mitten im Satz.
    static let inlineFormula = Snippet(
        id: "ribbon.inlineFormula",
        title: "Formel im Text",
        category: .formulas,
        body: "$\(Snippet.selectionToken)$",
        placement: .inline,
        help: "Formel mitten im Satz, z. B. $a^2 + b^2 = c^2$. Eine Auswahl wird zur Formel."
    )

    var body: some View {
        HStack(spacing: 0) {
            RibbonGroup("Formeln") {
                RibbonButton(title: Self.inlineFormula.title, icon: .symbol("function"), help: Self.inlineFormula.help) {
                    workspace.insert(Self.inlineFormula)
                }
                .disabled(workspace.formatState.inMath)
                SnippetButton(workspace: workspace, id: "display.unnumbered", title: "Abgesetzte Formel")
            }
            RibbonSeparator()
            RibbonGroup("Abbildungen") {
                RibbonButton(
                    title: "Bild",
                    icon: .symbol("photo.badge.plus"),
                    help: "Bild aus einer Datei einfügen – es wird in den Ordner „Bilder“ neben dem Dokument kopiert"
                ) {
                    workspace.insertImageFromFile()
                }
                SnippetMenuButton("Tabelle", icon: .symbol("tablecells"), workspace: workspace, category: .tables)
                SnippetMenuButton("Liste", icon: .symbol("list.bullet"), workspace: workspace, category: .lists)
            }
            RibbonSeparator()
            RibbonGroup("Gliederung") {
                SnippetMenuButton("Überschrift", icon: .symbol("textformat.size"), workspace: workspace, category: .headings)
                SnippetMenuButton("Satz und Beweis", icon: .symbol("checkmark.seal"), workspace: workspace, category: .theorems)
                SnippetMenuButton("Aufgabe", icon: .symbol("pencil"), workspace: workspace, category: .document)
            }
            RibbonSeparator()
            RibbonGroup("Text") {
                VStack(alignment: .leading, spacing: 4) {
                    SnippetSmallButton(workspace: workspace, id: "text.footnote")
                    SnippetSmallButton(workspace: workspace, id: "text.quote")
                }
                VStack(alignment: .leading, spacing: 4) {
                    SnippetSmallButton(workspace: workspace, id: "text.link")
                    SnippetSmallButton(workspace: workspace, id: "text.codeBlock")
                }
            }
            RibbonSeparator()
            RibbonGroup("Verweise und Seite") {
                SnippetMenuButton(
                    "Verweis",
                    icon: .symbol("arrow.right.circle"),
                    workspace: workspace,
                    ids: ["text.label", "text.ref", "text.eqref"],
                    help: "Querverweise: Stelle markieren und darauf verweisen"
                )
                SnippetMenuButton(
                    "Seite",
                    icon: .symbol("doc.on.doc"),
                    workspace: workspace,
                    ids: ["text.newPage", "text.lineBreak", "text.verticalSpace", "heading.tableOfContents", "heading.appendix"],
                    help: "Seiten- und Zeilenumbruch, Abstand, Inhaltsverzeichnis, Anhang"
                )
            }
        }
    }
}

// MARK: - Formeln

/// Formel-Bausteine, Symbole und abgesetzte Formeln.
struct MathTab: View {
    let workspace: DocumentWorkspace
    @Environment(\.ribbonDensity) private var density

    /// Häufig gebrauchte Zeichen, direkt in der Leiste.
    private static let quickSymbols: [MathSymbol] = {
        let commands = [
            #"\alpha"#, #"\beta"#, #"\pi"#, #"\lambda"#, #"\leq"#, #"\geq"#, #"\neq"#, #"\approx"#,
            #"\to"#, #"\Rightarrow"#, #"\Leftrightarrow"#, #"\infty"#, #"\in"#, #"\forall"#, #"\exists"#, #"\mathbb{R}"#
        ]
        let all = MathSymbolGroup.allCases.flatMap(\.symbols)
        return commands.compactMap { command in all.first { $0.command == command } }
    }()

    var body: some View {
        HStack(spacing: 0) {
            RibbonGroup("Bausteine") {
                SnippetButton(workspace: workspace, id: "formula.fraction")
                SnippetButton(workspace: workspace, id: "formula.squareRoot", title: "Wurzel")
                SnippetButton(workspace: workspace, id: "formula.superscript", title: "Potenz")
                SnippetButton(workspace: workspace, id: "formula.subscript", title: "Index")
                SnippetMenuButton(
                    "Mehr",
                    icon: .symbol("ellipsis.circle"),
                    workspace: workspace,
                    ids: [
                        "formula.nthRoot", "formula.binomial", "formula.absoluteValue", "formula.norm",
                        "formula.parentheses", "formula.vector", "formula.set", "formula.text",
                        "formula.realNumbers", "formula.naturalNumbers"
                    ],
                    help: "Weitere Formel-Bausteine"
                )
            }
            RibbonSeparator()
            RibbonGroup("Analysis") {
                SnippetButton(workspace: workspace, id: "formula.sum")
                SnippetButton(workspace: workspace, id: "formula.integral")
                SnippetButton(workspace: workspace, id: "formula.limit")
                SnippetMenuButton(
                    "Ableitung",
                    icon: .glyph("∂"),
                    workspace: workspace,
                    ids: ["formula.derivative", "formula.partialDerivative"]
                )
            }
            RibbonSeparator()
            RibbonGroup("Symbole") {
                if density == .full {
                    // Zwei Reihen mit je acht Zeichen.
                    let half = Self.quickSymbols.count / 2
                    Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                        GridRow {
                            ForEach(Self.quickSymbols.prefix(half)) { symbol in
                                SymbolTile(symbol: symbol, size: 26) { workspace.insert($0) }
                            }
                        }
                        GridRow {
                            ForEach(Self.quickSymbols.dropFirst(half)) { symbol in
                                SymbolTile(symbol: symbol, size: 26) { workspace.insert($0) }
                            }
                        }
                    }
                    .padding(.top, 2)
                    .padding(.trailing, 4)
                }
                RibbonMenuButton("Alle Symbole", icon: .glyph("Ω"), help: "Griechische Buchstaben, Vergleiche, Pfeile, Mengen …") {
                    SymbolPalette { workspace.insert($0) }
                }
            }
            RibbonSeparator()
            RibbonGroup("Abgesetzte Formeln") {
                SnippetButton(workspace: workspace, id: "display.unnumbered", title: "Formel")
                SnippetButton(workspace: workspace, id: "display.equation", title: "Nummeriert")
                SnippetButton(workspace: workspace, id: "display.alignUnnumbered", title: "Ausgerichtet")
                SnippetButton(workspace: workspace, id: "display.cases", title: "Fälle")
                SnippetMenuButton(
                    "Matrix",
                    icon: .symbol("square.grid.3x3"),
                    workspace: workspace,
                    ids: ["display.matrix2", "display.matrix3", "display.system", "display.align"],
                    help: "Matrizen, Gleichungssysteme und nummerierte mehrzeilige Formeln"
                )
            }
        }
    }
}

// MARK: - Layout

/// Schrift und Seite des ganzen Dokuments – wie „Layout“ in Word.
/// Jede Änderung landet als lesbare Zeile in der Präambel (siehe PreambleEditor).
struct LayoutTab: View {
    let workspace: DocumentWorkspace

    private var settings: DocumentSettings { workspace.documentSettings }
    private var hasPreamble: Bool { settings.documentClass != nil }

    var body: some View {
        HStack(spacing: 0) {
            Group {
                RibbonGroup("Schrift") {
                    RibbonMenuButton("Schriftart", icon: .symbol("textformat"), help: "Schriftart des ganzen Dokuments") {
                        RibbonMenu(minWidth: 300) {
                            ForEach(DocumentFont.allCases) { font in
                                RibbonMenuRow(font.title, subtitle: font.subtitle, isChecked: settings.font == font) {
                                    update { $0.font = font }
                                }
                            }
                        }
                    }
                    RibbonMenuButton("Grundgrösse", icon: .symbol("textformat.size"), help: "Schriftgrösse des Fliesstexts") {
                        RibbonMenu {
                            RibbonMenuRow("Standard (10 pt)", isChecked: settings.baseFontSize == nil) {
                                update { $0.baseFontSize = nil }
                            }
                            ForEach([10, 11, 12], id: \.self) { size in
                                RibbonMenuRow("\(size) pt", isChecked: settings.baseFontSize == size) {
                                    update { $0.baseFontSize = size }
                                }
                            }
                        }
                    }
                }
                RibbonSeparator()
                RibbonGroup("Seite") {
                    RibbonMenuButton("Papier", icon: .symbol("doc"), help: "Papierformat") {
                        RibbonMenu {
                            RibbonMenuRow("Standard", isChecked: settings.paperSize == nil) {
                                update { $0.paperSize = nil }
                            }
                            ForEach(PaperSize.allCases) { size in
                                RibbonMenuRow(size.title, isChecked: settings.paperSize == size) {
                                    update { $0.paperSize = size }
                                }
                            }
                        }
                    }
                    RibbonMenuButton("Ränder", icon: .symbol("rectangle.dashed"), help: "Seitenränder") {
                        RibbonMenu {
                            ForEach(PageMargins.allCases) { margins in
                                RibbonMenuRow(margins.title, isChecked: settings.margins == margins) {
                                    update { $0.margins = margins }
                                }
                            }
                        }
                    }
                    RibbonMenuButton("Zeilenabstand", icon: .symbol("line.3.horizontal"), help: "Abstand zwischen den Zeilen") {
                        RibbonMenu {
                            ForEach(LineSpacing.allCases) { spacing in
                                RibbonMenuRow(spacing.title, isChecked: settings.lineSpacing == spacing) {
                                    update { $0.lineSpacing = spacing }
                                }
                            }
                        }
                    }
                }
            }
            // Ohne Präambel gibt es nichts einzustellen (wie im Inspektor).
            .disabled(!hasPreamble)
            RibbonSeparator()
            RibbonGroup("Gliederung") {
                SnippetButton(workspace: workspace, id: "heading.tableOfContents", title: "Inhalt")
                SnippetButton(workspace: workspace, id: "text.newPage", title: "Neue Seite")
                SnippetButton(workspace: workspace, id: "heading.appendix")
            }
        }
    }

    private func update(_ change: (inout DocumentSettings) -> Void) {
        var updated = workspace.documentSettings
        change(&updated)
        workspace.applyDocumentSettings(updated)
    }
}

// MARK: - Blöcke

/// Werkzeuge für ganze Blöcke: auswählen, umwandeln, einpacken, verschieben.
struct BlocksTab: View {
    let workspace: DocumentWorkspace

    private var state: FormatState { workspace.formatState }
    private var conversions: [String] {
        state.environment.map { BlockEditor.conversions(for: $0) } ?? []
    }

    var body: some View {
        HStack(spacing: 0) {
            RibbonGroup("Auswahl") {
                RibbonButton(
                    title: "Block auswählen",
                    icon: .symbol("rectangle.dashed"),
                    help: "Wählt die Umgebung am Cursor aus; nochmals drücken wählt die nächstgrössere (⌥⌘A)"
                ) {
                    workspace.expandSelection()
                }
            }
            RibbonSeparator()
            RibbonGroup(environmentCaption) {
                RibbonMenuButton("Umwandeln", icon: .symbol("arrow.triangle.2.circlepath"), help: "Umgebung am Cursor in eine andere umwandeln") {
                    RibbonMenu {
                        ForEach(conversions, id: \.self) { target in
                            RibbonMenuRow(BlockEditor.displayName(for: target)) {
                                workspace.convertEnvironment(to: target)
                            }
                        }
                    }
                }
                .disabled(conversions.isEmpty)
                RibbonMenuButton("Einpacken", icon: .symbol("shippingbox"), help: "Auswahl in eine Umgebung einpacken") {
                    RibbonMenu {
                        ForEach(DocumentWorkspace.wrappableEnvironments, id: \.self) { name in
                            RibbonMenuRow(BlockEditor.displayName(for: name)) {
                                workspace.wrapSelection(inEnvironment: name)
                            }
                        }
                    }
                }
                RibbonButton(title: "Auflösen", icon: .symbol("shippingbox.and.arrow.backward"), help: "Umgebung entfernen, Inhalt behalten") {
                    workspace.unwrapEnvironment()
                }
                .disabled(state.environment == nil)
                RibbonButton(
                    title: "Nummerierung",
                    icon: .symbol("number"),
                    isOn: state.canToggleNumbering && state.environment?.hasSuffix("*") == false,
                    help: "Formelnummer (1), (2) … ein- oder ausschalten"
                ) {
                    workspace.toggleNumbering()
                }
                .disabled(!state.canToggleNumbering)
                RibbonButton(title: "Abgesetzt ↔ im Text", icon: .symbol("rectangle.2.swap"), help: "Formel zwischen eigener Zeile und Fliesstext umschalten (⇧⌘M)") {
                    workspace.toggleDisplayMath()
                }
                .disabled(!state.inMath)
            }
            RibbonSeparator()
            RibbonGroup("Zeilen") {
                RibbonButton(title: "Nach oben", icon: .symbol("arrow.up"), help: "Zeilen nach oben verschieben (⌥⌘↑)") {
                    workspace.moveLines(up: true)
                }
                RibbonButton(title: "Nach unten", icon: .symbol("arrow.down"), help: "Zeilen nach unten verschieben (⌥⌘↓)") {
                    workspace.moveLines(up: false)
                }
                RibbonButton(title: "Kommentar", icon: .symbol("percent"), help: "Zeilen auskommentieren oder wieder aktivieren (⌘/)") {
                    workspace.toggleComment()
                }
            }
        }
    }

    private var environmentCaption: String {
        guard let environment = state.environment else { return "Umgebung" }
        return "Umgebung: \(BlockEditor.displayName(for: environment))"
    }
}

// MARK: - Bausteine aus dem Katalog

/// Symbol für einen Baustein ohne eigenes SF-Symbol.
enum SnippetIcon {
    private static let glyphs: [String: String] = [
        "formula.nthRoot": "ⁿ√",
        "formula.integral": "∫",
        "formula.limit": "lim",
        "formula.binomial": "(ⁿₖ)",
        "formula.norm": "‖x‖",
        "formula.parentheses": "( )",
        "formula.derivative": "d/dx",
        "formula.partialDerivative": "∂/∂x",
        "formula.set": "{ | }",
        "display.align": "(1)",
        "heading.subsubsection": "§",
        "heading.sectionUnnumbered": "§",
        "text.eqref": "(1)"
    ]

    static func icon(for snippet: Snippet) -> RibbonIcon {
        if let symbol = snippet.symbol { return .symbol(symbol) }
        if let glyph = glyphs[snippet.id] { return .glyph(glyph) }
        return .symbol("square.dashed")
    }
}

/// Grosser Knopf für einen Baustein aus dem Katalog.
struct SnippetButton: View {
    let workspace: DocumentWorkspace
    let id: String
    var title: String?

    var body: some View {
        if let snippet = SnippetCatalog.snippet(withID: id) {
            RibbonButton(title: title ?? snippet.title, icon: SnippetIcon.icon(for: snippet), help: snippet.help) {
                workspace.insert(snippet)
            }
        }
    }
}

/// Kleiner Knopf mit Text für einen Baustein aus dem Katalog.
struct SnippetSmallButton: View {
    let workspace: DocumentWorkspace
    let id: String

    var body: some View {
        if let snippet = SnippetCatalog.snippet(withID: id) {
            RibbonSmallTextButton(title: snippet.title, systemImage: snippet.symbol ?? "square.dashed", help: snippet.help) {
                workspace.insert(snippet)
            }
        }
    }
}

/// Grosser Knopf, der eine Liste von Bausteinen anbietet.
struct SnippetMenuButton: View {
    let title: String
    let icon: RibbonIcon
    let workspace: DocumentWorkspace
    let snippets: [Snippet]
    var help: String?

    init(_ title: String, icon: RibbonIcon, workspace: DocumentWorkspace, category: SnippetCategory, help: String? = nil) {
        self.title = title
        self.icon = icon
        self.workspace = workspace
        self.snippets = SnippetCatalog.snippets(in: category)
        self.help = help ?? category.title
    }

    init(_ title: String, icon: RibbonIcon, workspace: DocumentWorkspace, ids: [String], help: String? = nil) {
        self.title = title
        self.icon = icon
        self.workspace = workspace
        self.snippets = ids.compactMap(SnippetCatalog.snippet(withID:))
        self.help = help
    }

    var body: some View {
        RibbonMenuButton(title, icon: icon, help: help) {
            RibbonMenu(minWidth: 250) {
                ForEach(snippets) { snippet in
                    RibbonMenuRow(snippet.title, icon: SnippetIcon.icon(for: snippet), help: snippet.help) {
                        workspace.insert(snippet)
                    }
                }
            }
        }
    }
}
