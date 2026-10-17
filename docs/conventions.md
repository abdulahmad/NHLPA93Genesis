# Conventions

How names, comments and commits are kept in this repo. The rule for every change: code, data and bytes do not change, so every build must still MATCH the retail and Rev A ROMs (`tools/verify_all.sh`).

## Naming lineage
- 92G (abdulahmad/NHL92Genesis, EA source) is the root. 93 -> 92; 94 -> 93 -> 92; 95 -> 94 -> 93 -> 92.
- Use the earliest game's name for the same routine/variable. 92 names are kept as-is, typos included.
- A name not from 92 that is inaccurate (checked against the routine body / usage) gets fixed, and the fix is propagated
  forward: 93 -> 94 -> 95, and to abdulahmad/NHLPA93SNES for 93 names that exist there.
- Clash rule: never reuse a name already used for a different item; pick a descriptive name instead.
- Teams: 93 (unlicensed) uses city names only; 94/95 use NYIslanders/NYRangers (NYI/NYR) style names.

## Comment rules
No other games' names or "X name" notes, no source-file/segment names, no IDA references (IDA, loc_, sub_, unk_),
no "(was: X)" history, no hardcoded ROM addresses (keep VRAM/RAM values, include address maps, RAM equate address
comments), no "only in 9x" tags ("New in 94/95:" allowed in file/section headers). Keep real explanations and
value-difference notes like "(94 $58)" / "92 used bit 6". Every routine has a header comment. Concise.

## Local label style
Follow 92G (EA source): 2105 locals, ~31% number-only (.0, .1 ...), the rest short lowercase words
(.loop, .next, .top, .done, .ex/.exit, .ok, .wait, .skip, plus abbreviations like .nna, .nodec, .sr).
- Give a word where the branch has a clear meaning (loop top, next item, skip/no-X case, exit, wait).
- Keep plain numbers for trivial jumps and for locals inherited from a matching parent routine.
- A routine that matches a parent routine uses the parent's local names.
- Data tables indexed by number (frames .0 .1 ..., team .0) stay numeric, as in 92.
- Renames are scope-aware (only between the routine's global label and the next one, code part
  only, never comments); every commit is diff-reviewed.

## Records
- `docs/history/name_map.csv`: every rename (old, new, source or reason). History lives there, not in comments.
- `docs/history/name_review_93.md`: the name-accuracy checklist (name, verdict) per module.

## Commits
Small commits per module; the build MATCHes before every push. Never commit ROMs, `Extracted/` or `output/`.
