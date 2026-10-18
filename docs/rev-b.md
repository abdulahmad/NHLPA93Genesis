# Rev B (REV=2) vs Rev A

The third shipped ROM, `1993.FEB`, version `-00`, header checksum `$86DB` (`nhlpa93retailRevB.bin`). It builds with `node tools/build.js revb` (`REV=2`) and `tools/verify_all.sh` checks it with the other two. Where Rev B is Rev A with something changed, the source has an `IF REV=2` block; the Rev A changes (50 Hz, the two extra RAM words) are on for Rev B too (`IF REV>=1`).

## The EASN to EA Sports change

EA renamed the EASN branding to EA Sports in this version. In the source:
- The pictures are `EASports.map.jim` (the logo, `EASportsMap`, which `EASNmap` is an alias of) and `EASports2.map.jim` (`EASportsMap2`). The five EASN bitmaps and the spinning EASN animation (`EASN.anim`, `SpinningEASN`) are gone, so the Stanley Cup screen draws one EA Sports picture and does not animate. Its vblank handler is `vb2`.
- The EASN logo is not drawn on the Scores screen, and the "Scores" title moved up.
- The ticker title is `EA Hockey Night`.
- The pictures that carry the branding were recompressed: Scouting, IceRink, Zam, GameSetup, Title3, TitleLogo and the player, crowd and face off sprite sheets (the sprite offset tables lost their entry for frame 0, see below) all have different bytes and sizes. `tools/extractAssets93.js` has the Rev B slices (`REVB_SLICES`); `tools/prebuild.js` extracts again when the build switches between Rev B and the other two.

## Other differences

- **Header and vectors**: `1993.FEB`, mixed case title, `GM T-50396 -00`, country code `UEJ`. The unused vectors are `$FFFFFFFF` instead of 0. The ROM sum for `ValidationRoutine` is `$07F7C2C9`.
- **Startup**: `KillCrowd` is called from `Begin` (after the sound set up, which now comes first) and no longer from `Start`.
- **Controllers**: `ReadPads` runs at the start of `p_music_vblank` with the Z80 bus held and leaves the raw bytes in `PadRaw1`/`PadRaw2` (two new RAM bytes before `disflags`); `ReadJoy1`/`ReadJoy2` only translate them.
- **DMA**: `DoDMA`, `DoDMA_nd2` and `DoFill` write the command long from RAM with interrupts off and the Z80 bus held; a DMA from a RAM source writes the first word by hand. The sound driver waits for the Z80 to grant the bus after each bus request (5 places).
- **Sprite sheets**: the frame offset tables (`addframe2`, face off, `SetSframe`, crowd) have no entry for frame 0, so the index is one word lower.
- **Small edits**: `check4bench` lost a dead test, `returngoalies` no longer exits when leading, the goalie stack left table has 3 frames fewer, `MenuWaitVblankWrapper` and `pucknothing` are gone (their callers go to the real routine), `SetupScreen` and `ExitStatsScreen` set the horizontal scroll register.
- **Pad bytes**: the pad bytes are `$FF` (Rev 0 has leftovers, Rev A has 0), and the scouting text pad is `$0D`.

## Finding the differences

`tools/diffrom.py built.bin reference.bin built.sym` aligns two ROMs on runs of identical bytes and lists the gaps, so a few bytes of difference do not shift the rest of the comparison. A gap with the same size on both sides is an address that moved; a gap whose size differs is an edit.
