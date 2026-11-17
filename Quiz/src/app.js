(function () {
  'use strict';
  var Q = QUIZ.questions, SUBJ = QUIZ.subjects, TOP = QUIZ.topics;
  var SID = SUBJ.map(function (s) { return s.id; });
  var BY_ID = {}, TI = {};
  Q.forEach(function (q) { BY_ID[q.id] = q; });
  SID.forEach(function (f) { TOP[f].forEach(function (t, i) { TI[t.id] = { f: f, i: i, t: t }; }); });
  function subj(f) { for (var i = 0; i < SUBJ.length; i++) if (SUBJ[i].id === f) return SUBJ[i]; }

  // ---------- Speicher ----------
  var KEY = 'basisjahr-quiz-v1';
  var S = {
    tab: 'unterwegs', subj: 'all', diff: 'mix', lim: {}, stoffOpen: true,
    stats: {}, days: {}, recent: { tap: [], write: [] }, review: false
  };
  SID.forEach(function (f) { S.lim[f] = TOP[f].length - 1; });
  try {
    var raw = localStorage.getItem(KEY);
    if (raw) {
      var saved = JSON.parse(raw);
      for (var k in saved) if (Object.prototype.hasOwnProperty.call(S, k)) S[k] = saved[k];
      SID.forEach(function (f) {
        if (typeof S.lim[f] !== 'number' || S.lim[f] < 0 || S.lim[f] > TOP[f].length - 1) S.lim[f] = TOP[f].length - 1;
      });
      S.review = false;
    }
  } catch (e) { /* ohne Speicher weiter */ }
  function save() {
    try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) { /* ignorieren */ }
  }
  var h = location.hash.replace('#', '');
  if (h === 'unterwegs' || h === 'schreiben' || h === 'fortschritt') S.tab = h;

  // ---------- Hilfen ----------
  function $(id) { return document.getElementById(id); }
  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
  function today() { var d = new Date(); return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
  function shuffle(a) { for (var i = a.length - 1; i > 0; i--) { var j = Math.floor(Math.random() * (i + 1)); var t = a[i]; a[i] = a[j]; a[j] = t; } return a; }
  var DIFF = { 1: 'leicht', 2: 'mittel', 3: 'schwer' };

  // ---------- Mini-Satz für Mathe ----------
  var SYM = {
    R: 'ℝ', N: 'ℕ', Z: 'ℤ', Q: 'ℚ', C: 'ℂ', in: '∈', notin: '∉', cdot: '·', le: '≤', ge: '≥', ne: '≠', to: '→',
    top: '⊤', perp: '⊥', dagger: '†', equiv: '≡', mid: '∣', nmid: '∤', forall: '∀', exists: '∃', neg: '¬', land: '∧', lor: '∨',
    Rightarrow: '⇒', Leftrightarrow: '⇔', lambda: 'λ', mu: 'μ', alpha: 'α', beta: 'β', gamma: 'γ', varphi: 'φ', phi: 'φ', rho: 'ρ', sigma: 'σ',
    theta: 'θ', pi: 'π', sum: '∑', prod: '∏', infty: '∞', times: '×', circ: '∘', emptyset: '∅', subseteq: '⊆', subset: '⊂', supseteq: '⊇',
    cup: '∪', cap: '∩', models: '⊨', ldots: '…', cdots: '⋯', approx: '≈', leftarrow: '⟵', oplus: '⊕', odot: '⊙', preceq: '⪯', prec: '≺',
    Theta: 'Θ', Omega: 'Ω', langle: '⟨', rangle: '⟩', setminus: '∖', sim: '∼', cong: '≅', pm: '±', lfloor: '⌊', rfloor: '⌋', lceil: '⌈', rceil: '⌉',
    epsilon: 'ε', varepsilon: 'ε', ell: 'ℓ', delta: 'δ', Delta: 'Δ', tau: 'τ', psi: 'ψ', omega: 'ω', nabla: '∇', partial: '∂', hat: '', quad: '\u2003',
    mapsto: '↦', iff: '⟺', implies: '⟹', Longrightarrow: '⟹', lVert: '‖', rVert: '‖', bigcup: '⋃', bigcap: '⋂', leq: '≤', geq: '≥', neq: '≠',
    rightarrow: '→', leftrightarrow: '↔', subsetneq: '⊊', dots: '…', big: '', Big: '', bigl: '', bigr: '', left: '', right: ''
  };
  var FUNCS = /^(log|ln|gcd|lcm|deg|cos|sin|max|min|dim|ker|bmod|ord|arccos|rank)$/;
  var CAL = { A: '𝒜', B: 'ℬ', C: '𝒞', D: '𝒟', E: 'ℰ', F: 'ℱ', G: '𝒢', H: 'ℋ', I: 'ℐ', L: 'ℒ', M: 'ℳ', N: '𝒩', O: '𝒪', P: '𝒫', R: 'ℛ', S: '𝒮', T: '𝒯', U: '𝒰', V: '𝒱', W: '𝒲' };
  function mathHtml(s) {
    s = s.replace(/\\not\s*\\equiv/g, '≢').replace(/\\not\s*\\mid/g, '∤').replace(/\\not\s*\\in/g, '∉');
    var i = 0, out = '';
    function grp() {
      while (s[i] === ' ') i++;
      if (s[i] !== '{') { var c = s[i] || ''; i++; return c; }
      var d = 0, st = i + 1;
      for (; i < s.length; i++) {
        if (s[i] === '{') d++;
        else if (s[i] === '}') { d--; if (d === 0) { i++; return s.slice(st, i - 1); } }
      }
      return s.slice(st);
    }
    function splitTop(str, sep) {
      var parts = [], d = 0, cur = '';
      for (var j = 0; j < str.length; j++) {
        var c = str[j];
        if (c === '{') d++; else if (c === '}') d--;
        if (c === sep && d === 0) { parts.push(cur); cur = ''; } else cur += c;
      }
      parts.push(cur);
      return parts;
    }
    while (i < s.length) {
      var c = s[i];
      if (c === '\\') {
        var m = /^\\([a-zA-Z]+)/.exec(s.slice(i));
        if (m) {
          var name = m[1]; i += m[0].length;
          if (FUNCS.test(name)) { out += '<span class="mf">' + (name === 'bmod' ? 'mod' : name) + '</span>'; }
          else if (name === 'mathcal') { var cg = grp(); out += cg.split('').map(function (ch) { return CAL[ch] || esc(ch); }).join(''); }
          else if (name === 'widehat') { out += '<span class="wh">' + mathHtml(grp()) + '</span>'; }
          else if (name === 'frac' || name === 'tfrac') { var a = grp(), b = grp(); out += '<span class="fr"><span>' + mathHtml(a) + '</span><span>' + mathHtml(b) + '</span></span>'; }
          else if (name === 'mat' || name === 'vec') {
            var body = grp(), rows = splitTop(body, ';').map(function (r) { return name === 'vec' ? [r] : splitTop(r, ','); });
            var cols = rows.reduce(function (mx, r) { return Math.max(mx, r.length); }, 1);
            out += '<span class="mx" style="grid-template-columns:repeat(' + cols + ',auto)">';
            rows.forEach(function (r) { for (var k = 0; k < cols; k++) out += '<span>' + mathHtml((r[k] || '').trim()) + '</span>'; });
            out += '</span>';
          }
          else if (name === 'sqrt') { out += '<span class="sq">√<span>' + mathHtml(grp()) + '</span></span>'; }
          else if (name === 'text') { out += '<span class="mt">' + esc(grp()) + '</span>'; }
          else if (name === 'bar' || name === 'overline') { out += '<span style="text-decoration:overline">' + mathHtml(grp()) + '</span>'; }
          else if (name === 'hat') { out += mathHtml(grp()) + '̂'; }
          else if (name === 'mathbb') { out += SYM[grp()] || ''; }
          else if (SYM.hasOwnProperty(name)) out += SYM[name];
          else out += esc('\\' + name);
          continue;
        }
        var nc = s[i + 1] || '';
        out += (nc === ',' || nc === ';' || nc === ':') ? '\u2009' : nc === '!' ? '' : esc(nc); i += 2; continue;
      }
      if (c === '_' || c === '^') {
        i++; var g = grp();
        out += c === '_' ? '<sub>' + mathHtml(g) + '</sub>' : '<sup>' + mathHtml(g) + '</sup>';
        continue;
      }
      out += esc(c); i++;
    }
    return out;
  }
  function inline(t) {
    // Segmente: `code`, $$block$$, $math$, Rest
    var out = '', re = /`([^`]+)`|\$\$([^$]+)\$\$|\$([^$]+)\$/g, last = 0, m;
    while ((m = re.exec(t))) {
      out += plain(t.slice(last, m.index));
      if (m[1] !== undefined) out += '<code>' + esc(m[1]) + '</code>';
      else if (m[2] !== undefined) out += '<span class="m blk">' + mathHtml(m[2]) + '</span>';
      else out += '<span class="m">' + mathHtml(m[3]) + '</span>';
      last = re.lastIndex;
    }
    return out + plain(t.slice(last));
  }
  function plain(t) { return esc(t).replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>'); }
  function fmt(text) {
    if (!text) return '';
    var blocks = [];
    text = String(text).replace(/```(\w*)\n?([\s\S]*?)```|(?:^|\n)`([^`]*\n[^`]*)`(?=\n|$)/g, function (_, lang, a, b) {
      blocks.push('<pre class="code" tabindex="0"><code>' + hl((a !== undefined ? a : b).replace(/\n$/, ''), lang || 'java') + '</code></pre>');
      return '\n\n\u0000' + (blocks.length - 1) + '\u0000\n\n';
    });
    return text.split(/\n\s*\n/).filter(function (p) { return p.trim(); }).map(function (para) {
      var bm = /^\s*\u0000(\d+)\u0000\s*$/.exec(para);
      if (bm) return blocks[+bm[1]];
      var lines = para.split('\n');
      if (lines.every(function (l) { return /^\s*- /.test(l); })) {
        return '<ul>' + lines.map(function (l) { return '<li>' + inline(l.replace(/^\s*- /, '')) + '</li>'; }).join('') + '</ul>';
      }
      return '<p>' + lines.map(inline).join('<br>') + '</p>';
    }).join('');
  }

  // ---------- Java-Hervorhebung ----------
  var KW = /^(public|private|protected|static|final|void|int|long|double|boolean|char|byte|short|float|class|new|return|if|else|for|while|do|null|true|false|this|enum|import|var|break|continue|switch|case|default)$/;
  function hl(code, lang) {
    if (lang === 'plain') return esc(code);
    var re = /(\/\/[^\n]*|\/\*[\s\S]*?\*\/)|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')|(\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?[LlfFdD]?\b)|(\b[A-Za-z_][A-Za-z0-9_]*\b)/g;
    var out = '', last = 0, m;
    while ((m = re.exec(code))) {
      out += esc(code.slice(last, m.index));
      if (m[1]) out += '<span class="tk-c">' + esc(m[1]) + '</span>';
      else if (m[2]) out += '<span class="tk-s">' + esc(m[2]) + '</span>';
      else if (m[3]) out += '<span class="tk-n">' + esc(m[3]) + '</span>';
      else if (KW.test(m[4])) out += '<span class="tk-k">' + m[4] + '</span>';
      else if (/^[A-Z]/.test(m[4])) out += '<span class="tk-t">' + m[4] + '</span>';
      else out += esc(m[4]);
      last = re.lastIndex;
    }
    return out + esc(code.slice(last));
  }
  function codeBlock(q) {
    if (!q.code) return '';
    var lang = q.lang || (q.f === 'ep' ? 'java' : 'plain');
    return '<pre class="code" tabindex="0" aria-label="Code"><code>' + hl(q.code, lang) + '</code></pre>';
  }

  // ---------- Pool und Stapel ----------
  function eligible(q, mode) {
    if ((mode === 'write') !== (q.k === 'w')) return false;
    var ti = TI[q.t]; if (!ti) return false;
    if (S.subj !== 'all' && S.subj !== q.f) return false;
    if (ti.i > S.lim[q.f]) return false;
    if (S.diff !== 'mix' && String(q.d) !== String(S.diff)) return false;
    if (S.review && mode === 'tap') { var st = S.stats[q.id]; if (!st || st.ok) return false; }
    return true;
  }
  function pool(mode) { return Q.filter(function (q) { return eligible(q, mode); }); }
  function prio(q) {
    var st = S.stats[q.id];
    if (!st) return 0 + Math.random() * 0.5;
    return (st.ok ? 2 : 1) + Math.min(st.n, 5) * 0.1 + Math.random() * 0.3;
  }
  var deck = { tap: [], write: [] }, cur = { tap: null, write: null };
  function buildDeck(mode) {
    var p = pool(mode);
    if (!p.length) { deck[mode] = []; return; }
    var recent = S.recent[mode] || [];
    var fresh = p.filter(function (q) { return recent.indexOf(q.id) < 0; });
    if (fresh.length >= Math.min(6, p.length)) p = fresh;
    var N = Math.min(mode === 'tap' ? 20 : 8, p.length);
    var b = { 1: [], 2: [], 3: [] };
    p.forEach(function (q) { b[q.d].push(q); });
    [1, 2, 3].forEach(function (d) { b[d].sort(function (x, y) { return prio(x) - prio(y); }); });
    var want = S.diff === 'mix' ? { 1: Math.round(N / 4), 3: Math.round(N / 4) } : { 1: 0, 3: 0 };
    want[2] = N - want[1] - want[3];
    if (S.diff !== 'mix') { want = { 1: 0, 2: 0, 3: 0 }; want[S.diff] = N; }
    var picked = [];
    [1, 2, 3].forEach(function (d) { picked = picked.concat(b[d].splice(0, want[d])); });
    if (picked.length < N) {
      var rest = b[1].concat(b[2], b[3]).sort(function (x, y) { return prio(x) - prio(y); });
      picked = picked.concat(rest.slice(0, N - picked.length));
    }
    deck[mode] = shuffle(picked).map(function (q) { return q.id; });
  }
  function nextQ(mode) {
    if (!deck[mode].length) buildDeck(mode);
    var id = deck[mode].shift();
    if (!id) { cur[mode] = null; return; }
    var q = BY_ID[id];
    var order = q.o ? q.o.map(function (_, i) { return i; }) : null;
    if (order && !q.fix) shuffle(order);
    cur[mode] = { id: id, order: order, sel: [], tf: {}, done: false, hint: false, sol: false, rate: null, check: null, input: '' };
    var r = S.recent[mode] || (S.recent[mode] = []);
    r.push(id); if (r.length > 12) r.shift();
    save();
  }
  function refreshAfterFilter() {
    ['tap', 'write'].forEach(function (mode) {
      deck[mode] = [];
      var c = cur[mode];
      if (!c || !BY_ID[c.id] || !eligible(BY_ID[c.id], mode) || c.done) nextQ(mode);
    });
  }

  // ---------- Statistik ----------
  function record(q, ok) {
    var st = S.stats[q.id] || (S.stats[q.id] = { n: 0, c: 0 });
    st.n++; if (ok) st.c++; st.ok = !!ok; st.t = Date.now();
    var d = today(); var day = S.days[d] || (S.days[d] = { n: 0, c: 0 });
    day.n++; if (ok) day.c++;
    save(); renderToday();
  }
  function renderToday() {
    var day = S.days[today()] || { n: 0, c: 0 };
    $('today').innerHTML = day.n ? 'Heute <b>' + day.n + '</b> beantwortet<br><b>' + day.c + '</b> richtig' : 'Heute noch<br>nichts beantwortet';
  }

  // ---------- Stoffstand ----------
  var SHORT = { dm: 'DM', la: 'LA', ad: 'AD', ep: 'EP' };
  function stoffSummary() { return SID.map(function (f) { return SHORT[f] + ' ' + TOP[f][S.lim[f]].nr; }).join(' · '); }
  function renderStoff() {
    var el = $('stoff');
    if (S.tab === 'fortschritt') { el.hidden = true; return; }
    el.hidden = false;
    var summary = stoffSummary();
    var html = '<button class="group-h" id="stoff-toggle" aria-expanded="' + S.stoffOpen + '" aria-controls="stoff-list">' +
      '<span style="min-width:0;display:flex;flex-direction:column;gap:2px"><span class="t">Stoffstand</span><span class="s">' + esc(summary) + '</span></span>' +
      '<svg class="chev" viewBox="0 0 14 14" aria-hidden="true"><path d="M5 2l5 5-5 5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></button>';
    html += '<div class="sl-list" id="stoff-list"' + (S.stoffOpen ? '' : ' hidden') + '>';
    SID.forEach(function (f) {
      var tp = TOP[f], v = S.lim[f], n = tp.length;
      html += '<div class="sl" style="--c:var(--' + f + ')">' +
        '<div class="sl-top"><label class="sl-name" for="rng-' + f + '"><span class="dot"></span>' + subj(f).name + '</label>' +
        '<span class="sl-val" id="val-' + f + '">bis <b>' + esc(tp[v].nr) + '</b> ' + esc(tp[v].name) + '</span></div>' +
        '<input class="range" type="range" id="rng-' + f + '" data-f="' + f + '" min="0" max="' + (n - 1) + '" step="1" value="' + v + '" style="--p:' + (n > 1 ? v / (n - 1) * 100 : 100) + '%" aria-valuetext="bis ' + esc(tp[v].nr + ' ' + tp[v].name) + '"></div>';
    });
    html += '<div class="sl-foot">Fragen kommen aus allen Themen bis zum eingestellten Thema.</div></div>';
    el.innerHTML = html;
    $('stoff-toggle').onclick = function () { S.stoffOpen = !S.stoffOpen; save(); renderStoff(); };
    SID.forEach(function (f) {
      var r = $('rng-' + f);
      r.oninput = function () {
        var v = +r.value, tp = TOP[f];
        S.lim[f] = v;
        r.style.setProperty('--p', (tp.length > 1 ? v / (tp.length - 1) * 100 : 100) + '%');
        r.setAttribute('aria-valuetext', 'bis ' + tp[v].nr + ' ' + tp[v].name);
        $('val-' + f).innerHTML = 'bis <b>' + esc(tp[v].nr) + '</b> ' + esc(tp[v].name);
        el.querySelector('.group-h .s').textContent = stoffSummary();
      };
      r.onchange = function () { save(); refreshAfterFilter(); renderPick(); renderMain(); };
    });
  }

  // ---------- Auswahl ----------
  function renderPick() {
    var el = $('pick');
    if (S.tab === 'fortschritt') { el.hidden = true; return; }
    el.hidden = false;
    var mode = S.tab === 'schreiben' ? 'write' : 'tap';
    var html = '<div class="chips" role="group" aria-label="Fach">';
    html += '<button class="chip" data-s="all" aria-pressed="' + (S.subj === 'all') + '">Alle</button>';
    SUBJ.forEach(function (s) {
      html += '<button class="chip" data-s="' + s.id + '" aria-pressed="' + (S.subj === s.id) + '" style="--c:var(--' + s.id + ')"><span class="dot"></span>' + s.name + '</button>';
    });
    html += '</div><div class="seg" role="group" aria-label="Schwierigkeit">';
    [['mix', 'Mix'], ['1', 'Leicht'], ['2', 'Mittel'], ['3', 'Schwer']].forEach(function (d) {
      html += '<button data-d="' + d[0] + '" aria-pressed="' + (String(S.diff) === d[0]) + '">' + d[1] + '</button>';
    });
    var n = pool(mode).length;
    html += '</div><p class="mixnote">' + (S.review && mode === 'tap' ? '<b>Fehler wiederholen:</b> nur zuletzt falsch beantwortete Fragen. ' : '') +
      n + (mode === 'tap' ? ' Fragen' : ' Aufgaben') + ' in der Auswahl' + (S.diff === 'mix' ? ' · jede Runde ¼ leicht, ½ mittel, ¼ schwer' : '') + '</p>';
    el.innerHTML = html;
    el.querySelectorAll('.chip').forEach(function (b) {
      b.onclick = function () { S.subj = b.getAttribute('data-s'); save(); refreshAfterFilter(); renderPick(); renderMain(); };
    });
    el.querySelectorAll('.seg button').forEach(function (b) {
      b.onclick = function () { var d = b.getAttribute('data-d'); S.diff = d === 'mix' ? 'mix' : +d; save(); refreshAfterFilter(); renderPick(); renderMain(); };
    });
  }

  // ---------- Kartenkopf ----------
  function metaHtml(q, extra) {
    var ti = TI[q.t], pips = '';
    for (var i = 1; i <= 3; i++) pips += '<i' + (i <= q.d ? ' class="on"' : '') + '></i>';
    return '<div class="meta"><span class="badge" style="--c:var(--' + q.f + ')"><span class="dot"></span>' + subj(q.f).name + '</span>' +
      '<span class="sep">·</span><span>' + esc(ti.t.nr + ' ' + ti.t.name) + '</span>' + (extra || '') +
      '<span class="diff"><span class="pips" aria-hidden="true">' + pips + '</span>' + DIFF[q.d] + '</span></div>';
  }
  function emptyHtml(mode) {
    if (S.review && mode === 'tap') {
      return '<div class="qcard empty"><h2>Keine offenen Fehler</h2><p>In dieser Auswahl hast du alle zuletzt falschen Fragen richtig beantwortet.</p><div class="actions" style="justify-content:center"><button class="btn btn-sec" id="end-review">Zurück zum normalen Mix</button></div></div>';
    }
    return '<div class="qcard empty"><h2>Keine ' + (mode === 'tap' ? 'Fragen' : 'Aufgaben') + ' in dieser Auswahl</h2><p>Schieb einen Regler weiter nach rechts, wähle ein anderes Fach oder stell die Schwierigkeit auf Mix.</p></div>';
  }

  // ---------- Unterwegs ----------
  function renderTap() {
    var c = cur.tap, main = $('main');
    if (!c) { main.innerHTML = emptyHtml('tap'); bindEnd(); return; }
    var q = BY_ID[c.id];
    var kindLabel = q.k === 'mc' ? '<span class="kind">Mehrfachauswahl</span>' : q.k === 'tf' ? '<span class="kind">Jede Zeile</span>' : '';
    var html = '<article class="qcard fade-in" data-q="' + q.id + '" aria-labelledby="qt">' + metaHtml(q, kindLabel ? '<span class="sep">·</span>' + kindLabel : '') +
      '<div class="qtext rich" id="qt">' + fmt(q.q) + '</div>' + codeBlock(q);
    if (q.k === 'sc' || q.k === 'mc') {
      html += '<div class="opts" role="group" aria-label="Antworten">';
      c.order.forEach(function (oi, pos) {
        var cls = 'opt' + (q.k === 'mc' ? ' multi' : ''), isRight = q.k === 'sc' ? oi === q.a : q.a.indexOf(oi) >= 0, chosen = c.sel.indexOf(oi) >= 0;
        var why = '';
        if (c.done) {
          if (isRight) cls += ' right';
          else if (chosen) cls += ' wrong';
          else cls += ' dim';
          if (q.w && q.w[oi] !== undefined && (chosen || isRight || q.k === 'mc')) why = '<span class="why">' + inline(q.w[oi]) + '</span>';
        }
        var label = String.fromCharCode(65 + pos);
        var mark = c.done ? (isRight ? '✓' : chosen ? '✗' : label) : label;
        html += '<button class="' + cls + '" data-oi="' + oi + '" aria-pressed="' + chosen + '"' + (c.done ? ' disabled' : '') + '>' +
          '<span class="key" aria-hidden="true">' + mark + '</span><span class="ot"><span class="sr">' + label + ': </span>' + inline(q.o[oi]) +
          (c.done ? '<span class="sr">' + (isRight ? ' (richtig)' : chosen ? ' (deine Wahl, falsch)' : '') + '</span>' : '') + why + '</span></button>';
      });
      html += '</div>';
    } else if (q.k === 'tf') {
      html += '<div class="tf">';
      q.rows.forEach(function (r, ri) {
        var v = c.tf[ri], cls = 'tf-row';
        if (c.done) cls += v === r[1] ? ' right' : ' wrong';
        html += '<div class="' + cls + '"><div class="st">' + inline(r[0]) + '</div><div class="tf-btns" role="group" aria-label="Aussage ' + (ri + 1) + '">' +
          ['wahr', 'falsch'].map(function (lab, bi) {
            var val = bi === 0, pressed = v === val;
            var solCls = c.done && r[1] === val ? ' class="sol"' : '';
            return '<button data-ri="' + ri + '" data-v="' + val + '" aria-pressed="' + pressed + '"' + solCls + (c.done ? ' disabled' : '') + '>' + lab + '</button>';
          }).join('') + '</div>' +
          (c.done ? '<div class="why">' + (v === r[1] ? '✓ ' : '✗ ') + '<b>' + (r[1] ? 'wahr' : 'falsch') + '.</b> ' + inline(r[2] || '') + '</div>' : '') + '</div>';
      });
      html += '</div>';
    }
    if (!c.done) {
      html += '<div class="actions">';
      if (q.k !== 'sc') {
        var ready = q.k === 'mc' ? c.sel.length > 0 : Object.keys(c.tf).length === q.rows.length;
        html += '<button class="btn btn-pri" id="check"' + (ready ? '' : ' disabled') + '>Antwort prüfen</button>';
      }
      html += '<button class="btn btn-plain" id="dunno">Weiss ich nicht, zeig es mir</button></div>';
    } else {
      var ok = c.ok;
      html += '<div class="verdict ' + (ok ? 'ok' : 'no') + '" role="status"><div class="vh">' + (ok ? '✓ Richtig' : c.dunno ? 'Lösung' : '✗ Nicht ganz') + '</div>' +
        (q.e ? '<div class="rich">' + fmt(q.e) + '</div>' : '') + '</div>';
      if (q.m) html += '<div class="merke"><b>Merke:</b> ' + inline(q.m) + '</div>';
      if (q.s) html += '<div class="src">Quelle: ' + esc(q.s) + '</div>';
      html += '<div class="actions"><button class="btn btn-pri" id="next">Weiter</button></div>';
    }
    html += '</article>';
    if (S.review) html = '<div class="verdict neutral" style="flex-direction:row;align-items:center;justify-content:space-between;flex-wrap:wrap"><span><b>Fehler wiederholen</b></span><button class="btn btn-plain" id="end-review">Beenden</button></div>' + html;
    main.innerHTML = html;
    bindEnd();
    main.querySelectorAll('.opt').forEach(function (b) {
      b.onclick = function () {
        var oi = +b.getAttribute('data-oi');
        if (q.k === 'sc') { c.sel = [oi]; finishTap(q, c, oi === q.a); }
        else { var p = c.sel.indexOf(oi); if (p >= 0) c.sel.splice(p, 1); else c.sel.push(oi); renderTap(); focusSel('[data-oi="' + oi + '"]'); }
      };
    });
    main.querySelectorAll('.tf-btns button').forEach(function (b) {
      b.onclick = function () { c.tf[+b.getAttribute('data-ri')] = b.getAttribute('data-v') === 'true'; renderTap(); focusSel('[data-ri="' + b.getAttribute('data-ri') + '"][data-v="' + b.getAttribute('data-v') + '"]'); };
    });
    if ($('check')) $('check').onclick = function () {
      var ok;
      if (q.k === 'mc') ok = c.sel.length === q.a.length && q.a.every(function (x) { return c.sel.indexOf(x) >= 0; });
      else ok = q.rows.every(function (r, ri) { return c.tf[ri] === r[1]; });
      finishTap(q, c, ok);
    };
    if ($('dunno')) $('dunno').onclick = function () { c.dunno = true; finishTap(q, c, false); };
    if ($('next')) $('next').onclick = function () { nextQ('tap'); renderTap(); window.scrollTo({ top: $('main').offsetTop - 80, behavior: 'smooth' }); focusSel('.qtext'); };
  }
  function focusSel(sel) { var e = $('main').querySelector(sel); if (e) { if (!e.hasAttribute('tabindex') && !/BUTTON|INPUT/.test(e.tagName)) e.setAttribute('tabindex', '-1'); e.focus({ preventScroll: true }); } }
  function finishTap(q, c, ok) {
    c.done = true; c.ok = ok; record(q, ok); renderPick(); renderTap();
    var v = $('main').querySelector('.verdict:not(.neutral)');
    if (v) { var r = v.getBoundingClientRect(); if (r.top > window.innerHeight - 140 || r.top < 0) window.scrollBy({ top: r.top - window.innerHeight * 0.35, behavior: 'smooth' }); }
    focusSel('#next');
  }
  function bindEnd() {
    var e = $('end-review');
    if (e) e.onclick = function () { S.review = false; save(); refreshAfterFilter(); renderPick(); renderMain(); };
  }

  // ---------- Schreiben ----------
  function parseNum(s) {
    s = String(s).trim().replace(/−/g, '-').replace(/\s+/g, '');
    if (!s) return NaN;
    var m = /^([-+]?\d+(?:[.,]\d+)?)\/([-+]?\d+(?:[.,]\d+)?)$/.exec(s);
    if (m) return parseFloat(m[1].replace(',', '.')) / parseFloat(m[2].replace(',', '.'));
    if (/^[-+]?(\d+([.,]\d*)?|[.,]\d+)(e[-+]?\d+)?$/i.test(s)) return parseFloat(s.replace(',', '.'));
    return NaN;
  }
  function nums(s) {
    var out = [], re = /[-+−]?\d+(?:[.,]\d+)?(?:\/[-+]?\d+(?:[.,]\d+)?)?/g, m;
    s = String(s).replace(/−/g, '-');
    while ((m = re.exec(s))) out.push(parseNum(m[0]));
    return out;
  }
  function near(a, b) { return Math.abs(a - b) <= 1e-6 * Math.max(1, Math.abs(b)); }
  function norm(s) { return String(s).toLowerCase().replace(/−/g, '-').replace(/[\s"'`]/g, '').replace(/[·*]/g, '*'); }
  function checkAns(a, input) {
    if (!String(input).trim()) return null;
    if (a.k === 'num') { var x = parseNum(input); return !isNaN(x) && [].concat(a.v).some(function (v) { return near(x, v); }); }
    if (a.k === 'vec' || a.k === 'set') {
      var xs = nums(input), vs = a.v.slice();
      if (xs.length !== vs.length) return false;
      if (a.k === 'set') { xs.sort(function (p, r) { return p - r; }); vs.sort(function (p, r) { return p - r; }); }
      return xs.every(function (x, i) { return near(x, vs[i]); });
    }
    return [].concat(a.v).some(function (v) { return norm(v) === norm(input); });
  }
  function renderWrite() {
    var c = cur.write, main = $('main');
    if (!c) { main.innerHTML = emptyHtml('write'); return; }
    var q = BY_ID[c.id];
    var html = '<article class="qcard paper fade-in" data-q="' + q.id + '" aria-labelledby="wt">' + metaHtml(q) +
      '<div class="task-label">Aufgabe</div><div class="qtext rich" id="wt">' + fmt(q.q) + '</div>' + codeBlock(q);
    if (q.hint) {
      html += c.hint ? '<div class="hint rich"><b>Tipp:</b> ' + fmt(q.hint) + '</div>' : '<div class="actions"><button class="btn btn-plain" id="show-hint">Tipp anzeigen</button></div>';
    }
    if (q.ans) {
      var st = c.check === true ? '<div class="verdict ok" role="status"><div class="vh">✓ Stimmt</div></div>' :
        c.check === false ? '<div class="verdict no" role="status"><div class="vh">✗ Stimmt noch nicht</div><div>Prüf deine Rechnung oder deck die Lösung auf.</div></div>' : '';
      html += '<form class="ansrow" id="ansform" autocomplete="off"><label for="ans">Dein Ergebnis</label>' +
        '<input class="field" id="ans" ' + (q.ans.k === 'num' ? 'inputmode="decimal" ' : '') + 'value="' + esc(c.input) + '" placeholder="' + esc(q.ans.ph || (q.ans.k === 'num' ? 'Zahl, z. B. 3/4 oder 0.75' : q.ans.k === 'vec' ? 'z. B. (1, -2, 3)' : 'Antwort')) + '">' +
        '<button class="btn btn-sec" type="submit">Prüfen</button>' + (q.ans.note ? '<div class="anshint">' + inline(q.ans.note) + '</div>' : '') + '</form>' + st;
    }
    if (!c.sol) {
      html += '<div class="actions"><button class="btn btn-pri" id="show-sol">Lösung zeigen</button><button class="btn btn-plain" id="skip">Überspringen</button></div>';
    } else {
      html += '<div class="task-label">Lösung</div><ol class="steps">' + q.sol.map(function (s) { return '<li><div class="rich">' + fmt(s) + '</div></li>'; }).join('') + '</ol>';
      if (q.res) html += '<div class="result rich">' + fmt(q.res) + '</div>';
      if (q.m) html += '<div class="merke"><b>Merke:</b> ' + inline(q.m) + '</div>';
      if (q.s) html += '<div class="src">Quelle: ' + esc(q.s) + '</div>';
      html += '<div class="task-label">Wie lief es?</div><div class="selfrate" role="group" aria-label="Selbsteinschätzung">' +
        [['ok', 'Gelöst'], ['part', 'Teilweise'], ['no', 'Nicht gelöst']].map(function (r) {
          return '<button data-r="' + r[0] + '" aria-pressed="' + (c.rate === r[0]) + '">' + r[1] + '</button>';
        }).join('') + '</div>';
      html += '<div class="actions"><button class="btn btn-pri" id="wnext"' + (c.rate ? '' : ' disabled') + '>Nächste Aufgabe</button></div>';
    }
    html += '</article>';
    main.innerHTML = html;
    if ($('show-hint')) $('show-hint').onclick = function () { c.hint = true; renderWrite(); };
    if ($('ansform')) {
      $('ans').oninput = function () { c.input = $('ans').value; };
      $('ansform').onsubmit = function (e) { e.preventDefault(); c.input = $('ans').value; c.check = checkAns(q.ans, c.input); renderWrite(); focusSel('#ans'); };
    }
    if ($('show-sol')) $('show-sol').onclick = function () { c.sol = true; if (c.check === true && !c.rate) c.rate = 'ok'; renderWrite(); focusSel('.steps'); };
    if ($('skip')) $('skip').onclick = function () { nextQ('write'); renderWrite(); focusSel('.qtext'); };
    main.querySelectorAll('.selfrate button').forEach(function (b) {
      b.onclick = function () { c.rate = b.getAttribute('data-r'); renderWrite(); focusSel('[data-r="' + c.rate + '"]'); };
    });
    if ($('wnext')) $('wnext').onclick = function () {
      record(q, c.rate === 'ok'); nextQ('write'); renderPick(); renderWrite();
      window.scrollTo({ top: $('main').offsetTop - 80, behavior: 'smooth' }); focusSel('.qtext');
    };
  }

  // ---------- Fortschritt ----------
  var confirmReset = false;
  function renderStats() {
    var main = $('main'), html = '';
    var tapN = 0, tapOk = 0, wN = 0, wOk = 0;
    Q.forEach(function (q) { var st = S.stats[q.id]; if (!st) return; if (q.k === 'w') { wN++; if (st.ok) wOk++; } else { tapN++; if (st.ok) tapOk++; } });
    var wrongOpen = Q.filter(function (q) { var st = S.stats[q.id]; return q.k !== 'w' && st && !st.ok; }).length;
    html += '<section class="group"><div class="about">' +
      '<div><b>' + tapOk + '</b> von ' + Q.filter(function (q) { return q.k !== 'w'; }).length + ' Tippfragen zuletzt richtig · <b>' + wOk + '</b> von ' + Q.filter(function (q) { return q.k === 'w'; }).length + ' Schreibaufgaben gelöst</div>' +
      '<div class="actions"><button class="btn btn-pri" id="review"' + (wrongOpen ? '' : ' disabled') + '>' + (wrongOpen ? wrongOpen + ' Fehler wiederholen' : 'Keine offenen Fehler') + '</button></div></div></section>';
    SUBJ.forEach(function (s) {
      var f = s.id, all = Q.filter(function (q) { return q.f === f; });
      var good = all.filter(function (q) { var st = S.stats[q.id]; return st && st.ok; }).length;
      html += '<section class="group" style="--c:var(--' + f + ')"><div class="stat-h"><h2><span class="dot"></span>' + s.long + '</h2><span class="big">' + good + ' / ' + all.length + '</span></div>';
      TOP[f].forEach(function (t, i) {
        var tq = all.filter(function (q) { return q.t === t.id; });
        var g = tq.filter(function (q) { var st = S.stats[q.id]; return st && st.ok; }).length;
        var pct = tq.length ? Math.round(g / tq.length * 100) : 0;
        html += '<div class="trow' + (i > S.lim[f] ? ' off' : '') + '"><span class="tn"><small>' + esc(t.nr) + '</small>' + esc(t.name) + '</span>' +
          '<span class="bar" role="img" aria-label="' + pct + ' Prozent gekonnt"><i style="width:' + pct + '%"></i></span><span class="num">' + g + '/' + tq.length + '</span></div>';
      });
      html += '</section>';
    });
    html += '<section class="group"><div class="about"><div><b>So funktioniert es.</b> Unterwegs gibt es kurze Tippfragen: eine Antwort, mehrere Antworten oder „wahr/falsch“ pro Zeile. Im Schreib-Modus rechnest oder beweist du auf Papier, tippst das Ergebnis zur Kontrolle ein und vergleichst mit der Musterlösung.</div>' +
      '<div>Jede Runde mischt etwa ¼ leichte, ½ mittlere und ¼ schwere Fragen. Neue und zuletzt falsche Fragen kommen zuerst.</div>' +
      '<div>Dein Fortschritt bleibt nur in diesem Browser auf diesem Gerät gespeichert.</div></div>' +
      (confirmReset ? '<div class="confirm"><span>Gesamten Fortschritt löschen?</span><button class="btn btn-danger" id="reset-yes">Löschen</button><button class="btn btn-plain" id="reset-no">Abbrechen</button></div>'
        : '<div class="confirm"><button class="btn btn-plain" id="reset" style="color:var(--no)">Fortschritt löschen</button></div>') + '</section>';
    main.innerHTML = html;
    $('review').onclick = function () { S.review = true; S.tab = 'unterwegs'; save(); refreshAfterFilter(); route(); };
    if ($('reset')) $('reset').onclick = function () { confirmReset = true; renderStats(); focusSel('#reset-yes'); };
    if ($('reset-no')) $('reset-no').onclick = function () { confirmReset = false; renderStats(); };
    if ($('reset-yes')) $('reset-yes').onclick = function () { S.stats = {}; S.days = {}; S.recent = { tap: [], write: [] }; confirmReset = false; save(); renderToday(); renderStats(); };
  }

  // ---------- Navigation ----------
  var TITLES = {
    unterwegs: ['Unterwegs', 'Kurze Tippfragen. Antippen, lesen, weiter.'],
    schreiben: ['Schreiben', 'Mit Stift und Papier lösen, dann vergleichen.'],
    fortschritt: ['Fortschritt', 'Was sitzt und was noch nicht.']
  };
  function renderMain() {
    if (S.tab === 'unterwegs') renderTap();
    else if (S.tab === 'schreiben') renderWrite();
    else renderStats();
  }
  function route() {
    $('title').textContent = TITLES[S.tab][0];
    $('subtitle').textContent = TITLES[S.tab][1];
    document.querySelectorAll('.tab').forEach(function (t) { t.setAttribute('aria-selected', String(t.getAttribute('data-tab') === S.tab)); });
    if (location.hash !== '#' + S.tab) { try { history.replaceState(null, '', '#' + S.tab); } catch (e) { /* egal */ } }
    renderStoff(); renderPick(); renderMain();
  }
  document.querySelectorAll('.tab').forEach(function (t) {
    t.onclick = function () { S.tab = t.getAttribute('data-tab'); confirmReset = false; save(); route(); window.scrollTo({ top: 0 }); };
  });
  window.addEventListener('hashchange', function () {
    var h = location.hash.replace('#', '');
    if (TITLES[h] && h !== S.tab) { S.tab = h; save(); route(); }
  });
  document.addEventListener('keydown', function (e) {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    var tag = (e.target && e.target.tagName) || '';
    if (tag === 'INPUT' || tag === 'TEXTAREA') return;
    if (S.tab !== 'unterwegs' || !cur.tap) return;
    var c = cur.tap, q = BY_ID[c.id];
    if (!c.done && (q.k === 'sc' || q.k === 'mc')) {
      var k = e.key.toLowerCase(), idx = '1234567'.indexOf(k); if (idx < 0) idx = 'abcdefg'.indexOf(k);
      if (idx >= 0 && idx < c.order.length) { e.preventDefault(); var b = $('main').querySelector('[data-oi="' + c.order[idx] + '"]'); if (b) b.click(); return; }
    }
    if (e.key === 'Enter' && c.done && tag !== 'BUTTON') { e.preventDefault(); $('next') && $('next').click(); }
  });

  nextQ('tap'); nextQ('write');
  renderToday();
  route();
})();
