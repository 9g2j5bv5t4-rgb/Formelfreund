import LaTeXKit
import SwiftUI

/// Mittlere Spalte: der Editor, darunter bei Bedarf eine schmale Fehlerleiste.
struct EditorPane: View {
    let workspace: DocumentWorkspace

    @AppStorage(AppSettings.Keys.editorFontSize) private var fontSize = AppSettings.Defaults.editorFontSize
    @AppStorage(AppSettings.Keys.showLineNumbers) private var showLineNumbers = AppSettings.Defaults.showLineNumbers
    @AppStorage(AppSettings.Keys.autoPairing) private var autoPairing = AppSettings.Defaults.autoPairing
    @AppStorage(AppSettings.Keys.highlightCurrentLine) private var highlightCurrentLine = AppSettings.Defaults.highlightCurrentLine

    var body: some View {
        EditorView(
            workspace: workspace,
            fontSize: CGFloat(fontSize),
            showLineNumbers: showLineNumbers,
            autoPairing: autoPairing,
            highlightCurrentLine: highlightCurrentLine
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let issue = workspace.errors.first {
                IssueBar(issue: issue, totalErrors: workspace.errors.count) {
                    if let line = issue.line { workspace.reveal(line: line) }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: workspace.errors.first?.id)
    }
}

/// Schmale Leiste unter dem Editor mit dem ersten Fehler.
struct IssueBar: View {
    let issue: CompileIssue
    let totalErrors: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                if let line = issue.line {
                    Text("Zeile \(line)")
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                }
                Text(issue.message)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 8)
                if totalErrors > 1 {
                    Text("+\(totalErrors - 1) weitere")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .help("Zur Fehlerstelle springen")
    }
}
