# HANDOFF: comment and name cleanup (NHLPA93)

## Purpose
Make this bit-perfect 68000 SNASM disassembly read like clean original source: accurate names that follow the
NHL92 Genesis (EA original) lineage, and comments without disassembler or porting artifacts. Code, data and
bytes never change: every build must still MATCH the retail ROM.

## Setup
ROMs (gitignored, never commit): nhlpa93retail.bin and nhlpa93retailRevA.bin in the repo root.
Windows: `npm run build:retail` and `npm run build:reva` (tools/prebuild.js, build93.bat, fixopcodes, verify);
segments: `npm run seg:<name>` (all keys in package.json `seg:*`).
Linux (wine): `apt install wine wine32` (dpkg --add-architecture i386), `export WINEDEBUG=-all`, then
1. `node tools/prebuild.js retail` (or `reva`; checks the ROM, extracts into Extracted/ if missing or incomplete; same as `node tools/extractAssets93-1.1.js nhlpa93retail.bin`), then `export NHL_PREBUILD_DONE=1` so the .bat files skip their own pre-step (no node under wine). Accepts retail or Rev A (found by SHA-1; Rev A slices from $16E53 on are +$2E; same files). Other ROMs are refused.
2. `wine cmd /c "set rev=0&& set checksum=1&& build93.bat"` (rev=1 for Rev A, ref nhlpa93retailRevA.bin)
3. `node tools/fixopcodes.js "output/nhl93 .lst" output/nhl93.bin`
4. `node tools/verifyRom.js output/modified_nhl93.bin <reference ROM>` must print MATCH
5. Segments: run each package.json `seg:*` chain the same way (`wine cmd /c "buildseg.bat <seg>"`, then its node steps); tools/verifySegment.js must MATCH.
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

## Local label style
Follow 92G (EA source): 2105 locals, ~31% number-only (.0, .1 ...), the rest short lowercase words
(.loop, .next, .top, .done, .ex/.exit, .ok, .wait, .skip, plus abbreviations like .nna, .nodec, .sr).
- Give a word where the branch has a clear meaning (loop top, next item, skip/no-X case, exit, wait).
- Keep plain numbers for trivial jumps and for locals inherited from a matching parent routine.
- A routine that matches a parent routine uses the parent's local names.
- Data tables indexed by number (frames .0 .1 ..., team .0) stay numeric, as in 92.
- Renames are scope-aware (only between the routine's global label and the next one, code part
  only, never comments); every commit is diff-reviewed. Tool: /workspace/tools_ll/ll.py on the box.

## Current state / Next
- Comment review: done in 93, 94, 95 and NHLPA93SNES.
- Name pass (full body read), records in docs/name_review_93.md / _94.md / _95.md:
  - Phase A (93): DONE, all modules. Renames propagated to 94/95/NHLPA93SNES.
  - Phase B (94): DONE (all src modules, RAM names, equates; docs/name_review_94.md).
  - Phase C (95): DONE (all modules, ram95, graphics95, frames95, sound95; docs/name_review_95.md).
- Local label pass (locals + header register notes; checklist "Local labels" in docs/name_review_9x.md):
  93G DONE (all modules). Next: 94G (also finish routine names by body), then 95G (also data labels and
  equates by usage), then NHLPA93SNES.
- Segment inline (93G): hockey93_01/_02/_03_05/_06_11 are now inline in src/hockey93.asm (as 92 hockey.asm);
  their files, stubs and seg:* scripts are gone. tools/verify_all.sh checks full ROM (retail + Rev A) + remaining segments.
- Header rewrite (file header comments, 92 style): 93G hockey93, main, teamdata, frames, ram, macros, sega, logic, middle, penalty, video, menu, stats, sram, sound, graphics, checksum, all stubs done (93G complete).
- Restructure: root .js tools (fixopcodes, verifyRom, verifySegment, find, checkAssetsinROM, generateFrameData, generateTeamData) and src/extractAssets93-1.1.js moved to tools/; run from repo root as node tools/<name>.js (default Extracted/output paths resolve from the repo root). verify_all.sh also fails on segment assembly errors. Fresh extract + ROM (retail, Rev A) + all segments MATCH.
- Header rewrite 2 (story-style file headers, model hockey93/main93/menu93): all 93G modules done. MATCH.
- Boundary moves (Task D, routine names/headers only): UnpackNibbles + WeightedRandomSelect logic93 -> middle93 (shared helpers);
  DoHiLights + StartHL2 penalty93 -> hockey93 after the penalty93 include (intermission highlights, not penalties);
  GameSetUpMap sound93 -> graphics93 (a bitmap). Stub orgs (middle93 $D5D2, graphics93 $2E1FC), package.json ranges and docs updated. MATCH.
- Segment stubs moved to src/stubinc/ (buildseg.bat assembles stubinc\<seg>_stub.asm). MATCH.
- Extractor takes any known retail ROM: SHA-1 detection (retail 8efc1cac..., Rev A 2ab048fc...), per-version slice offsets, clear refusal of unknown ROMs (e.g. the 1993.FEB build). verify_all.sh extracts fresh from each version's own ROM before its build. Fresh extract + ROM (retail, Rev A) + all segments MATCH.
- Build pre-step: every entry point (npm build:*/seg:* scripts and the .bat files) runs tools/prebuild.js first. It checks the ROM (path, SHA-1, size; stops with a message naming the exact file and version if it is missing or wrong, ROMs are not in the repo) and re-runs the extractor when Extracted/ is missing or incomplete. The extractor writes Extracted/.extract-complete.json last (ROM SHA-1, extractor SHA-1, every file and size). npm scripts set NHL_PREBUILD_DONE=1 so the .bat does not repeat it; verify_all.sh runs it with Linux node. Tested with Windows npm/cmd under wine: fresh build auto-extracts and MATCHes; missing ROM stops with the message. MATCH.
- Animation immediates (93G): logic93 done (75). hockey93 done (98: check/fall/fight/goalie SetSPA values, roster animation scripts, and the default-sprite frame fields SPFpad/SPFgoal/SPFpuck/SPFgloves/SPFGoalie). Retail ROM MATCH. Next: video93 (SPFarrow). No new frame symbols; the names already exist in frames93.asm. `$314` as a team-address table is not an animation and was left.
