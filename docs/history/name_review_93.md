# Name review: NHLPA93 (names not from 92G)

Verdicts from reading each routine body / variable usage. "ok" = name matches behavior.

## stats93

| name | verdict |
|---|---|
| AttribEnergy | ok |
| AttribFighting | ok |
| AttribHanded | ok |
| AttribPrintPct | ok |
| AttribRating | ok |
| AttribStatus | ok |
| AttribWeight | ok |
| AttributeOffsetTbl | ok |
| CheckPenaltyScroll | ok |
| CheckPlayerListScroll | ok |
| CheckScoringScroll | ok |
| ClearLineArea | ok |
| ClearLineEditorTop | ok |
| ClearMenuFlags | ok |
| CrowdMeterScreen | ok |
| DecodeTeamLines | ok |
| DisplayGameInfo | ok |
| DisplayPenaltyEntry | ok |
| DisplayPenaltyLineDown | ok |
| DisplayPenaltyLineUp | ok |
| DisplayPlayerList | ok |
| DisplayPlayerListDown | ok |
| DisplayPlayerListUp | ok |
| DisplayTeamStatsScreen | ok |
| DrawGoalieSelectList | ok |
| DrawLineIcon | ok |
| DrawLineIcons | ok |
| DrawScoringRow | ok |
| DrawScoringRowDown | ok |
| DrawScoringRowUp | ok |
| DrawScrollArrows | ok |
| DrawScrollArrowsPenalty | ok |
| DrawStatsList | ok |
| DrawStatsListArrows | ok |
| DrawStatsRow | ok |
| DrawStatsRowDown | ok |
| DrawStatsRowUp | ok |
| DrawTeamScreen | ok |
| EncodeTeamLines | ok |
| ExitStatsScreen | ok |
| GameStatisticsScreen | ok |
| GetForwardCount | ok |
| GetGoalieCount | ok |
| GetNameandAttrib | ok |
| GetPlayerCount | ok |
| GetStatColumn | ok |
| GetStatsValue | ok |
| GoalTypeTbl | ok |
| GoalieRowText | ok |
| HandedTextTbl | ok |
| LineCursorTable | ok |
| LineEditor | ok |
| LineEditorExit | ok |
| LineEditorMenu | ok |
| LineEditorRedraw | ok |
| LineIconGroups | ok |
| LineIconPosTable | ok |
| MenuWaitVblankWrapper | ok |
| PenaltySummaryScreen | ok |
| PlayerStatMenuTxt | ok |
| PlayerStatsList | ok |
| PlayerStatsScreen | ok |
| PlayoffStatsScreen | ok |
| PrintAttribHeader | ok |
| PrintCrowdDB | ok |
| PrintCrowdMeter | ok |
| PrintGameInfo | ok |
| PrintScorerName | ok |
| PrintStatValue | ok |
| ReadStatColumn | ok |
| ScoringSummaryScreen | ok |
| ScrollArrowTable | ok |
| ScrollArrowTbl | ok |
| ScrollArrowTbl2 | ok |
| SelectGoalieMenu | ok |
| SelectLinePlayer | ok |
| SetLineSlot | ok |
| SetStatsListScrollReg | ok |
| SetupScreen | ok |
| ShowScores | ok |
| StatColumnHeaders | ok |
| StatColumnOffsets | ok |
| StatSortTitles | ok |
| StatsOffsetTbl2 | ok |
| StatusTextTbl | ok |
| StopPlayerListScroll | ok |
| TeamRosterScreen | ok |
| TeamStatTextTbl | ok |
| TimeoutMenu | ok |
| UpdatePenaltyScroll | ok |
| UpdatePlayerListScroll | ok |
| UpdateScoresScroll | ok |
| UpdateScoringScroll | ok |
| UpdateStatsListScroll | ok |
| UpdateVertScrollReg | ok |
| WaitVSyncAndReadInput | ok |
| attribjmp | ok |
| loopthroughplayers | ok |

## menu93

| name | verdict |
|---|---|
| DrawMenuScreen | ok |
| HandleMenuInput | ok |
| InitMenuState | ok |
| MenuWaitVblank | ok |
| PutTeamBlock | ok |
| SetMenuPrintX | ok |
| UpdateMenuSelection | ok |

## hockey93_02

| name | verdict |
|---|---|
| RestoreReplayFrame | ok |
| UpdateCameraPos | ok |
| rtss2 | ok |

## hockey93_03_05

| name | verdict |
|---|---|
| Bcheck | ok |
| ClampNibble | ok |
| GetPeriodTimeRemaining | ok |
| TryAddPlayerToList | ok |
| checkagr | ok |
| puckglue | ok |
| setInjuryType | ok |

## video93

| name | verdict |
|---|---|
| ButtonLabelCharTable | ok |
| DoDMAList | ok |
| IRQ7 | ok |
| QueuePadLabel | renamed from FormatControllerDisplay |
| RenderSmallFontChar | ok |

## teamdata93

| name | verdict |
|---|---|
| AllStarsEast | ok |
| AllStarsWest | ok |
| LongIsland | ok |
| NewYork | ok |
| Ottawa | ok |
| TampaBay | ok |

## hockey93_01

| name | verdict |
|---|---|
| CheckInjury | ok |
| CheckLateGameSong | renamed from CheckPeriodEnd |
| ChkShortPeriods | ok |
| ClearShotData | ok |
| EndDemoOnPress | renamed from HandleJoy1 |
| GetPeriodTime | ok |
| RestoreBenchEnergy | renamed from UpdateLineChange |
| SetupPauseScreen | ok |
| UpdateCwdExcite | ok |
| clockcont_0 | ok |
| seta2 | ok |

## logic93

| name | verdict |
|---|---|
| Acheck | ok |
| AdjustFacingDirection | ok |
| CalcAngleOffset | ok |
| ClampYPosition | ok |
| ClearMessageLine | renamed from ShowInjuryMsg |
| ClearOffsidesIfAllPlayers | ok |
| GoalieSaveList | ok |
| ResetAndSelectPlayers | ok |
| StopNA | ok |
| UnpackNibbles | ok |
| WeightedRandomSelect | ok |
| addinfo | ok |
| assgoalietopuck | ok |
| banner | ok |
| clrplayer | ok |
| holdplayer | ok |
| lcfound2 | ok |
| puckIChk | ok |
| shotdiradj | ok |
| skatetopuckinit | ok |

## penalty93

| name | verdict |
|---|---|
| AdvanceStringPtr | ok |
| CheckGameTickerStatus | ok |
| ClearPenaltyBuffer | ok |
| ClearPenaltyMessage | ok |
| ClearTickerArea | ok |
| DrawEASNMap | ok |
| PrintStringFromList | ok |
| PrintTeamLogoAndScore | ok |
| PrintTeamNameAndScore | ok |
| ProcessPenaltyList | ok |
| RemovePlayerFromList | ok |
| SetTickerAreaPosition | ok |
| SetupTeamForIntermission | ok |
| loadTeamStruct | ok |

## sram93

| name | verdict |
|---|---|
| BackupRAM_Load | ok |
| BackupRAM_Read | ok |
| BackupRAM_ReadAck | ok |
| BackupRAM_ReadBit | ok |
| BackupRAM_ReadBlock | ok |
| BackupRAM_Save | ok |
| BackupRAM_SendAck | ok |
| BackupRAM_SendNoAck | ok |
| BackupRAM_Start | ok |
| BackupRAM_Stop | ok |
| BackupRAM_WaitReady | ok |
| BackupRAM_WriteBit | ok |
| BackupRAM_WriteBlock | ok |
| InitBackupRAM | ok |
| ReadPad1Held | ok |

## graphics93

| name | verdict |
|---|---|
| EASNmap2 | ok |
| EnergyBarMap | ok |
| FrameDataOff | ok |
| GameSetupSprites | ok |
| HotList | ok |
| RefMap2 | ok |
| RonBarrMap | ok |
| ScoresMap | ok |
| SprDataBytes | ok |
| Title3Sprites | ok |
| TitleLogoSprites | ok |

## middle93

| name | verdict |
|---|---|
| ControlCodeJumpTable | ok |
| ControlCode_AddX | ok |
| ControlCode_AddY | ok |
| ControlCode_SetAttribute | ok |
| ControlCode_SetFont | ok |
| ControlCode_SetMap | ok |
| ControlCode_SetMapAndPosition | ok |
| ControlCode_SetX | ok |
| ControlCode_SetY | ok |
| CopyBackwardReverseRun | ok |
| CopyBackwardRun | ok |
| CopyPaletteToCRAM | ok |
| DecompressBytecode | ok |
| DecompressGraphics | ok |
| DecompressGraphicsPlain | renamed from DoDMA_clearCallbackPointer |
| DecompressGraphicsWithCallback | ok |
| DoDMA_nd2 | ok |
| FlushOutputBuffer | ok |
| FormatAndPrintTime | ok |
| Opcode_ClearBytes | ok |
| Opcode_CopyBackwardExtended1 | ok |
| Opcode_CopyBackwardExtended2 | ok |
| Opcode_CopyBackwardLong | ok |
| Opcode_CopyBackwardMedium | ok |
| Opcode_CopyBackwardReverseLong | ok |
| Opcode_CopyBackwardReverseMedium | ok |
| Opcode_CopyBackwardReverseShort | ok |
| Opcode_CopyBackwardShort | ok |
| Opcode_CopyLiteral | ok |
| Opcode_Fillbytes | ok |
| PeriodLabelTable | ok |
| ProcessInputWithRepeat | ok |
| PushNumberWidth | ok |
| Readjoy1 | ok |
| Readjoy2 | ok |
| jump_table | ok |
| printsmall | ok |
| printsmallz | ok |
| setVram_0 | ok |
| sroot | ok |

## sound93

| name | verdict |
|---|---|
| ClearAllTrackAndSFXSlots | ok |
| ProcessOneMusicTrack | ok |
| ReleaseChannelAndNote | ok |
| ScoutingReportText | ok |
| SoundStreamTable | renamed from MusicTrackPointerTable |
| StopPCMChannel | renamed from ClearZ80SpecialEffectsFlags |
| UpdateChannelFrequencyAndVolume | ok |
| UploadCommandBufferToZ80 | ok |
| command_jump_table | ok |
| fm_instrument_patches | ok |
| fmtune_eop_cmdstream | ok |
| fmtune_faceoff_cmdstream | ok |
| fmtune_goal_cmdstream | ok |
| fmtune_lategame_cmdstream | ok |
| fmtune_periodstart_cmdstream | ok |
| fmtune_powerplay_cmdstream | ok |
| fmtune_scouting_cmdstream | ok |
| fmtune_title_cmdstream | ok |
| fmtune_title_loop | ok |
| handle_command_00 | ok |
| handle_command_10 | ok |
| handle_command_40 | ok |
| handle_command_60 | ok |
| handle_command_skip | ok |
| pcm_sample_table | ok |
| play_sfx_or_music_track | ok |
| sfx_check1_cmdstream | ok |
| sfx_check2_cmdstream | ok |
| sfx_check2_pcm | ok |
| sfx_check3_cmdstream | ok |
| sfx_check4_cmdstream | ok |
| sfx_crowdboo_cmdstream | ok |
| sfx_crowdcheer_cmdstream | ok |
| sfx_crowdcheer_pcm | ok |
| sfx_hithigh_cmdstream | ok |
| sfx_hithigh_pcm | ok |
| sfx_hitlow_cmdstream | ok |
| sfx_homewin_cmdstream | ok |
| sfx_oooh2_cmdstream | ok |
| sfx_bglass_cmdstream | ok |
| sfx_bglass_pcm | ok |
| sfx_playerwall2_cmdstream | ok |
| sfx_playerwall3_cmdstream | ok |
| sfx_playerwall4_cmdstream | ok |
| sfx_id_26_27_cmdstream | ok |
| sfx_oooh_cmdstream | ok |
| sfx_pass1_cmdstream | ok |
| sfx_pass2_cmdstream | ok |
| sfx_pass3_cmdstream | ok |
| sfx_pass4_cmdstream | ok |
| sfx_pass_pcm | ok |
| sfx_playerwall_cmdstream | ok |
| sfx_playerwall_pcm | ok |
| sfx_puckbody_cmdstream | ok |
| sfx_puckget_cmdstream | ok |
| sfx_puckice1_cmdstream | ok |
| sfx_puckice2_cmdstream | ok |
| sfx_puckice3_cmdstream | ok |
| sfx_puckice4_cmdstream | ok |
| sfx_puckpost_cmdstream | ok |
| sfx_puckwall1_cmdstream | ok |
| sfx_puckwall3_cmdstream | ok |
| sfx_puckwall4_cmdstream | ok |
| sfx_shotbh1_cmdstream | ok |
| sfx_shotbh2_cmdstream | ok |
| sfx_shotbh3_cmdstream | ok |
| sfx_shotbh4_cmdstream | ok |
| sfx_shotbh_pcm | ok |
| sfx_shotfh1_cmdstream | ok |
| sfx_shotfh2_cmdstream | ok |
| sfx_shotfh3_cmdstream | ok |
| sfx_shotfh4_cmdstream | ok |
| sfx_shotfh_pcm | ok |
| sfx_siren_cmdstream | ok |
| sfx_whistle_cmdstream | ok |
| stop_current_song | renamed from play_new_song |
| z80_bus_release_delay | ok |

## frames93

| name | verdict |
|---|---|
| SPAbglass | ok |
| SPAbglass_table | ok |
| SPAcatch | ok |
| SPAcatch_table | ok |
| SPAfake | ok |
| SPAfake_table | ok |
| SPAfinjury | ok |
| SPAfinjury_table | ok |
| SPAflip | ok |
| SPAflip_table | ok |
| SPAgdive | ok |
| SPAgdive_table | ok |
| SPAgglovel2 | ok |
| SPAgglovel2_table | ok |
| SPAgready2 | ok |
| SPAgready2_table | ok |
| SPAhook | ok |
| SPAhook2 | ok |
| SPAhook2_table | ok |
| SPAhook_table | ok |
| SPAinjury1 | ok |
| SPAinjury1_table | ok |
| SPAstumble | ok |
| SPAstumble_table | ok |
| SPFbglass | ok |
| SPFcatch | ok |
| SPFfinjury | ok |
| SPFflip | ok |
| SPFgdive | ok |
| SPFglovel2 | ok |
| SPFgready | ok |
| SPFhold | ok |
| SPFhook | ok |
| SPFinjury1 | ok |
| SPFreplay | ok |
| SPFstumble | ok |

## hockey93_06_11

| name | verdict |
|---|---|
| AddPlayoffTeamStats | ok |
| AddTeamSpriteFrame | ok |
| AddTitleLogoSprites | ok |
| BitWidthTable | ok |
| CalcStarScores | ok |
| CalcTeamStarScores | ok |
| CallAnimationCallback | ok |
| CheckSound | ok |
| ClearRosterName | renamed from ClearOptionDisplay |
| ContinuePlayoffs | ok |
| ConvertByteToDigits | renamed from ConverByteToDigits |
| CopyTeamBlockMapData | ok |
| DrawTeamBlocks | ok |
| DrawTreeArrow | ok |
| EndSpriteList | ok |
| ExitGameText | ok |
| ExitGameTextPO | ok |
| ExitToOpening | ok |
| FinalizeTextBuffer | ok |
| FormatPlayerName | ok |
| FormatPlayerNameShort | ok |
| FormatPlayerNumInitial | ok |
| GAttribColumns | ok |
| GetPlayerName | ok |
| GetPlayerNamePointer | ok |
| GetPlayerNumInitial | ok |
| GetRandomUnusedTeam | ok |
| GetRosterEntry | ok |
| GoalBoxText | ok |
| GoalieRosterAnims | ok |
| HandlePlayoffInput | ok |
| InitScoutingDisplay | ok |
| InitTeamStructure | ok |
| InitializeGameStructures | ok |
| IntermissionStart | ok |
| IntermissionText | ok |
| LineEditorMenuNoLoad | renamed from ExitAttribText |
| LineEditorMenuText | renamed from AttributeScreenText |
| PAttribColumns | ok |
| PauseText | ok |
| PauseText2 | ok |
| PickRosterAnim | ok |
| PickStartingGoalie | renamed from SetGoalieMode |
| PlayerPositionText | ok |
| PlayoffScreenExit | ok |
| PlayoffScreenText | ok |
| PlayoffScreen_waitvsync | ok |
| PlayoffTreeSetup | ok |
| PrintScoutLineRatings | ok |
| PrintScoutRatings | ok |
| PrintSeriesScore | ok |
| PrintStatNumber | ok |
| ReadTeamStats | ok |
| RosterAnimScripts | ok |
| RosterOrderTable | ok |
| ScoutRatingText | renamed from StatsText |
| ScrollDisplayUp | ok |
| SetupNextPlayer | ok |
| SetupStanleyCupCelebrationScreen | ok |
| ShowGoalBox | ok |
| ShowInjuryBox | ok |
| ShowThreeStars | ok |
| SkaterRosterAnims | ok |
| SlideOutRosterPlayer | renamed from ClearAndSetFlag |
| StanleyCupPosTable | ok |
| StartGameText | ok |
| StartGameTextPO | ok |
| StatNextLine | ok |
| TakeTopStarScore | ok |
| TitleAnimCallback | ok |
| TitlePalettes | ok |
| TitleScreen_wait | ok |
| TitleScrollTriggers | ok |
| UpdateHorizontalScroll | ok |
| UpdatePlayoffLevel | ok |
| UpdatePlayoffScroll | ok |
| UpdateRosterPlayer | ok |
| UpdateRosterPlayers | renamed from UpdateBothTeamDisplays |
| UpdateScoutingDisplay | ok |
| UpdateStanleyCupAnimation | ok |
| UpdateTeamSprites | ok |
| VBlank_Playoff | ok |
| VBlank_SetOptions | ok |
| VBlank_StanleyCup | ok |
| VBlank_TitleScreen | ok |
| box | ok |
| cd0 | ok |
| clearTeamStats | ok |
| defaultsprites2 | ok |
| getname | ok |
| maketree | ok |
| setoptions_printpos2 | ok |
| setupEASNmap | ok |
| setupIceRinkPal | renamed from setupIceRinkMap |
| setupTeamBlocksMap | ok |
| setupice_highlight | ok |

## ram93

| name | verdict |
|---|---|
| AwayTeamRosterPtr | ok |
| BackupRAM_Port | ok |
| BigFontChars | ok |
| CC_AddX | ok |
| CC_AddY | ok |
| CC_SetAttribute | ok |
| CC_SetFont | ok |
| CC_SetMap | ok |
| CC_SetMapAndPosition | ok |
| CC_SetX | ok |
| CC_SetY | ok |
| CameraPosStruct | ok |
| ChkCnt | ok |
| CwdExciteLvl | ok |
| DMAListend | ok |
| DMA_IN_PROGRESS | ok |
| DispAttribCtr | kept: multi-use scratch (stats sort column, ring buffer, cursor); no single accurate name |
| FIFO_EMPTY | ok |
| FIFO_FULL | ok |
| Framercset | ok |
| GoalieStruct | ok |
| HBLANKING | ok |
| HmAwBonus | ok |
| HomeTeamRosterPtr | ok |
| IO_CT1_RX | ok |
| IO_CT1_SMODE | ok |
| IO_CT1_TX | ok |
| IO_CT2_RX | ok |
| IO_CT2_SMODE | ok |
| IO_CT2_TX | ok |
| IO_EXT_CTRL | ok |
| IO_EXT_DATA | ok |
| IO_EXT_RX | ok |
| IO_EXT_SMODE | ok |
| IO_EXT_TX | ok |
| IO_FDC | ok |
| IO_PCBVER | ok |
| IO_RAMMODE | ok |
| IO_TIME | ok |
| IO_TMSS | ok |
| InitialSP | ok |
| InjCntDown | ok |
| M68K_RAM | ok |
| MaxCwdExciteLvl | ok |
| NumCwdExciteLvl | ok |
| ODD_FRAME | ok |
| OptPerlen | ok |
| PAL_MODE | ok |
| PKBonus | ok |
| PPBonus | ok |
| PadControlBits | ok |
| PalMode | renamed from music_global_tick_counter |
| PenSum | ok |
| PenSumLength | ok |
| PenaltyBufferEnd | ok |
| Pencntdwn | ok |
| PerTimeTotal | ok |
| PlayerScrollCtr | ok |
| PushNumberBuf | ok |
| PushWidthBuf | ok |
| SFXoooh2 | ok |
| SFXbglass | ok |
| SFXplayerwall2 | ok |
| SFXplayerwall3 | ok |
| SFXplayerwall4 | ok |
| SFX26 | ok |
| SFX27 | ok |
| SFXhomewin | ok |
| SPRITE_COLLISION | ok |
| SPRITE_OVERFLOW | ok |
| ScoreSum | ok |
| ScoreSumbytes | ok |
| ScoutingReportTimer | ok |
| SelectedPlayerIdx | ok |
| SngScout | ok |
| SumCwdExciteLvl | ok |
| TeamBlockMap | ok |
| TempPlOffset | ok |
| TestList | kept: multi-use scratch (stats sort column, ring buffer, cursor); no single accurate name |
| TextBuffer | ok |
| ThirdPBonus | ok |
| TitlePalBuffer | renamed from titleScreenState |
| VBLANKING | ok |
| VBLANK_PENDING | ok |
| VDP_CNTR | ok |
| VDP_PSG | ok |
| VDP__CNTR | ok |
| VDP__CTRL | ok |
| VDP__DATA | ok |
| VDP___CNTR | ok |
| VDP____CNTR | ok |
| VertLineScrolling | ok |
| VmMap1 | ok |
| VmMap2 | ok |
| VmMap3 | ok |
| Z80_RAM | ok |
| Z80_command_buffer | ok |
| address | ok |
| address2 | ok |
| animchars | renamed from gamesetuptilesetindex |
| awtmstruct | ok |
| basetileoffset | ok |
| bufferptr | ok |
| byecount | ok |
| bytecount | ok |
| callbackPtr | ok |
| clampcounter | ok |
| command | ok |
| crowdcnt | ok |
| crowdframe | ok |
| crowdlevel | ok |
| crowdstep | ok |
| databuffer | ok |
| energybarchars | ok |
| errorflag | ok |
| errorflag2 | ok |
| fm_channel_structs | ok |
| fm_track_slots | ok |
| fm_voice_usage_table | ok |
| fofdata2 | ok |
| glovestruct | ok |
| icingPlayer | ok |
| marker | ok |
| menudraw | ok |
| menuitem | ok |
| menulist | ok |
| music_needs_z80_update | ok |
| music_tick_divider | ok |
| nibblebuffer | ok |
| oldvcount | ok |
| outputbuffer | ok |
| palbuffer | ok |
| passReceiverPlayerNum | ok |
| pcm_channel_struct | ok |
| penmsgtimer | ok |
| per_channel_attenuation_table | ok |
| per_channel_frequency_table | ok |
| per_channel_patch_table | ok |
| periodendtime | ok |
| playoffspritex | ok |
| playoffspritey | ok |
| printfontset | ok |
| pwddatabuffer | ok |
| redrawicons | ok |
| repeatdelayframes | ok |
| replayactive | ok |
| retrycount | ok |
| screentimer | ok |
| smallfont2chars | ok |
| spritechars | ok |
| sramdataptr | ok |
| statsbuffer | ok |
| vbint | ok |
| vcount | ok |
| zamx | ok |

## Local labels

Number-only locals per module (before -> after). Data-table locals (frames93, teamdata93) stay numeric as in 92.

| module | before | after | notes |
|---|---|---|---|
| menu93 | 16 | 6 | PutTeamBlock header: TeamBlockMap instead of RAM address |
| stats93 | 71 | 41 | SelectGoalieMenu header: tmgoalie(a2) |
| hockey93_01 | 9 | 8 | Pausemode menu loop .loop; rest are 92 parent locals |
| logic93 | 72 | 71 | banner .find; rest 92 parent locals or trivial (ClampYPosition, Acheck, addinfo) |
| hockey93_06_11 | 30 | 30 | 92 parent locals (defaultsprites .0, vblank wait .0); clearTeamStats header: tmgoalie |
| hockey93_02 | 14 | 14 | 92 parent locals; UpdateCameraPos clamps trivial |
| hockey93_03_05 | 35 | 35 | 92 parent locals; setInjuryType trivial |
| middle93 | 34 | 34 | 92 parent locals (printsmall uses print's, setVram_0 uses setVram's) |
| penalty93 | 31 | 31 | 92 parent locals or trivial skips |
| video93 | 12 | 12 | 92 parent locals |
| frames93 | 488 | 488 | data table indices, as in 92 |
| teamdata93 | 26 | 26 | team data .0, as in 92 |
| total | 838 | 795 | |
