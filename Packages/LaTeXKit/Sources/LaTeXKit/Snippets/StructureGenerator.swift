import Foundation

/// Klammern einer Matrix (Umgebungen aus amsmath).
public enum MatrixDelimiter: String, CaseIterable, Sendable, Identifiable {
    case parentheses
    case brackets
    case bars
    case doubleBars
    case braces
    case none

    public var id: String { rawValue }

    /// Umgebung aus amsmath, z. B. `pmatrix`.
    public var environment: String {
        switch self {
        case .parentheses: return "pmatrix"
        case .brackets: return "bmatrix"
        case .bars: return "vmatrix"
        case .doubleBars: return "Vmatrix"
        case .braces: return "Bmatrix"
        case .none: return "matrix"
        }
    }

    public var title: String {
        switch self {
        case .parentheses: return "Runde Klammern"
        case .brackets: return "Eckige Klammern"
        case .bars: return "Determinante"
        case .doubleBars: return "Doppelstriche"
        case .braces: return "Geschweifte Klammern"
        case .none: return "Ohne Klammern"
        }
    }

    /// Klammerzeichen für die Vorschau im Menü.
    public var glyphs: (open: String, close: String) {
        switch self {
        case .parentheses: return ("(", ")")
        case .brackets: return ("[", "]")
        case .bars: return ("|", "|")
        case .doubleBars: return ("‖", "‖")
        case .braces: return ("{", "}")
        case .none: return ("", "")
        }
    }
}

/// Linien einer Tabelle.
public enum TableStyle: String, CaseIterable, Sendable, Identifiable {
    /// Alle Linien, wie ein Gitter.
    case grid
    /// Nur oben, unter der Kopfzeile und unten – wie in Büchern (Paket booktabs).
    case booktabs
    /// Ganz ohne Linien.
    case plain

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .grid: return "Gitter"
        case .booktabs: return "Wie im Buch"
        case .plain: return "Ohne Linien"
        }
    }
}

/// Ausrichtung des Inhalts in den Spalten einer Tabelle.
public enum ColumnAlignment: String, CaseIterable, Sendable, Identifiable {
    case left = "l"
    case center = "c"
    case right = "r"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .left: return "Links"
        case .center: return "Zentriert"
        case .right: return "Rechts"
        }
    }
}

/// Einstellungen für eine neue Tabelle.
public struct TableOptions: Hashable, Sendable {
    /// Zeilen inklusive Kopfzeile.
    public var rows: Int
    public var columns: Int
    public var style: TableStyle
    public var alignment: ColumnAlignment
    /// Erste Zeile fett als Kopfzeile.
    public var hasHeader: Bool
    /// Als Abbildung mit Beschriftung („Tabelle 1: …“) statt nur zentriert im Text.
    public var hasCaption: Bool

    public init(
        rows: Int,
        columns: Int,
        style: TableStyle = .grid,
        alignment: ColumnAlignment = .center,
        hasHeader: Bool = true,
        hasCaption: Bool = true
    ) {
        self.rows = rows
        self.columns = columns
        self.style = style
        self.alignment = alignment
        self.hasHeader = hasHeader
        self.hasCaption = hasCaption
    }
}

/// Erzeugt Bausteine in frei wählbarer Grösse: Tabellen, Matrizen,
/// Gleichungssysteme, Fallunterscheidungen, mehrzeilige Formeln, Listen.
///
/// Jede Zelle bekommt einen Platzhalter `•`, den man mit Tab anspringt.
public enum StructureGenerator {
    /// Grösste Anzahl Zeilen bzw. Spalten.
    public static let maximumSize = 20

    static func clamped(_ value: Int) -> Int {
        min(max(value, 1), maximumSize)
    }

    // MARK: - Tabellen

    public static func table(_ options: TableOptions) -> Snippet {
        let rows = clamped(options.rows)
        let columns = clamped(options.columns)
        let align = options.alignment.rawValue
        let spec: String
        switch options.style {
        case .grid: spec = "|" + Array(repeating: align, count: columns).joined(separator: "|") + "|"
        case .booktabs, .plain: spec = String(repeating: align, count: columns)
        }

        func row(header: Bool) -> String {
            let cell = header ? "\\textbf{•}" : "•"
            return Array(repeating: cell, count: columns).joined(separator: " & ") + " \\\\"
        }

        var body: [String] = ["\\begin{tabular}{\(spec)}"]
        switch options.style {
        case .grid: body.append("  \\hline")
        case .booktabs: body.append("  \\toprule")
        case .plain: break
        }
        for index in 0..<rows {
            let isHeader = options.hasHeader && index == 0
            body.append("  " + row(header: isHeader))
            switch options.style {
            case .grid:
                body.append("  \\hline")
            case .booktabs:
                if isHeader && rows > 1 { body.append("  \\midrule") }
            case .plain:
                break
            }
        }
        if options.style == .booktabs { body.append("  \\bottomrule") }
        body.append("\\end{tabular}")

        var lines: [String]
        if options.hasCaption {
            lines = ["\\begin{table}[htbp]", "  \\centering"]
            lines += body.map { "  " + $0 }
            lines += ["  \\caption{•}", "\\end{table}"]
        } else {
            lines = ["\\begin{center}"] + body.map { "  " + $0 } + ["\\end{center}"]
        }
        return Snippet(
            id: "generated.table.\(rows)x\(columns)",
            title: "Tabelle \(rows) × \(columns)",
            category: .tables,
            body: lines.joined(separator: "\n"),
            placement: .block,
            symbol: "tablecells",
            requirements: options.style == .booktabs ? [PackageRequirement("booktabs")] : [],
            help: "Tabelle mit \(rows) Zeilen und \(columns) Spalten. Tab springt von Zelle zu Zelle."
        )
    }

    // MARK: - Matrizen und Vektoren

    /// Matrix mit `rows` × `columns` Einträgen.
    /// - Parameter displayed: Auf eigenen Zeilen in `\[ … \]`; sonst kompakt für eine bestehende Formel.
    public static func matrix(rows: Int, columns: Int, delimiter: MatrixDelimiter, displayed: Bool) -> Snippet {
        let rows = clamped(rows)
        let columns = clamped(columns)
        let environment = delimiter.environment
        let cells = (0..<rows).map { _ in Array(repeating: "•", count: columns).joined(separator: " & ") }
        let body: String
        if displayed {
            var lines = ["\\[", "  \\begin{\(environment)}"]
            for (index, row) in cells.enumerated() {
                lines.append("    " + row + (index < rows - 1 ? " \\\\" : ""))
            }
            lines += ["  \\end{\(environment)}", "\\]"]
            body = lines.joined(separator: "\n")
        } else {
            body = "\\begin{\(environment)} " + cells.joined(separator: " \\\\ ") + " \\end{\(environment)}"
        }
        let name = delimiter == .bars ? "Determinante" : "Matrix"
        return Snippet(
            id: "generated.\(environment).\(rows)x\(columns)\(displayed ? ".display" : "")",
            title: "\(name) \(rows) × \(columns)",
            category: .formulaBlocks,
            body: body,
            placement: displayed ? .block : .inline,
            requiresMath: !displayed,
            symbol: "square.grid.3x3",
            requirements: [PackageRequirement("amsmath")],
            help: "\(name) mit \(rows) Zeilen und \(columns) Spalten (\(delimiter.title)). Tab springt von Eintrag zu Eintrag."
        )
    }

    /// Spaltenvektor mit `components` Einträgen – für eine bestehende Formel.
    public static func vector(components: Int, delimiter: MatrixDelimiter = .parentheses) -> Snippet {
        let count = clamped(components)
        let environment = delimiter.environment
        let body = "\\begin{\(environment)} " + Array(repeating: "•", count: count).joined(separator: " \\\\ ") + " \\end{\(environment)}"
        return Snippet(
            id: "generated.vector.\(count)",
            title: "Vektor mit \(count) Einträgen",
            category: .formulas,
            body: body,
            placement: .inline,
            requiresMath: true,
            symbol: "arrow.right",
            requirements: [PackageRequirement("amsmath")],
            help: "Spaltenvektor mit \(count) Einträgen."
        )
    }

    // MARK: - Gleichungen

    /// Gleichungssystem mit `equations` Zeilen (geschweifte Klammer links).
    public static func equationSystem(equations: Int) -> Snippet {
        let count = clamped(equations)
        var lines = ["\\[", "  \\begin{cases}"]
        for index in 0..<count {
            lines.append("    • = •" + (index < count - 1 ? " \\\\" : ""))
        }
        lines += ["  \\end{cases}", "\\]"]
        return Snippet(
            id: "generated.system.\(count)",
            title: "Gleichungssystem mit \(count) Gleichungen",
            category: .formulaBlocks,
            body: lines.joined(separator: "\n"),
            placement: .block,
            symbol: "equal.square",
            requirements: [PackageRequirement("amsmath")],
            help: "Gleichungssystem mit \(count) Gleichungen, links mit geschweifter Klammer."
        )
    }

    /// Fallunterscheidung mit `cases` Fällen; der letzte heisst „sonst“.
    public static func cases(_ cases: Int) -> Snippet {
        let count = clamped(cases)
        var lines = ["\\[", "  \(Snippet.selectionToken) = \\begin{cases}"]
        for index in 0..<count {
            let isLast = index == count - 1
            let condition = isLast && count > 1 ? "\\text{sonst}" : "\\text{falls } •"
            lines.append("    • & " + condition + (isLast ? "" : " \\\\"))
        }
        lines += ["  \\end{cases}", "\\]"]
        return Snippet(
            id: "generated.cases.\(count)",
            title: "Fallunterscheidung mit \(count) Fällen",
            category: .formulaBlocks,
            body: lines.joined(separator: "\n"),
            placement: .block,
            symbol: "arrow.triangle.branch",
            requirements: [PackageRequirement("amsmath")],
            help: "Funktion mit \(count) Fällen, z. B. für Betragsfunktionen oder stückweise Definitionen."
        )
    }

    /// Mehrzeilige Rechnung, an den Gleichheitszeichen ausgerichtet.
    public static func alignedEquations(_ lines: Int, numbered: Bool) -> Snippet {
        let count = clamped(lines)
        let environment = numbered ? "align" : "align*"
        var body = ["\\begin{\(environment)}"]
        for index in 0..<count {
            let left = index == 0 ? Snippet.selectionToken + " " : ""
            body.append("  \(left)&= •" + (index < count - 1 ? " \\\\" : ""))
        }
        body.append("\\end{\(environment)}")
        return Snippet(
            id: "generated.\(numbered ? "align" : "alignStar").\(count)",
            title: "\(count) ausgerichtete Zeilen",
            category: .formulaBlocks,
            body: body.joined(separator: "\n"),
            placement: .block,
            symbol: "equal",
            requirements: [PackageRequirement("amsmath")],
            help: "Rechnung über \(count) Zeilen, an den Gleichheitszeichen ausgerichtet\(numbered ? ", jede Zeile nummeriert" : "")."
        )
    }

    // MARK: - Listen

    /// Aufzählung oder nummerierte Liste mit `items` Punkten.
    public static func list(_ kind: ListKind, items: Int) -> Snippet {
        let count = clamped(items)
        var lines = ["\\begin{\(kind.environment)}"]
        for index in 0..<count {
            lines.append("  \\item " + (index == 0 ? Snippet.selectionToken : "•"))
        }
        lines.append("\\end{\(kind.environment)}")
        return Snippet(
            id: "generated.\(kind.environment).\(count)",
            title: "\(kind.title) mit \(count) Punkten",
            category: .lists,
            body: lines.joined(separator: "\n"),
            placement: .block,
            symbol: kind.symbol,
            help: "\(kind.title) mit \(count) Punkten."
        )
    }
}
