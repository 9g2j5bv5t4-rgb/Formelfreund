// Prüft den Fragenkatalog: Pflichtfelder, gültige Antworten, Themen,
// Verteilung der Schwierigkeit. Mit --java werden EProg-Snippets, die ein
// Feld `out` haben, kompiliert und ausgeführt und die Ausgabe verglichen.
// Aufruf: node Quiz/tools/check.mjs [--java]
import { readFileSync, mkdtempSync, writeFileSync, rmSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';
import vm from 'node:vm';

const here = dirname(fileURLToPath(import.meta.url));
const src = (p) => readFileSync(join(here, '..', 'src', p), 'utf8');
const ctx = { module: undefined };
vm.createContext(ctx);
vm.runInContext(src('topics.js'), ctx);
for (const f of readdirSync(join(here, '..', 'src', 'questions')).filter((x) => x.endsWith('.js')).sort()) {
  try { vm.runInContext(src('questions/' + f), ctx, { filename: f }); }
  catch (e) { console.error('Fehler in', f, e.message); process.exitCode = 1; }
}
const QUIZ = vm.runInContext('QUIZ', ctx);
const Q = QUIZ.questions;
const errors = [];
const ids = new Set();
const topicIds = new Set(Object.values(QUIZ.topics).flat().map((t) => t.id));

for (const q of Q) {
  const where = q.id || JSON.stringify(q).slice(0, 60);
  if (!q.id) errors.push(`${where}: keine id`);
  if (ids.has(q.id)) errors.push(`${where}: doppelte id`);
  ids.add(q.id);
  if (!topicIds.has(q.t)) errors.push(`${where}: unbekanntes Thema ${q.t}`);
  if (!q.t || !q.t.startsWith(q.f)) errors.push(`${where}: Thema passt nicht zum Fach`);
  if (![1, 2, 3].includes(q.d)) errors.push(`${where}: Schwierigkeit fehlt`);
  if (!q.q) errors.push(`${where}: Fragetext fehlt`);
  if (q.k === 'sc') {
    if (!Array.isArray(q.o) || q.o.length < 2) errors.push(`${where}: Optionen fehlen`);
    if (!(Number.isInteger(q.a) && q.a >= 0 && q.a < q.o.length)) errors.push(`${where}: Antwortindex ungültig`);
    if (new Set(q.o).size !== q.o.length) errors.push(`${where}: doppelte Optionen`);
    if (!q.e) errors.push(`${where}: Erklärung fehlt`);
  } else if (q.k === 'mc') {
    if (!Array.isArray(q.a) || !q.a.length || q.a.some((x) => x < 0 || x >= q.o.length)) errors.push(`${where}: Antwortindizes ungültig`);
    if (!q.e) errors.push(`${where}: Erklärung fehlt`);
  } else if (q.k === 'tf') {
    if (!Array.isArray(q.rows) || q.rows.length < 2) errors.push(`${where}: Zeilen fehlen`);
    else q.rows.forEach((r, i) => { if (typeof r[1] !== 'boolean' || !r[2]) errors.push(`${where}: Zeile ${i + 1} unvollständig`); });
  } else if (q.k === 'w') {
    if (!Array.isArray(q.sol) || !q.sol.length) errors.push(`${where}: Lösungsschritte fehlen`);
    if (q.ans && !['num', 'vec', 'set', 'str'].includes(q.ans.k)) errors.push(`${where}: Antworttyp ungültig`);
  } else errors.push(`${where}: unbekannter Typ ${q.k}`);
  const text = [q.q, q.e, q.m, ...(q.o || []), ...(q.sol || [])].join(' ');
  if ((text.match(/\$/g) || []).length % 2) errors.push(`${where}: ungerade Anzahl $`);
}

// Verteilung
const rows = [];
for (const s of QUIZ.subjects) {
  for (const mode of ['tap', 'write']) {
    const list = Q.filter((q) => q.f === s.id && (mode === 'write') === (q.k === 'w'));
    const c = [1, 2, 3].map((d) => list.filter((q) => q.d === d).length);
    const n = list.length || 1;
    rows.push(`${s.name.padEnd(9)} ${mode.padEnd(5)} ${String(list.length).padStart(4)}  leicht ${String(c[0]).padStart(3)} (${Math.round(c[0] / n * 100)}%)  mittel ${String(c[1]).padStart(3)} (${Math.round(c[1] / n * 100)}%)  schwer ${String(c[2]).padStart(3)} (${Math.round(c[2] / n * 100)}%)`);
  }
  const perTopic = QUIZ.topics[s.id].map((t) => `${t.nr}:${Q.filter((q) => q.t === t.id && q.k !== 'w').length}/${Q.filter((q) => q.t === t.id && q.k === 'w').length}`);
  rows.push('   Themen (tap/write): ' + perTopic.join('  '));
}
console.log(rows.join('\n'));
console.log('Total', Q.length, 'Fragen');

// Java
if (process.argv.includes('--java')) {
  const dir = mkdtempSync(join(tmpdir(), 'quizjava-'));
  let ok = 0, bad = 0;
  for (const q of Q.filter((x) => x.out !== undefined)) {
    const { members, body } = splitJava(q.code);
    const file = `import java.util.*;\npublic class Main {\n${members}\npublic static void main(String[] args) {\n${body}\n}\n}\n`;
    writeFileSync(join(dir, 'Main.java'), file);
    const r = spawnSync('java', ['Main.java'], { cwd: dir, encoding: 'utf8', timeout: 20000, env: { ...process.env, JAVA_TOOL_OPTIONS: '' } });
    const stderr = (r.stderr || '').replace(/Picked up JAVA_TOOL_OPTIONS.*\n?/g, '');
    let got;
    if (/error:/.test(stderr) && /compil/i.test(stderr + 'compil') && r.status !== 0 && !/Exception in thread/.test(stderr)) got = '#compile-error';
    else if (/Exception in thread "main" ([\w.]+)/.test(stderr)) got = (r.stdout || '') + '#exception:' + /Exception in thread "main" ([\w.$]+)/.exec(stderr)[1].split('.').pop();
    else got = r.stdout;
    const want = q.out;
    if (norm(got) === norm(want)) ok++;
    else { bad++; errors.push(`${q.id}: Java-Ausgabe ${JSON.stringify(got)} statt ${JSON.stringify(want)}${got === '#compile-error' ? '\n' + stderr.split('\n').slice(0, 4).join('\n') : ''}`); }
  }
  rmSync(dir, { recursive: true, force: true });
  console.log(`Java: ${ok} ok, ${bad} abweichend`);
}

if (errors.length) { console.log('\nProbleme:\n- ' + errors.join('\n- ')); process.exitCode = 1; }
else console.log('Keine Probleme gefunden.');

function norm(s) { return String(s).replace(/\r/g, '').replace(/\s+$/g, ''); }
function splitJava(code) {
  // Top-Level-Deklarationen (Klassen, Methoden, Enums) werden Klassenmitglieder,
  // alle übrigen Zeilen landen in main.
  const lines = code.split('\n');
  const members = [], body = [];
  let depth = 0, inMember = false;
  for (const line of lines) {
    const start = depth === 0 && /^(static |public |private |class |enum |record |interface |final |abstract |int [a-zA-Z_]+\(|void |String [a-zA-Z_]+\(|boolean [a-zA-Z_]+\(|double [a-zA-Z_]+\()/.test(line);
    if (depth === 0 && start) inMember = true;
    let fixed = line;
    if (inMember && depth === 0 && /^(class |enum |record |interface )/.test(line)) fixed = 'static ' + line;
    if (inMember && depth === 0 && /^(int |void |String |boolean |double )[a-zA-Z_]+\(/.test(line)) fixed = 'static ' + line;
    (inMember ? members : body).push(fixed);
    for (const ch of line.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\/\/.*$/g, '')) { if (ch === '{') depth++; else if (ch === '}') depth--; }
    if (depth === 0) inMember = false;
  }
  return { members: members.join('\n'), body: body.join('\n') };
}
