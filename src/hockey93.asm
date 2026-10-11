;	ROM map: retail nhlpa93retail.bin addresses (inclusive) for every include.
;	Boundaries are routine starts checked against the ROM bytes. 92 = the NHL 92
;	file/part the code comes from. See SEGMENT_AGENT.md "ROM map".
;	Top level of the full ROM build (build93.bat, npm run build:retail), like 92 hockey.asm. Ram93.Asm holds
;	the ports, RAM map and structure equates; each *_stub.asm includes it for a single segment build.

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

	include logic93.asm		;$00946E-$00D629  92 logic.asm: doinput ... dirtab, 93 nibble/random helpers (was logic93..5)
	include middle93.asm		;$00D62A-$00E525  92 middle.asm: remap ... AddTeamBlock (was middle93..2)
	include penalty93.asm		;$00E526-$00FAE1  92 Penalty.asm: AddPenalty ... StartHL2 (was penalty93..2; Penaltylist data in hockey93_06_11)

					;92 hockey.asm part 2 (checkcoll ... deflect)
	include hockey93_03_05.asm		;$00FAE2-$011801  checkcoll ... setplayer (was hockey93_03_05..05; contiguous)

	include video93.asm		;$011802-$0122A7  92 Video.asm: VBlank ... KillCrowd (was video93..2)

					;92 hockey.asm part 3 (setupice ... crash), then 93 data tables
	include hockey93_06_11.asm		;$0122A8-$015FE5  setupice ... PlayoffScreen, ScoutingReport, setoptions, playoffs/password, ResolveGames, data tables (was hockey93_06_11..11; contiguous)
					;  PerLabels, sizetab, sublist, priolist, menu/pause text
	
	include sram93.asm		;$015FE6-$0165D7  93 only: BackupRAM_*, BitsToPW, ClearRAMBuffer, ClearVRAM
	include sound93.asm		;$0165D8-$02EFA1  sound driver (68k code, Z80 blob at $016E53, sound data)
	include graphics93.asm	;$02EFA2-$07FB75  graphics data (92 incbins after hockey.asm part 3)
	include checksum93.asm		;$07FB76-$07FBC7  SecurityCheck, ValidationRoutine
	dcb.b	$80000-*,$FF		;$07FBC8-$07FFFF  $FF fill (92 dcb.b after include checksum.asm)