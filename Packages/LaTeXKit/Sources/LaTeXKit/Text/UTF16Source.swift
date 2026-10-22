import Foundation

/// Lesender Zugriff auf Text als UTF-16-Codeeinheiten.
///
/// AppKit (`NSTextView`, `NSString`) zählt Positionen in UTF-16-Einheiten.
/// Damit Positionen zwischen Editor und Logik ohne Umrechnung passen, arbeitet
/// LaTeXKit durchgehend mit UTF-16-Offsets. Über dieses Protokoll können die
/// Algorithmen sowohl auf einem schnellen `[UInt16]`-Puffer (Hintergrund-Analyse)
/// als auch direkt auf dem `NSString` des Editors (Hauptthread, kurze Scans)
/// laufen, ohne den Text vorher zu kopieren.
public protocol UTF16Source {
    /// Anzahl der UTF-16-Einheiten.
    var count: Int { get }
    /// Die Einheit an Position `index` (0 ≤ index < count).
    subscript(index: Int) -> UInt16 { get }
}

extension Array: UTF16Source where Element == UInt16 {}
extension ContiguousArray: UTF16Source where Element == UInt16 {}

/// Adapter, der einen `NSString` als `UTF16Source` nutzbar macht.
public struct NSStringSource: UTF16Source {
    public let string: NSString
    public init(_ string: NSString) { self.string = string }
    public var count: Int { string.length }
    public subscript(index: Int) -> UInt16 { string.character(at: index) }
}

extension UTF16Source {
    /// Zeichen an `index` oder `nil`, falls außerhalb des Textes.
    @inlinable
    public func unit(at index: Int) -> UInt16? {
        index >= 0 && index < count ? self[index] : nil
    }

    /// Wandelt einen Bereich in einen Swift-String um.
    public func string(in range: Range<Int>) -> String {
        let lower = max(0, range.lowerBound)
        let upper = min(count, range.upperBound)
        guard lower < upper else { return "" }
        var units: [UInt16] = []
        units.reserveCapacity(upper - lower)
        for i in lower..<upper { units.append(self[i]) }
        return String(decoding: units, as: UTF16.self)
    }

    /// Prüft, ob an `index` die ASCII-Zeichenfolge `literal` steht.
    public func matches(_ literal: String, at index: Int) -> Bool {
        var i = index
        for unit in literal.utf16 {
            guard i < count, i >= 0, self[i] == unit else { return false }
            i += 1
        }
        return true
    }

    /// Ist das Zeichen an `index` durch einen Backslash maskiert (z. B. `\{`)?
    /// Zählt die direkt davorstehenden Backslashes: ungerade Anzahl = maskiert.
    public func isEscaped(at index: Int) -> Bool {
        var backslashes = 0
        var i = index - 1
        while i >= 0 && self[i] == TeXChar.backslash {
            backslashes += 1
            i -= 1
        }
        return backslashes % 2 == 1
    }

    /// Anfang der Zeile, in der `index` liegt.
    public func lineStart(before index: Int) -> Int {
        var i = min(index, count) - 1
        while i >= 0 && self[i] != TeXChar.newline { i -= 1 }
        return i + 1
    }

    /// Ende der Zeile (Position des Zeilenumbruchs bzw. Textende) ab `index`.
    public func lineEnd(after index: Int) -> Int {
        var i = max(0, index)
        while i < count && self[i] != TeXChar.newline { i += 1 }
        return i
    }

    /// Beginn eines Kommentars (`%`) in der Zeile ab `lineStart`, falls vorhanden.
    public func commentStart(inLineStartingAt lineStart: Int) -> Int? {
        var i = lineStart
        while i < count && self[i] != TeXChar.newline {
            if self[i] == TeXChar.percent && !isEscaped(at: i) { return i }
            i += 1
        }
        return nil
    }
}

/// Häufig gebrauchte UTF-16-Werte. Als Konstanten benannt, damit der Code lesbar bleibt.
public enum TeXChar {
    public static let backslash: UInt16 = 0x5C   // \
    public static let braceOpen: UInt16 = 0x7B   // {
    public static let braceClose: UInt16 = 0x7D  // }
    public static let bracketOpen: UInt16 = 0x5B // [
    public static let bracketClose: UInt16 = 0x5D // ]
    public static let parenOpen: UInt16 = 0x28   // (
    public static let parenClose: UInt16 = 0x29  // )
    public static let dollar: UInt16 = 0x24      // $
    public static let percent: UInt16 = 0x25     // %
    public static let ampersand: UInt16 = 0x26   // &
    public static let tilde: UInt16 = 0x7E       // ~
    public static let caret: UInt16 = 0x5E       // ^
    public static let underscore: UInt16 = 0x5F  // _
    public static let hash: UInt16 = 0x23        // #
    public static let star: UInt16 = 0x2A        // *
    public static let newline: UInt16 = 0x0A     // \n
    public static let carriageReturn: UInt16 = 0x0D
    public static let space: UInt16 = 0x20
    public static let tab: UInt16 = 0x09

    @inlinable
    public static func isASCIILetter(_ u: UInt16) -> Bool {
        (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A)
    }

    @inlinable
    public static func isASCIIDigit(_ u: UInt16) -> Bool {
        u >= 0x30 && u <= 0x39
    }

    @inlinable
    public static func isWhitespace(_ u: UInt16) -> Bool {
        u == space || u == tab || u == newline || u == carriageReturn
    }

    /// Buchstabe oder Ziffer (inkl. Umlaute u. ä.).
    public static func isAlphanumeric(_ u: UInt16) -> Bool {
        if isASCIILetter(u) || isASCIIDigit(u) { return true }
        if u < 0x80 { return false }
        guard let scalar = Swift.Unicode.Scalar(u) else { return false }
        return CharacterSet.alphanumerics.contains(scalar)
    }
}
