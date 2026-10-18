#!/usr/bin/env python3
"""check_comments.py: checks the comment layout rules in CONTRIBUTING.md on the assembly sources.

  python3 tools/check_comments.py [--quiet] [paths...]    (default: every .asm/.inc/.mac under src/)

Rules checked (tab = 4 columns):
  - no comment line is wider than 110 columns
  - a trailing comment starts at column 36, or one tab after the code when the code reaches past column 36
  - no paragraph of a header-style comment block (lines starting ';<tab>', split by a ';'-only line) is longer
    than 3 lines; legends and tables written as ';text' are not checked
  - no doubled comment marker such as ';<tab>;' at the start of a line
Exit status 1 when anything is reported, so it can be used before a commit.
"""
import re, sys, os, glob

WIDTH, COL, MAXPARA = 110, 36, 3

def vis(s):
    c = 0
    for ch in s:
        c = (c // 4 + 1) * 4 if ch == '\t' else c + 1
    return c

def split(line):
    """Return (code, comment) with comment starting at the first ';' outside a string."""
    q = None
    for i, ch in enumerate(line):
        if q:
            if ch == q:
                q = None
        elif ch in "'\"":
            q = ch
        elif ch == ';':
            return line[:i], line[i:]
    return line, None

BANNER = re.compile(r'^;[>=<\-*]{3}')

def check(path):
    out = []
    lines = open(path, encoding='latin-1').read().split('\n')
    for n, l in enumerate(lines, 1):
        code, cm = split(l)
        if cm is None:
            continue
        if vis(l) > WIDTH and not code.strip().lower().startswith(('dc.', 'db ', 'dw ', 'dl ')):
            out.append((n, f'line is {vis(l)} columns wide (max {WIDTH})'))
        if code.strip():
            w = vis(code.rstrip())
            pos = vis(code)
            ok = (w < COL and pos == COL) or (w >= COL and 0 < pos - w <= 4)
            if not ok:
                out.append((n, f'trailing comment at column {pos} (expected {COL}, or one tab past code that is {w} wide)'))
        elif re.match(r'^;[ \t]+;', l):
            out.append((n, 'doubled comment marker'))
    i = 0
    while i < len(lines):
        if lines[i].startswith(';\t') and not BANNER.match(lines[i]):
            j = i
            while j < len(lines) and lines[j].startswith(';') and not BANNER.match(lines[j]):
                j += 1
            para = start = 0
            for k in range(i, j + 1):
                blank = k == j or re.match(r'^;\s*$', lines[k])
                if blank:
                    if para > MAXPARA:
                        out.append((start + 1, f'comment paragraph of {para} lines (max {MAXPARA})'))
                    para = 0
                else:
                    if para == 0:
                        start = k
                    para += 1
            i = j
        else:
            i += 1
    return out

def main(argv):
    quiet = '--quiet' in argv
    paths = [a for a in argv if not a.startswith('--')]
    if not paths:
        paths = [f for f in glob.glob('src/**/*', recursive=True)
                 if f.lower().endswith(('.asm', '.inc', '.mac')) and os.path.isfile(f)]
    total = 0
    for p in sorted(paths):
        for n, msg in check(p):
            total += 1
            if not quiet:
                print(f'{p}:{n}: {msg}')
    print(f'{total} comment layout problem(s)' if total else 'comment layout OK')
    return 1 if total else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
