import Foundation
import LaTeXKit

/// Alle Einstellungen der App an einem Ort.
///
/// Gespeichert wird in `UserDefaults` (wie bei jeder Mac-App). SwiftUI-Ansichten
/// lesen die Werte über `@AppStorage(AppSettings.Keys.…)`, die Logik über die
/// statischen Eigenschaften hier.
enum AppSettings {
    enum Keys {
        static let autoCompile = "autoCompile"
        static let autoCompileDelay = "autoCompileDelay"
        static let editorFontSize = "editorFontSize"
        static let showLineNumbers = "showLineNumbers"
        static let autoPairing = "autoPairing"
        static let highlightCurrentLine = "highlightCurrentLine"
        static let preferredEngine = "preferredEngine"
        static let showPreview = "showPreview"
    }

    enum Defaults {
        static let autoCompile = true
        static let autoCompileDelay = 1.5
        static let editorFontSize = 14.0
        static let showLineNumbers = true
        static let autoPairing = true
        static let highlightCurrentLine = true
        static let preferredEngine = EngineKind.tectonic.rawValue
        static let showPreview = true
    }

    /// Standardwerte registrieren, damit `UserDefaults` sie kennt, bevor der Nutzer etwas ändert.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.autoCompile: Defaults.autoCompile,
            Keys.autoCompileDelay: Defaults.autoCompileDelay,
            Keys.editorFontSize: Defaults.editorFontSize,
            Keys.showLineNumbers: Defaults.showLineNumbers,
            Keys.autoPairing: Defaults.autoPairing,
            Keys.highlightCurrentLine: Defaults.highlightCurrentLine,
            Keys.preferredEngine: Defaults.preferredEngine,
            Keys.showPreview: Defaults.showPreview
        ])
    }

    static var autoCompile: Bool { UserDefaults.standard.bool(forKey: Keys.autoCompile) }

    static var autoCompileDelay: Double {
        let value = UserDefaults.standard.double(forKey: Keys.autoCompileDelay)
        return min(max(value, 0.3), 10)
    }

    static var preferredEngine: EngineKind {
        get { EngineKind(rawValue: UserDefaults.standard.string(forKey: Keys.preferredEngine) ?? "") ?? .tectonic }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.preferredEngine) }
    }

    /// Erlaubter Bereich der Editor-Schriftgrösse.
    static let fontSizeRange: ClosedRange<Double> = 10...28
}
