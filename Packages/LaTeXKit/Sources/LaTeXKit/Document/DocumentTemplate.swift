import Foundation

/// Vorlage für ein neues Dokument („Ablage → Neu aus Vorlage …“).
///
/// Jede Vorlage ist mit XeLaTeX (der Grundlage von Tectonic) ohne Fehler und
/// Warnungen geprüft und erklärt in Kommentaren, wo man etwas anpasst.
public struct DocumentTemplate: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    /// Ein Satz, wofür die Vorlage gedacht ist.
    public var subtitle: String
    /// SF-Symbol, falls kein Vorschaubild da ist.
    public var symbol: String
    /// Name des Vorschaubilds im Asset-Katalog der App.
    public var previewImageName: String { "template-\(id)" }
    /// Querformat (Präsentation) statt A4 hoch.
    public var isLandscape: Bool { id == "presentation" }
    public var text: String

    public init(id: String, title: String, subtitle: String, symbol: String, text: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.text = text
    }
}

extension DocumentTemplate {
    /// Alle Vorlagen in der Reihenfolge der Galerie.
    public static let all: [DocumentTemplate] = [blank, exercise, notes, summary, report, paper, presentation]

    public static let blank = DocumentTemplate(
        id: "blank",
        title: "Leer",
        subtitle: "Nur das Nötigste für Text und Formeln",
        symbol: "doc",
        text: #"""
        \documentclass[a4paper,11pt]{article}
        \usepackage[ngerman]{babel}
        \usepackage{amsmath,amssymb,amsthm}

        \begin{document}

        \section{Erster Abschnitt}
        Hier beginnt dein Text. Eine Formel im Fliesstext: $a^2 + b^2 = c^2$.

        \end{document}

        """#
    )

    public static let exercise = DocumentTemplate(
        id: "exercise",
        title: "Übungsblatt",
        subtitle: "Lösungen mit Kopfzeile, Name und Matrikelnummer, Teilaufgaben (a), (b)",
        symbol: "pencil.and.list.clipboard",
        text: #"""
        \documentclass[a4paper,11pt]{article}
        \usepackage[ngerman]{babel}
        \usepackage[margin=2.5cm]{geometry}
        \usepackage{amsmath,amssymb,amsthm}
        \usepackage{enumitem}
        \usepackage{fancyhdr}

        % Deine Angaben – einmal hier eintragen, sie erscheinen oben auf jeder Seite.
        \newcommand{\fach}{Analysis I}
        \newcommand{\blatt}{1}
        \newcommand{\namen}{Vorname Nachname}
        \newcommand{\matrikel}{12345678}

        \pagestyle{fancy}
        \fancyhf{}
        \fancyhead[L]{\fach{} -- Übungsblatt \blatt}
        \fancyhead[R]{\namen{} (\matrikel)}
        \fancyfoot[C]{\thepage}
        \setlength{\headheight}{14pt}

        \begin{document}

        \begin{center}
          {\Large\bfseries \fach{} -- Übungsblatt \blatt}\\[4pt]
          \namen, Matrikelnummer \matrikel
        \end{center}

        \section*{Aufgabe 1}
        \begin{enumerate}[label=(\alph*)]
          \item Zeige, dass $\displaystyle\lim_{n \to \infty} \frac{1}{n} = 0$ gilt.

          \textbf{Lösung:} Sei $\varepsilon > 0$. Wähle $N \in \mathbb{N}$ mit $N > \frac{1}{\varepsilon}$.
          Dann gilt für alle $n \geq N$:
          \[
            \left| \frac{1}{n} - 0 \right| = \frac{1}{n} \leq \frac{1}{N} < \varepsilon.
          \]

          \item Berechne $\displaystyle\sum_{k=1}^{n} k$.

          \textbf{Lösung:}
        \end{enumerate}

        \section*{Aufgabe 2}
        Beweise: Für alle $n \in \mathbb{N}$ ist $n^2 + n$ gerade.

        \begin{proof}
          Es ist $n^2 + n = n(n+1)$, und von zwei aufeinanderfolgenden Zahlen ist eine gerade.
        \end{proof}

        \end{document}

        """#
    )

    public static let notes = DocumentTemplate(
        id: "notes",
        title: "Mitschrift",
        subtitle: "Vorlesungsnotizen mit Definition, Satz und Beweis",
        symbol: "book.pages",
        text: #"""
        \documentclass[a4paper,11pt]{article}
        \usepackage[ngerman]{babel}
        \usepackage[margin=2.5cm]{geometry}
        \usepackage{amsmath,amssymb,amsthm}
        \usepackage[hidelinks]{hyperref}

        % Sätze, Definitionen und Beispiele werden gemeinsam nummeriert (1.1, 1.2, …).
        \theoremstyle{plain}
        \newtheorem{satz}{Satz}[section]
        \newtheorem{lemma}[satz]{Lemma}
        \newtheorem{korollar}[satz]{Korollar}
        \theoremstyle{definition}
        \newtheorem{definition}[satz]{Definition}
        \newtheorem{beispiel}[satz]{Beispiel}
        \theoremstyle{remark}
        \newtheorem*{bemerkung}{Bemerkung}

        \title{Lineare Algebra I -- Mitschrift}
        \author{Vorname Nachname}
        \date{Wintersemester 2026/27}

        \begin{document}
        \maketitle
        \tableofcontents

        \section{Vektorräume}
        \subsection*{Vorlesung vom 3.~November}

        \begin{definition}
          Ein \emph{Vektorraum} über einem Körper $K$ ist eine Menge $V$ mit einer
          Addition und einer Skalarmultiplikation, die die bekannten Rechenregeln erfüllen.
        \end{definition}

        \begin{beispiel}
          $\mathbb{R}^n$ ist ein Vektorraum über $\mathbb{R}$.
        \end{beispiel}

        \begin{satz}
          Jeder endlich erzeugte Vektorraum besitzt eine Basis.
        \end{satz}

        \begin{proof}
          Man streicht aus einem Erzeugendensystem so lange Vektoren, bis es linear unabhängig ist.
        \end{proof}

        \begin{bemerkung}
          Hier ist Platz für eigene Gedanken und Fragen an die Übung.
        \end{bemerkung}

        \end{document}

        """#
    )

    public static let summary = DocumentTemplate(
        id: "summary",
        title: "Zusammenfassung",
        subtitle: "Kompakt in zwei Spalten – für die Prüfungsvorbereitung",
        symbol: "rectangle.split.2x1",
        text: #"""
        \documentclass[a4paper,10pt]{article}
        \usepackage[ngerman]{babel}
        \usepackage[margin=1.5cm]{geometry}
        \usepackage{amsmath,amssymb}
        \usepackage{multicol}
        \usepackage{enumitem}

        % Kompakt: wenig Rand, keine Einzüge, enge Listen, zwei Spalten.
        \setlist{nosep}
        \setlength{\parindent}{0pt}
        \setlength{\columnsep}{1cm}

        \begin{document}

        \begin{center}
          {\Large\bfseries Zusammenfassung Analysis I}
        \end{center}

        \begin{multicols}{2}
        \section*{Folgen und Grenzwerte}
        \begin{itemize}
          \item $a_n \to a$, wenn es zu jedem $\varepsilon > 0$ ein $N$ gibt mit
                $|a_n - a| < \varepsilon$ für alle $n \geq N$.
          \item Jede konvergente Folge ist beschränkt.
          \item Monoton und beschränkt $\Rightarrow$ konvergent.
        \end{itemize}

        \section*{Ableitungsregeln}
        \begin{align*}
          (f g)' &= f' g + f g' \\
          \left( \frac{f}{g} \right)' &= \frac{f' g - f g'}{g^2} \\
          (f \circ g)' &= (f' \circ g) \cdot g'
        \end{align*}

        \section*{Wichtige Grenzwerte}
        \[
          \lim_{x \to 0} \frac{\sin x}{x} = 1, \qquad
          \lim_{n \to \infty} \left( 1 + \frac{1}{n} \right)^{n} = e
        \]
        \end{multicols}

        \end{document}

        """#
    )

    public static let report = DocumentTemplate(
        id: "report",
        title: "Versuchsprotokoll",
        subtitle: "Theorie, Messwerte als Tabelle, Auswertung",
        symbol: "flask",
        text: #"""
        \documentclass[a4paper,11pt]{article}
        \usepackage[ngerman]{babel}
        \usepackage[margin=2.5cm]{geometry}
        \usepackage{amsmath,amssymb}
        \usepackage{graphicx}
        \usepackage{booktabs}
        \usepackage[hidelinks]{hyperref}

        \title{Versuchsprotokoll: Das Fadenpendel}
        \author{Vorname Nachname \and Name der Partnerin}
        \date{\today}

        \begin{document}
        \maketitle

        \section{Einleitung}
        Worum geht es im Versuch, und was soll gemessen werden?

        \section{Theorie}
        Für kleine Auslenkungen gilt für die Schwingungsdauer
        \begin{equation}
          T = 2\pi \sqrt{\frac{l}{g}}.
          \label{eq:periode}
        \end{equation}

        \section{Durchführung}
        Beschreibe den Aufbau. Bilder ziehst du einfach in den Editor
        oder fügst sie über die Schaltfläche „Bild“ ein.

        \section{Messwerte}
        \begin{table}[htbp]
          \centering
          \begin{tabular}{ccc}
            \toprule
            Länge $l$ in m & Zeit für 10 Schwingungen in s & $T$ in s \\
            \midrule
            0{,}50 & 14{,}2 & 1{,}42 \\
            1{,}00 & 20{,}1 & 2{,}01 \\
            \bottomrule
          \end{tabular}
          \caption{Gemessene Schwingungsdauern}
          \label{tab:messwerte}
        \end{table}

        \section{Auswertung}
        Mit Gleichung~\eqref{eq:periode} und den Werten aus Tabelle~\ref{tab:messwerte}
        ergibt sich für die Fallbeschleunigung \dots

        \section{Fazit}
        Was ist herausgekommen, und wie genau war die Messung?

        \end{document}

        """#
    )

    public static let paper = DocumentTemplate(
        id: "paper",
        title: "Seminararbeit",
        subtitle: "Titelseite, Inhaltsverzeichnis und Literaturverzeichnis",
        symbol: "text.book.closed",
        text: #"""
        \documentclass[a4paper,12pt]{article}
        \usepackage[ngerman]{babel}
        \usepackage[margin=2.5cm]{geometry}
        \usepackage{amsmath,amssymb}
        \usepackage{graphicx}
        \usepackage{setspace}
        \usepackage[hidelinks]{hyperref}
        \onehalfspacing

        \begin{document}

        \begin{titlepage}
          \centering
          {\large Universität Musterstadt\par}
          {\large Seminar: Thema des Seminars\par}
          \vspace{4cm}
          {\LARGE\bfseries Titel der Seminararbeit\par}
          \vspace{2cm}
          {\large Vorname Nachname\par}
          Matrikelnummer 12345678\par
          \vfill
          Betreut von Prof.~Dr.~Muster\par
          \today
        \end{titlepage}

        \tableofcontents
        \newpage

        \section{Einleitung}
        Hier stehen Fragestellung und Aufbau der Arbeit. Quellen zitierst du so: \cite{forster}.

        \section{Grundlagen}
        \subsection{Begriffe}
        Erkläre die wichtigsten Begriffe.

        \section{Hauptteil}
        Der eigentliche Inhalt.

        \section{Fazit}
        Fasse die Ergebnisse zusammen.

        \begin{thebibliography}{9}
          \bibitem{forster} Otto Forster: \emph{Analysis 1}. Springer Spektrum, 2016.
        \end{thebibliography}

        \end{document}

        """#
    )

    public static let presentation = DocumentTemplate(
        id: "presentation",
        title: "Präsentation",
        subtitle: "Folien für einen Vortrag (beamer)",
        symbol: "rectangle.on.rectangle",
        text: #"""
        \documentclass{beamer}
        \usepackage[ngerman]{babel}
        \usepackage{amsmath,amssymb}
        \setbeamertemplate{navigation symbols}{}

        \title{Titel des Vortrags}
        \author{Vorname Nachname}
        \date{\today}

        \begin{document}

        \begin{frame}
          \titlepage
        \end{frame}

        \begin{frame}{Überblick}
          \tableofcontents
        \end{frame}

        \section{Einführung}
        \begin{frame}{Worum geht es?}
          \begin{itemize}
            \item Erster Punkt
            \item Zweiter Punkt
            \item Dritter Punkt
          \end{itemize}
        \end{frame}

        \section{Ergebnis}
        \begin{frame}{Die wichtigste Formel}
          \[
            e^{i\pi} + 1 = 0
          \]
        \end{frame}

        \end{document}

        """#
    )
}
