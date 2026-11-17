// LinAlg Teil 2: Kapitel 4 (Vektorräume) und Teil II bis 6.3
QUIZ.add('la', [
  // ---------------- 4.1–4.2.2 Vektorräume, Unterräume ----------------
  { id: 'la10-01', t: 'la10', d: 1, k: 'sc',
    q: 'Welche Menge ist ein Unterraum von ℝ²?',
    o: ['$\\{(x, y) \\mid y = 2x\\}$', '$\\{(x, y) \\mid y = 2x + 1\\}$', '$\\{(x, y) \\mid x \\ge 0\\}$', '$\\{(x, y) \\mid xy = 0\\}$'], a: 0,
    w: { 1: 'Enthält den Nullvektor nicht.', 2: 'Nicht abgeschlossen unter λ = −1.', 3: '(1, 0) + (0, 1) = (1, 1) liegt nicht drin.' },
    e: 'Unterraumkriterium (Lemma 4.12): nicht leer, abgeschlossen unter Addition und Skalarmultiplikation. Geraden durch 0 erfüllen das.',
    m: 'Erster Test: liegt der Nullvektor drin?', s: 'Skript LinAlg I 4.2.1, Lemma 4.12' },

  { id: 'la10-02', t: 'la10', d: 2, k: 'mc',
    q: 'Welche Teilmengen von $\\R^{2 \\times 2}$ sind Unterräume? Wähle alle.',
    o: ['die symmetrischen Matrizen', 'die invertierbaren Matrizen', 'die Matrizen mit $a_{11} + a_{22} = 0$', 'die Matrizen mit $a_{11} = 1$', 'die oberen Dreiecksmatrizen'], a: [0, 2, 4],
    w: { 1: 'Die Nullmatrix ist nicht invertierbar, und I + (−I) = 0.', 3: 'Die Nullmatrix fehlt.' },
    e: 'Lineare Bedingungen (Gleichungen ohne konstanten Term) definieren immer Unterräume. Invertierbarkeit ist keine lineare Bedingung.',
    m: 'Homogene lineare Bedingungen → Unterraum.', s: 'Skript LinAlg I 4.2.1' },

  { id: 'la10-03', t: 'la10', d: 2, k: 'sc',
    q: 'Ist die Menge der Polynome vom Grad **genau** 2 ein Unterraum von ℝ[x]?',
    o: ['Nein: (x² + x) + (−x²) = x hat Grad 1, und das Nullpolynom fehlt', 'Ja', 'Ja, weil sie unter Skalarmultiplikation abgeschlossen ist', 'Nein, weil ℝ[x] kein Vektorraum ist'], a: 0,
    w: { 2: 'Auch das stimmt nicht: 0 · (x²) = 0 hat keinen Grad 2.' },
    e: 'Die Polynome vom Grad **höchstens** 2 bilden dagegen einen Unterraum der Dimension 3.',
    m: '„Genau“ ist fast nie abgeschlossen, „höchstens“ oft schon.', s: 'Skript LinAlg I 4.1–4.2' },

  { id: 'la10-04', t: 'la10', d: 3, k: 'tf',
    q: 'U, W sind Unterräume eines Vektorraums V. Wahr oder falsch?',
    rows: [
      ['U ∩ W ist ein Unterraum.', true, 'Abgeschlossenheit gilt in beiden, also auch im Schnitt.'],
      ['U ∪ W ist ein Unterraum.', false, 'x-Achse ∪ y-Achse: (1, 0) + (0, 1) liegt nicht drin.'],
      ['U ∪ W ist ein Unterraum, wenn U ⊆ W.', true, 'Dann ist U ∪ W = W.'],
      ['Jeder Unterraum enthält den Nullvektor.', true, 'Lemma 4.13.'],
      ['$\\{f: \\R \\to \\R \\mid f(0) = 1\\}$ ist ein Unterraum von $\\R^\\R$.', false, 'Die Nullfunktion fehlt.']
    ],
    e: 'Die Vereinigung zweier Unterräume ist nur dann einer, wenn einer im anderen liegt.', m: 'Schnitt ja, Vereinigung meist nein.', s: 'Skript LinAlg I 4.2.1' },

  { id: 'la10-05', t: 'la10', d: 2, k: 'sc',
    q: 'Warum gilt in jedem Vektorraum $0 \\cdot v = 0$?',
    o: ['$0v = (0 + 0)v = 0v + 0v$, dann auf beiden Seiten $-0v$ addieren', 'Weil es ein Axiom ist', 'Weil v = 0 sein muss', 'Weil man durch v teilen kann'], a: 0,
    w: { 1: 'Es folgt aus den Axiomen (Fact 4.9).', 3: 'Durch Vektoren teilt man nicht.' },
    e: 'Distributivität über Skalare liefert 0v = 0v + 0v. Addition des Gegenvektors von 0v auf beiden Seiten ergibt 0 = 0v.',
    m: 'Wie in Ringen: mit dem additiven Inversen kürzen.', s: 'Skript LinAlg I 4.1, Fact 4.9' },

  { id: 'la10-w1', t: 'la10', d: 1, k: 'w',
    q: 'Zeige mit dem Unterraumkriterium, dass $U = \\{x \\in \\R^3 \\mid x_1 + 2x_2 - x_3 = 0\\}$ ein Unterraum ist. Gib eine Basis und die Dimension an.',
    ans: { k: 'num', v: 2 },
    sol: [
      'Nicht leer: 0 ∈ U.',
      'Addition: aus $x_1 + 2x_2 - x_3 = 0$ und $y_1 + 2y_2 - y_3 = 0$ folgt durch Addieren dasselbe für x + y.',
      'Skalarmultiplikation: λ(x₁ + 2x₂ − x₃) = 0.',
      'Basis: x₁ = −2x₂ + x₃ mit freien x₂, x₃: (−2, 1, 0) und (1, 0, 1). Dimension 2.'
    ],
    res: 'U ist eine Ebene durch 0, dim U = 2',
    m: 'U = N(A) für A = (1, 2, −1), also ein Unterraum.', s: 'Skript LinAlg I 4.2.1' },

  // ---------------- 4.2.3–4.2.6 Basis, Dimension ----------------
  { id: 'la11-01', t: 'la11', d: 1, k: 'sc', fix: true,
    q: 'Welche Dimension hat $\\R^{2 \\times 3}$?',
    o: ['6', '5', '2', '3'], a: 0,
    e: 'Eine Basis sind die 6 Matrizen mit genau einer 1 und sonst Nullen.',
    m: 'dim $\\R^{m \\times n}$ = m · n.', s: 'Skript LinAlg I 4.2.5' },

  { id: 'la11-02', t: 'la11', d: 2, k: 'sc', fix: true,
    q: 'Welche Dimension hat der Raum der **symmetrischen** 3 × 3-Matrizen?',
    o: ['6', '9', '3', '5'], a: 0,
    e: 'Frei wählbar sind die Diagonale (3 Einträge) und der Teil oberhalb (3 Einträge). Der Rest ist durch Symmetrie festgelegt. Allgemein n(n + 1)/2.',
    m: 'Dimension = Anzahl frei wählbarer Parameter.', s: 'Skript LinAlg I 4.2.5' },

  { id: 'la11-03', t: 'la11', d: 2, k: 'sc',
    q: 'Ein Vektorraum wird von 4 Vektoren aufgespannt. Kann er 5 linear unabhängige Vektoren enthalten?',
    o: ['Nein, nach dem Austauschlemma von Steinitz gilt m ≤ n', 'Ja, wenn die 4 Vektoren abhängig sind', 'Ja, immer', 'Nur in Funktionenräumen'], a: 0,
    e: 'Steinitz (Lemma 4.26): sind v₁, …, vₘ unabhängig und spannen w₁, …, wₙ den Raum auf, dann ist m ≤ n. Daraus folgt, dass alle Basen gleich gross sind.',
    m: 'Unabhängige Familien sind nie grösser als Erzeugendensysteme.', s: 'Skript LinAlg I 4.2.4, Lemma 4.26' },

  { id: 'la11-04', t: 'la11', d: 2, k: 'sc', fix: true,
    q: 'Welche Dimension hat $\\{p \\in \\R[x] \\mid \\deg p \\le 3,\\ p(1) = 0\\}$?',
    o: ['3', '4', '2', '1'], a: 0,
    e: 'Die Polynome vom Grad ≤ 3 bilden einen Raum der Dimension 4. Die Bedingung p(1) = 0 ist eine einzige lineare Gleichung für die Koeffizienten, sie senkt die Dimension um 1. Basis z. B. x − 1, x² − 1, x³ − 1.',
    m: 'Eine unabhängige lineare Bedingung senkt die Dimension um 1.', s: 'Skript LinAlg I 4.2.5' },

  { id: 'la11-05', t: 'la11', d: 2, k: 'sc',
    q: 'Warum ist der Raum der Polynome vom Grad ≤ 2 isomorph zu ℝ³?',
    o: ['Die Abbildung $a_0 + a_1x + a_2x^2 \\mapsto (a_0, a_1, a_2)$ ist linear und umkehrbar', 'Weil beide unendlich viele Elemente haben', 'Weil Polynome Funktionen ℝ → ℝ sind', 'Weil jedes Polynom vom Grad 2 drei Nullstellen hat'], a: 0,
    e: 'Jeder endlich erzeugte Vektorraum der Dimension m ist isomorph zu ℝᵐ (Theorem 4.34): Koordinaten bezüglich einer Basis.',
    m: 'Koordinaten bezüglich einer Basis = Isomorphismus nach ℝᵐ.', s: 'Skript LinAlg I 4.2.6, Theorem 4.34' },

  { id: 'la11-06', t: 'la11', d: 3, k: 'tf',
    q: 'V ist ein Vektorraum der Dimension n. Wahr oder falsch?',
    rows: [
      ['n Vektoren, die V aufspannen, bilden eine Basis.', true, 'Wären sie abhängig, könnte man einen weglassen und hätte ein kleineres Erzeugendensystem.'],
      ['n linear unabhängige Vektoren bilden eine Basis.', true, 'Würden sie V nicht aufspannen, könnte man sie zu n + 1 unabhängigen ergänzen.'],
      ['V hat genau eine Basis.', false, 'Für n ≥ 1 gibt es unendlich viele.'],
      ['Der Raum {0} hat Dimension 0.', true, 'Die leere Familie ist eine Basis.'],
      ['Jeder Unterraum U ⊊ V hat dim U < n.', true, 'Gleiche Dimension würde U = V erzwingen.']
    ],
    e: 'Bei bekannter Dimension genügt eine der beiden Basiseigenschaften.', m: 'dim bekannt: unabhängig oder erzeugend reicht.', s: 'Skript LinAlg I 4.2.3–4.2.5' },

  { id: 'la11-w1', t: 'la11', d: 2, k: 'w',
    q: 'Bestimme eine Basis und die Dimension von $U = \\{p \\in \\R[x] \\mid \\deg p \\le 3,\\ p(1) = p(-1) = 0\\}$.',
    ans: { k: 'num', v: 2 },
    sol: [
      'Ansatz $p(x) = a_0 + a_1 x + a_2 x^2 + a_3 x^3$.',
      'p(1) = 0: $a_0 + a_1 + a_2 + a_3 = 0$. p(−1) = 0: $a_0 - a_1 + a_2 - a_3 = 0$.',
      'Addieren und subtrahieren: $a_0 + a_2 = 0$ und $a_1 + a_3 = 0$. Freie Parameter a₂, a₃.',
      'Basis: $x^2 - 1$ (a₂ = 1, a₃ = 0) und $x^3 - x$ (a₂ = 0, a₃ = 1). Dimension 2.'
    ],
    res: 'Basis $x^2 - 1,\\ x^3 - x$, dim U = 2',
    m: 'Bedingungen als lineares Gleichungssystem in den Koeffizienten.', s: 'Skript LinAlg I 4.2.3–4.2.5' },

  // ---------------- 4.3 Vier Unterräume, Lösungsraum ----------------
  { id: 'la12-01', t: 'la12', d: 1, k: 'sc', fix: true,
    q: 'A ist eine 3 × 5-Matrix mit Rang 2. Welche Dimension hat N(A)?',
    o: ['3', '2', '1', '5'], a: 0,
    e: 'Rangsatz: dim C(A) + dim N(A) = n = 5. Also 5 − 2 = 3.',
    m: 'Rang + Nullität = Anzahl Spalten.', s: 'Skript LinAlg I 4.3.3, Theorem 4.40' },

  { id: 'la12-02', t: 'la12', d: 2, k: 'sc',
    q: 's ist eine Lösung von Ax = b. Wie sieht die ganze Lösungsmenge aus?',
    o: ['$\\{s + x \\mid x \\in N(A)\\}$', '$\\{s + x \\mid x \\in C(A)\\}$', '$\\{s\\}$', '$N(A)$'], a: 0,
    w: { 3: 'N(A) ist die Lösungsmenge für b = 0.' },
    e: 'Zwei Lösungen unterscheiden sich um ein Element von N(A): A(s′ − s) = b − b = 0 (Theorem 4.42).',
    m: 'Lösungsmenge = spezielle Lösung + Nullraum.', s: 'Skript LinAlg I 4.3.4, Theorem 4.42' },

  { id: 'la12-03', t: 'la12', d: 3, k: 'sc',
    q: 'A ist 5 × 7 mit Rang 3. Welche Dimensionen haben C(A), N(A), R(A) und N(Aᵀ)?',
    o: ['3, 4, 3, 2', '3, 4, 4, 2', '3, 2, 3, 4', '5, 2, 7, 0'], a: 0,
    w: { 1: 'Zeilenrang = Spaltenrang.', 2: 'N(A) ⊆ ℝ⁷, also 7 − 3.' },
    e: 'dim C(A) = dim R(A) = Rang = 3 (Theorem 4.37). N(A) ⊆ ℝ⁷ hat 7 − 3 = 4. N(Aᵀ) ⊆ ℝ⁵ hat 5 − 3 = 2.',
    m: 'Die vier Unterräume: r, n − r, r, m − r.', s: 'Skript LinAlg I 4.3' },

  { id: 'la12-04', t: 'la12', d: 2, k: 'sc',
    q: 'A ist m × n mit Rang r = m. Was gilt für Ax = b?',
    o: ['Für jedes b gibt es mindestens eine Lösung', 'Für jedes b gibt es genau eine Lösung', 'Es gibt höchstens eine Lösung', 'Es gibt nur für b = 0 eine Lösung'], a: 0,
    w: { 1: 'Eindeutig wäre es nur bei r = n.', 2: 'Das gilt bei r = n.' },
    e: 'r = m heisst: C(A) hat Dimension m, also C(A) = ℝᵐ. Jedes b liegt im Spaltenraum. Ist zusätzlich n > m, gibt es unendlich viele Lösungen.',
    m: 'r = m: immer lösbar. r = n: höchstens eine Lösung.', s: 'Skript LinAlg I 4.3.5' },

  { id: 'la12-05', t: 'la12', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Ein unterbestimmtes System (m < n) hat immer unendlich viele Lösungen.', false, 'Es kann auch unlösbar sein, z. B. x + y = 0 und x + y = 1.'],
      ['Hat Ax = b zwei verschiedene Lösungen, hat es unendlich viele.', true, 's + λ(s′ − s) ist für jedes λ eine Lösung.'],
      ['Ax = 0 hat immer mindestens eine Lösung.', true, 'x = 0.'],
      ['Ist A quadratisch mit N(A) = {0}, so ist Ax = b für jedes b eindeutig lösbar.', true, 'Dann ist A invertierbar.'],
      ['Ein überbestimmtes System (m > n) hat nie eine Lösung.', false, 'Es hat eine, wenn b zufällig in C(A) liegt.']
    ],
    e: 'Die Anzahl Lösungen ist immer 0, 1 oder unendlich.', m: '0, 1 oder ∞ Lösungen, nie 2.', s: 'Skript LinAlg I 4.3.4–4.3.5' },

  { id: 'la12-w1', t: 'la12', d: 3, k: 'w',
    q: '$A = \\mat{1,2,0,1;0,0,1,1;1,2,1,2}$. Für welche b ist Ax = b lösbar? Gib für $b = \\vec{1;1;2}$ die vollständige Lösungsmenge an. Wie viele freie Parameter hat sie?',
    ans: { k: 'num', v: 2 },
    sol: [
      'C(A) wird von den unabhängigen Spalten (1, 0, 1) und (0, 1, 1) aufgespannt. Das sind alle (a, b, a + b). Lösbar genau dann, wenn b₃ = b₁ + b₂.',
      'Für b = (1, 1, 2): b = Spalte 1 + Spalte 3, also spezielle Lösung s = (1, 0, 1, 0).',
      'N(A) hat Dimension 4 − 2 = 2 mit Basis (2, −1, 0, 0) und (1, 0, 1, −1).',
      'Lösungsmenge: (1, 0, 1, 0) + λ(2, −1, 0, 0) + μ(1, 0, 1, −1).'
    ],
    res: 'Lösbar ⟺ b₃ = b₁ + b₂. Lösungsmenge mit 2 Parametern.',
    m: 'Spezielle Lösung aus den Spalten ablesen, dann N(A) dazu.', s: 'Skript LinAlg I 4.3.4' },

  // ---------------- II 5.1 Orthogonalität ----------------
  { id: 'la13-01', t: 'la13', d: 1, k: 'sc', fix: true,
    q: 'Welche Dimension hat das orthogonale Komplement von $V = \\{\\lambda (1, 1, 0) \\mid \\lambda \\in \\R\\}$ in ℝ³?',
    o: ['2', '1', '3', '0'], a: 0,
    e: '$\\dim V + \\dim V^\\perp = n$ (Theorem 5.1.7). V^⊥ ist die Ebene x₁ + x₂ = 0.',
    m: 'dim V + dim V^⊥ = n.', s: 'Skript LinAlg II 5.1, Theorem 5.1.7' },

  { id: 'la13-02', t: 'la13', d: 2, k: 'sc',
    q: 'Welche Beziehung gilt für jede Matrix A?',
    o: ['$N(A) = C(A^\\top)^\\perp$', '$N(A) = C(A)^\\perp$', '$C(A) = N(A)^\\perp$', '$R(A) = N(A^\\top)$'], a: 0,
    w: { 1: 'C(A) liegt in ℝᵐ, N(A) in ℝⁿ.', 2: 'Richtig wäre $C(A^\\top) = N(A)^\\perp$.' },
    e: 'Ax = 0 heisst: jede Zeile von A ist orthogonal zu x. Also ist N(A) genau das orthogonale Komplement des Zeilenraums R(A) = C(Aᵀ) (Theorem 5.1.6).',
    m: 'Nullraum ⊥ Zeilenraum.', s: 'Skript LinAlg II 5.1, Theorem 5.1.6' },

  { id: 'la13-03', t: 'la13', d: 2, k: 'sc',
    q: 'Welche Vektoren bilden eine Basis des orthogonalen Komplements von $V = \\{\\lambda (1, 2, 3)\\}$?',
    o: ['$(-2, 1, 0)$ und $(-3, 0, 1)$', '$(1, 2, 3)$', '$(-2, 1, 0)$ allein', '$(2, -1, 0)$ und $(-4, 2, 0)$'], a: 0,
    w: { 2: 'V^⊥ hat Dimension 2.', 3: 'Die beiden sind parallel.' },
    e: 'V^⊥ = {x | x₁ + 2x₂ + 3x₃ = 0}. Mit x₂, x₃ frei: (−2, 1, 0) und (−3, 0, 1). Beide sind orthogonal zu (1, 2, 3) und nicht parallel.',
    m: 'V^⊥ = Nullraum der Matrix, deren Zeilen V aufspannen.', s: 'Skript LinAlg II 5.1' },

  { id: 'la13-04', t: 'la13', d: 2, k: 'sc',
    q: 'Wann ist $A^\\top A$ invertierbar?',
    o: ['Genau dann, wenn A linear unabhängige Spalten hat', 'Immer', 'Genau dann, wenn A quadratisch ist', 'Genau dann, wenn A linear unabhängige Zeilen hat'], a: 0,
    w: { 1: 'Für A = 0 nicht.', 3: 'Für eine 3 × 2-Matrix sind die Zeilen immer abhängig, AᵀA kann trotzdem invertierbar sein.' },
    e: 'N(AᵀA) = N(A) (Lemma 5.1.10). AᵀA ist n × n und genau dann invertierbar, wenn N(A) = {0}, also wenn die Spalten unabhängig sind (Lemma 5.2.4).',
    m: 'AᵀA invertierbar ⟺ A hat vollen Spaltenrang.', s: 'Skript LinAlg II 5.1–5.2, Lemmata 5.1.10 und 5.2.4' },

  { id: 'la13-05', t: 'la13', d: 3, k: 'tf',
    q: 'V, W sind Unterräume von ℝⁿ. Wahr oder falsch?',
    rows: [
      ['$(V^\\perp)^\\perp = V$', true, 'Lemma 5.1.8.'],
      ['Sind V und W orthogonal, so ist V ∩ W = {0}.', true, 'Ein Vektor in beiden ist zu sich selbst orthogonal.'],
      ['Sind V und W orthogonal und dim V + dim W = n, dann ist W = V^⊥.', true, 'Theorem 5.1.7.'],
      ['Zwei Ebenen durch 0 in ℝ³ können orthogonale Unterräume sein.', false, '2 + 2 > 3, orthogonale Unterräume haben dim V + dim W ≤ n.'],
      ['Die x-Achse und die y-Achse in ℝ³ sind orthogonale Komplemente.', false, 'Orthogonal ja, aber das Komplement der x-Achse ist die ganze y-z-Ebene.']
    ],
    e: '„Orthogonal“ und „orthogonales Komplement“ sind nicht dasselbe. Das Komplement ist der grösste orthogonale Unterraum.', m: 'Komplement = alles, was senkrecht steht.', s: 'Skript LinAlg II 5.1' },

  { id: 'la13-w1', t: 'la13', d: 2, k: 'w',
    q: 'Bestimme eine Basis des orthogonalen Komplements von $V = \\text{Span}\\big((1, 1, 1, 1), (1, -1, 1, -1)\\big)$ in ℝ⁴. Gib die Dimension ein.',
    ans: { k: 'num', v: 2 },
    sol: [
      'V^⊥ = N(A) mit den Zeilen (1, 1, 1, 1) und (1, −1, 1, −1).',
      'Zeile 2 − Zeile 1: (0, −2, 0, −2) → (0, 1, 0, 1). Dann Zeile 1 − Zeile 2: (1, 0, 1, 0).',
      'x₁ = −x₃, x₂ = −x₄ mit freien x₃, x₄: Basis (−1, 0, 1, 0) und (0, −1, 0, 1).',
      'Kontrolle: dim V + dim V^⊥ = 2 + 2 = 4.'
    ],
    res: 'Basis (−1, 0, 1, 0), (0, −1, 0, 1), Dimension 2',
    m: 'Komplement berechnen = Nullraum berechnen.', s: 'Skript LinAlg II 5.1' },

  // ---------------- II 5.2 Projektionen ----------------
  { id: 'la14-01', t: 'la14', d: 2, k: 'sc',
    q: 'Was ist die Projektion von $b = (1, 2, 2)$ auf die Gerade durch $a = (1, 1, 0)$?',
    o: ['$(3/2,\\ 3/2,\\ 0)$', '$(3,\\ 3,\\ 0)$', '$(1,\\ 1,\\ 0)$', '$(1/2,\\ 1/2,\\ 0)$'], a: 0,
    w: { 1: 'Man teilt durch aᵀa = 2.' },
    e: '$\\text{proj}(b) = \\frac{a^\\top b}{a^\\top a} a = \\frac{3}{2}(1, 1, 0)$. Kontrolle: b − proj(b) = (−1/2, 1/2, 2) ist orthogonal zu a.',
    m: 'Projektion auf eine Gerade: $\\frac{a^\\top b}{a^\\top a} a$.', s: 'Skript LinAlg II 5.2, Lemma 5.2.2' },

  { id: 'la14-02', t: 'la14', d: 2, k: 'sc',
    q: 'Welche Matrix projiziert ℝ² orthogonal auf die Gerade durch $a = (1, 2)$?',
    o: ['$\\frac{1}{5}\\mat{1,2;2,4}$', '$\\mat{1,2;2,4}$', '$\\frac{1}{5}\\mat{4,-2;-2,1}$', '$\\frac{1}{\\sqrt 5}\\mat{1,2;2,4}$'], a: 0,
    w: { 1: 'Ohne Division durch aᵀa ist P² ≠ P.', 2: 'Das projiziert auf die orthogonale Gerade.' },
    e: '$P = \\frac{aa^\\top}{a^\\top a}$. Es gilt P² = P und Pᵀ = P.',
    m: 'Projektionsmatrix: symmetrisch und idempotent.', s: 'Skript LinAlg II 5.2, Theorem 5.2.5' },

  { id: 'la14-03', t: 'la14', d: 2, k: 'tf',
    q: 'P ist die Projektionsmatrix auf einen Unterraum S von ℝᵐ. Wahr oder falsch?',
    rows: [
      ['$P^2 = P$', true, 'Einmal projiziert, bleibt ein Punkt beim nochmaligen Projizieren liegen.'],
      ['$P^\\top = P$', true, '$P = A(A^\\top A)^{-1}A^\\top$ ist symmetrisch.'],
      ['$b - Pb$ ist orthogonal zu S.', true, 'Das ist genau die Bedingung „nächster Punkt“.'],
      ['$I - P$ projiziert auf $S^\\perp$.', true, 'b = Pb + (I − P)b zerlegt in S und S^⊥.'],
      ['P ist invertierbar.', false, 'Ausser für S = ℝᵐ, sonst wird S^⊥ auf 0 abgebildet.']
    ],
    e: 'Jedes b zerfällt eindeutig in einen Teil in S und einen in S^⊥.', m: 'P² = P, Pᵀ = P.', s: 'Skript LinAlg II 5.2, Remark 5.2.6' },

  { id: 'la14-04', t: 'la14', d: 3, k: 'sc',
    q: 'S ⊆ ℝ⁵ ist ein Unterraum der Dimension 2, P die Projektionsmatrix auf S. Welchen Rang haben P und I − P?',
    o: ['2 und 3', '2 und 5', '5 und 3', '2 und 2'], a: 0,
    e: 'C(P) = S, also Rang 2. I − P projiziert auf S^⊥ mit Dimension 5 − 2 = 3.',
    m: 'Rang einer Projektion = Dimension des Zielraums.', s: 'Skript LinAlg II 5.2' },

  { id: 'la14-05', t: 'la14', d: 2, k: 'sc',
    q: 'Für die Projektion von b auf S = C(A) gilt $\\text{proj}_S(b) = A\\hat{x}$. Welche Gleichung bestimmt $\\hat{x}$?',
    o: ['$A^\\top A \\hat{x} = A^\\top b$', '$A\\hat{x} = b$', '$AA^\\top \\hat{x} = b$', '$\\hat{x} = A^\\top b$'], a: 0,
    w: { 1: 'Die ist oft unlösbar, genau deshalb projiziert man.', 3: 'Nur bei orthonormalen Spalten.' },
    e: 'Normalengleichungen: b − Ax̂ muss orthogonal zu allen Spalten von A sein, also $A^\\top(b - A\\hat{x}) = 0$ (Lemma 5.2.3).',
    m: 'Fehler ⊥ Spaltenraum ⟹ Normalengleichungen.', s: 'Skript LinAlg II 5.2, Lemma 5.2.3' },

  { id: 'la14-w1', t: 'la14', d: 2, k: 'w',
    q: 'Projiziere $b = (1, 2, 0)$ auf die Ebene $S = \\text{Span}\\big((1, 0, 1), (0, 1, 1)\\big)$. Tippe die Projektion ein.',
    ans: { k: 'vec', v: [0, 1, 1], ph: 'p₁, p₂, p₃' },
    sol: [
      '$A = \\mat{1,0;0,1;1,1}$, $A^\\top A = \\mat{2,1;1,2}$, $A^\\top b = \\vec{1;2}$.',
      'Normalengleichungen: 2x̂₁ + x̂₂ = 1, x̂₁ + 2x̂₂ = 2. Lösung x̂ = (0, 1).',
      'Projektion p = Ax̂ = (0, 1, 1).',
      'Kontrolle: b − p = (1, 1, −1) ist orthogonal zu (1, 0, 1) und (0, 1, 1).'
    ],
    res: 'p = (0, 1, 1)',
    m: 'Am Ende immer die Orthogonalität des Fehlers prüfen.', s: 'Skript LinAlg II 5.2' },

  // ---------------- II 6.1 Kleinste Quadrate ----------------
  { id: 'la15-01', t: 'la15', d: 1, k: 'sc',
    q: 'Was minimiert die Kleinste-Quadrate-Lösung $\\hat{x}$ von Ax ≈ b?',
    o: ['$\\lVert Ax - b \\rVert^2$', '$\\lVert x \\rVert^2$', '$\\lVert Ax - b \\rVert_1$', 'die Anzahl Gleichungen mit Fehler ≠ 0'], a: 0,
    e: 'Gesucht ist das x, für das Ax am nächsten an b liegt. Ax̂ ist dann die Projektion von b auf C(A).',
    m: 'Kleinste Quadrate = Projektion auf den Spaltenraum.', s: 'Skript LinAlg II 6.1' },

  { id: 'la15-02', t: 'la15', d: 2, k: 'sc',
    q: 'Wann ist die Kleinste-Quadrate-Lösung eindeutig?',
    o: ['Wenn A linear unabhängige Spalten hat', 'Immer', 'Wenn b ∈ C(A)', 'Wenn A mehr Spalten als Zeilen hat'], a: 0,
    w: { 1: 'Die Projektion ist eindeutig, x̂ aber nur bei N(A) = {0}.', 2: 'Dann ist der Fehler 0, aber x̂ kann trotzdem mehrdeutig sein.' },
    e: 'Dann ist AᵀA invertierbar und $\\hat{x} = (A^\\top A)^{-1}A^\\top b$ (Fact 6.1.1).',
    m: 'Eindeutig ⟺ volle Spaltenrang.', s: 'Skript LinAlg II 6.1, Fact 6.1.1' },

  { id: 'la15-03', t: 'la15', d: 3, k: 'sc',
    q: 'Man passt eine Gerade $b \\approx \\alpha_0 + \\alpha_1 t$ an Messpunkte $(t_k, b_k)$ an. Wann sind die beiden Spalten von A abhängig?',
    o: ['Genau dann, wenn alle $t_k$ gleich sind', 'Wenn zwei $t_k$ gleich sind', 'Wenn alle $b_k$ gleich sind', 'Nie'], a: 0,
    w: { 1: 'Ein einziges anderes $t_k$ reicht schon für Unabhängigkeit.', 2: 'b spielt für die Spalten von A keine Rolle.' },
    e: 'Die Spalten sind (1, …, 1) und (t₁, …, tₘ). Sie sind abhängig, wenn der zweite Vektor ein Vielfaches des ersten ist, also alle tₖ gleich (Lemma 6.1.2).',
    m: 'Gerade durch Messpunkte: eindeutig, sobald zwei verschiedene t-Werte vorkommen.', s: 'Skript LinAlg II 6.1, Lemma 6.1.2' },

  { id: 'la15-04', t: 'la15', d: 2, k: 'sc',
    q: 'Kann man mit Kleinsten Quadraten auch eine Parabel $b \\approx \\alpha_0 + \\alpha_1 t + \\alpha_2 t^2$ anpassen?',
    o: ['Ja, das Modell ist linear in den Koeffizienten α₀, α₁, α₂', 'Nein, die Parabel ist nicht linear in t', 'Nur wenn alle tₖ positiv sind', 'Nur mit genau drei Messpunkten'], a: 0,
    e: 'A hat dann die Spalten (1), (tₖ), (tₖ²). Entscheidend ist Linearität in den Unbekannten, nicht in t (Beispiel 6.1.4).',
    m: 'Linear in den Parametern reicht.', s: 'Skript LinAlg II 6.1, Example 6.1.4' },

  { id: 'la15-05', t: 'la15', d: 3, k: 'sc',
    q: 'Warum verschiebt man bei der Geradenanpassung gern die Zeiten so, dass $\\sum_k t_k = 0$ gilt?',
    o: ['Dann sind die Spalten von A orthogonal und $A^\\top A$ ist diagonal', 'Dann ist der Fehler 0', 'Dann ist A quadratisch', 'Dann werden alle bₖ positiv'], a: 0,
    e: 'Das Skalarprodukt der Spalten (1, …, 1) und (t₁, …, tₘ) ist $\\sum t_k$. Ist es 0, wird AᵀA diagonal, und die Normalengleichungen zerfallen in zwei einzelne Gleichungen (Remark 6.1.3).',
    m: 'Orthogonale Spalten machen AᵀA diagonal.', s: 'Skript LinAlg II 6.1, Remark 6.1.3' },

  { id: 'la15-w1', t: 'la15', d: 1, k: 'w',
    q: 'Bestimme die Ausgleichsgerade $b = \\alpha_0 + \\alpha_1 t$ durch die Punkte (0, 0), (1, 1), (2, 1). Tippe „α₀, α₁“ ein.',
    ans: { k: 'vec', v: [1 / 6, 1 / 2], ph: 'α₀, α₁' },
    sol: [
      '$A = \\mat{1,0;1,1;1,2}$, $b = \\vec{0;1;1}$.',
      '$A^\\top A = \\mat{3,3;3,5}$, $A^\\top b = \\vec{2;3}$.',
      '3α₀ + 3α₁ = 2 und 3α₀ + 5α₁ = 3. Subtrahieren: 2α₁ = 1, also α₁ = 1/2, dann α₀ = 1/6.',
      'Kontrolle: Residuen (−1/6, 1/3, −1/6) haben Summe 0 und sind orthogonal zu (0, 1, 2).'
    ],
    res: '$b = \\frac{1}{6} + \\frac{1}{2}t$',
    m: 'Residuum ⊥ Spalten von A ist die Kontrolle.', s: 'Skript LinAlg II 6.1' },

  { id: 'la15-w2', t: 'la15', d: 3, k: 'w',
    q: 'Passe eine Gerade an die Punkte (−1, 0), (0, 1), (1, 1), (2, 3) an. Tippe „α₀, α₁“ ein.',
    ans: { k: 'vec', v: [0.8, 0.9], ph: 'α₀, α₁' },
    sol: [
      '$A^\\top A = \\mat{4,\\sum t;\\sum t,\\sum t^2} = \\mat{4,2;2,6}$.',
      '$A^\\top b = \\vec{\\sum b;\\sum tb} = \\vec{5;7}$ (0 + 1 + 1 + 3 und 0 + 0 + 1 + 6).',
      '4α₀ + 2α₁ = 5 und 2α₀ + 6α₁ = 7. Erste Gleichung mal 3 minus zweite: 10α₀ = 8.',
      'α₀ = 4/5, α₁ = (5 − 16/5)/2 = 9/10.'
    ],
    res: '$b = 0.8 + 0.9\\,t$',
    m: 'Für Geraden: AᵀA aus Σ1, Σt, Σt² zusammensetzen.', s: 'Skript LinAlg II 6.1' },

  // ---------------- II 6.2 Lösungsmengen, Zertifikate ----------------
  { id: 'la16-01', t: 'la16', d: 2, k: 'sc',
    q: 'Ax = b sei lösbar. Was sagt Theorem 6.2.2 über die Lösungsmenge?',
    o: ['Sie ist $x_1 + N(A)$ mit einem **eindeutigen** $x_1 \\in R(A)$', 'Sie ist $R(A)$', 'Sie enthält genau einen Vektor aus N(A)', 'Sie ist ein Unterraum'], a: 0,
    w: { 3: 'Für b ≠ 0 enthält sie den Nullvektor nicht.' },
    e: 'Jede Lösung zerfällt in einen Teil in R(A) und einen in N(A) = R(A)^⊥. Der Teil in R(A) ist für alle Lösungen derselbe (Lemma 6.2.1: A ist auf R(A) injektiv).',
    m: 'Genau eine Lösung liegt im Zeilenraum.', s: 'Skript LinAlg II 6.2, Theorem 6.2.2' },

  { id: 'la16-02', t: 'la16', d: 2, k: 'sc',
    q: 'Das System $x_1 + x_2 = 1$, $2x_1 + 2x_2 = 3$ ist unlösbar. Welches z ist ein Unlösbarkeitszertifikat ($A^\\top z = 0$, $b^\\top z = 1$)?',
    o: ['$z = (-2, 1)$', '$z = (2, -1)$', '$z = (1, 1)$', '$z = (1, -1/2)$'], a: 0,
    w: { 1: 'bᵀz = 2 − 3 = −1, nicht 1.', 2: 'Aᵀz = (3, 3) ≠ 0.', 3: 'bᵀz = 1 − 3/2 = −1/2.' },
    e: 'Aᵀz = (−2 + 2, −2 + 2) = 0 und bᵀz = −2 + 3 = 1. Das ist −2 mal Gleichung 1 plus Gleichung 2: links 0, rechts 1.',
    m: 'Zertifikat = Kombination der Gleichungen, die „0 = 1“ ergibt.', s: 'Skript LinAlg II 6.2, Theorem 6.2.4' },

  { id: 'la16-03', t: 'la16', d: 3, k: 'sc',
    q: 'Warum können Ax = b und $\\{A^\\top z = 0,\\ b^\\top z = 1\\}$ **nicht beide** lösbar sein?',
    o: ['Sonst wäre $1 = b^\\top z = (Ax)^\\top z = x^\\top A^\\top z = 0$', 'Weil A sonst invertierbar wäre', 'Weil z dann im Nullraum von A liegt', 'Weil b dann 0 sein müsste'], a: 0,
    e: 'Das ist die einfache Richtung von Theorem 6.2.4. Die schwierige Richtung ist, dass immer eines der beiden lösbar ist. Sie folgt aus b ∉ C(A) = N(Aᵀ)^⊥.',
    m: 'Zertifikate sind leicht zu prüfen.', s: 'Skript LinAlg II 6.2, Theorem 6.2.4' },

  { id: 'la16-04', t: 'la16', d: 3, k: 'tf',
    q: 'Ax = b ist lösbar. Wahr oder falsch?',
    rows: [
      ['Die Lösung im Zeilenraum R(A) ist die Lösung mit kleinster Norm.', true, 'Jede andere Lösung ist x₁ + n mit n ⊥ x₁, also grösser (Pythagoras).'],
      ['Es gibt genau eine Lösung in C(AᵀA).', true, 'Korollar 6.2.3, denn C(AᵀA) = C(Aᵀ).'],
      ['Jede Lösung liegt in R(A).', false, 'Nur genau eine, ausser N(A) = {0}.'],
      ['Ist N(A) = {0}, gibt es genau eine Lösung.', true, 'Die Lösungsmenge ist x₁ + {0}.']
    ],
    e: 'Zerlegung ℝⁿ = R(A) ⊕ N(A) mit orthogonalen Teilen.', m: 'Minimale Norm ⟺ im Zeilenraum.', s: 'Skript LinAlg II 6.2' },

  { id: 'la16-w1', t: 'la16', d: 2, k: 'w',
    q: 'Zeige mit einem Zertifikat, dass $x_1 + x_2 - x_3 = 2$, $2x_1 + 2x_2 - 2x_3 = 5$ keine Lösung hat. Tippe z ein.',
    ans: { k: 'vec', v: [-2, 1], ph: 'z₁, z₂' },
    sol: [
      'Gesucht: z mit Aᵀz = 0 und bᵀz = 1.',
      'Die zweite Zeile ist das Doppelte der ersten, also −2 · Zeile 1 + Zeile 2 = 0: z = (−2, 1) liefert Aᵀz = 0.',
      'bᵀz = −4 + 5 = 1.',
      'Gäbe es eine Lösung x, dann 1 = bᵀz = xᵀAᵀz = 0, Widerspruch.'
    ],
    res: 'z = (−2, 1)',
    m: 'Zertifikat: Linearkombination der Zeilen, die links 0 und rechts ≠ 0 ergibt (dann normieren).', s: 'Skript LinAlg II 6.2, Theorem 6.2.4' },

  { id: 'la16-w2', t: 'la16', d: 3, k: 'w',
    q: '$A = \\mat{1,1,0;0,1,1}$, $b = \\vec{3;5}$. Bestimme die Lösungsmenge und die eindeutige Lösung $x_1 \\in R(A)$. Tippe $x_1$ ein.',
    ans: { k: 'vec', v: [1 / 3, 8 / 3, 7 / 3], ph: 'x₁, x₂, x₃' },
    sol: [
      'RREF: (1, 0, −1 | −2), (0, 1, 1 | 5). Mit x₃ = t: x = (−2, 5, 0) + t(1, −1, 1). N(A) = Span(1, −1, 1).',
      'x liegt in R(A) = N(A)^⊥ genau dann, wenn x · (1, −1, 1) = 0.',
      '(−2 + t) − (5 − t) + t = 3t − 7 = 0, also t = 7/3.',
      'x₁ = (1/3, 8/3, 7/3). Kontrolle: Ax₁ = (3, 5).'
    ],
    res: '$x_1 = (1/3,\\ 8/3,\\ 7/3)$, die Lösung mit kleinster Norm',
    m: 'Die Zeilenraum-Lösung ist orthogonal zum Nullraum.', s: 'Skript LinAlg II 6.2, Theorem 6.2.2' },

  // ---------------- II 6.3 Pseudoinverse ----------------
  { id: 'la17-01', t: 'la17', d: 1, k: 'sc',
    q: 'Wie ist die Pseudoinverse für eine Matrix A mit **vollem Spaltenrang** definiert?',
    o: ['$A^\\dagger = (A^\\top A)^{-1}A^\\top$', '$A^\\dagger = A^\\top(AA^\\top)^{-1}$', '$A^\\dagger = A^{-1}$', '$A^\\dagger = A^\\top$'], a: 0,
    w: { 1: 'Das ist die Formel für vollen Zeilenrang.', 2: 'A ist im Allgemeinen nicht quadratisch.' },
    e: 'Bei vollem Spaltenrang ist AᵀA invertierbar. Dann ist A† eine Linksinverse: A†A = I (Proposition 6.3.2).',
    m: 'Voller Spaltenrang: links. Voller Zeilenrang: rechts.', s: 'Skript LinAlg II 6.3, Definition 6.3.1' },

  { id: 'la17-02', t: 'la17', d: 2, k: 'sc',
    q: 'Was ist die Pseudoinverse der 2 × 1-Matrix $a = \\vec{1;2}$?',
    o: ['$\\frac{1}{5}(1,\\ 2)$', '$(1,\\ 1/2)$', '$\\frac{1}{\\sqrt 5}(1,\\ 2)$', '$\\frac{1}{5}\\vec{1;2}$'], a: 0,
    w: { 1: 'Eintragsweise invertieren ist falsch.', 3: 'A† ist 1 × 2, also ein Zeilenvektor.' },
    e: '$a^\\dagger = (a^\\top a)^{-1}a^\\top = \\frac{1}{5}(1, 2)$. Kontrolle: $a^\\dagger a = \\frac{1}{5}(1 + 4) = 1$.',
    m: 'A† hat die Form n × m.', s: 'Skript LinAlg II 6.3' },

  { id: 'la17-03', t: 'la17', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Für invertierbares A ist $A^\\dagger = A^{-1}$.', true, 'Dann haben beide Formeln den Wert A⁻¹.'],
      ['$AA^\\dagger$ ist die Projektionsmatrix auf C(A).', true, 'Theorem 6.3.10.'],
      ['$A^\\dagger A = I$ für jede Matrix A.', false, 'Nur bei vollem Spaltenrang. Allgemein ist A†A die Projektion auf C(Aᵀ).'],
      ['$AA^\\dagger A = A$', true, 'Theorem 6.3.10.'],
      ['Bei vollem Zeilenrang liefert $A^\\dagger b$ die Lösung von Ax = b mit kleinster Norm.', true, 'Proposition 6.3.6.']
    ],
    e: 'Die Pseudoinverse verallgemeinert die Inverse: sie löst, was lösbar ist, und projiziert den Rest.', m: 'AA† projiziert auf C(A), A†A auf C(Aᵀ).', s: 'Skript LinAlg II 6.3' },

  { id: 'la17-04', t: 'la17', d: 3, k: 'sc',
    q: 'Was ist die Pseudoinverse von $\\mat{1,0;0,0}$?',
    o: ['$\\mat{1,0;0,0}$', 'existiert nicht', '$\\mat{1,0;0,1}$', '$\\mat{0,0;0,1}$'], a: 0,
    w: { 1: 'Jede Matrix hat eine Pseudoinverse (Definition 6.3.7).' },
    e: 'CR-Zerlegung: C = (1, 0)ᵀ, R = (1, 0). Beide haben Pseudoinverse (1, 0) bzw. (1, 0)ᵀ. A† = R†C† = (1, 0)ᵀ(1, 0) = A. Kontrolle: AA†A = A.',
    m: 'Allgemein: A = CR, A† = R†C†.', s: 'Skript LinAlg II 6.3, Definition 6.3.7' },

  { id: 'la17-w1', t: 'la17', d: 3, k: 'w',
    q: 'Berechne die Pseudoinverse von $A = \\mat{1,1,0;0,1,1}$ (voller Zeilenrang) und damit $A^\\dagger b$ für $b = \\vec{3;5}$. Tippe $A^\\dagger b$ ein.',
    ans: { k: 'vec', v: [1 / 3, 8 / 3, 7 / 3], ph: 'x₁, x₂, x₃' },
    sol: [
      '$AA^\\top = \\mat{2,1;1,2}$, $(AA^\\top)^{-1} = \\frac{1}{3}\\mat{2,-1;-1,2}$.',
      '$A^\\dagger = A^\\top(AA^\\top)^{-1} = \\frac{1}{3}\\mat{2,-1;1,1;-1,2}$.',
      '$A^\\dagger b = \\frac{1}{3}(6 - 5,\\ 3 + 5,\\ -3 + 10) = (1/3,\\ 8/3,\\ 7/3)$.',
      'Das ist genau die Lösung im Zeilenraum, also die mit kleinster Norm.'
    ],
    res: '$A^\\dagger b = (1/3,\\ 8/3,\\ 7/3)$',
    m: 'Voller Zeilenrang: $A^\\dagger = A^\\top(AA^\\top)^{-1}$.', s: 'Skript LinAlg II 6.3, Definition 6.3.3' },

  { id: 'la17-w2', t: 'la17', d: 3, k: 'w',
    q: 'Berechne die Pseudoinverse von $A = \\mat{1,1;1,1}$ über die CR-Zerlegung. Tippe den Eintrag oben links von $A^\\dagger$ ein.',
    ans: { k: 'num', v: 0.25 },
    sol: [
      'A hat Rang 1: C = (1, 1)ᵀ, R = (1, 1).',
      '$C^\\dagger = (C^\\top C)^{-1}C^\\top = \\frac{1}{2}(1, 1)$, $R^\\dagger = R^\\top(RR^\\top)^{-1} = \\frac{1}{2}\\vec{1;1}$.',
      '$A^\\dagger = R^\\dagger C^\\dagger = \\frac{1}{4}\\mat{1,1;1,1}$.',
      'Kontrolle: $AA^\\dagger = \\frac{1}{2}\\mat{1,1;1,1}$ ist die Projektion auf Span(1, 1), und $AA^\\dagger A = \\frac{1}{2}\\mat{2,2;2,2} = A$.'
    ],
    res: '$A^\\dagger = \\frac{1}{4}\\mat{1,1;1,1}$',
    m: 'A† = R†C† mit den beiden Rang-voll-Formeln.', s: 'Skript LinAlg II 6.3, Definition 6.3.7' }
]);
