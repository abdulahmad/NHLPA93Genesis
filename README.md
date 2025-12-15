# NHLPA93Genesis
A work-in-progress attempt at reverse engineering a bitwise perfect compilable source of NHLPA Hockey 93 for Sega Genesis. Requires original ROM file to build.

Built on the work that McMarkis (https://github.com/Mhopkinsinc/NHLHockey) did to get the NHL 92 source compiling, and my work to make the code bitwise perfect to the retail version. Also references chaos' disassembly work of NHL 92-94 (https://github.com/Chaos81/nhl94-disassembly).

Code Disassembly: 925 / 188924 bytes completed = 0.48% complete

Asset Identification: I think this the majority of the remaining 323 kb, and I want to say this is about 90% done. I think the main thing will be to double check the code as I find the references to the files in the disassembly to fine tune the start/ends of files. I'm not sure if I've identified the exact starts of every file, or just where the useful data begins.

## Features of this version:
- Retail version is bitwise perfect with retail ROM. Rev A Dev build is bitwise perfect with Rev A Dev build included with original release.
- Documentation of all File Formats used within the game
- Script which changes opcodes to match the custom compiler EA used to build the game
- Disassembled Retail Validation Check code included via checksum env variable
- Env vars allows build of Retail version (includes validation code), Rev A "retail" version (includes validation code) or Rev A Dev version (no validation code)
- Script to generate CRC16 Checksum used in ROM Header & CRC32 Checksum used in Validation code
- EA Logo code is disassembled and buildable
- Sound Driver code is disassembled and buildable
- Script to extract assets from retail rom (Graphics, PCM audio, FM audio, z80 snd driver)
- Requires retail ROM

## Instructions

1. Install node from https://nodejs.org/en/download if it isn't already installed on your machine

2. In the `NHLPA93Genesis` folder, run `npm i` to install `node_modules`

3. Copy the NHL Hockey (NHL93) Sega Genesis ROM file into the `NHLPA93Genesis` folder

4. Run `node .\extractAssets93.js <nhlpa93RomFileName>` to extract assets from the NHLPA Hockey 93 ROM file into the `Extracted` folder

5. Run `npm run build:logo` to build `EALogo93.bin` (`modified_EALogo93.bin` is the opcode corrected version)

6. Run `npm run build:sound` to build `Hockey93.snd` (`modified_Hockey93.snd` is the opcode corrected version)

7. You have the choice of building 3 versions:

    - For the `Retail` ROM, run `npm run build:retail` -- this includes the retail checksum validation check (modified_nhlpa93.bin is the opcode corrected version)

    - For the `Rev A` ROM, run `npm run build:reva` -- this includes the retail checksum validation check (modified_nhlpa93.bin is the opcode corrected version)

    - For developing your own version, run `npm run build:dev` -- this uses `Rev A` flags and does not include the retail checksum validation check  (modified_nhlpa93.bin is the opcode corrected version)

# Documentation

## Developing on this build
You need to build using `build:dev` to avoid the checksum validation. By default, this builds the `Rev A` version of the code. If for whatever reason, you do want to enforce checksum validation on your build, you need to use the `generateChecksum.js` script. Also, you need to do 2 passes of the script & updating the checksums to end up with the correct checksum for both CRC16 and CRC32. The game will not start if checksum validation is enabled and the checksum is incorrect.

## Retail (REV=0) vs Rev A (REV=1)
TBD.

### Overall Differences Between Retail (REV=0) vs Rev A (REV=1)
TBD.

### Specific Differences and Comments
TBD

## Sound System Overview
TBD

## .JIM
Documentation for the NHLPA93 .JIM and .JZIP file format and tools to import/export to/from .JIM/.JZIP format lives here: https://github.com/abdulahmad/EA-NHL-Tools/tree/main/JIM-Tools

## .ANIM94 format
Documentation for the NHLPA93 .ANIM file format and tool to export from .ANIM format lives here: https://github.com/abdulahmad/EA-NHL-Tools/tree/main/ANIM94-To-BMP

## .PAL
.pal files use standard Genesis CRAM format for palette. Each color is 2 bytes in Genesis format (0000BBB0GGG0RRR0, where BBB=Blue bits, GGG=Green bits, RRR=Red bits).

## SFX:
Note: This section has not been updated for NHLPA93 yet.
### SFX pointer table
Pointer table at $1035C (35 entries, longwords relative to `p_music_vblank`). Maps SFX IDs (0-34) to handlers (e.g., $0 = `handle_sfx_siren`). Some duplicates/share code (e.g., IDs 30-34 all point to `handle_sfx_id_30`).

### SFX handler
Handlers (e.g., `handle_sfx_puckwall1`) load YM2612 params or init channels via `Sound_InitSFXChannel`. Many write direct to YM2612 (e.g., `Sound_WriteYM2612`) for freq/volume, or chain to others (e.g., puckwall3 chains to pass).

### SFX cmdstream
Extracted .bin files (e.g., `sfx_siren_cmdstream_ch0.bin` at $FF74). Byte streams parsed in `Sound_Process_SFXChannels`: $80 (set instrument), $81/$82 (delay/alt delay), $83 (freq sweep: counter, base freq, increment), $84 (stop), $85 (loop). Frequency normalized to YM2612 range ($000-$7FF).

### SFX PCM
Extracted signed 8-bit PCM .bin files (e.g., `sfx_puckwall1_pcm.bin` 0x11C3E-0x12A58). Streamed via DAC. Some shared/partial (e.g., `sfx_puckbody_pcm` overlaps FM patches at $12A58). Sample rates ~8-11kHz based on counters.

### Instrument patches
Loaded via $80 command. Params: 4 operators (mul/dt/tl/rs/ar/dr/sr/rr/ssg-eg), alg/fb, stereo. 25+ defined; some hardcoded in handlers (e.g., `fm_instrument_patch_sfx_id_3` at $12DE2 overlaps PCM).

## Note Frequency Table
At $1017A (96 bytes): YM2612 freq low bytes for notes (C0-B7, incl. sharps). E.g., C0=$02, C#0=$03. Used in `process_note_frequency` with octave shifts.

## Note Octave Table
At $101DA (96 bytes): Freq high/octave bits. E.g., C0=$84, C1=$AA. Combined with freq table for full 11-bit YM2612 freq.

## Envelope Table
At $1023A (4 long ptrs to envelopes). Signed vibrato/detune patterns ($00 neutral, positive up, negative down; $84 loop). E.g., Envelope0: subtle oscillate (0,+1,+1,0,-1,-2,-1,0,loop). Applied in `check_envelope` for pitch/volume modulation.

## FMTunes:
### fmtune pointer table
At $10294 (5 entries, 26 bytes each): Num FM/PSG channels (word), 6 long ptrs to channel data (rel to `p_music_vblank`). E.g., Title ($0506, ch0-5 ptrs).

### fmtune channel table
Channel offsets (e.g., `fmtune_song0_ch0` at $10568): Words pointing to sequences (e.g., $11A3 = seq0). Up to 6 channels per track.

### fmtune sequence table
Sequences (`fmtune_seq0` at $1061E+): Byte streams for notes/rests ($00-$5F note/rest, $60 rest), commands ($80+ as in SFX but music-specific: $80 instr, $81 mod, $83 sustain, $84 loop, $85 stop, $86 env, $87 clear env, $88 pitch, $89 flag, $8A skip, $8B SFX). Durations $8C-$9F (multiplied by tempo).

## Z80 Snd Drv
Binary at $116A6-$11C3D (extracted as z80_snd_drv.bin). Loaded via `Sound_LoadZ80Program`. Disassembled (IDA Pro):

- **Entry**: `Z80_SoundDriver` ($116A6) sets stack ($1FFF), IM1, jumps to `MainLoop` ($116D6).
- **MainLoop**: Checks flags (`FLAG_CONTROL` $02A4). Processes DAC ($2A reg), FM channels (6x, regs $30-$8C via `ProcessFMChannels` $11775), PSG. Busy-waits for YM writes.
- **Channels**: Pointers at $0073. Flags at $00B0. Processes per-channel (key on/off $28, freq $A0/$A4, vol $4C).
- **DAC/PSG**: DAC enable ($2B reg). PSG via shared RAM ($00BE-$00C3).
- **Writes**: `WriteYM2612` ($118DF) / `WriteYM2612Part2` ($118EB) with delays (pop hl for timing).
- **Instruments**: Patched to YM regs (e.g., $30+ for operators).

## Known Issues/Limitations
- **PCM Overlaps**: Some FM patches overlap PCM (e.g., $10820 in fm_instrument_patch_sfx_31). Modding may corrupt audio due to hardcoded address
- **Checksum Sensitivity**: Builds require exact extracts for bitwise match; minor ROM diffs break validation.
- **Z80 Sound Driver**: There is an .lst file in the `sound` folder of the z80 sound driver disassembly, but I haven't gone through the effort of making it part of the build-- the z80 code extracted from the retail rom is used for the build.

## Modding Tips
- **Custom Music**: Edit `fmtune_pointer_table` / sequences. Add notes via freq tables; test envelopes for vibrato.
- **New SFX**: Add to `sfx_pointer_table`, create handler (init channels, YM writes), cmdstream (.bin), PCM if needed.
- **Testing**: Build `dev` for no checksum lock. Monitor shared RAM ($FFFFFE40+) for channel states.
