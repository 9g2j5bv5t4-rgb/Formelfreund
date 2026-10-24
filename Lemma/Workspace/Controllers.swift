import Foundation
import LaTeXKit

/// Was das Dokumentfenster vom Editor braucht – ohne den Editor selbst zu kennen.
///
/// Der Arbeitsbereich (`DocumentWorkspace`) spricht den Editor nur über dieses
/// Protokoll an. So bleiben Logik und AppKit-Ansicht sauber getrennt.
@MainActor
protocol EditorControlling: AnyObject {
    /// Springt zur Zeile (1-basiert), scrollt sie in die Mitte und hebt sie kurz hervor.
    func reveal(line: Int)
    /// Zeile, in der der Cursor steht (1-basiert).
    var cursorLine: Int { get }
    /// Holt den Tastaturfokus in den Editor.
    func focus()

    /// Aktuelle Auswahl (UTF-16-Offsets).
    var selection: Range<Int> { get }
    /// Der aktuelle Text, direkt aus dem Editor gelesen (ohne Kopie).
    var source: NSStringSource { get }
    /// Kopie des Textes als UTF-16-Puffer – für Berechnungen im Hintergrund.
    func snapshot() -> [UInt16]
    /// Letzte Syntax-Analyse, falls sie zum aktuellen Text passt.
    var currentAnalysis: TokenizedText? { get }

    /// Führt eine Änderung aus (rückgängig machbar).
    func apply(_ edit: TextEdit)
    /// Fasst mehrere Änderungen zu *einem* Rückgängig-Schritt mit Namen zusammen.
    func groupEdits(named actionName: String, _ body: () -> Void)
    /// Wählt einen Bereich aus und scrollt ihn ins Bild.
    func select(_ range: Range<Int>)
}

/// Was das Dokumentfenster von der PDF-Vorschau braucht.
@MainActor
protocol PDFViewerControlling: AnyObject {
    /// Zeigt eine SyncTeX-Position im PDF und hebt sie kurz hervor.
    func reveal(_ position: SyncTeXPosition)
}
