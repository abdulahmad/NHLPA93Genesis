# TODO

Open items for this repo. Cross-repo items are repeated in each repo they touch.

- [ ] Full comment pass of 93G, then carry it downstream to 94G, 95G, 96G, 93S, 94S and 95PC (awaiting go-ahead).
  - 93G pass in progress (instruction density, before -> now): hockey93 0.25 -> 0.82, logic93 0.28 -> 0.71,
    stats93 0.25 -> 0.80, sram93 0.22 -> 0.78, print93 0.24 -> 0.92, video93 0.31 -> 0.72,
    decompress93 0.27 -> 0.79, penalty93 0.42 -> 0.74, menu93 0.36 -> 0.83 (PRs #52-#73).
  - Still to do for 93G: bring hockey93, logic93, video93 and penalty93 up to about 0.85; sound93 (0.63)
    second pass; teamdata93, frames93, tables93 and graphics93 are data (headers only).
  - Downstream carry not started.
- [ ] Build: auto-size the ROM (pad to the next valid cartridge size, write the header ROM end and the checksum), as NHL94Genesis `tools/fixrom.js` does.
- [ ] README: add a Credits section thanking chaos, StaticEck and McMarkis (README currently mentions: chaos, McMarkis; StaticEck missing).
