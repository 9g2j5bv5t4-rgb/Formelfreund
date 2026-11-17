// Fächer und Themen. Die Reihenfolge der Themen bestimmt die Regler:
// Regler auf Thema k heisst "Fragen aus Thema 1 bis k".
var QUIZ = (function () {
  var subjects = [
    { id: 'dm', name: 'DiskMath', long: 'Diskrete Mathematik', src: 'Skript Maurer' },
    { id: 'la', name: 'LinAlg', long: 'Lineare Algebra', src: 'Skript Gärtner / Bandeira–Weismantel' },
    { id: 'ad', name: 'AlgoDat', long: 'Algorithmen und Datenstrukturen', src: 'Skript AuD HS26' },
    { id: 'ep', name: 'EProg', long: 'Einführung in die Programmierung', src: 'Folien EProg' }
  ];

  var topics = {
    dm: [
      { id: 'dm1', nr: '2.1–2.2', name: 'Aussagen und Beweisbegriff' },
      { id: 'dm2', nr: '2.3', name: 'Aussagenlogik' },
      { id: 'dm3', nr: '2.4–2.5', name: 'Prädikatenlogik' },
      { id: 'dm4', nr: '2.6', name: 'Beweismuster' },
      { id: 'dm5', nr: '3.1–3.2', name: 'Mengen' },
      { id: 'dm6', nr: '3.3', name: 'Relationen' },
      { id: 'dm7', nr: '3.4', name: 'Äquivalenzrelationen' },
      { id: 'dm8', nr: '3.5', name: 'Ordnungsrelationen' },
      { id: 'dm9', nr: '3.6', name: 'Funktionen' },
      { id: 'dm10', nr: '3.7', name: 'Abzählbarkeit' },
      { id: 'dm11', nr: '4.1–4.4', name: 'Teilbarkeit, ggT, Primzahlen' },
      { id: 'dm12', nr: '4.5–4.6', name: 'Modulare Arithmetik' },
      { id: 'dm13', nr: '5.1–5.2', name: 'Monoide und Gruppen' },
      { id: 'dm14', nr: '5.3', name: 'Struktur von Gruppen' },
      { id: 'dm15', nr: '5.4', name: 'RSA' },
      { id: 'dm16', nr: '5.5', name: 'Ringe und Körper' },
      { id: 'dm17', nr: '5.6', name: 'Polynome über Körpern' }
    ],
    la: [
      { id: 'la1', nr: '1.1', name: 'Vektoren und Linearkombinationen' },
      { id: 'la2', nr: '1.2', name: 'Skalarprodukt, Norm, Winkel' },
      { id: 'la3', nr: '1.3', name: 'Lineare Unabhängigkeit, Span' },
      { id: 'la4', nr: '2.1', name: 'Spaltenraum, Rang, Nullraum' },
      { id: 'la5', nr: '2.2', name: 'Lineare Abbildungen' },
      { id: 'la6', nr: '2.3', name: 'Matrixmultiplikation, CR' },
      { id: 'la7', nr: '2.4', name: 'Inverse Matrizen' },
      { id: 'la8', nr: '3.1–3.2', name: 'Gauss-Elimination, LU' },
      { id: 'la9', nr: '3.3', name: 'Gauss-Jordan, RREF' },
      { id: 'la10', nr: '4.1–4.2.2', name: 'Vektorräume, Unterräume' },
      { id: 'la11', nr: '4.2.3–4.2.6', name: 'Basis, Dimension' },
      { id: 'la12', nr: '4.3', name: 'Vier Unterräume, Lösungsraum' },
      { id: 'la13', nr: 'II 5.1', name: 'Orthogonalität' },
      { id: 'la14', nr: 'II 5.2', name: 'Projektionen' },
      { id: 'la15', nr: 'II 6.1', name: 'Kleinste Quadrate' },
      { id: 'la16', nr: 'II 6.2', name: 'Lösungsmengen, Zertifikate' },
      { id: 'la17', nr: 'II 6.3', name: 'Pseudoinverse' }
    ],
    ad: [
      { id: 'ad1', nr: '1.1–1.3', name: 'Pasture Break, Induktion, Starsuche' },
      { id: 'ad2', nr: '1.4–1.5', name: 'Asymptotik, Karatsuba' },
      { id: 'ad3', nr: '1.6', name: 'Maximum Subarray Sum' },
      { id: 'ad4', nr: '2', name: 'Suchen' },
      { id: 'ad5', nr: '3.1–3.3', name: 'Bubble-, Selection-, InsertionSort' },
      { id: 'ad6', nr: '3.4–3.5', name: 'MergeSort, QuickSort' },
      { id: 'ad7', nr: '3.6–3.7', name: 'HeapSort, untere Schranke' },
      { id: 'ad8', nr: '4', name: 'Abstrakte Datentypen' },
      { id: 'ad9', nr: '5', name: 'Suchbäume, 2-3-Bäume' },
      { id: 'ad10', nr: '6', name: 'DP-Grundlagen' },
      { id: 'ad11', nr: '7', name: 'DP-Beispiele' },
      { id: 'ad12', nr: '8', name: 'P vs. NP, LAT, Matrixketten' },
      { id: 'ad13', nr: '9', name: 'Graphen, Eulerzyklen' },
      { id: 'ad14', nr: '10', name: 'Topo-Sort, DFS, BFS' },
      { id: 'ad15', nr: '11', name: 'Dijkstra, Bellman-Ford' }
    ],
    ep: [
      { id: 'ep1', nr: '1', name: 'EBNF' },
      { id: 'ep2', nr: '2', name: 'Erste Java-Programme' },
      { id: 'ep3', nr: '3', name: 'Kontrollstrukturen, Methoden' },
      { id: 'ep4', nr: '4', name: 'Strings und Arrays' },
      { id: 'ep5', nr: '5', name: 'Rekursion' },
      { id: 'ep6', nr: '6', name: 'Logisches Schliessen' },
      { id: 'ep7', nr: '7', name: 'Klassen und Objekte' },
      { id: 'ep8', nr: '8', name: 'Stil und Refactoring' },
      { id: 'ep9', nr: '9', name: 'Verkettete Liste, Wrapper' }
    ]
  };

  var questions = [];
  function add(subject, list) {
    for (var i = 0; i < list.length; i++) {
      list[i].f = subject;
      questions.push(list[i]);
    }
  }
  return { subjects: subjects, topics: topics, questions: questions, add: add };
})();
if (typeof module !== 'undefined') module.exports = QUIZ;
