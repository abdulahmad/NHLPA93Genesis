;	NHLPA Hockey 93 (v1.1 retail) segment $6446-$68B3
;	VBLANK / Begin through the end of clockcont.
;	Names from the v1.1 IDA export. Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx),
;	so those sites are written as dc.w with the instruction in the comment.

VBLANK
	move.l	(vbint).w,-(sp)
	rts

Begin
	move	#$2700,sr
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0	;clear out ram
loc_6458
	clr.l	(a0)+
	cmpa.w	#$CDF0,a0		;retail v1.1 clear end (Rev A: $CDF4)
	blt.s	loc_6458

	jsr	(SetupStanleyCupCelebrationScreen).l
	jsr	(BackupRAM_Read).l
	jsr	(DefaultMenus).l	;set default menu choices for beginning of game
	jsr	(orjoy).l		;clear any previous button presses
	jsr	(p_initialZ80).l	;sound stuff
	jsr	(p_turnoff).l		;sound stuff
	jsr	(p_music_vblank).l	;sound stuff
	jmp	(Opening).l		;goto title screen and options etc.
;----------------------------------------------------

loc_649E
	bsr.w	Readjoy1
	dc.w	$B63C,$00E0		;cmp.b	#$E0,d3
	bne.w	StartGame
	move.w	#3,(word_FFCADE).w

StartGame
	clr.b	(gmode).w
	cmpi.w	#1,(OptPen).w
	bne.w	loc_64C4
	bset	#5,(gmode).w		;offsides pen. is active
loc_64C4
	cmpi.w	#1,(OptPlayMode).w
	ble.w	loc_64D2
	bsr.w	ClearShotData
loc_64D2
	jsr	(clearTeamStats).l
	clr.w	(ScoreSumbytes).w
	clr.w	(word_FFC3F4).w
	clr.w	(gsp).w
	clr.w	(ChkCnt).w
	bsr.w	InitTeamShots
	jsr	(InitScores).l
	jsr	(setupice).l
	jmp	(_sp).l

ClearShotData
	moveq	#$30,d0
	movea.w	#$CB0A,a0		;retail v1.1 shot buffer (Rev A outputbuffer: $CB0E)
loc_6504
	clr.w	(a0)+
	dbf	d0,loc_6504
	rts

InitTeamShots
	movea.w	#(hmtmstruct-M68K_RAM),a2	;team 1
	bsr.w	InitShotStruct
	adda.w	#$1A2,a2		;team 2
InitShotStruct
	move.w	#6,$24(a2)		;no players in pen. box
	moveq	#$32,d0
loc_6520
	move.w	#$FFFE,$66(a2,d0.w)	;all players on bench
	subq.w	#2,d0
	bpl.s	loc_6520
	rts

ResetClock	;set period length and stop clock
	bsr.w	GetPeriodTime
	cmpi.w	#3,(gsp).w
	blt.w	loc_6546
	tst.w	(OptPlayMode).w
	bne.w	loc_6546
	move.w	#$258,d0
loc_6546
	move.w	d0,(gameclock).w
	move.w	d0,(PerTimeTotal).w
	move.w	d0,(word_FFB048).w
	asr.w	#1,d0
	bsr.w	randomd0
	sub.w	d0,(word_FFB048).w
	bset	#0,(gmode).w
	rts

GetPeriodTime
	move.w	(word_FFCADE).w,d0
	asl.w	#1,d0
	lea	PeriodTimeTable(pc),a0
	move.w	0(a0,d0.w),d0
	rts
PeriodTimeTable
	dc.w	5*60,10*60,20*60,30

StartPer
	movea.w	#(Stack-M68K_RAM),sp
	jsr	(p_turnoff).l
	jsr	(setupice).l
	bsr.s	ResetClock
	ori.w	#$F000,(PadControlBits).w
	st	(c1playernum).w
	st	(c2playernum).w
	movea.w	#(puckx-M68K_RAM),a3
	clr.w	(fox).w
	clr.w	(foy).w
	move.l	#$1B,d0
	bsr.w	assreplace		;face off starts period
	bset	#2,(sflags2).w		;don't record
	bclr	#4,(sflags).w		;reset replay stuff
	move.w	#$FFFF,(lastsfx).w
	move.l	#$FFFF0000,(ReplayBufferPtr).w
	move.w	(vcount).w,(oldvcount).w
	bsr.w	DoGameFrame
	bsr.w	DoGameFrame
	move.w	(gamelevel).w,d0
	asl.w	#4,d0
	move.w	d0,(CwdExciteLvl).w
	move.w	#$31,-(sp)
	bsr.w	song
	cmpi.w	#2,(gsp).w
	bge.w	Gameloop
	bset	#7,(sflags3).w

Gameloop	;main loop for game
	bsr.w	DoGameFrame
	bsr.w	demoread		;check if demo mode
	btst	#0,(sflags).w
	beq.s	Gameloop
	bsr.w	Pausemode
	bra.s	Gameloop

DoGameFrame
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
	btst	#7,(sflags).w
	bne.w	rtss2			;exit if in horizontal mode
	sub.w	d7,(lldisp).w		;count down for screen updates
	bpl.w	rtss2
	addi.w	#$18,(lldisp).w
	bsr.w	ChkGoalies
	bsr.w	UpdateCwdExcite
	bsr.w	CheckPeriodEnd
	bsr.w	UpdateLineChange
	bsr.w	CheckInjury
	jmp	(updatepwrplay).l

CheckInjury
	subq.w	#1,(InjCntDown).w
	bne.w	rtss2
	jmp	(loc_14D36).l

UpdateLineChange
	tst.w	(OptLine).w
	bne.w	locret_66C6		;exit if line changes are off
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	loc_66A0
	lea	$1A2(a2),a2
loc_66A0
	moveq	#$32,d0
loc_66A2
	cmpi.w	#$FFFE,$66(a2,d0.w)
	bne.w	loc_66C2
	addi.w	#9,$32(a2,d0.w)
	cmpi.w	#$1000,$32(a2,d0.w)
	blt.w	loc_66C2
	move.w	#$1000,$32(a2,d0.w)
loc_66C2
	subq.w	#2,d0
	bpl.s	loc_66A2
locret_66C6
	rts

CheckPeriodEnd
	cmpi.w	#2,(gsp).w
	bne.w	locret_66F4
	btst	#4,(gmode).w
	bne.w	locret_66F4
	move.w	(gameclock).w,d0
	cmp.w	(word_FFB048).w,d0
	bgt.w	locret_66F4
	st	(word_FFB048).w
	move.w	#$32,-(sp)
	bsr.w	song
locret_66F4
	rts

UpdateCwdExcite
	move.w	(CwdExciteLvl).w,d0
	cmp.w	(word_FFB8A4).w,d0
	bls.w	loc_6706
	move.w	d0,(word_FFB8A4).w
loc_6706
	ext.l	d0
	add.l	d0,(dword_FFB8A8).w
	addq.w	#1,(word_FFB8A6).w
	subq.w	#1,(CwdExciteLvl).w
	bpl.w	locret_671C
	clr.w	(CwdExciteLvl).w
locret_671C
	rts

updatecrowdf	;this is called every game loop with d7 = elapsed frames
	;this will update the current frame of crowd animation
	cmpi.w	#$15E,(crowdlevel).w
	blt.w	loc_672C
	subq.w	#3,(crowdlevel).w
loc_672C
	sub.w	d7,(crowdlevel).w
	bpl.w	updatecrowdf_0
	clr.w	(crowdlevel).w
updatecrowdf_0
	sub.w	d7,(word_FFB8A0).w
	bpl.w	updatecrowdf_cf
	move.w	(crowdlevel).w,d0
	lsr.w	#1,d0
	dc.w	$B07C,$007F		;cmp.w	#$7F,d0
	bls.w	updatecrowdf_1
	moveq	#$7F,d0
updatecrowdf_1
	andi.w	#$60,d0
	addq.w	#2,(crowdstep).w
	andi.w	#$1E,(crowdstep).w
	add.w	(crowdstep).w,d0
	movea.l	#cd0,a0
	move.b	0(a0,d0.w),(crowdframe+1).w
	clr.w	d1
	move.b	1(a0,d0.w),d1
	move.w	(VDP_CNTR).l,d2
	and.w	d1,d2
	add.w	d2,d1
	move.w	d1,(word_FFB8A0).w
updatecrowdf_cf
	clr.b	(crowdframe).w
	cmpi.w	#$118,(crowdlevel).w
	bls.w	rtss2
	move.w	(VDP_CNTR).l,d0
	andi.w	#$7F,d0
	dc.w	$B07C,$0013		;cmp.w	#$13,d0
	blt.w	rtss2
	dc.w	$B07C,$0019		;cmp.w	#$19,d0
	bgt.w	rtss2
	move.b	d0,(crowdframe).w
	rts

clockcont	;monitor period clock and initiate various clock activated events
	btst	#0,(gmode).w
	bne.w	rtss2
	tst.w	(gameclock).w
	bne.w	rtss2
	move.w	#4,-(sp)
	bsr.w	sfx
	bsr.w	freezewindow
clockcont_0
	movea.w	#(puckx-M68K_RAM),a3
	move.l	#$18,d0
	bsr.w	assinsert
	cmpi.w	#2,(gsp).w
	blt.w	loc_68AA
	move.l	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	cmpi.w	#3,(gamelevel).w
	bne.w	_t3
	cmpi.w	#7,(bosgames).w
	beq.w	_sc

	moveq	#$10,d3
	mulu.w	(gamenum).w,d3
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d3,a0
	clr.w	d3
	btst	#0,$E(a0)
	beq.w	_nf
	eori.w	#2,d3
_nf
	move.w	(tmstructtmscore).w,d1
	sub.w	(tmstructtmscoretmsize).w,d1
	bpl.w	_ns1
	eori.w	#2,d3
_ns1
	cmpi.w	#3,4(a0,d3.w)
	bne.w	_t3

_sc
	move.l	#8,d0
	moveq	#$B,d2
_t0
	bclr	#3,$62(a3)
	adda.w	#$80,a3
	dbf	d2,_t0
	movea.w	#(SortCords-M68K_RAM),a3
_t3
	moveq	#5,d2
	move.w	(tmstructtmscore).w,d1
	sub.w	(tmstructtmscoretmsize).w,d1
	beq.w	loc_68AA
	bpl.w	_t2
	adda.w	#$300,a3
_t2
	tst.w	$34(a3)
	ble.w	_n2
	bsr.w	assinsert
	move.l	#7,d0
_n2
	adda.w	#$80,a3
	dbf	d2,_t2
_n3
	jsr	(ClearPenaltyBuffer).l
	addi.w	#$3E8,(crowdlevel).w
	addi.w	#$28,(CwdExciteLvl).w
	bset	#0,(gmode).w
	bset	#6,(gmode).w
	move.w	#4,d0
	bra.w	AddPenalty2

loc_68AA
	cmpi.w	#3,(gsp).w
	bne.w	_eop
	tst.w	(OptPlayMode).w
	beq.s	_n3
_eop
	move.w	#2,d0
	bra.w	AddPenalty2
