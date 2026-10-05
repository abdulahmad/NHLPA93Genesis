;	ROM map: retail nhlpa93retail.bin addresses (inclusive) for every include.
;	Boundaries are routine starts checked against the ROM bytes. 92 = the NHL 92
;	file/part the code comes from. See SEGMENT_AGENT.md "ROM map".

	include	Main93.Asm		;EA provided code for startup and EA logo
					;$000000-$00030F  vectors, header, SegaInit, Start
	include	TeamData93.Asm		;$000310-$004D8D
	include	Frames93.Asm		;graphics data table for Sprites.anim
					;$004D8E-$006445  SPAList
	include	Ram93.Asm			;ram allocation and some equates	
					;no ROM bytes (equates only)

					;92 hockey.asm part 1 (Begin ... updateanim), with 93 menus/stats inserted
	include hockey93_01.asm		;$006446-$0069FF  VBjsr, Begin ... Pausemode (92 PauseExit), SetupPauseScreen, seta2
	include menu93.asm		;$006A00-$006C09  93 only: InitMenuState ... MenuWaitVblank (menu engine)
	include stats93.asm		;$006C0A-$008AC3  93 only: stats, attribute, game info screens
	include hockey93_02.asm		;$008AC4-$00946D  ReplayMode ... updatereplay, updateplayers, updateanim, freezewindow, checkwindow

;	include logic93.asm		;$00946E-$00D629  92 logic.asm
 	include logic93_1.asm		;$00946E-$00A0FB  doinput ... check4bench
 	include logic93_2.asm		;$00A0FC-$00AE87  assbench ... asswingd
 	include logic93_3.asm		;$00AE88-$00BC6B  asswingo ... EvadePC
 	include logic93_4.asm		;$00BC6C-$00C9E9  checkob ... pucknorm
 	include logic93_5.asm		;$00C9EA-$00D629  ChkOffsides ... dirtab, 93 nibble/random helpers
;	include middle93.asm		;$00D62A-$00E525  92 middle.asm
 	include middle93_1.asm		;$00D62A-$00DCE3  remap ... Vmaddr
 	include middle93_2.asm		;$00DCE4-$00E525  dobitmap ... AddTeamBlock
;	include penalty93.asm		;$00E526-$00FAE1  92 Penalty.asm (Penaltylist data moved to hockey93_11)
 	include penalty93_1.asm		;$00E526-$00EFA7  AddPenalty ... SetHor
 	include penalty93_2.asm		;$00EFA8-$00FAE1  printscores1 ... StartHL2

					;92 hockey.asm part 2 (checkcoll ... deflect)
	include hockey93_03.asm		;$00FAE2-$010387  checkcoll ... FallDown
	include hockey93_04.asm		;$010388-$010E65  checkfight ... checkpuckcoll
	include hockey93_05.asm		;$010E66-$011801  puckstick ... deflect, then makepde ... setplayer (92 part 3, moved here)

;	include video93.asm		;$011802-$0122A7  92 Video.asm
 	include video93_1.asm		;$011802-$011D09  VBlank ... showcrowd
 	include video93_2.asm		;$011D0A-$0122A7  showclock ... KillCrowd

					;92 hockey.asm part 3 (setupice ... crash), then 93 data tables
	include hockey93_06.asm		;$0122A8-$012E25  setupice ... PeriodOver, Opening, PlayoffScreen
	include	hockey93_07.asm		;$012E26-$013951  ScoutingReport, StanleyCup screen, TitleScreen, CallAnimationCallback, CheckSound
	include hockey93_08.asm		;$013952-$014403  setoptions ...
	include hockey93_09.asm		;$014404-$01499D  DefaultMenus, NewPO, MakeTree, FigureJoy, password code
	include hockey93_10.asm		;$01499E-$015109  ResolveGames ... exception handlers, crash
	include hockey93_11.asm		;$01510A-$015FE5  data: cd0, asstab, PenaltyList, bfasciicon, linelist,
					;  PerLabels, sizetab, sublist, priolist, menu/pause text
	
	include sram93.asm		;$015FE6-$0165D7  93 only: BackupRAM_*, BitsToPW, ClearRAMBuffer, ClearVRAM
	include sound93.asm		;$0165D8-$02EFA1  sound driver (68k code, Z80 blob at $016E53, sound data)
	include graphics93.asm	;$02EFA2-$07FB75  graphics data (92 incbins after hockey.asm part 3)
	include checksum93.asm		;$07FB76-$07FBC7  SecurityCheck, ValidationRoutine
					;$07FBC8-$07FFFF  $FF fill