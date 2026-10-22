import Foundation

/// Ein LaTeX-Paket (plus evtl. nötige Präambel-Zeilen), das ein Baustein oder
/// eine Formatierung voraussetzt – z. B. `xcolor` für farbigen Text.
///
/// Fehlt das Paket, ergänzt der `PreambleEditor` es automatisch vor
/// `\begin{document}`. Einsteiger müssen sich so nicht um Pakete kümmern.
public struct PackageRequirement: Hashable, Sendable {
    /// Paketname, z. B. `xcolor`.
    public var name: String
    /// Optionen in eckigen Klammern, z. B. `table` → `\usepackage[table]{xcolor}`.
    public var options: String?
    /// Zusätzliche Zeilen, die nach dem Paket in der Präambel stehen müssen
    /// (z. B. `\newtheorem{satz}{Satz}`). Jede Zeile wird nur ergänzt, wenn sie fehlt.
    public var preambleLines: [String]

    public init(_ name: String, options: String? = nil, preambleLines: [String] = []) {
        self.name = name
        self.options = options
        self.preambleLines = preambleLines
    }

    /// Die `\usepackage`-Zeile für dieses Paket.
    public var usepackageLine: String {
        if let options, !options.isEmpty { return "\\usepackage[\(options)]{\(name)}" }
        return "\\usepackage{\(name)}"
    }

    public static let xcolor = PackageRequirement("xcolor")
    public static let graphicx = PackageRequirement("graphicx")
    public static let amsmath = PackageRequirement("amsmath")
    public static let amssymb = PackageRequirement("amssymb")
    public static let booktabs = PackageRequirement("booktabs")
    public static let hyperref = PackageRequirement("hyperref")
    public static let listings = PackageRequirement("listings")

    /// `amsthm` mit deutschen Satz-Umgebungen (Satz, Lemma, Definition, Beispiel, Bemerkung).
    /// `proof` („Beweis“) bringt amsthm selbst mit.
    public static let theorems = PackageRequirement("amsthm", preambleLines: [
        "\\theoremstyle{plain}",
        "\\newtheorem{satz}{Satz}[section]",
        "\\newtheorem{lemma}[satz]{Lemma}",
        "\\newtheorem{korollar}[satz]{Korollar}",
        "\\theoremstyle{definition}",
        "\\newtheorem{definition}[satz]{Definition}",
        "\\newtheorem{beispiel}[satz]{Beispiel}",
        "\\theoremstyle{remark}",
        "\\newtheorem*{bemerkung}{Bemerkung}"
    ])
}
