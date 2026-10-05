;	NHLPA Hockey 93 (retail) segment $10388-$10E65
;	92 hockey.asm part 2, second half: checkfight, SetInst, checkwallcoll,
;	checkgoal, Goal, the 93-only GetPeriodTimeRemaining, checkgoalp,
;	CheckBump, wallcollb, wallcoll and checkpuckcoll.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly, and also the exg a2,a1 encoding.
;	93 SortCords offsets ($80 per object), 92 names in comments where the
;	use matches: Xpos 0, attribute 4, frame 6, Ypos $14, Zpos $18,
;	OldXpos $1C, OldYpos $20, OldZpos $24, Xvel $28, Yvel $2A, Zvel $2C,
;	impactp $2E, impact $32, position $34, assnum $36, asslist $38,
;	Wallcos $4E, Wallsin $50, SCnum $52, facedir $54, nopuck $5E (byte),
;	pflags $62, pflags2 $63, pnum $66 (byte). $74 is a byte fight rating
;	(IDA "fight value").
;	pflags bits match 92 (2 pfnc, 5 pfalock, 6 pfteam, 7 pfgoal). pflags2
;	bit 0 is pf2fight and bit 1 pf2aip; 93 moved the others: bit 2 player
;	unavailable (92 pf2unav = 4), bit 4 caused a penalty (92 pf2pen = 6),
;	bit 5 no player collision (92 pf2npc = 7).
;	SPA values are 93 SPAList offsets, penalty numbers are 93 Penaltylist
;	offsets and sound numbers are 93 sfx numbers; the 92 name in a comment
;	gives the role and the 92 value.
;	93 team struct (tmsize $1A2): $C (Goal adds 1, as 92 tmscore), $22 first
;	sort obj (92 tmsort, a word here), $11C check count per player (byte).

checkfight	;look for start of fight between players a2 & a3. Called from checkcx (hockey93_03)
	;93 needs impact >= 10 on both, no anim lock, no penalty, no goalie, clock
	;running, no highlight and the puck not fighting or on a faceoff. SetInst
	;(both ways) decides, with d0 = 10 + max(0, 40 - ChkCnt)/4. If a3 then has
	;pf2fight, both players start fighting and everyone else watches
	cmpi.w	#$A,$32(a3)		;impact
	blt.w	rtss			;a3 impact < 10
	cmpi.w	#$A,$32(a2)
	blt.w	rtss			;a2 impact < 10
	btst	#5,pflags(a3)		;pfalock
	bne.w	rtss
	btst	#5,pflags(a2)		;pfalock
	bne.w	rtss
	btst	#4,pflags2(a3)		;caused a penalty (92 pf2pen = 6)
	bne.w	rtss
	btst	#4,pflags2(a2)
	bne.w	rtss
	tst.w	$34(a3)			;position
	beq.w	rtss			;no fights with goalies
	tst.w	$34(a2)
	beq.w	rtss
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	btst	#4,(gmode).w		;gmhl
	bne.w	rtss
	btst	#0,(byte_FFB7AD).w	;puckx+pflags2, pf2fight
	bne.w	rtss
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	#(puckx-M68K_RAM),a0
	move.w	$36(a0),d0		;assnum
	cmpi.b	#$1B,$38(a0,d0.w)	;pfaceoff (92 same), asslist
	beq.w	.ex
	moveq	#$28,d0			;40 - ChkCnt
	sub.w	(ChkCnt).w,d0
	bpl.w	.pos
	clr.w	d0
.pos	lsr.w	#2,d0			;IDA: _cont
	addi.w	#$A,d0			;d0 = fight rating needed by SetInst
	bsr.w	SetInst
	exg	a2,a3
	bsr.w	SetInst
	exg	a2,a3
	btst	#0,pflags2(a3)		;pf2fight set by SetInst?
	beq.w	.ex			;no fight
	clr.w	(ChkCnt).w
	moveq	#$19,d0			;26 players per team
	movea.w	#(unk_FFC602-M68K_RAM),a0	;hmtmstruct+$11C, check count per player
.clr	clr.b	$1A2(a0)		;IDA: _loop. away team (tmsize)
	clr.b	(a0)+			;home team
	dbf	d0,.clr
	addi.w	#$3E8,(crowdlevel).w	;add 1000
	addi.w	#$23,(CwdExciteLvl).w
	bclr	#2,(sflags).w		;sfspdir
	bclr	#3,(sflags).w		;sfssdir
	move.w	$52(a3),(puckc).w	;SCnum
	move.w	Ypos(a3),d1		;93 sets only yc1 (92 also set a clamped xc1)
	add.w	Ypos(a2),d1
	asr.w	#1,d1
	move.w	d1,(yc1).w
	bset	#6,(sflags).w		;sfslock
	moveq	#2,d1			;make the players face each other
	move.w	(a3),d0
	cmp.w	(a2),d0
	blt.w	.1
	eori.w	#7,d1			;d1 = 5
.1	move.w	d1,$54(a3)		;IDA: _o1. facedir
	eori.w	#7,d1
	move.w	d1,$54(a2)
	move.l	a3,-(sp)
	bsr.w	.sf
	exg	a2,a3
	bsr.w	.sf
	movea.w	#(SortCords-M68K_RAM),a3
	move.l	#$15,d0			;afwatch (92 same), other players watch fight
	moveq	#$B,d1
.0	btst	#0,pflags2(a3)		;pf2fight
	bne.w	.next
	tst.w	$34(a3)			;goalie
	beq.w	.next
	btst	#2,pflags2(a3)		;unavailable (92 pf2unav = 4)
	bne.w	.next
	bsr.w	assinsert
.next	adda.w	#SCstruct,a3
	dbf	d1,.0
	movea.w	#(puckx-M68K_RAM),a3
	bset	#0,pflags2(a3)		;pf2fight
	move.l	#$1A,d0			;pnothing (92 same)
	bsr.w	assinsert
	st	(collflag).w
	movea.l	(sp)+,a3
.ex	movem.l	(sp)+,d0-d4/a0-a3
	rts

.sf	move.w	$52(a2),$2E(a3)		;IDA: checkfight_sf. start fight for a3 against a2. SCnum to impactp (92 called SetInst first here)
	move.l	#$26,d0			;penalty $26 (92 PenFighting = $20)
	bsr.w	AddPenalty2
	move.w	$52(a3),d0		;SCnum
	bsr.w	setd0player
	move.l	#$14,d0			;afight (92 same)
	bsr.w	assinsert
	bclr	#3,attribute(a3)
	move.w	#$FC00,d1		;Xvel -$400
	cmpi.w	#2,$54(a3)		;facedir 2?
	beq.w	.sf2
	bset	#3,attribute(a3)		;flip the other way
	neg.w	d1
.sf2	move.w	d1,Xvel(a3)
	bset	#2,pflags2(a3)		;unavailable (92 pf2unav = 4)
	bset	#1,pflags2(a3)		;pf2aip
	bset	#5,pflags2(a3)		;no player coll (92 pf2npc = 7)
	bclr	#5,pflags(a3)		;pfalock
	move.w	#$F8E,d1		;SPA $F8E (92 SPAfight = $DE8)
	bra.w	SetSPA

SetInst	;93: d0 = fight rating a3 needs. Called twice from checkfight (a2/a3 swapped)
	;Returns unless a3's fight rating ($74) >= d0, a2's >= 2 and a2's >= $10 -
	;2 * a2's check count ($11C in its team struct). Then sets pf2fight on a2
	;and a3. If a3 was not already fighting, OptPen is not 0 and HV counter & 3
	;is 0, calls AddPenalty2 with penalty $2A (92 PenInst = $22) and a3 = the
	;first skater on a3's team (not a3) that has no penalty and is available.
	;a3 is restored. 92 SetInst only did that last part, for a shoulder check SPA
	cmp.b	$74(a3),d0
	bhi.w	rtss			;a3 fight rating < d0
	cmpi.b	#2,$74(a2)
	blt.w	rtss			;a2 fight rating < 2
	clr.w	d1
	move.b	$66(a2),d1		;pnum
	movea.w	#(hmtmstruct-M68K_RAM),a0
	btst	#6,pflags(a2)		;pfteam
	beq.w	.tm
	adda.w	#$1A2,a0		;tmsize
.tm	adda.w	d1,a0			;IDA: loc_10594
	move.b	$11C(a0),d1		;a2 check count
	asl.b	#1,d1
	neg.b	d1
	addi.b	#$10,d1			;d1 = $10 - 2 * check count
	cmp.b	$74(a2),d1
	bgt.w	rtss			;a2 fight rating < d1
	bset	#0,pflags2(a2)		;pf2fight
	bset	#0,pflags2(a3)		;pf2fight
	bne.w	rtss			;a3 was already fighting
	tst.w	(OptPen).w
	beq.w	rtss
	move.w	(VDP_CNTR).l,d0		;HV counter (92 HVcount)
	andi.w	#3,d0
	bne.w	rtss			;3 of 4 times no penalty
	movea.l	a3,a4
	moveq	#5,d0
	movea.w	#(SortCords-M68K_RAM),a3
	btst	#6,pflags(a4)		;pfteam
	beq.w	.1
	adda.w	#6*SCstruct,a3
.1	cmpa.w	a3,a4			;IDA: _playerloop
	beq.w	.next
	tst.w	$34(a3)			;position
	ble.w	.next
	btst	#4,pflags2(a3)		;caused a penalty (92 pf2pen = 6)
	bne.w	.next
	btst	#2,pflags2(a3)		;unavailable (92 pf2unav = 4)
	bne.w	.next
	move.w	#$2A,d0			;penalty $2A (92 PenInst = $22)
	bsr.w	AddPenalty2
	movea.l	a4,a3
	rts
.next	adda.w	#SCstruct,a3			;IDA: _endloop
	dbf	d0,.1
	movea.l	a4,a3
	rts

checkwallcoll	;d2/d3 = x/y to test, a3 = object, wcradiusx/wcradiusy = radius. Called from checkcoll (hockey93_03)
	;Check the corner circles, the goals and then the side and end boards.
	;Calls wallcollb (or checkgoal) on a hit, with d0/d1 = cos/sin of the wall
	move.w	#$88,d4			;92 Sideline (a RAM word); 93 uses 136
	sub.w	(wcradiusx).w,d4
	move.w	#$12A,d5		;92 Blueline + .ywall (210); 93 uses 298
	sub.w	(wcradiusy).w,d5
	movem.w	d2-d5,-(sp)
	neg.w	d4
	neg.w	d5
	addi.w	#$40,d4			;.radius = 64, radius of the rink corners
	addi.w	#$40,d5
	cmp.w	d5,d3
	bgt.w	.ctc			;not in the -y end zone
	cmp.w	d4,d2
	blt.w	.circle
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.circle
	movea.w	#(unk_FFB6CA-M68K_RAM),a2	;SortCords+(13*SCstruct), goal at the -y end
	bsr.w	checkgoal
	bra.w	.exit
.ctc	neg.w	d5
	cmp.w	d5,d3
	blt.w	.exit			;between the end zones
	cmp.w	d4,d2
	blt.w	.circle
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.circle
	movea.w	#(SortCordsSCStructCalc-M68K_RAM),a2	;SortCords+(12*SCstruct), goal at the +y end
	bsr.w	checkgoal
	bra.w	.exit
.circle	sub.w	d4,d2
	sub.w	d5,d3
	move.w	d3,d0			;cos0 = dy/r
	move.w	d2,d1			;sin0 =-dx/r
	neg.w	d1
	muls.w	d3,d3
	muls.w	d2,d2
	add.l	d2,d3			;dist from dot
	cmp.l	#$1000,d3		;.radius*.radius
	bls.w	.exit
	exg	d0,d3
	bsr.w	sroot
	exg	d0,d3
	ext.l	d0
	asl.l	#8,d0
	divs.w	d3,d0
	ext.l	d1
	asl.l	#8,d1
	divs.w	d3,d1
	bsr.w	wallcollb
.exit	movem.w	(sp)+,d2-d5
	move.w	$4E(a3),d0		;Wallcos
	or.w	$50(a3),d0		;Wallsin
	bne.w	rtss
	move.w	#$100,d0		;now check side walls
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

checkgoal	;look for coll with goal/net. a2 = goal struct, a3 = object, d2/d3 = x/y. Called from checkwallcoll
	;Not the puck: checkgoalp. Puck inside the goal area: over the top (bounce
	;Zvel), through the mouth (Goal), off a post (deflect) or off the side/back
	;(wallcoll)
	cmpi.w	#$D,Zpos(a3)		;.zside = 13, height of goal. Zpos
	bgt.w	rtss			;over goal
	cmpi.w	#$E,$52(a3)		;puckSCnum
	bne.w	checkgoalp		;coll with player not puck
	sub.w	(a2),d2			;Xpos
	moveq	#$10,d4			;.xside = 16, width of goal/2
	add.w	(wcradiusx).w,d4
	cmp.w	d4,d2
	bgt.w	rtss
	neg.w	d4
	cmp.w	d4,d2
	blt.w	rtss
	sub.w	Ypos(a2),d3
	move.w	#2,d5			;.yside = 2, depth of goal/2
	add.w	(wcradiusy).w,d5
	cmp.w	d5,d3
	bgt.w	rtss
	neg.w	d5
	cmp.w	d5,d3
	blt.w	rtss
;inside goal area now
	st	(collflag).w
	cmpi.w	#$D,$24(a3)		;.zside, OldZpos
	blt.w	.nod
	move.w	$24(a3),Zpos(a3)		;OldZpos to Zpos
	bra.w	.deflectz
.nod	bclr	#7,pflags(a3)		;IDA: loc_1074A. pfgoal
	move.w	(puckc).w,d0
	bmi.w	.nocon			;no puck carrier
	st	(puckc).w
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	move.b	#8,$5E(a0,d0.w)		;nopuck (92 wrote a word)
	move.w	(pucky).w,d1
	btst	#7,pflags(a0,d0.w)		;pfgoal of the carrier
	bne.w	.an
	neg.w	d1
.an	tst.w	d1			;IDA: loc_10778
	bpl.w	.nocon
	bset	#7,pflags(a3)		;pfgoal
.nocon	move.w	#$FF00,d0		;IDA: loc_10784. -256
	move.l	Ypos(a3),d1
	sub.l	$20(a3),d1		;OldYpos
	asr.l	#8,d1
	beq.w	.sideentry
	bmi.w	.0
	neg.w	d0			;check top entry
	neg.w	d5
.0	add.w	d3,d5			;IDA: loc_1079E. dy
	move.l	(a3),d3			;Xpos
	sub.l	$1C(a3),d3		;OldXpos
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
	btst	#7,pflags(a3)		;pfgoal
	bne.w	wallcoll
	cmpi.w	#$D,Zpos(a3)		;.zside, Zpos
	beq.w	.deflectsf
	subq.w	#1,d4			;mouth = half width - 1 (92 sub #5)
	cmp.w	d4,d2
	bgt.w	.deflectsf
	neg.w	d4
	cmp.w	d4,d2
	bge.w	Goal
.deflectsf	bsr.w	ChkShotStat		;IDA: loc_107F2. off the post
	move.w	#$25,-(sp)		;sfx $25 when the clock is stopped (92 SFXpuckpost = 9)
	btst	#0,(gmode).w		;gmclock
	bne.w	.snd
	move.w	#8,(sp)			;sfx 8 (92 SFXoooh = 31) and crowd
	addi.w	#$12C,(crowdlevel).w	;add 300
	addi.w	#$28,(CwdExciteLvl).w
.snd	bsr.w	sfx			;IDA: loc_10814
	move.w	#$1000,d0
	bsr.w	randomd0
	tst.w	Ypos(a3)
	bmi.w	.df0
	neg.w	d0
.df0	move.w	d0,$2A(a3)		;IDA: loc_1082A. Yvel
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,$2C(a3)		;Zvel
	bra.w	puckflip
.deflectz	neg.w	$2C(a3)		;IDA: loc_1084A. Zvel
	bpl.w	rtss
	neg.w	$2C(a3)
	rts
.sideentry	clr.w	d0		;IDA: loc_10858
	move.w	#$100,d1
	move.w	(a3),d2			;Xpos
	sub.w	$1C(a3),d2		;OldXpos
	bmi.w	wallcoll
	neg.w	d1
	bra.w	wallcoll

Goal	;puck in goal. a3 = puck. Entered from checkgoal
	;93: new song, sfx 0, score +1 for the scoring team (a2, a1 = the other
	;team), song $30 if the home team scored, a 6 byte ScoreSum entry,
	;goal/assist counts, PenGoalStuff, printscores1, new assignments for the
	;scoring team, puck into the net, siren SPA and penalty $E
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	bsr.w	ChkShotStat
	bsr.w	play_new_song		;93 only
	move.w	#0,-(sp)		;SFXsiren (92 same, 0)
	bsr.w	sfx
	bsr.w	freezewindow
	addi.w	#$1F4,(crowdlevel).w	;add 500 (92 800)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	$1A2(a2),a1		;tmsize
	tst.w	Ypos(a3)
	bpl.w	.g0
	exg	a2,a1
.g0	btst	#1,(gmode).w		;gmdir
	beq.w	.g1
	exg	a2,a1
.g1	addq.w	#1,$C(a2)		;92 tmscore
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	bne.w	.nocheer
	move.w	#$30,-(sp)		;song $30 (92 SFX with SFXcrowdcheer = 25)
	bsr.w	song
.nocheer	cmpi.w	#$B4,(ScoreSumbytes).w	;30 entries of 6 bytes full?
	bne.w	.sum
	subq.w	#6,(ScoreSumbytes).w	;overwrite the last entry
.sum	movea.w	#(ScoreSum-M68K_RAM),a0	;IDA: loc_108D2
	adda.w	(ScoreSumbytes).w,a0
	addq.w	#6,(ScoreSumbytes).w
	bsr.w	GetPeriodTimeRemaining
	move.w	d0,(a0)+		;entry word 0 = period/time
	moveq	#2,d0
	add.w	$24(a2),d0
	sub.w	$24(a1),d0
	move.b	d0,(a0)+		;byte 2 = 2 + $24(a2) - $24(a1)
	addi.w	#$1E,(CwdExciteLvl).w
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	beq.w	.home
	subi.w	#$14,(CwdExciteLvl).w	;less for an away goal
	bset	#7,-1(a0)		;byte 2 bit 7 = away team scored
.home	move.w	$18(a2),d0		;IDA: loc_1090A. scorer
	move.b	d0,(a0)+		;byte 3
	move.w	#$FFFF,(a0)		;no assists yet
	addi.w	#$B4,d0
	addq.b	#1,(a2,d0.w)		;team byte $B4 + scorer +1
	move.w	$1A(a2),d0		;first assist
	bmi.w	.noast
	move.b	d0,(a0)+		;byte 4
	addi.w	#$CE,d0
	addq.b	#1,(a2,d0.w)		;team byte $CE + player +1
	move.w	$1C(a2),d0		;second assist
	bmi.w	.noast
	move.b	d0,(a0)			;byte 5
	addi.w	#$CE,d0
	addq.b	#1,(a2,d0.w)
.noast	move.w	$26(a1),d0		;IDA: loc_10940
	bmi.w	.pen
	addi.w	#$B4,d0
	addq.b	#1,(a1,d0.w)		;other team byte $B4 + $26(a1) +1
.pen	bsr.w	PenGoalStuff		;IDA: loc_10950
	bsr.w	printscores1
	move.l	#7,d0			;assignment 7 (92 ascore = 8)
	bsr.w	.setass
	clr.w	(collflag).w
	clr.w	Xvel(a3)
	clr.w	$2A(a3)			;Yvel
	moveq	#6,d0
	tst.w	(a3)			;Xpos
	bpl.w	.1
	neg.w	d0
.1	move.w	d0,(a3)			;IDA: loc_10978. Xpos
	move.w	#$110,d0		;92 blueline+goalline+8
	tst.w	Ypos(a3)
	bpl.w	.0
	neg.w	d0
.0	move.w	d0,Ypos(a3)		;IDA: loc_10988
	move.w	#$600,$2C(a3)		;Zvel
	clr.w	Zpos(a3)
	st	(puckcrossPlus2).w	;puckcross+2
	st	(puckcrossPlus6).w	;puckcross+6
	bset	#2,pflags(a3)		;pfnc
	move.w	#$1A,d0			;pnothing (92 same)
	bsr.w	assreplace
	move.l	a3,-(sp)
	adda.w	#SCstruct,a3
	move.w	#$11E8,d1		;SPA $11E8 (92 SPAsiren = $FE8)
	bsr.w	SetSPA
	movea.w	$22(a1),a3		;first sort obj of the other team (92 used the puck)
	move.l	#$E,d0			;penalty $E (92 PenGoal = 6)
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts

.setass	move.l	a3,-(sp)		;IDA: ResetTeamPlayerAssignments. d0 = assignment, a2 = team
	;give each skater of team a2 that is not fighting assignment d0, clear pfnc
	movea.w	$22(a2),a3		;92 tmsort (a long)
	moveq	#5,d3
.loop	tst.w	$34(a3)			;IDA: loc_109D4. position
	ble.w	.nl
	btst	#0,pflags2(a3)		;pf2fight
	bne.w	.nl
	bclr	#2,pflags(a3)		;pfnc
	bsr.w	assinsert
.nl	adda.w	#SCstruct,a3			;IDA: loc_109F0
	dbf	d3,.loop
	movea.l	(sp)+,a3
	rts

GetPeriodTimeRemaining	;93: return d0 = (gsp << 14 | PerTimeTotal) - gameclock. Called from Goal (ScoreSum entry) and InProgress (penalty93_1)
	move.w	(gsp).w,d0
	swap	d0
	clr.w	d0
	lsr.l	#2,d0			;gsp in bits 14-15
	or.w	(PerTimeTotal).w,d0
	sub.w	(gameclock).w,d0
	rts

checkgoalp	;check for player a3 collision with goal/net a2. Entered from checkgoal
	;oval goal, .radiusx = 32, .radiusy = 11. Skipped for no player coll,
	;Zpos > 10 and non players. Calls CheckBump, then wallcoll with the normal
	btst	#5,pflags2(a3)		;no player coll (92 pf2npc = 7)
	bne.w	rtss
	cmpi.w	#$A,Zpos(a3)
	bgt.w	rtss
	cmpi.w	#$B,$52(a3)		;SCnum
	bgt.w	rtss			;not a player
	movem.w	d2-d3,-(sp)
	sub.w	Ypos(a2),d3
	move.w	d3,d0			;cos0 =-dy/r
	sub.w	(a2),d2			;Xpos
	move.w	d2,d1			;sin0 = dx/r
	neg.w	d0
	asl.w	#4,d2
	muls.w	d2,d2
	divu.w	#$400,d2		;.radiusx*.radiusx
	cmp.w	#$100,d2
	bhi.w	.exit
	asl.w	#4,d3
	muls.w	d3,d3
	divu.w	#$79,d3			;.radiusy*.radiusy
	add.w	d2,d3
	cmp.w	#$100,d3
	bhi.w	.exit			;outside the oval
	movem.w	(sp)+,d2-d3
	bsr.w	CheckBump
	movem.w	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	sroot
	move.w	d0,d2
	movem.w	(sp)+,d0-d1
	addq.w	#1,d2
	asl.l	#8,d0
	divs.w	d2,d0
	asl.l	#8,d1
	divs.w	d2,d1
	bsr.w	wallcoll
.exit	movem.w	(sp)+,d2-d3
	rts

CheckBump	;supply minimum separation velocity for coll with walls/goal/net. a2 = goal, a3 = player. Called from checkgoalp
	;When HV counter & $1F is 0 (92 & $F), the puck is within 40 y of the goal
	;and a3 is faster than $2000 in x or y: a quarter of a3's velocity goes to
	;the goal, a3 stops, and if the clock runs penalty 8. That path returns
	;straight to checkgoalp's caller
	movem.l	d0-d1,-(sp)
	move.w	(VDP_CNTR).l,d0		;HV counter (92 HVcount)
	andi.w	#$1F,d0
	bne.w	.ex
	move.w	(pucky).w,d0
	sub.w	Ypos(a2),d0
	cmp.w	#$28,d0			;40
	bgt.w	.ex
	cmp.w	#$FFD8,d0		;-40
	blt.w	.ex
	move.w	Xvel(a3),d0
	move.w	$2A(a3),d1		;Yvel
	cmp.w	#$2000,d0		;.minv
	bgt.w	.bb
	cmp.w	#$E000,d0		;-.minv
	blt.w	.bb
	cmp.w	#$2000,d1
	bgt.w	.bb
	cmp.w	#$E000,d1
	blt.w	.bb
.ex	movem.l	(sp)+,d0-d1
	rts
.bb	adda.w	#$C,sp			;drop d0-d1 and the return to checkgoalp
	asr.w	#2,d0
	asr.w	#2,d1
	move.w	d0,Xvel(a2)
	move.w	d1,$2A(a2)		;Yvel
	clr.w	Xvel(a3)
	clr.w	$2A(a3)
	bset	#6,(sflags).w		;sfslock
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	move.l	#8,d0			;penalty 8 (92 Penghold = $E)
	bra.w	AddPenalty2

wallcollb	;check for puck over wall. a3 = object, d0/d1 = cos/sin of the wall. Called from checkwallcoll
	;Not the puck: wallcoll. Zpos > 29, or Zpos > 18 with Ypos < 280, goes
	;over: pfnc, scroll lock, frame of the next struct cleared and, if the
	;clock runs, penalty 6 for ltplayer. 93 adds: Ypos >= 280, Xpos 13-15 and
	;Yvel >= $FA0 halves Yvel, starts SPA $1232 on the next struct with sfx $E
	;and crowd, then goes over
	cmpi.w	#$E,$52(a3)		;puckSCnum
	bne.w	wallcoll		;not puck so wall coll
	cmpi.w	#$1D,Zpos(a3)		;Zpos (92 12*8/3 = 32)
	bgt.w	.0
	cmpi.w	#$12,Zpos(a3)		;Zpos (92 8*8/3 = 21)
	bls.w	wallcoll
	cmpi.w	#$118,Ypos(a3)		;Ypos 280 (92 274, checked first)
	blt.w	.0
	cmpi.w	#$D,(a3)		;Xpos
	blt.w	wallcoll
	cmpi.w	#$F,(a3)
	bgt.w	wallcoll
	cmpi.w	#$FA0,$2A(a3)		;Yvel
	blt.w	wallcoll
	move.l	a3,-(sp)
	asr.w	$2A(a3)			;halve Yvel
	adda.w	#SCstruct,a3
	move.w	#$1232,d1		;SPA $1232 (93 only)
	bsr.w	SetSPA
	movea.l	(sp)+,a3
	move.w	#$E,-(sp)		;sfx $E
	bsr.w	sfx
	addi.w	#$258,(crowdlevel).w	;add 600
	addi.w	#$F,(CwdExciteLvl).w
.0	bset	#6,(sflags).w		;sfslock
	bset	#2,pflags(a3)		;pfnc
	tst.w	Ypos(a3)
	bpl.w	.1
	ori.w	#$8000,attribute(a3)
.1	clr.w	$86(a3)			;frame+SCstruct
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	move.l	a3,-(sp)
	move.w	(ltplayer).w,d0
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.l	#6,d0			;penalty 6 (92 PenOOP = $C)
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts

wallcoll	;d0 = cosine, d1 = sine of angle of incidence with wall, a3 = object. Called from checkgoal, checkgoalp, wallcollb
	;Bounce a3 off the wall: the puck loses speed, flips and plays sfx $28-$2B,
	;a player plays sfx $20 on a hard hit
	move.w	d0,$4E(a3)		;Wallcos
	move.w	d1,$50(a3)		;Wallsin
	movem.l	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	$2A(a3),d0		;Yvel
	muls.w	Xvel(a3),d1
	sub.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d2			;v1n
	movem.w	(sp),d0-d1
	muls.w	Xvel(a3),d0
	muls.w	$2A(a3),d1
	add.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d3			;v1t
	neg.w	d2
	cmpi.w	#$E,$52(a3)		;puckSCnum
	bne.w	.player
	bclr	#4,(sflags2).w		;sf2shot
	tst.w	d2
	bpl.w	.nocoll
	asr.w	#2,d2			;reduce normal speed on puck
	cmp.w	#$FC00,d2		;-$400
	bgt.w	.pok
	move.w	#$800,d0
	bsr.w	randomd0
	neg.w	d0
	move.w	d0,$2C(a3)		;Zvel
	bsr.w	puckflip
	move.w	d2,d0			;93: sfx $28 + ((v1n >> 10) + 4) & 3 (92 SFXpuckwall1-3 by speed)
	asr.w	#8,d0
	asr.w	#2,d0
	addq.w	#4,d0
	bpl.w	.sf0
	clr.w	d0
.sf0	andi.w	#3,d0
	addi.w	#$28,d0
	move.w	d0,-(sp)
	bsr.w	sfx
.pok	move.w	d3,d0			;reduce tangent speed on puck
	asr.w	#6,d0
	sub.w	d0,d3
	asr.w	#1,d0
	sub.w	d0,d3
	bra.w	.noadd
.player	cmp.w	#$3E8,d2		;1000
	bgt.w	.nocoll
	cmp.w	#$F000,d2		;-$1000
	bgt.w	.nosfx
	cmpi.w	#$A,$32(a3)		;impact
	blt.w	.nosfx
	move.w	#$20,-(sp)		;sfx $20 (92 SFXplayerwall = 15)
	bsr.w	sfx
.nosfx	asr.w	#2,d2
	cmp.w	#$FC7C,d2		;-900
	blt.w	.noadd
	move.w	#$FC18,d2		;-1000
.noadd	movem.w	(sp),d0-d1
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
	move.w	d3,$2A(a3)		;Yvel
	tst.w	$2C(a3)			;Zvel
	bmi.w	.nocoll
	clr.w	$2C(a3)
.nocoll	addq.w	#4,sp
	movem.l	(sp)+,d2-d3
	rts

checkpuckcoll	;look for puck coll with players. a3 = puck. Entered from pucknorm (logic93_4)
	;93 first clears Yvel when Ypos > 400 or Ypos <= -400. Walks up and down
	;the OOlist from the puck and runs .ccx on each object within 22 in y:
	;stick (puckstick), body (puckbody) or goalie (puckgoalie)
	cmpi.w	#$190,Ypos(a3)		;Ypos 400
	bgt.w	.clrvy
	cmpi.w	#$FE70,Ypos(a3)		;-400
	bgt.w	.chkz
.clrvy	clr.w	$2A(a3)			;IDA: _resetYvel. Yvel
.chkz	cmpi.w	#$10,Zpos(a3)		;IDA: _setup. Zpos, 6*8/3 = 16
	bgt.w	rtss			;feet in air
	move.w	$52(a3),d0		;SCnum
	asl.w	#1,d0			;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1		;current objects pos in OOlist
.0	cmp.w	#$F,d1			;sortobjs-1
	beq.w	.cl			;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4		;next higher object number
	move.w	(a2,d4.w),d5		;y pos of next higher object
	sub.w	Ypos(a3),d5
	cmp.w	#$16,d5			;.cbody+.cstick
	bgt.w	.cl			;no higher sprite coll
	bsr.w	.ccx
	addq.w	#1,d1
	bra.s	.0
.cl	move.w	(a0,d0.w),d1
	beq.w	.ex
.1	clr.w	d4
	move.b	-1(a1,d1.w),d4		;next lower object number
	move.w	Ypos(a3),d5
	sub.w	(a2,d4.w),d5		;y pos of next lower object
	cmp.w	#$16,d5			;.cbody+.cstick
	bgt.w	.ex
	bsr.w	.ccx
	subq.w	#1,d1
	bne.s	.1
.ex	rts
.ccx	movem.l	d0-d7/a0-a3,-(sp)	;d4 = object number * 2
	lsr.w	#1,d4
	cmp.w	(puckc).w,d4
	beq.w	.exit			;puck carrier
	cmp.w	#$B,d4
	bgt.w	.exit			;not a player
	asl.w	#7,d4			;scsize
	movea.w	#(SortCords-M68K_RAM),a2
	adda.w	d4,a2
	btst	#2,pflags(a2)		;pfnc
	bne.w	.exit			;object has no coll mode on
	tst.b	$5E(a2)			;nopuck
	bne.w	.exit
	btst	#2,pflags2(a2)		;unavailable (92 pf2unav = 4)
	bne.w	.chkbody
	cmpi.w	#5,Zpos(a3)		;Zpos, 2*8/3 = 5
	bgt.w	.chkbody
	cmpi.w	#$200,$2C(a3)		;Zvel (92 $100)
	bgt.w	.chkbody
	move.l	a2,-(sp)
	bsr.w	GetHot
	add.w	(a2),d0			;Xpos
	sub.w	(a3),d0
	cmp.w	#$E,d0			;.cstick = 14
	bgt.w	.chkbody
	cmp.w	#$FFF2,d0		;-.cstick
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
	move.l	#$C4,d1			;.cstick*.cstick
	tst.b	$5E(a3)			;nopuck. puck is not ready to be caught
	ble.w	.lo
	lsr.w	#2,d1
.lo	cmp.l	d1,d0
	bhi.w	.chkbody
	bsr.w	puckstick
	bra.w	.exit
.chkbody	tst.w	$34(a2)		;position
	beq.w	.chkgoalie
	move.w	(a2),d0			;Xpos
	sub.w	(a3),d0
	cmp.w	#8,d0			;.cbody = 8
	bgt.w	.exit
	cmp.w	#$FFF8,d0		;-.cbody
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
	cmp.l	#$40,d0			;.cbody*.cbody
	bhi.w	.exit
	bsr.w	puckbody
.exit	movem.l	(sp)+,d0-d7/a0-a3
	rts
.chkgoalie	move.w	(a2),d0		;Xpos
	sub.w	(a3),d0
	cmp.w	#$C,d0			;.cbg = 12
	bgt.s	.exit
	cmp.w	#$FFF4,d0		;-.cbg
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
	cmp.l	#$90,d0			;.cbg*.cbg
	movem.w	(sp)+,d0-d1
	bhi.s	.exit
	bsr.w	puckgoalie
	bra.s	.exit
