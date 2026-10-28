;	Main game source and top level of the ROM build. It includes the other modules in ROM order and holds the
;	core game code: startup, the game loop, pause and replay, players, collisions, and the title, playoff,
;	scouting and setup screens.
;
;	REV selects the revision: REV=0 is Rev 0 (v1.0, the retail ROM, serial -00), REV=1 is Rev A (v1.1,
;	serial -01) and REV=2 is Rev B (v1.2, 1993.FEB). Differences from 92 are noted in the comments.
;
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx) but SNASM emits CMPI (0Cxx). The source has the real cmp,
;	and fixopcodes.js patches the encoding after assembly.

	include	Main93.Asm				;EA provided code for startup and EA logo
	;null, TeamList ... CreditsPages: src/teamdata93.asm with the real player names put back by tools/build.js (it has
	;placeholders in git and needs the ROM, see its header)
	;this build's copy (TeamData93Asm, a string equate used as \TeamData93Asm): dev is the only build with CHECKSUM=0 (REV=1), the retail builds go by REV
	IF CHECKSUM=0 ; dev
TeamData93Asm	equs	"..\output\dev\obj\TeamData93.Asm"
	ELSEIF REV=0 ; retail (Rev 0)
TeamData93Asm	equs	"..\output\retail\obj\TeamData93.Asm"
	ELSEIF REV=1 ; Rev A
TeamData93Asm	equs	"..\output\reva\obj\TeamData93.Asm"
	ELSE ; Rev B (REV=2)
TeamData93Asm	equs	"..\output\revb\obj\TeamData93.Asm"
	ENDIF
	include	\TeamData93Asm
	include	Frames93.Asm			;graphics data table for Sprites.anim
	include	Ram93.Asm				;ram allocation and some equates	
					;no ROM bytes (equates only)

;------------------------------------------------------------
;	Startup, game loop, clock and pause screen
;------------------------------------------------------------

VBjsr								;Vertical blank interrupt (vector $78), jumps through the VBint RAM vector
	move.l	(VBint).w,-(sp)			;push handler address
	rts								;and "return" into it

Begin								;cold start, entered from Reset. Clear RAM, init menus and sound, go to
									;title
	move	#$2700,sr				;interrupts off
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0	;clear out ram
.0	clr.l	(a0)+					;clear 4 bytes of ram per pass
	cmpa.w	#(fm_track_slots+(8*6)-M68K_RAM),a0	;clear to the end of the track slots
	blt.s	.0
	IF REV>=1
	move.w	(Vctrl).l,d0			;Rev A: VDP status bit 0 = PAL (50 Hz)
	andi.w	#1,d0
	move.w	d0,(PalMode).w
	ENDIF

	IF REV=2
	jsr	p_initialZ80				;sound stuff (Rev B does the sound set up first and calls KillCrowd here)
	jsr	p_turnoff
	jsr	p_music_vblank
	jsr	KillCrowd
	jsr	(SetupStanleyCupCelebrationScreen).l
	jsr	(BackupRAM_Read).l
	jsr	DefaultMenus				;set initial menu choices
	jsr	orjoy						;clear any previous button presses
	jmp	(Opening).l					;goto title screen and options etc.
	ELSE
	jsr	(SetupStanleyCupCelebrationScreen).l
	jsr	(BackupRAM_Read).l
	jsr	DefaultMenus				;set initial menu choices
	jsr	orjoy						;clear any previous button presses
	jsr	p_initialZ80				;sound stuff
	jsr	p_turnoff					;sound stuff
	jsr	p_music_vblank				;sound stuff
	jmp	(Opening).l					;goto title screen and options etc.
	ENDIF
;----------------------------------------------------

ChkShortPeriods						;Pad 1 = $E0 at game start forces 30 second periods
	bsr.w	ReadJoy1
	cmp.b	#$E0,d3
	bne.w	StartGame
	move.w	#3,(Optperlen).w		;period length index 3 = 30

StartGame							;reset game state for a new game, then start the first period
	clr.b	(gmode).w
	cmpi.w	#1,(OptPen).w
	bne.w	.0
	bset	#gmoffs,(gmode).w		;offsides pen. is active
.0	cmpi.w	#1,(OptPlayMode).w		;OptPlayMode test (shot buffer)
	ble.w	.1						;OptPlayMode 0-1 keep the shot buffer
	bsr.w	ClearShotData
.1	jsr	(clearTeamStats).l			;reset team stats
	clr.w	(ScoreSumbytes).w
	clr.w	(PenSumLength).w
	clr.w	(gsp).w					;first period
	clr.w	(ChkCnt).w
	bsr.w	restoreteams
	jsr	(InitScores).l
	jsr	setupice
	jmp	(IntermissionStart).l		;on to period start

ClearShotData						;clear the 49 words of outputbuffer (the shot data)
	moveq	#$30,d0
	movea.w	#(outputbuffer-M68K_RAM),a0	;shot data buffer
.0	clr.w	(a0)+					;clear one word
	dbf	d0,.0
	rts

restoreteams						;Put both teams' rosters on the bench
	movea.w	#(tmstruct-M68K_RAM),a2	;team 1
	bsr.w	.r
	adda.w	#tmsize,a2				;team 2
.r									;Reset one team struct (a2), falls in for team 2
	move.w	#6,tmap(a2)				;no players in pen. box
	moveq	#(maxros-1)*2,d0		;(maxros-1)*2
.0	move.w	#$FFFE,tmpdst(a2,d0.w)	;all players on bench
	subq.w	#2,d0
	bpl.s	.0
	rts

ResetClock							;set period length and stop clock
	bsr.w	GetPeriodTime			;d0 = period length in seconds
	cmpi.w	#3,(gsp).w				;overtime?
	blt.w	.set
	tst.w	(OptPlayMode).w
	bne.w	.set
	move.w	#$258,d0				;OptPlayMode 0 overtime is always 10:00
.set	move.w	d0,(gameclock).w	;d0 = period length in seconds
	move.w	d0,(PerTimeTotal).w
	move.w	d0,(periodendtime).w	;CheckLateGameSong trigger time =
	asr.w	#1,d0
	bsr.w	randomd0
	sub.w	d0,(periodendtime).w	;length - random(length/2)
	bset	#gmclock,(gmode).w		;stop clock
	rts

GetPeriodTime						;from 92 ResetClock (period length lookup). return d0 = period length in
									;seconds for the period length option
	move.w	(Optperlen).w,d0
	asl.w	#1,d0
	lea	.timetab(pc),a0
	move.w	0(a0,d0.w),d0
	rts
.timetab							;Period length in seconds: 5, 10, 20 min, 30 sec
	dc.w	5*60,10*60,20*60,30

StartPer							;start a period: reset stack, rink and clock, face off, run the game loop
	movea.w	#(Stack-M68K_RAM),sp
	jsr	p_turnoff					;sound off
	jsr	setupice
	bsr.s	ResetClock
	ori.w	#$F000,(PadControlBits).w
	st	(c1playernum).w				;no controlled player yet
	st	(c2playernum).w
	movea.w	#(puckx-M68K_RAM),a3	;puck
	clr.w	(fox).w					;face off at center ice
	clr.w	(foy).w
	move.l	#pfaceoff,d0			;pfaceoff
	bsr.w	assreplace				;face off starts period
	bset	#sf2drec,(sflags2).w	;don't record
	bclr	#sfwrap,(sflags).w		;reset replay stuff
	move.w	#$FFFF,(lastsfx).w
	move.l	#M68K_RAM,(recbpr).w
	move.w	(Vcount).w,(OldVcount).w
	bsr.w	DoGameFrame				;run two frames before the loop
	bsr.w	DoGameFrame
	move.w	(gamelevel).w,d0
	asl.w	#4,d0
	move.w	d0,(CwdExciteLvl).w		;starting excitement = gamelevel*16
	move.w	#SngPeriodStart,-(sp)	;period start tune
	bsr.w	song
	cmpi.w	#2,(gsp).w
	bge.w	Gameloop
	bset	#sf3fosong,(sflags3).w	;set for periods 1 and 2 only

Gameloop							;main loop for game
	bsr.w	DoGameFrame
	bsr.w	demoread				;check if demo mode
	btst	#sfpz,(sflags).w
	beq.s	Gameloop
	bsr.w	Pausemode
	bra.s	Gameloop

DoGameFrame							;wait for at least one vblank, then run one frame of game logic
	move.w	(Vcount).w,d7
	sub.w	(OldVcount).w,d7		;number of frames since last loop
	beq.s	DoGameFrame
	move.w	(Vcount).w,(OldVcount).w
	bsr.w	periodicevents
	bsr.w	updateplayers			;apply velocity and check collisions
	bsr.w	checkwindow
	bsr.w	updatereplay
	jmp	(setvideo).l

periodicevents						;called every time thru game loop with d7 = elapsed frames
	jsr	(PenaltyManager).l
	bsr.w	updatecrowdf
	jsr	updatesound
	bsr.w	clockcont
	btst	#sfhor,(sflags).w
	bne.w	rtss2					;exit if in horizontal mode
	sub.w	d7,(lldisp).w			;count down for screen updates
	bpl.w	rtss2
	addi.w	#jps,(lldisp).w			;jps: only update once per second
	bsr.w	ChkGoalies
	bsr.w	UpdateCwdExcite
	bsr.w	CheckLateGameSong
	bsr.w	RestoreBenchEnergy
	bsr.w	CheckInjury
	jmp	(updatepwrplay).l

CheckInjury							;called once per second. Count down InjCntDown, act on it at zero
	subq.w	#1,(InjCntDown).w
	bne.w	rtss2
	jmp	(ShowInjuryBox).l			;countdown expired

RestoreBenchEnergy					;from 92 periodicevents tail (.notinprog). called once per second. Restore
									;energy for players on the bench
	tst.w	(OptLine).w
	bne.w	.x						;exit if line changes are off
	movea.w	#(tmstruct-M68K_RAM),a2	;team 1
	bsr.w	.team
	lea	tmsize(a2),a2				;team 2
.team	moveq	#(maxros-1)*2,d0	;(maxros-1)*2
.b0	cmpi.w	#$FFFE,tmpdst(a2,d0.w)	;on bench?
	bne.w	.next
	addi.w	#9,tmpde(a2,d0.w)		;energy +9
	cmpi.w	#$1000,tmpde(a2,d0.w)
	blt.w	.next
	move.w	#$1000,tmpde(a2,d0.w)	;max energy
.next	subq.w	#2,d0				;next roster slot
	bpl.s	.b0
.x	rts								;done

CheckLateGameSong					;called once per second. 3rd period: play tune $32 once at the random
									;trigger time set by ResetClock
	cmpi.w	#2,(gsp).w				;3rd period only
	bne.w	.x
	btst	#gmhl,(gmode).w
	bne.w	.x
	move.w	(gameclock).w,d0
	cmp.w	(periodendtime).w,d0
	bgt.w	.x						;not there yet
	st	(periodendtime).w			;high byte $FF: trigger goes negative, fires once
	move.w	#SngLateGame,-(sp)
	bsr.w	song
.x	rts								;return

UpdateCwdExcite						;called once per second. Track peak and running total of crowd excitement,
									;then decay the level by 1 (floor 0)
	move.w	(CwdExciteLvl).w,d0
	cmp.w	(MaxCwdExciteLvl).w,d0
	bls.w	.nomax
	move.w	d0,(MaxCwdExciteLvl).w	;new peak
.nomax	ext.l	d0					;running total of the level
	add.l	d0,(SumCwdExciteLvl).w	;running total
	addq.w	#1,(NumCwdExciteLvl).w	;sample count
	subq.w	#1,(CwdExciteLvl).w		;decay
	bpl.w	.x
	clr.w	(CwdExciteLvl).w
.x	rts								;return

updatecrowdf						;this is called every game loop with d7 = elapsed frames this will update
									;the current frame of crowd animation
	cmpi.w	#$15E,(Crowdlevel).w
	blt.w	.dec
	subq.w	#3,(Crowdlevel).w		;loud crowd calms down faster
.dec	sub.w	d7,(Crowdlevel).w	;crowd level decays by the elapsed frames
	bpl.w	.0
	clr.w	(Crowdlevel).w
.0	sub.w	d7,(Crowdcnt).w			;count down to the next crowd animation step
	bpl.w	.cf
	move.w	(Crowdlevel).w,d0
	lsr.w	#1,d0
	cmp.w	#127,d0
	bls.w	.1
	moveq	#$7F,d0
.1	andi.w	#$60,d0					;%01100000
	addq.w	#2,(Crowdstep).w
	andi.w	#$1E,(Crowdstep).w		;%00011110
	add.w	(Crowdstep).w,d0
	movea.l	#cd0,a0					;$fftt frame/time table
	move.b	0(a0,d0.w),(Crowdframe+1).w
	clr.w	d1
	move.b	1(a0,d0.w),d1
	move.w	(HVcount).l,d2			;HVcount
	and.w	d1,d2					;random 0..time
	add.w	d2,d1
	move.w	d1,(Crowdcnt).w			;time + random
.cf	clr.b	(Crowdframe).w			;no extra frame unless the crowd is loud
	cmpi.w	#$118,(Crowdlevel).w	;280
	bls.w	rtss2
	move.w	(HVcount).l,d0			;HVcount
	andi.w	#$7F,d0
	cmp.w	#19,d0
	blt.w	rtss2
	cmp.w	#25,d0
	bgt.w	rtss2
	move.b	d0,(Crowdframe).w		;random extra frame 19-25 when crowd is loud
	rts

clockcont							;monitor period clock and initiate various clock activated events
	btst	#gmclock,(gmode).w
	bne.w	rtss2
	tst.w	(gameclock).w
	bne.w	rtss2

	move.w	#SFXhorn,-(sp)			;horn (92 used 24)
	bsr.w	sfx
	bsr.w	freezewindow
clockcont_0							;from 92 clockcont. end of period. Also entered from puckfaceoff
	movea.w	#(puckx-M68K_RAM),a3	;puck
	move.l	#$18,d0
	bsr.w	assinsert
	cmpi.w	#2,(gsp).w				;periods 1-2 just end the period
	blt.w	.chkot
	move.l	#7,d0					;score assignment (92 used 8)
	movea.w	#(SortCords-M68K_RAM),a3
	cmpi.w	#3,(gamelevel).w		;playoffs?
	bne.w	.t3
	cmpi.w	#7,(bosgames).w
	beq.w	.sc						;bosgames 7 skips the series check

	;Stanley Cup if the winning team already has 3 series wins
	moveq	#gssize,d3				;game struct size
	mulu.w	(gamenum).w,d3
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d3,a0
	clr.w	d3
	btst	#gsftf,gsflags(a0)		;teams flipped in this game?
	beq.w	.nf
	eori.w	#2,d3					;swap sides
.nf	move.w	(tmstruct+tmscore).w,d1	;d1 = home score - away score
	sub.w	(awtmstruct+tmscore).w,d1
	bpl.w	.ns1
	eori.w	#2,d3					;swap sides
.ns1	cmpi.w	#3,gspotwins(a0,d3.w)	;3 wins already: this win takes the series
	bne.w	.t3

.sc	move.l	#8,d0					;stanley cup assignment (92 used 9)
	moveq	#$B,d2					;all 12 players lose joystick control
.t0	bclr	#pfjoycon,pflags(a3)	;clear joystick control of one player
	adda.w	#SCstruct,a3
	dbf	d2,.t0
	movea.w	#(SortCords-M68K_RAM),a3
.t3	moveq	#5,d2					;winning team's skaters celebrate
	move.w	(tmstruct+tmscore).w,d1
	sub.w	(awtmstruct+tmscore).w,d1
	beq.w	.chkot					;tied
	bpl.w	.t2						;home team leads
	adda.w	#6*SCstruct,a3			;away team leads
.t2	tst.w	position(a3)			;loop over the six skaters of the celebrating team
	ble.w	.n2						;skip the goalie
	bsr.w	assinsert				;first skater gets d0, the rest get score
	move.l	#7,d0					;score assignment
.n2	adda.w	#SCstruct,a3			;next player
	dbf	d2,.t2
.eog	jsr	(ClearPenaltyBuffer).l	;End of game
	addi.w	#$3E8,(Crowdlevel).w	;crowd roars
	addi.w	#$28,(CwdExciteLvl).w
	bset	#gmclock,(gmode).w
	bset	#gmeog,(gmode).w		;set at end of game
	move.w	#PenEOG,d0
	bra.w	AddPenalty2

.chkot	cmpi.w	#3,(gsp).w			;overtime?
	bne.w	.eop
	tst.w	(OptPlayMode).w
	beq.s	.eog					;gsp 3 with OptPlayMode 0 ends the game
.eop	move.w	#PenEOP,d0			;end of period event
	bra.w	AddPenalty2

demoread							;monitor joystick if in demo mode (called every game loop)
	tst.w	(cont1team).w
	bne.w	rtss2					;not demo
	tst.w	(cont2team).w
	bne.w	rtss2					;not demo
	bsr.w	ReadJoy1
	btst	#sbut,d1				;start pressed?
	bne.w	startpause1				;start on pad 1 pauses (92 went to Opening)
	bsr.w	EndDemoOnPress
	bsr.w	ReadJoy2
	btst	#sbut,d1				;start pressed?
	bne.w	startpause2
	;falls into EndDemoOnPress with pad 2 in d1

EndDemoOnPress						;from 92 demoread. any button on the pad just read (d1) ends the demo
									;falls in from demoread for pad 2
	tst.w	d1
	beq.w	rtss2					;nothing pressed
	jmp	(ExitToOpening).l			;exit demo

startpause1							;pause intiated by cont 1
	bclr	#sfpj,(sflags).w
	bra.w	startpause
startpause2							;pause intiated by cont 2
	bset	#sfpj,(sflags).w
startpause							;common tail: request pause
	bset	#sfpz,(sflags).w
	rts

Pausemode							;game is in pause mode now
	jsr	p_turnoff					;shut off sound
	move.w	(sflags).w,-(sp)
	bsr.w	forceblack				;fade screen to black
	bsr.w	seta2					;a2 = team of pausing controller
	movea.l	#PauseText,a0			;menu item list
	lea	SetupPauseScreen(pc),a1		;screen draw routine
	btst	#tmftimeout,tmflags(a2)
	beq.w	.0
	movea.l	#PauseText2,a0			;alternate item list
.0	bsr.w	InitMenuState			;build menu from list a0, draw routine a1
	;menu loop: wait for vblank, read the pausing pad, auto repeat, handle selection
.loop	bsr.w	MenuWaitVblank		;wait for vblank and read controller
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	bsr.w	HandleMenuInput
	bne.s	.loop					;eq = leave pause

PauseExit	equ	*					;92 PauseExit: restore graphics and return from pause mode (92 had it as a
									;routine; here Pausemode falls into it)
	bsr.w	forceblack
	move.w	(sp)+,(sflags).w
	btst	#sfhor,(sflags).w
	bne.w	.hor
	jsr	(ClrHor).l
.hor	movea.l	#Vdata,a0			;restore the plane size registers
	move.w	#$9100,4(a0)
	move.w	#$9200,4(a0)
	bset	#dfclock,(disflags).w	;clock needs update
	bclr	#sfpz,(sflags).w
	jsr	(printscores1).l
	jsr	(setvideo).l
	move.w	#$18,(palcount).w
.wait	tst.w	(palcount).w		;wait for the palette fade to finish
	bpl.s	.wait
	move.w	(Vcount).w,(OldVcount).w
	rts

SetupPauseScreen					;from 92 Pausemode .pall. draw routine for the pause menu
	movea.l	#Vdata,a0
	move.w	#$9100,4(a0)			;playfield 3 width
	move.w	#$921C,4(a0)			;playfield 3 height
	jsr	(SetHor).l
	jsr	(setvideo).l
	jsr	KillCrowd
	bsr.w	printsmallz				;erase playfield 3
	String	CC_SetMap,3,CC_SetX,0,CC_SetY,0
	moveq	#$20,d0					;width
	moveq	#$1C,d1					;height
	move.w	#$7FF,d2
	bra.w	eraser

seta2								;Set a2 to tmstruct of pause joystick
									;also called from HandleMenuInput
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#sfpj,(sflags).w
	beq.w	.seta20
	cmpi.w	#1,(cont2team).w
	bra.w	.seta21
.seta20	cmpi.w	#1,(cont1team).w	;pad 1 paused
.seta21	beq.w	.x					;a2 stays home if the pausing pad controls team 1
	adda.w	#tmsize,a2
.x	rts								;return

	include menu93.asm				;InitMenuState ... MenuWaitVblank (menu engine)
	include stats93.asm				;stats, attribute, game info screens
;------------------------------------------------------------
;	Instant replay, player and animation update, scroll window
;------------------------------------------------------------

ReplayMode							;this is instant replay play-back control and display code.
									;Called from the pause menu. Tracking: a d-pad press picks the
									;nearest object in that direction and the camera follows it
	bsr.w	forceblack
	move.w	(disflags).w,-(sp)
	bset	#sf2replay,(sflags2).w	;flag that replay is on
	bsr.w	ClrHor					;goto vertical icerink
	move.w	#$400,d0
	move.w	(VmMAP3).w,d1
	move.w	#$7FF,d2
	bsr.w	DoFill					;clear map 3
	bsr.w	printz
	String	$BD,2,2
	moveq	#$20,d0
	moveq	#$55,d1
	moveq	#8,d2
	moveq	#4,d3
	move.w	(rinkvrcset).w,d4
	move.w	#0,d5
	movea.l	#IceRinkMap,a1
	adda.l	jimdata(a1),a1
	movea.w	#null,a2
	bsr.w	dobitmap				;display replay icon
	bclr	#sfscrl,(sflags).w		;manual scroll is off
	bclr	#sf3track,(sflags3).w	;no tracked object
	st	(replayactive).w
	movea.l	(recbpr).w,a4			;record buffer pointer (current frame)
.rwd	bsr.w	suba4				;Rewind to first frame
	tst.w	d7
	bne.s	.rwd
	jsr	SprSort
	jsr	(setvideo).l
	bclr	#sf3rmplay,(sflags3).w	;play mode is off
	move.w	#$18,(palcount).w		;fade in colors now/graphics are ready
	moveq	#1,d7
	;replay main loop: wait d7 frames (1 = full speed), then read the pad that paused
.top	move.w	(Vcount).w,d0		;wait until d7 frames have passed
	sub.w	(OldVcount).w,d0
	cmp.w	d0,d7
	bhi.s	.top					;wait d7 frames
	move.w	(Vcount).w,(OldVcount).w
	moveq	#1,d7
	bsr.w	getpzjoy
	movea.w	#(CameraPosStruct-M68K_RAM),a5
	btst	#sf3track,(sflags3).w	;tracking an object?
	beq.w	.dir
	move.w	d1,d5
	andi.w	#$F,d5					;new d-pad press?
	beq.w	.nomans					;no: keep tracking
	;d-pad held: pick the nearest player in that direction to track, or scroll by hand
.dir	btst	#3,d0				;d0 bit 3 set = no d-pad direction held
	bne.w	.nomans					;no d-pad input
	bset	#sfscrl,(sflags).w		;manual scrolling is on
	bne.w	.man
	move.w	(Hpos).w,(a5)			;first frame: camera starts at the screen
	move.w	(Vpos).w,Ypos(a5)
.man	move.w	d0,d5				;d5 = d-pad direction
	andi.w	#7,d5
	eori.w	#4,d5
	movea.w	#(SortCords-M68K_RAM),a1
	st	d3							;no object to skip
	bclr	#sf3track,(sflags3).w
	beq.w	.find
	move.w	camtrack(a5),d3			;skip the object tracked now
.find	move.w	(a5),d0				;camera position d0/d1: search 12 players
	move.w	Ypos(a5),d1
	moveq	#$B,d2					;12 players
	move.l	#$100,d4				;nearest distance squared so far
	movem.w	d0-d1,-(sp)
.obj	cmp.w	SCnum(a1),d3		;loop over the 12 players, skipping the tracked one
	beq.w	.skip
	movem.w	(sp),d0-d1
	sub.w	(a1),d0
	sub.w	Ypos(a1),d1
	jsr	(vtoa).l					;direction to object
	btst	#3,d0
	bne.w	.skip
	sub.w	d5,d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.skip					;not within 45 degrees of the d-pad
	movem.w	(sp),d0-d1
	sub.w	(a1),d0
	sub.w	Ypos(a1),d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#4,d0
	bls.w	.skip					;too close
	cmp.l	d4,d0
	bhi.w	.skip					;not nearer
	move.l	d0,d4
	move.w	SCnum(a1),camtrack(a5)	;new target
	bset	#sf3track,(sflags3).w
.skip	adda.w	#SCstruct,a1		;next object
	dbf	d2,.obj
	addq.w	#4,sp
	btst	#sf3track,(sflags3).w
	beq.w	.scrl					;nothing found: scroll by hand
	move.w	camtrack(a5),d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	moveq	#4,d4
	bsr.w	setpads
	bsr.w	UpdateCameraPos
	jsr	(setvideo).l
	bra.w	.top
.scrl	bset	#sfscrl,(sflags).w	;no object found: scroll the camera by hand
	eori.w	#4,d5
	asl.w	#2,d5
	lea	.stab(pc),a0
	move.w	(a0,d5.w),d0
	add.w	(a5),d0
	cmp.w	#$88,d0
	bgt.w	.nox
	cmp.w	#-$88,d0
	blt.w	.nox
	move.w	d0,(a5)
.nox	move.w	2(a0,d5.w),d1		;y step
	add.w	Ypos(a5),d1
	cmp.w	#$126,d1
	bgt.w	.noy
	cmp.w	#-$126,d1
	blt.w	.noy
	move.w	d1,Ypos(a5)
.noy	movea.w	a5,a3				;camera struct is the object to follow
	clr.w	camidle(a5)
	andi.w	#$FFF,(PadControlBits).w
	ori.w	#$E000,(PadControlBits).w
	bsr.w	UpdateCameraPos
	jsr	(setvideo).l
	bra.w	.top
.stab	dc.w	0,2,2,2,2,0,2,-2,0,-2,-2,-2,-2,0,-2,2	;steps * 2

	;buttons: C toggles play mode, A rewinds 4 frames, B steps 1 frame (slow motion), A+B manual scroll off,
	;Start exits
.nomans	st	camidle(a5)				;no d-pad: handle the buttons
	btst	#cbut,d1				;C: play or stop
	beq.w	.00
	bchg	#sf3rmplay,(sflags3).w	;switch play mode
.00	btst	#abut,d3				;A held?
	beq.w	.0
	bsr.w	suba4					;fast rewind
	bsr.w	suba4
	bsr.w	suba4
	bsr.w	suba4
	jsr	SprSort
	jsr	(setvideo).l
	moveq	#1,d7
	bclr	#sf3rmplay,(sflags3).w	;turn off play mode
.0	btst	#bbut,d3				;B held?
	beq.w	.1
	btst	#abut,d3				;A held too?
	beq.w	.f1
	bclr	#sf3track,(sflags3).w
	bclr	#sfscrl,(sflags).w		;a+b but = manual scroll off (hidden feature)
	bra.w	.top
.f1	bsr.w	adda4					;Advance 1 frame
	jsr	SprSort
	jsr	(setvideo).l
	asl.w	#1,d7					;double delay time between frames = 1/2 speed slow motion
	bclr	#sf3rmplay,(sflags3).w	;turn off play mode
	;play mode: advance one frame and replay its sound effect
.1	btst	#sf3rmplay,(sflags3).w	;play mode on?
	beq.w	.noplay
	st	(lastsfx).w					;play mode is on = advance one frame at original speed
	bsr.w	adda4
	move.w	(lastsfx).w,-(sp)		;play sound effects
	bsr.w	sfx
	jsr	SprSort
.noplay	jsr	(setvideo).l			;redraw
	btst	#sbut,d1				;start pressed?
	beq.w	.top					;no exit yet
	;Start pressed: leave replay, restore the live frame and video
	bsr.w	forceblack
	ori.w	#$F000,(PadControlBits).w
	bclr	#sfscrl,(sflags).w
	movea.l	(recbpr).w,a4			;back to the current frame
	bsr.w	RestoreReplayFrame
	jsr	SprSort
	bclr	#sf2replay,(sflags2).w
	move.w	(sp)+,(disflags).w
	bsr.w	SetHor
	jsr	(setvideo).l				;restore old video
	move.w	#$18,(palcount).w
	rts								;exit replay mode

getpzjoy							;read the joystick of the pad that paused
	btst	#sfpj,(sflags).w
	bne.w	ReadJoy2
	bra.w	ReadJoy1

suba4								;a4 = address in replay buffer of current
									;frame. Back up 1 frame and set video parameters for display.
									;d7 will be set to delay between frames or zero if at the end of replay
	cmpa.l	#replaystart,a4			;at the start of the buffer?
	bne.w	.1
	btst	#sfwrap,(sflags).w
	beq.w	.end
	movea.l	#replayend,a4
.1	suba.w	#replaysize,a4			;back one frame
	cmpa.l	(recbpr).w,a4
	bne.w	RestoreReplayFrame
	adda.w	#replaysize,a4			;reached the record point
.end	bsr.w	RestoreReplayFrame	;at either end of the replay: show frame, d7 = 0
	clr.w	d7
	rts

adda4								;a4 = address in replay buffer of current
									;frame. Step forward 1 frame and set video parameters for display.
									;d7 will be set to delay between frames or zero if at the end of replay
	clr.w	d7
	btst	#sf2drec,(sflags2).w
	beq.w	adda42
	move.l	a4,-(sp)
	bsr.w	adda43
	cmpa.l	(recbpr).w,a4
	movea.l	(sp)+,a4
	beq.w	rtss2
adda42								;adda4 without the sf2drec look-ahead. Stop at the record point, else show
									;the frame and fall into adda43
	cmpa.l	(recbpr).w,a4
	beq.w	rtss2
	bsr.w	RestoreReplayFrame
adda43								;a4 += replaysize, wrapping from replayend to replaystart
	adda.w	#replaysize,a4			;forward one frame
	cmpa.l	#replayend,a4
	bne.w	rtss2
	movea.l	#replaystart,a4			;wrap to the start
	rts

UpdateCameraPos						;Camera struct a5 = object a3's x/y, Hpos/Vpos = that position clamped to
									;the scroll limits
	movem.l	d0-d2,-(sp)
	move.w	(a3),d0
	move.w	d0,(a5)
	move.w	Ypos(a3),d1
	move.w	d1,Ypos(a5)
	cmp.w	#$3C,d0
	blt.w	.0
	move.w	#$3C,d0					;xslim
.0	cmp.w	#-$3C,d0				;clamp the low limit
	bgt.w	.1
	move.w	#$FFC4,d0
.1	move.w	d0,(Hpos).w				;set Hpos
	cmp.w	#$100,d1
	blt.w	.2
	move.w	#$100,d1				;upper y scroll limit
.2	cmp.w	#-200,d1				;clamp the low y limit
	bgt.w	.3
	move.w	#$FF38,d1				;lower y scroll limit
.3	move.w	d1,(Vpos).w				;set Vpos
	movem.l	(sp)+,d0-d2
	rts

RestoreReplayFrame					;from 92 SetRCords + nonshift in one routine. a4 = current replay frame
									;address to convert into normal cordinates, then set the other replay
									;variables. Returns d7 = frame delay. Hpos/Vpos come from the frame unless
									;scrolling by hand (sfscrl), then from the camera or tracked object.
									;Also the tail of suba4
SetRCords	equ	*					;from 92 SetRCords: the object unpack (the nonshift half follows below)
	movem.l	d0-d2/a0,-(sp)
	movea.l	a4,a0
	moveq	#$F,d1					;16 objects to convert (12 players/puck/shadow/2 goal nets)
	movea.w	#(SortCords-M68K_RAM),a3
	;unpack the 4 byte record of each object: x, y, frame and flip bits
.top	move.w	2(a0),d2			;loop over the 16 objects: x from word 1
	andi.w	#$3FF,d2
	btst	#9,d2
	beq.w	.p
	ori.w	#$FC00,d2
.p	move.w	d2,(a3)					;Xpos
	move.l	(a0),d2
	asr.l	#4,d2
	asr.w	#6,d2
	btst	#9,d2
	beq.w	.p1
	ori.w	#$FC00,d2
.p1	move.w	d2,Ypos(a3)				;store the sign extended y
	move.w	(a0),d2
	asr.w	#4,d2
	andi.w	#$3FF,d2
	move.w	d2,frame(a3)
	move.w	(a0),d2
	asr.w	#3,d2
	andi.w	#$1800,d2
	andi.w	#$E7FF,attribute(a3)	;flip bits
	or.w	d2,attribute(a3)
	addq.w	#4,a0
	adda.w	#SCstruct,a3
	dbf	d1,.top
	moveq	#5,d2					;6 pairs of players
	movea.w	#(SortCords-M68K_RAM),a3
	;3 bytes per pair of players: both rostnum values and both position nibbles
.pl	move.b	(a0)+,rostnum(a3)		;loop over the 6 pairs of players
	move.b	(a0),d0
	andi.w	#$F,d0
	cmp.w	#$F,d0
	bne.w	.n0
	moveq	#-1,d0					;$F = not on ice
.n0	move.w	d0,position(a3)			;position of the first player of the pair
	adda.w	#SCstruct,a3
	move.b	(a0)+,d0
	lsr.b	#4,d0
	move.b	d0,rostnum(a3)
	move.b	(a0),d0
	asl.b	#4,d0
	or.b	d0,rostnum(a3)
	move.b	(a0)+,d0
	lsr.b	#4,d0
	andi.w	#$F,d0
	cmp.w	#$F,d0
	bne.w	.n1
	moveq	#-1,d0
.n1	move.w	d0,position(a3)			;position of the second player
	adda.w	#SCstruct,a3
	dbf	d2,.pl
nonshift	equ	*					;92 nonshift: set the other replay variables (92 SetRCords is the object
									;unpack above)
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(puckz).w			;puck z cord
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(SortCords+(15*SCstruct)+Zpos).w	;puck shadow zcord
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(lastsfx).w			;sound effect cue
	clr.w	d7
	move.b	(a0)+,d7				;frame delay
	move.w	(a0)+,d0
	andi.w	#$FFF,d0
	andi.w	#$F000,(PadControlBits).w
	or.w	d0,(PadControlBits).w
	move.w	(a0)+,(Crowdframe).w
	move.w	(a0)+,(glovecords).w
	move.b	(a0)+,(PBnum).w
	addq.w	#1,a0
	;manual scroll: camera follows the tracked object or the camera struct, else Hpos/Vpos come from the frame
	btst	#sfscrl,(sflags).w
	beq.w	.pos
	movea.w	a5,a3
	btst	#sf3track,(sflags3).w	;tracking an object?
	beq.w	.cam
	clr.w	camidle(a5)
	move.w	camtrack(a5),d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
.cam	bsr.w	UpdateCameraPos		;camera follows the object a3
	bra.w	.x
.pos	move.w	(a0)+,(Hpos).w		;use Hpos/Vpos saved in the frame
	move.w	(a0)+,(Vpos).w
.x	movem.l	(sp)+,d0-d2/a0			;return
	rts

updatereplay						;called every frame to save replay events, d7 = elapsed frames
	btst	#gmhl,(gmode).w			;no recording in highlight mode
	bne.w	rtss2
	btst	#sf2drec,(sflags2).w
	bne.w	.rec					;record off: keep overwriting this frame
	addi.l	#replaysize,(recbpr).w	;next frame slot
	cmpi.l	#replayend,(recbpr).w	;past the end of the buffer?
	bne.w	.rec
	bset	#sfwrap,(sflags).w
	move.l	#replaystart,(recbpr).w	;wrap to the start
.rec	movea.l	(recbpr).w,a0		;from 92 updatereplay2 (also: 92 record, run here for all 16 objects
									;below)
	moveq	#$F,d2					;16 objects
	movea.w	#(SortCords-M68K_RAM),a3
	;pack each object into a 4 byte record (inverse of RestoreReplayFrame)
.top	clr.l	(a0)				;loop over the 16 objects: pack x, y, frame, flip bits
	move.w	(a3),d1					;Xpos
	andi.w	#$3FF,d1
	move.w	d1,2(a0)
	clr.l	d1
	move.w	Ypos(a3),d1
	asl.w	#6,d1
	asl.l	#4,d1
	or.l	d1,(a0)
	move.w	frame(a3),d1
	asl.w	#4,d1
	or.w	d1,(a0)
	move.w	attribute(a3),d1
	andi.w	#$1800,d1
	asl.w	#3,d1
	or.w	d1,(a0)
	addq.w	#4,a0
	adda.w	#SCstruct,a3
	dbf	d2,.top
	moveq	#5,d2					;6 pairs of players
	movea.w	#(SortCords-M68K_RAM),a3
.pl	move.b	rostnum(a3),(a0)+		;loop over the 6 pairs of players
	move.w	position(a3),d0
	bpl.w	.n0
	moveq	#$F,d0					;not on ice
.n0	andi.w	#$F,d0					;position nibble
	move.b	d0,(a0)
	adda.w	#SCstruct,a3
	move.b	rostnum(a3),d0
	asl.w	#4,d0
	or.b	d0,(a0)+
	move.b	rostnum(a3),d0
	lsr.b	#4,d0
	move.b	d0,(a0)
	move.w	position(a3),d0
	bpl.w	.n1
	moveq	#$F,d0
.n1	asl.w	#4,d0					;up 4
	or.b	d0,(a0)+
	adda.w	#SCstruct,a3
	dbf	d2,.pl
	;then puck z, shadow z, sound cue, elapsed frames, pad bits, crowd frame, glove coords, PBnum, Hpos/Vpos
	move.b	(puckz+1).w,(a0)+
	move.b	(SortCords+(15*SCstruct)+Zpos+1).w,(a0)+	;puck shadow z
	move.b	(lastsfx+1).w,(a0)+		;sound effect cue
	bset	#7,(lastsfx+1).w
	move.b	d7,(a0)+				;save elapsed frames
	move.w	(PadControlBits).w,(a0)+
	move.w	(Crowdframe).w,(a0)+
	move.w	(glovecords).w,(a0)+
	move.b	(PBnum).w,(a0)+
	addq.w	#1,a0
	move.w	(Hpos).w,(a0)+
	move.w	(Vpos).w,(a0)+
rtss2	rts							;shared rts

updateplayers						;update every object in SortCords
									;this routine calls all collision/animation/assignment code for all the
									;players
									;d7 = elapse frames since last call
	btst	#sfhor,(sflags).w
	bne.w	.u0
	ori.w	#$F,(PadControlBits).w
.u0	movea.w	#(SortCords-M68K_RAM),a3	;a3 walks SortCords
	;loop over all objects: save the old position first
.top	move.l	(a3),OldXpos(a3)	;save X as old X
	move.l	Ypos(a3),OldYpos(a3)
	move.l	Zpos(a3),OldZpos(a3)
	;off ice players (negative position) skip to .nf1; the rest get animation and timers
	tst.w	position(a3)
	bmi.w	.nf1					;player is not on ice
	bsr.w	updateanim
	sub.b	d7,nopuck(a3)			;puck control
	bpl.w	.np
	clr.b	nopuck(a3)
.np	sub.b	d7,nopuckb(a3)			;second timer, same countdown
	bpl.w	.np2
	clr.b	nopuckb(a3)
.np2	btst	#sf3icetime,(sflags3).w	;once a second: count time on ice
	beq.w	.vel
	clr.w	d0
	move.b	pnum(a3),d0
	bmi.w	.vel
	add.w	d0,d0
	addi.w	#$136,d0
	bsr.w	loadTeamStruct
	addq.w	#1,(a2,d0.w)			;count frames on ice for this player
	;velocity update: injured players do not move
.vel	cmpi.w	#SPAinjury1,SPA(a3)	;skip movement and bounce
	beq.w	.done
;----------------------------------	now update velocity
	IF REV>=1
	moveq	#$10,d4					;Rev A: 16 per frame, 20 at 50 Hz (PalMode set)
	tst.w	(PalMode).w
	beq.w	.ntsc
	moveq	#$14,d4
.ntsc	mulu.w	d7,d4				;d4 = velocity step * elapsed frames
	ELSE
	move.w	d7,d4
	asl.w	#4,d4
	ENDIF
	;friction only on the ice (Zpos 0): shift 6, or 9 with pfdoff; velocity -= max(1, velocity >> shift)
	tst.w	Zpos(a3)
	bne.w	.y2						;no deceleration
	moveq	#6,d2
	btst	#pfdoff,pflags(a3)
	beq.w	.off
	moveq	#9,d2
.off	move.w	Xvel(a3),d0			;x friction
	beq.w	.x2
	asr.w	d2,d0
	bne.w	.x1
	moveq	#1,d0
.x1	sub.w	d0,Xvel(a3)				;apply x friction
.x2	move.w	Yvel(a3),d0				;y friction
	beq.w	.y2
	asr.w	d2,d0
	bne.w	.y1
	moveq	#1,d0
.y1	sub.w	d0,Yvel(a3)				;apply y friction
.y2	move.w	Xvel(a3),d0				;move in x
	beq.w	.x3
	muls.w	d4,d0
	add.l	d0,(a3)
.x3	move.w	Yvel(a3),d0				;move in y
	beq.w	.y3
	muls.w	d4,d0
	add.l	d0,Ypos(a3)
	;z axis: gravity on Zvel, then Zpos += Zvel * d4; below the ice it bounces
.y3	tst.w	Zpos(a3)				;z axis
	bmi.w	.done
	bne.w	.z1
	tst.w	Zvel(a3)
	beq.w	.done
.z1	asl.w	#1,d4					;gravity: d4 = 32*d7, Zvel -= it
	sub.w	d4,Zvel(a3)
	asl.w	#1,d4					;d4 = 64*d7, Zvel -= it: 96*d7 in all (120*d7
									;Rev A PAL); Zvel unit 1/4096 px a frame
	sub.w	d4,Zvel(a3)
	lsr.w	#2,d4					;d4 back to 16*d7, the position step
	move.w	Zvel(a3),d0
	muls.w	d4,d0
	add.l	d0,Zpos(a3)
	bpl.w	.done
	clr.l	Zpos(a3)				;bounce off the ice
	neg.w	Zvel(a3)
	asr.w	Zvel(a3)				;lsr
	moveq	#5,d0
	sub.b	Zvel(a3),d0
	bpl.w	.snd
	clr.w	d0
.snd	cmp.w	#3,d0				;only the four slowest bounces make a sound
	bhi.w	.done
	addi.w	#SFXpuckice,d0			;bounce sound $2C-$2F by speed
	move.w	d0,-(sp)
	bsr.w	sfx
	;player control: carrier setpads, controller 1 and 2 players read their pad
.done	move.w	SCnum(a3),d6		;d6 = this object's number
	cmp.w	(puckc).w,d6
	bne.w	.tp						;not puck carrier
	btst	#pf2fight,pflags2(a3)
	bne.w	.tp
	btst	#sfhor,(sflags).w
	bne.w	.tp
	moveq	#-2,d4					;pad index for puck carrier
	bsr.w	setpads
.tp	cmp.w	(c1playernum).w,d6		;is it the controller 1 player?
	bne.w	.t0
	bsr.w	ReadJoy1
	clr.w	d4						;pad index for cont 1 player
	bsr.w	doinput
	bra.w	.t1
.t0	cmp.w	(c2playernum).w,d6		;is it the controller 2 player?
	bne.w	.t1
	bsr.w	ReadJoy2
	moveq	#2,d4					;pad index for cont 2 player
	bsr.w	doinput
	;run the assignment routine asstab[asslist[assnum]] for this object
.t1	move.w	assnum(a3),d0			;92 skipped this while pfalock was set; 93 and 94G always run it
	clr.w	d1
	move.b	asslist(a3,d0.w),d1
	asl.w	#2,d1
	movea.l	#asstab,a0
	movea.l	(a0,d1.w),a0
	bsr.w	loadTeamStruct
	jsr	(a0)						;call assignment for this player
	;clear wall contact; test collisions if the object moved at least one pixel
	clr.w	Wallcos(a3)
	clr.w	Wallsin(a3)
	move.w	(a3),d2
	move.w	Ypos(a3),d3
	cmp.w	OldXpos(a3),d2
	bne.w	.cc
	cmp.w	OldYpos(a3),d3
	beq.w	.nf
.cc	bsr.w	checkcoll				;Check for coll if moved by at least 1 pix
.nf	move.w	d7,d0					;reduce impact at a rate of 2 per frame
	asl.w	#1,d0
	sub.w	d0,impact(a3)			;reduce impact at constant rate
	bpl.w	.nf1
	clr.w	impact(a3)
.nf1	move.w	impact(a3),limpact(a3)	;limpact = impact for the next frame
	adda.w	#SCstruct,a3
	cmpi.w	#$F,SCnum-SCstruct(a3)	;the struct just done
	blt.w	.top					;loop for all Sort objects
	rts

updateanim							;frame switch control on struct a3. Also called from UpdateRosterPlayer
	tst.w	SPA(a3)
	bne.w	.ia
	bclr	#pfalock,pflags(a3)
	bclr	#pf2aip,pflags2(a3)
	rts
.ia	movea.l	#SPAList,a0				;Animation data tables (frames)
	adda.w	SPA(a3),a0
	move.w	SPAattr(a0),d1			;attributes for anim
	;direction index d0 = facedir (rotated on the horizontal rink, mirrored if x flipped)
	move.w	facedir(a3),d0
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	cmpi.w	#$C,SCnum(a3)
	bge.w	.nhor
	subq.w	#2,d0					;direction adj for horizontal rink
	andi.w	#7,d0
.nhor	btst	#3,attribute(a3)	;X flip flag
	beq.w	.nox
	neg.w	d0
	addq.w	#8,d0
	andi.w	#7,d0
.nox	asl.w	#1,d0				;d0 = direction * 2 indexes the anim's direction offsets a0 = frame list
									;for this direction; SPAnum indexes 4 byte (frame, duration) steps
	adda.w	(a0,d0.w),a0
	move.w	SPAnum(a3),d0
	move.w	(a0,d0.w),d2			;new frame
	;count SPAcnt down, then step on; a negative duration marks the last step: clear SPAnum and
	;pfalock/pf2aip, end the anim unless looping (attribute bit 0)
	tst.w	SPAcnt(a3)
	bmi.w	.1
	sub.w	d7,SPAcnt(a3)
	bpl.w	.cframe
	addq.w	#4,SPAnum(a3)
	addq.w	#4,d0
	tst.w	-2(a0,d0.w)
	bpl.w	.1
	clr.w	d0
	clr.w	SPAnum(a3)
	bclr	#pfalock,pflags(a3)
	bclr	#pf2aip,pflags2(a3)
	btst	#0,d1
	bne.w	.1						;looper
	clr.w	SPA(a3)
.1	move.w	2(a0,d0.w),d0			;d0 = duration of this step
	bpl.w	.0
	neg.w	d0
.0	move.w	d0,SPAcnt(a3)			;store as the step countdown
	;limit frame switches with the glitch timer, then store the new frame
.cframe	sub.b	d7,glitch(a3)		;Limit minimum time between frame switches
	bpl.w	rtss
	clr.b	glitch(a3)
	cmp.w	frame(a3),d2
	beq.w	rtss
	move.w	d2,frame(a3)
	move.b	#4,glitch(a3)			;/60 sec min frame switch time
	rts

freezewindow						;lock scrolling to current position
	move.w	(Vpos).w,(yc1).w
	move.w	(Hpos).w,(xc1).w
	bset	#sfslock,(sflags).w
	rts

checkwindow							;set hpos and vpos according to how screen should follow puck
	move.w	(yc1).w,d2
	move.w	(xc1).w,d3				;if locked, use these cordinates
	btst	#sfslock,(sflags).w
	bne.w	.dd
	;follow the puck, or the puck carrier's entry in SortCords
	movea.w	#(puckx-M68K_RAM),a3
	move.w	(puckc).w,d0
	bmi.w	.ok
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.w	d7,d0
	add.w	d0,d0
	;pfgoal set: yleader += 2*frames up to $32; clear: down to -$32
	btst	#pfgoal,pflags(a3)
	beq.w	.gd
	add.w	d0,(yleader).w
	cmpi.w	#$32,(yleader).w		;.ylmax = 50
	blt.w	.ok
	move.w	#$32,(yleader).w
	bra.w	.ok
.gd	sub.w	d0,(yleader).w			;pfgoal clear: yleader moves the other way
	cmpi.w	#$FFCE,(yleader).w		;-.ylmax
	bgt.w	.ok
	move.w	#$FFCE,(yleader).w
.ok	move.w	Yvel(a3),d2				;target y = Ypos + Yvel/128 + yleader
	asr.w	#7,d2
	add.w	Ypos(a3),d2
	add.w	(yleader).w,d2
	move.w	(a3),d3					;Xpos
	move.w	d2,(yc1).w
	move.w	d3,(xc1).w
.dd	move.w	d2,d0					;d2 = target y, d3 = target x. d0 = target y - Vpos
	sub.w	(Vpos).w,d0
	cmp.w	#-10,d0					;-.ylim
	bge.w	.1
	move.w	d2,d1
	subi.w	#$FFF6,d1				;-.ylim
	cmp.w	#-200,d1				;.yslimd
	bgt.w	.2
	move.w	#$FF38,d1
	bra.w	.2
.1	cmp.w	#10,d0					;ylim
	ble.w	.2x
	move.w	d2,d1
	subi.w	#$A,d1
	cmp.w	#256,d1					;.yslimu
	blt.w	.2
	move.w	#$100,d1
.2	sub.w	(Vpos).w,d1				;d1 = distance to scroll
	beq.w	.2x
	asr.w	#4,d1
	bne.w	.v2
	addq.w	#1,d1
.v2	add.w	d1,(Vpos).w				;move Vpos 1/16 of the distance, at least 1
.2x	move.w	d3,d0					;now the x axis
	sub.w	(Hpos).w,d0
	cmp.w	#-40,d0					;-.xlim
	bge.w	.3
	move.w	d3,d1
	subi.w	#$FFD8,d1
	cmp.w	#-60,d1					;-.xslim
	bge.w	.4
	move.w	#$FFC4,d1
	bra.w	.4
.3	cmp.w	#40,d0					;xlim
	ble.w	rtss
	move.w	d3,d1
	subi.w	#$28,d1
	cmp.w	#60,d1					;.xslim
	ble.w	.4
	move.w	#$3C,d1
.4	sub.w	(Hpos).w,d1				;d1 = distance to scroll
	beq.w	rtss
	asr.w	#4,d1
	bne.w	.h2
	addq.w	#1,d1
.h2	add.w	d1,(Hpos).w				;move Hpos 1/16 of the distance, at least 1
	rts


	include logic93.asm				;doinput ... dirtab
	include middle93.asm			;UnpackNibbles ... AddTeamBlock
	include penalty93.asm			;AddPenalty ... AdvanceStringPtr, DoHiLights ... StartHL2


;------------------------------------------------------------
;	Collisions, checking, falls and injuries
;------------------------------------------------------------

collrad	=	8						;collision radius of an object (players collide within collrad*2)

checkcoll							;d2 = new x cord, d3 = new y cord, a3 = struct of object. Check wall
									;collision (around the hot spot and the end of the stick) and player
									;collisions, then move a3 in the OOlist sort order by its y. If a player
									;collision set collflag, restore the old x/y instead. Does not clear
									;Wallcos/Wallsin first (92 did). Called from updateplayers
	clr.w	(collflag).w
	btst	#sfhor,(sflags).w
	beq.w	.nhor1
	exg	d2,d3
.nhor1	btst	#pfnc,pflags(a3)	;no coll mode: skip all tests
	bne.w	.ex
	movem.l	d0-d7,-(sp)
	move.w	(a3),d2					;Xpos
	move.w	Ypos(a3),d3				;check coll around hot spot with wall
	move.w	radiusx(a3),(wcradiusx).w	;wall coll radius x
	move.w	radiusy(a3),(wcradiusy).w	;wall coll radius y
	bsr.w	checkwallcoll
	move.w	Wallcos(a3),d0
	or.w	Wallsin(a3),d0
	bne.w	.xx						;coll did happen
	cmpi.w	#$B,SCnum(a3)
	bgt.w	.xx						;not a player
	movem.l	(sp),d0-d7
	move.l	a3,-(sp)
	bsr.w	GetHot
	move.w	(a3),d2
	move.w	Ypos(a3),d3
	add.w	d0,d2
	add.w	d1,d3					;check coll around end of stick with wall
	move.w	#1,(wcradiusx).w
	move.w	#1,(wcradiusy).w
	bsr.w	checkwallcoll
.xx	movem.l	(sp)+,d0-d7				;restore registers

	bsr.w	checkplcoll				;check coll with other players

;now check order of sprites
.ex	tst.w	(collflag).w			;collision: restore, else re-sort in OOlist
	bne.w	.restoreold
	;re-sort this object in OOlist (ordered by y): move up past neighbours with a smaller y, then down past
	;those with a greater y
	move.w	SCnum(a3),d0
	asl.w	#1,d0					;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1			;current objects pos in OOlist
.2	cmp.w	#$F,d1					;Sortobjs-1
	beq.w	.cl2					;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4			;next higher object number
	cmp.w	(a2,d4.w),d3			;y pos of next higher object
	ble.w	.cl2

	addq.w	#1,(a0,d0.w)
	subq.w	#1,(a0,d4.w)

	move.b	d4,(a1,d1.w)
	move.b	d0,1(a1,d1.w)

	addq.w	#1,d1
	bra.s	.2

.cl2	move.w	(a0,d0.w),d1		;current objects pos in OOlist
	beq.w	.ex2
.3	clr.w	d4						;loop: move down past lower objects with a greater y
	move.b	-1(a1,d1.w),d4			;next lower object number
	cmp.w	(a2,d4.w),d3			;y pos of next lower object
	bge.w	.ex2

	subq.w	#1,(a0,d0.w)
	addq.w	#1,(a0,d4.w)

	move.b	d4,(a1,d1.w)
	move.b	d0,-1(a1,d1.w)

	subq.w	#1,d1
	bne.s	.3
.ex2	move.w	d3,(a2,d0.w)		;update Ylist
	rts
.restoreold	move.w	OldXpos(a3),(a3)	;undo the move
	move.w	OldYpos(a3),Ypos(a3)
	rts

checkplcoll							;d2/d3 = x/y cords, a3 = struct. Walk up and down the OOlist from a3 and
									;call checkcx for each object within $10 in y. Called from checkcoll
	btst	#pf2npc,pflags2(a3)		;no player collision bit (92 used 7)
	bne.w	.ex
	cmpi.w	#$B,SCnum(a3)
	bgt.w	.ex						;not a player
	move.w	SCnum(a3),d0
	asl.w	#1,d0					;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1			;current objects pos in OOlist
.0	cmp.w	#$F,d1					;Sortobjs-1
	beq.w	.cl						;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4			;next higher object number
	move.w	(a2,d4.w),d5			;y pos of next higher object
	sub.w	d3,d5
	cmp.w	#collrad*2,d5
	bgt.w	.cl						;no higher sprite coll
	bsr.w	checkcx
	addq.w	#1,d1
	bra.s	.0

.cl	move.w	(a0,d0.w),d1			;now check the neighbours below
	beq.w	.ex
.1	clr.w	d4						;loop: lower neighbours
	move.b	-1(a1,d1.w),d4			;next lower object number
	move.w	d3,d5
	sub.w	(a2,d4.w),d5			;y pos of next lower object
	cmp.w	#collrad*2,d5
	bgt.w	.ex
	bsr.w	checkcx
	subq.w	#1,d1
	bne.s	.1
.ex	rts								;return

checkcx								;d4 = obj. # * 2 for possible coll so check x range and distance for coll.
									;d2 = x, d5 = delta y, a3 = moving object. Opposing players add impact and
									;run newcheck, checkint, checkcheck and checkfight; then momentum moves
									;from a3 to a2. Called from checkplcoll
	movem.l	d0-d7/a0-a3,-(sp)
	asl.w	#6,d4					;obj. # * 2 * $40 = * $80
	movea.l	#SortCords,a2
	adda.w	d4,a2

	btst	#pfnc,pflags(a2)
	bne.w	.exit					;object has no coll mode on
	btst	#pf2npc,pflags2(a2)		;no player collision bit (92 used 7)
	bne.w	.exit
	cmpi.w	#$B,SCnum(a2)
	bgt.w	.exit					;not a player

	move.w	(a2),d0					;Xpos
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	move.w	Ypos(a2),d0
.nhor	sub.w	d2,d0				;delta x
	cmp.w	#-collrad*2,d0
	blt.w	.exit
	cmp.w	#collrad*2,d0
	bgt.w	.exit
	muls.w	d5,d5					;delta y^2
	muls.w	d0,d0					;delta x^2
	add.l	d5,d0
	cmp.l	#(collrad*2)*(collrad*2),d0
	bgt.w	.exit					;outside of radius

	;momentum transfer setup: evalue = 0, d6 = pflags xor (pfteam set = opposing teams)
	move.w	#0,(evalue).w
	move.b	pflags(a3),d6
	move.b	pflags(a2),d0
	eor.b	d0,d6

;now do momentum transfer from object a3 to object a2

	move.w	Xvel(a3),d0
	sub.w	Xvel(a2),d0				;Vx
	move.w	Yvel(a3),d1
	sub.w	Yvel(a2),d1				;Vy

	move.w	(a3),d2					;Xpos
	sub.w	(a2),d2
	neg.w	d2						;Dx
	move.w	Ypos(a3),d3
	sub.w	Ypos(a2),d3
	neg.w	d3						;Dy

	movem.w	d0-d1,-(sp)
	muls.w	d3,d1					;Vy*Dy
	muls.w	d2,d0					;Vx*Dx
	add.l	d0,d1					;(Vy*Dy)+(Vx*Dx)
	bmi.w	.exit4					;no col if v1n < 0
	asr.l	#4,d1

	btst	#pfteam,d6
	beq.w	.not					;players are on same team
	move.w	d1,d4
	lsr.w	#8,d4
	cmp.w	#5,d4
	bgt.w	.g40
	moveq	#5,d4					;minimum impact value
.g40	add.w	d4,impact(a3)		;add impact to both players
	add.w	d4,impact(a2)
	btst	#pf2fight,pflags2(a2)
	bne.w	.if
	move.w	SCnum(a3),impactp(a2)	;SCnum -> impactp
.if	btst	#pf2fight,pflags2(a3)	;same for the second player
	bne.w	.if2
	move.w	SCnum(a2),impactp(a3)
.if2	cmp.w	#$14,d4				;impact under 20: no check sound
	blt.w	.n1
	move.w	(puckc).w,d0			;check sound only if one of them has the puck
	cmp.w	SCnum(a3),d0
	beq.w	.nc
	cmp.w	SCnum(a2),d0
	bne.w	.n1
.nc	bsr.w	newcheck				;start a check sound

.n1	bsr.w	checkint				;interference, check and fight tests
	bsr.w	checkcheck
	bsr.w	checkfight
.not	move.w	d1,d4				;V1n

	movem.w	(sp)+,d0-d1
	tst.w	(collflag).w			;set to -1 by holdcheck / Bcheck: no transfer
	bmi.w	.exit

	muls.w	d2,d1					;Vy*Dx
	muls.w	d3,d0					;Vx*Dy
	sub.l	d1,d0					;(Vx*Dy)-(Vy*Dx)
	asr.l	#4,d0
	move.w	d0,d5					;V1t

	clr.w	d0
	move.b	weight(a3),d0			;weight m1
	addi.w	#$8C,d0					;+140
	clr.w	d1
	move.b	weight(a2),d1			;weight m2
	addi.w	#$8C,d1
	move.w	(evalue).w,d7			;e*16 value (0-16)
	mulu.w	d1,d7
	lsr.w	#4,d7					;m2*e
	add.w	d0,d1					;m1+m2
	sub.w	d7,d0					;(m1-m2*e)
	muls.w	d4,d0					;V1n*(m1-m2*e)
	divs.w	d1,d0					;V1n'=(V1n*(m1-m2*e))/(m1+m2)

	move.w	(evalue).w,d1
	muls.w	d4,d1					;V1n*e
	asr.w	#4,d1
	add.w	d0,d1					;V2n'=V1n'+V1n*e

	movem.w	d2-d3,-(sp)				;save Dx,Dy
	muls.w	d5,d3					;V1t'*Dy
	muls.w	d0,d2					;V1n'*Dx
	add.l	d2,d3					;V1t'*Dy+V1n'*Dx
	asr.l	#4,d3
	add.w	Xvel(a2),d3
	move.w	d3,Xvel(a3)

	movem.w	(sp),d2-d3				;restore Dx,Dy
	muls.w	d5,d2					;V1t'*Dx
	muls.w	d0,d3					;V1n'*Dy
	sub.l	d2,d3					;V1n'*Dy-V1t'*Dx
	asr.l	#4,d3
	add.w	Yvel(a2),d3
	move.w	d3,Yvel(a3)

	movem.w	(sp)+,d2-d3
	muls.w	d1,d2					;V2n'*Dx
	asr.l	#4,d2
	add.w	d2,Xvel(a2)

	muls.w	d1,d3					;V2n'*Dy
	asr.l	#4,d3
	add.w	d3,Yvel(a2)

	st	(collflag).w

.exit	movem.l	(sp)+,d0-d7/a0-a3	;restore registers
	rts

.exit4	addq.w	#4,sp				;drop the saved Vx/Vy
	bra.s	.exit

newcheck							;start a new check sound: one of 4 sounds $1C-$1F (92 picked one of 5 from
									;18), never the last one again. Called from checkcx; FallDown branches
									;here when the player who fell did not have the puck
	move.l	d0,-(sp)
	moveq	#3,d0
	bsr.w	randomd0
	addq.w	#1,d0					;1-3 sounds on from the last one
	add.w	(ltack).w,d0			;last tackle sound
	andi.w	#3,d0
	move.w	d0,(ltack).w
	addi.w	#SFXcheck,d0			;first check sound (92 used 18)
	move.w	d0,-(sp)
	bsr.w	sfx						;tackle sound
	move.l	(sp)+,d0
	rts

checkint							;check for interference penalty. player a2 interferes with a3 or
									;vice-versa; goalie is only player who cause an interference call. Called
									;from checkcx
	move.l	d0,-(sp)
	bsr.w	.ci
	exg	a2,a3
	bsr.w	.ci
	exg	a2,a3
	move.l	(sp)+,d0
	rts
.ci	tst.w	position(a2)			;position: a2 must be a goalie
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	rtss					;no fall downs during celebrate
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	beq.w	.pc						;a3 has the puck, skip the $19 test
	cmpi.w	#$19,impact(a3)			;impact of a3 (92 tests impact(a2) > 10)
	ble.w	rtss
.pc	cmpi.w	#2,impact(a3)			;impact test
	ble.w	rtss
	exg	a2,a3
	bsr.w	FallDown				;a3 falls
	exg	a2,a3
	cmpi.w	#$1E,impact(a2)			;impact 30
	ble.w	rtss
	btst	#pf2pen,pflags2(a3)		;caused a penalty (92 used 6)
	bne.w	rtss					;no double minor
	moveq	#$14,d0					;penalty 3 times in (20 - aggress)
	sub.b	aggress(a3),d0
	bsr.w	randomd0
	cmp.w	#2,d0
	bhi.w	rtss
	btst	#gmhl,(gmode).w
	bne.w	rtss
	move.l	#$22,d0					;penalty $22 (92 used $1C)
	bra.w	AddPenalty

checkcheck							;player is in contact look for various contact events. Runs .cc for a3 on
									;a2, then for a2 on a3. d4 = impact. Called from checkcx
	movem.l	d0-d4/a0-a3,-(sp)
	bsr.w	.cc
	exg	a2,a3
	bsr.w	.cc
	movem.l	(sp)+,d0-d4/a0-a3
	rts

.cc	cmpi.w	#SPAHold,SPA(a2)		;player a3 is checking player a2
	beq.w	holdcheck				;if in hold animation
	cmpi.w	#SPAhook,SPA(a2)		;this anim also holds
	beq.w	holdcheck
	cmpi.w	#SPAsweepchk,SPA(a2)	;this anim goes to Bcheck
	beq.w	Bcheck
	cmpi.w	#SPAburst,SPA(a3)
	bne.w	rtss					;if not in cbut burst anim exit
	btst	#gmclock,(gmode).w
	beq.w	.nofight
	move.w	#$100,impact(a3)		;increased fight chance after clock stops
	move.w	#$100,impact(a2)
.nofight	move.w	(a2),d0			;direction from a3 to a2 picks the check animation
	sub.w	(a3),d0
	move.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	sub.w	facedir(a3),d0
	andi.w	#7,d0
	btst	#3,attribute(a3)		;xflip?
	beq.w	.0
	neg.w	d0
	addq.w	#8,d0
	andi.w	#7,d0
.0	asl.w	#1,d0					;d0 = direction * 2 into .list
	lea	.list(pc),a0
	move.w	(a0,d0.w),d1
	bset	#pfalock,pflags(a3)
	bsr.w	SetSPA

	tst.w	position(a2)			;goalie doesn't fall
	beq.w	rtss
	cmp.w	#$14,d4					;impact under 20: no fall
	blt.w	rtss
	moveq	#$78,d0					;start with 120 dec. (92 60)
	btst	#pfjoycon,pflags(a3)	;check if player controlled
	beq.w	.00						;branch if not
	asl.w	#1,d0					;mult. by 2
.00	sub.b	weight(a3),d0			;sub weight
	add.b	weight(a2),d0			;add weight
	lsr.w	#1,d0					;divide by 2
	sub.w	impact(a2),d0			;sub impact
	beq.w	.down
	bmi.w	.down
	bsr.w	randomd0
	cmp.b	checking(a3),d0			;Chk rating
	ble.w	.down
	bsr.w	checkagr				;penalty roll
	cmp.w	#4,d0
	bhi.w	rtss
	btst	#gmhl,(gmode).w
	bne.w	rtss
	move.b	(HVcount).l,d0			;HVcount
	andi.w	#2,d0
	addi.w	#$16,d0					;random penalty $16 or $18 (92 used $10)
	bra.w	AddPenalty
.down	bsr.w	checkagr			;roll a penalty, then a2 falls
	cmp.w	#3,d0
	bhi.w	.dn2
	btst	#gmhl,(gmode).w
	bne.w	.dn2
	move.b	(HVcount).l,d0			;HVcount
	andi.w	#2,d0
	addi.w	#$1A,d0					;penalty $1A or $1C (92 used $14, and #%110)
	bsr.w	AddPenalty
.dn2	bra.w	FallDown			;fall down

.list	dc.w	SPAshoulderchkl		;check anim by direction (8 entries)
	dc.w	SPAshoulderchkr
	dc.w	SPAhipchkr
	dc.w	SPAhipchkr
	dc.w	SPAhipchkr
	dc.w	SPAhipchkl
	dc.w	SPAhipchkl
	dc.w	SPAshoulderchkl

checkagr							;penalty roll for player a3. Range = (20 - byte $73) * 13, doubled for a
									;joystick player, halved within $28 of the puck in x and y. Return d0 =
									;randomd0 of that range; the callers call a penalty when it is small.
									;Called from checkcheck .cc, holdcheck and Bcheck
	moveq	#$14,d0
	sub.b	aggress(a3),d0
	mulu.w	#$D,d0
	btst	#pfjoycon,pflags(a3)
	beq.w	.nojoy
	asl.w	#1,d0					;joystick player: twice the range, fewer penalties
.nojoy	move.w	(a3),d1				;Xpos
	sub.w	(puckx).w,d1
	cmp.w	#$28,d1
	bgt.w	.far
	cmp.w	#-$28,d1
	blt.w	.far
	move.w	Ypos(a3),d1
	sub.w	(pucky).w,d1
	cmp.w	#$28,d1
	bgt.w	.far
	cmp.w	#-$28,d1
	blt.w	.far
	asr.w	#1,d0					;near the puck: half the range, more penalties
.far	bra.w	randomd0			;random roll of d0

holdcheck							;player a2 is in hold animation looking to hold opponent a3. Entered from
									;checkcheck .cc for SPAHold or SPAhook. Checks facing, clears the puck
									;carrier sflags, has a second hold anim, and rolls the penalty with
									;checkagr
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	tst.w	position(a3)
	beq.w	rtss					;no hold on goalies
	btst	#pf2fight,pflags2(a3)
	bne.w	rtss					;no hold on fighters
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa					;direction from a2 to a3
	sub.w	facedir(a2),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	rtss					;a3 must be within 1 direction of where a2 faces
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.nopc
	bclr	#sfssdir,(sflags).w		;a3 has the puck
.nopc	move.w	Xvel(a3),d0			;hold: both players get the average velocity
	add.w	Xvel(a2),d0
	asr.w	#1,d0
	move.w	d0,Xvel(a3)
	move.w	d0,Xvel(a2)
	move.w	Yvel(a3),d0
	add.w	Yvel(a2),d0
	asr.w	#1,d0
	move.w	d0,Yvel(a3)
	move.w	d0,Yvel(a2)
	bset	#pfalock,pflags(a3)
	move.w	#SPAflail,d1
	bsr.w	SetSPA
	exg	a2,a3
	bset	#pfalock,pflags(a3)
	move.w	#SPAHold2,d1
	cmpi.w	#SPAHold,SPA(a3)
	beq.w	.h2
	move.w	#SPAhook2,d1			;holding anim after SPAhook
.h2	bsr.w	SetSPA					;start the hold animation
	bsr.w	checkagr
	cmp.w	#6,d0
	bhi.w	.ex
	move.w	#$24,d0					;holding (92 used penalty $1E)
	cmpi.w	#SPAHold2,SPA(a3)
	beq.w	.pen
	move.w	#$1E,d0					;hooking
.pen	bsr.w	AddPenalty			;call the penalty
.ex	exg	a2,a3						;swap back
	st	(collflag).w
	rts

Bcheck								;player a2 is in SPAsweepchk and a3 is the other player. Entered from
									;checkcheck .cc. If OptPen is 0 and a2 is joystick controlled, a2 needs
									;randomd0($10 + a2 checking rating - a3 legstr) >= $C. If a3 is within 1
									;direction of where a2 faces, a3 falls and checkagr may call penalty $20
									;on a2. Sets collflag to -1
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	tst.w	position(a3)			;position: not on a goalie
	beq.w	rtss
	btst	#pf2fight,pflags2(a3)
	bne.w	rtss
	tst.w	(OptPen).w
	bne.w	.dir
	btst	#pfjoycon,pflags(a2)
	beq.w	.dir
	moveq	#$10,d0
	add.b	checking(a2),d0			;checking rating
	sub.b	legstr(a3),d0
	bsr.w	randomd0
	cmp.w	#$C,d0
	blt.w	rtss
.dir	move.w	(a3),d0				;direction test
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa					;direction from a2 to a3
	sub.w	facedir(a2),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	rtss
	exg	a2,a3
	bsr.w	FallDown				;a3 falls, a2 is the hitter
	bsr.w	checkagr
	cmp.w	#4,d0
	bhi.w	.ex
	move.w	#$20,d0
	bsr.w	AddPenalty
.ex	exg	a2,a3						;swap back
	st	(collflag).w
	rts

FallDown							;player a2 falls down, player a3 is the hitting player. Some players get
									;SPAstumble instead of a fall; also counts check stats for the hitter, has
									;a third fall anim (SPAflip), and injuries (setInjuryType) with a penalty.
									;Called from checkint.ci, checkcheck.cc and Bcheck; also entered from
									;setd0player
	cmpi.w	#$B,SCnum(a2)
	bgt.w	rtss					;not a player
	btst	#pf2fight,pflags2(a2)
	bne.w	rtss
	cmpi.w	#SPAinjury1,SPA(a2)		;already in one of the fall anims
	beq.w	rtss
	cmpi.w	#SPAstumble,SPA(a2)
	beq.w	rtss
	cmpi.w	#SPAfallfwd,SPA(a2)
	beq.w	rtss
	cmpi.w	#SPAfallback,SPA(a2)
	beq.w	rtss
	cmpi.w	#SPAflip,SPA(a2)
	beq.w	rtss
	move.w	#SPAstumble,d1			;instead of a fall when stickhand >= $C
	cmpi.b	#$C,stickhand(a2)		;timer nopuckb is 0 and impact < $10-$1F (HVcount)
	blt.w	.fall
	tst.b	nopuckb(a2)
	bne.w	.fall
	move.w	(HVcount).l,d0			;HVcount
	andi.w	#$F,d0
	addi.w	#$10,d0
	cmp.w	impact(a2),d0
	ble.w	.fall
	move.b	#$3C,nopuckb(a2)		;no second stumble until the timer runs out
	bra.w	.2

.fall	tst.w	position(a3)		;position: no check stats for a goalie hitter
	beq.w	.nostat
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a3)
	beq.w	.tm
	adda.w	#tmsize,a0
.tm	addq.w	#1,tmchecks(a0)			;team check count
	clr.w	d0
	move.b	pnum(a3),d0
	adda.w	d0,a0
	addq.b	#1,pchecks(a0)			;player check count
	addq.w	#1,(ChkCnt).w
	tst.b	fighting(a3)
	bne.w	.nostat
	addq.w	#2,(ChkCnt).w			;fighting is 0: ChkCnt +3
.nostat	move.b	#$78,nopuck(a2)		;nopuck = 120
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa					;direction from a2 to the hitter
	move.w	#SPAfallback,d1
	sub.w	facedir(a2),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bls.w	.2						;hit from the front: fall back
	move.w	#SPAfallfwd,d1
	move.w	facedir(a2),d0
	andi.w	#3,d0
	bne.w	.2
	cmpi.b	#$A,checking(a3)		;facedir 0 or 4 and hitter checking rating >= $A
	blt.w	.2
	cmpi.w	#$B,SCnum(a3)			;and the hitter is a player
	bgt.w	.2
	move.w	#SPAflip,d1				;third fall anim
.2	exg	a2,a3						;start the fall anim d1 on a2
	bset	#pfalock,pflags(a3)
	bsr.w	SetSPA
	exg	a2,a3

	addi.w	#$12C,(Crowdlevel).w	;300
	addi.w	#$F,(CwdExciteLvl).w	;raise crowd excitement

	move.w	(puckc).w,d0
	bmi.w	newcheck
	cmp.w	SCnum(a2),d0
	bne.w	newcheck				;a2 did not have the puck: check sound only
	st	(puckc).w
	btst	#gmhl,(gmode).w			;no injury in highlights
	bne.w	.snd
	cmpi.w	#SPAfallback,SPA(a2)	;injury: only from a fall back
	bne.w	.snd
	move.w	facedir(a2),d0
	andi.w	#3,d0					;with facedir 0 or 4
	bne.w	.snd
	btst	#pf2pen,pflags2(a2)		;caused a penalty (92 used 6)
	bne.w	.snd
	move.l	#$A0,d0
	bsr.w	randomd0
	cmp.w	impact(a2),d0			;injured if randomd0(160) <= impact
	bgt.w	.snd
	btst	#gmclock,(gmode).w
	bne.w	.snd
	exg	a2,a3
	move.w	#SPAinjury1,d1
	bsr.w	SetSPA
	exg	a2,a3
	bsr.w	setInjuryType
	move.w	#4,(InjCntDown).w
	move.l	#$14,d0					;penalty $14 if the hitter is a goalie or OptPen is 0
	tst.w	position(a3)
	beq.w	AddPenalty2
	tst.w	(OptPen).w
	beq.w	AddPenalty2
	move.l	#$12,d0					;else penalty $12, then Stop4Pen
	bsr.w	AddPenalty2
	bra.w	Stop4Pen
.snd	move.w	#SFXcrowdcheer,-(sp)	;92 used 25 via SFX
	btst	#pfteam,pflags(a2)
	bne.w	.3
	move.w	#SFXcrowdboo,(sp)		;92 used 26
.3	bsr.w	song					;play the crowd song
	rts

setInjuryType						;sets period injury. a2 = player injured, a3 = player checking. Marks a2
									;unavailable, pumps up the crowd, plays sfx $D, locks the scroll on a2,
									;sets TempPlOffset (pnum, bit 15 set for the away team) and puts $FFFD
									;(injured for the period) in a2's tmpdst. Called from FallDown and from
									;chkhit.fall
	bset	#pf2unav,pflags2(a2)	;set player unavailable (92 used 4)
	addi.w	#$12C,(Crowdlevel).w	;pump up crowd
	addi.w	#$1E,(CwdExciteLvl).w
	move.w	#SFXoooh2,-(sp)			;SFX
	bsr.w	sfx
	move.w	(a2),(xc1).w			;move X and Y pos to scroll center
	move.w	Ypos(a2),(yc1).w
	bset	#sfslock,(sflags).w		;scroll lock
	clr.w	d1
	movea.w	#(tmstruct-M68K_RAM),a0	;Home team struct into a0
	btst	#pfteam,pflags(a2)		;check if home or away
	beq.w	.0						;branch if home
	move.w	#$8000,d1				;away team flag
	adda.w	#tmsize,a0				;tmsize: away team struct
.0	move.b	pnum(a2),d1				;pnum: roster offset
	move.w	d1,(TempPlOffset).w
	ext.w	d1						;drop the away team flag
	add.w	d1,d1
	move.w	#$FFFD,tmpdst(a0,d1.w)	;tmpdst: $FFFD = injury for period
	rts

;======================================================================
;======================================================================
;	Collisions and checking: checkfight, SetInst, wall, goal and net collisions, Goal scoring, CheckBump and
;	puck collisions (checkpuckcoll). Field and flag names are in ram93.asm; 92 values are in the comments.

checkfight							;look for start of fight between players a2 & a3. Called from checkcx
									;Needs impact >= 10 on both, no anim lock, no penalty, no goalie, clock
									;running, no highlight and the puck not fighting or on a faceoff. SetInst
									;(both ways) decides, with d0 = 10 + max(0, 40 - ChkCnt)/4. If a3 then has
									;pf2fight, both players start fighting and everyone else watches
	cmpi.w	#$A,impact(a3)
	blt.w	rtss					;a3 impact < 10
	cmpi.w	#$A,impact(a2)
	blt.w	rtss					;a2 impact < 10
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#pfalock,pflags(a2)
	bne.w	rtss
	btst	#pf2pen,pflags2(a3)		;caused a penalty (92 used 6)
	bne.w	rtss
	btst	#pf2pen,pflags2(a2)
	bne.w	rtss
	tst.w	position(a3)
	beq.w	rtss					;no fights with goalies
	tst.w	position(a2)
	beq.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	rtss
	btst	#gmhl,(gmode).w
	bne.w	rtss
	btst	#pf2fight,(puckx+pflags2).w
	bne.w	rtss
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	#(puckx-M68K_RAM),a0
	move.w	assnum(a0),d0
	cmpi.b	#pfaceoff,asslist(a0,d0.w)	;pfaceoff (92 same)
	beq.w	.ex
	moveq	#$28,d0					;40 - ChkCnt
	sub.w	(ChkCnt).w,d0
	bpl.w	.pos
	clr.w	d0
.pos	lsr.w	#2,d0				;d0 = (40 - ChkCnt)/4
	addi.w	#$A,d0					;d0 = fight rating needed by SetInst
	bsr.w	SetInst
	exg	a2,a3
	bsr.w	SetInst
	exg	a2,a3
	btst	#pf2fight,pflags2(a3)	;set by SetInst?
	beq.w	.ex						;no fight
	clr.w	(ChkCnt).w
	moveq	#$19,d0					;26 players per team
	movea.w	#(tmstruct+pchecks-M68K_RAM),a0	;check count per player
.clr	clr.b	tmsize(a0)			;away team
	clr.b	(a0)+					;home team
	dbf	d0,.clr
	addi.w	#$3E8,(Crowdlevel).w	;add 1000
	addi.w	#$23,(CwdExciteLvl).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
	move.w	SCnum(a3),(puckc).w
	move.w	Ypos(a3),d1				;sets only yc1 (92 also set a clamped xc1)
	add.w	Ypos(a2),d1
	asr.w	#1,d1
	move.w	d1,(yc1).w
	bset	#sfslock,(sflags).w
	moveq	#2,d1					;make the players face each other
	move.w	(a3),d0
	cmp.w	(a2),d0
	blt.w	.1
	eori.w	#7,d1					;d1 = 5
.1	move.w	d1,facedir(a3)			;a3 faces d1, a2 the opposite way
	eori.w	#7,d1
	move.w	d1,facedir(a2)
	move.l	a3,-(sp)
	bsr.w	.sf
	exg	a2,a3
	bsr.w	.sf
	movea.w	#(SortCords-M68K_RAM),a3
	move.l	#afwatch,d0				;afwatch (92 same), other players watch fight
	moveq	#$B,d1
.0	btst	#pf2fight,pflags2(a3)	;loop over the 12 players
	bne.w	.next
	tst.w	position(a3)			;goalie
	beq.w	.next
	btst	#pf2unav,pflags2(a3)	;unavailable (92 used 4)
	bne.w	.next
	bsr.w	assinsert
.next	adda.w	#SCstruct,a3		;next player
	dbf	d1,.0
	movea.w	#(puckx-M68K_RAM),a3
	bset	#pf2fight,pflags2(a3)
	move.l	#pnothing,d0			;pnothing (92 same)
	bsr.w	assinsert
	st	(collflag).w
	movea.l	(sp)+,a3
.ex	movem.l	(sp)+,d0-d4/a0-a3		;restore registers
	rts

.sf	move.w	SCnum(a2),impactp(a3)	;start fight for a3 against a2. SCnum to impactp (92 called SetInst first
									;here)
	move.l	#$26,d0					;penalty $26 (92 used $20)
	bsr.w	AddPenalty2
	move.w	SCnum(a3),d0
	bsr.w	setd0player
	move.l	#afight,d0				;afight (92 same)
	bsr.w	assinsert
	bclr	#3,attribute(a3)
	move.w	#$FC00,d1				;Xvel -$400
	cmpi.w	#2,facedir(a3)			;facedir 2?
	beq.w	.sf2
	bset	#3,attribute(a3)		;flip the other way
	neg.w	d1
.sf2	move.w	d1,Xvel(a3)			;store the Xvel
	bset	#pf2unav,pflags2(a3)	;unavailable (92 used 4)
	bset	#pf2aip,pflags2(a3)
	bset	#pf2npc,pflags2(a3)		;no player coll (92 used 7)
	bclr	#pfalock,pflags(a3)
	move.w	#SPAfight,d1			;92 used $DE8
	bra.w	SetSPA

SetInst								;d0 = fight rating a3 needs. Called twice from checkfight (a2/a3 swapped)
									;Returns unless a3's fighting rating >= d0, a2's >= 2 and a2's >= $10 -
									;2 * a2's pchecks. Then sets pf2fight on a2
									;and a3. If a3 was not already fighting, OptPen is not 0 and HV counter &
									;3 is 0, calls AddPenalty2 with penalty $2A (92 used $22) and a3 = the
									;first skater on a3's team (not a3) that has no penalty and is available.
									;a3 is restored
	cmp.b	fighting(a3),d0
	bhi.w	rtss					;a3 fight rating < d0
	cmpi.b	#2,fighting(a2)
	blt.w	rtss					;a2 fight rating < 2
	clr.w	d1
	move.b	pnum(a2),d1
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a2)
	beq.w	.tm
	adda.w	#tmsize,a0
.tm	adda.w	d1,a0					;a0 = a2's slot in its team struct
	move.b	pchecks(a0),d1			;a2 check count
	asl.b	#1,d1
	neg.b	d1
	addi.b	#$10,d1					;d1 = $10 - 2 * check count
	cmp.b	fighting(a2),d1
	bgt.w	rtss					;a2 fight rating < d1
	bset	#pf2fight,pflags2(a2)
	bset	#pf2fight,pflags2(a3)
	bne.w	rtss					;a3 was already fighting
	tst.w	(OptPen).w
	beq.w	rtss
	move.w	(HVcount).l,d0			;HV counter
	andi.w	#3,d0
	bne.w	rtss					;3 of 4 times no penalty
	movea.l	a3,a4
	moveq	#5,d0
	movea.w	#(SortCords-M68K_RAM),a3
	btst	#pfteam,pflags(a4)
	beq.w	.1
	adda.w	#6*SCstruct,a3
.1	cmpa.w	a3,a4					;loop: skater on a3's team that is not a4
	beq.w	.next
	tst.w	position(a3)
	ble.w	.next
	btst	#pf2pen,pflags2(a3)		;caused a penalty (92 used 6)
	bne.w	.next
	btst	#pf2unav,pflags2(a3)	;unavailable (92 used 4)
	bne.w	.next
	move.w	#$2A,d0					;penalty $2A (92 used $22)
	bsr.w	AddPenalty2
	movea.l	a4,a3
	rts
.next	adda.w	#SCstruct,a3		;next skater
	dbf	d0,.1
	movea.l	a4,a3
	rts

checkwallcoll						;d2/d3 = x/y to test, a3 = object, wcradiusx/wcradiusy = radius. Called
									;from checkcoll
									;Check the corner circles, the goals and then the side and end boards.
									;Calls wallcollb (or checkgoal) on a hit, with d0/d1 = cos/sin of the wall
									;d4/d5 = rink half width $88 and half length $12A minus the object radius
	move.w	#$88,d4					;136 (92 used a RAM word)
	sub.w	(wcradiusx).w,d4
	move.w	#$12A,d5				;298
	sub.w	(wcradiusy).w,d5
	movem.w	d2-d5,-(sp)
	neg.w	d4
	neg.w	d5
	addi.w	#$40,d4					;.radius = 64, radius of the rink corners
	addi.w	#$40,d5
	;in an end zone: goal mouth x range gives checkgoal, outside it the corner circle
	cmp.w	d5,d3
	bgt.w	.ctc					;not in the -y end zone
	cmp.w	d4,d2
	blt.w	.circle
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.circle
	movea.w	#(SortCords+(13*SCstruct)-M68K_RAM),a2	;goal at the -y end
	bsr.w	checkgoal
	bra.w	.exit
.ctc	neg.w	d5					;other end zone (+y)
	cmp.w	d5,d3
	blt.w	.exit					;between the end zones
	cmp.w	d4,d2
	blt.w	.circle
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.circle
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a2	;goal at the +y end
	bsr.w	checkgoal
	bra.w	.exit
.circle	sub.w	d4,d2				;corner circle: d2/d3 = offset from the circle centre
	sub.w	d5,d3
	move.w	d3,d0					;cos0 = dy/r
	move.w	d2,d1					;sin0 =-dx/r
	neg.w	d1
	muls.w	d3,d3
	muls.w	d2,d2
	add.l	d2,d3					;dist from dot
	cmp.l	#$1000,d3				;.radius*.radius
	bls.w	.exit
	exg	d0,d3
	bsr.w	Sroot
	exg	d0,d3
	ext.l	d0
	asl.l	#8,d0
	divs.w	d3,d0
	ext.l	d1
	asl.l	#8,d1
	divs.w	d3,d1
	bsr.w	wallcollb
.exit	movem.w	(sp)+,d2-d5			;restore d2-d5
	move.w	Wallcos(a3),d0
	or.w	Wallsin(a3),d0
	bne.w	rtss
	;no hit yet: check the side boards, then the end boards (d0/d1 = wall normal)
	move.w	#$100,d0				;now check side walls
	clr.w	d1
	cmp.w	d5,d3
	bge.w	wallcollb
	neg.w	d5
	neg.w	d0
	cmp.w	d5,d3
	ble.w	wallcollb
	exg	d0,d1
	cmp.w	d4,d2
	bge.w	wallcollb
	neg.w	d4
	neg.w	d1
	cmp.w	d4,d2
	ble.w	wallcollb
	rts

checkgoal							;look for coll with goal/net. a2 = goal struct, a3 = object, d2/d3 = x/y.
									;Called from checkwallcoll
									;Not the puck: checkgoalp. Puck inside the goal area: over the top (bounce
									;Zvel), through the mouth (Goal), off a post (deflect) or off the
									;side/back
									;(wallcoll)
	cmpi.w	#$D,Zpos(a3)			;.zside = 13, height of goal. Zpos
	bgt.w	rtss					;over goal
	cmpi.w	#puckscnum,SCnum(a3)	;puckSCnum
	bne.w	checkgoalp				;coll with player not puck
	sub.w	(a2),d2					;Xpos
	moveq	#$10,d4					;.xside = 16, width of goal/2
	add.w	(wcradiusx).w,d4
	cmp.w	d4,d2
	bgt.w	rtss
	neg.w	d4
	cmp.w	d4,d2
	blt.w	rtss
	sub.w	Ypos(a2),d3
	move.w	#2,d5					;.yside = 2, depth of goal/2
	add.w	(wcradiusy).w,d5
	cmp.w	d5,d3
	bgt.w	rtss
	neg.w	d5
	cmp.w	d5,d3
	blt.w	rtss
;inside goal area now
	st	(collflag).w
	cmpi.w	#$D,OldZpos(a3)			;.zside
	blt.w	.nod
	move.w	OldZpos(a3),Zpos(a3)
	bra.w	.deflectz
.nod	bclr	#pfgoal,pflags(a3)	;puck was below the top of the net
	move.w	(puckc).w,d0
	bmi.w	.nocon					;no puck carrier
	st	(puckc).w
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	move.b	#8,nopuck(a0,d0.w)		;92 wrote a word
	move.w	(pucky).w,d1
	btst	#pfgoal,pflags(a0,d0.w)	;carrier
	bne.w	.an
	neg.w	d1
.an	tst.w	d1						;carrier's side sign
	bpl.w	.nocon
	bset	#pfgoal,pflags(a3)
.nocon	move.w	#$FF00,d0			;-256
	move.l	Ypos(a3),d1
	sub.l	OldYpos(a3),d1
	asr.l	#8,d1
	beq.w	.sideentry
	bmi.w	.0
	neg.w	d0						;check top entry
	neg.w	d5
.0	add.w	d3,d5					;dy
	move.l	(a3),d3					;Xpos
	sub.l	OldXpos(a3),d3
	asr.l	#8,d3
	muls.w	d3,d5
	divs.w	d1,d5
	bvs.w	.sideentry
	sub.w	d5,d2
	cmp.w	d4,d2
	blt.w	.sideentry
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.sideentry
	clr.w	d1
	move.w	Ypos(a3),d3
	eor.w	d0,d3
	bmi.w	wallcoll
	neg.w	d0
	btst	#pfgoal,pflags(a3)
	bne.w	wallcoll
	cmpi.w	#$D,Zpos(a3)			;.zside, Zpos
	beq.w	.deflectsf
	subq.w	#1,d4					;mouth = half width - 1 (92 sub #5)
	cmp.w	d4,d2
	bgt.w	.deflectsf
	neg.w	d4
	cmp.w	d4,d2
	bge.w	Goal
.deflectsf	bsr.w	ChkShotStat		;off the post
	move.w	#$25,-(sp)				;sfx $25 when the clock is stopped (92 used 9)
	btst	#gmclock,(gmode).w
	bne.w	.snd
	move.w	#SFXoooh,(sp)			;sfx 8 (92 used 31) and crowd
	addi.w	#$12C,(Crowdlevel).w	;add 300
	addi.w	#$28,(CwdExciteLvl).w
.snd	bsr.w	sfx					;play the sound
	move.w	#$1000,d0
	bsr.w	randomd0
	tst.w	Ypos(a3)
	bmi.w	.df0
	neg.w	d0
.df0	move.w	d0,Yvel(a3)			;store the Yvel
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Zvel(a3)
	bra.w	puckflip
.deflectz	neg.w	Zvel(a3)		;Zvel = abs(Zvel): bounce up off the top
	bpl.w	rtss
	neg.w	Zvel(a3)
	rts
.sideentry	clr.w	d0				;through the side or back: wall normal along x, sign from x motion
	move.w	#$100,d1
	move.w	(a3),d2					;Xpos
	sub.w	OldXpos(a3),d2
	bmi.w	wallcoll
	neg.w	d1
	bra.w	wallcoll

Goal								;puck in goal. a3 = puck. Entered from checkgoal new song, sfx 0, score +1
									;for the scoring team (a2, a1 = the other
									;team), song $30 if the home team scored, a 6 byte ScoreSum entry,
									;goal/assist counts, PenGoalStuff, printscores1, new assignments for the
									;scoring team, puck into the net, siren SPA and penalty $E
	btst	#gmclock,(gmode).w
	bne.w	rtss
	bsr.w	ChkShotStat
	bsr.w	stop_current_song
	move.w	#SFXsiren,-(sp)			;SFXsiren (92 same, 0)
	bsr.w	sfx
	bsr.w	freezewindow
	addi.w	#$1F4,(Crowdlevel).w	;add 500 (92 800)
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	;scoring team a2: home if puck Ypos >= 0, away if negative; gmdir swaps the ends
	tst.w	Ypos(a3)
	bpl.w	.g0
	exg	a2,a1
.g0	btst	#gmdir,(gmode).w		;gmdir swaps the ends
	beq.w	.g1
	exg	a2,a1
.g1	addq.w	#1,tmscore(a2)			;score +1
	cmpa.w	#(tmstruct-M68K_RAM),a2
	bne.w	.nocheer
	move.w	#SngGoal,-(sp)			;song $30
	bsr.w	song
.nocheer	cmpi.w	#$B4,(ScoreSumbytes).w	;30 entries of 6 bytes full?
	bne.w	.sum
	subq.w	#6,(ScoreSumbytes).w	;overwrite the last entry
.sum	movea.w	#(ScoreSum-M68K_RAM),a0	;a0 = next 6 byte ScoreSum entry
	adda.w	(ScoreSumbytes).w,a0
	addq.w	#6,(ScoreSumbytes).w
	bsr.w	GetPeriodTimeRemaining
	move.w	d0,(a0)+				;entry word 0 = period/time
	moveq	#2,d0
	add.w	tmap(a2),d0
	sub.w	tmap(a1),d0
	move.b	d0,(a0)+				;byte 2 = 2 + tmap(a2) - tmap(a1)
	addi.w	#$1E,(CwdExciteLvl).w
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.home
	subi.w	#$14,(CwdExciteLvl).w	;less for an away goal
	bset	#7,-1(a0)				;byte 2 bit 7 = away team scored
	;record the scorer and assists in the ScoreSum entry and the team goal and assist bytes
.home	move.w	tmtouch1(a2),d0		;scorer
	move.b	d0,(a0)+				;byte 3
	move.w	#$FFFF,(a0)				;no assists yet
	addi.w	#tmgoals,d0
	addq.b	#1,(a2,d0.w)			;tmgoals of the scorer +1
	move.w	tmtouch2(a2),d0			;first assist
	bmi.w	.noast
	move.b	d0,(a0)+				;byte 4
	addi.w	#tmassists,d0
	addq.b	#1,(a2,d0.w)			;tmassists of the player +1
	move.w	tmtouch3(a2),d0			;second assist
	bmi.w	.noast
	move.b	d0,(a0)					;byte 5
	addi.w	#tmassists,d0
	addq.b	#1,(a2,d0.w)
.noast	move.w	tmgoalie(a1),d0		;goalie of the other team gets a goal against
	bmi.w	.pen
	addi.w	#tmgoals,d0
	addq.b	#1,(a1,d0.w)			;tmgoals of the other team's goalie +1
.pen	bsr.w	PenGoalStuff		;penalty and goal bookkeeping
	bsr.w	printscores1
	move.l	#7,d0					;assignment 7 (92 used 8)
	bsr.w	.setass
	;puck goes into the net: stops, sits behind the goal line, bounces up, no collision
	clr.w	(collflag).w
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	moveq	#6,d0
	tst.w	(a3)					;Xpos
	bpl.w	.1
	neg.w	d0
.1	move.w	d0,(a3)					;Xpos
	move.w	#$110,d0				;+goalline+8
	tst.w	Ypos(a3)
	bpl.w	.0
	neg.w	d0
.0	move.w	d0,Ypos(a3)				;store Ypos
	move.w	#$600,Zvel(a3)
	clr.w	Zpos(a3)
	st	(puckcross+pcframes).w		;no crossing frames for line 1
	st	(puckcross+pcsize+pcframes).w	;or line 2
	bset	#pfnc,pflags(a3)
	move.w	#pnothing,d0			;pnothing (92 same)
	bsr.w	assreplace
	move.l	a3,-(sp)
	adda.w	#SCstruct,a3
	move.w	#SPAsiren,d1			;92 used $FE8
	bsr.w	SetSPA
	movea.w	tmsort(a1),a3			;first sort obj of the other team (92 used the puck)
	move.l	#$E,d0					;penalty $E (92 used 6)
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts

.setass	move.l	a3,-(sp)			;d0 = assignment, a2 = team
	;give each skater of team a2 that is not fighting assignment d0, clear pfnc
	movea.w	tmsort(a2),a3			;in 92 this is a long
	moveq	#5,d3
.loop	tst.w	position(a3)		;loop over the 6 skaters
	ble.w	.nl
	btst	#pf2fight,pflags2(a3)
	bne.w	.nl
	bclr	#pfnc,pflags(a3)
	bsr.w	assinsert
.nl	adda.w	#SCstruct,a3			;next skater
	dbf	d3,.loop
	movea.l	(sp)+,a3
	rts

GetPeriodTimeRemaining				;return d0 = (gsp << 14 | PerTimeTotal) - gameclock. Called from Goal
									;(ScoreSum entry) and InProgress
	move.w	(gsp).w,d0
	swap	d0
	clr.w	d0
	lsr.l	#2,d0					;gsp in bits 14-15
	or.w	(PerTimeTotal).w,d0
	sub.w	(gameclock).w,d0
	rts

checkgoalp							;check for player a3 collision with goal/net a2. Entered from checkgoal
									;oval goal, .radiusx = 32, .radiusy = 11. Skipped for no player coll, Zpos
									;> 10 and non players. Calls CheckBump, then wallcoll with the normal
	btst	#pf2npc,pflags2(a3)		;no player coll (92 used 7)
	bne.w	rtss
	cmpi.w	#$A,Zpos(a3)
	bgt.w	rtss
	cmpi.w	#$B,SCnum(a3)
	bgt.w	rtss					;not a player
	;oval hit test: (dx/32)^2 + (dy/11)^2 <= 1, scaled by 256
	movem.w	d2-d3,-(sp)
	sub.w	Ypos(a2),d3
	move.w	d3,d0					;cos0 =-dy/r
	sub.w	(a2),d2					;Xpos
	move.w	d2,d1					;sin0 = dx/r
	neg.w	d0
	asl.w	#4,d2
	muls.w	d2,d2
	divu.w	#$400,d2				;.radiusx*.radiusx
	cmp.w	#$100,d2
	bhi.w	.exit
	asl.w	#4,d3
	muls.w	d3,d3
	divu.w	#$79,d3					;.radiusy*.radiusy
	add.w	d2,d3
	cmp.w	#$100,d3
	bhi.w	.exit					;outside the oval
	movem.w	(sp)+,d2-d3
	bsr.w	CheckBump
	movem.w	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	Sroot
	;normalise the normal (d0,d1) to length 256, then bounce
	move.w	d0,d2
	movem.w	(sp)+,d0-d1
	addq.w	#1,d2
	asl.l	#8,d0
	divs.w	d2,d0
	asl.l	#8,d1
	divs.w	d2,d1
	bsr.w	wallcoll
.exit	movem.w	(sp)+,d2-d3			;restore d2/d3
	rts

CheckBump							;supply minimum separation velocity for coll with walls/goal/net. a2 =
									;goal, a3 = player. Called from checkgoalp
									;When HV counter & $1F is 0 (92 & $F), the puck is within 40 y of the goal
									;and a3 is faster than $2000 in x or y: a quarter of a3's velocity goes to
									;the goal, a3 stops, and if the clock runs penalty 8. That path returns
									;straight to checkgoalp's caller
	movem.l	d0-d1,-(sp)
	move.w	(HVcount).l,d0			;HV counter
	andi.w	#$1F,d0
	bne.w	.ex
	move.w	(pucky).w,d0
	sub.w	Ypos(a2),d0
	cmp.w	#$28,d0					;40
	bgt.w	.ex
	cmp.w	#$FFD8,d0				;-40
	blt.w	.ex
	move.w	Xvel(a3),d0
	move.w	Yvel(a3),d1
	cmp.w	#$2000,d0				;.minv
	bgt.w	.bb
	cmp.w	#$E000,d0				;-.minv
	blt.w	.bb
	cmp.w	#$2000,d1
	bgt.w	.bb
	cmp.w	#$E000,d1
	blt.w	.bb
.ex	movem.l	(sp)+,d0-d1				;no bump: restore and return
	rts
.bb	adda.w	#$C,sp					;drop d0-d1 and the return to checkgoalp
	asr.w	#2,d0
	asr.w	#2,d1
	move.w	d0,Xvel(a2)
	move.w	d1,Yvel(a2)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	bset	#sfslock,(sflags).w
	btst	#gmclock,(gmode).w
	bne.w	rtss
	move.l	#8,d0					;penalty 8 (92 used $E)
	bra.w	AddPenalty2

wallcollb							;check for puck over wall. a3 = object, d0/d1 = cos/sin of the wall.
									;Called from checkwallcoll
									;Not the puck: wallcoll. Zpos > 29, or Zpos > 18 with Ypos < 280, goes
									;over: pfnc, scroll lock, frame of the next struct cleared and, if the
									;clock runs, penalty 6 for ltplayer. Also: Ypos >= 280, Xpos 13-15 and
									;Yvel >= $FA0 halves Yvel, starts SPAbglass on the next struct with sfx $E
									;and crowd, then goes over
	cmpi.w	#puckscnum,SCnum(a3)	;puck?
	bne.w	wallcoll				;not puck so wall coll
	cmpi.w	#$1D,Zpos(a3)			;Zpos (92 12*8/3 = 32)
	bgt.w	.0
	cmpi.w	#$12,Zpos(a3)			;Zpos (92 8*8/3 = 21)
	bls.w	wallcoll
	cmpi.w	#$118,Ypos(a3)			;Ypos 280 (92 274, checked first)
	blt.w	.0
	cmpi.w	#$D,(a3)				;Xpos
	blt.w	wallcoll
	cmpi.w	#$F,(a3)
	bgt.w	wallcoll
	cmpi.w	#$FA0,Yvel(a3)
	blt.w	wallcoll
	move.l	a3,-(sp)
	asr.w	Yvel(a3)				;halve Yvel
	adda.w	#SCstruct,a3
	move.w	#SPAbglass,d1
	bsr.w	SetSPA
	movea.l	(sp)+,a3
	move.w	#SFXbglass,-(sp)		;sfx $E
	bsr.w	sfx
	addi.w	#$258,(Crowdlevel).w	;add 600
	addi.w	#$F,(CwdExciteLvl).w
.0	bset	#sfslock,(sflags).w		;puck goes over the wall: lock the scroll
	bset	#pfnc,pflags(a3)
	tst.w	Ypos(a3)
	bpl.w	.1
	ori.w	#$8000,attribute(a3)
.1	clr.w	frame+SCstruct(a3)		;next object's frame (the puck shadow)
	btst	#gmclock,(gmode).w
	bne.w	rtss
	move.l	a3,-(sp)
	move.w	(ltplayer).w,d0
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.l	#6,d0					;penalty 6 (92 used $C)
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts

wallcoll							;d0 = cosine, d1 = sine of angle of incidence with wall, a3 = object.
									;Called from checkgoal, checkgoalp, wallcollb
									;Bounce a3 off the wall: the puck loses speed, flips and plays sfx
									;$28-$2B,
									;a player plays sfx $20 on a hard hit
	move.w	d0,Wallcos(a3)
	move.w	d1,Wallsin(a3)
	movem.l	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	Yvel(a3),d0
	muls.w	Xvel(a3),d1
	sub.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d2					;v1n
	movem.w	(sp),d0-d1
	muls.w	Xvel(a3),d0
	muls.w	Yvel(a3),d1
	add.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d3					;v1t
	neg.w	d2
	cmpi.w	#puckscnum,SCnum(a3)	;puckSCnum
	bne.w	.player
	bclr	#sf2shot,(sflags2).w
	tst.w	d2
	bpl.w	.nocoll
	asr.w	#2,d2					;reduce normal speed on puck
	cmp.w	#$FC00,d2				;-$400
	bgt.w	.pok
	move.w	#$800,d0
	bsr.w	randomd0
	neg.w	d0
	move.w	d0,Zvel(a3)
	bsr.w	puckflip
	move.w	d2,d0					;sfx $28 + ((v1n >> 10) + 4) & 3
	asr.w	#8,d0
	asr.w	#2,d0
	addq.w	#4,d0
	bpl.w	.sf0
	clr.w	d0
.sf0	andi.w	#3,d0				;negative index becomes 0; sfx index 0-3
	addi.w	#SFXpuckwall1,d0
	move.w	d0,-(sp)
	bsr.w	sfx
.pok	move.w	d3,d0				;reduce tangent speed on puck
	asr.w	#6,d0
	sub.w	d0,d3
	asr.w	#1,d0
	sub.w	d0,d3
	bra.w	.noadd
.player	cmp.w	#$3E8,d2			;1000
	bgt.w	.nocoll
	cmp.w	#$F000,d2				;-$1000
	bgt.w	.nosfx
	cmpi.w	#$A,impact(a3)
	blt.w	.nosfx
	move.w	#SFXplayerwall,-(sp)	;sfx $20 (92 used 15)
	bsr.w	sfx
.nosfx	asr.w	#2,d2				;reduce normal speed on player to 1/4
	cmp.w	#$FC7C,d2				;-900
	blt.w	.noadd
	move.w	#$FC18,d2				;-1000
.noadd	movem.w	(sp),d0-d1			;rotate normal/tangent speeds (d2/d3) back into Xvel/Yvel
	movem.w	d2-d3,-(sp)
	muls.w	d0,d3
	muls.w	d1,d2
	sub.l	d2,d3
	asr.l	#8,d3
	move.w	d3,Xvel(a3)
	movem.w	(sp)+,d2-d3
	movem.w	(sp),d0-d1
	muls.w	d1,d3
	muls.w	d0,d2
	add.l	d2,d3
	asr.l	#8,d3
	move.w	d3,Yvel(a3)
	tst.w	Zvel(a3)
	bmi.w	.nocoll
	clr.w	Zvel(a3)
.nocoll	addq.w	#4,sp				;drop saved cos/sin
	movem.l	(sp)+,d2-d3
	rts

checkpuckcoll						;look for puck coll with players. a3 = puck. Entered from pucknorm First
									;clears Yvel when Ypos > 400 or Ypos <= -400. Walks up and down the OOlist
									;from the puck and runs .ccx on each object within 22 in y:
									;stick (puckstick), body (puckbody) or goalie (puckgoalie)
	cmpi.w	#$190,Ypos(a3)			;Ypos 400
	bgt.w	.clrvy
	cmpi.w	#$FE70,Ypos(a3)			;-400
	bgt.w	.chkz
.clrvy	clr.w	Yvel(a3)			;puck beyond +-400 in y: stop y movement
.chkz	cmpi.w	#$10,Zpos(a3)		;Zpos, 6*8/3 = 16
	bgt.w	rtss					;feet in air
	move.w	SCnum(a3),d0
	asl.w	#1,d0					;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1			;current objects pos in OOlist
.0	cmp.w	#$F,d1					;sortobjs-1
	beq.w	.cl						;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4			;next higher object number
	move.w	(a2,d4.w),d5			;y pos of next higher object
	sub.w	Ypos(a3),d5
	cmp.w	#$16,d5					;.cbody+.cstick
	bgt.w	.cl						;no higher sprite coll
	bsr.w	.ccx
	addq.w	#1,d1
	bra.s	.0
.cl	move.w	(a0,d0.w),d1			;now walk down the OOlist from the puck's position
	beq.w	.ex						;puck is the lowest object
.1	clr.w	d4						;loop: examine the next lower object
	move.b	-1(a1,d1.w),d4			;next lower object number
	move.w	Ypos(a3),d5
	sub.w	(a2,d4.w),d5			;y pos of next lower object
	cmp.w	#$16,d5					;.cbody+.cstick
	bgt.w	.ex
	bsr.w	.ccx
	subq.w	#1,d1
	bne.s	.1
.ex	rts								;end of checkpuckcoll
.ccx	movem.l	d0-d7/a0-a3,-(sp)	;d4 = object number * 2
	lsr.w	#1,d4
	cmp.w	(puckc).w,d4
	beq.w	.exit					;puck carrier
	cmp.w	#$B,d4
	bgt.w	.exit					;not a player
	asl.w	#scsize,d4				;scsize
	movea.w	#(SortCords-M68K_RAM),a2
	adda.w	d4,a2
	btst	#pfnc,pflags(a2)
	bne.w	.exit					;object has no coll mode on
	tst.b	nopuck(a2)
	bne.w	.exit
	btst	#pf2unav,pflags2(a2)	;unavailable (92 used 4)
	bne.w	.chkbody
	cmpi.w	#5,Zpos(a3)				;Zpos, 2*8/3 = 5
	bgt.w	.chkbody
	cmpi.w	#$200,Zvel(a3)			;92 $100
	bgt.w	.chkbody
	move.l	a2,-(sp)
	bsr.w	GetHot
	add.w	(a2),d0					;Xpos
	sub.w	(a3),d0
	cmp.w	#$E,d0					;.cstick = 14
	bgt.w	.chkbody
	cmp.w	#$FFF2,d0				;-.cstick
	blt.w	.chkbody
	add.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	cmp.w	#$E,d1
	bgt.w	.chkbody
	cmp.w	#$FFF2,d1
	blt.w	.chkbody
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	move.l	#$C4,d1					;.cstick*.cstick
	tst.b	nopuck(a3)				;puck is not ready to be caught
	ble.w	.lo
	lsr.w	#2,d1
.lo	cmp.l	d1,d0					;dist^2 vs stick radius^2 (a quarter if nopuck(a3) > 0)
	bhi.w	.chkbody
	bsr.w	puckstick
	bra.w	.exit
.chkbody	tst.w	position(a2)	;stick missed: test the body; position 0 = goalie
	beq.w	.chkgoalie
	move.w	(a2),d0					;Xpos
	sub.w	(a3),d0
	cmp.w	#8,d0					;.cbody = 8
	bgt.w	.exit
	cmp.w	#$FFF8,d0				;-.cbody
	blt.w	.exit
	move.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	cmp.w	#8,d1
	bgt.w	.exit
	cmp.w	#$FFF8,d1
	blt.w	.exit
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#$40,d0					;.cbody*.cbody
	bhi.w	.exit
	bsr.w	puckbody
.exit	movem.l	(sp)+,d0-d7/a0-a3	;restore and return to the OOlist walk
	rts
.chkgoalie	move.w	(a2),d0			;Xpos
	sub.w	(a3),d0
	cmp.w	#$C,d0					;.cbg = 12
	bgt.s	.exit
	cmp.w	#$FFF4,d0				;-.cbg
	blt.s	.exit
	move.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	cmp.w	#$C,d1
	bgt.s	.exit
	cmp.w	#$FFF4,d1
	blt.s	.exit
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#$90,d0					;.cbg*.cbg
	movem.w	(sp)+,d0-d1
	bhi.s	.exit
	bsr.w	puckgoalie
	bra.s	.exit

;======================================================================
;======================================================================
;	Puck collisions (puckstick, setd0player, puckbody, puckgoalie, deflect), then the player roster code
;	(makepde ... setplayer, TryAddPlayerToList, ClampNibble).
;
;	setplayer writes the attribute bytes from the roster record: weight, legstr, legspd, aioff, aidef,
;	shotspd, shotacc, passacc, rostnum, spodds, stickhand, endurance, aggress, the fight and checking ratings
;	and handed.

puckstick							;puck collides with stick
									;a2 = player who collided, a3 = puck, d0 = distance^2 (from checkpuckcoll
									;.ccx)
									;a goalie skips the steal roll, a goalie needs a loose puck within
									;8, and the catch speed limit is 13000 + 700 * stickhand
	tst.w	position(a2)
	bne.w	.0
	btst	#gmhl,(gmode).w
	bne.w	rtss
.0	bclr	#pfdoff,pflags(a2)		;a2 touched the puck: clear pfdoff
	move.w	(puckc).w,d1
	bmi.w	.nosteal				;nobody has the puck
	asl.w	#scsize,d1				;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d1,a0					;a0 = puck carrier
	move.b	pflags(a0),d1
	move.b	pflags(a2),d2
	eor.w	d1,d2
	btst	#pfteam,d2
	beq.w	rtss					;no steal from team member
	cmp.l	#$24,d0					;6*6
	bhi.w	rtss					;smaller range for stealing puck
	tst.w	position(a2)
	beq.w	.steal					;a goalie always steals
	tst.w	position(a0)
	beq.w	rtss					;no steal from goalie
	move.b	stickhand(a0),d0
	bsr.w	makepde
	move.w	d0,-(sp)
	exg	a0,a2
	move.b	stickhand(a0),d0
	bsr.w	makepde
	exg	a0,a2
	neg.w	d0
	add.w	(sp)+,d0				;carrier - stealer
	addi.w	#$24,d0					;36
	bsr.w	randomd0
	cmp.w	#2,d0
	bhi.w	rtss					;steal fails
.steal	move.b	stickhand(a0),d0	;steal: both players get nopuck = scaled stickhand + 20
	bsr.w	makepde
	addi.w	#$14,d0					;20
	move.b	d0,nopuck(a0)
	exg	a0,a2
	move.b	stickhand(a0),d0
	bsr.w	makepde
	addi.w	#$14,d0
	move.b	d0,nopuck(a0)
	exg	a0,a2
	move.w	SCnum(a0),(lastplayer).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
.stdef	move.w	#SFXstdef,-(sp)		;stick deflect sound (92 used 5)
	bsr.w	sfx
	bsr.w	a2touchpuck
	bra.w	deflect

.nosteal	tst.w	position(a2)	;loose puck
	bne.w	.spd					;skater: any range
	cmp.l	#$40,d0					;8*8
	bhi.w	rtss					;goalie too far from a loose puck
.spd	move.w	(puckvx).w,d0		;d0 = puck speed^2, d1 = catch limit
	move.w	(puckvy).w,d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0					;puck speed^2 (92 scaled each by 1/64)
	clr.w	d1
	btst	#sf2shot,(sflags2).w
	bne.w	.nohand					;shot taken: no stickhand bonus
	move.b	stickhand(a2),d1
	mulu.w	#$2BC,d1				;* 700
.nohand	addi.w	#$32C8,d1			;+ 13000
	mulu.w	d1,d1
	cmp.l	d1,d0
	bls.w	puckglue				;slow enough to catch (92 320*64)
	move.b	#8,nopuck(a2)
	bra.s	.stdef

puckglue							;from 92 .glue. Player a2 takes the puck 
									;Global because puckgoalie .nopc also branches here. Plays sound effect
									;SFXpuckget, or after a faceoff (sf3fo) SFXcrowdboo (SFXcrowdcheer for the
									;home team), and counts a completed pass when a2 is passReceiverPlayerNum.
									;Falls into setd0player
	move.w	#SFXpuckget,-(sp)
	move.w	SCnum(a2),d0
	move.w	d0,(puckc).w
	movea.w	#(tmstruct-M68K_RAM),a0
	lea	tmsize(a0),a1
	btst	#pfteam,pflags(a2)
	bne.w	.tm
	exg	a0,a1
.tm	st	tmtouch2(a0)				;a0 = other team, a1 = a2's team
	st	tmtouch3(a0)
	bset	#tmflast,tmflags(a0)	;tmflast: other team did not touch it last
	bclr	#sf3fo,(sflags3).w
	beq.w	.snd					;no
	addq.w	#1,tmfowon(a1)			;tmfowon + 1
	addi.w	#$C8,(Crowdlevel).w		;+200
	move.w	#SFXcrowdboo,(sp)
	cmpa.w	#(tmstruct-M68K_RAM),a1
	bne.w	.snd					;away team
	addi.w	#$A,(CwdExciteLvl).w
	move.w	#SFXcrowdcheer,(sp)		;home team
.snd	bsr.w	song				;play the chosen sound effect
	move.w	SCnum(a2),d0
	cmp.w	(passReceiverPlayerNum).w,d0
	bne.w	.nrec
	addq.w	#1,tmpasscomp(a1)		;pass reached its receiver: tmpasscomp + 1
.nrec	st	(passReceiverPlayerNum).w	;no pass pending any more
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
	tst.w	position(a2)
	bne.w	setd0player
	bsr.w	ChkShotStat
	move.w	#$8C,temp5(a2)			;temp5 = 140, count down for faceoff (92 120)
	cmpi.w	#SPAgdive,SPA(a2)
	bne.w	setd0player
	move.w	#5,temp5(a2)			;temp5 = 5 for SPAgdive

setd0player							;give control of player d0 to a controller if his team is controlled d0 =
									;SCnum. Also called by checkfight.sf
	cmp.w	(c1playernum).w,d0
	beq.w	rtss					;already on controller 1
	cmp.w	(c2playernum).w,d0
	beq.w	rtss					;already on controller 2
	cmp.w	#6,d0
	slt	d1
	ext.w	d1
	addq.w	#2,d1					;d1 = 1 home (SCnum < 6), 2 visitors
	move.w	(lastplayer).w,d2
	cmp.w	(c2playernum).w,d2
	beq.w	.1						;last player was controller 2's: try cont 2 first
	cmp.w	(cont1team).w,d1
	beq.w	setc1player
.1	cmp.w	(cont2team).w,d1		;is controller 2 on this team?
	beq.w	setc2player
	cmp.w	(cont1team).w,d1
	beq.w	setc1player
	rts

puckbody							;puck hits player a2. a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx)
									;Uses the old puck speed: a fast puck above 12 knocks a2 down (FallDown),
									;a slower one above 8 plays SPAcatch on a2
	cmpi.w	#8,Zpos(a3)				;Zpos, 3*8/3
	bgt.w	.hit
	move.w	d0,d1
	andi.w	#$F,d1					;radius^2 from center
	bne.w	rtss
.hit	bsr.w	a2touchpuck			;real hit: a2 touched the puck
	move.w	#SFXpuckbody,-(sp)		;puck body sound (92 used 5)
	bsr.w	sfx
	clr.w	Zvel(a3)
	move.b	#8,nopuck(a2)
	move.w	(a3),d0					;Xpos
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0	move.w	Xvel(a3),d2				;old Xvel
	move.w	Yvel(a3),d3				;old Yvel
	move.b	d0,Xvel(a3)
	move.b	d1,Yvel(a3)
	bsr.w	puckflip
	cmpi.w	#8,Zpos(a3)
	ble.w	rtss					;puck low: no effect on a2
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d3,d2					;old speed^2
	cmp.l	#$9000000,d2			;$3000^2
	bls.w	.slow
	cmpi.w	#$C,Zpos(a3)			;Zpos 12
	bgt.w	FallDown
	rts
.slow	bset	#pfalock,pflags(a2)	;slow puck: lock a2's anim to catch it
	bne.w	rtss					;already in a locked anim
	move.w	#SPAcatch,d1			;on a2
	exg	a2,a3
	bsr.w	SetSPA
	exg	a2,a3
rtss	rts							;shared rts

puckgoalie							;puck hits goalie a2. a3 = puck, d0/d1 = goalie - puck x/y Save odds from
									;the goalie's save attribute and the frame table .list2. Crowd sound
									;effect on a hard shot, a puck carrier loses the puck, and a slow
									;loose puck (.nopc) is caught through puckglue
	btst	#gmhl,(gmode).w
	bne.s	rtss
	clr.w	d2						;puck region
	cmpi.w	#8,Zpos(a3)				;Zpos, 3*8/3
	bgt.w	.1
	addq.w	#2,d2
.1	neg.w	d0						;d0/d1 = puck - goalie; vtoa gives its direction
	neg.w	d1
	bsr.w	vtoa
	sub.w	facedir(a2),d0
	andi.w	#7,d0
;0 puck straight in front of goalie
;1-3 puck to goalies right
;4 puck straight behind goalie
;5-7 puck to goalies left
	move.w	d0,d1
	andi.w	#3,d1
	bne.w	.2
	move.w	(HVcount).l,d0			;HV counter, just for random bit
.2	andi.w	#4,d0					;bit 2 = side (right/left), random if front/back
	lsr.w	#2,d0
	eori.w	#1,d0
	add.w	d0,d2
	add.w	d2,d2
	lea	.list(pc),a0
	move.w	(a0,d2.w),d0
	moveq	#$F,d1
	add.b	(a2,d0.w),d1			;save odds
	lea	.list2(pc),a0
	btst	#3,attribute(a2)		;x flip?
	beq.w	.3
	eori.w	#2,d2
.3	move.w	frame(a2),d0			;goalie frame selects a .list2 byte, 2 bits per region
	subi.w	#SPFGoalie,d0
	move.b	(a0,d0.w),d0
	lsr.w	d2,d0
	andi.w	#3,d0
	mulu.w	d1,d0
	beq.s	rtss
	bsr.w	randomd0
	cmp.w	#8,d0
	blt.w	rtss					;no save
	bsr.w	ChkShotStat
	bsr.w	a2touchpuck
	cmpi.w	#$3000,(puckvy).w
	bgt.w	.setsfx
	cmpi.w	#$D000,(puckvy).w
	bgt.w	.nosong					;-$3000 < Yvel <= $3000: no crowd sound
.setsfx	move.w	#SFXcrowdcheer,-(sp)	;cheer sound effect (home goalie)
	btst	#pfteam,pflags(a2)
	beq.w	.song
	move.w	#SFXoooh2,(sp)			;oooh sound effect (visiting goalie)
.song	bsr.w	song				;play it (song plays sound effects too)
.nosong	move.w	#SFXpuckbody,-(sp)	;puck body sound (92 used 5)
	bsr.w	sfx
	move.w	(puckc).w,d2
	bmi.w	.nopc					;loose puck
	st	(puckc).w					;carrier loses the puck
	asl.w	#scsize,d2				;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d2,a0
	move.b	#$14,nopuck(a0)			;carrier nopuck = 20
	move.w	SCnum(a0),(lastplayer).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
.bounce	clr.w	Zvel(a3)			;puck rebounds off the goalie
	move.b	#$A,nopuck(a2)			;nopuck (92 8)
	move.w	#4,temp4(a2)
	move.w	(a3),d0					;Xpos
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0	move.b	d0,Xvel(a3)				;puck velocity = byte of the vector away from the goalie
	move.b	d1,Yvel(a3)
	bra.w	puckflip
.nopc	cmpi.w	#SPAgdive,SPA(a2)	;loose puck: a diving goalie always rebounds it
	beq.s	.bounce
	moveq	#2,d0
	add.b	shotspd(a2),d0			;shotspd byte
	asl.w	#8,d0
	asl.w	#1,d0					;d0 = (2 + shotspd) * 512
	bsr.w	randomd0
	addi.w	#$C00,d0				;catch speed limit
	cmp.w	(puckvx).w,d0
	blt.s	.bounce					;too fast in x
	cmp.w	(puckvy).w,d0
	blt.s	.bounce					;too fast in y
	neg.w	d0
	cmp.w	(puckvx).w,d0
	bgt.s	.bounce
	cmp.w	(puckvy).w,d0
	bgt.s	.bounce
	btst	#pf2unav,pflags2(a2)	;unavailable (92 used 4)
	bne.s	.bounce
	clr.w	Zvel(a3)
	bra.w	puckglue				;goalie holds the puck

.list	dc.w	GGSleft,passacc		;save attribute offsets (92 had stickhand,shotacc)
	dc.w	spodds,endurance

.list2								;odds for stopping puck in each quadrant for each possible goalie frame
	pix	1111,2131,1213				;ready/glover/glovel
	pix	1111,2131,1213
	pix	1111,2131,1213
	pix	1111,2131,1213
	pix	1111,2131,1213
	pix	1111,2131,1213
	pix	1111,2131,1213
	pix	1111,2131,1213
	pix	1111,1111					;goalie swing
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,3300					;goalie stack right
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300					;goalie stack left
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	;Rev B has 6 fewer stack left entries, so the stick entries start at frame +64, where the stick save
	;frames are (SPAgstickr). Rev 0/A read them from +70, so those frames got stack odds.
	IF REV<2
	pix	1111,3300
	pix	1111,3300
	pix	1111,3300
	ENDIF
	pix	3111,1311					;goalie stick right/left
	pix	3111,1311
	pix	3111,1311
	pix	3111,1311
	pix	3111,1311
	pix	3111,1311
	pix	3111,1311
	pix	3111,1311
	pix	1111,1111					;from here
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	1111,1111
	pix	3300,3300
	pix	3300,3300
	pix	3300,3300
	pix	3300,3300
	pix	3300,3300
	pix	3300,3300
	pix	3300,3300
	pix	3300,3300
	pix	1113,1113
	pix	1113,1113
	pix	2211,2211
	pix	2211,2211
	pix	2211,2211
	pix	2211,2211
	pix	2211,2211
	pix	2211,2211
	pix	2211,2211
	pix	2211,2211

deflect								;random puck direction on deflection puck = a3.
									;Entered from puckstick .stdef
	st	(puckc).w
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Yvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,Zvel(a3)
	bra.w	puckflip

makepde								;pass d0 as value to be scaled by player a0's energy level return d0 as
									;result. Called from puckstick and (ShotMode)
	ext.w	d0
	move.w	d0,-(sp)
	movem.l	d1/a2-a3,-(sp)
	movea.l	a0,a3
	bsr.w	getpde
	movem.l	(sp)+,d1/a2-a3
	muls.w	(sp)+,d0
	asl.l	#4,d0
	swap	d0
	ext.l	d0						;d0 = d0 * energy / 4096
	rts

getpde								;get player a3's energy level into d0. Return a2 = his team struct, d1 =
									;pnum*2
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)
	beq.w	.0
	adda.w	#tmsize,a2
.0	move.b	pnum(a3),d1				;d1 = pnum * 2, word index into tmpde
	ext.w	d1
	add.w	d1,d1
	move.w	tmpde(a2,d1.w),d0
	rts

setpde								;d1 = rostnum of player * 2, a2 = team struct
									;d0 = new energy level (no d1 range check)
	tst.w	d0
	bpl.w	.0
	clr.w	d0
.0	move.w	d0,tmpde(a2,d1.w)		;store the energy level (negative becomes 0)
	rts

setpersonel							;this will set personel on team a2 according to team a2's registers Asks
									;SetPlList for the wanted players, keeps the ones already on the ice, and
									;puts the rest in sort objs with no requested player
	movem.l	d0-d5/a0-a4,-(sp)
	movea.w	tmsort(a2),a3
	moveq	#5,d4
.l0	st	newpos(a3)					;clear the request of each of the 6 sort objs
	st	newpnum(a3)
	adda.w	#SCstruct,a3
	dbf	d4,.l0
	bsr.w	SetPlList
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4	;list of players we want on ice
.1	clr.w	d5						;pass 1, slot d4: keep wanted players who are already on the ice
	move.b	(a4,d4.w),d5
	beq.w	.next
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	tmsort(a2),a3
	suba.w	#SCstruct,a3
.2	adda.w	#SCstruct,a3			;search the sort objs for pnum d5
	cmp.b	pnum(a3),d5
	dbeq	d3,.2
	bne.w	.next					;not on the ice now
	move.b	plpos(a4,d4.w),newpos(a3)
	move.b	d5,newpnum(a3)
	clr.b	(a4,d4.w)
.next	dbf	d4,.1					;next PlList slot
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4
.3	clr.w	d5						;pass 2, slot d4: place the players still wanted
	move.b	(a4,d4.w),d5
	beq.w	.next2
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	tmsort(a2),a3
	suba.w	#SCstruct,a3
.4	adda.w	#SCstruct,a3			;next sort obj
	tst.b	newpnum(a3)
	dbmi	d3,.4					;find a sort obj with no requested player
	bpl.w	.chkpos					;none left
	movea.w	a3,a0					;a0 = free sort obj
.chkpos	tst.w	position(a3)		;does this obj have a position yet?
	dbpl	d3,.4					;keep looking while that obj has no position
	move.b	plpos(a4,d4.w),newpos(a0)
	move.b	d5,newpnum(a0)
	clr.b	(a4,d4.w)
.next2	dbf	d4,.3					;next PlList slot
	movem.l	(sp)+,d0-d5/a0-a4
	rts

SetPlList							;create list (PlList) of players who we want on the ice now a2 = team
									;struct. Reads the lines from tmlines, and falls back to
									;every roster player when sublist has no free player
	movea.w	#(PlList-M68K_RAM),a4
	clr.l	(a4)
	clr.w	4(a4)
	movea.l	#priolist,a0
	tst.w	tmgoalie(a2)
	bpl.w	.gin
	addq.w	#1,a0					;no goalie: skip priolist goalie entry
.gin	lea	tmlines(a2),a1			;line sets
	move.w	tmline(a2),d0
	asl.w	#3,d0
	adda.w	d0,a1
	move.w	tmap(a2),d4				;tmap, active players 4-6
	bra.w	.next
.0	clr.w	d5						;slot d4: d5 = position from priolist
	move.b	(a0,d4.w),d5			;position
	move.b	(a1,d5.w),(a4,d4.w)		;player number
	move.b	d5,plpos(a4,d4.w)
	bne.w	.next
	moveq	#1,d3
	add.w	tmgoalie(a2),d3			;goalie: 1 + tmgoalie (92 adds 1 for the 2nd goalie only)
	move.b	d3,(a4,d4.w)
.next	dbf	d4,.0					;next slot
	moveq	#5,d4					;now check to see if player is avail
.1	move.b	(a4,d4.w),d3			;slot d4: d3 = wanted player number (0 = empty)
	beq.w	.next1
	ext.w	d3
	subq.w	#1,d3
	add.w	d3,d3
	cmpi.w	#$FFFD,tmpdst(a2,d3.w)	;tmpdst -3
	beq.w	.sub
	tst.w	tmpdst(a2,d3.w)
	ble.w	.next1					;player is ok
.sub	lea	tmlines(a2),a1			;now find player of similar position who is available
	move.b	plpos(a4,d4.w),d0		;position
	ext.w	d0
	asl.w	#1,d0
	movea.l	#sublist,a0
	adda.w	(a0,d0.w),a0			;sublist is word offsets (92 long pointers)
.s1	clr.w	d0						;next substitute position from sublist
	move.b	(a0)+,d0
	bmi.w	.all					;end of list
	move.b	(a1,d0.w),d0
	bsr.w	TryAddPlayerToList
	beq.s	.s1						;not available
.next1	dbf	d4,.1					;next slot
	rts
.all	jsr	(GetPlayerCount).l		;try every roster player, last first
	move.w	d0,d3
.try	move.w	d3,d0				;d0 = candidate player number, d3 counts down
	subq.w	#1,d3
	bmi.s	.next1					;none available
	bsr.w	TryAddPlayerToList
	beq.s	.try
	bra.s	.next1

TryAddPlayerToList					;from 92 SetPlList .s1/.s2. d0 = player number (1 based), d4 = PlList slot
									;a2 = team struct, a4 = PlList. Return Z clear = added, Z set (d1 = 0) =
									;not available
	move.w	d0,d1
	subq.w	#1,d0
	add.w	d0,d0
	tst.w	tmpdst(a2,d0.w)
	bgt.w	.no						;in penalty box
	cmpi.w	#$FFFD,tmpdst(a2,d0.w)	;-3
	beq.w	.no
	moveq	#5,d0
.s2	cmp.b	(a4,d0.w),d1			;is d1 already in PlList?
	dbeq	d0,.s2
	beq.w	.no						;already in PlList
	move.b	d1,(a4,d4.w)
	rts
.no	clr.w	d1						;not available: Z set, d1 = 0
	rts

forcepldata							;no skating on/off force players to correct data (for faceoffs only) a2 =
									;team struct
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	tmsort(a2),a3
	moveq	#5,d4
.top	move.b	newpos(a3),d0		;each of the 6 sort objs: position = requested newpos
	ext.w	d0
	move.w	d0,position(a3)
	bmi.w	.next
	bsr.w	Setplass
	cmpi.w	#4,position(a3)			;center
	bne.w	.notnear
	move.l	#anearest,d0			;anearest (92 17)
	bsr.w	assinsert
.notnear	clr.w	d3				;d3 = requested player number
	move.b	newpnum(a3),d3
	add.w	d3,d3
	move.w	#$FFFF,tmpdst(a2,d3.w)	;tmpdst, put player on the ice
	lsr.w	#1,d3
	bsr.w	setplayer
.next	st	newpnum(a3)				;request consumed
	st	newpos(a3)
	adda.w	#SCstruct,a3
	dbf	d4,.top
	movem.l	(sp)+,d0-d4/a0-a3
	rts

ResetBench							;remove all players from penalty box/ put all players on their own bench
									;PBnum = players left in the box, home * 16 + visitors. Keeps -3 players
									;and drops box players with tmpdst bit 12 set and no time left from the
									;count
	clr.b	(PBnum).w
	moveq	#$10,d1
	movea.w	#(tmstruct-M68K_RAM),a0
	bsr.w	.rb
	moveq	#1,d1
	adda.w	#tmsize,a0				;tmsize, falls in for the visitors
.rb	moveq	#(maxros-1)*2,d0		;(MaxRos-1)*2
.rb1	add.b	d1,(PBnum).w		;loop over roster words d0; count this player as in the box
	tst.w	tmpdst(a0,d0.w)
	ble.w	.nopen
	btst	#4,tmpdst(a0,d0.w)		;leaving the box when the time runs out?
	beq.w	.next					;stays in the box
	move.w	tmpdst(a0,d0.w),d2
	andi.w	#$7FF,d2
	bne.w	.next					;time left
	sub.b	d1,(PBnum).w
	bra.w	.next
.nopen	sub.b	d1,(PBnum).w		;not in the box (tmpdst <= 0): uncount
	cmpi.w	#$FFFD,tmpdst(a0,d0.w)	;-3
	beq.w	.next
	move.w	#$FFFE,tmpdst(a0,d0.w)	;-2 bench
.next	subq.w	#2,d0				;previous roster entry
	bpl.s	.rb1
	rts

Setplass							;set players (a3) initial assignment
	move.w	position(a3),d0
	bmi.w	rtss
	lea	.alist(pc),a0
	move.b	(a0,d0.w),d0
	bra.w	assreplace

.alist								;asstab numbers
	dc.b	agoalie					;agoalie (92 15)
	dc.b	adefd					;adefd
	dc.b	adefd					;adefd
	dc.b	awingd					;awingd
	dc.b	acenterd				;acenterd
	dc.b	awingd					;awingd
	dc.b	acenterd				;acenterd
	IF REV=0
	dc.b	$FA						;Rev 0 pad (Rev A: 0)
	ELSE
	dc.b	PadByte
	ENDIF

setplayer							;bring player onto the ice and set his stats
									;d3 = player number, a3 = sortcord of player. Reads each attribute
									;nibble from a variable-length roster record and, for skaters, adds the
									;modifier bytes PPBonus / PKBonus (from sflags2 bit 5 and chkpk2),
									;HmAwBonus (home bonus / visitor penalty) and ThirdPBonus (2 when tied or
									;trailing with at least half of the 3rd period left, or after the 3rd
									;period), clamped to
									;0-15 by ClampNibble
	bclr	#pf2inj,pflags2(a3)		;not injured
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a3)
	beq.w	.0
	adda.w	#tmsize,a0
.0	move.b	d3,pnum(a3)				;a0 = this player's team struct
	move.l	#aepen,d0				;aepen (92 11)
	ext.w	d3
	add.w	d3,d3
	move.w	tmpdst(a0,d3.w),d1
	bpl.w	.da						;from the penalty box
	move.l	#aeben,d0				;aeben (92 10)
	cmp.w	#$FFFE,d1				;-2 bench
	bne.w	.nda
.da	bsr.w	assinsert				;enter the penalty box / bench exit assignment d0
	bclr	#pfalock,pflags(a3)
	clr.w	SPA(a3)
.nda	move.w	#$FFFF,tmpdst(a0,d3.w)	;tmpdst -1 on the ice
	lsr.w	#1,d3
	movea.l	tmdata(a0),a0
	move.l	a0,-(sp)
	adda.w	ScoutReport(a0),a0		;scouting report bytes
	clr.l	(PPBonus).w				;all four bonus bytes
	tst.w	position(a3)
	beq.w	.nomod					;goalie: no modifiers
	btst	#sf2pwrplay,(sflags2).w
	beq.w	.nda3
	bsr.w	chkpk2
	beq.w	.nda2
	move.b	1(a0),(PPBonus).w		;low nibble of byte 1
	andi.b	#$F,(PPBonus).w
	bra.w	.nda3
.nda2	move.b	1(a0),d0			;PKBonus path (chkpk2 returned Z)
	lsr.b	#4,d0
	neg.b	d0
	move.b	d0,(PKBonus).w			;-high nibble of byte 1
.nda3	move.b	2(a0),d0			;home/away bonus from byte 2
	andi.b	#$F,d0
	neg.b	d0						;visitors: -low nibble of byte 2
	btst	#pfteam,pflags(a3)
	bne.w	.tm
	move.b	2(a0),d0
	lsr.b	#4,d0					;home: high nibble of byte 2
.tm	move.b	d0,(HmAwBonus).w		;store the home/away modifier
	cmpi.w	#2,(gsp).w				;period
	blt.w	.nomod					;1st or 2nd period
	bgt.w	.score					;after the 3rd period
	jsr	(GetPeriodTime).w
	lsr.w	#1,d0
	cmp.w	(gameclock).w,d0
	bgt.w	.nomod					;under half of the 3rd period left (clock counts down)
.score	move.w	(tmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;- visitor score
	beq.w	.close					;tied
	btst	#pfteam,pflags(a3)
	beq.w	.side
	eori	#8,ccr					;visitors: flip N
.side	bpl.w	.nomod				;leading
.close	move.b	#2,(ThirdPBonus).w	;tied or trailing late in the game: +2 to some ratings
.nomod	movea.l	(sp)+,a0			;tmdata
	adda.w	(a0),a0					;roster records
.find	adda.w	(a0),a0				;skip name
	addq.w	#pldsize,a0				;skip 8 attribute bytes
	dbf	d3,.find
	subq.w	#pldsize,a0				;a0 = player d3's attribute bytes
	;roster attribute bytes (a0): 0 rostnum; 1 weight/legstr; 2 legspd/aioff; 3 aidef/shotspd;
	;4 checking/fight/handed; 5 stickhand/shotacc; 6 endurance/spodds; 7 passacc/aggress
	move.b	(a0),rostnum(a3)
	move.b	pldweight(a0),d3
	andi.w	#$F0,d3
	lsr.w	#1,d3					;(92 no shift)
	move.b	d3,weight(a3)
	move.b	pldweight(a0),d3
	andi.b	#$F,d3
	move.b	d3,legstr(a3)
	move.b	pldlegspd(a0),d3
	lsr.b	#4,d3
	move.b	d3,legspd(a3)
	move.b	pldlegspd(a0),d3
	andi.b	#$F,d3
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	eori.b	#$F,d3
	addi.b	#$F,d3					;frames to skip
	lsr.b	#1,d3
	move.b	d3,aioff(a3)
	move.b	pldaidef(a0),d3
	lsr.b	#4,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	eori.b	#$F,d3
	addi.b	#$F,d3					;frames to skip
	lsr.b	#1,d3
	move.b	d3,aidef(a3)
	move.b	pldaidef(a0),shotspd(a3)
	andi.b	#$F,shotspd(a3)
	move.b	pldcheck(a0),d3
	lsr.b	#4,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,checking(a3)			;checking rating
	bclr	#3,attribute(a3)
	move.b	pldcheck(a0),handed(a3)
	andi.b	#1,handed(a3)			;bit 0 set is left handed
	bne.w	.ha
	bset	#3,attribute(a3)
.ha	move.b	pldcheck(a0),fighting(a3)	;fight rating = byte 4 & $E
	andi.b	#$E,fighting(a3)
	move.b	pldstick(a0),d3
	lsr.b	#4,d3
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,stickhand(a3)
	move.b	pldstick(a0),d3
	andi.b	#$F,d3
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,shotacc(a3)
	move.b	pldendur(a0),d3
	lsr.b	#4,d3
	move.b	d3,endurance(a3)
	move.b	pldendur(a0),d3
	andi.b	#$F,d3
	add.b	(ThirdPBonus).w,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,spodds(a3)
	move.b	pldpass(a0),d3
	lsr.b	#4,d3
	add.b	(PPBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,passacc(a3)
	move.b	pldpass(a0),aggress(a3)	;aggress
	andi.b	#$F,aggress(a3)
	rts

ClampNibble							;clamp byte d3 to 0-15. Called by setplayer
	tst.b	d3
	bpl.w	.hi
	clr.w	d3						;negative: 0
.hi	cmp.b	#$F,d3					;above 15: clamp to 15
	ble.w	.x
	moveq	#$F,d3
.x	rts								;return d3 clamped to 0-15


	include video93.asm				;VBlank ... KillCrowd

;------------------------------------------------------------
;	Rink and team setup, title, playoffs and options screens
;------------------------------------------------------------

setupice							;set all variables, send non purgeable graphics, build sprite frame lists
									;for ice rink.
									;Called from StartGame and StartPer. 93 decompresses the tile sets with
									;DecompressGraphicsPlain / DecompressGraphicsWithRemap
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#df32c,(disflags).w
	move.w	#$C000,(VmMAP2).w		;map 2 address
	move.w	#6,(Map2col).w			;map 2 width
	move.w	#$DC00,(VSPRITES).w		;sprites address
	move.w	#$E000,(VmMAP1).w		;map 1 address
	move.w	#6,(Map1col).w			;map 1 width (same as 2 always)
	move.w	#$F000,(VmMAP3).w		;map 3 address (92 $F800)
	move.w	#5,(Map3col).w			;map 3 width (dependent on df32c mode)
	move.w	#$FC00,(VSCRLPM).w		;horizontal scroll address (92 $0000, set first)
	moveq	#0,d0					;color to fade to
	bsr.w	setVram
	bclr	#sfpz,(sflags).w

	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w

	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w		;2000
	st	(Zamx).w

	move.w	#$800,d0				;(92 $1000)
	move.w	(VmMAP1).w,d1
	move.w	#$7FF,d2				;(92 moveq #1,d2)
	bsr.w	DoFill					;erase map 1

	clr.w	d4						;vram char 0 (92 started at 2)
	move.w	d4,(rinkvrcset).w		;1st vram char for rink map tiles
	movea.l	#IceRinkMap+8,a2
	bsr.w	DecompressGraphicsPlain	;tiles to vram at d4, d4 advanced past them

	move.w	d4,(EASNcset).w			;1st vram char for easn logo tiles
	bsr.w	setupEASNmap

	move.w	d4,(energybarchars).w	;1st vram char for the energy bar tiles
	movea.l	#EnergyBarMap+8,a2
	bsr.w	DecompressGraphicsPlain

	move.w	d4,(crowdvrcset).w		;1st vram char for crowd animation tiles
	movea.l	#CrowdSprites+8,a2
	bsr.w	DecompressGraphicsPlain

	move.w	d4,(spritechars).w		;sprite char start, reused by setupice_highlight
	bsr.w	defaultsprites
	bsr.w	setupIceRinkPal			;transfer pal 0&1

	bsr.w	AddFramer				;Framer tiles (92 inline ReMap)
	move.w	d4,(smallfontchars).w	;1st vram char for smallfont tiles
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$43434567,$89ABCDEF		;remap table for the small font
	move.w	d4,(BigFontchars).w		;1st vram char for Bigfont tiles
	movea.l	#BigFontMap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$71234567,$89ABCDEF		;remap table for the big font

	bsr.w	setupTeamBlocksMap		;team blocks for both teams

	move.w	d4,(ExtraChars).w		;char space for extra graphics

	btst	#gmdir,(gmode).w
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0					;12 players
.l01	bchg	#pfgoal,pflags(a3)	;second half (gmdir set): swap pfgoal on all 12 players
	adda.w	#SCstruct,a3
	dbf	d0,.l01
.gok	bsr.w	setplayercolors		;copy both teams' palettes

	move.w	#$FFFF,(PadControlBits).w	;no pad assignments
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	st	(c1playernum).w
	st	(c2playernum).w

	movea.w	#(DMAList-M68K_RAM),a5	;dump pad sprites so numbers
	movea.w	#(Satt-M68K_RAM),a6		;aren't written over later.
	moveq	#1,d6
	movea.w	#(pads-M68K_RAM),a3
	clr.w	d0
	clr.w	d1
	bsr.w	addframe2
	adda.w	#ffosize,a3				;ffosize
	bsr.w	addframe2
	adda.w	#ffosize,a3				;ffosize
	bsr.w	addframe2
	move.l	a5,(DMAlistend).w
	bsr.w	dodmalist

	move.w	(sp)+,(disflags).w		;(palcount is set in setupice_highlight only)

	move.l	#VBlank,(VBint).w
	bclr	#dfok,(disflags).w
	bclr	#dfng,(disflags).w
	move.w	#$2300,sr

	movem.l	(sp)+,d0-d7/a0-a6
	rts

setupice_highlight					;Rebuild the rink sprites after a highlight replay without reloading
									;tiles, then fade in.
									;Called from StartHL2. Uses the sprite char start saved by setupice in
									;spritechars
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
	bclr	#sfpz,(sflags).w
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w		;2000
	st	(Zamx).w
	move.w	(spritechars).w,d4		;sprite char start from setupice
	bsr.w	defaultsprites
	bsr.w	setupIceRinkPal			;transfer pal 0&1
	btst	#gmdir,(gmode).w
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0					;12 players
.l01	bchg	#pfgoal,pflags(a3)	;gmdir set: swap pfgoal on all 12 players
	adda.w	#SCstruct,a3
	dbf	d0,.l01
.gok	bsr.w	setplayercolors		;copy both teams' palettes
	move.w	#$FFFF,(PadControlBits).w	;no pad assignments
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	st	(c1playernum).w
	st	(c2playernum).w
	bsr.w	setupEASNmap			;easn tiles at EASNcset again
	movea.w	#(DMAList-M68K_RAM),a5	;dump pad sprites
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6
	movea.w	#(pads-M68K_RAM),a3
	clr.w	d0
	clr.w	d1
	bsr.w	addframe2
	adda.w	#ffosize,a3				;ffosize
	bsr.w	addframe2
	adda.w	#ffosize,a3				;ffosize
	bsr.w	addframe2
	move.l	a5,(DMAlistend).w
	bsr.w	dodmalist
	move.w	#$1C,(palcount).w		;fade in new graphics now
	move.w	(sp)+,(disflags).w
	move.l	#VBlank,(VBint).w
	bclr	#dfok,(disflags).w
	bclr	#dfng,(disflags).w
	move.w	#$2300,sr
	movem.l	(sp)+,d0-d7/a0-a6
	rts								;(its only xref is a constant, so no label)

setupIceRinkPal						;copy the ice rink palettes (pal 0&1, 16 longs) to palfadenew.ipal.
									;Called from setupice, setupice_highlight
	movea.l	#IceRinkMap,a0
	adda.l	(a0),a0					;palette offset in the map header
	moveq	#$F,d0
	movea.w	#(palfadenew-M68K_RAM),a1
.ipal	move.l	(a0)+,(a1)+			;16 longs = palettes 0 and 1
	dbf	d0,.ipal
	rts

setupEASNmap						;from 92 setupice EASN block. Decompress the easn logo tiles to vram at
									;EASNcset. Called from setupice and setupice_highlight.
									;Return d4 = next free vram char
	move.w	(EASNcset).w,d4
	movea.l	#EASNmap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$71234567,$89ABCDEF		;remap table
	rts

setupTeamBlocksMap					;Load TeamBlocks.map tiles at d4+$30 and copy the home and visitor team
									;blocks (24 rows each) to vram at basetileoffset and basetileoffset+$18.
									;Called from setupice. d4 = 1st vram char; return d4 = basetileoffset+$30
	move.w	d4,(basetileoffset).w
	addi.w	#$30,d4					;skip the 48 chars for the two team blocks
	movea.w	#(TeamBlockMap-M68K_RAM),a1	;map word buffer for CopyTeamBlockMapData
	movea.l	#TeamBlocksmap,a0
	lea	jimtilecount(a0),a2
	bsr.w	DecompressGraphicsPlain	;all team block tiles to vram at d4
	adda.l	jimdata(a0),a0			;map data
	move.l	a0,-(sp)
	move.w	(HomeTeam).w,d0
	move.w	(basetileoffset).w,d1
	asl.w	#5,d1					;vram address of char
	bsr.w	CopyTeamBlockMapData
	movea.l	(sp)+,a0
	move.w	(VisTeam).w,d0
	move.w	(basetileoffset).w,d1
	addi.w	#$18,d1					;visitor block after the 24 home chars
	asl.w	#5,d1
	bsr.w	CopyTeamBlockMapData
	move.w	(basetileoffset).w,d4
	addi.w	#$30,d4
	rts

CopyTeamBlockMapData				;Copy one team's 24 block chars from the loaded tile set to vram at d1 by
									;vram dma and store their map words at (a1)+. a0 = map data, d0 = team, d1
									;= vram address.
									;Called from setupTeamBlocksMap
	mulu.w	#$30,d0					;24 map words per team
	lea	4(a0,d0.w),a0
	moveq	#$17,d3					;24 chars
.row	moveq	#$20,d0				;32 bytes per char
	move.w	d1,-(sp)
	move.b	(a0),(a1)				;keep the map word flag bits
	andi.w	#$F800,(a1)
	lsr.w	#5,d1					;vram address back to char number
	ori.w	#$8000,d1				;priority
	or.w	d1,(a1)+
	move.w	(sp)+,d1
	move.w	(a0)+,d2
	andi.w	#$7FF,d2				;source char in the loaded tile set
	add.w	(basetileoffset).w,d2
	addi.w	#$30,d2
	asl.w	#5,d2					;source vram address
	bsr.w	DoDMA_nd2				;vram to vram copy
	addi.w	#$20,d1					;next char
	dbf	d3,.row
	rts

defaultsprites						;allocate vram and assign char area for graphic
									;structures. d4 = char area for data.
									;Called from setupice and setupice_highlight. 93 splits off the SortCords
									;half as defaultsprites2 (jumped to at the end)
	movea.l	#.listsso,a2
	movea.w	#(sso-M68K_RAM),a3
	moveq	#ssonum-1,d0			;92 used 4 sso objects: 2 arrows + 2 scoreboard logos
.ssotop	move.w	#$FFFF,oldframe(a3)	;screen objects not locked to scroll of screen
	move.w	(a2)+,Xcord(a3)
	move.w	(a2)+,Ycord(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4				;vram char size (92 also kept it in VRsize)
	adda.w	#ssosize,a3
	dbf	d0,.ssotop

	movea.l	#.listffo,a2
	movea.l	#pads,a3				;ffo (first ffo is the pads)
	moveq	#ffonum-1,d0
.ffotop	st	oldframe(a3)			;objects tied to screen scrolling (not players/net/puck)
	move.w	(a2)+,(a3)				;Xpos
	move.w	(a2)+,Ypos(a3)
	move.w	(a2)+,Zpos(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4				;vram char size
	adda.w	#ffosize,a3				;ffosize
	dbf	d0,.ffotop
	bra.w	defaultsprites2

.listsso							;xcord,ycord,frame,attribute,vram char size
	dc.w	0,0,0,0,9
	dc.w	0,0,0,0,9

.listffo							;xcord,ycord,zpos,frame,attribute,vram char size
	dc.w	0,0,$FFFF,SPFpad+2,0,7
	dc.w	0,0,$FFFF,SPFpad,0,7
	dc.w	0,0,$FFFF,SPFpad+1,0,7
	dc.w	0,0,$FFFF,SPFreplay,$8000,7	;attribute 0, 12 chars
	dc.w	0,0,$FFFF,SPFgloves,0,5

defaultsprites2						;from 92 defaultsprites .0 loop. objects which are tied to screen
									;scrolling and have velocity relative to icerink
									;also set some variables in the structure to default settings.
									;Jumped to from defaultsprites, also called from setoptions. d4 = vram
									;char; ends in SprSort
	clr.w	d6
	movea.w	#(OOlist-M68K_RAM),a1
	lea	.list(pc),a2
	movea.w	#(SortCords-M68K_RAM),a3
	movea.w	#(OOlistpos-M68K_RAM),a4
.0	moveq	#$1F,d0					;(SCstruct/4)-1
	movea.w	a3,a0
.1	clr.l	(a0)+					;clear the whole SortCords struct
	dbf	d0,.1

	move.w	d6,SCnum(a3)
	st	oldframe(a3)
	st	pnum(a3)
	move.w	(a2)+,(a3)				;Xpos
	move.w	(a2)+,Ypos(a3)
	move.w	(a2)+,Zpos(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4				;vram char size
	move.w	(a2)+,radiusx(a3)
	move.w	(a2)+,radiusy(a3)
	addq.w	#1,a2
	move.b	(a2)+,asslist(a3)
	addq.w	#1,a2
	move.b	(a2)+,pflags(a3)

	adda.w	#SCstruct,a3
	asl.w	#1,d6
	move.b	d6,(a1)+				;OOlist seed
	lsr.w	#1,d6
	move.w	d6,(a4)+				;OOlistpos
	addq.w	#1,d6
	cmp.w	#Sortobjs,d6			;Sortobjs
	bne.s	.0
	bra.w	SprSort

.list								;xcord,ycord,zcord,frame,att,vrsize,radx,rady,asslist,pflags
	dc.w	$180,$C0,0,1,0,$14,8,4,0,$80	;home team, 1<<pfgoal (92 first player at -200,-120)
	dc.w	-$C8,-$64,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$50,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$3C,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$28,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$14,0,1,0,$14,8,4,0,$80

	dc.w	$C0,$C0,0,1,1,$14,8,4,0,$40	;visitor team, 1<<pfteam (92 first player at -200,20)
	dc.w	-$C8,$28,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$3C,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$50,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$64,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$78,0,1,1,$14,8,4,0,$40

	dc.w	0,$10C,0,SPFgoal,0,$B,$14,6,0,0	;goal net (92 used $18E)
	dc.w	0,-$10C,0,SPFgoal+1,0,$11,$14,6,0,0

	dc.w	0,0,0,SPFpuck+1,0,1,5,5,pnorm,1	;puck: pnorm, 1<<pfdoff
	dc.w	0,0,0,SPFpuck,0,$11,3,3,pshad,4	;puck shadow: pshad, 1<<pfnc (92 used $183, 4 chars)

SprSort								;sort objects in struct SortObj and set corresponding tables for keeping
									;them sorted later
	movem.l	d0-d4/a0-a2,-(sp)
	movea.l	#OOlistpos,a2
	movea.l	#Ylist,a1
	movea.l	#SortCords,a0
	move.w	#$F,d3					;Sortobjs-1
.loop0	move.w	Ypos(a0),d4			;fill Ylist with each object's sort key (Ypos, Xpos if sfhor)
	btst	#sfhor,(sflags).w
	beq.w	.l01
	move.w	(a0),d4					;Xpos
.l01	move.w	d4,(a1)+			;update ylist
	adda.w	#SCstruct,a0
	dbf	d3,.loop0

	movea.l	#Ylist,a1
.loop	clr.w	d4					;one bubble pass over OOlist; d4 = swapped flag
	movea.l	#OOlist,a0
	move.w	#$E,d3					;Sortobjs-2
	clr.w	d0
	clr.w	d1
.0	move.b	(a0)+,d0				;object number *2
	move.b	(a0),d1
	move.w	(a1,d0.w),d2			;pos of sup lower sprite
	cmp.w	(a1,d1.w),d2
	ble.w	.1
	move.b	d0,(a0)
	move.b	d1,-1(a0)

	move.l	a0,d2
	subi.l	#OOlist,d2
	move.w	d2,(a2,d0.w)
	subq.w	#1,d2
	move.w	d2,(a2,d1.w)

	st	d4							;flag for incomplete sort
.1	dbf	d3,.0						;next adjacent pair
	tst.w	d4
	bne.s	.loop					;swapped something: another pass
	movem.l	(sp)+,d0-d4/a0-a2
	rts

resetplstuff						;reset team variables/and players on both teams. Called from puckfaceoff2
									;and StartHL2
	movem.l	d0-d2/a0-a3,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	.top
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize
	bsr.w	.top
	movem.l	(sp)+,d0-d2/a0-a3
	rts

.top	bclr	#tmfoside,tmflags(a2)	;clear team flag bit 4
	moveq	#5,d2
	movea.w	tmsort(a2),a3
.loop	clr.b	pflags2(a3)			;pflags2 (92 also cleared pflags3)
	tst.w	position(a3)
	bmi.w	.next
	move.w	#SPAglide,d1			;92 $346
	bsr.w	SetSPA
	clr.w	impact(a3)
	clr.b	nopuck(a3)				;clear the byte
	andi.b	#$C2,pflags(a3)			;keep pfteam, pfgoal, pfna in pflags
.next	adda.w	#SCstruct,a3		;next of the team's 6 sort objs
	dbf	d2,.loop
	rts

clearTeamStats						;from 92 setteams clear loop. clear both team structs (2 x tmsize) but
									;keep tmgoalie of each team, and set the first tmboxlist byte of each.
									;Falls into setteams.
									;Called from StartGame, StartHL2 and ScoutingReport
	move.w	(tmstruct+tmgoalie).w,-(sp)
	move.w	(awtmstruct+tmgoalie).w,-(sp)
	move.l	#tmsize-1,d0			;tmsize words = 2 x tmsize bytes (both team structs)
	movea.w	#(tmstruct-M68K_RAM),a0
.0	clr.w	(a0)+					;clear both team structs
	dbf	d0,.0
	move.w	(sp)+,(awtmstruct+tmgoalie).w
	move.w	(sp)+,(tmstruct+tmgoalie).w
	st	(tmstruct+tmboxlist).w
	st	(awtmstruct+tmboxlist).w

setteams							;use hometeam/visteam to set team structures. Falls in from
									;clearTeamStats, also called.
									;93 sets tmsort as a word and leaves the team data setup to
									;InitTeamStructure
	movem.l	d0/a0-a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(HomeTeam).w,d0
	move.w	#(SortCords-M68K_RAM),tmsort(a2)
	bsr.w	InitTeamStructure
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize
	move.w	(VisTeam).w,d0
	move.w	#(SortCords-M68K_RAM)+(6*SCstruct),tmsort(a2)
	bsr.w	InitTeamStructure
	movem.l	(sp)+,d0/a0-a2
	rts

InitTeamStructure					;from 92 setteams. Set up team struct a2 for team d0: store the team
									;number at tmteam, the team data address at tmdata ($1E, from the team
									;address table TeamList), and copy 14 longs of line data (team data +6
									;offset) to tmlines. Called from setteams
	move.w	d0,tmteam(a2)
	movea.w	#TeamList,a0			;team address table
	asl.w	#2,d0
	move.l	(a0,d0.w),tmdata(a2)
CopyTeamLines						;'Set Original lines' (LineEditorMenuText): copy the team data line
									;sets to tmlines. a2 = team struct, tmdata(a2) set
	moveq	#$D,d0					;14 longs
	movea.l	tmdata(a2),a0
	adda.w	LineSets(a0),a0			;lines offset in the team data
	lea	tmlines(a2),a1
.copy	move.l	(a0)+,(a1)+			;copy the line sets to tmlines
	dbf	d0,.copy
	rts

setplayercolors						;copy in correct color data for each team. Called from setupice,
									;setupice_highlight
									;StartHL2
	clr.w	d1
	movea.w	#(tmstruct-M68K_RAM),a0
	bsr.w	.sp
	moveq	#$20,d1
	adda.w	#tmsize,a0

.sp	movea.l	tmdata(a0),a2			;a0 = team struct, d1 = palette offset (0 home, $20 visitors)
	adda.w	Palettedata(a2),a2		;palettes
	adda.w	d1,a2
	movea.w	#(palfadenew+$40-M68K_RAM),a1
	adda.w	d1,a1
	moveq	#7,d0
.5	move.l	(a2)+,(a1)+				;copy 8 longs (one 16 color palette)
	dbf	d0,.5
	rts

PeriodOver							;what to do if period over. Branched to from
									;puckfaceoff when the clock runs out.
									;forceblack comes after the period count; no SetVideo or palcount here
	addq.w	#1,(gsp).w				;period number
	bchg	#gmdir,(gmode).w
	cmpi.w	#3,(gsp).w
	blt.w	.0						;periods 1-2 done
	beq.w	.nop					;3rd period done
	move.w	#3,(gsp).w				;overtime done: stay at 3
	tst.w	(OptPlayMode).w
	bne.w	.nop					;playoffs: decided by the score check
	move.w	#4,(gsp).w				;regular season: game over after overtime
.nop	move.w	(tmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;visitor score
	beq.w	.0						;tied: play overtime
	move.w	#4,(gsp).w				;game over
.0	bsr.w	forceblack				;fade the screen to black

IntermissionStart					;from 92 PeriodOver .sp. PeriodOver tail: reset the clock, song $36,
									;ticker scores playoff team stats at game over, then Intermission. Next
									;period, or GameOver when gsp = 4.
									;Also jumped to from StartGame (as _sp) for the pregame intermission
	jsr	ResetClock
	move.w	#SngEOP,-(sp)			;song $36 (92 used 3 here)
	bsr.w	song
	bsr.w	UpdateScores
	cmpi.w	#4,(gsp).w
	bne.w	.1						;not game over
	bsr.w	AddPlayoffTeamStats
.1	bsr.w	Intermission			;intermission screen
	cmpi.w	#4,(gsp).w
	beq.w	GameOver
	jmp	(StartPer).w

GameOver							;Save the password, show the playoff stats and playoff screen in playoff
									;mode, then song $35 and back to Opening2. Branched to from
									;IntermissionStart
	bsr.w	EncodePW
	tst.w	(OptPlayMode).w
	beq.w	.po						;regular season
	bclr	#sfpj,(sflags).w
	jsr	(PlayoffStatsScreen).w		;"Playoff Stats"
.po	bsr.w	PlayoffScreen			;returns at once outside playoff mode

ExitToOpening						;Song $35, then restart at Opening2. Falls in from GameOver also jumped to
									;from EndDemoOnPress to end the demo
	move.w	#SngTitle,-(sp)
	bsr.w	song
	bra.w	Opening2

Opening								;title screen, then into Opening2. Jumped to from Begin
	bsr.w	KillCrowd
	bsr.w	TitleScreen

Opening2							;reset the stack and clear the variables, then options, playoff screen,
									;scouting report and on to a new game
	bsr.w	KillCrowd				;stop the crowd sound
	move.w	#$2700,sr
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0	;varstart
.0	clr.l	(a0)+					;clear the variable area up to varend
	cmpa.w	#(varend-M68K_RAM),a0	;varend
	blt.s	.0
	move.l	#vb2,(VBint).w
	move.w	#$2500,sr
	bsr.w	setoptions
Opening3	bsr.w	PlayoffScreen	;playoff tree (returns at once outside playoff mode)
Opening4	bsr.w	ScoutingReport	;pregame scouting report
	jmp	(ChkShortPeriods).w			;first check pad 1 for short periods

PlayoffScreen						;bring up playoff screen if in playoff mode. Called from GameOver and
									;Opening2.
									;runs its own vblank and scrolls the tree a page ($70 pixels) at a time.
									;Returns when start is pressed (PlayoffScreenExit)
	tst.w	(OptPlayMode).w
	beq.w	rtss

	move.l	#VBlank_Playoff,(VBint).l
	bclr	#df32c,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$BC00,(VSPRITES).w
	move.w	#$B000,(VmMAP3).w
	move.w	#6,(Map3col).w
	move.w	#$C000,(VmMAP2).w
	move.w	#7,(Map2col).w
	move.w	#$E000,(VmMAP1).w
	move.w	#7,(Map1col).w			;128 col mode
	move.w	#0,d0					;fade to color
	bsr.w	setVram

	bsr.w	printz
	String	$FF,0,0					;(92 -$01,0,0)
	move.l	#$80,d0					;128 x 28
	moveq	#$1C,d1
	move.w	#$7FF,d2				;(92 moveq #1,d2)
	bsr.w	eraser

	bsr.w	printz
	String	$FD,0,0					;(92 -$03,0,0)
	moveq	#$28,d0					;40 x 2
	moveq	#2,d1
	move.w	#$7FF,d2
	bsr.w	eraser

	bsr.w	AddTeamBlock			;TeamBlocks tiles
	bsr.w	AddSmallFont			;smallfont tiles

	movea.l	#Arrowsmap+8,a2
	move.w	d4,(ExtraChars).w
	bsr.w	DecompressGraphicsPlain	;arrow tiles at ExtraChars

	bsr.w	printz
	String	$CE,0,0					;(92 -$01,60,4 before the Stanleymap bitmap)
	movea.l	#EASNBGMap,a0			;bitmap map data
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2					;width and height from the map header
	move.w	mapheight(a1),d3
	moveq	#3,d5
	bsr.w	dobitmap

	movea.l	#TitleLogoSprites,a1	;Titlemap2 palette to pal 0, tiles at logochars
	lea	8(a1),a2
	adda.l	(a1),a1
	moveq	#7,d0
	movea.w	#(palfadenew+$40-M68K_RAM),a0
.pal	move.l	-$40(a0),$20(a0)	;pal 0 -> pal 3
	move.l	(a1)+,-$40(a0)			;Titlemap2 palette -> pal 0
	move.l	-$20(a0),(a0)+			;pal 1 -> pal 2
	dbf	d0,.pal
	move.w	d4,(logochars).w
	bsr.w	DecompressGraphicsPlain

	move.w	#$104,(logoslide).w		;RAM reused by this screen
	move.w	#$110,(playoffspritey).w

	movea.l	#Vctrl,a0
	move.w	#$9202,(a0)				;window V position 2

	movea.w	#(potree-M68K_RAM),a1
	movea.l	#PlayoffTreeSetup,a0	;tree layout tables by gamelevel
	move.w	(gamelevel).w,d0
	asl.w	#1,d0
	adda.w	(a0,d0.w),a0
	clr.w	d4
	move.b	(a0)+,d4				;team count-1
.top	bsr.w	printz				;per team block: set map 1 origin, then x/y from the tree table
	String	$FF,0,0
	move.b	(a0)+,(printx+1).w
	move.b	(a0)+,(printy+1).w
	clr.w	d1
	move.b	(a1)+,d1				;team from potree
	add.w	d1,d1
	bsr.w	DrawTeamBlocks			;draw both team blocks
	dbf	d4,.top

	clr.w	d4
	move.b	(a0)+,d4				;arrow count-1
.top2	bsr.w	printz				;per bracket arrow: x and arrow number from the tree table
	String	$FF,0,2					;(92 move #2,printy)
	move.b	(a0)+,(printx+1).w
	clr.w	d0
	move.b	(a0)+,d0
	bsr.w	DrawTreeArrow			;draw the bracket lines
	dbf	d4,.top2

	bsr.w	printz
	String	$EF,0,0					;(92 -$11,0,0)
	cmpi.w	#7,(bosgames).w
	beq.w	.noscr
	clr.w	d4
	move.b	(a0)+,d4				;score count-1
	bmi.w	.noscr
	movea.w	#(gstruct-M68K_RAM),a2
.top3	move.b	(a0)+,(printx+1).w	;per series score: x, y from the tree table
	move.b	(a0)+,(printy+1).w
	bsr.w	PrintSeriesScore		;series scores
	adda.w	#gssize,a2				;gssize
	dbf	d4,.top3

.noscr	bsr.w	printsmallz			;round title
	String	$F8,1,1,$41,$1A
	lea	PlayoffScreenText(pc),a1
	move.w	(gamelevel).w,d0
	bsr.w	AdvanceStringPtr		;a1 = string d0
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w			;center it
	bsr.w	printsmall
	tst.w	(gamelevel).w
	beq.w	.nopage					;one page only
	bsr.w	printz
	String	$CD,$A,1,'Press [ or ] to page'
.nopage	move.w	#$18,(palcount).w	;24 frames per color flash
	move.w	#SngEOP,-(sp)			;song $36 (92 used 4)
	bsr.w	song

	clr.w	d0
	clr.w	d4
	move.w	#$FFFF,(PlayerScrollCtr).w	;scroll step (RAM shared with the stats screens)
	move.w	#1,(playoffscroll).w	;scroll position
	bsr.w	UpdatePlayoffScroll

.input	bsr.w	waitxc1				;main loop: flash color, wait a frame, then read pads
	movea.l	#rtss,a0				;no animation callback
	bsr.w	CallAnimationCallback
	bsr.w	HandlePlayoffInput		;page / exit input
	bra.s	.input

HandlePlayoffInput					;from 92 PlayoffScreen .jin. read both pads: start leaves PlayoffScreen,
									;right/left set the scroll step, then falls into
									;UpdatePlayoffScroll. Called from PlayoffScreen .input
	bsr.w	ReadJoy1
	move.w	d3,-(sp)
	bsr.w	ReadJoy2
	or.w	(sp)+,d3				;either pad
	btst	#sbut,d3				;sbut
	bne.w	PlayoffScreenExit
	btst	#rbut,d3				;rbut
	beq.w	.nr
	move.w	#$FFFE,(PlayerScrollCtr).w	;step -2
.nr	btst	#lbut,d3				;lbut
	beq.w	UpdatePlayoffScroll
	move.w	#2,(PlayerScrollCtr).w	;step +2

UpdatePlayoffScroll					;from 92 PlayoffScreen .scrup. move the tree one step (PlayerScrollCtr)
									;and stop on a page boundary ($70). The position is limited to +/-
									;min(gamelevel,3) pages; the vblank adds it to the hscroll. Falls in from
									;HandlePlayoffInput, also called from PlayoffScreen
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss					;not scrolling
	add.w	(playoffscroll).w,d0
	move.w	(gamelevel).w,d1
	cmp.w	#3,d1
	bls.w	.lim
	moveq	#3,d1					;at most 3 pages each way
.lim	mulu.w	#$70,d1				;limit = pages * $70 pixels
	cmp.w	d1,d0
	bgt.w	rtss
	neg.w	d1
	cmp.w	d1,d0
	blt.w	rtss
	move.w	d0,(playoffscroll).w
	clr.w	(playoffspritex).w
	move.w	d0,d1
	addi.w	#$124,d1
	cmp.w	#$40,d1
	blt.w	.nox					;playoffspritex = position+$124 only inside $40-$200, else 0
	cmp.w	#$200,d1
	bgt.w	.nox
	move.w	d1,(playoffspritex).w
.nox	ext.l	d0					;is the new position on a page boundary?
	divs.w	#$70,d0
	swap	d0						;remainder
	tst.w	d0
	bne.w	rtss					;not on a page yet
	clr.w	(PlayerScrollCtr).w		;stop
	rts

PlayoffScreenExit					;from 92 PlayoffScreen .exit. drop HandlePlayoffInput's return address and
									;return from PlayoffScreen. Branched to from
									;HandlePlayoffInput on start, so it has to be global
	addq.w	#4,sp
	rts

waitxc1								;each time palcount runs out, eor the color
									;word at palfadenew+$42 with $EE and
									;restart palcount at $18 (a color flash), then wait for the next vblank.
									;Called from PlayoffScreen .input
	tst.w	(palcount).w
	bpl.w	.wait					;palcount still counting
	eori.w	#$EE,(palfadenew+$42).w
	move.w	#$18,(palcount).w
.wait	move.w	(Vcount).w,d0		;wait until the vblank handler bumps Vcount
	cmp.w	(OldVcount).w,d0
	beq.s	.wait
	move.w	d0,(OldVcount).w
	rts

PrintSeriesScore					;from 92 PlayoffScreen .doscores. print best of 7 wins "t-b" for game
									;struct a2 at printx/printy (92 .doscores).
									;Called from PlayoffScreen .top3
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#6,(a1)+				;string length
	move.w	gspotwins(a2),d0		;gspotwins
	addi.w	#$30,d0					;'0'
	move.b	d0,(a1)+
	move.b	#$2D,(a1)+				;'-'
	move.w	gspobwins(a2),d0		;gspobwins
	addi.w	#$30,d0					;'0'
	move.b	d0,(a1)+
	clr.b	(a1)+
	movea.w	#(mesarea-M68K_RAM),a1
	bra.w	print

DrawTreeArrow						;from 92 PlayoffScreen .doarrow. draw tree arrow d0 from Arrows.map at
									;printx/printy (92 .doarrow).
									;Called from PlayoffScreen .top2
	movem.l	d0-d7/a0-a3,-(sp)
	movea.l	#ArrowsMap,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	jimdata(a1),a1
	movea.w	#null,a2				;no tiles
	clr.w	d1
	moveq	#2,d2
	moveq	#$17,d3					;23
	move.w	(ExtraChars).w,d4
	moveq	#0,d5					;(92 %0100)
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d7/a0-a3
	rts

DrawTeamBlocks						;from 92 PlayoffScreen .doteam. draw team block d1 (team*2) from
									;TeamBlocks.map at printx/printy; the user's team (potree entry
									;at potreeteam) gets printa $6000.doteam. Called from PlayoffScreen .top
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d0
	move.b	(a0,d0.w),d0
	add.b	d0,d0
	cmp.b	d0,d1
	bne.w	.nohi
	move.w	#$6000,(printa).w		;palette 3
.nohi	movea.l	#TeamBlocksmap,a1	;a1 = map header of the team blocks
	adda.l	jimdata(a1),a1
	movea.w	#null,a2				;no tiles
	clr.w	d0
	move.w	(a1),d2					;(92 moveq #13,d2)
	moveq	#2,d3
	moveq	#2,d4
	moveq	#0,d5					;(92 %0010)
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d7/a0-a3
	rts

VBlank_Playoff						;(it undecoded): the PlayoffScreen vblank handler (VBint).
									;If dfng is clear and Sattsize is set: clear Sattsize, DoDMA the sprite
									;table (Satt) to VSPRITES, then Vmaddr(VSCRLPM) and write
									;$FEA0+playoffscroll to the hscroll, then cramfade. Always Vcount+1,
									;p_music_vblank, rte
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.nosat
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
	move.w	(VSCRLPM).w,d0
	bsr.w	Vmaddr
	move.w	#$FEA0,d0
	add.w	(playoffscroll).w,d0
	move.w	d0,(a0)
.nosat	bsr.w	cramfade			;step the palette fade
.nograph	addq.w	#1,(Vcount).w	;frame counter
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
	rte

PlayoffScreenText					;round titles by gamelevel, printed with printsmall.
									;Used by PlayoffScreen .noscr
	String	'Playoffs'
	String	'Quarterfinals'
	String	'Semifinals'
	String	'Finals'
	String	'Champions'

;======================================================================
;======================================================================
;	ScoutingReport (team ratings and a typed commentary), the Stanley Cup celebration screen, TitleScreen with
;	its credits scroller and vblank, the sprite list helpers, and an unreferenced sound test (CheckSound).
;
;	printz strings: first byte -$ab = map/attribute code ($FF = map 1), then x, y. printsmallz codes: $F8
;	attribute,map,x,y; $F9 char set; $FC y; $FD x. DecompressGraphicsWithRemap is followed by its remap
;	table.

ScoutingReport						;pregame scouting report. Called from PeriodOver.
									;Draws both team blocks, the Ron Barr picture and the scouting report
									;ratings, then types out the commentary paragraphs listed in TestList.
									;Returns on start, or when screentimer runs out ($1E0 after the text ends)
	move.w	#SngScouting,-(sp)		;song $37
	bsr.w	song
	move.l	#vb2,(VBint).w
	bsr.w	clearTeamStats
	bclr	#df32c,(disflags).w
	move.w	#6,(Map1col).w
	move.w	#6,(Map2col).w
	move.w	#0,d0					;fade to color
	bsr.w	setVram

	bsr.w	AddTeamBlock
	bsr.w	AddSmallFont
	move.w	d4,(smallfont2chars).w	;1st vram char of the 2nd small font set
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$0A234567,$89ABCDEF		;remap table (Rev 0; / or.l)
	bsr.w	AddFramer

	bsr.w	printz
	String	$FE,0,0					;(92 -$02,0,0)
	movea.l	#EASNBGMap,a0			;bitmap map data (same as PlayoffScreen)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2					;40 x 28
	moveq	#$1C,d3
	moveq	#3,d5					;color fam 1-2
	bsr.w	dobitmap

	bsr.w	printz
	String	$FE,6,3
	moveq	#$21,d0					;33 x 9 frame
	moveq	#9,d1
	bsr.w	Framer

	bsr.w	printz
	String	$FF,1,1
	movea.l	#Ronbarrmap,a0			;Ron Barr picture: palette offset, then map header offset
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0				;a0 = palette
	adda.l	(a2)+,a1				;a1 = map header
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2					;width and height from the map header
	move.w	mapheight(a1),d3
	moveq	#$C,d5					;color fam 3-4
	bsr.w	dobitmap

	bsr.w	printz
	String	$FF,3,$D				;(92 -$01,3,6)
	move.w	(VisTeam).w,d1
	bsr.w	dotb

	bsr.w	printz
	String	$FF,$18,$D				;(92 -$01,24,6)
	move.w	(HomeTeam).w,d1
	bsr.w	dotb

	bsr.w	printsmallz
	String	CC_SetMapAndPosition,0,1,$15,$F,CC_SetFont,1	;attribute 0, map 1, x $15, y $F, char set 1
	lea	ScoutRatingText(pc),a1		;rating names
.pl	move.w	(a1),d0					;string length: half of it centers the name
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$15,d0					;center on column 21
	move.w	d0,(printx).w
	bsr.w	printsmall
	addq.w	#1,(printy).w
	eori.w	#2,(printfontset).w		;alternate char set each line
	tst.w	(a1)
	bpl.s	.pl						;-1 ends the list

	bsr.w	printsmallz
	String	CC_SetX,$1D,CC_SetY,$F,CC_SetFont	;x $1D, y $F, char set 0 (pad byte)
	movea.l	(HomeTeamRosterPtr).w,a0
	adda.w	ScoutReport(a0),a0		;a0 = home scouting report bytes
	movea.l	(AwayTeamRosterPtr).w,a2
	adda.w	ScoutReport(a2),a2		;a2 = away scouting report bytes
	bsr.w	PrintScoutRatings		;home ratings at x $1D
	bsr.w	printsmallz
	String	CC_SetX,7,CC_SetY,$F,CC_SetFont	;x 7, y $F, char set 0 (pad byte)
	exg	a0,a2
	bsr.w	PrintScoutRatings		;away ratings at x 7

	move.w	#$18,(palcount).w		;24
	move.l	#vb2,(VBint).w
	move	#$2500,sr

	bsr.w	InitScoutingDisplay		;a0 = TestList
	move.w	#$1A,(a0)+				;paragraph numbers into ScoutingReportText
	move.w	#$1B,(a0)+
	move.w	#$1D,(a0)+
	move.w	(HomeTeam).w,d0
	move.w	d0,(a0)+				;home team paragraph
	move.w	#$1D,(a0)+
	cmp.w	(VisTeam).w,d0
	beq.w	.same					;same team, one paragraph
	move.w	(VisTeam).w,(a0)+		;visiting team paragraph
.same	move.w	#$1D,(a0)+			;closing paragraphs $1D, $1C
	move.w	#$1C,(a0)+
	move.w	#$FFFF,(a0)				;end of list
	clr.w	(asv).w					;fast text flag
	move.w	#$7FFF,(screentimer).w	;frames left on the screen

.top	moveq	#0,d0				;main loop, once per frame: read pads
	bsr.w	waitx					;d1 = new presses
	btst	#sbut,d1				;sbut
	bne.w	rtss					;start leaves
	btst	#dbut,d1				;dbut
	beq.w	.upd
	st	(asv).w						;down: type the rest without delays
.upd	bsr.w	UpdateScoutingDisplay	;type the next word if the timer allows
	subq.w	#1,(screentimer).w
	bpl.s	.top
	rts

PrintScoutRatings					;print the 8 rating nibbles of the scouting report long at 4(a0), one per
									;line, at printx.
									;a0 = this team's scouting report, a2 = the other team's (for the combined
									;line). Called from ScoutingReport
	move.l	4(a0),d5				;bytes 4-7: shooting/skating, passing/defense,
									;checking/fighting, goalkeeping/overall
	moveq	#7,d6
.loop	eori.w	#2,(printfontset).w	;alternate char set each line
	rol.l	#4,d5					;next nibble
	move.w	d5,d0
	andi.w	#$F,d0
	bsr.w	PrintStatNumber
	cmp.w	#1,d6
	bne.w	.next
	bsr.w	PrintScoutLineRatings	;after goalkeeping: power play and home team lines
.next	dbf	d6,.loop				;8 nibbles in total
	rts

PrintScoutLineRatings				;print the power play line (byte 1 low nibble of a0 + byte 1 high nibble
									;of a2), and on the right column (printx >= $14) the home team line (byte
									;2 high nibble of a0 + low nibble of a2). Falls into PrintStatNumber
	eori.w	#2,(printfontset).w
	move.w	(a0),d0
	andi.w	#$F,d0
	move.w	(a2),d1
	lsr.w	#4,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bsr.w	PrintStatNumber
	eori.w	#2,(printfontset).w
	cmpi.w	#$14,(printx).w
	blt.w	StatNextLine			;left column: skip the home team line
	move.b	2(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	move.b	2(a2),d1
	andi.w	#$F,d1
	add.w	d1,d0

PrintStatNumber						;print d0 as a 2 digit number at printx/printy in the small font, then
									;move down a line.
									;Called from PrintScoutRatings, falls in from PrintScoutLineRatings
	moveq	#2,d1					;2 digits
	bsr.w	PushNumberWidth
	move.w	(printx).w,-(sp)
	bsr.w	printsmall
	move.w	(sp)+,(printx).w
StatNextLine						;Next line; branched to from PrintScoutLineRatings
	addq.w	#1,(printy).w
	rts

ScoutRatingText						;rating names for the scouting report, centered by ScoutingReport. -1 ends
									;the list
	String	'Shooting'
	String	'Skating'
	String	'Passing'
	String	'Defense'
	String	'Checking'
	String	'Fighting'
	String	'Goalkeeping'
	String	'Power Play Adv.'
	String	'-    Home Team Adv.    '
	String	'Overall'
	dc.w	-1

InitScoutingDisplay					;reset the scouting text scroller. Return a0 = TestList (paragraph list).
									;Called from ScoutingReport
	move.w	#$FFFF,(VertLineScrolling).w	;text line -1
	st	(PlayerScrollCtr).w			;negative: start the next paragraph
	clr.w	(SelectedPlayerIdx).w	;TestList index
	clr.w	(ScoutingReportTimer).w
	movea.w	#(TestList-M68K_RAM),a0
	rts

UpdateScoutingDisplay				;called every frame by ScoutingReport. When ScoutingReportTimer runs out
									;(at once if asv is set), print the next word of ScoutingReportText. '_'
									;'{' '}' '[' ']' print a team or player name.
									;PlayerScrollCtr = offset of the next word (negative: next paragraph),
									;scoutcolumn = column
	cmpi.w	#$1000,(ScoutingReportTimer).w
	bgt.w	rtss					;text finished ($7FFF)
	tst.w	(asv).w
	bmi.w	.go						;fast: no delay
	subq.w	#1,(ScoutingReportTimer).w
	bpl.w	rtss
.go	movea.l	#ScoutingReportText,a1	;time to print: a1 = text base
	move.w	(PlayerScrollCtr).w,d0
	bpl.w	.cont					;in a paragraph
	clr.w	(scoutcolumn).w			;column 0
	move.w	(SelectedPlayerIdx).w,d0
	addq.w	#2,(SelectedPlayerIdx).w
	movea.w	#(TestList-M68K_RAM),a0
	move.w	(a0,d0.w),d0			;next paragraph number
	bpl.w	.para
	move.w	#$7FFF,(ScoutingReportTimer).w	;end of list: stop typing
	move.w	#$1E0,(screentimer).w	;and leave the screen in 480 frames
	rts
.para	bsr.w	ScrollDisplayUp		;blank line between paragraphs
	movea.l	a1,a2
	bra.w	.cnt
.find	cmpi.b	#$D,(a2)+			;skip one $D ended paragraph
	bne.s	.find
.cnt	dbf	d0,.find				;skip d0 paragraphs
	suba.l	a1,a2
	move.w	a2,d0					;d0 = paragraph offset
.cont	lea	(a1,d0.w),a2			;a2 = next word to print
	move.w	#$A,(ScoutingReportTimer).w	;10 frames per word
	move.w	(scoutcolumn).w,d0
	cmpi.b	#$5F,(a2)				;'_'
	beq.w	.under
	cmpi.b	#$7B,(a2)				;'{' home team name
	beq.w	.home
	cmpi.b	#$7D,(a2)				;'}' away team name
	beq.w	.away
	cmpi.b	#$5B,(a2)				;'[' home player name
	beq.w	.hmtm
	cmpi.b	#$5D,(a2)				;']' away player name
	beq.w	.awtm
	st	(PlayerScrollCtr).w			;assume end of paragraph
	movea.w	#(TextBuffer-M68K_RAM),a0
	clr.w	d1						;word length
.word	cmpi.b	#$D,(a2)			;copy one word into TextBuffer (d1 = length, d0 = column)
	beq.w	.eol					;end of paragraph
	addq.w	#1,d0
.copy	move.b	(a2),(a0)+			;copy the word and its trailing spaces
	addq.w	#1,d1
	cmpi.b	#$2C,(a2)				;','
	beq.w	.pause
	cmpi.b	#$2E,(a2)				;'.'
	bne.w	.nopause
.pause	addi.w	#$28,(ScoutingReportTimer).w	;40 more frames after punctuation
.nopause	cmpi.b	#$20,(a2)+		;stop the word at a space
	bne.s	.word
	cmpi.b	#$20,(a2)
	beq.s	.copy
	subq.w	#1,d0
	suba.w	a1,a2
	move.w	a2,(PlayerScrollCtr).w	;offset of the next word
.eol	move.w	d1,(mesarea).w		;make a String at mesarea
	addq.w	#2,(mesarea).w
	btst	#0,d1
	beq.w	.even
	clr.b	(a0)					;pad
	addq.w	#1,(mesarea).w
.even	movea.w	#(mesarea-M68K_RAM),a1	;a1 = the string to print
.print	cmp.w	#$1D,d0				;past column 29?
	ble.w	.noscr
	bsr.w	ScrollDisplayUp			;wrap to a new line
.noscr	bsr.w	printz				;position the word: x 9 + column, y 4 + line
	String	$FF,9,4
	move.w	(scoutcolumn).w,d0
	add.w	d0,(printx).w			;x 9 + column
	move.w	(VertLineScrolling).w,d0
	add.w	d0,(printy).w			;y 4 + text line
	bsr.w	print
	add.w	d1,(scoutcolumn).w
	rts
.awtm	movea.w	#(awtmstruct-M68K_RAM),a1	;away player name
	bra.w	.team
.hmtm	movea.w	#(tmstruct-M68K_RAM),a1	;home player name
.team	move.w	tmgoalie(a1),d1		;goalie's roster index
	movea.l	tmdata(a1),a1
	adda.w	(a1),a1					;player data
	bra.w	.pn
.pl	adda.w	(a1),a1					;skip name and 8 bytes of ratings
	addq.w	#pldsize,a1
.pn	dbf	d1,.pl						;step through d1 roster records
	bra.w	.name
.away	movea.l	(AwayTeamRosterPtr).w,a1	;away team name
	bra.w	.tname
.under	movea.l	#Montreal,a1		;team block
	cmpi.w	#$18,(tmstruct+tmgoalie+2).w
	bge.w	.tname					;used when >= $18
.home	movea.l	(HomeTeamRosterPtr).w,a1	;home team name
.tname	adda.w	Teamname(a1),a1		;team name
.name	addq.w	#1,(PlayerScrollCtr).w	;step past the escape char
	add.w	(a1),d0
	subq.w	#1,d0
	move.w	(a1),d1
	subq.w	#2,d1					;d1 = chars
	tst.b	1(a1,d1.w)
	bne.w	.print
	subq.w	#1,d1					;less the pad byte
	bra.w	.print

ScrollDisplayUp						;next text line for UpdateScoutingDisplay (column 0). After line 7, move
									;the text box up one row (DoDMA_nd2 copies 8 rows of $3A from VmMAP1+$212,
									;rows $80 apart) and stay on the last line
	clr.w	(scoutcolumn).w
	addq.w	#1,(VertLineScrolling).w
	cmpi.w	#7,(VertLineScrolling).l
	blt.w	rtss
	subq.w	#1,(VertLineScrolling).w
	movem.l	d0-d3,-(sp)
	move.l	#7,d3
	move.w	(VmMAP1).w,d1
	addi.w	#$212,d1				;text box top left
.loop	move.l	#$3A,d0				;copy 8 rows of the text box up by one row
	move.w	d1,d2
	addi.w	#$80,d2					;from the row below
	bsr.w	DoDMA_nd2				;vram copy d2 -> d1
	move.w	d2,d1
	dbf	d3,.loop
	movem.l	(sp)+,d0-d3
	rts

SetupStanleyCupCelebrationScreen	;Stanley Cup screen. Five EASN bitmaps at StanleyCupPosTable with
									;SpinningEASN sprites over them, $50 x 4 frames or until a button. Called
									;from Begin. Rev B shows one EA Sports picture instead
	IF REV=2
	move.l	#vb2,(VBint).w
	ELSE
	move.l	#VBlank_StanleyCup,(VBint).l
	ENDIF
	bclr	#df32c,(disflags).w
	move.w	#5,(Map3col).w
	move.w	#$A000,(VmMAP2).w
	move.w	#7,(Map2col).w
	move.w	#$C000,(VmMAP1).w
	move.w	#7,(Map1col).w
	move.w	#$F000,(VmMAP3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d1
.clr	clr.l	(a0)+				;black palettes
	dbf	d1,.clr
	bsr.w	CopyPaletteToCRAM
	bsr.w	setVram_0

	bsr.w	printz
	String	$FE,0,0					;(the lea in this string)
	IF REV=2
	movea.l	#EASportsMap2,a2
	movea.l	a2,a0					;a0 = palette (first long), a1 = map header (second long), a2 = tiles
	movea.l	a2,a1
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	mapheight(a1),d3
	clr.w	d4
	moveq	#$F,d5					;color fam 1-4
	bsr.w	dobitmap
	move.w	#$18,(palcount).w		;24
	move	#$2500,sr
	move.w	#$50,(seed).w
.wait	moveq	#4,d0				;wait for $50 steps or a button
	bsr.w	waitx
	tst.w	d1
	bne.w	.ex						;any button
	subq.w	#1,(seed).w
	bpl.s	.wait
.ex	move	#$2700,sr				;interrupts off again before returning
	rts
	ELSE
	lea	StanleyCupPosTable(pc),a4
.top	move.w	(a4)+,(printx).w	;each StanleyCupPosTable entry: column, row of one EASN bitmap
	move.w	(a4)+,(printy).w
	movea.l	#EASNmap2,a0
	movea.l	a0,a1
	adda.l	(a0),a0					;palette
	adda.l	jimdata(a1),a1			;map header
	movea.w	#null,a2				;a zero word: no tiles
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	mapheight(a1),d3
	clr.w	d4
	moveq	#$F,d5					;color fam 1-4
	bsr.w	dobitmap
	tst.w	(a4)
	bpl.s	.top
	movea.l	#EASNmap2+8,a2
	clr.w	d4						;tiles at vram char 0
	bsr.w	DecompressGraphicsPlain
	movea.l	#SpinningEASN+8,a2
	move.w	d4,(logochars).w		;1st vram char of the cup sprites
	bsr.w	DecompressGraphicsPlain
	bsr.w	UpdateStanleyCupAnimation
	move.w	#$18,(palcount).w		;24
	move	#$2500,sr
	move.w	#$50,(seed).w
.wait	moveq	#4,d0				;animate for $50 steps: waitx, then check buttons
	bsr.w	waitx
	tst.w	d1
	bne.w	.ex						;any button
	bsr.w	UpdateStanleyCupAnimation
	subq.w	#1,(seed).w
	bpl.s	.wait
.ex	move	#$2700,sr				;interrupts off again before returning
	rts
	ENDIF
	IF REV<2

UpdateStanleyCupAnimation			;one SpinningEASN sprite at each StanleyCupPosTable spot, frame 1 + asv
									;(0-7), then close the sprite list. Called from
									;SetupStanleyCupCelebrationScreen
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6					;link counter
	addq.w	#1,(asv).w
	andi.w	#7,(asv).w
	movea.l	#SpinningEASN,a0
	lea	StanleyCupPosTable(pc),a4
	move.w	(logochars).w,d3
.top	move.w	(a4)+,d0			;each table entry: column in d0, row in d1
	asl.w	#3,d0
	addi.w	#$58,d0					;x = column * 8 + $58
	move.w	(a4)+,d1
	asl.w	#3,d1
	addi.w	#$38,d1					;y = row * 8 + $38
	moveq	#1,d2
	add.w	(asv).w,d2
	bsr.w	SetSframe
	tst.w	(a4)
	bpl.s	.top
	bra.w	EndSpriteList

VBlank_StanleyCup					;VBint handler for the Stanley Cup screen: sprite table dma, cramfade,
									;Vcount
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.x
	move.w	(Sattsize).w,d0
	beq.w	.nos
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	movea.w	#(Satt-M68K_RAM),a0
	bsr.w	DoDMA
.nos	bsr.w	cramfade			;step the palette fade
.x	addq.w	#1,(Vcount).w			;frame counter
	movem.l	(sp)+,d0-d7/a0-a6
	rte

StanleyCupPosTable					;column, row of the five Stanley Cup bitmaps and sprites. -1 ends
	dc.w	3,1
	dc.w	$1C,1
	dc.w	$10,9
	dc.w	3,$12
	dc.w	$1C,$12
	dc.w	-1
	ENDIF

TitleScreen							;bring up title screen and credits. Called from PeriodOver.
									;Titlemap backdrop, three Title3map sprites, Titlemap2 logo sprites,
									;scrolling credits. Start leaves
	move.w	#SngTitle,-(sp)			;song $35 (92 used 1)
	bsr.w	song
	move.w	(HVcount).l,(seed).w	;seed randomd0 from the H/V counter
	move.w	(HVcount).l,(seed+2).w
	move.l	#VBlank_TitleScreen,(VBint).l
	bset	#df32c,(disflags).w
	move.w	#5,(Map3col).w
	move.w	#$A000,(VmMAP2).w
	move.w	#7,(Map2col).w
	move.w	#$C000,(VmMAP1).w
	move.w	#7,(Map1col).w
	move.w	#$F000,(VmMAP3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	move.w	#0,d0					;fade to color
	bsr.w	setVram
	movea.l	#Vdata,a0
	move.w	#$9100,4(a0)			;window h position 0
	move.w	#$9216,4(a0)			;window v position 22 (92 $9200+22)
	move.w	#$8B03,4(a0)			;h scroll by line
	clr.w	(Vscroll).w

	;clear both title planes: map 1 ($FF) then map 2 ($FE), 128 x 32 cells of char $7FF
	bsr.w	printz
	String	$FF,0,0					;(92 -$01,0,0)
	move.l	#$80,d0					;128 x 32
	moveq	#$20,d1
	move.l	#$7FF,d2				;(92 moveq #1,d2)
	bsr.w	eraser

	bsr.w	printz
	String	$FE,0,0
	move.l	#$80,d0
	moveq	#$20,d1
	move.l	#$7FF,d2
	bsr.w	eraser

	clr.w	d4
	bsr.w	printz
	String	$FE,0,$16
	movea.l	#Title1Map,a1			;rows $16 down of Titlemap, map only
	adda.l	jimdata(a1),a1
	movea.w	#null,a2				;a zero word: no tiles
	clr.w	d0
	moveq	#$16,d1
	move.w	(a1),d2
	move.w	mapheight(a1),d3
	sub.w	d1,d3
	moveq	#0,d5					;no palettes
	bsr.w	dobitmap

	bsr.w	printz
	String	$FD,0,0					;Title1Map
	movea.l	#Title1Map,a0			;whole Titlemap with palettes (Rev 0; Rev A)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	mapheight(a1),d3
	moveq	#$F,d5					;color fam 1-4
	bsr.w	dobitmap

	clr.w	(palfadenew).w
	moveq	#4,d0
	bsr.w	randomd0
	asl.w	#5,d0
	lea	TitlePalettes(pc),a1		;one of 4 random palettes
	adda.w	d0,a1
	movea.w	#(palfadenew+$20-M68K_RAM),a0
	moveq	#7,d0
.tops0	move.l	(a1)+,(a0)+			;copy 8 longs = 16 colors
	dbf	d0,.tops0

	bsr.w	printz
	String	$FE,0,$A
	movea.l	#Title2Map,a1			;bitmap
	lea	jimtilecount(a1),a2
	adda.l	jimdata(a1),a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	mapheight(a1),d3
	moveq	#0,d5					;no palettes
	bsr.w	dobitmap

	movea.l	#TitleLogoSprites+8,a2
	move.w	d4,(logochars).w		;1st vram char of the logo sprites
	bsr.w	DecompressGraphicsPlain
	movea.l	#Title3Sprites+8,a2
	move.w	d4,(menuspritechars).w	;1st vram char of the Title3map sprites
	bsr.w	DecompressGraphicsPlain
	clr.l	(fofdata2).w			;TitleAnimCallback timers
	clr.w	(fofdata2+4).w
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$08F04567,$89ABCDEF		;remap table (Rev 0; #$67 / or.l)

	bsr.w	printz
	String	$FF,0,0
	movea.l	#Credits,a1				;copyright lines
	bsr.w	.top4
	addi.w	#$20,(Vscroll).w
	move.w	#$104,(logoslide).w		;AddTitleLogoSprites logo slide in
	move.w	#$120,(playoffspritex).w	;logo x
	move.w	#$D0,(playoffspritey).w	;logo y
	clr.w	(asv).w
	move.w	#$FFCE,(titlescrollspeed).w	;Hscroll speed (UpdateHorizontalScroll)
	move.w	#$20,(palcount).w
	move	#$2500,sr

.top1	bsr.w	TitleScreen_wait	;wait for the logo
	tst.w	(logoslide).w
	bne.s	.top1

	move.w	#$3C,d3					;1 second
.tops	bsr.w	TitleScreen_wait	;one frame per pass, d3 = $3C passes
	dbf	d3,.tops

	bsr.w	printz
	String	$FF,0,0
	movea.l	#CreditsPages,a1		;credits pages after the copyright lines
.top2	bsr.w	.top4				;one credits page: erase rows, print a1 strings
	adda.w	(a1),a1
	moveq	#$2F,d4					;scroll 6*8 lines (92 6*8-1)
.top5	bsr.w	TitleScreen_wait	;scroll 1 line per 2 frames, 48 lines
	bsr.w	TitleScreen_wait
	addq.w	#1,(Vscroll).w
	dbf	d4,.top5
	moveq	#$78,d4					;120 frames (92 4*60)
.top6	bsr.w	TitleScreen_wait	;hold the page for 120 frames
	dbf	d4,.top6
	tst.w	2(a1)
	bpl.s	.top2
	rts

.top4								;erase 6 rows below the scroll and print a1 strings centered, to -1
	move.w	(Vscroll).w,d0
	asr.w	#3,d0
	addi.w	#$1C,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	move.w	d0,-(sp)
	clr.w	(printx).w
	moveq	#$20,d0
	moveq	#6,d1
	move.w	#$7FF,d2				;(92 moveq #1,d2)
	bsr.w	eraser
	move.w	(sp)+,(printy).w
.top4x	move.w	(a1),d0				;next string: x = $11 - length/2 (centered)
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$11,d0					;(92 16)
	move.w	d0,(printx).w
	bsr.w	print
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w
	tst.w	2(a1)
	bpl.s	.top4x
	rts

TitleAnimCallback					;CallAnimationCallback routine for the title
									;screen (from TitleScreen_wait).
									;Three Title3map sprites: a running fofdata2 timer shows the sprite and
									;counts down; a stopped one restarts at 20 when Hscroll + $1EC -
									;TitleScrollTriggers entry is within 0-20 (mod $400)
	movea.l	#Title3Sprites,a0
	movea.w	#(fofdata2-M68K_RAM),a1
	lea	TitleScrollTriggers(pc),a2
	moveq	#2,d7
	move.w	(menuspritechars).w,d3
	ori.w	#$8000,d3				;priority
.top	move.w	(a1)+,d0			;sprite d7 (2-0): d0 = its fofdata2 timer
	bmi.w	.chk
	subq.w	#1,-2(a1)
	moveq	#1,d2
	add.w	d7,d2
	mulu.w	#$B,d2
	lsr.w	#1,d0
	sub.w	d0,d2					;frame (sprite d7 + 1) * 11 - timer / 2
	move.w	#$80,d0
	move.w	#$80,d1
	bsr.w	SetSframe
	bra.w	.next
.chk	move.w	(Hscroll).w,d0		;timer stopped: test its Hscroll trigger
	addi.w	#$1EC,d0
	sub.w	(a2),d0
	andi.w	#$3FF,d0
	cmp.w	#$14,d0
	bhi.w	.next
	move.w	#$14,-2(a1)				;start this sprite
.next	addq.w	#2,a2				;next trigger entry and sprite
	dbf	d7,.top
	rts

TitleScrollTriggers					;Hscroll trigger points for the three TitleAnimCallback sprites
	dc.w	$B2,$DA,$6C
TitlePalettes						;four 16 color palettes for palfadenew+$20, one
									;picked at random by TitleScreen
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$4A4,$484,$262,$40
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$E44,$A44,$822,$400
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$44A,$228,6,4
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$AE,$8C,$6A,$48

UpdateHorizontalScroll				;title screen line scroll, called each vblank from VBlank_TitleScreen.
									;The top $AF lines scroll plane B by Hscroll, the last $31 lines and plane
									;A stay at 0. Hscroll moves by (asv += titlescrollspeed) >> 8; beyond +-8
									;the direction flips, else about 1 in 40 frames picks a new speed (-$32
									;to $32)
	move.w	#$DF,d0					;224 lines
	movea.w	#(SortCords-M68K_RAM),a0	;line scroll table
.loop	clr.l	(a0)+				;clear one line scroll entry (plane A and B words); d0 = lines left
	cmp.w	#$30,d0
	ble.w	.next
	move.w	(Hscroll).w,-2(a0)
.next	dbf	d0,.loop				;next line
	move.w	(titlescrollspeed).w,d0
	add.w	(asv).w,d0
	move.w	d0,(asv).w
	asr.w	#8,d0
	add.w	d0,(Hscroll).w
	cmp.w	#8,d0
	bgt.w	.rev
	cmp.w	#$FFF8,d0				;-8
	blt.w	.rev
	move.w	#$FA0,d0				;4000
	bsr.w	randomd0
	cmp.w	#$64,d0
	bhi.w	.x
	subi.w	#$32,d0
	move.w	d0,(titlescrollspeed).w
.rev	neg.w	(titlescrollspeed).w	;flip the scroll direction
.x	rts								;return

TitleScreen_wait					;wait for vblank, run TitleAnimCallback through CallAnimationCallback.wait
									;if start is pressed, return to TitleScreen's caller (pops the return
									;address). Called from TitleScreen
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(Vcount).w,d0
.0	cmp.w	(Vcount).w,d0			;spin until the vblank handler bumps Vcount
	beq.s	.0
	lea	TitleAnimCallback(pc),a0
	bsr.w	CallAnimationCallback
	bsr.w	orjoy
	btst	#sbut,d1				;sbut
	movem.l	(sp)+,d0-d7/a0-a6
	beq.w	rtss
	addq.w	#4,sp					;start: leave TitleScreen
	rts

VBlank_TitleScreen					;VBint handler for the title screen: line scroll and sprite table dma,
									;Vscroll, cramfade Vcount, UpdateHorizontalScroll and the music driver
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.x
	movea.w	#(SortCords-M68K_RAM),a0	;line scroll table
	move.w	(VSCRLPM).w,d1
	move.w	#$1C0,d0
	bsr.w	DoDMA
	movea.l	#Vdata,a0
	move.l	#VSRAM_W,4(a0)			;vsram write 0
	move.w	(Vscroll).w,(a0)
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.nos
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
.nos	bsr.w	cramfade			;palette fade step
.x	addq.w	#1,(Vcount).w			;frame counter
	bsr.w	UpdateHorizontalScroll
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

CallAnimationCallback				;build a sprite list with routine a0 (a6 = Satt, d6 = link counter), add
									;the logo sprites, then close the list. Called from PlayoffScreen and
									;TitleScreen_wait
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6					;link counter
	jsr	(a0)
	bsr.w	AddTitleLogoSprites
EndSpriteList						;end of the sprite list build: close the sprite list at a6 and set
									;Sattsize (in words).
									;Branched to from UpdateStanleyCupAnimation
	cmpa.w	#(Satt-M68K_RAM),a6
	bne.w	.n
	clr.l	(a6)+					;no sprites: one blank entry
	clr.l	(a6)+
.n	clr.b	satLink-satLen(a6)		;end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0
	move.w	d0,(Sattsize).w
	rts

AddTitleLogoSprites					;four Titlemap2 logo sprites at playoffspritex, playoffspritey.
									;logoslide counts down by 2 and the pieces drop into place from above,
									;each 64 later than the next.
									;Called from CallAnimationCallback
	subq.w	#2,(logoslide).w
	bpl.w	.0
	clr.w	(logoslide).w
.0	movea.l	#TitleLogoSprites,a0	;a0 = logo sprite data
	moveq	#3,d7
	move.w	(logochars).w,d3
	ori.w	#$8000,d3				;priority
.top	move.w	(playoffspritex).w,d0	;logo piece d7 (3-0): x = playoffspritex
	move.w	d7,d1
	asl.w	#6,d1
	sub.w	(logoslide).w,d1
	bmi.w	.1
	clr.w	d1						;in place
.1	add.w	(playoffspritey).w,d1	;y = piece drop offset + base y
	moveq	#4,d2
	sub.w	d7,d2					;frame 1-4
	bsr.w	SetSframe
	dbf	d7,.top
	rts

CheckSound							;sound test, no caller found. Runs only with start+a+c held on pad 1.
									;Prints "Check Sound"; right/left change the number, c plays it with sfx,
									;start leaves
	bsr.w	ReadJoy1
	cmp.b	#$E0,d3					;held: sbut, abut, cbut
	bne.w	rtss
	move	#$2500,sr
	move.l	#vb2,(VBint).w
	jsr	p_turnoff
	bsr.w	forceblack
	move.w	#$18,(palcount).w
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,3,$C,1,'Check Sound'	;attribute 4, map 3, x $C, y 1
	moveq	#$14,d6					;sound number
.top	move.w	(Vcount).w,d0		;sound test loop: wait for a frame
.wait	cmp.w	(Vcount).w,d0		;spin until Vcount changes
	beq.s	.wait
	bsr.w	ReadJoy1
	bsr.w	ProcessInputWithRepeat
	tst.b	d1
	beq.s	.top
	btst	#sbut,d1				;sbut
	bne.w	rtss
	btst	#rbut,d1				;rbut
	beq.w	.nor
	addq.w	#1,d6
.nor	btst	#lbut,d1			;lbut
	beq.w	.nol
	subq.w	#1,d6
.nol	btst	#cbut,d1			;cbut
	beq.w	.nob
	move.w	d6,-(sp)
	bsr.w	sfx
.nob	move.w	d6,d0				;print the sound number d6 at x $17
	moveq	#3,d1					;3 digits
	bsr.w	PushNumberWidth
	move.w	#$17,(printx).w
	bsr.w	print
	bra.s	.top

;	The game setup screen (setoptions) with the two team blocks and their animated roster players
;	(UpdateRosterPlayers ... AddTeamSpriteFrame), and its own vblank handler (VBlank_SetOptions).
;
;	printz strings: first byte c, with -c = $ab: map = b&3, printa = (-c<<9)&$F800; then x, y. $FF is map 1,
;	$FE map 2, $BF map 1 + priority, $BE map 2 + priority. Map 1 = VmMAP1 ($E000), map 2 = VmMAP2 ($C000).

setoptions							;options screen display and input. Called from PeriodOver.
									;6 minute demo timeout polling both pads, animated roster players in the
									;team blocks random teams after a demo, ends with bra MakeTree
	move	#$2500,sr				;(92 Rev A order)
	move.l	#VBlank_SetOptions,(VBint).l
	bclr	#dfok,(disflags).w
	bset	#dfng,(disflags).w
	bclr	#df32c,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$B400,(VSPRITES).w
	move.w	#$B800,(VmMAP3).w
	move.w	#5,(Map3col).w
	move.w	#$C000,(VmMAP2).w
	move.w	#6,(Map2col).w
	move.w	#$E000,(VmMAP1).w
	move.w	#6,(Map1col).w
	move.w	#0,d0					;fade to color
	bsr.w	setVram

	bsr.w	orjoy

	bsr.w	AddTeamBlock
	move.w	d4,(framercset).w		;framer tiles loaded here
	movea.l	#FramerMap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$01234562,$89ABCDEF		;remap table (Rev 0; / or.l)
	move.w	d4,(smallfontchars).w	;small font loaded here
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithRemap
	dc.l	$0FC04567,$89ABCDEF		;remap table (Rev 0; / or.l)

	bsr.w	printz
	String	$FF,0,0					;map 1 (92 -$02,0,0)
	moveq	#$28,d0					;40 x 28 (#$28,d0)
	moveq	#$1C,d1
	move.w	#$7FF,d2				;blank char (92 moveq #1)
	bsr.w	eraser

	bsr.w	printz
	String	$FE,0,0					;map 2 (92 -$01,0,0)
	movea.l	#GameSetUpMap,a0		;game setup bitmap
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2					;40 x 28
	moveq	#$1C,d3
	moveq	#$F,d5					;color fam 1-4 (92 %1101)
	bsr.w	dobitmap

	movea.l	#GameSetupSprites+8,a2	;roster player sprite tiles after the bitmap
	move.w	d4,(menuspritechars).w
	bsr.w	DecompressGraphicsPlain
	bsr.w	defaultsprites2
	move.w	#$28,(SortCords+rosxoff).w	;home player x offset 40 (off the block)
	move.w	#$28,(SortCords+(6*SCstruct)+rosxoff).w	;visitor player x offset 40
	st	(tmstruct).w				;team shown = $FFxx, so UpdateRosterPlayer starts a new team
	st	(awtmstruct).w

	movea.l	#.text,a1				;options static text
.textlp	bsr.w	print				;print each static text string until the empty one
	tst.b	2(a1)
	bne.s	.textlp

	tst.w	(demoflag).w
	bne.w	.keep					;demoflag clear (a demo ran): random teams
	moveq	#$1A,d0					;26 teams
	bsr.w	randomd0
	move.w	d0,(Opt1team).w
	moveq	#$1A,d0
	bsr.w	randomd0
	move.w	d0,(Opt2team).w
.keep	st	(demoflag).w			;demoflag = $FFFF: no demo running now
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.notree					;regular season or continue playoffs
	bsr.w	NewPO					;new playoffs
.notree	cmpi.w	#1,(OptPlayMode).w	;play mode 1 = continue playoffs
	bne.w	.nopo
	bsr.w	ContinuePlayoffs		;continue playoffs
.nopo	clr.w	d7					;menu line 0
	clr.w	d0
	bsr.w	.nms
	bsr.w	.ps
	move.w	#$18,(palcount).w		;24
	bclr	#dfng,(disflags).w		;fade in graphics now
;----------
.top	move.l	#$5460,d6			;21600 frames (6 minutes) before the demo (92 40*60)
.wait	move.w	(Vcount).w,d1		;d1 = frames since the last pass
	sub.w	(OldVcount).w,d1
	beq.s	.wait					;wait for the next vblank
	move.w	(Vcount).w,(OldVcount).w
	bsr.w	UpdateRosterPlayers
	bsr.w	ReadJoy1
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.nd						;pad 1 pressed
	bsr.w	ReadJoy2
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.nd						;pad 2 pressed
	dbf	d6,.wait

	clr.w	(demoflag).w			;not a demo now
	move.w	(HVcount).l,(seed).w	;92 used HVcount
	move.w	(HVcount).l,(seed+2).w
	clr.w	(OptPlayMode).w			;regular season
	clr.w	(OptNOP).w
	clr.w	(OptLine).w				;line changes on
	move.w	#1,(OptPen).w			;penalties "On"
.ex	bsr.w	UpdatePlayoffLevel		;leave the menu: playoff level, fresh seed, then MakeTree
	move.w	(HVcount).l,(seed).w	;random seed hopefully
	move.w	(HVcount).l,(seed+2).w
	bra.w	MakeTree

.nd	btst	#sbut,d1				;sbut
	bne.s	.ex
	btst	#dbut,d1				;dbut
	beq.w	.2
	moveq	#2,d0
	bsr.w	.nms					;new menu line selected
	bsr.w	.ps						;print screen
	bra.w	.top

.2	btst	#ubut,d1				;ubut
	beq.w	.3
	moveq	#-2,d0
	bsr.w	.nms					;new menu line
	bsr.w	.ps						;print screen
	bra.w	.top

.3	moveq	#1,d2					;left/right pressed: d2 = +1 or -1
	btst	#rbut,d1				;rbut
	bne.w	.4
	btst	#lbut,d1				;lbut
	beq.w	.top
	moveq	#-1,d2
.4	bsr.w	.IncItem				;change item
	bsr.w	.ps						;print screen
	bra.w	.top

.IncItem							;add d2 to current item d7 (d2 = 0: just limit it)
	movea.w	#(OptPlayMode-M68K_RAM),a2
	movea.l	#.pslim,a3
	clr.w	d5						;low limit
	move.w	(a3,d7.w),d4			;limit
	move.w	(a2,d7.w),d3			;current value
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.ii0
	cmp.w	#4,d7					;team 1 in new playoffs
	bne.w	.ii0
	moveq	#$18,d4					;24
.ii0	cmp.w	#2,d7				;players
	bne.w	.ii1
	moveq	#5,d5					;playoffs: player choices 5-7
	tst.w	(OptPlayMode).w
	bne.w	.ii1
	clr.w	d5						;regular season: player choices 0-4
	moveq	#5,d4
.ii1	bsr.w	.iilimit			;step d3 by d2 and wrap into d5 ... d4-1
	move.w	d3,(a2,d7.w)
	tst.w	d2
	beq.w	rtss
	cmpi.w	#1,(OptPlayMode).w
	bne.w	.npo
	tst.w	d7
	bne.w	.npo
	bsr.w	ContinuePlayoffs		;play mode moved onto continue playoffs
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.s	.ii1					;nothing to continue: step past it
	rts

.npo	cmpi.w	#2,(OptPlayMode).w	;new playoffs modes: rebuild the tree when mode or team 1 changed
	blt.w	rtss
	tst.w	d7
	beq.w	NewPO					;new playoffs: play mode or team 1 changed
	cmp.w	#4,d7
	beq.w	NewPO
	rts

.iilimit							;d3 + d2, wrapped into d5 ... d4-1
	add.w	d2,d3
	cmp.w	d5,d3
	bge.w	.iil1
	move.w	d4,d3
	subq.w	#1,d3
.iil1	cmp.w	d4,d3				;at or past the high limit: wrap to the low limit
	blt.w	rtss
	move.w	d5,d3
	rts

.ps									;print choices and show team icons/colors
	move.w	d7,d6
	moveq	#-2,d7
.pstop	addq.w	#2,d7				;next menu line (word index)
	clr.w	d2
	bsr.w	.IncItem
	bsr.w	.psd
	cmp.w	#$C,d7					;last menu item (word index)
	bne.s	.pstop
	move.w	d6,d7
	bra.w	TeamIcons

.psd								;print the choice for menu line d7
	bsr.w	printz
	String	$BE,$11,$D				;map 2 + priority (92 -$01,16,11)
	add.w	d7,(printy).w			;row $D + d7 (2 rows per item)
	moveq	#$14,d0					;erase 20 x 1
	moveq	#1,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	subq.w	#1,(printy).w			;eraser moved down a line
	move.w	#$11,(printx).w			;(92 16)
	cmp.w	#4,d7					;team 1
	beq.w	.psdtp
	cmp.w	#6,d7					;team 2
	beq.w	.psdtp
	movea.l	#OptPlayMode,a0
	move.w	(a0,d7.w),d3
	movea.l	#.pl,a0
	adda.w	(a0,d7.w),a0
.psd3	movea.l	a0,a1				;step to string d3
	adda.w	(a0),a0
	dbf	d3,.psd3
	bra.w	print

.psdtp	movea.l	#OptPlayMode,a1		;team line: print the team name from the team address table
	move.w	(a1,d7.w),d3
	movea.w	#TeamList,a1			;team address table
	asl.w	#2,d3
	movea.l	(a1,d3.w),a1
	lsr.w	#2,d3
	adda.w	Teamname(a1),a1
	bra.w	print

.nms								;next menu by d0
	move.w	d7,d3
.nms0	add.w	d0,d7				;step the line by d0, clamped to 0 ... $C
	bpl.w	.nms1
	clr.w	d7
.nms1	cmp.w	#$E,d7				;*2
	blt.w	.nms2
	sub.w	d0,d7
.nms2	cmpi.w	#1,(OptPlayMode).w	;continue playoffs: only line 0 and the lines below team 2
	bne.w	.nms3
	tst.w	d7
	beq.w	.nms3
	cmp.w	#6,d7					;continue playoffs: skip lines 1-3
	bls.s	.nms0
.nms3	cmpi.w	#2,(OptPlayMode).w	;new playoffs: team 2 line is skipped
	blt.w	.nms4
	cmp.w	#6,d7					;new playoffs: skip team 2
	beq.s	.nms0
.nms4	bsr.w	.setrect			;erase the old frame
	move.w	#$7FF,d2				;(92 moveq #1)
	bsr.w	eraser
	move.w	d7,d3
	bsr.w	.setrect
	bra.w	Framer

.setrect							;set rectangle cords for framing line d3
	bsr.w	printz
	String	$FF,$10,$C				;map 1
	add.w	d3,(printy).w			;(/ cmp.b hid this and the moveq)
	moveq	#$16,d0					;22 x 3 (92 24)
	moveq	#3,d1
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtss
	cmp.w	#4,d3					;team 1 in new playoffs
	bne.w	rtss
	moveq	#5,d1					;taller frame
	rts

;limit of each item
	dc.w	0
.pslim	dc.w	4,8,$1A,$1A,3,3,2	;92 used $1A

;menu item names
.pl	dc.w	.pl0-.pl				;offsets to the string list of each menu line
	dc.w	.pl1-.pl
	dc.w	.pl2-.pl
	dc.w	.pl3-.pl
	dc.w	.pl4-.pl
	dc.w	.pl5-.pl
	dc.w	.pl6-.pl

.pl0	String	'Regular Season'	;play mode
	String	'Continue Playoffs'
	String	'New Playoffs'
	String	'New Playoffs/7 game'

.pl1	String	'Demo'				;players
	String	'One - Home'
	String	'One - Visitor'
	String	'Two - Teammates'
	String	'Two - Head to Head'

	String	'Two - Head to Head'
	String	'Two - Teammates'
	String	'One'
.pl2								;team 1 line (name comes from the team table, shares the next list)
.pl3								;team 2 line (same)
.pl4	String	'5 Minutes'			;period length
	String	'10 Minutes'
	String	'20 Minutes'
	String	'30 Seconds'

.pl5	String	'Off, Except fighting'	;penalties
	String	'On'
	String	'On, Except Off-sides'
.pl6	String	'On'				;line changes
	String	'Off'

.text								;static text
	String	$FE,3,$D,'Play Mode'	;(92 -$01,2,11)
	String	$FE,3,$F,'Players'
	String	$FE,3,$11,'Team 1'
	String	$FE,3,$13,'Team 2'
	String	$FE,3,$15,'Per. Length'
	String	$FE,3,$17,'Penalties'
	String	$FE,3,$19,'Line Changes'
	dc.w	4,0						;empty string

UpdatePlayoffLevel					;in new playoffs set playoffroundoffset = 7 - playofflevel.
									;Called from setoptions .ex
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtss
	moveq	#7,d0
	sub.w	(OptNOP).w,d0
	move.w	d0,(pojoy).w
	rts

TeamIcons							;draw team name bars and set colors. Branched to from setoptions.ps.
									;no continue playoffs exit and no setplayercolors (SetupNextPlayer loads
									;the palettes)
	movem.l	d0-d7/a0-a2,-(sp)
	tst.w	(OptPlayMode).w
	bne.w	.0
	move.w	(Opt1team).w,(HomeTeam).w
	move.w	(Opt2team).w,(VisTeam).w
.0	bsr.w	printz					;TeamIcons: draw the visitor bar, then the home bar
	String	$BE,2,1					;map 2 + priority (92 -$02,3,8)
	move.w	(VisTeam).w,d1
	bsr.w	dotb
	bsr.w	printz
	String	$BE,$1A,1				;(92 -$02,24,8)
	move.w	(HomeTeam).w,d1
	bsr.w	dotb
	bsr.w	setteams
	move.w	#$18,(palcount).w		;24
	movem.l	(sp)+,d0-d7/a0-a2
	rts

dotb								;draw team name bar d1 = team number at printx/printy.
									;Called from TeamIcons and
									;ScoutingReport
	clr.w	d0
	asl.w	#1,d1
	movea.l	#TeamBlocksmap,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	jimdata(a1),a1
	movea.w	#null,a2				;tile data: word 0 at null = no tiles
	move.w	(a1),d2					;width from the map header (92 13)
	moveq	#2,d3
	moveq	#2,d4					;(92 $8002)
	moveq	#2,d5					;color fam 2
	bra.w	dobitmap

ClearRosterName						;erase the 12 x 2 player name area of team a2. Called from
									;SlideOutRosterPlayer
	bsr.w	setoptions_printpos2
	moveq	#$C,d0
	moveq	#2,d1
	move.w	#$7FF,d2
	bra.w	eraser

setoptions_printpos2				;set the print position of team a2's player name: x 2 (visitor) or x $1A
									;(home), y $A map 1 + priority. Called from ClearRosterName and
									;UpdateRosterPlayer
	bsr.w	printz
	String	$BF,2,$A
	cmpa.w	#(tmstruct-M68K_RAM),a2	;(/ mulu.w)
	bne.w	rtss
	move.w	#$1A,(printx).w			;home team on the right
	rts

PickStartingGoalie					;pick the goalie shown for team a2 on a change: tmgoalie(a2) = weighted
									;random roster index from the 4 nibbles in the team data
									;(UnpackNibbles / WeightedRandomSelect). $26 stays 0 when a pad controls
									;the team, gamelevel > 2 or OptLine is set. Called from UpdateRosterPlayer
	movem.l	d0/a0,-(sp)
	clr.w	tmgoalie(a2)
	bsr.w	FigureJoy				;sets cont1team / cont2team
	cmpa.w	#(tmstruct-M68K_RAM),a2
	seq	d0
	ext.w	d0
	addq.w	#2,d0					;home 1, visitor 2
	cmp.w	(cont1team).w,d0
	beq.w	.x						;pad 1 on this team
	cmp.w	(cont2team).w,d0
	beq.w	.x						;pad 2 on this team
	moveq	#0,d0
	cmpi.w	#2,(gamelevel).w
	bgt.w	.set
	tst.w	(OptLine).w
	bne.w	.set					;line changes off
	movea.w	#TeamList,a0			;team address table
	move.w	(a2),d0					;team shown
	asl.w	#2,d0
	movea.l	(a0,d0.w),a0
	adda.w	GoalieOdds(a0),a0		;starting goalie weights (GoalieOdds)
	moveq	#4,d0
	bsr.w	UnpackNibbles
	bsr.w	WeightedRandomSelect	;d0 = index 0-3
.set	move.w	d0,tmgoalie(a2)		;store the pick (0 = first goalie)
.x	movem.l	(sp)+,d0/a0				;restore registers
	rts

UpdateRosterPlayers					;run the roster player in both team blocks and build their sprite list.
									;Called once per frame from setoptions .wait
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#1,d7
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	UpdateRosterPlayer
	adda.w	#tmsize,a2				;awtmstruct
	bsr.w	UpdateRosterPlayer
	bsr.w	UpdateTeamSprites
	movem.l	(sp)+,d0-d7/a0-a6
	rts

UpdateRosterPlayer					;roster player of team a2 (sprite struct a3 = tmsort(a2)). When the
									;team (tmteam, set by setteams) differs from the one shown ((a2)), start
									;over. tmfslide of tmflags(a2) set: slide the player out 3 per frame, then
									;SetupNextPlayer. Else slide in 1 per frame, run updateanim, and when the
									;animation is done step the RosterAnimScripts script (8(a2) = script,
									;tmrosstep(a2) = offset). A negative direction also prints the player's
									;number and name. Called from UpdateRosterPlayers
	move.w	tmteam(a2),d0
	cmp.w	(a2),d0
	beq.w	.same
	move.w	d0,(a2)					;new team
	bsr.w	PickStartingGoalie
	clr.w	2(a2)					;first RosterOrderTable entry
	bsr.w	SlideOutRosterPlayer
.same	movea.w	tmsort(a2),a3		;a3 = roster player sprite struct
	btst	#tmfslide,tmflags(a2)
	beq.w	.in
	addq.w	#3,rosslide(a3)			;sliding out
	addq.w	#3,rosxoff(a3)			;x offset
	cmpi.w	#$28,rosxoff(a3)
	bgt.w	SetupNextPlayer			;past 40: next player
	rts

.in	tst.w	rosxoff(a3)				;not sliding out: slide in while the x offset is negative
	bpl.w	.anim
	addq.w	#1,rosslide(a3)			;sliding in from -40
	addq.w	#1,rosxoff(a3)
.anim	jsr	(updateanim).l			;advance the player animation
	btst	#pf2aip,pflags2(a3)
	bne.w	rtss					;animation still running
	move.w	8(a2),d0				;script number
	add.w	d0,d0
	movea.l	#RosterAnimScripts,a0
	adda.w	(a0,d0.w),a0
	adda.w	tmrosstep(a2),a0
	addq.w	#4,tmrosstep(a2)		;next step
	move.w	(a0),d1					;animation
	beq.w	SlideOutRosterPlayer	;end of script: slide out
	bsr.w	SetSPA
	bset	#pf2aip,pflags2(a3)
	move.w	2(a0),facedir(a3)		;facing direction (read by updateanim)
	bpl.w	rtss
	neg.w	facedir(a3)				;negative direction: also show the name

	move.w	4(a2),d0				;roster index
	bsr.w	GetRosterEntry
	bsr.w	setoptions_printpos2
	movea.w	#(mesarea-M68K_RAM),a3
	lea	2(a3),a1
	move.w	#6,(a3)					;string length: 2 digits and a space
	move.l	a0,-(sp)
	adda.w	(a0),a0
	move.b	(a0),d0					;player number (BCD)
	bsr.w	ConvertByteToDigits
	move.w	#$2000,4(a3)			;space, end
	movea.l	(sp)+,a1
	bsr.w	appstring				;"NN " + name
	movea.w	a3,a0
	adda.w	(a0),a0
.trim	cmpi.b	#$20,-(a0)			;find the last space
	bne.s	.trim
	clr.b	(a0)					;line 1 = number and first name
	move.w	a0,d0
	sub.w	a3,d0
	btst	#0,d0
	beq.w	.even
	addq.w	#1,a0					;keep the last name word aligned
	addq.w	#1,d0
.even	move.w	(a3),d1				;d1 = length left for the last name
	sub.w	d0,d1
	addq.w	#2,d1					;length of the last name string
	move.w	d0,(a3)
	movea.w	a3,a1
	move.w	(printx).w,-(sp)
	lsr.w	#1,d0
	subq.w	#7,d0
	sub.w	d0,(printx).w			;center in 14 columns
	bsr.w	print
	move.w	d1,-(a0)				;length word in front of the last name
	tst.b	strtext(a0)
	bne.w	.ln2
	subq.w	#1,d1					;starts with the pad byte
.ln2	movea.w	a0,a1				;a1 = last name string, center it too
	lsr.w	#1,d1
	neg.w	d1
	addq.w	#7,d1
	add.w	(sp)+,d1
	move.w	d1,(printx).w			;center in 14 columns
	addq.w	#1,(printy).w
	bra.w	print					;line 2 = last name

SlideOutRosterPlayer				;erase the name of team a2 and set tmfslide in
									;tmflags(a2) (tmfslide: slide the player out).
									;Called and branched to from UpdateRosterPlayer
	bsr.w	ClearRosterName
	bset	#tmfslide,tmflags(a2)
	rts

SetupNextPlayer						;player of team a2 slid out. Load the team palette (setplayercolors.sp),
									;put the sprite at x offset -40, take the next RosterOrderTable slot
									;(goalie slot: tmgoalie(a2)), set the sprite flag from the player and pick
									;his animation script from the ratings. Branched to from
									;UpdateRosterPlayer
	movea.l	tmdata(a2),a0
	adda.w	Palettedata(a0),a0		;palettes
	movea.w	#(palfadenew+$40-M68K_RAM),a1
	moveq	#7,d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.pal
	adda.w	#$20,a0					;visitor: second palette
	adda.w	#$20,a1
.pal	move.l	(a0)+,(a1)+			;copy 8 longs = 16 colors of the team palette
	dbf	d0,.pal
	move.w	#$18,(palcount).w		;24
	bclr	#tmfslide,tmflags(a2)
	movea.w	tmsort(a2),a3
	move.w	#$FFD8,rosxoff(a3)		;x offset -40
	clr.w	SPA(a3)
.next	move.w	2(a2),d0			;next RosterOrderTable index
	lea	RosterOrderTable(pc),a0
	move.b	(a0,d0.w),d0
	bpl.w	.got
	clr.w	2(a2)					;end of list: start again
	bra.s	.next

.got	move.w	d0,6(a2)			;line slot
	addq.w	#1,2(a2)
	lea	tmlines(a2),a0				;line data
	move.b	(a0,d0.w),d0
	subq.w	#1,d0					;roster index
	tst.w	6(a2)
	bne.w	.pn
	move.w	tmgoalie(a2),d0			;slot 0 (goalie): PickStartingGoalie's pick
.pn	move.w	d0,4(a2)				;4(a2) = roster index shown
	bsr.w	GetRosterEntry
	adda.w	(a0),a0					;past the name
	bclr	#3,attribute(a3)
	btst	#0,4(a0)
	bne.w	.r
	bset	#3,attribute(a3)		;bit 0 of player byte 4 clear
.r	addq.w	#1,a0					;rating bytes
	moveq	#6,d0					;7 bytes, 14 nibbles
	clr.w	d2						;best rating
	movea.l	#SkaterRosterAnims,a1
	move.w	6(a2),d3
	andi.w	#7,d3
	bne.w	.nib
	movea.l	#GoalieRosterAnims,a1	;goalie slot
.nib	move.b	(a0),d1				;rating byte: high nibble, then low nibble
	lsr.b	#4,d1
	bsr.w	PickRosterAnim
	move.b	(a0)+,d1
	andi.b	#$F,d1
	bsr.w	PickRosterAnim
	dbf	d0,.nib
	clr.w	tmrosstep(a2)			;start of the script
	rts

PickRosterAnim						;rating d1 against the next (minimum, script) pair at a1. If d1 >= minimum
									;and >= best d2 (and the minimum is not 0 once d2 is set), d2 = d1 and
									;8(a2) = script. Called from SetupNextPlayer
	addq.w	#2,a1
	cmp.b	-2(a1),d1
	blt.w	rtss					;below the minimum
	cmp.b	d2,d1
	blt.w	rtss					;below the best so far
	tst.w	d2
	beq.w	.set
	tst.b	-2(a1)
	beq.w	rtss
.set	move.b	d1,d2				;new best rating d2; script number = low byte of the pair
	clr.w	8(a2)
	move.b	-1(a1),9(a2)
	rts

GetRosterEntry						;a0 = roster entry d0 of team a2 (name string, then 8 bytes: number and
									;ratings).
									;Called from UpdateRosterPlayer and SetupNextPlayer
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0					;player data
	bra.w	.cnt
.next	adda.w	(a0),a0				;skip the name
	addq.w	#pldsize,a0
.cnt	dbf	d0,.next				;d0 entries to skip
	rts

SkaterRosterAnims					;skater (minimum rating, animation script) per rating nibble, used by
									;SetupNextPlayer
	dc.b	0,1,$B,2,0,1,0,1,$B,6,$B,3,0,1,$B,7,$B,4,0,1,0,1,0,1,0,1,0,1
GoalieRosterAnims					;goalie (minimum rating, animation script) per rating nibble
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,$B,5,$B,5
RosterAnimScripts					;roster player animation scripts 0-7 (offsets), each (SetSPA animation,
									;facing direction) pairs ending in 0.
									;A negative direction also prints the name. Used by UpdateRosterPlayer
	dc.w	.s0-RosterAnimScripts,.s1-RosterAnimScripts,.s2-RosterAnimScripts
	dc.w	.s3-RosterAnimScripts,.s4-RosterAnimScripts,.s5-RosterAnimScripts
	dc.w	.s6-RosterAnimScripts,.s7-RosterAnimScripts
.s0	dc.w	SPAgready2,3,SPAgready2,4,SPAgready2,5,SPAgready2,-4	;goalie script
	dc.w	SPAgglover,4,SPAgready2,4,SPAgglovel,4,SPAgready2,4,0
.s5	dc.w	SPAgready2,3,SPAgready2,4,SPAgready2,5,SPAgready2,-4	;goalie script (other glove)
	dc.w	SPAgglovel2,4,SPAgready2,4,SPAgready2,4,0
.s1	dc.w	SPAskate,3,SPAskate,4,SPAcelebrate,-5,SPAcelebrate,4,SPAglide,4,SPAglide,4,0	;skater celebrate
.s2	dc.w	SPAskatewp,4,SPAskatewp,4,SPAfake,-4,SPAglide,4,SPAglide,4,0	;skater fake
.s3	dc.w	SPAskatewp,5,SPAskatewp,5,SPAshotf,-5,SPAglide,5,SPAglide,5,0	;skater shot
.s4	dc.w	SPAskatewp,3,SPAskatewp,3,SPAstumble,-3,SPAshotf,3,SPAglide,3,SPAglide,3,0	;skater stumble, shot
.s6	dc.w	SPAskate,4,SPAskate,5,SPAsweepchk,-5,SPAsweepchk,5	;skater sweep check
	dc.w	SPAskate,5,SPAsweepchk,5,SPAglide,5,SPAglide,5,0
.s7	dc.w	SPAskate,3,SPAskate,2,SPAfight,-2,SPAfhigh,2,SPAflow,2,SPAfhigh,2,SPAflow,2,0	;skater fight
RosterOrderTable					;line data slots shown in turn: C, RW, LW, G, RD, LD of line 1, then lines
									;2 and 3; $FF ends
	dc.b	4,5,3,0,2,1,$C,$D,$B,$A,9,$14,$15,$13,$12,$11,$FF,PadByte

UpdateTeamSprites					;sprite list for the two roster players. a5 = DMAList, a6 = Satt.
									;Sets dfok for VBlank_SetOptions. Called from UpdateRosterPlayers
	movea.w	#(DMAList-M68K_RAM),a5
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6					;link counter
	movea.w	#(SortCords-M68K_RAM),a3	;home player
	bsr.w	AddTeamSpriteFrame
	adda.w	#6*SCstruct,a3			;visitor player
	bsr.w	AddTeamSpriteFrame
	cmpa.w	#(Satt-M68K_RAM),a6
	bne.w	.n
	clr.l	(a6)+					;no sprites: one blank entry
	clr.l	(a6)+
.n	clr.b	satLink-satLen(a6)		;end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0
	move.w	d0,(Sattsize).w
	move.l	a5,(DMAlistend).w
	bset	#dfok,(disflags).w
	rts

AddTeamSpriteFrame					;add player a3 (x = Xpos + rosxoff, y = Ypos) and a GameSetupMap frame 1
									;sprite at y $80, x $80 + ($24/2 mod 48), +$C0 when pflags(a3) bit 6 is
									;clear. Called from UpdateTeamSprites
	move.w	(a3),d0
	add.w	rosxoff(a3),d0
	move.w	Ypos(a3),d1
	bsr.w	addframe2
	movea.l	#GameSetupSprites,a0
	clr.l	d0
	move.w	rosslide(a3),d0
	lsr.w	#1,d0
	divu.w	#$30,d0
	swap	d0						;remainder
	addi.w	#$80,d0
	btst	#pfteam,pflags(a3)
	bne.w	.x
	addi.w	#$C0,d0
.x	move.w	#$80,d1					;sprite y
	moveq	#1,d2					;frame
	move.w	(menuspritechars).w,d3
	bra.w	SetSframe

VBlank_SetOptions					;VBint handler stored by setoptions: cramfade unless dfng, plus
									;DumpSprites2 when dfok is set
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	bclr	#dfok,(disflags).w
	beq.w	.fade
	bsr.w	DumpSprites2
.fade	bsr.w	cramfade			;palette fade step
.nograph	addq.w	#1,(Vcount).w	;frame counter
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;======================================================================
;======================================================================
;	DefaultMenus, NewPO, MakeTree, FigureJoy and the playoff password code (ReadPassBits ... SuperDiv,
;	GetShifter), then the playoff stat packing (AddPlayoffTeamStats, ReadTeamStats).
;
;	The password bits are kept in a 5 word buffer at a3 and there is no password checksum (92 had one). The
;	buffers are passbits, tpassbits and outputbuffer (Rev 0 addresses are 4 bytes lower than Rev A).
;
;	playoffroundoffset reuses the old playoff joystick word and playofflevel reuses the old number-of-players
;	option slot.

DefaultMenus						;set default menu choices for beginning of game. Called once from Begin
									;(jsr abs.l).
	st	(demoflag).w				;no demo has run yet
	movea.l	#OptPlayMode,a0
	movea.l	#.defom,a1
	move.w	#6,d0					;7 words
.1	move.w	(a1)+,(a0)+				;7 words of default menu values
	dbf	d0,.1
	rts
.defom	dc.w	0,1,$F,3,1,0,1		;play mode, players, team 1, team 2, period length penalties, line changes
									;(92 0,1,14,8,1,0,1)

ContinuePlayoffs					;continue playoffs: read the playoff state back from the password bits,
									;rebuild the tree.
									;Called from setoptions when play mode becomes "continue playoffs".
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(passbits-M68K_RAM),a3	;password bits
	bsr.w	ReadPassBits
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.w	.ex						;level 0, game 0: nothing played yet
	bsr.w	MakeTree
	moveq	#7,d0
	sub.w	(pojoy).w,d0
	move.w	d0,(OptNOP).w			;menu value from pojoy
.ex	movem.l	(sp)+,d0-d7/a0-a3		;restore registers
	rts

NewPO								;new playoff generates tree with same team 1.
									;Called from setoptions for "new playoffs". Falls into MakeTree.
	moveq	#$20,d0					;32 trees
	bsr.w	randomd0
.top	addq.w	#1,d0				;next tree number (wraps at 32)
	andi.w	#$1F,d0
	asl.w	#4,d0					;16 teams per tree
	movea.l	#playoffseats,a0
	adda.w	d0,a0
	lsr.w	#4,d0
	moveq	#$F,d1
	move.w	(Opt1team).w,d2
	cmp.w	#$17,d2					;-3: all-star teams use team 23
	bls.w	.loop
	moveq	#$17,d2
.loop	cmp.b	(a0)+,d2			;find team 1 in this tree
	dbeq	d1,.loop
	bne.s	.top					;not in this tree, try the next one
	eori.w	#$F,d1
	move.w	d1,(potreeteam).w
	move.w	d0,(postarts).w
	clr.w	(gamelevel).w
	move.w	#7,(bosgames).w			;not best of seven
	cmpi.w	#2,(OptPlayMode).w
	beq.w	MakeTree				;2 = playoffs (single games)
	clr.w	(bosgames).w			;best of seven: game 0
	moveq	#7,d0					;clr games won
	movea.w	#(gstruct-M68K_RAM),a0
.cg	clr.w	gspotwins(a0)			;clear the series wins of game d0
	clr.w	gspobwins(a0)
	adda.w	#gssize,a0
	dbf	d0,.cg
;	falls into MakeTree

MakeTree							;make playoff tree from playoffseats/winbits.
									;Called from setoptions (bra), NewPO, EncodePW; falls in from
									;SelectRandomPlayoffTree.
	movem.l	d0-d4/a0-a3,-(sp)
	move.w	(postarts).w,d1
	asl.w	#4,d1
	movea.w	#(potree-M68K_RAM),a0
	movea.l	#playoffseats,a1
	adda.w	d1,a1
	move.l	(a1),(a0)				;first round: 16 teams from the tree
	move.l	4(a1),4(a0)
	move.l	8(a1),8(a0)
	move.l	$C(a1),$C(a0)
	lea	$10(a0),a1
	moveq	#$E,d2					;15 winners
	move.w	(WinBits).w,d0
.0	move.w	d0,d1					;d1 = lowest WinBits bit: pick the pair member
	andi.w	#1,d1					;winbit picks the top or bottom team of the pair
	move.b	0(a0,d1.w),(a1)+
	addq.w	#2,a0
	lsr.w	#1,d0
	dbf	d2,.0

	bsr.w	GetShifter
	tst.w	d1
	bmi.w	.nogames				;playoffs over
	movea.w	#(potree-M68K_RAM),a0
	adda.w	d2,a0
	adda.w	d2,a0
	movea.w	#(gstruct-M68K_RAM),a1
.2	clr.w	gss1(a1)				;reset game d1 of the round: scores, period, highlight
	clr.w	gss2(a1)
	clr.w	gsper(a1)
	bclr	#gsfhl,gsflags(a1)		;hilite requested
	bsr.w	.sett
	adda.w	#gssize,a1
	dbf	d1,.2
	bsr.w	FigureJoy
.nogames	movem.l	(sp)+,d0-d4/a0-a3	;restore registers
	rts

.sett	cmpi.w	#2,(bosgames).w		;series games 2, 3, 5: tree order, others swapped
	beq.w	.flip
	cmpi.w	#3,(bosgames).w
	beq.w	.flip
	cmpi.w	#5,(bosgames).w
	beq.w	.flip
	bset	#gsftf,gsflags(a1)		;teams are flipped
	move.b	(a0)+,gst2+1(a1)
	move.b	(a0)+,gst1+1(a1)
	rts
.flip	bclr	#gsftf,gsflags(a1)	;gsftf
	move.b	(a0)+,gst1+1(a1)
	move.b	(a0)+,gst2+1(a1)
	rts

FigureJoy							;set cont1team/cont2team appropriately. Called from MakeTree and
									;PickStartingGoalie.
									;after a demo (demoflag clear) fills gstruct with random matchups
									;(InitializeGameStructures)
	movem.l	d0-d3/a0-a1,-(sp)
	clr.w	(cont1team).w
	clr.w	(cont2team).w
	tst.w	(demoflag).w
	beq.w	.init					;demo ran
	tst.w	(OptPlayMode).w
	beq.w	.fjnpo					;regular season
	bsr.w	GetShifter
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2			;po team
	movea.w	#(gstruct-M68K_RAM),a1
	moveq	#gssize,d4
	mulu.w	d1,d4
	adda.w	d4,a1
	st	(gamenum).w
	clr.w	d0
.f0	cmp.w	(a1),d2					;gst1
	beq.w	.it1
	cmp.w	gst2(a1),d2
	beq.w	.it2
	suba.w	#gssize,a1
	dbf	d1,.f0
	bra.w	.ex						;po team not in playoffs

.it2	moveq	#4,d0				;po team is gst2: pojoy list row 2
	move.w	(a1),(Opt2team).w		;gst1
	move.w	gst2(a1),(Opt1team).w	;also set team 1
	bra.w	.itx
.it1	clr.w	d0					;po team is gst1: pojoy list row 1
	move.w	gst2(a1),(Opt2team).w
	move.w	(a1),(Opt1team).w
.itx	add.w	(pojoy).w,d0		;d0 = list row + pojoy, pads for this game
	move.w	d1,(gamenum).w
	move.w	(a1),(HomeTeam).w		;gst1
	move.w	gst2(a1),(VisTeam).w
	asl.w	#2,d0
	lea	.pojoylist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
	bra.w	.ex

.pojoylist	dc.w	1,0				;pojoy 0-3 with the po team as team 1
	dc.w	1,1
	dc.w	1,2
	dc.w	2,1

	dc.w	2,0						;pojoy 0-3 with the po team as team 2
	dc.w	2,2
	dc.w	2,1
	dc.w	1,2

.fjnpo	move.w	(OptNOP).w,d0		;regular season: pads from .noplist[OptNOP]
	asl.w	#2,d0
	lea	.noplist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
.init	bsr.w	InitializeGameStructures	;random matchups for the other games
.ex	movem.l	(sp)+,d0-d3/a0-a1		;restore registers
	rts

.noplist							;cont1team, cont2team per OptNOP 0-4
	dc.w	0,0
	dc.w	1,0
	dc.w	2,0
	dc.w	1,1
	dc.w	1,2

InitializeGameStructures			;random team pairs for all 8 gstruct games, none of them HomeTeam or
									;VisTeam. Called from FigureJoy (also after the regular season pad
									;set-up).
	st	(gamenum).w
	clr.l	d3						;d3 = used team bits
	move.w	(HomeTeam).w,d1
	bset	d1,d3
	move.w	(VisTeam).w,d1
	bset	d1,d3
	movea.w	#(gstruct-M68K_RAM),a1
	moveq	#7,d2
.loop	bsr.w	GetRandomUnusedTeam	;both teams of game d2
	move.w	d0,(a1)					;gst1
	bsr.w	GetRandomUnusedTeam
	move.w	d0,gst2(a1)
	adda.w	#gssize,a1
	dbf	d2,.loop
	rts

GetRandomUnusedTeam					;return d0 = random team 0-23 not yet set in d3, and set its bit.
	moveq	#$18,d0					;24 teams
	bsr.w	randomd0
	bset	d0,d3
	bne.s	GetRandomUnusedTeam		;already used, pick again
	rts

ReadPassBits						;translate the password bits at a3 (5 words) to the playoff variables.
									;Called from NewPO and EncodePW. a3 = bits buffer, kept: the 5 words are
									;saved and restored.
									;no password checksum (92 checked one)
	moveq	#4,d0
	lea	5*2(a3),a0
.save	move.w	-(a0),-(sp)			;SuperDiv destroys the bits
	dbf	d0,.save
	moveq	#7,d2					;set gspobwins/gspotwins
	movea.w	#(gstruct+(7*gssize)-M68K_RAM),a1
.0	bclr	#gsfso,gsflags(a1)		;series over
	moveq	#5,d0
	bsr.w	SuperDiv
	move.w	d0,gspobwins(a1)
	cmp.w	#4,d0
	bne.w	.nsf0
	bset	#gsfso,gsflags(a1)		;4 wins: gsfso
.nsf0	moveq	#5,d0				;second variable: gspotwins
	bsr.w	SuperDiv
	move.w	d0,gspotwins(a1)
	cmp.w	#4,d0
	bne.w	.nsf1
	bset	#gsfso,gsflags(a1)		;gsfso
.nsf1	suba.w	#gssize,a1			;previous game struct
	dbf	d2,.0

	move.w	#$4000,d0				;set winbits (92 1<<14)
	bsr.w	SuperDiv
	move.w	d0,(WinBits).w

	moveq	#4,d0					;set POJoy
	bsr.w	SuperDiv
	move.w	d0,(pojoy).w

	moveq	#$10,d0					;set POTreeTeam
	bsr.w	SuperDiv
	move.w	d0,(potreeteam).w

	moveq	#4,d0					;set gamelevel
	bsr.w	SuperDiv
	move.w	d0,(gamelevel).w

	moveq	#8,d0					;set bosgames
	bsr.w	SuperDiv
	move.w	d0,(bosgames).w

	moveq	#$20,d0					;set PoStarts
	bsr.w	SuperDiv
	move.w	d0,(postarts).w
	moveq	#4,d0
	lea	(a3),a0
.restore	move.w	(sp)+,(a0)+		;put the bits back
	dbf	d0,.restore
	rts

EncodePW							;after playoff game compute winners and password if needed. Called from
									;GameOver.
	tst.w	(OptPlayMode).w
	beq.w	rtss					;regular season
	move.w	#1,(OptPlayMode).w		;continue season

	bsr.w	ResolveGames
	bsr.w	MakeTree
	cmpi.w	#4,(gamelevel).w
	beq.w	.userwon				;finished playoffs
	tst.w	(gamenum).w
	bmi.w	.userwon				;po team out, same as a win
	movea.w	#(passbits-M68K_RAM),a3	;password bits
	bsr.w	WritePassBits
	bsr.w	BackupRAM_Save
	btst	#sf3alttree,(sflags3).w
	beq.w	rtss					;(92 retail; Rev A beq MakeTree)
	movea.w	#(tpassbits-M68K_RAM),a3	;bits before all games resolved (Rev 0)
	bsr.w	ReadPassBits
	bra.w	MakeTree

.userwon	movea.w	#(passbits-M68K_RAM),a3	;password bits
	bsr.w	ClrPassBits
	bsr.w	BackupRAM_Save
	move.w	#2,(OptPlayMode).w		;new playoffs
	cmpi.w	#7,(bosgames).w
	beq.w	rtss
	move.w	#3,(OptPlayMode).w		;new playoffs best of 7
	rts

WritePassBits						;transfer game variables to the password bits at a3., without the
									;checksum.
									;Called from EncodePW and ResolveGames.
	bsr.w	ClrPassBits
	move.w	(postarts).w,d0
	moveq	#$20,d1
	bsr.w	PushBits

	move.w	(bosgames).w,d0
	moveq	#8,d1
	bsr.w	PushBits

	move.w	(gamelevel).w,d0
	moveq	#4,d1
	bsr.w	PushBits

	move.w	(potreeteam).w,d0
	moveq	#$10,d1
	bsr.w	PushBits

	move.w	(pojoy).w,d0
	moveq	#4,d1
	bsr.w	PushBits

	move.w	(WinBits).w,d0
	move.w	#$4000,d1				;92 1<<14
	bsr.w	PushBits

	moveq	#5,d1
	moveq	#7,d2
	movea.w	#(gstruct-M68K_RAM),a1
.0	move.w	gspotwins(a1),d0		;per game: push both win counts (range 5)
	bsr.w	PushBits
	move.w	gspobwins(a1),d0
	bsr.w	PushBits
	adda.w	#gssize,a1
	dbf	d2,.0
	rts

PushBits							;bits = bits * d1 + d0.
									;d1=range 2^1-2^15
									;d0=data
	movem.l	d0-d1,-(sp)
	exg	d0,d1
	bsr.w	SuperMult
	clr.l	d0
	move.w	d1,d0
	bsr.w	SuperAdd
	movem.l	(sp)+,d0-d1
	rts

ClrPassBits							;clr the 5 words of bits at a3
	movea.w	a3,a0
	moveq	#4,d0
.0	clr.w	(a0)+					;5 words
	dbf	d0,.0
	rts

SuperAdd							;1 long (d0.L) added to the 5 words at a3.
	movem.l	d1/a0,-(sp)
	lea	5*2(a3),a0
	moveq	#3,d1
	add.l	d0,-(a0)
	bra.w	.2
.1	addq.w	#1,-(a0)				;carry into the next word up
.2	dbcc	d1,.1					;loop while no carry out of the word
	movem.l	(sp)+,d1/a0
	rts

SuperMult							;1 word (d0) multiplied by the 5 words at a3.
	movem.l	d1-d4/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d4
.0	move.w	(a0),-(sp)				;stack the 5 words, clearing the buffer
	clr.w	(a0)+
	dbf	d4,.0
	moveq	#4,d4
.1	move.w	d0,d1					;multiply a stacked word by d0, add into the buffer
	mulu.w	(sp)+,d1
	lea	2(a3),a0
	adda.w	d4,a0
	adda.w	d4,a0
	move.w	d4,d2
	add.l	d1,-(a0)
	bra.w	.3
.2	addq.w	#1,-(a0)				;carry into the next word up
.3	dbcc	d2,.2					;loop while a carry remains
	dbf	d4,.1
	movem.l	(sp)+,d1-d4/a0
	rts

SuperDiv							;5 words at a3 divided by 1 word (d0).
									;d0 = remainder on exit
	movem.l	d1-d2/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d1
	clr.l	d2
.0	move.w	(a0),d2					;one word: d2 = remainder:word, divide by d0
	divu.w	d0,d2
	move.w	d2,(a0)+
	dbf	d1,.0
	swap	d2
	move.w	d2,d0
	movem.l	(sp)+,d1-d2/a0
	rts

GetShifter							;returns:
									;d1 = number of games-1
									;d2 = first bit of WinBits
									;Called from MakeTree, FigureJoy, ResolveGames, and the stats,
									;intermission and penalty screens.
	move.l	d0,-(sp)
	moveq	#-$10,d2
	moveq	#$10,d1
	move.w	(gamelevel).w,d0
.3	add.w	d1,d2					;d2 = sum of the halving sizes (bit offset of the round)
	lsr.w	#1,d1
	dbf	d0,.3
	subq.w	#1,d1
	move.l	(sp)+,d0
	rts

AddPlayoffTeamStats					;Adds the po team's game stats to its packed playoff totals. Called from
									;PeriodOver at the end of a playoff game. Unpacks the totals
									;(ReadTeamStats), adds the $68 stat bytes from tmgoals on, then packs
									;each total back into the bit stream in outputbuffer, clamped to its
									;BitWidthTable width (8, 10, 6, 6 bits, by d0 & 3).
	cmpi.w	#1,(OptPlayMode).w
	blt.w	rtss					;regular season
	bsr.w	ReadTeamStats
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2			;po team
	movea.w	#(tmstruct-M68K_RAM),a2
	cmp.w	tmteam(a2),d2			;team number of the home team struct
	beq.w	.area
	adda.w	#tmsize,a2				;po team is the visitor
.area	adda.w	#tmgoals,a2			;stat bytes in the team struct
	moveq	#$67,d0					;$68 stats
	movea.w	#(statsbuffer-M68K_RAM),a1
.acc	clr.w	d1					;add stat byte to its statsbuffer word
	move.b	(a2)+,d1
	add.w	d1,(a1)+
	dbf	d0,.acc
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2	;bit stream base
	moveq	#$67,d0
	clr.w	d4						;d4 = bit position
.loop	clr.l	d1					;one stat: d1 = total, d2 = width, d3 = max
	move.w	(a0)+,d1
	move.w	d0,d2
	andi.w	#3,d2
	move.b	0(a1,d2.w),d2			;d2 = bit width
	clr.l	d3
	bset	d2,d3
	subq.w	#1,d3					;d3 = max value
	cmp.w	d3,d1
	ble.w	.pack
	move.w	d3,d1					;clamp
.pack	not.l	d3					;rotate mask and value to bit position d4, clear field then insert
	move.w	d4,d5
	andi.w	#$F,d5
	rol.l	d5,d3
	rol.l	d5,d1
	move.w	d4,d5
	lsr.w	#4,d5
	add.w	d5,d5
	neg.w	d5						;the stream runs down in words from base+$5E
	and.l	d3,marker-outputbuffer-4(a2,d5.w)
	or.l	d1,marker-outputbuffer-4(a2,d5.w)
	add.w	d2,d4
	dbf	d0,.loop
	rts

BitWidthTable						;playoff stat bit widths, indexed by stat number & 3.
									;Used by AddPlayoffTeamStats and ReadTeamStats.
	dc.b	8,$A,6,6

ReadTeamStats						;Unpack the $68 playoff stat totals from the outputbuffer bit stream into
									;statsbuffer words. Called from AddPlayoffTeamStats and
									;PlayoffStatsScreen.
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2	;bit stream base
	moveq	#$67,d0					;$68 stats
	clr.w	d4						;d4 = bit position
.loop	move.w	d4,d5				;d4 = bit position of the stat
	lsr.w	#4,d5
	add.w	d5,d5
	neg.w	d5
	move.l	marker-outputbuffer-4(a2,d5.w),d1
	move.w	d4,d5
	andi.w	#$F,d5
	lsr.l	d5,d1
	move.w	d0,d2
	andi.w	#3,d2
	move.b	0(a1,d2.w),d2			;d2 = bit width
	add.w	d2,d4
	clr.w	d3
	bset	d2,d3
	subq.w	#1,d3
	and.w	d3,d1					;mask to width
	move.w	d1,(a0)+
	dbf	d0,.loop
	rts

;======================================================================
;======================================================================
;	ResolveGames, the end of game "Stars of the Game" box (ShowThreeStars ... CalcTeamStarScores), the injury
;	and goal boxes, the player name formatters (getname ... ConvertByteToDigits) and the exception handlers.
;
;	A goal entry (ScoreSum, 6 bytes): word period/time, byte 2 bit 7 away team scored, byte 3 scorer, bytes 4
;	and 5 assists (negative: none). ChkCnt + ScoreSumbytes is the last entry.
;
;	Per roster slot (26 slots) the team struct keeps goals (tmgoals; goalies: against), assists (tmassists),
;	shots (tmpshots, shots against for a goalie) and frames on ice (tmpice, words).

ResolveGames						;compute winners and losers for playoff matchups. Called from EncodePW
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gstruct-M68K_RAM),a0
	move.w	(tmstruct+tmscore).w,gss1(a0,d0.w)	;copy score from played game into game structures
	move.w	(awtmstruct+tmscore).w,gss2(a0,d0.w)

	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	cmpi.w	#7,(bosgames).w
	beq.w	.notbos					;not best of 7
.b0	cmpi.w	#4,gspotwins(a0)		;per game: skip finished series
	beq.w	.b1
	cmpi.w	#4,gspobwins(a0)
	beq.w	.b1
	clr.w	d3
	btst	#gsftf,gsflags(a0)		;teams flipped
	beq.w	.nf
	eori.w	#gspobwins-gspotwins,d3
.nf	move.w	gss1(a0),d0				;score difference decides the winner
	sub.w	gss2(a0),d0
	bpl.w	.ns1
	eori.w	#gspobwins-gspotwins,d3
.ns1	addq.w	#1,gspotwins(a0,d3.w)	;count the win
.b1	suba.w	#gssize,a0				;previous game of the round
	dbf	d1,.b0
	addq.w	#1,(bosgames).w
	cmpi.w	#7,(bosgames).w
	beq.w	.nextround
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	cmpi.w	#4,gspotwins(a0)
	beq.w	.cround
	cmpi.w	#4,gspobwins(a0)
	bne.w	rtss
.cround	cmpi.w	#3,(gamelevel).w	;finish off rest of round games here
	bge.w	.nextround
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
.cr0	cmp.w	(gamenum).w,d1		;skip the game just played
	beq.w	.crn
	cmpi.w	#4,gspotwins(a0)
	beq.w	.crn
	cmpi.w	#4,gspobwins(a0)
	beq.w	.crn
	addq.w	#1,gspotwins(a0)
	move.l	#200,d0
	bsr.w	randomd0
	andi.w	#1,d0
	beq.s	.cr0
	subq.w	#1,gspotwins(a0)
	addq.w	#1,gspobwins(a0)
	bra.s	.cr0
.crn	suba.w	#gssize,a0			;previous game
	dbf	d1,.cr0
	movea.w	#(tpassbits-M68K_RAM),a3	;bits before advancing to next round (Rev 0)
	bsr.w	WritePassBits			;(92 wrote passbits and copied them to tpassbits)
	bset	#sf3alttree,(sflags3).w

.nextround	clr.w	(bosgames).w	;advance to next round
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	clr.w	d3
.nr0	cmpi.w	#4,gspotwins(a0)	;series won by team 1 (or flipped): leave bit clear
	beq.w	.nr1
	bset	d1,d3
.nr1	clr.w	gspotwins(a0)		;reset win counts for the next round
	clr.w	gspobwins(a0)
	suba.w	#gssize,a0
	dbf	d1,.nr0
	moveq	#1,d1					;(92 Rev A only) clear this round's winbits
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts

.notbos	clr.w	d3					;solve for no best of 7 playoffs (much simpler)
.nb0	move.w	gss1(a0),d0			;one game: higher score wins
	cmp.w	gss2(a0),d0
	bhi.w	.nb1
	bset	d1,d3
.nb1	btst	#gsftf,gsflags(a0)	;teams flipped
	beq.w	.nb2
	bchg	d1,d3
.nb2	suba.w	#gssize,a0			;previous game
	dbf	d1,.nb0
	moveq	#1,d1					;(92 Rev A only)
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts

ShowThreeStars						;end of game "Stars of the Game" box. Called from UpdatePA while RefPen is
									;the game over penalty. Waits for RefCnt <= $40 and runs once (gmode bit
									;7). Frames the box, draws a bitmap from IceRinkMap, then the three best
									;star scores (TakeTopStarScore): team data string and getname.
									;Song $F when the home team won.
	cmpi.w	#$40,(RefCnt).w
	bgt.w	rtss					;ref animation not far enough yet
	bset	#gmstars,(gmode).w
	bne.w	rtss					;already shown
	movem.l	d0-d5/a0-a4,-(sp)
	bsr.w	printz
	String	$BF,2,$E
	moveq	#$1C,d0					;framer size
	moveq	#9,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,9,$10,'Stars of the Game',$BF,3,$F
	movea.l	#IceRinkMap,a1			;in the string. map at IceRinkMap offset 4
	movea.w	#null,a2
	adda.l	jimdata(a1),a1
	moveq	#$D,d0					;dobitmap d0-d5
	moveq	#$5B,d1
	moveq	#6,d2
	moveq	#4,d3
	move.w	(rinkvrcset).w,d4
	clr.w	d5
	bsr.w	dobitmap
	bsr.w	CalcStarScores
	move.w	#$12,(printy).w
	moveq	#2,d2					;3 stars
.loop	bsr.w	TakeTopStarScore	;a2 = team, d0 = player
	move.w	#$1A,(printx).w
	addq.w	#1,(printy).w
	movea.l	tmdata(a2),a1			;string at team data offset 4, then its first offset
	adda.w	Teamname(a1),a1
	adda.w	(a1),a1
	bsr.w	print
	bsr.w	getname					;a1 = number and name of player d0
	move.w	#3,(printx).w
	bsr.w	print
	dbf	d2,.loop
	move.w	(tmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;- visitor score
	ble.w	.nosong
	move.w	#SFXhomewin,-(sp)		;song $F: home team won
	bsr.w	song
.nosong	movem.l	(sp)+,d0-d5/a0-a4	;restore registers
	rts

TakeTopStarScore					;take the highest of the 52 star scores at starscores (26 per team,
									;home first) and clear it. Returns d0 = player slot, a2 = its team struct.
									;Called from ShowThreeStars
	movem.l	d1-d2/a1/a4,-(sp)
	movea.w	#(starscores-M68K_RAM),a4
	clr.l	d0						;best so far
	moveq	#$33,d2					;52 scores
.find	cmp.l	(a4)+,d0			;scan for the highest score
	bge.w	.next					;not higher
	lea	-4(a4),a1					;a1 = best entry
	move.l	(a1),d0
.next	dbf	d2,.find				;next entry
	clr.l	(a1)					;taken
	move.w	a1,d0
	subi.w	#(starscores-M68K_RAM),d0
	lsr.w	#2,d0					;entry number
	movea.w	#(tmstruct-M68K_RAM),a2
	cmp.w	#$1A,d0
	blt.w	.home					;0-25: home team
	subi.w	#$1A,d0
	adda.w	#tmsize,a2				;26-51: away team
.home	movem.l	(sp)+,d1-d2/a1/a4	;restore registers
	rts

CalcStarScores						;star score for every roster slot of both teams to starscores (26 longs
									;per team, home first). d5 = GetPeriodTime + d2, the goalie ice time
									;needed. If gsp is 3 and the score is not tied, the scorer of the last
									;goal gets $7FFFFFFF. Called from ShowThreeStars
	movea.w	#(starscores-M68K_RAM),a4
	jsr	(GetPeriodTime).w
	move.w	d0,d5
	add.w	d2,d5
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3				;a3 = other team
	bsr.w	CalcTeamStarScores		;home
	movea.w	a3,a2
	lea	-tmsize(a2),a3
	bsr.w	CalcTeamStarScores		;away (d3 = away - home score)
	cmpi.w	#3,(gsp).w
	bne.w	.x
	tst.w	d3
	beq.w	.x						;tied
	movea.w	#(ChkCnt-M68K_RAM),a0	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a0
	clr.w	d0
	btst	#7,ssflags(a0)
	beq.w	.slot					;home goal
	addi.w	#$1A,d0					;away goal: second 26 entries
.slot	add.b	ssscorer(a0),d0		;scorer
	asl.w	#2,d0
	movea.w	#(starscores-M68K_RAM),a0
	move.l	#$7FFFFFFF,0(a0,d0.w)	;game winner is the first star
.x	rts								;return

CalcTeamStarScores					;star scores of team a2 (a3 = other team) to (a4)+, one long per roster
									;slot (26). Each starts at the goal difference. Skaters: goals*11000 +
									;assists*10100 + shots*10, or in a tied game shots*1000 + frames on ice.
									;Goalies (the first slots) on ice at least d5 with shots against:
									;+32000 if goals against*100/shots <= 4, +75000 more for a shutout. Called
									;from CalcStarScores
	movea.w	a2,a1
	move.w	tmscore(a2),d3
	sub.w	tmscore(a3),d3			;goal difference
	ext.l	d3
	moveq	#$19,d4					;26 slots
	jsr	(GetGoalieCount).l			;d0 = goalies on the team
	neg.w	d0
	add.w	d4,d0					;d4 above $19 - goalies: goalie slot
.loop	move.l	d3,(a4)				;slot d4: start at the goal difference
	cmp.w	d0,d4
	bhi.w	.goalie
	clr.w	d1
	move.b	tmgoals(a2),d1			;goals
	mulu.w	#$2AF8,d1				;11000
	add.l	d1,(a4)
	clr.w	d1
	move.b	tmassists(a2),d1		;assists
	mulu.w	#$2774,d1				;10100
	add.l	d1,(a4)
	clr.w	d1
	move.b	tmpshots(a2),d1			;shots
	mulu.w	#$A,d1
	tst.w	d3
	bne.w	.add					;not tied: shots*10
	mulu.w	#$64,d1					;tied: shots*1000
	add.l	d1,(a4)
	clr.l	d1
	add.w	tmpice(a1),d1			;+ frames on ice
.add	add.l	d1,(a4)				;add shots part
	bra.w	.next
.goalie	cmp.w	tmpice(a1),d5		;goalie slot: needs enough frames on ice
	bhi.w	.next					;not on ice long enough
	clr.w	d1
	move.b	tmgoals(a2),d1			;goals against
	mulu.w	#$64,d1
	clr.w	d2
	move.b	tmpshots(a2),d2			;shots against
	beq.w	.next
	divu.w	d2,d1
	cmp.w	#4,d1
	bhi.w	.next
	addi.l	#$7D00,(a4)				;32000
	tst.w	d1
	bne.w	.next
	addi.l	#$124F8,(a4)			;75000 for a shutout
.next	addq.w	#2,a1				;next slot (word, byte, long tables)
	addq.w	#1,a2
	addq.w	#4,a4
	dbf	d4,.loop
	rts

ShowInjuryBox						;injury box "Injury to:" player TempPlOffset (set by setInjuryType) "Out
									;for period", or "the game" when puckx+pflags2 bit pf2fight is set. Jumped
									;to (jmp abs.l) from CheckInjury when InjCntDown runs out, so global
	movem.l	d0-d2/a0-a4,-(sp)
	bsr.w	printz
	String	$BF,$B,3
	moveq	#$12,d0					;framer size
	moveq	#5,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,$C,4,'Injury to:',$BF,$C,6,'Out for period',$BF,$C,5
	bsr.w	GetPlayerNumInitial		;in the string
	bsr.w	print
	btst	#pf2fight,(puckx+pflags2).w
	beq.w	.ex
	bsr.w	printz
	String	$BF,$14,6,'the game'	;over "period"
.ex	movem.l	(sp)+,d0-d2/a0-a4		;restore registers
	rts

ShowGoalBox							;goal box. Closes both line change boxes, then printbig "GOAL!" (or "HAT
									;TRICK!" on the scorer's third goal), the scorer and up to two assists of
									;the last goal entry.
									;Called from SetPA for the goal penalty number
	movem.l	d0-d2/a0-a4,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	jsr	(lcfound2).l				;close lc box
	adda.w	#tmsize,a2
	jsr	(lcfound2).l
	movea.w	#(ChkCnt-M68K_RAM),a4	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a4
	bsr.w	printz
	String	$BF,$B,2
	moveq	#$13,d0					;in the string. framer size
	moveq	#5,d1					;5 rows: no assist
	tst.b	ssassist1(a4)
	bmi.w	.frame
	addq.w	#2,d1					;7: one assist
	tst.b	ssassist2(a4)
	bmi.w	.frame
	addq.w	#1,d1					;8: two assists
.frame	bsr.w	Framer				;draw the box frame
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#7,ssflags(a4)
	beq.w	.home					;home team scored
	adda.w	#tmsize,a2
.home	lea	GoalBoxText(pc),a1		;a1 = GOAL! string
	clr.w	d0
	move.b	ssscorer(a4),d0			;scorer
	addi.w	#tmgoals,d0				;goals of the scorer
	cmpi.b	#3,0(a2,d0.w)			;goals
	bne.w	.print
	adda.w	(a1),a1					;third goal: HAT TRICK!
.print	bsr.w	printbig			;big text, then scorer
	clr.w	d0
	move.b	ssscorer(a4),d0
	bsr.w	FormatPlayerNumInitial
	bsr.w	print
	clr.w	d0
	move.b	ssassist1(a4),d0		;first assist
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$E,6,'Assist by:',$BF,$C,7
	bsr.w	FormatPlayerNumInitial	;in the string
	bsr.w	print
	clr.w	d0
	move.b	ssassist2(a4),d0		;second assist
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$C,8
	bsr.w	FormatPlayerNumInitial	;and the next line in the string
	bsr.w	print
.ex	movem.l	(sp)+,d0-d2/a0-a4		;restore registers
	rts

GoalBoxText							;printbig strings for ShowGoalBox: GOAL!, then HAT TRICK!
	String	$BF,$F,3,'GOAL!',$BF,$C,5
	String	$BF,$C,3,'HAT TRICK!',$BF,$C,5

box									;fill a $13 x 8 rectangle at printz position
									;$FF,$B,2 with char $7FF (eraser).
									;Called from SetLCmode2 and banner
	bsr.w	printz
	String	$FF,$B,2
	moveq	#$13,d0					;in the string
	moveq	#8,d1
	move.l	#$7FF,d2
	bra.w	eraser

GetPlayerName						;a1 = mesarea "NN First Last" (getname) for player TempPlOffset (bit 15
									;set: away team). Called from UpdatePA
	movem.l	d0/a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2				;away team
.get	bsr.w	getname				;name for d0 of team a2
	movem.l	(sp)+,d0/a2
	rts

getname								;a1 = mesarea string "NN First Last" for player d0 of team a2. The number
									;is the bcd byte after the name. Called from ShowThreeStars,
									;GetPlayerName, banner and others
	movem.l	d0-d3/a0/a2-a3,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#4,(a3)					;length word + 2 digits
	lea	2(a3),a1
	adda.w	(a0),a0					;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConvertByteToDigits
	bsr.w	appendz
	String	' '
	movea.l	(sp)+,a1				;name string
	bsr.w	appstring
	movea.w	#(mesarea-M68K_RAM),a1
	movem.l	(sp)+,d0-d3/a0/a2-a3
	rts

GetPlayerNumInitial					;a1 = mesarea "NN F. Last" (FormatPlayerNumInitial) for player
									;TempPlOffset (bit 15 set: away team). Called from ShowInjuryBox
	movem.l	d0/a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2				;away team
.get	bsr.w	FormatPlayerNumInitial	;name for d0 of team a2
	movem.l	(sp)+,d0/a2
	rts

FormatPlayerNumInitial				;a1 = mesarea string "NN F. Last" for player d0 of team a2, built in
									;TextBuffer. Called from ShowGoalBox, GetPlayerNumInitial, PrintScorerName
									;and others
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0					;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConvertByteToDigits
	move.b	#$20,(a1)+				;' '
	movea.l	(sp)+,a0
	move.w	(a0)+,d0				;string length
	lea	-2(a0,d0.w),a2				;end of the name
	move.b	(a0)+,(a1)+				;first initial
	move.w	#$2E20,(a1)+			;'. '
.skip	cmpi.b	#$20,(a0)+			;skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+			;last name
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FormatPlayerName					;a1 = mesarea string "NN Last" for player d0 of
									;team a2, built in TextBuffer.
									;Called from DrawStatsRow
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0					;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConvertByteToDigits
	move.b	#$20,(a1)+				;' '
	movea.l	(sp)+,a0
	move.w	(a0)+,d0				;string length
	lea	-2(a0,d0.w),a2				;end of the name
.skip	cmpi.b	#$20,(a0)+			;skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+			;last name
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FormatPlayerNameShort				;a1 = mesarea string " Last" for player d0 of team a2, space padded to 12
									;characters; a 0 byte also ends the name. Called from DrawLineIcon
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	movea.w	#(TextBuffer-M68K_RAM),a1
	move.b	#$20,(a1)+				;' '
	move.w	(a0)+,d0				;string length
	lea	-2(a0,d0.w),a2				;end of the name
.skip	cmpi.b	#$20,(a0)+			;skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+			;last name
	cmpa.l	a0,a2
	beq.w	.chk
	tst.b	(a0)
	bne.s	.copy
	bra.w	.chk
.pad	move.b	#$20,(a1)+			;pad with spaces
.chk	cmpa.w	#(TextBuffer+12-M68K_RAM),a1	;TextBuffer+12
	blt.s	.pad
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FinalizeTextBuffer					;mesarea length word = a1 - mesarea, with a 0 pad byte when odd. Returns
									;a1 = mesarea. Called from the FormatPlayerName routines
	move.w	a1,d0
	subi.w	#(mesarea-M68K_RAM),d0
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even	movea.w	#(mesarea-M68K_RAM),a1	;a1 = mesarea
	move.w	d0,(a1)
	rts

GetPlayerNamePointer				;a0 = name string of player d0 on team a2. From tmdata and its first
									;offset each record is a length word string and 8 more bytes
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0
	bra.w	.cnt
.next	adda.w	(a0),a0				;skip the name
	addq.w	#pldsize,a0
.cnt	dbf	d0,.next				;d0 entries to skip
	rts

ConvertByteToDigits					;from 92 .dispen digit code. two ascii digits of bcd byte d0 to (a1)+, a
									;leading 0 becomes a space.
									;Called from getname, the FormatPlayerName routines, pplpen and others
	move.w	d0,-(sp)
	lsr.b	#4,d0
	bne.w	.digit
	move.b	#$F0,d0					;$F0+'0' = ' '
.digit	addi.b	#$30,d0				;'0'
	move.b	d0,(a1)+
	move.w	(sp)+,d0
	andi.w	#$F,d0
	addi.b	#$30,d0					;'0'
	move.b	d0,(a1)+
	rts

AddError							;address error vector. The bus error vector also points here
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Address Error'	;92 -$43
	move.l	$A(sp),d0				;pc (exception frame)
	move.l	2(sp),d1				;access address (exception frame)
	bra.w	crash

Illinst								;illegal instruction vector.
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Illegal Instruction'
	move.l	2(sp),d0				;pc (exception frame)
	move.l	d0,d1
	bra.w	crash

ZeroDiv								;divide by zero vector., falls into crash
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Division by zero'
	move.l	2(sp),d0				;and the next line in the string
	move.l	d0,d1

crash								;printbig d1 then d0 as hex, set the vdp up, load a palette and hang.
									;Copies 8 longs
									;IceRinkMap+$20 to cram $20 (92 wrote one colour $0EEE to cram 6)
	movea.w	#(mesarea-M68K_RAM),a0
	move.w	#2+3+8+3+8,(a0)+
	move.b	#$BD,(a0)+				;92 -$43
	move.b	#0,(a0)+
	move.b	#2,(a0)+
	move.l	d1,-(sp)
	bsr.w	.ri

	move.b	#$BD,(a0)+
	move.b	#0,(a0)+
	move.b	#4,(a0)+
	move.l	(sp)+,d0
	bsr.w	.ri

	movea.w	#(mesarea-M68K_RAM),a1
	bsr.w	printbig

	movea.l	#Vdata,a0
	move.w	#$9100,4(a0)
	move.w	#$9206,4(a0)
	move.w	#$8F02,4(a0)
	move.l	#CRAM_W+($20<<16),4(a0)	;cram write $20 (92 $C0060000)
	movea.l	#IceRinkMap,a1
	adda.l	(a1),a1
	adda.w	#$20,a1
	moveq	#7,d0
.pal	move.l	(a1)+,(a0)			;write 8 longs = 16 colors to cram
	dbf	d0,.pal
.end	bra.w	.end				;hang

.ri	moveq	#7,d2					;d0 as 8 hex digits to (a0)+
.top	rol.l	#4,d0				;next hex digit (high nibble first)
	move.w	d0,d1
	andi.w	#$F,d1
	addi.w	#$30,d1					;'0'
	cmp.w	#$39,d1					;'9'
	ble.w	.t1
	addq.w	#7,d1					;'A'-'0'-10
.t1	move.b	d1,(a0)+				;store the digit
	dbf	d2,.top
	rts

	include tables93.asm			;data tables (crowd frames, asstab, penalty list, playoff tree, menu item
									;lists)
	include sram93.asm				;BackupRAM_*, BackupRAM_Save, ClearRAMBuffer, ClearVRAM
	include sound\sound93.asm				;sound driver (68k code, Z80 blob, sound data)
	include graphics93.asm			;graphics data (92 incbins after part 3)
	include checksum93.asm			;SecurityCheck, ValidationRoutine
	dcb.b	$80000-*,$FF