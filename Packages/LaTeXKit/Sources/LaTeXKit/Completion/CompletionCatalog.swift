import Foundation

/// Alle Befehle, Umgebungen, Pakete und Klassen, die Lemma beim Tippen vorschlägt.
///
/// Jeder Eintrag hat eine deutsche Erklärung und deutsche Suchbegriffe: Wer
/// `\bruch` tippt, bekommt `\frac` angeboten, `\wurzel` findet `\sqrt`.
public enum CompletionCatalog {
    // MARK: - Befehle

    public static let commands: [CompletionItem] = textCommands + mathCommands + symbolCommands

    private static let textCommands: [CompletionItem] = [
        // Gliederung
        command("section", "\\section{•}", "Abschnitt (Überschrift 1)", keywords: ["abschnitt", "überschrift", "titel"], priority: 95),
        command("section*", "\\section*{•}", "Abschnitt ohne Nummer", keywords: ["abschnitt", "überschrift", "ohne nummer"], priority: 60),
        command("subsection", "\\subsection{•}", "Unterabschnitt (Überschrift 2)", keywords: ["unterabschnitt", "überschrift"], priority: 85),
        command("subsection*", "\\subsection*{•}", "Unterabschnitt ohne Nummer", keywords: ["unterabschnitt"], priority: 45),
        command("subsubsection", "\\subsubsection{•}", "Unter-Unterabschnitt (Überschrift 3)", keywords: ["überschrift"], priority: 60),
        command("paragraph", "\\paragraph{•}", "Absatzüberschrift (fett, im Text)", keywords: ["absatz", "überschrift"], priority: 30),
        command("chapter", "\\chapter{•}", "Kapitel (nur report und book)", keywords: ["kapitel"], priority: 50),
        command("part", "\\part{•}", "Teil (über Kapiteln)", keywords: ["teil"], priority: 15),
        command("title", "\\title{•}", "Titel des Dokuments", keywords: ["titel"], priority: 60),
        command("author", "\\author{•}", "Autor oder Autorin", keywords: ["autor", "name", "verfasser"], priority: 60),
        command("date", "\\date{•}", "Datum unter dem Titel", keywords: ["datum"], priority: 45),
        command("maketitle", "\\maketitle", "Titel, Autor und Datum setzen", keywords: ["titel", "titelseite"], priority: 60),
        command("tableofcontents", "\\tableofcontents", "Inhaltsverzeichnis", keywords: ["inhaltsverzeichnis", "inhalt"], priority: 60),
        command("listoffigures", "\\listoffigures", "Abbildungsverzeichnis", keywords: ["abbildungsverzeichnis"], priority: 25),
        command("listoftables", "\\listoftables", "Tabellenverzeichnis", keywords: ["tabellenverzeichnis"], priority: 20),
        command("appendix", "\\appendix", "Ab hier Anhang (A, B, …)", keywords: ["anhang"], priority: 30),
        command("today", "\\today", "Heutiges Datum", keywords: ["heute", "datum"], priority: 35),

        // Schrift
        command("textbf", "\\textbf{•}", "Fett", keywords: ["fett", "bold"], priority: 90),
        command("textit", "\\textit{•}", "Kursiv", keywords: ["kursiv", "schräg", "italic"], priority: 85),
        command("underline", "\\underline{•}", "Unterstrichen", keywords: ["unterstrichen", "unterstreichen"], priority: 60),
        command("emph", "\\emph{•}", "Hervorheben (meist kursiv)", keywords: ["hervorheben", "betonen"], priority: 70),
        command("texttt", "\\texttt{•}", "Schreibmaschinenschrift", keywords: ["schreibmaschine", "code", "monospace"], priority: 40),
        command("textsc", "\\textsc{•}", "Kapitälchen", keywords: ["kapitälchen"], priority: 20),
        command("textsf", "\\textsf{•}", "Serifenlose Schrift", keywords: ["serifenlos"], priority: 20),
        command("textcolor", "\\textcolor{•}{•}", "Farbiger Text, z. B. {red}{Text}", keywords: ["farbe", "farbig", "color"], requirements: [.xcolor], priority: 45),
        command("tiny", "\\tiny", "Winzige Schrift (ab hier)", keywords: ["schriftgrösse", "klein"], priority: 15),
        command("small", "\\small", "Kleine Schrift (ab hier)", keywords: ["schriftgrösse", "klein"], priority: 30),
        command("footnotesize", "\\footnotesize", "Schrift wie Fussnoten (ab hier)", keywords: ["schriftgrösse", "klein"], priority: 20),
        command("normalsize", "\\normalsize", "Normale Schriftgrösse", keywords: ["schriftgrösse", "normal"], priority: 20),
        command("large", "\\large", "Grössere Schrift (ab hier)", keywords: ["schriftgrösse", "gross"], priority: 30),
        command("Large", "\\Large", "Noch grössere Schrift", keywords: ["schriftgrösse", "gross"], priority: 25),
        command("LARGE", "\\LARGE", "Sehr grosse Schrift", keywords: ["schriftgrösse", "gross"], priority: 15),
        command("huge", "\\huge", "Riesige Schrift", keywords: ["schriftgrösse", "gross"], priority: 15),

        // Listen, Verweise, Fussnoten
        command("item", "\\item ", "Aufzählungspunkt", keywords: ["punkt", "aufzählung", "liste"], priority: 95),
        command("label", "\\label{•}", "Marke, auf die man verweisen kann", keywords: ["marke", "verweis", "anker"], priority: 70),
        argument("ref", "Verweis auf eine Marke (Nummer)", keywords: ["verweis", "referenz"], priority: 75),
        argument("eqref", "Verweis auf eine Gleichung, z. B. (3)", keywords: ["verweis", "gleichung"], requirements: [.amsmath], priority: 55),
        argument("pageref", "Seitenzahl einer Marke", keywords: ["seite", "verweis"], priority: 20),
        argument("cite", "Quelle zitieren", keywords: ["zitieren", "quelle", "literatur"], priority: 55),
        command("footnote", "\\footnote{•}", "Fussnote", keywords: ["fussnote", "anmerkung"], priority: 60),
        command("url", "\\url{•}", "Internetadresse", keywords: ["link", "internet", "adresse"], requirements: [.hyperref], priority: 30),
        command("href", "\\href{•}{•}", "Link mit eigenem Text", keywords: ["link", "verknüpfung"], requirements: [.hyperref], priority: 30),

        // Bilder und Tabellen
        command("includegraphics", "\\includegraphics[width=0.8\\textwidth]{•}", "Bild einbinden", keywords: ["bild", "grafik", "foto"], requirements: [.graphicx], priority: 60),
        command("caption", "\\caption{•}", "Beschriftung einer Abbildung oder Tabelle", keywords: ["beschriftung", "bildunterschrift"], priority: 60),
        command("centering", "\\centering", "Zentrieren (in Abbildungen und Tabellen)", keywords: ["zentrieren", "mitte"], priority: 55),
        command("hline", "\\hline", "Waagrechte Linie in einer Tabelle", keywords: ["linie", "tabelle", "strich"], priority: 45),
        command("toprule", "\\toprule", "Obere Linie (booktabs)", keywords: ["linie", "tabelle"], requirements: [.booktabs], priority: 25),
        command("midrule", "\\midrule", "Mittlere Linie (booktabs)", keywords: ["linie", "tabelle"], requirements: [.booktabs], priority: 25),
        command("bottomrule", "\\bottomrule", "Untere Linie (booktabs)", keywords: ["linie", "tabelle"], requirements: [.booktabs], priority: 25),
        command("multicolumn", "\\multicolumn{•}{•}{•}", "Zelle über mehrere Spalten", keywords: ["zellen verbinden", "spalten"], priority: 25),
        command("textwidth", "\\textwidth", "Breite des Textes (als Länge)", keywords: ["breite"], priority: 30),
        command("linewidth", "\\linewidth", "Breite der aktuellen Zeile (als Länge)", keywords: ["breite"], priority: 20),

        // Abstände und Seiten
        command("newpage", "\\newpage", "Neue Seite", keywords: ["seite", "seitenumbruch"], priority: 50),
        command("clearpage", "\\clearpage", "Neue Seite, offene Abbildungen vorher setzen", keywords: ["seite", "seitenumbruch"], priority: 25),
        command("newline", "\\newline", "Zeilenumbruch", keywords: ["zeile", "umbruch"], priority: 25),
        command("noindent", "\\noindent", "Absatz ohne Einzug", keywords: ["einzug"], priority: 35),
        command("vspace", "\\vspace{•}", "Senkrechter Abstand, z. B. 1cm", keywords: ["abstand", "leerraum", "vertikal"], priority: 40),
        command("hspace", "\\hspace{•}", "Waagrechter Abstand, z. B. 1cm", keywords: ["abstand", "leerraum", "horizontal"], priority: 35),
        command("smallskip", "\\smallskip", "Kleiner Abstand zwischen Absätzen", keywords: ["abstand"], priority: 20),
        command("medskip", "\\medskip", "Mittlerer Abstand zwischen Absätzen", keywords: ["abstand"], priority: 25),
        command("bigskip", "\\bigskip", "Grosser Abstand zwischen Absätzen", keywords: ["abstand"], priority: 25),

        // Dokument
        argument("usepackage", "Paket laden", keywords: ["paket"], priority: 70),
        argument("documentclass", "Dokumentklasse festlegen", keywords: ["klasse", "dokumentklasse"], priority: 30),
        argument("begin", "Umgebung beginnen", keywords: ["umgebung", "anfang"], priority: 90),
        argument("end", "Umgebung beenden", keywords: ["umgebung", "ende"], priority: 60),
        command("input", "\\input{•}", "Andere .tex-Datei hier einfügen", keywords: ["datei", "einbinden"], priority: 20),
        command("newcommand", "\\newcommand{\\•}{•}", "Eigenen Befehl festlegen", keywords: ["befehl", "makro", "abkürzung"], priority: 30),
        command("renewcommand", "\\renewcommand{\\•}{•}", "Befehl neu festlegen", keywords: ["befehl", "makro"], priority: 15),
        command("bibliography", "\\bibliography{•}", "Literaturverzeichnis aus einer .bib-Datei", keywords: ["literatur", "quellen"], priority: 20),
        command("bibliographystyle", "\\bibliographystyle{•}", "Stil des Literaturverzeichnisses, z. B. plain", keywords: ["literatur"], priority: 15),
        command("printbibliography", "\\printbibliography", "Literaturverzeichnis (biblatex)", keywords: ["literatur", "quellen"], priority: 15),
        command("LaTeX", "\\LaTeX", "Das LaTeX-Logo", keywords: ["logo"], priority: 10),
        command("ldots", "\\ldots", "Auslassungspunkte …", glyph: "…", keywords: ["punkte", "auslassung"], priority: 40),
        command("quad", "\\quad", "Abstand (eine Schriftbreite)", keywords: ["abstand"], priority: 45),
        command("qquad", "\\qquad", "Doppelter Abstand", keywords: ["abstand"], priority: 35)
    ]

    private static let mathCommands: [CompletionItem] = [
        math("frac", "\\frac{•}{•}", "Bruch", keywords: ["bruch", "geteilt"], priority: 95),
        math("dfrac", "\\dfrac{•}{•}", "Grosser Bruch (auch im Text)", keywords: ["bruch"], requirements: [.amsmath], priority: 40),
        math("tfrac", "\\tfrac{•}{•}", "Kleiner Bruch", keywords: ["bruch"], requirements: [.amsmath], priority: 15),
        math("sqrt", "\\sqrt{•}", "Wurzel", keywords: ["wurzel", "quadratwurzel"], priority: 90),
        math("sqrt", "\\sqrt[•]{•}", "n-te Wurzel", label: "\\sqrt[n]{…}", keywords: ["wurzel", "kubikwurzel"], id: "sqrt.n", priority: 50),
        math("sum", "\\sum_{•}^{•}", "Summe", glyph: "∑", keywords: ["summe", "summenzeichen"], priority: 80),
        math("prod", "\\prod_{•}^{•}", "Produkt", glyph: "∏", keywords: ["produkt"], priority: 55),
        math("int", "\\int_{•}^{•}", "Integral", glyph: "∫", keywords: ["integral"], priority: 80),
        math("iint", "\\iint", "Doppelintegral", glyph: "∬", keywords: ["integral", "doppelintegral"], requirements: [.amsmath], priority: 25),
        math("iiint", "\\iiint", "Dreifachintegral", glyph: "∭", keywords: ["integral"], requirements: [.amsmath], priority: 15),
        math("oint", "\\oint", "Kurvenintegral", glyph: "∮", keywords: ["integral", "kurvenintegral"], priority: 20),
        math("lim", "\\lim_{• \\to •}", "Grenzwert", keywords: ["grenzwert", "limes"], priority: 75),
        math("limsup", "\\limsup_{• \\to •}", "Limes superior", keywords: ["grenzwert"], priority: 15),
        math("liminf", "\\liminf_{• \\to •}", "Limes inferior", keywords: ["grenzwert"], priority: 15),
        math("max", "\\max", "Maximum", keywords: ["maximum"], priority: 40),
        math("min", "\\min", "Minimum", keywords: ["minimum"], priority: 40),
        math("sup", "\\sup", "Supremum", keywords: ["supremum"], priority: 30),
        math("inf", "\\inf", "Infimum", keywords: ["infimum"], priority: 25),
        math("sin", "\\sin", "Sinus", keywords: ["sinus"], priority: 55),
        math("cos", "\\cos", "Kosinus", keywords: ["kosinus", "cosinus"], priority: 55),
        math("tan", "\\tan", "Tangens", keywords: ["tangens"], priority: 40),
        math("arcsin", "\\arcsin", "Arkussinus", keywords: ["arkussinus"], priority: 20),
        math("arccos", "\\arccos", "Arkuskosinus", keywords: ["arkuskosinus"], priority: 20),
        math("arctan", "\\arctan", "Arkustangens", keywords: ["arkustangens"], priority: 20),
        math("sinh", "\\sinh", "Sinus hyperbolicus", priority: 10),
        math("cosh", "\\cosh", "Kosinus hyperbolicus", priority: 10),
        math("log", "\\log", "Logarithmus", keywords: ["logarithmus"], priority: 50),
        math("ln", "\\ln", "Natürlicher Logarithmus", keywords: ["logarithmus", "natürlich"], priority: 55),
        math("exp", "\\exp", "Exponentialfunktion", keywords: ["exponential"], priority: 35),
        math("det", "\\det", "Determinante", keywords: ["determinante"], priority: 35),
        math("dim", "\\dim", "Dimension", keywords: ["dimension"], priority: 25),
        math("ker", "\\ker", "Kern", keywords: ["kern"], priority: 25),
        math("gcd", "\\gcd", "Grösster gemeinsamer Teiler", keywords: ["ggt", "teiler"], priority: 15),
        math("cdot", "\\cdot", "Mal-Punkt", glyph: "·", keywords: ["mal", "punkt", "multiplikation"], priority: 85),
        math("times", "\\times", "Mal-Kreuz", glyph: "×", keywords: ["mal", "kreuz", "kreuzprodukt"], priority: 65),
        math("div", "\\div", "Geteilt-Zeichen", glyph: "÷", keywords: ["geteilt"], priority: 25),
        math("pm", "\\pm", "Plus-minus", glyph: "±", keywords: ["plusminus"], priority: 55),
        math("infty", "\\infty", "Unendlich", glyph: "∞", keywords: ["unendlich"], priority: 75),
        math("partial", "\\partial", "Partielle Ableitung", glyph: "∂", keywords: ["ableitung", "partiell"], priority: 50),
        math("nabla", "\\nabla", "Nabla", glyph: "∇", keywords: ["gradient"], priority: 25),
        math("cdots", "\\cdots", "Punkte auf Mitte", glyph: "⋯", keywords: ["punkte"], priority: 45),
        math("ldots", "\\ldots", "Punkte unten", glyph: "…", keywords: ["punkte"], priority: 40),
        math("vdots", "\\vdots", "Punkte senkrecht", glyph: "⋮", keywords: ["punkte"], priority: 30),
        math("ddots", "\\ddots", "Punkte schräg", glyph: "⋱", keywords: ["punkte"], priority: 25),
        math("mathbb", "\\mathbb{•}", "Zahlenmenge wie ℝ oder ℕ", glyph: "ℝ", keywords: ["zahlenmenge", "reelle", "natürliche"], requirements: [.amssymb], priority: 65),
        math("mathbf", "\\mathbf{•}", "Fett in Formeln", keywords: ["fett"], priority: 45),
        math("mathrm", "\\mathrm{•}", "Aufrecht in Formeln (z. B. Einheiten)", keywords: ["aufrecht"], priority: 40),
        math("mathcal", "\\mathcal{•}", "Schreibschrift in Formeln", glyph: "𝒜", keywords: ["schreibschrift"], priority: 30),
        math("text", "\\text{•}", "Normaler Text in einer Formel", keywords: ["text", "wort"], requirements: [.amsmath], priority: 70),
        math("operatorname", "\\operatorname{•}", "Eigener Funktionsname, aufrecht", keywords: ["funktion", "operator"], requirements: [.amsmath], priority: 20),
        math("vec", "\\vec{•}", "Vektorpfeil", glyph: "x⃗", keywords: ["vektor", "pfeil"], priority: 60),
        math("hat", "\\hat{•}", "Dach", glyph: "x̂", keywords: ["dach"], priority: 35),
        math("bar", "\\bar{•}", "Querstrich", glyph: "x̄", keywords: ["strich", "querstrich"], priority: 35),
        math("overline", "\\overline{•}", "Langer Strich darüber", keywords: ["strich", "konjugiert"], priority: 40),
        math("dot", "\\dot{•}", "Punkt darüber (Ableitung nach der Zeit)", glyph: "ẋ", keywords: ["punkt", "ableitung"], priority: 25),
        math("ddot", "\\ddot{•}", "Zwei Punkte darüber", glyph: "ẍ", keywords: ["ableitung"], priority: 15),
        math("tilde", "\\tilde{•}", "Tilde darüber", glyph: "x̃", keywords: ["tilde"], priority: 25),
        math("underbrace", "\\underbrace{•}_{•}", "Klammer darunter mit Text", keywords: ["klammer", "geschweift"], priority: 25),
        math("overbrace", "\\overbrace{•}^{•}", "Klammer darüber mit Text", keywords: ["klammer"], priority: 15),
        math("binom", "\\binom{•}{•}", "Binomialkoeffizient", keywords: ["binomial", "über", "auswahl"], requirements: [.amsmath], priority: 45),
        math("left(", "\\left( • \\right)", "Runde Klammern, die mitwachsen", label: "\\left( … \\right)", keywords: ["klammer", "rund"], id: "left.paren", priority: 60),
        math("left[", "\\left[ • \\right]", "Eckige Klammern, die mitwachsen", label: "\\left[ … \\right]", keywords: ["klammer", "eckig"], id: "left.bracket", priority: 40),
        math("left\\{", "\\left\\{ • \\right\\}", "Geschweifte Klammern, die mitwachsen", label: "\\left\\{ … \\right\\}", keywords: ["klammer", "geschweift", "menge"], id: "left.brace", priority: 35),
        math("left|", "\\left| • \\right|", "Betragsstriche, die mitwachsen", label: "\\left| … \\right|", keywords: ["betrag"], id: "left.bar", priority: 30),
        math("mod", "\\mod", "Modulo", keywords: ["modulo", "rest"], priority: 20),
        math("pmod", "\\pmod{•}", "Modulo in Klammern", keywords: ["modulo", "kongruenz"], priority: 15),
        math("displaystyle", "\\displaystyle", "Formel im Text gross setzen", keywords: ["gross"], priority: 15)
    ]

    /// Die Zeichen aus den Symbol-Kacheln (griechische Buchstaben, Vergleiche, Pfeile …).
    private static let symbolCommands: [CompletionItem] = {
        var seen = Set<String>()
        var items: [CompletionItem] = []
        let common: Set<String> = ["alpha", "beta", "pi", "leq", "geq", "neq", "in", "to", "approx", "lambda", "varphi", "sigma", "mu", "Rightarrow", "Leftrightarrow", "subseteq", "forall", "exists"]
        for symbol in MathSymbolGroup.allCases.flatMap(\.symbols) {
            // `\mathbb{R}` usw. stehen schon als \mathbb im Katalog.
            let name = String(symbol.command.dropFirst())
            guard name.allSatisfy({ $0.isLetter && $0.isASCII }), seen.insert(name).inserted else { continue }
            items.append(CompletionItem(
                id: "symbol.\(name)",
                kind: .symbol,
                name: name,
                label: symbol.command,
                detail: symbol.name.prefix(1).uppercased() + symbol.name.dropFirst(),
                glyph: symbol.glyph,
                body: symbol.command,
                requiresMath: true,
                isMath: true,
                keywords: [symbol.name.lowercased()],
                requirements: symbol.requirements,
                priority: common.contains(name) ? 60 : 40
            ))
        }
        return items
    }()

    // MARK: - Umgebungen

    public static let environments: [CompletionItem] = [
        environment("itemize", "Aufzählung mit Punkten", "\\begin{itemize}\n  \\item ‸\n\\end{itemize}", keywords: ["aufzählung", "liste", "punkte"], priority: 90),
        environment("enumerate", "Nummerierte Liste", "\\begin{enumerate}\n  \\item ‸\n\\end{enumerate}", keywords: ["nummeriert", "liste", "aufzählung"], priority: 90),
        environment("description", "Liste mit Begriffen", "\\begin{description}\n  \\item[•] •\n\\end{description}", keywords: ["begriffe", "liste"], priority: 35),
        environment("equation", "Nummerierte Formel", "\\begin{equation}\n  ‸\n\\end{equation}", keywords: ["formel", "gleichung"], math: true, priority: 80),
        environment("equation*", "Abgesetzte Formel ohne Nummer", "\\begin{equation*}\n  ‸\n\\end{equation*}", keywords: ["formel", "gleichung"], math: true, requirements: [.amsmath], priority: 60),
        environment("align", "Mehrzeilige Rechnung, an & ausgerichtet", "\\begin{align}\n  • &= • \\\\\n  &= •\n\\end{align}", keywords: ["rechnung", "mehrzeilig", "ausrichten"], math: true, requirements: [.amsmath], priority: 75),
        environment("align*", "Mehrzeilige Rechnung ohne Nummern", "\\begin{align*}\n  • &= • \\\\\n  &= •\n\\end{align*}", keywords: ["rechnung", "mehrzeilig"], math: true, requirements: [.amsmath], priority: 75),
        environment("gather", "Mehrere zentrierte Formeln", "\\begin{gather}\n  ‸\n\\end{gather}", keywords: ["formeln"], math: true, requirements: [.amsmath], priority: 25),
        environment("multline", "Lange Formel über mehrere Zeilen", "\\begin{multline}\n  ‸\n\\end{multline}", keywords: ["lang"], math: true, requirements: [.amsmath], priority: 15),
        environment("cases", "Fallunterscheidung (in einer Formel)", "\\begin{cases}\n  • & \\text{falls } • \\\\\n  • & \\text{sonst}\n\\end{cases}", keywords: ["fall", "fallunterscheidung", "falls"], math: true, requirements: [.amsmath], priority: 60),
        environment("pmatrix", "Matrix mit runden Klammern", "\\begin{pmatrix}\n  • & • \\\\\n  • & •\n\\end{pmatrix}", keywords: ["matrix"], math: true, requirements: [.amsmath], priority: 60),
        environment("bmatrix", "Matrix mit eckigen Klammern", "\\begin{bmatrix}\n  • & • \\\\\n  • & •\n\\end{bmatrix}", keywords: ["matrix"], math: true, requirements: [.amsmath], priority: 45),
        environment("vmatrix", "Determinante (Betragsstriche)", "\\begin{vmatrix}\n  • & • \\\\\n  • & •\n\\end{vmatrix}", keywords: ["determinante", "matrix"], math: true, requirements: [.amsmath], priority: 35),
        environment("matrix", "Matrix ohne Klammern", "\\begin{matrix}\n  • & • \\\\\n  • & •\n\\end{matrix}", keywords: ["matrix"], math: true, requirements: [.amsmath], priority: 25),
        environment("figure", "Abbildung mit Beschriftung", "\\begin{figure}[htbp]\n  \\centering\n  \\includegraphics[width=0.8\\textwidth]{•}\n  \\caption{•}\n  \\label{fig:•}\n\\end{figure}", keywords: ["abbildung", "bild", "grafik"], requirements: [.graphicx], priority: 70),
        environment("table", "Tabelle mit Beschriftung", "\\begin{table}[htbp]\n  \\centering\n  \\begin{tabular}{•}\n    •\n  \\end{tabular}\n  \\caption{•}\n  \\label{tab:•}\n\\end{table}", keywords: ["tabelle"], priority: 55),
        environment("tabular", "Tabelle, Spalten z. B. {lcr}", "\\begin{tabular}{•}\n  •\n\\end{tabular}", keywords: ["tabelle", "spalten"], priority: 70),
        environment("center", "Zentriert", "\\begin{center}\n  ‸\n\\end{center}", keywords: ["zentriert", "mitte"], priority: 55),
        environment("flushright", "Rechtsbündig", "\\begin{flushright}\n  ‸\n\\end{flushright}", keywords: ["rechts", "rechtsbündig"], priority: 25),
        environment("flushleft", "Linksbündig", "\\begin{flushleft}\n  ‸\n\\end{flushleft}", keywords: ["links", "linksbündig"], priority: 15),
        environment("minipage", "Kasten mit fester Breite (z. B. zwei nebeneinander)", "\\begin{minipage}{0.45\\textwidth}\n  ‸\n\\end{minipage}", keywords: ["nebeneinander", "spalte", "kasten"], priority: 30),
        environment("multicols", "Mehrere Spalten", "\\begin{multicols}{2}\n  ‸\n\\end{multicols}", keywords: ["spalten", "zweispaltig"], requirements: [PackageRequirement("multicol")], priority: 25),
        environment("quote", "Eingerücktes Zitat", "\\begin{quote}\n  ‸\n\\end{quote}", keywords: ["zitat"], priority: 35),
        environment("abstract", "Zusammenfassung am Anfang", "\\begin{abstract}\n  ‸\n\\end{abstract}", keywords: ["zusammenfassung", "abstract"], priority: 35),
        environment("verbatim", "Text genau so, wie er dasteht", "\\begin{verbatim}\n‸\n\\end{verbatim}", keywords: ["wörtlich", "code"], priority: 25),
        environment("lstlisting", "Quellcode", "\\begin{lstlisting}\n‸\n\\end{lstlisting}", keywords: ["code", "programm", "quellcode"], requirements: [.listings], priority: 25),
        environment("proof", "Beweis (endet mit □)", "\\begin{proof}\n  ‸\n\\end{proof}", keywords: ["beweis"], requirements: [PackageRequirement("amsthm")], priority: 55),
        environment("satz", "Satz (nummeriert)", "\\begin{satz}\n  ‸\n\\end{satz}", keywords: ["satz", "theorem"], requirements: [.theorems], priority: 50),
        environment("lemma", "Lemma (nummeriert)", "\\begin{lemma}\n  ‸\n\\end{lemma}", keywords: ["lemma", "hilfssatz"], requirements: [.theorems], priority: 40),
        environment("korollar", "Korollar (Folgerung)", "\\begin{korollar}\n  ‸\n\\end{korollar}", keywords: ["korollar", "folgerung"], requirements: [.theorems], priority: 25),
        environment("definition", "Definition (nummeriert)", "\\begin{definition}\n  ‸\n\\end{definition}", keywords: ["definition"], requirements: [.theorems], priority: 50),
        environment("beispiel", "Beispiel (nummeriert)", "\\begin{beispiel}\n  ‸\n\\end{beispiel}", keywords: ["beispiel"], requirements: [.theorems], priority: 40),
        environment("bemerkung", "Bemerkung", "\\begin{bemerkung}\n  ‸\n\\end{bemerkung}", keywords: ["bemerkung", "hinweis"], requirements: [.theorems], priority: 30),
        environment("frame", "Folie einer Präsentation (beamer)", "\\begin{frame}{•}\n  ‸\n\\end{frame}", keywords: ["folie", "präsentation"], priority: 35),
        environment("thebibliography", "Literaturverzeichnis von Hand", "\\begin{thebibliography}{9}\n  \\bibitem{•} •\n\\end{thebibliography}", keywords: ["literatur", "quellen"], priority: 20),
        environment("tikzpicture", "Zeichnung (TikZ)", "\\begin{tikzpicture}\n  ‸\n\\end{tikzpicture}", keywords: ["zeichnung", "grafik"], requirements: [PackageRequirement("tikz")], priority: 20),
        environment("document", "Inhalt des Dokuments", "\\begin{document}\n‸\n\\end{document}", keywords: ["dokument", "inhalt"], priority: 30)
    ]

    // MARK: - Pakete und Klassen

    public static let packages: [CompletionItem] = packageList.map { name, detail, priority in
        CompletionItem(id: "package.\(name)", kind: .package, name: name, label: name, detail: detail, body: name, priority: priority)
    }

    private static let packageList: [(String, String, Int)] = [
        ("amsmath", "Mathematik-Erweiterungen (align, cases, \\text …)", 90),
        ("amssymb", "Zusätzliche Zeichen (ℝ, ≤, ∴ …)", 85),
        ("amsthm", "Sätze, Definitionen und Beweise", 60),
        ("mathtools", "Noch mehr Mathe-Werkzeuge (lädt amsmath)", 40),
        ("graphicx", "Bilder einbinden", 80),
        ("xcolor", "Farben", 60),
        ("hyperref", "Klickbare Links und Verweise", 60),
        ("geometry", "Seitenränder und Papierformat", 70),
        ("babel", "Sprache, z. B. [ngerman] für Deutsch", 70),
        ("csquotes", "Richtige Anführungszeichen („…“)", 30),
        ("booktabs", "Schöne Tabellenlinien", 45),
        ("tabularx", "Tabellen mit fester Gesamtbreite", 30),
        ("array", "Mehr Spaltenarten für Tabellen", 20),
        ("longtable", "Tabellen über mehrere Seiten", 15),
        ("enumitem", "Listen anpassen, z. B. (a), (b)", 45),
        ("float", "Abbildungen genau hier platzieren [H]", 40),
        ("caption", "Beschriftungen anpassen", 25),
        ("subcaption", "Teilabbildungen (a), (b)", 25),
        ("wrapfig", "Bilder, die vom Text umflossen werden", 15),
        ("siunitx", "Zahlen und Einheiten (\\SI{5}{\\meter})", 40),
        ("tikz", "Zeichnungen", 35),
        ("pgfplots", "Diagramme und Funktionsgraphen", 30),
        ("listings", "Quellcode mit Hervorhebung", 30),
        ("microtype", "Feinere Typografie", 30),
        ("setspace", "Zeilenabstand", 30),
        ("parskip", "Absätze mit Abstand statt Einzug", 30),
        ("fancyhdr", "Kopf- und Fusszeilen", 35),
        ("multicol", "Mehrere Spalten", 30),
        ("cancel", "Durchstreichen in Formeln (Kürzen)", 25),
        ("tcolorbox", "Farbige Kästen", 20),
        ("mhchem", "Chemische Formeln (\\ce{H2O})", 15),
        ("biblatex", "Literaturverzeichnis (modern)", 25),
        ("url", "Internetadressen setzen", 15),
        ("titlesec", "Überschriften gestalten", 15),
        ("lmodern", "Schrift Latin Modern", 20),
        ("fontspec", "Systemschriften verwenden (XeLaTeX)", 20),
        ("lipsum", "Blindtext zum Ausprobieren", 15)
    ]

    public static let documentClasses: [CompletionItem] = classList.map { name, detail, priority in
        CompletionItem(id: "class.\(name)", kind: .documentClass, name: name, label: name, detail: detail, body: name, priority: priority)
    }

    private static let classList: [(String, String, Int)] = [
        ("article", "Artikel: Übungsblätter, kurze Texte", 90),
        ("report", "Bericht mit Kapiteln", 50),
        ("book", "Buch", 30),
        ("scrartcl", "KOMA-Artikel (europäische Typografie)", 60),
        ("scrreprt", "KOMA-Bericht mit Kapiteln", 40),
        ("scrbook", "KOMA-Buch", 20),
        ("beamer", "Präsentation mit Folien", 50),
        ("letter", "Brief", 15),
        ("scrlttr2", "KOMA-Brief", 15),
        ("standalone", "Einzelne Grafik oder Formel", 10)
    ]

    // MARK: - Bausteine für die Liste

    private static func command(
        _ name: String, _ body: String, _ detail: String,
        glyph: String? = nil, keywords: [String] = [],
        requirements: [PackageRequirement] = [], priority: Int
    ) -> CompletionItem {
        CompletionItem(
            id: "command.\(name)", kind: .command, name: name, label: label(for: body), detail: detail,
            glyph: glyph, body: body, keywords: keywords, requirements: requirements, priority: priority
        )
    }

    /// Befehl mit einem Argument, das gleich weiter vervollständigt wird (`\ref{` → Marken).
    private static func argument(
        _ name: String, _ detail: String, keywords: [String] = [],
        requirements: [PackageRequirement] = [], priority: Int
    ) -> CompletionItem {
        CompletionItem(
            id: "command.\(name)", kind: .command, name: name, label: "\\\(name){…}", detail: detail,
            body: "\\\(name){‸}", keywords: keywords, requirements: requirements,
            continuesCompletion: true, priority: priority
        )
    }

    private static func math(
        _ name: String, _ body: String, _ detail: String,
        label explicitLabel: String? = nil, glyph: String? = nil, keywords: [String] = [],
        requirements: [PackageRequirement] = [], id: String? = nil, priority: Int
    ) -> CompletionItem {
        CompletionItem(
            id: "math.\(id ?? name)", kind: .command, name: name, label: explicitLabel ?? label(for: body), detail: detail,
            glyph: glyph, body: body, requiresMath: true, isMath: true,
            keywords: keywords, requirements: requirements, priority: priority
        )
    }

    private static func environment(
        _ name: String, _ detail: String, _ body: String,
        keywords: [String] = [], math: Bool = false,
        requirements: [PackageRequirement] = [], priority: Int
    ) -> CompletionItem {
        CompletionItem(
            id: "environment.\(name)", kind: .environment, name: name, label: name, detail: detail,
            body: body, isMath: math, keywords: keywords, requirements: requirements, priority: priority
        )
    }

    /// `\frac{•}{•}` → `\frac{…}{…}` für die Anzeige.
    static func label(for body: String) -> String {
        body.replacingOccurrences(of: Placeholders.marker, with: "…")
            .replacingOccurrences(of: CompletionItem.cursorMarker, with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
