# Handoff: NHLPA93 Genesis

## Now

- Stage / unit: CONTRIBUTING.md rewrite; `from 92 <name>` comments moved into `docs/history/name_map.csv` and deleted.
- Branch: `claude/project-thread-ggw7zu`
- Last check: comment-only 93G pass pending MATCH (`tools/verify_all.sh -q`)
- Next: pairing/MATCH as needed; do not merge to main
- Open PRs: (this unit)

## Status (2026-10-20)

- Everything is merged and `tools/verify_all.sh -q` prints ALL MATCH for retail, Rev A and Rev B.
- Song equates follow the in-game cues: `SngGoal`, `SngPeriodStart`, `SngLateGame`, `SngPP`, `SngFaceoff`, `SngTitle`, `SngEOP`, `SngScouting` (`src/ram93.asm`). `SngPP` was `SngPowerPlay` and `SngScouting` was `SngScout` (both in `docs/history/name_map.csv`).
- The scouting background is `EASNBGMap` (file `EASNBG.map.jim`; it was `ScoutMap` / `Scouting.map.jim`). On Rev B every EASN becomes EA Sports, so the map is `EASportsBGMap` (`EASportsBG.map.jim`) and `EASNBGMap equ EASportsBGMap`.
- Lineage that used to live in `;92 <name>` / `from 92 <name>` comments is in `docs/history/name_map.csv` only.
- 93G is the reference for 93S, 94G and 94S. Names and comments flow 92 -> 93 -> 94.

## How to work

- Build and check: `tools/verify_all.sh -q` (needs wine on Linux).
- Rules: `docs/conventions.md` and `CONTRIBUTING.md`.
- A comment-only or rename-only change must not change a byte. Record renames in `docs/history/name_map.csv`.
- Never commit ROMs, `Extracted/` or `output/`.

## Open

- Nothing is pending in this repo. Later renames here must be made in NHLPA93SNES, NHL94Genesis and NHL94SNES too (see their `docs/HANDOFF.md`), and nhl-disasm-report regenerated.
