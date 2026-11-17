// LinAlg Teil 1: Kapitel 1–3 (Vektoren, Matrizen, Gleichungssysteme)
QUIZ.add('la', [
  // ---------------- 1.1 Vektoren und Linearkombinationen ----------------
  { id: 'la1-01', t: 'la1', d: 1, k: 'sc',
    q: 'Was ist $2\\vec{1;-2} + 3\\vec{0;1}$?',
    o: ['$\\vec{2;-1}$', '$\\vec{2;-7}$', '$\\vec{5;-1}$', '$\\vec{2;1}$'], a: 0,
    e: 'Komponentenweise: $2 \\cdot 1 + 3 \\cdot 0 = 2$ und $2 \\cdot (-2) + 3 \\cdot 1 = -1$.',
    m: 'Vektoren werden komponentenweise addiert und skaliert.', s: 'Skript LinAlg I 1.1' },

  { id: 'la1-02', t: 'la1', d: 2, k: 'sc',
    q: 'Mit welchen Koeffizienten ist $\\vec{5;1} = \\lambda \\vec{1;1} + \\mu \\vec{2;-1}$?',
    o: ['$\\lambda = 7/3,\\ \\mu = 4/3$', '$\\lambda = 3,\\ \\mu = 1$', '$\\lambda = 1,\\ \\mu = 2$', 'Es gibt keine, die Vektoren sind parallel'], a: 0,
    w: { 1: '3 + 2 = 5, aber 3 − 1 = 2 ≠ 1.', 3: '(1, 1) und (2, −1) sind nicht parallel.' },
    e: 'λ + 2μ = 5 und λ − μ = 1. Subtrahieren: 3μ = 4, also μ = 4/3 und λ = 7/3.',
    m: 'Linearkombination finden = kleines Gleichungssystem lösen.', s: 'Skript LinAlg I 1.1.3' },

  { id: 'la1-03', t: 'la1', d: 2, k: 'mc',
    q: 'Welche Vektoren sind Linearkombinationen von $\\vec{1;0;1}$ und $\\vec{0;1;1}$? Wähle alle.',
    o: ['$\\vec{2;3;5}$', '$\\vec{1;1;1}$', '$\\vec{0;0;0}$', '$\\vec{-1;2;1}$', '$\\vec{1;2;4}$'], a: [0, 2, 3],
    w: { 1: 'Die dritte Komponente müsste 1 + 1 = 2 sein.', 4: 'Die dritte Komponente müsste 3 sein.' },
    e: 'λ(1, 0, 1) + μ(0, 1, 1) = (λ, μ, λ + μ). Genau die Vektoren, deren dritte Komponente die Summe der ersten beiden ist.',
    m: 'Allgemeine Linearkombination aufschreiben, dann Bedingung ablesen.', s: 'Skript LinAlg I 1.1.3' },

  { id: 'la1-04', t: 'la1', d: 1, k: 'sc',
    q: 'Ist jeder Vektor in ℝ² eine Linearkombination von $\\vec{2;3}$ und $\\vec{4;6}$?',
    o: ['Nein, beide liegen auf derselben Geraden durch 0', 'Ja, zwei Vektoren spannen immer ℝ² auf', 'Ja, weil beide nicht 0 sind', 'Nur die Vektoren mit positiven Einträgen'], a: 0,
    e: '(4, 6) = 2 · (2, 3). Alle Linearkombinationen sind Vielfache von (2, 3) und liegen auf einer Geraden. (1, 0) etwa erreicht man nicht.',
    m: 'Zwei Vektoren spannen ℝ² nur auf, wenn sie nicht parallel sind.', s: 'Skript LinAlg I 1.1, Fact 1.5' },

  { id: 'la1-w1', t: 'la1', d: 1, k: 'w',
    q: 'Schreibe $\\vec{4;7}$ als Linearkombination von $\\vec{1;2}$ und $\\vec{1;-1}$. Tippe die Koeffizienten „λ, μ“ ein.',
    ans: { k: 'vec', v: [11 / 3, 1 / 3], ph: 'λ, μ' },
    sol: [
      'Ansatz: λ(1, 2) + μ(1, −1) = (4, 7), also λ + μ = 4 und 2λ − μ = 7.',
      'Addieren: 3λ = 11, also λ = 11/3.',
      'μ = 4 − 11/3 = 1/3.',
      'Probe: 11/3 + 1/3 = 4 und 22/3 − 1/3 = 7.'
    ],
    res: 'λ = 11/3, μ = 1/3',
    m: 'Eindeutig, weil die beiden Vektoren nicht parallel sind.', s: 'Skript LinAlg I 1.1.3' },

  // ---------------- 1.2 Skalarprodukt, Norm, Winkel ----------------
  { id: 'la2-01', t: 'la2', d: 1, k: 'sc', fix: true,
    q: 'Was ist $\\vec{1;2;3} \\cdot \\vec{4;-5;6}$?',
    o: ['12', '32', '−12', '0'], a: 0,
    e: '1 · 4 + 2 · (−5) + 3 · 6 = 4 − 10 + 18 = 12.',
    m: 'Skalarprodukt: komponentenweise multiplizieren, dann addieren.', s: 'Skript LinAlg I 1.2.1' },

  { id: 'la2-02', t: 'la2', d: 1, k: 'sc', fix: true,
    q: 'Was ist $\\lVert (3, 4, 12) \\rVert$?',
    o: ['13', '19', '169', '$\\sqrt{19}$'], a: 0,
    w: { 1: 'Das ist die Summe der Einträge.', 2: 'Das ist $\\lVert v \\rVert^2$.' },
    e: '$\\sqrt{9 + 16 + 144} = \\sqrt{169} = 13$.',
    m: '$\\lVert v \\rVert = \\sqrt{v \\cdot v}$', s: 'Skript LinAlg I 1.2.2' },

  { id: 'la2-03', t: 'la2', d: 1, k: 'sc',
    q: 'Welcher Einheitsvektor zeigt in Richtung $\\vec{2;-1;2}$?',
    o: ['$\\frac{1}{3}\\vec{2;-1;2}$', '$\\frac{1}{9}\\vec{2;-1;2}$', '$\\frac{1}{5}\\vec{2;-1;2}$', '$\\vec{1;-1;1}$'], a: 0,
    w: { 1: 'Man teilt durch die Norm, nicht durch ihr Quadrat.' },
    e: 'Die Norm ist $\\sqrt{4 + 1 + 4} = 3$. Teilt man durch die Norm, erhält man Länge 1.',
    m: 'Normieren: $v / \\lVert v \\rVert$ für v ≠ 0.', s: 'Skript LinAlg I 1.2.2' },

  { id: 'la2-04', t: 'la2', d: 2, k: 'sc', fix: true,
    q: 'Für welches t sind $\\vec{1;t;2}$ und $\\vec{t;3;-1}$ orthogonal?',
    o: ['t = 1/2', 't = 2', 't = −1/2', 'für kein t'], a: 0,
    e: 'Skalarprodukt: t + 3t − 2 = 4t − 2 = 0, also t = 1/2.',
    m: 'Orthogonal ⟺ Skalarprodukt 0.', s: 'Skript LinAlg I 1.2.4, Definition 1.13' },

  { id: 'la2-05', t: 'la2', d: 2, k: 'sc',
    q: 'Wann gilt in der Cauchy-Schwarz-Ungleichung $|v \\cdot w| \\le \\lVert v \\rVert \\lVert w \\rVert$ Gleichheit?',
    o: ['Genau dann, wenn ein Vektor ein Vielfaches des anderen ist', 'Genau dann, wenn v und w orthogonal sind', 'Nur für v = w', 'Nie, die Ungleichung ist strikt'], a: 0,
    w: { 1: 'Dann ist die linke Seite 0, also meistens strikt kleiner.' },
    e: 'Lemma 1.10: Gleichheit genau dann, wenn v und w linear abhängig sind. Dann ist der Winkel 0 oder π.',
    m: 'Cauchy-Schwarz macht den Winkel überhaupt erst definierbar: $-1 \\le \\cos\\alpha \\le 1$.', s: 'Skript LinAlg I 1.2.3, Lemma 1.10' },

  { id: 'la2-06', t: 'la2', d: 3, k: 'sc', fix: true,
    q: 'Es gilt $\\lVert v \\rVert = 3$, $\\lVert w \\rVert = 4$ und $v \\cdot w = 6$. Was ist $\\lVert v - w \\rVert$?',
    o: ['$\\sqrt{13}$', '1', '5', '$\\sqrt{37}$'], a: 0,
    w: { 1: 'Normen kann man nicht einfach subtrahieren.', 2: 'Das wäre bei Orthogonalität richtig.', 3: 'Das wäre $\\lVert v + w \\rVert$.' },
    e: '$\\lVert v - w \\rVert^2 = (v - w) \\cdot (v - w) = \\lVert v \\rVert^2 - 2 v \\cdot w + \\lVert w \\rVert^2 = 9 - 12 + 16 = 13$.',
    m: 'Normen über das Skalarprodukt ausmultiplizieren.', s: 'Skript LinAlg I 1.2, Observation 1.8' },

  { id: 'la2-07', t: 'la2', d: 3, k: 'tf',
    q: 'v, w ∈ ℝᵐ. Wahr oder falsch?',
    rows: [
      ['$\\lVert v + w \\rVert \\le \\lVert v \\rVert + \\lVert w \\rVert$', true, 'Dreiecksungleichung (Lemma 1.15).'],
      ['$\\lVert v + w \\rVert^2 = \\lVert v \\rVert^2 + \\lVert w \\rVert^2$ genau dann, wenn v · w = 0.', true, 'Der gemischte Term 2 v · w verschwindet genau dann.'],
      ['$\\lVert \\lambda v \\rVert = \\lambda \\lVert v \\rVert$ für alle λ ∈ ℝ.', false, 'Richtig ist |λ| · ‖v‖, für negative λ unterscheidet sich das.'],
      ['Aus v · w = v · u folgt w = u.', false, 'v = 0 ist ein Gegenbeispiel, oder w − u orthogonal zu v.'],
      ['$v \\cdot v = 0$ gilt nur für v = 0.', true, 'Summe von Quadraten.']
    ],
    e: 'Viele Fehler entstehen, wenn man das Skalarprodukt wie eine Zahlenmultiplikation behandelt: man kann nicht durch v kürzen.', m: 'Skalarprodukt: kein Kürzen.', s: 'Skript LinAlg I 1.2' },

  { id: 'la2-w1', t: 'la2', d: 1, k: 'w',
    q: 'Berechne den Winkel zwischen $\\vec{1;1;0}$ und $\\vec{1;0;1}$ in Grad.',
    ans: { k: 'num', v: 60 },
    sol: [
      'Skalarprodukt: 1 · 1 + 1 · 0 + 0 · 1 = 1.',
      'Normen: beide $\\sqrt{2}$.',
      '$\\cos\\alpha = \\frac{1}{\\sqrt{2} \\cdot \\sqrt{2}} = \\frac{1}{2}$, also α = 60°.'
    ],
    res: 'α = 60° (π/3)',
    m: '$\\cos\\alpha = \\frac{v \\cdot w}{\\lVert v \\rVert \\lVert w \\rVert}$', s: 'Skript LinAlg I 1.2.4' },

  { id: 'la2-w2', t: 'la2', d: 2, k: 'w',
    q: 'Beweise die Parallelogrammgleichung: $\\lVert v + w \\rVert^2 + \\lVert v - w \\rVert^2 = 2\\lVert v \\rVert^2 + 2\\lVert w \\rVert^2$.',
    sol: [
      '$\\lVert v + w \\rVert^2 = v \\cdot v + 2 v \\cdot w + w \\cdot w$ (Bilinearität und Symmetrie).',
      '$\\lVert v - w \\rVert^2 = v \\cdot v - 2 v \\cdot w + w \\cdot w$.',
      'Addieren: die gemischten Terme heben sich auf, es bleibt $2 v \\cdot v + 2 w \\cdot w$.'
    ],
    res: 'Die Summe der Quadrate der Diagonalen ist die Summe der Quadrate der vier Seiten.',
    m: 'Normquadrate immer als Skalarprodukte ausschreiben.', s: 'Skript LinAlg I 1.2, Observation 1.8' },

  // ---------------- 1.3 Lineare Unabhängigkeit, Span ----------------
  { id: 'la3-01', t: 'la3', d: 1, k: 'sc',
    q: 'Sind $\\vec{1;0;1}$, $\\vec{0;1;1}$, $\\vec{1;1;2}$ linear unabhängig?',
    o: ['Nein, der dritte ist die Summe der ersten beiden', 'Ja', 'Nein, weil sie in ℝ³ liegen', 'Ja, weil keiner ein Vielfaches eines anderen ist'], a: 0,
    w: { 3: 'Paarweise nicht parallel reicht nicht für Unabhängigkeit von drei Vektoren.' },
    e: 'Abhängig heisst: mindestens einer ist eine Linearkombination der anderen. Hier ist (1, 1, 2) = (1, 0, 1) + (0, 1, 1).',
    m: 'Paarweise nicht parallel ≠ linear unabhängig.', s: 'Skript LinAlg I 1.3.1' },

  { id: 'la3-02', t: 'la3', d: 2, k: 'sc', fix: true,
    q: 'Für welches t sind $\\vec{1;1;0}$, $\\vec{0;1;1}$, $\\vec{1;0;t}$ linear abhängig?',
    o: ['t = −1', 't = 1', 't = 0', 'für kein t'], a: 0,
    e: 'Ansatz (1, 0, t) = a(1, 1, 0) + b(0, 1, 1): erste Komponente a = 1, zweite a + b = 0, also b = −1, dritte t = b = −1. Die ersten beiden Vektoren sind unabhängig, also ist das der einzige Fall.',
    m: 'Prüfen, ob der neue Vektor im Span der anderen liegt.', s: 'Skript LinAlg I 1.3' },

  { id: 'la3-03', t: 'la3', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Eine Familie, die den Nullvektor enthält, ist linear abhängig.', true, '0 ist Linearkombination der anderen (alle Koeffizienten 0).'],
      ['Sind u, v unabhängig und v, w unabhängig, dann sind u, v, w unabhängig.', false, 'u = (1, 0), v = (0, 1), w = (1, 1).'],
      ['Vier Vektoren in ℝ³ sind immer linear abhängig.', true, 'Höchstens m unabhängige Vektoren in ℝᵐ.'],
      ['Sind v₁, …, vₙ unabhängig, so ist jede Linearkombination eindeutig.', true, 'Lemma 1.22.'],
      ['Liegt v im Span von v₁, …, vₙ, dann ist Span(v₁, …, vₙ, v) grösser als Span(v₁, …, vₙ).', false, 'Gleich gross (Lemma 1.24).']
    ],
    e: 'Lineare Unabhängigkeit ist eine Eigenschaft der ganzen Familie, nicht von Paaren.', m: 'Unabhängig ⟺ nur die triviale Kombination ergibt 0.', s: 'Skript LinAlg I 1.3' },

  { id: 'la3-04', t: 'la3', d: 2, k: 'sc',
    q: 'Welche Aussage ist **äquivalent** zu „v₁, …, vₙ sind linear unabhängig“?',
    o: ['Aus $\\sum \\lambda_j v_j = 0$ folgt $\\lambda_1 = \\ldots = \\lambda_n = 0$', 'Kein vⱼ ist der Nullvektor', 'Je zwei der Vektoren sind nicht parallel', 'Die Vektoren spannen ℝⁿ auf'], a: 0,
    w: { 1: 'Notwendig, aber nicht hinreichend.', 2: 'Notwendig, aber nicht hinreichend.', 3: 'Die Vektoren können in einem anderen ℝᵐ liegen.' },
    e: 'Das ist Korollar 1.21 (ii): nur die triviale Linearkombination ergibt den Nullvektor. Diese Formulierung ist meistens am einfachsten nachzuprüfen.',
    m: 'Standardtest: nur die triviale Lösung für $\\sum \\lambda_j v_j = 0$.', s: 'Skript LinAlg I 1.3.2, Korollar 1.21' },

  { id: 'la3-w1', t: 'la3', d: 2, k: 'w',
    q: 'Beweise: Sind v₁, …, vₙ linear unabhängig und liegt v **nicht** im Span von v₁, …, vₙ, dann sind auch v₁, …, vₙ, v linear unabhängig.',
    sol: [
      'Angenommen $\\lambda_1 v_1 + \\ldots + \\lambda_n v_n + \\mu v = 0$.',
      'Fall μ ≠ 0: dann ist $v = -\\frac{1}{\\mu}(\\lambda_1 v_1 + \\ldots + \\lambda_n v_n)$ im Span, Widerspruch.',
      'Also μ = 0, und dann $\\lambda_1 v_1 + \\ldots + \\lambda_n v_n = 0$. Wegen der Unabhängigkeit sind alle λⱼ = 0.',
      'Nur die triviale Kombination ergibt 0, also unabhängig.'
    ],
    res: 'Fallunterscheidung nach dem Koeffizienten von v.',
    m: 'So wächst eine unabhängige Familie Schritt für Schritt.', s: 'Skript LinAlg I 1.3' },

  // ---------------- 2.1 Spaltenraum, Rang, Nullraum ----------------
  { id: 'la4-01', t: 'la4', d: 1, k: 'sc', fix: true,
    q: 'Welchen Rang hat $\\mat{1,2,3;2,4,6}$?',
    o: ['1', '2', '3', '0'], a: 0,
    e: 'Die zweite und dritte Spalte sind Vielfache der ersten. Nur die erste Spalte ist unabhängig.',
    m: 'Rang = Anzahl unabhängiger Spalten.', s: 'Skript LinAlg I 2.1.2, Definition 2.10' },

  { id: 'la4-02', t: 'la4', d: 2, k: 'sc',
    q: 'Welche Spalten von $A = \\mat{1,2,0,1;0,0,1,1;1,2,1,2}$ sind im Sinne des Skripts **unabhängig** (keine Linearkombination der vorherigen Spalten)?',
    o: ['Spalten 1 und 3', 'Spalten 1, 2 und 3', 'Spalten 1 und 2', 'Spalten 3 und 4'], a: 0,
    w: { 1: 'Spalte 2 = 2 · Spalte 1.', 3: 'Die Definition schaut nur auf vorherige Spalten. Spalte 1 hat keine vorherigen und ist ≠ 0.' },
    e: 'Spalte 2 = 2 · Spalte 1, Spalte 4 = Spalte 1 + Spalte 3. Spalte 3 ist keine Kombination von Spalte 1 und 2. Also Rang 2 mit unabhängigen Spalten 1 und 3.',
    m: 'Unabhängige Spalte = nicht Kombination der Spalten links davon.', s: 'Skript LinAlg I 2.1.2' },

  { id: 'la4-03', t: 'la4', d: 3, k: 'sc',
    q: 'Die Spalten von A sind in dieser Reihenfolge $\\vec{1;1}$, $\\vec{1;0}$, $\\vec{0;1}$. Welche Spalten sind nach der Definition im Skript unabhängig?',
    o: ['Spalten 1 und 2', 'Spalten 2 und 3', 'alle drei', 'Spalten 1 und 3'], a: 0,
    w: { 1: 'Welche Spalten unabhängig sind, hängt von der Reihenfolge ab.', 3: 'Spalte 3 = Spalte 1 − Spalte 2 ist abhängig.' },
    e: 'Spalte 1 ≠ 0: unabhängig. Spalte 2 ist kein Vielfaches von Spalte 1: unabhängig. Spalte 3 = Spalte 1 − Spalte 2: abhängig. Der Rang 2 hängt nicht von der Reihenfolge ab, die Menge der unabhängigen Spalten schon.',
    m: 'Rang: eindeutig. Welche Spalten unabhängig heissen: abhängig von der Reihenfolge.', s: 'Skript LinAlg I 2.1.2, Definition 2.10' },

  { id: 'la4-04', t: 'la4', d: 1, k: 'sc',
    q: 'Was ist der Nullraum von $\\mat{1,2;2,4}$?',
    o: ['$\\{\\lambda \\vec{-2;1} \\mid \\lambda \\in \\R\\}$', '$\\{0\\}$', '$\\R^2$', '$\\{\\lambda \\vec{1;2} \\mid \\lambda \\in \\R\\}$'], a: 0,
    w: { 3: 'Das ist der Spaltenraum.' },
    e: 'Ax = 0 heisst x₁ + 2x₂ = 0. Lösungen: x = λ(−2, 1).',
    m: 'N(A) = alle x mit Ax = 0, ein Unterraum von ℝⁿ.', s: 'Skript LinAlg I 2.1.5, Definition 2.17' },

  { id: 'la4-05', t: 'la4', d: 2, k: 'sc',
    q: 'Welche Matrix hat Rang 1?',
    o: ['$\\mat{2,4;3,6}$', '$\\mat{1,0;0,1}$', '$\\mat{0,0;0,0}$', '$\\mat{1,2;3,4}$'], a: 0,
    e: '$\\mat{2,4;3,6} = \\vec{2;3}(1, 2)$: jede Zeile ist Vielfaches von (1, 2), jede Spalte Vielfaches von (2, 3). Rang-1-Matrizen sind genau die Matrizen $vw^\\top$ mit v, w ≠ 0 (Lemma 2.15).',
    m: 'Rang 1 ⟺ äusseres Produkt $vw^\\top$.', s: 'Skript LinAlg I 2.1.4, Lemma 2.15' },

  { id: 'la4-06', t: 'la4', d: 2, k: 'tf',
    q: 'A ist eine m × n-Matrix. Wahr oder falsch?',
    rows: [
      ['$C(A)$ ist eine Teilmenge von ℝᵐ.', true, 'Linearkombinationen der Spalten, die in ℝᵐ liegen.'],
      ['$N(A)$ ist eine Teilmenge von ℝᵐ.', false, 'N(A) ⊆ ℝⁿ, x hat n Einträge.'],
      ['b ∈ C(A) genau dann, wenn Ax = b eine Lösung hat.', true, 'Observation 2.5.'],
      ['$R(A) = C(A^\\top)$', true, 'So ist der Zeilenraum definiert.'],
      ['Die unabhängigen Spalten spannen C(A) auf.', true, 'Lemma 2.11.']
    ],
    e: 'C(A) lebt im Bildbereich ℝᵐ, N(A) und R(A) im Urbildbereich ℝⁿ.', m: 'C(A), N(Aᵀ) ⊆ ℝᵐ. R(A), N(A) ⊆ ℝⁿ.', s: 'Skript LinAlg I 2.1' },

  { id: 'la4-w1', t: 'la4', d: 2, k: 'w',
    q: 'Bestimme für $A = \\mat{1,2,0,1;0,0,1,1;1,2,1,2}$ die unabhängigen Spalten, den Rang und eine Basis des Nullraums. Tippe den Rang ein.',
    ans: { k: 'num', v: 2 },
    sol: [
      'Spalte 1 unabhängig, Spalte 2 = 2 · Spalte 1, Spalte 3 unabhängig, Spalte 4 = Spalte 1 + Spalte 3. Rang 2.',
      'Jede Abhängigkeit liefert einen Nullraumvektor: 2 · Spalte 1 − Spalte 2 = 0 gibt (2, −1, 0, 0). Spalte 1 + Spalte 3 − Spalte 4 = 0 gibt (1, 0, 1, −1).',
      'Diese beiden sind unabhängig, und dim N(A) = 4 − 2 = 2 (Rangsatz, kommt in Kapitel 4). Also eine Basis.'
    ],
    res: 'Rang 2, Nullraum-Basis (2, −1, 0, 0), (1, 0, 1, −1)',
    m: 'Jede abhängige Spalte liefert einen Vektor im Nullraum.', s: 'Skript LinAlg I 2.1' },

  // ---------------- 2.2 Lineare Abbildungen ----------------
  { id: 'la5-01', t: 'la5', d: 1, k: 'sc',
    q: 'Welche Abbildung ℝ² → ℝ² ist linear?',
    o: ['$(x, y) \\mapsto (3x - y,\\ 2y)$', '$(x, y) \\mapsto (x + 1,\\ y)$', '$(x, y) \\mapsto (xy,\\ x)$', '$(x, y) \\mapsto (|x|,\\ y)$'], a: 0,
    w: { 1: 'T(0) = (1, 0) ≠ 0.', 2: 'T(2v) ≠ 2T(v).', 3: 'T(−v) ≠ −T(v).' },
    e: 'Linear heisst T(x + x′) = T(x) + T(x′) und T(λx) = λT(x). Insbesondere muss T(0) = 0 gelten (Lemma 2.21).',
    m: 'Schnelltest: T(0) = 0? Keine Produkte oder Beträge von Koordinaten?', s: 'Skript LinAlg I 2.2.2, Definition 2.19' },

  { id: 'la5-02', t: 'la5', d: 1, k: 'sc',
    q: 'Welche Matrix gehört zur linearen Abbildung $T(x, y, z) = (x + 2z,\\ y - z)$?',
    o: ['$\\mat{1,0,2;0,1,-1}$', '$\\mat{1,0;0,1;2,-1}$', '$\\mat{1,2;1,-1}$', '$\\mat{1,0,2;0,-1,1}$'], a: 0,
    w: { 1: 'Das ist die Transponierte, eine 3 × 2-Matrix passt nicht zu ℝ³ → ℝ².' },
    e: 'Die Spalten sind die Bilder der Standardbasisvektoren: T(e₁) = (1, 0), T(e₂) = (0, 1), T(e₃) = (2, −1) (Theorem 2.23).',
    m: 'Spalte j der Matrix = T(eⱼ).', s: 'Skript LinAlg I 2.2.3, Theorem 2.23' },

  { id: 'la5-03', t: 'la5', d: 2, k: 'sc',
    q: 'T: ℝ² → ℝ² ist linear mit $T(e_1) = \\vec{1;2}$ und $T(e_2) = \\vec{3;4}$. Was ist $T\\vec{2;-1}$?',
    o: ['$\\vec{-1;0}$', '$\\vec{5;8}$', '$\\vec{2;-4}$', '$\\vec{-1;2}$'], a: 0,
    e: '$T(2e_1 - e_2) = 2T(e_1) - T(e_2) = (2, 4) - (3, 4) = (-1, 0)$.',
    m: 'Eine lineare Abbildung ist durch die Bilder einer Basis festgelegt.', s: 'Skript LinAlg I 2.2, Lemma 2.22' },

  { id: 'la5-04', t: 'la5', d: 1, k: 'sc',
    q: 'Welche Matrix dreht ℝ² um 90° gegen den Uhrzeigersinn?',
    o: ['$\\mat{0,-1;1,0}$', '$\\mat{0,1;-1,0}$', '$\\mat{-1,0;0,-1}$', '$\\mat{0,1;1,0}$'], a: 0,
    w: { 1: 'Das dreht im Uhrzeigersinn.', 2: 'Das dreht um 180°.', 3: 'Das spiegelt an der Diagonalen.' },
    e: 'e₁ = (1, 0) geht auf (0, 1), e₂ = (0, 1) geht auf (−1, 0). Diese Bilder sind die Spalten.',
    m: 'Bilder der Basisvektoren als Spalten eintragen.', s: 'Skript LinAlg I 2.2.1' },

  { id: 'la5-05', t: 'la5', d: 2, k: 'sc',
    q: 'T: ℝ² → ℝ² projiziert jeden Punkt senkrecht auf die x-Achse. Was ist Ker(T), was ist Im(T)?',
    o: ['Ker = y-Achse, Im = x-Achse', 'Ker = x-Achse, Im = y-Achse', 'Ker = {0}, Im = ℝ²', 'Ker = x-Achse, Im = x-Achse'], a: 0,
    e: 'T(x, y) = (x, 0). Auf 0 abgebildet werden genau die Punkte (0, y). Getroffen werden genau die Punkte (x, 0).',
    m: 'Ker(T) = N(A), Im(T) = C(A).', s: 'Skript LinAlg I 2.2.4, Definition 2.25' },

  { id: 'la5-06', t: 'la5', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['$x \\mapsto \\lVert x \\rVert$ ist ein lineares Funktional auf ℝᵐ.', false, '‖−x‖ = ‖x‖ ≠ −‖x‖.'],
      ['$x \\mapsto a^\\top x$ ist für jedes a ein lineares Funktional.', true, 'Das ist die Matrixtransformation mit der 1 × m-Matrix aᵀ.'],
      ['$x \\mapsto Ax + b$ ist genau dann linear, wenn b = 0.', true, 'Sonst ist T(0) = b ≠ 0.'],
      ['Die Komposition linearer Abbildungen ist linear.', true, 'Lemma 2.32.'],
      ['Jede lineare Abbildung ℝⁿ → ℝᵐ ist injektiv.', false, 'Die Nullabbildung nicht.']
    ],
    e: 'Lineare Abbildungen ℝⁿ → ℝᵐ sind genau die Matrixtransformationen.', m: 'Linear ⟺ Matrix.', s: 'Skript LinAlg I 2.2' },

  { id: 'la5-w1', t: 'la5', d: 1, k: 'w',
    q: 'Gib die Matrix der Spiegelung an der Geraden y = x in ℝ² an. Bestimme Kern und Bild.',
    sol: [
      'Die Spiegelung vertauscht die Koordinaten: T(x, y) = (y, x).',
      'T(e₁) = (0, 1), T(e₂) = (1, 0), also $A = \\mat{0,1;1,0}$.',
      'Ker(T) = {0}, weil (y, x) = (0, 0) nur für x = y = 0 gilt. Im(T) = ℝ², jeder Punkt (a, b) ist Bild von (b, a).',
      'T ist umkehrbar mit T⁻¹ = T, also A² = I.'
    ],
    res: '$A = \\mat{0,1;1,0}$, Ker = {0}, Im = ℝ²',
    m: 'Spiegelungen sind ihr eigenes Inverses.', s: 'Skript LinAlg I 2.2' },

  { id: 'la5-w2', t: 'la5', d: 2, k: 'w',
    q: 'Beweise: Eine lineare Abbildung T: ℝⁿ → ℝᵐ ist genau dann injektiv, wenn Ker(T) = {0}.',
    sol: [
      '„⟹“: Es gilt T(0) = 0. Ist T injektiv, kann kein anderes x auf 0 abgebildet werden, also Ker(T) = {0}.',
      '„⟸“: Sei T(x) = T(x′). Dann ist T(x − x′) = T(x) − T(x′) = 0 wegen Linearität.',
      'Also x − x′ ∈ Ker(T) = {0}, also x = x′.'
    ],
    res: 'Injektiv ⟺ trivialer Kern.',
    m: 'Linearität macht aus „gleiche Bilder“ ein „Differenz im Kern“.', s: 'Skript LinAlg I 2.2.4' },

  // ---------------- 2.3 Matrixmultiplikation, CR ----------------
  { id: 'la6-01', t: 'la6', d: 1, k: 'sc',
    q: 'A ist 2 × 3, B ist 3 × 4. Welche Grösse hat AB, und ist BA definiert?',
    o: ['AB ist 2 × 4, BA ist nicht definiert', 'AB ist 3 × 3, BA ist 4 × 2', 'AB ist 2 × 4, BA ist 4 × 2', 'AB ist nicht definiert'], a: 0,
    e: 'AB braucht: Spalten von A = Zeilen von B (3 = 3), Ergebnis Zeilen von A × Spalten von B. Für BA müsste 4 = 2 gelten.',
    m: '(m × k)(k × n) = m × n.', s: 'Skript LinAlg I 2.3.2' },

  { id: 'la6-02', t: 'la6', d: 2, k: 'sc',
    q: 'Was ist $\\mat{1,2;3,4}\\mat{0,1;1,0}$?',
    o: ['$\\mat{2,1;4,3}$', '$\\mat{3,4;1,2}$', '$\\mat{0,2;3,0}$', '$\\mat{1,2;3,4}$'], a: 0,
    w: { 1: 'Das wäre die Multiplikation von links, BA: Zeilen vertauschen.' },
    e: 'Multiplikation von rechts mit dieser Matrix vertauscht die Spalten. Von links würde sie die Zeilen vertauschen.',
    m: 'Von rechts: Spalten. Von links: Zeilen.', s: 'Skript LinAlg I 2.3.2' },

  { id: 'la6-03', t: 'la6', d: 2, k: 'sc',
    q: 'Was ist das äussere Produkt $\\vec{1;2}(3,\\ 4)$?',
    o: ['$\\mat{3,4;6,8}$', '11', '$\\mat{3,6;4,8}$', '$\\vec{3;8}$'], a: 0,
    w: { 1: 'Das wäre das Skalarprodukt $v^\\top w$.', 2: 'Das wäre $w v^\\top$.' },
    e: '$vw^\\top$ ist die 2 × 2-Matrix mit Einträgen $v_i w_j$. Sie hat Rang 1.',
    m: '$v^\\top w$ ist eine Zahl, $vw^\\top$ eine Matrix.', s: 'Skript LinAlg I 2.3.4, Definition 2.42' },

  { id: 'la6-04', t: 'la6', d: 3, k: 'tf',
    q: 'A, B, C sind quadratische Matrizen gleicher Grösse. Wahr oder falsch?',
    rows: [
      ['Aus AB = 0 folgt A = 0 oder B = 0.', false, '$A = B = \\mat{0,1;0,0}$ erfüllt AB = 0.'],
      ['$(A + B)^2 = A^2 + 2AB + B^2$', false, 'Richtig ist A² + AB + BA + B², und AB ≠ BA im Allgemeinen.'],
      ['$A(BC) = (AB)C$', true, 'Assoziativität (Lemma 2.40).'],
      ['$(AB)^\\top = A^\\top B^\\top$', false, 'Richtig ist $B^\\top A^\\top$ (Lemma 2.38).'],
      ['Spalte j von AB ist A mal Spalte j von B.', true, 'Matrixmultiplikation in Spaltennotation.']
    ],
    e: 'Matrixmultiplikation ist assoziativ, aber nicht kommutativ, und es gibt Nullteiler.', m: 'Transponieren und Invertieren kehren die Reihenfolge um.', s: 'Skript LinAlg I 2.3' },

  { id: 'la6-05', t: 'la6', d: 3, k: 'sc',
    q: 'Was ist die CR-Zerlegung von $A = \\mat{1,2,0,1;0,0,1,1;1,2,1,2}$?',
    o: ['$C = \\mat{1,0;0,1;1,1}$, $R = \\mat{1,2,0,1;0,0,1,1}$', '$C = \\mat{1,2;0,0;1,2}$, $R = \\mat{1,0,0,1;0,1,1,0}$', '$C = A$, $R = I$', '$C = \\mat{1,0;0,1;1,1}$, $R = \\mat{1,0;2,0;0,1;1,1}$'], a: 0,
    w: { 1: 'Spalte 2 ist abhängig und gehört nicht in C.', 3: 'R muss r × n = 2 × 4 sein.' },
    e: 'C enthält die unabhängigen Spalten 1 und 3. Spalte j von R enthält die Koeffizienten, mit denen Spalte j von A aus den Spalten von C entsteht: Spalte 2 = 2 · c₁, Spalte 4 = c₁ + c₂.',
    m: 'A = CR: C = unabhängige Spalten, R = Koeffizienten (r × n).', s: 'Skript LinAlg I 2.3.5, Theorem 2.44' },

  { id: 'la6-w1', t: 'la6', d: 2, k: 'w',
    q: 'Bestimme die CR-Zerlegung von $A = \\mat{2,4,1;1,2,0;3,6,1}$ und kontrolliere A = CR.',
    sol: [
      'Spalte 1 = (2, 1, 3) ist unabhängig. Spalte 2 = 2 · Spalte 1, abhängig.',
      'Spalte 3 = (1, 0, 1) ist kein Vielfaches von Spalte 1 (zweite Komponente 0, aber nicht alle 0), also unabhängig. Rang 2.',
      '$C = \\mat{2,1;1,0;3,1}$. Spalte 1 von A = 1 · c₁, Spalte 2 = 2 · c₁, Spalte 3 = 1 · c₂.',
      '$R = \\mat{1,2,0;0,0,1}$. Kontrolle: CR hat die Spalten c₁, 2c₁, c₂ = A.'
    ],
    res: '$C = \\mat{2,1;1,0;3,1}$, $R = \\mat{1,2,0;0,0,1}$',
    m: 'R hat die Einheitsvektoren in den Spalten der unabhängigen Spalten.', s: 'Skript LinAlg I 2.3.5' },

  // ---------------- 2.4 Inverse Matrizen ----------------
  { id: 'la7-01', t: 'la7', d: 1, k: 'sc',
    q: 'Was ist die Inverse von $\\mat{2,1;5,3}$?',
    o: ['$\\mat{3,-1;-5,2}$', '$\\mat{1/2,1;1/5,1/3}$', '$\\mat{-3,1;5,-2}$', '$\\mat{3,5;1,2}$'], a: 0,
    w: { 1: 'Die Inverse ist nicht eintragsweise.', 2: 'Vorzeichen: das ist −A⁻¹.' },
    e: 'Kontrolle: $\\mat{2,1;5,3}\\mat{3,-1;-5,2} = \\mat{6-5,-2+2;15-15,-5+6} = I$.',
    m: 'Eine vermutete Inverse prüft man durch Multiplizieren.', s: 'Skript LinAlg I 2.4.2' },

  { id: 'la7-02', t: 'la7', d: 1, k: 'sc',
    q: 'A und B sind invertierbar. Was ist $(AB)^{-1}$?',
    o: ['$B^{-1}A^{-1}$', '$A^{-1}B^{-1}$', '$(BA)^{-1}$ = $A^{-1}B^{-1}$', 'existiert nicht im Allgemeinen'], a: 0,
    e: '$(AB)(B^{-1}A^{-1}) = A(BB^{-1})A^{-1} = I$. Anschaulich: zuerst B, dann A; rückgängig zuerst A⁻¹, dann B⁻¹ (Lemma 2.58).',
    m: 'Socken-Schuhe-Prinzip.', s: 'Skript LinAlg I 2.4.2, Lemma 2.58' },

  { id: 'la7-03', t: 'la7', d: 2, k: 'sc',
    q: 'Warum ist eine Matrixtransformation $T_A: \\R^3 \\to \\R^2$ nie umkehrbar?',
    o: ['Die drei Spalten in ℝ² sind abhängig, also ist T_A nicht injektiv', 'Weil T_A nicht surjektiv sein kann', 'Weil A keine Nullzeile hat', 'Weil ℝ³ mehr Vektoren als ℝ² enthält'], a: 0,
    w: { 1: 'Surjektiv kann sie durchaus sein.', 3: 'Beide Mengen sind gleichmächtig, das Argument trägt nicht.' },
    e: 'Drei Vektoren in ℝ² sind linear abhängig, also gibt es x ≠ 0 mit Ax = 0 = A0. Zwei Urbilder für 0: nicht injektiv (Lemma 2.50).',
    m: 'Nur quadratische Matrizen können invertierbar sein.', s: 'Skript LinAlg I 2.4.1, Lemmata 2.50–2.51' },

  { id: 'la7-04', t: 'la7', d: 2, k: 'sc',
    q: 'A und B sind m × m-Matrizen mit BA = I. Was folgt?',
    o: ['Auch AB = I, also B = A⁻¹', 'Nichts über AB', 'AB = I nur, wenn A symmetrisch ist', 'A = I'], a: 0,
    e: 'Für quadratische Matrizen reicht eine Seite: BA = I macht T_A umkehrbar, und dann gilt auch AB = I (Lemma 2.53). Für nicht quadratische Matrizen stimmt das nicht.',
    m: 'Quadratisch: Linksinverse = Rechtsinverse.', s: 'Skript LinAlg I 2.4.2, Lemma 2.53' },

  { id: 'la7-05', t: 'la7', d: 3, k: 'tf',
    q: 'A, B sind quadratisch. Wahr oder falsch?',
    rows: [
      ['A ist invertierbar ⟺ die Spalten von A sind linear unabhängig.', true, 'Lemma 2.52.'],
      ['Sind A und B invertierbar, ist auch A + B invertierbar.', false, 'A = I, B = −I.'],
      ['Aus $A^2 = I$ folgt $A^{-1} = A$.', true, 'A · A = I.'],
      ['$(2A)^{-1} = 2A^{-1}$', false, 'Richtig ist $\\tfrac{1}{2}A^{-1}$.'],
      ['$(A^\\top)^{-1} = (A^{-1})^\\top$', true, 'Lemma 2.59.']
    ],
    e: 'Invertierbarkeit verträgt sich mit Produkten und Transponieren, nicht mit Summen.', m: 'Skalar herausziehen: $(cA)^{-1} = c^{-1}A^{-1}$.', s: 'Skript LinAlg I 2.4' },

  { id: 'la7-w1', t: 'la7', d: 2, k: 'w',
    q: 'Es gelte $A^3 = 0$ für eine quadratische Matrix A. Zeige, dass I − A invertierbar ist, und gib die Inverse an.',
    hint: 'Denk an die geometrische Reihe $1 + x + x^2 = \\frac{1 - x^3}{1 - x}$.',
    sol: [
      'Kandidat: $B = I + A + A^2$.',
      '$(I - A)(I + A + A^2) = I + A + A^2 - A - A^2 - A^3 = I - A^3 = I$.',
      'Für quadratische Matrizen reicht eine Seite (Lemma 2.53), also $(I - A)^{-1} = I + A + A^2$.'
    ],
    res: '$(I - A)^{-1} = I + A + A^2$',
    m: 'Eine Inverse raten und durch Multiplikation bestätigen.', s: 'Skript LinAlg I 2.4' },

  { id: 'la7-w2', t: 'la7', d: 2, k: 'w',
    q: 'Berechne mit Gauss-Jordan die Inverse von $B = \\mat{1,2,0;0,1,0;2,0,1}$. Tippe den Eintrag in Zeile 3, Spalte 2 von $B^{-1}$ ein.',
    ans: { k: 'num', v: 4 },
    sol: [
      'Starte mit (B | I). Zeile 3 − 2 · Zeile 1: (0, −4, 1 | −2, 0, 1).',
      'Zeile 3 + 4 · Zeile 2: (0, 0, 1 | −2, 4, 1).',
      'Zeile 1 − 2 · Zeile 2: (1, 0, 0 | 1, −2, 0).',
      'Ergebnis: $B^{-1} = \\mat{1,-2,0;0,1,0;-2,4,1}$. Kontrolle: B · B⁻¹ = I.'
    ],
    res: '$B^{-1} = \\mat{1,-2,0;0,1,0;-2,4,1}$, also $(B^{-1})_{3,2} = 4$',
    m: 'Gauss-Jordan auf (A | I) liefert (I | A⁻¹).', s: 'Skript LinAlg I 3.2.6 und 3.3.5' },

  // ---------------- 3.1–3.2 Gauss-Elimination, LU ----------------
  { id: 'la8-01', t: 'la8', d: 1, k: 'sc',
    q: 'Welche Laufzeiten haben Gauss-Elimination und Rückwärtseinsetzen für ein m × m-System?',
    o: ['O(m³) und O(m²)', 'O(m²) und O(m)', 'O(m³) und O(m³)', 'O(2ᵐ) und O(m²)'], a: 0,
    e: 'Elimination: für jede der m Spalten bis zu m Zeilen mit je bis zu m Einträgen ändern. Rückwärtseinsetzen: Zeile i braucht O(m − i) Operationen (Theoreme 3.9–3.10).',
    m: 'Eliminieren kubisch, Einsetzen quadratisch.', s: 'Skript LinAlg I 3.2.5' },

  { id: 'la8-02', t: 'la8', d: 2, k: 'sc',
    q: 'Wann gelingt die Gauss-Elimination (mit Zeilenvertauschungen) für ein quadratisches System Ax = b?',
    o: ['Genau dann, wenn die Spalten von A linear unabhängig sind', 'Genau dann, wenn b ≠ 0', 'Immer', 'Genau dann, wenn A symmetrisch ist'], a: 0,
    e: 'Theorem 3.7: Scheitert die Elimination in Spalte j, hat diese Spalte unterhalb der Diagonalen nur Nullen, und man findet eine Abhängigkeit unter den Spalten.',
    m: 'Gauss erfolgreich ⟺ A invertierbar.', s: 'Skript LinAlg I 3.2.4, Theorem 3.7' },

  { id: 'la8-03', t: 'la8', d: 2, k: 'sc', fix: true,
    q: 'Löse durch Rückwärtseinsetzen: $\\mat{2,1,-1;0,3,2;0,0,4}x = \\vec{1;8;8}$. Was ist x₁?',
    o: ['5/6', '1', '2', '4/3'], a: 0,
    w: { 2: 'Das ist x₃.', 3: 'Das ist x₂.' },
    e: 'x₃ = 8/4 = 2. x₂ = (8 − 2 · 2)/3 = 4/3. x₁ = (1 − 4/3 + 2)/2 = (5/3)/2 = 5/6.',
    m: 'Von unten nach oben einsetzen.', s: 'Skript LinAlg I 3.2.1' },

  { id: 'la8-04', t: 'la8', d: 2, k: 'sc',
    q: 'Was ist die LU-Zerlegung von $A = \\mat{2,1;6,5}$ (L untere Dreiecksmatrix mit Einsen auf der Diagonalen)?',
    o: ['$L = \\mat{1,0;3,1}$, $U = \\mat{2,1;0,2}$', '$L = \\mat{1,0;-3,1}$, $U = \\mat{2,1;0,2}$', '$L = \\mat{2,0;6,1}$, $U = \\mat{1,1;0,5}$', '$L = \\mat{1,0;3,1}$, $U = \\mat{2,1;0,5}$'], a: 0,
    w: { 1: 'In L steht der Faktor mit positivem Vorzeichen: Zeile 2 − 3 · Zeile 1.', 3: '5 − 3 · 1 = 2.' },
    e: 'Elimination: Zeile 2 minus 3 · Zeile 1 ergibt U = (2, 1; 0, 2). L speichert den Faktor 3. Kontrolle: LU = (2, 1; 6, 3 + 2) = A.',
    m: 'L sammelt die Eliminationsfaktoren.', s: 'Skript LinAlg I 3.2.7' },

  { id: 'la8-05', t: 'la8', d: 3, k: 'tf',
    q: 'M ist eine invertierbare m × m-Matrix (z. B. das Produkt der Zeilenoperationen). Wahr oder falsch?',
    rows: [
      ['A und MA haben denselben Nullraum.', true, 'Lemma 3.3.'],
      ['A und MA haben denselben Zeilenraum.', true, 'Lemma 3.5.'],
      ['A und MA haben denselben Spaltenraum.', false, 'Zeilenoperationen ändern die Spalten. Beispiel A = (1; 0), M vertauscht die Zeilen.'],
      ['A und MA haben dieselben unabhängigen Spaltenindizes.', true, 'Lemma 3.6, daher auch denselben Rang.'],
      ['Ax = b und MAx = Mb haben dieselben Lösungen.', true, 'Lemma 3.2.']
    ],
    e: 'Deshalb darf man an der RREF die unabhängigen Spalten und den Nullraum ablesen, den Spaltenraum aber an den Originalspalten.', m: 'Zeilenoperationen erhalten N(A), R(A), Rang und Spaltenindizes, nicht C(A).', s: 'Skript LinAlg I 3.1–3.2' },

  { id: 'la8-w1', t: 'la8', d: 1, k: 'w',
    q: 'Löse mit Gauss-Elimination und Rückwärtseinsetzen:\n$2x + y - z = 8$\n$-3x - y + 2z = -11$\n$-2x + y + 2z = -3$\nTippe „x, y, z“ ein.',
    ans: { k: 'vec', v: [2, 3, -1], ph: 'x, y, z' },
    sol: [
      'Zeile 2 + 3/2 · Zeile 1: (0, 1/2, 1/2 | 1). Zeile 3 + Zeile 1: (0, 2, 1 | 5).',
      'Zeile 3 − 4 · Zeile 2: (0, 0, −1 | 1).',
      'Rückwärts: z = −1. Aus y/2 + z/2 = 1 folgt y = 3. Aus 2x + 3 + 1 = 8 folgt x = 2.',
      'Probe in Zeile 3: −4 + 3 − 2 = −3.'
    ],
    res: '(x, y, z) = (2, 3, −1)',
    m: 'Am Ende immer in eine Originalgleichung einsetzen.', s: 'Skript LinAlg I 3.2' },

  { id: 'la8-w2', t: 'la8', d: 3, k: 'w',
    q: 'Bestimme die LU-Zerlegung von $A = \\mat{2,1,1;4,3,3;8,7,9}$ und löse damit $Ax = \\vec{4;10;24}$ (zuerst Ly = b, dann Ux = y). Tippe x ein.',
    ans: { k: 'vec', v: [1, 1, 1], ph: 'x₁, x₂, x₃' },
    sol: [
      'Zeile 2 − 2 · Zeile 1, Zeile 3 − 4 · Zeile 1: (2, 1, 1; 0, 1, 1; 0, 3, 5). Dann Zeile 3 − 3 · Zeile 2: (0, 0, 2).',
      '$L = \\mat{1,0,0;2,1,0;4,3,1}$, $U = \\mat{2,1,1;0,1,1;0,0,2}$.',
      'Ly = b vorwärts: y₁ = 4, y₂ = 10 − 8 = 2, y₃ = 24 − 16 − 6 = 2.',
      'Ux = y rückwärts: x₃ = 1, x₂ = 2 − 1 = 1, x₁ = (4 − 1 − 1)/2 = 1.'
    ],
    res: 'x = (1, 1, 1)',
    m: 'Mit LU kostet jede neue rechte Seite nur O(m²).', s: 'Skript LinAlg I 3.2.7' },

  // ---------------- 3.3 Gauss-Jordan, RREF ----------------
  { id: 'la9-01', t: 'la9', d: 1, k: 'sc',
    q: 'Welche Matrix ist in reduzierter Zeilenstufenform (RREF)?',
    o: ['$\\mat{1,3,0,2;0,0,1,-1}$', '$\\mat{1,3,2,2;0,0,1,-1}$', '$\\mat{2,0,0;0,1,0}$', '$\\mat{0,0,1;1,0,0}$'], a: 0,
    w: { 1: 'Über der führenden 1 in Spalte 3 steht 2 statt 0.', 2: 'Führende Einträge müssen 1 sein.', 3: 'Die Stufen müssen nach rechts wandern.' },
    e: 'RREF: führende Einsen, die nach unten nach rechts wandern, und in den Spalten der führenden Einsen sonst nur Nullen.',
    m: 'RREF: Pivot = 1, darüber und darunter 0.', s: 'Skript LinAlg I 3.3.1, Definition 3.13' },

  { id: 'la9-02', t: 'la9', d: 2, k: 'sc',
    q: 'Was ist die RREF von $\\mat{1,2,3;2,4,7}$?',
    o: ['$\\mat{1,2,0;0,0,1}$', '$\\mat{1,2,3;0,0,1}$', '$\\mat{1,0,0;0,1,0}$', '$\\mat{1,2,3;0,0,0}$'], a: 0,
    w: { 1: 'Über der zweiten führenden 1 muss noch eliminiert werden.', 2: 'Spalte 2 ist von Spalte 1 abhängig, dort kann keine führende 1 stehen.' },
    e: 'Zeile 2 − 2 · Zeile 1: (0, 0, 1). Dann Zeile 1 − 3 · Zeile 2: (1, 2, 0). Unabhängige Spalten: 1 und 3.',
    m: 'Die Pivotspalten der RREF sind die unabhängigen Spalten von A.', s: 'Skript LinAlg I 3.3' },

  { id: 'la9-03', t: 'la9', d: 2, k: 'sc',
    q: 'Gauss-Jordan auf (A | I) für eine quadratische Matrix A liefert (R | M). Wann ist A invertierbar?',
    o: ['Genau dann, wenn R = I, und dann ist M = A⁻¹', 'Immer, M ist dann A⁻¹', 'Genau dann, wenn M = I', 'Genau dann, wenn R eine Nullzeile hat'], a: 0,
    e: 'Es gilt R = MA mit invertierbarem M (Theorem 3.17). Ist R = I, folgt MA = I, also M = A⁻¹ (Theorem 3.19).',
    m: 'RREF einer invertierbaren Matrix ist I.', s: 'Skript LinAlg I 3.3.5, Theorem 3.19' },

  { id: 'la9-04', t: 'la9', d: 3, k: 'sc',
    q: 'Die RREF von A (3 × 5) hat führende Einsen in den Spalten 1, 2 und 4. Wie viele freie Variablen hat Ax = 0, und welche?',
    o: ['2: x₃ und x₅', '3: x₁, x₂, x₄', '2: x₄ und x₅', '0'], a: 0,
    e: 'Freie Variablen gehören zu den Nicht-Pivotspalten. n − r = 5 − 3 = 2. Jede Wahl von x₃, x₅ bestimmt x₁, x₂, x₄ eindeutig.',
    m: 'Freie Variablen = Spalten ohne führende 1.', s: 'Skript LinAlg I 3.3.2' },

  { id: 'la9-w1', t: 'la9', d: 2, k: 'w',
    q: 'Bestimme mit Gauss-Jordan die Lösungsmenge von\n$x_1 + 2x_2 + x_3 + 3x_4 = 2$\n$2x_1 + 4x_2 + 2x_4 = 6$\nWie viele freie Parameter hat sie?',
    ans: { k: 'num', v: 2 },
    sol: [
      'Zeile 2 − 2 · Zeile 1: (0, 0, −2, −4 | 2), durch −2: (0, 0, 1, 2 | −1).',
      'Zeile 1 − Zeile 2: (1, 2, 0, 1 | 3). RREF mit Pivots in Spalten 1 und 3.',
      'Freie Variablen x₂ = s, x₄ = t: x₁ = 3 − 2s − t, x₃ = −1 − 2t.',
      'Lösungsmenge: (3, 0, −1, 0) + s(−2, 1, 0, 0) + t(−1, 0, −2, 1).'
    ],
    res: 'Spezielle Lösung plus Nullraum mit 2 Parametern',
    m: 'Lösungsmenge = spezielle Lösung + N(A).', s: 'Skript LinAlg I 3.3.2' }
]);
