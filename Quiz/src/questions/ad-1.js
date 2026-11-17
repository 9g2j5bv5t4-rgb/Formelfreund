// AlgoDat Teil 1: Kapitel 1 (Einleitung), 2 (Suchen), 3 (Sortieren), 4 (ADT)
QUIZ.add('ad', [
  // ---------------- 1.1–1.3 Pasture Break, Induktion, Starsuche ----------------
  { id: 'ad1-01', t: 'ad1', d: 1, k: 'sc', fix: true,
    q: 'Pasture Break: Die Kuh **kennt** die Distanz k zur Lücke, weiss aber nicht, auf welcher Seite sie liegt. Wie viele Schritte braucht die beste Strategie im Worst Case?',
    o: ['3k', '2k', '4k', '9k'], a: 0,
    w: { 1: 'Liegt die Lücke auf der zweiten Seite, muss die Kuh k hin, k zurück und k auf die andere Seite.', 3: 'Das ist die Schranke ohne bekannte Distanz.' },
    e: 'k Schritte nach links, falls dort nichts ist, 2k Schritte nach rechts. Worst Case: 3k.',
    m: 'Bekannte Distanz: 3k. Unbekannte Distanz mit Verdoppeln: 9k.', s: 'Skript AuD 1.1.2' },

  { id: 'ad1-02', t: 'ad1', d: 2, k: 'sc', fix: true,
    q: 'Pasture Break, Algorithmus 1: Die Distanz zum Start wächst bei jedem Richtungswechsel um 1 (1 links, 2 rechts, 3 links, …). Wie viele Schritte braucht die Kuh im Worst Case für k = 10?',
    o: ['120', '30', '90', '210'], a: 0,
    w: { 2: 'Das ist die Schranke 9k des Verdopplungsalgorithmus.' },
    e: 'Worst Case: 2 · (1 + 2 + … + k) + k = k(k + 1) + k = k(k + 2). Für k = 10 sind das 120 Schritte. Der Aufwand wächst quadratisch.',
    m: 'Gleichmässig wachsende Distanzen → quadratischer Aufwand.', s: 'Skript AuD 1.1.2' },

  { id: 'ad1-03', t: 'ad1', d: 2, k: 'sc',
    q: 'Beim Verdopplungsalgorithmus läuft die Kuh 1, 2, 4, 8, … Schritte abwechselnd links und rechts. Welche Worst-Case-Schranke gilt?',
    o: ['9k', '3k', '4k', '$k \\log_2 k$'], a: 0,
    w: { 1: 'Nur mit bekannter Distanz erreichbar.' },
    e: 'Mit $2^{i-1} < k \\le 2^i$ läuft die Kuh $2(2^0 + \\ldots + 2^i) + k = 2(2^{i+1} - 1) + k < 8k + k$. Schneller wachsende Distanzen verschlechtern den Worst Case, 9k ist bestmöglich.',
    m: 'Pro Runde etwa so viel Neues erkunden, wie man schon kennt.', s: 'Skript AuD 1.1.2' },

  { id: 'ad1-04', t: 'ad1', d: 1, k: 'sc',
    q: 'Warum gibt es in einer Gruppe **höchstens einen** Star?',
    o: ['Ist Pₛ ein Star, dann kennen alle anderen Pₛ und sind deshalb selbst kein Star', 'Weil ein Star niemanden kennt', 'Weil höchstens eine Person alle anderen kennt', 'Das stimmt nicht, es kann zwei geben'], a: 0,
    w: { 1: 'Das ist nur die halbe Definition.' },
    e: 'Ein Star kennt niemanden. Wenn Pₛ ein Star ist, kennt jede andere Person Pₛ, kann also selbst kein Star sein.',
    m: 'Star: wird von allen gekannt und kennt niemanden.', s: 'Skript AuD 1.3' },

  { id: 'ad1-05', t: 'ad1', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Fragen „Kennt Pᵢ die Person Pⱼ?“ braucht die verbesserte Starsuche im Worst Case für n = 10 Personen?',
    o: ['26', '90', '18', '30'], a: 0,
    w: { 1: 'n(n − 1): so viele braucht der naive Algorithmus.', 2: '2(n − 1): das ist der Best Case des einfachen rekursiven Algorithmus.' },
    e: 'Basisfall mit 2 Personen: 2 Fragen. Jede weitere Person kostet höchstens 3 Fragen (eine im Schritt 0, zwei für den Test). 2 + 3 · (n − 2) = 3n − 4 = 26.',
    m: 'Verbesserte Starsuche: 3n − 4 Fragen.', s: 'Skript AuD 1.3' },

  { id: 'ad1-06', t: 'ad1', d: 3, k: 'sc',
    q: 'In der verbesserten Starsuche wird vor dem rekursiven Aufruf gefragt, ob Pₙ₋₁ die Person Pₙ kennt. Falls ja, werden die beiden vertauscht. Warum ist das danach entfernte Pₙ sicher **kein** Star?',
    o: ['War das alte Pₙ ein Star, wurde getauscht, und das neue Pₙ kennt jemanden. Wurde nicht getauscht, kennt das alte Pₙ₋₁ das alte Pₙ nicht, also ist Pₙ kein Star', 'Weil Pₙ immer mindestens eine Person kennt', 'Weil Stars nie am Ende der Liste stehen', 'Weil der Tausch die Star-Eigenschaft zerstört'], a: 0,
    e: 'Fall Tausch: das neue Pₙ (altes Pₙ₋₁) kennt das alte Pₙ, also kennt es jemanden und ist kein Star. Fall kein Tausch: Pₙ₋₁ kennt Pₙ nicht, also wird Pₙ nicht von allen gekannt. In beiden Fällen kann man Pₙ ohne Verlust aus der Rekursion nehmen.',
    m: 'Vor der Rekursion eine Person entfernen, die garantiert kein Star ist.', s: 'Skript AuD 1.3' },

  { id: 'ad1-07', t: 'ad1', d: 2, k: 'sc',
    q: 'Im Induktionsbeweis der Bernoulli-Ungleichung $(1 + x)^n \\ge 1 + nx$ wird die Annahme mit $(1 + x)$ multipliziert. Wofür braucht man die Voraussetzung $x \\ge -1$?',
    o: ['Damit $1 + x \\ge 0$ ist und die Ungleichung beim Multiplizieren ihre Richtung behält', 'Damit $nx^2 \\ge 0$ ist', 'Damit die Basis n = 1 stimmt', 'Damit $1 + nx$ positiv ist'], a: 0,
    w: { 1: '$nx^2 \\ge 0$ gilt für jedes reelle x.', 2: 'Die Basis gilt für alle x.' },
    e: 'Multipliziert man eine Ungleichung mit einer negativen Zahl, kehrt sich die Richtung um. Deshalb braucht der Schritt $(1 + x)^{n+1} \\ge (1 + nx)(1 + x)$ die Bedingung $1 + x \\ge 0$.',
    m: 'Ungleichungen nur mit nicht negativen Zahlen multiplizieren.', s: 'Skript AuD 1.2' },

  { id: 'ad1-w1', t: 'ad1', d: 1, k: 'w',
    q: 'Für die verbesserte Starsuche gilt F(2) = 2 und F(n) = F(n − 1) + 3 für n ≥ 3. Beweise per Induktion: F(n) = 3n − 4 für alle n ≥ 2.',
    sol: [
      'Induktionsanfang n = 2: F(2) = 2 = 3 · 2 − 4.',
      'Induktionsannahme: F(n) = 3n − 4 für ein n ≥ 2.',
      'Schritt: F(n + 1) = F(n) + 3 = 3n − 4 + 3 = 3(n + 1) − 4.',
      'Damit gilt die Formel für alle n ≥ 2.'
    ],
    res: 'F(n) = 3n − 4',
    m: 'Rekurrenz plus Vermutung, dann Induktion: das Standardrezept.', s: 'Skript AuD 1.2–1.3' },

  { id: 'ad1-w2', t: 'ad1', d: 3, k: 'w',
    q: 'Pasture Break mit **Verdreifachen** statt Verdoppeln: Die Kuh läuft 1, 3, 9, 27, … Schritte abwechselnd links und rechts (jeweils zurück zum Start). Schätze den Worst Case nach oben ab wie im Skript. Ist das besser als 9k?',
    hint: 'Wähle i mit $3^{i-1} < k \\le 3^i$ und denk an den Fall, in dem die Kuh bei $3^{i-1}$ knapp an der falschen Seite umkehrt.',
    sol: [
      'Worst Case: Die Lücke liegt in Distanz k knapp hinter $3^{i-1}$ auf der Seite, die zuletzt mit Distanz $3^{i-1}$ besucht wurde. Die Kuh läuft also alle Runden mit Distanzen $3^0, \\ldots, 3^i$ hin und zurück und findet die Lücke erst in der nächsten Runde nach k Schritten.',
      'Schritte: $2(3^0 + 3^1 + \\ldots + 3^i) + k = 2 \\cdot \\frac{3^{i+1} - 1}{2} + k < 3^{i+1} + k$.',
      'Mit $3^{i+1} = 9 \\cdot 3^{i-1} < 9k$ folgt eine Schranke von etwa $9k + k = 10k$.',
      'Das ist schlechter als 9k. Zu schnelles Wachstum verschwendet Schritte in die falsche Richtung.'
    ],
    res: 'Etwa 10k im Worst Case, also schlechter als Verdoppeln (9k).',
    m: 'Verdoppeln ist der optimale Kompromiss.', s: 'Skript AuD 1.1.2' },

  // ---------------- 1.4–1.5 Asymptotik, Karatsuba ----------------
  { id: 'ad2-01', t: 'ad2', d: 1, k: 'sc',
    q: 'Für welche Funktion f gilt $10n^{1.6} + 1000n + 100 = \\Theta(f(n))$?',
    o: ['$n^{1.6}$', '$n$', '$n^2$', '$1000n$'], a: 0,
    w: { 2: 'Obere Schranke ja, aber nicht Θ.', 3: 'Wächst langsamer als $n^{1.6}$.' },
    e: 'Der Term mit dem grössten Wachstum dominiert, Konstanten fallen weg. Für n ≥ 1 ist der Quotient durch $n^{1.6}$ beschränkt (z. B. durch 1110) und mindestens 10.',
    m: 'Θ = gleiches Wachstum bis auf konstante Faktoren.', s: 'Skript AuD 1.4' },

  { id: 'ad2-02', t: 'ad2', d: 2, k: 'mc',
    q: 'Für welche g gilt $g(n) \\le O(n^2)$ (Eingabegrössen n ≥ 2)? Wähle alle.',
    o: ['$n \\log n$', '$1000n^2 + n$', '$n^2 \\log n$', '$2^{\\log_2 n}$', '$n^3 / 1000$'], a: [0, 1, 3],
    w: { 2: 'Der Quotient $\\log n$ ist unbeschränkt.', 3: 'Das ist einfach n.', 4: 'Konstante Faktoren ändern die Ordnung nicht, $n^3$ wächst schneller.' },
    e: '$g \\le O(f)$ heisst: $g(n)/f(n)$ ist beschränkt. Kleine Konstanten wie 1/1000 retten ein schnelleres Wachstum nicht.',
    m: 'Quotient beschränkt → O.', s: 'Skript AuD 1.4' },

  { id: 'ad2-03', t: 'ad2', d: 2, k: 'sc',
    q: 'Welche Reihenfolge ist aufsteigend nach Wachstum?',
    o: ['$\\log n,\\ \\sqrt{n},\\ n,\\ n \\log n,\\ n^{1.58},\\ n^2,\\ 2^n,\\ n!$', '$\\sqrt{n},\\ \\log n,\\ n,\\ n^{1.58},\\ n \\log n,\\ n^2,\\ n!,\\ 2^n$', '$\\log n,\\ \\sqrt{n},\\ n \\log n,\\ n,\\ n^2,\\ n^{1.58},\\ 2^n,\\ n!$', '$\\log n,\\ n,\\ \\sqrt{n},\\ n \\log n,\\ n^{1.58},\\ 2^n,\\ n^2,\\ n!$'], a: 0,
    e: 'Logarithmen wachsen langsamer als jede Potenz $n^\\varepsilon$. $n \\log n$ liegt zwischen n und $n^{1+\\varepsilon}$. Exponentialfunktionen schlagen jedes Polynom, und n! wächst noch schneller als $2^n$.',
    m: 'log < Potenz < Exponential < Fakultät.', s: 'Skript AuD 1.4' },

  { id: 'ad2-04', t: 'ad2', d: 2, k: 'sc',
    q: 'Karatsuba ersetzt 4 Teilprodukte durch 3. Welche Laufzeit ergibt sich für zwei n-stellige Zahlen?',
    o: ['$O(n^{\\log_2 3}) \\approx O(n^{1.585})$', '$O(n^2)$', '$O(n \\log n)$', '$O(n^{1.5})$'], a: 0,
    w: { 1: 'Das ist der Schulalgorithmus.' },
    e: 'Rekursion T(n) = 3T(n/2) + O(n). Auf Ebene i gibt es $3^i$ Teilprobleme der Grösse $n/2^i$. Die letzte Ebene dominiert mit $3^{\\log_2 n} = n^{\\log_2 3}$ Teilproblemen.',
    m: 'Ein Teilprodukt weniger pro Ebene → $n^{\\log_2 3}$.', s: 'Skript AuD 1.5.2' },

  { id: 'ad2-05', t: 'ad2', d: 3, k: 'sc',
    q: 'Karatsuba für zweistellige Zahlen braucht $a_0 b_1 + a_1 b_0$, berechnet aber nur drei Produkte. Welche Identität steckt dahinter?',
    o: ['$a_0 b_1 + a_1 b_0 = a_0 b_0 + a_1 b_1 - (a_1 - a_0)(b_1 - b_0)$', '$a_0 b_1 + a_1 b_0 = (a_0 + a_1)(b_0 + b_1)$', '$a_0 b_1 + a_1 b_0 = a_0 b_0 \\cdot a_1 b_1$', '$a_0 b_1 + a_1 b_0 = (a_1 - a_0)(b_1 - b_0) - a_0 b_0$'], a: 0,
    w: { 1: 'Da fehlen $- a_0 b_0 - a_1 b_1$.' },
    e: '$(a_1 - a_0)(b_1 - b_0) = a_1 b_1 - a_1 b_0 - a_0 b_1 + a_0 b_0$. Also ist $a_0 b_0 + a_1 b_1 - (a_1 - a_0)(b_1 - b_0) = a_1 b_0 + a_0 b_1$. Die Produkte $a_0 b_0$ und $a_1 b_1$ werden ohnehin gebraucht.',
    m: 'Gemischte Terme aus bereits berechneten Produkten gewinnen.', s: 'Skript AuD 1.5.2' },

  { id: 'ad2-06', t: 'ad2', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['$\\log_2(n!) \\le O(n \\log n)$', true, '$n! \\le n^n$.'],
      ['$2^{n+1} \\le O(2^n)$', true, '$2^{n+1} = 2 \\cdot 2^n$.'],
      ['$2^{2n} \\le O(2^n)$', false, 'Der Quotient $2^n$ ist unbeschränkt.'],
      ['$\\log_2 n = \\Theta(\\log_{10} n)$', true, 'Logarithmen zu verschiedenen Basen unterscheiden sich um einen konstanten Faktor.'],
      ['$\\sqrt{n} \\le O(\\log^2 n)$', false, 'Jede Potenz $n^\\varepsilon$ wächst schneller als jede Potenz von log n.']
    ],
    e: 'Faktoren im Exponenten sind keine konstanten Faktoren mehr: $2^{2n} = 4^n$.', m: 'Konstante vor der Funktion: egal. Konstante im Exponenten: nicht egal.', s: 'Skript AuD 1.4' },

  { id: 'ad2-07', t: 'ad2', d: 2, k: 'sc', fix: true,
    q: 'Wie viele einstellige Multiplikationen braucht Karatsuba für zwei Zahlen mit n = 8 Stellen (rekursiv bis zu einer Stelle)?',
    o: ['27', '64', '24', '16'], a: 0,
    w: { 1: 'So viele braucht der Schulalgorithmus: n².' },
    e: 'Jede Halbierung verdreifacht die Zahl der Teilprodukte: 8 = 2³ Stellen → $3^3 = 27$ einstellige Produkte.',
    m: 'Karatsuba: $3^{\\log_2 n}$ Elementarprodukte.', s: 'Skript AuD 1.5.2' },

  { id: 'ad2-w1', t: 'ad2', d: 2, k: 'w',
    q: 'Zeige mit der Definition aus dem Skript (Eingabegrössen n ≥ 2):\n1. $3n^2 + 5n \\log_2 n \\le O(n^2)$, gib eine Konstante C an.\n2. $n^2 \\le O(n \\log_2 n)$ gilt **nicht**.',
    sol: [
      '1. Für n ≥ 2 ist $\\log_2 n \\le n$. Also $3n^2 + 5n \\log_2 n \\le 3n^2 + 5n^2 = 8n^2$. Mit C = 8 gilt die Definition.',
      '2. Der Quotient $\\frac{n^2}{n \\log_2 n} = \\frac{n}{\\log_2 n}$ ist unbeschränkt (z. B. für $n = 2^k$ ergibt sich $2^k / k \\to \\infty$).',
      'Gäbe es C mit $n^2 \\le C n \\log_2 n$ für alle n, wäre $n / \\log_2 n \\le C$ beschränkt. Widerspruch.'
    ],
    res: 'C = 8 für Teil 1, Teil 2 über einen unbeschränkten Quotienten.',
    m: 'O-Nachweis: Konstante angeben. Gegenbeweis: Quotient unbeschränkt.', s: 'Skript AuD 1.4' },

  { id: 'ad2-w2', t: 'ad2', d: 3, k: 'w',
    q: 'Löse die Rekurrenz $T(1) = 1$, $T(n) = 3T(n/2) + n$ für Zweierpotenzen $n = 2^k$ (Teleskopieren oder Rekursionsbaum) und zeige $T(n) \\le O(n^{\\log_2 3})$.',
    hint: 'Auf Ebene i des Rekursionsbaums gibt es $3^i$ Knoten mit Kosten je $n/2^i$.',
    sol: [
      'Ebene i (i = 0, …, k − 1) kostet $3^i \\cdot n / 2^i = n (3/2)^i$. Die Blätter (Ebene k) kosten $3^k \\cdot T(1) = 3^k$.',
      'Summe: $T(n) = n \\sum_{i=0}^{k-1} (3/2)^i + 3^k = n \\cdot \\frac{(3/2)^k - 1}{1/2} + 3^k = 2n((3/2)^k - 1) + 3^k$.',
      'Mit $n = 2^k$: $2n (3/2)^k = 2 \\cdot 3^k$, also $T(n) = 3 \\cdot 3^k - 2n$.',
      '$3^k = 3^{\\log_2 n} = n^{\\log_2 3}$. Also $T(n) = 3n^{\\log_2 3} - 2n \\le O(n^{\\log_2 3})$.'
    ],
    res: '$T(n) = 3n^{\\log_2 3} - 2n = \\Theta(n^{1.585})$',
    m: 'Geometrische Reihe mit Quotient > 1: die letzte Ebene dominiert.', s: 'Skript AuD 1.5.2' },

  // ---------------- 1.6 Maximum Subarray Sum ----------------
  { id: 'ad3-01', t: 'ad3', d: 1, k: 'sc',
    q: 'Welche Laufzeit hat der Divide-and-Conquer-Algorithmus für Maximum Subarray Sum?',
    o: ['Θ(n log n)', 'Θ(n)', 'Θ(n²)', 'Θ(n³)'], a: 0,
    w: { 1: 'Das ist der induktive Algorithmus.', 2: 'Das sind die Präfixsummen.', 3: 'Das ist der naive Algorithmus.' },
    e: 'Zwei Hälften rekursiv plus das beste Teilarray über die Mitte in linearer Zeit: T(n) = 2T(n/2) + O(n) = O(n log n).',
    m: 'MSS: naiv n³, Präfixsummen n², D&C n log n, induktiv n.', s: 'Skript AuD 1.6, Theorem 1.3' },

  { id: 'ad3-02', t: 'ad3', d: 2, k: 'sc', fix: true,
    q: 'Was ist die Maximum Subarray Sum von (2, −3, 4, −1, 2, −5, 3)?',
    o: ['5', '4', '6', '3'], a: 0,
    e: 'Das Teilarray (4, −1, 2) hat Summe 5. Länger lohnt nicht: mit −5 und 3 kommt man nur auf 3, mit 2, −3 davor auf 4.',
    m: 'Negative Elemente lohnen sich, wenn danach genug Positives kommt.', s: 'Skript AuD 1.6' },

  { id: 'ad3-03', t: 'ad3', d: 2, k: 'sc', fix: true,
    q: 'Was ist nach der Definition im Skript die Maximum Subarray Sum von (−4, −1, −7)?',
    o: ['0', '−1', '−12', 'nicht definiert'], a: 0,
    w: { 1: 'Das wäre richtig, wenn das leere Teilarray nicht erlaubt wäre.' },
    e: 'Das leere Teilarray mit Summe 0 ist ausdrücklich zugelassen. Bei lauter negativen Zahlen ist es optimal.',
    m: 'Definition genau lesen: das leere Teilarray zählt.', s: 'Skript AuD 6.2, Definition 6.1' },

  { id: 'ad3-04', t: 'ad3', d: 3, k: 'sc',
    q: 'Der induktive Θ(n)-Algorithmus hält eine Variable randmax, die nach Element i wie folgt aktualisiert wird: randmax ← max(randmax + aᵢ, 0). Was ist randmax?',
    o: ['Die grösste Summe eines (eventuell leeren) Teilarrays, das genau bei Position i endet', 'Die Maximum Subarray Sum von a₁, …, aᵢ', 'Die Summe a₁ + … + aᵢ', 'Das grösste Element unter a₁, …, aᵢ'], a: 0,
    w: { 1: 'Dafür gibt es die zweite Variable, das bisherige Maximum.' },
    e: 'Ein bestes Teilarray, das bei i endet, ist entweder leer oder ein bestes bei i − 1 endendes plus aᵢ. Das Gesamtmaximum ist das Maximum aller randmax-Werte.',
    m: 'Induktiv: die Lösung für i aus der Lösung für i − 1 und einem „Randwert“ aufbauen.', s: 'Skript AuD 1.6, Theorem 1.4' },

  { id: 'ad3-05', t: 'ad3', d: 2, k: 'sc',
    q: 'Warum braucht jeder Algorithmus für Maximum Subarray Sum Ω(n) Zeit?',
    o: ['Ein Element, das er nie liest, könnte riesig sein und die Lösung ändern', 'Weil die Ausgabe Länge n hat', 'Weil man sortieren muss', 'Weil die Präfixsummen n Additionen brauchen'], a: 0,
    w: { 1: 'Die Ausgabe ist eine einzige Zahl.' },
    e: 'Liest ein Algorithmus aᵢ nicht, kann man aᵢ so gross machen, dass das optimale Teilarray aᵢ enthält. Der Algorithmus würde dieselbe Antwort geben, also eine falsche.',
    m: 'Untere Schranke durch einen Gegenspieler: nicht gelesene Eingaben ändern.', s: 'Skript AuD 1.6' },

  { id: 'ad3-w1', t: 'ad3', d: 2, k: 'w',
    q: 'Führe den induktiven Algorithmus für (−2, 5, −1, −3, 4, 2, −6, 3) aus. Notiere nach jedem Element randmax und das bisherige Maximum. Was ist die Maximum Subarray Sum?',
    ans: { k: 'num', v: 7 },
    sol: [
      'Start: randmax = 0, max = 0.',
      '−2: randmax = max(−2, 0) = 0. 5: randmax = 5, max = 5. −1: randmax = 4. −3: randmax = 1.',
      '4: randmax = 5. 2: randmax = 7, max = 7. −6: randmax = 1. 3: randmax = 4.',
      'Ergebnis 7, zum Teilarray (5, −1, −3, 4, 2).'
    ],
    res: 'Maximum Subarray Sum = 7',
    m: 'Wird randmax negativ, beginnt man neu bei 0.', s: 'Skript AuD 1.6' },

  // ---------------- 2 Suchen ----------------
  { id: 'ad4-01', t: 'ad4', d: 1, k: 'sc',
    q: 'Wie viele Vergleiche braucht binäre Suche in einem sortierten Array der Länge n im Worst Case?',
    o: ['O(log n)', 'O(n)', 'O(1)', 'O(n log n)'], a: 0,
    e: 'Jeder Vergleich halbiert den Suchbereich. Nach etwa $\\log_2 n$ Schritten ist er leer.',
    m: 'Halbieren → logarithmisch.', s: 'Skript AuD 2.2' },

  { id: 'ad4-02', t: 'ad4', d: 2, k: 'sc', fix: true,
    q: 'Mindestens wie viele Vergleiche braucht **jeder** vergleichsbasierte Suchalgorithmus im Worst Case für ein sortiertes Array mit n = 1000 Elementen?',
    o: ['10', '9', '500', '1000'], a: 0,
    w: { 1: '$2^9 = 512 < 1001$.' },
    e: 'Der Entscheidungsbaum braucht mindestens n + 1 = 1001 Blätter (n Positionen und „nicht gefunden“). Ein Binärbaum der Höhe h hat höchstens $2^h$ Blätter, also $2^h \\ge 1001$ und $h \\ge 10$.',
    m: 'Untere Schranke: Anzahl möglicher Ausgaben → Blätter → Höhe.', s: 'Skript AuD 2.2.1' },

  { id: 'ad4-03', t: 'ad4', d: 2, k: 'sc',
    q: 'Binäre Suche nach 8 in (1, 3, 5, 7, 9, 11, 13), jeweils mit dem mittleren Element (bei gerader Länge das linke). Mit welchen Elementen wird verglichen?',
    o: ['7, 11, 9', '7, 9', '7, 11, 9, 8', '1, 3, 5, 7, 9'], a: 0,
    w: { 1: 'Nach 7 ist der Bereich (9, 11, 13), die Mitte ist 11.', 2: '8 ist nicht im Array.' },
    e: 'Mitte 7 < 8 → rechts (9, 11, 13). Mitte 11 > 8 → links (9). Vergleich mit 9 > 8 → Bereich leer, „nicht gefunden“. 3 Vergleiche = $\\lceil \\log_2 8 \\rceil$.',
    m: 'Binäre Suche bricht ab, wenn der Bereich leer ist.', s: 'Skript AuD 2.2' },

  { id: 'ad4-04', t: 'ad4', d: 2, k: 'sc',
    q: 'Warum ist das Argument „Lineare Suche schaut jedes Element an, also braucht Suchen in unsortierten Arrays Ω(n)“ **kein** Beweis einer unteren Schranke?',
    o: ['Es spricht nur über einen Algorithmus, eine untere Schranke muss für alle Algorithmen gelten', 'Weil binäre Suche schneller ist', 'Weil Ω(n) falsch ist', 'Weil Hashing schneller ist'], a: 0,
    w: { 1: 'Binäre Suche funktioniert nur auf sortierten Arrays.', 2: 'Die Schranke selbst stimmt.' },
    e: 'Eine untere Schranke für ein Problem muss jeden denkbaren Algorithmus abdecken. Richtig ist: Ein Algorithmus, der ein Element nie anschaut, kann nicht wissen, ob es das gesuchte ist.',
    m: 'Untere Schranken gelten für das Problem, nicht für einen Algorithmus.', s: 'Skript AuD 2.1' },

  { id: 'ad4-w1', t: 'ad4', d: 1, k: 'w',
    q: 'Binäre Suche (Mitte = linkes Element bei gerader Länge) nach 22 im Array (2, 4, 6, …, 30), also den 15 geraden Zahlen von 2 bis 30. Mit welchen Elementen wird verglichen? Wie viele Vergleiche sind es?',
    ans: { k: 'num', v: 4 },
    sol: [
      'Bereich Index 1–15, Mitte 8: Element 16 < 22 → rechts.',
      'Bereich 9–15, Mitte 12: Element 24 > 22 → links.',
      'Bereich 9–11, Mitte 10: Element 20 < 22 → rechts.',
      'Bereich 11–11: Element 22 gefunden.'
    ],
    res: 'Vergleiche mit 16, 24, 20, 22, also 4 Vergleiche',
    m: '$n = 2^4 - 1$: höchstens 4 Vergleiche.', s: 'Skript AuD 2.2' },

  // ---------------- 3.1–3.3 Elementare Sortierverfahren ----------------
  { id: 'ad5-01', t: 'ad5', d: 1, k: 'sc',
    q: 'Welches Verfahren kommt mit **O(n) Vertauschungen** aus?',
    o: ['SelectionSort', 'BubbleSort', 'InsertionSort', 'keines der drei'], a: 0,
    e: 'SelectionSort sucht pro Durchlauf das Maximum (bzw. Minimum) und setzt es mit einer einzigen Vertauschung an seinen Platz. Vergleiche braucht es trotzdem Θ(n²).',
    m: 'Selection: wenig Vertauschungen. Insertion: weniger Vergleiche möglich.', s: 'Skript AuD 3.2' },

  { id: 'ad5-02', t: 'ad5', d: 2, k: 'sc',
    q: 'Was gilt für InsertionSort, wenn man die Einfügeposition mit **binärer Suche** bestimmt?',
    o: ['O(n log n) Vergleiche, aber im Worst Case weiterhin Θ(n²) Vertauschungen', 'O(n log n) Laufzeit insgesamt', 'O(n) Vertauschungen', 'Θ(n²) Vergleiche'], a: 0,
    w: { 1: 'Das Verschieben der Elemente kostet weiterhin quadratisch viel.' },
    e: 'Die Suche im sortierten Präfix kostet O(log j). Das Element muss aber trotzdem an seine Position verschoben werden, bei umgekehrt sortiertem Input j Vertauschungen.',
    m: 'Weniger Vergleiche heisst nicht weniger Arbeit insgesamt.', s: 'Skript AuD 3.3' },

  { id: 'ad5-03', t: 'ad5', d: 2, k: 'sc',
    q: 'BubbleSort (jeder Durchlauf vergleicht benachbarte Paare von links nach rechts) auf (5, 1, 4, 2, 8, 3). Wie sieht das Array nach **zwei** Durchläufen aus?',
    o: ['(1, 2, 4, 3, 5, 8)', '(1, 4, 2, 5, 3, 8)', '(1, 2, 3, 4, 5, 8)', '(1, 2, 4, 5, 3, 8)'], a: 0,
    w: { 1: 'Das ist der Zustand nach einem Durchlauf.', 2: 'Es braucht noch einen Durchlauf.' },
    e: 'Durchlauf 1: 8 blubbert nach hinten → (1, 4, 2, 5, 3, 8). Durchlauf 2: 5 blubbert an die zweitletzte Stelle → (1, 2, 4, 3, 5, 8). Invariante: nach j Durchläufen stehen die j grössten richtig.',
    m: 'BubbleSort: nach j Durchläufen sind die j grössten Elemente am Ende.', s: 'Skript AuD 3.1' },

  { id: 'ad5-04', t: 'ad5', d: 2, k: 'sc',
    q: 'InsertionSort auf (7, 3, 5, 1, 9, 2). Wie sieht das Array aus, nachdem die ersten **4** Elemente sortiert sind?',
    o: ['(1, 3, 5, 7, 9, 2)', '(3, 5, 7, 1, 9, 2)', '(1, 2, 3, 5, 7, 9)', '(1, 3, 5, 7, 2, 9)'], a: 0,
    w: { 1: 'Da sind erst 3 Elemente sortiert.' },
    e: 'Invariante: die ersten j Elemente sind unter sich sortiert, der Rest ist unverändert. Die ersten vier (7, 3, 5, 1) werden zu (1, 3, 5, 7), 9 und 2 bleiben stehen.',
    m: 'InsertionSort: sortiertes Präfix wächst um eins pro Durchlauf.', s: 'Skript AuD 3.3' },

  { id: 'ad5-05', t: 'ad5', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Vertauschungen benachbarter Elemente macht InsertionSort auf dem umgekehrt sortierten Array (6, 5, 4, 3, 2, 1)?',
    o: ['15', '6', '36', '5'], a: 0,
    e: 'Element j muss an allen j − 1 Elementen vor sich vorbei: 1 + 2 + 3 + 4 + 5 = 15 = n(n − 1)/2. Das ist die Anzahl Fehlstände.',
    m: 'Benachbarte Vertauschungen = Anzahl Fehlstände.', s: 'Skript AuD 3.3' },

  { id: 'ad5-06', t: 'ad5', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['SelectionSort macht auf jedem Input Θ(n²) Vergleiche.', true, 'Das Maximum unter j Elementen braucht j − 1 Vergleiche, egal wie der Input aussieht.'],
      ['BubbleSort macht im Worst Case Θ(n²) Vertauschungen.', true, 'Beim umgekehrt sortierten Array.'],
      ['Aus einer Invariante kann man einen Algorithmus konstruieren.', true, 'So wurde InsertionSort im Skript hergeleitet.'],
      ['Nach j Durchläufen von InsertionSort stehen die j kleinsten Elemente an ihrer endgültigen Position.', false, 'Garantiert ist nur, dass die ersten j Elemente unter sich sortiert sind. Ein kleines Element weiter hinten kommt erst später nach vorne.']
    ],
    e: 'Invarianten beschreiben, was nach jedem Durchlauf garantiert gilt, und liefern so den Korrektheitsbeweis.', m: 'Korrektheit von Sortierverfahren über Invarianten.', s: 'Skript AuD 3.1–3.3' },

  { id: 'ad5-w1', t: 'ad5', d: 1, k: 'w',
    q: 'Führe InsertionSort auf (4, 7, 2, 9, 1) aus. Schreibe das Array nach jedem Durchlauf der äusseren Schleife auf (j = 2, 3, 4, 5) und formuliere die Invariante.',
    sol: [
      'j = 2: (4, 7, 2, 9, 1), 7 bleibt.',
      'j = 3: (2, 4, 7, 9, 1), 2 wandert nach vorne.',
      'j = 4: (2, 4, 7, 9, 1), 9 bleibt.',
      'j = 5: (1, 2, 4, 7, 9), 1 wandert ganz nach vorne.',
      'Invariante: Nach dem Durchlauf j ist A[1..j] eine sortierte Umordnung der ursprünglichen A[1..j].'
    ],
    res: 'Endergebnis (1, 2, 4, 7, 9)',
    m: 'Invariante + Ende der Schleife ⟹ sortiert.', s: 'Skript AuD 3.3' },

  // ---------------- 3.4–3.5 MergeSort, QuickSort ----------------
  { id: 'ad6-01', t: 'ad6', d: 1, k: 'sc',
    q: 'Welche Laufzeit hat MergeSort im Best Case?',
    o: ['Θ(n log n)', 'Θ(n)', 'Θ(n²)', 'Θ(log n)'], a: 0,
    e: 'MergeSort teilt immer in der Mitte und merged immer alle Elemente. Die Struktur hängt nicht vom Input ab, also gilt Θ(n log n) in jedem Fall.',
    m: 'MergeSort: immer n log n, braucht aber Zusatzspeicher.', s: 'Skript AuD 3.4' },

  { id: 'ad6-02', t: 'ad6', d: 2, k: 'sc', fix: true,
    q: 'Höchstens wie viele Vergleiche braucht das Mischen zweier sortierter Folgen der Länge 4 und 4?',
    o: ['7', '8', '4', '16'], a: 0,
    w: { 2: 'Das ist der Best Case: eine Folge ist komplett kleiner.' },
    e: 'Jeder Vergleich gibt ein Element aus. Sobald eine Folge leer ist, wird der Rest ohne Vergleich kopiert. Mindestens das letzte Element braucht keinen Vergleich: 8 − 1 = 7.',
    m: 'Mischen von insgesamt n Elementen: höchstens n − 1 Vergleiche.', s: 'Skript AuD 3.4' },

  { id: 'ad6-03', t: 'ad6', d: 1, k: 'sc',
    q: 'QuickSort wählt immer das letzte Element als Pivot. Bei welchem Input passiert der Worst Case Θ(n²)?',
    o: ['Bei einem bereits sortierten Array', 'Bei einem zufällig permutierten Array', 'Bei einem Array mit lauter verschiedenen Zahlen', 'Nie, QuickSort ist immer O(n log n)'], a: 0,
    e: 'Ist das Pivot immer das Maximum, ist eine Seite leer und die andere hat n − 1 Elemente. Die Rekursion hat Tiefe n, Gesamtkosten n + (n − 1) + … = Θ(n²).',
    m: 'Schlechte Pivots → unbalancierte Teilung → quadratisch.', s: 'Skript AuD 3.5.4' },

  { id: 'ad6-04', t: 'ad6', d: 2, k: 'sc', fix: true,
    q: 'QuickSort teilt (3, 8, 2, 5, 1, 4) mit Pivot 4 (das letzte Element) auf. An welcher Position (1-basiert) steht das Pivot danach?',
    o: ['4', '6', '3', '1'], a: 0,
    e: 'Nach dem Aufteilen stehen links genau die kleineren Elemente (3, 2, 1) und rechts die grösseren (8, 5). Das Pivot steht also an Position 4, und das ist schon seine endgültige Position.',
    m: 'Nach dem Aufteilen ist das Pivot endgültig an seinem Platz.', s: 'Skript AuD 3.5.3' },

  { id: 'ad6-05', t: 'ad6', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['MergeSort arbeitet in-place (mit O(1) Zusatzspeicher).', false, 'Das Mischen braucht ein Hilfsarray der Grösse n.'],
      ['QuickSort macht im Worst Case Θ(n²) Vergleiche.', true, 'Bei immer extremen Pivots.'],
      ['QuickSort mit zufällig gewähltem Pivot hat erwartete Laufzeit O(n log n).', true, 'Für jeden Input, gemittelt über den Zufall.'],
      ['Die Rekursionstiefe von MergeSort ist etwa $\\log_2 n$.', true, 'Halbieren bis zur Grösse 1.'],
      ['QuickSort ist für jeden Input schneller als MergeSort.', false, 'Im Worst Case ist QuickSort quadratisch.']
    ],
    e: 'Kein Verfahren ist in allen Kriterien das beste: Laufzeitgarantie, Zusatzspeicher, praktische Geschwindigkeit.', m: 'MergeSort: Garantie. QuickSort: in-place und praktisch schnell.', s: 'Skript AuD 3.4–3.5' },

  { id: 'ad6-w1', t: 'ad6', d: 2, k: 'w',
    q: 'Löse die MergeSort-Rekurrenz $T(1) = 0$, $T(n) = 2T(n/2) + n$ für $n = 2^k$ exakt und gib T(16) an.',
    ans: { k: 'num', v: 64 },
    sol: [
      'Teleskopieren: $T(n) = 2T(n/2) + n = 4T(n/4) + 2n = \\ldots = 2^k T(1) + kn$.',
      'Mit T(1) = 0 und $k = \\log_2 n$: $T(n) = n \\log_2 n$.',
      'Kontrolle per Induktion: $2 \\cdot \\frac{n}{2} \\log_2 \\frac{n}{2} + n = n(\\log_2 n - 1) + n = n \\log_2 n$.',
      'T(16) = 16 · 4 = 64.'
    ],
    res: '$T(n) = n \\log_2 n$, also T(16) = 64',
    m: 'Pro Ebene n, $\\log_2 n$ Ebenen.', s: 'Skript AuD 3.4' },

  { id: 'ad6-w2', t: 'ad6', d: 3, k: 'w',
    q: 'Zeige: Wählt QuickSort immer das Maximum als Pivot, so macht es auf n Elementen genau $\\frac{n(n-1)}{2}$ Vergleiche mit dem Pivot. Stelle die Rekurrenz auf und löse sie.',
    sol: [
      'Aufteilen von k Elementen vergleicht jedes der k − 1 anderen Elemente mit dem Pivot.',
      'Ist das Pivot das Maximum, bleiben links k − 1 Elemente und rechts keines: V(k) = V(k − 1) + (k − 1), V(1) = 0.',
      'Aufsummieren: $V(n) = \\sum_{k=2}^{n} (k - 1) = 1 + 2 + \\ldots + (n - 1) = \\frac{n(n-1)}{2}$.'
    ],
    res: '$V(n) = n(n-1)/2 = \\Theta(n^2)$',
    m: 'Unbalancierte Rekursion → arithmetische Reihe → quadratisch.', s: 'Skript AuD 3.5.4' },

  // ---------------- 3.6–3.7 HeapSort, untere Schranke ----------------
  { id: 'ad7-01', t: 'ad7', d: 1, k: 'sc',
    q: 'Ein Heap ist ab Index 1 in einem Array gespeichert. Wo stehen die Kinder des Knotens an Index 5?',
    o: ['An 10 und 11', 'An 6 und 7', 'An 11 und 12', 'An 9 und 10'], a: 0,
    e: 'Kinder von k stehen an 2k und 2k + 1, der Elternknoten an ⌊k/2⌋. So braucht man keine Zeiger.',
    m: 'Kinder 2k, 2k + 1. Eltern ⌊k/2⌋.', s: 'Skript AuD 3.6.7' },

  { id: 'ad7-02', t: 'ad7', d: 2, k: 'sc',
    q: 'Welches Array (ab Index 1) ist ein **Max-Heap**?',
    o: ['(9, 7, 8, 3, 6, 5)', '(9, 8, 7, 6, 5, 10)', '(7, 9, 8, 3, 6, 5)', '(9, 3, 8, 7, 6, 5)'], a: 0,
    w: { 1: '10 an Index 6 ist grösser als sein Elternknoten 7 an Index 3.', 2: 'Die Wurzel 7 ist kleiner als ihr Kind 9.', 3: '3 an Index 2 hat die grösseren Kinder 7 und 6.' },
    e: 'Prüfe für jedes k: A[k] ≥ A[2k] und A[k] ≥ A[2k + 1]. Bei (9, 7, 8, 3, 6, 5): 9 ≥ 7, 8; 7 ≥ 3, 6; 8 ≥ 5.',
    m: 'Heap-Bedingung: Eltern ≥ Kinder.', s: 'Skript AuD 3.6.2' },

  { id: 'ad7-03', t: 'ad7', d: 2, k: 'sc',
    q: 'extractMax auf dem Max-Heap (9, 7, 8, 3, 6, 5): letztes Element an die Wurzel, dann versickern. Welches Array entsteht?',
    o: ['(8, 7, 5, 3, 6)', '(8, 7, 6, 3, 5)', '(7, 8, 5, 3, 6)', '(5, 7, 8, 3, 6)'], a: 0,
    w: { 1: 'Die 5 sinkt nur einmal: nach dem Tausch mit 8 an Index 3 hat sie keine Kinder mehr.', 2: 'Beim Versickern tauscht man mit dem grösseren Kind, also 8.', 3: 'Das ist vor dem Versickern.' },
    e: '9 wird entfernt, 5 kommt an die Wurzel: (5, 7, 8, 3, 6). Das grössere Kind von 5 ist 8, also tauschen: (8, 7, 5, 3, 6). Index 3 hat keine Kinder mehr (6 und 7 > 5).',
    m: 'Versickern: immer mit dem grösseren Kind tauschen.', s: 'Skript AuD 3.6.4' },

  { id: 'ad7-04', t: 'ad7', d: 2, k: 'sc',
    q: 'Wie lange dauert es, aus einem beliebigen Array mit n Elementen einen Heap zu machen, wenn man von unten nach oben alle inneren Knoten versickern lässt?',
    o: ['O(n)', 'O(n log n)', 'O(log n)', 'O(n²)'], a: 0,
    w: { 1: 'Das ist eine korrekte, aber nicht scharfe Schranke.' },
    e: 'Die meisten Knoten liegen weit unten und sinken nur wenig. Ein Knoten in Tiefe i sinkt höchstens t − i Ebenen. Die Summe $\\sum_i 2^i (t - i)$ ist O(n).',
    m: 'Heap bauen: linear. n-mal einfügen: n log n.', s: 'Skript AuD 3.6.5' },

  { id: 'ad7-05', t: 'ad7', d: 3, k: 'sc', fix: true,
    q: 'Mindestens wie viele Vergleiche braucht jeder vergleichsbasierte Algorithmus im Worst Case, um **4** verschiedene Elemente zu sortieren?',
    o: ['5', '4', '3', '6'], a: 0,
    w: { 1: '$2^4 = 16 < 24$.', 3: 'Mit MergeSort braucht man 5, mehr ist nicht nötig.' },
    e: 'Es gibt 4! = 24 Permutationen, der Entscheidungsbaum braucht mindestens 24 Blätter. Höhe h mit $2^h \\ge 24$ verlangt h ≥ 5.',
    m: 'Sortieren: Höhe ≥ $\\log_2(n!) = \\Omega(n \\log n)$.', s: 'Skript AuD 3.7.1' },

  { id: 'ad7-06', t: 'ad7', d: 2, k: 'sc',
    q: 'Wie kann BucketSort schneller als Ω(n log n) sein?',
    o: ['Es vergleicht keine Elemente, sondern nutzt die eingeschränkte Form der Eingabe', 'Es verwendet einen besseren Pivot', 'Die untere Schranke gilt nur für den Average Case', 'Es sortiert nur teilweise'], a: 0,
    w: { 2: 'Die Schranke gilt für den Worst Case vergleichsbasierter Verfahren.' },
    e: 'Die Schranke Ω(n log n) gilt nur für vergleichsbasierte Algorithmen. BucketSort verteilt Schlüssel aus einem kleinen Wertebereich direkt auf Fächer.',
    m: 'Untere Schranken gelten immer nur für ein bestimmtes Berechnungsmodell.', s: 'Skript AuD 3.7.2' },

  { id: 'ad7-07', t: 'ad7', d: 3, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['HeapSort braucht nur O(1) Zusatzspeicher.', true, 'Der Heap liegt im Eingabearray selbst.'],
      ['HeapSort läuft im Worst Case in O(n log n).', true, 'n-mal extractMax mit O(log n).'],
      ['Ein absteigend sortiertes Array ist ein Max-Heap.', true, 'Jeder Elternknoten steht weiter vorne und ist daher grösser.'],
      ['Das Minimum eines Max-Heaps findet man in O(log n).', false, 'Es kann in jedem Blatt stehen, das sind etwa n/2 Kandidaten.'],
      ['Einfügen in einen Heap kostet O(log n).', true, 'Hinten anfügen und nach oben steigen lassen.']
    ],
    e: 'Ein Heap ist nur teilweise geordnet: entlang jedes Pfads von der Wurzel absteigend, aber zwischen Geschwistern beliebig.', m: 'Heap: Maximum schnell, alles andere nicht.', s: 'Skript AuD 3.6' },

  { id: 'ad7-w1', t: 'ad7', d: 2, k: 'w',
    q: 'Baue aus (3, 9, 2, 1, 4, 5) (Index 1 bis 6) einen Max-Heap, indem du die Knoten 3, 2, 1 in dieser Reihenfolge versickern lässt. Tippe das Ergebnis-Array ein.',
    ans: { k: 'vec', v: [9, 4, 5, 1, 3, 2], ph: 'z. B. (9, 4, …)' },
    sol: [
      'Knoten 3 (Wert 2) hat das Kind 5 an Index 6: tauschen → (3, 9, 5, 1, 4, 2).',
      'Knoten 2 (Wert 9) hat die Kinder 1 und 4: alles in Ordnung.',
      'Knoten 1 (Wert 3): grösseres Kind 9 → tauschen → (9, 3, 5, 1, 4, 2). Weiter an Index 2: Kinder 1 und 4, grösser 4 → tauschen → (9, 4, 5, 1, 3, 2).'
    ],
    res: '(9, 4, 5, 1, 3, 2)',
    m: 'Bottom-up: von ⌊n/2⌋ rückwärts bis 1 versickern.', s: 'Skript AuD 3.6.5' },

  { id: 'ad7-w2', t: 'ad7', d: 2, k: 'w',
    q: 'Zeige: $\\log_2(n!) \\ge \\frac{n}{2} \\log_2 \\frac{n}{2}$. Folgere, dass vergleichsbasiertes Sortieren Ω(n log n) Vergleiche braucht.',
    sol: [
      'Von den n Faktoren von $n! = n \\cdot (n - 1) \\cdots 1$ sind mindestens n/2 grösser oder gleich n/2.',
      'Also $n! \\ge (n/2)^{n/2}$ und damit $\\log_2(n!) \\ge \\frac{n}{2} \\log_2 \\frac{n}{2}$.',
      'Der Entscheidungsbaum eines Sortierverfahrens hat mindestens n! Blätter, also Höhe $h \\ge \\log_2(n!)$, also mindestens $\\frac{n}{2}\\log_2\\frac{n}{2} = \\Omega(n \\log n)$ Vergleiche im Worst Case.'
    ],
    res: '$h \\ge \\log_2(n!) \\ge \\frac{n}{2}\\log_2\\frac{n}{2} = \\Omega(n \\log n)$',
    m: 'Grob abschätzen reicht: die Hälfte der Faktoren ist gross.', s: 'Skript AuD 3.7.1' },

  // ---------------- 4 Abstrakte Datentypen ----------------
  { id: 'ad8-01', t: 'ad8', d: 1, k: 'sc',
    q: 'Ein leerer **Stack**: push(1), push(2), pop(), push(3), pop(), pop(). In welcher Reihenfolge werden Werte zurückgegeben?',
    o: ['2, 3, 1', '1, 2, 3', '2, 1, 3', '3, 2, 1'], a: 0,
    e: 'LIFO: pop gibt das zuletzt eingefügte Element zurück. Nach push(1), push(2) liefert pop 2. Nach push(3) liefert pop 3, danach 1.',
    m: 'Stack = LIFO, Queue = FIFO.', s: 'Skript AuD 4.2' },

  { id: 'ad8-02', t: 'ad8', d: 1, k: 'sc',
    q: 'Eine leere **Queue**: enqueue(1), enqueue(2), enqueue(3), dequeue(), enqueue(4), dequeue(). Was wird zurückgegeben?',
    o: ['1, 2', '3, 4', '1, 4', '3, 2'], a: 0,
    e: 'FIFO: dequeue gibt das am längsten wartende Element zurück, zuerst 1, dann 2. In der Queue bleiben 3, 4.',
    m: 'Queue = Warteschlange.', s: 'Skript AuD 4.3' },

  { id: 'ad8-03', t: 'ad8', d: 2, k: 'mc',
    q: 'ADT Liste mit n Elementen. Welche Operationen gehen in **O(1)**? Wähle alle.',
    o: ['get(i) bei einem Array', 'Einfügen nach einem gegebenen Knoten in einer doppelt verketteten Liste', 'get(i) bei einer verketteten Liste', 'Einfügen an Position 1 bei einem Array', 'Löschen eines gegebenen Knotens in einer doppelt verketteten Liste'], a: [0, 1, 4],
    w: { 2: 'Man muss i Zeigern folgen.', 3: 'Alle Elemente müssen verschoben werden: Θ(n).' },
    e: 'Arrays: direkter Zugriff, teures Einfügen. Verkettete Listen: billiges Einfügen und Löschen an bekannter Stelle, teurer Zugriff per Index.',
    m: 'Kein Datenstruktur-Typ ist für alle Operationen am besten.', s: 'Skript AuD 4.1' },

  { id: 'ad8-04', t: 'ad8', d: 1, k: 'sc',
    q: 'Eine Prioritätswarteschlange wird mit einem Max-Heap implementiert. Welche Laufzeiten haben insert und extractMax?',
    o: ['beide O(log n)', 'insert O(1), extractMax O(n)', 'beide O(1)', 'insert O(n), extractMax O(1)'], a: 0,
    w: { 1: 'So wäre es mit einer unsortierten Liste.', 3: 'So wäre es mit einer sortierten Liste.' },
    e: 'Beim Einfügen steigt das neue Element höchstens bis zur Wurzel auf, beim Entfernen sinkt das neue Wurzelelement höchstens bis zu einem Blatt. Der Heap hat Höhe O(log n).',
    m: 'Prioritätswarteschlange = Heap.', s: 'Skript AuD 4.4' },

  { id: 'ad8-05', t: 'ad8', d: 3, k: 'sc',
    q: 'Gegeben ist ein Zeiger auf einen Knoten x (nicht der letzte). Warum ist Löschen von x in einer **einfach** verketteten Liste im Allgemeinen teurer als in einer doppelt verketteten?',
    o: ['Man muss den Vorgänger von x finden, um dessen next-Zeiger umzuhängen, und das kostet O(n)', 'Weil man alle Elemente verschieben muss', 'Weil einfach verkettete Listen keine Zeiger speichern', 'Es gibt keinen Unterschied'], a: 0,
    e: 'In der doppelt verketteten Liste kennt x seinen Vorgänger, beide Nachbarn lassen sich in O(1) verbinden. In der einfach verketteten Liste muss man den Vorgänger von vorne suchen.',
    m: 'Doppelt verkettet: Vorgänger in O(1).', s: 'Skript AuD 4.1.2–4.1.3' },

  { id: 'ad8-w1', t: 'ad8', d: 1, k: 'w',
    q: 'Beschreibe mit einem Stack einen Algorithmus, der prüft, ob ein Klammerausdruck aus `(`, `)`, `[`, `]` korrekt geschachtelt ist. Führe ihn für `([)]` und `[()()]` aus.',
    sol: [
      'Öffnende Klammer: push. Schliessende Klammer: Ist der Stack leer oder passt pop() nicht dazu → falsch.',
      'Am Ende: korrekt genau dann, wenn der Stack leer ist.',
      '`([)]`: push (, push [, dann ) – pop liefert [ → passt nicht → falsch.',
      '`[()()]`: push [, push (, pop ( ✓, push (, pop ( ✓, pop [ ✓, Stack leer → korrekt.'
    ],
    res: 'Stack, weil die zuletzt geöffnete Klammer zuerst geschlossen werden muss (LIFO).',
    m: 'Verschachtelung ↔ Stack.', s: 'Skript AuD 4.2' }
]);
