# Segment matching agent

Finish one NHLPA 93 segment so it assembles with SNASM68K and matches the retail ROM bytes. Do not decompile the rest of the ROM.

## Listing path — read this first

The annotated disassembly already exists in the workspace. Before writing any asm, open this file and search it for the routine:

`EA-NHL-Disassembly-Project/NHL93-Genesis/NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst`

From this repo that path is `../EA-NHL-Disassembly-Project/NHL93-Genesis/NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst`. It is also in the workspace next to this repo. It has IDA function names, labels, and comments. Transcribe from it.

This is the only name source. Do not disassemble `nhlpa93retail.bin`. Do not create a disassembler, decoder, listing parser, ROM dumper, or any other tool. Do not add a `.js`, `.py`, or `.md` file. `verifySegment.js`, `buildseg.bat`, and `fixopcodes.js` already work. Do not pass this IDA `.lst` to `fixopcodes.js`.

If that `.lst` does not open, stop and say the path you tried. Do not work around a missing listing by disassembling the ROM.

## Sources of truth, in order

1. Retail ROM bytes. `nhlpa93retail.bin` wins over the listing, the current asm, and NHL 92.
2. IDA names. The v1.1 `.lst` above is the name source for functions, labels, and RAM. It is not an assembler listing. Do not pass it to `fixopcodes.js`. Despite the file name, it was built from Rev A (input MD5 `B6FB2CE2...` = `nhlpa93retailRevA.bin`).
3. Style. `NHL92Genesis/src/hockey.asm`, `ram.asm`, and `macros/` are the style source. Same mnemonics, `equ`, local labels with `.`, and comment density. Do not paste 92 code over 93.
4. Current segment. `src/hockey93_09_stub.asm` is `org $14404` and includes `src/hockey93_09.asm`. The segment is `$14404-$1499D` (92 `hockey.asm` `DefaultMenus` through the playoff password code: `DefaultMenus`, `NewPO` (93 continue-playoffs reload; not 92 `NewPO`), `SelectRandomPlayoffTree` (92 `NewPO` body), `maketree` with its 92 local `.sett` (IDA `SetGameTeamOrder`), `FigureJoy`, the 93-only `InitializeGameStructures` / `GetRandomUnusedTeam`, `ReadPassBits`, `EncodePW`, `WritePassBits`, `PushBits` / `ClrPassBits` / `SuperAdd` / `SuperMult` / `SuperDiv` (IDA `EncodeValueToPassword` / `ResetPassWord` / `AddValueToAccumulators` / `MultiplyValueByWeights` / `ReadPassBits__sd`), `GetShifter`, and the 93-only playoff stat packing `DisplayTeamStatsForPlayoffs` / `BitWidthTable` / `ReadTeamStats`; see "ROM map"). `ResolveGames` onward is `hockey93_10`. Run it with `npm.cmd run seg:hockey93_09` (or `npm.cmd run seg`). There are no printz strings and no remap tables in this range. The password buffers are above `$CB00`, where retail RAM is 4 bytes lower than `ram_addrs.inc` (Rev A): `movea.w #$CB00,a3` (Rev A `pwddatabuffer` `$CB04`), `#$CB6E` (Rev A `unk_FFCB72`), `#$CB0A` (Rev A `outputbuffer` `$CB0E`), written as retail numbers with a comment. `$491A` (92 `playoffseats`, TeamData93) has delta 0. `cmp.w #$17,d2` and `cmp.w #4,d0` are EA `cmp` (`B47C` / `B07C`), patched by `fixopcodes.js`; `exg d0,d1` in `PushBits` is left as is. Outside targets from the retail displacements: `randomd0` `$D7A6`, `rtss` `$110E0`, `ResolveGames` `$1499E` (hockey93_10), `BitsToPW` `$164AC` (sram93). A match must report 1434 bytes. RAM names already live in `src/stubinc/ram_addrs.inc`. Include that file. Do not invent a second RAM map.

Do not edit `hockey93_01.asm` (`$6446-$69FF`, 1466 bytes), `menu93.asm` (`$6A00-$6C09`, 522 bytes), `stats93.asm` (`$6C0A-$8AC3`, 7866 bytes), `hockey93_02.asm` (`$8AC4-$946D`, 2474 bytes), `logic93_1.asm` (`$946E-$A0FB`, 3214 bytes), `logic93_2.asm` (`$A0FC-$AE87`, 3468 bytes), `logic93_3.asm` (`$AE88-$BC6B`, 3556 bytes), `logic93_4.asm` (`$BC6C-$C9E9`, 3454 bytes), `logic93_5.asm` (`$C9EA-$D629`, 3136 bytes), `middle93_1.asm` (`$D62A-$DCE3`, 1722 bytes), `middle93_2.asm` (`$DCE4-$E525`, 2114 bytes), `penalty93_1.asm` (`$E526-$EFA7`, 2690 bytes), `penalty93_2.asm` (`$EFA8-$FAE1`, 2874 bytes), `hockey93_03.asm` (`$FAE2-$10387`, 2214 bytes), `hockey93_04.asm` (`$10388-$10E65`, 2782 bytes), `hockey93_05.asm` (`$10E66-$11801`, 2460 bytes), `video93_1.asm` (`$11802-$11D09`, 1288 bytes) `video93_2.asm` (`$11D0A-$122A7`, 1438 bytes), `hockey93_06.asm` (`$122A8-$12E25`, 2942 bytes), `hockey93_07.asm` (`$12E26-$13951`, 2860 bytes) or `hockey93_08.asm` (`$13952-$14403`, 2738 bytes). They match retail and are done; re-check them with `npm.cmd run seg:01`, `npm.cmd run seg:menu93`, `npm.cmd run seg:stats93`, `npm.cmd run seg:02`, `npm.cmd run seg:logic93_1`, `npm.cmd run seg:logic93_2`, `npm.cmd run seg:logic93_3`, `npm.cmd run seg:logic93_4`, `npm.cmd run seg:logic93_5`, `npm.cmd run seg:middle93_1`, `npm.cmd run seg:middle93_2`, `npm.cmd run seg:penalty93_1`, `npm.cmd run seg:penalty93_2`, `npm.cmd run seg:hockey93_03`, `npm.cmd run seg:hockey93_04`, `npm.cmd run seg:hockey93_05`, `npm.cmd run seg:video93_1`, `npm.cmd run seg:video93_2`, `npm.cmd run seg:hockey93_06`, `npm.cmd run seg:hockey93_07` and `npm.cmd run seg:hockey93_08`. Routines they contain are stubs in later segments, under the source names from the rename table.

## ROM map

`src/hockey93.asm` is the full-ROM include list and follows NHL 92 file naming. The big 92 files (`hockey.asm`, `logic`, `middle`, `penalty`, `video`) are split into numbered files only so each piece can be verified on its own. Every include in `hockey93.asm` has its retail range as a comment. That comment is the contract: a segment file's `org` is the start of its range, and it must assemble to exactly that range. Do not rename or reorder includes in `hockey93.asm`.

Retail (`nhlpa93retail.bin`) ranges, inclusive. Boundaries are routine starts, checked against the ROM bytes.

| File | Range | Contents (92 source) |
| --- | --- | --- |
| Main93 | `$000000-$00030F` | vectors, header, SegaInit, Start |
| TeamData93 | `$000310-$004D8D` | team data |
| Frames93 | `$004D8E-$006445` | SPAList |
| Ram93 | no bytes | equates |
| hockey93_01 | `$006446-$0069FF` | VBjsr, Begin ... Pausemode, SetupPauseScreen, seta2 (92 hockey part 1) |
| menu93 | `$006A00-$006C09` | 93 only: InitMenuState ... MenuWaitVblank |
| stats93 | `$006C0A-$008AC3` | 93 only: stats, attribute, game info screens |
| hockey93_02 | `$008AC4-$00946D` | ReplayMode ... updateplayers, updateanim, freezewindow, checkwindow (92 hockey part 1) |
| logic93_1 | `$00946E-$00A0FB` | doinput ... check4bench |
| logic93_2 | `$00A0FC-$00AE87` | assbench ... asswingd |
| logic93_3 | `$00AE88-$00BC6B` | asswingo ... EvadePC |
| logic93_4 | `$00BC6C-$00C9E9` | checkob ... pucknorm |
| logic93_5 | `$00C9EA-$00D629` | ChkOffsides ... dirtab, 93 nibble/random helpers |
| middle93_1 | `$00D62A-$00DCE3` | remap ... Vmaddr |
| middle93_2 | `$00DCE4-$00E525` | dobitmap ... AddTeamBlock |
| penalty93_1 | `$00E526-$00EFA7` | AddPenalty ... SetHor (Penaltylist data is in hockey93_11) |
| penalty93_2 | `$00EFA8-$00FAE1` | printscores1 ... StartHL2 |
| hockey93_03 | `$00FAE2-$010387` | checkcoll ... FallDown (92 hockey part 2) |
| hockey93_04 | `$010388-$010E65` | checkfight ... checkpuckcoll |
| hockey93_05 | `$010E66-$011801` | puckstick ... deflect, then makepde ... setplayer (moved from 92 part 3) |
| video93_1 | `$011802-$011D09` | VBlank ... showcrowd |
| video93_2 | `$011D0A-$0122A7` | showclock ... KillCrowd |
| hockey93_06 | `$0122A8-$012E25` | setupice ... PeriodOver, Opening, PlayoffScreen (92 hockey part 3) |
| hockey93_07 | `$012E26-$013951` | ScoutingReport, SetupStanleyCupCelebrationScreen, TitleScreen, CallAnimationCallback, CheckSound (93 screens) |
| hockey93_08 | `$013952-$014403` | setoptions, UpdatePlayoffLevel, TeamIcons, dotb, roster player display, VBlank_SetOptions |
| hockey93_09 | `$014404-$01499D` | DefaultMenus, NewPO, MakeTree, FigureJoy, password code |
| hockey93_10 | `$01499E-$015109` | ResolveGames ... exception handlers, crash |
| hockey93_11 | `$01510A-$015FE5` | data: cd0, asstab, PenaltyList, bfasciicon, linelist, PerLabels, sizetab, sublist, priolist, menu/pause text |
| sram93 | `$015FE6-$0165D7` | 93 only: BackupRAM_*, BitsToPW, ClearRAMBuffer, ClearVRAM |
| (none) | `$0165D8-$02EFA1` | sound: 68k driver (p_turnoff), Z80 code at `$016E53`, sound data |
| (none) | `$02EFA2-$07FB75` | graphics data (`extractAssets93-1.0.js`) |
| checksum93 | `$07FB76-$07FBC7` | SecurityCheck, ValidationRoutine; `$FF` fill to `$07FFFF` |

Before this map existed, `$68B4-$6C09` was matched as "hockey93_02". That code was moved without byte changes: `$68B4-$69FF` (demoread ... seta2) to the end of `hockey93_01.asm`, and `$6A00-$6C09` to `menu93.asm`. Both re-verified. `menu93` sits between hockey93_01 and hockey93_02 in the ROM, and `stats93` (`$6C0A-$8AC3`) now matches too.

Rev A to retail. Take the Rev A address from either IDA listing and add the delta:

| Rev A range | Delta | Cause |
| --- | --- | --- |
| `$000000-$006456` | 0 | |
| `$0064A2-$009114` | -`$0E` | Rev A change in `Begin` |
| `$009124-$0166E4` | -`$18` | 10-byte Rev A insertion inside `updateplayers` |
| `$01672E-$07FBA4` | -`$2E` | 22-byte Rev A insertion in the sound driver |
| `$07FBAE-` | -`$2C` | |

Between the ranges, read the retail bytes directly. Always confirm a converted address against `nhlpa93retail.bin`.

## Previous segment

`hockey93_01` (`$6446-$69FF`), `menu93` (`$6A00-$6C09`), `stats93` (`$6C0A-$8AC3`), `hockey93_02` (`$8AC4-$946D`), `logic93_1` (`$946E-$A0FB`), `logic93_2` (`$A0FC-$AE87`), `logic93_3` (`$AE88-$BC6B`), `logic93_4` (`$BC6C-$C9E9`), `logic93_5` (`$C9EA-$D629`), `middle93_1` (`$D62A-$DCE3`), `middle93_2` (`$DCE4-$E525`), `penalty93_1` (`$E526-$EFA7`), `penalty93_2` (`$EFA8-$FAE1`), `hockey93_03` (`$FAE2-$10387`), `hockey93_04` (`$10388-$10E65`), `hockey93_05` (`$10E66-$11801`), `video93_1` (`$11802-$11D09`), `video93_2` (`$11D0A-$122A7`), `hockey93_06` (`$122A8-$12E25`), `hockey93_07` (`$12E26-$13951`) and `hockey93_08` (`$13952-$14403`) matched. hockey93_08 note: its two remap tables are retail (Framer `$01234562`, small font `$0FC04567`); its stub calls `NewPO` / `SelectRandomPlayoffTree` / `maketree` / `FigureJoy` by the hockey93_09 names, which hockey93_09 kept. hockey93_07 note: its two remap tables are retail (`$0A234567` / `$08F04567`); `CheckSound` (`$138BE`, IDA `dc.b`) is code with no caller; both TitleScreen bitmaps use `Titlemap` `$2F0B0`; `cmpi.w #7,(VertLineScrolling).l` keeps the `.l`; its stub still says `DisplayTeamBlock` (now `dotb`). hockey93_06 note: `PlayoffScreenDataTable` is the playoff vblank handler, kept as retail words; each `DecompressGraphicsWithCallback` is followed by an 8-byte retail remap table. video93_2 note: `ButtonLabelCharTable` ends in a `$10` pad byte in retail (0 in the Rev A listing); `checksso .ca` and `find3d` use `exg d0,d1` (`C141`), left as is. Keep each source line well under about 340 characters: SNASM crashed (access violation, empty `.bin`) on a 531-character header comment, and `verifySegment.js` then printed `MATCH ... 0 bytes`. Split long headers into `;` continuation lines. video93_1 note: `vb2` has no `rte` of its own and falls into `IRQ7`; `p_music_vblank` is called with `jsr (x).l` (`4EB9`); `VBlank` (IDA `VBlank_org`) is the `vbint` handler, not `VBjsr`. hockey93_05 note: the `Setplass .alist` pad byte is `$FA` in retail and 0 in the Rev A listing; `setplayer` calls `GetPeriodTime` with `jsr (x).w` (`4EB8`). hockey93_03 note: FallDown has a `move.w #4,(InjCntDown).w` right after `bsr setInjuryType` that is easy to miss in the listing (leaving it out makes the build 6 bytes short). logic93_3 note: retail has `exg a2,a1` as `C549`; SNASM swaps address-register operands and emits `C34A`, and `fixopcodes.js` rewrites it to `C549`. stats93 notes: RAM from about `$FFCAxx` is 4 bytes lower in retail than in `ram_addrs.inc` (Rev A); databuffer is `$CAEE` retail vs `$CAF2`, written as a number with a `;retail databuffer (Rev A: $CAF2)` comment. The notes below in "Loop" use hockey93_01 as the worked example.

Original failure, kept for reference: `verifySegment.js` reported `1022 of 1138` bytes differ in `$6446-$68B7`. At `$6460` the ROM is `4E B9` (`jsr abs.l`) and the stub assembled `30 39` (`move.w abs.l`). The old `hockey93_01.asm` was a Rev A disassembly dump. It was rewritten from the retail bytes.

`Stack` is `$FFFFFFFE` in the IDB export. Do not use the `$FFFFF6` equate from `main93.asm`.

IDA addresses drift from retail (the listing is Rev A; see "ROM map"). In the named `.lst`, auto labels from `Pausemode` ($6904) on are `$E` higher than the retail bytes (IDA `loc_693E` is retail `$6930`), and far targets drift too (IDA `loc_12A16` is retail `$129FE`, IDA `loc_14D36` is retail `$14D1E`). Take every stub address and branch target from the ROM bytes. Keep the IDA name and note the retail address in the stub comment.

## Loop

1. Read `DECOMPILATION_LEARNINGS.md` and this file.
2. Open `EA-NHL-Disassembly-Project/NHL93-Genesis/NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst` and read only the current segment. Transcribe those named instructions. Do not disassemble the ROM. Use `nhlpa93retail.bin` only to check bytes and to fix addresses with the delta table. If the listing does not open, stop.
3. Rewrite the current segment asm in NHL 92 style. Stub external calls that are outside this range. Do not follow those calls.
4. Run `npm run seg`. It assembles, runs `fixopcodes.js` on that segment's assembler listing (`output\<segment> .lst`) and `output\<segment>.bin` at the segment org, which writes `output\modified_<segment>.bin`, then runs `verifySegment.js` on that modified file. `verifySegment.js` compares `output\modified_<segment>.bin`, not the raw assembler bin. Do not pass the IDA `.lst` to `fixopcodes.js`.
5. Write the real `cmp` / `cmpi` / `exg`. Do not hand-encode opcodes. SNASM may emit the wrong encoding for EA `cmp #imm,Dn` (CMPI `0Cxx` instead of CMP `Bxxx`) and for `exg a2,a1` / `exg d1,d0`; `fixopcodes.js` fixes those after the assemble. Do not rewrite `exg d0,d1`. The `0C80` to `B0BC` rule only applies where the retail byte is `B0BC`. The sound-incbin early-out in `fixopcodes.js` stays.
6. Stop after 5 failed verifies. Write the first remaining mismatch and what the ROM bytes are. Do not keep editing.

Inline strings. IDA misdecodes the bytes after `bsr printz` and `bsr appendz` as instructions (`ori.b #x,d6`, `move.b d0,-(a3)`, `btst d0,d0`, stray `#$7C` lines ...). The first word is the String length. Where the listing and the retail bytes disagree there, write a `String` from the retail bytes, and keep any real instruction IDA swallowed after the string (it starts where the length ends). A label whose only reference is inside one of those strings is not an entry. Do not create it.

Stub addresses. Take every outside stub address from the retail branch displacement: the `bsr` / `bra` / `Bcc` target is the address of the displacement word plus the signed displacement; `jsr (x).w` / `jsr (x).l` and `movea.l #x` carry the address itself. A Rev A address from the listing, converted with the delta table, is only a candidate until it agrees with those retail bytes. Do not copy an address from another stub without that check.

A match prints `MATCH: hockey93_03 confirmed 2214 bytes at 0x00fae2-0x010387`. The byte count must equal the ROM map range. Commit only that.

## Comments and labels

Do this after the bytes match. Run `npm run seg` again afterward; renaming and comments must not change a byte.

Comments:

- Find the matching NHL 92 routine in `NHL92Genesis/src/hockey.asm` (or the file it lives in) and copy its comments onto the instructions that do the same thing in 93.
- Where 92 uses a symbolic constant (`gmclock`, `sfhor`, `pfjoycon`, `PenEOG`, ...), check the 92 value in `ram.asm` / the 92 `.lst`. If the 93 byte is the same, put the 92 name in the comment (`bset #0,(gmode).w ;gmclock`). If the value differs, say so (`;horn (92 SFXhorn = 24)`). Sfx, song and penalty numbers stay numbers. A flag bit named this way then moves into the operand under "Bit names" below. Struct field offsets (`SCstruct`, `Ypos`, `tmsize`, `tmdata`, ...) are not this case: they are equates under "Names" below, even when 93 moved the field.
- 93-only code gets a short factual comment from what the bytes do. Do not guess game meaning you cannot see in the code.
- Mark retail-vs-Rev A differences inline (`;retail clear end (Rev A: $CDF4)`).
- EA `cmp` / `exg` encodings are not written as `dc.w`. Write the real instruction; `fixopcodes.js` patches the encoding.
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
  - A 92 name wins only when the body is the same routine.
  - If an earlier segment already has that global, keep the IDA name or make it local, and record the collision in the rename table.
- Other human-named IDA globals (`StartGame`, `clockcont_0`, ...) stay as-is.
- IDA auto names inside the segment (`loc_XXXX`, `locret_XXXX`) and IDA `_xx` / `func_N` pseudo-locals become `.` local labels.
  - Use the 92 local label when the code matches (`.0`, `.1`, `.cf`, `.nf`, `.ns1`, `.sc`, `.t0`, `.t2`, `.t3`, `.n2`, `.eop`).
  - Otherwise pick a short descriptive name (`.x` for a shared `rts`, `.next`, `.set`, `.nomax`, `.eog`).
  - Add `;IDA: loc_XXXX` on the line so the IDA address stays searchable.
- An auto-named label that is reached from outside the segment (IDA xref outside the range) must stay global. Give it a meaningful name and add `;IDA: loc_XXXX`.
- Local labels end at the next global label. Check that every branch to a local is still inside its scope before you verify.
- Stubs for routines outside the segment keep the IDA name, even an auto name. They belong to the segment that owns that code. That segment's pass will rename them to 92 names.
- Record every rename of a global in the rename table below. Later segments must call the renamed routine by its source name, not its IDA name.

Names. After the bytes match, replace a numeric offset or RAM address with an equate when the value is known. A 92 name is the field, not the number. The equate holds the 93 value, and its comment in `src/stubinc/struct93.inc` gives the 92 value when 93 moved the field: `tmsize` is `$1A2` in 93 (92 `$88`), `tmdata` is `$1E` (92 `$E`), and both are valid names. Put shared equates in `src/stubinc/struct93.inc` and include that file from every stub. Do not add a second RAM map. A RAM word already in `ram_addrs.inc` is used by that name. A `word_FF` / `byte_FF` name becomes an equate only when the IDA listing or `NHL92Genesis/src/ram.asm` names that exact address. A SortCords or team-struct field goes into struct93.inc only when a finished segment comment or `NHL92Genesis/src/ram.asm` already uses that name for that field at that 93 offset; do not invent a name. Replace a number only where the code uses it as that field: a SortCords offset on a sort object pointer, a team-struct offset on a team struct pointer. A team-struct field is not a SortCords field, and a number that only equals an equate stays a number (`$62` as the replay frame size is not `pflags`; `$16(a5)` in the replay camera struct is not `tmline`). Leave `(aN)` with no displacement as it is (`tmshots(a2)` / `Xpos(a3)` can assemble as a `d16(An)` form). An immediate that is a penalty, sfx, or song number stays a number. When the name goes in the operand, drop the same name from the line comment. Run the segment's seg script afterward; the MATCH byte count and range must not change.

struct93.inc fields (93 value; 92 value in brackets where 93 moved it). SortCords: `Xpos` 0, `attribute` 4, `frame` 6, `oldframe` 8, `VRoffs` `$A`, `VRchar` `$12`, `Ypos` `$14`, `Zpos` `$18`, `OldXpos` `$1C`, `OldYpos` `$20`, `OldZpos` `$24`, `Xvel` `$28`, `Yvel` `$2A`, `Zvel` `$2C`, `impactp` `$2E`, `limpact` `$30`, `impact` `$32`, `position` `$34`, `assnum` `$36`, `asslist` `$38`, `temp1`-`temp5` `$40`-`$48`, `radiusx` `$4A`, `radiusy` `$4C`, `Wallcos` `$4E`, `Wallsin` `$50`, `SCnum` `$52`, `facedir` `$54`, `SPA` `$58`, `SPAnum` `$5A`, `SPAcnt` `$5C`, `nopuck` `$5E`, `newpos` `$60`, `newpnum` `$61`, `pflags` `$62`, `pflags2` `$63`, `glitch` `$65`, `pnum` `$66`, `weight` `$67`, `legstr` `$68`, `legspd` `$69`, `aioff` `$6A`, `aidef` `$6B`, `shotspd` `$6C`, `shotacc` `$6D`, `passacc` `$6E`, `rostnum` `$6F`, `spodds` `$70`, `stickhand` `$71`, `endurance` `$72`, `handed` `$76` (`$74`), `SCstruct` `$80`. Team struct: `tmshots` 0, `tmPwrGoals` 2, `tmPwrPlays` 4, `tmPenalties` 6, `tmPenmin` 8, `tmATOP` `$A` (`$C`), `tmscore` `$C` (`$16`), `tmline` `$16` (`$18`), `tmdata` `$1E` (`$E`), `tmsort` `$22` (`$12`, word in 93), `tmap` `$24` (`$1A`), `tmgoalie` `$26` (`$1C`), `tmflags` `$30` (`$1E`), `tmpde` `$32` (`$20`), `tmpdst` `$66` (`$54`), `tmsize` `$1A2` (`$88`). Game struct (`gstruct`, 92 `ram.asm` names and offsets, unchanged in 93): `gst1` 0, `gst2` 2, `gspotwins` 4, `gspobwins` 6, `gsper` 8, `gss1` `$A`, `gss2` `$C`, `gsflags` `$E`, `gssize` `$10`; the `gsflags` bits (`gsftf` 0, `gsfhl` 1, `gsfso` 2) are not in the "Bit names" list and stay numbers. 92 `aggress` is not defined: finished comments put it at `$73`, `$74` and `$75`.

Bit names. A line comment that names a 92 bit equate (`bset #2,(sflags2).w ;sf2drec`) means the bit number is that 92 equate. Write the equate as the bit number: `bset #sf2drec,(sflags2).w`, `bclr #sfwrap,(sflags).w`. This covers the bits `NHL92Genesis/src/ram.asm` defines for `sflags`, `sflags2`, `sflags3`, `gmode`, `disflags`, `pflags` and `pflags2`. The flag word comes from the retail bytes: keep the operand the 93 code uses, even where 92 used a different word. The 92 name is only the bit number. Use it only when the comment names it and the 93 bit number equals the `ram.asm` value. Where 93 moved the bit (`btst #2,pflags2(a3) ;unavailable (92 pf2unav = 4)`), or the comment gives no 92 name, the number stays a number. Do not invent a bit name, and a number that only equals a bit equate stays a number. The equates live in `src/stubinc/struct93.inc`; add one there, with its `ram.asm` value, before the first use. Drop the name from the line comment, as under Names. Run the seg script afterward; the MATCH byte count and range must not change.

Call form. Where 92 writes an unsized call (`jsr p_turnoff`, `jsr setupice`), 93 may use that form only if SNASM emits the same opcode as the retail bytes. The jsr size comes from the retail bytes: `jsr (p_turnoff).l` is absolute long, `4EB9`; `jsr (ResetClock).w` is absolute short, `4EB8`. The 92 name is only the label. If dropping the size or the parentheses changes the first opcode byte, keep the sized form. Where 92 has no unsized `jsr` to that label, keep the sized form. `bsr.w` stays `bsr.w`. Run the seg script afterward; the MATCH byte count and range must not change.

Expressions. Where a number is a combination of proven names, write the expression instead of the number. Use the form NHL 92 writes when 92 has the same code: `#6*SCstruct` (the other team's first sort object, `$300`), `Xpos-SCstruct(a3)` / `Ypos-SCstruct(a3)` (the object before a3, `-$80` / `-$6C`), `moveq #Ypos,d0` / `moveq #Xpos,d0` (a field offset used as an index), `#(SortCords-M68K_RAM)+(6*SCstruct)` (word address of a sort object, `$B34A`). A RAM address used as a word immediate is `#(name-M68K_RAM)` (`cmpa.w #(hmtmstruct-M68K_RAM),a2`), and a byte inside a RAM word is `(name+1).w` (`(crowdframe+1).w`). Every term must be a proven name under the rule above, and the expression must evaluate to exactly the number it replaces. Do not build an expression to explain a number whose meaning you cannot see in the code: a value that only happens to equal a sum (for example `$62` used as the replay frame size, not `pflags`) stays a number. A field 93 moved is a proven name like any other: an expression may use `tmsize`, `tmdata`, or any struct93.inc equate when every name is a defined equate and the expression equals the number it replaces (`#tmsize-1` for a `dbf` count of `$1A1` over `tmsize` words). A byte inside a struct field is `name+1(aN)` as 92 writes it (`temp2+1(a3)` `$43`, `SCnum+1(a3)` `$53`, `position+1(a3)` `$35`, `attribute+1(a3)` 5); the other team's field from a team pointer is `tmsize+tmap(a2)` (`$1C6`) / `tmap-tmsize(a2)` (`-$17E`); 1-based player indexing is `tmpde-2(a2,d3.w)` (`$30`). Run the seg script afterward, as above.
### Renamed globals

| Segment | IDA name | Source name | Why |
| --- | --- | --- | --- |
| hockey93_01 | `VBLANK` | `VBjsr` | 92 level 6 vector target, same `move.l vbint,-(sp)` / `rts` |
| hockey93_01 | `InitTeamShots` | `restoreteams` | 92 body match; 92 `StartHL` calls `RestoreTeams`, 93 `StartHL+8C` calls this |
| hockey93_01 | `InitShotStruct` | `restoreteams .r` (local) | 92 local; only caller is `restoreteams` |
| hockey93_01 | `PeriodTimeTable` | `GetPeriodTime .timetab` (local) | 92 `ResetClock .timetab`, same 4 values; only reference is `GetPeriodTime` |
| hockey93_01 | `loc_649E` | `ChkShortPeriods` | auto name, entered from `PeriodOver+D0`; named from behaviour |
| hockey93_01 | `GetTeamFromPause` | `seta2` | 92 `Pausemode .seta2`, same instructions; stays global because `HandleMenuInput` also calls it |
| stats93 | (none, retail `$6C0A`) | `ShowScores` | unnamed entry; prints "Scores" (93 only, no 92 counterpart) |
| stats93 | (none, retail `$6E08`) | `LineEditor` | unnamed entry; prints "Line Editor" |
| stats93 | `loc_6E32` | `LineEditorRedraw` | auto name, also entered from `ExitAttributeScreen` |
| stats93 | `loc_6E52` | `LineEditorMenu` | auto name, also entered from `SelectAttributeItem` |
| stats93 | `word_729C` | `MenuIconPosTable-6` | data auto name; label removed, referenced as an expression |
| stats93 | `word_72A4` | `MenuIconPosTable+2` | data auto name; label removed, referenced as an expression |
| stats93 | `unk_72CE` | `LineCursorTable` | data auto name; line editor cursor move table |
| stats93 | (none, retail `$7418`) | `EncodePlayerAttributes` | unnamed; reverse of `DecodePlayerAttributes`, ends in `BitsToPW` |
| stats93 | (none, retail `$749C`) | `TeamRosterScreen` | unnamed entry; prints "Team Roster" |
| stats93 | `loc_7666` | `StopPlayerListScroll` | auto name branched to from `CheckPlayerListScroll` (separate global in IDA flow) |
| stats93 | (none) | `GoalieRowText` | unlabeled data (`movea.l #$7788` Rev A) |
| stats93 | (none) | `AttribStatus`, `AttribEnergy`, `AttribHanded`, `AttribWeight`, `AttribFighting`, `AttribRating` | `attribjmp` targets (IDA comments "jump for status/energy/..."); table now uses label differences |
| stats93 | `loc_794E` | `AttribPrintPct` | shared tail of the energy/fighting/rating handlers |
| stats93 | (none, retail `$7992`) | `ScoringSummaryScreen` | unnamed entry; prints "Scoring Summary" |
| stats93 | `DisplayPenaltyList` | (dropped) | IDA label inside the misdecoded "Penalty Summary" string; not a real entry |
| stats93 | (none, retail `$7C0C`) | `PenaltySummaryScreen` | unnamed entry; prints "Penalty Summary" |
| stats93 | (none, retail `$7F04`) | `PlayerStatsScreen` | unnamed `clr.w d7` entry before `DisplayAttributeScreen`; prints "Player Stats" |
| stats93 | `loc_8088` | `SetAttribScrollReg` | auto name, branched to from `DisplayAttributeMenu` |
| stats93 | (none) | `AttributeTitleTxt` | unlabeled data used by `DisplayAttributeMenu` |
| stats93 | (none, retail `$849E`) | `GameStatisticsScreen` | unnamed entry; prints "Game Statistics" |
| stats93 | (none, retail `$866C`) | `CrowdMeterScreen` | unnamed entry; prints "Crowd Meter" |
| stats93 | (none, retail `$8894`) | `TimeoutMenu` | undecoded code (kept as retail `dc.b`); prints "Timeout" |
| stats93 | (none, retail `$88FC`) | `SelectGoalieMenu` | unnamed entry; goalie pick list with "no goalie" |
| hockey93_02 | `suba4_reverseReplayFrame` | `suba4` | 92 `suba4`: same rewind-one-frame job and callers in `ReplayMode` |
| hockey93_02 | `adda4_advanceReplayFrame` | `adda4` | 92 `adda4`, same `sf2drec` look-ahead and `adda42`/`adda43` fall-through |
| hockey93_02 | `RewindToStart`, `ReplayMainLoop`, `HandleNoInput`, `CheckRewind`, `CheckAdvance`, `AdvanceOneFrame`, `CheckPlayMode`, `CheckExit`, `ClampCameraX`, `ClampCameraY`, `ScrollDirTbl` | `ReplayMode .rwd .top .nomans .00 .0 .f1 .1 .noplay .nox .noy .stab` (locals) | 92 `ReplayMode` locals; only referenced inside `ReplayMode` |
| hockey93_02 | `CheckDirectionInput`, `ManualScroll`, `FindTrackingTarget`, `CheckObjectLoop`, `SkipObject`, `UpdateManualScroll` | `ReplayMode .dir .man .find .obj .skip .scrl` (locals) | 93-only tracking code inside `ReplayMode`; only referenced there |
| hockey93_02 | `nonshift` | `updatereplay .n1` (local) | IDA put the name on a branch target inside `updatereplay`; not the 92 `nonshift` routine (that job is in `RestoreReplayFrame`) |
| hockey93_02 | `_scload`, `_top` | `updateplayers .u0 .top` (locals) | IDA pseudo-locals; 92 local names |
| logic93_1 | `loc_9660` | `SetLCmode` | 92 name; abut by puck carrier starts line change mode |
| logic93_1 | `showfaceoff` | `SetLCmode2` | draws the line change box (no faceoff job); fall-through from `SetLCmode`, also called by `lineinput` |
| logic93_1 | `retorepl` | `restorepl` | 92 name (IDA typo) |
| logic93_1 | `checkgoalp_CalcGoalShotDir` | (kept) | 93-only aim-at-open-side helper for `doshot`. Was renamed `checkgoalp`; reverted in the hockey93_04 pass because 92 `checkgoalp` (goal/net collision, same body) is in hockey93_04 |
| logic93_1 | `loc_949C`, `_nhor`, `loc_9516`, `loc_952C`, `loc_9564` | `doinput .0 .nhor .ispc .pc1 .islocked` (locals) | branch targets inside `doinput` |
| logic93_1 | `_noa`, `_0`, `_1`, `_ind` | `fightinput .noa .0 .1 .ind` (locals) | IDA pseudo-locals |
| logic93_1 | `unk_97A2` | `getlchoice .tab` (local) | line choice table, 21 rows of 3 + pad byte |
| logic93_1 | `CalcPassTime`, `ClampPassTime`, `ClampPassTime2`, `CalcPuckVelocities` | `passtoa0 .0 .1 .2 .3` (locals) | branch targets inside `passtoa0` |
| logic93_1 | `t1_CheckPlayers`, `top_CheckPlayerLoop`, `next_SkipPlayer`, `ex_CheckSweep` | `changeplayer .t1 .top .next .ex` (locals) | `.ex` is pushed with `pea (.ex).l` |
| logic93_1 | `ReleaseOldPlayer`, `spd_SetNewPlayer` | `restorepl .rel .spd` (locals) | branch targets |
| logic93_1 | `_ck0_CalcShotToGoal`, `_ck1_SetShotAnim` | `SetShotMode .ck0 .ck1` (locals) | IDA put them under `Findhittype` |
| logic93_1 | `ShotMode_ss0`, `CheckCButton`, `ReverseShot` | `ShotMode .ss0 .cb .rev` (locals) | branch targets |
| logic93_1 | `doshot_nbh` ... `doshot_ex`, `ClampPenalty`, `AddRandomError`, `AddYError`, `AddMoreRandom`, `shotsets` | `doshot .nbh .c .0 .1 .notperf .cp .ar .ay .am .perf .noup .ex .shotsets` (locals) | 92 `doshot` locals plus the 93 crowd-bonus branch |
| logic93_1 | `CheckOpponentGoalie`, `CalcLeftAngle`, `SetShotDirection`, `ReturnDefaultDir` | `checkgoalp_CalcGoalShotDir .g .l .s .x` (locals) | branch targets |
| logic93_1 | `loc_A0A8`, `loc_A0E4` | `check4bench .b .samepl` (locals) | branch targets |
| logic93_2 | `loc_A154` ... `loc_A26C` | `assbench .0 .nna .gli .ok .done .t0 .nodec .nobench .nobench2` (locals) | 92 `assbench` locals |
| logic93_2 | `CwdFight` | `chkhit .cwd` (local) | only called by `chkhit` |
| logic93_2 | `FightFall`, `FindPenaltyLoop`, `NoInjury`, `PlayCrowdSound` | `chkhit .fall .loop .noinj .snd` (locals) | 92 `chkhit .fall`; it ends in `bra .ex`, so it has to share `chkhit`'s scope |
| logic93_2 | `sub_A8AE` (Rev A) | `ShowInjuryMsg` | named listing name |
| logic93_2 | `_a1` | `assfight .al` (local) | 92 name; punch SPA table |
| logic93_2 | `_nna`, `_nna2`, `_j`, `_njc`, `_0`, `_jc`, `_y1`, `_y2`, `loc_A5C0`, `loc_A652` | `assfight .nna .nna2 .j .njc .0 .jc .y1 .y2 .s .p` (locals) | IDA pseudo-locals / branch targets |
| logic93_2 | `_ex`, `_dropped`, `_chkneg`, `_drcont`, `_dr0`, `_grab`, `_hithigh`, `_hitlow`, `_xveladj` | `chkhit .ex .dropped .chkneg .drcont .dr0 .grab .hithigh .hitlow .xveladj` (locals) | IDA pseudo-locals |
| logic93_2 | `loc_*` in asseben ... asswingd | 92 local names (`.nna`, `.st`, `.nodec`, `.de0`-`.de3`, `.gup`, `.gdwn`, ...) | branch targets; IDA comment on each line |
| logic93_2 | `$BBEA` (Rev A literal) | `EvadePC` | 92 `move.l #EvadePC,a0`; retail `$BBD2` |
| logic93_2 | `SFX` (Rev A) | `song` | named listing name; retail `$D876`, not `sfx` (`$D852`) |
| logic93_3 | `loc_B18A` | `assgoalie` | 92 name; assignment table entry `agoalie`, also entered from `assnearest` |
| logic93_3 | `AdjustFacingDirecion` | `AdjustFacingDirection` | IDA typo; body misdecoded in the listing, rebuilt from the bytes |
| logic93_3 | `unk_B6F2` | `GoalieSaveList` | 92 `assgoalie .list`; global because it sits after `AdjustFacingDirection` |
| logic93_3 | `sub_F268`, `sub_C340` (Rev A) | `AvgCline`, `CompLine` | named listing names, used by `chk4lc` |
| logic93_3 | `unk_AF8A`, `unk_B14E` | `asswingo .dedata`, `asscentero .dedata` (locals) | 92 names |
| logic93_3 | `asspuckc_nna`, `asspuckc_onside`, `asspuckc_nd1`, `asspuckc_nd0`, `asspuckc_chkdir`, `asspuckc_cd0`, `asspuckc_next`, `_posttab` | `asspuckc .nna .nodec .nd1 .nd0 .chkdir .cd0 .next .postab` (locals) | 92 names |
| logic93_3 | `checkForPassAcrossBlueLine`, `_dp0`, `_dp1`, `_f0`, `_oko`, `_ok`, `_co0`, `_co1` | `chk4pass .bl .dp0 .dp1 .f0 .oko .ok .co0 .co1` (locals) | 92 names (`.bl` is 93 only) |
| logic93_3 | `loc_*` in asswingo ... EvadePC | 92 local names (`.nna`, `.nodec`, `.de0`-`.de8`, `.noskate`, `.mbfo`, `.nofo`, ...) or short names | branch targets; IDA comment on each line |
| logic93_4 | `loc_BFC6` | `asspassrec` | 92 name; assignment table entry `apassrec` (Rev A `$151EE`) |
| logic93_4 | `loc_C028` | `assshoot` | 92 name; assignment table entry `ashoot` (Rev A `$151EA`) |
| logic93_4 | `loc_C2C2` | `ReturnGoalies` | 92 name; 92 `puckfaceoff` calls `returngoalies`, 93 `puckfaceoff+70` calls this |
| logic93_4 | `loc_C2F6` | `CPgoalie` | 92 name; falls in from `ReturnGoalies`, entered from `ChkGoalies .CPG` |
| logic93_4 | `CheckGoaliePull` | `ChkGoalies .CPG` (local) | 92 local; only caller is `ChkGoalies` (bsr + fall-through) |
| logic93_4 | `puckfaceoff_sclc`, `puckfaceoff_slc`, `nna`, `UpdatePlayerLineChangeTimer` | `puckfaceoff .sclc .slc .nna .clc` (locals) | 92 locals; only referenced inside `puckfaceoff` |
| logic93_4 | `topuck`, `_topuck` | `assnearest .topuck .mid` (locals) | `topuck` is 92 `.topuck`; `_topuck` is the 93 in-between-spot code |
| logic93_4 | `_apl`, `hl1`, `_al1`, (none, Rev A `$C92C`) | `puckfaceoff2 .apl .ptab`, `CompLine .hl1 .al1`, `Endfaceoff .ftab` (locals) | 92 names; `movea.l #$C790`/`#$C7A8`/`#$C92C` are now `#.apl`/`#.ptab`/`#.ftab` |
| logic93_4 | `checkob_*`, `_nna` ... `_nd0`, `loc_BF0A`, `loc_BF16`, `loc_BF36` ... `loc_C9EA` | 92 local names (`.0`, `.bottom`, `.bn`, `.nob`, `.ex`, `.ob`, `.dref`, `.top`, `.top1`, `.tn`, `.nna`, `.nopc`, `.np`, `.de0`, `.next`, `.switch`, `.de1`, `.nfar`, `.x`, `.nodec`, `.nd0`, `.nopen`, `.npo`, `.nohor`, `.nlp`, `.nlp2`, `.t1`, `.slcex`, `.clnd`, `.clcex`, `.h0`, `.away`, `.a0`, `.p`, `.ntm`, `.cw`, `.l0`, `.l1`, `.goalie1`, `.t0`, `.f0`, `.notmid`, `.nodef`, `.goalie2`, `.fok`, `.nfl`, `.nt1`, `.nt2`, `.p1won`, `.pos`, `.nojoy`, `.nj2`, `.nothandled`) or short names (`.neg`, `.go`, `.ex`, `.rg`, `.lcm`, `.clh`, `.cp`, `.tm`, `.nx`, `.nol`, `.erase`, `.np`, `.mv`, `.z`) | branch targets; IDA comment on each line |
| logic93_4 | `puckunflip` (Rev A listing, `$C05C`) | `pucknothing` | named listing name; Rev A `puckunflip2` is the real `puckunflip` (retail `$CC8E`) |
| logic93_5 | `sub_CAB4` (Rev A lst) | `ClearOffsidesIfAllPlayers` | named listing name; 93 only (team offsides flag), retail `$CA9C` |
| logic93_5 | `sub_CAF4` (Rev A lst) | `a2offsides` | named listing and 92 name, retail `$CADC` |
| logic93_5 | `puckunflip2` (Rev A lst) | `puckunflip` | named listing and 92 name, retail `$CC8E` |
| logic93_5 | `sub_CCD0` (Rev A lst) | `puckflip` | named listing and 92 name, retail `$CCB8` |
| logic93_5 | `sub_CD44` (Rev A lst) | `findpc` | named listing and 92 name, retail `$CD2C` |
| logic93_5 | `sub_CE86` (Rev A lst) | `avdgoal` | named listing and 92 name, retail `$CE6E` |
| logic93_5 | `loc_D366` | `noturn0` | 92 name; reached from `doplayeracc` but sits after `goalieacc`, so global (retail `$D34E`) |
| logic93_5 | `loc_D410` | `noturn` | 92 name; entered from `doplayeracc` and `noturn0`, falls into `playeracc` (retail `$D3F8`) |
| logic93_5 | `loc_D538` | `dostop` | 92 name; entered from `doplayeracc` and `noturn0`, falls into `StopNA` (retail `$D520`) |
| logic93_5 | `sub_D5EA`, `sub_D616` (Rev A lst) | `UnpackNibbles`, `WeightedRandomSelect` | named listing names; 93 only, retail `$D5D2`, `$D5FE` |
| logic93_5 | `findpc_calc`, `avggoal_ch1` | `findpc .calc`, `avdgoal .ch1` (locals) | 92 locals; only called by their parent |
| logic93_5 | (none, Rev A `$D0CE`, `$D2F8`) | `vtoa .dt`, `doplayeracc .ftab` (locals) | 92 names; `movea.l #$D0CE`/`#$D2F8` are now `#.dt`/`#.ftab` (retail `$D0B6`/`$D2E0`) |
| logic93_5 | `loc_*`, `locret_CD42`, `process_one_nibble`, `extract_and_store_nibble`, `loop_control`, `sum_all_weights`, `find_entry_random` | 92 local names (`.neg`, `.0`-`.3`, `.icing`, `.up`, `.notice`, `.k`, `.siren`, `.nhor`, `.s0`, `.o1`, `.o2`, `.nocross`, `.next`, `.vt`, `.nvt`, `.nf`, `.ex`, `.lower`, `.chbar`, `.ch2`, `.ch3`, `.nodir`, `.nox`, `.noy`, `.d0`, `.d1`, `.cgl`, `.c1`, `.inrev`, `.rev`, `.setrev`, `.fwd`/`.clrrev`, `.done`, `.iok`, `.i0`, `.s1`-`.s3`, `.nostop`, `.nos0`, `.nochg`, `.ns`, `.sube`, `.set`, `.xp`, `.y`, `.yp`) or short names (`.t0`, `.t1`, `.top`, `.t`, `.st`, `.same`, `.chkx`, `.spa`, `.nb6`, `.ng`, `.ms`, `.loop`, `.lo`, `.sum`, `.find`) | branch targets; IDA comment on each line |
| middle93_1 | `ConvertAndWriteToVDP` (Rev A lst `loc_D642`) | `remap` | 92 name and interface (a0 data, d0 words, d1 vram, a1 map); 93 packs the map two nibbles per byte. Retail `$D62A` |
| middle93_1 | `sub_D6BE`, `sub_D6EE`, `sub_D77C` (Rev A lst) | `forcefade`, `cramfade`, `CopyPaletteToCRAM` | named listing names (92 names for the first two), retail `$D6A6`, `$D6D6`, `$D764` |
| middle93_1 | `sub_D7B2` (Rev A lst) | `randomd0s` | named listing and 92 name, retail `$D79A` |
| middle93_1 | `SFX` (Rev A lst) | `song` | named listing and 92 name; `SFX` would clash with `sfx` (case-insensitive). Retail `$D876` |
| middle93_1 | `sub_D8AE`, `sub_D8D8` (Rev A lst) | `waitx`, `IntermissionLoop` | named listing names; `IntermissionLoop` is the 93 rewrite of 92 `waitxsr`, kept under its IDA name. Retail `$D896`, `$D8C0` |
| middle93_1 | (none, Rev A `$D95E`, IDA `dc.b`) | `waitjoy` | 92 name; same 18 bytes as 92 `waitjoy`, no caller found. Retail `$D946` |
| middle93_1 | `sub_D970`, `sub_D97E`, `sub_D9A6`, `readjoy1`, `readjoy2`, `sub_DA0A` (Rev A lst) | `orjoy`, `nodiag`, `ProcessInputWithRepeat`, `Readjoy1`, `Readjoy2`, `ReadJoy` | named listing names; retail `$D958`, `$D966`, `$D98E`, `$D9B6`, `$D9D4`, `$D9F2` |
| middle93_1 | (none, Rev A `$DA88`) | `jdtab` | 92 name; `movea.l #$DA88,a0` is now `#jdtab` (retail `$DA70`) |
| middle93_1 | `loc_DA98`, `sub_DAAC`, `sub_DB46`, `sub_DBB0`, `sub_DBE4` (Rev A lst) | `DoDMApro`, `DoDMA`, `DoDMA_nd2`, `DoFill`, `WaitDMA` | named listing names; `DoDMA_nd2` is 93 only (vram copy). Retail `$DA80`, `$DA94`, `$DB2E`, `$DB98`, `$DBCC` |
| middle93_1 | `sub_DBF6`, `sub_DC0C`, `sub_DCE2` (Rev A lst) | `setVram`, `setVram_0`, `Vmaddr` | named listing names; `setVram_0` is the second half of 92 `setVram`, global because `SetupStanleyCupCelebrationScreen` calls it. Retail `$DBDE`, `$DBF4`, `$DCCA` |
| middle93_1 | `DoDMA_dd`, `_nd` | `DoDMA .dd .nd` (locals) | 92 locals; IDA split `.dd` into a function, only caller is `DoDMA` |
| middle93_1 | `process_word`, `process_nibble`, `pack_nibble_into_output`, `sfx_none`, `_none`, `_1`, `_top`, `_nn`, `_next`, `_wait`, `_0`, `_9`, `_i32`, `_i64`, `loc_*` | 92 local names (`.1`, `.2`, `.0`, `.top`, `.nn`, `.next`, `.m2`, `.none`, `.wait`, `.nz`, `.ok`, `.z`, `.zz`, `.9`, `.i32`, `.i64`) or short names (`.lo`, `.done`, `.big`, `.bs`, `.key`, `.menu`, `.resume`, `.vid`, `.ex`, `.chg`) | branch targets; IDA comment on each line |
| middle93_2 | `sub_DCFC`, `sub_DFA6`, `sub_E3F4`, `sub_E406`, `sub_E516`, `sub_E524`, `sub_E532` (Rev A lst) | `dobitmap`, `xyVmMap`, `printbigz`, `printbig`, `AddSmallFont`, `AddFramer`, `AddTeamBlock` | named listing and 92 names; retail `$DCE4`, `$DF8E`, `$E3DC`, `$E3EE`, `$E4FE`, `$E50C`, `$E51A` |
| middle93_2 | `sub_DD80`, `sub_DD8C`, `sub_DD90`, `sub_DDCE`, `unk_DE06`, `sub_DF78` (Rev A lst) | `DecompressGraphicsWithCallback`, `DoDMA_clearCallbackPointer`, `DecompressGraphics`, `DecompressBytecode`, `jump_table`, `FlushOutputBuffer` | named listing names; 93 only tile decompressor. Retail `$DD68`, `$DD74`, `$DD78`, `$DDB6`, `$DDEE`, `$DF60` |
| middle93_2 | `printz2` (Rev A lst), `sub_E09A` (Rev A lst) | `printsmallz`, `printsmall` | named listing names; 93 small font print with control codes. Retail `$E070`, `$E082` |
| middle93_2 | `sub_E284`, `sub_E2B4`, `sub_E318` (Rev A lst) | `FormatAndPrintTime`, `PushTime`, `PushNumber` | named listing names (92 names for the last two); retail `$E26C`, `$E29C`, `$E300` |
| middle93_2 | `pushnumber` (Rev A lst `DeterStrLength?`) | `PushNumberWidth` | SNASM is case-insensitive, clashes with `PushNumber`; d1 digit right-justified number. Retail `$E334` (stats93 stub already used this name) |
| middle93_2 | `_copybackwardloop1`, `_copybackwardsreverseloop1` | `CopyBackwardRun`, `CopyBackwardReverseRun` | IDA pseudo-locals branched to from other `Opcode_*` handlers, so they must be global. Retail `$DE7C`, `$DF0A` |
| middle93_2 | `sub_E15C`, `sub_E170`, `sub_E180`, `loc_E18E` (Rev A lst) | `ControlCode_SetMap`, `ControlCode_SetAttribute`, `ControlCode_SetX`, `ControlCode_SetY` | named listing names; `ControlCodeJumpTable` targets. Retail `$E144`, `$E158`, `$E168`, `$E176` |
| middle93_2 | (none, Rev A `$E19C`, `$E1AA`, `$E1B8`) | `ControlCode_AddX`, `ControlCode_AddY`, `ControlCode_SetFont` | unnamed `ControlCodeJumpTable` targets (codes -5/-6/-7), named from behaviour. Retail `$E184`, `$E192`, `$E1A0` |
| middle93_2 | (none, Rev A `$E128`, `$E2A4`) | `ControlCodeJumpTable`, `PeriodLabelTable` | named listing names for data; `movea.l #$E128`/`#$E2A4` are now `#ControlCodeJumpTable`/`#PeriodLabelTable` (retail `$E110`/`$E28C`) |
| middle93_2 | `Framer_tbline`, `Framer_setter`, `printbig_dochar`, `printbig_dump` | `Framer .tbline .setter`, `printbig .dochar .dump` (locals) | 92 locals; only called inside their parent |
| middle93_2 | `_00`, `_01`, `_02`, `_loop1`, `_loop2`, `_decompress`, `_enddecompression`, `main_bytecode_intepreter_loop`, `Copy_bytes_loop`, `Clear_bytes_loop`, `Fill_bytes_loop`, `loop_for_count*`, `_copybackwardloop2`, `_copybackwardcheckbuffer`, `_copybackwardsreverseloop2`, `_chkbuf`, `_copybackwardsreversemedium_end`, `_checksize`, `_nocallback`, `_done`, `_mtop`, `_tblp`, `loc_*` | 92 local names (`.00`, `.01`, `.02`, `.loop1`, `.loop2`, `.0`, `.1`, `.2`, `.3`, `.4`, `.ex`, `.mtop`, `.tblp`, `.nocom`, `.noblank`, `.p`, `.noz`, `.p0`, `.p1`) or short names (`.packed`, `.done`, `.loop`, `.next`, `.fin`, `.size`, `.dma`, `.skip`, `.mul`, `.pw`, `.dig`, `.digit`, `.put`, `.even`) | branch targets; IDA comment on each line |
| penalty93_1 | `limitfo_lf` | `limitfo .lf` (local) | 92 local; only caller is `limitfo` |
| penalty93_1 | `updatepwrplay_clr` | `updatepwrplay .clrpwrplay` (local) | 92 local; only referenced inside `updatepwrplay` |
| penalty93_1 | `CheckAndReleasePlayer`, `process_next_player`, `continue_if_time_greater_than_zero`, `handle_coincidental_penalty`, `loc_ECFC`, `loc_ED16`, `loc_ED1E`, `loc_ED40`, `loc_ED66` | `ProcessPenaltyList .chk .next .cont .coinpen .done .n1 .two .snd .clr` (locals) | only referenced inside `ProcessPenaltyList`; `.coinpen` sits after `.chk` and branches back to `.next`, so they must share one scope. `.snd`/`.coinpen` are 92 `updatepentime` local names |
| penalty93_1 | `shift_entries` | `RemovePlayerFromList .shift` (local) | branch target |
| penalty93_1 | `coinsearch` | (kept) | IDA name kept; 93 body is the 92 `InProgress .ap` job (sets tmap), not 92 `coinsearch` (inlined in 93 `InProgress` as `.ctop`) |
| penalty93_1 | `loc_*`, `_top`, `_0`-`_3`, `_Sa`, `_sa2`, `_exit`, `_ex`, `_next`, `_iscalled`, `_callit`, `_dc`, `_noticing`, `_skipfo`, `_sx`, `_clearit`, `loop` | 92 local names (`.snd`, `.0`-`.4`, `.noplayer`, `.top`, `.Sa`, `.sa1`, `.sa2`, `.exit`, `.ex`, `.nap`, `.next`, `.iscalled`, `.callit`, `.dc`, `.noticing`, `.skipfo`, `.loop`, `.sx`, `.pr`, `.clearit`, `.noblank`, `.nb0`, `.nb1`, `.hor`, `.gin`, `.t0`, `.upp`, `.uppt`, `.p`) or short names (`.nosnd`, `.find`, `.full`, `.st`, `.ctop`, `.nocoin`, `.pl`, `.m1`, `.cl`, `.t2`, `.t3`) | branch targets; IDA comment on each line. IDA `loc_EA08` (xref from stats93 string bytes, not code) has no label |
| penalty93_2 | `DrawEASNLogo` | `EASNLogo` | 92 name; same pwrplay check, `$BF,1,$19` string and easn.map bitmap. Retail `$F0CA` (penalty93_1 stub still says `DrawEASNLogo`) |
| penalty93_2 | `loc_F0F6` | `DrawEASNMap` | auto name entered from stats93 `ShowScores` (`jsr (loc_F0F6).l`), so global; named from behaviour. Retail `$F0DE` |
| penalty93_2 | `PrintTeamLogoAndScore?`, `pplpen?` | `PrintTeamLogoAndScore`, `pplpen` | `?` is not a valid SNASM symbol character; `pplpen` is the 92 name (penalty box time line for `USBoard .dispen`) |
| penalty93_2 | `restoreteams` (Rev A `$F31E`) | `SetupTeamForIntermission .r` (local) | not 92 `restoreteams` (that is hockey93_01's, IDA `InitTeamShots`); only caller is `SetupTeamForIntermission` (bsr + fall-through), same shape as 92 `restoreteams .r` |
| penalty93_2 | `USBoard_dispen`, `SetScore_getscore`, `sctab`, `NewTicker3_tn`, `_sslist` | `USBoard .dispen`, `SetScore .getscore .sctab`, `NewTicker3 .tn`, `Intermission .sslist` (locals) | 92 locals; only referenced by their parent |
| penalty93_2 | `dobar` | `linebar .ok` (local) | IDA put the 92 name on a branch target inside `linebar`; 92 `dobar` is a separate routine. 92 `dobar .ok` is the same clamp |
| penalty93_2 | `SetupTeamForReplay`, `StartHL2_ndi`, `StartHL2_ranres`, `StartHL2_sv`, `StartHL2_sv1`, `StartHL2_lo`, `StartHL2_lo1`, `_postab`, `exit`, `exit2` | `StartHL2 .setteam .ndi .ranres .sv .sv1 .lo .lo1 .postab .exit .exit2` (locals) | 92 `StartHL2` locals; `SetupTeamForReplay` (93 split, only called from `StartHL2`) sits between `.nhl0` and `.ranres`, so it has to share the scope |
| penalty93_2 | `loc_*`, `_0`, `_1`, `_ss`, `_top`, `_next` | 92 local names (`.ex`, `.sbscreen`, `.loop`, `.next`, `.l0`, `.0`, `.1`, `.top`, `.clrh`, `.doh`, `.clrz`, `.ss`, `.ploop`, `.pl0`, `.eh`, `.endhl`, `.nhl0`, `.nhl1`, `.rr0`) or short names (`.l1`, `.p2`, `.l2`, `.find`, `.nb`, `.wait`, `.gl`, `.clr`) | branch targets; IDA comment on each line |
| hockey93_03 | `checkint_ci` | `checkint .ci` (local) | 92 local; only callers are `checkint+2` / `+8` |
| hockey93_03 | `CC` | `checkcheck .cc` (local) | 92 local; only callers are `checkcheck+4` / `+A`. It branches out to the globals `holdcheck` and `Bcheck` |
| hockey93_03 | `list` | `checkcheck .list` (local) | 92 `.cc` table of check anims; `lea .list(pc),a0` is the only reference |
| hockey93_03 | `loc_FFFE` (Rev A) | (no label) | only xref is dopass `cmp.l #$10000,d0`, a constant, not a branch |
| hockey93_03 | `checkagr`, `Bcheck`, `setInjuryType` | (kept) | 93 only, no 92 routine; IDA names. No earlier segment defines them (`setInjuryType` is only a logic93_2 stub) |
| hockey93_03 | `loc_*`, `locret_FC66`, `_exit`, `_nofight`, `_0`, `_00`, `_down`, `_dn2`, `_3` | 92 local names (`.nhor1`, `.xx`, `.ex`, `.2`, `.cl2`, `.3`, `.ex2`, `.restoreold`, `.0`, `.cl`, `.1`, `.nhor`, `.g40`, `.if`, `.if2`, `.nc`, `.n1`, `.not`, `.exit`, `.exit4`, `.nofight`, `.down`, `.dn2`) or short names (`.pc`, `.00`, `.nojoy`, `.far`, `.nopc`, `.h2`, `.pen`, `.dir`, `.fall`, `.tm`, `.nostat`, `.snd`) | branch targets; IDA comment on each line |
| hockey93_04 | `checkfight_sf` | `checkfight .sf` (local) | 92 local; only callers are `checkfight+10A` / `+110` |
| hockey93_04 | `ResetTeamPlayerAssignments` | `Goal .setass` (local) | 92 local, same loop; only caller is `Goal` (IDA `checkgoal+270`) |
| hockey93_04 | `checkgoalp` | (kept) | IDA and 92 name, same body. Collided with logic93_1's `checkgoalp` (its rename of `checkgoalp_CalcGoalShotDir`); logic93_1 was reverted to the IDA name and re-verified |
| hockey93_04 | `SetInst`, `checkwallcoll`, `checkgoal`, `Goal`, `CheckBump`, `wallcollb`, `wallcoll`, `checkpuckcoll`, `GetPeriodTimeRemaining` | (kept) | IDA names (92 names, except the 93-only `GetPeriodTimeRemaining`). 93 `SetInst` adds the fight rating test in front of the 92 instigator penalty |
| hockey93_04 | `loc_*`, `_cont`, `_loop`, `_o1`, `_playerloop`, `_endloop`, `_resetYvel`, `_setup`, other `_x` | 92 local names (`.1`, `.next`, `.nod`, `.an`, `.nocon`, `.0`, `.deflectsf`, `.df0`, `.deflectz`, `.sideentry`, `.g0`, `.g1`, `.nocheer`, `.loop`, `.nl`, `.ctc`, `.circle`, `.exit`, `.ex`, `.bb`, `.player`, `.nocoll`, `.pok`, `.sf0`, `.nosfx`, `.noadd`, `.cl`, `.ccx`, `.lo`, `.chkbody`, `.chkgoalie`) or short names (`.pos`, `.clr`, `.tm`, `.snd`, `.sum`, `.home`, `.noast`, `.pen`, `.clrvy`, `.chkz`) | branch targets; IDA comment on each renamed line |
| hockey93_05 | `loc_10F8A` | `puckglue` | auto name; 92 `puckstick .glue` (player takes the puck). Global because `puckgoalie .nopc` also branches to it. Retail `$10F72` |
| hockey93_05 | `ResetBench_rb` | `ResetBench .rb` (local) | 92 local; only caller is `ResetBench+A` (bsr + fall-through) |
| hockey93_05 | `puckstick`, `setd0player`, `puckbody`, `rtss`, `puckgoalie`, `deflect`, `makepde`, `getpde`, `setpde`, `setpersonel`, `SetPlList`, `forcepldata`, `ResetBench`, `Setplass`, `setplayer` | (kept) | IDA and 92 names, same routines |
| hockey93_05 | `TryAddPlayerToList`, `ClampNibble` | (kept) | 93 only, IDA names. `TryAddPlayerToList` is the 92 `SetPlList .s1`/`.s2` test split out; `ClampNibble` clamps `setplayer`'s attribute nibbles |
| hockey93_05 | `_list`, `_list2`, `_alist`, `_1`-`_3`, `_setsfx`, `_l0`, `_gin`, `_0`, `_next`, `_next1`, `_s1`, `_top`, `_notnear`, `_rb1`, `_da`, `_nda`, `_nda2`, `_nda3` | 92 local names (`.list`, `.list2`, `.alist`, `.1`-`.3`, `.setsfx`, `.l0`, `.gin`, `.0`, `.next`, `.next1`, `.s1`, `.top`, `.notnear`, `.rb1`, `.da`, `.nda`, `.nda2`, `.nda3`) | IDA pseudo-locals |
| hockey93_05 | `loc_*`, `locret_11818` | 92 local names (`.0`, `.steal`, `.stdef`, `.nosteal`, `.1`, `.hit`, `.3`, `.4`, `.next2`, `.s2`, `.ha`) or short names (`.spd`, `.nohand`, `.tm`, `.snd`, `.nrec`, `.slow`, `.song`, `.nosong`, `.bounce`, `.nopc`, `.chkpos`, `.sub`, `.all`, `.try`, `.no`, `.nopen`, `.score`, `.side`, `.close`, `.nomod`, `.find`, `.hi`, `.x`) | branch targets; IDA comment on each renamed line |
| video93_1 | `VBlank_org` | `VBlank` | 92 name, same body (game play vblank handler stored in `vbint`). Not `VBjsr`, the hockey93_01 vector stub. Retail `$11802` |
| video93_1 | `DoScroller` | `SetScroll2` | body is 92 `SetScroll2` (Hscroll / Vscroll to the vdp); 92 `DoScroller` also did the `tempmap` transfers, which 93 dropped. Only caller is `DumpSprites`. Retail `$118D6` |
| video93_1 | `showcrowd_pb`, `showcrowd_sc` | `showcrowd .pb .sc` (locals) | 92 locals; only callers are `showcrowd` and `.pb` |
| video93_1 | `unk_11B8C` | `showzam .ftab` (local) | 93-only frame table; `movea.l #unk_11B8C` is now `#.ftab` (retail `$11B74`) |
| video93_1 | `vb2`, `IRQ7`, `DumpSprites`, `DumpSprites2`, `DoDMAList`, `setvideo`, `show_rink`, `showref`, `checkfo`, `checkfo2`, `showzam`, `SetSframe`, `showcrowd` | (kept) | IDA and 92 names (`DoDMAList` is 92 `dodmalist`, case only). `IRQ7` is a lone `rte` that `vb2` falls into, not 92 `VBcount`. `show_rink` does the 92 `updatescroll` job through the dma list, so the IDA name stays |
| video93_1 | `_01`, `_nograph`, `_c`, `_0`, `_p`, `_n`, `_sloop`, `_noxflip`, `_next`, `_v`, `_pb0`, `_pbt`, `_nextpb`, `_loop`, `write_sprite_piece`, `exit_sprite_write`, `loc_*` | 92 local names (`.01`, `.nograph`, `.c`, `.0`-`.2`, `.p`, `.n`, `.sd`, `.su`, `.top`, `.sloop`, `.noxflip`, `.next`, `.v`, `.pb0`, `.pbt`, `.nextpb`, `.loop`, `.ex`) or short names (`.pos`, `.get`, `.chk`) | IDA pseudo-locals / branch targets; IDA comment on each renamed line |
| video93_2 | `showclock_char` | `showclock .char` (local) | 92 local, same digit-to-tile body; only caller is `showclock` |
| video93_2 | `checksso_ca`, `_tab` | `checksso .ca .tab` (locals) | 92 locals, same off-screen arrow body and table; only callers are `checksso+16` and the fall-through from `checksso` |
| video93_2 | `showclock`, `checksso`, `setsortcords`, `setffo`, `uppads`, `addframe`, `addframe2`, `find3d`, `updatesound`, `KillCrowd` | (kept) | IDA and 92 names, same routines (93 `checksso` returns in sfhor mode, 93 `uppads` handles 4 pads from `PadControlBits` nibbles) |
| video93_2 | `FormatControllerDisplay`, `RenderSmallFontChar`, `ButtonLabelCharTable` | (kept) | 93 only, IDA names. `RenderSmallFontChar` does the 92 `uppads .pd` job but is entered by fall-through from `FormatControllerDisplay`. `ButtonLabelCharTable` pad byte is `$10` in retail |
| video93_2 | `_0`, `_cv`, `_nhor`, `_hord`, `_0`-`_5`, `_sloop`, `_nn`, `_nodup`, `_dup`, `_noref`, `_noyflip`, `_noxflip`, `_nospec`, `_exit`, `loc_*` | 92 local names (`.0`, `.cv`, `.nhor`, `.hord`, `.0`-`.5`, `.top`, `.nogloves`, `.next`, `.exit`, `.sloop`, `.nn`, `.nodup`, `.dup`, `.noref`, `.noyflip`, `.noxflip`, `.nospec`, `.crange`, `.offscr`, `.ip`, `.iasv`, `.non`) or short names (`.chg`, `.hi`, `.lo`, `.btn`) | IDA pseudo-locals / branch targets; IDA comment on each renamed line |
| hockey93_06 | `_sp` | `IntermissionStart` | IDA pseudo-local at 92 `PeriodOver .sp` (jsr ResetClock); global because StartGame jumps to it (hockey93_01 stub still says `_sp`). Retail `$129B4` |
| hockey93_06 | `loc_129FC` | `GameOver` | 92 name; same EncodePW / PlayoffScreen game over path, global as in 92. Retail `$129E4` |
| hockey93_06 | `loc_12A16` | `ExitToOpening` | auto name; song `$35` then Opening2. Global because HandleJoy1 jumps to it (hockey93_01 stub still says `loc_12a16`). Retail `$129FE` |
| hockey93_06 | `loc_12CFA` | `PlayoffScreenExit` | 92 `PlayoffScreen .exit`; global because HandlePlayoffInput reaches it across the UpdatePlayoffScroll global. Retail `$12CE2` |
| hockey93_06 | `resetplstuff_top`, `resetplstuff_loop`, `resetplstuff_next` | `resetplstuff .top .loop .next` (locals) | 92 locals; only callers are `resetplstuff+8` / `+10` |
| hockey93_06 | `setplayercolors_sp`, `setplayercolors_s` | `setplayercolors .sp .5` (locals) | 92 locals; only callers are `setplayercolors+6` and the fall-through |
| hockey93_06 | `locret_124F8` | (no label) | only xref is `addi.l #locret_124F8,(a4)` in CalculateTeamAttributeValues, a constant, not a branch (the retail rts is `$124E0`) |
| hockey93_06 | `_ssotop`, `_ffotop`, `_listsso`, `_listffo`, `_list`, `_nop`, `_0`, `_1` | `defaultsprites .ssotop .ffotop .listsso .listffo`, `defaultsprites2 .list`, `PeriodOver .nop .0`, `IntermissionStart .1` (locals) | IDA pseudo-locals; 92 names where 92 has them |
| hockey93_06 | `setupice`, `defaultsprites`, `SprSort`, `resetplstuff`, `setteams`, `setplayercolors`, `PeriodOver`, `Opening`, `Opening2`, `PlayoffScreen` | (kept) | IDA and 92 names, same routines |
| hockey93_06 | `setupice_highlight`, `setupIceRinkMap`, `setupEASNmap`, `setupTeamBlocksMap`, `CopyTeamBlockMapData`, `defaultsprites2`, `clearTeamStats`, `InitTeamSructure`, `HandlePlayoffInput`, `UpdatePlayoffScroll`, `PlayoffScreen_waitvsync`, `FormatScore`, `DrawPlayoffBracket`, `DrawTeamBlocks`, `PlayoffScreenDataTable`, `PlayoffScreenText` | (kept) | 93 only or 93 splits, IDA names. `setupIceRinkMap` is 92 `setupice .ipal`, `defaultsprites2` is 92 `defaultsprites .0`, `clearTeamStats` is the 92 `setteams` clear loop, `FormatScore` / `DrawPlayoffBracket` / `DrawTeamBlocks` are 92 `PlayoffScreen .doscores .doarrow .doteam` (global because they sit after other globals). `PlayoffScreenDataTable` is the playoff vblank handler |
| hockey93_06 | `loc_*` | 92 local names (`.l01`, `.gok`, `.ipal`, `.0`, `.1`, `.loop0`, `.loop`, `.po`, `.top`, `.top2`, `.top3`, `.noscr`, `.input`) or short names (`.row`, `.copy`, `.pal`, `.nopage`, `.nr`, `.lim`, `.nox`, `.wait`, `.nohi`) | branch targets; IDA comment on each renamed line |
| hockey93_07 | `loc_13064` | `StatNextLine` | auto name inside `PrintStatNumber` (`addq.w #1,printy`), global because `DisplayCombinedStats` branches to it across the `PrintStatNumber` global. Retail `$1304C` |
| hockey93_07 | `loc_133EE` | `VBlank_StanleyCup` | auto name; vbint handler stored by `SetupStanleyCupCelebrationScreen` (`move.l #x,(vbint).l`), after another global. Retail `$133D6` |
| hockey93_07 | `unk_13422` | `StanleyCupPosTable` | data auto name; bitmap/sprite column,row table used by `SetupStanleyCupCelebrationScreen` and `UpdateStanleyCupAnimation` (`lea x(pc)`). Retail `$1340A` |
| hockey93_07 | `loc_1369C` | `TitleAnimCallback` | auto name; the `CallAnimationCallback` routine loaded by `TitleScreen_wait` (`lea x(pc),a0`), after other globals. Retail `$13684` |
| hockey93_07 | `loc_13876` | `EndSpriteList` | auto name; 92 `setvideo` sprite list close (`cmp #Satt,a6` ... `move d0,Sattsize`). Global because `UpdateStanleyCupAnimation` branches to it inside `CallAnimationCallback`. Retail `$1385E` |
| hockey93_07 | (none, Rev A `$138D6`, IDA `dc.b`) | `CheckSound` | unreferenced sound test after `FinalizeSpriteList` (prints "Check Sound", plays `sfx` d6); named from behaviour. Retail `$138BE` |
| hockey93_07 | `TitleScreen_top4`, `_top4x` | `TitleScreen .top4 .top4x` (locals) | 92 `TitleScreen .top4 .top4x` (erase and print the next credits block); only caller is `TitleScreen`, no global in between |
| hockey93_07 | `ScoutingReport`, `TitleScreen`, `DisplayPlayerStats`, `DisplayCombinedStats`, `PrintStatNumber`, `StatsText`, `InitScoutingDisplay`, `UpdateScoutingDisplay`, `ScrollDisplayUp`, `SetupStanleyCupCelebrationScreen`, `UpdateStanleyCupAnimation`, `TitleData1`, `TitleData2`, `UpdateHorizontalScroll`, `TitleScreen_wait`, `VBlank_TitleScreen`, `CallAnimationCallback`, `FinalizeSpriteList` | (kept) | IDA names (`ScoutingReport` and `TitleScreen` are also the 92 names; the 93 bodies are rewritten). `TitleScreen_wait` is 92 `TitleScreen .wait` but sits after other globals. No earlier segment defines them |
| hockey93_07 | `_tops0`, `_top1`, `_tops`, `_top2`, `_top5`, `_top6`, `loc_*`, `locret_137DE` | 92 local names (`.top1`, `.tops`, `.top2`, `.top5`, `.top6`, `.pl`, `.wait`, `.0`, `.n`) or short names (`.tops0`, `.same`, `.top`, `.upd`, `.loop`, `.next`, `.go`, `.cont`, `.para`, `.find`, `.cnt`, `.word`, `.copy`, `.pause`, `.nopause`, `.eol`, `.even`, `.print`, `.noscr`, `.awtm`, `.hmtm`, `.team`, `.pn`, `.away`, `.under`, `.home`, `.tname`, `.name`, `.clr`, `.ex`, `.nos`, `.x`, `.chk`, `.rev`, `.1`) | branch targets; IDA comment on each renamed line |
| hockey93_08 | `setoptions_updateoptionvalue`, `setoptions_clampoptionvalue`, `setoptions_updatealloptions`, `setoptions_displayoptionvalue`, `setoptions_navigate`, `setoptions_printpos` | `setoptions .IncItem .iilimit .ps .psd .nms .setrect` (locals) | 92 `setoptions` locals, same jobs; only referenced inside `setoptions`, no global in between |
| hockey93_08 | `MaxValuesTable`, `OptionsTextOffsetTable`, `MenuTextData` | `setoptions .pslim .pl .text` (locals) | 92 locals (limits, item names, static text); `movea.l #x` are now `#.pslim` / `#.pl` / `#.text`. The `.pl` offsets are label differences |
| hockey93_08 | `loc_13EE8` | `TeamIcons` | 92 name; same team name bars + setteams + palcount job, global as in 92 (branched to from `setoptions .ps`). Retail `$13ED0` |
| hockey93_08 | `DisplayTeamBlock` | `dotb` | 92 name; 92 `TeamIcons` calls `dotb`, 93 `TeamIcons` calls this (team d1 bar from TeamBlocksmap via dobitmap). Retail `$13F1C` (hockey93_07 stub still says `DisplayTeamBlock`) |
| hockey93_08 | `loc_14120` | `SetupNextPlayer` | auto name branched to from `UpdateTeamNameAnimation` across the `ClearAndSetFlag` global; named from behaviour (palette, next roster slot, animation script). Retail `$14108` |
| hockey93_08 | `loc_143EC` | `VBlank_SetOptions` | auto name; vbint handler stored by `setoptions` (`move.l #x,(vbint).l`): 92 `vb2` plus `DumpSprites2`. Retail `$143D4` |
| hockey93_08 | `UpdatePlayoffLevel`, `ClearOptionDisplay`, `setoptions_printpos2`, `UpdateTeamNameisplay`, `UpdateBothTeamDisplays`, `UpdateTeamNameAnimation`, `ClearAndSetFlag`, `ValidateCharacterNibbles`, `GetTeamNamePtr`, `CharacterValidationTable`, `AltCharValidationTable`, `TeamNameAnimationTable`, `RosterOrderTable`, `UpdateTeamSprites`, `AddTeamSpriteFrame` | (kept) | 93 only, IDA names (`UpdateTeamNameisplay` keeps the IDA spelling; it picks the goalie, header says so). No earlier segment defines them |
| hockey93_08 | `loc_*` | 92 local names (`.textlp`, `.nopo`, `.top`, `.ex`, `.nd`, `.2`, `.3`, `.4`, `.ii0`, `.ii1`, `.iil1`, `.pstop`, `.psd3`, `.psdtp`, `.nms0`-`.nms4`, `.0`, `.nograph`) or short names (`.keep`, `.notree`, `.wait`, `.npo`, `.set`, `.x`, `.same`, `.in`, `.anim`, `.trim`, `.even`, `.ln2`, `.pal`, `.next`, `.got`, `.pn`, `.r`, `.nib`, `.cnt`, `.n`, `.fade`, `.s0`-`.s7`) | branch targets; IDA comment on each renamed line |
| hockey93_09 | `SelectRandomPlayoffTree` | (kept) | body is 92 `NewPO` (random tree holding team 1, clear series wins, falls into MakeTree). The name `NewPO` is already the IDA name of a different routine here, and hockey93_08 calls both by their IDA names, so the IDA name stays. Retail `$1445A` |
| hockey93_09 | `NewPO` | (kept) | IDA name; 93 continue-playoffs reload (ReadPassBits, maketree, playofflevel), the job 92 `GameOver` does with `DecodePW` + `MakeTree`. Not 92 `NewPO`. Retail `$1442E` |
| hockey93_09 | `SetGameTeamOrder`, `_flip` | `maketree .sett .flip` (locals) | 92 `MakeTree .sett .flip`, same body; only caller is `maketree`, no global in between |
| hockey93_09 | `EncodeValueToPassword` | `PushBits` | 92 name, same body (`exg d0,d1`, SuperMult, SuperAdd). Retail `$1481C` |
| hockey93_09 | `ResetPassWord` | `ClrPassBits` | 92 `ClrPassBits` body (clear the bits buffer, 5 words at a3 in 93). Not 92 `ResetPassWord` (password text). Retail `$14834` |
| hockey93_09 | `AddValueToAccumulators` | `SuperAdd` | 92 name, same carry loop (5 words at a3). Retail `$14840` |
| hockey93_09 | `MultiplyValueByWeights` | `SuperMult` | 92 name, same multiply loop (5 words at a3). Retail `$1485C` |
| hockey93_09 | `ReadPassBits__sd` | `SuperDiv` | 92 `SuperDiv` body (divide the bits, d0 = remainder); 92 `ReadPassBits .sd` was the checksum wrapper around it. Global because it sits after other globals. Retail `$14892` |
| hockey93_09 | `DefaultMenus`, `maketree`, `FigureJoy`, `ReadPassBits`, `EncodePW`, `WritePassBits`, `GetShifter` | (kept) | IDA and 92 names, same routines (`maketree` is 92 `MakeTree`, case only). 93 drops the password checksum |
| hockey93_09 | `InitializeGameStructures`, `GetRandomUnusedTeam`, `DisplayTeamStatsForPlayoffs`, `BitWidthTable`, `ReadTeamStats` | (kept) | 93 only, IDA names. `DisplayTeamStatsForPlayoffs` adds the po team's game stats to the packed playoff totals (it does not display); `BitWidthTable` is shared by it and `ReadTeamStats` |
| hockey93_09 | `_1`, `_defom`, `_pojoylist`, `unk_14678`, `_0`, `_nsf0`, `_nsf1`, `_userwon`, `get_team_stats_area`, `accumulate_team_stats`, `loop`, `pack_val_into_bitstream`, `unpack_stats_from_bitstream`, `loc_*` | 92 local names (`.1`, `.defom`, `.top`, `.loop`, `.cg`, `.0`, `.2`, `.nogames`, `.f0`, `.it1`, `.it2`, `.itx`, `.pojoylist`, `.fjnpo`, `.noplist`, `.nsf0`, `.nsf1`, `.userwon`, `.1`, `.3`) or short names (`.ex`, `.init`, `.save`, `.restore`, `.area`, `.acc`, `.pack`) | IDA pseudo-locals / branch targets; IDA comment on each renamed line |

## Out of scope

- `hockey93.asm` and the full-ROM `build:retail` path.
- Rev A, Rev B, Z80, frame extractor, `extractAssets93.js`, NHL 94.
- Touch `extractAssets` only after this segment matches and a later segment is a data table the extractor already owns.
- Any new script, disassembler, or listing generator.
