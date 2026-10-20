# Handoff: NHLPA93 Genesis

## Status (2026-10-20)

- Everything is merged and `tools/verify_all.sh -q` prints ALL MATCH for retail, Rev A and Rev B.
- Song equates follow the in-game cues: `SngGoal`, `SngPeriodStart`, `SngLateGame`, `SngPP`, `SngFaceoff`, `SngTitle`, `SngEOP`, `SngScouting` (`src/ram93.asm`). `SngPP` was `SngPowerPlay` and `SngScouting` was `SngScout` (both in `docs/history/name_map.csv`).
- The scouting background is `EASNBGMap` (file `EASNBG.map.jim`; it was `ScoutMap` / `Scouting.map.jim`). On Rev B every EASN becomes EA Sports, so the map is `EASportsBGMap` (`EASportsBG.map.jim`) and `EASNBGMap equ EASportsBGMap`.
- Notes that said `;92 <name>` now read `from 92 <name>`.
- 93G is the reference for 93S, 94G and 94S. Names and comments flow 92 -> 93 -> 94.

## How to work

- Build and check: `tools/verify_all.sh -q` (needs wine on Linux).
- Rules: `docs/conventions.md` and `CONTRIBUTING.md`.
- A comment-only or rename-only change must not change a byte. Record renames in `docs/history/name_map.csv`.
- Never commit ROMs, `Extracted/` or `output/`.

## Open

- Nothing is pending in this repo. Later renames here must be made in NHLPA93SNES, NHL94Genesis and NHL94SNES too (see their `docs/HANDOFF.md`), and nhl-disasm-report regenerated.
