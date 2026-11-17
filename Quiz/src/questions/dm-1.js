// DiskMath Teil 1: Kapitel 2 (Logik und Beweise) und 3.1–3.5 (Mengen, Relationen, Ordnungen)
QUIZ.add('dm', [
  // ---------------- 2.1–2.2 Aussagen und Beweisbegriff ----------------
  { id: 'dm1-01', t: 'dm1', d: 1, k: 'sc',
    q: 'Welches ist eine mathematische Aussage im Sinne des Skripts?',
    o: ['Jede gerade Zahl grösser als 2 ist Summe zweier Primzahlen.', '$x > 5$', 'Dieser Satz ist falsch.', 'Der Algorithmus X ist effizient.'], a: 0,
    w: { 0: 'Das ist die Goldbach-Vermutung: ob sie wahr ist, weiss niemand, aber sie ist entweder wahr oder falsch.', 1: 'Der Wahrheitswert hängt von x ab, das ist ein Prädikat.', 2: 'Selbstbezüglich, weder wahr noch falsch.', 3: '„Effizient“ ist nicht präzise definiert.' },
    e: 'Eine mathematische Aussage ist im absoluten Sinn wahr oder falsch. Man muss den Wahrheitswert nicht kennen: eine unbewiesene, aber geglaubte Aussage heisst Vermutung.',
    m: 'Aussage = eindeutig wahr oder falsch, auch wenn wir es (noch) nicht wissen.', s: 'Skript DiskMath 2.1' },

  { id: 'dm1-02', t: 'dm1', d: 1, k: 'sc',
    q: 'Welche Aussage ist **wahr**?',
    o: ['Wenn 2 + 2 = 5 ist, dann ist 7 keine Primzahl.', 'Wenn 7 eine Primzahl ist, dann ist 2 + 2 = 5.', 'Wenn 2 + 2 = 4 ist, dann ist 9 eine Primzahl.', '3 ist gerade, oder 2 + 2 = 5.'], a: 0,
    w: { 1: 'Wahre Voraussetzung, falsche Folgerung: die Implikation ist falsch.', 2: 'Wahre Voraussetzung, falsche Folgerung.', 3: 'Beide Teile der Disjunktion sind falsch.' },
    e: 'Eine Implikation S ⟹ T ist nur dann falsch, wenn S wahr und T falsch ist. Bei falscher Voraussetzung ist sie immer wahr, egal was folgt.',
    m: 'Aus Falschem folgt Beliebiges.', s: 'Skript DiskMath 2.1.3 und 2.3' },

  { id: 'dm1-03', t: 'dm1', d: 2, k: 'tf',
    q: 'Entscheide für jede Aussage über Beweise.',
    rows: [
      ['Prüft man eine Allaussage für 10⁹ Beispiele und findet kein Gegenbeispiel, ist sie bewiesen.', false, 'Beispiele können eine Allaussage nie beweisen, nur widerlegen.'],
      ['Ein Beweis ist eine Folge einfacher, nachprüfbarer Schritte, ausgehend von Axiomen und bekannten Tatsachen.', true, 'Das ist die informelle Definition 2.2.'],
      ['Aus „S ⟹ T“ und „T ist wahr“ folgt, dass S wahr ist.', false, 'Das ist ein klassischer Fehlschluss. Modus ponens verlangt, dass S wahr ist.'],
      ['Ein Lemma ist ein bewiesenes Zwischenresultat.', true, 'Theorem, Lemma und Korollar bezeichnen alle bewiesene Aussagen.']
    ],
    e: 'Ein Beweis muss für alle Fälle gelten. Darum sind Fehlschlüsse wie „T wahr, also S wahr“ so gefährlich.', m: 'Nur S und S ⟹ T zusammen liefern T.', s: 'Skript DiskMath 2.1–2.2' },

  { id: 'dm1-04', t: 'dm1', d: 3, k: 'sc',
    q: '„Beweis“ per Induktion, dass sich beliebige n paarweise nicht parallele Geraden in **einem** Punkt schneiden: Basis n = 2 stimmt. Schritt: Von n + 1 Geraden schneiden sich die ersten n in einem Punkt und die letzten n auch, und beide Gruppen teilen Geraden, also ist es derselbe Punkt. Wo liegt der Fehler?',
    o: ['Im Schritt von n = 2 auf n = 3: die beiden Gruppen teilen sich dann nur eine Gerade, und eine Gerade legt keinen Punkt fest', 'Die Basis müsste bei n = 1 beginnen', 'Induktion darf man in der Geometrie nicht verwenden', 'Die Annahme „nicht parallel“ wird nirgends gebraucht'], a: 0,
    w: { 1: 'Eine andere Basis ändert nichts am fehlerhaften Schritt.', 2: 'Induktion ist ein allgemeines Beweisprinzip.' },
    e: 'Für n + 1 = 3 Geraden haben die Gruppen {ℓ₁, ℓ₂} und {ℓ₂, ℓ₃} nur ℓ₂ gemeinsam. Daraus folgt nicht, dass die beiden Schnittpunkte gleich sind. Der Induktionsschritt muss für **jedes** n gelten, hier versagt er schon beim ersten.',
    m: 'Den Induktionsschritt immer auch für das kleinste n prüfen.', s: 'Skript DiskMath 2.2, Beispiel 2.4' },

  { id: 'dm1-05', t: 'dm1', d: 2, k: 'sc',
    q: 'Welche dieser Zahlen ist ein Teiler von $2^{143} - 1$?',
    o: ['$2^{11} - 1 = 2047$', '$3$', '$11$', '$143$'], a: 0,
    w: { 1: '3 = 2² − 1 teilt 2ᵏ − 1 nur für gerades k.', 2: 'Rest 7.', 3: 'Kein Teiler.' },
    e: 'Es ist 143 = 11 · 13. Für $k = 11m$ gilt $2^k - 1 = (2^{11})^m - 1$, und $x^m - 1$ ist durch $x - 1$ teilbar. Mit $x = 2^{11}$ folgt, dass $2^{11} - 1$ ein Teiler ist. Also ist $2^{143} - 1$ keine Primzahl.',
    m: 'Aus d ∣ k folgt $2^d - 1 \\mid 2^k - 1$.', s: 'Skript DiskMath 2.2, Beispiel 2.2' },

  { id: 'dm1-w1', t: 'dm1', d: 1, k: 'w',
    q: 'Beweise **indirekt**: Für jede ganze Zahl n gilt: Ist $n^2$ gerade, dann ist n gerade.',
    sol: [
      'Indirekter Beweis von S ⟹ T: Man nimmt ¬T an und zeigt ¬S.',
      'Annahme: n ist ungerade, also n = 2k + 1 für ein k ∈ ℤ.',
      'Dann ist $n^2 = 4k^2 + 4k + 1 = 2(2k^2 + 2k) + 1$, also ungerade.',
      'Damit gilt „n ungerade ⟹ n² ungerade“, und das ist äquivalent zur Behauptung.'
    ],
    res: 'Kontraposition: ¬B → ¬A ist äquivalent zu A → B.',
    m: 'Indirekter Beweis: ¬T annehmen, ¬S zeigen.', s: 'Skript DiskMath 2.6.2' },

  // ---------------- 2.3 Aussagenlogik ----------------
  { id: 'dm2-01', t: 'dm2', d: 1, k: 'sc',
    q: 'Für welche Belegung ist $A \\to B$ **falsch**?',
    o: ['A = 1, B = 0', 'A = 0, B = 1', 'A = 0, B = 0', 'A = 1, B = 1'], a: 0,
    e: 'Die Implikation ist nur falsch, wenn die Voraussetzung wahr und die Folgerung falsch ist. Es gilt $A \\to B \\equiv \\neg A \\lor B$.',
    m: '$A \\to B \\equiv \\neg A \\lor B$', s: 'Skript DiskMath 2.3.3' },

  { id: 'dm2-02', t: 'dm2', d: 2, k: 'mc',
    q: 'Welche Formeln sind Tautologien? Wähle alle.',
    o: ['$A \\lor \\neg A$', '$(A \\land (A \\to B)) \\to B$', '$A \\to (B \\to A)$', '$(A \\to B) \\to (B \\to A)$', '$(A \\to B) \\lor (B \\to A)$'], a: [0, 1, 2, 4],
    w: { 1: 'Das ist der Modus ponens als Formel.', 2: 'Ist A wahr, ist B → A wahr. Ist A falsch, ist die Implikation wahr.', 3: 'Falsch für A = 0, B = 1.', 4: 'Ist A → B falsch, dann A = 1 und B = 0, und dann ist B → A wahr.' },
    e: 'Eine Tautologie ist für alle Belegungen wahr. Oft prüft man am schnellsten, ob es eine Belegung gibt, die sie falsch macht.',
    m: 'Tautologie prüfen: Gegenbelegung suchen.', s: 'Skript DiskMath 2.3.5' },

  { id: 'dm2-03', t: 'dm2', d: 2, k: 'tf',
    q: 'Gelten diese Äquivalenzen?',
    rows: [
      ['$\\neg(A \\land B) \\equiv \\neg A \\land \\neg B$', false, 'De Morgan: $\\neg(A \\land B) \\equiv \\neg A \\lor \\neg B$.'],
      ['$A \\lor (A \\land B) \\equiv A$', true, 'Absorption.'],
      ['$A \\to B \\equiv \\neg B \\to \\neg A$', true, 'Kontraposition.'],
      ['$A \\to B \\equiv B \\to A$', false, 'A = 1, B = 0 unterscheidet die beiden.'],
      ['$(A \\land B) \\lor C \\equiv (A \\lor C) \\land (B \\lor C)$', true, 'Distributivgesetz.']
    ],
    e: 'Äquivalent heisst: gleiche Wahrheitswerte für alle Belegungen. Eine einzige unterscheidende Belegung genügt als Gegenbeweis.', m: 'Die Gesetze aus Lemma 2.1 sind das Werkzeug fürs Umformen.', s: 'Skript DiskMath 2.3.4, Lemma 2.1' },

  { id: 'dm2-04', t: 'dm2', d: 2, k: 'sc',
    q: 'Welche logische Folgerung gilt?',
    o: ['$A \\land B \\models A \\lor B$', '$A \\lor B \\models A \\land B$', '$A \\to B \\models B \\to A$', '$A \\lor B \\models A$'], a: 0,
    w: { 1: 'A = 1, B = 0: links wahr, rechts falsch.', 2: 'A = 0, B = 1: links wahr, rechts falsch.', 3: 'A = 0, B = 1.' },
    e: '$F \\models G$ heisst: jede Belegung, die F wahr macht, macht auch G wahr. Ist A ∧ B wahr, sind beide wahr, also auch A ∨ B.',
    m: '$F \\models G$ genau dann, wenn $F \\to G$ eine Tautologie ist.', s: 'Skript DiskMath 2.3.5, Lemma 2.3' },

  { id: 'dm2-05', t: 'dm2', d: 3, k: 'tf',
    q: 'F und G sind beliebige Formeln der Aussagenlogik. Wahr oder falsch?',
    rows: [
      ['Ist $F \\land G$ erfüllbar, dann sind F und G erfüllbar.', true, 'Dieselbe Belegung macht beide wahr.'],
      ['Ist $F \\lor G$ eine Tautologie, dann ist F oder G eine Tautologie.', false, 'F = A, G = ¬A: keine der beiden ist eine Tautologie.'],
      ['$F \\equiv G$ gilt genau dann, wenn $F \\models G$ und $G \\models F$.', true, 'Folgerung in beide Richtungen heisst gleiche Wahrheitswerte.'],
      ['Ist $\\neg F$ erfüllbar, dann ist F keine Tautologie.', true, 'Die Belegung, die ¬F wahr macht, macht F falsch (Lemma 2.2).'],
      ['Ist F unerfüllbar, dann ist $F \\to G$ eine Tautologie.', true, 'Die Voraussetzung ist nie wahr.']
    ],
    e: 'Erfüllbar heisst: mindestens eine Belegung macht die Formel wahr. Tautologie: alle Belegungen.', m: 'F Tautologie ⟺ ¬F unerfüllbar.', s: 'Skript DiskMath 2.3.5' },

  { id: 'dm2-06', t: 'dm2', d: 3, k: 'sc', fix: true,
    q: 'Wie viele paarweise **nicht äquivalente** Formeln gibt es, die nur die Symbole A und B verwenden?',
    o: ['4', '8', '16', 'unendlich viele'], a: 2,
    w: { 0: 'Das ist die Anzahl Belegungen.', 3: 'Es gibt unendlich viele Formeln, aber nur endlich viele Äquivalenzklassen.' },
    e: 'Eine Formel entspricht einer Funktion $\\{0, 1\\}^2 \\to \\{0, 1\\}$. Es gibt 4 Belegungen und für jede 2 mögliche Werte, also $2^4 = 16$ verschiedene Funktionen.',
    m: 'Mit n Symbolen gibt es $2^{2^n}$ Funktionen.', s: 'Skript DiskMath 2.3.4' },

  { id: 'dm2-07', t: 'dm2', d: 2, k: 'sc', fix: true,
    q: 'Für wie viele der 8 Belegungen ist $(A \\to B) \\land (B \\to C) \\land (C \\to A)$ wahr?',
    o: ['2', '1', '4', '6'], a: 0,
    e: 'Die drei Implikationen bilden einen Kreis A → B → C → A. Ist eine Variable 1, müssen alle 1 sein. Also nur A = B = C = 0 und A = B = C = 1.',
    m: 'Implikationen im Kreis erzwingen gleiche Wahrheitswerte.', s: 'Skript DiskMath 2.3' },

  { id: 'dm2-w1', t: 'dm2', d: 2, k: 'w',
    q: 'Zeige durch Umformen mit den Gesetzen aus Lemma 2.1:\n$\\neg(A \\to B) \\lor (A \\land C) \\equiv A \\land (\\neg B \\lor C)$',
    sol: [
      '$A \\to B \\equiv \\neg A \\lor B$, also $\\neg(A \\to B) \\equiv \\neg(\\neg A \\lor B)$.',
      'De Morgan und doppelte Negation: $\\neg(\\neg A \\lor B) \\equiv A \\land \\neg B$.',
      'Zusammen: $(A \\land \\neg B) \\lor (A \\land C)$.',
      'Distributivgesetz rückwärts (A ausklammern): $A \\land (\\neg B \\lor C)$.'
    ],
    res: 'Kette von Äquivalenzen, jeder Schritt mit Gesetz begründet.',
    m: 'Implikation zuerst durch ¬ und ∨ ersetzen.', s: 'Skript DiskMath 2.3.4' },

  { id: 'dm2-w2', t: 'dm2', d: 3, k: 'w',
    q: 'Wie viele Belegungen von A, B, C erfüllen\n$F = (A \\lor B) \\land (\\neg A \\lor C) \\land (\\neg B \\lor \\neg C)$?\nBegründe ohne vollständige Wahrheitstabelle.',
    ans: { k: 'num', v: 2 },
    hint: 'Fallunterscheidung nach C.',
    sol: [
      'Fall C = 1: Die dritte Klausel verlangt B = 0. Die erste verlangt dann A = 1. Die zweite (¬A ∨ C) ist wegen C = 1 erfüllt. → Belegung A = 1, B = 0, C = 1.',
      'Fall C = 0: Die zweite Klausel verlangt A = 0. Die erste verlangt dann B = 1. Die dritte (¬B ∨ ¬C) ist wegen C = 0 erfüllt. → Belegung A = 0, B = 1, C = 0.',
      'Die Fälle C = 0 und C = 1 decken alles ab.'
    ],
    res: '2 erfüllende Belegungen',
    m: 'Fallunterscheidung nach der Variable, die am meisten festlegt.', s: 'Skript DiskMath 2.3.5' },

  // ---------------- 2.4–2.5 Prädikatenlogik ----------------
  { id: 'dm3-01', t: 'dm3', d: 1, k: 'sc',
    q: 'Universum ℕ = {0, 1, 2, …}. Welche Formel ist **wahr**?',
    o: ['$\\forall x\\, \\exists y\\, (y > x)$', '$\\exists y\\, \\forall x\\, (y > x)$', '$\\forall x\\, \\exists y\\, (y < x)$', '$\\exists x\\, (x + 5 = 3)$'], a: 0,
    w: { 1: 'Dann wäre y > y.', 2: 'Für x = 0 gibt es kein kleineres y in ℕ.', 3: 'x = −2 liegt nicht in ℕ.' },
    e: 'Bei ∀x ∃y darf y von x abhängen: y = x + 1. Bei ∃y ∀x müsste ein einziges y für alle x passen. Die Reihenfolge der Quantoren ist entscheidend.',
    m: '∀x ∃y ≠ ∃y ∀x.', s: 'Skript DiskMath 2.4, Beispiele 2.17–2.18' },

  { id: 'dm3-02', t: 'dm3', d: 2, k: 'tf',
    q: 'Universum ℤ. Wahr oder falsch?',
    rows: [
      ['$\\forall x\\, \\exists y\\, (x + y = 0)$', true, 'y = −x.'],
      ['$\\exists y\\, \\forall x\\, (x + y = x)$', true, 'y = 0.'],
      ['$\\forall x\\, \\exists y\\, (x \\cdot y = 1)$', false, 'Für x = 2 gibt es kein ganzzahliges Inverses.'],
      ['$\\exists x\\, \\forall y\\, (x \\cdot y = 0)$', true, 'x = 0.'],
      ['$\\forall x\\, \\forall y\\, (x < y \\to \\exists z\\, (x < z \\land z < y))$', false, 'x = 0, y = 1: keine ganze Zahl dazwischen.']
    ],
    e: 'Für ∃ genügt ein Zeuge, für ∀ widerlegt ein Gegenbeispiel.', m: 'Zeuge für ∃, Gegenbeispiel gegen ∀.', s: 'Skript DiskMath 2.4' },

  { id: 'dm3-03', t: 'dm3', d: 2, k: 'sc',
    q: 'Welche Formel ist äquivalent zu $\\neg \\forall x\\, \\exists y\\, P(x, y)$?',
    o: ['$\\exists x\\, \\forall y\\, \\neg P(x, y)$', '$\\forall x\\, \\exists y\\, \\neg P(x, y)$', '$\\exists x\\, \\exists y\\, \\neg P(x, y)$', '$\\neg \\exists x\\, \\forall y\\, P(x, y)$'], a: 0,
    w: { 1: 'Bei der Negation werden die Quantoren getauscht.', 2: 'Der innere Quantor wird auch getauscht.' },
    e: 'Die Negation wandert nach innen und tauscht jeden Quantor: $\\neg\\forall x\\, F \\equiv \\exists x\\, \\neg F$ und $\\neg\\exists y\\, G \\equiv \\forall y\\, \\neg G$.',
    m: 'Negation durchschieben: ∀ ↔ ∃.', s: 'Skript DiskMath 2.4.6' },

  { id: 'dm3-04', t: 'dm3', d: 3, k: 'sc',
    q: 'Welche Folgerung ist **nicht** für alle Prädikate P und alle (nicht leeren) Universen gültig?',
    o: ['$\\forall y\\, \\exists x\\, P(x, y) \\models \\exists x\\, \\forall y\\, P(x, y)$', '$\\exists x\\, \\forall y\\, P(x, y) \\models \\forall y\\, \\exists x\\, P(x, y)$', '$\\forall x\\, P(x) \\models \\exists x\\, P(x)$', '$\\forall x\\, \\forall y\\, P(x, y) \\models \\forall y\\, \\forall x\\, P(x, y)$'], a: 0,
    w: { 1: 'Ein x, das für alle y passt, ist für jedes y ein Zeuge.', 2: 'Gilt im nicht leeren Universum.', 3: 'Gleiche Quantoren darf man vertauschen.' },
    e: 'Gegenbeispiel: ℕ mit P(x, y) = „x > y“. Zu jedem y gibt es ein grösseres x, aber kein x ist grösser als alle y.',
    m: '∃x ∀y ⊨ ∀y ∃x, die Umkehrung nicht.', s: 'Skript DiskMath 2.4' },

  { id: 'dm3-05', t: 'dm3', d: 3, k: 'mc',
    q: 'Für welche Universen (mit dem üblichen <) ist $\\forall x\\, \\forall y\\, (x < y \\to \\exists z\\, (x < z \\land z < y))$ wahr? Wähle alle.',
    o: ['ℕ', 'ℤ', 'ℚ', 'ℝ', '{0}'], a: [2, 3, 4],
    w: { 0: '0 < 1, nichts dazwischen.', 1: '0 < 1, nichts dazwischen.', 2: 'z = (x + y)/2.', 3: 'z = (x + y)/2.', 4: 'x < y gilt nie, also ist die Implikation immer wahr.' },
    e: 'Die Formel sagt: zwischen zwei verschiedenen Elementen liegt immer ein drittes (dichte Ordnung). Im Universum {0} ist sie trivial wahr, weil die Voraussetzung nie erfüllt ist.',
    m: 'Leere Voraussetzung macht die Implikation wahr.', s: 'Skript DiskMath 2.4, Beispiel 2.23' },

  { id: 'dm3-06', t: 'dm3', d: 2, k: 'sc',
    q: 'Universum ℕ. Welche Formel sagt „Zu jeder Zahl gibt es eine grössere Primzahl“?',
    o: ['$\\forall x\\, \\exists y\\, (y > x \\land \\text{prime}(y))$', '$\\forall x\\, \\exists y\\, (y > x \\to \\text{prime}(y))$', '$\\exists y\\, \\forall x\\, (y > x \\land \\text{prime}(y))$', '$\\forall x\\, \\exists y\\, (\\text{prime}(y) \\to y > x)$'], a: 0,
    w: { 1: 'Mit y = 0 ist die Implikation immer wahr. Die Formel sagt nichts.', 2: 'Das wäre eine Primzahl grösser als alle Zahlen.', 3: 'Mit y = 4 (keine Primzahl) ist die Implikation wahr. Die Formel sagt nichts.' },
    e: 'Bei ∃ gehört ein ∧ in den Rumpf: es soll ein y geben, das grösser **und** prim ist. Ein → unter ∃ macht die Formel fast immer trivial wahr.',
    m: '∀ mit →, ∃ mit ∧.', s: 'Skript DiskMath 2.4, Beispiel 2.21' },

  { id: 'dm3-w1', t: 'dm3', d: 2, k: 'w',
    q: 'Negiere und schiebe die Negation ganz nach innen, bis ¬ nur noch direkt vor Prädikaten steht:\n$\\neg \\forall x\\, \\big(P(x) \\to \\exists y\\, (Q(x, y) \\land \\neg R(y))\\big)$',
    sol: [
      '$\\neg \\forall x\\, F \\equiv \\exists x\\, \\neg F$: $\\exists x\\, \\neg(P(x) \\to \\exists y\\, (Q(x, y) \\land \\neg R(y)))$',
      '$\\neg(A \\to B) \\equiv A \\land \\neg B$: $\\exists x\\, (P(x) \\land \\neg \\exists y\\, (Q(x, y) \\land \\neg R(y)))$',
      '$\\neg\\exists y \\equiv \\forall y\\, \\neg$: $\\exists x\\, (P(x) \\land \\forall y\\, \\neg(Q(x, y) \\land \\neg R(y)))$',
      'De Morgan: $\\exists x\\, (P(x) \\land \\forall y\\, (\\neg Q(x, y) \\lor R(y)))$'
    ],
    res: '$\\exists x\\, \\big(P(x) \\land \\forall y\\, (\\neg Q(x, y) \\lor R(y))\\big)$',
    m: 'Schrittweise: Quantor tauschen, Implikation auflösen, De Morgan.', s: 'Skript DiskMath 2.4' },

  { id: 'dm3-w2', t: 'dm3', d: 2, k: 'w',
    q: 'Universum ℕ, Prädikate prime(x) und das zweistellige Prädikat $x \\mid y$ („x teilt y“). Formalisiere:\n1. „Jede Zahl ≥ 2 hat einen Primteiler.“\n2. „Es gibt keine grösste Primzahl.“',
    sol: [
      '1. $\\forall n\\, \\big(n \\ge 2 \\to \\exists p\\, (\\text{prime}(p) \\land p \\mid n)\\big)$',
      '2. Formel für „p ist die grösste Primzahl“: $\\text{prime}(p) \\land \\forall q\\, (\\text{prime}(q) \\to q \\le p)$.',
      'Negation der Existenz einer solchen Zahl: $\\neg \\exists p\\, \\big(\\text{prime}(p) \\land \\forall q\\, (\\text{prime}(q) \\to q \\le p)\\big)$',
      'Äquivalent: $\\forall p\\, \\big(\\text{prime}(p) \\to \\exists q\\, (\\text{prime}(q) \\land q > p)\\big)$'
    ],
    res: 'Unter ∀ steht →, unter ∃ steht ∧.',
    m: 'Bereichseinschränkungen: ∀x (Bedingung → …) und ∃x (Bedingung ∧ …).', s: 'Skript DiskMath 2.4' },

  // ---------------- 2.6 Beweismuster ----------------
  { id: 'dm4-01', t: 'dm4', d: 1, k: 'sc',
    q: 'Was zeigt ein **indirekter** Beweis der Implikation S ⟹ T?',
    o: ['¬T ⟹ ¬S', '¬S ⟹ ¬T', 'T ⟹ S', 'S ∧ ¬T ist wahr'], a: 0,
    w: { 1: 'Das ist die Umkehrung der Kontraposition und nicht äquivalent.', 2: 'Das ist die Umkehrung, nicht äquivalent.', 3: 'Das würde S ⟹ T widerlegen.' },
    e: 'Man nimmt an, dass T falsch ist, und zeigt, dass dann S falsch ist. Das ist korrekt, weil $\\neg B \\to \\neg A \\models A \\to B$ (Lemma 2.6).',
    m: 'Indirekt = Kontraposition.', s: 'Skript DiskMath 2.6.2' },

  { id: 'dm4-02', t: 'dm4', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Personen braucht man mindestens, damit sicher **5** davon im selben Monat Geburtstag haben?',
    o: ['49', '48', '60', '61'], a: 0,
    w: { 1: 'Mit 48 können je 4 auf jeden Monat fallen.', 2: 'Das reicht, ist aber nicht minimal.' },
    e: 'Schubfachprinzip: bei n Objekten in 12 Fächern enthält ein Fach mindestens ⌈n/12⌉. Es braucht ⌈n/12⌉ ≥ 5, also n > 48, also n = 49.',
    m: 'Schubfach: ⌈n / k⌉.', s: 'Skript DiskMath 2.6.7, Theorem 2.10' },

  { id: 'dm4-03', t: 'dm4', d: 2, k: 'sc', fix: true,
    q: 'Was ist das kleinste n ∈ ℕ, für das $n^2 - n + 41$ **keine** Primzahl ist?',
    o: ['41', '40', '42', '39'], a: 0,
    e: 'Für n = 41 ist $41^2 - 41 + 41 = 41^2$, also zusammengesetzt. Für n = 0 bis 40 ergeben sich nur Primzahlen. Das zeigt: viele passende Beispiele beweisen nichts, ein Gegenbeispiel widerlegt.',
    m: 'Ein Gegenbeispiel widerlegt eine Allaussage.', s: 'Skript DiskMath 2.6.8, Beispiel 2.34' },

  { id: 'dm4-04', t: 'dm4', d: 2, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Ein Beweis durch Gegenbeispiel ist ein Existenzbeweis.', true, 'Man zeigt, dass ein a mit ¬Sₐ existiert.'],
      ['Ein nicht-konstruktiver Existenzbeweis gibt ein konkretes Beispiel an.', false, 'Er zeigt nur, dass es eines geben muss.'],
      ['Bei einer Fallunterscheidung muss man auch zeigen, dass die Fälle alles abdecken.', true, 'Schritt 2 der Definition: mindestens ein Fall tritt ein.'],
      ['Für einen Widerspruchsbeweis von S nimmt man an, dass S falsch ist.', true, 'Dann leitet man eine falsche Aussage T her.']
    ],
    e: 'Jedes Beweismuster beruht auf einer Tautologie der Aussagenlogik (Lemmata 2.5–2.9).', m: 'Konstruktiv = Zeuge wird angegeben.', s: 'Skript DiskMath 2.6' },

  { id: 'dm4-05', t: 'dm4', d: 3, k: 'sc',
    q: 'Jemand zeigt P(0) und $\\forall n \\ge 1\\, (P(n) \\to P(n + 1))$. Was ist damit bewiesen?',
    o: ['Nur P(0). Für P(1) fehlt der Schritt von 0 auf 1', 'P(n) für alle n ∈ ℕ', 'P(n) für alle n ≥ 1', 'P(n) für alle geraden n'], a: 0,
    w: { 1: 'Die Kette bricht zwischen 0 und 1.', 2: 'Dafür müsste P(1) bewiesen sein.' },
    e: 'Die Induktion braucht eine lückenlose Kette ab der Basis. Hier wird P(1) nie hergeleitet, also kommt man nicht über P(0) hinaus. Mit zusätzlich P(1) wäre alles bewiesen.',
    m: 'Basis und Schritt müssen aneinander anschliessen.', s: 'Skript DiskMath 2.6.9, Theorem 2.11' },

  { id: 'dm4-06', t: 'dm4', d: 3, k: 'sc',
    q: 'Behauptung: Jede Teilmenge A ⊆ {1, 2, …, 2n} mit n + 1 Elementen enthält zwei Zahlen, von denen eine die andere teilt. Was sind beim Schubfach-Beweis die „Schubfächer“?',
    o: ['Die ungeraden Zahlen m, wobei jedes a als $2^k \\cdot m$ mit ungeradem m geschrieben wird', 'Die Paare {2i − 1, 2i}', 'Die Primzahlen bis 2n', 'Die Reste modulo n'], a: 0,
    w: { 1: 'Damit findet man zwei aufeinanderfolgende (also teilerfremde) Zahlen, nicht Teiler.' },
    e: 'Es gibt nur n ungerade Zahlen in {1, …, 2n}. Bei n + 1 Elementen haben zwei denselben ungeraden Anteil m: $a = 2^k m$, $b = 2^l m$ mit k < l. Dann teilt a die Zahl b.',
    m: 'Beim Schubfachprinzip ist die Wahl der Fächer die eigentliche Idee.', s: 'Skript DiskMath 2.6.7, Beispiel 2.32' },

  { id: 'dm4-07', t: 'dm4', d: 3, k: 'sc', fix: true,
    q: 'Eine Folge besteht aus 10 verschiedenen reellen Zahlen. Welche Länge einer streng monotonen Teilfolge (steigend oder fallend) ist **garantiert**?',
    o: ['4', '3', '5', '10'], a: 0,
    w: { 1: 'Garantiert ist mehr.', 2: 'Dafür bräuchte es 17 Zahlen.' },
    e: 'Jede Folge aus $n^2 + 1$ verschiedenen Zahlen hat eine streng monotone Teilfolge der Länge n + 1. Mit 10 = 3² + 1 sind das 4. Beweisidee: Jedem Glied ordnet man die Länge der längsten steigenden Teilfolge zu, die dort beginnt, und wendet das Schubfachprinzip an.',
    m: 'Erdős–Szekeres: $n^2 + 1$ Zahlen → Länge n + 1.', s: 'Skript DiskMath 2.6.7, Beispiel 2.33' },

  { id: 'dm4-w1', t: 'dm4', d: 1, k: 'w',
    q: 'Beweise per Induktion: Für alle n ≥ 1 gilt $\\sum_{i=1}^{n} (2i - 1) = n^2$.',
    sol: [
      'Basis n = 1: links 1, rechts 1² = 1.',
      'Induktionsannahme: Für ein n ≥ 1 gilt $\\sum_{i=1}^{n} (2i - 1) = n^2$.',
      'Schritt: $\\sum_{i=1}^{n+1} (2i - 1) = n^2 + (2(n + 1) - 1) = n^2 + 2n + 1 = (n + 1)^2$.',
      'Nach dem Induktionsprinzip gilt die Aussage für alle n ≥ 1.'
    ],
    res: 'Die Summe der ersten n ungeraden Zahlen ist n².',
    m: 'Im Schritt den letzten Summanden abspalten und die Annahme einsetzen.', s: 'Skript DiskMath 2.6.9' },

  { id: 'dm4-w2', t: 'dm4', d: 2, k: 'w',
    q: 'Beweise: Wählt man aus {1, 2, …, 2n} beliebige n + 1 Zahlen, so sind zwei davon **teilerfremd**.',
    hint: 'Welche Zahlen sind sicher teilerfremd? Bilde n Schubfächer.',
    sol: [
      'Schubfächer: die n Paare {1, 2}, {3, 4}, …, {2n − 1, 2n}.',
      'n + 1 Zahlen in n Fächern: ein Fach enthält zwei gewählte Zahlen, also k und k + 1.',
      'Jeder gemeinsame Teiler d von k und k + 1 teilt auch (k + 1) − k = 1. Also gcd(k, k + 1) = 1.'
    ],
    res: 'Zwei aufeinanderfolgende Zahlen sind immer teilerfremd.',
    m: 'Schubfachprinzip: Fächer so wählen, dass „zwei im selben Fach“ die Behauptung liefert.', s: 'Skript DiskMath 2.6.7' },

  { id: 'dm4-w3', t: 'dm4', d: 2, k: 'w',
    q: 'Beweise durch Widerspruch, dass $\\sqrt{3}$ irrational ist.',
    sol: [
      'Annahme: $\\sqrt{3} = m/n$ mit m, n ∈ ℤ, n ≠ 0 und gcd(m, n) = 1.',
      'Dann ist $m^2 = 3n^2$, also 3 ∣ m². Weil 3 prim ist, folgt 3 ∣ m, also m = 3k.',
      'Einsetzen: $9k^2 = 3n^2$, also $n^2 = 3k^2$, also 3 ∣ n.',
      'Damit ist 3 ein gemeinsamer Teiler von m und n, Widerspruch zu gcd(m, n) = 1.'
    ],
    res: 'Die Annahme führt zum Widerspruch, also ist √3 irrational.',
    m: 'Gekürzten Bruch annehmen, gemeinsamen Teiler herleiten.', s: 'Skript DiskMath 2.6.6, Beispiel 2.28' },

  // ---------------- 3.1–3.2 Mengen ----------------
  { id: 'dm5-01', t: 'dm5', d: 1, k: 'sc', fix: true,
    q: 'Wie viele Elemente hat $\\mathcal{P}(\\{a, b, c\\})$?',
    o: ['8', '6', '3', '9'], a: 0,
    e: 'Jedes Element ist drin oder nicht: $2^3 = 8$ Teilmengen, darunter ∅ und {a, b, c}.',
    m: '$|\\mathcal{P}(A)| = 2^{|A|}$', s: 'Skript DiskMath 3.2, Definition 3.7' },

  { id: 'dm5-02', t: 'dm5', d: 2, k: 'mc',
    q: 'Sei $A = \\{\\emptyset, \\{\\emptyset\\}\\}$. Welche Aussagen stimmen? Wähle alle.',
    o: ['$\\emptyset \\in A$', '$\\{\\emptyset\\} \\subseteq A$', '$\\{\\{\\emptyset\\}\\} \\in A$', '$|\\mathcal{P}(A)| = 4$', '$\\{\\emptyset, \\{\\emptyset\\}\\} \\in A$'], a: [0, 1, 3],
    w: { 0: '∅ ist ein Element von A.', 1: 'Das einzige Element von {∅}, nämlich ∅, liegt in A.', 2: 'A enthält {∅}, aber nicht {{∅}}. Es gilt aber {{∅}} ⊆ A.', 3: '|A| = 2.', 4: 'Das ist A selbst, A ∈ A gilt nicht.' },
    e: 'Unterscheide genau: „∈“ fragt, ob etwas ein Element ist. „⊆“ fragt, ob alle Elemente der linken Menge in der rechten liegen.',
    m: 'x ∈ A ⟺ {x} ⊆ A', s: 'Skript DiskMath 3.2, Beispiel 3.3' },

  { id: 'dm5-03', t: 'dm5', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Elemente hat $\\mathcal{P}(\\mathcal{P}(\\mathcal{P}(\\emptyset)))$?',
    o: ['4', '2', '1', '8'], a: 0,
    e: '$\\mathcal{P}(\\emptyset) = \\{\\emptyset\\}$ hat 1 Element. $\\mathcal{P}$ davon hat $2^1 = 2$ Elemente, und die nächste Potenzmenge hat $2^2 = 4$.',
    m: 'Die leere Menge hat genau eine Teilmenge: sich selbst.', s: 'Skript DiskMath 3.2, Beispiel 3.6' },

  { id: 'dm5-04', t: 'dm5', d: 2, k: 'tf',
    q: 'Gelten diese Gleichungen für alle Mengen A, B, C?',
    rows: [
      ['$A \\setminus (B \\cup C) = (A \\setminus B) \\cap (A \\setminus C)$', true, 'De Morgan für Mengen.'],
      ['$A \\cup (B \\cap C) = (A \\cup B) \\cap (A \\cup C)$', true, 'Distributivgesetz.'],
      ['$A \\setminus (B \\setminus C) = (A \\setminus B) \\setminus C$', false, 'A = C = {1}, B = ∅: links {1}, rechts ∅.'],
      ['$A \\times (B \\cup C) = (A \\times B) \\cup (A \\times C)$', true, 'Das kartesische Produkt verteilt sich über ∪.'],
      ['$\\mathcal{P}(A \\cup B) = \\mathcal{P}(A) \\cup \\mathcal{P}(B)$', false, 'A = {1}, B = {2}: {1, 2} liegt nur links.']
    ],
    e: 'Ein Gegenbeispiel mit ganz kleinen Mengen reicht, um eine Gleichung zu widerlegen.', m: 'Gegenbeispiele mit ∅ und Einermengen suchen.', s: 'Skript DiskMath 3.2, Theorem 3.4' },

  { id: 'dm5-05', t: 'dm5', d: 3, k: 'sc',
    q: 'Welche Aussage gilt für **alle** Mengen A, B?',
    o: ['$\\mathcal{P}(A) \\cap \\mathcal{P}(B) = \\mathcal{P}(A \\cap B)$', '$\\mathcal{P}(A) \\cup \\mathcal{P}(B) = \\mathcal{P}(A \\cup B)$', '$\\mathcal{P}(A \\setminus B) = \\mathcal{P}(A) \\setminus \\mathcal{P}(B)$', '$\\mathcal{P}(A \\times B) = \\mathcal{P}(A) \\times \\mathcal{P}(B)$'], a: 0,
    w: { 1: 'Nur ⊆ gilt.', 2: '∅ liegt links, aber nicht rechts.', 3: 'Links stehen Mengen von Paaren, rechts Paare von Mengen.' },
    e: 'S ⊆ A und S ⊆ B gilt genau dann, wenn S ⊆ A ∩ B. Also haben beide Seiten dieselben Elemente.',
    m: 'Mengengleichheit: zeige x ∈ links ⟺ x ∈ rechts.', s: 'Skript DiskMath 3.2' },

  { id: 'dm5-06', t: 'dm5', d: 2, k: 'sc', fix: true,
    q: 'Wie viele verschiedene **Relationen** von A = {1, 2, 3} nach B = {a, b} gibt es?',
    o: ['64', '6', '8', '9'], a: 0,
    w: { 1: 'So viele Elemente hat A × B.', 2: 'So viele Funktionen A → B gibt es.' },
    e: 'Eine Relation ist eine beliebige Teilmenge von A × B. |A × B| = 6, also gibt es $2^6 = 64$ Relationen.',
    m: 'Relationen von A nach B = Teilmengen von A × B.', s: 'Skript DiskMath 3.3, Definition 3.9' },

  { id: 'dm5-w1', t: 'dm5', d: 1, k: 'w',
    q: 'Beweise für alle Mengen A, B, C: $A \\setminus (B \\cap C) = (A \\setminus B) \\cup (A \\setminus C)$',
    sol: [
      'Zeige für beliebiges x: x ∈ links ⟺ x ∈ rechts.',
      '$x \\in A \\setminus (B \\cap C) \\iff x \\in A \\land \\neg(x \\in B \\land x \\in C)$',
      '$\\iff x \\in A \\land (x \\notin B \\lor x \\notin C)$ (De Morgan)',
      '$\\iff (x \\in A \\land x \\notin B) \\lor (x \\in A \\land x \\notin C)$ (Distributivität)',
      '$\\iff x \\in (A \\setminus B) \\cup (A \\setminus C)$'
    ],
    res: 'Mengengleichheit über die logische Äquivalenz der Bedingungen.',
    m: 'Mengengesetze sind Logikgesetze in anderer Schreibweise.', s: 'Skript DiskMath 3.2, Theorem 3.4' },

  // ---------------- 3.3 Relationen ----------------
  { id: 'dm6-01', t: 'dm6', d: 1, k: 'sc',
    q: 'Ist $\\rho = \\{(1, 1), (2, 2), (1, 2)\\}$ auf A = {1, 2, 3} reflexiv?',
    o: ['Nein, (3, 3) fehlt', 'Ja', 'Nein, (2, 1) fehlt', 'Nein, reflexiv geht nur auf ℕ'], a: 0,
    w: { 2: 'Das betrifft die Symmetrie, nicht die Reflexivität.' },
    e: 'Reflexiv heisst: a ρ a für **alle** a ∈ A, also id ⊆ ρ. Das Element 3 steht nicht in Relation zu sich selbst.',
    m: 'Reflexivität hängt von der Grundmenge A ab.', s: 'Skript DiskMath 3.3, Definition 3.13' },

  { id: 'dm6-02', t: 'dm6', d: 2, k: 'mc',
    q: 'Welche Eigenschaften hat $\\rho = \\{(1, 2), (2, 1), (1, 1)\\}$ auf A = {1, 2, 3}? Wähle alle.',
    o: ['symmetrisch', 'reflexiv', 'transitiv', 'antisymmetrisch', 'irreflexiv'], a: [0],
    w: { 0: 'Zu jedem Paar ist auch das umgekehrte drin.', 1: '(2, 2) und (3, 3) fehlen.', 2: '(2, 1) und (1, 2) verlangen (2, 2).', 3: '(1, 2) und (2, 1) mit 1 ≠ 2.', 4: '(1, 1) ist enthalten.' },
    e: 'Transitivität prüfst du, indem du alle Ketten a ρ b ρ c durchgehst: (2, 1), (1, 2) ergibt (2, 2), das fehlt.',
    m: 'Nicht reflexiv heisst noch nicht irreflexiv.', s: 'Skript DiskMath 3.3.4' },

  { id: 'dm6-03', t: 'dm6', d: 2, k: 'sc',
    q: '$\\rho = \\{(1, 2), (2, 3)\\}$ und $\\sigma = \\{(2, a), (3, b), (1, c)\\}$. Was ist $\\rho \\circ \\sigma$ (Definition im Skript: erst ρ, dann σ)?',
    o: ['$\\{(1, a), (2, b)\\}$', '$\\{(1, c)\\}$', '$\\{(1, a), (2, b), (1, c)\\}$', '$\\{(2, a), (3, b)\\}$'], a: 0,
    e: '$\\rho \\circ \\sigma = \\{(x, z) \\mid \\exists y\\, (x \\rho y \\land y \\sigma z)\\}$. 1 → 2 → a und 2 → 3 → b.',
    m: 'Im Skript: ρ ∘ σ heisst „zuerst ρ, dann σ“. Bei Funktionen ist g ∘ f „zuerst f“.', s: 'Skript DiskMath 3.3.3, Definition 3.12' },

  { id: 'dm6-04', t: 'dm6', d: 2, k: 'sc',
    q: 'Was ist das Inverse $\\widehat{\\rho\\sigma}$ der Komposition?',
    o: ['$\\hat{\\sigma}\\hat{\\rho}$', '$\\hat{\\rho}\\hat{\\sigma}$', '$\\rho\\sigma$', '$\\sigma\\rho$'], a: 0,
    e: 'Ist x ρ y und y σ z, dann z σ̂ y und y ρ̂ x. Rückwärts geht man zuerst durch σ̂, dann durch ρ̂ (Lemma 3.8).',
    m: 'Umkehren kehrt die Reihenfolge um, wie bei Socken und Schuhen.', s: 'Skript DiskMath 3.3.3, Lemma 3.8' },

  { id: 'dm6-05', t: 'dm6', d: 3, k: 'sc', fix: true,
    q: 'Wie viele Relationen auf {1, 2, 3} sind gleichzeitig **reflexiv und symmetrisch**?',
    o: ['8', '64', '512', '16'], a: 0,
    w: { 1: 'So viele sind reflexiv, oder auch so viele symmetrisch.', 2: 'So viele Relationen gibt es insgesamt.' },
    e: 'Die 3 Diagonalpaare müssen drin sein. Von den 6 übrigen Paaren bilden je zwei ein symmetrisches Paar {(a, b), (b, a)}, das ganz oder gar nicht drin ist: 3 Entscheidungen, also $2^3 = 8$.',
    m: 'Abzählen: was ist erzwungen, was ist frei, was ist gekoppelt?', s: 'Skript DiskMath 3.3.4' },

  { id: 'dm6-06', t: 'dm6', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Paare hat die transitive Hülle $\\rho^*$ von $\\rho = \\{(1, 2), (2, 3), (3, 4)\\}$?',
    o: ['6', '3', '10', '16'], a: 0,
    w: { 2: 'Die Diagonale gehört hier nicht dazu: ρ* ist die Vereinigung der ρⁿ für n ≥ 1.' },
    e: 'ρ² = {(1, 3), (2, 4)}, ρ³ = {(1, 4)}, ρ⁴ = ∅. Zusammen 3 + 2 + 1 = 6 Paare.',
    m: '$\\rho^* = \\bigcup_{n \\ge 1} \\rho^n$', s: 'Skript DiskMath 3.3.5, Definition 3.18' },

  { id: 'dm6-07', t: 'dm6', d: 3, k: 'tf',
    q: 'ρ ist eine Relation auf einer nicht leeren Menge A. Wahr oder falsch?',
    rows: [
      ['Ist ρ symmetrisch und antisymmetrisch, dann ist ρ ⊆ id.', true, 'Aus a ρ b folgt b ρ a, und dann a = b.'],
      ['Die leere Relation ist reflexiv.', false, 'A ist nicht leer, also fehlt (a, a).'],
      ['Die leere Relation ist transitiv.', true, 'Es gibt keine Kette, die man prüfen müsste.'],
      ['ρ ist genau dann transitiv, wenn $\\rho^2 \\subseteq \\rho$.', true, 'Das ist Lemma 3.9.'],
      ['Ist ρ symmetrisch und transitiv, dann ist ρ reflexiv.', false, 'Die leere Relation ist ein Gegenbeispiel: a muss gar nicht in Relation zu etwas stehen.']
    ],
    e: 'Der „Beweis“ für die letzte Aussage (a ρ b, b ρ a, also a ρ a) setzt voraus, dass es ein b gibt.', m: 'Leere Relation als Testfall verwenden.', s: 'Skript DiskMath 3.3.4–3.3.5' },

  { id: 'dm6-w1', t: 'dm6', d: 1, k: 'w',
    q: 'Sei $\\rho = \\{(1, 2), (2, 3), (3, 1)\\}$ auf {1, 2, 3}. Berechne $\\rho^2$, $\\rho^3$ und $\\rho^*$. Wie viele Paare hat $\\rho^*$?',
    ans: { k: 'num', v: 9 },
    sol: [
      '$\\rho^2 = \\rho \\circ \\rho$: 1 → 2 → 3, 2 → 3 → 1, 3 → 1 → 2, also $\\{(1, 3), (2, 1), (3, 2)\\}$.',
      '$\\rho^3$: 1 → 2 → 3 → 1 usw., also $\\{(1, 1), (2, 2), (3, 3)\\}$.',
      '$\\rho^4 = \\rho$, danach wiederholt es sich.',
      '$\\rho^* = \\rho \\cup \\rho^2 \\cup \\rho^3$ enthält alle 9 Paare.'
    ],
    res: '$\\rho^* = \\{1, 2, 3\\}^2$ mit 9 Paaren',
    m: 'Bei Zyklen wiederholen sich die Potenzen.', s: 'Skript DiskMath 3.3.5' },

  // ---------------- 3.4 Äquivalenzrelationen ----------------
  { id: 'dm7-01', t: 'dm7', d: 1, k: 'sc',
    q: 'Was ist die Äquivalenzklasse $[3]_{\\equiv_5}$ in ℤ?',
    o: ['$\\{\\ldots, -7, -2, 3, 8, 13, \\ldots\\}$', '$\\{0, 1, 2, 3, 4\\}$', '$\\{3\\}$', '$\\{3, 8, 13, \\ldots\\}$'], a: 0,
    w: { 3: 'Auch negative Zahlen wie −2 sind kongruent zu 3 modulo 5.' },
    e: 'Alle ganzen Zahlen mit demselben Rest wie 3 bei Division durch 5, also 3 + 5k für k ∈ ℤ.',
    m: '$[a]_\\theta = \\{b \\mid b\\, \\theta\\, a\\}$', s: 'Skript DiskMath 3.4, Definition 3.20' },

  { id: 'dm7-02', t: 'dm7', d: 3, k: 'sc', fix: true,
    q: 'Wie viele verschiedene Äquivalenzrelationen gibt es auf {1, 2, 3}?',
    o: ['5', '3', '8', '27'], a: 0,
    e: 'Äquivalenzrelationen entsprechen genau den Partitionen (Theorem 3.11). Partitionen von {1, 2, 3}: alles einzeln; {1, 2}{3}; {1, 3}{2}; {2, 3}{1}; alles zusammen. Das sind 5.',
    m: 'Äquivalenzrelation ↔ Partition.', s: 'Skript DiskMath 3.4, Theorem 3.11' },

  { id: 'dm7-03', t: 'dm7', d: 2, k: 'sc', fix: true,
    q: 'Wie viele Paare enthält die Äquivalenzrelation auf {1, 2, 3, 4, 5} mit den Klassen {1, 2, 3} und {4, 5}?',
    o: ['13', '5', '8', '7'], a: 0,
    e: 'Innerhalb einer Klasse steht jedes Element mit jedem in Relation (auch mit sich selbst): $3^2 + 2^2 = 9 + 4 = 13$.',
    m: 'Klasse der Grösse k liefert k² Paare.', s: 'Skript DiskMath 3.4' },

  { id: 'dm7-04', t: 'dm7', d: 2, k: 'sc',
    q: 'Welche Relation ist $\\equiv_4 \\cap \\equiv_6$ auf ℤ?',
    o: ['$\\equiv_{12}$', '$\\equiv_{24}$', '$\\equiv_2$', '$\\equiv_{10}$'], a: 0,
    w: { 1: '4 und 6 sind nicht teilerfremd.', 2: 'Das wäre der ggT, aber ∩ verlangt beide Bedingungen.' },
    e: 'a ≡ b in beiden heisst: 4 ∣ a − b und 6 ∣ a − b, also kgV(4, 6) = 12 ∣ a − b. Der Schnitt zweier Äquivalenzrelationen ist wieder eine (Lemma 3.10).',
    m: 'Schnitt von ≡ₘ und ≡ₙ ist ≡ mit kgV(m, n).', s: 'Skript DiskMath 3.4, Lemma 3.10' },

  { id: 'dm7-05', t: 'dm7', d: 3, k: 'sc',
    q: 'Ist $\\equiv_2 \\cup \\equiv_3$ eine Äquivalenzrelation auf ℤ?',
    o: ['Nein, sie ist nicht transitiv', 'Ja', 'Nein, sie ist nicht symmetrisch', 'Nein, sie ist nicht reflexiv'], a: 0,
    w: { 2: 'Beide Teile sind symmetrisch, die Vereinigung auch.', 3: 'Beide Teile sind reflexiv.' },
    e: '0 ≡₂ 2 und 2 ≡₃ 5, also stehen 0 ~ 2 und 2 ~ 5 in der Vereinigung. Aber 0 und 5 sind weder modulo 2 noch modulo 3 kongruent.',
    m: 'Schnitt ja, Vereinigung im Allgemeinen nein.', s: 'Skript DiskMath 3.4' },

  { id: 'dm7-w1', t: 'dm7', d: 3, k: 'w',
    q: 'Auf $A = \\Z \\times (\\Z \\setminus \\{0\\})$ sei $(a, b) \\sim (c, d) :\\iff ad = bc$. Beweise, dass ∼ eine Äquivalenzrelation ist. Wo brauchst du, dass die zweiten Komponenten ≠ 0 sind?',
    sol: [
      'Reflexiv: ab = ba.',
      'Symmetrisch: aus ad = bc folgt cb = da.',
      'Transitiv: Es gelte ad = bc und cf = de. Multipliziere die erste Gleichung mit f: adf = bcf = b(cf) = b(de). Also $d \\cdot (af) = d \\cdot (be)$.',
      'Weil d ≠ 0 ist, darf man kürzen (ℤ hat keine Nullteiler): af = be, also (a, b) ∼ (e, f).',
      'Die Bedingung ≠ 0 wird genau beim Kürzen durch d gebraucht. Mit d = 0 wäre z. B. (1, 1) ∼ (0, 0) ∼ (2, 1), aber (1, 1) ≁ (2, 1).'
    ],
    res: 'Die Klassen sind genau die rationalen Zahlen a/b.',
    m: 'Transitivität ist meistens der Teil mit der eigentlichen Arbeit.', s: 'Skript DiskMath 3.4' },

  // ---------------- 3.5 Ordnungsrelationen ----------------
  { id: 'dm8-01', t: 'dm8', d: 1, k: 'sc',
    q: 'Welche Relation ist **keine** Halbordnung (partielle Ordnung)?',
    o: ['< auf ℤ', '≤ auf ℤ', '∣ auf ℕ ∖ {0}', '⊆ auf P(A)'], a: 0,
    w: { 2: 'Auf ℕ ∖ {0} ist ∣ antisymmetrisch. (Auf ℤ wäre 2 ∣ −2 und −2 ∣ 2.)' },
    e: 'Eine Halbordnung ist reflexiv, antisymmetrisch und transitiv. < ist nicht reflexiv, weil a < a nie gilt.',
    m: 'Halbordnung = reflexiv + antisymmetrisch + transitiv.', s: 'Skript DiskMath 3.5, Definition 3.23' },

  { id: 'dm8-02', t: 'dm8', d: 2, k: 'sc', fix: true,
    q: 'Wie viele **maximale** Elemente hat die Halbordnung ({2, 3, 4, 5, 6, 7, 8, 9}; ∣)?',
    o: ['5', '1', '3', '4'], a: 0,
    w: { 1: 'Es gibt kein grösstes Element.' },
    e: 'Maximal heisst: kein anderes Element der Menge ist ein Vielfaches. Das sind 5, 6, 7, 8 und 9. Die minimalen Elemente sind 2, 3, 5 und 7.',
    m: 'Maximal ≠ grösstes Element.', s: 'Skript DiskMath 3.5, Definition 3.29' },

  { id: 'dm8-03', t: 'dm8', d: 2, k: 'tf',
    q: 'Wahr oder falsch?',
    rows: [
      ['Jede endliche, nicht leere Halbordnung hat ein minimales Element.', true, 'Geh von einem Element aus immer weiter nach unten, das endet.'],
      ['Eine Halbordnung hat höchstens ein kleinstes Element.', true, 'Zwei kleinste a, b: a ⪯ b und b ⪯ a, also a = b.'],
      ['Jedes minimale Element ist ein kleinstes Element.', false, 'In ({2, 3}; ∣) sind 2 und 3 minimal, aber keines ist kleinstes.'],
      ['(ℤ; ≤) ist wohlgeordnet.', false, 'ℤ selbst hat kein kleinstes Element.'],
      ['(ℕ; ≤) ist wohlgeordnet.', true, 'Jede nicht leere Teilmenge hat ein kleinstes Element.']
    ],
    e: 'Minimal heisst „nichts darunter“, kleinstes heisst „unter allem“. Das fällt nur bei totalen Ordnungen zusammen.', m: 'Wohlordnung = total + jede nicht leere Teilmenge hat ein Minimum.', s: 'Skript DiskMath 3.5' },

  { id: 'dm8-04', t: 'dm8', d: 2, k: 'sc',
    q: 'Im direkten Produkt (ℕ; ≤) × (ℕ; ≤) mit (a₁, b₁) ≤ (a₂, b₂) ⟺ a₁ ≤ a₂ ∧ b₁ ≤ b₂: Wie stehen (1, 3) und (2, 2) zueinander?',
    o: ['Sie sind unvergleichbar', '(1, 3) ≤ (2, 2)', '(2, 2) ≤ (1, 3)', 'Sie sind gleich'], a: 0,
    w: { 1: 'Das gilt in der lexikographischen Ordnung, nicht im direkten Produkt.' },
    e: 'Erste Komponente: 1 ≤ 2. Zweite Komponente: 3 > 2. Keine Richtung erfüllt beide Bedingungen. Das direkte Produkt totaler Ordnungen ist im Allgemeinen nicht total.',
    m: 'Direktes Produkt: komponentenweise. Lexikographisch: zuerst die erste Komponente.', s: 'Skript DiskMath 3.5.3, Definition 3.28' },

  { id: 'dm8-05', t: 'dm8', d: 3, k: 'sc', fix: true,
    q: 'Wie viele Kanten hat das Hasse-Diagramm von $(\\mathcal{P}(\\{a, b, c\\}); \\subseteq)$?',
    o: ['12', '8', '19', '27'], a: 0,
    w: { 1: 'Das ist die Anzahl Knoten.', 2: 'Das wäre die Anzahl echter Inklusionen ohne Reflexivität. Im Hasse-Diagramm stehen nur Überdeckungen.' },
    e: 'Kanten verbinden nur Überdeckungen: S wird von T überdeckt, wenn T genau ein Element mehr hat. Jede k-elementige Menge hat k Kanten nach unten: $0 \\cdot 1 + 1 \\cdot 3 + 2 \\cdot 3 + 3 \\cdot 1 = 12$.',
    m: 'Hasse-Diagramm: nur Überdeckungen, ohne Schleifen und ohne transitive Kanten.', s: 'Skript DiskMath 3.5.2, Beispiel 3.44' },

  { id: 'dm8-06', t: 'dm8', d: 3, k: 'sc',
    q: 'Ist ({1, 2, 3}; ∣) ein Verband (jedes Paar hat Meet und Join)?',
    o: ['Nein, 2 und 3 haben keine obere Schranke in der Menge', 'Ja', 'Nein, 2 und 3 haben keine untere Schranke', 'Nein, weil die Ordnung nicht total ist'], a: 0,
    w: { 2: '1 teilt beide, also gibt es ein Meet: 1.', 3: 'Verbände müssen nicht total sein, z. B. (P(A); ⊆).' },
    e: 'Ein Join von 2 und 3 müsste eine kleinste obere Schranke sein, also ein Element, das von 2 und 3 geteilt wird. In {1, 2, 3} gibt es keines. Mit 6 in der Menge wäre es ein Verband.',
    m: 'In (ℕ; ∣) ist Meet = ggT und Join = kgV, sofern die in der Menge liegen.', s: 'Skript DiskMath 3.5.4, Definition 3.31' },

  { id: 'dm8-w1', t: 'dm8', d: 2, k: 'w',
    q: 'Zeichne das Hasse-Diagramm von ({1, 2, 3, 4, 6, 8, 12, 24}; ∣). Gib minimale, maximale, kleinste und grösste Elemente an. Wie viele Kanten hat das Diagramm?',
    ans: { k: 'num', v: 10 },
    sol: [
      'Überdeckungen (a wird von b überdeckt, wenn b/a eine Primzahl ist): 1–2, 1–3, 2–4, 2–6, 3–6, 4–8, 4–12, 6–12, 8–24, 12–24.',
      'Das sind 10 Kanten.',
      'Kleinstes (und einziges minimales) Element: 1. Grösstes (und einziges maximales) Element: 24.',
      'Es ist sogar ein Verband: Meet = ggT, Join = kgV, beide liegen immer in der Menge.'
    ],
    res: '10 Kanten, kleinstes 1, grösstes 24',
    m: 'In (Teiler von n; ∣) verbindet eine Kante a mit a·p für eine Primzahl p.', s: 'Skript DiskMath 3.5.2, Beispiel 3.43' }
]);
