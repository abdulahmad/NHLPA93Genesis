;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $FAE2-$10387
;	92 hockey.asm part 2, first half: checkcoll, checkplcoll, checkcx,
;	newcheck, checkint, checkcheck, the 93-only checkagr, holdcheck, the
;	93-only Bcheck, FallDown and the 93-only setInjuryType.
;Global names from the 92 names where the routine is the
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
;the checking rating ("Chk rating").
;	pflags bits match 92 (2 pfnc, 3 pfjoycon, 5 pfalock, 6 pfteam). pflags2
;	bit 0 is pf2fight; 93 moved the others: bit 2 player unavailable (92
;	pf2unav = 4), bit 4 caused a penalty (92 pf2pen = 6), bit 5 no player
;	collision (92 pf2npc = 7).
;	SPA values are 93 SPAList offsets; the 92 name in a comment gives the role.
;	93 team struct (tmsize $1A2): $10 check count, $66 tmpdst (word per
;	player), $11C check count per player (byte).

checkcoll	;d2 = new x cord, d3 = new y cord, a3 = struct of object. Check wall collision (around the hot spot and the end of the stick) and player collisions, then move a3 in the OOlist sort order by its y. If a player collision set collflag, restore the old x/y instead. 93 no longer clears Wallcos/Wallsin first. Called from updateplayers
	clr.w	(collflag).w
	btst	#sfhor,(sflags).w
	beq.w	.nhor1
	exg	d2,d3
.nhor1	btst	#pfnc,pflags(a3)
	bne.w	.ex
	movem.l	d0-d7,-(sp)
	move.w	(a3),d2			;Xpos
	move.w	Ypos(a3),d3		;check coll around hot spot with wall
	move.w	radiusx(a3),(wcradiusx).w	;wall coll radius x
	move.w	radiusy(a3),(wcradiusy).w	;wall coll radius y
	bsr.w	checkwallcoll
	move.w	Wallcos(a3),d0
	or.w	Wallsin(a3),d0
	bne.w	.xx			;coll did happen
	cmpi.w	#$B,SCnum(a3)
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
.xx	movem.l	(sp)+,d0-d7

	bsr.w	checkplcoll		;check coll with other players

;now check order of sprites
.ex	tst.w	(collflag).w
	bne.w	.restoreold
	move.w	SCnum(a3),d0
	asl.w	#1,d0			;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1		;current objects pos in OOlist
.2	cmp.w	#$F,d1			;Sortobjs-1
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

.cl2	move.w	(a0,d0.w),d1		;current objects pos in OOlist
	beq.w	.ex2
.3	clr.w	d4
	move.b	-1(a1,d1.w),d4		;next lower object number
	cmp.w	(a2,d4.w),d3		;y pos of next lower object
	bge.w	.ex2

	subq.w	#1,(a0,d0.w)
	addq.w	#1,(a0,d4.w)

	move.b	d4,(a1,d1.w)
	move.b	d0,-1(a1,d1.w)

	subq.w	#1,d1
	bne.s	.3
.ex2	move.w	d3,(a2,d0.w)		;update Ylist
	rts
.restoreold	move.w	OldXpos(a3),(a3)
	move.w	OldYpos(a3),Ypos(a3)
	rts

checkplcoll	;d2/d3 = x/y cords, a3 = struct. Walk up and down the OOlist from a3 and call checkcx for each object within $10 in y (92 collrad*2). Called from checkcoll
	btst	#pf2npc,pflags2(a3)		;93 no player coll bit (92 pf2npc = 7)
	bne.w	.ex
	cmpi.w	#$B,SCnum(a3)
	bgt.w	.ex			;not a player
	move.w	SCnum(a3),d0
	asl.w	#1,d0			;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	(a0,d0.w),d1		;current objects pos in OOlist
.0	cmp.w	#$F,d1			;Sortobjs-1
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

.cl	move.w	(a0,d0.w),d1
	beq.w	.ex
.1	clr.w	d4
	move.b	-1(a1,d1.w),d4		;next lower object number
	move.w	d3,d5
	sub.w	(a2,d4.w),d5		;y pos of next lower object
	cmp.w	#$10,d5			;collrad*2
	bgt.w	.ex
	bsr.w	checkcx
	subq.w	#1,d1
	bne.s	.1
.ex	rts

checkcx	;d4 = obj. # * 2 for possible coll so check x range and distance for coll. d2 = x, d5 = delta y, a3 = moving object. Opposing players add impact and run newcheck, checkint, checkcheck and checkfight; then momentum moves from a3 to a2. Called from checkplcoll
	movem.l	d0-d7/a0-a3,-(sp)
	asl.w	#6,d4			;obj. # * 2 * $40 = * $80 (92 scsize-1)
	movea.l	#SortCords,a2
	adda.w	d4,a2

	btst	#pfnc,pflags(a2)
	bne.w	.exit			;object has no coll mode on
	btst	#pf2npc,pflags2(a2)		;93 no player coll bit (92 pf2npc = 7)
	bne.w	.exit
	cmpi.w	#$B,SCnum(a2)
	bgt.w	.exit			;not a player

	move.w	(a2),d0			;Xpos
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	move.w	Ypos(a2),d0
.nhor	sub.w	d2,d0			;delta x
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
	move.w	Yvel(a3),d1
	sub.w	Yvel(a2),d1		;Vy

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

	btst	#pfteam,d6
	beq.w	.not			;players are on same team
	move.w	d1,d4
	lsr.w	#8,d4
	cmp.w	#5,d4
	bgt.w	.g40
	moveq	#5,d4			;minimum impact value
.g40	add.w	d4,impact(a3)
	add.w	d4,impact(a2)
	btst	#pf2fight,pflags2(a2)
	bne.w	.if
	move.w	SCnum(a3),impactp(a2)		;SCnum -> impactp
.if	btst	#pf2fight,pflags2(a3)
	bne.w	.if2
	move.w	SCnum(a2),impactp(a3)
.if2	cmp.w	#$14,d4			;impact under 20: no check sound
	blt.w	.n1
	move.w	(puckc).w,d0		;check sound only if one of them has the puck
	cmp.w	SCnum(a3),d0
	beq.w	.nc
	cmp.w	SCnum(a2),d0
	bne.w	.n1
.nc	bsr.w	newcheck

.n1	bsr.w	checkint
	bsr.w	checkcheck
	bsr.w	checkfight
.not	move.w	d1,d4			;V1n

	movem.w	(sp)+,d0-d1
	tst.w	(collflag).w		;set to -1 by holdcheck / Bcheck: no transfer
	bmi.w	.exit

	muls.w	d2,d1			;Vy*Dx
	muls.w	d3,d0			;Vx*Dy
	sub.l	d1,d0			;(Vx*Dy)-(Vy*Dx)
	asr.l	#4,d0
	move.w	d0,d5			;V1t

	clr.w	d0
	move.b	weight(a3),d0		;weight m1
	addi.w	#$8C,d0			;+140
	clr.w	d1
	move.b	weight(a2),d1		;weight m2
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
	add.w	Yvel(a2),d3
	move.w	d3,Yvel(a3)

	movem.w	(sp)+,d2-d3
	muls.w	d1,d2			;V2n'*Dx
	asr.l	#4,d2
	add.w	d2,Xvel(a2)

	muls.w	d1,d3			;V2n'*Dy
	asr.l	#4,d3
	add.w	d3,Yvel(a2)

	st	(collflag).w

.exit	movem.l	(sp)+,d0-d7/a0-a3
	rts

.exit4	addq.w	#4,sp			;drop the saved Vx/Vy
	bra.s	.exit

newcheck	;start a new check sound. 93: one of 4 sounds $1C-$1F (92: one of 5 from SFXcheck = 18), never the last one again. Called from checkcx; FallDown branches here when the player who fell did not have the puck
	move.l	d0,-(sp)
	moveq	#3,d0
	bsr.w	randomd0
	addq.w	#1,d0			;1-3 sounds on from the last one
	add.w	(ltack).w,d0	;last tackle sound
	andi.w	#3,d0
	move.w	d0,(ltack).w
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
.ci	tst.w	position(a2)			;position: a2 must be a goalie
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	rtss			;no fall downs during celebrate
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	beq.w	.pc			;93: a3 has the puck, skip the $19 test
	cmpi.w	#$19,impact(a3)		;impact of a3 (92 tests impact(a2) > 10)
	ble.w	rtss
.pc	cmpi.w	#2,impact(a3)
	ble.w	rtss
	exg	a2,a3
	bsr.w	FallDown		;a3 falls
	exg	a2,a3
	cmpi.w	#$1E,impact(a2)		;impact 30
	ble.w	rtss
	btst	#pf2pen,pflags2(a3)		;93 penalty bit (92 pf2pen = 6)
	bne.w	rtss			;no double minor
	moveq	#$14,d0			;93: penalty 3 times in (20 - byte $73)
	sub.b	aggress(a3),d0
	bsr.w	randomd0
	cmp.w	#2,d0
	bhi.w	rtss
	btst	#gmhl,(gmode).w
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

.cc	cmpi.w	#$CB0,SPA(a2)		;player a3 is checking player a2. SPA (92 SPAHold)
	beq.w	holdcheck		;if in hold animation
	cmpi.w	#$12DC,SPA(a2)		;93: this anim also holds
	beq.w	holdcheck
	cmpi.w	#$B44,SPA(a2)		;93: this anim goes to Bcheck
	beq.w	Bcheck
	cmpi.w	#$C7E,SPA(a3)		;92 SPAburst
	bne.w	rtss			;if not in cbut burst anim exit
	btst	#gmclock,(gmode).w
	beq.w	.nofight
	move.w	#$100,impact(a3)		;increased fight chance after clock stops
	move.w	#$100,impact(a2)
.nofight	move.w	(a2),d0
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
.0	asl.w	#1,d0
	lea	.list(pc),a0
	move.w	(a0,d0.w),d1
	bset	#pfalock,pflags(a3)
	bsr.w	SetSPA

	tst.w	position(a2)			;goalie doesn't fall
	beq.w	rtss
	cmp.w	#$14,d4			;impact under 20: no fall
	blt.w	rtss
	moveq	#$78,d0			;start with 120 dec. (92 60)
	btst	#pfjoycon,pflags(a3)		;check if player controlled
	beq.w	.00			;branch if not
	asl.w	#1,d0			;mult. by 2
.00	sub.b	weight(a3),d0		;sub weight
	add.b	weight(a2),d0		;add weight
	lsr.w	#1,d0			;divide by 2
	sub.w	impact(a2),d0		;sub impact
	beq.w	.down
	bmi.w	.down
	bsr.w	randomd0
	cmp.b	$75(a3),d0		;Chk rating (92 aggress)
	ble.w	.down
	bsr.w	checkagr		;93: penalty roll (92 HVcount mask)
	cmp.w	#4,d0
	bhi.w	rtss
	btst	#gmhl,(gmode).w
	bne.w	rtss
	move.b	(VDP_CNTR).l,d0		;HVcount
	andi.w	#2,d0
	addi.w	#$16,d0			;random penalty $16 or $18 (92 PenCharging = $10)
	bra.w	AddPenalty
.down	bsr.w	checkagr
	cmp.w	#3,d0
	bhi.w	.dn2
	btst	#gmhl,(gmode).w
	bne.w	.dn2
	move.b	(VDP_CNTR).l,d0		;HVcount
	andi.w	#2,d0
	addi.w	#$1A,d0			;penalty $1A or $1C (92 PenTripping = $14, and #%110)
	bsr.w	AddPenalty
.dn2	bra.w	FallDown

.list	dc.w	$BB6			;92 SPAshoulderchkl
	dc.w	$BE8			;92 SPAshoulderchkr
	dc.w	$C4C			;92 SPAhipchkr
	dc.w	$C4C			;92 SPAhipchkr
	dc.w	$C4C			;92 SPAhipchkr
	dc.w	$C1A			;92 SPAhipchkl
	dc.w	$C1A			;92 SPAhipchkl
	dc.w	$BB6			;92 SPAshoulderchkl

checkagr	;93: penalty roll for player a3. Range = (20 - byte $73) * 13, doubled for a joystick player, halved within $28 of the puck in x and y. Return d0 = randomd0 of that range; the callers call a penalty when it is small. Called from checkcheck .cc, holdcheck and Bcheck
	moveq	#$14,d0
	sub.b	aggress(a3),d0
	mulu.w	#$D,d0
	btst	#pfjoycon,pflags(a3)
	beq.w	.nojoy
	asl.w	#1,d0			;joystick player: twice the range, fewer penalties
.nojoy	move.w	(a3),d1			;Xpos
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
.far	bra.w	randomd0

holdcheck	;player a2 is in hold animation looking to hold opponent a3. Entered from checkcheck .cc for SPA $CB0 (92 SPAHold) or $12DC. 93 adds the facing test, the puck carrier sflags clear and the second hold anim, and rolls the penalty with checkagr
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	tst.w	position(a3)
	beq.w	rtss			;no hold on goalies
	btst	#pf2fight,pflags2(a3)
	bne.w	rtss			;no hold on fighters
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa			;direction from a2 to a3
	sub.w	facedir(a2),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	rtss			;93: a3 must be within 1 direction of where a2 faces
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.nopc
	bclr	#sfssdir,(sflags).w		;a3 has the puck
.nopc	move.w	Xvel(a3),d0
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
	move.w	#$D14,d1		;92 SPAFlail
	bsr.w	SetSPA
	exg	a2,a3
	bset	#5,pflags(a3)
	move.w	#$CE2,d1		;92 SPAHold2
	cmpi.w	#$CB0,SPA(a3)		;92 SPAHold
	beq.w	.h2
	move.w	#$130E,d1		;93: holding anim after $12DC
.h2	bsr.w	SetSPA
	bsr.w	checkagr
	cmp.w	#6,d0
	bhi.w	.ex
	move.w	#$24,d0			;penalty $24 after $CE2 (92 PenHolding = $1E)
	cmpi.w	#$CE2,SPA(a3)
	beq.w	.pen
	move.w	#$1E,d0			;penalty $1E after $130E
.pen	bsr.w	AddPenalty
.ex	exg	a2,a3
	st	(collflag).w
	rts

Bcheck	;93: player a2 is in SPA $B44 and a3 is the other player. Entered from checkcheck .cc. If OptPen is 0 and a2 is joystick controlled, a2 needs randomd0($10 + a2 checking rating - a3 legstr) >= $C. If a3 is within 1 direction of where a2 faces, a3 falls and checkagr may call penalty $20 on a2. Sets collflag to -1
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
	add.b	$75(a2),d0		;checking rating
	sub.b	legstr(a3),d0
	bsr.w	randomd0
	cmp.w	#$C,d0
	blt.w	rtss
.dir	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa			;direction from a2 to a3
	sub.w	facedir(a2),d0
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
.ex	exg	a2,a3
	st	(collflag).w
	rts

FallDown	;player a2 falls down, player a3 is the hitting player. 93 adds anim $13A0 in place of a fall for some players, check stats for the hitter, a third fall anim ($1524), and injuries (setInjuryType) with a penalty. Called from checkint .ci, checkcheck .cc and Bcheck; also entered from setd0player (hockey93_03_05)
	cmpi.w	#$B,SCnum(a2)
	bgt.w	rtss			;not a player
	btst	#pf2fight,pflags2(a2)
	bne.w	rtss
	cmpi.w	#$1616,SPA(a2)		;SPA: already in one of the fall anims
	beq.w	rtss
	cmpi.w	#$13A0,SPA(a2)
	beq.w	rtss
	cmpi.w	#$D46,SPA(a2)		;92 SPAfallfwd
	beq.w	rtss
	cmpi.w	#$DF8,SPA(a2)		;92 SPAfallback
	beq.w	rtss
	cmpi.w	#$1524,SPA(a2)
	beq.w	rtss
	move.w	#$13A0,d1		;93: anim $13A0 instead of a fall when byte $71 >= $C,
	cmpi.b	#$C,$71(a2)		;timer $5F is 0 and impact < $10-$1F (HVcount)
	blt.w	.fall
	tst.b	$5F(a2)
	bne.w	.fall
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#$F,d0
	addi.w	#$10,d0
	cmp.w	impact(a2),d0
	ble.w	.fall
	move.b	#$3C,$5F(a2)		;no second $13A0 until the timer runs out
	bra.w	.2

.fall	tst.w	position(a3)			;position: no check stats for a goalie hitter
	beq.w	.nostat
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a3)
	beq.w	.tm
	adda.w	#tmsize,a0
.tm	addq.w	#1,$10(a0)		;team check count
	clr.w	d0
	move.b	pnum(a3),d0
	adda.w	d0,a0
	addq.b	#1,$11C(a0)		;player check count
	addq.w	#1,(ChkCnt).w
	tst.b	$74(a3)
	bne.w	.nostat
	addq.w	#2,(ChkCnt).w		;byte $74 is 0: ChkCnt +3
.nostat	move.b	#$78,nopuck(a2)		;nopuck = 120
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bsr.w	vtoa			;direction from a2 to the hitter
	move.w	#$DF8,d1		;92 SPAfallback
	sub.w	facedir(a2),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bls.w	.2			;hit from the front: fall back
	move.w	#$D46,d1		;92 SPAfallfwd
	move.w	facedir(a2),d0
	andi.w	#3,d0
	bne.w	.2
	cmpi.b	#$A,$75(a3)		;93: facedir 0 or 4 and hitter checking rating >= $A
	blt.w	.2
	cmpi.w	#$B,SCnum(a3)		;and the hitter is a player
	bgt.w	.2
	move.w	#$1524,d1		;93 third fall anim
.2	exg	a2,a3
	bset	#pfalock,pflags(a3)
	bsr.w	SetSPA
	exg	a2,a3

	addi.w	#$12C,(crowdlevel).w	;300
	addi.w	#$F,(CwdExciteLvl).w	;93

	move.w	(puckc).w,d0
	bmi.w	newcheck
	cmp.w	SCnum(a2),d0
	bne.w	newcheck		;a2 did not have the puck: check sound only
	st	(puckc).w
	btst	#gmhl,(gmode).w		;no injury in highlights
	bne.w	.snd
	cmpi.w	#$DF8,SPA(a2)		;93 injury: only from a fall back (92 SPAfallback)
	bne.w	.snd
	move.w	facedir(a2),d0
	andi.w	#3,d0			;with facedir 0 or 4
	bne.w	.snd
	btst	#pf2pen,pflags2(a2)		;93 penalty bit (92 pf2pen = 6)
	bne.w	.snd
	move.l	#$A0,d0
	bsr.w	randomd0
	cmp.w	impact(a2),d0		;injured if randomd0(160) <= impact
	bgt.w	.snd
	btst	#gmclock,(gmode).w
	bne.w	.snd
	exg	a2,a3
	move.w	#$1616,d1		;injured anim
	bsr.w	SetSPA
	exg	a2,a3
	bsr.w	setInjuryType
	move.w	#4,(InjCntDown).w
	move.l	#$14,d0			;penalty $14 if the hitter is a goalie or OptPen is 0
	tst.w	position(a3)
	beq.w	AddPenalty2
	tst.w	(OptPen).w
	beq.w	AddPenalty2
	move.l	#$12,d0			;else penalty $12, then Stop4Pen
	bsr.w	AddPenalty2
	bra.w	Stop4Pen
.snd	move.w	#$B,-(sp)		;92 SFXcrowdcheer = 25 via SFX
	btst	#pfteam,pflags(a2)
	bne.w	.3
	move.w	#$C,(sp)		;92 SFXcrowdboo = 26
.3	bsr.w	song
	rts

setInjuryType	;93: sets period injury. a2 = player injured, a3 = player checking. Marks a2 unavailable, pumps up the crowd, plays sfx $D, locks the scroll on a2, sets TempPlOffset (pnum, bit 15 set for the away team) and puts $FFFD (injured for the period) in a2's tmpdst. Called from FallDown and from logic93 chkhit.fall
	bset	#pf2unav,pflags2(a2)		;set player unavailable (92 pf2unav = 4)
	addi.w	#$12C,(crowdlevel).w	;pump up crowd
	addi.w	#$1E,(CwdExciteLvl).w
	move.w	#SFX0D,-(sp)		;SFX
	bsr.w	sfx
	move.w	(a2),(xc1).w		;move X and Y pos to scroll center
	move.w	Ypos(a2),(yc1).w
	bset	#sfslock,(sflags).w		;scroll lock
	clr.w	d1
	movea.w	#(tmstruct-M68K_RAM),a0	;Home team struct into a0
	btst	#pfteam,pflags(a2)		;check if home or away
	beq.w	.0			;branch if home
	move.w	#$8000,d1		;away team flag
	adda.w	#tmsize,a0		;tmsize: away team struct
.0	move.b	pnum(a2),d1		;pnum: roster offset
	move.w	d1,(TempPlOffset).w
	ext.w	d1			;drop the away team flag
	add.w	d1,d1
	move.w	#$FFFD,tmpdst(a0,d1.w)	;tmpdst: $FFFD = injury for period
	rts

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $10388-$10E65
;	92 hockey.asm part 2, second half: checkfight, SetInst, checkwallcoll,
;	checkgoal, Goal, the 93-only GetPeriodTimeRemaining, checkgoalp,
;	CheckBump, wallcollb, wallcoll and checkpuckcoll.
;Global names from the 92 names where the routine is the
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
;("fight value").
;	pflags bits match 92 (2 pfnc, 5 pfalock, 6 pfteam, 7 pfgoal). pflags2
;	bit 0 is pf2fight and bit 1 pf2aip; 93 moved the others: bit 2 player
;	unavailable (92 pf2unav = 4), bit 4 caused a penalty (92 pf2pen = 6),
;	bit 5 no player collision (92 pf2npc = 7).
;	SPA values are 93 SPAList offsets, penalty numbers are 93 Penaltylist
;	offsets and sound numbers are 93 sfx numbers; the 92 name in a comment
;	gives the role and the 92 value.
;	93 team struct (tmsize $1A2): $C (Goal adds 1, as 92 tmscore), $22 first
;	sort obj (92 tmsort, a word here), $11C check count per player (byte).

checkfight	;look for start of fight between players a2 & a3. Called from checkcx (hockey93_03_05)
	;93 needs impact >= 10 on both, no anim lock, no penalty, no goalie, clock
	;running, no highlight and the puck not fighting or on a faceoff. SetInst
	;(both ways) decides, with d0 = 10 + max(0, 40 - ChkCnt)/4. If a3 then has
	;pf2fight, both players start fighting and everyone else watches
	cmpi.w	#$A,impact(a3)
	blt.w	rtss			;a3 impact < 10
	cmpi.w	#$A,impact(a2)
	blt.w	rtss			;a2 impact < 10
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#pfalock,pflags(a2)
	bne.w	rtss
	btst	#pf2pen,pflags2(a3)		;caused a penalty (92 pf2pen = 6)
	bne.w	rtss
	btst	#pf2pen,pflags2(a2)
	bne.w	rtss
	tst.w	position(a3)
	beq.w	rtss			;no fights with goalies
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
	cmpi.b	#$1B,asslist(a0,d0.w)	;pfaceoff (92 same)
	beq.w	.ex
	moveq	#$28,d0			;40 - ChkCnt
	sub.w	(ChkCnt).w,d0
	bpl.w	.pos
	clr.w	d0
.pos	lsr.w	#2,d0
	addi.w	#$A,d0			;d0 = fight rating needed by SetInst
	bsr.w	SetInst
	exg	a2,a3
	bsr.w	SetInst
	exg	a2,a3
	btst	#pf2fight,pflags2(a3)		;set by SetInst?
	beq.w	.ex			;no fight
	clr.w	(ChkCnt).w
	moveq	#$19,d0			;26 players per team
	movea.w	#(tmstruct+$11C-M68K_RAM),a0	;check count per player
.clr	clr.b	tmsize(a0)		;away team
	clr.b	(a0)+			;home team
	dbf	d0,.clr
	addi.w	#$3E8,(crowdlevel).w	;add 1000
	addi.w	#$23,(CwdExciteLvl).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
	move.w	SCnum(a3),(puckc).w
	move.w	Ypos(a3),d1		;93 sets only yc1 (92 also set a clamped xc1)
	add.w	Ypos(a2),d1
	asr.w	#1,d1
	move.w	d1,(yc1).w
	bset	#sfslock,(sflags).w
	moveq	#2,d1			;make the players face each other
	move.w	(a3),d0
	cmp.w	(a2),d0
	blt.w	.1
	eori.w	#7,d1			;d1 = 5
.1	move.w	d1,facedir(a3)
	eori.w	#7,d1
	move.w	d1,facedir(a2)
	move.l	a3,-(sp)
	bsr.w	.sf
	exg	a2,a3
	bsr.w	.sf
	movea.w	#(SortCords-M68K_RAM),a3
	move.l	#$15,d0			;afwatch (92 same), other players watch fight
	moveq	#$B,d1
.0	btst	#pf2fight,pflags2(a3)
	bne.w	.next
	tst.w	position(a3)			;goalie
	beq.w	.next
	btst	#pf2unav,pflags2(a3)		;unavailable (92 pf2unav = 4)
	bne.w	.next
	bsr.w	assinsert
.next	adda.w	#SCstruct,a3
	dbf	d1,.0
	movea.w	#(puckx-M68K_RAM),a3
	bset	#pf2fight,pflags2(a3)
	move.l	#$1A,d0			;pnothing (92 same)
	bsr.w	assinsert
	st	(collflag).w
	movea.l	(sp)+,a3
.ex	movem.l	(sp)+,d0-d4/a0-a3
	rts

.sf	move.w	SCnum(a2),impactp(a3)		;start fight for a3 against a2. SCnum to impactp (92 called SetInst first here)
	move.l	#$26,d0			;penalty $26 (92 PenFighting = $20)
	bsr.w	AddPenalty2
	move.w	SCnum(a3),d0
	bsr.w	setd0player
	move.l	#$14,d0			;afight (92 same)
	bsr.w	assinsert
	bclr	#3,attribute(a3)
	move.w	#$FC00,d1		;Xvel -$400
	cmpi.w	#2,facedir(a3)		;facedir 2?
	beq.w	.sf2
	bset	#3,attribute(a3)		;flip the other way
	neg.w	d1
.sf2	move.w	d1,Xvel(a3)
	bset	#pf2unav,pflags2(a3)		;unavailable (92 pf2unav = 4)
	bset	#pf2aip,pflags2(a3)
	bset	#pf2npc,pflags2(a3)		;no player coll (92 pf2npc = 7)
	bclr	#pfalock,pflags(a3)
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
	move.b	pnum(a2),d1
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a2)
	beq.w	.tm
	adda.w	#tmsize,a0
.tm	adda.w	d1,a0
	move.b	$11C(a0),d1		;a2 check count
	asl.b	#1,d1
	neg.b	d1
	addi.b	#$10,d1			;d1 = $10 - 2 * check count
	cmp.b	$74(a2),d1
	bgt.w	rtss			;a2 fight rating < d1
	bset	#pf2fight,pflags2(a2)
	bset	#pf2fight,pflags2(a3)
	bne.w	rtss			;a3 was already fighting
	tst.w	(OptPen).w
	beq.w	rtss
	move.w	(VDP_CNTR).l,d0		;HV counter (92 HVcount)
	andi.w	#3,d0
	bne.w	rtss			;3 of 4 times no penalty
	movea.l	a3,a4
	moveq	#5,d0
	movea.w	#(SortCords-M68K_RAM),a3
	btst	#pfteam,pflags(a4)
	beq.w	.1
	adda.w	#6*SCstruct,a3
.1	cmpa.w	a3,a4
	beq.w	.next
	tst.w	position(a3)
	ble.w	.next
	btst	#pf2pen,pflags2(a3)		;caused a penalty (92 pf2pen = 6)
	bne.w	.next
	btst	#pf2unav,pflags2(a3)		;unavailable (92 pf2unav = 4)
	bne.w	.next
	move.w	#$2A,d0			;penalty $2A (92 PenInst = $22)
	bsr.w	AddPenalty2
	movea.l	a4,a3
	rts
.next	adda.w	#SCstruct,a3
	dbf	d0,.1
	movea.l	a4,a3
	rts

checkwallcoll	;d2/d3 = x/y to test, a3 = object, wcradiusx/wcradiusy = radius. Called from checkcoll (hockey93_03_05)
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
	movea.w	#(SortCords+(13*SCstruct)-M68K_RAM),a2	;goal at the -y end
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
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a2	;SortCords+(12*SCstruct), goal at the +y end
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
	move.w	Wallcos(a3),d0
	or.w	Wallsin(a3),d0
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
	cmpi.w	#$E,SCnum(a3)		;puckSCnum
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
	cmpi.w	#$D,OldZpos(a3)		;.zside
	blt.w	.nod
	move.w	OldZpos(a3),Zpos(a3)
	bra.w	.deflectz
.nod	bclr	#pfgoal,pflags(a3)
	move.w	(puckc).w,d0
	bmi.w	.nocon			;no puck carrier
	st	(puckc).w
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	move.b	#8,nopuck(a0,d0.w)		;92 wrote a word
	move.w	(pucky).w,d1
	btst	#pfgoal,pflags(a0,d0.w)		;carrier
	bne.w	.an
	neg.w	d1
.an	tst.w	d1
	bpl.w	.nocon
	bset	#pfgoal,pflags(a3)
.nocon	move.w	#$FF00,d0		;-256
	move.l	Ypos(a3),d1
	sub.l	OldYpos(a3),d1
	asr.l	#8,d1
	beq.w	.sideentry
	bmi.w	.0
	neg.w	d0			;check top entry
	neg.w	d5
.0	add.w	d3,d5			;dy
	move.l	(a3),d3			;Xpos
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
	cmpi.w	#$D,Zpos(a3)		;.zside, Zpos
	beq.w	.deflectsf
	subq.w	#1,d4			;mouth = half width - 1 (92 sub #5)
	cmp.w	d4,d2
	bgt.w	.deflectsf
	neg.w	d4
	cmp.w	d4,d2
	bge.w	Goal
.deflectsf	bsr.w	ChkShotStat		;off the post
	move.w	#$25,-(sp)		;sfx $25 when the clock is stopped (92 SFXpuckpost = 9)
	btst	#gmclock,(gmode).w
	bne.w	.snd
	move.w	#8,(sp)			;sfx 8 (92 SFXoooh = 31) and crowd
	addi.w	#$12C,(crowdlevel).w	;add 300
	addi.w	#$28,(CwdExciteLvl).w
.snd	bsr.w	sfx
	move.w	#$1000,d0
	bsr.w	randomd0
	tst.w	Ypos(a3)
	bmi.w	.df0
	neg.w	d0
.df0	move.w	d0,Yvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Zvel(a3)
	bra.w	puckflip
.deflectz	neg.w	Zvel(a3)
	bpl.w	rtss
	neg.w	Zvel(a3)
	rts
.sideentry	clr.w	d0
	move.w	#$100,d1
	move.w	(a3),d2			;Xpos
	sub.w	OldXpos(a3),d2
	bmi.w	wallcoll
	neg.w	d1
	bra.w	wallcoll

Goal	;puck in goal. a3 = puck. Entered from checkgoal
	;93: new song, sfx 0, score +1 for the scoring team (a2, a1 = the other
	;team), song $30 if the home team scored, a 6 byte ScoreSum entry,
	;goal/assist counts, PenGoalStuff, printscores1, new assignments for the
	;scoring team, puck into the net, siren SPA and penalty $E
	btst	#gmclock,(gmode).w
	bne.w	rtss
	bsr.w	ChkShotStat
	bsr.w	play_new_song		;93 only
	move.w	#SFXsiren,-(sp)		;SFXsiren (92 same, 0)
	bsr.w	sfx
	bsr.w	freezewindow
	addi.w	#$1F4,(crowdlevel).w	;add 500 (92 800)
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	tst.w	Ypos(a3)
	bpl.w	.g0
	exg	a2,a1
.g0	btst	#gmdir,(gmode).w
	beq.w	.g1
	exg	a2,a1
.g1	addq.w	#1,tmscore(a2)
	cmpa.w	#(tmstruct-M68K_RAM),a2
	bne.w	.nocheer
	move.w	#$30,-(sp)		;song $30 (92 SFX with SFXcrowdcheer = 25)
	bsr.w	song
.nocheer	cmpi.w	#$B4,(ScoreSumbytes).w	;30 entries of 6 bytes full?
	bne.w	.sum
	subq.w	#6,(ScoreSumbytes).w	;overwrite the last entry
.sum	movea.w	#(ScoreSum-M68K_RAM),a0
	adda.w	(ScoreSumbytes).w,a0
	addq.w	#6,(ScoreSumbytes).w
	bsr.w	GetPeriodTimeRemaining
	move.w	d0,(a0)+		;entry word 0 = period/time
	moveq	#2,d0
	add.w	tmap(a2),d0
	sub.w	tmap(a1),d0
	move.b	d0,(a0)+		;byte 2 = 2 + tmap(a2) - tmap(a1)
	addi.w	#$1E,(CwdExciteLvl).w
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.home
	subi.w	#$14,(CwdExciteLvl).w	;less for an away goal
	bset	#7,-1(a0)		;byte 2 bit 7 = away team scored
.home	move.w	$18(a2),d0		;scorer
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
.noast	move.w	tmgoalie(a1),d0
	bmi.w	.pen
	addi.w	#$B4,d0
	addq.b	#1,(a1,d0.w)		;other team byte $B4 + $26(a1) +1
.pen	bsr.w	PenGoalStuff
	bsr.w	printscores1
	move.l	#7,d0			;assignment 7 (92 ascore = 8)
	bsr.w	.setass
	clr.w	(collflag).w
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	moveq	#6,d0
	tst.w	(a3)			;Xpos
	bpl.w	.1
	neg.w	d0
.1	move.w	d0,(a3)			;Xpos
	move.w	#$110,d0		;92 blueline+goalline+8
	tst.w	Ypos(a3)
	bpl.w	.0
	neg.w	d0
.0	move.w	d0,Ypos(a3)
	move.w	#$600,Zvel(a3)
	clr.w	Zpos(a3)
	st	(puckcross+2).w	;puckcross+2
	st	(puckcross+6).w	;puckcross+6
	bset	#pfnc,pflags(a3)
	move.w	#$1A,d0			;pnothing (92 same)
	bsr.w	assreplace
	move.l	a3,-(sp)
	adda.w	#SCstruct,a3
	move.w	#$11E8,d1		;SPA $11E8 (92 SPAsiren = $FE8)
	bsr.w	SetSPA
	movea.w	tmsort(a1),a3		;first sort obj of the other team (92 used the puck)
	move.l	#$E,d0			;penalty $E (92 PenGoal = 6)
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts

.setass	move.l	a3,-(sp)		;d0 = assignment, a2 = team
	;give each skater of team a2 that is not fighting assignment d0, clear pfnc
	movea.w	tmsort(a2),a3		;92 tmsort is a long
	moveq	#5,d3
.loop	tst.w	position(a3)
	ble.w	.nl
	btst	#pf2fight,pflags2(a3)
	bne.w	.nl
	bclr	#pfnc,pflags(a3)
	bsr.w	assinsert
.nl	adda.w	#SCstruct,a3
	dbf	d3,.loop
	movea.l	(sp)+,a3
	rts

GetPeriodTimeRemaining	;93: return d0 = (gsp << 14 | PerTimeTotal) - gameclock. Called from Goal (ScoreSum entry) and InProgress (penalty93)
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
	btst	#pf2npc,pflags2(a3)		;no player coll (92 pf2npc = 7)
	bne.w	rtss
	cmpi.w	#$A,Zpos(a3)
	bgt.w	rtss
	cmpi.w	#$B,SCnum(a3)
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
	move.w	Yvel(a3),d1
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
	move.w	d1,Yvel(a2)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	bset	#sfslock,(sflags).w
	btst	#gmclock,(gmode).w
	bne.w	rtss
	move.l	#8,d0			;penalty 8 (92 Penghold = $E)
	bra.w	AddPenalty2

wallcollb	;check for puck over wall. a3 = object, d0/d1 = cos/sin of the wall. Called from checkwallcoll
	;Not the puck: wallcoll. Zpos > 29, or Zpos > 18 with Ypos < 280, goes
	;over: pfnc, scroll lock, frame of the next struct cleared and, if the
	;clock runs, penalty 6 for ltplayer. 93 adds: Ypos >= 280, Xpos 13-15 and
	;Yvel >= $FA0 halves Yvel, starts SPA $1232 on the next struct with sfx $E
	;and crowd, then goes over
	cmpi.w	#$E,SCnum(a3)		;puckSCnum
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
	cmpi.w	#$FA0,Yvel(a3)
	blt.w	wallcoll
	move.l	a3,-(sp)
	asr.w	Yvel(a3)			;halve Yvel
	adda.w	#SCstruct,a3
	move.w	#$1232,d1		;SPA $1232 (93 only)
	bsr.w	SetSPA
	movea.l	(sp)+,a3
	move.w	#SFX0E,-(sp)		;sfx $E
	bsr.w	sfx
	addi.w	#$258,(crowdlevel).w	;add 600
	addi.w	#$F,(CwdExciteLvl).w
.0	bset	#sfslock,(sflags).w
	bset	#pfnc,pflags(a3)
	tst.w	Ypos(a3)
	bpl.w	.1
	ori.w	#$8000,attribute(a3)
.1	clr.w	$86(a3)			;frame+SCstruct
	btst	#gmclock,(gmode).w
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
	move.w	d0,Wallcos(a3)
	move.w	d1,Wallsin(a3)
	movem.l	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	Yvel(a3),d0
	muls.w	Xvel(a3),d1
	sub.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d2			;v1n
	movem.w	(sp),d0-d1
	muls.w	Xvel(a3),d0
	muls.w	Yvel(a3),d1
	add.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d3			;v1t
	neg.w	d2
	cmpi.w	#$E,SCnum(a3)		;puckSCnum
	bne.w	.player
	bclr	#sf2shot,(sflags2).w
	tst.w	d2
	bpl.w	.nocoll
	asr.w	#2,d2			;reduce normal speed on puck
	cmp.w	#$FC00,d2		;-$400
	bgt.w	.pok
	move.w	#$800,d0
	bsr.w	randomd0
	neg.w	d0
	move.w	d0,Zvel(a3)
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
	cmpi.w	#$A,impact(a3)
	blt.w	.nosfx
	move.w	#SFXplayerwall,-(sp)		;sfx $20 (92 SFXplayerwall = 15)
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
	move.w	d3,Yvel(a3)
	tst.w	Zvel(a3)
	bmi.w	.nocoll
	clr.w	Zvel(a3)
.nocoll	addq.w	#4,sp
	movem.l	(sp)+,d2-d3
	rts

checkpuckcoll	;look for puck coll with players. a3 = puck. Entered from pucknorm (logic93)
	;93 first clears Yvel when Ypos > 400 or Ypos <= -400. Walks up and down
	;the OOlist from the puck and runs .ccx on each object within 22 in y:
	;stick (puckstick), body (puckbody) or goalie (puckgoalie)
	cmpi.w	#$190,Ypos(a3)		;Ypos 400
	bgt.w	.clrvy
	cmpi.w	#$FE70,Ypos(a3)		;-400
	bgt.w	.chkz
.clrvy	clr.w	Yvel(a3)
.chkz	cmpi.w	#$10,Zpos(a3)		;Zpos, 6*8/3 = 16
	bgt.w	rtss			;feet in air
	move.w	SCnum(a3),d0
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
	btst	#pfnc,pflags(a2)
	bne.w	.exit			;object has no coll mode on
	tst.b	nopuck(a2)
	bne.w	.exit
	btst	#pf2unav,pflags2(a2)		;unavailable (92 pf2unav = 4)
	bne.w	.chkbody
	cmpi.w	#5,Zpos(a3)		;Zpos, 2*8/3 = 5
	bgt.w	.chkbody
	cmpi.w	#$200,Zvel(a3)		;92 $100
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
	tst.b	nopuck(a3)			;puck is not ready to be caught
	ble.w	.lo
	lsr.w	#2,d1
.lo	cmp.l	d1,d0
	bhi.w	.chkbody
	bsr.w	puckstick
	bra.w	.exit
.chkbody	tst.w	position(a2)
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

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $10E66-$11801
;	92 hockey.asm part 2 tail (puckstick, setd0player, puckbody, puckgoalie,
;	deflect), then the 92 part 3 player-roster code that 93 moved here
;	(makepde ... setplayer) and the 93-only TryAddPlayerToList / ClampNibble.
;Global names from the 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	93 SortCords offsets ($80 per object), 92 names in comments where the
;	use matches: Xpos 0, attribute 4, frame 6, Ypos $14, Zpos $18, Xvel $28,
;	Yvel $2A, Zvel $2C, position $34, temp4 $46, temp5 $48, SCnum $52,
;	facedir $54, SPA $58, nopuck $5E (byte), newpos $60, newpnum $61,
;	pflags $62, pflags2 $63, pnum $66.
;	Player attributes written by setplayer: weight $67, legstr $68, legspd
;	$69, aioff $6A, aidef $6B, shotspd $6C, shotacc $6D, passacc $6E,
;	rostnum $6F, spodds $70, stickhand $71, endurance $72, aggress $73,
;	$74 (4(a0) & $E; hockey93_03_05 reads it as the fight rating), $75 (93
;	only), handed $76 (bit 0 set is left handed).
;	pflags bits match 92 (0 pfdoff, 5 pfalock, 6 pfteam). pflags2 bit 2 is
;	unavailable (92 pf2unav = 4).
;	93 team struct (tmsize $1A2, home at hmtmstruct): $C score (92 tmscore),
;	$16 tmline, $1E tmdata (long), $22 tmsort (word), $24 tmap, $26
;	tmgoalie (negative = no goalie), $30 tmflags, $32 tmpde, $66 tmpdst
;	(92 -2 bench / -1 ice / >0 penalty box; 93 adds -3), $16A line sets.
;	Assignment numbers are 93 asstab indexes; sound numbers are 93 sfx/song
;	numbers. The 92 name in a comment gives the role and the 92 value.

puckstick	;puck collides with stick
	;a2 = player who collided, a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx)
	;93: a goalie skips the steal roll, a goalie needs a loose puck within
	;8, and the catch speed limit is 13000 + 700 * stickhand
	tst.w	position(a2)
	bne.w	.0
	btst	#gmhl,(gmode).w
	bne.w	rtss
.0	bclr	#pfdoff,pflags(a2)
	move.w	(puckc).w,d1
	bmi.w	.nosteal		;nobody has the puck
	asl.w	#7,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d1,a0			;a0 = puck carrier
	move.b	pflags(a0),d1
	move.b	pflags(a2),d2
	eor.w	d1,d2
	btst	#pfteam,d2
	beq.w	rtss			;no steal from team member
	cmp.l	#$24,d0			;6*6
	bhi.w	rtss			;smaller range for stealing puck
	tst.w	position(a2)
	beq.w	.steal			;93: a goalie always steals
	tst.w	position(a0)
	beq.w	rtss			;no steal from goalie
	move.b	stickhand(a0),d0
	bsr.w	makepde
	move.w	d0,-(sp)
	exg	a0,a2
	move.b	stickhand(a0),d0
	bsr.w	makepde
	exg	a0,a2
	neg.w	d0
	add.w	(sp)+,d0		;carrier - stealer
	addi.w	#$24,d0			;36
	bsr.w	randomd0
	cmp.w	#2,d0
	bhi.w	rtss			;steal fails
.steal	move.b	stickhand(a0),d0
	bsr.w	makepde
	addi.w	#$14,d0			;20
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
.stdef	move.w	#6,-(sp)		;stick deflect sound (92 SFXstdef = 5)
	bsr.w	sfx
	bsr.w	a2touchpuck
	bra.w	deflect

.nosteal	tst.w	position(a2)
	bne.w	.spd			;skater: any range
	cmp.l	#$40,d0			;8*8 (93 only)
	bhi.w	rtss			;goalie too far from a loose puck
.spd	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0			;puck speed^2 (92 scaled each by 1/64)
	clr.w	d1
	btst	#4,(sflags2).w
	bne.w	.nohand			;sflags2 bit 4 set: no stickhand bonus
	move.b	stickhand(a2),d1
	mulu.w	#$2BC,d1		;* 700
.nohand	addi.w	#$32C8,d1		;+ 13000
	mulu.w	d1,d1
	cmp.l	d1,d0
	bls.w	puckglue		;slow enough to catch (92 320*64)
	move.b	#8,nopuck(a2)
	bra.s	.stdef

puckglue	;Player a2 takes the puck (92 puckstick.glue)
	;Global because puckgoalie .nopc also branches here. Plays song 7, or $C
	;($B for the home team) when sflags3 bit 4 was set, and counts a pass
	;completion when a2 is passReceiverPlayerNum. Falls into setd0player
	move.w	#7,-(sp)		;song 7 (92 sfx SFXpuckget = 8)
	move.w	SCnum(a2),d0
	move.w	d0,(puckc).w
	movea.w	#(tmstruct-M68K_RAM),a0
	lea	tmsize(a0),a1
	btst	#pfteam,pflags(a2)
	bne.w	.tm
	exg	a0,a1
.tm	st	$1A(a0)			;a0 = other team, a1 = a2's team
	st	$1C(a0)
	bset	#3,tmflags(a0)		;tmflags bit 3
	bclr	#4,(sflags3).w
	beq.w	.snd			;sflags3 bit 4 was clear
	addq.w	#1,$E(a1)		;team word $E + 1
	addi.w	#$C8,(crowdlevel).w	;+200
	move.w	#$C,(sp)		;song $C
	cmpa.w	#(tmstruct-M68K_RAM),a1
	bne.w	.snd			;away team
	addi.w	#$A,(CwdExciteLvl).w
	move.w	#$B,(sp)		;song $B for the home team
.snd	bsr.w	song
	move.w	SCnum(a2),d0
	cmp.w	(passReceiverPlayerNum).w,d0
	bne.w	.nrec
	addq.w	#1,$14(a1)		;pass reached its receiver: team word $14 + 1
.nrec	st	(passReceiverPlayerNum).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
	tst.w	position(a2)
	bne.w	setd0player
	bsr.w	ChkShotStat
	move.w	#$8C,temp5(a2)		;temp5 = 140, count down for faceoff (92 120)
	cmpi.w	#$314,SPA(a2)
	bne.w	setd0player
	move.w	#5,temp5(a2)		;temp5 = 5 for SPA $314

setd0player	;give control of player d0 to a controller if his team is controlled
	;d0 = SCnum. Also called by checkfight .sf (hockey93_03_05)
	cmp.w	(c1playernum).w,d0
	beq.w	rtss			;already on controller 1
	cmp.w	(c2playernum).w,d0
	beq.w	rtss			;already on controller 2
	cmp.w	#6,d0
	slt	d1
	ext.w	d1
	addq.w	#2,d1			;d1 = 1 home (SCnum < 6), 2 visitors
	move.w	(lastplayer).w,d2
	cmp.w	(c2playernum).w,d2
	beq.w	.1			;last player was controller 2's: try cont 2 first
	cmp.w	(cont1team).w,d1
	beq.w	setc1player
.1	cmp.w	(cont2team).w,d1
	beq.w	setc2player
	cmp.w	(cont1team).w,d1
	beq.w	setc1player
	rts

puckbody	;puck hits player a2. a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx)
	;93 keeps the old puck speed: a fast puck above 12 knocks a2 down
	;(FallDown), a slower one above 8 plays SPA $128A on a2
	cmpi.w	#8,Zpos(a3)		;Zpos, 3*8/3
	bgt.w	.hit
	move.w	d0,d1
	andi.w	#$F,d1			;radius^2 from center
	bne.w	rtss
.hit	bsr.w	a2touchpuck
	move.w	#SFXpuckbody,-(sp)		;puck body sound (92 SFXpuckbody = 5)
	bsr.w	sfx
	clr.w	Zvel(a3)
	move.b	#8,nopuck(a2)
	move.w	(a3),d0			;Xpos
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0	move.w	Xvel(a3),d2		;old Xvel
	move.w	Yvel(a3),d3		;old Yvel
	move.b	d0,Xvel(a3)
	move.b	d1,Yvel(a3)
	bsr.w	puckflip
	cmpi.w	#8,Zpos(a3)
	ble.w	rtss			;puck low: no effect on a2
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d3,d2			;old speed^2
	cmp.l	#$9000000,d2		;$3000^2
	bls.w	.slow
	cmpi.w	#$C,Zpos(a3)		;Zpos 12
	bgt.w	FallDown
	rts
.slow	bset	#pfalock,pflags(a2)
	bne.w	rtss			;already in a locked anim
	move.w	#$128A,d1		;SPA for a2
	exg	a2,a3
	bsr.w	SetSPA
	exg	a2,a3
rtss	rts				;shared rts, branched to from many segments

puckgoalie	;puck hits goalie a2. a3 = puck, d0/d1 = goalie - puck x/y
	;Save odds from the goalie's save attribute and the frame table .list2.
	;93: song on a hard shot, a puck carrier loses the puck, and a slow
	;loose puck (.nopc) is caught through puckglue
	btst	#gmhl,(gmode).w
	bne.s	rtss
	clr.w	d2			;puck region
	cmpi.w	#8,Zpos(a3)		;Zpos, 3*8/3
	bgt.w	.1
	addq.w	#2,d2
.1	neg.w	d0
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
	move.w	(VDP_CNTR).l,d0		;HV counter, just for random bit
.2	andi.w	#4,d0
	lsr.w	#2,d0
	eori.w	#1,d0
	add.w	d0,d2
	add.w	d2,d2
	lea	.list(pc),a0
	move.w	(a0,d2.w),d0
	moveq	#$F,d1
	add.b	(a2,d0.w),d1		;save odds
	lea	.list2(pc),a0
	btst	#3,attribute(a2)		;x flip?
	beq.w	.3
	eori.w	#2,d2
.3	move.w	frame(a2),d0
	subi.w	#$197,d0		;first goalie frame (92 SPFgoalie)
	move.b	(a0,d0.w),d0
	lsr.w	d2,d0
	andi.w	#3,d0
	mulu.w	d1,d0
	beq.s	rtss
	bsr.w	randomd0
	cmp.w	#8,d0
	blt.w	rtss			;no save
	bsr.w	ChkShotStat
	bsr.w	a2touchpuck
	cmpi.w	#$3000,(puckvy).w
	bgt.w	.setsfx
	cmpi.w	#$D000,(puckvy).w
	bgt.w	.nosong			;-$3000 < Yvel <= $3000: no song
.setsfx	move.w	#$B,-(sp)		;song $B (home goalie)
	btst	#pfteam,pflags(a2)
	beq.w	.song
	move.w	#$D,(sp)		;song $D (visiting goalie)
.song	bsr.w	song
.nosong	move.w	#$24,-(sp)		;puck body sound (92 SFXpuckbody = 5)
	bsr.w	sfx
	move.w	(puckc).w,d2
	bmi.w	.nopc			;loose puck
	st	(puckc).w		;carrier loses the puck
	asl.w	#7,d2			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d2,a0
	move.b	#$14,nopuck(a0)		;carrier nopuck = 20
	move.w	SCnum(a0),(lastplayer).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
.bounce	clr.w	Zvel(a3)
	move.b	#$A,nopuck(a2)		;nopuck (92 8)
	move.w	#4,temp4(a2)
	move.w	(a3),d0			;Xpos
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0	move.b	d0,Xvel(a3)
	move.b	d1,Yvel(a3)
	bra.w	puckflip
.nopc	cmpi.w	#$314,SPA(a2)
	beq.s	.bounce
	moveq	#2,d0
	add.b	shotspd(a2),d0		;shotspd byte
	asl.w	#8,d0
	asl.w	#1,d0			;d0 = (2 + $6C) * 512
	bsr.w	randomd0
	addi.w	#$C00,d0		;catch speed limit
	cmp.w	(puckvx).w,d0
	blt.s	.bounce			;too fast in x
	cmp.w	(puckvy).w,d0
	blt.s	.bounce			;too fast in y
	neg.w	d0
	cmp.w	(puckvx).w,d0
	bgt.s	.bounce
	cmp.w	(puckvy).w,d0
	bgt.s	.bounce
	btst	#pf2unav,pflags2(a2)		;unavailable (92 pf2unav = 4)
	bne.s	.bounce
	clr.w	Zvel(a3)
	bra.w	puckglue		;goalie holds the puck

.list	dc.b	0,$73,0,$6E,0,$70,0,$72	;save attribute offsets (92 GGSleft, GGSright, GSSleft, GSSright)

.list2	;odds for stopping puck in each quadrant for each possible goalie frame
	dc.b	$55,$9D,$67,$55,$9D,$67,$55,$9D,$67,$55,$9D,$67	;ready/glover/glovel (92 pix 1111,2131,1213)
	dc.b	$55,$9D,$67,$55,$9D,$67,$55,$9D,$67,$55,$9D,$67
	dc.b	$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55	;goalie swing
	dc.b	$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0	;goalie stack right
	dc.b	$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0	;goalie stack left
	dc.b	$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75	;goalie stick right/left
	dc.b	$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55	;93 only from here
	dc.b	$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55
	dc.b	$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
	dc.b	$57,$57,$57,$57
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5

deflect	;random puck direction on deflection puck = a3. Entered from puckstick .stdef
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

makepde	;pass d0 as value to be scaled by player a0's energy level
	;return d0 as result. Called from puckstick and logic93 (ShotMode)
	ext.w	d0
	move.w	d0,-(sp)
	movem.l	d1/a2-a3,-(sp)
	movea.l	a0,a3
	bsr.w	getpde
	movem.l	(sp)+,d1/a2-a3
	muls.w	(sp)+,d0
	asl.l	#4,d0
	swap	d0
	ext.l	d0			;d0 = d0 * energy / 4096
	rts

getpde	;get player a3's energy level into d0. Return a2 = his team struct, d1 = pnum*2
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)
	beq.w	.0
	adda.w	#tmsize,a2
.0	move.b	pnum(a3),d1
	ext.w	d1
	add.w	d1,d1
	move.w	tmpde(a2,d1.w),d0
	rts

setpde	;d1 = rostnum of player * 2, a2 = team struct
	;d0 = new energy level. 93 drops the 92 d1 range check
	tst.w	d0
	bpl.w	.0
	clr.w	d0
.0	move.w	d0,tmpde(a2,d1.w)
	rts

setpersonel	;this will set personel on team a2 according to team a2's registers
	;Asks SetPlList for the wanted players, keeps the ones already on the
	;ice, and puts the rest in sort objs with no requested player
	movem.l	d0-d5/a0-a4,-(sp)
	movea.w	tmsort(a2),a3
	moveq	#5,d4
.l0	st	newpos(a3)
	st	newpnum(a3)
	adda.w	#SCstruct,a3
	dbf	d4,.l0
	bsr.w	SetPlList
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4	;list of players we want on ice
.1	clr.w	d5
	move.b	(a4,d4.w),d5
	beq.w	.next
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	tmsort(a2),a3
	suba.w	#SCstruct,a3
.2	adda.w	#SCstruct,a3
	cmp.b	pnum(a3),d5
	dbeq	d3,.2
	bne.w	.next			;not on the ice now
	move.b	6(a4,d4.w),newpos(a3)
	move.b	d5,newpnum(a3)
	clr.b	(a4,d4.w)
.next	dbf	d4,.1
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4
.3	clr.w	d5
	move.b	(a4,d4.w),d5
	beq.w	.next2
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	tmsort(a2),a3
	suba.w	#SCstruct,a3
.4	adda.w	#SCstruct,a3
	tst.b	newpnum(a3)
	dbmi	d3,.4			;find a sort obj with no requested player
	bpl.w	.chkpos			;none left
	movea.w	a3,a0			;a0 = free sort obj
.chkpos	tst.w	position(a3)
	dbpl	d3,.4			;93: keep looking while that obj has no position
	move.b	6(a4,d4.w),newpos(a0)
	move.b	d5,newpnum(a0)
	clr.b	(a4,d4.w)
.next2	dbf	d4,.3
	movem.l	(sp)+,d0-d5/a0-a4
	rts

SetPlList	;create list (PlList) of players who we want on the ice now
	;a2 = team struct. 93 reads the lines from the team struct ($16A), and
	;falls back to every roster player when sublist has no free player
	movea.w	#(PlList-M68K_RAM),a4
	clr.l	(a4)
	clr.w	4(a4)
	movea.l	#priolist,a0
	tst.w	tmgoalie(a2)
	bpl.w	.gin
	addq.w	#1,a0			;no goalie: skip priolist goalie entry
.gin	lea	$16A(a2),a1		;line sets (92 tmdata LineSets)
	move.w	tmline(a2),d0
	asl.w	#3,d0
	adda.w	d0,a1
	move.w	tmap(a2),d4		;tmap, active players 4-6
	bra.w	.next
.0	clr.w	d5
	move.b	(a0,d4.w),d5		;position
	move.b	(a1,d5.w),(a4,d4.w)	;player number
	move.b	d5,6(a4,d4.w)
	bne.w	.next
	moveq	#1,d3
	add.w	tmgoalie(a2),d3		;goalie: 1 + tmgoalie (92 adds 1 for the 2nd goalie only)
	move.b	d3,(a4,d4.w)
.next	dbf	d4,.0
	moveq	#5,d4			;now check to see if player is avail
.1	move.b	(a4,d4.w),d3
	beq.w	.next1
	ext.w	d3
	subq.w	#1,d3
	add.w	d3,d3
	cmpi.w	#$FFFD,tmpdst(a2,d3.w)	;tmpdst -3 (93)
	beq.w	.sub
	tst.w	tmpdst(a2,d3.w)
	ble.w	.next1			;player is ok
.sub	lea	$16A(a2),a1		;now find player of similar position who is available
	move.b	6(a4,d4.w),d0		;position
	ext.w	d0
	asl.w	#1,d0
	movea.l	#sublist,a0
	adda.w	(a0,d0.w),a0		;93 sublist is word offsets (92 long pointers)
.s1	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.all			;end of list
	move.b	(a1,d0.w),d0
	bsr.w	TryAddPlayerToList
	beq.s	.s1			;not available
.next1	dbf	d4,.1
	rts
.all	jsr	(GetPlayerCount).l	;93: try every roster player, last first
	move.w	d0,d3
.try	move.w	d3,d0
	subq.w	#1,d3
	bmi.s	.next1			;none available
	bsr.w	TryAddPlayerToList
	beq.s	.try
	bra.s	.next1

TryAddPlayerToList	;93 split of 92 SetPlList .s1/.s2. d0 = player number (1 based), d4 = PlList slot
	;a2 = team struct, a4 = PlList. Return Z clear = added, Z set (d1 = 0) = not available
	move.w	d0,d1
	subq.w	#1,d0
	add.w	d0,d0
	tst.w	tmpdst(a2,d0.w)
	bgt.w	.no			;in penalty box
	cmpi.w	#$FFFD,tmpdst(a2,d0.w)	;-3 (93)
	beq.w	.no
	moveq	#5,d0
.s2	cmp.b	(a4,d0.w),d1
	dbeq	d0,.s2
	beq.w	.no			;already in PlList
	move.b	d1,(a4,d4.w)
	rts
.no	clr.w	d1
	rts

forcepldata	;no skating on/off force players to correct data (for faceoffs only)
	;a2 = team struct
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	tmsort(a2),a3
	moveq	#5,d4
.top	move.b	newpos(a3),d0
	ext.w	d0
	move.w	d0,position(a3)
	bmi.w	.next
	bsr.w	Setplass
	cmpi.w	#4,position(a3)		;center
	bne.w	.notnear
	move.l	#$11,d0			;anearest (92 17)
	bsr.w	assinsert
.notnear	clr.w	d3
	move.b	newpnum(a3),d3
	add.w	d3,d3
	move.w	#$FFFF,tmpdst(a2,d3.w)	;tmpdst, put player on the ice
	lsr.w	#1,d3
	bsr.w	setplayer
.next	st	newpnum(a3)
	st	newpos(a3)
	adda.w	#SCstruct,a3
	dbf	d4,.top
	movem.l	(sp)+,d0-d4/a0-a3
	rts

ResetBench	;remove all players from penalty box/ put all players on their own bench
	;PBnum = players left in the box, home * 16 + visitors. 93 keeps -3 players
	;and drops box players with tmpdst bit 12 set and no time left from the count
	clr.b	(PBnum).w
	moveq	#$10,d1
	movea.w	#(tmstruct-M68K_RAM),a0
	bsr.w	.rb
	moveq	#1,d1
	adda.w	#tmsize,a0		;tmsize, falls in for the visitors
.rb	moveq	#$32,d0			;(MaxRos-1)*2
.rb1	add.b	d1,(PBnum).w
	tst.w	tmpdst(a0,d0.w)
	ble.w	.nopen
	btst	#4,tmpdst(a0,d0.w)		;bit 12 of tmpdst
	beq.w	.next			;stays in the box
	move.w	tmpdst(a0,d0.w),d2
	andi.w	#$7FF,d2
	bne.w	.next			;time left
	sub.b	d1,(PBnum).w
	bra.w	.next
.nopen	sub.b	d1,(PBnum).w
	cmpi.w	#$FFFD,tmpdst(a0,d0.w)	;-3 (93)
	beq.w	.next
	move.w	#$FFFE,tmpdst(a0,d0.w)	;-2 bench
.next	subq.w	#2,d0
	bpl.s	.rb1
	rts

Setplass	;set players (a3) initial assignment
	move.w	position(a3),d0
	bmi.w	rtss
	lea	.alist(pc),a0
	move.b	(a0,d0.w),d0
	bra.w	assreplace

.alist	;93 asstab numbers
	dc.b	$E			;agoalie (92 15)
	dc.b	2			;adefd
	dc.b	2			;adefd
	dc.b	3			;awingd
	dc.b	5			;acenterd
	dc.b	3			;awingd
	dc.b	5			;acenterd
	IF REV=0
	dc.b	$FA			;retail pad (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

setplayer	;bring player onto the ice and set his stats
	;d3 = player number, a3 = sortcord of player. 93 reads each attribute
	;nibble from a variable-length roster record and, for skaters, adds the
	;modifier bytes PPBonus / PKBonus (from sflags2 bit 5 and chkpk2),
	;HmAwBonus (home bonus / visitor penalty) and ThirdPBonus (2 when tied or trailing with at
	;least half of the 3rd period left, or after the 3rd period), clamped to
	;0-15 by ClampNibble
	bclr	#6,pflags2(a3)		;pflags2 bit 6 (93)
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a3)
	beq.w	.0
	adda.w	#tmsize,a0
.0	move.b	d3,pnum(a3)
	move.l	#$A,d0			;aepen (92 11)
	ext.w	d3
	add.w	d3,d3
	move.w	tmpdst(a0,d3.w),d1
	bpl.w	.da			;from the penalty box
	move.l	#9,d0			;aeben (92 10)
	cmp.w	#$FFFE,d1		;-2 bench
	bne.w	.nda
.da	bsr.w	assinsert
	bclr	#pfalock,pflags(a3)
	clr.w	SPA(a3)
.nda	move.w	#$FFFF,tmpdst(a0,d3.w)	;tmpdst -1 on the ice (93)
	lsr.w	#1,d3
	movea.l	tmdata(a0),a0
	move.l	a0,-(sp)
	adda.w	8(a0),a0		;team data + word at team data+8 (92 LineSets offset)
	clr.l	(PPBonus).w	;all four bonus bytes
	tst.w	position(a3)
	beq.w	.nomod			;goalie: no modifiers
	btst	#5,(sflags2).w
	beq.w	.nda3
	bsr.w	chkpk2
	beq.w	.nda2
	move.b	1(a0),(PPBonus).w	;low nibble of byte 1
	andi.b	#$F,(PPBonus).w
	bra.w	.nda3
.nda2	move.b	1(a0),d0
	lsr.b	#4,d0
	neg.b	d0
	move.b	d0,(PKBonus).w	;-high nibble of byte 1
.nda3	move.b	2(a0),d0
	andi.b	#$F,d0
	neg.b	d0			;visitors: -low nibble of byte 2
	btst	#pfteam,pflags(a3)
	bne.w	.tm
	move.b	2(a0),d0
	lsr.b	#4,d0			;home: high nibble of byte 2
.tm	move.b	d0,(HmAwBonus).w
	cmpi.w	#2,(gsp).w		;period
	blt.w	.nomod			;1st or 2nd period
	bgt.w	.score			;after the 3rd period
	jsr	(GetPeriodTime).w
	lsr.w	#1,d0
	cmp.w	(gameclock).w,d0
	bgt.w	.nomod			;under half of the 3rd period left (clock counts down)
.score	move.w	(tmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;- visitor score
	beq.w	.close			;tied
	btst	#pfteam,pflags(a3)
	beq.w	.side
	eori	#8,ccr			;visitors: flip N
.side	bpl.w	.nomod			;leading
.close	move.b	#2,(ThirdPBonus).w
.nomod	movea.l	(sp)+,a0		;tmdata
	adda.w	(a0),a0			;roster records (92 Playerdata)
.find	adda.w	(a0),a0			;skip name
	addq.w	#8,a0			;skip 8 attribute bytes
	dbf	d3,.find
	subq.w	#8,a0			;a0 = player d3's attribute bytes
	move.b	(a0),rostnum(a3)
	move.b	1(a0),d3
	andi.w	#$F0,d3
	lsr.w	#1,d3			;(92 no shift)
	move.b	d3,weight(a3)
	move.b	1(a0),d3
	andi.b	#$F,d3
	move.b	d3,legstr(a3)
	move.b	2(a0),d3
	lsr.b	#4,d3
	move.b	d3,legspd(a3)
	move.b	2(a0),d3
	andi.b	#$F,d3
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	eori.b	#$F,d3
	addi.b	#$F,d3			;frames to skip
	lsr.b	#1,d3
	move.b	d3,aioff(a3)
	move.b	3(a0),d3
	lsr.b	#4,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	eori.b	#$F,d3
	addi.b	#$F,d3			;frames to skip
	lsr.b	#1,d3
	move.b	d3,aidef(a3)
	move.b	3(a0),shotspd(a3)
	andi.b	#$F,shotspd(a3)
	move.b	4(a0),d3
	lsr.b	#4,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,$75(a3)		;93 only attribute
	bclr	#3,attribute(a3)
	move.b	4(a0),handed(a3)
	andi.b	#1,handed(a3)		;bit 0 set is left handed
	bne.w	.ha
	bset	#3,attribute(a3)
.ha	move.b	4(a0),$74(a3)
	andi.b	#$E,$74(a3)
	move.b	5(a0),d3
	lsr.b	#4,d3
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,stickhand(a3)
	move.b	5(a0),d3
	andi.b	#$F,d3
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,shotacc(a3)
	move.b	6(a0),d3
	lsr.b	#4,d3
	move.b	d3,endurance(a3)
	move.b	6(a0),d3
	andi.b	#$F,d3
	add.b	(ThirdPBonus).w,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,spodds(a3)
	move.b	7(a0),d3
	lsr.b	#4,d3
	add.b	(PPBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,passacc(a3)
	move.b	7(a0),aggress(a3)		;aggress
	andi.b	#$F,aggress(a3)
	rts

ClampNibble	;93 only: clamp byte d3 to 0-15. Called by setplayer
	tst.b	d3
	bpl.w	.hi
	clr.w	d3			;negative: 0
.hi	cmp.b	#$F,d3
	ble.w	.x
	moveq	#$F,d3
.x	rts
