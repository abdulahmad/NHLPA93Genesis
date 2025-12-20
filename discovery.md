0x314-0x37B = Team Address
0x37C-0x387 = Team 0 Offsets (6th offset tracks something different in 93 than 92)
0x388-0x3C7 = home/away pals

Palette in build: 0x3AA
Palette in retail: 0x388


## NHLPA93 Team Data Section (Big Endian)
By default, `NumTeams = 26`
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `startOfTeamListOffset..startOfTeamListOffset+4*NumTeams`     | `<TeamList>`          | Table of pointers to each team's data |
| `endofTeamList+1..endofTeamIndex0`                            | `<TeamAtIndexData>`          | Team Data. Includes Jersey Palettes, Scouting Report, Lines, Player Attributes, Team Name |

## NHLPA93 TeamAtIndexData Section (Big Endian)
| `0x00..0x01`  | `<unit16>` | Pointer to Team at Index 0 |
| `0x02..0x03`  | `<unit16>` | Pointer to Team at Index 1 |
| `0x04..0x05`  | `<unit16>` | Pointer to Team at Index 2 |
|...|...|...|
| `0x0((NumTeams-1)*2)..0x0((NumTeams-1)*2+1)`  | `<unit16>` | Pointer to Team at Index (NumTeams-1) |

## NHLPA93 TeamAtIndexData Section (Big Endian)
| `0x00..0x01`  | `<unit16>` | Pointer to Player Data |
| `0x02..0x03`  | `<unit16>` | Pointer to Jersey Palettes |
| `0x04..0x05`  | `<unit16>` | Pointer to Team Name |
| `0x06..0x07`  | `<unit16>` | Pointer to Line Combinations |
| `0x08..0x09`  | `<unit16>` | Pointer to Scouting Report Data |
| `0x10..0x11`  | `<unit16>` | Pointer to Unknown Team Data |
| `0x00..0x01`  | `<unit16>` | Pointer to Player Data |
| `0x02..0x03`  | `<unit16>` | Pointer to Jersey Palettes |
| `0x04..0x05`  | `<unit16>` | Pointer to Team Name |
| `0x06..0x07`  | `<unit16>` | Pointer to Line Combinations |
| `0x08..0x09`  | `<unit16>` | Pointer to Scouting Report Data |
| `0x0A..0x0B`  | `<unit16>` | Pointer to Unknown Team Data |
| `0x0C..0x2B`  | `<HomePalette>` | Home Palette Data. 32 Bytes long. 2 Genesis Palettes |
| `0x2C..0x4B`  | `<AwayPalette>` | Away Palette Data. 32 Bytes long. 2 Genesis Palettes |
Scouting Report
Unknown
Lines
Player Data
Team Name

## NHLPA93 PlayerData Section (Big Endian)
| `0x00..0x01`  | `<PlayerData>` | Pointer to Player Data |
| `0x02..0x03`  | `<JerseyPalettes>` | Pointer to Jersey Palettes |
| `0x04..0x05`  | `<string>` | Pointer to Team Name |
| `0x06..0x07`  | `<Lines>` | Pointer to Line Combinations |
| `0x08..0x09`  | `<ScoutingReportData>` | Pointer to Scouting Report Data |
| `0x10..0x11`  | `<UnknownData>` | Pointer to Unknown Team Data |

| `0x06-FrameDataEnd`                   | `<Frame Data>`        | List of Frames in .ANIM file                      |
| `0x(FrameDataEnd+1)-(FrameDataEnd+2)` | `"CC"`                | Character Content (Tile Data) Header              |
| `0x(FrameDataEnd+3)-(FrameDataEnd+4)` | `<uint16>`             | Number of Tiles in ANIM file                      |
| `0x(FrameDataEnd+5)-(TileDataEnd)`    | `<Sprite Tile Data>`  | 8x8 Tiles, 4 bits per pixel, Column-Major order. In the retail ROM, sprites are grouped together in order of descending height. See `Size Table` Definition Section for Sprite Sizes. Sprites seem to be in opposite order of tileIndex in each size group.                                        |
| `0x(TileDataEnd+1)-(TileDataEnd+2)`   | `"PP"`                | Palette Section Header                            |
| `0x(TileDataEnd+3)-(TileDataEnd+82)`  | `<Palette Data>`      | 128 bytes of Palette Data. 4 palettes of 16 colors (9bpp Sega Genesis Format).                                                                                               |
| `0x(TileDataEnd+83)-(TileDataEnd+84)`| `"DD"`                 | Unknown Data Section Header                       |
| `0x(TileDataEnd+85)-(TileDataEnd+94)`| `<DD Data>`            | 16 bytes of Unknown Data                          |
| `0x(TileDataEnd+95)-(TileDataEnd+96)`| `"ZZ"`                 | End of File Footer                                |
