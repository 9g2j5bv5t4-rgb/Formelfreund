// DiskMath Teil 2: 3.6–3.7 (Funktionen, Abzählbarkeit), 4 (Zahlentheorie), 5.1–5.6 (Algebra)
QUIZ.add('dm', [
  // ---------------- 3.6 Funktionen ----------------
  { id: 'dm9-01', t: 'dm9', d: 1, k: 'sc',
    q: 'Welche Eigenschaften hat $f: \\R \\to \\R,\\ x \\mapsto x^2$?',
    o: ['weder injektiv noch surjektiv', 'injektiv, aber nicht surjektiv', 'surjektiv, aber nicht injektiv', 'bijektiv'], a: 0,
    w: { 1: 'f(−1) = f(1).', 2: 'Negative Zahlen werden nicht getroffen.' },
    e: 'Nicht injektiv wegen f(−1) = f(1) = 1. Nicht surjektiv, weil kein x mit x² = −1 existiert. Auf $[0, \\infty) \\to [0, \\infty)$ eingeschränkt wäre f bijektiv.',
    m: 'Definitions- und Zielbereich gehören zur Funktion.', s: 'Skript DiskMath 3.6, Definition 3.39' },

  { id: 'dm9-02', t: 'dm9', d: 2, k: 'sc', fix: true,
    q: 'Wie viele **surjektive** Funktionen {1, 2, 3} → {a, b} gibt es?',
    o: ['6', '8', '2', '0'], a: 0,
    w: { 1: 'So viele Funktionen gibt es insgesamt.', 2: 'So viele sind konstant und damit gerade nicht surjektiv.', 3: 'So viele injektive gibt es.' },
    e: 'Es gibt $2^3 = 8$ Funktionen. Nicht surjektiv sind nur die beiden konstanten. Also 8 − 2 = 6.',
    m: 'Abzählen über das Komplement: alle minus die schlechten.', s: 'Skript DiskMath 3.6' },

  { id: 'dm9-03', t: 'dm9', d: 2, k: 'sc',
    q: '$f: \\R \\to \\R,\\ f(x) = x^2$. Was ist das Urbild $f^{-1}([4, 9])$?',
    o: ['$[-3, -2] \\cup [2, 3]$', '$[2, 3]$', '$[16, 81]$', '$[-3, 3]$'], a: 0,
    w: { 1: 'Auch negative x landen in [4, 9].', 2: 'Das wäre das Bild f([4, 9]).', 3: 'Zum Beispiel x = 0 landet nicht in [4, 9].' },
    e: 'Das Urbild sind alle x mit 4 ≤ x² ≤ 9, also 2 ≤ |x| ≤ 3. Die Notation $f^{-1}(T)$ ist auch definiert, wenn f nicht bijektiv ist.',
    m: 'Urbild $f^{-1}(T) = \\{x \\mid f(x) \\in T\\}$ existiert immer.', s: 'Skript DiskMath 3.6, Definition 3.38' },

  { id: 'dm9-04', t: 'dm9', d: 3, k: 'tf',
    q: '$f: A \\to B$ und $g: B \\to C$. Wahr oder falsch?',
    rows: [
      ['Sind f und g injektiv, so ist $g \\circ f$ injektiv.', true, 'g(f(a)) = g(f(a′)) ⟹ f(a) = f(a′) ⟹ a = a′.'],
      ['Ist $g \\circ f$ injektiv, so ist f injektiv.', true, 'Aus f(a) = f(a′) folgt g(f(a)) = g(f(a′)), also a = a′.'],
      ['Ist $g \\circ f$ injektiv, so ist g injektiv.', false, 'A = {1}, B = {1, 2}, g bildet beide auf denselben Wert ab, f trifft nur einen.'],
      ['Ist $g \\circ f$ surjektiv, so ist g surjektiv.', true, 'Jedes c = g(f(a)) wird von g getroffen.'],
      ['Ist $g \\circ f$ surjektiv, so ist f surjektiv.', false, 'Gleiches Gegenbeispiel wie oben: f trifft 2 nicht.']
    ],
    e: 'Merkhilfe: Die erste Funktion muss injektiv sein, die letzte surjektiv.', m: 'g ∘ f injektiv ⟹ f injektiv. g ∘ f surjektiv ⟹ g surjektiv.', s: 'Skript DiskMath 3.6, Definition 3.41' },

  { id: 'dm9-05', t: 'dm9', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Elemente hat $B^A$ für $A = \\{0, 1\\}^3$ und $B = \\{0, 1\\}$?',
    o: ['256', '8', '64', '16'], a: 0,
    w: { 1: 'So viele Elemente hat A.' },
    e: '$|B^A| = |B|^{|A|}$. Hier ist |A| = 8 und |B| = 2, also $2^8 = 256$. Das sind alle Booleschen Funktionen mit 3 Eingaben.',
    m: '$B^A$ = Menge aller Funktionen A → B, $|B^A| = |B|^{|A|}$.', s: 'Skript DiskMath 3.6, Definition 3.34' },

  { id: 'dm9-w1', t: 'dm9', d: 1, k: 'w',
    q: 'Zeige: $f: \\Z \\to \\Z,\\ f(x) = 3x + 2$ ist injektiv, aber nicht surjektiv.',
    sol: [
      'Injektiv: Aus f(x) = f(y) folgt 3x + 2 = 3y + 2, also 3x = 3y, also x = y.',
      'Nicht surjektiv: Gesucht wäre x ∈ ℤ mit 3x + 2 = 0, also x = −2/3 ∉ ℤ. Die 0 wird also nicht getroffen.',
      'Allgemein trifft f genau die Zahlen mit Rest 2 modulo 3.'
    ],
    res: 'Injektiv durch Umformen, nicht surjektiv durch ein nicht getroffenes Element.',
    m: 'Surjektivität widerlegen: ein Element im Zielbereich ohne Urbild angeben.', s: 'Skript DiskMath 3.6' },

  { id: 'dm9-w2', t: 'dm9', d: 2, k: 'w',
    q: 'Beweise: Ist $g \\circ f$ surjektiv (mit $f: A \\to B$, $g: B \\to C$), dann ist g surjektiv. Gib ausserdem ein Beispiel an, in dem $g \\circ f$ surjektiv ist, f aber nicht.',
    sol: [
      'Sei c ∈ C beliebig. Weil g ∘ f surjektiv ist, gibt es a ∈ A mit g(f(a)) = c.',
      'Setze b = f(a) ∈ B. Dann ist g(b) = c. Also wird jedes c von g getroffen.',
      'Beispiel: A = {1}, B = {1, 2}, C = {1}, f(1) = 1, g(1) = g(2) = 1. Dann ist g ∘ f surjektiv, f trifft 2 aber nicht.'
    ],
    res: 'Die letzte Funktion einer surjektiven Komposition ist surjektiv.',
    m: 'Für Gegenbeispiele reichen winzige Mengen.', s: 'Skript DiskMath 3.6' },

  // ---------------- 3.7 Abzählbarkeit ----------------
  { id: 'dm10-01', t: 'dm10', d: 1, k: 'mc',
    q: 'Welche Mengen sind abzählbar? Wähle alle.',
    o: ['ℤ', 'ℚ', '$\\{0, 1\\}^*$ (endliche Bitfolgen)', 'ℕ × ℕ', '$\\{0, 1\\}^\\infty$ (unendliche Bitfolgen)', '$\\mathcal{P}(\\N)$'], a: [0, 1, 2, 3],
    w: { 4: 'Diagonalargument (Theorem 3.23).', 5: 'Teilmengen von ℕ entsprechen unendlichen Bitfolgen.' },
    e: 'Abzählbar heisst A ⪯ ℕ. Endliche Bitfolgen kann man der Länge nach auflisten. Unendliche Bitfolgen nicht, das zeigt das Diagonalargument.',
    m: 'Endliche Objekte über einem endlichen Alphabet: abzählbar. Unendliche Folgen: nicht.', s: 'Skript DiskMath 3.7' },

  { id: 'dm10-02', t: 'dm10', d: 2, k: 'sc',
    q: 'Beim Diagonalargument nimmt man eine angebliche Aufzählung $f(0), f(1), \\ldots$ aller unendlichen Bitfolgen an. Welche Folge führt zum Widerspruch?',
    o: ['Die Folge, deren i-tes Bit das Gegenteil des i-ten Bits von f(i) ist', 'Die Folge aus lauter Nullen', 'Die Folge, deren i-tes Bit gleich dem i-ten Bit von f(i) ist', 'Die Folge f(0) mit vertauschten Bits'], a: 0,
    w: { 1: 'Die kann durchaus in der Liste vorkommen.', 2: 'Diese Diagonale kann in der Liste stehen.' },
    e: 'Die invertierte Diagonale unterscheidet sich von jedem f(i) an der Stelle i. Also kommt sie in der Liste nicht vor, Widerspruch zur Annahme.',
    m: 'Diagonalargument: an Stelle i von Folge i abweichen.', s: 'Skript DiskMath 3.7.3, Theorem 3.23' },

  { id: 'dm10-03', t: 'dm10', d: 2, k: 'sc',
    q: 'Warum gibt es Funktionen ℕ → {0, 1}, die kein Programm berechnet?',
    o: ['Es gibt nur abzählbar viele Programme, aber überabzählbar viele solche Funktionen', 'Weil Programme keine unendlichen Eingaben verarbeiten', 'Weil manche Funktionen zu schnell wachsen', 'Weil der Speicher endlich ist'], a: 0,
    e: 'Jedes Programm ist eine endliche Bitfolge, also gibt es abzählbar viele. Die Funktionen ℕ → {0, 1} entsprechen den unendlichen Bitfolgen und sind überabzählbar. Es bleiben unberechenbare übrig, und zwar „fast alle“.',
    m: 'Abzählbar viele Programme gegen überabzählbar viele Funktionen.', s: 'Skript DiskMath 3.7.4, Korollar 3.24' },

  { id: 'dm10-04', t: 'dm10', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Die Vereinigung abzählbar vieler abzählbarer Mengen ist abzählbar.', true, 'Theorem 3.22.'],
      ['Jede Teilmenge einer abzählbaren Menge ist abzählbar.', true, 'Die Inklusion ist eine Injektion.'],
      ['ℕ und ℤ sind gleichmächtig.', true, 'Zum Beispiel 0, −1, 1, −2, 2, … ist eine Bijektion.'],
      ['Es gibt eine Surjektion ℕ → $\\{0, 1\\}^\\infty$.', false, 'Dann wäre $\\{0, 1\\}^\\infty$ abzählbar.'],
      ['Aus A ⪯ B und B ⪯ A folgt A ∼ B.', true, 'Satz von Schröder-Bernstein (Theorem 3.16).']
    ],
    e: 'A ⪯ B heisst: es gibt eine Injektion A → B. A ∼ B heisst: es gibt eine Bijektion.', m: 'Zwei Injektionen in beide Richtungen reichen für Gleichmächtigkeit.', s: 'Skript DiskMath 3.7' },

  { id: 'dm10-05', t: 'dm10', d: 1, k: 'sc', fix: true,
    q: 'Die Bijektion ℕ → ℤ sei $f(n) = (-1)^n \\lceil n/2 \\rceil$. Was ist f(5)?',
    o: ['−3', '3', '−2', '2'], a: 0,
    e: '⌈5/2⌉ = 3 und $(-1)^5 = -1$, also f(5) = −3. Die Werte für n = 0, 1, 2, 3, 4, 5 sind 0, −1, 1, −2, 2, −3.',
    m: 'ℤ ist abzählbar: abwechselnd negativ und positiv aufzählen.', s: 'Skript DiskMath 3.7' },

  { id: 'dm10-w1', t: 'dm10', d: 3, k: 'w',
    q: 'Zeige, dass ℕ × ℕ abzählbar ist, indem du eine **explizite Injektion** ℕ × ℕ → ℕ angibst und ihre Injektivität beweist.',
    hint: 'Eindeutigkeit der Primfaktorzerlegung.',
    sol: [
      'Definiere $g(a, b) = 2^a \\cdot 3^b$.',
      'Injektiv: Aus $2^a 3^b = 2^c 3^d$ folgt mit der eindeutigen Primfaktorzerlegung a = c und b = d.',
      'Also ℕ × ℕ ⪯ ℕ, d. h. ℕ × ℕ ist abzählbar. (Eine Bijektion ist z. B. die Cantor-Abzählung entlang der Diagonalen.)'
    ],
    res: '$g(a, b) = 2^a 3^b$ ist injektiv.',
    m: 'Für Abzählbarkeit genügt eine Injektion nach ℕ.', s: 'Skript DiskMath 3.7.2, Theorem 3.19' },

  // ---------------- 4.1–4.4 Teilbarkeit, ggT, Primzahlen ----------------
  { id: 'dm11-01', t: 'dm11', d: 2, k: 'sc',
    q: 'Division mit Rest nach Euklid: a = −17, d = 5. Welche q und r erfüllen a = dq + r mit 0 ≤ r < |d|?',
    o: ['q = −4, r = 3', 'q = −3, r = −2', 'q = −3, r = 2', 'q = −4, r = −3'], a: 0,
    w: { 1: 'r muss nicht negativ sein. (Java rechnet so: `-17 % 5` ist −2.)', 2: '5 · (−3) + 2 = −13.', 3: 'r muss nicht negativ sein.' },
    e: '5 · (−4) + 3 = −20 + 3 = −17, und 0 ≤ 3 < 5. Mathematisch ist der Rest nie negativ, anders als bei Javas `%`.',
    m: 'Mathe: 0 ≤ r < |d|. Java: Vorzeichen wie der Dividend.', s: 'Skript DiskMath 4.2, Theorem 4.1' },

  { id: 'dm11-02', t: 'dm11', d: 1, k: 'sc', fix: true,
    q: 'Was ist gcd(252, 198)?',
    o: ['18', '6', '9', '36'], a: 0,
    e: 'Euklid: 252 = 1 · 198 + 54, 198 = 3 · 54 + 36, 54 = 1 · 36 + 18, 36 = 2 · 18 + 0. Also 18.',
    m: 'gcd(a, b) = gcd(b, a mod b).', s: 'Skript DiskMath 4.2, Lemma 4.2' },

  { id: 'dm11-03', t: 'dm11', d: 2, k: 'sc',
    q: 'Welches Paar (u, v) erfüllt $17u + 13v = 1$?',
    o: ['(−3, 4)', '(3, −4)', '(4, −5)', '(1, −1)'], a: 0,
    w: { 1: 'Ergibt −1.', 2: 'Ergibt 3.', 3: 'Ergibt 4.' },
    e: '17 · (−3) + 13 · 4 = −51 + 52 = 1. Solche Koeffizienten liefert der erweiterte euklidische Algorithmus. Sie sind nicht eindeutig: (10, −13) geht auch.',
    m: 'Bézout: gcd(a, b) = ua + vb für passende ganze u, v.', s: 'Skript DiskMath 4.2.3, Korollar 4.5' },

  { id: 'dm11-04', t: 'dm11', d: 2, k: 'sc',
    q: 'Welche Zahl liegt **nicht** im Ideal (12, 18) = {12u + 18v | u, v ∈ ℤ}?',
    o: ['9', '6', '−30', '0'], a: 0,
    w: { 1: '6 = 12 · (−1) + 18 · 1.', 2: '−30 = 12 · (−1) + 18 · (−1).', 3: 'u = v = 0.' },
    e: 'Das Ideal (12, 18) ist gleich (6), also die Menge aller Vielfachen von gcd(12, 18) = 6. 9 ist kein Vielfaches von 6.',
    m: '(a, b) = (gcd(a, b)).', s: 'Skript DiskMath 4.2.3, Lemma 4.3' },

  { id: 'dm11-05', t: 'dm11', d: 2, k: 'sc', fix: true,
    q: 'Es gilt gcd(a, b) = 6, lcm(a, b) = 180 und a = 36. Was ist b?',
    o: ['30', '5', '180', '6'], a: 0,
    e: 'Für positive Zahlen gilt gcd(a, b) · lcm(a, b) = a · b. Also b = 6 · 180 / 36 = 30. Kontrolle: gcd(36, 30) = 6, lcm(36, 30) = 180.',
    m: 'gcd · lcm = a · b (für a, b > 0).', s: 'Skript DiskMath 4.2–4.3' },

  { id: 'dm11-06', t: 'dm11', d: 3, k: 'tf',
    q: 'Für ganze Zahlen: wahr oder falsch?',
    rows: [
      ['Jede ganze Zahl teilt 0.', true, '0 = a · 0.'],
      ['0 teilt 0.', true, 'Es gibt ein c mit 0 = 0 · c, z. B. c = 5.'],
      ['Aus a ∣ b und b ∣ a folgt a = b.', false, 'a = 2, b = −2. Es folgt nur a = ±b.'],
      ['gcd(0, n) = |n| für n ≠ 0.', true, 'Jede Zahl teilt 0, der grösste Teiler von n ist |n|.'],
      ['Ist p prim und p ∣ ab, dann p ∣ a oder p ∣ b.', true, 'Lemma 4.7.']
    ],
    e: 'Die Definition „a ∣ b ⟺ ∃c: b = ac“ liefert in Grenzfällen manchmal überraschende Antworten.', m: 'Teilbarkeit in ℤ: Vorzeichen und die Null beachten.', s: 'Skript DiskMath 4.1–4.3' },

  { id: 'dm11-07', t: 'dm11', d: 2, k: 'sc', fix: true,
    q: 'Wie viele positive Teiler hat 360?',
    o: ['24', '12', '18', '30'], a: 0,
    e: '$360 = 2^3 \\cdot 3^2 \\cdot 5$. Ein Teiler wählt jeden Exponenten unabhängig: (3 + 1)(2 + 1)(1 + 1) = 24.',
    m: 'Anzahl Teiler = Produkt der (Exponent + 1).', s: 'Skript DiskMath 4.3, Theorem 4.6' },

  { id: 'dm11-08', t: 'dm11', d: 2, k: 'sc',
    q: 'Theorem 4.10 konstruiert lange Primzahllücken mit $n = (k + 1)! + 2$. Welche k = 4 aufeinanderfolgenden zusammengesetzten Zahlen liefert das?',
    o: ['122, 123, 124, 125', '24, 25, 26, 27', '26, 27, 28, 29', '120, 121, 122, 123'], a: 0,
    w: { 2: '29 ist eine Primzahl.' },
    e: 'n = 5! + 2 = 122. Für l = 2, …, 5 teilt l die Zahl 120 + l: 2 ∣ 122, 3 ∣ 123, 4 ∣ 124, 5 ∣ 125.',
    m: '(k + 1)! + l ist durch l teilbar für 2 ≤ l ≤ k + 1.', s: 'Skript DiskMath 4.4, Theorem 4.10' },

  { id: 'dm11-09', t: 'dm11', d: 2, k: 'sc',
    q: 'Um zu prüfen, ob 221 prim ist, welche Primzahlen muss man höchstens als Teiler testen?',
    o: ['2, 3, 5, 7, 11, 13', 'alle Primzahlen bis 110', '2, 3, 5, 7', 'alle Primzahlen bis 221'], a: 0,
    w: { 2: '13 ≤ √221 fehlt, und tatsächlich ist 221 = 13 · 17.' },
    e: 'Jede zusammengesetzte Zahl n hat einen Primteiler ≤ √n (Lemma 4.12). √221 ≈ 14,9. Man findet 221 = 13 · 17.',
    m: 'Primtest von Hand: nur Primteiler bis √n prüfen.', s: 'Skript DiskMath 4.4, Lemma 4.12' },

  { id: 'dm11-w1', t: 'dm11', d: 2, k: 'w',
    q: 'Berechne mit dem erweiterten euklidischen Algorithmus gcd(240, 46) und ganze Zahlen u, v mit $240u + 46v = \\gcd(240, 46)$. Tippe „u, v“ ein (die Lösung mit |u| < 23).',
    ans: { k: 'vec', v: [-9, 47], ph: 'u, v' },
    sol: [
      '240 = 5 · 46 + 10, 46 = 4 · 10 + 6, 10 = 1 · 6 + 4, 6 = 1 · 4 + 2, 4 = 2 · 2 + 0. Also gcd = 2.',
      'Rückwärts: 2 = 6 − 4 = 6 − (10 − 6) = 2 · 6 − 10.',
      '6 = 46 − 4 · 10: 2 = 2 · 46 − 9 · 10.',
      '10 = 240 − 5 · 46: 2 = 2 · 46 − 9 · 240 + 45 · 46 = 47 · 46 − 9 · 240.',
      'Probe: 47 · 46 = 2162, 9 · 240 = 2160, Differenz 2.'
    ],
    res: 'gcd = 2, u = −9, v = 47',
    m: 'Beim Rückwärtseinsetzen immer nur den letzten Rest ersetzen.', s: 'Skript DiskMath 4.2.3' },

  { id: 'dm11-w2', t: 'dm11', d: 2, k: 'w',
    q: 'Zeige mit Idealen bzw. Linearkombinationen: Für alle n ∈ ℤ ist gcd(2n + 1, 3n + 1) = 1.',
    hint: 'Finde ganze u, v mit u(2n + 1) + v(3n + 1) = 1.',
    sol: [
      'Jeder gemeinsame Teiler d von 2n + 1 und 3n + 1 teilt jede ganzzahlige Linearkombination.',
      '3 · (2n + 1) − 2 · (3n + 1) = 6n + 3 − 6n − 2 = 1.',
      'Also d ∣ 1, d. h. gcd(2n + 1, 3n + 1) = 1.'
    ],
    res: '3(2n + 1) − 2(3n + 1) = 1',
    m: 'Eine Linearkombination, die 1 ergibt, beweist Teilerfremdheit.', s: 'Skript DiskMath 4.2.3' },

  // ---------------- 4.5–4.6 Modulare Arithmetik ----------------
  { id: 'dm12-01', t: 'dm12', d: 1, k: 'sc', fix: true,
    q: 'Was ist $R_7(100)$?',
    o: ['2', '3', '1', '6'], a: 0,
    e: '100 = 14 · 7 + 2. $R_m(a)$ ist der Rest von a bei Division durch m, also eine Zahl in {0, …, m − 1}.',
    m: '$R_m(a)$ liegt immer in {0, …, m − 1}.', s: 'Skript DiskMath 4.5.1' },

  { id: 'dm12-02', t: 'dm12', d: 2, k: 'sc', fix: true,
    q: 'Was ist $R_{24}(11^{101})$?',
    o: ['11', '1', '13', '23'], a: 0,
    w: { 1: 'Das wäre ein gerader Exponent.' },
    e: '$11^2 = 121 = 5 \\cdot 24 + 1 \\equiv_{24} 1$. Also $11^{101} = (11^2)^{50} \\cdot 11 \\equiv_{24} 1 \\cdot 11 = 11$.',
    m: 'Eine Potenz suchen, die ≡ 1 ist, und den Exponenten zerlegen.', s: 'Skript DiskMath 4.5, Beispiel 4.13' },

  { id: 'dm12-03', t: 'dm12', d: 2, k: 'sc', fix: true,
    q: 'Was ist das multiplikative Inverse von 5 modulo 13?',
    o: ['8', '5', '3', '12'], a: 0,
    e: '5 · 8 = 40 = 3 · 13 + 1 ≡₁₃ 1. Es existiert, weil gcd(5, 13) = 1.',
    m: 'Inverses von a mod m existiert genau dann, wenn gcd(a, m) = 1.', s: 'Skript DiskMath 4.5.3, Lemma 4.18' },

  { id: 'dm12-04', t: 'dm12', d: 2, k: 'sc',
    q: 'Welche Kongruenz hat **keine** Lösung x?',
    o: ['$6x \\equiv_9 1$', '$4x \\equiv_9 1$', '$5x \\equiv_{12} 1$', '$7x \\equiv_{10} 1$'], a: 0,
    w: { 1: 'x = 7.', 2: 'x = 5.', 3: 'x = 3.' },
    e: 'gcd(6, 9) = 3 ≠ 1. Jedes 6x − 1 ist dann nicht durch 3 teilbar, also auch nicht durch 9.',
    m: 'ax ≡ₘ 1 lösbar ⟺ gcd(a, m) = 1.', s: 'Skript DiskMath 4.5.3, Lemma 4.18' },

  { id: 'dm12-05', t: 'dm12', d: 2, k: 'sc', fix: true,
    q: 'Welches x ∈ {0, …, 11} erfüllt $x \\equiv_3 1$ und $x \\equiv_4 2$?',
    o: ['10', '7', '4', '1'], a: 0,
    w: { 1: '7 ≡₄ 3.', 2: '4 ≡₃ 1, aber 4 ≡₄ 0.', 3: '1 ≡₄ 1.' },
    e: 'Kandidaten mit x ≡₄ 2: 2, 6, 10. Davon hat nur 10 den Rest 1 modulo 3. Nach dem chinesischen Restsatz ist die Lösung modulo 12 eindeutig.',
    m: 'CRT: teilerfremde Moduli → genau eine Lösung modulo dem Produkt.', s: 'Skript DiskMath 4.5.4, Theorem 4.19' },

  { id: 'dm12-06', t: 'dm12', d: 2, k: 'sc', fix: true,
    q: 'Was ist die letzte Ziffer von $3^{2026}$?',
    o: ['9', '3', '7', '1'], a: 0,
    e: 'Modulo 10: 3, 9, 7, 1, dann wiederholt es sich mit Periode 4. 2026 = 4 · 506 + 2, also $3^{2026} \\equiv_{10} 3^2 = 9$.',
    m: 'Letzte Ziffer = Rest modulo 10.', s: 'Skript DiskMath 4.5' },

  { id: 'dm12-07', t: 'dm12', d: 1, k: 'sc',
    q: 'Worauf beruht die Sicherheit des Diffie-Hellman-Schlüsselaustauschs?',
    o: ['Darauf, dass man aus $g^x \\bmod p$ das x nicht effizient berechnen kann (diskreter Logarithmus)', 'Darauf, dass man grosse Zahlen nicht effizient multiplizieren kann', 'Darauf, dass p geheim bleibt', 'Darauf, dass beide denselben geheimen Exponenten wählen'], a: 0,
    w: { 1: 'Multiplizieren und Potenzieren modulo p geht schnell.', 2: 'p und g sind öffentlich.', 3: 'Jeder wählt sein eigenes geheimes x.' },
    e: 'Alice sendet $g^{x_A}$, Bob $g^{x_B}$. Beide können $g^{x_A x_B}$ berechnen. Ein Lauscher kennt nur $g^{x_A}$ und $g^{x_B}$. Dafür ist kein effizientes Verfahren bekannt.',
    m: 'Potenzieren ist leicht, Logarithmieren modulo p schwer.', s: 'Skript DiskMath 4.6' },

  { id: 'dm12-08', t: 'dm12', d: 3, k: 'tf',
    q: 'm ≥ 2. Wahr oder falsch?',
    rows: [
      ['Aus $a \\equiv_m b$ folgt $a^2 \\equiv_m b^2$.', true, 'Kongruenzen sind mit Multiplikation verträglich (Lemma 4.14).'],
      ['Aus $a^2 \\equiv_m b^2$ folgt $a \\equiv_m b$.', false, 'm = 5: 1² ≡ 4², aber 1 ≢ 4.'],
      ['Aus $ac \\equiv_m bc$ und $c \\not\\equiv_m 0$ folgt $a \\equiv_m b$.', false, 'm = 6, c = 2, a = 0, b = 3. Kürzen geht nur, wenn gcd(c, m) = 1.'],
      ['$R_m(a + b) = R_m(R_m(a) + R_m(b))$', true, 'Korollar 4.17.'],
      ['Aus $a \\equiv_m b$ folgt $2^a \\equiv_m 2^b$.', false, 'm = 3: 0 ≡ 3, aber 2⁰ = 1 und 2³ = 8 ≡ 2.']
    ],
    e: 'Polynome in a, b sind verträglich mit ≡ₘ. Exponenten dagegen nicht: sie leben modulo der Ordnung, nicht modulo m.', m: 'Kürzen modulo m nur mit Faktoren, die zu m teilerfremd sind.', s: 'Skript DiskMath 4.5' },

  { id: 'dm12-w1', t: 'dm12', d: 2, k: 'w',
    q: 'Löse $17x \\equiv_{43} 5$. Gib x ∈ {0, …, 42} an.',
    ans: { k: 'num', v: 18 },
    sol: [
      'Inverses von 17 modulo 43 mit Euklid: 43 = 2 · 17 + 9, 17 = 1 · 9 + 8, 9 = 1 · 8 + 1.',
      'Rückwärts: 1 = 9 − 8 = 9 − (17 − 9) = 2 · 9 − 17 = 2 · (43 − 2 · 17) − 17 = 2 · 43 − 5 · 17.',
      'Also $17^{-1} \\equiv_{43} -5 \\equiv_{43} 38$.',
      'x ≡ 5 · 38 = 190 = 4 · 43 + 18, also x = 18. Probe: 17 · 18 = 306 = 7 · 43 + 5.'
    ],
    res: 'x = 18',
    m: 'Lineare Kongruenz: mit dem Inversen multiplizieren.', s: 'Skript DiskMath 4.5.3' },

  { id: 'dm12-w2', t: 'dm12', d: 3, k: 'w',
    q: 'Löse das System mit dem chinesischen Restsatz:\n$x \\equiv_4 1$, $x \\equiv_5 2$, $x \\equiv_7 3$.\nGib die Lösung in {0, …, 139} an.',
    ans: { k: 'num', v: 17 },
    sol: [
      'M = 4 · 5 · 7 = 140, M₁ = 35, M₂ = 28, M₃ = 20.',
      'Inverse: 35 ≡₄ 3, und 3 · 3 = 9 ≡₄ 1, also N₁ = 3. 28 ≡₅ 3, und 3 · 2 = 6 ≡₅ 1, also N₂ = 2. 20 ≡₇ 6, und 6 · 6 = 36 ≡₇ 1, also N₃ = 6.',
      'x ≡ 1 · 35 · 3 + 2 · 28 · 2 + 3 · 20 · 6 = 105 + 112 + 360 = 577.',
      '577 = 4 · 140 + 17, also x = 17. Probe: 17 ≡₄ 1, 17 ≡₅ 2, 17 ≡₇ 3.'
    ],
    res: 'x = 17 (modulo 140)',
    m: 'CRT: $x = \\sum a_i M_i N_i$ mit $N_i \\equiv M_i^{-1}$ modulo $m_i$.', s: 'Skript DiskMath 4.5.4, Theorem 4.19' },

  { id: 'dm12-w3', t: 'dm12', d: 2, k: 'w',
    q: 'Diffie-Hellman mit p = 23, g = 5. Alice wählt $x_A = 6$, Bob $x_B = 15$. Berechne die gesendeten Werte und den gemeinsamen Schlüssel.',
    ans: { k: 'num', v: 2 },
    hint: 'Quadriere wiederholt: 5² ≡ 2, 5⁴ ≡ 4, 5⁸ ≡ 16 (mod 23).',
    sol: [
      '$y_A = 5^6 = 5^4 \\cdot 5^2 \\equiv 4 \\cdot 2 = 8$.',
      '$y_B = 5^{15} = 5^8 \\cdot 5^4 \\cdot 5^2 \\cdot 5 \\equiv 16 \\cdot 4 \\cdot 2 \\cdot 5 = 640 \\equiv 640 - 27 \\cdot 23 = 19$.',
      'Alice rechnet $19^6$: $19 \\equiv -4$, also $(-4)^6 = 4096 = 178 \\cdot 23 + 2 \\equiv 2$.',
      'Bob rechnet $8^{15} = 2^{45}$. Weil $2^{11} = 2048 = 89 \\cdot 23 + 1 \\equiv 1$, ist $2^{45} = 2^{44} \\cdot 2 \\equiv 2$.'
    ],
    res: '$y_A = 8$, $y_B = 19$, Schlüssel 2',
    m: 'Square-and-multiply hält die Zahlen klein.', s: 'Skript DiskMath 4.6' },

  // ---------------- 5.1–5.2 Monoide und Gruppen ----------------
  { id: 'dm13-01', t: 'dm13', d: 1, k: 'sc',
    q: 'Welche Algebra ist eine Gruppe?',
    o: ['⟨ℤ; +⟩', '⟨ℤ; ·⟩', '⟨ℕ; +⟩', '⟨ℤ₆ ∖ {0}; ⊙⟩'], a: 0,
    w: { 1: '2 hat kein multiplikatives Inverses in ℤ.', 2: '1 hat kein additives Inverses in ℕ.', 3: 'Nicht abgeschlossen: 2 ⊙ 3 = 0.' },
    e: 'Gruppenaxiome: Assoziativität, neutrales Element, Inverse. Bei ⟨ℤ; +⟩ ist 0 neutral und −a invers.',
    m: 'Zuerst prüfen, ob die Operation überhaupt abgeschlossen ist.', s: 'Skript DiskMath 5.2, Definition 5.7' },

  { id: 'dm13-02', t: 'dm13', d: 1, k: 'sc',
    q: 'In einer Gruppe ⟨G; ∗, ^, e⟩: Was ist das Inverse von a ∗ b?',
    o: ['$\\hat{b} * \\hat{a}$', '$\\hat{a} * \\hat{b}$', '$a * b$', '$\\hat{a} * b$'], a: 0,
    w: { 1: 'Das stimmt nur in abelschen Gruppen.' },
    e: '$(a * b) * (\\hat{b} * \\hat{a}) = a * (b * \\hat{b}) * \\hat{a} = a * \\hat{a} = e$. Die Reihenfolge kehrt sich um.',
    m: 'Inverses eines Produkts: Reihenfolge umkehren.', s: 'Skript DiskMath 5.2, Lemma 5.3' },

  { id: 'dm13-03', t: 'dm13', d: 2, k: 'sc',
    q: 'Was ist ⟨{0, 1}*; ·, ε⟩, wobei · die Konkatenation von Bitfolgen ist?',
    o: ['Ein Monoid, aber keine Gruppe', 'Eine Gruppe', 'Keine Algebra, weil · nicht abgeschlossen ist', 'Eine abelsche Gruppe'], a: 0,
    w: { 1: 'Zu „0“ gibt es keine Folge w mit 0 · w = ε.', 3: 'Konkatenation ist nicht kommutativ: 01 ≠ 10.' },
    e: 'Konkatenation ist assoziativ und ε ist neutral, also ein Monoid. Weil Konkatenation nie kürzer macht, hat nur ε ein Inverses.',
    m: 'Monoid = assoziativ + neutrales Element.', s: 'Skript DiskMath 5.2, Definition 5.5' },

  { id: 'dm13-04', t: 'dm13', d: 2, k: 'sc',
    q: 'Im direkten Produkt ⟨ℤ₅; ⊕⟩ × ⟨ℤ₇; ⊕⟩: Was ist das Inverse von (2, 3)?',
    o: ['(3, 4)', '(−2, −3)', '(3, 3)', '(2, 4)'], a: 0,
    w: { 1: '−2 und −3 liegen nicht in ℤ₅ bzw. ℤ₇. Die Vertreter sind 3 und 4.' },
    e: 'Komponentenweise: 2 ⊕ 3 = 0 in ℤ₅ und 3 ⊕ 4 = 0 in ℤ₇. Das neutrale Element ist (0, 0), die Gruppe hat 35 Elemente.',
    m: 'Direktes Produkt: alles komponentenweise.', s: 'Skript DiskMath 5.2, Lemma 5.4' },

  { id: 'dm13-05', t: 'dm13', d: 1, k: 'sc',
    q: 'Welche Abbildung ist ein Gruppenhomomorphismus ⟨ℤ; +⟩ → ⟨ℤ; +⟩?',
    o: ['$x \\mapsto 3x$', '$x \\mapsto x + 1$', '$x \\mapsto x^2$', '$x \\mapsto |x|$'], a: 0,
    w: { 1: 'ψ(0) = 1 ≠ 0, ein Homomorphismus bildet e auf e ab.', 2: '(1 + 1)² ≠ 1² + 1².', 3: '|1 + (−1)| ≠ |1| + |−1|.' },
    e: 'ψ(a + b) = 3(a + b) = 3a + 3b = ψ(a) + ψ(b).',
    m: 'Homomorphismus: ψ(a ∗ b) = ψ(a) ⋆ ψ(b), daraus folgt ψ(e) = e′.', s: 'Skript DiskMath 5.2, Definition 5.10' },

  { id: 'dm13-06', t: 'dm13', d: 2, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['In einer Gruppe folgt aus a ∗ b = a ∗ c, dass b = c.', true, 'Links mit â multiplizieren.'],
      ['Jede Gruppe ist abelsch.', false, 'Permutationen von {1, 2, 3} unter Komposition sind nicht kommutativ.'],
      ['In einem Monoid hat jedes Element ein Inverses.', false, '⟨ℤ; ·⟩: 2 hat keines.'],
      ['Das neutrale Element eines Monoids ist eindeutig.', true, 'e = e ∗ e′ = e′ (Lemma 5.1).'],
      ['Gilt a ∗ a = a in einer Gruppe, dann ist a = e.', true, 'Mit â multiplizieren: a = e.']
    ],
    e: 'Kürzen ist in Gruppen erlaubt, weil Inverse existieren. In Monoiden nicht unbedingt.', m: 'Gruppe: kürzen erlaubt.', s: 'Skript DiskMath 5.2' },

  { id: 'dm13-w1', t: 'dm13', d: 2, k: 'w',
    q: 'Auf ℤ sei $a * b = a + b + 1$. Zeige, dass ⟨ℤ; ∗⟩ eine Gruppe ist: Gib das neutrale Element und das Inverse eines beliebigen a an. Was ist das Inverse von 5?',
    ans: { k: 'num', v: -7 },
    sol: [
      'Assoziativ: (a ∗ b) ∗ c = a + b + c + 2 = a ∗ (b ∗ c).',
      'Neutrales Element e: a + e + 1 = a ⟹ e = −1. Kontrolle: −1 ∗ a = a.',
      'Inverses â: a + â + 1 = −1 ⟹ â = −a − 2.',
      'Für a = 5: â = −7. Kontrolle: 5 + (−7) + 1 = −1 = e.'
    ],
    res: 'e = −1, â = −a − 2, Inverses von 5 ist −7',
    m: 'Das neutrale Element muss nicht 0 oder 1 sein.', s: 'Skript DiskMath 5.2' },

  // ---------------- 5.3 Struktur von Gruppen ----------------
  { id: 'dm14-01', t: 'dm14', d: 1, k: 'sc',
    q: 'Eine Gruppe G hat 12 Elemente. Welche Ordnung kann eine Untergruppe von G **nicht** haben?',
    o: ['5', '4', '6', '1'], a: 0,
    e: 'Satz von Lagrange: Die Ordnung jeder Untergruppe teilt |G|. 5 teilt 12 nicht.',
    m: 'Lagrange: |H| teilt |G|, also auch ord(a) teilt |G|.', s: 'Skript DiskMath 5.3, Theorem 5.8' },

  { id: 'dm14-02', t: 'dm14', d: 1, k: 'sc', fix: true,
    q: 'Was ist die Ordnung von 2 in $\\Z_7^*$?',
    o: ['3', '6', '2', '7'], a: 0,
    e: '2¹ = 2, 2² = 4, 2³ = 8 ≡ 1. Also ord(2) = 3. Das teilt |ℤ₇*| = 6, wie Lagrange verlangt.',
    m: 'ord(a) = kleinstes m ≥ 1 mit aᵐ = e.', s: 'Skript DiskMath 5.3, Definition 5.12' },

  { id: 'dm14-03', t: 'dm14', d: 2, k: 'sc', fix: true,
    q: 'Was ist φ(100)?',
    o: ['40', '50', '60', '99'], a: 0,
    e: '$100 = 2^2 \\cdot 5^2$, $\\varphi(100) = 100 \\cdot (1 - \\tfrac{1}{2})(1 - \\tfrac{1}{5}) = 40$. Das ist die Anzahl Zahlen in {1, …, 100}, die zu 100 teilerfremd sind.',
    m: '$\\varphi(m) = m \\prod_{p \\mid m} (1 - 1/p)$', s: 'Skript DiskMath 5.3, Definition 5.17' },

  { id: 'dm14-04', t: 'dm14', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Erzeuger hat die zyklische Gruppe ⟨ℤ₁₂; ⊕⟩?',
    o: ['4', '1', '6', '11'], a: 0,
    e: 'a erzeugt ℤ₁₂ genau dann, wenn ord(a) = 12/gcd(a, 12) = 12, also gcd(a, 12) = 1: die Erzeuger sind 1, 5, 7, 11.',
    m: 'In ⟨ℤₘ; ⊕⟩ gilt ord(a) = m / gcd(a, m).', s: 'Skript DiskMath 5.3, Definition 5.15' },

  { id: 'dm14-05', t: 'dm14', d: 3, k: 'sc',
    q: 'Ist $\\Z_8^* = \\{1, 3, 5, 7\\}$ zyklisch?',
    o: ['Nein, jedes Element hat Ordnung höchstens 2', 'Ja, 3 ist ein Erzeuger', 'Ja, jede Gruppe mit 4 Elementen ist zyklisch', 'Nein, weil 8 keine Primzahl ist'], a: 0,
    w: { 1: '3² = 9 ≡ 1.', 2: 'Gegenbeispiel ist genau diese Gruppe.', 3: 'ℤ₉* ist zyklisch, obwohl 9 keine Primzahl ist.' },
    e: '3² = 9, 5² = 25, 7² = 49 sind alle ≡ 1 modulo 8. Kein Element hat Ordnung 4. Das passt zu Theorem 5.15: 8 = 2³ hat nicht die Form 2, 4, pᵉ oder 2pᵉ.',
    m: 'Zyklisch ⟺ es gibt ein Element der Ordnung |G|.', s: 'Skript DiskMath 5.3, Theorem 5.15' },

  { id: 'dm14-06', t: 'dm14', d: 2, k: 'sc', fix: true,
    q: 'Was ist $R_7(3^{2026})$?',
    o: ['4', '1', '3', '2'], a: 0,
    e: 'In ℤ₇* gilt $a^6 = 1$ (Korollar 5.10, |ℤ₇*| = 6). 2026 = 6 · 337 + 4, also $3^{2026} \\equiv 3^4 = 81 = 11 \\cdot 7 + 4$.',
    m: '$a^{|G|} = e$: Exponenten modulo |G| reduzieren.', s: 'Skript DiskMath 5.3, Korollar 5.10' },

  { id: 'dm14-07', t: 'dm14', d: 2, k: 'sc',
    q: 'Welche Untergruppe von $\\Z_9^* = \\{1, 2, 4, 5, 7, 8\\}$ erzeugt 4?',
    o: ['{1, 4, 7}', '{1, 4}', '{1, 2, 4, 5, 7, 8}', '{1, 4, 7, 8}'], a: 0,
    w: { 3: 'Eine Untergruppe von ℤ₉* mit 4 Elementen kann es nach Lagrange nicht geben.' },
    e: '4¹ = 4, 4² = 16 ≡ 7, 4³ = 28 ≡ 1. Also ⟨4⟩ = {1, 4, 7} mit Ordnung 3, ein Teiler von 6.',
    m: '⟨a⟩ = {e, a, a², …}, |⟨a⟩| = ord(a).', s: 'Skript DiskMath 5.3, Definition 5.14' },

  { id: 'dm14-08', t: 'dm14', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Jede Gruppe von Primzahlordnung ist zyklisch.', true, 'Korollar 5.11.'],
      ['Eine Gruppe mit 10 Elementen kann ein Element der Ordnung 4 haben.', false, '4 teilt 10 nicht.'],
      ['Jede zyklische Gruppe ist abelsch.', true, '$a^i a^j = a^{i+j} = a^j a^i$.'],
      ['Jede abelsche Gruppe ist zyklisch.', false, '$\\Z_8^*$ ist abelsch, aber nicht zyklisch.'],
      ['Für eine Primzahl p hat $\\Z_p^*$ genau p − 1 Elemente.', true, 'Alle von 0 verschiedenen Reste sind teilerfremd zu p.']
    ],
    e: 'Lagrange liefert die meisten Antworten: Ordnungen teilen die Gruppenordnung.', m: 'Zyklisch ⟹ abelsch, nicht umgekehrt.', s: 'Skript DiskMath 5.3' },

  { id: 'dm14-w1', t: 'dm14', d: 3, k: 'w',
    q: 'Bestimme $\\Z_{15}^*$, φ(15) und die Ordnung jedes Elements. Ist die Gruppe zyklisch? Gib die grösste vorkommende Elementordnung ein.',
    ans: { k: 'num', v: 4 },
    sol: [
      '$\\Z_{15}^* = \\{1, 2, 4, 7, 8, 11, 13, 14\\}$, φ(15) = (3 − 1)(5 − 1) = 8.',
      'Ordnungen: ord(1) = 1. Ordnung 2: 4 (16 ≡ 1), 11 (121 ≡ 1), 14 (≡ −1).',
      'Ordnung 4: 2 (2, 4, 8, 1), 7 (7, 4, 13, 1), 8 (8, 4, 2, 1), 13 (13, 4, 7, 1).',
      'Kein Element hat Ordnung 8, also ist die Gruppe nicht zyklisch (passt zu Theorem 5.15: 15 = 3 · 5).'
    ],
    res: 'Grösste Ordnung 4, nicht zyklisch',
    m: 'Zyklisch genau dann, wenn ein Element Ordnung |G| hat.', s: 'Skript DiskMath 5.3' },

  { id: 'dm14-w2', t: 'dm14', d: 3, k: 'w',
    q: 'Beweise: Gilt in einer Gruppe G für **alle** a ∈ G, dass a ∗ a = e, dann ist G abelsch.',
    hint: 'Was folgt aus a ∗ a = e für das Inverse von a? Wende das auf a ∗ b an.',
    sol: [
      'Aus a ∗ a = e folgt â = a für alle a.',
      'Für beliebige a, b ist auch (a ∗ b) ∗ (a ∗ b) = e, also $\\widehat{a * b} = a * b$.',
      'Andererseits ist $\\widehat{a * b} = \\hat{b} * \\hat{a} = b * a$.',
      'Zusammen: a ∗ b = b ∗ a.'
    ],
    res: 'Jedes Element ist sein eigenes Inverses, daraus folgt Kommutativität.',
    m: 'Das Inverse des Produkts ist das Produkt der Inversen in umgekehrter Reihenfolge.', s: 'Skript DiskMath 5.2–5.3' },

  // ---------------- 5.4 RSA ----------------
  { id: 'dm15-01', t: 'dm15', d: 1, k: 'sc',
    q: 'Was bleibt bei RSA **geheim**?',
    o: ['d (und damit p, q bzw. φ(n))', 'n', 'e', 'die verschlüsselte Nachricht'], a: 0,
    w: { 1: 'n ist Teil des öffentlichen Schlüssels.', 2: 'e ist Teil des öffentlichen Schlüssels.', 3: 'Der Chiffretext wird offen übertragen.' },
    e: 'Öffentlich: (n, e). Geheim: d mit e · d ≡ 1 modulo φ(n). Wer p und q kennt, kann φ(n) und damit d berechnen. Deshalb müssen p und q geheim bleiben.',
    m: 'Sicherheit von RSA hängt an der Schwierigkeit, n zu faktorisieren.', s: 'Skript DiskMath 5.4' },

  { id: 'dm15-02', t: 'dm15', d: 2, k: 'sc', fix: true,
    q: 'RSA mit p = 5, q = 11, e = 3. Was ist d?',
    o: ['27', '7', '3', '37'], a: 0,
    e: 'n = 55, φ(n) = 4 · 10 = 40. d ist das Inverse von 3 modulo 40: 3 · 27 = 81 = 2 · 40 + 1.',
    m: 'd = e⁻¹ modulo (p − 1)(q − 1).', s: 'Skript DiskMath 5.4' },

  { id: 'dm15-03', t: 'dm15', d: 2, k: 'sc',
    q: 'RSA mit p = 5, q = 11. Welcher Exponent e ist **nicht** zulässig?',
    o: ['e = 5', 'e = 3', 'e = 7', 'e = 9'], a: 0,
    e: 'e muss teilerfremd zu φ(n) = 40 sein, sonst existiert kein d. gcd(5, 40) = 5.',
    m: 'gcd(e, φ(n)) = 1 ist Pflicht.', s: 'Skript DiskMath 5.4' },

  { id: 'dm15-04', t: 'dm15', d: 3, k: 'sc',
    q: 'Warum funktioniert die RSA-Entschlüsselung $(x^e)^d = x$ für $x \\in \\Z_n^*$?',
    o: ['Weil $ed = k \\cdot \\varphi(n) + 1$ und $x^{\\varphi(n)} = 1$ in der Gruppe $\\Z_n^*$', 'Weil e und d beide Primzahlen sind', 'Weil $x^n \\equiv_n x$ für alle x gilt', 'Weil die Multiplikation modulo n kommutativ ist'], a: 0,
    w: { 1: 'e und d müssen keine Primzahlen sein.', 2: 'Das gilt für zusammengesetzte n im Allgemeinen nicht.' },
    e: 'In einer endlichen Gruppe gilt $a^{|G|} = e$ (Korollar 5.10), hier mit $|\\Z_n^*| = \\varphi(n)$. Also $x^{ed} = (x^{\\varphi(n)})^k \\cdot x = x$. Das ist der Spezialfall von Theorem 5.16.',
    m: 'RSA ist Lagrange plus Inverses modulo φ(n).', s: 'Skript DiskMath 5.4, Theorem 5.16' },

  { id: 'dm15-w1', t: 'dm15', d: 2, k: 'w',
    q: 'RSA mit p = 7, q = 13, e = 5. Berechne n, φ(n) und d. Verschlüssele dann m = 10 (gib den Chiffretext ein).',
    ans: { k: 'num', v: 82 },
    sol: [
      'n = 91, φ(n) = 6 · 12 = 72.',
      'd = 5⁻¹ modulo 72: 5 · 29 = 145 = 2 · 72 + 1, also d = 29.',
      'Verschlüsseln: $10^5 \\bmod 91$. 10² = 100 ≡ 9, 10⁴ ≡ 81, 10⁵ ≡ 81 · 10 = 810 = 8 · 91 + 82.',
      'Chiffretext c = 82. (Probe: $82^{29} \\equiv_{91} 10$.)'
    ],
    res: 'n = 91, φ(n) = 72, d = 29, c = 82',
    m: 'Zwischenergebnisse sofort modulo n reduzieren.', s: 'Skript DiskMath 5.4' },

  // ---------------- 5.5 Ringe und Körper ----------------
  { id: 'dm16-01', t: 'dm16', d: 1, k: 'sc',
    q: 'Was ist die Charakteristik des Rings ℤ?',
    o: ['0', '∞', '1', 'nicht definiert'], a: 0,
    w: { 1: 'Per Definition setzt man 0, nicht ∞.' },
    e: 'Die Charakteristik ist die Ordnung von 1 in der additiven Gruppe. In ℤ wird 1 + 1 + … + 1 nie 0, dann ist die Charakteristik definitionsgemäss 0. In ℤₘ ist sie m.',
    m: 'Charakteristik „unendlich“ heisst 0.', s: 'Skript DiskMath 5.5, Definition 5.19' },

  { id: 'dm16-02', t: 'dm16', d: 1, k: 'sc',
    q: 'Was ist die Einheitengruppe $\\Z_{12}^*$ des Rings ℤ₁₂?',
    o: ['{1, 5, 7, 11}', '{1, 11}', '{1, 2, 3, …, 11}', '{1}'], a: 0,
    e: 'Eine Einheit hat ein multiplikatives Inverses. In ℤₘ sind das genau die zu m teilerfremden Reste: 5 · 5 = 25 ≡ 1, 7 · 7 = 49 ≡ 1, 11 · 11 = 121 ≡ 1.',
    m: 'Einheit = invertierbar, nicht zu verwechseln mit dem neutralen Element.', s: 'Skript DiskMath 5.5, Definition 5.20' },

  { id: 'dm16-03', t: 'dm16', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Nullteiler hat ℤ₁₂?',
    o: ['7', '4', '8', '11'], a: 0,
    e: 'Nullteiler sind a ≠ 0 mit ab = 0 für ein b ≠ 0. In ℤ₁₂ sind das genau die a ≠ 0 mit gcd(a, 12) > 1: 2, 3, 4, 6, 8, 9, 10. Jedes Element ≠ 0 ist also Einheit oder Nullteiler.',
    m: 'In ℤₘ: a ≠ 0 ist Einheit (gcd = 1) oder Nullteiler (gcd > 1).', s: 'Skript DiskMath 5.5, Definition 5.23' },

  { id: 'dm16-04', t: 'dm16', d: 1, k: 'mc',
    q: 'Welche Ringe sind Körper? Wähle alle.',
    o: ['ℤ₇', 'ℚ', 'ℝ', 'ℤ', 'ℤ₉'], a: [0, 1, 2],
    w: { 3: '2 ist keine Einheit.', 4: '3 ist ein Nullteiler: 3 · 3 = 0.' },
    e: 'Ein Körper ist ein nicht trivialer kommutativer Ring, in dem jedes Element ≠ 0 eine Einheit ist. ℤₘ ist genau dann ein Körper, wenn m prim ist (Theorem 5.23).',
    m: 'GF(p) = ℤₚ für Primzahlen p.', s: 'Skript DiskMath 5.5, Definition 5.26' },

  { id: 'dm16-05', t: 'dm16', d: 2, k: 'sc',
    q: 'Wie beweist man $a \\cdot 0 = 0$ in einem beliebigen Ring?',
    o: ['$a0 = a(0 + 0) = a0 + a0$, dann in der additiven Gruppe $a0$ abziehen', 'Durch Division durch a', 'Es ist ein Axiom', 'Durch Multiplikation mit $a^{-1}$'], a: 0,
    w: { 1: 'In Ringen gibt es keine allgemeine Division.', 2: 'Es folgt aus den Axiomen.', 3: 'a muss keine Einheit sein.' },
    e: 'Distributivgesetz und 0 + 0 = 0 liefern a0 = a0 + a0. In der additiven Gruppe darf man kürzen, also 0 = a0. Gekürzt wird additiv, nicht multiplikativ.',
    m: 'Ringbeweise kürzen additiv.', s: 'Skript DiskMath 5.5, Lemma 5.17' },

  { id: 'dm16-06', t: 'dm16', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Jeder Körper ist ein Integritätsbereich.', true, 'Theorem 5.24: eine Einheit ist nie Nullteiler.'],
      ['Jeder Integritätsbereich ist ein Körper.', false, 'ℤ ist ein Integritätsbereich, aber kein Körper.'],
      ['In ℤₘ ist a genau dann eine Einheit, wenn gcd(a, m) = 1.', true, 'Lemma 4.18.'],
      ['Ein Element eines kommutativen Rings kann Einheit und Nullteiler zugleich sein.', false, 'Aus ub = 0 folgt b = u⁻¹ub = 0.'],
      ['Die Charakteristik eines Integritätsbereichs ist 0 oder eine Primzahl.', true, 'Wäre sie n = kl, dann (k · 1)(l · 1) = 0 mit beiden Faktoren ≠ 0.']
    ],
    e: 'Nullteiler verhindern Kürzen. Integritätsbereiche haben keine, Körper erst recht nicht.', m: 'Körper ⊂ Integritätsbereiche ⊂ kommutative Ringe.', s: 'Skript DiskMath 5.5' },

  { id: 'dm16-07', t: 'dm16', d: 3, k: 'sc',
    q: 'Ist $2x + 1$ eine Einheit im Polynomring $\\Z_4[x]$?',
    o: ['Ja, denn $(2x + 1)^2 = 1$', 'Nein, Einheiten von R[x] sind immer konstant', 'Nein, weil der Grad 1 ist', 'Ja, aber nur in $\\Z_4$, nicht in $\\Z_4[x]$'], a: 0,
    w: { 1: 'Das gilt nur, wenn R ein Integritätsbereich ist (Lemma 5.22).', 2: 'Über einem Integritätsbereich wäre das richtig.' },
    e: '$(2x + 1)^2 = 4x^2 + 4x + 1 = 1$ in $\\Z_4$. Grund: $\\Z_4$ hat den Nullteiler 2, deshalb addieren sich Grade beim Multiplizieren nicht.',
    m: 'deg(ab) = deg(a) + deg(b) gilt nur über Integritätsbereichen.', s: 'Skript DiskMath 5.5.5, Lemma 5.22' },

  { id: 'dm16-08', t: 'dm16', d: 3, k: 'sc', fix: true,
    q: 'Welchen Grad hat $(2x + 1)(3x + 1)$ in $\\Z_6[x]$?',
    o: ['1', '2', '0', '3'], a: 0,
    e: '$(2x + 1)(3x + 1) = 6x^2 + 5x + 1 = 5x + 1$ in $\\Z_6$, weil 2 · 3 = 0. Der Grad ist 1, nicht 1 + 1.',
    m: 'Nullteiler im Koeffizientenring können den Leitterm auslöschen.', s: 'Skript DiskMath 5.5.5' },

  { id: 'dm16-w1', t: 'dm16', d: 1, k: 'w',
    q: 'Beweise aus den Ringaxiomen: In jedem Ring gilt $(-a)b = -(ab)$.',
    hint: 'Zeige, dass (−a)b das additive Inverse von ab ist.',
    sol: [
      'Zu zeigen: ab + (−a)b = 0, dann ist (−a)b wegen der Eindeutigkeit der Inversen gleich −(ab).',
      'Distributivgesetz: ab + (−a)b = (a + (−a))b = 0 · b.',
      '0 · b = 0 (wie a0 = 0, mit 0b = (0 + 0)b = 0b + 0b und additivem Kürzen).'
    ],
    res: 'ab + (−a)b = 0, also (−a)b = −(ab).',
    m: 'Inverse sind eindeutig, also genügt es zu zeigen, dass die Summe 0 ergibt.', s: 'Skript DiskMath 5.5, Lemma 5.17' },

  { id: 'dm16-w2', t: 'dm16', d: 3, k: 'w',
    q: 'Bestimme die Charakteristik des Rings $\\Z_4 \\times \\Z_6$ (komponentenweise Operationen). Ist er ein Integritätsbereich?',
    ans: { k: 'num', v: 12 },
    sol: [
      'Die Eins ist (1, 1). k · (1, 1) = (k mod 4, k mod 6) ist (0, 0) genau dann, wenn 4 ∣ k und 6 ∣ k.',
      'Das kleinste solche k ist lcm(4, 6) = 12.',
      'Kein Integritätsbereich: (1, 0) · (0, 1) = (0, 0) mit beiden Faktoren ≠ 0.'
    ],
    res: 'Charakteristik 12, Nullteiler (1, 0) und (0, 1)',
    m: 'Charakteristik eines Produkts = kgV der Charakteristiken.', s: 'Skript DiskMath 5.5, Definition 5.19' },

  // ---------------- 5.6 Polynome über Körpern ----------------
  { id: 'dm17-01', t: 'dm17', d: 1, k: 'sc',
    q: 'Wann heisst ein Polynom $a(x) \\in F[x]$ monisch?',
    o: ['Wenn der Leitkoeffizient 1 ist', 'Wenn alle Koeffizienten 0 oder 1 sind', 'Wenn es irreduzibel ist', 'Wenn der konstante Term 1 ist'], a: 0,
    e: 'Monisch: der Koeffizient vor der höchsten Potenz ist 1. Über einem Körper kann man jedes Polynom ≠ 0 durch Division durch den Leitkoeffizienten monisch machen.',
    m: 'Der ggT von Polynomen wird monisch gewählt, damit er eindeutig ist.', s: 'Skript DiskMath 5.6, Definition 5.27' },

  { id: 'dm17-02', t: 'dm17', d: 2, k: 'sc',
    q: 'Teilt $x + 3$ das Polynom $x^3 + 2x^2 + 4$ in $GF(5)[x]$?',
    o: ['Ja, Quotient $x^2 + 4x + 3$, Rest 0', 'Nein, Rest 4', 'Nein, Rest 1', 'Ja, Quotient $x^2 - x + 3$ in ℤ[x]'], a: 0,
    e: 'Kontrolle: $(x + 3)(x^2 + 4x + 3) = x^3 + 7x^2 + 15x + 9 \\equiv x^3 + 2x^2 + 4$ modulo 5. Also Rest 0.',
    m: 'Polynomdivision wie schriftliche Division, Koeffizienten modulo p.', s: 'Skript DiskMath 5.6, Theorem 5.25' },

  { id: 'dm17-03', t: 'dm17', d: 2, k: 'sc',
    q: 'Welches Polynom ist irreduzibel über GF(2)?',
    o: ['$x^2 + x + 1$', '$x^2 + 1$', '$x^2 + x$', '$x^2$'], a: 0,
    w: { 1: '$(x + 1)^2 = x^2 + 2x + 1 = x^2 + 1$ über GF(2).', 2: '$x(x + 1)$.', 3: '$x \\cdot x$.' },
    e: 'Ein Polynom vom Grad 2 ist reduzibel genau dann, wenn es ein Produkt zweier Polynome vom Grad 1 ist. Über GF(2) gibt es nur x und x + 1, und deren Produkte sind x², x² + x und x² + 1.',
    m: 'Kleine Grade: alle Produkte niedrigeren Grades auflisten.', s: 'Skript DiskMath 5.6, Definition 5.28' },

  { id: 'dm17-04', t: 'dm17', d: 2, k: 'sc', fix: true,
    q: 'Wie viele **monische** Polynome vom Grad 3 gibt es in $GF(5)[x]$?',
    o: ['125', '500', '625', '64'], a: 0,
    w: { 1: 'So viele Polynome vom Grad genau 3 gibt es insgesamt (Leitkoeffizient 1 bis 4).', 2: 'So viele Polynome vom Grad ≤ 3 gibt es.' },
    e: 'Leitkoeffizient fest 1, die drei übrigen Koeffizienten frei aus 5 Werten: $5^3 = 125$.',
    m: 'Monisch fixiert den Leitkoeffizienten.', s: 'Skript DiskMath 5.6' },

  { id: 'dm17-05', t: 'dm17', d: 2, k: 'sc',
    q: 'Was ist $\\gcd(x^2 - 1,\\ x^2 + 2x + 1)$ in ℚ[x]?',
    o: ['$x + 1$', '$x - 1$', '$(x + 1)^2$', '1'], a: 0,
    e: '$x^2 - 1 = (x - 1)(x + 1)$ und $x^2 + 2x + 1 = (x + 1)^2$. Der gemeinsame monische Teiler grössten Grades ist x + 1.',
    m: 'ggT von Polynomen: monisch und vom grössten Grad.', s: 'Skript DiskMath 5.6, Definition 5.29' },

  { id: 'dm17-06', t: 'dm17', d: 3, k: 'tf',
    q: 'F ist ein Körper. Wahr oder falsch?',
    rows: [
      ['Die Einheiten von F[x] sind genau die konstanten Polynome ≠ 0.', true, 'Grade addieren sich, also müssen beide Faktoren Grad 0 haben.'],
      ['Jedes Polynom vom Grad 1 ist irreduzibel.', true, 'Ein Faktor müsste Grad 0, also eine Einheit sein.'],
      ['Ein Polynom vom Grad 4 ohne Teiler vom Grad 1 ist irreduzibel.', false, 'Es kann Produkt zweier irreduzibler Polynome vom Grad 2 sein, z. B. $(x^2 + 1)^2$ über ℝ.'],
      ['Bei der Division mit Rest ist der Grad des Rests kleiner als der Grad des Divisors.', true, 'Theorem 5.25.'],
      ['Für a, b ≠ 0 gilt deg(ab) = deg(a) + deg(b).', true, 'F ist ein Integritätsbereich.']
    ],
    e: 'F[x] verhält sich wie ℤ: Division mit Rest, ggT, eindeutige Zerlegung in Irreduzible.', m: 'Grad 2 und 3: irreduzibel ⟺ kein Teiler vom Grad 1. Ab Grad 4 reicht das nicht mehr.', s: 'Skript DiskMath 5.6' },

  { id: 'dm17-07', t: 'dm17', d: 3, k: 'sc', fix: true,
    q: 'Wie viele monische irreduzible Polynome vom Grad 2 gibt es über GF(3)?',
    o: ['3', '9', '6', '1'], a: 0,
    w: { 1: 'So viele monische Polynome vom Grad 2 gibt es insgesamt.', 2: 'So viele sind reduzibel.' },
    e: 'Monisch vom Grad 2: 9 Stück. Reduzibel sind die Produkte (x − a)(x − b) mit a ≤ b: 3 mit a = b und 3 mit a < b, zusammen 6. Es bleiben 9 − 6 = 3 (x² + 1, x² + x + 2, x² + 2x + 2).',
    m: 'Irreduzible zählen: alle minus die Produkte.', s: 'Skript DiskMath 5.6' },

  { id: 'dm17-w1', t: 'dm17', d: 2, k: 'w',
    q: 'Dividiere in $GF(3)[x]$ mit Rest: $a(x) = x^3 + 2x + 1$ durch $b(x) = x + 1$. Gib Quotient und Rest an. Tippe den Rest ein.',
    ans: { k: 'num', v: 1 },
    sol: [
      'Erster Schritt: x³ : x = x². Abziehen: $x^3 + 2x + 1 - x^2(x + 1) = -x^2 + 2x + 1 = 2x^2 + 2x + 1$.',
      'Zweiter Schritt: 2x² : x = 2x. Abziehen: $2x^2 + 2x + 1 - 2x(x + 1) = 1$.',
      'Der Rest 1 hat Grad 0 < 1, fertig.',
      'Probe: $(x + 1)(x^2 + 2x) + 1 = x^3 + 3x^2 + 2x + 1 = x^3 + 2x + 1$ über GF(3).'
    ],
    res: 'Quotient $x^2 + 2x$, Rest 1',
    m: 'Bei jedem Schritt Koeffizienten modulo p reduzieren, −1 ist 2.', s: 'Skript DiskMath 5.6, Theorem 5.25' },

  { id: 'dm17-w2', t: 'dm17', d: 3, k: 'w',
    q: 'Berechne mit dem euklidischen Algorithmus $\\gcd(x^4 + x^2 + 1,\\ x^3 + 1)$ in $GF(2)[x]$.',
    sol: [
      '$x^4 + x^2 + 1 = x \\cdot (x^3 + 1) + (x^2 + x + 1)$, denn $x^4 + x^2 + 1 - (x^4 + x) = x^2 + x + 1$ (über GF(2) ist −x = x).',
      '$x^3 + 1 = (x + 1)(x^2 + x + 1) + 0$, denn $(x + 1)(x^2 + x + 1) = x^3 + 2x^2 + 2x + 1 = x^3 + 1$.',
      'Der letzte Rest ≠ 0 ist $x^2 + x + 1$, und er ist schon monisch.'
    ],
    res: '$\\gcd = x^2 + x + 1$',
    m: 'Euklid funktioniert in F[x] genau wie in ℤ, mit dem Grad als Mass.', s: 'Skript DiskMath 5.6' }
]);
