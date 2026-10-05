;	NHLPA Hockey 93 (v1.1 retail) segment $6446-$68B3
;	VBLANK / Begin through the end of clockcont.
;	Global names from the v1.1 IDA export. Local labels and comments follow
;	NHL 92 hockey.asm where the code matches. Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx),
;	so those sites are written as dc.w with the instruction in the comment.
;	92 equate names in comments are only used where the 93 value is the same.

VBLANK	;vertical blank interrupt (vector $78), jumps through the vbint RAM vector
	move.l	(vbint).w,-(sp)		;push handler address
	rts				;and "return" into it

Begin	;cold start, entered from Reset. Clear RAM, init menus and sound, go to title
	move	#$2700,sr		;interrupts off
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0	;clear out ram
.0	clr.l	(a0)+
	cmpa.w	#$CDF0,a0		;retail v1.1 clear end (Rev A: $CDF4)
	blt.s	.0

	jsr	(SetupStanleyCupCelebrationScreen).l
	jsr	(BackupRAM_Read).l
	jsr	(DefaultMenus).l	;set initial menu choices
	jsr	(orjoy).l		;clear any previous button presses
	jsr	(p_initialZ80).l	;sound stuff
	jsr	(p_turnoff).l		;sound stuff
	jsr	(p_music_vblank).l	;sound stuff
	jmp	(Opening).l		;goto title screen and options etc.
;----------------------------------------------------

ChkShortPeriods	;IDA: loc_649E. Pad 1 = $E0 at game start forces 30 second periods
	bsr.w	Readjoy1
	dc.w	$B63C,$00E0		;cmp.b	#$E0,d3
	bne.w	StartGame
	move.w	#3,(word_FFCADE).w	;period length index 3 = 30 (92 OptPerlen)

StartGame	;reset game state for a new game, then start the first period
	clr.b	(gmode).w
	cmpi.w	#1,(OptPen).w
	bne.w	.0
	bset	#5,(gmode).w		;gmoffs: offsides pen. is active
.0	cmpi.w	#1,(OptPlayMode).w
	ble.w	.1			;OptPlayMode 0-1 keep the shot buffer
	bsr.w	ClearShotData
.1	jsr	(clearTeamStats).l
	clr.w	(ScoreSumbytes).w
	clr.w	(word_FFC3F4).w
	clr.w	(gsp).w			;first period
	clr.w	(ChkCnt).w
	bsr.w	InitTeamShots
	jsr	(InitScores).l
	jsr	(setupice).l
	jmp	(_sp).l			;on to period start

ClearShotData	;clear 49 words at $FFCB0A
	moveq	#$30,d0
	movea.w	#$CB0A,a0		;retail v1.1 shot buffer (Rev A outputbuffer: $CB0E)
.0	clr.w	(a0)+
	dbf	d0,.0
	rts

InitTeamShots	;92 restoreteams. Put both teams' rosters on the bench
	movea.w	#(hmtmstruct-M68K_RAM),a2	;team 1
	bsr.w	InitShotStruct
	adda.w	#$1A2,a2		;team 2
InitShotStruct	;92 restoreteams .r. Reset one team struct (a2), falls in from InitTeamShots
	move.w	#6,$24(a2)		;no players in pen. box
	moveq	#$32,d0			;(maxros-1)*2
.0	move.w	#$FFFE,$66(a2,d0.w)	;all players on bench
	subq.w	#2,d0
	bpl.s	.0
	rts

ResetClock	;set period length and stop clock
	bsr.w	GetPeriodTime		;d0 = period length in seconds
	cmpi.w	#3,(gsp).w		;overtime?
	blt.w	.set
	tst.w	(OptPlayMode).w
	bne.w	.set
	move.w	#$258,d0		;OptPlayMode 0 overtime is always 10:00
.set	move.w	d0,(gameclock).w
	move.w	d0,(PerTimeTotal).w
	move.w	d0,(word_FFB048).w	;CheckPeriodEnd trigger time =
	asr.w	#1,d0
	bsr.w	randomd0
	sub.w	d0,(word_FFB048).w	;length - random(length/2)
	bset	#0,(gmode).w		;gmclock: stop clock
	rts

GetPeriodTime	;return d0 = period length in seconds for the period length option
	move.w	(word_FFCADE).w,d0	;92 OptPerlen
	asl.w	#1,d0
	lea	PeriodTimeTable(pc),a0
	move.w	0(a0,d0.w),d0
	rts
PeriodTimeTable	;92 ResetClock .timetab. Period length in seconds: 5, 10, 20 min, 30 sec
	dc.w	5*60,10*60,20*60,30

StartPer	;start a period: reset stack, rink and clock, face off, run the game loop
	movea.w	#(Stack-M68K_RAM),sp
	jsr	(p_turnoff).l		;sound off
	jsr	(setupice).l
	bsr.s	ResetClock
	ori.w	#$F000,(PadControlBits).w
	st	(c1playernum).w		;no controlled player yet
	st	(c2playernum).w
	movea.w	#(puckx-M68K_RAM),a3	;puck
	clr.w	(fox).w			;face off at center ice
	clr.w	(foy).w
	move.l	#$1B,d0			;pfaceoff
	bsr.w	assreplace		;face off starts period
	bset	#2,(sflags2).w		;sf2drec: don't record
	bclr	#4,(sflags).w		;sfwrap: reset replay stuff
	move.w	#$FFFF,(lastsfx).w
	move.l	#$FFFF0000,(ReplayBufferPtr).w
	move.w	(vcount).w,(oldvcount).w
	bsr.w	DoGameFrame		;run two frames before the loop
	bsr.w	DoGameFrame
	move.w	(gamelevel).w,d0
	asl.w	#4,d0
	move.w	d0,(CwdExciteLvl).w	;starting excitement = gamelevel*16
	move.w	#$31,-(sp)		;period start tune
	bsr.w	song
	cmpi.w	#2,(gsp).w
	bge.w	Gameloop
	bset	#7,(sflags3).w		;set for periods 1 and 2 only

Gameloop	;main loop for game
	bsr.w	DoGameFrame
	bsr.w	demoread		;check if demo mode
	btst	#0,(sflags).w		;sfpz
	beq.s	Gameloop
	bsr.w	Pausemode
	bra.s	Gameloop

DoGameFrame	;wait for at least one vblank, then run one frame of game logic
	move.w	(vcount).w,d7
	sub.w	(oldvcount).w,d7	;number of frames since last loop
	beq.s	DoGameFrame
	move.w	(vcount).w,(oldvcount).w
	bsr.w	periodicevents
	bsr.w	updateplayers		;apply velocity and check collisions
	bsr.w	checkwindow
	bsr.w	updatereplay
	jmp	(setvideo).l

periodicevents	;called every time thru game loop with d7 = elapsed frames
	jsr	(PenaltyManager).l
	bsr.w	updatecrowdf
	jsr	(updatesound).l
	bsr.w	clockcont
	btst	#7,(sflags).w		;sfhor
	bne.w	rtss2			;exit if in horizontal mode
	sub.w	d7,(lldisp).w		;count down for screen updates
	bpl.w	rtss2
	addi.w	#$18,(lldisp).w		;jps: only update once per second
	bsr.w	ChkGoalies
	bsr.w	UpdateCwdExcite
	bsr.w	CheckPeriodEnd
	bsr.w	UpdateLineChange
	bsr.w	CheckInjury
	jmp	(updatepwrplay).l

CheckInjury	;called once per second. Count down InjCntDown, act on it at zero
	subq.w	#1,(InjCntDown).w
	bne.w	rtss2
	jmp	(loc_14D36).l		;countdown expired

UpdateLineChange	;called once per second. Restore energy for players on the bench
	tst.w	(OptLine).w
	bne.w	.x			;exit if line changes are off
	movea.w	#(hmtmstruct-M68K_RAM),a2	;team 1
	bsr.w	.team
	lea	$1A2(a2),a2		;team 2
.team	moveq	#$32,d0			;(maxros-1)*2
.b0	cmpi.w	#$FFFE,$66(a2,d0.w)	;on bench?
	bne.w	.next
	addi.w	#9,$32(a2,d0.w)		;tmpde: energy +9
	cmpi.w	#$1000,$32(a2,d0.w)
	blt.w	.next
	move.w	#$1000,$32(a2,d0.w)	;max energy
.next	subq.w	#2,d0
	bpl.s	.b0
.x	rts

CheckPeriodEnd	;called once per second. 3rd period: play tune $32 once at the random
		;trigger time set by ResetClock
	cmpi.w	#2,(gsp).w		;3rd period only
	bne.w	.x
	btst	#4,(gmode).w
	bne.w	.x
	move.w	(gameclock).w,d0
	cmp.w	(word_FFB048).w,d0
	bgt.w	.x			;not there yet
	st	(word_FFB048).w		;high byte $FF: trigger goes negative, fires once
	move.w	#$32,-(sp)
	bsr.w	song
.x	rts

UpdateCwdExcite	;called once per second. Track peak and running total of crowd
		;excitement, then decay the level by 1 (floor 0)
	move.w	(CwdExciteLvl).w,d0
	cmp.w	(word_FFB8A4).w,d0
	bls.w	.nomax
	move.w	d0,(word_FFB8A4).w	;new peak
.nomax	ext.l	d0
	add.l	d0,(dword_FFB8A8).w	;running total
	addq.w	#1,(word_FFB8A6).w	;sample count
	subq.w	#1,(CwdExciteLvl).w	;decay
	bpl.w	.x
	clr.w	(CwdExciteLvl).w
.x	rts

updatecrowdf	;this is called every game loop with d7 = elapsed frames
	;this will update the current frame of crowd animation
	cmpi.w	#$15E,(crowdlevel).w
	blt.w	.dec
	subq.w	#3,(crowdlevel).w	;loud crowd calms down faster
.dec	sub.w	d7,(crowdlevel).w
	bpl.w	.0
	clr.w	(crowdlevel).w
.0	sub.w	d7,(word_FFB8A0).w	;92 crowdcnt
	bpl.w	.cf
	move.w	(crowdlevel).w,d0
	lsr.w	#1,d0
	dc.w	$B07C,$007F		;cmp.w	#127,d0
	bls.w	.1
	moveq	#$7F,d0
.1	andi.w	#$60,d0			;%01100000
	addq.w	#2,(crowdstep).w
	andi.w	#$1E,(crowdstep).w	;%00011110
	add.w	(crowdstep).w,d0
	movea.l	#cd0,a0			;$fftt frame/time table (92 .cd0)
	move.b	0(a0,d0.w),(crowdframe+1).w
	clr.w	d1
	move.b	1(a0,d0.w),d1
	move.w	(VDP_CNTR).l,d2		;HVcount
	and.w	d1,d2			;random 0..time
	add.w	d2,d1
	move.w	d1,(word_FFB8A0).w	;crowdcnt = time + random
.cf	clr.b	(crowdframe).w
	cmpi.w	#$118,(crowdlevel).w	;280
	bls.w	rtss2
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#$7F,d0
	dc.w	$B07C,$0013		;cmp.w	#19,d0
	blt.w	rtss2
	dc.w	$B07C,$0019		;cmp.w	#25,d0
	bgt.w	rtss2
	move.b	d0,(crowdframe).w	;random extra frame 19-25 when crowd is loud
	rts

clockcont	;monitor period clock and initiate various clock activated events
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss2
	tst.w	(gameclock).w
	bne.w	rtss2

	move.w	#4,-(sp)		;horn (92 SFXhorn = 24)
	bsr.w	sfx
	bsr.w	freezewindow
clockcont_0	;end of period. Also entered from puckfaceoff+2E
	movea.w	#(puckx-M68K_RAM),a3	;puck
	move.l	#$18,d0
	bsr.w	assinsert
	cmpi.w	#2,(gsp).w		;periods 1-2 just end the period
	blt.w	.chkot
	move.l	#7,d0			;score assignment (92 ascore = 8)
	movea.w	#(SortCords-M68K_RAM),a3
	cmpi.w	#3,(gamelevel).w	;playoffs?
	bne.w	.t3
	cmpi.w	#7,(bosgames).w
	beq.w	.sc			;bosgames 7 skips the series check

	;Stanley Cup if the winning team already has 3 series wins
	moveq	#$10,d3			;gssize
	mulu.w	(gamenum).w,d3
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d3,a0
	clr.w	d3
	btst	#0,$E(a0)		;gsftf, gsflags(a0)
	beq.w	.nf
	eori.w	#2,d3			;gspobwins-gspotwins
.nf	move.w	(tmstructtmscore).w,d1
	sub.w	(tmstructtmscoretmsize).w,d1
	bpl.w	.ns1
	eori.w	#2,d3			;gspobwins-gspotwins
.ns1	cmpi.w	#3,4(a0,d3.w)		;gspotwins(a0,d3)
	bne.w	.t3

.sc	move.l	#8,d0			;stanley cup assignment (92 astanley = 9)
	moveq	#$B,d2			;all 12 players lose joystick control
.t0	bclr	#3,$62(a3)		;pfjoycon, pflags(a3)
	adda.w	#$80,a3			;SCstruct
	dbf	d2,.t0
	movea.w	#(SortCords-M68K_RAM),a3
.t3	moveq	#5,d2			;winning team's skaters celebrate
	move.w	(tmstructtmscore).w,d1
	sub.w	(tmstructtmscoretmsize).w,d1
	beq.w	.chkot			;tied
	bpl.w	.t2			;home team leads
	adda.w	#$300,a3		;6*SCstruct: away team leads
.t2	tst.w	$34(a3)			;position(a3)
	ble.w	.n2			;skip the goalie
	bsr.w	assinsert		;first skater gets d0, the rest get score
	move.l	#7,d0			;score assignment
.n2	adda.w	#$80,a3			;SCstruct
	dbf	d2,.t2
.eog	jsr	(ClearPenaltyBuffer).l	;IDA: _n3. End of game
	addi.w	#$3E8,(crowdlevel).w	;1000
	addi.w	#$28,(CwdExciteLvl).w
	bset	#0,(gmode).w		;gmclock
	bset	#6,(gmode).w		;set at end of game
	move.w	#4,d0			;PenEOG
	bra.w	AddPenalty2

.chkot	cmpi.w	#3,(gsp).w		;IDA: loc_68AA. Tie or periods 1-2
	bne.w	.eop
	tst.w	(OptPlayMode).w
	beq.s	.eog			;gsp 3 with OptPlayMode 0 ends the game
.eop	move.w	#2,d0			;PenEOP
	bra.w	AddPenalty2
