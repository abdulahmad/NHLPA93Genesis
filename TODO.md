# TODO

Open items for this repo. Cross-repo items are repeated in each repo they touch.

- [ ] Full comment pass of 93G, then carry it downstream to 94G, 95G, 96G, 93S, 94S and 95PC (awaiting go-ahead).
  - 93G pass reverted as too noisy (#75-#84): trailing comments added by #52-#73 on lines that had no comment
    before were removed; replaced comments (operand echoes, raw offsets/bits, wrong or misplaced labels) were kept.
    Instruction density is back to about the pre-pass level (hockey93 0.31, logic93 0.36, stats93 0.30, sram93
    0.28, print93 0.31, video93 0.36, decompress93 0.33, penalty93 0.47, menu93 0.43, middle93 0.45, sound93 0.47).
  - Follow-ups done: scratch RAM aliases (#85), puckgoalie sound effect comments and MenuWaitVblank note (#86).
  - Any further 93G comments: only where they add information (why, named fields/flags), not restating code.
  - Downstream carry not started.
- [ ] Build: auto-size the ROM (pad to the next valid cartridge size, write the header ROM end and the checksum), as NHL94Genesis `tools/fixrom.js` does.
- [ ] README: add a Credits section thanking chaos, StaticEck and McMarkis (README currently mentions: chaos, McMarkis; StaticEck missing).
