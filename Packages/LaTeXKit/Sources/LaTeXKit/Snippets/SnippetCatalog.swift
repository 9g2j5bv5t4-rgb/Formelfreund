import Foundation

/// Alle Bausteine des Menüs „Einfügen“.
public enum SnippetCatalog {
    /// Alle Bausteine in Menü-Reihenfolge.
    public static var all: [Snippet] {
        fatalError("Noch nicht umgesetzt")
    }

    /// Bausteine einer Gruppe in Menü-Reihenfolge.
    public static func snippets(in category: SnippetCategory) -> [Snippet] {
        all.filter { $0.category == category }
    }

    /// Baustein mit dieser ID.
    public static func snippet(withID id: String) -> Snippet? {
        all.first { $0.id == id }
    }
}
