import Foundation

/// Gruppen im Menü „Einfügen“.
public enum SnippetCategory: String, CaseIterable, Sendable, Identifiable {
    case headings
    case text
    case lists
    case formulas
    case formulaBlocks
    case theorems
    case figures
    case tables
    case document

    public var id: String { rawValue }

    /// Deutscher Menütitel.
    public var title: String {
        switch self {
        case .headings: return "Überschriften"
        case .text: return "Text"
        case .lists: return "Listen"
        case .formulas: return "Formel-Bausteine"
        case .formulaBlocks: return "Abgesetzte Formeln"
        case .theorems: return "Definition, Satz, Beweis"
        case .figures: return "Bilder"
        case .tables: return "Tabellen"
        case .document: return "Dokument"
        }
    }

    /// SF-Symbol für Menüs.
    public var symbol: String {
        switch self {
        case .headings: return "textformat.size"
        case .text: return "text.alignleft"
        case .lists: return "list.bullet"
        case .formulas: return "x.squareroot"
        case .formulaBlocks: return "function"
        case .theorems: return "checkmark.seal"
        case .figures: return "photo"
        case .tables: return "tablecells"
        case .document: return "doc.text"
        }
    }
}

/// Ein vordefinierter Baustein zum Einfügen, z. B. „Bruch“ oder „Definition“.
///
/// Der Text (`body`) enthält Platzhalter `•`, die der Nutzer mit Tab der Reihe
/// nach anspringt. `Snippet.selectionToken` markiert die Stelle, an die eine
/// vorher markierte Auswahl wandert (z. B. „Auswahl als Definition“).
public struct Snippet: Identifiable, Hashable, Sendable {
    public enum Placement: Hashable, Sendable {
        /// Wird an der Cursorposition in den Fliesstext eingefügt (z. B. `\frac{•}{•}`).
        case inline
        /// Steht auf eigenen Zeilen (z. B. eine `align`-Umgebung).
        case block
    }

    /// Markiert im `body` die Stelle für die aktuelle Auswahl. Ohne Auswahl wird daraus ein Platzhalter.
    public static let selectionToken = "⟦⟧"

    public let id: String
    public var title: String
    public var category: SnippetCategory
    /// LaTeX-Text mit Platzhaltern `•` und optional `selectionToken`. Zeilen mit `\n` getrennt,
    /// Einrückung relativ (wird an die aktuelle Zeile angepasst).
    public var body: String
    public var placement: Placement
    /// Muss im Mathe-Modus stehen (z. B. `\frac`). Ausserhalb einer Formel wird
    /// der Baustein automatisch in `$…$` gesetzt.
    public var requiresMath: Bool
    /// Suchbegriffe auf Deutsch und Englisch (für die Befehlspalette).
    public var keywords: [String]
    /// SF-Symbol für Menüs (optional).
    public var symbol: String?
    /// Benötigte Pakete – werden beim Einfügen automatisch ergänzt.
    public var requirements: [PackageRequirement]
    /// Kurze Erklärung für Einsteiger (Tooltip / Lernmodus).
    public var help: String

    public init(
        id: String,
        title: String,
        category: SnippetCategory,
        body: String,
        placement: Placement,
        requiresMath: Bool = false,
        keywords: [String] = [],
        symbol: String? = nil,
        requirements: [PackageRequirement] = [],
        help: String = ""
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.body = body
        self.placement = placement
        self.requiresMath = requiresMath
        self.keywords = keywords
        self.symbol = symbol
        self.requirements = requirements
        self.help = help
    }
}
