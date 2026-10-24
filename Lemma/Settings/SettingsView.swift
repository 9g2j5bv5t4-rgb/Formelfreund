import LaTeXKit
import SwiftUI

/// Das Einstellungsfenster (⌘,).
struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Allgemein", systemImage: "gearshape") {
                GeneralSettingsView()
                    .frame(width: 540, height: 260)
            }
            Tab("Editor", systemImage: "character.cursor.ibeam") {
                EditorSettingsView()
                    .frame(width: 540, height: 400)
            }
            Tab("LaTeX", systemImage: "function") {
                EngineSettingsView(engines: EngineManager.shared)
                    .frame(width: 540, height: 460)
            }
        }
        // Gruppierte Formulare haben unter macOS keine eigene Höhe. Ohne feste
        // Grösse öffnet das Fenster zu klein und schneidet Inhalte ab. Passt
        // etwas nicht ganz hinein, lässt sich das Formular scrollen.
    }
}

private struct GeneralSettingsView: View {
    @AppStorage(AppSettings.Keys.autoCompile) private var autoCompile = AppSettings.Defaults.autoCompile
    @AppStorage(AppSettings.Keys.autoCompileDelay) private var delay = AppSettings.Defaults.autoCompileDelay

    var body: some View {
        Form {
            Section {
                Toggle("Automatisch kompilieren", isOn: $autoCompile)
                LabeledContent("Nach einer Tipp-Pause von") {
                    HStack {
                        Slider(value: $delay, in: 0.5...5, step: 0.5)
                            .frame(width: 180)
                        Text("\(delay.formatted(.number.precision(.fractionLength(1)))) s")
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                .disabled(!autoCompile)
            } footer: {
                Text("Die Vorschau aktualisiert sich, sobald du kurz mit Tippen aufhörst. Manuell kompilierst du jederzeit mit ⌘↩.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct EditorSettingsView: View {
    @AppStorage(AppSettings.Keys.editorFontSize) private var fontSize = AppSettings.Defaults.editorFontSize
    @AppStorage(AppSettings.Keys.showLineNumbers) private var showLineNumbers = AppSettings.Defaults.showLineNumbers
    @AppStorage(AppSettings.Keys.autoPairing) private var autoPairing = AppSettings.Defaults.autoPairing
    @AppStorage(AppSettings.Keys.highlightCurrentLine) private var highlightCurrentLine = AppSettings.Defaults.highlightCurrentLine
    @AppStorage(AppSettings.Keys.showFormatBar) private var showFormatBar = AppSettings.Defaults.showFormatBar

    var body: some View {
        Form {
            Section {
                LabeledContent("Schriftgrösse") {
                    Stepper(value: $fontSize, in: AppSettings.fontSizeRange, step: 1) {
                        Text("\(Int(fontSize)) pt")
                            .monospacedDigit()
                    }
                }
                Toggle("Zeilennummern anzeigen", isOn: $showLineNumbers)
                Toggle("Aktuelle Zeile hervorheben", isOn: $highlightCurrentLine)
                Toggle("Format-Leiste über dem Editor", isOn: $showFormatBar)
            }
            Section {
                Toggle("Klammern und $ automatisch schliessen", isOn: $autoPairing)
            } footer: {
                Text("Ergänzt beim Tippen von { das passende }, bei $ das schliessende $ und nach \\begin{…} das zugehörige \\end{…}. Rückt neue Zeilen ein und setzt Aufzählungen mit \\item fort.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct EngineSettingsView: View {
    @Bindable var engines: EngineManager

    var body: some View {
        Form {
            Section {
                Picker("Engine", selection: $engines.preferredEngine) {
                    Text("Tectonic (empfohlen)").tag(EngineKind.tectonic)
                    Text("latexmk aus MacTeX").tag(EngineKind.latexmk)
                }
                .pickerStyle(.radioGroup)
            } footer: {
                if engines.preferredEngine == .latexmk && engines.latexmkURL == nil {
                    Text("latexmk wurde nicht gefunden. Installiere MacTeX (tug.org/mactex) oder verwende Tectonic. Bis dahin kompiliert Lemma mit Tectonic.")
                        .foregroundStyle(.orange)
                } else {
                    Text("Tectonic lädt fehlende LaTeX-Pakete automatisch nach. latexmk verwendet eine vorhandene MacTeX-Installation mit pdfLaTeX.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Tectonic") {
                LabeledContent("Status") {
                    tectonicStatus
                }
                if case .notInstalled = engines.tectonicState {
                    Button("Jetzt herunterladen") {
                        Task { try? await engines.ensureTectonic() }
                    }
                }
                if case .failed = engines.tectonicState {
                    Button("Erneut versuchen") {
                        Task { try? await engines.ensureTectonic() }
                    }
                }
            }

            Section("MacTeX") {
                LabeledContent("latexmk") {
                    if let url = engines.latexmkURL {
                        Text(verbatim: url.path)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Nicht gefunden")
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Erneut suchen") { engines.refresh() }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var tectonicStatus: some View {
        switch engines.tectonicState {
        case .notInstalled:
            Text("Wird beim ersten Kompilieren geladen")
                .foregroundStyle(.secondary)
        case .downloading(let progress):
            ProgressView(value: progress)
                .frame(width: 160)
        case .installing:
            ProgressView()
                .controlSize(.small)
        case .ready(let url):
            Label {
                Text(verbatim: url.path)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .failed(let message):
            Text(message)
                .foregroundStyle(.red)
        }
    }
}
