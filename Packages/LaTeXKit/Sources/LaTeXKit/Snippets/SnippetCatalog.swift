import Foundation

/// Alle Bausteine des Menüs „Einfügen“.
///
/// So liest man einen Baustein:
/// - `•` ist ein Platzhalter. Nach dem Einfügen ist der erste ausgewählt,
///   Tab springt zum nächsten.
/// - `⟦⟧` (`Snippet.selectionToken`) ist die Stelle, an die vorher markierter
///   Text wandert. Ist nichts markiert, wird daraus ein Platzhalter.
/// - Zeilen sind relativ eingerückt (zwei Leerzeichen pro Ebene); beim Einfügen
///   kommt die Einrückung der aktuellen Zeile dazu.
public enum SnippetCatalog {
    /// Alle Bausteine in Menü-Reihenfolge.
    public static var all: [Snippet] {
        catalog
    }

    /// Bausteine einer Gruppe in Menü-Reihenfolge.
    public static func snippets(in category: SnippetCategory) -> [Snippet] {
        all.filter { $0.category == category }
    }

    /// Baustein mit dieser ID.
    public static func snippet(withID id: String) -> Snippet? {
        all.first { $0.id == id }
    }

    /// Wird nur einmal zusammengesetzt; die Reihenfolge entspricht dem Menü.
    private static let catalog: [Snippet] =
        headings + text + lists + formulas + formulaBlocks + theorems + figures + tables + document

    // MARK: - Überschriften

    private static let headings: [Snippet] = [
        Snippet(
            id: "heading.title",
            title: "Titel",
            category: .headings,
            body: #"""
                \title{•}
                \author{•}
                \date{\today}
                \maketitle
                """#,
            placement: .block,
            keywords: ["titel", "titelseite", "autor", "datum", "title", "author", "date", "maketitle"],
            symbol: "textformat",
            help: #"Titel, Autor und Datum des Dokuments. \maketitle setzt daraus den Titelkopf, \today wird beim Kompilieren durch das heutige Datum ersetzt. Gehört direkt hinter \begin{document}."#
        ),
        Snippet(
            id: "heading.section",
            title: "Abschnitt",
            category: .headings,
            body: #"\section{⟦⟧}"#,
            placement: .block,
            keywords: ["abschnitt", "überschrift", "kapitel", "gliederung", "section", "heading", "chapter"],
            symbol: "textformat.size",
            help: "Überschrift der ersten Ebene mit Nummer (1, 2, 3 …). Sie erscheint auch im Inhaltsverzeichnis."
        ),
        Snippet(
            id: "heading.subsection",
            title: "Unterabschnitt",
            category: .headings,
            body: #"\subsection{⟦⟧}"#,
            placement: .block,
            keywords: ["unterabschnitt", "überschrift", "gliederung", "subsection", "heading"],
            symbol: "textformat.size.smaller",
            help: "Überschrift der zweiten Ebene (1.1, 1.2 …)."
        ),
        Snippet(
            id: "heading.subsubsection",
            title: "Unterunterabschnitt",
            category: .headings,
            body: #"\subsubsection{⟦⟧}"#,
            placement: .block,
            keywords: ["unterunterabschnitt", "überschrift", "gliederung", "subsubsection", "heading"],
            help: "Überschrift der dritten Ebene (1.1.1 …). Noch tiefer sollte man selten gliedern."
        ),
        Snippet(
            id: "heading.sectionUnnumbered",
            title: "Abschnitt ohne Nummer",
            category: .headings,
            body: #"\section*{⟦⟧}"#,
            placement: .block,
            keywords: ["abschnitt ohne nummer", "unnummeriert", "stern", "überschrift", "section*", "unnumbered", "heading"],
            help: "Überschrift ohne Nummer. Der Stern * schaltet die Nummerierung ab; die Überschrift erscheint dann auch nicht im Inhaltsverzeichnis."
        ),
        Snippet(
            id: "heading.tableOfContents",
            title: "Inhaltsverzeichnis",
            category: .headings,
            body: #"\tableofcontents"#,
            placement: .block,
            keywords: ["inhaltsverzeichnis", "inhalt", "verzeichnis", "table of contents", "toc", "contents"],
            symbol: "list.bullet.rectangle",
            help: "Erstellt das Inhaltsverzeichnis aus allen nummerierten Überschriften. Es ist erst nach dem zweiten Kompilieren vollständig."
        ),
        Snippet(
            id: "heading.appendix",
            title: "Anhang",
            category: .headings,
            body: #"\appendix"#,
            placement: .block,
            keywords: ["anhang", "anlage", "appendix", "attachment"],
            symbol: "paperclip",
            help: "Ab hier werden Abschnitte mit A, B, C … statt mit Zahlen nummeriert."
        )
    ]

    // MARK: - Text

    private static let text: [Snippet] = [
        Snippet(
            id: "text.footnote",
            title: "Fussnote",
            category: .text,
            body: #"\footnote{⟦⟧}"#,
            placement: .inline,
            keywords: ["fussnote", "anmerkung", "fussnoten", "footnote", "note"],
            symbol: "note.text",
            help: "Kleine Anmerkung unten auf der Seite. Direkt hinter das Wort oder Satzzeichen setzen, ohne Leerzeichen davor."
        ),
        Snippet(
            id: "text.quote",
            title: "Zitat",
            category: .text,
            body: #"""
                \begin{quote}
                  ⟦⟧
                \end{quote}
                """#,
            placement: .block,
            keywords: ["zitat", "eingerückt", "zitieren", "quote", "quotation"],
            symbol: "text.quote",
            help: "Eingerückter Absatz für längere wörtliche Zitate."
        ),
        Snippet(
            id: "text.label",
            title: "Querverweis setzen",
            category: .text,
            body: #"\label{•}"#,
            placement: .inline,
            keywords: ["querverweis", "marke", "anker", "name", "label", "anchor", "reference"],
            symbol: "tag",
            help: #"Gibt einer Stelle einen Namen, z. B. direkt hinter \section{…}, in einer Formel oder einer Abbildung. Mit \ref{Name} verweist du später darauf."#
        ),
        Snippet(
            id: "text.ref",
            title: "Verweis",
            category: .text,
            body: #"\ref{•}"#,
            placement: .inline,
            keywords: ["verweis", "querverweis", "referenz", "siehe", "ref", "reference", "cross-reference"],
            symbol: "arrow.right.circle",
            help: #"Setzt die Nummer einer Stelle ein, die mit \label{…} markiert ist. Braucht zwei Kompilierläufe; bis dahin steht dort „??“."#
        ),
        Snippet(
            id: "text.eqref",
            title: "Gleichungsverweis",
            category: .text,
            body: #"\eqref{•}"#,
            placement: .inline,
            keywords: ["gleichungsverweis", "formelverweis", "verweis", "gleichung", "eqref", "equation reference"],
            requirements: [.amsmath],
            help: #"Wie „Verweis“, aber für Formeln: Die Nummer steht in Klammern, z. B. (3). Die Formel braucht dafür ein \label{…}."#
        ),
        Snippet(
            id: "text.link",
            title: "Link",
            category: .text,
            body: #"\href{•}{⟦⟧}"#,
            placement: .inline,
            keywords: ["link", "internetadresse", "webseite", "url", "hyperlink", "href", "web"],
            symbol: "link",
            requirements: [.hyperref],
            help: "Anklickbarer Link im PDF. Zuerst die Adresse (z. B. https://www.example.org), dann der Text, der angezeigt wird."
        ),
        Snippet(
            id: "text.lineBreak",
            title: "Zeilenumbruch",
            category: .text,
            body: #"\\"#,
            placement: .inline,
            keywords: ["zeilenumbruch", "neue zeile", "umbruch", "line break", "newline"],
            symbol: "return",
            help: #"Beginnt eine neue Zeile, ohne einen neuen Absatz anzufangen. Für einen neuen Absatz lässt man besser eine Leerzeile. \\ nie an den Anfang eines Absatzes setzen."#
        ),
        Snippet(
            id: "text.newPage",
            title: "Seitenumbruch",
            category: .text,
            body: #"\newpage"#,
            placement: .block,
            keywords: ["seitenumbruch", "neue seite", "seitenwechsel", "page break", "newpage", "new page"],
            symbol: "doc.on.doc",
            help: "Der folgende Text beginnt auf einer neuen Seite."
        ),
        Snippet(
            id: "text.verticalSpace",
            title: "Vertikaler Abstand",
            category: .text,
            body: #"\vspace{•}"#,
            placement: .block,
            keywords: ["abstand", "vertikal", "leerraum", "platz", "vspace", "vertical space", "spacing", "gap"],
            symbol: "arrow.up.and.down",
            help: "Fügt senkrechten Leerraum ein. Gib eine Länge mit Einheit an, z. B. 1cm, 5mm oder 2em."
        ),
        Snippet(
            id: "text.codeBlock",
            title: "Code-Block",
            category: .text,
            body: #"""
                \begin{verbatim}
                ⟦⟧
                \end{verbatim}
                """#,
            placement: .block,
            keywords: ["code", "quelltext", "programm", "wörtlich", "verbatim", "source code", "listing"],
            symbol: "curlybraces",
            help: "Text erscheint genau so, wie er dasteht, in Schreibmaschinenschrift – praktisch für Programmcode. LaTeX-Befehle werden darin nicht ausgeführt."
        )
    ]

    // MARK: - Listen

    private static let lists: [Snippet] = [
        Snippet(
            id: "list.itemize",
            title: "Aufzählung",
            category: .lists,
            body: #"""
                \begin{itemize}
                  \item ⟦⟧
                  \item •
                \end{itemize}
                """#,
            placement: .block,
            keywords: ["aufzählung", "liste", "stichpunkte", "punkte", "itemize", "bullet", "bullet points", "list"],
            symbol: "list.bullet",
            help: #"Liste mit Punkten. Jeder Eintrag beginnt mit \item. Markierte Zeilen werden zu einzelnen Punkten."#
        ),
        Snippet(
            id: "list.enumerate",
            title: "Nummerierte Liste",
            category: .lists,
            body: #"""
                \begin{enumerate}
                  \item ⟦⟧
                  \item •
                \end{enumerate}
                """#,
            placement: .block,
            keywords: ["nummerierte liste", "nummerierung", "liste", "aufzählung", "enumerate", "numbered list", "list"],
            symbol: "list.number",
            help: #"Liste mit 1., 2., 3. … Jeder Eintrag beginnt mit \item. Markierte Zeilen werden zu einzelnen Punkten."#
        ),
        Snippet(
            id: "list.description",
            title: "Beschreibungsliste",
            category: .lists,
            body: #"""
                \begin{description}
                  \item[•] •
                  \item[•] •
                \end{description}
                """#,
            placement: .block,
            keywords: ["beschreibungsliste", "begriffe", "glossar", "erklärung", "description", "definition list", "glossary"],
            symbol: "list.dash",
            help: #"Liste mit fett gedruckten Begriffen: In die eckigen Klammern kommt der Begriff, dahinter die Erklärung."#
        )
    ]

    // MARK: - Formel-Bausteine (im Fliesstext automatisch in $…$)

    private static let formulas: [Snippet] = [
        Snippet(
            id: "formula.fraction",
            title: "Bruch",
            category: .formulas,
            body: #"\frac{⟦⟧}{•}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["bruch", "geteilt", "zähler", "nenner", "frac", "fraction", "divide"],
            symbol: "divide",
            help: "Bruch: in die erste Klammer der Zähler (oben), in die zweite der Nenner (unten)."
        ),
        Snippet(
            id: "formula.squareRoot",
            title: "Quadratwurzel",
            category: .formulas,
            body: #"\sqrt{⟦⟧}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["quadratwurzel", "wurzel", "sqrt", "square root", "root"],
            symbol: "x.squareroot",
            help: "Quadratwurzel aus dem Ausdruck in den Klammern."
        ),
        Snippet(
            id: "formula.nthRoot",
            title: "n-te Wurzel",
            category: .formulas,
            body: #"\sqrt[•]{⟦⟧}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["n-te wurzel", "wurzel", "kubikwurzel", "dritte wurzel", "nth root", "cube root", "root"],
            help: "Wurzel mit beliebigem Exponenten: in die eckigen Klammern kommt n (z. B. 3 für die dritte Wurzel), in die geschweiften der Ausdruck."
        ),
        Snippet(
            id: "formula.superscript",
            title: "Hochgestellt (Potenz)",
            category: .formulas,
            body: #"^{⟦⟧}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["hochgestellt", "potenz", "hoch", "exponent", "quadrat", "superscript", "power"],
            symbol: "textformat.superscript",
            help: "Hochgestellt, z. B. x^{2} für x². Die geschweiften Klammern fassen mehrere Zeichen zusammen: x^{10}."
        ),
        Snippet(
            id: "formula.subscript",
            title: "Tiefgestellt (Index)",
            category: .formulas,
            body: #"_{⟦⟧}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["tiefgestellt", "index", "tief", "subscript"],
            symbol: "textformat.subscript",
            help: "Tiefgestellt, z. B. a_{n} oder x_{12}."
        ),
        Snippet(
            id: "formula.sum",
            title: "Summe",
            category: .formulas,
            body: #"\sum_{•}^{•}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["summe", "summenzeichen", "sigma", "sum", "series"],
            symbol: "sum",
            help: #"Summenzeichen: unten der Start (z. B. k=1), oben das Ende (z. B. n oder \infty). Danach folgt, was summiert wird."#
        ),
        Snippet(
            id: "formula.product",
            title: "Produkt",
            category: .formulas,
            body: #"\prod_{•}^{•}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["produkt", "produktzeichen", "pi", "product"],
            symbol: "product",
            help: "Produktzeichen: unten der Start (z. B. k=1), oben das Ende. Danach folgt, was multipliziert wird."
        ),
        Snippet(
            id: "formula.integral",
            title: "Integral",
            category: .formulas,
            body: #"\int_{•}^{•} • \,\mathrm{d}•"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["integral", "integrieren", "stammfunktion", "int", "integrate"],
            help: #"Bestimmtes Integral: untere und obere Grenze, dann die Funktion und zuletzt die Variable (dx). \, macht einen kleinen Abstand vor dem d, \mathrm setzt das d aufrecht."#
        ),
        Snippet(
            id: "formula.limit",
            title: "Grenzwert",
            category: .formulas,
            body: #"\lim_{• \to •}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["grenzwert", "limes", "konvergenz", "lim", "limit"],
            help: #"Grenzwert, z. B. \lim_{n \to \infty}. \to ist der Pfeil, \infty das Zeichen für unendlich."#
        ),
        Snippet(
            id: "formula.binomial",
            title: "Binomialkoeffizient",
            category: .formulas,
            body: #"\binom{•}{•}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["binomialkoeffizient", "n über k", "binom", "binomial", "choose"],
            requirements: [.amsmath],
            help: #"„n über k“: \binom{n}{k}."#
        ),
        Snippet(
            id: "formula.absoluteValue",
            title: "Betrag",
            category: .formulas,
            body: #"\left| ⟦⟧ \right|"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["betrag", "betragsstriche", "absolut", "abs", "absolute value"],
            symbol: "absolutevalue",
            help: #"Betragsstriche. \left und \right passen die Grösse der Striche an den Inhalt an, z. B. bei Brüchen."#
        ),
        Snippet(
            id: "formula.norm",
            title: "Norm",
            category: .formulas,
            body: #"\lVert ⟦⟧ \rVert"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["norm", "länge", "doppelstrich", "betrag eines vektors", "length", "magnitude"],
            requirements: [.amsmath],
            help: #"Norm (Länge) eines Vektors mit Doppelstrichen. Für hohe Inhalte: \left\lVert … \right\rVert."#
        ),
        Snippet(
            id: "formula.parentheses",
            title: "Runde Klammern",
            category: .formulas,
            body: #"\left( ⟦⟧ \right)"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["runde klammern", "klammer", "klammern", "parentheses", "brackets"],
            help: #"Klammern, die mit dem Inhalt mitwachsen – z. B. um einen Bruch. \left und \right gehören immer zusammen."#
        ),
        Snippet(
            id: "formula.vector",
            title: "Vektor",
            category: .formulas,
            body: #"\vec{⟦⟧}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["vektor", "pfeil", "vec", "vector", "arrow"],
            symbol: "arrow.right",
            help: #"Pfeil über einem Buchstaben, z. B. \vec{v}."#
        ),
        Snippet(
            id: "formula.derivative",
            title: "Ableitung",
            category: .formulas,
            body: #"\frac{\mathrm{d}•}{\mathrm{d}•}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["ableitung", "differential", "differenzieren", "derivative", "d/dx"],
            help: "Ableitung in Leibniz-Schreibweise, z. B. df/dx: oben die Funktion, unten die Variable."
        ),
        Snippet(
            id: "formula.partialDerivative",
            title: "Partielle Ableitung",
            category: .formulas,
            body: #"\frac{\partial •}{\partial •}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["partielle ableitung", "partiell", "partial", "partial derivative"],
            help: "Partielle Ableitung (rundes d): oben die Funktion, unten die Variable, nach der abgeleitet wird."
        ),
        Snippet(
            id: "formula.set",
            title: "Menge",
            category: .formulas,
            body: #"\{ • \mid • \}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["menge", "mengenklammer", "mengenschreibweise", "set", "set builder"],
            help: #"Menge { x | Bedingung }. Geschweifte Klammern muss man in Formeln als \{ und \} schreiben, \mid ist der senkrechte Strich."#
        ),
        Snippet(
            id: "formula.text",
            title: "Text in Formel",
            category: .formulas,
            body: #"\text{⟦⟧}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["text in formel", "text", "wort", "normaler text", "text in math"],
            symbol: "textformat",
            requirements: [.amsmath],
            help: #"Normaler Text innerhalb einer Formel, z. B. \text{für alle}. Ohne \text würden Wörter kursiv und ohne Leerzeichen gesetzt."#
        ),
        Snippet(
            id: "formula.realNumbers",
            title: "Reelle Zahlen",
            category: .formulas,
            body: #"\mathbb{R}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["reelle zahlen", "reell", "doppelstrich", "mathbb", "real numbers", "reals"],
            symbol: "r.square",
            requirements: [.amssymb],
            help: "Das R mit Doppelstrich für die Menge der reellen Zahlen."
        ),
        Snippet(
            id: "formula.naturalNumbers",
            title: "Natürliche Zahlen",
            category: .formulas,
            body: #"\mathbb{N}"#,
            placement: .inline,
            requiresMath: true,
            keywords: ["natürliche zahlen", "natürlich", "doppelstrich", "mathbb", "natural numbers", "naturals"],
            symbol: "n.square",
            requirements: [.amssymb],
            help: "Das N mit Doppelstrich für die Menge der natürlichen Zahlen."
        )
    ]

    // MARK: - Abgesetzte Formeln

    private static let formulaBlocks: [Snippet] = [
        Snippet(
            id: "display.unnumbered",
            title: "Abgesetzte Formel",
            category: .formulaBlocks,
            body: #"""
                \[
                  ⟦⟧
                \]
                """#,
            placement: .block,
            keywords: ["abgesetzte formel", "formel", "gleichung", "zentriert", "display math", "equation", "displaymath"],
            symbol: "function",
            help: "Formel auf einer eigenen Zeile, zentriert und ohne Nummer."
        ),
        Snippet(
            id: "display.equation",
            title: "Nummerierte Formel",
            category: .formulaBlocks,
            body: #"""
                \begin{equation}
                  ⟦⟧
                \end{equation}
                """#,
            placement: .block,
            keywords: ["nummerierte formel", "formel", "gleichung", "nummer", "equation", "numbered equation"],
            symbol: "number",
            help: #"Formel auf einer eigenen Zeile mit Nummer rechts. Mit \label{…} in der Formel kannst du per „Gleichungsverweis“ darauf verweisen."#
        ),
        Snippet(
            id: "display.alignUnnumbered",
            title: "Mehrzeilig ausgerichtet",
            category: .formulaBlocks,
            body: #"""
                \begin{align*}
                  ⟦⟧ &= • \\
                  &= •
                \end{align*}
                """#,
            placement: .block,
            keywords: ["mehrzeilig ausgerichtet", "ausgerichtet", "umformung", "rechnung", "mehrzeilig", "align", "aligned", "multiline"],
            symbol: "equal",
            requirements: [.amsmath],
            help: #"Rechnung über mehrere Zeilen ohne Nummern. Das & steht vor dem Gleichheitszeichen – diese Stellen werden untereinander ausgerichtet. \\ beginnt eine neue Zeile."#
        ),
        Snippet(
            id: "display.align",
            title: "Nummeriert ausgerichtet",
            category: .formulaBlocks,
            body: #"""
                \begin{align}
                  ⟦⟧ &= • \\
                  &= •
                \end{align}
                """#,
            placement: .block,
            keywords: ["nummeriert ausgerichtet", "ausgerichtet", "umformung", "mehrzeilig", "nummer", "align", "numbered"],
            requirements: [.amsmath],
            help: #"Wie „Mehrzeilig ausgerichtet“, aber jede Zeile bekommt eine Nummer. \notag am Zeilenende lässt die Nummer einer Zeile weg."#
        ),
        Snippet(
            id: "display.cases",
            title: "Fallunterscheidung",
            category: .formulaBlocks,
            body: #"""
                \[
                  ⟦⟧ = \begin{cases}
                    • & \text{falls } • \\
                    • & \text{sonst}
                  \end{cases}
                \]
                """#,
            placement: .block,
            keywords: ["fallunterscheidung", "fälle", "stückweise", "abschnittsweise", "cases", "piecewise"],
            symbol: "arrow.triangle.branch",
            requirements: [.amsmath],
            help: #"Abschnittsweise definierte Funktion mit geschweifter Klammer, z. B. f(x) = … falls x ≥ 0. Links vom & steht der Wert, rechts die Bedingung; \\ beginnt den nächsten Fall."#
        ),
        Snippet(
            id: "display.matrix2",
            title: "Matrix 2×2",
            category: .formulaBlocks,
            body: #"""
                \[
                  \begin{pmatrix}
                    • & • \\
                    • & •
                  \end{pmatrix}
                \]
                """#,
            placement: .block,
            keywords: ["matrix", "2x2", "2×2", "pmatrix", "lineare algebra", "linear algebra"],
            symbol: "square.grid.2x2",
            requirements: [.amsmath],
            help: #"Matrix mit runden Klammern. & trennt die Spalten, \\ beendet eine Zeile. Für eckige Klammern pmatrix durch bmatrix ersetzen."#
        ),
        Snippet(
            id: "display.matrix3",
            title: "Matrix 3×3",
            category: .formulaBlocks,
            body: #"""
                \[
                  \begin{pmatrix}
                    • & • & • \\
                    • & • & • \\
                    • & • & •
                  \end{pmatrix}
                \]
                """#,
            placement: .block,
            keywords: ["matrix", "3x3", "3×3", "pmatrix", "lineare algebra", "linear algebra"],
            symbol: "square.grid.3x3",
            requirements: [.amsmath],
            help: #"Matrix mit runden Klammern. & trennt die Spalten, \\ beendet eine Zeile. Für eckige Klammern pmatrix durch bmatrix ersetzen."#
        ),
        Snippet(
            id: "display.system",
            title: "Gleichungssystem",
            category: .formulaBlocks,
            body: #"""
                \[
                  \begin{cases}
                    • = • \\
                    • = •
                  \end{cases}
                \]
                """#,
            placement: .block,
            keywords: ["gleichungssystem", "lineares gleichungssystem", "lgs", "gleichungen", "system of equations", "linear system", "cases"],
            symbol: "equal.square",
            requirements: [.amsmath],
            help: #"Mehrere Gleichungen mit einer geschweiften Klammer links (cases-Umgebung). Jede Gleichung steht auf einer eigenen Zeile, \\ trennt sie. Sollen die Gleichheitszeichen genau untereinander stehen, nimm „Mehrzeilig ausgerichtet“."#
        )
    ]

    // MARK: - Definition, Satz, Beweis

    private static let theorems: [Snippet] = [
        theorem(
            "definition",
            title: "Definition",
            keywords: ["definition", "def", "begriff", "festlegung"],
            symbol: "text.book.closed",
            help: #"Nummerierter Absatz für eine Definition. Einen Namen kannst du in eckigen Klammern ergänzen: \begin{definition}[Stetigkeit]."#
        ),
        theorem(
            "satz",
            title: "Satz",
            keywords: ["satz", "theorem", "aussage", "proposition"],
            symbol: "checkmark.seal",
            help: "Nummerierter Satz in kursiver Schrift. Der Beweis folgt danach in einer eigenen Umgebung „Beweis“."
        ),
        theorem(
            "lemma",
            title: "Lemma",
            keywords: ["lemma", "hilfssatz", "hilfsaussage", "auxiliary theorem"],
            help: "Hilfssatz, der für einen späteren Satz gebraucht wird. Wird zusammen mit den Sätzen nummeriert."
        ),
        theorem(
            "korollar",
            title: "Korollar",
            keywords: ["korollar", "folgerung", "folgesatz", "corollary"],
            help: "Folgerung, die sich direkt aus einem Satz ergibt. Wird zusammen mit den Sätzen nummeriert."
        ),
        theorem(
            "beispiel",
            title: "Beispiel",
            keywords: ["beispiel", "bsp", "example"],
            symbol: "lightbulb",
            help: "Nummeriertes Beispiel in normaler Schrift."
        ),
        theorem(
            "bemerkung",
            title: "Bemerkung",
            keywords: ["bemerkung", "hinweis", "anmerkung", "remark", "note"],
            symbol: "text.bubble",
            help: "Bemerkung ohne Nummer in normaler Schrift."
        ),
        Snippet(
            id: "theorem.proof",
            title: "Beweis",
            category: .theorems,
            body: #"""
                \begin{proof}
                  ⟦⟧
                \end{proof}
                """#,
            placement: .block,
            keywords: ["beweis", "bewiesen", "qed", "proof"],
            symbol: "checkmark.square",
            requirements: [PackageRequirement("amsthm")],
            help: "Beweis: beginnt mit „Beweis.“ und endet automatisch mit einem Kästchen □."
        )
    ]

    /// Satz-artige Umgebung, wie sie `PackageRequirement.theorems` in der Präambel festlegt.
    private static func theorem(
        _ environment: String,
        title: String,
        keywords: [String],
        symbol: String? = nil,
        help: String
    ) -> Snippet {
        Snippet(
            id: "theorem.\(environment)",
            title: title,
            category: .theorems,
            body: "\\begin{\(environment)}\n  \(Snippet.selectionToken)\n\\end{\(environment)}",
            placement: .block,
            keywords: keywords,
            symbol: symbol,
            requirements: [.theorems],
            help: help
        )
    }

    // MARK: - Bilder

    private static let figures: [Snippet] = [
        Snippet(
            id: "figure.figure",
            title: "Bild mit Beschriftung",
            category: .figures,
            body: #"""
                \begin{figure}[htbp]
                  \centering
                  \includegraphics[width=0.8\textwidth]{•}
                  \caption{•}
                  \label{fig:•}
                \end{figure}
                """#,
            placement: .block,
            keywords: ["bild mit beschriftung", "bild", "abbildung", "grafik", "foto", "figure", "image", "picture", "graphic"],
            symbol: "photo",
            requirements: [.graphicx],
            help: "Bild mit Unterschrift und Nummer. Zuerst der Dateiname des Bildes (z. B. skizze.png, im selben Ordner wie das Dokument), dann die Beschriftung und ein Name für Verweise. [htbp] lässt LaTeX einen guten Platz wählen: hier, oben, unten oder auf einer eigenen Seite."
        ),
        Snippet(
            id: "figure.includegraphics",
            title: "Bild ohne Umgebung",
            category: .figures,
            body: #"\includegraphics[width=0.5\textwidth]{•}"#,
            placement: .block,
            keywords: ["bild ohne umgebung", "bild", "grafik", "foto", "includegraphics", "image", "picture"],
            symbol: "photo.on.rectangle",
            requirements: [.graphicx],
            help: #"Bild genau an dieser Stelle, ohne Nummer und Beschriftung. width=0.5\textwidth heisst: halb so breit wie der Text."#
        )
    ]

    // MARK: - Tabellen

    private static let tables: [Snippet] = [
        Snippet(
            id: "table.2x2",
            title: "Tabelle 2×2",
            category: .tables,
            body: #"""
                \begin{table}[htbp]
                  \centering
                  \begin{tabular}{|c|c|}
                    \hline
                    • & • \\
                    \hline
                    • & • \\
                    \hline
                  \end{tabular}
                  \caption{•}
                \end{table}
                """#,
            placement: .block,
            keywords: ["tabelle", "2x2", "2×2", "table", "tabular", "grid"],
            symbol: "tablecells",
            help: #"Tabelle mit Rahmen. & trennt die Spalten, \\ beendet eine Zeile, \hline zieht eine waagrechte Linie. Das c in {|c|c|} heisst zentriert (l = links, r = rechts)."#
        ),
        Snippet(
            id: "table.3x3",
            title: "Tabelle 3×3",
            category: .tables,
            body: #"""
                \begin{table}[htbp]
                  \centering
                  \begin{tabular}{|c|c|c|}
                    \hline
                    • & • & • \\
                    \hline
                    • & • & • \\
                    \hline
                    • & • & • \\
                    \hline
                  \end{tabular}
                  \caption{•}
                \end{table}
                """#,
            placement: .block,
            keywords: ["tabelle", "3x3", "3×3", "table", "tabular", "grid"],
            symbol: "tablecells",
            help: #"Tabelle mit Rahmen. & trennt die Spalten, \\ beendet eine Zeile, \hline zieht eine waagrechte Linie. Das c in {|c|c|c|} heisst zentriert (l = links, r = rechts)."#
        )
    ]

    // MARK: - Dokument

    private static let document: [Snippet] = [
        Snippet(
            id: "document.exercise",
            title: "Aufgabe",
            category: .document,
            body: #"""
                \section*{Aufgabe •}
                ⟦⟧
                """#,
            placement: .block,
            keywords: ["aufgabe", "übung", "übungsblatt", "hausaufgabe", "exercise", "problem", "task", "homework"],
            symbol: "pencil",
            help: "Überschrift „Aufgabe …“ für Übungsblätter. Die Nummer trägst du selbst ein, darunter folgt deine Bearbeitung."
        ),
        Snippet(
            id: "document.solution",
            title: "Lösung",
            category: .document,
            body: #"""
                \paragraph{Lösung}
                ⟦⟧
                """#,
            placement: .block,
            keywords: ["lösung", "antwort", "lösungsweg", "solution", "answer"],
            symbol: "checkmark.circle",
            help: "Fett gedrucktes „Lösung“, direkt gefolgt vom Text deiner Lösung."
        ),
        Snippet(
            id: "document.comment",
            title: "Kommentar-Notiz",
            category: .document,
            body: "% •",
            placement: .block,
            keywords: ["kommentar", "notiz", "todo", "merker", "comment", "note"],
            symbol: "bubble.left",
            help: "Notiz nur für dich: Alles nach % bis zum Zeilenende erscheint nicht im PDF."
        )
    ]
}
