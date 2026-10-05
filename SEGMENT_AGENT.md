# Segment matching agent

Finish one NHLPA 93 segment so it assembles with SNASM68K and matches the retail ROM bytes. Do not decompile the rest of the ROM.

## Sources of truth, in order

1. Retail ROM bytes. `nhlpa93retail.bin` wins over the listing, the current asm, and NHL 92.
2. IDA names. `EA-NHL-Disassembly-Project/NHL93-Genesis/NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst` is the name source for functions, labels, and RAM. It is not an assembler listing. Do not pass it to `fixopcodes.js`.
3. Style. `NHL92Genesis/src/hockey.asm`, `ram.asm`, and `macros/` are the style source. Same mnemonics, `equ`, local labels with `.`, and comment density. Do not paste 92 code over 93.
4. Current segment. `src/hockey93_02_stub.asm` is `org $68B4` and includes `src/hockey93_02.asm`. The segment starts at the first instruction after `clockcont` (`demoread`, `$68B4`). RAM names already live in `src/stubinc/ram_addrs.inc`. Include that file. Do not invent a second RAM map.

Do not edit `hockey93_01.asm`. It matches retail (`$6446-$68B3`, 1134 bytes) and is done. Routines it contains are stubs in `hockey93_02_stub.asm`, under the source names from the rename table.

## Previous segment

`hockey93_01` (`$6446-$68B3`) matched. The notes below in "Loop" use it as the worked example.

Original failure, kept for reference: `verifySegment.js` reported `1022 of 1138` bytes differ in `$6446-$68B7`. At `$6460` the ROM is `4E B9` (`jsr abs.l`) and the stub assembled `30 39` (`move.w abs.l`). The old `hockey93_01.asm` was a Rev A disassembly dump. It was rewritten from the retail bytes.

`Stack` is `$FFFFFFFE` in the IDB export. Do not use the `$FFFFF6` equate from `main93.asm`.

IDA addresses drift from retail. In the v1.1 `.lst`, auto labels from `Pausemode` ($6904) on are `$E` higher than the retail bytes (IDA `loc_693E` is retail `$6930`), and far targets drift too (IDA `loc_12A16` is retail `$129FE`, IDA `loc_14D36` is retail `$14D1E`). Take every stub address and branch target from the ROM bytes. Keep the IDA name and note the retail address in the stub comment.

## Loop

1. Read `DECOMPILATION_LEARNINGS.md`.
2. Read only the current segment range from the IDA `.lst` and from `nhlpa93retail.bin`.
3. Rewrite `src/hockey93_02.asm` in NHL 92 style. Stub external calls that are outside this range. Do not follow those calls.
4. Run `npm run seg`.
5. If the mismatch is only a known EA `cmp` / `exg` encoding, write that instruction as `dc.w` with the real instruction in the comment (what `hockey93_01` does), because `npm run seg` checks raw assembler output. Do not rewrite `exg d0,d1`. The `0C80` to `B0BC` rule only applies where the ROM byte is `B0BC`.
6. Stop after 5 failed verifies. Write the first remaining mismatch and what the ROM bytes are. Do not keep editing.

A match prints `MATCH: hockey93_02 confirmed ... at 0x0068b4-...`. Commit only that.

## Comments and labels

Do this after the bytes match. Run `npm run seg` again afterward; renaming and comments must not change a byte.

Comments:

- Find the matching NHL 92 routine in `NHL92Genesis/src/hockey.asm` (or the file it lives in) and copy its comments onto the instructions that do the same thing in 93.
- Where 92 uses a symbolic constant (`gmclock`, `sfhor`, `pfjoycon`, `SCstruct`, `PenEOG`, ...), check the 92 value in `ram.asm` / the 92 `.lst`. If the 93 byte is the same, put the 92 name in the comment (`bset #0,(gmode).w ;gmclock`). If the value differs, say so (`;horn (92 SFXhorn = 24)`). Do not add 92 equates to the 93 build.
- 93-only code gets a short factual comment from what the bytes do. Do not guess game meaning you cannot see in the code.
- Mark retail-vs-Rev A differences inline (`;retail v1.1 clear end (Rev A: $CDF4)`).
- Assembler workarounds (`dc.w` for EA `cmp` encodings) keep the real instruction in the comment.
- Every global routine and data label gets a header comment on its label line: what it does, when it is called (for example `;called once per second`), and its inputs and outputs (`d7 = elapsed frames`, `return d0 = ...`). Use the 92 header if the routine exists in 92. Otherwise write one from the bytes.
- Note fall-through and outside entry points in the header (`falls in for team 2`, `Also entered from puckfaceoff+2E`).
- Inside a routine, comment every branch condition or magic value that is not obvious: what is tested, what the constant means, and which path is taken. Leave obvious lines alone.
- Comments describe behaviour you can see in the bytes. If the purpose of a flag or RAM word is unknown, describe the effect (`;set at end of game`) and leave the name alone. Do not rename RAM from a guess.
- Comment-only passes must not change bytes. Run `npm run seg` afterwards.

Labels:

- NHL 92 names win over IDA names when the routine is the same routine. For each global in the segment, find the 92 counterpart: same body shape and constants, or the same caller in 92 (for example, 93 `StartHL+8C` calls `InitTeamShots`, and 92 `StartHL` calls `RestoreTeams`). If it matches, use the 92 name and put the IDA name in the header (`restoreteams ;IDA: InitTeamShots. ...`).
  - If 92 has it as a local (`restoreteams .r`, `ResetClock .timetab`) and no code outside the segment references it in 93, make it the same local. If outside code references it, keep it global under the 92-style name.
  - If 93 split a 92 routine into a new one with no 92 name (`GetPeriodTime`), keep the IDA name and say where it came from in the header.
  - If the 92 routine does something different, keep the IDA name. A similar-looking name is not enough.
  - SNASM is case-insensitive. Do not rename just for case (`Pausemode` / `PauseMode`).
- Other human-named IDA globals (`StartGame`, `clockcont_0`, ...) stay as-is.
- IDA auto names inside the segment (`loc_XXXX`, `locret_XXXX`) and IDA `_xx` / `func_N` pseudo-locals become `.` local labels.
  - Use the 92 local label when the code matches (`.0`, `.1`, `.cf`, `.nf`, `.ns1`, `.sc`, `.t0`, `.t2`, `.t3`, `.n2`, `.eop`).
  - Otherwise pick a short descriptive name (`.x` for a shared `rts`, `.next`, `.set`, `.nomax`, `.eog`).
  - Add `;IDA: loc_XXXX` on the line so the IDA address stays searchable.
- An auto-named label that is reached from outside the segment (IDA xref outside the range) must stay global. Give it a meaningful name and add `;IDA: loc_XXXX`.
- Local labels end at the next global label. Check that every branch to a local is still inside its scope before you verify.
- Stubs for routines outside the segment keep the IDA name, even an auto name. They belong to the segment that owns that code. That segment's pass will rename them to 92 names.
- Record every rename of a global in the rename table below. Later segments must call the renamed routine by its source name, not its IDA name.

### Renamed globals

| Segment | IDA name | Source name | Why |
| --- | --- | --- | --- |
| hockey93_01 | `VBLANK` | `VBjsr` | 92 level 6 vector target, same `move.l vbint,-(sp)` / `rts` |
| hockey93_01 | `InitTeamShots` | `restoreteams` | 92 body match; 92 `StartHL` calls `RestoreTeams`, 93 `StartHL+8C` calls this |
| hockey93_01 | `InitShotStruct` | `restoreteams .r` (local) | 92 local; only caller is `restoreteams` |
| hockey93_01 | `PeriodTimeTable` | `GetPeriodTime .timetab` (local) | 92 `ResetClock .timetab`, same 4 values; only reference is `GetPeriodTime` |
| hockey93_01 | `loc_649E` | `ChkShortPeriods` | auto name, entered from `PeriodOver+D0`; named from behaviour |
| hockey93_02 | `GetTeamFromPause` | `seta2` | 92 `Pausemode .seta2`, same instructions; stays global because `HandleMenuInput` also calls it |

## Out of scope

- `hockey93.asm` and the full-ROM `build:retail` path.
- Rev A, Rev B, Z80, frame extractor, `extractAssets93.js`, NHL 94.
- Touch `extractAssets` only after this segment matches and a later segment is a data table the extractor already owns.
