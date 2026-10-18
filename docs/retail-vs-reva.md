# Rev 0 (REV=0) vs Rev A (REV=1) vs Rev B (REV=2)

How the three shipped versions of the ROM differ, and what the `REV` build flag changes in the source.

All three build from the same source (`IF REV=...` blocks). The revisions are numbered `REV=0` = Rev 0 = v1.0, `REV=1` = Rev A = v1.1 and `REV=2` = Rev B = v1.2. Rev 0 is the ROM called "retail" in the file and build mode names (`nhlpa93retail.bin`, `build:retail`); it is `1992.JUL` version `-00`. Rev A is `1992.OCT` version `-01` (`build:reva`). Rev B is `1993.FEB` version `-00` (`node tools/build.js revb`). `tools/verify_all.sh` builds and checks all three. Rev B contains everything from Rev A (the source tests `REV>=1` for those parts).

## Overall Differences Between Rev 0 (REV=0) and Rev A (REV=1)
- Rev A supports 50 Hz: `Begin` stores the VDP PAL bit in `music_global_tick_counter`. When it is set, `updateplayers` moves skaters 20 units per frame instead of 16, and `p_music_vblank` runs the music track slots a second time every 6th frame.
- Rev A adds two RAM words (`music_global_tick_counter`, `music_tick_divider`) before `databuffer`, so every variable from `databuffer` up is 4 bytes higher (`ram93.asm` handles it).
- Rev 0 has a `SecurityCheck` `$FFFF` word before `ValidationRoutine`; Rev A does not. The checksums differ (header `$2799` / `$FA57`, ROM sum `$EB689746` / `$C62A6024`).

## Specific Differences and Comments (Rev 0 vs Rev A)
- Header: Rev A writes the title `NHLPA HOCKEY '93` in capitals.
- Code addresses move by +`$E` after `Begin`, +`$18` after `updateplayers` and +`$2E` after `p_music_vblank`. The source uses labels, so the moves are automatic, including the sound data's absolute pointers (PCM sample table, song loop pointers, the Z80 driver's FM patch bank address).
- Pad bytes: Rev 0 has leftover values in 11 pad bytes (`Setplass .alist`, `ButtonLabelCharTable`, `bfasciicon`, `priolist`, `PlayoffTreeSetup`, the Z80 driver end, four PCM sample ends and the scouting text end); Rev A has 0.

## Overall Differences Between Rev A (REV=1) and Rev B (REV=2)

EA changed the EASN branding to EA Sports in this version and reworked parts of the engine. About 96% of the bytes of Rev A are found in Rev B, shifted by a few bytes here and there. The reasons given below are read from the code, not documented anywhere.

- **EA Sports replaces EASN.**
  - The pictures are `EASports.map.jim` (the logo, `EASportsMap`, which `EASNmap` is an alias of) and `EASports2.map.jim` (`EASportsMap2`). The five EASN bitmaps and the spinning EASN animation (`EASN.anim`, `SpinningEASN`) are gone, so the Stanley Cup screen draws one EA Sports picture and does not animate. Its vblank handler is `vb2`.
  - The EASN logo is not drawn on the Scores screen, and the "Scores" title moved up.
  - The ticker title is `EA Hockey Night`.
  - The pictures that carried the branding are recompressed and have different sizes: Scouting, IceRink, Zam, GameSetup, Title3, TitleLogo and the player, crowd and face off sprite sheets. `tools/extractAssets93.js` has the Rev B slices (`REVB_SLICES`) and `tools/prebuild.js` extracts again when a build switches between Rev B and the other two.
- **Controllers are read in the vblank.** `ReadPads` runs at the start of `p_music_vblank` with the Z80 bus held and leaves the raw bytes in `PadRaw1` and `PadRaw2` (two new RAM bytes before `disflags`, so every variable from there up is 2 bytes higher than in Rev A). `ReadJoy1` and `ReadJoy2` only translate them; `ReadJoy` no longer touches the hardware. In Rev 0 and Rev A they read the pads directly.
- **DMA and the Z80 bus.** `DoDMA`, `DoDMA_nd2` and `DoFill` write the VDP command from RAM with interrupts off and the Z80 bus held, and a DMA from a RAM source writes its first word by hand (the DMA loses it). The sound driver waits for the Z80 to grant the bus after each bus request (5 places).
- **Sprite offset tables.** The tables of the player sheet and the frame banks have no entry for frame 0, so `addframe2`, the face off drawing, `SetSframe` and the crowd drawing index one word lower. The player sheet is 2 bytes shorter for this reason.
- **Startup.** `KillCrowd` is called from `Begin`, after the sound set up (which now comes first), and no longer from `Start`.
- **Small edits.** `check4bench` lost a dead test, `returngoalies` no longer exits when a team leads, the goalie save odds table (`.list2` in `puckgoalie`) has 6 fewer stack-left entries, which moves the stick-save entries to line up with their sprite frames (they were 6 frames off in 1.0 and 1.1; the sprite frames themselves do not change), `MenuWaitVblankWrapper` and `pucknothing` are gone (their callers go to the real routine), `SetupScreen` and `ExitStatsScreen` set the horizontal scroll register, and a few hard-coded RAM addresses in the stats screens moved with the layout (the source now uses `Satt`, `statsbuffer` and `TextBuffer`).

## Specific Differences and Comments (Rev A vs Rev B)
- Header: `1993.FEB`, the title back to mixed case (`NHLPA Hockey '93`), `GM T-50396 -00`, country code `UEJ`, header checksum `$86DB`.
- The unused exception vectors are `$FFFFFFFF` instead of 0, and the vectors of the handlers moved with the code.
- The ROM sum for `ValidationRoutine` is `$07F7C2C9`.
- Pad bytes: the same pad bytes as in Rev 0 are `$FF` (`PadByte` in `main93.asm`), and the scouting text pad is `$0D`.
- Graphics order: `EASportsMap` comes before the arrows map, and the last picture is `EASportsMap2`. `HotList` is 2 bytes earlier in the player sheet.

## Finding the differences

`python3 tools/diffrom.py built.bin reference.bin built.sym` aligns two ROMs on runs of identical bytes and lists the gaps, so a few bytes of difference do not shift the rest of the comparison. A gap with the same size on both sides is an address that moved; a gap whose size differs is an edit.
