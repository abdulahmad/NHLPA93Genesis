;	NHLPA Hockey 93 (retail) segment $BC6C-$C9E9
;	92 Logic.Asm part 4: checkob, assnearest, check4check, asspassrec,
;	assshoot, pucknothing, puckfaceoff, ChkGoalies, ReturnGoalies,
;	CPgoalie, CompLine, puckfaceoff2, updatefaceoff, Endfaceoff,
;	pucknorm. Global names from the IDA export, 92 names where the
;	routine is the same (see the SEGMENT_AGENT.md rename table). Bytes
;	match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	93 SortCords offsets, 92 names in comments: Xpos 0, attribute 4,
;	frame 6, Ypos $14, Zpos $18, Xvel $28, Yvel $2A, Zvel $2C,
;	position $34, assnum $36, asslist $38, temp1 $40, temp2 $42,
;	temp3 $44, temp4 $46, SCnum $52, facedir $54, SPA $58, nopuck $5E,
;	pflags $62 (pfdoff 0, pfna 1, pfnc 2, pfjoycon 3, pfalock 5,
;	pfteam 6, pfgoal 7), pflags2 $63 (pf2fight 0, pf2unav 2, pf2lcm 3),
;	aioff $6A, aggress $75.
;	Team struct (hmtmstruct, tmsize $1A2): tmscore $C, tmline $16,
;	tmsort $22 (word), tmap $24, tmgoalie $26, $2A = long (93),
;	tmflags $30.

checkob	;bring up little warning ref if a player on your team is over blue line. Called from doinput and asspuckc
	btst	#gmoffs,(gmode).w
	beq.w	rtss
	movem.l	d0-d1/a0,-(sp)
	moveq	#5,d0
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	blt.w	.0
	adda.w	#6*SCstruct,a0
.0	moveq	#$5C,d1			;IDA: checkob_0. blue line y (92 move blueline,d1)
	btst	#pfgoal,pflags(a3)
	bne.w	.top
	neg.w	d1
	cmp.w	(pucky).w,d1
	bgt.w	.nob
.bottom	tst.w	position(a0)			;IDA: checkob_bottom
	bmi.w	.bn
	cmp.w	Ypos(a0),d1
	bgt.w	.ob
.bn	adda.w	#SCstruct,a0			;IDA: checkob_bn
	dbf	d0,.bottom
.nob	moveq	#$40,d0			;IDA: checkob_nob
	bclr	#sf2offsig,(sflags2).w
	bne.w	.dref
.ex	movem.l	(sp)+,d0-d1/a0		;IDA: checkob_ex
	rts

.ob	moveq	#6,d0			;IDA: checkob_ob (92 moveq #32,d0)
	bset	#sf2offsig,(sflags2).w
	bne.s	.ex
.dref	tst.w	(RefCnt).w		;IDA: checkob_dref
	bpl.s	.ex
	bsr.w	PushRef
	bra.s	.ex

.top	cmp.w	(pucky).w,d1		;IDA: checkob_top
	blt.s	.nob
.top1	tst.w	position(a0)			;IDA: checkob_top1
	bmi.w	.tn
	cmp.w	Ypos(a0),d1
	blt.s	.ob
.tn	adda.w	#SCstruct,a0			;IDA: checkob_tn
	dbf	d0,.top1
	bra.s	.nob

assnearest	;this is a special assignment used for the player who is nearest the puck but doesn't have it. Assignment anearest ($11)
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp3(a3)
	move.w	#8,temp2(a3)
	clr.w	temp1(a3)
.nna	move.w	SCnum(a3),d1		;IDA: _nna
	cmp.w	(puckc).w,d1
	bne.w	.nopc
	tst.w	position(a3)
	beq.w	assgoalie
	move.l	#$10,d0			;apuckc
	btst	#pfjoycon,pflags(a3)
	beq.w	assinsert
	rts
.nopc	sub.b	d7,temp1(a3)		;IDA: _nopc
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)
	clr.l	$2A(a2)			;93: team long, set to best distance below
	move.w	(puckc).w,d1
	bmi.w	.np
	asl.w	#7,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a1
	adda.w	d1,a1
	move.b	pflags(a1),d0
	move.b	pflags(a3),d1
	eor.b	d0,d1
	btst	#pfteam,d1
	beq.w	.switch			;our team has the puck
.np	moveq	#-1,d2			;IDA: _np
	moveq	#5,d4
	movea.w	tmsort(a2),a0		;tmsort: first player of the team (92 from SCnum)
.de0	tst.w	position(a0)			;IDA: _de0
	ble.w	.next
	tst.b	nopuck(a0)
	bne.w	.next
	btst	#2,pflags2(a0)		;pf2unav
	bne.w	.next
	move.w	assnum(a0),d0		;93: skip a player whose current assignment
	cmpi.b	#$13,asslist(a0,d0.w)	;is apassrec
	beq.w	.next
	move.l	a0,-(sp)
	bsr.w	GetHot
	add.w	(a0),d0
	sub.w	(puckx).w,d0
	add.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	move.w	(puckvx).w,d3		;93: always lead the puck (92 only if carried)
	asr.w	#6,d3
	sub.w	d3,d0
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	sub.w	d3,d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	d2,d0
	bhi.w	.next
	move.l	d0,d2
	movea.w	a0,a1
.next	adda.w	#SCstruct,a0			;IDA: _next
	dbf	d4,.de0
	tst.l	d2
	bmi.w	.de1
	move.l	d2,$2A(a2)		;93: nearest distance^2
.switch	cmpa.w	a1,a3			;IDA: _switch
	beq.w	.de1
	btst	#gmclock,(gmode).w
	bne.w	.de1
	btst	#2,pflags2(a1)		;pf2unav
	bne.w	.de1
	exg	a1,a3
	bclr	#pfdoff,pflags(a3)
	move.l	#$11,d0			;anearest
	bsr.w	assinsert
	exg	a1,a3
	bra.w	assexit
.de1	btst	#pfalock,pflags(a3)		;IDA: _de1. 92 tst position / beq rtss
	bne.w	rtss
	moveq	#2,d1
	cmp.w	#$190,d2		;20^2,d2 (commented out in 92)
	bhi.w	.nfar
	subq.w	#2,d1
	cmpi.w	#2,position(a3)
	bls.w	.nodec			;close and position <= 2: no new temp3
.nfar	btst	#sf2pwrplay,(sflags2).w		;IDA: _nfar
	beq.w	.x
	subq.w	#2,d1
	bsr.w	chkpk2
	bne.w	.x			;not killing penalty
	addq.w	#4,d1
.x	moveq	#$14,d0			;IDA: _x
	sub.b	$75(a3),d0		;aggress
	asl.w	d1,d0
	bsr.w	randomd0
	cmp.w	#1,d0		;(92 #2)
	bhi.w	.nodec
	move.w	#$F0,temp3(a3)		;temp3 = 240
.nodec	btst	#pfalock,pflags(a3)		;IDA: _nodec. 92 tst position
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	assnothing		;92 donothing
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	btst	#2,tmflags(a2)		;93: tmflags bit 2 always takes the in-between spot
	bne.w	.mid
	tst.w	(puckc).w
	bmi.w	.topuck
	sub.w	d7,temp3(a3)
	bpl.w	.topuck
	clr.w	temp3(a3)
.mid	bsr.w	skatetopuckinit		;IDA: _topuck. 93: d0/d1 = halfway between
	movem.w	d0-d1,-(sp)		;skatetopuckinit's spot and (0,$F4),
	neg.w	d0			;or (0,-$F4) if pfgoal
	neg.w	d1
	addi.w	#$F4,d1
	btst	#pfgoal,pflags(a3)
	beq.w	.nd0
	subi.w	#$1E8,d1
.nd0	asr.w	#1,d0			;IDA: _nd0
	asr.w	#1,d1
	add.w	(sp)+,d0
	add.w	(sp)+,d1
	btst	#2,tmflags(a2)		;tmflags bit 2: clamp y to +-$44 from $53
	beq.w	.go
	btst	#pfgoal,pflags(a3)
	beq.w	.neg
	cmp.w	#$53,d1
	blt.w	.go
	move.w	#$44,d1
	bra.w	.go
.neg	cmp.w	#-$53,d1		;IDA: loc_BF0A
	bgt.w	.go
	move.w	#-$44,d1
.go	lea	rtss(pc),a0		;IDA: loc_BF16
	bsr.w	skateto
	bra.w	check4check
.topuck	bsr.w	skatetopuck		;IDA: topuck. Falls into check4check

check4check	;look for good opportunity for checking opponent. Falls in from assnearest; also entered from assfwatch and asswingd
	moveq	#$14,d0
	sub.b	$75(a3),d0		;aggress
	tst.w	(OptPen).w
	beq.w	.nopen
	asl.w	#1,d0
.nopen	bsr.w	randomd0		;IDA: loc_BF36
	cmp.w	#3,d0		;(92 tst d0)
	bhi.w	rtss
	moveq	#5,d2
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.0
	adda.w	#6*SCstruct,a0
.0	tst.w	position(a0)			;IDA: loc_BF56
	beq.w	.next
	btst	#pfalock,pflags(a0)		;93: skip
	bne.w	.next
	btst	#pf2fight,pflags2(a0)		;93: skip
	bne.w	.next
	move.w	(a0),d0
	sub.w	(a3),d0
	cmp.w	#30,d0
	bgt.w	.next
	cmp.w	#-30,d0
	blt.w	.next
	move.w	Ypos(a0),d1
	sub.w	Ypos(a3),d1
	cmp.w	#30,d1
	bgt.w	.next
	cmp.w	#-30,d1
	blt.w	.next
	bsr.w	vtoa
	cmp.w	facedir(a3),d0
	bne.w	.next
	move.w	(VDP_CNTR).l,d0		;93: HV counter as random, 1 in 4 is a
	andi.w	#3,d0			;hold/hook instead of a check
	bne.w	burst
	bra.w	Acheck
.next	adda.w	#SCstruct,a0			;IDA: loc_BFBC
	dbf	d2,.0
	rts

asspassrec	;IDA: loc_BFC6. assignment for catching pass. Assignment apassrec ($13)
	btst	#pfalock,pflags(a3)		;93 only
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	assnothing		;92 donothing
	btst	#pfjoycon,pflags(a3)
	bne.w	assexit
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	bset	#pfdoff,pflags(a3)
	move.b	#8,temp2+1(a3)
	clr.b	temp2(a3)			;93: temp2 high byte
.nna	tst.w	(puckc).w		;IDA: loc_BFFE
	bpl.w	.ex
	sub.b	d7,temp1(a3)		;93: puck loose: wait temp1 (92 bmi skatetopuck)
	bpl.w	rtss
.ex	bclr	#pfdoff,pflags(a3)		;IDA: loc_C00E
	bra.w	assexit
;unreferenced (IDA dc.b): skate to temp3/temp4
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	lea	rtss(pc),a0
	bra.w	skateto

assshoot	;IDA: loc_C028. assignment for computer shooting. Assignment ashoot ($12)
	btst	#pfalock,pflags(a3)		;93 only
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	bra.w	SetShotMode
.nna	btst	#sfssdir,(sflags).w		;IDA: loc_C040
	beq.w	assexit
	clr.w	d2			;(92 also loads temp1 into d0)
	sub.w	d7,temp2(a3)
	bpl.w	ShotMode
	bset	#5,d2			;cbut
	bra.w	ShotMode

pucknothing	;puck just slides along. Rev A listing labels this puckunflip
	bra.w	puckunflip

puckfaceoff	;this is where the action starts
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	tst.w	(gameclock).w
	beq.w	PeriodOver
	btst	#6,(gmode).w		;93: gmode bit 6 also ends the period
	bne.w	PeriodOver
	cmpi.w	#3,(gsp).w
	bne.w	.npo
	move.w	(hmtmstruct+tmscore).w,d0
	cmp.w	(awtmstruct+tmscore).w,d0
	bne.w	clockcont_0		;92 PeriodOver
.npo	btst	#gmpendel,(gmode).w		;IDA: _npo
	bne.w	Stop4Pen
	move.w	(PerTimeTotal).w,d0	;93: song $34 once, at the first faceoff
	asr.w	#1,d0			;past half the period with 60 s or more left,
	cmp.w	(gameclock).w,d0	;while sflags3 bit 7 is set
	bls.w	.rg
	cmpi.w	#$3C,(gameclock).w
	blt.w	.rg
	bclr	#7,(sflags3).w
	beq.w	.rg
	btst	#gmclock,(gmode).w
	beq.w	.rg
	move.w	#$34,-(sp)
	bsr.w	song
.rg	bsr.w	ReturnGoalies		;IDA: loc_C0D0
	st	temp1(a3)
	st	temp2(a3)
	tst.w	(OptLine).w
	bne.w	.nna
	bclr	#1,(byte_FFC516).w	;93: home tmflags bit 1
	bclr	#1,(byte_FFC6B8).w	;93: away tmflags bit 1
	movea.w	#(SortCords-M68K_RAM),a0	;93: clear pf2lcm on all 12 players
	moveq	#$B,d0
.lcm	bclr	#3,pflags2(a0)		;IDA: loc_C0F6
	adda.w	#SCstruct,a0
	dbf	d0,.lcm
	move.w	(cont1team).w,d0
	or.w	(cont2team).w,d0
	beq.w	.nohor
	btst	#sfhor,(sflags).w
	beq.w	.nohor
	bsr.w	forceblack
	bset	#sfslock,(sflags).w
	bsr.w	ClrHor
	move.w	#$18,(palcount).w
.nohor	move.w	(c1playernum).w,d0	;IDA: nohor
	bmi.w	.nlp
	bsr.w	.slc
.nlp	move.w	(c2playernum).w,d0	;IDA: nlp
	bmi.w	.nlp2
	bsr.w	.slc
.nlp2	movea.w	#(hmtmstruct-M68K_RAM),a1	;IDA: nlp2
	lea	tmsize(a1),a2
	moveq	#2,d0
	bsr.w	.sclc
	bra.w	.nna

.sclc	tst.w	(OptLine).w		;IDA: puckfaceoff_sclc
	bne.w	rtss
	cmp.w	(cont1team).w,d0
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	bsr.w	CompLine
	bsr.w	setpersonel
	bra.w	printscores1

.slc	exg	a2,a3			;IDA: puckfaceoff_slc
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	bclr	#3,pflags2(a3)		;pf2lcm
	move.l	a2,-(sp)
	bsr.w	SetLCmode
	movea.l	(sp)+,a2
	btst	#3,pflags2(a3)		;pf2lcm
	beq.w	.slcex
	btst	#pfteam,pflags(a3)
	beq.w	.t1
	move.w	#$168,temp2(a2)		;temp2 = 6*60 (92 3*60)
	move.w	SCnum(a3),temp4(a2)		;temp4 = SCnum
	bra.w	.slcex
.t1	move.w	#$258,temp1(a2)		;IDA: loc_C1B8. temp1 = 10*60 (92 5*60)
	move.w	SCnum(a3),temp3(a2)		;temp3 = SCnum
.slcex	exg	a2,a3			;IDA: loc_C1C4
	rts
.nna	move.w	#$40,d0			;IDA: nna. temp1
	bsr.w	.clc
	move.w	#$42,d0			;temp2
	bsr.w	.clc
	tst.w	temp1(a3)
	bpl.w	rtss
	tst.w	temp2(a3)
	bpl.w	rtss
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.sclc
	move.w	#$1C,d0			;pfaceoff2
	bra.w	assreplace

.clc	tst.w	(a3,d0.w)		;IDA: UpdatePlayerLineChangeTimer
	bmi.w	rtss
	move.w	4(a3,d0.w),d1		;temp3/temp4 = SCnum
	asl.w	#7,d1
	movea.w	#(SortCords-M68K_RAM),a0
	movea.w	#(hmtmstruct-M68K_RAM),a2	;93: a2 = his team for SetLCmode2
	btst	#pfteam,pflags(a0,d1.w)
	beq.w	.clh
	adda.w	#tmsize,a2
.clh	btst	#3,pflags2(a0,d1.w)		;IDA: loc_C222. pf2lcm
	bne.w	.clnd
	st	(a3,d0.w)
	bra.w	SetLCmode2		;93: redraw lc box (92 rts)
.clnd	sub.w	d7,(a3,d0.w)		;IDA: loc_C234
	bpl.w	rtss
	move.l	a3,-(sp)
	lea	(a0,d1.w),a3
	btst	#3,pflags2(a3)		;pf2lcm
	beq.w	.clcex
	clr.w	d2
	bsr.w	lcfound
	bsr.w	SetLCmode2		;93
.clcex	movea.l	(sp)+,a3		;IDA: loc_C256
	rts

ChkGoalies	;computer pulls goalie on delayed penalty. Called from periodicevents
	btst	#gmclock,(gmode).w		;93 only
	bne.w	rtss
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.CPG
	moveq	#2,d0
	exg	a1,a2
.CPG	tst.w	tmgoalie(a2)			;IDA: CheckGoaliePull. tmgoalie already out
	bmi.w	rtss
	move.w	(puckc).w,d1
	bmi.w	rtss
	subq.w	#6,d1
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	beq.w	.0
	not.w	d1			;(92 neg)
.0	tst.w	d1			;IDA: loc_C292
	bpl.w	rtss			;exit unless team a2 has the puck
	btst	#gmpendel,(gmode).w
	beq.w	.cp
	st	tmgoalie(a2)			;pull goalie (92 move #2,tmgoalie), any team
	bra.w	setpersonel
.cp	cmp.w	(cont1team).w,d0	;IDA: loc_C2AA. 93: rest is CPG for computer teams
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	move.w	(pucky).w,d1
	bra.w	CPgoalie

ReturnGoalies	;IDA: loc_C2C2. if computer pulled goalie, look to see if computer should return him. Called from puckfaceoff
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.r
	moveq	#2,d0
	exg	a1,a2
.r	cmpi.w	#-1,tmgoalie(a2)		;IDA: loc_C2D4. tmgoalie $FFFF stays out
	beq.w	rtss
	clr.b	tmgoalie(a2)			;return goalie
	cmp.w	(cont1team).w,d0
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	move.w	(foy).w,d1

CPgoalie	;IDA: loc_C2F6. see if computer should pull his goalie. d1 = puck/faceoff y. Falls in from ReturnGoalies; also entered from ChkGoalies
	cmpi.w	#2,(gsp).w
	bne.w	rtss			;exit if not 3rd per.
	move.w	tmscore(a1),d0
	sub.w	tmscore(a2),d0
	bmi.w	rtss			;exit if leading the game
	cmp.w	#2,d0
	bne.w	rtss			;exit unless behind by 2
	cmpi.w	#$3C,(gameclock).w
	bgt.w	rtss			;exit if more than 1 min left
	move.l	a0,-(sp)
	movea.w	tmsort(a2),a0
	btst	#pfgoal,pflags(a0)
	movea.l	(sp)+,a0
	bne.w	.0
	neg.w	d1
.0	tst.w	d1			;IDA: loc_C332
	bmi.w	rtss
	st	tmgoalie(a2)			;pull goalie (92 move #2,tmgoalie)
	bra.w	setpersonel

CompLine	;find good line for comp to switch to. a2 = team, a1 = other team. Called from chk4lc and puckfaceoff
	movem.l	d0-d2/a0,-(sp)
	moveq	#3,d0
	move.w	tmap(a2),d1
	sub.w	tmap(a1),d1
	beq.w	.nopwr
	bpl.w	.0
	addq.w	#2,d0
.0	move.w	d0,-(sp)		;IDA: _0. find pk/pwr line
	bsr.w	getlinee
	move.w	d0,d1
	move.w	(sp),d0
	addq.w	#1,d0
	bsr.w	getlinee
	cmp.w	d0,d1
	bge.w	.1
	addq.w	#1,(sp)
.1	move.w	(sp)+,tmline(a2)		;IDA: _1
.ex	movem.l	(sp)+,d0-d2/a0		;IDA: _ex
	rts

.nopwr	cmpa.w	#(hmtmstruct-M68K_RAM),a2	;IDA: _nopwr. find normal line
	bne.w	.away
	moveq	#2,d1
	lea	.hl1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.h0
	move.w	tmscore(a2),d2
	cmp.w	tmscore(a1),d2
	beq.w	.h0
	adda.w	#$E,a0
	bgt.w	.h0			;(92 bgt .a0)
	adda.w	#$E,a0
.h0	move.w	tmline(a1),d1		;IDA: _h0
	asl.w	#1,d1
	move.w	(a0,d1.w),d0
	bsr.w	getlinee
	cmp.w	#3*$1000/4,d0
	bls.w	.away
	move.w	(a0,d1.w),tmline(a2)
	bra.s	.ex

.hl1	dc.w	0,1,2,0,1,0,1		;IDA: hl1
	dc.w	2,0,1,2,0,2,0
	dc.w	0,1,0,0,1,0,1

.away	moveq	#2,d1			;IDA: _away
	lea	.al1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.a0
	move.w	tmscore(a2),d2
	cmp.w	tmscore(a1),d2
	beq.w	.a0
	addq.w	#6,a0
	bgt.w	.a0
	addq.w	#6,a0
.a0	move.w	(a0)+,d0		;IDA: _a0
	bsr.w	getlinee
	cmp.w	#3*$1000/4,d0		;(92 19*$1000/20)
	dbhi	d1,.a0
	move.w	-(a0),tmline(a2)
	bra.w	.ex

.al1	dc.w	0,1,2			;IDA: _al1
	dc.w	0,2,1
	dc.w	0,1,0

puckfaceoff2	;face off control logic and general setup for action
	bclr	#pfna,pflags(a3)
	beq.w	.nna			;not first time thru
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
.p	btst	#dfok,(disflags).w		;IDA: _p
	bne.s	.p			;wait for vblank
	cmpi.w	#$258,(crowdlevel).w
	bls.w	.ntm
	move.w	#$258,(crowdlevel).w	;limit crowd level
.ntm	bset	#dfclock,(disflags).w		;IDA: _ntm. stop clock
	bclr	#sfpz,(sflags).w		;no pause
	bclr	#sf3llcs,(sflags3).w		;no line changes
	clr.w	(glovecords).w		;no fighting gloves
	clr.b	(iflags).w		;no icing
	st	(RefCnt).w		;no refs
	st	(puckcross+2).w	;no goalie moes
	st	(puckcross+6).w
	bclr	#sf2refref,(sflags2).w
	bset	#sf2faceoff,(sflags2).w
	bset	#sf2drec,(sflags2).w		;don't record yet
	st	(passReceiverPlayerNum).w	;93
	bset	#4,(disflags).w		;93: cleared again in updatefaceoff
	bsr.w	ClrHor			;vertical icerink
	clr.w	(Vpos).w		;center h/v pos
	clr.w	(Hpos).w
	move.w	(fox).w,(puckx).w
	move.w	(foy).w,(pucky).w
	st	(puckz).w		;no visible puck
	clr.w	(puckvx).w
	clr.w	(puckvy).w
	clr.w	(puckvz).w
	st	(puckc).w
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a0	;reposition goal nets
	clr.w	Xvel(a0)
	clr.w	Yvel(a0)
	clr.w	(a0)			;Xpos
	move.w	#$10C,Ypos(a0)		;268
	adda.w	#SCstruct,a0
	clr.w	Xvel(a0)
	clr.w	Yvel(a0)
	clr.w	(a0)
	move.w	#-$10C,Ypos(a0)
	movea.w	#(SortCords+(15*SCstruct)-M68K_RAM),a0
	move.w	#$18A,frame(a0)		;SPFpuck
	clr.w	SPA(a0)
	clr.w	attribute(a0)
	clr.w	(word_FFB74E).w		;SortCords+(puckSCnum*SCstruct)+attribute
	bclr	#sfslock,(sflags).w		;free up scrolling
	moveq	#$64,d4
.cw	bsr.w	checkwindow		;IDA: _cw. scroll to faceoff spot
	dbf	d4,.cw
	move.w	#$3C,(yleader).w
	bsr.w	ResetBench
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	adda.w	#tmsize,a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	bsr.w	resetplstuff
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d2
.l0	move.w	#-$F0,(a3)		;IDA: loc_C552. Xpos = -240
	clr.w	Ypos(a3)
	clr.w	frame(a3)
	move.w	position(a3),d1
	bmi.w	.next
	beq.w	.goalie1
	move.l	#$16,d0			;afaceoff
	cmp.w	#4,d1
	bne.w	.l1
	movea.w	#(hmtmstruct-M68K_RAM),a2	;93: faceoff man resets team $18-$1C
	btst	#pfteam,pflags(a3)
	beq.w	.tm
	adda.w	#tmsize,a2
.tm	clr.w	$18(a2)			;IDA: loc_C58A
	move.b	pnum(a3),$19(a2)
	st	$1A(a2)
	st	$1C(a2)
	bclr	#3,tmflags(a2)		;tmflags bit 3
	move.l	#$17,d0			;afaceoffpl
.l1	bsr.w	assinsert		;IDA: loc_C5A8
.goalie1	move.w	(hmtmstruct+tmap).w,d4	;IDA: loc_C5AC
	btst	#pfteam,pflags(a3)
	beq.w	.t0
	move.w	(awtmstruct+tmap).w,d4
.t0	neg.w	d4			;IDA: loc_C5BE
	addq.w	#6,d4
	asl.w	#3,d4
	movea.l	#.apl,a1
	adda.w	d4,a1
	move.b	(a1,d1.w),d4
	asl.w	#2,d4
	movea.l	#.ptab,a1
	move.w	(a1,d4.w),d0
	move.w	2(a1,d4.w),d1
	btst	#pfgoal,pflags(a3)
	bne.w	.f0
	neg.w	d0
	neg.w	d1
.f0	tst.w	position(a3)			;IDA: loc_C5EE
	beq.w	.goalie2
	cmp.w	#2*4,d4
	bgt.w	.nodef
	move.w	(fox).w,d3
	eor.w	d0,d3
	bpl.w	.notmid
	move.w	(foy).w,d3
	asr.w	#3,d3
	sub.w	d3,d1
.notmid	move.w	(fox).w,d3		;IDA: loc_C610
	asr.w	#2,d3
	sub.w	d3,d0
.nodef	add.w	(fox).w,d0		;IDA: loc_C618
	add.w	(foy).w,d1
.goalie2	move.w	d0,(a3)			;IDA: _goalie2. Xpos
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	neg.w	d0
	neg.w	d1
	bsr.w	vtoa
	move.w	d0,facedir(a3)
	bclr	#2,pflags2(a3)		;pf2unav
	bclr	#pfalock,pflags(a3)
	move.w	#$52C,d1		;SPAglide
	bsr.w	SetSPA
.next	adda.w	#$80,a3			;IDA: _next
	dbf	d2,.l0
	bsr.w	SprSort
	movea.l	(sp)+,a3
	bsr.w	ResetAndSelectPlayers	;92 had this inline
	bsr.w	printz
	String	$FF,0,0
	moveq	#$36,d0			;8+46
	tst.w	(fox).w
	bpl.w	.fok
	move.w	#$BE,d0			;(18*8)+46
.fok	move.w	d0,(fodropx).w		;IDA: _fok
	subi.w	#$2E,d0
	asr.w	#3,d0
	move.w	d0,(printx).w
	moveq	#$5C,d0			;(3*8)+68
	move.w	d0,(fodropy).w
	subi.w	#$44,d0
	asr.w	#3,d0
	move.w	d0,(printy).w
	move.w	(ExtraChars).w,d4	;space for faceoff map
	movea.l	#FaceOffMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$C,d2
	moveq	#$A,d3
	moveq	#0,d5
	bsr.w	dobitmap
	move.w	d4,(faceoffvrcset).w	;space for faceoff sprites
	movea.l	#FaceOffSprites+8,a2	;93: replaces 92 Buildframelist/DoDMA
	bsr.w	DoDMA_clearCallbackPointer
	tst.w	(OptLine).w		;93: line names box when lines are on
	bne.w	.nol
	bsr.w	printsmallz
	String	$FA,$A,$FE,4
	moveq	#$C,d0
	moveq	#3,d1
	bsr.w	Framer
	move.w	(word_FFC4FC).w,d0	;home tmline
	move.w	(word_FFC69E).w,d1	;away tmline
	btst	#gmdir,(gmode).w
	bne.w	.nx
	exg	d0,d1
.nx	bsr.w	printsmallz		;IDA: loc_C6FA
	String	$FB,1,$FA,$FE
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
	addq.w	#4,(printx).w
	move.w	d1,d0
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
.nol	move.w	#$78,d0			;IDA: loc_C71E
	bsr.w	randomd0
	addi.w	#$B4,d0
	move.w	d0,temp1(a3)		;time for puck drop
	move.w	#$18,(palcount).w
	movea.l	#fofdata2,a0
	move.w	#1,(a0)
	move.w	#$8000,2(a0)
	move.w	#4,4(a0)
	move.w	#$A800,6(a0)
	move.w	#7,8(a0)		;frame of ref
	move.w	#$8000,$A(a0)
	btst	#gmdir,(gmode).w
	bne.w	.nfl
	eori.w	#$800,2(a0)
	eori.w	#$800,6(a0)
.nfl	move.w	#-1,(fodir1).w		;IDA: _nfl
	move.w	#-1,(fodir2).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.nna	subq.w	#1,temp1(a3)		;IDA: loc_C784. (92 sub d7)
	bpl.w	updatefaceoff
	bra.w	Endfaceoff

.apl	;IDA: _apl
	dc.b	0,1,2,3,4,5,6,0
	dc.b	0,1,5,3,4,2,0,0
	dc.b	0,3,5,1,4,0,0,0
.ptab
	dc.w	0,-250
	dc.w	-35,-50
	dc.w	35,-50
	dc.w	-50,-10
	dc.w	0,-15
	dc.w	50,-10
	dc.w	0,-60

ResetAndSelectPlayers	;93 split from 92 puckfaceoff2: c1playernum/c2playernum = -1, then changeplayer for each human team. Called from puckfaceoff2
	move.w	#-1,(c1playernum).w
	move.w	#-1,(c2playernum).w
	tst.w	(cont1team).w
	beq.w	.nt1
	clr.w	d4
	bsr.w	changeplayer
.nt1	tst.w	(cont2team).w		;IDA: loc_C7DE
	beq.w	.nt2
	moveq	#2,d4
	bsr.w	changeplayer
.nt2	rts				;IDA: locret_C7EC

updatefaceoff	;a3 = puck. Drop animation frame from temp1; at 0 erases the faceoff box (92 did that in Endfaceoff). Entered from puckfaceoff2
	move.w	temp1(a3),d0
	beq.w	.erase
	addq.w	#6,d0
	lsr.w	#3,d0
	cmp.w	#2,d0
	bgt.w	rtss
	neg.w	d0
	addi.w	#$A,d0
	move.w	d0,(fofdata).w		;92 fofdata+8
	rts
.erase	bclr	#4,(disflags).w		;IDA: loc_C80E
	bsr.w	printz
	String	$BF,0,0
	move.w	(fodropx).w,d0
	subi.w	#$2E,d0
	asr.w	#3,d0
	move.w	d0,(printx).w
	moveq	#$64,d0			;(4*8)+68, overwritten (as in 92)
	move.w	(fodropy).w,d0
	subi.w	#$44,d0
	asr.w	#3,d0
	move.w	d0,(printy).w
	moveq	#$C,d0
	moveq	#$D,d1			;(92 10)
	move.w	#$7FF,d2		;(92 moveq #1,d2)
	bra.w	eraser

Endfaceoff	;drop the puck: pick the faceoff winner and send the puck off. Entered from puckfaceoff2
	move.w	#$2F,-(sp)		;SFXpuckice
	bsr.w	sfx
	bclr	#sf2faceoff,(sflags2).w
	move.w	(ExtraChars).w,d4
	movea.l	#RefsMap+8,a2
	bsr.w	DoDMA_clearCallbackPointer	;ref cam chars (92 DoDMAPro)
	bclr	#sf2drec,(sflags2).w
	bclr	#gmclock,(gmode).w
	bclr	#pf2fight,pflags2(a3)
	bset	#4,(sflags3).w		;93
	move.w	(fodir1).w,d3		;figure out who won face off
	move.w	#$800,d4
	movea.l	#.ftab,a0
	movea.w	#(fofdata2-M68K_RAM),a1
	moveq	#$10,d2
	move.w	(a1),d1
	sub.b	-1(a0,d1.w),d2
	move.w	4(a1),d1
	add.b	-1(a0,d1.w),d2
	moveq	#$21,d0
	bsr.w	randomd0
	cmp.b	d0,d2
	bls.w	.p1won
	addq.w	#4,a1
.p1won	btst	#3,2(a1)		;IDA: loc_C8AC
	beq.w	.pos
	move.w	(fodir2).w,d3
	neg.w	d4
.pos	move.w	d3,d0			;IDA: loc_C8BC
	btst	#3,d0
	bne.w	.nojoy
	andi.w	#7,d0
	move.w	(VDP_CNTR).l,d1		;hvcount
	andi.w	#3,d1
	bne.w	.nj2
.nojoy	moveq	#5,d0			;IDA: loc_C8D8
	bsr.w	randomd0
	subq.w	#2,d0
	andi.w	#7,d0
	tst.w	d4
	bmi.w	.nj2
	eori.w	#4,d0
.nj2	asl.w	#2,d0			;IDA: loc_C8EE
	movea.l	#dirtab,a0
	move.w	(a0,d0.w),d1
	asl.w	#5,d1
	move.w	d1,Xvel(a3)
	move.w	2(a0,d0.w),d1
	asl.w	#5,d1
	add.w	d4,d1
	move.w	d1,Yvel(a3)
	move.w	#$800,d0
	bsr.w	randomd0
	move.w	d0,Zvel(a3)
	clr.w	(puckz).w
	bclr	#pfnc,pflags(a3)
	move.l	#$18,d0			;pnorm
	bra.w	assreplace

.ftab	dc.b	0,8,16,0,8,16

pucknorm	;assignment for puck most of the time. a3 = puck, d7 = elapse frames since last call
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#$78,temp2(a3)		;93: temp2 = still puck timer
.nna	movea.w	#(puckcross-M68K_RAM),a1	;IDA: loc_C946. table for puck crossing lines
	sub.w	d7,2(a1)		;sub elapse frames from time til crossing
	sub.w	d7,6(a1)
	sub.w	d7,temp1(a3)
	bpl.w	.0
	addq.w	#5,temp1(a3)
	bsr.w	findpc
.0	move.w	(puckc).w,d0		;IDA: loc_C962
	bmi.w	.nothandled
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a2
	adda.w	d0,a2
	bsr.w	a2touchpuck
	move.l	a2,-(sp)
	bsr.w	GetHot
	add.w	(a2),d0			;bunjy the puck towards the hot spot on player a2
	sub.w	(a3),d0
	asr.w	#2,d0
	add.w	d0,(a3)
	add.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	asr.w	#2,d1
	add.w	d1,Ypos(a3)
	move.w	Xvel(a2),Xvel(a3)
	move.w	Yvel(a2),Yvel(a3)
.nothandled	bsr.w	puckIChk	;IDA: loc_C99E
	bsr.w	ChkOffsides
	btst	#0,(gmode).w		;93: loose puck that has not moved
	bne.w	.z			;(Xpos = $1C, Ypos = $20) for 120 calls
	tst.w	(puckc).w		;calls AddPenalty2 with d0 = 6
	bpl.w	.mv
	move.w	(a3),d0
	cmp.w	OldXpos(a3),d0
	bne.w	.mv
	move.w	Ypos(a3),d0
	cmp.w	OldYpos(a3),d0
	bne.w	.mv
	move.l	#6,d0
	subq.w	#1,temp2(a3)
	bpl.w	.np
	bsr.w	AddPenalty2
.np	bra.w	.z			;IDA: loc_C9E0
.mv	move.w	#$78,temp2(a3)		;IDA: loc_C9E4. reset still puck timer
.z	tst.b	Zvel(a3)			;IDA: loc_C9EA
	bne.w	checkpuckcoll
	tst.w	Zpos(a3)
	bne.w	checkpuckcoll
	bsr.w	puckunflip
	bra.w	checkpuckcoll
