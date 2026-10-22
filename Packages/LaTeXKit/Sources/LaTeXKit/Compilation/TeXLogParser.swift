import Foundation

/// Liest Fehler und Warnungen aus der `.log`-Datei von LaTeX bzw. aus der
/// Konsolenausgabe von Tectonic.
///
/// TeX-Logs sind nicht für Maschinen gemacht. Der Parser kennt die üblichen
/// Muster:
/// - `! Undefined control sequence.` gefolgt von `l.12 \foo` (klassisch)
/// - `./main.tex:12: Undefined control sequence.` (mit `-file-line-error`)
/// - `LaTeX Warning: … on input line 12.`
/// - `Overfull \hbox (…) in paragraph at lines 12--14`
/// - Tectonic: `error: main.tex:12: Undefined control sequence`
public enum TeXLogParser {
    /// Folgemeldungen, die keinen eigenen Mehrwert haben.
    static let ignoredErrors: Set<String> = [
        "Emergency stop.",
        "==> Fatal error occurred, no output PDF file produced!"
    ]

    static let ignoredWarningPrefixes = [
        "There were undefined references",
        "Label(s) may have changed",
        "There were multiply-defined labels",
        "Unused global option"
    ]

    public static func parse(log: String) -> [CompileIssue] {
        let lines = log.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var issues: [CompileIssue] = []
        var fileStack = FileStack()
        var index = 0

        while index < lines.count {
            let line = lines[index]

            if line.hasPrefix("! ") {
                let message = String(line.dropFirst(2))
                if !ignoredErrors.contains(message) {
                    let context = findContext(in: lines, after: index)
                    let lineNumber = context.line ?? inputLine(in: message)
                    issues.append(CompileIssue(
                        severity: .error,
                        message: message,
                        contextBefore: context.before,
                        contextAfter: context.after,
                        file: fileStack.current,
                        line: lineNumber
                    ))
                }
                index += 1
                continue
            }

            if let fileLine = parseFileLineError(line) {
                let context = findContext(in: lines, after: index)
                if !ignoredErrors.contains(fileLine.message) {
                    issues.append(CompileIssue(
                        severity: .error,
                        message: fileLine.message,
                        contextBefore: context.before,
                        contextAfter: context.after,
                        file: fileLine.file,
                        line: fileLine.line
                    ))
                }
                index += 1
                continue
            }

            if let warning = parseWarningStart(line) {
                // Mehrzeilige Warnungen einsammeln.
                var text = warning.text
                var next = index + 1
                while next < lines.count {
                    let continuation = lines[next]
                    if continuation.trimmingCharacters(in: .whitespaces).isEmpty { break }
                    if let package = warning.package, continuation.hasPrefix("(\(package))") {
                        text += " " + continuation.dropFirst(package.count + 2).trimmingCharacters(in: .whitespaces)
                    } else if warning.package == nil && !continuation.hasPrefix("(") && !continuation.hasPrefix("[") {
                        text += " " + continuation.trimmingCharacters(in: .whitespaces)
                    } else {
                        break
                    }
                    next += 1
                }
                if !ignoredWarningPrefixes.contains(where: { text.hasPrefix($0) }) {
                    issues.append(CompileIssue(
                        severity: .warning,
                        message: text,
                        file: fileStack.current,
                        line: inputLine(in: text)
                    ))
                }
                fileStack.scan(line)
                index = next
                continue
            }

            if line.hasPrefix("Overfull \\hbox") || line.hasPrefix("Overfull \\vbox") {
                issues.append(CompileIssue(
                    severity: .badBox,
                    message: line,
                    file: fileStack.current,
                    line: linesRangeStart(in: line)
                ))
            }

            fileStack.scan(line)
            index += 1
        }
        return deduplicated(issues)
    }

    /// Wertet die Konsolenausgabe von Tectonic aus (`error: main.tex:12: …`).
    public static func parse(tectonicConsole output: String) -> [CompileIssue] {
        var issues: [CompileIssue] = []
        for rawLine in output.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            let severity: CompileIssue.Severity
            let rest: Substring
            if line.hasPrefix("error: ") {
                severity = .error
                rest = line.dropFirst(7)
            } else if line.hasPrefix("warning: ") {
                severity = .warning
                rest = line.dropFirst(9)
            } else {
                continue
            }
            // Allgemeine Abschlussmeldungen ohne Inhalt überspringen.
            if rest.hasPrefix("halted on potentially-recoverable error")
                || rest.hasPrefix("the TeX engine had an error") {
                continue
            }
            if let parsed = parseFileLineError(String(rest)) {
                issues.append(CompileIssue(severity: severity, message: parsed.message, file: parsed.file, line: parsed.line))
            } else {
                issues.append(CompileIssue(severity: severity, message: String(rest)))
            }
        }
        return deduplicated(issues)
    }

    // MARK: - Einzelne Muster

    struct FileLineError {
        var file: String
        var line: Int
        var message: String
    }

    /// `./main.tex:12: Message` bzw. `main.tex:12: Message`
    static func parseFileLineError(_ line: String) -> FileLineError? {
        let extensions = [".tex:", ".sty:", ".cls:", ".ltx:", ".bbl:", ".aux:"]
        for ext in extensions {
            guard let extRange = line.range(of: ext) else { continue }
            let file = String(line[..<extRange.lowerBound]) + ext.dropLast()
            let afterExt = line[extRange.upperBound...]
            guard let colon = afterExt.firstIndex(of: ":") else { continue }
            guard let number = Int(afterExt[..<colon]) else { continue }
            let message = afterExt[afterExt.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            guard !file.contains(" "), !message.isEmpty else { continue }
            return FileLineError(file: file, line: number, message: message)
        }
        return nil
    }

    struct WarningStart {
        var text: String
        var package: String?
    }

    /// `LaTeX Warning: …`, `Package foo Warning: …`, `Class foo Warning: …`, `LaTeX Font Warning: …`
    static func parseWarningStart(_ line: String) -> WarningStart? {
        guard let marker = line.range(of: " Warning: ") else { return nil }
        let head = line[..<marker.lowerBound]
        let text = String(line[marker.upperBound...]).trimmingCharacters(in: .whitespaces)
        let words = head.split(separator: " ")
        guard let first = words.first else { return nil }
        switch first {
        case "LaTeX":
            if words.count == 1 { return WarningStart(text: text, package: nil) }
            if words.count == 2 { return WarningStart(text: text, package: String(words[1])) }  // z. B. „LaTeX Font“
        case "Package", "Class":
            if words.count == 2 { return WarningStart(text: text, package: String(words[1])) }
        default:
            break
        }
        return nil
    }

    /// Sucht nach einer Fehlermeldung die Zeile `l.12 …` mit Zeilennummer und Kontext.
    static func findContext(in lines: [String], after index: Int) -> (line: Int?, before: String?, after: String?) {
        var j = index + 1
        while j < lines.count && j <= index + 25 {
            let line = lines[j]
            if line.hasPrefix("! ") || parseFileLineError(line) != nil { break }
            if line.hasPrefix("l."), let space = line.firstIndex(of: " ") {
                let numberText = line[line.index(line.startIndex, offsetBy: 2)..<space]
                if let number = Int(numberText) {
                    let before = String(line[line.index(after: space)...])
                    var after: String?
                    if j + 1 < lines.count {
                        let next = lines[j + 1].trimmingCharacters(in: .whitespaces)
                        after = next.isEmpty ? nil : next
                    }
                    return (number, before, after)
                }
            }
            j += 1
        }
        return (nil, nil, nil)
    }

    /// „… on input line 12.“ → 12
    static func inputLine(in text: String) -> Int? {
        guard let range = text.range(of: "on input line ") else { return nil }
        let digits = text[range.upperBound...].prefix(while: { $0.isNumber })
        return Int(digits)
    }

    /// „… at lines 12--14“ / „… at line 12“ → 12
    static func linesRangeStart(in text: String) -> Int? {
        for marker in ["at lines ", "at line "] {
            if let range = text.range(of: marker) {
                let digits = text[range.upperBound...].prefix(while: { $0.isNumber })
                if let value = Int(digits) { return value }
            }
        }
        return nil
    }

    static func deduplicated(_ issues: [CompileIssue]) -> [CompileIssue] {
        var seen = Set<String>()
        return issues.filter { seen.insert($0.id).inserted }
    }
}

/// Verfolgt, welche Datei TeX gerade liest. Im Log öffnet `(./datei.tex`
/// eine Datei, die passende `)` schliesst sie wieder.
struct FileStack {
    private var stack: [String?] = []

    var current: String? {
        for entry in stack.reversed() {
            if let entry { return entry }
        }
        return nil
    }

    mutating func scan(_ line: String) {
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "(" {
                // Dateiname bis zum nächsten Leerzeichen oder Klammer.
                var j = i + 1
                while j < chars.count && chars[j] != " " && chars[j] != "(" && chars[j] != ")" { j += 1 }
                let candidate = String(chars[(i + 1)..<j])
                stack.append(Self.looksLikeFile(candidate) ? candidate : nil)
                i = j
                continue
            }
            if c == ")" {
                if !stack.isEmpty { stack.removeLast() }
            }
            i += 1
        }
    }

    static func looksLikeFile(_ candidate: String) -> Bool {
        guard !candidate.isEmpty else { return false }
        if candidate.hasPrefix("./") || candidate.hasPrefix("/") { return true }
        let extensions = [".tex", ".sty", ".cls", ".clo", ".cfg", ".def", ".fd", ".aux", ".ldf", ".bbl", ".toc", ".out"]
        return extensions.contains { candidate.hasSuffix($0) }
    }
}
