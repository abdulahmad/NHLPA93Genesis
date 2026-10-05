;	NHLPA Hockey 93 (retail) segment $A0FC-$AE87
;	92 Logic.Asm part 2: player assignments assbench ... asswingd, with the
;	fight code (assfight, chkhit, banner). Global names from the IDA export,
;	92 names where the routine is the same (see the SEGMENT_AGENT.md rename
;	table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	93 SortCords offsets, 92 names in comments: Xpos 0, frame 6, oldframe 8,
;	Xvel $28, Yvel $2A, impactp $2E, position $34, temp1 $40, temp2 $42,
;	temp3 $44, temp4 $46, wallcos $4E, wallsin $50, SCnum $52, facedir $54,
;	SPA $58, SPAnum $5A, nopuck $5E, newpos $60, newpnum $61, pflags $62
;	(pfna 1, pfnc 2, pfjoycon 3, pfalock 5, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2aip 1, pf2unav 2, pf2pen 4, pf2npc 5), pnum $66, aioff $6A,
;	aidef $6B, aggress $74, checking $75, handed $76.
;	Every assignment starts with "btst #pfalock / bne rtss" (93 only).

assbench	;player a3 should goto bench
	btst	#5,$62(a3)		;pfalock
	bne.w	rtss
	cmpi.w	#$64,$40(a3)		;temp1 = 100 flag: at the bench door
	beq.w	.done
	bsr.w	check4bench
	btst	#4,$63(a3)		;pf2pen
	bne.w	assexit
	bclr	#1,$62(a3)		;pfna
	beq.w	.nna
	move.w	#8,$42(a3)		;temp2
	moveq	#$50,d0			;80
	btst	#6,$62(a3)		;pfteam
	bne.w	.0
	neg.w	d0
.0	move.w	d0,$46(a3)		;IDA: loc_A154. temp4 = bench y
	move.w	#$88,$44(a3)		;sideline
	neg.w	$44(a3)
	subq.w	#8,$44(a3)		;temp3 = bench x
	clr.w	$40(a3)
.nna	move.b	$61(a3),d0		;IDA: loc_A16A. newpnum
	cmp.b	$66(a3),d0		;pnum
	beq.w	.nobench		;same player, just change position
	sub.w	d7,$40(a3)
	bpl.w	.nodec
	addq.w	#8,$40(a3)
	move.w	$14(a3),d0
	sub.w	$46(a3),d0
	cmp.w	#40,d0
	bgt.w	.nodec
	cmp.w	#-40,d0
	blt.w	.nodec
	move.w	(a3),d0
	sub.w	$44(a3),d0
	cmp.w	#32,d0
	bgt.w	.nodec
	move.w	#$52C,d1		;SPAglide
	tst.w	$34(a3)
	bne.w	.gli
	move.w	#2,d1			;SPAgready
.gli	bsr.w	SetSPA			;IDA: loc_A1B8
	bset	#2,$62(a3)		;pfnc
	cmpi.w	#4,$54(a3)
	beq.w	.ok
	addq.w	#1,$54(a3)		;turn toward the bench
	andi.w	#7,$54(a3)
.ok	clr.w	$2A(a3)			;IDA: loc_A1D6
	move.w	#$F800,$28(a3)		;-$800
	cmp.w	#16,d0
	bgt.w	rtss
	clr.w	$28(a3)
	cmpi.w	#4,$54(a3)
	bne.w	rtss
	move.w	#$F800,$28(a3)
	move.w	#2,$54(a3)
	move.w	#$1166,d1		;SPAwallleft
	bsr.w	SetSPA
	bset	#5,$62(a3)		;pfalock
	move.w	#$64,$40(a3)		;100
	rts
.done	clr.w	6(a3)			;IDA: loc_A218. frame
	clr.w	d0
	move.b	$66(a3),d0		;pnum
	add.w	d0,d0
	movea.l	#hmtmstruct,a0
	btst	#6,$62(a3)
	beq.w	.t0
	adda.w	#$1A2,a0		;tmsize
.t0	move.w	#$FFFE,$66(a0,d0.w)	;IDA: loc_A238. tmpdst: put used player on bench
	move.b	$61(a3),d3
	bsr.w	.nobench2
	bra.w	setplayer
.nodec	btst	#2,$62(a3)		;IDA: loc_A24A. pfnc
	bne.w	rtss
	move.w	$44(a3),d0
	move.w	$46(a3),d1
	movea.l	#EvadePC,a0
	bra.w	skateto
.nobench	bclr	#2,$63(a3)		;IDA: loc_A266. pf2unav
.nobench2	move.b	$60(a3),d0		;IDA: loc_A26C. newpos
	ext.w	d0
	move.w	d0,$34(a3)
	bsr.w	Setplass
	st	$61(a3)
	st	$60(a3)
	rts

asseben	;player a3 should exit bench area
	btst	#5,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	clr.w	$28(a3)
	clr.w	$2A(a3)
	move.w	$52(a3),d0
	subq.w	#6,d0
	bmi.w	.0
	addq.w	#1,d0
.0	muls.w	#$E,d0			;IDA: loc_A2AC
	move.w	d0,$14(a3)
	move.w	#$88,(a3)		;sideline
	neg.w	(a3)
	move.w	#2,$54(a3)
	bset	#5,$62(a3)
	move.w	#$1128,d1		;SPAwallright
	bra.w	SetSPA
.nna	move.w	#4,$54(a3)		;IDA: loc_A2CE
	bclr	#2,$62(a3)		;pfnc
	bclr	#5,$63(a3)		;pf2npc
	bclr	#2,$63(a3)		;pf2unav
	clr.w	$58(a3)			;SPA
	move.w	#$1000,$28(a3)
	bra.w	assexit

asspenalty	;player a3 should goto penalty box
	btst	#5,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	bset	#2,$63(a3)		;pf2unav
	bsr.w	clrplayer
	moveq	#-2,d4
	bsr.w	setpads			;put number on player leaving
	move.w	#8,$42(a3)
	moveq	#$B,d0			;92: 55 - 10*n, 93: 11*(n+3)
	move.b	(PBnum).w,d1
	btst	#6,$62(a3)
	bne.w	.0
	lsr.w	#4,d1
	neg.w	d0
.0	andi.w	#$F,d1			;IDA: loc_A332
	cmp.w	#2,d1
	bls.w	.1
	moveq	#2,d1
.1	addq.w	#3,d1			;IDA: loc_A340
	muls.w	d0,d1
	move.w	d1,$46(a3)		;temp4
	move.w	#$88,$44(a3)		;temp3 = sideline
	clr.w	$40(a3)
	bset	#5,$63(a3)		;pf2npc: no player coll.
	clr.w	$4E(a3)			;wallcos
	clr.w	$50(a3)			;wallsin
.nna	move.w	$14(a3),d0		;IDA: loc_A360
	sub.w	$46(a3),d0
	cmp.w	#12,d0
	bgt.w	.st
	cmp.w	#-12,d0
	blt.w	.st
	move.w	(a3),d0
	sub.w	$44(a3),d0
	cmp.w	#-24,d0
	blt.w	.st
	sub.w	d7,$40(a3)
	bpl.w	rtss
	addq.w	#8,$40(a3)
	bset	#2,$62(a3)		;pfnc
	move.w	#$52C,d1		;SPAglide
	bsr.w	SetSPA
	moveq	#6,d2
	tst.b	$76(a3)			;handed
	beq.w	.left
	moveq	#2,d2
.left	cmp.w	$54(a3),d2		;IDA: loc_A3AC
	beq.w	.ok
	addq.w	#1,$54(a3)
	andi.w	#7,$54(a3)
.ok	clr.w	$2A(a3)			;IDA: loc_A3BE
	move.w	#$1000,$28(a3)
	cmp.w	#-8,d0
	blt.w	rtss
	clr.w	$28(a3)
	cmp.w	$54(a3),d2
	bne.w	rtss
	bset	#5,$62(a3)
	move.w	#2,$54(a3)
	move.w	#$1128,d1		;SPAwallright
	bsr.w	SetSPA
	bclr	#4,$63(a3)		;pf2pen
	move.l	#$D,d0			;adopen
	bra.w	assreplace
.st	move.w	$44(a3),d0		;IDA: loc_A400
	move.w	$46(a3),d1
	movea.l	#rtss,a0
	bra.w	skateto

clrplayer	;take the joystick off player a3 (92 asspenalty .clrplayer)
	btst	#3,$62(a3)
	beq.w	rtss
	clr.w	d4
	move.w	$52(a3),d0
	cmp.w	(c1playernum).w,d0
	beq.w	changeplayer
	moveq	#2,d4
	bra.w	changeplayer

assdopen	;add player a3 to penalty box
	btst	#5,$62(a3)
	bne.w	rtss
	moveq	#$10,d0
	btst	#6,$62(a3)
	beq.w	.1
	moveq	#1,d0
.1	add.b	d0,(PBnum).w		;IDA: loc_A448. Players in penalty box
	st	$34(a3)
	clr.w	6(a3)
	rts

assepen	;player a3 should exit penalty area
	btst	#5,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	bset	#2,$62(a3)		;pfnc
	bset	#2,$63(a3)		;pf2unav
	moveq	#$10,d0
	moveq	#-$3C,d1		;-60
	btst	#6,$62(a3)
	beq.w	.1
	moveq	#1,d0
	neg.w	d1
.1	sub.b	d0,(PBnum).w		;IDA: loc_A488. Players in penalty box
	move.w	d1,$14(a3)
	clr.w	$28(a3)
	clr.w	$2A(a3)
	move.w	#$86,(a3)
	move.w	#2,$54(a3)
	bset	#5,$62(a3)
	move.w	#$1166,d1		;SPAwallleft
	bsr.w	SetSPA
	jmp	SprSort
.nna	move.w	#4,$54(a3)		;IDA: loc_A4B6
	st	$61(a3)
	st	$60(a3)
	bclr	#3,$62(a3)		;pfjoycon
	bclr	#2,$62(a3)		;pfnc
	bclr	#5,$63(a3)		;pf2npc
	bclr	#2,$63(a3)		;pf2unav
	move.w	#$F000,$28(a3)		;-$1000
	bra.w	assexit

assfaceoff	;players do nothing until faceoff is over
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#0,(sflags2).w		;sf2faceoff
	beq.w	assexit			;exit once faceoff is over
	rts

assfaceoffp1	;assignment for players actually participating in faceoff
	;a3 = player (92 assfaceoffpl)
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#0,(sflags2).w
	beq.w	.exit
	bclr	#1,$62(a3)
	beq.w	.nna
	clr.w	$40(a3)
.nna	movea.l	#fofdata2,a0		;IDA: loc_A51E
	btst	#6,$62(a3)
	beq.w	.0
	addq.w	#4,a0
.0	move.w	$5A(a3),d0		;IDA: loc_A530. SPAnum
	lsr.w	#2,d0
	addq.w	#1,d0
	tst.b	$76(a3)			;handed
	bne.w	.lefty
	addq.w	#3,d0
.lefty	move.w	d0,(a0)			;IDA: loc_A542
	btst	#3,$62(a3)		;pfjoycon
	bne.w	rtss
	bset	#1,$63(a3)		;pf2aip
	bne.w	rtss
	move.w	#$11A4,d1		;SPAfaceoff
	cmpi.w	#$10,(word_FFB78A).w	;puckx+temp1
	bls.w	.d
	moveq	#8,d0
	bsr.w	randomd0
	tst.w	d0
	beq.w	.d
	move.w	#$11CE,d1		;SPAfaceoffr
.d	bset	#1,$63(a3)		;IDA: loc_A576
	bra.w	SetSPA
.exit	move.b	#$14,$5E(a3)		;IDA: loc_A580. nopuck = 20
	bra.w	assexit

assfight	;fighting logic
	;a3 = player
	btst	#5,$62(a3)		;check if animation lock
	bne.w	rtss			;exit if so
	tst.w	(Pencntdwn).w		;fight over?
	bmi.w	assnothing
	bclr	#1,$62(a3)		;clear new assignment
	beq.w	.nna			;not first time through
	bsr.w	getpde			;get player's energy level
	move.b	$74(a3),d1		;aggress (fighting)
	ext.w	d1
	mulu.w	d1,d0
	lsr.w	#8,d0
	lsr.w	#4,d0
	cmp.w	#5,d0
	bgt.w	.s
	moveq	#5,d0			;min strength is 5
.s	move.w	d0,$44(a3)		;IDA: loc_A5C0. temp3 = strength
	clr.w	$42(a3)			;temp2
	move.w	#$FFFF,$46(a3)		;temp4 = banner timer
	cmpi.w	#2,$54(a3)		;facedir
	bne.w	.nna
	move.w	#$5A,$46(a3)		;90: one player shows the banner
.nna	sub.w	d7,$46(a3)		;IDA: _nna. Sub frames elapsed from temp4
	bcc.w	.nna2
	bsr.w	banner			;show fighters' names
.nna2	tst.w	$44(a3)			;IDA: _nna2. temp3
	bmi.w	rtss
	move.w	$2E(a3),d0		;impactp
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0			;a0 = opponent
	move.w	(a3),d0
	add.w	(a0),d0
	asr.w	#1,d0
	move.w	d0,(xc1).w		;scroll lock between the fighters
	btst	#3,$62(a3)		;pfjoycon
	bne.w	.j
	bset	#1,$63(a3)		;pf2aip
	bne.w	.j
	move.w	(a3),d0			;computer punches only when in range
	sub.w	(a0),d0
	move.w	$28(a3),d1
	asr.w	#8,d1
	add.w	d1,d0
	move.w	$28(a0),d1
	asr.w	#8,d1
	sub.w	d1,d0
	cmp.w	#20,d0
	bgt.w	.j
	cmp.w	#-20,d0
	blt.w	.j
	moveq	#8,d0
	bsr.w	randomd0
	cmp.w	#2,d0
	bls.w	.p
	andi.w	#1,d0
.p	asl.w	#1,d0			;IDA: loc_A652
	lea	.al(pc),a1		;choose punch type
	move.w	(a1,d0.w),d1
	bsr.w	SetSPA
.j	bsr.w	chkhit			;IDA: _j
	cmpi.w	#$FE2,$58(a3)		;SPAfheld
	beq.w	.njc
	cmpi.w	#$F8E,$58(a3)		;SPAfight
	beq.w	.jc
	btst	#3,$62(a3)
	bne.w	.jc
.njc	move.w	(xc1).w,d0		;IDA: _njc
	addi.w	#$A,d0
	cmpi.w	#2,$54(a3)
	bne.w	.0
	subi.w	#$14,d0
.0	sub.w	(a3),d0			;IDA: _0
	asl.w	#5,d0			;93 adds to Xvel (92 clamps and sets)
	add.w	d0,$28(a3)
.jc	move.w	(yc1).w,d1		;IDA: _jc
	sub.w	$14(a3),d1
	asl.w	#8,d1
	cmp.w	#$1000,d1
	blt.w	.y1
	move.w	#$1000,d1
.y1	cmp.w	#-$1000,d1		;IDA: _y1
	bgt.w	.y2
	move.w	#$F000,d1
.y2	move.w	d1,$2A(a3)		;IDA: _y2. Yvel
	rts
.al	dc.w	$1004			;IDA: _a1. SPAfhigh
	dc.w	$1036			;SPAflow
	dc.w	$FC0			;SPAfgrab

chkhit	;part of fight to see if player is hit
	;a3 = player, a0 = opponent
	movem.l	d0/a0-a3,-(sp)
	move.w	6(a3),d0		;frame
	cmp.w	8(a3),d0		;oldframe
	beq.w	.ex
	cmp.w	#$164,d0		;SPFfight+2,d0
	beq.w	.dropped
	move.w	(a3),d0
	sub.w	(a0),d0
	cmp.w	#22,d0
	bgt.w	.ex
	cmp.w	#-22,d0
	blt.w	.ex
	move.w	$14(a3),d0
	sub.w	$14(a0),d0
	cmp.w	#8,d0
	bgt.w	.ex
	cmp.w	#-8,d0
	blt.w	.ex
	move.w	6(a3),d0
	cmp.w	#$168,d0		;SPFfight+6,d0
	beq.w	.hithigh
	cmp.w	#$16D,d0		;SPFfight+6+5,d0
	beq.w	.hithigh
	cmp.w	#$169,d0		;SPFfight+7,d0
	beq.w	.hitlow
	cmp.w	#$16E,d0		;SPFfight+7+5,d0
	beq.w	.hitlow
	cmp.w	#$166,d0		;SPFfight+4,d0
	beq.w	.grab
	cmp.w	#$16B,d0		;SPFfight+4+5,d0
	beq.w	.grab
.ex	movem.l	(sp)+,d0/a0-a3
	rts
.dropped	bclr	#5,$63(a3)		;pf2npc: gloves dropped
	move.w	(xc1).w,d0
	cmp.w	#90,d0
	blt.w	.chkneg
	moveq	#$5A,d0
.chkneg	cmp.w	#-90,d0		;IDA: _chkneg
	bgt.w	.drcont
	moveq	#-$5A,d0
.drcont	asr.w	#2,d0			;IDA: _drcont
	bne.w	.dr0
	addq.w	#1,d0
.dr0	move.b	d0,(glovecords).w	;IDA: _dr0
	move.w	(yc1).w,d0
	asr.w	#2,d0
	move.b	d0,(glovecords+1).w
	bra.s	.ex
.grab	exg	a0,a3			;IDA: _grab
	bset	#1,$63(a3)		;pf2aip
	move.w	#$FE2,d1		;SPAfheld
	bsr.w	SetSPA
	bra.s	.ex
.hithigh	exg	a0,a3			;IDA: _hithigh
	bsr.w	.cwd			;crowd reacts, knock back
	bset	#1,$63(a3)
	subq.w	#1,$44(a3)		;temp3
	bmi.w	.fall
	move.w	#$1068,d1		;SPAfhith
	bsr.w	SetSPA
	move.w	#9,-(sp)		;SFXhithigh
	bsr.w	sfx
	bra.s	.ex
.hitlow	exg	a0,a3			;IDA: _hitlow
	bsr.w	.cwd
	bset	#1,$63(a3)
	subq.w	#1,$44(a3)
	bmi.w	.fall
	move.w	#$108A,d1		;SPAfhitl
	bsr.w	SetSPA
	move.w	#$A,-(sp)		;SFXhitlow
	bsr.w	sfx
	bra.w	.ex
.cwd	;IDA: CwdFight. Crowd reacts to a punch; push the hit player (a3)
	;back by the puncher's (a0) strength
	addi.w	#$50,(crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
	moveq	#5,d0
	add.w	$44(a0),d0		;temp3
	mulu.w	#$1F4,d0		;500
	cmpi.w	#2,$54(a3)
	bne.w	.xveladj
	neg.w	d0
.xveladj	add.w	d0,$28(a3)		;IDA: _xveladj. Xvel
	rts
.fall	;IDA: FightFall. a3 lost the fight: change the a0 player's penalty to
	;fighting (PenFighting), maybe injure a3
	movem.l	a1,-(sp)
	movea.w	#(PenaltyBufferEnd-M68K_RAM),a1	;end of the scoring summary
.loop	addq.w	#2,a1			;IDA: FindPenaltyLoop
	cmpi.b	#$26,(a1)
	bne.s	.loop
	move.b	1(a1),d0
	andi.w	#$F,d0
	cmp.w	$52(a0),d0		;SCnum
	bne.s	.loop			;find the penalty of the a0 player
	move.b	#$28,(a1)		;penalty becomes PenFighting
	movem.l	(sp)+,a1
	move.w	#$3C,(Pencntdwn).w	;60
	move.w	#$FFFF,$44(a0)		;temp3 = -1
	addi.w	#$258,(crowdlevel).w	;600
	addi.w	#$1E,(CwdExciteLvl).w
	moveq	#$3C,d0
	bsr.w	randomd0
	cmp.b	$75(a0),d0		;checking value
	bgt.w	.noinj			;skip injury
	move.w	#$B4,(Pencntdwn).w	;180: player is injured
	bset	#6,$63(a3)
	move.w	#$10CE,d1		;SPAffall
	bsr.w	SetSPA
	bsr.w	ShowInjuryMsg
	movea.w	a3,a2
	bsr.w	setInjuryType
	move.w	#$112C,$66(a0,d1.w)	;overwrite setInjuryType result in the team struct
	move.w	#3,(InjCntDown).w
	bra.w	.ex
.noinj	move.w	#$10AC,d1		;IDA: NoInjury. SPAbfall
	bsr.w	SetSPA
	movea.w	#(hmtmstruct-M68K_RAM),a2
	move.w	#$B,-(sp)		;SFXcrowdcheer
	btst	#6,$62(a3)
	bne.w	.snd
	lea	$1A2(a2),a2
	move.w	#$C,(sp)		;SFXcrowdboo
.snd	bsr.w	song			;IDA: PlayCrowdSound
	bra.w	.ex

ShowInjuryMsg	;IDA: sub_A8AE (Rev A). Clear the message line
	bsr.w	printz
	String	$BF,0,1,0
	moveq	#$28,d0
	moveq	#5,d1
	move.w	#$7FF,d2
	bra.w	eraser

banner	;fight banner: close both line change boxes, frame a box with
	;"<player> <team>" for both fighters and "vs"
	movem.l	d0-d3/a0-a4,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	jsr	(lcfound2).l
	adda.w	#$1A2,a2
	jsr	(lcfound2).l
	jsr	(box).l
	movea.w	#(PenBuf-M68K_RAM),a0
	clr.w	d2			;widest line
.0	tst.w	(a0)+			;find end of penalty list
	bne.s	.0
	move.b	-3(a0),d0		;last penalty: the two fighters
	clr.b	d3
	bsr.w	addinfo
	neg.b	d3
	move.b	-5(a0),d0
	bsr.w	addinfo
	bsr.w	printz
	String	$BF,$F,1,0
	move.w	d2,d0
	lsr.w	#1,d2
	sub.w	d2,(printx).w
	moveq	#5,d1
	bsr.w	Framer
	move.w	#2,(printy).w
	tst.b	d3			;stronger fighter on top
	bmi.w	.neg
	move.w	#4,(printy).w
.neg	move.b	-3(a0),d0		;IDA: _neg
	bsr.w	addinfo
	bsr.w	print
	eori.w	#6,(printy).w
	move.b	-5(a0),d0
	bsr.w	addinfo
	bsr.w	print
	bsr.w	printz
	String	$BF,$F,3,'vs',0
	movem.l	(sp)+,d0-d3/a0-a4
	rts

addinfo	;d0 = penalty byte (player SCnum in low nibble). Build
	;"<name> <team>" in a1, add aggress to d3, keep widest in d2,
	;centre printx
	movea.w	#(SortCords-M68K_RAM),a1
	andi.w	#$F,d0
	asl.w	#7,d0
	add.b	$74(a1,d0.w),d3		;aggress
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#6,$62(a1,d0.w)
	beq.w	.0
	adda.w	#$1A2,a2
.0	move.b	$66(a1,d0.w),d0		;IDA: _0. pnum
	ext.w	d0
	jsr	(getname).l
	movea.w	a1,a3
	bsr.w	appendz
	String	' ',0
	movea.l	$1E(a2),a1		;team name
	adda.w	4(a1),a1
	adda.w	(a1),a1
	bsr.w	appstring
	cmp.w	(a3),d2
	bgt.w	.gt
	move.w	(a3),d2
.gt	movea.w	a3,a1			;IDA: _gt
	move.w	(a1),d0
	lsr.w	#1,d0
	neg.w	d0
	addi.w	#$10,d0
	move.w	d0,(printx).w
	rts

assfwatch	;for player who is watching fight
	;a3 = player
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#3,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	clr.w	$40(a3)
.nna	sub.w	d7,$40(a3)		;IDA: loc_A9DA
	bpl.w	.go
	addi.w	#$3C,$40(a3)		;new spot every second
	move.w	(a3),d0
	sub.w	(xc1).w,d0
	move.w	$14(a3),d1
	sub.w	(yc1).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	sroot
	move.w	d0,d2
	bne.w	.d
	moveq	#1,d2
.d	movem.w	(sp)+,d0-d1		;IDA: loc_AA0C
	muls.w	#$50,d0			;80 pixels from the fight
	divs.w	d2,d0
	add.w	(xc1).w,d0
	move.w	#$7E,d3
	cmp.w	d3,d0
	blt.w	.x0
	move.w	d3,d0
.x0	neg.w	d3			;IDA: loc_AA26
	cmp.w	d3,d0
	bgt.w	.x1
	move.w	d3,d0
.x1	move.w	d0,$44(a3)		;IDA: loc_AA30. temp3
	muls.w	#$50,d1
	divs.w	d2,d1
	add.w	(yc1).w,d1
	move.w	d1,$46(a3)		;temp4
.go	move.w	$44(a3),d0		;IDA: loc_AA42
	move.w	$46(a3),d1
	lea	rtss(pc),a0
	bsr.w	skateto
	bra.w	check4check

assnothing	;player should do nothing
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#3,$62(a3)
	bne.w	rtss
	moveq	#8,d0
	bra.w	doplayeracc

assstanley	;player a3 skates with stanley cup overhead
	btst	#5,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	move.w	#$5A,$44(a3)		;90
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	$44(a3)
.0	move.w	(Vpos).w,$46(a3)	;IDA: loc_AA96
	move.w	#$1258,d1		;SPAStanley
	bsr.w	SetSPA
.nna	move.w	$44(a3),d0		;IDA: loc_AAA4
	sub.w	(a3),d0
	move.w	$46(a3),d1
	sub.w	$14(a3),d1
	bsr.w	vtoa
	cmp.w	#7,d0
	bgt.w	rtss
	move.w	d0,d2
	move.w	d2,$54(a3)
	bra.w	playeracc

assscore	;player a3 celebrates, if scoring player then do arm pump
	btst	#5,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	bsr.w	.1
	move.w	#8,$42(a3)
	move.w	#$5A,$44(a3)
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	$44(a3)
.0	move.w	(Vpos).w,$46(a3)	;IDA: loc_AAF8
.nna	movea.l	#rtss,a0		;IDA: loc_AAFE
	move.w	$44(a3),d0
	move.w	$46(a3),d1
	sub.w	d7,$40(a3)
	bpl.w	.chkcon
	bset	#5,$62(a3)
	move.w	#$EAA,d1		;SPAcelebrate
	move.w	(shotplayer).w,d0
	cmp.w	$52(a3),d0
	bne.w	.nopump
	move.w	#$F1C,d1		;SPApump
.nopump	bsr.w	SetSPA			;IDA: loc_AB2E
.1	moveq	#$78,d0			;IDA: loc_AB32. 120
	bsr.w	randomd0
	move.w	d0,$40(a3)
	rts
.chkcon	btst	#3,$62(a3)		;IDA: loc_AB3E
	beq.w	skateto
	rts

assdefo	;player a3 is defensive player on offense
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#0,(gmode).w		;gmclock
	bne.w	assnothing
	bsr.w	check4bench
	btst	#3,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	clr.w	$40(a3)
	move.w	#8,$42(a3)
.nna	sub.b	d7,$40(a3)		;IDA: loc_AB80
	bpl.w	.nodec
	move.b	$6A(a3),$40(a3)		;aioff
	move.l	#2,d0			;adefd
	btst	#4,$30(a2)		;93: team flag forces defense
	bne.w	assreplace
	move.w	(pucky).w,d1
	btst	#7,$62(a3)
	bne.w	.de1
	neg.w	d1
.de1	cmp.w	#$5D,d1		;IDA: loc_ABAE. blueline,d1
	blt.w	assreplace
	move.w	(puckc).w,d1
	bmi.w	.nodec
	subq.w	#6,d1
	move.w	$52(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace		;other team has puck
.nodec	lea	EvadePC(pc),a0		;IDA: loc_ABCC
	moveq	#$50,d0
	cmpi.w	#2,$34(a3)
	beq.w	.1
	neg.w	d0
.1	move.w	#$62,d1			;IDA: loc_ABDE. 93: 98 (92 blueline+10)
	btst	#7,$62(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0	move.w	(puckx).w,d2		;IDA: loc_ABF0
	eor.w	d0,d2
	bmi.w	.2
	move.w	(puckx).w,d0
	bra.w	skateto
.2	move.w	(puckx).w,d2		;IDA: loc_AC02
	asr.w	#1,d2
	add.w	d2,d0
	bra.w	skateto

assdefd	;player a3 is defensive player on defense
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	assnothing
	bsr.w	check4bench
	btst	#3,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	clr.w	$40(a3)
	move.w	#8,$42(a3)
.nna	sub.b	d7,$40(a3)		;IDA: loc_AC44
	bpl.w	.de3
	move.b	$6B(a3),$40(a3)		;aidef
	move.w	(pucky).w,d1
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	btst	#7,$62(a3)
	bne.w	.de00
	neg.w	d1
	neg.w	d3
.de00	tst.w	d3			;IDA: loc_AC6A. 93: only lead when moving up ice
	bpl.w	.v
	clr.w	d3
.v	add.w	d1,d3			;IDA: loc_AC72
	cmp.w	#$58,d3
	blt.w	.de0
	btst	#4,$30(a2)
	bne.w	.de0
	move.w	(puckc).w,d1
	bmi.w	.de0
	bsr.w	chkpk
	beq.w	.de0
	move.l	#1,d0			;adefo
	subq.w	#6,d1
	move.w	$52(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace		;our team has puck
.de0	move.w	#$41,$44(a3)		;IDA: loc_ACAA. 65
	cmpi.w	#2,$34(a3)
	beq.w	.de1
	neg.w	$44(a3)
.de1	movea.w	#(SortCords-M68K_RAM),a0	;IDA: loc_ACBE
	cmpi.w	#6,$52(a3)
	bge.w	.de2
	adda.w	#$300,a0		;6*SCstruct
.de2	moveq	#5,d2			;IDA: loc_ACD0. Find furthest-up attacker
	move.w	#$FC18,d0		;-1000
	btst	#7,$62(a3)
	beq.w	.gdwn
	neg.w	d0
.gup	btst	#2,$63(a0)		;IDA: loc_ACE2. pf2unav
	bne.w	.gu0
	tst.w	$34(a0)
	bmi.w	.gu0
	move.w	$2A(a0),d1
	bmi.w	.gu2
	clr.w	d1
.gu2	asr.w	#4,d1			;IDA: loc_ACFE. 92 asr #5
	add.w	$14(a0),d1
	cmp.w	d0,d1
	bgt.w	.gu0
	move.w	d1,d0
.gu0	adda.w	#$80,a0			;IDA: loc_AD0C
	dbf	d2,.gup
	subi.w	#$32,d0			;93: 50 back of him
	cmp.w	#-190,d0
	bgt.w	.gu1
	move.w	#$FF24,d0		;-220
.gu1	move.w	d0,$46(a3)		;IDA: loc_AD24
	move.w	(puckx).w,d0
	move.w	$44(a3),d1
	eor.w	d0,d1
	bpl.w	.de3
	clr.w	$44(a3)
	bra.w	.de3
.gdwn	btst	#2,$63(a0)		;IDA: loc_AD3E
	bne.w	.gd0
	tst.w	$34(a0)
	bmi.w	.gd0
	move.w	$2A(a0),d1
	bpl.w	.gd2
	clr.w	d1
.gd2	asr.w	#4,d1			;IDA: loc_AD5A
	add.w	$14(a0),d1
	cmp.w	d0,d1
	blt.w	.gd0
	move.w	d1,d0
.gd0	adda.w	#$80,a0			;IDA: loc_AD68
	dbf	d2,.gdwn
	addi.w	#$32,d0
	cmp.w	#190,d0
	blt.w	.gd1
	move.w	#$DC,d0			;220
.gd1	move.w	d0,$46(a3)		;IDA: loc_AD80
	neg.w	$44(a3)
	move.w	(puckx).w,d0
	move.w	$44(a3),d1
	eor.w	d0,d1
	bpl.w	.de3
	clr.w	$44(a3)
.de3	move.w	$44(a3),d0		;IDA: loc_AD9A
	move.w	$46(a3),d1
	movea.l	#EvadePC,a0
	bsr.w	skateto
	bra.w	check4check

asswingd	;player a3 is wing on defense
	btst	#5,$62(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	assnothing
	bsr.w	check4bench
	btst	#3,$62(a3)
	bne.w	rtss
	bclr	#1,$62(a3)
	beq.w	.nna
	clr.w	$40(a3)
	move.w	#8,$42(a3)
.nna	sub.b	d7,$40(a3)		;IDA: loc_ADE6
	bpl.w	.nodec
	move.b	$6B(a3),$40(a3)		;aidef
	move.w	(puckc).w,d1
	bmi.w	.nodec
	move.l	#4,d0			;awingo
	subq.w	#6,d1
	move.w	$52(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace		;our team has puck
.nodec	moveq	#$64,d0			;IDA: loc_AE10. 100
	cmpi.w	#5,$34(a3)
	bne.w	.0
	neg.w	d0
.0	move.l	#$9E,d1			;IDA: loc_AE1E
	btst	#7,$62(a3)
	beq.w	.up
	neg.w	d0
	neg.w	d1
	moveq	#-$4E,d2
	btst	#4,$30(a2)
	bne.w	.set
	cmp.w	(pucky).w,d2
	bgt.w	.lo
	move.w	(pucky).w,d1
	bra.w	.go
.lo	move.w	#$FEF8,d2		;IDA: loc_AE4E. -264
	cmp.w	(pucky).w,d2
	blt.w	.go
	move.w	d2,d1
	bra.w	.go
.up	moveq	#$4E,d2			;IDA: loc_AE60
	btst	#4,$30(a2)
	bne.w	.set
	cmp.w	(pucky).w,d2
	blt.w	.hi
	move.w	(pucky).w,d1
	bra.w	.go
.hi	move.w	#$108,d2		;IDA: loc_AE7C. 264
	cmp.w	(pucky).w,d2
	bgt.w	.go
.set	move.w	d2,d1			;IDA: loc_AE88
.go	lea	rtss(pc),a0		;IDA: loc_AE8A
	move.w	(puckx).w,d2
	eor.w	d0,d2
	bmi.w	skateto
	move.w	(puckx).w,d0
	bra.w	skateto
