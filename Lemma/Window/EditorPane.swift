import LaTeXKit
import SwiftUI

/// Mittlere Spalte: der Editor, darüber bei Bedarf der erste Fehler mit Erklärung.
///
/// Der Fehler steht oben statt in einer Leiste am unteren Rand: Fenster werden oft
/// so verschoben, dass der untere Rand nicht zu sehen ist (Apple, Windows).
struct EditorPane: View {
    let workspace: DocumentWorkspace

    @AppStorage(AppSettings.Keys.editorFontSize) private var fontSize = AppSettings.Defaults.editorFontSize
    @AppStorage(AppSettings.Keys.showLineNumbers) private var showLineNumbers = AppSettings.Defaults.showLineNumbers
    @AppStorage(AppSettings.Keys.autoPairing) private var autoPairing = AppSettings.Defaults.autoPairing
    @AppStorage(AppSettings.Keys.highlightCurrentLine) private var highlightCurrentLine = AppSettings.Defaults.highlightCurrentLine

    var body: some View {
        VStack(spacing: 0) {
            if let issue = workspace.errors.first {
                IssueBar(
                    issue: issue,
                    advice: workspace.advice(for: issue),
                    totalErrors: workspace.errors.count,
                    reveal: { if let line = issue.line { workspace.reveal(line: line) } },
                    fix: { workspace.applyFix($0) }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            EditorView(
                workspace: workspace,
                fontSize: CGFloat(fontSize),
                showLineNumbers: showLineNumbers,
                autoPairing: autoPairing,
                highlightCurrentLine: highlightCurrentLine
            )
        }
        .animation(.easeInOut(duration: 0.2), value: workspace.errors.first?.id)
    }
}

/// Schmale Leiste über dem Editor mit dem ersten Fehler – auf Deutsch erklärt,
/// mit Vorschlag und (wenn möglich) einem Knopf, der den Fehler behebt.
struct IssueBar: View {
    let issue: CompileIssue
    let advice: IssueAdvice?
    let totalErrors: Int
    let reveal: () -> Void
    let fix: (QuickFix) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: reveal) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill")
                        .foregroundStyle(.red)
                    if let line = issue.line {
                        Text("Zeile \(line)")
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(advice?.explanation ?? issue.message)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if let suggestion = advice?.suggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(helpText)
            if let quickFix = advice?.fix {
                Button {
                    fix(quickFix)
                } label: {
                    Label("Beheben", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("\(quickFix.title) – rückgängig mit ⌘Z")
            }
            if totalErrors > 1 {
                Text("+\(totalErrors - 1) weitere")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.red.opacity(0.07))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var helpText: String {
        guard let advice else { return "Zur Fehlerstelle springen" }
        return "\(advice.explanation)\n\(advice.suggestion)\n\nLaTeX meldet: \(issue.message)"
    }
}
