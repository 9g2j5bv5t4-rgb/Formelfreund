import Foundation
import Testing
@testable import LaTeXKit

@Suite("Umgebung am Cursor")
struct EnvironmentTests {
    private func block(_ textWithCursor: String, named: Set<String>? = nil) -> (name: String, content: String, whole: String)? {
        let cursor = (textWithCursor as NSString).range(of: "|").location
        let text = textWithCursor.replacingOccurrences(of: "|", with: "")
        let units = Array(text.utf16)
        guard let block = BlockEditor.enclosingEnvironment(in: units, at: cursor, named: named) else { return nil }
        return (block.name, units.string(in: block.contentRange), units.string(in: block.range))
    }

    @Test func innermostEnvironment() {
        let source = "\\begin{document}\n\\begin{itemize}\n  \\item a \\begin{center}x|y\\end{center}\n\\end{itemize}\n\\end{document}"
        #expect(block(source)?.name == "center")
        #expect(block(source)?.content == "xy")
        #expect(block(source, named: ["itemize"])?.name == "itemize")
    }

    @Test func documentIsNeverReturned() {
        #expect(block("\\begin{document}\nText|\n\\end{document}") == nil)
    }

    @Test func cursorOnBeginAndEndTokens() {
        #expect(block("\\beg|in{align}a\\end{align}")?.name == "align")
        #expect(block("\\begin{align}a\\end{al|ign}")?.name == "align")
        #expect(block("\\begin{align}a\\end{align}|") == nil)
        #expect(block("|\\begin{align}a\\end{align}") == nil)
    }

    @Test func nestedSameName() {
        let found = block("\\begin{itemize}\\begin{itemize}a\\end{itemize}|b\\end{itemize}")
        #expect(found?.content == "\\begin{itemize}a\\end{itemize}b")
    }

    @Test func ignoresCommentsAndUnclosed() {
        #expect(block("% \\begin{center}\nText|") == nil)
        #expect(block("\\begin{center}\nText| % \\end{center}") == nil)
        #expect(block("\\begin{quote}\\begin{center}x|\\end{quote}")?.name == "quote")
    }

    @Test func verbatimContentIsOpaque() {
        #expect(block("\\begin{verbatim}\n\\begin{center}|\n\\end{verbatim}")?.name == "verbatim")
        #expect(block("\\begin{verbatim}\\end{center}\\end{verbatim}\\begin{quote}|\\end{quote}")?.name == "quote")
    }
}
