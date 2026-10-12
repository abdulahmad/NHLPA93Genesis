# HANDOFF: comment and name cleanup (NHLPA93)

## Purpose
Make this bit-perfect 68000 SNASM disassembly read like clean original source: accurate names that follow the
NHL92 Genesis (EA original) lineage, and comments without disassembler or porting artifacts. Code, data and
bytes never change: every build must still MATCH the retail ROM.

## Setup
ROMs (gitignored, never commit): nhlpa93retail.bin and nhlpa93retailRevA.bin in the repo root.
Windows: `npm run build:retail` and `npm run build:reva` (extractassets, build93.bat, fixopcodes, verify);
segments: `npm run seg:<name>` (all keys in package.json `seg:*`).
Linux (wine): `apt install wine wine32` (dpkg --add-architecture i386), `export WINEDEBUG=-all`, then
1. `node src/extractAssets93-1.1.js nhlpa93retail.bin` (once, fills Extracted/)
2. `wine cmd /c "set rev=0&& set checksum=1&& build93.bat"` (rev=1 for Rev A, ref nhlpa93retailRevA.bin)
3. `node fixopcodes.js "output/nhl93 .lst" output/nhl93.bin`
4. `node verifyRom.js output/modified_nhl93.bin <reference ROM>` must print MATCH
5. Segments: run each package.json `seg:*` chain the same way (`wine cmd /c "buildseg.bat <seg>"`, then its node steps); verifySegment.js must MATCH.
Failed-assembly detection: delete output/*.bin first, then check the bin exists and is fresh and that output/Build*.log has no
`^[1-9][0-9]* error` line. tools/verify_all.sh does all of this (top ROM + every segment).

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

## Records
- docs/name_map.csv: every rename (old -> new, source/reason). History lives here, not in comments.
- docs/name_review_9x.md: name-accuracy checklist (name, verdict) per module.

## Conventions
Small commits per module; builds MATCH before every push; `git pull --rebase origin main` then push to main.
No force-push, no PRs, never commit ROMs, Extracted/ or output/.

## Current state / Next
- Comment review: done in 93, 94, 95 and NHLPA93SNES.
- Name pass (full body read), records in docs/name_review_93.md / _94.md / _95.md:
  - Phase A (93): DONE, all modules. Renames propagated to 94/95/NHLPA93SNES.
  - Phase B (94): DONE (all src modules, RAM names, equates; docs/name_review_94.md).
  - Phase C (95, docs/name_review_95.md): done: all small modules + setup goal middle pause trade awards. Todo: sound95 frames95 graphics95 stats95 season95 create95 ram95.
