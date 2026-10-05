;	NHLPA Hockey 93 (retail) segment $AE88-$BC6B
;	92 Logic.Asm part 3: asswingo ... asspuckc, chk4lc, chkpk, chk4shot,
;	CompShoot, chk4pass, EvadePC. Global names from the IDA export, 92
;	names where the routine is the same (see the SEGMENT_AGENT.md rename
;	table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	93 SortCords offsets, 92 names in comments: Xpos 0, attribute 4,
;	Ypos $14, Xvel $28, Yvel $2A, position $34, temp1 $40, temp2 $42,
;	temp3 $44, temp4 $46, temp5 $48, SCnum $52, facedir $54, nopuck $5E,
;	pflags $62 (pfalock 5, pfjoycon 3, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2aip 1, pf2unav 2, pf2lcm 3), aioff $6A, aidef $6B, spodds $70.
;	Team struct: tmflags $30, $2A = long stat (93). blueline = $58,
;	goalline+blueline = $108.

asswingo	;player a3 is winger on offense
	btst	#5,pflags(a3)		;pfalock
	bne.w	rtss
	btst	#0,(gmode).w		;gmclock
	bne.w	assnothing
	bsr.w	check4bench
	btst	#3,pflags(a3)		;pfjoycon
	bne.w	rtss
	bclr	#1,pflags(a3)		;pfna
	beq.w	.nna
	st	temp5(a3)			;temp5 = old zone number
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;IDA: loc_AEDA
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.l	#3,d0			;awingd
	move.w	(puckc).w,d1
	bmi.w	.de0
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace		;other team has puck
.de0	move.w	(pucky).w,d0		;IDA: loc_AF04
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	add.w	d0,d3
	btst	#7,pflags(a3)		;pfgoal
	bne.w	.de1
	neg.w	d0
	neg.w	d3
.de1	clr.w	d2			;IDA: loc_AF1E. Set zone number
	cmp.w	#-$58,d3		;-blueline,d3
	blt.w	.de2
	addq.w	#8,d2
	cmp.w	#$58,d0		;blueline,d0
	blt.w	.de2
	btst	#4,tmflags(a2)		;93: team flag keeps him back
	bne.w	.de2
	addq.w	#8,d2
	cmp.w	#$108,d3		;blueline+goalline,d3
	blt.w	.de2
	addq.w	#8,d2
.de2	cmp.w	temp5(a3),d2		;IDA: loc_AF48
	bne.w	.de3
	move.w	(VDP_CNTR).l,d0		;93: HV counter as random
	andi.w	#$7F,d0
	bne.w	.nodec
.de3	move.w	d2,temp5(a3)		;IDA: loc_AF5E
	lea	.dedata(pc),a0
	move.w	2(a0,d2.w),d0
	bsr.w	randomd0s
	add.w	(a0,d2.w),d0
	move.w	d0,temp3(a3)
	move.w	6(a0,d2.w),d0
	bsr.w	randomd0s
	add.w	4(a0,d2.w),d0
	move.w	d0,temp4(a3)
	bra.w	.nodec
.dedata	;IDA: unk_AF8A. x, x random, y, y random
	dc.w	80,20,-70,10		;in own zone
	dc.w	100,20,58,5		;center ice area
	dc.w	60,50,230,20		;opp zone
	dc.w	80,30,250,20		;past goalline
.nodec	move.w	temp3(a3),d0		;IDA: loc_AFAA
	cmpi.w	#5,position(a3)
	beq.w	.1
	neg.w	d0
.1	move.w	temp4(a3),d1		;IDA: loc_AFBA
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0	lea	EvadePC(pc),a0		;IDA: loc_AFCC
	bra.w	skateto

asscenterd	;player a3 is center on defense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	assnothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;IDA: loc_B00A
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.w	(puckc).w,d1
	bmi.w	.nodec
	move.l	#6,d0			;acentero
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace		;our team has puck
.nodec	move.w	(puckx).w,d0		;IDA: loc_B034
	asr.w	#1,d0
	move.w	(pucky).w,d2
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d2
.0	moveq	#-$80,d1		;IDA: loc_B04A
	cmp.w	#-$58,d2		;-blueline,d2
	blt.w	.z0
	add.w	(pucky).w,d1
	asr.w	#1,d1
.z0	btst	#7,pflags(a3)		;IDA: loc_B05A
	bne.w	.z1
	neg.w	d1
.z1	lea	rtss(pc),a0		;IDA: loc_B066
	bra.w	skateto

asscentero	;player a3 is center on offense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	assnothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	st	temp5(a3)			;old zone number
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;IDA: loc_B0A8
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.w	(puckc).w,d1
	bmi.w	.de0
	move.l	#5,d0			;acenterd
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace
.de0	move.w	(pucky).w,d0		;IDA: loc_B0D2
	btst	#7,pflags(a3)
	bne.w	.de1
	neg.w	d0
.de1	clr.w	d2			;IDA: loc_B0E2. Set zone number
	cmp.w	#-$58,d0		;-blueline,d0
	blt.w	.de2
	addq.w	#8,d2
	cmp.w	#$58,d0		;blueline,d0
	blt.w	.de2
	btst	#4,tmflags(a2)
	bne.w	.de2
	addq.w	#8,d2
	cmp.w	#$108,d0		;blueline+goalline,d0
	blt.w	.de2
	addq.w	#8,d2
.de2	cmp.w	temp5(a3),d2		;IDA: loc_B10C
	bne.w	.de3
	move.w	(VDP_CNTR).l,d0
	andi.w	#$7F,d0
	bne.w	.nodec
.de3	move.w	d2,temp5(a3)		;IDA: loc_B122
	lea	.dedata(pc),a0
	move.w	2(a0,d2.w),d0
	bsr.w	randomd0s
	add.w	(a0,d2.w),d0
	move.w	d0,temp3(a3)
	move.w	6(a0,d2.w),d0
	bsr.w	randomd0s
	add.w	4(a0,d2.w),d0
	move.w	d0,temp4(a3)
	bra.w	.nodec
.dedata	;IDA: unk_B14E
	dc.w	0,60,-70,10
	dc.w	0,60,60,10
	dc.w	0,40,170,30
	dc.w	0,80,170,20
.nodec	move.w	temp3(a3),d0		;IDA: loc_B16E
	move.w	temp4(a3),d1
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d1
.0	lea	EvadePC(pc),a0		;IDA: loc_B182
	bra.w	skateto

assgoalie	;IDA: loc_B18A. Player a3 is goalie. Also entered from assnearest
	btst	#5,pflags(a3)
	bne.w	rtss
	bsr.w	check4bench
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
	st	temp4(a3)			;93: temp4 = cover countdown
.nna	cmpi.w	#$34,(a3)		;IDA: loc_B1B0. Outside the crease area?
	bgt.w	.skate
	cmpi.w	#$FFCC,(a3)
	blt.w	.skate
	cmpi.w	#$10E,Ypos(a3)
	bgt.w	.skate
	cmpi.w	#$FEF2,Ypos(a3)
	blt.w	.skate
	cmpi.w	#$D2,Ypos(a3)
	bgt.w	.noskate
	cmpi.w	#$FF2E,Ypos(a3)
	blt.w	.noskate
.skate	lea	rtss(pc),a0		;IDA: loc_B1E8. Skate back to the net
	moveq	#4,d0
	tst.w	(a3)
	bpl.w	.0
	neg.w	d0
.0	move.w	#$E4,d1			;IDA: loc_B1F6
	btst	#7,pflags(a3)
	beq.w	skateto
	neg.w	d1
	bra.w	skateto
.noskate	btst	#1,pflags2(a3)		;IDA: loc_B20A. pf2aip
	bne.w	rtss
	move.w	#2,d1			;SPAgready
	bsr.w	SetSPA
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	tst.w	temp5(a3)			;temp5 = holding time
	bmi.w	.nofo
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	.mbfo
	st	temp5(a3)
	bra.w	.nofo
.mbfo	sub.w	d7,temp5(a3)		;IDA: loc_B242
	bpl.w	.nofo
	move.l	#8,d0			;PenGhold
	bsr.w	AddPenalty2
.nofo	sub.b	d7,temp1(a3)		;IDA: loc_B254
	bpl.w	.nodec
	move.b	aidef(a3),d0
	lsr.b	#2,d0			;92 lsr #1
	move.b	d0,temp1(a3)
	btst	#3,pflags(a3)
	bne.w	.cover
	move.w	(pucky).w,d0
	move.w	Ypos(a3),d1
	eor.w	d0,d1
	bpl.w	.cnt			;puck in my half
	clr.w	d0			;puck in other half: stay at the top of the crease
	move.w	#$F4,d2
	btst	#7,pflags(a3)
	beq.w	.de5
	neg.w	d2
	bra.w	.de5
.cnt	subq.w	#1,temp4(a3)		;IDA: loc_B294
	bpl.w	.pc
	move.w	#$FFFF,temp4(a3)
.pc	move.w	SCnum(a3),d0		;IDA: loc_B2A2
	cmp.w	(puckc).w,d0
	bne.w	.cover
	tst.w	temp5(a3)
	bpl.w	.hold
	move.w	#$5A,temp5(a3)		;90 frames before holding penalty
.hold	st	temp4(a3)			;IDA: loc_B2BC
	cmpi.w	#$5A,temp5(a3)
	bgt.w	.de1
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	bne.w	.de1
	moveq	#5,d0			;pass only if no opponent is near the puck
	movea.w	#(SortCords-M68K_RAM),a0
	btst	#6,pflags(a3)
	bne.w	.tl
	adda.w	#6*SCstruct,a0
.tl	btst	#2,pflags2(a0)		;IDA: loc_B2EC. pf2unav
	bne.w	.tn
	move.w	(pucky).w,d1
	sub.w	Ypos(a0),d1
	cmp.w	#28,d1
	bgt.w	.tn
	cmp.w	#-28,d1
	blt.w	.tn
	move.w	(puckx).w,d1
	sub.w	(a0),d1
	cmp.w	#25,d1
	bgt.w	.tn
	cmp.w	#-25,d1
	bgt.w	.de1
.tn	adda.w	#SCstruct,a0			;IDA: loc_B324
	dbf	d0,.tl
	move.w	#1,(threat).w
	bsr.w	chk4pass
	bra.w	.de1
.cover	tst.w	temp4(a3)			;IDA: loc_B33A. 93: cover a loose puck at the crease
	bne.w	.de1
	tst.w	(puckc).w
	bpl.w	.de1
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	cmp.w	#20,d0
	bgt.w	.de1
	cmp.w	#-20,d0
	blt.w	.de1
	move.w	(pucky).w,d1
	cmp.w	#$108,d1		;blueline+goalline,d1
	bgt.w	.de1
	cmp.w	#-$108,d1		;-(blueline+goalline),d1
	blt.w	.de1
	sub.w	Ypos(a3),d1
	cmp.w	#30,d1
	bgt.w	.de1
	cmp.w	#-30,d1
	blt.w	.de1
	bsr.w	vtoa
	move.w	d0,facedir(a3)
	move.b	#8,nopuck(a3)
	move.w	#$314,d1
	bsr.w	SetSPA
	bset	#1,pflags2(a3)
	addi.w	#$96,(crowdlevel).w	;150
	addi.w	#$A,(CwdExciteLvl).w
	rts
.de1	movea.w	#(puckcross-M68K_RAM),a0	;IDA: loc_B3B2
	move.w	#$104,d3		;goal line
	btst	#7,pflags(a3)
	beq.w	.de2
	addq.w	#4,a0
	neg.w	d3
.de2	cmpi.w	#$104,Ypos(a3)		;IDA: loc_B3C8
	bgt.w	.out
	cmpi.w	#$FEFC,Ypos(a3)
	bgt.w	.in
.out	clr.w	d2			;IDA: loc_B3DC. Behind the goal line
	clr.w	d0
	cmpi.w	#$2C,(a3)
	bgt.w	.de5
	cmpi.w	#$FFD4,(a3)
	blt.w	.de5
	move.w	#$88,d0
	tst.w	(a3)
	bpl.w	.de5
	neg.w	d0
	bra.w	.de5
.in	move.w	(puckx).w,d0		;IDA: loc_B400. Face the puck
	move.w	(pucky).w,d1
	bsr.w	ClampYPosition
	bsr.w	vtoa
	bsr.w	AdjustFacingDirection
	move.w	(gameclock).w,d0	;lead the puck by 160-272/256 of its velocity
	andi.w	#7,d0
	asl.w	#4,d0
	addi.w	#$A0,d0
	cmpi.w	#$DB,(pucky).w
	bgt.w	.lead2
	cmpi.w	#$FF25,(pucky).w
	bgt.w	.lead
.lead2	subi.w	#$40,d0			;IDA: loc_B436
.lead	move.w	d0,d1			;IDA: loc_B43A
	muls.w	(puckvx).w,d0
	swap	d0
	add.w	(puckx).w,d0
	muls.w	(puckvy).w,d1
	swap	d1
	add.w	(pucky).w,d1
	bsr.w	ClampYPosition
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#30*30,d0
	bhi.w	.far
	movem.w	(sp)+,d0-d1
	bra.w	.de4
.far	bsr.w	sroot			;IDA: loc_B470. Scale to an 18 (26 if shooting) pixel arc
	moveq	#1,d2
	add.w	d0,d2
	moveq	#$12,d4
	btst	#3,(sflags).w		;sfssdir
	beq.w	.f0
	addq.w	#8,d4
.f0	movem.w	(sp)+,d0-d1		;IDA: loc_B486
	muls.w	d4,d1
	addq.w	#8,d4
	muls.w	d4,d0
	divs.w	d2,d0
	divs.w	d2,d1
.de4	add.w	d3,d1			;IDA: loc_B494
	move.w	d1,d2
	cmpi.w	#$22,2(a0)		;frames til crossing
	bhi.w	.de5
	cmpi.w	#$18,(a0)
	bgt.w	.rush
	cmpi.w	#$FFE8,(a0)
	blt.w	.rush
	cmpi.w	#$C,2(a0)
	bhi.w	.de8
	cmpi.w	#$108,(pucky).w
	bgt.w	.de8
	cmpi.w	#$FEF8,(pucky).w
	blt.w	.de8
	bset	#1,pflags2(a3)		;pf2aip
	bne.w	.de8
	move.w	(a0),d0
	sub.w	(a3),d0
	move.w	d3,d1			;goalline
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	sub.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,d3
	lsr.w	#2,d0			;glove
	btst	#3,attribute(a3)
	beq.w	.noflip
	eori.w	#1,d0
.noflip	cmpi.w	#8,(puckz).w		;IDA: loc_B502
	bgt.w	.de7
	cmpi.w	#$800,(puckvz).w
	bgt.w	.de7
	addq.w	#4,d0			;stick
	cmpi.w	#8,2(a0)
	bls.w	.de7
	cmpi.w	#2,facedir(a3)
	beq.w	.de7
	cmpi.w	#6,facedir(a3)
	beq.w	.de7
	tst.w	(puckc).w
	bmi.w	.de7
	subq.w	#2,d0			;stack
.de7	add.w	d0,d0			;IDA: loc_B540
	lea	GoalieSaveList(pc),a1
	move.w	(a1,d0.w),d1
	cmp.w	#$198,d1
	bne.w	.set
	andi.w	#3,d3
	beq.w	.set
	cmpi.b	#$B,$73(a3)
	blt.w	.set
	move.w	#$1CA,d1
.set	bsr.w	SetSPA			;IDA: loc_B568
	addi.w	#$96,(crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
.de8	move.w	(a0),d0			;IDA: loc_B578
	cmpi.w	#$FC,(pucky).w
	bgt.w	.post
	cmpi.w	#$FF04,(pucky).w
	bgt.w	.de5
.post	moveq	#$18,d0			;IDA: loc_B58E. Hug the post
	tst.w	(puckx).w
	bpl.w	.de5
	neg.w	d0
.de5	move.w	d2,d1			;IDA: loc_B59A
	movem.w	d0-d1,-(sp)
	move.b	Xvel(a3),d0
	ext.w	d0
	neg.w	d0
	add.w	(sp)+,d0
	sub.w	(a3),d0
	move.b	Yvel(a3),d1
	ext.w	d1
	neg.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1
	cmp.w	#4,d0
	bgt.w	.vt
	cmp.w	#-4,d0
	blt.w	.vt
	cmp.w	#4,d1
	bgt.w	.vt
	cmp.w	#-4,d1
	blt.w	.vt
	clr.w	d0
	clr.w	d1
.vt	bsr.w	vtoa			;IDA: loc_B5DE
	move.b	d0,temp2+1(a3)
.nodec	move.b	temp2+1(a3),d2		;IDA: loc_B5E6
	ext.w	d2
	cmp.w	#7,d2
	ble.w	playeracc
	bra.w	StopNA
.rush	tst.w	(puckc).w		;IDA: loc_B5F8. 93: rush a loose puck when
	bpl.s	.de5			;the score/time stats say so
	btst	#2,(iflags).w
	bne.s	.de5
	movea.w	#(hmtmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	btst	#6,pflags(a3)
	beq.w	.t0
	exg	a1,a2
.t0	cmpi.l	#$1324,$2A(a1)		;IDA: loc_B61A
	blt.w	.de5
	cmpi.l	#$9C4,$2A(a2)
	blt.w	.de5
	cmpi.w	#$E0,(pucky).w
	bgt.w	.dir
	cmpi.w	#$FF20,(pucky).w
	bgt.w	.de5
.dir	tst.w	(puckvy).w		;IDA: loc_B646
	btst	#7,pflags(a3)
	beq.w	.dir2
	eori	#8,ccr			;flip N
.dir2	bmi.w	.de5			;IDA: loc_B658. Puck moving away
	move.w	(puckvx).w,d0
	bpl.w	.ax
	neg.w	d0
.ax	move.w	(puckvy).w,d1		;IDA: loc_B666
	bpl.w	.ay
	neg.w	d1
.ay	cmp.w	d0,d1			;IDA: loc_B670
	blt.w	.de5
	move.l	#$F,d0			;assgoalietopuck
	bra.w	assinsert

ClampYPosition	;d1 = y clamped to +-$103, minus goal line d3. d0 = 0 if a3
	;has the puck
	move.w	(puckc).w,d2
	cmp.w	SCnum(a3),d2
	bne.w	.0
	clr.w	d0
.0	cmp.w	#$103,d1		;IDA: loc_B68E
	blt.w	.1
	move.w	#$103,d1
.1	cmp.w	#-$103,d1		;IDA: loc_B69A
	bgt.w	.2
	move.w	#$FEFD,d1
.2	sub.w	d3,d1			;IDA: loc_B6A6
	rts

AdjustFacingDirection	;IDA: AdjustFacingDirecion. Turn facedir one step
	;toward direction d0, two steps past the directions the goalie can't
	;face (bit masks by goal end)
	move.w	facedir(a3),d1
	sub.w	d1,d0
	beq.w	rtss
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0			;d0 = +1/-1
	btst	d1,#$42			;facing 1 or 6
	beq.w	.add
	add.w	d0,d1
	btst	#7,pflags(a3)		;pfgoal
	bne.w	.dn
	btst	d1,#$83			;0, 1 or 7
	bra.w	.t
.dn	btst	d1,#$38			;3, 4 or 5
.t	beq.w	.set
	neg.w	d0
	add.w	d0,d1
.add	add.w	d0,d1
.set	andi.w	#7,d1
	move.w	d1,facedir(a3)
	rts

GoalieSaveList	;IDA: unk_B6F2. 92 assgoalie .list
	dc.w	$166			;SPAgglover
	dc.w	$198			;SPAgglovel
	dc.w	$270			;SPAgstackr
	dc.w	$2C2			;SPAgstackl
	dc.w	$20C			;SPAgstickr
	dc.w	$23E			;SPAgstickl

assgoalietopuck	;93 only: goalie skates out to a loose puck (inserted by
	;assgoalie)
	btst	#3,pflags(a3)
	bne.w	assexit
	btst	#0,(gmode).w
	bne.w	assexit
	bsr.w	check4bench
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna	sub.b	d7,temp1(a3)		;IDA: loc_B724
	bpl.w	.go
	move.b	aidef(a3),d0
	lsr.b	#2,d0
	move.b	d0,temp1(a3)
	tst.w	(puckc).w
	bpl.w	assexit
	tst.w	(puckvy).w
	btst	#7,pflags(a3)
	beq.w	.dir
	eori	#8,ccr
.dir	bmi.w	assexit			;IDA: loc_B750
	movea.w	#(hmtmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	btst	#6,pflags(a3)
	beq.w	.t0
	exg	a1,a2
.t0	cmpi.l	#$E10,$2A(a1)		;IDA: loc_B768
	blt.w	assexit
	cmpi.l	#$640,$2A(a2)
	blt.w	assexit
.go	bra.w	skatetopuck		;IDA: loc_B780

asspuckc	;player a3 is puck handler
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	assexit
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	assnothing
	btst	#3,pflags(a3)
	bne.w	assexit
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	move.w	d0,temp3(a3)		;temp3 = random 0-3
.nna	sub.b	d7,temp1(a3)		;IDA: asspuckc_nna
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)
	bsr.w	checkob
	bsr.w	chk4lc
	bsr.w	chk4shot
	bsr.w	chk4pass
.nodec	moveq	#6,d0			;IDA: asspuckc_onside
	add.w	temp3(a3),d0
	lea	.postab(pc),a0
	btst	#7,(sflags2).w		;sf2offsig: someone is over the line
	beq.w	.nd1
	move.w	position(a3),d0
.nd1	asl.w	#2,d0			;IDA: asspuckc_nd1
	move.w	2(a0,d0.w),d1
	move.w	(a0,d0.w),d0
	btst	#7,pflags(a3)
	bne.w	.nd0
	neg.w	d0
	neg.w	d1
.nd0	lea	.chkdir(pc),a0		;IDA: asspuckc_nd0
	bra.w	skateto
.chkdir	ext.w	d0			;IDA: asspuckc_chkdir
	move.b	Xvel(a3),d2
	ext.w	d2
	add.w	(puckx).w,d2
	move.b	Yvel(a3),d3
	ext.w	d3
	add.w	(pucky).w,d3
	clr.w	(threat).w
	moveq	#5,d4
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.cd0
	adda.w	#6*SCstruct,a0
.cd0	move.b	Xvel(a0),d1		;IDA: asspuckc_cd0
	ext.w	d1
	add.w	(a0),d1
	sub.w	d2,d1
	cmp.w	#20,d1
	bgt.w	.next
	cmp.w	#-20,d1
	blt.w	.next
	move.b	Yvel(a0),d1
	ext.w	d1
	add.w	Ypos(a0),d1
	sub.w	d3,d1
	cmp.w	#20,d1
	bgt.w	.next
	cmp.w	#-20,d1
	blt.w	.next
	addq.w	#1,(threat).w
	move.w	(a3),d0
	sub.w	(a0),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a0),d1
	bsr.w	vtoa
	move.w	facedir(a3),d1
	eori.w	#4,d1
	cmp.w	d0,d1
	bne.w	.next
	move.w	(VDP_CNTR).l,d1		;93: turn either way
	andi.w	#1,d1
	add.w	d1,d0
	andi.w	#7,d0
.next	adda.w	#SCstruct,a0			;IDA: asspuckc_next
	dbf	d4,.cd0
	rts
.postab	;IDA: _posttab. x,y by position when offsides (1-5), then 4
	;random onside spots (6-9)
	dc.w	-100,-20
	dc.w	100,-20
	dc.w	-120,40
	dc.w	20,40
	dc.w	120,40
	dc.w	-20,40
	dc.w	-40,240
	dc.w	0,220
	dc.w	20,230
	dc.w	30,230

chk4lc	;see if computer should call line change
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.gu
	neg.w	d0
.gu	tst.w	d0			;IDA: _gu
	bmi.w	rtss
	cmp.w	#$58,d0		;blueline,d0
	bgt.w	rtss
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#3,d0
	bne.w	rtss
	btst	#3,pflags2(a3)		;pf2lcm
	bne.w	rtss
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	btst	#6,pflags(a3)
	beq.w	.0
	exg	a2,a1
.0	bsr.w	AvgCline		;IDA: _0
	cmp.w	#$C00,d0
	bhi.w	rtss
	bsr.w	CompLine
	bsr.w	setpersonel
	bsr.w	printscores1
	bra.w	CompShoot

chkpk	;return z flag set if killing penalty
	;return z flag clr if not
	btst	#5,(sflags2).w		;sf2pwrplay
	bne.w	chkpk2
	eori	#4,ccr			;93: no power play returns ne
	rts

chkpk2	movem.l	d0-d1,-(sp)
	btst	#6,(sflags2).w		;sf2pwrtm
	move.w	sr,d0
	btst	#6,pflags(a3)		;pfteam
	move.w	sr,d1
	eor.w	d1,d0
	move.w	d0,ccr
	movem.l	(sp)+,d0-d1
	rts

chk4shot	;player a3 looks for shot (computer controlled)
	bsr.s	chkpk
	bne.w	.npk			;not pkilling
	tst.w	(threat).w
	beq.w	.npk			;no threat
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	beq.w	CompShoot		;clear puck (no icing if pkilling)
.npk	moveq	#$20,d4			;IDA: _npk
	sub.b	spodds(a3),d4		;shot/pass odds
	asl.w	#4,d4
	move.w	#$108,d1		;blueline+goalline
	btst	#7,pflags(a3)
	bne.w	.c0
	neg.w	d1
.c0	sub.w	(pucky).w,d1		;IDA: _c0
	move.w	(puckx).w,d0
	neg.w	d0
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d0,d1			;distance from goal squared
	cmp.l	#100*100,d1
	movem.w	(sp)+,d0-d1
	bhi.w	.no1
	lsr.w	#4,d4
	bsr.w	vtoa
	move.w	d0,d5
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	bge.w	.co0
	adda.w	#6*SCstruct,a1
.co0	tst.w	position(a1)			;IDA: _co0
	beq.w	.gl
	move.w	(a1),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
	sub.w	(pucky).w,d1
	bsr.w	vtoa
	cmp.w	d5,d0
	bne.w	.co1
	asl.w	#1,d4			;defender in the shot line
	bra.w	.co1
.gl	btst	#1,pflags2(a1)		;IDA: loc_BA1A. 93: goalie busy, shoot now
	beq.w	.co1
	clr.w	d3
	moveq	#1,d4
.co1	adda.w	#SCstruct,a1			;IDA: loc_BA28
	dbf	d3,.co0
.no1	move.w	d4,d0			;IDA: loc_BA30
	bsr.w	randomd0
	cmp.w	#8,d0
	bgt.w	rtss
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0	tst.w	d0			;IDA: loc_BA4E
	bmi.w	rtss			;don't shoot from behind center line
	move.w	#$108,d1
	sub.w	d0,d1
	bmi.w	rtss
	btst	#7,(sflags2).w		;sf2offsig
	bne.w	rtss			;player is offsides
CompShoot	;player a3 shoots (computer controlled player)
	addq.w	#4,sp			;don't return
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0	move.w	#$108,d1		;IDA: loc_BA7A
	sub.w	d0,d1
	lsr.w	#3,d1
	cmp.w	#20,d1
	blt.w	.lt
	moveq	#$14,d1
.lt	move.w	d1,temp2(a3)		;IDA: loc_BA8C. temp2 = swing time
	move.l	#$12,d0			;ashoot
	bra.w	assreplace

chk4pass	;player a3 looks for good pass (computer controlled)
	tst.w	(threat).w
	bne.w	.dp0
	moveq	#$10,d0
	add.b	spodds(a3),d0
	bsr.w	randomd0
	cmp.w	#8,d0
	bgt.w	rtss
.dp0	moveq	#6,d0			;IDA: _dp0. Set up pass assignment
	bsr.w	randomd0
	cmpi.w	#6,SCnum(a3)
	blt.w	.dp1
	addq.w	#6,d0
.dp1	tst.w	position(a3)			;IDA: _dp1. 93: from the goalie, or skaters
	beq.w	.bl			;outside the slot only
	cmpi.w	#$28,(puckx).w
	bgt.w	.bl
	cmpi.w	#$FFD8,(puckx).w
	blt.w	.bl
	cmpi.w	#$CC,(pucky).w
	bgt.w	rtss
	cmpi.w	#$FF34,(pucky).w
	blt.w	rtss
.bl	cmp.w	SCnum(a3),d0		;IDA: checkForPassAcrossBlueLine
	beq.w	rtss			;don't pass to yourself
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0
	tst.w	position(a0)
	ble.w	rtss			;don't pass to goalie or illegal player
	btst	#2,pflags2(a0)		;pf2unav
	bne.w	rtss
	btst	#5,pflags(a0)		;pfalock
	bne.w	rtss			;don't pass to locked player
	move.w	Ypos(a0),d0		;check for pass across blue line
	move.w	Ypos(a3),d1
	btst	#7,pflags(a3)
	bne.w	.f0
	neg.w	d0
	neg.w	d1
.f0	btst	#5,(gmode).w		;IDA: _f0. gmoffs
	beq.w	.oko
	movem.w	d0-d1,-(sp)
	subi.w	#$58,d0
	subi.w	#$58,d1
	eor.w	d0,d1
	movem.w	(sp)+,d0-d1
	bmi.w	rtss
.oko	cmp.w	#$58,d0		;IDA: _oko. blueline,d0
	bgt.w	.ok
	sub.w	d1,d0
	cmp.w	#-15,d0
	blt.w	rtss
.ok	move.w	(a0),d0			;IDA: _ok
	sub.w	(puckx).w,d0
	move.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa
	move.w	d0,(passdir).w
	movem.w	(sp)+,d1-d2
	muls.w	d1,d1
	muls.w	d2,d2
	add.l	d1,d2
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	bge.w	.co0
	adda.w	#6*SCstruct,a1
.co0	move.w	(a1),d0			;IDA: _co0
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d0,d1
	cmp.l	d2,d1
	movem.w	(sp)+,d0-d1
	bhi.w	.co1
	bsr.w	vtoa
	cmp.w	(passdir).w,d0
	beq.w	rtss			;opponent in the pass lane
.co1	adda.w	#SCstruct,a1			;IDA: _co1
	dbf	d3,.co0
	bsr.w	dopass
	tst.w	position(a3)
	beq.w	rtss
	addq.w	#4,sp
	bra.w	assexit

EvadePC	;player a3 should avoid the puck carrier if he's on my team
	tst.w	(puckc).w
	bmi.w	rtss			;no puck handler
	move.b	Xvel(a3),d2
	sub.b	(puckvx).w,d2
	ext.w	d2
	add.w	(a3),d2
	sub.w	(puckx).w,d2
	cmp.w	#40,d2
	bgt.w	rtss
	cmp.w	#-40,d2
	blt.w	rtss
	move.b	Yvel(a3),d1
	sub.b	(puckvy).w,d1
	ext.w	d1
	add.w	Ypos(a3),d1
	sub.w	(pucky).w,d1
	cmp.w	#40,d1
	bgt.w	rtss
	cmp.w	#-40,d1
	blt.w	rtss
	move.w	(a3),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a3),d1
	sub.w	(pucky).w,d1
	bsr.w	vtoa
	btst	#5,(gmode).w		;93: with offsides on, don't skate
	beq.w	.x			;offside: go sideways near the blue line
	move.w	Ypos(a3),d1
	btst	#7,pflags(a3)
	bne.w	.y
	neg.w	d1
.y	subi.w	#$58,d1			;IDA: loc_BC60
	cmp.w	#10,d1
	bgt.w	.x
	cmp.w	#-50,d1
	blt.w	.x
	moveq	#2,d0
	move.w	(a3),d1
	cmp.w	(puckx).w,d1
	bgt.w	.x
	moveq	#6,d0
.x	rts				;IDA: locret_BC82
