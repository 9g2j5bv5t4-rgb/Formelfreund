import Foundation

/// Eine Meldung aus dem LaTeX-Lauf: Fehler, Warnung oder Satzproblem.
public struct CompileIssue: Identifiable, Hashable, Sendable {
    public enum Severity: Int, Sendable, Comparable, Hashable {
        case error = 0
        case warning = 1
        /// „Overfull \hbox“ u. ä. – rein typografisch, für Einsteiger meist unwichtig.
        case badBox = 2

        public static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public var id: String
    public var severity: Severity
    /// Originalmeldung von LaTeX (Englisch), z. B. „Undefined control sequence.“
    public var message: String
    /// Quelltext an der Fehlerstelle, so wie LaTeX ihn zeigt (Text bis zum Fehler).
    public var contextBefore: String?
    /// Rest der Zeile nach der Fehlerstelle.
    public var contextAfter: String?
    /// Datei, in der der Fehler auftrat (wie im Log angegeben), falls bekannt.
    public var file: String?
    /// 1-basierte Zeile, falls bekannt.
    public var line: Int?

    public init(
        severity: Severity,
        message: String,
        contextBefore: String? = nil,
        contextAfter: String? = nil,
        file: String? = nil,
        line: Int? = nil
    ) {
        self.severity = severity
        self.message = message
        self.contextBefore = contextBefore
        self.contextAfter = contextAfter
        self.file = file
        self.line = line
        self.id = "\(severity.rawValue)|\(file ?? "")|\(line ?? 0)|\(message)|\(contextBefore ?? "")"
    }

    /// Gehört die Meldung zur Hauptdatei (oder ist die Datei unbekannt)?
    public func belongs(toMainFile mainFileName: String) -> Bool {
        guard let file else { return true }
        return (file as NSString).lastPathComponent == mainFileName
    }
}
