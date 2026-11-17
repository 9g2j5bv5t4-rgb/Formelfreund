// Baut die App zu einer einzigen HTML-Datei: dist/basisjahr-quiz.html
// Aufruf: node Quiz/build.mjs
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = (p) => readFileSync(join(here, 'src', p), 'utf8');
const files = readdirSync(join(here, 'src', 'questions')).filter((f) => f.endsWith('.js')).sort();

// "</script" darf in eingebettetem Code nicht vorkommen
const safe = (s) => s.replace(/<\/script/gi, '<\\/script');

let html = src('shell.html');
html += '\n<script>\n' + safe(src('topics.js')) + '\n</script>\n';
for (const f of files) html += '<script>\n' + safe(src('questions/' + f)) + '\n</script>\n';
html += '<script>\n' + safe(src('app.js')) + '\n</script>\n';

mkdirSync(join(here, 'dist'), { recursive: true });
writeFileSync(join(here, 'dist', 'basisjahr-quiz.html'), html);
console.log('dist/basisjahr-quiz.html', (html.length / 1024).toFixed(0) + ' KB');
