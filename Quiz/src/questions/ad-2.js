// AlgoDat Teil 2: Kapitel 5 (Wörterbücher), 6–8 (DP), 9–11 (Graphen)
QUIZ.add('ad', [
  // ---------------- 5 Suchbäume, 2-3-Bäume ----------------
  { id: 'ad9-01', t: 'ad9', d: 1, k: 'sc',
    q: 'Wie teuer ist die Suche in einem binären Suchbaum mit n Schlüsseln im Worst Case, wenn er nicht balanciert wird?',
    o: ['Θ(n)', 'Θ(log n)', 'Θ(1)', 'Θ(n log n)'], a: 0,
    e: 'Fügt man sortierte Schlüssel ein, entartet der Baum zu einer Liste mit Höhe n − 1. Die Suche kostet O(h).',
    m: 'BST: O(Höhe). Balancierte Bäume halten die Höhe bei O(log n).', s: 'Skript AuD 5.2.3' },

  { id: 'ad9-02', t: 'ad9', d: 2, k: 'sc', fix: true,
    q: 'Man fügt 5, 3, 8, 1, 4, 7, 9, 2 in dieser Reihenfolge in einen leeren binären Suchbaum ein. Welche Höhe hat der Baum (Anzahl Kanten auf dem längsten Pfad von der Wurzel)?',
    o: ['3', '2', '4', '7'], a: 0,
    e: '5 ist Wurzel, 3 und 8 seine Kinder, 1 und 4 unter 3, 7 und 9 unter 8. Die 2 landet rechts unter 1. Längster Pfad: 5 → 3 → 1 → 2, also Höhe 3.',
    m: 'Einfügen: suchen, wo der Schlüssel wäre, dort als Blatt anhängen.', s: 'Skript AuD 5.2.1' },

  { id: 'ad9-03', t: 'ad9', d: 2, k: 'sc',
    q: 'Im Baum aus der Reihenfolge 5, 3, 8, 1, 4, 7, 9, 2 wird die Wurzel 5 gelöscht, indem man sie durch ihren **symmetrischen Nachfolger** ersetzt. Welcher Schlüssel steht danach in der Wurzel?',
    o: ['7', '4', '8', '3'], a: 0,
    w: { 1: '4 wäre der symmetrische Vorgänger. Das ginge auch, ist aber nicht gefragt.', 2: '8 ist das rechte Kind, nicht der kleinste Schlüssel im rechten Teilbaum.' },
    e: 'Der symmetrische Nachfolger ist der kleinste Schlüssel im rechten Teilbaum: von 8 aus immer links, also 7. Er hat höchstens ein (rechtes) Kind und lässt sich leicht entfernen.',
    m: 'Knoten mit zwei Kindern löschen: mit symmetrischem Nachfolger tauschen.', s: 'Skript AuD 5.2.2' },

  { id: 'ad9-04', t: 'ad9', d: 1, k: 'sc',
    q: 'Wo stehen in den 2-3-Bäumen dieser Vorlesung die eigentlichen Schlüssel?',
    o: ['Nur in den Blättern, innere Knoten enthalten Separatoren', 'In allen Knoten, wie beim binären Suchbaum', 'Nur in der Wurzel', 'In den inneren Knoten, Blätter sind leer'], a: 0,
    w: { 1: 'Das wäre ein interner Suchbaum. Die 2-3-Bäume hier sind extern.' },
    e: 'Die 2-3-Bäume sind externe Suchbäume: Daten in den Blättern, alle Blätter auf derselben Tiefe. Innere Knoten haben 2 oder 3 Kinder und 1 oder 2 Separatoren zur Navigation.',
    m: 'Externer Suchbaum: Schlüssel unten, Wegweiser oben.', s: 'Skript AuD 5.3.1' },

  { id: 'ad9-05', t: 'ad9', d: 2, k: 'sc',
    q: 'Ein innerer Knoten eines 2-3-Baums hat die Separatoren 13 und 25. In welchen Teilbaum geht die Suche nach dem Schlüssel 13?',
    o: ['In den linken', 'In den mittleren', 'In den rechten', 'Die Suche endet hier, 13 ist gefunden'], a: 0,
    w: { 1: 'Der mittlere Teilbaum enthält Schlüssel > 13 und ≤ 25.', 3: 'Separatoren sind nur Wegweiser, der Schlüssel steht in einem Blatt.' },
    e: 'Separatorbedingung: links alle Schlüssel ≤ s₁, Mitte > s₁ und ≤ s₂, rechts > s₂. 13 ≤ 13, also links.',
    m: 'Gleichheit mit dem Separator heisst „links davon“.', s: 'Skript AuD 5.3.1' },

  { id: 'ad9-06', t: 'ad9', d: 3, k: 'sc', fix: true,
    q: 'Wie viele Schlüssel kann ein 2-3-Baum der Höhe 3 höchstens bzw. mindestens speichern?',
    o: ['höchstens 27, mindestens 8', 'höchstens 9, mindestens 6', 'höchstens 27, mindestens 3', 'höchstens 81, mindestens 16'], a: 0,
    e: 'Alle Blätter liegen in Tiefe 3, jedes Blatt hat genau einen Schlüssel. Mit nur Dreierknoten: $3^3 = 27$ Blätter. Mit nur Zweierknoten: $2^3 = 8$. Daraus folgt $h \\le \\log_2 n$.',
    m: '$2^h \\le n \\le 3^h$ für 2-3-Bäume.', s: 'Skript AuD 5.3.1' },

  { id: 'ad9-07', t: 'ad9', d: 3, k: 'sc',
    q: 'Wann wird ein 2-3-Baum beim Einfügen **höher**?',
    o: ['Nur wenn die Spaltung bis zur Wurzel hochläuft und die Wurzel geteilt wird', 'Bei jedem Einfügen', 'Wenn ein Blatt in einen Knoten mit 2 Kindern eingefügt wird', 'Wenn der neue Schlüssel grösser als alle anderen ist'], a: 0,
    w: { 2: 'Dann hat der Knoten danach 3 Kinder, das ist erlaubt.' },
    e: 'Hat ein Knoten nach dem Einfügen 4 Kinder, wird er in zwei Knoten mit je 2 Kindern geteilt, und der Elternknoten bekommt ein Kind mehr. Erreicht das die Wurzel, entsteht eine neue Wurzel über den beiden Hälften. Alle Blätter bleiben auf gleicher Tiefe.',
    m: '2-3-Bäume wachsen an der Wurzel, nicht an den Blättern.', s: 'Skript AuD 5.3.2' },

  { id: 'ad9-08', t: 'ad9', d: 2, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Ein Inorder-Durchlauf eines binären Suchbaums liefert die Schlüssel sortiert.', true, 'Links kleiner, rechts grösser, rekursiv.'],
      ['search, insert und delete gehen in einem 2-3-Baum in O(log n).', true, 'Die Höhe ist O(log n).'],
      ['In einem 2-3-Baum können Blätter auf verschiedenen Tiefen liegen.', false, 'Alle Blätter liegen auf derselben Tiefe.'],
      ['Ein Max-Heap unterstützt die Suche nach einem beliebigen Schlüssel in O(log n).', false, 'Der Heap ist nur teilweise geordnet, Suche kostet O(n).']
    ],
    e: 'Wörterbücher brauchen search, insert, delete. Suchbäume liefern das, Heaps nicht.', m: 'Heap ≠ Suchbaum.', s: 'Skript AuD 5' },

  { id: 'ad9-w1', t: 'ad9', d: 2, k: 'w',
    q: 'Füge 50, 30, 70, 20, 40, 60, 80, 35, 45 in einen leeren binären Suchbaum ein. Lösche dann 30 (mit symmetrischem Nachfolger). Gib die Inorder-Folge und die neue Wurzel des linken Teilbaums an.',
    sol: [
      'Baum: 50 mit Kindern 30 und 70. Unter 30: 20 und 40. Unter 40: 35 und 45. Unter 70: 60 und 80.',
      '30 hat zwei Kinder. Symmetrischer Nachfolger: kleinster Schlüssel im rechten Teilbaum von 30, also von 40 aus links: 35.',
      '35 ersetzt 30. 35 war ein Blatt und verschwindet an der alten Stelle.',
      'Linker Teilbaum: 35 mit Kindern 20 und 40, unter 40 nur noch 45. Inorder: 20, 35, 40, 45, 50, 60, 70, 80.'
    ],
    res: 'Neue Wurzel links: 35. Inorder: 20, 35, 40, 45, 50, 60, 70, 80',
    m: 'Nach jedem Löschen muss Inorder sortiert bleiben.', s: 'Skript AuD 5.2' },

  { id: 'ad9-w2', t: 'ad9', d: 3, k: 'w',
    q: 'Ein 2-3-Baum hat die Wurzel mit Separatoren 10 und 20 und drei Kinder: links ein Knoten mit Separator 5 über den Blättern 3 und 7, in der Mitte ein Knoten mit Separatoren 12 und 15 über den Blättern 11, 14, 18, rechts ein Knoten mit Separator 25 über den Blättern 22 und 30. Füge 13 ein. Beschreibe jeden Schritt.',
    hint: 'Das Blatt 13 gehört zwischen 11 und 14. Wie viele Kinder hat der mittlere Knoten danach?',
    sol: [
      'Suche: 13 > 10 und ≤ 20 → mittlerer Knoten. Dort 12 < 13 ≤ 15 → zwischen den Blättern 11 und 14 einfügen.',
      'Der mittlere Knoten hat jetzt 4 Kinder (11, 13, 14, 18) und braucht 3 Separatoren, z. B. 12, 13, 15. Die 2-3-Bedingung ist verletzt.',
      'Teilen: linker Teil mit Blättern 11, 13 und Separator 12; rechter Teil mit Blättern 14, 18 und Separator 15. Der mittlere Separator 13 wandert in die Wurzel.',
      'Die Wurzel hat jetzt 4 Kinder und die Separatoren 10, 13, 20 → auch sie wird geteilt: neue Wurzel mit Separator 13, darunter zwei Knoten mit Separator 10 bzw. 20, je mit 2 Kindern.',
      'Der Baum ist um eine Ebene gewachsen, alle Blätter liegen weiterhin auf derselben Tiefe.'
    ],
    res: 'Spaltung bis zur Wurzel, neue Wurzel mit Separator 13, Höhe + 1.',
    m: 'Vier Kinder → teilen und den mittleren Separator nach oben geben.', s: 'Skript AuD 5.3.2' },

  // ---------------- 6 DP-Grundlagen ----------------
  { id: 'ad10-01', t: 'ad10', d: 1, k: 'sc',
    q: 'Die naive Rekursion für Fibonacci-Zahlen ist exponentiell. Was macht **Memoization**?',
    o: ['Bereits berechnete Teilergebnisse speichern und beim nächsten Aufruf nachschlagen', 'Die Rekursion durch eine Formel ersetzen', 'Die Teilprobleme in zufälliger Reihenfolge berechnen', 'Die Rekursionstiefe begrenzen'], a: 0,
    e: 'Jeder Wert F(i) wird nur einmal berechnet, danach aus einer Tabelle gelesen. Die Laufzeit sinkt auf O(n).',
    m: 'Memoization = Rekursion + Gedächtnis.', s: 'Skript AuD 6.1.2' },

  { id: 'ad10-02', t: 'ad10', d: 2, k: 'sc',
    q: 'Was unterscheidet Bottom-up-DP von Memoization?',
    o: ['Bottom-up füllt die Tabelle in einer festen Reihenfolge, sodass jeder benötigte Eintrag schon berechnet ist', 'Bottom-up ist asymptotisch immer schneller', 'Memoization braucht keine Tabelle', 'Bottom-up funktioniert nur für eindimensionale Tabellen'], a: 0,
    w: { 1: 'Asymptotisch sind beide oft gleich. Bottom-up spart nur den Rekursions-Overhead.' },
    e: 'Bei Bottom-up muss man eine Berechnungsreihenfolge festlegen, in der alle Abhängigkeiten zuerst kommen. Memoization findet die Reihenfolge automatisch durch die Rekursion.',
    m: 'DP-Rezept: Teilproblem, Rekursion, Reihenfolge, Lösung auslesen.', s: 'Skript AuD 6.1.3–6.1.4' },

  { id: 'ad10-03', t: 'ad10', d: 2, k: 'sc',
    q: 'R[i] sei die grösste Summe eines **nicht leeren** Teilarrays, das genau bei Position i endet. Welche Rekursion stimmt?',
    o: ['R[i] = max(A[i], R[i − 1] + A[i])', 'R[i] = max(R[i − 1], A[i])', 'R[i] = R[i − 1] + A[i]', 'R[i] = max(R[i − 1], R[i − 1] + A[i])'], a: 0,
    w: { 1: 'Das wäre ein Teilarray, das nicht bei i endet.', 2: 'Manchmal lohnt es sich, neu zu beginnen.', 3: 'A[i] muss enthalten sein.' },
    e: 'Ein Teilarray, das bei i endet, ist entweder nur A[i] oder verlängert das beste bei i − 1 endende. Die Gesamtlösung ist das Maximum über alle R[i].',
    m: 'Teilproblem „endet genau bei i“ macht die Rekursion einfach.', s: 'Skript AuD 6.2.1' },

  { id: 'ad10-04', t: 'ad10', d: 2, k: 'sc', fix: true,
    q: 'Treppe mit n Stufen, pro Schritt 1 oder 2 Stufen. Auf wie viele Arten kommt man nach oben, wenn n = 6?',
    o: ['13', '8', '21', '12'], a: 0,
    e: 'W(n) = W(n − 1) + W(n − 2), weil der letzte Schritt 1 oder 2 Stufen ist. W(1) = 1, W(2) = 2, dann 3, 5, 8, 13.',
    m: 'Fallunterscheidung nach dem letzten Schritt.', s: 'Skript AuD 6.1' },

  { id: 'ad10-05', t: 'ad10', d: 3, k: 'sc',
    q: 'Wie viele Aufrufe macht die naive Rekursion F(n) = F(n − 1) + F(n − 2) mit F(1) = F(2) = 1 ungefähr?',
    o: ['Exponentiell viele, etwa $\\Theta(\\varphi^n)$ mit $\\varphi \\approx 1.618$', 'Θ(n²)', 'Θ(n)', 'Θ(2^n) genau'], a: 0,
    w: { 3: 'Die Anzahl wächst exponentiell, aber mit Basis φ, nicht 2.' },
    e: 'Die Anzahl Aufrufe A(n) = A(n − 1) + A(n − 2) + 1 wächst wie die Fibonacci-Zahlen selbst, also mit dem goldenen Schnitt als Basis.',
    m: 'Doppelte Berechnung gleicher Teilprobleme ist der Grund für DP.', s: 'Skript AuD 6.1.1' },

  { id: 'ad10-w1', t: 'ad10', d: 1, k: 'w',
    q: 'Treppe mit n Stufen, pro Schritt 1 oder 2 Stufen. Stelle die DP auf (Teilproblem, Rekursion, Reihenfolge, Lösung) und berechne die Anzahl Wege für n = 10.',
    ans: { k: 'num', v: 89 },
    sol: [
      'Teilproblem: W[i] = Anzahl Wege auf Stufe i.',
      'Rekursion: W[i] = W[i − 1] + W[i − 2], Basis W[0] = 1, W[1] = 1.',
      'Reihenfolge: i = 2, 3, …, n aufsteigend. Laufzeit O(n).',
      'Werte: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89. Also W[10] = 89.'
    ],
    res: 'W[10] = 89',
    m: 'Vier Teile jeder DP-Lösung: Tabelle, Rekursion, Reihenfolge, Auslesen.', s: 'Skript AuD 6' },

  // ---------------- 7 DP-Beispiele ----------------
  { id: 'ad11-01', t: 'ad11', d: 1, k: 'sc', fix: true,
    q: 'Jump Game mit A = (2, 3, 1, 1, 4): Start an Position 1, von i aus Sprung auf i + 1 bis i + A[i]. Wie viele Sprünge braucht man mindestens bis Position 5?',
    o: ['2', '3', '1', '4'], a: 0,
    e: '1 → 2 (A[1] = 2 erlaubt Sprung auf 2 oder 3), dann 2 → 5 (A[2] = 3 erlaubt bis 5).',
    m: 'Minimale Sprünge, nicht maximale Weite pro Sprung.', s: 'Skript AuD 7.1' },

  { id: 'ad11-02', t: 'ad11', d: 2, k: 'sc', fix: true,
    q: 'Jump Game mit A = (1, 3, 5, 3, 2, 1, 2, 4, 4, 2, 9). Das Skript zeigt die Lösung 1 → 2 → 5 → 7 → 9 → 11. Wie viele Sprünge braucht man **mindestens**?',
    o: ['4', '5', '3', '6'], a: 0,
    w: { 1: 'Das ist nur eine mögliche Lösung.', 2: 'Mit 3 Sprüngen kommt man höchstens bis Position 10 (M[3] = 10).' },
    e: 'Mit M[k] = grösster Index nach k Sprüngen: M[0] = 1, M[1] = 2, M[2] = 5, M[3] = 8 (über i = 3: 3 + 5), M[4] = 12 ≥ 11 (über i = 8: 8 + 4). Also 4 Sprünge, z. B. 1 → 2 → 3 → 8 → 11.',
    m: 'Zweiter Ansatz: M[k] = max{i + A[i] | i ≤ M[k − 1]}.', s: 'Skript AuD 7.1.2' },

  { id: 'ad11-03', t: 'ad11', d: 2, k: 'sc', fix: true,
    q: 'Wie lang ist die längste gemeinsame Teilfolge (LGT) von BANANE und ANANAS?',
    o: ['4', '5', '3', '6'], a: 0,
    e: 'Zum Beispiel ANAN ist Teilfolge von beiden. Eine gemeinsame Teilfolge der Länge 5 gibt es nicht. Die DP-Tabelle mit L[i][j] = L[i−1][j−1] + 1 bei gleichem Zeichen, sonst max(L[i−1][j], L[i][j−1]), liefert 4.',
    m: 'Teilfolge: Reihenfolge bleibt, Lücken sind erlaubt.', s: 'Skript AuD 7.2' },

  { id: 'ad11-04', t: 'ad11', d: 2, k: 'sc', fix: true,
    q: 'Was ist die Editierdistanz von KATZE und TATZEN (Einfügen, Löschen, Ersetzen kosten je 1)?',
    o: ['2', '1', '3', '4'], a: 0,
    e: 'K durch T ersetzen und am Ende N einfügen. Mit nur einer Operation müsste ein einziges Einfügen aus KATZE das Wort TATZEN machen. Dann wäre KATZE eine Teilfolge von TATZEN, aber K kommt in TATZEN nicht vor.',
    m: 'ED ≥ Längenunterschied.', s: 'Skript AuD 7.3' },

  { id: 'ad11-05', t: 'ad11', d: 2, k: 'sc',
    q: 'Welche Rekursion berechnet die Editierdistanz ED(i, j) der Präfixe A[1..i] und B[1..j]?',
    o: [
      'min(ED(i−1, j) + 1, ED(i, j−1) + 1, ED(i−1, j−1) + [aᵢ ≠ bⱼ])',
      'max(ED(i−1, j), ED(i, j−1)) + 1',
      'ED(i−1, j−1) + [aᵢ ≠ bⱼ]',
      'min(ED(i−1, j), ED(i, j−1)) + [aᵢ ≠ bⱼ]'
    ], a: 0,
    w: { 2: 'Einfügen und Löschen fehlen.', 3: 'Einfügen und Löschen kosten immer 1, unabhängig vom Vergleich.' },
    e: 'Das letzte Zeichen von A wird gelöscht, an B wird ein Zeichen angefügt, oder die letzten Zeichen werden aufeinander abgebildet (kostenlos bei Gleichheit, sonst ersetzt). Basis: ED(i, 0) = i, ED(0, j) = j.',
    m: 'Was passiert mit dem letzten Zeichen?', s: 'Skript AuD 7.3.3' },

  { id: 'ad11-06', t: 'ad11', d: 3, k: 'sc',
    q: 'Das Teilsummenproblem lässt sich per DP in Zeit O(n · b) lösen. Warum widerspricht das nicht der Vermutung P ≠ NP?',
    o: ['O(n · b) ist nicht polynomiell in der Eingabelänge, weil b nur mit etwa log b Bits kodiert wird', 'Weil die DP nur für kleine n funktioniert', 'Weil das Teilsummenproblem in P liegt', 'Weil die DP falsch ist'], a: 0,
    w: { 2: 'Das ist nicht bekannt, ein Polynomialzeit-Algorithmus würde P = NP zeigen.' },
    e: 'Die Laufzeit ist pseudopolynomiell: polynomiell im Zahlenwert b, aber exponentiell in der Anzahl Bits von b. Für b ≈ 2ⁿ ist die Tabelle riesig.',
    m: 'Pseudopolynomiell = polynomiell im Wert, nicht in der Länge.', s: 'Skript AuD 7.4 und 8.1' },

  { id: 'ad11-07', t: 'ad11', d: 2, k: 'sc',
    q: 'T(i, s) heisst: s ist eine Teilsumme von A[1..i]. Welche Rekursion stimmt (für s ≥ A[i])?',
    o: ['T(i, s) = T(i − 1, s) ∨ T(i − 1, s − A[i])', 'T(i, s) = T(i − 1, s) ∧ T(i − 1, s − A[i])', 'T(i, s) = T(i, s − A[i])', 'T(i, s) = T(i − 1, s − 1) ∨ T(i − 1, s)'], a: 0,
    w: { 2: 'Dann dürfte man A[i] mehrfach verwenden.' },
    e: 'Entweder A[i] gehört nicht zur Teilmenge, dann muss s schon eine Teilsumme von A[1..i−1] sein. Oder es gehört dazu, dann muss s − A[i] eine Teilsumme von A[1..i−1] sein.',
    m: 'Pro Element: nehmen oder nicht nehmen.', s: 'Skript AuD 7.4, Definition 7.5' },

  { id: 'ad11-08', t: 'ad11', d: 2, k: 'sc', fix: true,
    q: 'Rucksack mit Gewichtslimit W = 5 und Gegenständen (Gewicht, Profit): (2, 3), (3, 4), (4, 5), (5, 6). Was ist der maximale Profit?',
    o: ['7', '6', '9', '8'], a: 0,
    w: { 1: 'Der einzelne Gegenstand (5, 6) ist schlechter als die Kombination der ersten beiden.', 2: '(2, 3) und (4, 5) wiegen zusammen 6.' },
    e: 'Gegenstände 1 und 2: Gewicht 5, Profit 7. Andere zulässige Kombinationen erreichen höchstens 6.',
    m: 'Gierig nach Profit pro Gewicht ist beim 0/1-Rucksack nicht immer optimal, DP schon.', s: 'Skript AuD 7.5' },

  { id: 'ad11-09', t: 'ad11', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['ED(A, B) ≥ |len(A) − len(B)|.', true, 'Jedes Einfügen oder Löschen ändert die Länge um höchstens 1.'],
      ['ED(A, B) ≤ max(len(A), len(B)).', true, 'Den kürzeren String zeichenweise ersetzen, den Rest einfügen.'],
      ['ED(A, B) = 0 genau dann, wenn A = B.', true, 'Ohne Operation bleibt der String gleich.'],
      ['Die LGT von A und B ist eindeutig.', false, 'Die Länge ist eindeutig, die Teilfolge nicht: AB und BA haben die LGTs A und B.'],
      ['Die LGT-Tabelle hat (n + 1) · (m + 1) Einträge und lässt sich in O(nm) füllen.', true, 'Jeder Eintrag in O(1).']
    ],
    e: 'Viele Schranken folgen direkt aus der Definition, ohne DP.', m: 'Länge eindeutig, Lösung nicht.', s: 'Skript AuD 7.2–7.3' },

  { id: 'ad11-10', t: 'ad11', d: 3, k: 'sc',
    q: 'Für den Rucksack gibt es die Tabellen P(i, w) (maximaler Profit bei Gewichtslimit w) mit Laufzeit O(n · W) und G(i, p) (minimales Gewicht für Profit ≥ p) mit Laufzeit O(n · P), P = Summe aller Profite. Wann ist G vorzuziehen?',
    o: ['Wenn die Profite klein sind, die Gewichte aber riesig', 'Wenn die Gewichte klein sind', 'Nie, beide sind gleich gut', 'Wenn n sehr gross ist'], a: 0,
    w: { 1: 'Dann ist P(i, w) mit O(n · W) günstig.' },
    e: 'Die Laufzeit hängt vom Wert der Zahlen ab, die als Tabellenindex dienen. Sind die Profite klein, ist P klein, und G ist schnell. Genau das nutzt der Approximationsalgorithmus aus, indem er Profite rundet.',
    m: 'Die Variable mit kleinem Wertebereich gehört in den Tabellenindex.', s: 'Skript AuD 7.5, Definitionen 7.7–7.8' },

  { id: 'ad11-w1', t: 'ad11', d: 2, k: 'w',
    q: 'Berechne die Editierdistanz von SONNTAG und MONTAG mit einer DP-Tabelle. Gib eine optimale Folge von Operationen an.',
    ans: { k: 'num', v: 2 },
    sol: [
      'Tabelle ED(i, j) mit SONNTAG als Zeilen und MONTAG als Spalten, erste Zeile 0…6, erste Spalte 0…7.',
      'Die Diagonale bleibt kostenlos, solange die Zeichen gleich sind (O, N, T, A, G passen), zusätzliche Kosten entstehen nur an zwei Stellen.',
      'Optimale Folge: S durch M ersetzen (MONNTAG), ein N löschen (MONTAG).',
      'Untere Schranke: die Längen unterscheiden sich um 1 und das erste Zeichen ist verschieden, also mindestens 2.'
    ],
    res: 'ED(SONNTAG, MONTAG) = 2',
    m: 'Die Tabelle rechts unten liefert ED, Zurückverfolgen liefert die Operationen.', s: 'Skript AuD 7.3.4–7.3.7' },

  { id: 'ad11-w2', t: 'ad11', d: 2, k: 'w',
    q: 'Gib die LGT-Tabelle für A = TIGER und B = ZIEGE an. Wie lang ist die LGT, und welche Teilfolge ist es?',
    ans: { k: 'num', v: 3 },
    sol: [
      'L[i][j] = L[i−1][j−1] + 1, falls aᵢ = bⱼ, sonst max(L[i−1][j], L[i][j−1]).',
      'Gleiche Zeichen: I (T-I-G-E-R Index 2, Z-I-E-G-E Index 2), G (3 und 4), E (4 und 3 oder 5).',
      'Rechts unten steht 3. Zurückverfolgen liefert z. B. I, G, E (TIGER: I, G, E; ZIEGE: I, G, E am Ende).',
      'Andere Kandidaten der Länge 3 enthalten T oder R (kommen in ZIEGE nicht vor) oder zwei E (TIGER hat nur eines). „IGE“ ist hier also die einzige LGT.'
    ],
    res: 'LGT-Länge 3, zum Beispiel „IGE“',
    m: 'Bei Gleichheit diagonal, sonst das Maximum von oben und links.', s: 'Skript AuD 7.2' },

  { id: 'ad11-w3', t: 'ad11', d: 3, k: 'w',
    q: 'Rucksack mit W = 10 und Gegenständen (Gewicht, Profit): (5, 10), (4, 40), (6, 30), (3, 50). Fülle die Tabelle P(i, w) für i = 0, …, 4 nur für die nötigen w aus oder argumentiere direkt. Was ist der maximale Profit?',
    ans: { k: 'num', v: 90 },
    sol: [
      'P(i, w) = max(P(i − 1, w), pᵢ + P(i − 1, w − wᵢ)) für wᵢ ≤ w, sonst P(i − 1, w).',
      'Mit allen vier Gegenständen: Kombinationen mit Gewicht ≤ 10: {2, 4} Gewicht 7, Profit 90. {3, 4} Gewicht 9, Profit 80. {1, 2} Gewicht 9, Profit 50. {1, 4} Gewicht 8, Profit 60. {2, 3} Gewicht 10, Profit 70.',
      'Drei Gegenstände passen nie: schon die leichtesten drei wiegen 3 + 4 + 5 = 12 > 10.',
      'Also P(4, 10) = 90 mit den Gegenständen 2 und 4.'
    ],
    res: 'Maximaler Profit 90 (Gegenstände 2 und 4)',
    m: 'Rucksack-DP: nehmen oder nicht nehmen, Kapazität als zweite Dimension.', s: 'Skript AuD 7.5, Definition 7.7' },

  { id: 'ad11-w4', t: 'ad11', d: 2, k: 'w',
    q: 'A = (3, 5, 7, 9). Bestimme mit der Tabelle T(i, s), welche Summen s ∈ {0, …, 24} Teilsummen sind. Ist 11 eine Teilsumme? Wie viele Werte von 0 bis 24 sind keine Teilsumme?',
    ans: { k: 'num', v: 10 },
    sol: [
      'T(0, s) ist nur für s = 0 wahr.',
      'Nach Element 3: {0, 3}. Nach 5: {0, 3, 5, 8}. Nach 7: {0, 3, 5, 7, 8, 10, 12, 15}.',
      'Nach 9: zusätzlich {9, 12, 14, 16, 17, 19, 21, 24}, zusammen {0, 3, 5, 7, 8, 9, 10, 12, 14, 15, 16, 17, 19, 21, 24}.',
      '11 ist keine Teilsumme. Von den 25 Werten 0 bis 24 sind 15 Teilsummen, also 10 nicht.'
    ],
    res: '11 ist keine Teilsumme, 10 Werte fehlen',
    m: 'Neue Zeile = alte Menge ∪ (alte Menge + A[i]).', s: 'Skript AuD 7.4' },

  // ---------------- 8 P vs NP, LAT, Matrixketten ----------------
  { id: 'ad12-01', t: 'ad12', d: 1, k: 'sc',
    q: 'Was würde ein Polynomialzeit-Algorithmus für das Teilsummenproblem bedeuten?',
    o: ['P = NP', 'P ≠ NP', 'Nur dass Teilsumme in P liegt, sonst nichts', 'Dass auch Sortieren schneller geht'], a: 0,
    e: 'Das Teilsummenproblem ist NP-schwer: viele schwierige Probleme lassen sich darauf zurückführen (Theorem 8.1). Damit würden alle Probleme in NP polynomiell lösbar.',
    m: 'NP-schwere Probleme: polynomieller Algorithmus → P = NP.', s: 'Skript AuD 8.1, Theorem 8.1' },

  { id: 'ad12-02', t: 'ad12', d: 2, k: 'sc', fix: true,
    q: 'Wie lang ist die längste aufsteigende Teilfolge von (2, 13, 17, 9, 11, 4, 78, 28, 15, 25, 99)?',
    o: ['6', '5', '4', '7'], a: 0,
    e: 'Zum Beispiel (2, 9, 11, 15, 25, 99). Länger geht nicht: die DP mit M(i, ℓ) = kleinstmögliches Ende einer aufsteigenden Teilfolge der Länge ℓ liefert am Ende die Länge 6.',
    m: 'LAT: kleinste Endungen pro Länge merken.', s: 'Skript AuD 8.3' },

  { id: 'ad12-03', t: 'ad12', d: 2, k: 'sc',
    q: 'Welche Laufzeit erreicht die LAT-Lösung mit „kleinstmöglicher Endung pro Länge“, wenn man die passende Länge per binärer Suche findet?',
    o: ['O(n log n)', 'O(n²)', 'O(n)', 'O(n³)'], a: 0,
    e: 'Die Endungen M(ℓ) sind aufsteigend sortiert. Für jedes neue Element sucht man per binärer Suche die erste Endung ≥ A[i] und ersetzt sie. n Elemente mal O(log n).',
    m: 'Monotone DP-Tabelle → binäre Suche.', s: 'Skript AuD 8.3, Definition 8.6' },

  { id: 'ad12-04', t: 'ad12', d: 2, k: 'sc', fix: true,
    q: 'A₁ ist 10 × 100, A₂ ist 100 × 5, A₃ ist 5 × 50. Wie viele Multiplikationen von Einträgen braucht die beste Klammerung von A₁A₂A₃?',
    o: ['7500', '75000', '5000', '50000'], a: 0,
    w: { 1: 'Das ist A₁(A₂A₃).' },
    e: '(A₁A₂)A₃: 10 · 100 · 5 + 10 · 5 · 50 = 5000 + 2500 = 7500. A₁(A₂A₃): 100 · 5 · 50 + 10 · 100 · 50 = 75000.',
    m: 'p × q mal q × r kostet p · q · r Multiplikationen.', s: 'Skript AuD 8.4' },

  { id: 'ad12-05', t: 'ad12', d: 3, k: 'sc',
    q: 'Welche Laufzeit hat die DP für die Matrixkettenmultiplikation mit M(i, j) = min über k von M(i, k) + M(k + 1, j) + Kosten des letzten Produkts?',
    o: ['Θ(n³)', 'Θ(n²)', 'Θ(2ⁿ)', 'Θ(n log n)'], a: 0,
    w: { 1: 'Das ist die Anzahl Einträge, jeder kostet aber O(n).', 2: 'Das wäre das Ausprobieren aller Klammerungen (sogar mehr).' },
    e: 'Es gibt Θ(n²) Paare i ≤ j, und für jedes probiert man bis zu n Trennstellen k aus.',
    m: 'Laufzeit = Anzahl Einträge × Kosten pro Eintrag.', s: 'Skript AuD 8.4, Definition 8.7' },

  { id: 'ad12-06', t: 'ad12', d: 3, k: 'sc',
    q: 'Der Approximationsalgorithmus für den Rucksack rundet jeden Profit auf ein Vielfaches von K ab und löst dann exakt. Mit welcher Wahl von K erhält man eine Lösung mit Profit mindestens (1 − ε) · OPT?',
    o: ['$K = \\varepsilon \\cdot p_{\\max} / n$', '$K = \\varepsilon \\cdot n$', '$K = p_{\\max}$', '$K = 1/\\varepsilon$'], a: 0,
    e: 'Pro Gegenstand verliert man höchstens K, insgesamt höchstens nK = ε · p_max ≤ ε · OPT (weil jeder Gegenstand allein passt). Die Laufzeit O(n · P/K) wird damit O(n³/ε), also polynomiell für festes ε.',
    m: 'Gröbere Rundung: schneller, aber ungenauer.', s: 'Skript AuD 8.2' },

  { id: 'ad12-w1', t: 'ad12', d: 2, k: 'w',
    q: 'Matrizen mit Dimensionen 5 × 10, 10 × 3, 3 × 12, 12 × 5 (also d = (5, 10, 3, 12, 5)). Berechne die DP-Tabelle M(i, j) und die minimale Anzahl Multiplikationen.',
    ans: { k: 'num', v: 405 },
    sol: [
      'Länge 2: M(1,2) = 5·10·3 = 150, M(2,3) = 10·3·12 = 360, M(3,4) = 3·12·5 = 180.',
      'Länge 3: M(1,3) = min(M(2,3) + 5·10·12, M(1,2) + 5·3·12) = min(360 + 600, 150 + 180) = 330. M(2,4) = min(M(3,4) + 10·3·5, M(2,3) + 10·12·5) = min(180 + 150, 360 + 600) = 330.',
      'Länge 4: M(1,4) = min(M(2,4) + 5·10·5, M(1,2) + M(3,4) + 5·3·5, M(1,3) + 5·12·5) = min(330 + 250, 150 + 180 + 75, 330 + 300) = min(580, 405, 630) = 405.',
      'Beste Klammerung: (A₁A₂)(A₃A₄).'
    ],
    res: '405 Multiplikationen mit (A₁A₂)(A₃A₄)',
    m: 'Tabelle nach wachsender Kettenlänge füllen.', s: 'Skript AuD 8.4' },

  { id: 'ad12-w2', t: 'ad12', d: 2, k: 'w',
    q: 'Bestimme für A = (5, 2, 8, 6, 3, 6, 9, 7) die Länge einer längsten aufsteigenden Teilfolge mit der Methode „kleinstmögliche Endung pro Länge“. Schreibe die Endungen nach jedem Element auf.',
    ans: { k: 'num', v: 4 },
    sol: [
      'Endungen-Array M (Index = Länge): 5 → (5). 2 → (2). 8 → (2, 8). 6 → (2, 6). 3 → (2, 3).',
      '6 → (2, 3, 6). 9 → (2, 3, 6, 9). 7 → (2, 3, 6, 7).',
      'Jedes Element ersetzt die erste Endung ≥ sich selbst oder wird angehängt.',
      'Länge 4, zum Beispiel (2, 3, 6, 7) oder (2, 3, 6, 9).'
    ],
    res: 'LAT-Länge 4',
    m: 'Die Endungen bleiben sortiert, deshalb geht binäre Suche.', s: 'Skript AuD 8.3' },

  // ---------------- 9 Graphen, Eulerzyklen ----------------
  { id: 'ad13-01', t: 'ad13', d: 1, k: 'sc', fix: true,
    q: 'Ein Graph hat die Knotengrade 3, 3, 2, 2, 2. Wie viele Kanten hat er?',
    o: ['6', '12', '5', '10'], a: 0,
    w: { 1: 'Das ist die Gradsumme, jede Kante zählt dort doppelt.' },
    e: 'Handschlaglemma: Summe der Grade = 2m. 3 + 3 + 2 + 2 + 2 = 12, also m = 6.',
    m: '$\\sum_v \\deg(v) = 2m$', s: 'Skript AuD 9.3, Lemma 9.6' },

  { id: 'ad13-02', t: 'ad13', d: 1, k: 'sc',
    q: 'Welcher Graph besitzt einen Eulerzyklus?',
    o: ['K₅ (vollständiger Graph mit 5 Knoten)', 'K₄', 'K₃,₃', 'ein Pfad mit 4 Knoten'], a: 0,
    w: { 1: 'Alle Grade sind 3.', 2: 'Alle Grade sind 3.', 3: 'Die Endknoten haben Grad 1.' },
    e: 'Satz von Euler: ein zusammenhängender Graph hat genau dann einen Eulerzyklus, wenn alle Grade gerade sind. In K₅ hat jeder Knoten Grad 4.',
    m: 'Eulerzyklus ⟺ zusammenhängend und alle Grade gerade.', s: 'Skript AuD 9.4, Theorem 9.12' },

  { id: 'ad13-03', t: 'ad13', d: 2, k: 'sc',
    q: 'Welche Gradfolge kann zu **keinem** Graphen (ohne Mehrfachkanten und Schleifen) gehören?',
    o: ['(3, 3, 3, 2, 2)', '(2, 2, 2, 2)', '(3, 3, 2, 2)', '(1, 1, 1, 1)'], a: 0,
    w: { 1: 'Ein Kreis mit 4 Knoten.', 2: 'Ein Kreis mit 4 Knoten und einer Diagonale.', 3: 'Zwei disjunkte Kanten.' },
    e: 'Die Anzahl Knoten mit ungeradem Grad muss gerade sein (Korollar 9.7). Bei (3, 3, 3, 2, 2) sind es drei.',
    m: 'Ungerade Grade kommen immer paarweise.', s: 'Skript AuD 9.3, Korollar 9.7' },

  { id: 'ad13-04', t: 'ad13', d: 2, k: 'tf',
    q: 'Begriffe aus dem Skript: wahr oder falsch?',
    rows: [
      ['Ein Pfad ist ein Weg, in dem sich kein Knoten wiederholt.', true, 'Definition 9.9.'],
      ['Ein Zyklus darf denselben Knoten mehrmals besuchen, aber keine Kante mehrfach.', true, 'Kreise verbieten zusätzlich wiederholte Knoten.'],
      ['„Kreis“ heisst auf Englisch „circuit“.', false, 'Kreis = cycle, Zyklus = circuit. Die Übersetzung ist tückisch.'],
      ['In einem einfachen Graphen hat jeder Zyklus Länge mindestens 3.', true, 'Länge 2 würde dieselbe Kante zweimal benutzen.'],
      ['Ein Eulerzyklus ist ein Kreis, der jede Kante benutzt.', false, 'Er ist ein Zyklus: Knoten dürfen sich wiederholen.']
    ],
    e: 'Weg ⊃ Pfad, geschlossener Weg ⊃ Zyklus ⊃ Kreis.', m: 'Zyklus (circuit): keine Kante doppelt. Kreis (cycle): auch kein Knoten doppelt.', s: 'Skript AuD 9.3, Definition 9.9' },

  { id: 'ad13-05', t: 'ad13', d: 2, k: 'mc',
    q: 'Vergleich Adjazenzmatrix und Adjazenzlisten für einen Graphen mit n Knoten und m Kanten. Was stimmt? Wähle alle.',
    o: ['Die Matrix braucht Θ(n²) Speicher', 'Listen brauchen Θ(n + m) Speicher', 'Test, ob {u, v} eine Kante ist: Matrix O(1)', 'Alle Nachbarn von u aufzählen: Matrix O(deg(u))', 'Test, ob {u, v} eine Kante ist: Listen immer O(1)'], a: [0, 1, 2],
    w: { 3: 'Man muss die ganze Zeile durchgehen: Θ(n).', 4: 'Man muss die Liste von u durchsuchen: O(deg(u)).' },
    e: 'Die Matrix lohnt sich für dichte Graphen und schnelle Kantentests. Listen sind besser für dünne Graphen und für Algorithmen, die Nachbarn durchlaufen (DFS, BFS, Dijkstra).',
    m: 'Dünne Graphen: Listen. Dichte Graphen: Matrix.', s: 'Skript AuD 9.5' },

  { id: 'ad13-06', t: 'ad13', d: 2, k: 'sc',
    q: 'Das „Haus vom Nikolaus“ (Quadrat mit beiden Diagonalen und Dach) hat die Grade 2, 3, 3, 4, 4. Was folgt?',
    o: ['Es gibt einen Weg, der jede Kante genau einmal benutzt, er muss bei einem Knoten vom Grad 3 starten', 'Es gibt einen Eulerzyklus', 'Es gibt keinen Weg, der jede Kante genau einmal benutzt', 'Man kann bei jedem Knoten starten'], a: 0,
    e: 'Nach Lemma 9.10 sind bei einem Weg mit v₀ ≠ vₗ genau Start und Ende zu ungerade vielen Kanten inzident. Zwei Knoten mit ungeradem Grad → Start und Ende sind genau diese beiden.',
    m: 'Eulerweg (nicht geschlossen): genau zwei ungerade Knoten, dort Start und Ende.', s: 'Skript AuD 9.3, Lemma 9.10' },

  { id: 'ad13-07', t: 'ad13', d: 3, k: 'sc',
    q: 'Welche Laufzeit hat Hierholzers Algorithmus für einen zusammenhängenden Graphen mit lauter geraden Graden in Adjazenzlisten-Darstellung (mit den Zeiger-Erweiterungen)?',
    o: ['O(m)', 'O(n · m)', 'O(n²)', 'O(m log m)'], a: 0,
    w: { 2: 'Das wäre mit Adjazenzmatrix der Fall.' },
    e: 'Jede Kante wird genau einmal benutzt und gelöscht. Mit Zeigern zwischen den beiden Kopien jeder Kante in den Listen geht das Löschen in O(1). Die Erweiterungen selbst kosten einmalig O(n + m).',
    m: 'Eulerzyklus: linear. Hamiltonkreis: NP-schwer.', s: 'Skript AuD 9.5.4, Theorem 9.17' },

  { id: 'ad13-08', t: 'ad13', d: 3, k: 'sc',
    q: 'Warum ist der von FindeZyklus gefundene Weg immer geschlossen, wenn alle Grade gerade sind?',
    o: ['Jedes Betreten eines Knotens ≠ v₀ benutzt eine Kante, und weil der Grad gerade ist, bleibt immer eine zum Verlassen übrig', 'Weil der Graph zusammenhängend ist', 'Weil der Algorithmus immer zum Startknoten zurückspringt', 'Weil es keine Brücken gibt'], a: 0,
    w: { 1: 'Zusammenhang braucht man erst, um alle Zyklen zu einem Eulerzyklus zu verschmelzen.' },
    e: 'Man bleibt nur stecken, wenn an einem Knoten keine Kante mehr liegt. Bei einem Knoten v ≠ v₀ wurde bisher eine ungerade Anzahl seiner Kanten gelöscht, wegen geradem Grad liegt noch eine an. Also bleibt man nur bei v₀ stecken.',
    m: 'Gerade Grade: rein und raus kommen paarweise.', s: 'Skript AuD 9.4.1, Lemma 9.13' },

  { id: 'ad13-w1', t: 'ad13', d: 1, k: 'w',
    q: 'Beweise aus dem Handschlaglemma: In jedem Graphen ist die Anzahl Knoten mit ungeradem Grad gerade.',
    sol: [
      'Handschlaglemma: $\\sum_{v} \\deg(v) = 2m$ ist gerade.',
      'Teile die Summe in Knoten mit geradem und mit ungeradem Grad.',
      'Die Summe der geraden Grade ist gerade. Also muss auch die Summe der ungeraden Grade gerade sein.',
      'Eine Summe ungerader Zahlen ist genau dann gerade, wenn es gerade viele Summanden sind.'
    ],
    res: 'Die Anzahl ungerader Knoten ist gerade.',
    m: 'Paritätsargumente: gerade + gerade, ungerade + ungerade.', s: 'Skript AuD 9.3, Korollar 9.7' },

  // ---------------- 10 Topo-Sort, DFS, BFS ----------------
  { id: 'ad14-01', t: 'ad14', d: 1, k: 'sc',
    q: 'Wann besitzt ein gerichteter Graph eine topologische Sortierung?',
    o: ['Genau dann, wenn er keinen gerichteten Zyklus enthält', 'Immer', 'Genau dann, wenn er zusammenhängend ist', 'Genau dann, wenn jeder Knoten Eingangsgrad ≤ 1 hat'], a: 0,
    e: 'Ein gerichteter Zyklus kann nicht von links nach rechts angeordnet werden. Umgekehrt findet die Tiefensuche in jedem azyklischen Graphen eine Sortierung (Theorem 10.3).',
    m: 'Topologisch sortierbar ⟺ DAG.', s: 'Skript AuD 10.1, Theorem 10.3' },

  { id: 'ad14-02', t: 'ad14', d: 2, k: 'sc',
    q: 'Gerichtete Kanten: a→b, a→c, b→d, c→d, d→e, c→f, f→e. Welche Reihenfolge ist **keine** topologische Sortierung?',
    o: ['a, b, d, c, f, e', 'a, c, f, b, d, e', 'a, b, c, d, f, e', 'a, c, b, f, d, e'], a: 0,
    w: { 1: 'Alle Kanten zeigen nach rechts.', 2: 'Alle Kanten zeigen nach rechts.', 3: 'Alle Kanten zeigen nach rechts.' },
    e: 'In „a, b, d, c, f, e“ steht d vor c, aber es gibt die Kante c → d. Jede Kante muss von links nach rechts zeigen.',
    m: 'Prüfen: jede Kante einzeln.', s: 'Skript AuD 10.1, Definition 10.2' },

  { id: 'ad14-03', t: 'ad14', d: 2, k: 'sc',
    q: 'Wie erhält man aus einer Tiefensuche ohne back-Kanten eine topologische Sortierung?',
    o: ['Knoten absteigend nach post-Zeit sortieren', 'Knoten aufsteigend nach pre-Zeit sortieren', 'Knoten aufsteigend nach post-Zeit sortieren', 'Knoten in der Reihenfolge des ersten Besuchs'], a: 0,
    w: { 1: 'Ein später entdeckter Knoten kann eine Kante auf einen früher entdeckten haben (cross-Kante).' },
    e: 'Für jede Baum-, forward- und cross-Kante (u, v) gilt post[u] > post[v] (Beobachtung 10.6). Sortiert man absteigend nach post, zeigen alle Kanten nach rechts.',
    m: 'Topo-Sort = umgekehrte post-Reihenfolge.', s: 'Skript AuD 10.4, Theorem 10.7' },

  { id: 'ad14-04', t: 'ad14', d: 2, k: 'sc',
    q: 'Tiefensuche auf einem gerichteten Graphen: u hat das Intervall [pre, post] = [2, 7], v hat [1, 10]. Welcher Typ ist die Kante (u, v)?',
    o: ['back-Kante', 'Baumkante', 'forward-Kante', 'cross-Kante'], a: 0,
    w: { 1: 'Baum- und forward-Kanten zeigen von einem Vorfahren zu einem Nachfahren.', 3: 'Bei cross-Kanten sind die Intervalle disjunkt.' },
    e: 'I_u ⊂ I_v: u ist ein Nachfahre von v. Eine Kante von einem Nachfahren zurück zum Vorfahren ist eine back-Kante und zeigt einen gerichteten Zyklus an.',
    m: 'Intervalle verschachtelt: Baum/forward (nach unten) oder back (nach oben). Disjunkt: cross.', s: 'Skript AuD 10.4.2' },

  { id: 'ad14-05', t: 'ad14', d: 3, k: 'sc',
    q: 'Kante (u, v) mit u: [8, 9] und v: [3, 4] in einer Tiefensuche. Welcher Typ, und welche Ungleichung gilt?',
    o: ['cross-Kante, post[v] < pre[u]', 'back-Kante, post[u] < post[v]', 'forward-Kante, pre[u] < pre[v]', 'Das kann nicht vorkommen'], a: 0,
    e: 'Die Intervalle sind disjunkt und v wurde vollständig abgearbeitet, bevor u entdeckt wurde. Eine Kante in die umgekehrte Richtung (v früher, Kante von v nach u) kann es nicht geben, weil die Tiefensuche u dann von v aus entdeckt hätte.',
    m: 'cross-Kanten zeigen immer „zurück in die Vergangenheit“.', s: 'Skript AuD 10.4.2, Beobachtung 10.6' },

  { id: 'ad14-06', t: 'ad14', d: 3, k: 'tf',
    q: 'Tiefensuche: wahr oder falsch?',
    rows: [
      ['Zwei Intervalle [pre, post] sind entweder disjunkt oder ineinander enthalten.', true, 'Klammerungseigenschaft.'],
      ['Findet die Tiefensuche keine back-Kante, ist der Graph azyklisch.', true, 'Theorem 10.7.'],
      ['Für jede Baumkante (u, v) gilt post[u] > post[v].', true, 'v wird fertig, bevor u fertig wird.'],
      ['Auf ungerichteten Graphen gibt es cross-Kanten.', false, 'Eine solche Kante hätte die Tiefensuche schon als Baumkante benutzt. Es gibt nur Baum- und back-Kanten.'],
      ['Die Tiefensuche läuft mit Adjazenzlisten in O(n + m).', true, 'Jeder Knoten einmal, jede Kante einmal.']
    ],
    e: 'Die Zeitstempel erlauben es, Kanten zu klassifizieren, ohne den Baum explizit zu speichern.', m: 'back-Kante ⟺ gerichteter Zyklus.', s: 'Skript AuD 10.4' },

  { id: 'ad14-07', t: 'ad14', d: 2, k: 'sc',
    q: 'BFS auf einem **ungerichteten** Graphen von s aus. Knoten u liegt in Schicht Sᵢ (Distanz i) und {u, v} ist eine Kante. In welchen Schichten kann v liegen?',
    o: ['Sᵢ₋₁, Sᵢ oder Sᵢ₊₁', 'nur Sᵢ₊₁', 'in jeder Schicht Sⱼ mit j ≥ i', 'nur Sᵢ₋₁ oder Sᵢ₊₁'], a: 0,
    w: { 3: 'Kanten innerhalb einer Schicht sind möglich, z. B. in einem Dreieck.' },
    e: 'Über die Kante gilt d(s, v) ≤ i + 1 und d(s, u) ≤ d(s, v) + 1. In gerichteten Graphen gilt nur j ≤ i + 1, dort kann eine Kante beliebig weit zurückzeigen.',
    m: 'Ungerichtet: Kanten überspringen keine Schicht.', s: 'Skript AuD 10.5.2, Beobachtung 10.10' },

  { id: 'ad14-08', t: 'ad14', d: 2, k: 'sc',
    q: 'Warum findet BFS kürzeste Wege (nach Kantenzahl), DFS aber nicht?',
    o: ['BFS bearbeitet Knoten in der Reihenfolge wachsender Distanz, weil die Queue FIFO ist', 'Weil BFS jeden Knoten nur einmal besucht', 'Weil DFS rekursiv ist', 'Weil BFS Adjazenzlisten nutzt'], a: 0,
    w: { 1: 'Das tut DFS auch.' },
    e: 'Alle Knoten aus Sₖ kommen in die Queue, bevor irgendein Knoten aus Sₖ₊₁ hineinkommt. So erhält jeder Knoten seinen dist-Wert über einen kürzesten Weg (Theorem 10.12).',
    m: 'BFS: Queue. DFS: Stack bzw. Rekursion.', s: 'Skript AuD 10.5.2' },

  { id: 'ad14-w1', t: 'ad14', d: 3, k: 'w',
    q: 'Gerichteter Graph mit Kanten a→b, a→c, b→d, c→d, c→f, d→e, f→e. Führe die Tiefensuche mit Zeitstempeln aus (Start bei a, Nachbarn alphabetisch). Gib pre/post jedes Knotens an, klassifiziere alle Kanten und leite eine topologische Sortierung ab.',
    sol: [
      'a [1, 12], b [2, 7], d [3, 6], e [4, 5], c [8, 11], f [9, 10].',
      'Baumkanten: a→b, b→d, d→e, a→c, c→f.',
      'c→d: Intervalle [8, 11] und [3, 6] disjunkt, d schon fertig → cross-Kante. f→e: ebenfalls cross-Kante.',
      'Keine back-Kante, also azyklisch. Absteigend nach post: a (12), c (11), f (10), b (7), d (6), e (5).'
    ],
    res: 'Topologische Sortierung: a, c, f, b, d, e',
    m: 'Bei jeder bereits besuchten Nachbarin Intervalle vergleichen.', s: 'Skript AuD 10.4' },

  { id: 'ad14-w2', t: 'ad14', d: 2, k: 'w',
    q: 'Ungerichteter Graph mit Kanten s–a, s–b, a–c, a–d, b–d, c–e, d–e, e–f. Führe BFS von s aus (Nachbarn alphabetisch). Gib die Distanzen von a, b, c, d, e, f ein.',
    ans: { k: 'vec', v: [1, 1, 2, 2, 3, 4], ph: 'd(a), d(b), …, d(f)' },
    sol: [
      'Queue: s. s entdeckt a, b (Distanz 1).',
      'a entdeckt c, d (Distanz 2). b: d ist schon entdeckt.',
      'c entdeckt e (Distanz 3). d: e schon entdeckt.',
      'e entdeckt f (Distanz 4). Bearbeitungsreihenfolge: s, a, b, c, d, e, f.'
    ],
    res: 'd = (1, 1, 2, 2, 3, 4) für a, b, c, d, e, f',
    m: 'dist wird beim Entdecken gesetzt, nicht beim Bearbeiten.', s: 'Skript AuD 10.5.2' },

  // ---------------- 11 Dijkstra, Bellman-Ford ----------------
  { id: 'ad15-01', t: 'ad15', d: 1, k: 'sc',
    q: 'Unter welcher Voraussetzung berechnet Dijkstra korrekte Distanzen?',
    o: ['Alle Kantenkosten sind nicht negativ', 'Der Graph ist azyklisch', 'Der Graph ist ungerichtet', 'Alle Kantenkosten sind verschieden'], a: 0,
    e: 'Dijkstra legt den Knoten mit der kleinsten vorläufigen Distanz endgültig fest. Das ist nur richtig, wenn ein späterer Umweg nicht billiger werden kann, also ohne negative Kosten.',
    m: 'Negative Kanten → Bellman-Ford.', s: 'Skript AuD 11.3, Theorem 11.7' },

  { id: 'ad15-02', t: 'ad15', d: 1, k: 'sc',
    q: 'Welche Laufzeit hat Dijkstra mit einem Heap als Prioritätswarteschlange (n Knoten, m Kanten)?',
    o: ['O((m + n) log n)', 'O(n · m)', 'O(n²)', 'O(m + n)'], a: 0,
    w: { 1: 'Das ist Bellman-Ford.', 3: 'Das ist BFS.' },
    e: 'n-mal das Minimum entnehmen und bis zu m-mal eine Distanz verringern, jede Heap-Operation kostet O(log n).',
    m: 'Dijkstra: BFS mit Prioritätswarteschlange statt Queue.', s: 'Skript AuD 11.3.4, Theorem 11.8' },

  { id: 'ad15-03', t: 'ad15', d: 2, k: 'sc',
    q: 'Kanten s→a (2), s→b (3), b→a (−2). Welche Distanz für a liefert Dijkstra, und welche ist richtig?',
    o: ['Dijkstra: 2, richtig: 1', 'Dijkstra: 1, richtig: 1', 'Dijkstra: 2, richtig: 2', 'Dijkstra: −2, richtig: 1'], a: 0,
    e: 'Dijkstra nimmt zuerst a (vorläufige Distanz 2 < 3) und legt es fest. Später würde der Weg über b nur 3 − 2 = 1 kosten, aber a ist schon fertig.',
    m: 'Ein einziges negatives Gewicht reicht, um Dijkstra zu brechen.', s: 'Skript AuD 11.3' },

  { id: 'ad15-04', t: 'ad15', d: 2, k: 'sc',
    q: 'Bellman-Ford berechnet T(v, k). Was bedeutet T(v, k)?',
    o: ['Die minimalen Kosten eines Weges von s nach v mit höchstens k Kanten', 'Die Kosten nach k Iterationen von Dijkstra', 'Die Anzahl Wege von s nach v mit k Kanten', 'Die minimalen Kosten über genau k Knoten'], a: 0,
    e: 'Ohne negative Zyklen gibt es einen günstigsten Weg, der ein Pfad ist, also höchstens n − 1 Kanten hat. Deshalb genügt T(v, n − 1) = d(s, v). Rekursion: T(v, k) = min(T(v, k − 1), min über Kanten (u, v) von T(u, k − 1) + c(u, v)).',
    m: 'Bellman-Ford: DP über die Anzahl Kanten.', s: 'Skript AuD 11.4.1' },

  { id: 'ad15-05', t: 'ad15', d: 2, k: 'sc',
    q: 'Welche Laufzeit hat Bellman-Ford laut Skript (n − 1 Runden, in jeder Runde alle Knoten und Kanten)?',
    o: ['O(n(n + m))', 'O((m + n) log n)', 'O(n + m)', 'O(n³)'], a: 0,
    w: { 1: 'Das ist Dijkstra.', 3: 'Das ist Floyd-Warshall (kommt später).' },
    e: 'n − 1 Runden, jede kostet O(n + m). Speicher reicht O(n) mit der In-place-Variante.',
    m: 'Bellman-Ford: langsamer als Dijkstra, aber mit negativen Kanten.', s: 'Skript AuD 11.4, Theorem 11.10' },

  { id: 'ad15-06', t: 'ad15', d: 3, k: 'sc',
    q: 'Wie erkennt Bellman-Ford einen von s aus erreichbaren **negativen Zyklus**?',
    o: ['Eine zusätzliche n-te Runde verbessert noch mindestens einen Wert', 'Ein Wert wird negativ', 'Ein Knoten wird zweimal besucht', 'Der Algorithmus terminiert nicht'], a: 0,
    w: { 1: 'Negative Distanzen sind ohne negative Zyklen völlig normal.' },
    e: 'Ohne negativen Zyklus stehen nach n − 1 Runden die echten Distanzen fest, weitere Runden ändern nichts. Mit einem erreichbaren negativen Zyklus wird in Runde n mindestens ein Wert kleiner (Theorem 11.11).',
    m: 'Runde n ändert noch etwas → negativer Zyklus.', s: 'Skript AuD 11.4.3, Theorem 11.11' },

  { id: 'ad15-07', t: 'ad15', d: 2, k: 'sc',
    q: 'Kanten s→a (4), s→b (1), b→a (2), a→c (1), b→c (5), c→d (3), b→d (8), d→t (1), c→t (6). In welcher Reihenfolge legt Dijkstra die Knoten endgültig fest?',
    o: ['s, b, a, c, d, t', 's, a, b, c, d, t', 's, b, c, a, d, t', 's, b, a, c, t, d'], a: 0,
    w: { 1: 'b hat die kleinere vorläufige Distanz 1.', 2: 'a erreicht über b die Distanz 3, c erst 4.', 3: 't erreicht über d die Distanz 8, d selbst hat 7.' },
    e: 'Distanzen: s 0, b 1, a 3 (über b), c 4, d 7, t 8. Dijkstra legt die Knoten in aufsteigender Distanz fest.',
    m: 'Dijkstra: Reihenfolge = aufsteigende Distanz.', s: 'Skript AuD 11.3' },

  { id: 'ad15-08', t: 'ad15', d: 3, k: 'sc',
    q: 'Man addiert zu **jeder** Kante dieselbe Konstante c > 0, damit alle Kosten positiv werden, und lässt dann Dijkstra laufen. Was stimmt?',
    o: ['Das kann die günstigsten Wege verändern, weil Wege mit vielen Kanten stärker bestraft werden', 'Die günstigsten Wege bleiben gleich, nur die Distanzen ändern sich um c', 'Dijkstra liefert dann die Originaldistanzen plus c', 'Das funktioniert, wenn c gross genug ist'], a: 0,
    w: { 1: 'Ein Weg mit k Kanten wird um k · c teurer, nicht um c.', 2: 'Der Aufschlag hängt von der Anzahl Kanten des Weges ab.', 3: 'Je grösser c, desto stärker werden lange Wege bestraft.' },
    e: 'Beispiel: s→a direkt kostet 3, über zwei Kanten 1 + 1 = 2. Mit c = 2: direkt 5, über zwei Kanten 3 + 3 = 6. Der optimale Weg wechselt.',
    m: 'Gleiche Konstante pro Kante verzerrt Wege mit vielen Kanten.', s: 'Skript AuD 11.2–11.3' },

  { id: 'ad15-09', t: 'ad15', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Ohne negative Zyklen gibt es zu jedem u-v-Weg einen u-v-Pfad, der nicht teurer ist.', true, 'Zyklen im Weg haben Kosten ≥ 0 und können entfernt werden (Lemma 11.3).'],
      ['Mit einem erreichbaren negativen Zyklus kann d(s, v) für manche v gleich −∞ sein.', true, 'Man kann den Zyklus beliebig oft durchlaufen.'],
      ['Teilwege günstigster Wege sind wieder günstigste Wege.', true, 'Sonst könnte man den Teilweg ersetzen.'],
      ['Die Dreiecksungleichung d(u, v) ≤ d(u, w) + d(w, v) gilt nur bei positiven Kosten.', false, 'Sie folgt direkt aus der Definition als Minimum über Wege.'],
      ['Dijkstra funktioniert auch mit Kosten 0.', true, 'Nicht negativ reicht.']
    ],
    e: 'Die Struktur günstigster Wege erlaubt DP (Bellman-Ford) und gierige Verfahren (Dijkstra).', m: 'Teilwege optimaler Wege sind optimal.', s: 'Skript AuD 11.2' },

  { id: 'ad15-w1', t: 'ad15', d: 2, k: 'w',
    q: 'Führe Dijkstra von s aus: Kanten s→a (4), s→b (1), b→a (2), a→c (1), b→c (5), c→d (3), b→d (8), d→t (1), c→t (6). Gib die Distanzen von a, b, c, d, t ein.',
    ans: { k: 'vec', v: [3, 1, 4, 7, 8], ph: 'd(a), d(b), d(c), d(d), d(t)' },
    sol: [
      'Start: d[s] = 0, alle anderen ∞. Fest s → b = 1, a = 4.',
      'Fest b (1) → a = min(4, 1 + 2) = 3, c = 6, d = 9.',
      'Fest a (3) → c = min(6, 3 + 1) = 4.',
      'Fest c (4) → d = min(9, 4 + 3) = 7, t = 10. Fest d (7) → t = min(10, 8) = 8. Fest t (8).'
    ],
    res: 'd = (3, 1, 4, 7, 8) für a, b, c, d, t',
    m: 'Immer den kleinsten nicht festen Knoten nehmen und seine Nachbarn relaxieren.', s: 'Skript AuD 11.3' },

  { id: 'ad15-w2', t: 'ad15', d: 3, k: 'w',
    q: 'Bellman-Ford von s aus mit Kanten s→a (4), s→b (3), b→a (−2), a→c (2), b→c (4), c→d (−3), a→d (1). Gibt es einen negativen Zyklus? Gib die Distanzen von a, b, c, d ein.',
    ans: { k: 'vec', v: [1, 3, 3, 0], ph: 'd(a), d(b), d(c), d(d)' },
    sol: [
      'T(·, 0): s = 0, sonst ∞.',
      'T(·, 1): a = 4, b = 3.',
      'T(·, 2): a = min(4, 3 − 2) = 1, c = min(4 + 2, 3 + 4) = 6, d = 4 + 1 = 5.',
      'T(·, 3): c = min(6, 1 + 2) = 3, d = min(5, 1 + 1, 6 − 3) = 2. T(·, 4): d = min(2, 3 − 3) = 0.',
      'Eine weitere Runde ändert nichts mehr: kein negativer Zyklus (der Graph ist sogar azyklisch).'
    ],
    res: 'd = (1, 3, 3, 0) für a, b, c, d',
    m: 'Bellman-Ford: nach Runde k sind alle Wege mit ≤ k Kanten berücksichtigt.', s: 'Skript AuD 11.4' }
]);
