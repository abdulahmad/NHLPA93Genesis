# NHLPA93Genesis
A work-in-progress attempt at reverse engineering a bitwise perfect compilable source of NHLPA Hockey 93 for Sega Genesis. Requires original ROM file to build.

Built on the work that McMarkis (https://github.com/Mhopkinsinc/NHLHockey) did to get the NHL 92 source compiling, and my work to make the code bitwise perfect to the retail version. Also references chaos' disassembly work of NHL 92-94 (https://github.com/Chaos81/nhl94-disassembly).

Status: all 68k code is source and both the retail and the Rev A ROM build bitwise perfect from it. The Z80 sound driver, the sound data (PCM samples, FM patches, event streams), the team palettes and the graphics are incbins of slices extracted from the retail ROM; anything in them that holds a ROM address is source, so the data follows the code.

## Features of this version:
- Retail (`1992.JUL -00`) and Rev A (`1992.OCT -01`) ROMs build bitwise perfect from the same source (`IF REV=1` blocks)
- Label-based source: RAM, ports and structure equates live in `src/ram93.asm` (laid out like NHL 92 `ram.asm`), and the code and data use labels instead of addresses
- Every code segment can also be built and verified on its own against the retail ROM (`npm run seg:<name>`, `src/<name>_stub.asm`)
- Script which changes opcodes to match the custom compiler EA used to build the game (`fixopcodes.js`)
- Disassembled Retail Validation Check code (`checksum93.asm`) included via the checksum env variable
- Script to extract assets from the retail ROM (team palettes, graphics, PCM samples, FM patches, sound event streams, Z80 sound driver, scouting report text)
- Documentation of the file formats used within the game
- Requires the retail ROM

## Instructions

1. Install node from https://nodejs.org/en/download if it isn't already installed on your machine

2. In the `NHLPA93Genesis` folder, run `npm i` to install `node_modules`

3. Copy the NHLPA Hockey 93 Sega Genesis retail ROM file into the `NHLPA93Genesis` folder as `nhlpa93retail.bin` (CRC32 `CBBF4262`). Copy the Rev A ROM as `nhlpa93retailRevA.bin` if you want to verify Rev A builds

4. Build one of these versions. Each build runs `npm run extractassets` first (`node src/extractAssets93-1.1.js nhlpa93retail.bin`, which writes `Extracted/Sound`, `Extracted/Text` and `Extracted/Graphics`), assembles `src/hockey93.asm` to `output/nhl93.bin`, and fixes the opcodes into `output/modified_nhl93.bin`:

    - For the `Retail` ROM, run `npm run build:retail` -- verified byte for byte against `nhlpa93retail.bin`

    - For the `Rev A` ROM, run `npm run build:reva` -- same build with `REV=1`, verified byte for byte against `nhlpa93retailRevA.bin`

    - For developing your own version, run `npm run build:dev` -- `Rev A` code without the checksum validation check (not verified against any ROM)

5. To build and verify one code segment against the retail ROM, run `npm run seg:<name>` (for example `npm run seg:logic93_1`)

# Documentation

## Developing on this build
Build with `build:dev` (`checksum=0`): `Start` skips `jsr ValidationRoutine` and the header checksum is 0, so changed code still boots. With `checksum=1` the validation routine sums the ROM, and any change turns the screen red. There is no checksum generator in this repo. `build:dev` is not identical to `nhlpa93devRevA.bin`: that ROM has its own header (`1992.MAY`, titles `NHLPA HOCKEY` / `NHL HOCKEY`, product `T-50236`) and different bytes from `$7FBA4` to the end.

Because the source uses labels, code and data can grow or move. Add new RAM to `src/ram93.asm`. Sound and graphics files come from `Extracted/`; replace a file there (keeping its name) to change an asset, or add an `incbin` with a label.

## Retail (REV=0) vs Rev A (REV=1)
Both build from the same source (`IF REV=1` blocks). Retail is `1992.JUL` version `-00`; Rev A is `1992.OCT` version `-01`.

### Overall Differences Between Retail (REV=0) vs Rev A (REV=1)
- Rev A supports 50 Hz: `Begin` stores the VDP PAL bit in `music_global_tick_counter`. When it is set, `updateplayers` moves skaters 20 units per frame instead of 16, and `p_music_vblank` runs the music track slots a second time every 6th frame.
- Rev A adds two RAM words (`music_global_tick_counter`, `music_tick_divider`) before `databuffer`, so every variable from `databuffer` up is 4 bytes higher (`ram93.asm` handles it).
- Retail has a `SecurityCheck` `$FFFF` word before `ValidationRoutine`; Rev A does not. The checksums differ (header `$2799` / `$FA57`, ROM sum `$EB689746` / `$C62A6024`).

### Specific Differences and Comments
- Header: Rev A writes the title `NHLPA HOCKEY '93` in capitals.
- Code addresses move by +`$E` after `Begin`, +`$18` after `updateplayers` and +`$2E` after `p_music_vblank`. The source uses labels, so the moves are automatic, including the sound data's absolute pointers (PCM sample table, song loop pointers, the Z80 driver's FM patch bank address).
- Pad bytes: retail has leftover values in 11 pad bytes (`Setplass .alist`, `ButtonLabelCharTable`, `bfasciicon`, `priolist`, `PlayoffTreeSetup`, the Z80 driver end, four PCM sample ends and the scouting text end); Rev A has 0.

## Sound System Overview
The 68k side of the driver is source (`src/sound93.asm`, `p_turnoff` ... `ClearAllTrackAndSFXSlots`); the Z80 side is the incbin `z80_snd_drv93.bin`. There is no NHL 92 code in it: 92 used a different driver.

- **Sound numbers**: `sfx` and `song` both call `play_sfx_or_music_track`. Sounds 0-`$2F` are effects, `$30`-`$37` are songs (`$30` goal, `$31` period start, `$32` third period, `$33` power play, `$34` faceoff, `$35` title, `$36` end of game / playoffs / highlights, `$37` scouting report). Starting a song stops the one already playing.
- **Track slots**: 8 slots at `fm_track_slots` (long event pointer, delay). `p_music_vblank` runs every slot once per frame; in Rev A, at 50 Hz, it runs them again every 6th frame.
- **Event streams**: `MusicTrackPointerTable` holds word offsets of the 56 streams (`sfx_<name>_cmdstream`, `fmtune_<name>_cmdstream`). An event is 4 bytes: delay before it, status (bits 6-4 command, bits 3-0 MIDI channel), two data bytes. Commands: `$0x` key off, `$1x` key on (note, volume; volume 0 = key off), `$4x` set the channel's patch, `$6x` pitch bend; `$2x`, `$3x`, `$5x`, `$7x` are ignored. Status 0 ends the stream; a non-negative long after it is a loop pointer (songs `$35`-`$37`).
- **Channels**: 6 channel structs (`fm_channel_structs`; the 6th, `pcm_channel_struct`, is the PCM channel). A key on takes an off channel that already has the patch, else the oldest channel.
- **FM patches**: `fm_instrument_patches`, 32 patches of 32 bytes (byte `$1E` is the pitch bend scale). The Z80 reads them through the 32K bank window (bank `fm_instrument_patches>>15`).
- **PCM**: patches `$60` and up are samples. `pcm_sample_table` has 15 entries (sample address, 0); the 68k copies them to Z80 RAM `$23`-`$28` and posts command `$29`. The 12 samples are `sfx_<name>_pcm` (signed 8-bit).
- **68k to Z80**: changes collect in `Z80_command_buffer` (key off / key on / volume / frequency / patch bits, then 7 volumes, 7 frequency words, 7 patches) and are copied to Z80 RAM `$02` with command `$D1` when the Z80 is idle.
- **Z80 start**: `p_initialZ80` copies `$295` bytes from `Z80_Program_Code` (`$16E52`) to Z80 RAM and builds 29 volume tables of 256 bytes below Z80 `$2000`.

## .JIM
Documentation for the NHLPA93 .JIM and .JZIP file format and tools to import/export to/from .JIM/.JZIP format lives here: https://github.com/abdulahmad/EA-NHL-Tools/tree/main/JIM-Tools

## .ANIM94 format
Documentation for the NHLPA93 .ANIM file format and tool to export from .ANIM format lives here: https://github.com/abdulahmad/EA-NHL-Tools/tree/main/ANIM94-To-BMP

## .PAL
.pal files use standard Genesis CRAM format for palette. Each color is 2 bytes in Genesis format (0000BBB0GGG0RRR0, where BBB=Blue bits, GGG=Green bits, RRR=Red bits).

## Known Issues/Limitations
- **Rev B**: `nhlpa93retailRevB.bin` (`1993.FEB`) is a separate later build (different rosters, graphics and about 145 code changes) and is not built.
- **Z80 sound driver**: the Z80 code is the extracted binary, not source.
- **Asset boundaries**: graphics and sound slices start at the labels the code uses; a few files may contain more than one asset.
- **Checksum sensitivity**: `build:retail` / `build:reva` need the exact retail ROM for the extracted files; with validation on, any change stops the game at boot.

## Modding Tips
- **Custom music / SFX**: add an event stream file and an `incbin` with a label in `sound93.asm`, then point a `MusicTrackPointerTable` entry at it (`dc.w <label>-MusicTrackPointerTable`).
- **New samples**: add the sample with a label and use it in `pcm_sample_table` (patch `$60` + index).
- **Testing**: build `build:dev` so checksum validation does not lock the game.
