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
}

/// Was das Dokumentfenster von der PDF-Vorschau braucht.
@MainActor
protocol PDFViewerControlling: AnyObject {
    /// Zeigt eine SyncTeX-Position im PDF und hebt sie kurz hervor.
    func reveal(_ position: SyncTeXPosition)
}
