import json, sys

for line in sys.stdin:
    r = json.loads(line)
    print(r["name"], r["engine"], "PDF" if r["pdf"] else "NOPDF",
          ("ERR " + str(r["errors"][:1])) if r["errors"] else "",
          "TEXT-OK" if r["text_ok"] else "TEXT-BAD " + str(r["missing_words"]),
          r["missing"][:1], r["fontwarn"][:2],
          " ".join(f.split("+")[-1] for f in r["fonts"]))
