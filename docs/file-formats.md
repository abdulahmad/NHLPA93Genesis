# File formats

Formats of the data in the NHLPA 93 (Genesis) ROM, and of the files in `Extracted/`. The sister document for the Super Nintendo game is
[NHLPA93SNES docs/file-formats.md](https://github.com/abdulahmad/NHLPA93SNES/blob/main/docs/file-formats.md); it uses the same sections, so
the two can be read side by side. All values are big endian (68000).

## Extracted/

`tools/extractAssets93.js` cuts the assets out of the retail ROM into `Extracted/{Graphics,Sound,Text}/` (150 files for Rev 0 and Rev A, which
share their slices; Rev B has pictures and sound data of its own and is extracted from its own ROM). `Extracted/` is not committed;
`tools/prebuild.js` runs the extractor before every build when the folder is missing or stale, and the source `incbin`s the files.
The extension gives the format:

| Extension | Format | Files |
|-----------|--------|-------|
| `.map.jim` | Screen container: palette, map and tiles, see [.map.jim](#mapjim-and-anim-the-container) | 20 files in `Graphics/` (`Title1`, `IceRink`, `Arrows`, `Framer`, `BigFont`, `SmallFont`, ...) |
| `.anim` | Sprite frame set: tiles, frame table and sprite entries, see [.anim](#anim-sprite-frames) | `Sprites` (all the player, goalie and puck frames), `Crowd`, `Zam`, `FaceOff`, `EASN`, `GameSetup`, `Title3`, `TitleLogo` |
| `.pal` | Team palette, 32 bytes, see [Palettes](#palettes) | `Graphics/Pals/<team>h`, `<team>v` (52 files) |
| `_cmdstream.bin` | 68000 event stream of a song or effect, see [Sound](#sound) | `Sound/fmtune_<song>`, `Sound/sfx_<name>` |
| `_pcm.bin` | Raw signed 8-bit PCM sample | `Sound/sfx_<name>_pcm` (12 files) |
| `fm_instrument_patches.bin` | 32 YM2612 patches of 32 bytes | `Sound/` |
| `z80_snd_drv93.bin`, `z80_snd_drv93_end.bin` | The Z80 sound driver, in two pieces around the FM patch bank address | `Sound/` |
| `.bin` (text) | `Text/ScoutingReportText.bin`, see [Text](#text) | `Text/` |

## .map.jim and .anim: the container

Both are one container with the same first twelve bytes, so a screen and a sprite set load tiles the same way:

| Offset | Size | Content |
|--------|------|---------|
| `0x00` | long | offset of the palette from the start of the file, or `$FFFFFFFF` for none |
| `0x04` | long | `.map.jim`: offset of the map. `.anim`: offset of the frame offset table |
| `0x08` | word | tile count; bit 15 set = the tiles are packed (see [Packed tiles](#packed-tiles)) |
| `0x0A` | | the tiles (raw: 32 bytes each, or one packed stream) |

`DecompressGraphics` (`src/decompress93.asm`) sends the tiles to VRAM from the word at `0x08`. The `JIM-Tools` and `ANIM94-To-BMP` tools in
[EA-NHL-Tools](https://github.com/abdulahmad/EA-NHL-Tools) convert `.map.jim` / `.anim` files to and from BMP.

### Tiles

8 x 8 pixels, 4 bits per pixel, 32 bytes per tile, row by row (the Genesis VDP format).

### Packed tiles

`DecompressBytecode` unpacks the stream through a 256 byte ring buffer, which it sends to VRAM every time it is full. It is a byte oriented
LZ77 style code. The high nibble of an opcode byte selects the handler:

| Opcode | Does |
|--------|------|
| `$00-$1F` | copy the next (opcode & `$1F`) + 1 bytes |
| `$2x` | write (x + 1) zero bytes |
| `$3x` | write the next byte (x + 3) times |
| `$40-$7F` | copy (bits 0-2) + 2 bytes from (bits 3-5) + 1 bytes back |
| `$8x` | copy x + 3 bytes from the distance in the next byte |
| `$9x` | count = 5 bits (x and bit 7 of the next byte) + 3, distance = (bits 0-6 of the next byte) + 1 |
| `$Ax` | count = 6 bits (x and the top 2 bits of the next byte) + 3, distance = (bits 0-5 of the next byte) + 1 |
| `$Bx` | count = 7 bits (x and the top 3 bits of the next byte) + 3, distance = (bits 0-4 of the next byte) + 1 |
| `$C0-$DF` | like `$40-$7F`, but the source walks down: count (bits 0-1) + 2, distance (bits 2-4) + 1 |
| `$Ex` | like `$8x`, source walks down; distance 0 ends the stream |
| `$Fx` | like `$9x`, source walks down |

The SNES game uses the same code (see its file-formats document).

### Palette

Four palette lines of 16 colors, 2 bytes each in Genesis CRAM format (see [Palettes](#palettes)): 128 bytes at the palette offset. `dobitmap`
copies the lines selected by a bit mask into the palette fade buffer.

### Map (`.map.jim`)

At the map offset: a word with the width, a word with the height, then width x height map words. A map word is the Genesis name table
entry: priority bit 15, palette bits 14-13, vflip 12, hflip 11, tile 10-0. `dobitmap` adds the start tile and XORs the attribute bits of the
caller's `printa`. Sizes: `Title1` 32 x 28, `Arrows` 12 x 23, `Framer` 3 x 3.

### Sprite frames (`.anim`)

At the frame offset table: one word per frame, plus one for the end, each the offset (from the table) of the frame's first sprite entry; a frame's
entries run to the next frame's offset. Frame numbers start at 0 in 93 (92 counted from 1). A sprite entry is 8 bytes:

| Offset | Size | Content |
|--------|------|---------|
| 0 | word | x, signed, relative to the frame origin |
| 2 | word | y, signed |
| 4 | word | tile number, relative to where the set's tiles are loaded |
| 6 | word | bits 15-11: priority, palette (2 bits), vflip, hflip, as in a name table entry; bits 7-0: size code (see below) |

Size codes 0-15 are the VDP sprite sizes: `sizetab` (`src/tables93.asm`) gives the number of tiles, `1,2,3,4,2,4,6,8,3,6,9,12,4,8,12,16`
(1 x 1 to 4 x 4 tiles).

`Sprites.anim` is the big set. Its header word at `0x04` is `$3574A`, and after the frame offset table (`FrameDataOff`) come the entries
(`SprDataBytes`, `Sprites+$35C60`) and, last, the hot spot list (`HotList`, `Sprites+$3A056` in Rev 0 and Rev A, `$3A054` in Rev B): two signed
bytes per frame (x, y of the stick blade relative to the frame origin). The other `.anim` files have no hot spots. The crowd frames
(`Crowd.anim`) for the horizontal rink are 31 frames after the vertical ones. Rev B reads the table one entry earlier (see the `REV=2` branches
in `SetSframe`).

### Animations (`src/frames93.asm`)

`SPFxxx` equates give the first frame number of each group of frames. `SPAlist` is the list of animation tables, one per animation, in the
order of the `SPA` numbers (a `SPA` value is the table's offset from `SPAlist`). A table is eight word offsets (one per facing direction 0-7,
relative to `.t`), a flags word (0 or 1), then per direction a list of `frame, time` word pairs; a negative time ends the list.

## Palettes

`Graphics/Pals/<team>h.pal` (home) and `<team>v.pal` (visitor): 32 bytes, 16 colors, each a word in Genesis CRAM format `0000 BBB0 GGG0 RRR0`
(BBB, GGG and RRR are the 3 bit blue, green and red). The two files of a team are stored back to back in the team record
(`Palettedata`). The 26 teams give 52 files; `ASE` / `ASW` are the All-Star teams.

## Text

### Strings

A string is a word that counts itself, then the bytes, padded with a zero to an even length (the pad is in the count): `String 'Boston'` is
`00 08 "Boston"`. The `String` macro (`src/macros/genesis93.mac`) builds them; `StringB` writes the length as a byte, which gives the same
bytes for strings under 256 bytes. A byte with bit 7 set inside a string for `printsmall` is a control code, `-(ControlCodeJumpTable entry)`:

| Code | Name | Next bytes |
|------|------|------------|
| `$FF` | `CC_SetMap` | map number (`printm`) |
| `$FE` | `CC_SetAttribute` | palette/priority (`printa`) |
| `$FD` | `CC_SetX` | `printx` |
| `$FC` | `CC_SetY` | `printy` |
| `$FB` | `CC_AddX` | signed byte added to `printx` |
| `$FA` | `CC_AddY` | signed byte added to `printy` |
| `$F9` | `CC_SetFont` | char set index |
| `$F8` | `CC_SetMapAndPosition` | attribute, map, x, y |

`String -1` ends a list of strings (the credits, the menus). An empty string is `00 02`.

### `Text/ScoutingReportText.bin`

ASCII paragraphs, each ended by `$0D`, for the scouting report screen (`UpdateScoutingDisplay`): paragraph n for team n (0-25), then four fixed
ones (`$1A`-`$1D`: the intro and the closing lines). Words are separated by spaces; `_` `{` `}` `[` `]` stand for a team name or a player name
(home / away) that the game inserts. `,` and `.` make the typing pause.

## Sound

The 68000 side of the driver is source (`src/sound93.asm`); `docs/sound-system.md` describes the driver, the sound numbers and the streams in
full. The files:

| File | Content |
|------|---------|
| `fmtune_<song>_cmdstream.bin`, `sfx_<name>_cmdstream.bin` | An event stream. An event is 4 bytes: delay before it, status (bits 6-4 command, bits 3-0 MIDI channel), two data bytes. Commands: `$0x` key off, `$1x` key on (note, volume; volume 0 = key off), `$4x` set the channel's patch, `$6x` pitch bend; the others are ignored. Status 0 ends the stream; a non-negative long after it is a loop pointer (songs `$35`-`$37`). `MusicTrackPointerTable` holds the word offsets of the 56 streams |
| `fm_instrument_patches.bin` | 32 patches of 32 bytes (1024 bytes). Byte `$1E` is the pitch bend scale. The Z80 reads them through its 32K bank window |
| `sfx_<name>_pcm.bin` | A sample, raw signed 8-bit PCM. Patches `$60` and up are samples; `pcm_sample_table` has 15 entries (sample address, 0), the 12 samples are these files |
| `z80_snd_drv93.bin`, `z80_snd_drv93_end.bin` | The Z80 program (631 and 14 bytes). The first byte (`$18`) and the `ld bc` / `ld a` that load the FM patch bank address are in `src/sound93.asm`; `p_initialZ80` copies `$295` bytes to Z80 RAM |

## Team data

Team data layout of the Rev 0 ROM (all values big endian). The source (`src/teamdata93.asm`) has the record layout and, above each `.sr` and `.pld`, a legend of the nibbles; where this table says Unknown, the legend may name the field.

Start of the team table: `0x314-0x37B` team addresses, `0x37C-0x387` team 0 offsets (the 6th offset tracks something different in 93 than in 92), `0x388-0x3C7` home and away palettes.


### NHLPA93 Team Data Section (Big Endian)
By default, `NumTeams = 26`
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `startOfTeamListOffset..startOfTeamListOffset+4*NumTeams`     | `<TeamList>`          | Table of pointers to each team's data |
| `endofTeamList+1..endofTeamIndex0`                            | `<TeamAtIndexData>`          | Team Data. Includes Jersey Palettes, Scouting Report, Lines, Player Attributes, Team Name |

### NHLPA93 TeamAtIndexData Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00..0x01`  | `<uint16>` | Absolute pointer to Team at Index 0 |
| `0x02..0x03`  | `<uint16>` | Absolute pointer to Team at Index 1 |
| `0x04..0x05`  | `<uint16>` | Absolute pointer to Team at Index 2 |
|...|...|...|
| `0x0((NumTeams-1)*2)..0x0((NumTeams-1)*2+1)`  | `<uint16>` | Absolute pointer to Team at Index (NumTeams-1) |

### NHLPA93 TeamAtIndexData Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00..0x01`  | `<uint16>` | Relative pointer from `TeamAtIndexDataStart` to `PlayerData` |
| `0x02..0x03`  | `<uint16>` | Relative pointer from `TeamAtIndexDataStart` to `HomePalette` |
| `0x04..0x05`  | `<uint16>` | Relative pointer from `TeamAtIndexDataStart` to `TeamNameSection` |
| `0x06..0x07`  | `<uint16>` | Relative pointer from `TeamAtIndexDataStart` to `Lines` |
| `0x08..0x09`  | `<uint16>` | Relative pointer from `TeamAtIndexDataStart` to `ScoutingReport` |
| `0x0A..0x0B`  | `<uint16>` | Relative pointer from `TeamAtIndexDataStart` to `UnknownTeamData` |
| `0x0C..0x2B`  | `<HomePalette>` | Home Palette Data. 32 Bytes long. 2 3-bit 16 color Genesis Palettes |
| `0x2C..0x4B`  | `<AwayPalette>` | Away Palette Data. 32 Bytes long. 2 3-bit 16 color Genesis Palettes |
| `0x4C..0x53`  | `<ScoutingReport>` | Scouting Report Data. 8 bytes in length. |
| `0x54..0x55`  | `<UnknownTeamData>` | Unknown Team Data. 2 bytes in length. |
| `0x56..0x8D`  | `<Lines>` | Lines. 7 Lines * 8 bytes in length = 56 bytes in length. |
| `0x8E..endOfPlayerData`  | `<PlayerData>` | Player Data. 20 to 23 players. |
| `endOfPlayerData+1..endOfTeamNameSection`  | `<TeamNameSection>` | Team Name & Abbreviation. |

### NHLPA93 Scouting Report Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00`  | `<uint8>:Bits 7-4` | Unknown |
| `0x00`  | `<uint8>:Bits 3-0` | Unknown |
| `0x01`  | `<uint8>:Bits 7-4` | Power Play Advantage |
| `0x01`  | `<uint8>:Bits 3-0` | Unknown |
| `0x02`  | `<uint8>:Bits 7-4` | Unknown |
| `0x02`  | `<uint8>:Bits 3-0` | Unknown |
| `0x03`  | `<uint8>:Bits 7-4` | Unknown |
| `0x03`  | `<uint8>:Bits 3-0` | Unknown |
| `0x04`  | `<uint8>:Bits 7-4` | Shooting |
| `0x04`  | `<uint8>:Bits 3-0` | Skating |
| `0x05`  | `<uint8>:Bits 7-4` | Passing |
| `0x05`  | `<uint8>:Bits 3-0` | Defense |
| `0x06`  | `<uint8>:Bits 7-4` | Checking |
| `0x06`  | `<uint8>:Bits 3-0` | Fighting |
| `0x07`  | `<uint8>:Bits 7-4` | Goalkeeping |
| `0x07`  | `<uint8>:Bits 3-0` | Overall |

### NHLPA93 Lines Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00..0x07`  | `<LineAtIndexData>` | Line 1 |
| `0x08..0x0E`  | `<LineAtIndexData>` | Line 2 |
| `0x0F..0x15`  | `<LineAtIndexData>` | Line 3 |
| `0x16..0x1C`  | `<LineAtIndexData>` | Line 4 |
| `0x1D..0x23`  | `<LineAtIndexData>` | Line 5 |
| `0x24..0x2A`  | `<LineAtIndexData>` | Line 6 |
| `0x2B..0x31`  | `<LineAtIndexData>` | Line 7 |

### NHLPA93 LineAtIndexData Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00`  | `<unit8>` | Team Player ID for Goalie |
| `0x01`  | `<unit8>` | Team Player ID for Left Defense |
| `0x02`  | `<unit8>` | Team Player ID for Right Defense |
| `0x03`  | `<unit8>` | Team Player ID for Left Wing |
| `0x04`  | `<unit8>` | Team Player ID for Center |
| `0x05`  | `<unit8>` | Team Player ID for Right Wing |
| `0x06`  | `<unit8>` | Team Player ID for Extra Attacker |
| `0x07`  | `00`      | Alignment Byte |

### NHLPA93 Player Data Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00..0x01`  | `<PlayerNameLength+2>` | Length of Player Name + 2. Includes extra alignment blank space as part of count if name is uneven |
| `0x02..0x02+PlayerNameLength`  | `<string>` | Player's Name. If Length is uneven, a blank space is added to the end for alignment |
| `EndofName+1`  | `<uint8>:Bits 7-4` | uniform # x10 |
| `EndofName+1`  | `<uint8>:Bits 3-0` | uniform # x1 |
| `EndofName+2`  | `<uint8>:Bits 7-4` | weight |
| `EndofName+2`  | `<uint8>:Bits 3-0` | leg power |
| `EndofName+3`  | `<uint8>:Bits 7-4` | speed |
| `EndofName+3`  | `<uint8>:Bits 3-0` | offensive awareness |
| `EndofName+4`  | `<uint8>:Bits 7-4` | defensive awareness |
| `EndofName+4`  | `<uint8>:Bits 3-0` | shot power / NA for goalie |
| `EndofName+5`  | `<uint8>:Bits 7-4` | checking strength / NA |
| `EndofName+5`  | `<uint8>:Bits 3-0` | shooting hand / glove hand |
| `EndofName+6`  | `<uint8>:Bits 7-4` | stickhandling / glove left saves |
| `EndofName+6`  | `<uint8>:Bits 3-0` | shooting accuracy / glove right saves |
| `EndofName+7`  | `<uint8>:Bits 7-4` | endurance / stick right saves |
| `EndofName+7`  | `<uint8>:Bits 3-0` | shot/pass decision / stick left saves |
| `EndofName+8`  | `<uint8>:Bits 7-4` | passing accuracy / consistency |
| `EndofName+8`  | `<uint8>:Bits 3-0` | aggressiveness (PIM) / NA |

### NHLPA93 Team Name Section (Big Endian)
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `0x00..0x01`  | `<TeamNameLength+1>` | Length of Team Name + 1. Includes extra alignment blank space as part of count if name is uneven |
| `0x02..0x02+TeamNameLength`  | `<string>` | Team's Name. If Length is uneven, a blank space is added to the end for alignment |
| `0xTeamNameLength+1..0xTeamNameLength+2`  | `<TeamAbbreviationLength+1>` | Length of Team Abbreviation + 1. Includes extra alignment blank space as part of count if name is uneven |
| `0xTeamNameLength+2..0xTeamNameLength+TeamAbbreviationLength+3`  | `<string>` | Team's Abbreviation. If Length is uneven, a blank space is added to the end for alignment |

## Tools

- `tools/extractAssets93.js` writes `Extracted/` from a ROM (found by SHA-1; `npm run extractassets`).
- `tools/prebuild.js` checks the ROM and runs the extractor when `Extracted/` is missing or stale.
- EA-NHL-Tools: `JIM-Tools` (`.map.jim` to and from BMP), `ANIM94-To-BMP` (`.anim` frames to BMP/RAW), `PAL-To-ACT` (`.pal` to Photoshop swatches).
