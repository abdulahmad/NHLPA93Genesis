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


Sprite animation frames:
SPFskatewp = 1
SPFskate = 41
SPFturnl = 81
SPFturnr = 89
SPFswing = 97
SPFstop = 145
SPFskateb = 161
SPFcelebrate = 185
SPFpump = 201
SPFcup = 217
SPFhipl = 225
SPFhipr = 233
SPFshoulderl = 241
SPFshoulderr = 249
SPFsweep = 257
SPFfallback = 273
SPFfallfwd = 305
SPFduck = 337
SPFHold = 345
SPFgloves = 353
SPFfight = 354
SPFPen = 371
SPFarrow = 378
SPFpad = 384
SPFpuck = 387
SPFgoal = 398
SPFGoalie = 400
SPFLogos = 512
SPFSiren = 536

SPAgready_table
SPAgglover_table
SPAgglovel_table
SPAgstickr_table
SPAgstickl_table
SPAgstackr_table
SPAgstackl_table
SPAgswing_table
SPAgskate_table
SPApflip_table
SPAglide_table
SPAskatewp_table
SPAskate_table
SPAturnl_table
SPAturnr_table
SPAstop_table
SPApassf_table
SPApassb_table
SPAshotf_table
SPAshotb_table
SPAglideback_table
SPAskateback_table
SPAsweepchk_table
SPAshoulderchkl_table
SPAshoulderchkr_table
SPAhipchkl_table
SPAhipchkr_table
SPAburst_table
SPAHold_table
SPAHold2_table
SPAflail_table
SPAfallfwd_table
SPAfallback_table
SPAcelebrate_table
SPApump_table
SPAfight_table
SPAfgrab_table
SPAfheld_table
SPAfhigh_table
SPAflow_table
SPAfhith_table
SPAfhitl_table
SPAffall_table
SPAwallright_table
SPAwallleft_table
SPAfaceoff_table
SPAfaceoffr_table
SPAsiren_table
SPAstanley_table

Changes from 92 to 93
93.371-93.376 are new-- fight fall & injured -> NAME = 
92.371 -> shifted to 93.377 (+6 offset)
93.393 -> new instant replay cursor -> NAME = 
92.387 -> shifted to 93.394 (+7 offset)
92.486 = 93.493
92.511 = 93.518
92.512-535 = logos
93.519-534 - new goalie dive -> NAME = 
93.535-538 - new goalie glove wide save -> NAME = 
93.539-554 - goalie smack stick on ice -> NAME = 
92.536-549 -> shifted to 93.555-568 (+19 offset)
93.569-584 - new player bat puck animation -> NAME = 
93.585-600 - new player hook -> NAME = 
93.601-624 - player flail/off balance -> NAME = 
93.625-632 - player flip -> NAME =
93.633-644 - player injured -> NAME = 
93.645-649 - glass break -> NAME = 

92 frame.asm format:
<offset from SPAList> - buffer or alignment byte -> pointer to Animation 1 gready
<ptr to dir 0>
<ptr to dir 1>
<ptr to dir 2>
<ptr to dir 3>
<ptr to dir 4>
<ptr to dir 5>
<ptr to dir 7>
<animFlags>
<frame 1 dir 0> <-time> <addional frame/time groups>
<frame 1 dir 1> <-time> <addional frame/time groups>
<frame 1 dir 2> <-time> <addional frame/time groups>
<frame 1 dir 3> <-time> <addional frame/time groups>
<frame 1 dir 4> <-time> <addional frame/time groups>
<frame 1 dir 5> <-time> <addional frame/time groups>
<frame 1 dir 6> <-time> <addional frame/time groups>
<frame 1 dir 7> <-time> <addional frame/time groups>
