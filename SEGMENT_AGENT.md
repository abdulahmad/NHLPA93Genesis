# Segment matching agent

Finish one NHLPA 93 segment so it assembles with SNASM68K and matches the retail ROM bytes. Do not decompile the rest of the ROM.

## Sources of truth, in order

1. Retail ROM bytes. `nhlpa93retail.bin` wins over the listing, the current asm, and NHL 92.
2. IDA names. `EA-NHL-Disassembly-Project/NHL93-Genesis/NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst` is the name source for functions, labels, and RAM. It is not an assembler listing. Do not pass it to `fixopcodes.js`.
3. Style. `NHL92Genesis/src/hockey.asm`, `ram.asm`, and `macros/` are the style source. Same mnemonics, `equ`, local labels with `.`, and comment density. Do not paste 92 code over 93.
4. Current segment. `src/hockey93_01_stub.asm` is `org $6446` and includes `src/hockey93_01.asm`. RAM names already live in `src/stubinc/ram_addrs.inc`. Include that file. Do not invent a second RAM map.

## Current failure

`npm run seg` assembles. `verifySegment.js` then reports `1022 of 1138` bytes differ in `$6446-$68B7`. First real instruction mismatch: at `$6460` the ROM is `4E B9` (`jsr abs.l`) and the stub assembled `30 39` (`move.w abs.l`). The current `hockey93_01.asm` is a disassembly dump, not matching source. Rewrite the instructions from the ROM bytes. Keep IDA names.

`Stack` is `$FFFFFFFE` in the IDB export. Do not use the `$FFFFF6` equate from `main93.asm`.

## Loop

1. Read `DECOMPILATION_LEARNINGS.md`.
2. Read only `$6446-$68B7` from the IDA `.lst` and from `nhlpa93retail.bin`.
3. Rewrite `src/hockey93_01.asm` in NHL 92 style. Stub external calls that are outside this range. Do not follow those calls.
4. Run `npm run seg`.
5. If the mismatch is only a known EA `cmp` / `exg` encoding, run `fixopcodes.js` on `output/hockey93_01.lst` and `output/hockey93_01.bin`, then compare `modified_hockey93_01.bin`. Do not rewrite `exg d0,d1`. The `0C80` to `B0BC` rule stays, but it must not fire inside this segment unless the ROM byte is `B0BC`.
6. Stop after 5 failed verifies. Write the first remaining mismatch and what the ROM bytes are. Do not keep editing.

A match prints `MATCH: hockey93_01 confirmed ... at 0x006446-...`. Commit only that.

## Out of scope

- `hockey93.asm` and the full-ROM `build:retail` path.
- Rev A, Rev B, Z80, frame extractor, `extractAssets93.js`, NHL 94.
- Touch `extractAssets` only after this segment matches and a later segment is a data table the extractor already owns.
