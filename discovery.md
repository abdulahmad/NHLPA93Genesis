0x314-0x37B = Team Address
0x37C-0x387 = Team 0 Offsets (6th offset tracks something different in 93 than 92)
0x388-0x3C7 = Team home/away pals


## NHLPA93 Team Data Section (Big Endian)
By default, `NumTeams = 26`
| Byte (All values in hexadecimal)                              | Value                 | Description |
| --------                                                      | -------               | -------     |
| `startOfTeamListOffset..startOfTeamListOffset+4*NumTeams`     | `<TeamList>`          | Table of pointers to each team's data |
| `endofTeamList+1..endofTeamIndex0`                            | `<TeamAtIndexData>`          | Team Data. Includes Jersey Palettes, Scouting Report, Lines, Player Attributes, Team Name |

## NHLPA93 TeamAtIndexData Section (Big Endian)
| `0x00..0x01`  | `<uint16>` | Absolute pointer to Team at Index 0 |
| `0x02..0x03`  | `<uint16>` | Absolute pointer to Team at Index 1 |
| `0x04..0x05`  | `<uint16>` | Absolute pointer to Team at Index 2 |
|...|...|...|
| `0x0((NumTeams-1)*2)..0x0((NumTeams-1)*2+1)`  | `<uint16>` | Absolute pointer to Team at Index (NumTeams-1) |

## NHLPA93 TeamAtIndexData Section (Big Endian)
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

## NHLPA93 Scouting Report Section (Big Endian)
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

## NHLPA93 Lines Section (Big Endian)
| `0x00..0x07`  | `<LineAtIndexData>` | Line 1 |
| `0x08..0x0E`  | `<LineAtIndexData>` | Line 2 |
| `0x0F..0x15`  | `<LineAtIndexData>` | Line 3 |
| `0x16..0x1C`  | `<LineAtIndexData>` | Line 4 |
| `0x1D..0x23`  | `<LineAtIndexData>` | Line 5 |
| `0x24..0x2A`  | `<LineAtIndexData>` | Line 6 |
| `0x2B..0x31`  | `<LineAtIndexData>` | Line 7 |

## NHLPA93 LineAtIndexData Section (Big Endian)
| `0x00`  | `<unit8>` | Team Player ID for Goalie |
| `0x01`  | `<unit8>` | Team Player ID for Left Defense |
| `0x02`  | `<unit8>` | Team Player ID for Right Defense |
| `0x03`  | `<unit8>` | Team Player ID for Left Wing |
| `0x04`  | `<unit8>` | Team Player ID for Center |
| `0x05`  | `<unit8>` | Team Player ID for Right Wing |
| `0x06`  | `<unit8>` | Team Player ID for Extra Attacker |
| `0x07`  | `00`      | Alignment Byte |

## NHLPA93 Player Data Section (Big Endian)
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

## NHLPA93 Team Name Section (Big Endian)
| `0x00..0x01`  | `<TeamNameLength+1>` | Length of Team Name + 1. Includes extra alignment blank space as part of count if name is uneven |
| `0x02..0x02+TeamNameLength`  | `<string>` | Team's Name. If Length is uneven, a blank space is added to the end for alignment |
| `0xTeamNameLength+1..0xTeamNameLength+2`  | `<TeamAbbreviationLength+1>` | Length of Team Abbreviation + 1. Includes extra alignment blank space as part of count if name is uneven |
| `0xTeamNameLength+2..0xTeamNameLength+TeamAbbreviationLength+3`  | `<string>` | Team's Abbreviation. If Length is uneven, a blank space is added to the end for alignment |