import os, subprocess, sys, shutil

# Kleiner Test: Präambel-Zeilen + ein bestimmter Körper, zeigt die eingebetteten Schriften.
EMPTY_FC = "/tmp/ff-fontmatrix/empty-fonts.conf"
lines = sys.argv[1].split("\\n") if sys.argv[1] else []
body = sys.argv[2]
engine = sys.argv[3]
d = "/tmp/ff-fontmatrix/probe-" + engine
shutil.rmtree(d, ignore_errors=True)
os.makedirs(d)
src = ("\\documentclass[a4paper,11pt]{article}\n\\usepackage[ngerman]{babel}\n\\usepackage{amsmath,amssymb,amsthm}\n"
       + "\n".join(lines) + "\n\\begin{document}\n" + body + "\n\\end{document}\n")
open(os.path.join(d, "t.tex"), "w").write(src)
env = dict(os.environ)
if engine == "xelatex":
    env["FONTCONFIG_FILE"] = EMPTY_FC
subprocess.run([engine, "-interaction=nonstopmode", "-halt-on-error", "t.tex"], cwd=d, env=env, capture_output=True)
log = open(os.path.join(d, "t.log"), errors="replace").read()
for l in log.splitlines():
    if l.startswith("!") or "Font Warning" in l or "Missing character" in l or "undefined" in l:
        print("LOG:", l)
print(subprocess.run(["pdffonts", os.path.join(d, "t.pdf")], capture_output=True, text=True).stdout)
