import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// LaTeX-Quelltext (`.tex`). In `Config/Info.plist` als importierter Typ deklariert,
    /// damit Formelfreund dieselbe Kennung wie andere TeX-Programme verwendet.
    static let latexSource = UTType(importedAs: "org.tug.tex", conformingTo: .plainText)
}

/// Ein geöffnetes `.tex`-Dokument.
///
/// Warum eine Klasse (`ReferenceFileDocument`) und kein `struct`?
/// Der Editor (`NSTextView`) verwaltet Text und Rückgängig-Funktion selbst
/// sehr effizient. Mit einer Klasse können Editor und Dokument denselben
/// Zustand teilen, ohne dass SwiftUI bei jedem Tastendruck das ganze Dokument
/// kopiert oder eine zweite, konkurrierende Undo-Historie anlegt.
///
/// Der Text ist mit einer Sperre geschützt, weil macOS Dokumente beim
/// Sichern auf einem Hintergrund-Thread schreibt.
final class TeXDocument: ReferenceFileDocument, @unchecked Sendable {
    typealias Snapshot = String

    static var readableContentTypes: [UTType] { [.latexSource, .plainText] }
    static var writableContentTypes: [UTType] { [.latexSource] }

    private let lock = NSLock()
    private var storage: String

    /// Aktueller Quelltext.
    var text: String {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }

    init(text: String = TeXDocument.starterText) {
        storage = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        storage = TeXDocument.decode(data)
    }

    func snapshot(contentType: UTType) throws -> String {
        text
    }

    func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        // Immer UTF-8 – das erwarten Overleaf, TeXShop und alle aktuellen LaTeX-Versionen.
        FileWrapper(regularFileWithContents: Data(snapshot.utf8))
    }

    /// Liest UTF-8 und fällt bei älteren Dateien auf Latin-1 bzw. Mac Roman zurück.
    static func decode(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        if let latin1 = String(data: data, encoding: .isoLatin1) { return latin1 }
        return String(decoding: data, as: UTF8.self)
    }

    /// Inhalt eines neuen, leeren Dokuments: das Nötigste für ein deutsches Dokument mit Mathematik.
    static let starterText = """
    \\documentclass[a4paper,11pt]{article}
    \\usepackage[ngerman]{babel}
    \\usepackage{amsmath,amssymb,amsthm}

    \\begin{document}

    \\section{Erster Abschnitt}
    Hier beginnt dein Text. Eine Formel im Fliesstext: $a^2 + b^2 = c^2$.

    \\end{document}

    """
}
