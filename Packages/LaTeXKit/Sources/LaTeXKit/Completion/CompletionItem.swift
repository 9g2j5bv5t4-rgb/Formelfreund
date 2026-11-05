import Foundation

/// Ein Vorschlag der Autovervollständigung, z. B. `\frac{…}{…}` oder `enumerate`.
public struct CompletionItem: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        /// Befehl aus dem Katalog, z. B. `\textbf`.
        case command
        /// Umgebung, z. B. `itemize` (nach `\begin{` oder als `\begin{itemize}`).
        case environment
        /// Mathematisches Zeichen mit Vorschau, z. B. `\alpha` → α.
        case symbol
        /// Im Dokument selbst festgelegter Befehl (`\newcommand`).
        case userCommand
        /// Marke für `\ref{…}`.
        case reference
        /// Quelle für `\cite{…}`.
        case citation
        /// Paket für `\usepackage{…}`.
        case package
        /// Dokumentklasse für `\documentclass{…}`.
        case documentClass
    }

    /// Markiert im `body` die Cursorposition nach dem Einfügen (wird entfernt).
    public static let cursorMarker = "‸"

    public let id: String
    public var kind: Kind
    /// Name zum Vergleichen mit dem Getippten, ohne Backslash (`frac`, `itemize`, `fig:kreis`).
    public var name: String
    /// So steht der Vorschlag in der Liste (`\frac{…}{…}`).
    public var label: String
    /// Deutsche Erklärung (`Bruch`).
    public var detail: String
    /// Vorschau-Zeichen wie „α“ (optional).
    public var glyph: String?
    /// Einzufügender Text. Platzhalter `•` werden der Reihe nach mit Tab angesprungen,
    /// `cursorMarker` legt den Cursor fest. Ohne beides steht der Cursor am Ende.
    public var body: String
    /// Gehört in eine Formel; ausserhalb wird der Text in `$…$` gesetzt.
    public var requiresMath: Bool
    /// In Formeln besonders passend (für die Reihenfolge).
    public var isMath: Bool
    /// Weitere Suchbegriffe, vor allem deutsche (`bruch` findet `\frac`).
    public var keywords: [String]
    public var requirements: [PackageRequirement]
    /// Nach dem Einfügen gleich die nächsten Vorschläge zeigen (z. B. nach `\begin{`).
    public var continuesCompletion: Bool
    /// Wie oft gebraucht, 0–100 – bestimmt die Reihenfolge bei gleicher Übereinstimmung.
    public var priority: Int

    public init(
        id: String,
        kind: Kind,
        name: String,
        label: String,
        detail: String,
        glyph: String? = nil,
        body: String,
        requiresMath: Bool = false,
        isMath: Bool = false,
        keywords: [String] = [],
        requirements: [PackageRequirement] = [],
        continuesCompletion: Bool = false,
        priority: Int = 50
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.label = label
        self.detail = detail
        self.glyph = glyph
        self.body = body
        self.requiresMath = requiresMath
        self.isMath = isMath
        self.keywords = keywords
        self.requirements = requirements
        self.continuesCompletion = continuesCompletion
        self.priority = priority
    }
}

/// Wo der Cursor steht und was dort vervollständigt werden kann.
public struct CompletionContext: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// Befehlsname nach `\`.
        case command
        /// Umgebung in `\begin{…}` (`isEnd == false`) oder `\end{…}`.
        case environment(isEnd: Bool)
        /// Marke in `\ref{…}`, `\eqref{…}` …
        case reference
        /// Quelle in `\cite{…}` …
        case citation
        /// Paket in `\usepackage{…}`.
        case package
        /// Klasse in `\documentclass{…}`.
        case documentClass
    }

    public var kind: Kind
    /// Bereits Getipptes (ohne Backslash bzw. Klammer).
    public var prefix: String
    /// Bereich, den der Vorschlag ersetzt (bei Befehlen inklusive Backslash).
    public var range: Range<Int>
    /// Beginn des Befehls (`\` von `\begin`) – für ganze Umgebungen.
    public var commandStart: Int
    /// Folgt direkt eine schliessende `}`? Sie wird dann übersprungen statt verdoppelt.
    public var closingBraceFollows: Bool
    /// Steht der Cursor in einer Formel?
    public var inMath: Bool

    public init(kind: Kind, prefix: String, range: Range<Int>, commandStart: Int, closingBraceFollows: Bool, inMath: Bool) {
        self.kind = kind
        self.prefix = prefix
        self.range = range
        self.commandStart = commandStart
        self.closingBraceFollows = closingBraceFollows
        self.inMath = inMath
    }
}
