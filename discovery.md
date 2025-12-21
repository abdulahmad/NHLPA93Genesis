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
| `0x0C..0x2B`  | `<HomePalette>` | Home Palette Data. 32 Bytes long. 2 3-bit 16 color Genesis Palettes |
| `0x2C..0x4B`  | `<AwayPalette>` | Away Palette Data. 32 Bytes long. 2 3-bit 16 color Genesis Palettes |
| `0x4C..0x53`  | `<ScoutingReport>` | Scouting Report Data. 8 bytes in length. |
| `0x54..0x55`  | `<UnknownTeamData>` | Unknown Team Data. 2 bytes in length. |
| `0x56..0x8D`  | `<Lines>` | Lines. 7 Lines * 8 bytes in length = 56 bytes in length. |
| `0x8E..endOfPlayerData`  | `<PlayerData>` | Player Data. 20 to 23 players. |
| `endOfPlayerData+1..endOfTeamNameSection`  | `<TeamNameSection>` | Team Name & Abbreviation. |

## NHLPA93 Scouting Report Section (Big Endian)
| `0x00..0x01`  | `<PlayerData>` | Pointer to Player Data |

## NHLPA93 Lines Section (Big Endian)
| `0x00..0x01`  | `<PlayerData>` | Pointer to Player Data |

## NHLPA93 Player Data Section (Big Endian)
| `0x00..0x01`  | `<PlayerData>` | Pointer to Player Data |

## NHLPA93 Team Name Section (Big Endian)
| `0x00..0x01`  | `<PlayerData>` | Pointer to Player Data |