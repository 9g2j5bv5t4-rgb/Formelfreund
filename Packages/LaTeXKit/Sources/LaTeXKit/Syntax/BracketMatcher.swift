import Foundation

/// Findet zusammengehörige Klammern, um sie im Editor hervorzuheben.
///
/// Berücksichtigt maskierte Klammern (`\{`) und Kommentare. Die Suche ist auf
/// eine Distanz begrenzt, damit sie auf dem Hauptthread nie spürbar wird.
public enum BracketMatcher {
    public struct Match: Equatable, Sendable {
        /// Position der öffnenden Klammer.
        public var open: Int
        /// Position der schliessenden Klammer.
        public var close: Int

        public init(open: Int, close: Int) {
            self.open = open
            self.close = close
        }
    }

    static let openers: [UInt16: UInt16] = [
        TeXChar.braceOpen: TeXChar.braceClose,
        TeXChar.bracketOpen: TeXChar.bracketClose,
        TeXChar.parenOpen: TeXChar.parenClose
    ]
    static let closers: [UInt16: UInt16] = [
        TeXChar.braceClose: TeXChar.braceOpen,
        TeXChar.bracketClose: TeXChar.bracketOpen,
        TeXChar.parenClose: TeXChar.parenOpen
    ]

    /// Sucht das Klammerpaar für eine Klammer direkt vor oder hinter dem Cursor.
    /// Die Klammer vor dem Cursor (gerade getippt) hat Vorrang.
    public static func match<S: UTF16Source>(in text: S, cursor: Int, limit: Int = 20_000) -> Match? {
        for position in [cursor - 1, cursor] {
            guard let unit = text.unit(at: position) else { continue }
            guard openers[unit] != nil || closers[unit] != nil else { continue }
            guard !text.isEscaped(at: position), !isInComment(text, position) else { continue }
            if let closer = openers[unit] {
                if let close = scanForward(text, from: position, open: unit, close: closer, limit: limit) {
                    return Match(open: position, close: close)
                }
            } else if let opener = closers[unit] {
                if let open = scanBackward(text, from: position, open: opener, close: unit, limit: limit) {
                    return Match(open: open, close: position)
                }
            }
        }
        return nil
    }

    /// Liegt die Position in einem Kommentar?
    static func isInComment<S: UTF16Source>(_ text: S, _ position: Int) -> Bool {
        let start = text.lineStart(before: position)
        guard let comment = text.commentStart(inLineStartingAt: start) else { return false }
        return comment < position
    }

    static func scanForward<S: UTF16Source>(_ text: S, from position: Int, open: UInt16, close: UInt16, limit: Int) -> Int? {
        var depth = 1
        var j = position + 1
        let end = min(text.count, position + limit)
        while j < end {
            let u = text[j]
            if u == TeXChar.percent && !text.isEscaped(at: j) {
                // Rest der Zeile ist Kommentar.
                j = text.lineEnd(after: j)
                continue
            }
            if u == open && !text.isEscaped(at: j) {
                depth += 1
            } else if u == close && !text.isEscaped(at: j) {
                depth -= 1
                if depth == 0 { return j }
            }
            j += 1
        }
        return nil
    }

    static func scanBackward<S: UTF16Source>(_ text: S, from position: Int, open: UInt16, close: UInt16, limit: Int) -> Int? {
        var depth = 1
        let stop = max(0, position - limit)
        // Zeilenweise rückwärts, damit Kommentare zuverlässig übersprungen werden.
        var segmentEnd = position             // exklusiv
        var lineStart = text.lineStart(before: position)
        while true {
            let comment = text.commentStart(inLineStartingAt: lineStart) ?? Int.max
            var j = min(segmentEnd, comment) - 1
            while j >= max(lineStart, stop) {
                let u = text[j]
                if u == close && !text.isEscaped(at: j) {
                    depth += 1
                } else if u == open && !text.isEscaped(at: j) {
                    depth -= 1
                    if depth == 0 { return j }
                }
                j -= 1
            }
            if lineStart <= stop || lineStart == 0 { return nil }
            segmentEnd = lineStart - 1        // Zeilenumbruch der vorherigen Zeile
            lineStart = text.lineStart(before: segmentEnd)
        }
    }
}
