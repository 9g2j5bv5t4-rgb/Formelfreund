import LaTeXKit
import SwiftUI

/// Liste aller Meldungen des letzten Laufs (im Popover der Statusanzeige).
struct IssueListView: View {
    let workspace: DocumentWorkspace
    let dismiss: () -> Void
    @State private var showsTypography = false

    private var visibleIssues: [CompileIssue] {
        workspace.issues.filter { showsTypography || $0.severity != .badBox }
    }

    private var badBoxCount: Int {
        workspace.issues.filter { $0.severity == .badBox }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if visibleIssues.isEmpty {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: emptySymbol)
                } description: {
                    Text(emptyDescription)
                }
                .frame(height: 180)
            } else {
                List(visibleIssues) { issue in
                    IssueRow(issue: issue)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let line = issue.line {
                                workspace.reveal(line: line)
                                dismiss()
                            }
                        }
                }
                .listStyle(.inset)
                .frame(minHeight: 120, idealHeight: 260, maxHeight: 400)
            }
            Divider()
            footer
        }
        .frame(width: 420)
    }

    private var header: some View {
        HStack {
            Text("Meldungen")
                .font(.headline)
            Spacer()
            if case .engineUnavailable = workspace.status {
                Button("Erneut versuchen") { workspace.retryEngineSetup() }
            }
        }
        .padding(12)
    }

    private var footer: some View {
        HStack {
            if badBoxCount > 0 {
                Toggle("Satzwarnungen (\(badBoxCount))", isOn: $showsTypography)
                    .toggleStyle(.checkbox)
                    .help("„Overfull hbox“ u. ä.: Eine Zeile ragt etwas über den Rand. Meist unkritisch.")
            }
            Spacer()
            Button("Protokoll anzeigen") {
                dismiss()
                workspace.isShowingLog = true
            }
            .disabled(workspace.lastLog == nil)
        }
        .controlSize(.small)
        .padding(10)
    }

    private var emptyTitle: String {
        if case .engineUnavailable = workspace.status { return "LaTeX nicht verfügbar" }
        return workspace.status == .idle ? "Noch nicht kompiliert" : "Keine Meldungen"
    }

    private var emptySymbol: String {
        if case .engineUnavailable = workspace.status { return "wifi.exclamationmark" }
        return workspace.status == .idle ? "circle.dashed" : "checkmark.circle"
    }

    private var emptyDescription: String {
        if case .engineUnavailable(let message) = workspace.status { return message }
        return workspace.status == .idle
            ? "Drücke ⌘↩, um das Dokument zu kompilieren."
            : "LaTeX hat keine Fehler oder Warnungen gemeldet."
    }
}

/// Eine Meldung mit Symbol, Zeile, Text und Quelltextausschnitt.
struct IssueRow: View {
    let issue: CompileIssue

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            symbol
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(issue.message)
                        .font(.callout)
                        .textSelection(.enabled)
                    Spacer(minLength: 4)
                    if let line = issue.line {
                        Text("Zeile \(line)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                if let context = issue.contextBefore {
                    // So zeigt LaTeX die Fehlerstelle: Text bis zum Fehler, dann der Rest der Zeile.
                    Text(verbatim: context + (issue.contextAfter.map { " " + $0 } ?? ""))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var symbol: some View {
        switch issue.severity {
        case .error:
            Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
        case .badBox:
            Image(systemName: "arrow.left.and.right.square").foregroundStyle(.secondary)
        }
    }
}

/// Das vollständige LaTeX-Protokoll – für alle, die es genau wissen wollen.
struct LogView: View {
    let log: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LaTeX-Protokoll")
                    .font(.headline)
                Spacer()
                Button("Fertig") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            Divider()
            ScrollView {
                Text(log.isEmpty ? "Kein Protokoll vorhanden." : log)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .frame(minWidth: 640, idealWidth: 760, minHeight: 420, idealHeight: 560)
    }
}
