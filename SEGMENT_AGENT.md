# Segment matching agent

Finish one NHLPA 93 segment so it assembles with SNASM68K and matches the retail ROM bytes. Do not decompile the rest of the ROM.

## Do not write tools

The disassembly already exists. Do not create a disassembler, decoder, listing parser, ROM dumper, or any other tool. Do not add a `.js`, `.py`, or `.md` file for this. `verifySegment.js`, `buildseg.bat`, and `fixopcodes.js` are the only tools, and they already work.

Read the annotated listing and transcribe that range into asm. The named listing is `../EA-NHL-Disassembly-Project/NHL93-Genesis/NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst`. Open it and search for the routine. It has IDA function names, labels, and comments. `nhlpa93retailRevA.lst` in this repo is the same Rev A ROM with exact bytes and mostly auto names. Use it only to confirm bytes. Neither listing has retail addresses. Convert with the delta table in "ROM map", then confirm the bytes in `nhlpa93retail.bin`.

If you cannot find the listing, stop and say so. Do not work around a missing listing by disassembling the ROM yourself.

## Sources of truth, in order

1. Retail ROM bytes. `nhlpa93retail.bin` wins over the listing, the current asm, and NHL 92.
2. IDA names. The v1.1 `.lst` above is the name source for functions, labels, and RAM. It is not an assembler listing. Do not pass it to `fixopcodes.js`. Despite the file name, it was built from Rev A (input MD5 `B6FB2CE2...` = `nhlpa93retailRevA.bin`).
3. Style. `NHL92Genesis/src/hockey.asm`, `ram.asm`, and `macros/` are the style source. Same mnemonics, `equ`, local labels with `.`, and comment density. Do not paste 92 code over 93.
4. Current segment. `src/middle93_2_stub.asm` is `org $DCE4` and includes `src/middle93_2.asm`. The segment is `$DCE4-$E525` (92 Middle.Asm part 2: dobitmap, the 93 tile decompressor DecompressGraphicsWithCallback, DoDMA_clearCallbackPointer, DecompressGraphics, DecompressBytecode, jump_table, Opcode_* handlers, FlushOutputBuffer, then xyVmMap, eraser, Framer, 93 printsmallz/printsmall with ControlCodeJumpTable and ControlCode_* handlers, printz, print, 93 FormatAndPrintTime/PeriodLabelTable, PushTime, PushNumber, 93 PushNumberWidth, appendz, appstring, printbigz, printbig, AddSmallFont, AddFramer, AddTeamBlock; see "ROM map"). RAM names already live in `src/stubinc/ram_addrs.inc`. Include that file. Do not invent a second RAM map.

Do not edit `hockey93_01.asm` (`$6446-$69FF`, 1466 bytes), `menu93.asm` (`$6A00-$6C09`, 522 bytes), `stats93.asm` (`$6C0A-$8AC3`, 7866 bytes), `hockey93_02.asm` (`$8AC4-$946D`, 2474 bytes), `logic93_1.asm` (`$946E-$A0FB`, 3214 bytes), `logic93_2.asm` (`$A0FC-$AE87`, 3468 bytes), `logic93_3.asm` (`$AE88-$BC6B`, 3556 bytes), `logic93_4.asm` (`$BC6C-$C9E9`, 3454 bytes), `logic93_5.asm` (`$C9EA-$D629`, 3136 bytes) or `middle93_1.asm` (`$D62A-$DCE3`, 1722 bytes). They match retail and are done; re-check them with `npm.cmd run seg:01`, `npm.cmd run seg:menu93`, `npm.cmd run seg:stats93`, `npm.cmd run seg:02`, `npm.cmd run seg:logic93_1`, `npm.cmd run seg:logic93_2`, `npm.cmd run seg:logic93_3`, `npm.cmd run seg:logic93_4`, `npm.cmd run seg:logic93_5` and `npm.cmd run seg:middle93_1`. Routines they contain are stubs in later segments, under the source names from the rename table.

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
| hockey93_07 | `$012E26-$013951` | ScoutingReport ... |
| hockey93_08 | `$013952-$014403` | setoptions ... |
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

`hockey93_01` (`$6446-$69FF`), `menu93` (`$6A00-$6C09`), `stats93` (`$6C0A-$8AC3`), `hockey93_02` (`$8AC4-$946D`), `logic93_1` (`$946E-$A0FB`), `logic93_2` (`$A0FC-$AE87`), `logic93_3` (`$AE88-$BC6B`), `logic93_4` (`$BC6C-$C9E9`), `logic93_5` (`$C9EA-$D629`) and `middle93_1` (`$D62A-$DCE3`) matched. logic93_3 note: retail has `exg a2,a1` as `C549`; SNASM swaps address-register operands and emits `C34A`, so that one is `dc.w $C549`. stats93 notes: RAM from about `$FFCAxx` is 4 bytes lower in retail than in `ram_addrs.inc` (Rev A); databuffer is `$CAEE` retail vs `$CAF2`, written as a number with a `;retail databuffer (Rev A: $CAF2)` comment. The notes below in "Loop" use hockey93_01 as the worked example.

Original failure, kept for reference: `verifySegment.js` reported `1022 of 1138` bytes differ in `$6446-$68B7`. At `$6460` the ROM is `4E B9` (`jsr abs.l`) and the stub assembled `30 39` (`move.w abs.l`). The old `hockey93_01.asm` was a Rev A disassembly dump. It was rewritten from the retail bytes.

`Stack` is `$FFFFFFFE` in the IDB export. Do not use the `$FFFFF6` equate from `main93.asm`.

IDA addresses drift from retail (the listing is Rev A; see "ROM map"). In the named `.lst`, auto labels from `Pausemode` ($6904) on are `$E` higher than the retail bytes (IDA `loc_693E` is retail `$6930`), and far targets drift too (IDA `loc_12A16` is retail `$129FE`, IDA `loc_14D36` is retail `$14D1E`). Take every stub address and branch target from the ROM bytes. Keep the IDA name and note the retail address in the stub comment.

## Loop

1. Read `DECOMPILATION_LEARNINGS.md` and this file.
2. Open the v1.1 `.lst` and read only the current segment. Transcribe those named instructions. Do not disassemble the ROM. Use `nhlpa93retail.bin` only to check bytes and to fix addresses with the delta table.
3. Rewrite the current segment asm in NHL 92 style. Stub external calls that are outside this range. Do not follow those calls.
4. Run `npm run seg`.
5. If the mismatch is only a known EA `cmp` / `exg` encoding, write that instruction as `dc.w` with the real instruction in the comment (what `hockey93_01` does), because `npm run seg` checks raw assembler output. Do not rewrite `exg d0,d1`. The `0C80` to `B0BC` rule only applies where the ROM byte is `B0BC`.
6. Stop after 5 failed verifies. Write the first remaining mismatch and what the ROM bytes are. Do not keep editing.

A match prints `MATCH: middle93_2 confirmed 2114 bytes at 0x00dce4-0x00e525`. The byte count must equal the ROM map range. Commit only that.

## Comments and labels

Do this after the bytes match. Run `npm run seg` again afterward; renaming and comments must not change a byte.

Comments:

- Find the matching NHL 92 routine in `NHL92Genesis/src/hockey.asm` (or the file it lives in) and copy its comments onto the instructions that do the same thing in 93.
- Where 92 uses a symbolic constant (`gmclock`, `sfhor`, `pfjoycon`, `SCstruct`, `PenEOG`, ...), check the 92 value in `ram.asm` / the 92 `.lst`. If the 93 byte is the same, put the 92 name in the comment (`bset #0,(gmode).w ;gmclock`). If the value differs, say so (`;horn (92 SFXhorn = 24)`). Do not add 92 equates to the 93 build.
- 93-only code gets a short factual comment from what the bytes do. Do not guess game meaning you cannot see in the code.
- Mark retail-vs-Rev A differences inline (`;retail clear end (Rev A: $CDF4)`).
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
| logic93_1 | `checkgoalp_CalcGoalShotDir` | `checkgoalp` | 93-only aim-at-open-side helper for `doshot` |
| logic93_1 | `loc_949C`, `_nhor`, `loc_9516`, `loc_952C`, `loc_9564` | `doinput .0 .nhor .ispc .pc1 .islocked` (locals) | branch targets inside `doinput` |
| logic93_1 | `_noa`, `_0`, `_1`, `_ind` | `fightinput .noa .0 .1 .ind` (locals) | IDA pseudo-locals |
| logic93_1 | `unk_97A2` | `getlchoice .tab` (local) | line choice table, 21 rows of 3 + pad byte |
| logic93_1 | `CalcPassTime`, `ClampPassTime`, `ClampPassTime2`, `CalcPuckVelocities` | `passtoa0 .0 .1 .2 .3` (locals) | branch targets inside `passtoa0` |
| logic93_1 | `t1_CheckPlayers`, `top_CheckPlayerLoop`, `next_SkipPlayer`, `ex_CheckSweep` | `changeplayer .t1 .top .next .ex` (locals) | `.ex` is pushed with `pea (.ex).l` |
| logic93_1 | `ReleaseOldPlayer`, `spd_SetNewPlayer` | `restorepl .rel .spd` (locals) | branch targets |
| logic93_1 | `_ck0_CalcShotToGoal`, `_ck1_SetShotAnim` | `SetShotMode .ck0 .ck1` (locals) | IDA put them under `Findhittype` |
| logic93_1 | `ShotMode_ss0`, `CheckCButton`, `ReverseShot` | `ShotMode .ss0 .cb .rev` (locals) | branch targets |
| logic93_1 | `doshot_nbh` ... `doshot_ex`, `ClampPenalty`, `AddRandomError`, `AddYError`, `AddMoreRandom`, `shotsets` | `doshot .nbh .c .0 .1 .notperf .cp .ar .ay .am .perf .noup .ex .shotsets` (locals) | 92 `doshot` locals plus the 93 crowd-bonus branch |
| logic93_1 | `CheckOpponentGoalie`, `CalcLeftAngle`, `SetShotDirection`, `ReturnDefaultDir` | `checkgoalp .g .l .s .x` (locals) | branch targets |
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

## Out of scope

- `hockey93.asm` and the full-ROM `build:retail` path.
- Rev A, Rev B, Z80, frame extractor, `extractAssets93.js`, NHL 94.
- Touch `extractAssets` only after this segment matches and a later segment is a data table the extractor already owns.
- Any new script, disassembler, or listing generator.
