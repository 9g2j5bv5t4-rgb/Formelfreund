import json, os, re, subprocess, sys, shutil

ROOT = "/tmp/ff-fontmatrix/runs"
EMPTY_FC = "/tmp/ff-fontmatrix/empty-fonts.conf"
with open(EMPTY_FC, "w") as f:
    f.write('<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "fonts.dtd">\n<fontconfig><cachedir>/tmp/ff-fontmatrix/fccache</cachedir></fontconfig>\n')

HEAD = r"""\documentclass[a4paper,11pt]{article}
\usepackage[ngerman]{babel}
\usepackage{amsmath,amssymb,amsthm}
"""
BODY = r"""
\begin{document}
\section{Äpfel und Übungen}
Größe ähnlich Öl. Straße, Füße, ÄÖÜ äöü ß. \textbf{Fett Größe} \emph{Kursiv Größe}.
\parbox{1cm}{Donaudampfschifffahrtsgesellschaftskapitänsmützenabzeichen Übungsaufgabenlösungsvorschläge}

Formel $\int_0^1 x^2\,dx = \frac13$ und
\[ \sum_{k=1}^n k = \frac{n(n+1)}{2} \]
\end{document}
"""

def run(name, lines, engine):
    d = os.path.join(ROOT, f"{name}-{engine}")
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    if name.endswith("@late"):
        # Pakete erst NACH den Schrift-Zeilen laden (wie es ensure() später tun könnte).
        src = (HEAD.replace("\\usepackage{amsmath,amssymb,amsthm}\n", "") + "\n".join(lines) + "\n"
               + "\\usepackage{amsmath}\n\\usepackage{amssymb}\n\\usepackage{amsthm}\n\\usepackage{xcolor}\n"
               + "\\usepackage{graphicx}\n\\usepackage{booktabs}\n\\usepackage{listings}\n\\usepackage{hyperref}\n"
               + "\\usepackage[margin=2cm]{geometry}\n\\usepackage[onehalfspacing]{setspace}\n" + BODY)
    elif name.endswith("@legacy"):
        # Typische Vorlage aus dem Netz: inputenc und T1 schon von Hand geladen.
        src = (HEAD + "\\usepackage[utf8]{inputenc}\n\\usepackage[T1]{fontenc}\n\\usepackage{hyperref}\n"
               + "\n".join(lines) + "\n" + BODY)
    else:
        src = HEAD + "\n".join(lines) + "\n" + BODY
    with open(os.path.join(d, "t.tex"), "w") as f:
        f.write(src)
    env = dict(os.environ)
    if engine == "xelatex" and os.environ.get("FF_SYSTEM_FONTS") != "1":
        env["FONTCONFIG_FILE"] = EMPTY_FC
    subprocess.run([engine, "-interaction=nonstopmode", "-halt-on-error", "t.tex"], cwd=d, env=env,
                   capture_output=True, text=True, errors="replace", timeout=300)
    logpath = os.path.join(d, "t.log")
    log = open(logpath, errors="replace").read() if os.path.exists(logpath) else ""
    errors = [l for l in log.splitlines() if l.startswith("!")]
    missing = sorted(set(l.strip() for l in log.splitlines() if "Missing character" in l))
    fontwarn = sorted(set(l.strip() for l in log.splitlines()
                          if re.search(r"Font shape .* (undefined|not available)|Some font shapes were not available", l)))
    pdf = os.path.join(d, "t.pdf")
    text = ""
    fonts = ""
    if os.path.exists(pdf):
        text = subprocess.run(["pdftotext", "-enc", "UTF-8", pdf, "-"], capture_output=True, text=True).stdout
        fonts = subprocess.run(["pdffonts", pdf], capture_output=True, text=True).stdout
    fontnames = [l.split()[0] for l in fonts.splitlines()[2:] if l.strip()]
    words = ["Größe", "Äpfel", "Übungen", "ähnlich", "Öl", "Straße"]
    ok_text = all(w in text for w in words)
    # Silbentrennung im schmalen Kasten: steht ein getrenntes Wortstück mit Umlaut da?
    hyph_lines = [l for l in text.splitlines() if l.endswith("-")]
    return dict(name=name, engine=engine, pdf=os.path.exists(pdf), errors=errors[:3], missing=missing[:3],
                fontwarn=fontwarn[:4], text_ok=ok_text, missing_words=[w for w in words if w not in text],
                fonts=fontnames, hyphenated=hyph_lines[:6])

CANDS = json.load(open(sys.argv[1]))
only = sys.argv[2:]
for name, lines in CANDS.items():
    if only and name not in only:
        continue
    for engine in ["pdflatex", "xelatex"]:
        r = run(name, lines, engine)
        print(json.dumps(r, ensure_ascii=False))
        sys.stdout.flush()
