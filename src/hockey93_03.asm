;	NHLPA Hockey 93 (retail) segment $FAE2-$10387
;	92 hockey.asm part 2, first half: checkcoll, checkplcoll, checkcx,
;	newcheck, checkint, checkcheck, the 93-only checkagr, holdcheck, the
;	93-only Bcheck, FallDown and the 93-only setInjuryType.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after assembly.
;	93 SortCords offsets ($80 per object), 92 names in comments where the
;	use matches: Xpos 0, attribute 4, Ypos $14, OldXpos $1C, OldYpos $20,
;	Xvel $28, Yvel $2A, impactp $2E, impact $32, position $34, radiusx $4A,
;	radiusy $4C, Wallcos $4E, Wallsin $50, SCnum $52, facedir $54, SPA $58,
;	nopuck $5E (byte), pflags $62, pflags2 $63, pnum $66, weight $67,
;	legstr $68. $5F is a byte timer that updateplayers counts down. $75 is
;	the checking rating (IDA "Chk rating").
;	pflags bits match 92 (2 pfnc, 3 pfjoycon, 5 pfalock, 6 pfteam). pflags2
;	bit 0 is pf2fight; 93 moved the others: bit 2 player unavailable (92
;	pf2unav = 4), bit 4 caused a penalty (92 pf2pen = 6), bit 5 no player
;	collision (92 pf2npc = 7).
;	SPA values are 93 SPAList offsets; the 92 name in a comment gives the role.
;	93 team struct (tmsize $1A2): $10 check count, $66 tmpdst (word per
;	player), $11C check count per player (byte).

checkcoll	;d2 = new x cord, d3 = new y cord, a3 = struct of object. Check wall collision (around the hot spot and the end of the stick) and player collisions, then move a3 in the OOlist sort order by its y. If a player collision set collflag, restore the old x/y instead. 93 no longer clears Wallcos/Wallsin first. Called from updateplayers
	clr.w	(collflag).w
	btst	#7,(sflags).w		;sfhor
	beq.w	.nhor1
	exg	d2,d3
.nhor1	btst	#2,pflags(a3)		;IDA: loc_FB0A. pfnc
	bne.w	.ex
	movem.l	d0-d7,-(sp)
	move.w	(a3),d2			;Xpos
	move.w	Ypos(a3),d3		;check coll around hot spot with wall
	move.w	$4A(a3),(wcradiusx).w	;wall coll radius x
	move.w	$4C(a3),(wcradiusy).w	;wall coll radius y
	bsr.w	checkwallcoll
	move.w	$4E(a3),d0		;Wallcos
	or.w	$50(a3),d0		;Wallsin
	bne.w	.xx			;coll did happen
	cmpi.w	#$B,$52(a3)		;SCnum
	bgt.w	.xx			;not a player
	movem.l	(sp),d0-d7
	move.l	a3,-(sp)
	bsr.w	GetHot
	move.w	(a3),d2
	move.w	Ypos(a3),d3
	add.w	d0,d2
	add.w	d1,d3			;check coll around end of stick with wall
	move.w	#1,(wcradiusx).w
	move.w	#1,(wcradiusy).w
	bsr.w	checkwallcoll
.xx	movem.l	(sp)+,d0-d7		;IDA: loc_FB68

	bsr.w	checkplcoll		;check coll with other players

;now check order of sprites
.ex	tst.w	(collflag).w		;IDA: loc_FB70
	bne.w	.restoreold
	move.w	$52(a3),d0		;SCnum
	asl.w	#1,d0			;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1		;current objects pos in OOlist
.2	cmp.w	#$F,d1			;IDA: loc_FB8E. Sortobjs-1
	beq.w	.cl2			;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4		;next higher object number
	cmp.w	(a2,d4.w),d3		;y pos of next higher object
	ble.w	.cl2

	addq.w	#1,(a0,d0.w)
	subq.w	#1,(a0,d4.w)

	move.b	d4,(a1,d1.w)
	move.b	d0,1(a1,d1.w)

	addq.w	#1,d1
	bra.s	.2

.cl2	move.w	(a0,d0.w),d1		;IDA: loc_FBB8. current objects pos in OOlist
	beq.w	.ex2
.3	clr.w	d4			;IDA: loc_FBC0
	move.b	-1(a1,d1.w),d4		;next lower object number
	cmp.w	(a2,d4.w),d3		;y pos of next lower object
	bge.w	.ex2

	subq.w	#1,(a0,d0.w)
	addq.w	#1,(a0,d4.w)

	move.b	d4,(a1,d1.w)
	move.b	d0,-1(a1,d1.w)

	subq.w	#1,d1
	bne.s	.3
.ex2	move.w	d3,(a2,d0.w)		;IDA: loc_FBE2. update Ylist
	rts
.restoreold	move.w	$1C(a3),(a3)		;IDA: loc_FBE8. OldXpos
	move.w	$20(a3),Ypos(a3)		;OldYpos
	rts

checkplcoll	;d2/d3 = x/y cords, a3 = struct. Walk up and down the OOlist from a3 and call checkcx for each object within $10 in y (92 collrad*2). Called from checkcoll
	btst	#5,pflags2(a3)		;93 no player coll bit (92 pf2npc = 7)
	bne.w	.ex
	cmpi.w	#$B,$52(a3)		;SCnum
	bgt.w	.ex			;not a player
	move.w	$52(a3),d0
	asl.w	#1,d0			;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1		;current objects pos in OOlist
.0	cmp.w	#$F,d1			;IDA: loc_FC1E. Sortobjs-1
	beq.w	.cl			;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4		;next higher object number
	move.w	(a2,d4.w),d5		;y pos of next higher object
	sub.w	d3,d5
	cmp.w	#$10,d5			;collrad*2
	bgt.w	.cl			;no higher sprite coll
	bsr.w	checkcx
	addq.w	#1,d1
	bra.s	.0

.cl	move.w	(a0,d0.w),d1		;IDA: loc_FC42
	beq.w	.ex
.1	clr.w	d4			;IDA: loc_FC4A
	move.b	-1(a1,d1.w),d4		;next lower object number
	move.w	d3,d5
	sub.w	(a2,d4.w),d5		;y pos of next lower object
	cmp.w	#$10,d5			;collrad*2
	bgt.w	.ex
	bsr.w	checkcx
	subq.w	#1,d1
	bne.s	.1
.ex	rts				;IDA: locret_FC66

checkcx	;d4 = obj. # * 2 for possible coll so check x range and distance for coll. d2 = x, d5 = delta y, a3 = moving object. Opposing players add impact and run newcheck, checkint, checkcheck and checkfight; then momentum moves from a3 to a2. Called from checkplcoll
	movem.l	d0-d7/a0-a3,-(sp)
	asl.w	#6,d4			;obj. # * 2 * $40 = * $80 (92 scsize-1)
	movea.l	#SortCords,a2
	adda.w	d4,a2

	btst	#2,pflags(a2)		;pfnc
	bne.w	.exit			;object has no coll mode on
	btst	#5,pflags2(a2)		;93 no player coll bit (92 pf2npc = 7)
	bne.w	.exit
	cmpi.w	#$B,$52(a2)		;SCnum
	bgt.w	.exit			;not a player

	move.w	(a2),d0			;Xpos
	btst	#7,(sflags).w		;sfhor
	beq.w	.nhor
	move.w	Ypos(a2),d0
.nhor	sub.w	d2,d0			;IDA: loc_FCA4. delta x
	cmp.w	#-$10,d0		;-collrad*2
	blt.w	.exit
	cmp.w	#$10,d0			;collrad*2
	bgt.w	.exit
	muls.w	d5,d5			;delta y^2
	muls.w	d0,d0			;delta x^2
	add.l	d5,d0
	cmp.l	#$100,d0		;(collrad*2)*(collrad*2)
	bgt.w	.exit			;outside of radius

	move.w	#0,(evalue).w
	move.b	pflags(a3),d6
	move.b	pflags(a2),d0
	eor.b	d0,d6

;now do momentum transfer from object a3 to object a2

	move.w	Xvel(a3),d0
	sub.w	Xvel(a2),d0		;Vx
	move.w	$2A(a3),d1		;Yvel
	sub.w	$2A(a2),d1		;Vy

	move.w	(a3),d2			;Xpos
	sub.w	(a2),d2
	neg.w	d2			;Dx
	move.w	Ypos(a3),d3
	sub.w	Ypos(a2),d3
	neg.w	d3			;Dy

	movem.w	d0-d1,-(sp)
	muls.w	d3,d1			;Vy*Dy
	muls.w	d2,d0			;Vx*Dx
	add.l	d0,d1			;(Vy*Dy)+(Vx*Dx)
	bmi.w	.exit4			;no col if v1n < 0
	asr.l	#4,d1

	btst	#6,d6			;pfteam
	beq.w	.not			;players are on same team
	move.w	d1,d4
	lsr.w	#8,d4
	cmp.w	#5,d4
	bgt.w	.g40
	moveq	#5,d4			;minimum impact value
.g40	add.w	d4,$32(a3)		;IDA: loc_FD1C. impact
	add.w	d4,$32(a2)
	btst	#0,pflags2(a2)		;pf2fight
	bne.w	.if
	move.w	$52(a3),$2E(a2)		;SCnum -> impactp
.if	btst	#0,pflags2(a3)		;IDA: loc_FD34. pf2fight
	bne.w	.if2
	move.w	$52(a2),$2E(a3)
.if2	cmp.w	#$14,d4			;IDA: loc_FD44. impact under 20: no check sound
	blt.w	.n1
	move.w	(puckc).w,d0		;check sound only if one of them has the puck
	cmp.w	$52(a3),d0
	beq.w	.nc
	cmp.w	$52(a2),d0
	bne.w	.n1
.nc	bsr.w	newcheck		;IDA: loc_FD60

.n1	bsr.w	checkint		;IDA: loc_FD64
	bsr.w	checkcheck
	bsr.w	checkfight
.not	move.w	d1,d4			;IDA: loc_FD70. V1n

	movem.w	(sp)+,d0-d1
	tst.w	(collflag).w		;set to -1 by holdcheck / Bcheck: no transfer
	bmi.w	.exit

	muls.w	d2,d1			;Vy*Dx
	muls.w	d3,d0			;Vx*Dy
	sub.l	d1,d0			;(Vx*Dy)-(Vy*Dx)
	asr.l	#4,d0
	move.w	d0,d5			;V1t

	clr.w	d0
	move.b	$67(a3),d0		;weight m1
	addi.w	#$8C,d0			;+140
	clr.w	d1
	move.b	$67(a2),d1		;weight m2
	addi.w	#$8C,d1
	move.w	(evalue).w,d7		;e*16 value (0-16)
	mulu.w	d1,d7
	lsr.w	#4,d7			;m2*e
	add.w	d0,d1			;m1+m2
	sub.w	d7,d0			;(m1-m2*e)
	muls.w	d4,d0			;V1n*(m1-m2*e)
	divs.w	d1,d0			;V1n'=(V1n*(m1-m2*e))/(m1+m2)

	move.w	(evalue).w,d1
	muls.w	d4,d1			;V1n*e
	asr.w	#4,d1
	add.w	d0,d1			;V2n'=V1n'+V1n*e

	movem.w	d2-d3,-(sp)		;save Dx,Dy
	muls.w	d5,d3			;V1t'*Dy
	muls.w	d0,d2			;V1n'*Dx
	add.l	d2,d3			;V1t'*Dy+V1n'*Dx
	asr.l	#4,d3
	add.w	Xvel(a2),d3
	move.w	d3,Xvel(a3)

	movem.w	(sp),d2-d3		;restore Dx,Dy
	muls.w	d5,d2			;V1t'*Dx
	muls.w	d0,d3			;V1n'*Dy
	sub.l	d2,d3			;V1n'*Dy-V1t'*Dx
	asr.l	#4,d3
	add.w	$2A(a2),d3		;Yvel
	move.w	d3,$2A(a3)

	movem.w	(sp)+,d2-d3
	muls.w	d1,d2			;V2n'*Dx
	asr.l	#4,d2
	add.w	d2,Xvel(a2)

	muls.w	d1,d3			;V2n'*Dy
	asr.l	#4,d3
	add.w	d3,$2A(a2)

	st	(collflag).w

.exit	movem.l	(sp)+,d0-d7/a0-a3	;IDA: _exit
	rts

.exit4	addq.w	#4,sp			;IDA: loc_FDFC. drop the saved Vx/Vy
	bra.s	.exit

newcheck	;start a new check sound. 93: one of 4 sounds $1C-$1F (92: one of 5 from SFXcheck = 18), never the last one again. Called from checkcx; FallDown branches here when the player who fell did not have the puck
	move.l	d0,-(sp)
	moveq	#3,d0
	bsr.w	randomd0
	addq.w	#1,d0			;1-3 sounds on from the last one
	add.w	(word_FFBF26).w,d0	;last tackle sound (92 ltack)
	andi.w	#3,d0
	move.w	d0,(word_FFBF26).w
	addi.w	#$1C,d0			;first check sound (92 SFXcheck = 18)
	move.w	d0,-(sp)
	bsr.w	sfx			;tackle sound
	move.l	(sp)+,d0
	rts

checkint	;check for interference penalty. player a2 interferes with a3 or vice-versa; goalie is only player who cause an interference call. Called from checkcx
	move.l	d0,-(sp)
	bsr.w	.ci
	exg	a2,a3
	bsr.w	.ci
	exg	a2,a3
	move.l	(sp)+,d0
	rts
.ci	tst.w	$34(a2)			;IDA: checkint_ci. position: a2 must be a goalie
	bne.w	rtss
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss			;no fall downs during celebrate
	move.w	(puckc).w,d0
	cmp.w	$52(a3),d0
	beq.w	.pc			;93: a3 has the puck, skip the $19 test
	cmpi.w	#$19,$32(a3)		;impact of a3 (92 tests impact(a2) > 10)
	ble.w	rtss
.pc	cmpi.w	#2,$32(a3)		;IDA: loc_FE5E. impact
	ble.w	rtss
	exg	a2,a3
	bsr.w	FallDown		;a3 falls
	exg	a2,a3
	cmpi.w	#$1E,$32(a2)		;impact 30
	ble.w	rtss
	btst	#4,pflags2(a3)		;93 penalty bit (92 pf2pen = 6)
	bne.w	rtss			;no double minor
	moveq	#$14,d0			;93: penalty 3 times in (20 - byte $73)
	sub.b	$73(a3),d0
	bsr.w	randomd0
	cmp.w	#2,d0
	bhi.w	rtss
	btst	#4,(gmode).w		;gmhl
	bne.w	rtss
	move.l	#$22,d0			;93 penalty $22 (92 PenInterference = $1C)
	bra.w	AddPenalty

checkcheck	;player is in contact look for various contact events. Runs .cc for a3 on a2, then for a2 on a3. d4 = impact. Called from checkcx
	movem.l	d0-d4/a0-a3,-(sp)
	bsr.w	.cc
	exg	a2,a3
	bsr.w	.cc
	movem.l	(sp)+,d0-d4/a0-a3
	rts

.cc	cmpi.w	#$CB0,$58(a2)		;IDA: CC. player a3 is checking player a2. SPA (92 SPAHold)
	beq.w	holdcheck		;if in hold animation
	cmpi.w	#$12DC,$58(a2)		;93: this anim also holds
	beq.w	holdcheck
	cmpi.w	#$B44,$58(a2)		;93: this anim goes to Bcheck
	beq.w	Bcheck
	cmpi.w	#$C7E,$58(a3)		;92 SPAburst
	bne.w	rtss			;if not in cbut burst anim exit
	btst	#0,(gmode).w		;gmclock
	beq.w	.nofight
	move.w	#$100,$32(a3)		;increased fight chance after clock stops
	move.w	#$100,$32(a2)
.nofight	move.w	(a2),d0			;IDA: _nofight
	sub.w	(a3),d0
	move.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	sub.w	$54(a3),d0		;facedir
	andi.w	#7,d0
	btst	#3,attribute(a3)		;xflip?
	beq.w	.0
	neg.w	d0
	addq.w	#8,d0
	andi.w	#7,d0
.0	asl.w	#1,d0			;IDA: _0
	lea	.list(pc),a0
	move.w	(a0,d0.w),d1
	bset	#5,pflags(a3)		;pfalock
	bsr.w	SetSPA

	tst.w	$34(a2)			;goalie doesn't fall
	beq.w	rtss
	cmp.w	#$14,d4			;impact under 20: no fall
	blt.w	rtss
	moveq	#$78,d0			;start with 120 dec. (92 60)
	btst	#3,pflags(a3)		;pfjoycon: check if player controlled
	beq.w	.00			;branch if not
	asl.w	#1,d0			;mult. by 2
.00	sub.b	$67(a3),d0		;IDA: _00. sub weight
	add.b	$67(a2),d0		;add weight
	lsr.w	#1,d0			;divide by 2
	sub.w	$32(a2),d0		;sub impact
	beq.w	.down
	bmi.w	.down
	bsr.w	randomd0
	cmp.b	$75(a3),d0		;Chk rating (92 aggress)
	ble.w	.down
	bsr.w	checkagr		;93: penalty roll (92 HVcount mask)
	cmp.w	#4,d0
	bhi.w	rtss
	btst	#4,(gmode).w		;gmhl
	bne.w	rtss
	move.b	(VDP_CNTR).l,d0		;HVcount
	andi.w	#2,d0
	addi.w	#$16,d0			;random penalty $16 or $18 (92 PenCharging = $10)
	bra.w	AddPenalty
.down	bsr.w	checkagr		;IDA: _down
	cmp.w	#3,d0
	bhi.w	.dn2
	btst	#4,(gmode).w		;gmhl
	bne.w	.dn2
	move.b	(VDP_CNTR).l,d0		;HVcount
	andi.w	#2,d0
	addi.w	#$1A,d0			;penalty $1A or $1C (92 PenTripping = $14, and #%110)
	bsr.w	AddPenalty
.dn2	bra.w	FallDown		;IDA: _dn2

.list	dc.w	$BB6			;IDA: list. 92 SPAshoulderchkl
	dc.w	$BE8			;92 SPAshoulderchkr
	dc.w	$C4C			;92 SPAhipchkr
	dc.w	$C4C			;92 SPAhipchkr
	dc.w	$C4C			;92 SPAhipchkr
	dc.w	$C1A			;92 SPAhipchkl
	dc.w	$C1A			;92 SPAhipchkl
	dc.w	$BB6			;92 SPAshoulderchkl

checkagr	;93: penalty roll for player a3. Range = (20 - byte $73) * 13, doubled for a joystick player, halved within $28 of the puck in x and y. Return d0 = randomd0 of that range; the callers call a penalty when it is small. Called from checkcheck .cc, holdcheck and Bcheck
	moveq	#$14,d0
	sub.b	$73(a3),d0
	mulu.w	#$D,d0
	btst	#3,pflags(a3)		;pfjoycon
	beq.w	.nojoy
	asl.w	#1,d0			;joystick player: twice the range, fewer penalties
.nojoy	move.w	(a3),d1			;IDA: loc_FFF4. Xpos
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
	asr.w	#1,d0			;near the puck: half the range, more penalties
.far	bra.w	randomd0		;IDA: loc_10024

holdcheck	;player a2 is in hold animation looking to hold opponent a3. Entered from checkcheck .cc for SPA $CB0 (92 SPAHold) or $12DC. 93 adds the facing test, the puck carrier sflags clear and the second hold anim, and rolls the penalty with checkagr
	btst	#5,pflags(a3)		;pfalock
	bne.w	rtss
	tst.w	$34(a3)			;position
	beq.w	rtss			;no hold on goalies
	btst	#0,pflags2(a3)		;pf2fight
	bne.w	rtss			;no hold on fighters
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa			;direction from a2 to a3
	sub.w	$54(a2),d0		;facedir
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	rtss			;93: a3 must be within 1 direction of where a2 faces
	move.w	(puckc).w,d0
	cmp.w	$52(a3),d0
	bne.w	.nopc
	bclr	#3,(sflags).w		;a3 has the puck: clear sfssdir
.nopc	move.w	Xvel(a3),d0		;IDA: loc_10078
	add.w	Xvel(a2),d0
	asr.w	#1,d0
	move.w	d0,Xvel(a3)
	move.w	d0,Xvel(a2)
	move.w	$2A(a3),d0		;Yvel
	add.w	$2A(a2),d0
	asr.w	#1,d0
	move.w	d0,$2A(a3)
	move.w	d0,$2A(a2)
	bset	#5,pflags(a3)		;pfalock
	move.w	#$D14,d1		;92 SPAFlail
	bsr.w	SetSPA
	exg	a2,a3
	bset	#5,pflags(a3)
	move.w	#$CE2,d1		;92 SPAHold2
	cmpi.w	#$CB0,$58(a3)		;92 SPAHold
	beq.w	.h2
	move.w	#$130E,d1		;93: holding anim after $12DC
.h2	bsr.w	SetSPA			;IDA: loc_100C4
	bsr.w	checkagr
	cmp.w	#6,d0
	bhi.w	.ex
	move.w	#$24,d0			;penalty $24 after $CE2 (92 PenHolding = $1E)
	cmpi.w	#$CE2,$58(a3)
	beq.w	.pen
	move.w	#$1E,d0			;penalty $1E after $130E
.pen	bsr.w	AddPenalty		;IDA: loc_100E6
.ex	exg	a2,a3			;IDA: loc_100EA
	st	(collflag).w
	rts

Bcheck	;93: player a2 is in SPA $B44 and a3 is the other player. Entered from checkcheck .cc. If OptPen is 0 and a2 is joystick controlled, a2 needs randomd0($10 + a2 checking rating - a3 legstr) >= $C. If a3 is within 1 direction of where a2 faces, a3 falls and checkagr may call penalty $20 on a2. Sets collflag to -1
	btst	#5,pflags(a3)		;pfalock
	bne.w	rtss
	tst.w	$34(a3)			;position: not on a goalie
	beq.w	rtss
	btst	#0,pflags2(a3)		;pf2fight
	bne.w	rtss
	tst.w	(OptPen).w
	bne.w	.dir
	btst	#3,pflags(a2)		;pfjoycon
	beq.w	.dir
	moveq	#$10,d0
	add.b	$75(a2),d0		;checking rating
	sub.b	$68(a3),d0		;legstr
	bsr.w	randomd0
	cmp.w	#$C,d0
	blt.w	rtss
.dir	move.w	(a3),d0			;IDA: loc_10136
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa			;direction from a2 to a3
	sub.w	$54(a2),d0		;facedir
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	rtss
	exg	a2,a3
	bsr.w	FallDown		;a3 falls, a2 is the hitter
	bsr.w	checkagr
	cmp.w	#4,d0
	bhi.w	.ex
	move.w	#$20,d0
	bsr.w	AddPenalty
.ex	exg	a2,a3			;IDA: loc_10172
	st	(collflag).w
	rts

FallDown	;player a2 falls down, player a3 is the hitting player. 93 adds anim $13A0 in place of a fall for some players, check stats for the hitter, a third fall anim ($1524), and injuries (setInjuryType) with a penalty. Called from checkint .ci, checkcheck .cc and Bcheck; also entered from setd0player (hockey93_05)
	cmpi.w	#$B,$52(a2)		;SCnum
	bgt.w	rtss			;not a player
	btst	#0,pflags2(a2)		;pf2fight
	bne.w	rtss
	cmpi.w	#$1616,$58(a2)		;SPA: already in one of the fall anims
	beq.w	rtss
	cmpi.w	#$13A0,$58(a2)
	beq.w	rtss
	cmpi.w	#$D46,$58(a2)		;92 SPAfallfwd
	beq.w	rtss
	cmpi.w	#$DF8,$58(a2)		;92 SPAfallback
	beq.w	rtss
	cmpi.w	#$1524,$58(a2)
	beq.w	rtss
	move.w	#$13A0,d1		;93: anim $13A0 instead of a fall when byte $71 >= $C,
	cmpi.b	#$C,$71(a2)		;timer $5F is 0 and impact < $10-$1F (HVcount)
	blt.w	.fall
	tst.b	$5F(a2)
	bne.w	.fall
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#$F,d0
	addi.w	#$10,d0
	cmp.w	$32(a2),d0		;impact
	ble.w	.fall
	move.b	#$3C,$5F(a2)		;no second $13A0 until the timer runs out
	bra.w	.2

.fall	tst.w	$34(a3)			;IDA: loc_101F6. position: no check stats for a goalie hitter
	beq.w	.nostat
	movea.w	#(hmtmstruct-M68K_RAM),a0
	btst	#6,pflags(a3)		;pfteam
	beq.w	.tm
	adda.w	#$1A2,a0		;tmsize
.tm	addq.w	#1,$10(a0)		;IDA: loc_10210. team check count
	clr.w	d0
	move.b	$66(a3),d0		;pnum
	adda.w	d0,a0
	addq.b	#1,$11C(a0)		;player check count
	addq.w	#1,(ChkCnt).w
	tst.b	$74(a3)
	bne.w	.nostat
	addq.w	#2,(ChkCnt).w		;byte $74 is 0: ChkCnt +3
.nostat	move.b	#$78,$5E(a2)		;IDA: loc_10230. nopuck = 120
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa			;direction from a2 to the hitter
	move.w	#$DF8,d1		;92 SPAfallback
	sub.w	$54(a2),d0		;facedir
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bls.w	.2			;hit from the front: fall back
	move.w	#$D46,d1		;92 SPAfallfwd
	move.w	$54(a2),d0
	andi.w	#3,d0
	bne.w	.2
	cmpi.b	#$A,$75(a3)		;93: facedir 0 or 4 and hitter checking rating >= $A
	blt.w	.2
	cmpi.w	#$B,$52(a3)		;and the hitter is a player
	bgt.w	.2
	move.w	#$1524,d1		;93 third fall anim
.2	exg	a2,a3			;IDA: loc_10284
	bset	#5,pflags(a3)		;pfalock
	bsr.w	SetSPA
	exg	a2,a3

	addi.w	#$12C,(crowdlevel).w	;300
	addi.w	#$F,(CwdExciteLvl).w	;93

	move.w	(puckc).w,d0
	bmi.w	newcheck
	cmp.w	$52(a2),d0
	bne.w	newcheck		;a2 did not have the puck: check sound only
	st	(puckc).w
	btst	#4,(gmode).w		;gmhl: no injury in highlights
	bne.w	.snd
	cmpi.w	#$DF8,$58(a2)		;93 injury: only from a fall back (92 SPAfallback)
	bne.w	.snd
	move.w	$54(a2),d0
	andi.w	#3,d0			;with facedir 0 or 4
	bne.w	.snd
	btst	#4,pflags2(a2)		;93 penalty bit (92 pf2pen = 6)
	bne.w	.snd
	move.l	#$A0,d0
	bsr.w	randomd0
	cmp.w	$32(a2),d0		;injured if randomd0(160) <= impact
	bgt.w	.snd
	btst	#0,(gmode).w		;gmclock
	bne.w	.snd
	exg	a2,a3
	move.w	#$1616,d1		;injured anim
	bsr.w	SetSPA
	exg	a2,a3
	bsr.w	setInjuryType
	move.w	#4,(InjCntDown).w
	move.l	#$14,d0			;penalty $14 if the hitter is a goalie or OptPen is 0
	tst.w	$34(a3)
	beq.w	AddPenalty2
	tst.w	(OptPen).w
	beq.w	AddPenalty2
	move.l	#$12,d0			;else penalty $12, then Stop4Pen
	bsr.w	AddPenalty2
	bra.w	Stop4Pen
.snd	move.w	#$B,-(sp)		;IDA: loc_10332. 92 SFXcrowdcheer = 25 via SFX
	btst	#6,pflags(a2)		;pfteam
	bne.w	.3
	move.w	#$C,(sp)		;92 SFXcrowdboo = 26
.3	bsr.w	song			;IDA: _3
	rts

setInjuryType	;93: sets period injury. a2 = player injured, a3 = player checking. Marks a2 unavailable, pumps up the crowd, plays sfx $D, locks the scroll on a2, sets TempPlOffset (pnum, bit 15 set for the away team) and puts $FFFD (injured for the period) in a2's tmpdst. Called from FallDown and from logic93_2 chkhit .fall (IDA FightFall)
	bset	#2,pflags2(a2)		;set player unavailable (92 pf2unav = 4)
	addi.w	#$12C,(crowdlevel).w	;pump up crowd
	addi.w	#$1E,(CwdExciteLvl).w
	move.w	#$D,-(sp)		;SFX
	bsr.w	sfx
	move.w	(a2),(xc1).w		;move X and Y pos to scroll center
	move.w	Ypos(a2),(yc1).w
	bset	#6,(sflags).w		;sfslock (scroll lock)
	clr.w	d1
	movea.w	#(hmtmstruct-M68K_RAM),a0	;Home team struct into a0
	btst	#6,pflags(a2)		;pfteam: check if home or away
	beq.w	.0			;branch if home
	move.w	#$8000,d1		;away team flag
	adda.w	#$1A2,a0		;tmsize: away team struct
.0	move.b	$66(a2),d1		;IDA: _0. pnum: roster offset
	move.w	d1,(TempPlOffset).w
	ext.w	d1			;drop the away team flag
	add.w	d1,d1
	move.w	#$FFFD,$66(a0,d1.w)	;tmpdst: $FFFD = injury for period
	rts
