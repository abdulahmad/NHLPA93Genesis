;	NHLPA Hockey 93 (retail) segment $C9EA-$D629
;	92 Logic.Asm part 5: ChkOffsides, a2offsides, a2touchpuck, PuckIChk,
;	puckunflip, puckflip, puckshadow, findpc, skateto, avdgoal,
;	skatetopuck, assexit, assinsert, assreplace, vtoa, GetHot, SetSPA,
;	doplayeracc, goalieacc, noturn0, noturn, playeracc, MaxSpeed, dostop,
;	stopna, dirtab, then the 93-only UnpackNibbles and
;	WeightedRandomSelect. Global names from the IDA export, 92 names
;	where the routine is the same (see the SEGMENT_AGENT.md rename
;	table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	93 SortCords offsets, 92 names in comments: Xpos 0, attribute 4,
;	frame 6, Ypos $14, Zpos $18, OldYpos $20, Xvel $28, Yvel $2A,
;	position $34, assnum $36, asslist $38, temp2 $42, wallcos $4E,
;	wallsin $50, SCnum $52, facedir $54, SPA $58, SPAnum $5A, SPAcnt $5C,
;	pflags $62 (pfna 1, pfrev 4, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2fight 0, pf2aip 1), pnum $66, weight $67, legstr $68, legspd $69.
;	Team struct (hmtmstruct, tmsize $1A2): $18/$1A/$1C last touches (93),
;	tmsort $22, tmap $24, tmflags $30 (bit 4 = team offsides, 93).
;	iflags: ifcgl 0, ifdir 1, ifok 2; icingPlayer = 92 iflags+1.

ChkOffsides	;check for offsides penalty. a3 = puck. 93 flags the whole team (tmflags bit 4), 92 flagged each player (pf3oside). Called from pucknorm
	btst	#gmoffs,(gmode).w
	beq.w	rtss
	movea.w	#(hmtmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2		;team 2 (tmsize)
	bsr.w	ClearOffsidesIfAllPlayers
	exg	a1,a2
	bsr.w	ClearOffsidesIfAllPlayers
	move.w	#$54,d0			;blueline-4 (92 move blueline,d0 / sub #4,d0)
	cmp.w	Ypos(a3),d0
	bgt.w	.neg
	cmp.w	OldYpos(a3),d0		;OldYpos: puck crossed the top line this frame?
	ble.w	rtss
	addi.w	#$A,d0
	btst	#gmdir,(gmode).w
	beq.w	.t0
	exg	a2,a1
.t0	moveq	#5,d2			;IDA: loc_CA42
	movea.w	tmsort(a2),a0		;tmsort: first player of the team
.0	tst.w	position(a0)			;IDA: loc_CA48. position: skip off ice
	bmi.w	.1
	cmp.w	Ypos(a0),d0
	bge.w	.1
	bset	#4,tmflags(a2)		;player past the line: team offsides
	rts
.1	adda.w	#SCstruct,a0			;IDA: loc_CA60
	dbf	d2,.0
	rts

.neg	neg.w	d0			;IDA: loc_CA6A
	cmp.w	Ypos(a3),d0
	blt.w	rtss
	cmp.w	OldYpos(a3),d0		;OldYpos: puck crossed the bottom line this frame?
	bge.w	rtss
	subi.w	#$A,d0
	btst	#gmdir,(gmode).w
	bne.w	.t1
	exg	a2,a1
.t1	moveq	#5,d2			;IDA: loc_CA8C
	movea.w	tmsort(a2),a0
.2	tst.w	position(a0)			;IDA: loc_CA92
	bmi.w	.3
	cmp.w	Ypos(a0),d0
	ble.w	.3
	bset	#4,tmflags(a2)		;team offsides
	rts
.3	adda.w	#SCstruct,a0			;IDA: loc_CAAA
	dbf	d2,.2
	rts

ClearOffsidesIfAllPlayers	;93: a2 = team struct. Clears the team offsides flag (tmflags bit 4) once no skater on ice is past the blue line ($58, sign by pfgoal). Called twice from ChkOffsides
	btst	#4,tmflags(a2)
	beq.w	rtss
	movea.w	tmsort(a2),a0
	moveq	#5,d1
.top	tst.w	position(a0)			;IDA: loc_CAC4. position: off ice keeps the last d0
	bmi.w	.next
	move.w	Ypos(a0),d0
	btst	#pfgoal,pflags(a0)
	bne.w	.next
	neg.w	d0
.next	adda.w	#SCstruct,a0			;IDA: loc_CADC
	cmp.w	#$58,d0		;(blueline)
	dbgt	d1,.top
	bgt.w	rtss			;someone still past the line
	bclr	#4,tmflags(a2)
	rts

a2offsides	;player a2 touched the puck: offsides penalty if his team is flagged and the puck is past the blue line. Called from a2touchpuck
	btst	#gmoffs,(gmode).w		;93 only
	beq.w	rtss
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a2)
	bne.w	.0
	neg.w	d0
.0	cmp.w	#$58,d0		;IDA: loc_CB0E (92 cmp blueline,d0)
	blt.w	rtss
	movea.w	#(hmtmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a2)
	beq.w	.1
	adda.w	#tmsize,a0
.1	btst	#4,tmflags(a0)		;IDA: loc_CB28. team offsides flag (92 pf3oside loop over the players)
	beq.w	rtss
	btst	#gmhl,(gmode).w
	bne.w	rtss
	exg	a2,a3
	move.l	#$10,d0			;PenOffsides
	bsr.w	AddPenalty
	exg	a2,a3
	rts

a2touchpuck	;player a2 touches puck. Look for penalties/offsides/other junk. Called from pucknorm, puckstick and others
	move.w	(a2),(ltx).w		;Xpos
	move.w	Ypos(a2),(lty).w
	move.w	SCnum(a2),(ltplayer).w
	movea.w	#(hmtmstruct-M68K_RAM),a0	;93: keep the last three touches per team
	btst	#pfteam,pflags(a2)
	beq.w	.t
	lea	tmsize(a0),a0
.t	clr.w	d0			;IDA: loc_CB6E
	move.b	pnum(a2),d0
	cmp.w	$18(a0),d0		;same player as the last touch: no change
	beq.w	.same
	bclr	#3,tmflags(a0)		;tmflags bit 3 set: overwrite the last touch only
	bne.w	.st
	move.w	$1A(a0),$1C(a0)		;shift the touch list down
	move.w	$18(a0),$1A(a0)
.st	move.w	d0,$18(a0)		;IDA: loc_CB92
	cmp.w	$1C(a0),d0
	bne.w	.same
	st	$1C(a0)			;player was also the third touch: drop it
.same	bclr	#sf2shot,(sflags2).w		;IDA: loc_CBA2
	bsr.w	a2offsides
	btst	#2,(iflags).w		;ifok
	beq.w	.notice
	btst	#0,(iflags).w		;ifcgl
	beq.w	.notice
	tst.w	position(a2)
	beq.w	.notice
	btst	#1,(iflags).w		;ifdir
	bne.w	.up
	btst	#pfgoal,pflags(a2)
	beq.w	.notice
.icing	clr.w	d0			;IDA: loc_CBDC
	move.b	(icingPlayer).w,d0	;92 iflags+1
	asl.w	#7,d0			;scsize
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.w	#$C,d0			;PenIcing
	bsr.w	AddPenalty
	movea.l	(sp)+,a3
	rts
.up	btst	#pfgoal,pflags(a2)		;IDA: loc_CBF8
	beq.s	.icing
.notice	clr.b	(iflags).w		;IDA: loc_CC00
	move.b	SCnum+1(a2),(icingPlayer).w
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a2)
	beq.w	.0
	bset	#1,(iflags).w		;ifdir
	neg.w	d0
.0	bmi.w	rtss			;IDA: loc_CC20
	move.w	(hmtmstruct+tmap).w,d0
	sub.w	(awtmstruct+tmap).w,d0
	btst	#pfteam,pflags(a2)
	beq.w	.1
	neg.w	d0
.1	bmi.w	rtss			;IDA: loc_CC38
	bset	#2,(iflags).w		;ifok
	rts

puckIChk	;check for icing of puck penalty. Called from pucknorm
	btst	#2,(iflags).w		;ifok
	beq.w	rtss
	btst	#0,(iflags).w		;ifcgl
	bne.w	rtss
	tst.w	(puckc).w
	bpl.w	rtss
	move.w	#$108,d0		;blueline+goalline
	btst	#1,(iflags).w		;ifdir
	bne.w	.0
	neg.w	d0
	cmp.w	(pucky).w,d0
	bgt.w	.chkx
	rts
.0	cmp.w	(pucky).w,d0		;IDA: loc_CC7A
	bgt.w	rtss
.chkx	cmpi.w	#$2C,(puckx).w		;IDA: loc_CC82. 93: |puckx| <= $2C at the goal line
	bgt.w	.set
	cmpi.w	#-$2C,(puckx).w
	blt.w	.set
	bclr	#2,(iflags).w		;ifok cleared: no icing
	rts
.set	bset	#0,(iflags).w		;IDA: loc_CC9E. ifcgl
	rts

puckunflip	;stop spinning puck. a3 = puck. Entered from pucknothing, called from pucknorm
	cmpi.w	#8,SPAnum(a3)		;2*4 SPAnum
	blt.w	.k
	cmpi.w	#$18,SPAnum(a3)		;6*4
	bge.w	.k
	eori.w	#2,facedir(a3)
.k	ori.w	#4,facedir(a3)		;IDA: loc_CCC0
	clr.w	SPAnum(a3)
	st	SPAcnt(a3)
	rts

puckflip	;start puck spinning. a3 = puck, d0 bit 0 = flip. Called from checkgoal, wallcoll and others
	andi.w	#1,d0
	eor.w	d0,facedir(a3)
	andi.w	#3,facedir(a3)
	st	SPAcnt(a3)
	move.w	#$48A,d1		;SPApflip
	bra.w	SetSPA

puckshadow	;assignment for puck shadow. a3 = puck shadow (struct after the puck)
	cmpi.w	#$18A,frame(a3)		;frame SPFpuck
	bne.w	.siren			;shadow turns into siren on goals
	move.w	Xpos-SCstruct(a3),(a3)
	move.w	Ypos-SCstruct(a3),Ypos(a3)
	clr.w	Zpos(a3)
	moveq	#Ypos,d0
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	moveq	#Xpos,d0
.nhor	addq.w	#1,(a3,d0.w)		;IDA: loc_CD10
	rts

.siren	tst.w	frame(a3)			;IDA: loc_CD16
	beq.w	rtss
	clr.w	(a3)			;Xpos
	move.w	#$12C,Ypos(a3)		;Ypos 300
	move.w	#$E,Zpos(a3)		;Zpos 14
	tst.w	Ypos-SCstruct(a3)
	bpl.w	.s0
	move.w	#$8000,attribute(a3)
	neg.w	Ypos(a3)
	subq.w	#1,Zpos(a3)
.s0	rts				;IDA: locret_CD42

findpc	;find puck crossing lines: calculate when puck will cross goalline (if at all). Called from pucknorm
	movem.l	d0-d4/a1-a2,-(sp)
	movea.w	#(puckcross-M68K_RAM),a1
	move.w	#$88,d1			;sideline
	move.w	#$108,d4		;blueline+goalline
	bsr.w	.calc
	neg.w	d4
	bsr.w	.calc
	movem.l	(sp)+,d0-d4/a1-a2
	rts
.calc	move.w	d4,d0			;IDA: findpc_calc
	sub.w	(pucky).w,d0
	tst.w	(puckvy).w
	beq.w	.nocross
	move.w	d0,d2
	swap	d2
	clr.w	d2
	asr.l	#4,d2
	divs.w	(puckvy).w,d2
	bmi.w	.nocross
	move.w	d2,2(a1)		;time until crossing in frames
	muls.w	(puckvx).w,d0
	divs.w	(puckvy).w,d0
	bvs.w	.nocross
	add.w	(puckx).w,d0
	cmp.w	d1,d0
	blt.w	.o1
	neg.w	d0
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
.o1	neg.w	d1			;IDA: loc_CDA4
	cmp.w	d1,d0
	bgt.w	.o2
	neg.w	d0
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
.o2	neg.w	d1			;IDA: loc_CDB4
	move.w	d0,(a1)
	bra.w	.next
.nocross	move.w	#-1,2(a1)	;IDA: loc_CDBC
.next	addq.w	#4,a1			;IDA: loc_CDC2
	rts

skateto	;a0 = extra routine for collision avoidance, d0/d1 = x/y cord to skate to, d7 = elapse frames
	sub.b	d7,temp2(a3)
	bpl.w	.ex
	addi.b	#$C,temp2(a3)		;only execute every 12/60 sec.
	bsr.w	avdgoal
	movem.w	d0-d1,-(sp)		;93: no deltax/deltay test (92 .norm)
	move.w	Xvel(a3),d0
	asr.w	#8,d0
	neg.w	d0
	add.w	(sp)+,d0
	sub.w	(a3),d0
	move.w	Yvel(a3),d1
	asr.w	#8,d1
	neg.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1
	cmp.w	#12,d0
	bgt.w	.vt
	cmp.w	#-12,d0
	blt.w	.vt
	cmp.w	#12,d1
	bgt.w	.vt
	cmp.w	#-12,d1
	blt.w	.vt
	moveq	#9,d0			;close enough: no direction
	bra.w	.nvt
.vt	bsr.w	vtoa			;IDA: loc_CE1C
.nvt	jsr	(a0)			;IDA: loc_CE20
	move.b	d0,temp2+1(a3)
	cmp.w	#7,d0
	ble.w	.ex
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	bne.w	.ex
	move.w	(puckx).w,d0
	move.w	(pucky).w,d1
	btst	#pf2fight,(puckx+pflags2).w
	beq.w	.nf
	move.w	(xc1).w,d0
	move.w	(yc1).w,d1
.nf	sub.w	(a3),d0			;IDA: loc_CE54
	sub.w	Ypos(a3),d1		;face towards puck
	bsr.w	vtoa
	sub.w	facedir(a3),d0
	beq.w	.ex
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
.ex	clr.w	d0			;IDA: loc_CE7C
	move.b	temp2+1(a3),d0
	bra.w	doplayeracc

avdgoal	;don't try to skate thru goal: if d0/d1 cords intersect thru goal then provide new d0/d1 cords. a3 = player. 93 .gl 254 ($FE), .yr/.ye 35 (92 258/30/30), .xr 80
	clr.w	(deltax).w
	clr.w	(deltay).w
	tst.w	position(a3)
	beq.w	rtss
	move.w	(a3),d2
	eor.w	d0,d2
	bpl.w	.chbar
	move.w	d1,d2
	sub.w	Ypos(a3),d2
	move.w	(a3),d3
	muls.w	d3,d2
	sub.w	d0,d3
	divs.w	d3,d2
	add.w	Ypos(a3),d2
	cmp.w	#$121,d2		;.gl+.yr,d2
	bgt.w	.chbar
	cmp.w	#$DB,d2		;.gl-.yr,d2
	blt.w	.lower
	move.w	#$144,d3		;.gl+.yr+.ye
	cmp.w	#$FE,d2		;.gl,d2
	bgt.w	.2
	blt.w	.1
	cmpi.w	#$FE,Ypos(a3)		;.gl
	bgt.w	.2
.1	move.w	#$B8,d3			;IDA: loc_CEDA. .gl-.yr-.ye
.2	sub.w	d2,d3			;IDA: loc_CEDE
	move.w	d3,(deltay).w
	bra.w	.chbar

.lower	cmp.w	#-$DB,d2		;IDA: loc_CEE8. -.gl+.yr,d2
	bgt.w	.chbar
	cmp.w	#-$121,d2		;-.gl-.yr,d2
	blt.w	.chbar
	move.w	#-$B8,d3		;-.gl+.yr+.ye
	cmp.w	#-$FE,d2		;-.gl,d2
	bgt.w	.4
	blt.w	.3
	cmpi.w	#-$FE,Ypos(a3)
	bgt.w	.4
.3	move.w	#-$144,d3		;IDA: loc_CF12. -.gl-.yr-.ye
.4	sub.w	d2,d3			;IDA: loc_CF16
	move.w	d3,(deltay).w

.chbar	move.w	d1,d3			;IDA: loc_CF1C
	subi.w	#$FE,d3			;.gl
	move.w	Ypos(a3),d2
	subi.w	#$FE,d2
	bsr.w	.ch1
	move.w	d1,d3
	addi.w	#$FE,d3
	move.w	Ypos(a3),d2
	addi.w	#$FE,d2
	bsr.w	.ch1
	add.w	(deltax).w,d0
	add.w	(deltay).w,d1
	rts

.ch1	move.w	d3,d4			;IDA: avggoal_ch1
	eor.w	d2,d4
	bpl.w	rtss
	move.w	d0,d4
	sub.w	(a3),d4
	muls.w	d2,d4
	sub.w	d3,d2
	divs.w	d2,d4
	add.w	(a3),d4
	cmp.w	#$50,d4		;.xr,d4
	bgt.w	rtss
	cmp.w	#-$50,d4		;-.xr,d4
	blt.w	rtss
	moveq	#$50,d3			;.xr
	tst.w	d4
	bne.w	.ch2
	tst.w	(a3)
.ch2	bpl.w	.ch3			;IDA: loc_CF78
	neg.w	d3
.ch3	sub.w	d4,d3			;IDA: loc_CF7E
	move.w	d3,(deltax).w
	rts

skatetopuckinit	;93 split from 92 skatetopuck: d0/d1 = puck x/y plus half the high byte of its velocity. Called from skatetopuck and assnearest
	move.b	(puckvx).w,d0
	asr.b	#1,d0
	ext.w	d0
	add.w	(puckx).w,d0
	move.b	(puckvy).w,d1
	asr.b	#1,d1
	ext.w	d1
	add.w	(pucky).w,d1
	rts

skatetopuck	;player a3 should skate to puck. d7 = elapse frames
	bsr.s	skatetopuckinit
	sub.b	d7,temp2(a3)
	bpl.w	.ex
	addi.b	#$A,temp2(a3)
	bsr.w	avdgoal
	movem.w	d0-d1,-(sp)
	move.l	a3,-(sp)
	bsr.w	GetHot
	neg.b	d0
	neg.b	d1
	sub.b	Xvel(a3),d0
	ext.w	d0
	add.w	(sp)+,d0
	sub.w	(a3),d0
	sub.b	Yvel(a3),d1
	ext.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	move.b	d0,temp2+1(a3)
	tst.w	position(a3)			;93: goalie skips the sweep check
	beq.w	.ex
	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	bsr.w	vtoa
	eori.w	#4,d0
	cmp.w	facedir(a3),d0
	beq.w	.ex			;puck is coming towards players
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	move.w	(pucky).w,d1
	sub.w	Ypos(a3),d1
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa
	cmp.w	facedir(a3),d0
	movem.w	(sp)+,d0-d1
	bne.w	.ex
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#30*30,d0
	bls.w	.ex
	cmp.l	#38*38,d0
	bls.w	Sweepcheck
.ex	move.b	temp2+1(a3),d0		;IDA: loc_D03C
	bra.w	doplayeracc

assexit	;exit current assignment on player a3
	addq.w	#1,assnum(a3)
	andi.w	#7,assnum(a3)
	bset	#pfna,pflags(a3)		;signal next assignment
	rts

assinsert	;insert new assignment on player a3. d0 = assignment. Falls into assreplace
	subq.w	#1,assnum(a3)
	andi.w	#7,assnum(a3)
assreplace	;replace current assignment on player a3. d0 = assignment
	move.l	d1,-(sp)
	move.w	assnum(a3),d1
	move.b	d0,asslist(a3,d1.w)
	bset	#pfna,pflags(a3)
	move.l	(sp)+,d1
	rts

vtoa	;d0/d1 are x/y distances which are converted into direction 0-7 and returned in d0 (8 = no direction)
	movem.l	d2/a0,-(sp)
	move.w	d0,d2
	or.w	d1,d2
	beq.w	.nodir
	clr.w	d2
	tst.w	d0
	bpl.w	.0
	neg.w	d0
	bset	#0,d2
.0	tst.w	d1			;IDA: loc_D08E
	bpl.w	.1
	neg.w	d1
	bset	#1,d2
.1	asl.w	#1,d1			;IDA: loc_D09A
	cmp.w	d1,d0
	bhi.w	.2
	bset	#2,d2
.2	lsr.w	#1,d1			;IDA: loc_D0A6
	asl.w	#1,d0
	cmp.w	d0,d1
	bhi.w	.3
	bset	#3,d2
.3	movea.l	#.dt,a0			;IDA: loc_D0B4. retail $D0B6 (Rev A $D0CE)
	clr.w	d0
	move.b	(a0,d2.w),d0
	movem.l	(sp)+,d2/a0
	rts

.nodir	moveq	#8,d0			;IDA: loc_D0C6
	movem.l	(sp)+,d2/a0
	rts

.dt	dc.b	1,7,3,5,0,0,4,4
	dc.b	2,6,2,6,1,7,3,5

GetHot	;push long address of structure to get hot spot from. Hot spot x/y returned in d0/d1. 93 reads a byte pair per frame from HotList (92 framelist SprStrHot)
	movem.l	a0-a1,-(sp)
	movea.l	$C(sp),a0
	clr.w	d0
	clr.w	d1
	tst.w	frame(a0)
	ble.w	.ex
	movea.l	#HotList,a1
	move.w	frame(a0),d0
	add.w	d0,d0
	move.b	1(a1,d0.w),d1		;hot y
	ext.w	d1
	move.b	(a1,d0.w),d0		;hot x
	ext.w	d0
	btst	#3,attribute(a0)
	beq.w	.nox
	neg.w	d0
.nox	btst	#4,attribute(a0)		;IDA: loc_D116
	bne.w	.noy
	neg.w	d1
.noy	btst	#sfhor,(sflags).w		;IDA: loc_D122
	beq.w	.nhor
	exg	d0,d1
	neg.w	d1
.nhor
.ex	movem.l	(sp)+,a0-a1		;IDA: loc_D130
	move.l	(sp)+,(sp)
	rts

SetSPA	;set sprite animation on struct a3. d1 = new animation
	cmp.w	SPA(a3),d1
	beq.w	rtss
	clr.w	SPAnum(a3)
	move.w	d1,SPA(a3)
	st	SPAcnt(a3)			;SPAcnt: restart animation
	rts

doplayeracc	;player a3 gets acc. in d0 dir
	tst.w	position(a3)
	beq.w	goalieacc		;goalie is special
	move.w	#$52C,d1		;SPAglide
	btst	#pfrev,pflags(a3)
	beq.w	.d0
	move.w	#$A80,d1		;SPAglideback
.d0	andi.w	#$F,d0			;IDA: loc_D168
	cmp.w	#7,d0
	ble.w	.d1
	cmp.w	#9,d0
	bne.w	.cgl
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	bne.w	dostop
.cgl	btst	#pf2aip,pflags2(a3)		;IDA: loc_D188
	beq.s	SetSPA
	rts

.d1	movem.w	d0-d1,-(sp)		;IDA: loc_D192
	move.w	d0,d2
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	.clrrev
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	move.w	Ypos(a3),d3
	move.b	(puckvy).w,d1		;(92 move puckvy,d1 / asr #7,d1)
	ext.w	d1
	add.w	(pucky).w,d1
	sub.w	d3,d1
	btst	#pfgoal,pflags(a3)
	bne.w	.c1
	neg.w	d0
	neg.w	d1
	neg.w	d3
	eori.w	#4,d2
.c1	btst	#pfrev,pflags(a3)		;IDA: loc_D1CE
	bne.w	.inrev
	tst.w	d3
	bpl.w	.fwd			;skate back in own zone only
	cmp.w	#4,d2
	bne.w	.fwd
	bsr.w	vtoa
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.fwd
	bra.w	.rev
.inrev	subq.w	#3,d2			;IDA: loc_D1FC
	andi.w	#7,d2
	cmp.w	#2,d2
	bhi.w	.fwd
	bsr.w	vtoa
	addq.w	#2,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	bhi.w	.fwd

.rev	btst	#pfrev,pflags(a3)		;IDA: loc_D21C
	bne.w	.done
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	beq.w	.setrev
	move.w	Xvel(a3),d0
	move.w	Yvel(a3),d1
	bsr.w	vtoa
	sub.w	(sp),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.done
.setrev	bset	#pfrev,pflags(a3)		;IDA: loc_D24E
	bra.w	.done

.fwd					;IDA: loc_D258
.clrrev	bclr	#pfrev,pflags(a3)

.done	movem.w	(sp)+,d0-d1		;IDA: loc_D25E
	move.w	facedir(a3),d2
	sub.w	d2,d0
	andi.w	#7,d0
	movea.l	#.ftab,a0		;retail $D2E0 (Rev A $D2F8)
	asl.w	#1,d0
	tst.w	(a0,d0.w)
	beq.w	noturn0

	move.w	Xvel(a3),d4
	muls.w	d4,d4
	move.w	Yvel(a3),d3
	muls.w	d3,d3
	add.l	d4,d3
	swap	d3
	move.w	#$300,d4
	sub.w	d3,d4
	cmp.w	#$180,d4
	bge.w	.iok
	move.w	#$180,d4
.iok	muls.w	(a0,d0.w),d4		;IDA: loc_D29E
	btst	#pfrev,pflags(a3)
	beq.w	.i0
	neg.l	d4
.i0	add.l	d4,facedir(a3)		;IDA: loc_D2AE
	andi.w	#7,facedir(a3)
	move.w	facedir(a3),d2

	cmp.w	#20,d3
	bls.w	.s3

	clr.w	d1
	tst.w	(a0,d0.w)
	bpl.w	.s1
	eori.w	#-$32,d1		;SPAturnl-SPAturnr
.s1	btst	#3,attribute(a3)		;IDA: loc_D2D2
	beq.w	.s2
	eori.w	#-$32,d1		;SPAturnl-SPAturnr
.s2	addi.w	#$6B4,d1		;IDA: loc_D2E0. SPAturnr
	bset	#pf2aip,pflags2(a3)
.s3	bsr.w	SetSPA			;IDA: loc_D2EA

	cmp.w	#2,d3
	bhi.w	noturn
	rts

.ftab	dc.w	0,$10,$10,$10,0,-$10,-$10,-$10

goalieacc	;goalie gets acc. in direction d0. 93 turns facedir one step toward d0 (92 set it directly)
	move.w	#2,d1			;SPAgready
	andi.w	#$F,d0
	cmp.w	#7,d0
	ble.w	.d1
	cmp.w	#9,d0
	bne.w	.cgl
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	bne.w	StopNA
.cgl	btst	#pf2aip,pflags2(a3)		;IDA: loc_D32C
	beq.w	SetSPA
	rts
.d1	sub.w	facedir(a3),d0		;IDA: loc_D338
	beq.w	.spa
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
.spa	move.w	#$3F8,d1		;IDA: loc_D356. SPAgskate
	bsr.w	SetSPA
	move.w	facedir(a3),d2
	bra.w	playeracc

noturn0	;IDA: loc_D366. doplayeracc when the wanted direction needs no turn (.ftab entry 0). d0 = direction minus facedir, times 2
	moveq	#2,d4
	btst	#pfrev,pflags(a3)
	beq.w	.0
	addq.w	#4,d4
	eori.w	#8,d0
.0	tst.w	d0			;IDA: loc_D378
	beq.w	.nochg
	move.w	Xvel(a3),d0
	move.w	Yvel(a3),d1
	bsr.w	vtoa
	btst	#3,d0			;not moving
	bne.w	.nostop
	sub.w	facedir(a3),d0
	add.w	d4,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	blt.w	dostop

.nostop	addq.w	#1,facedir(a3)		;IDA: loc_D3A4
	btst	#3,attribute(a3)
	beq.w	.nos0
	subq.w	#2,facedir(a3)
.nos0	andi.w	#7,facedir(a3)		;IDA: loc_D3B6
	move.w	#$52C,d1		;SPAglide
	btst	#pfrev,pflags(a3)
	beq.w	SetSPA
	move.w	#$A80,d1		;SPAglideback
	bra.w	SetSPA

.nochg	move.w	#$AB2,d1		;IDA: loc_D3D2. SPAskateback
	btst	#pfrev,pflags(a3)
	bne.w	.ns
	move.w	#$5F0,d1		;SPAskate
	btst	#6,pflags2(a3)		;93: pflags2 bit 6 uses animation $13A0
	beq.w	.nb6
	move.w	#$13A0,d1
.nb6	move.w	(puckc).w,d4		;IDA: loc_D3F2
	cmp.w	SCnum(a3),d4
	bne.w	.ns
	move.w	#$55E,d1		;SPAskatewp
.ns	btst	#pf2aip,pflags2(a3)		;IDA: loc_D402
	bne.w	noturn
	bsr.w	SetSPA

noturn	;IDA: loc_D410. reverse the acc. direction when skating backwards, then falls into playeracc. Entered from doplayeracc and noturn0
	btst	#pfrev,pflags(a3)
	beq.w	playeracc
	eori.w	#4,d2

playeracc	;d2 = direction of acc
	asl.w	#2,d2
	lea	dirtab(pc),a0		;(92 move.l #dirtab,a0)
	move.w	2(a0,d2.w),d1		;y inc
	move.w	(a0,d2.w),d0		;x inc
	move.w	Wallsin(a3),d2		;wallsin: check acc dir and don't push wall
	beq.w	.nox
	eor.w	d0,d2
	bpl.w	.nox
	clr.w	d0
.nox	move.w	Wallcos(a3),d2		;IDA: loc_D43C
	beq.w	.noy
	eor.w	d1,d2
	bmi.w	.noy
	clr.w	d1
.noy	clr.w	d2			;IDA: loc_D44C
	move.b	weight(a3),d2
	lsr.w	#3,d2			;(92 lsr #4)
	neg.w	d2
	addi.w	#$20,d2			;32
	add.b	legstr(a3),d2
	tst.w	position(a3)
	bne.w	.ng
	add.b	legstr(a3),d2		;93: goalie adds legstr twice plus 8
	addq.w	#8,d2

.ng	muls.w	d2,d0			;IDA: loc_D46C
	muls.w	d2,d1
	asr.l	#5,d0
	asr.l	#5,d1

	muls.w	d7,d0
	muls.w	d7,d1
	add.w	Xvel(a3),d0
	add.w	Yvel(a3),d1
	move.w	d0,d2
	move.w	d1,d3
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d2,d3

	movem.w	d0-d1,-(sp)
	bsr.w	getpde
	clr.w	d2
	move.b	legspd(a3),d2
	mulu.w	d0,d2
	asl.l	#4,d2
	swap	d2
	asl.w	#2,d2
	lea	MaxSpeed(pc),a2		;(92 move.l #MaxSpeed,a2)
	move.l	(a2,d2.w),d2
	btst	#6,pflags2(a3)		;93: pflags2 bit 6 cuts max speed to 1/8
	beq.w	.ms
	lsr.l	#3,d2
.ms	movem.w	(sp)+,d0-d1		;IDA: loc_D4B4

	cmp.l	d2,d3			;max speed check
	bhi.w	.sube
	move.w	d0,Xvel(a3)
	move.w	d1,Yvel(a3)

.sube	tst.w	(OptLine).w		;IDA: loc_D4C6
	bne.w	rtss
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#$7F,d0
	bne.w	rtss
	bsr.w	getpde
	subi.w	#$21,d0			;33
	cmp.w	#$C00,d0
	blt.w	setpde
	move.b	endurance(a3),d2		;92 endurance
	ext.w	d2
	add.w	d2,d0
	bra.w	setpde

MaxSpeed	;max speed values for each rating level 0-f. 93: ((n+20)*275)^2 (92 used 250)
	dc.l	(20*275)*(20*275)
	dc.l	(21*275)*(21*275)
	dc.l	(22*275)*(22*275)
	dc.l	(23*275)*(23*275)
	dc.l	(24*275)*(24*275)
	dc.l	(25*275)*(25*275)
	dc.l	(26*275)*(26*275)
	dc.l	(27*275)*(27*275)
	dc.l	(28*275)*(28*275)
	dc.l	(29*275)*(29*275)
	dc.l	(30*275)*(30*275)
	dc.l	(31*275)*(31*275)
	dc.l	(32*275)*(32*275)
	dc.l	(33*275)*(33*275)
	dc.l	(34*275)*(34*275)
	dc.l	(35*275)*(35*275)

dostop	;IDA: loc_D538. player a3 stops. Entered from doplayeracc and noturn0
	cmpi.w	#$1000,Xvel(a3)		;.slim Xvel
	bgt.w	.set
	cmpi.w	#-$1000,Xvel(a3)
	blt.w	.set
	cmpi.w	#$1000,Yvel(a3)
	bgt.w	.set
	cmpi.w	#-$1000,Yvel(a3)
	blt.w	.set
	bra.w	StopNA			;stop with no anim
.set	move.w	#$52C,d1		;IDA: loc_D564. SPAglide
	btst	#pfrev,pflags(a3)
	bne.w	.0
	bset	#pf2aip,pflags2(a3)
	move.w	#$6E6,d1		;SPAstop
.0	bsr.w	SetSPA			;IDA: loc_D57C
StopNA	;slow player a3 by 150 on each axis, no animation change. Falls in from dostop, also entered from goalieacc and others
	tst.w	Xvel(a3)
	bpl.w	.xp
	addi.w	#$96,Xvel(a3)		;150
	bmi.w	.y
	clr.w	Xvel(a3)
.xp	subi.w	#$96,Xvel(a3)		;IDA: loc_D596
	bpl.w	.y
	clr.w	Xvel(a3)
.y	tst.w	Yvel(a3)			;IDA: loc_D5A4
	bpl.w	.yp
	addi.w	#$96,Yvel(a3)
	bmi.w	rtss
	clr.w	Yvel(a3)
.yp	subi.w	#$96,Yvel(a3)		;IDA: loc_D5BA
	bpl.w	rtss
	clr.w	Yvel(a3)
	rts

dirtab	;x,y speed for each direction 0-7 (92 runspeed 200, diagonal 200*1000/1414 = 141)
	dc.w	0,200
	dc.w	141,141
	dc.w	200,0
	dc.w	141,-141
	dc.w	0,-200
	dc.w	-141,-141
	dc.w	-200,0
	dc.w	-141,141

UnpackNibbles	;93: a0 = packed data, d0 = count. Unpacks d0 4-bit values (high nibble first) into words at nibblebuffer. Called from UpdateTeamNameisplay
	movem.l	d0-d2/a0-a1,-(sp)
	movea.w	#(nibblebuffer-M68K_RAM),a1
	clr.w	d2
	bra.w	.next
.loop	move.b	(a0)+,d1		;IDA: process_one_nibble
	bchg	#0,d2			;toggle high/low nibble
	bne.w	.lo
	subq.w	#1,a0			;high nibble: read the same byte again next time
	lsr.w	#4,d1
.lo	andi.w	#$F,d1			;IDA: extract_and_store_nibble
	move.w	d1,(a1)+
.next	dbf	d0,.loop		;IDA: loop_control
	movem.l	(sp)+,d0-d2/a0-a1
	rts

WeightedRandomSelect	;93: d0 = number of word weights at nibblebuffer. Return d0 = random index, picked with those weights. Called from SetScore_getscore and UpdateTeamNameisplay
	movem.l	d1/a1,-(sp)
	movea.w	#(nibblebuffer-M68K_RAM),a1
	clr.w	d1
	bra.w	.next
.sum	add.w	(a1)+,d1		;IDA: sum_all_weights
.next	dbf	d0,.sum			;IDA: loop_control
	move.w	d1,d0			;d0 = total weight
	bsr.w	randomd0
.find	sub.w	-(a1),d0		;IDA: find_entry_random. walk back from the last weight
	bpl.s	.find
	suba.w	#(nibblebuffer-M68K_RAM),a1
	move.w	a1,d0
	lsr.w	#1,d0			;word offset -> index
	movem.l	(sp)+,d1/a1
	rts
