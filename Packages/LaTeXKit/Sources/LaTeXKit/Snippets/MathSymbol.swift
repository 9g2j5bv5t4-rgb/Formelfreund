import Foundation

/// Ein mathematisches Zeichen für die Symbol-Kacheln, z. B. α → `\alpha`.
///
/// Angezeigt wird das Unicode-Zeichen (`glyph`), eingefügt der LaTeX-Befehl.
public struct MathSymbol: Identifiable, Hashable, Sendable {
    /// Das Zeichen, wie es auf der Kachel erscheint.
    public let glyph: String
    /// LaTeX-Befehl, z. B. `\alpha`.
    public let command: String
    /// Deutscher Name für den Hilfetext, z. B. „kleines Alpha“.
    public let name: String
    /// Benötigte Pakete (z. B. `amssymb` für `\mathbb`).
    public let requirements: [PackageRequirement]

    public var id: String { command }

    public init(_ glyph: String, _ command: String, _ name: String, requirements: [PackageRequirement] = []) {
        self.glyph = glyph
        self.command = command
        self.name = name
        self.requirements = requirements
    }

    /// Baustein zum Einfügen. Ausserhalb einer Formel wird er automatisch in `$…$` gesetzt.
    ///
    /// - Parameter inMath: Steht der Cursor schon in einer Formel? Dann folgt einem
    ///   Befehlsnamen wie `\alpha` ein Leerzeichen, damit ein danach getippter
    ///   Buchstabe nicht mit ihm verschmilzt (`\alphax` wäre ein unbekannter Befehl).
    ///   In einer Formel verschluckt LaTeX dieses Leerzeichen ohnehin.
    public func snippet(inMath: Bool) -> Snippet {
        let endsWithLetter = command.last.map { $0.isLetter && $0.isASCII } ?? false
        return Snippet(
            id: "symbol.\(command)",
            title: name,
            category: .formulas,
            body: inMath && endsWithLetter ? command + " " : command,
            placement: .inline,
            requiresMath: true,
            keywords: [name, String(command.dropFirst())],
            requirements: requirements,
            help: "\(name) – LaTeX: \(command)"
        )
    }
}

/// Gruppen der Symbol-Kacheln (Register „Formeln“).
public enum MathSymbolGroup: String, CaseIterable, Sendable, Identifiable {
    case greekLowercase
    case greekUppercase
    case relations
    case operators
    case arrows
    case logicAndSets
    case numberSets

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .greekLowercase: return "Griechisch klein"
        case .greekUppercase: return "Griechisch gross"
        case .relations: return "Vergleiche"
        case .operators: return "Operatoren"
        case .arrows: return "Pfeile"
        case .logicAndSets: return "Logik und Mengen"
        case .numberSets: return "Zahlbereiche"
        }
    }

    /// Zeichen, das die Gruppe auf ihrem Knopf vertritt.
    public var representativeGlyph: String {
        switch self {
        case .greekLowercase: return "α"
        case .greekUppercase: return "Ω"
        case .relations: return "≤"
        case .operators: return "±"
        case .arrows: return "⇒"
        case .logicAndSets: return "∀"
        case .numberSets: return "ℝ"
        }
    }

    public var symbols: [MathSymbol] {
        switch self {
        case .greekLowercase:
            return [
                MathSymbol("α", #"\alpha"#, "Alpha"),
                MathSymbol("β", #"\beta"#, "Beta"),
                MathSymbol("γ", #"\gamma"#, "Gamma"),
                MathSymbol("δ", #"\delta"#, "Delta"),
                MathSymbol("ε", #"\varepsilon"#, "Epsilon"),
                MathSymbol("ζ", #"\zeta"#, "Zeta"),
                MathSymbol("η", #"\eta"#, "Eta"),
                MathSymbol("θ", #"\theta"#, "Theta"),
                MathSymbol("ι", #"\iota"#, "Iota"),
                MathSymbol("κ", #"\kappa"#, "Kappa"),
                MathSymbol("λ", #"\lambda"#, "Lambda"),
                MathSymbol("μ", #"\mu"#, "My"),
                MathSymbol("ν", #"\nu"#, "Ny"),
                MathSymbol("ξ", #"\xi"#, "Xi"),
                MathSymbol("π", #"\pi"#, "Pi"),
                MathSymbol("ρ", #"\rho"#, "Rho"),
                MathSymbol("σ", #"\sigma"#, "Sigma"),
                MathSymbol("τ", #"\tau"#, "Tau"),
                MathSymbol("φ", #"\varphi"#, "Phi"),
                MathSymbol("χ", #"\chi"#, "Chi"),
                MathSymbol("ψ", #"\psi"#, "Psi"),
                MathSymbol("ω", #"\omega"#, "Omega")
            ]
        case .greekUppercase:
            return [
                MathSymbol("Γ", #"\Gamma"#, "grosses Gamma"),
                MathSymbol("Δ", #"\Delta"#, "grosses Delta"),
                MathSymbol("Θ", #"\Theta"#, "grosses Theta"),
                MathSymbol("Λ", #"\Lambda"#, "grosses Lambda"),
                MathSymbol("Ξ", #"\Xi"#, "grosses Xi"),
                MathSymbol("Π", #"\Pi"#, "grosses Pi"),
                MathSymbol("Σ", #"\Sigma"#, "grosses Sigma"),
                MathSymbol("Φ", #"\Phi"#, "grosses Phi"),
                MathSymbol("Ψ", #"\Psi"#, "grosses Psi"),
                MathSymbol("Ω", #"\Omega"#, "grosses Omega")
            ]
        case .relations:
            return [
                MathSymbol("≠", #"\neq"#, "ungleich"),
                MathSymbol("≈", #"\approx"#, "ungefähr gleich"),
                MathSymbol("≡", #"\equiv"#, "identisch, kongruent"),
                MathSymbol("≤", #"\leq"#, "kleiner gleich"),
                MathSymbol("≥", #"\geq"#, "grösser gleich"),
                MathSymbol("≪", #"\ll"#, "sehr viel kleiner"),
                MathSymbol("≫", #"\gg"#, "sehr viel grösser"),
                MathSymbol("∼", #"\sim"#, "ähnlich, verteilt wie"),
                MathSymbol("≅", #"\cong"#, "isomorph"),
                MathSymbol("∝", #"\propto"#, "proportional"),
                MathSymbol("∣", #"\mid"#, "teilt"),
                MathSymbol("∤", #"\nmid"#, "teilt nicht", requirements: [PackageRequirement("amssymb")])
            ]
        case .operators:
            return [
                MathSymbol("±", #"\pm"#, "plus minus"),
                MathSymbol("∓", #"\mp"#, "minus plus"),
                MathSymbol("·", #"\cdot"#, "mal (Punkt)"),
                MathSymbol("×", #"\times"#, "mal (Kreuz)"),
                MathSymbol("÷", #"\div"#, "geteilt"),
                MathSymbol("∘", #"\circ"#, "verkettet mit"),
                MathSymbol("⊕", #"\oplus"#, "direkte Summe, XOR"),
                MathSymbol("⊗", #"\otimes"#, "Tensorprodukt"),
                MathSymbol("∞", #"\infty"#, "unendlich"),
                MathSymbol("∂", #"\partial"#, "partiell"),
                MathSymbol("∇", #"\nabla"#, "Nabla"),
                MathSymbol("…", #"\ldots"#, "Punkte unten"),
                MathSymbol("⋯", #"\cdots"#, "Punkte mittig")
            ]
        case .arrows:
            return [
                MathSymbol("→", #"\to"#, "nach, gegen"),
                MathSymbol("←", #"\leftarrow"#, "Pfeil nach links"),
                MathSymbol("↔", #"\leftrightarrow"#, "Pfeil in beide Richtungen"),
                MathSymbol("⇒", #"\Rightarrow"#, "daraus folgt"),
                MathSymbol("⇐", #"\Leftarrow"#, "folgt aus"),
                MathSymbol("⇔", #"\Leftrightarrow"#, "genau dann, wenn"),
                MathSymbol("↦", #"\mapsto"#, "wird abgebildet auf"),
                MathSymbol("↑", #"\uparrow"#, "Pfeil nach oben"),
                MathSymbol("↓", #"\downarrow"#, "Pfeil nach unten")
            ]
        case .logicAndSets:
            return [
                MathSymbol("∀", #"\forall"#, "für alle"),
                MathSymbol("∃", #"\exists"#, "es existiert"),
                MathSymbol("∄", #"\nexists"#, "es existiert kein", requirements: [PackageRequirement("amssymb")]),
                MathSymbol("¬", #"\neg"#, "nicht"),
                MathSymbol("∧", #"\land"#, "und"),
                MathSymbol("∨", #"\lor"#, "oder"),
                MathSymbol("∈", #"\in"#, "Element von"),
                MathSymbol("∉", #"\notin"#, "nicht Element von"),
                MathSymbol("⊂", #"\subset"#, "echte Teilmenge"),
                MathSymbol("⊆", #"\subseteq"#, "Teilmenge"),
                MathSymbol("∪", #"\cup"#, "vereinigt"),
                MathSymbol("∩", #"\cap"#, "geschnitten"),
                MathSymbol("∖", #"\setminus"#, "ohne"),
                MathSymbol("∅", #"\emptyset"#, "leere Menge")
            ]
        case .numberSets:
            let amssymb = [PackageRequirement("amssymb")]
            return [
                MathSymbol("ℕ", #"\mathbb{N}"#, "natürliche Zahlen", requirements: amssymb),
                MathSymbol("ℤ", #"\mathbb{Z}"#, "ganze Zahlen", requirements: amssymb),
                MathSymbol("ℚ", #"\mathbb{Q}"#, "rationale Zahlen", requirements: amssymb),
                MathSymbol("ℝ", #"\mathbb{R}"#, "reelle Zahlen", requirements: amssymb),
                MathSymbol("ℂ", #"\mathbb{C}"#, "komplexe Zahlen", requirements: amssymb)
            ]
        }
    }
}
