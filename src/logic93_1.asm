;	NHLPA Hockey 93 (retail) segment $946E-$A0FB
;	92 Logic.Asm part 1: controller input for skaters (doinput ... setpads)
;	and check4bench. Global names from the IDA export, 92 names where the
;	routine is the same (see the SEGMENT_AGENT.md rename table).
;	Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	93 SortCords offsets, 92 names in comments: Xpos 0, attribute 4, Ypos $14,
;	Xvel $28, Yvel $2A, impact $32, position $34, assnum $36, asslist $38,
;	SCnum $52, facedir $54, SPA $58, SPAnum $5A, nopuck $5E, pflags $62
;	(pfdoff 0, pfna 1, pfjoycon 3, pfalock 5, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2fight 0, pf2aip 1, pf2unav 2, pf2lcm 3). Team struct: tmline $16,
;	tmap $24. Buttons: abut 6, bbut 4, cbut 5, sbut 7.

doinput	;process controller input
	;d0 = dpad
	;d1 = new buttons
	;d2 = changed buttons
	;d3 = held buttons
	;d4 = controller 0/2
	bsr.w	setpads			;set cordinates for stars
	btst	#7,d1			;start button
	beq.w	.0
	tst.w	d4
	beq.w	startpause1
	bra.w	startpause2
.0	btst	#7,(sflags).w		;IDA: loc_949C. sfhor: is screen in horizontal mode
	beq.w	.nhor
	btst	#3,d0
	bne.w	.nhor
	addq.w	#2,d0			;add 90 degrees if in horizontal mode
	andi.w	#7,d0
.nhor	btst	#0,(sflags2).w		;IDA: _nhor. sf2faceoff
	bne.w	faceoffinput
	btst	#3,$63(a3)		;pf2lcm
	bne.w	lineinput		;line change interface on
	btst	#3,$62(a3)		;pfjoycon
	beq.w	rtss			;no joystick cont so exit
	btst	#5,$62(a3)		;pfalock
	bne.w	.islocked
	btst	#0,$63(a3)		;pf2fight
	bne.w	fightinput		;fighting in progress
	move.w	(puckc).w,d5
	cmp.w	$52(a3),d5
	beq.w	.ispc			;player is puck carrier
	btst	#6,d1			;abut
	bne.w	holdplayer		;hold button
	btst	#4,d1			;bbut, is not puck c
	bne.w	changeplayer		;switch players
	tst.w	$34(a3)			;position
	beq.w	rtss			;goalie can't check
	btst	#5,d1			;cbut
	bne.w	burst			;burst/check
	bra.w	doplayeracc		;no button, just dpad input
.ispc	bsr.w	checkob			;IDA: loc_9516. Player is puck handler
	tst.w	$34(a3)
	bne.w	.pc1
	btst	#1,$63(a3)		;goalie: pf2aip
	bne.w	rtss
.pc1	btst	#2,(sflags).w		;IDA: loc_952C. sfspdir
	bne.w	passmode
	btst	#3,(sflags).w		;sfssdir
	bne.w	ShotMode
	btst	#4,d1			;bbut
	bne.w	setpassmode
	btst	#6,d1			;abut
	bne.w	SetLCmode
	tst.w	$34(a3)
	beq.w	rtss			;exit if goalie
	btst	#5,d1			;cbut
	bne.w	SetShotMode
	bra.w	doplayeracc
.islocked	move.w	(puckc).w,d5		;IDA: loc_9564. Animation is locked /don't interupt it/
	cmp.w	$52(a3),d5
	beq.w	rtss
	btst	#4,d1			;bbut, is not puck handler
	bne.w	changeplayer
	rts

faceoffinput	;controller processing for faceoff
	move.w	$36(a3),d4		;assnum
	cmpi.b	#$17,$38(a3,d4.w)	;afaceoffpl
	bne.w	rtss			;exit if this is not a faceoff player
	movea.w	#(fodir1-M68K_RAM),a0	;faceoff direction of puck controll variable
	btst	#7,$62(a3)		;pfgoal
	beq.w	.2
	movea.w	#(fodir2-M68K_RAM),a0
.2	move.w	d0,(a0)			;IDA: loc_959A. Store dpad for faceoff pull
	btst	#1,$63(a3)		;pf2aip
	bne.w	rtss
	btst	#4,d1			;bbut
	beq.w	.1
	move.w	#$11A4,d1		;SPAfaceoff
	bset	#1,$63(a3)
	bra.w	SetSPA
.1	move.w	#$11CE,d1		;IDA: loc_95BC. SPAfaceoffr
	bra.w	SetSPA

fightinput	;controller processing for fighting
	tst.w	$44(a3)			;temp3
	bmi.w	rtss			;exit if fight is over
	tst.w	(Pencntdwn).w
	bmi.w	rtss			;exit if fight is over
	cmpi.w	#$F8E,$58(a3)		;SPAfight
	beq.w	rtss			;exit if this player is not in ready position
	move.w	d0,d2			;dpad input
	move.w	d1,-(sp)		;new button presses
	btst	#3,d2
	bne.w	.noa
	andi.w	#7,d2
	bsr.w	playeracc		;move player
.noa	move.w	(xc1).w,d0		;IDA: _noa. Keep the players face to face and in range of xc1
	addi.w	#$C,d0
	cmpi.w	#2,$54(a3)		;facedir
	bne.w	.0
	subi.w	#$18,d0			;xc1 - 12
.0	sub.w	(a3),d0			;IDA: _0
	move.w	$28(a3),d1		;Xvel
	eor.w	d0,d1
	bpl.w	.ind
	tst.w	d0
	bpl.w	.1
	neg.w	d0
.1	muls.w	$28(a3),d0		;IDA: _1
	asr.l	#4,d0
	sub.w	d0,$28(a3)
.ind	move.w	(sp)+,d1		;IDA: _ind
	bset	#1,$63(a3)		;pf2aip
	bne.w	rtss
	move.w	d1,d2
	move.w	#$1004,d1		;SPAfhigh
	btst	#5,d2			;cbut
	bne.w	SetSPA			;start hit high anim
	move.w	#$1036,d1		;SPAflow
	btst	#4,d2			;bbut
	bne.w	SetSPA			;start hit low anim
	move.w	#$FC0,d1		;SPAfgrab
	btst	#6,d2			;abut
	bne.w	SetSPA			;start grab anim
	bclr	#1,$63(a3)		;clear anim in prog if none
	rts

SetLCmode	;IDA: loc_9660. Initiate line change option if available (abut
	;pressed by the puck carrier)
	tst.w	(OptLine).w
	bne.w	rtss			;exit if line changes off
	bsr.w	loadTeamStruct
	bset	#1,$30(a2)		;team already in lc mode?
	bne.w	rtss
	bclr	#2,(sflags).w		;terminate passing by this player
	bclr	#3,(sflags).w		;same with shooting
	bset	#3,$63(a3)		;pf2lcm: this player in lc mode
SetLCmode2	;IDA: showfaceoff. a2 = team struct for lc. Draw the lc box with
	;one row per eligible line (A/B/C + line name). Also called from lineinput
	bsr.w	setlccords		;set screen cords for this teams lc box
	cmpi.w	#$F,(printy).w
	blt.w	.box
	bset	#0,(sflags3).w		;sf3llcs: flag for lower (on screen) line change
	bra.w	.frame
.box	jsr	(box).l			;IDA: loc_96A0
	bsr.w	setlccords
.frame	bsr.w	Framer			;IDA: loc_96AA. Frame lc box
	subq.w	#2,(printy).w
	addq.w	#1,(printx).w
	moveq	#2,d4			;loop 3 times
.loop	move.w	d4,d0			;IDA: loc_96B8
	bsr.w	getlchoice
	tst.w	d0
	bmi.w	.next			;no line for this button
	btst	#1,$30(a2)
	bne.w	.pr
	cmp.w	$2E(a2),d4		;box being closed: only the chosen row
	bne.w	.up
	move.w	$16(a2),d0		;tmline
.pr	movea.w	#(mesarea-M68K_RAM),a1	;IDA: loc_96DA
	move.l	#$44120,(a1)		;String 'A '
	add.b	d4,2(a1)		;'A'-'C'
	bsr.w	print
	move.w	d0,-(sp)
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
	move.w	(sp)+,d0
	bsr.w	linebar
	subq.w	#5,(printx).w
.up	subq.w	#1,(printy).w		;IDA: loc_9702
.next	dbf	d4,.loop		;IDA: loc_9706
	movea.l	$1E(a2),a1		;team name
	adda.w	4(a1),a1
	adda.w	(a1),a1
	addq.w	#2,(printx).w
	bra.w	print

setlccords	;set printx/y to cords for lc box on team a2
	;set d0/d1 for framer box size
	clr.w	d0
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	bne.w	.0
	eori.w	#$16,d0
.0	btst	#1,(gmode).w		;IDA: loc_972A. gmdir
	beq.w	.noflip
	eori.w	#$16,d0
.noflip	bsr.w	printz			;IDA: loc_9738
	String	$BF,$16,0
	add.w	d0,(printy).w
	moveq	#2,d0
	bsr.w	getlchoice
	moveq	#6,d1			;3 rows
	tst.w	d0
	bpl.w	.ex
	subq.w	#1,d1			;no third choice: 2 rows
	addq.w	#1,(printy).w
.ex	moveq	#9,d0			;IDA: loc_975A
	rts

getlchoice	;d0 = 0-2 (a2 = team)
	;return d0 = possible line number or -1 for none in this position
	movem.l	d1-d2,-(sp)
	move.w	$1C6(a2),d2		;other team's tmap
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	beq.w	.0
	move.w	-$17E(a2),d2
.0	sub.w	$24(a2),d2		;IDA: loc_9772. d2= number I'm short
	beq.w	.1
	addi.w	#$15,d0			;3*7
	tst.w	d2
	bmi.w	.1
	addi.w	#$15,d0
.1	move.w	$16(a2),d1		;IDA: loc_9788. tmline
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
	lea	.tab(pc),a0
	move.b	(a0,d0.w),d0
	ext.w	d0
	movem.l	(sp)+,d1-d2
	rts
.tab	;IDA: unk_97A2
;offset = 0 no power play
	dc.b	0,1,2			;line 0
	dc.b	1,2,0			;line 1
	dc.b	2,0,1			;line 2
	dc.b	0,1,2			;line 3
	dc.b	0,1,2			;line 4
	dc.b	0,1,2			;line 5
	dc.b	0,1,2			;line 6
;offset = 3/4 penalty killing
	dc.b	3,4,-1			;line 0
	dc.b	3,4,-1			;line 1
	dc.b	3,4,-1			;line 2
	dc.b	3,4,-1			;line 3
	dc.b	4,3,-1			;line 4
	dc.b	3,4,-1			;line 5
	dc.b	3,4,-1			;line 6
;offset = 5/6 power play
	dc.b	5,6,-1			;line 0
	dc.b	5,6,-1			;line 1
	dc.b	5,6,-1			;line 2
	dc.b	5,6,-1			;line 3
	dc.b	5,6,-1			;line 4
	dc.b	5,6,-1			;line 5
	dc.b	6,5,-1			;line 6
	dc.b	0			;pad (92 retail $01)

lineinput	;process input for line changes
	;d1 = new button presses
	move.w	d1,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#6,$62(a3)		;pfteam
	beq.w	.0
	adda.w	#$1A2,a2		;tmsize
.0	bclr	#0,$30(a2)		;IDA: loc_97F6. Flag to start lc mode
	beq.w	.1
	bsr.w	lcfound2		;close the old box
	bsr.w	SetLCmode2		;start lc mode
.1	move.w	(sp)+,d1		;IDA: loc_9808. New presses
	clr.w	d2			;choice made index
	btst	#6,d1			;abut
	bne.w	lcfound
	addq.w	#1,d2
	btst	#4,d1			;bbut
	bne.w	lcfound
	addq.w	#1,d2
	btst	#5,d1			;cbut
	bne.w	lcfound
	btst	#3,$62(a3)		;pfjoycon
	beq.w	.x
	btst	#5,$62(a3)		;pfalock
	bne.w	.x
	btst	#0,$63(a3)		;pf2fight
	beq.w	doplayeracc		;skate with dpad if not fighting
.x	rts				;IDA: locret_9846

lcfound	;d2 = choice made 0-2
	move.w	d2,d0
	move.w	d2,$2E(a2)
	bsr.w	getlchoice		;translate choice 0-2 into line number 0-6
	tst.w	d0
	bmi.w	rtss			;not an eligible choice
	bclr	#3,$63(a3)		;pf2lcm
	bset	#3,$62(a3)		;pfjoycon
	bsr.w	loadTeamStruct
	bclr	#1,$30(a2)
	move.w	d0,$16(a2)		;tmline
	jsr	(setpersonel).l
lcfound2	;close lc box. Also called from lineinput
	bsr.w	setlccords
	cmpi.w	#$F,(printy).w
	blt.w	.nollcm
	bclr	#0,(sflags3).w		;sf3llcs
.nollcm	addq.w	#1,d1			;IDA: loc_988C
	move.w	#$7FF,d2
	bsr.w	eraser
	bra.w	printscores1

burst	;cbut press check/speed. Also entered from check4check
	bsr.w	getpde			;get players energy
	tst.w	(OptLine).w
	bne.w	.0
	subi.w	#$CC,d0			;$1000/20
	bsr.w	setpde			;decrease players energy
.0	lsr.w	#7,d0			;IDA: loc_98AE
	move.w	d0,d1			;energy = speed increase (check violence)
	move.w	$54(a3),d2		;facedir
	asl.w	#2,d2
	movea.l	#dirtab,a0
	muls.w	(a0,d2.w),d0
	muls.w	2(a0,d2.w),d1
	add.w	d0,$28(a3)
	add.w	d1,$2A(a3)
	bset	#5,$62(a3)		;pfalock: lock in this animation
	move.w	#$C7E,d1		;SPAburst
	bra.w	SetSPA

holdplayer	;abut press hold (92 Holdplayer). a0 = the player this one is
	;assigned to, falls into Acheck
	bset	#5,$62(a3)
	move.w	#$12DC,d1		;SPAHold
	tst.w	$32(a3)
	beq.w	SetSPA
	movea.w	#(SortCords-M68K_RAM),a0
	move.w	$2E(a3),d0
	asl.w	#7,d0
	adda.w	d0,a0
Acheck	;start hold (or hook if a0 is ahead, $CB0) on player a0. Also entered
	;from check4check
	bset	#5,$62(a3)		;pfalock
	move.w	#$12DC,d1		;SPAHold
	tst.w	$32(a3)
	beq.w	.set
	move.w	$14(a3),d0
	sub.w	$14(a0),d0
	btst	#7,$62(a3)		;pfgoal
	beq.w	.0
	neg.w	d0
.0	bmi.w	.set			;IDA: loc_9920
	move.w	#$CB0,d1
.set	bra.w	SetSPA			;IDA: loc_9928

setpassmode	;initialize pass mode
	move.w	$54(a3),(passdir).w	;default pass dir.
	andi.w	#7,(passdir).w
	bset	#2,(sflags).w		;sfspdir
	rts

passmode	;dpad sets passdir until bbut changes
	btst	#4,d2			;has bbut changed?
	bne.w	dopass			;yes
	btst	#3,d0			;look for dpad
	bne.w	rtss
	andi.w	#7,d0
	move.w	d0,(passdir).w		;new pass dir
	bset	#3,d0
dopass	;pass the puck in passdir, to the best teammate there if any.
	;Also called from chk4pass
	movem.l	d0-d5/a0-a1,-(sp)
	bclr	#2,(sflags).w		;sfspdir
	st	(puckc).w		;player is not puck handler anymore
	move.b	#$10,$5E(a3)		;nopuck
	move.w	$52(a3),(lastplayer).w
	moveq	#8,d0
	tst.w	$34(a3)
	beq.w	.pa			;goalie
	move.b	$6E(a3),d0		;passacc
.pa	asl.w	#2,d0			;IDA: loc_9984
	addi.w	#$A0,d0			;160
	move.w	d0,(passspeed).w
	moveq	#-1,d4			;look for closest and best player to pass to
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,$52(a3)
	blt.w	.0
	adda.w	#$300,a1		;6*SCstruct
.0	cmpa.l	a1,a3			;IDA: loc_99A4
	beq.w	.next			;don't pass to yourself
	tst.w	$34(a1)
	beq.w	.next			;don't pass to goalie
	btst	#2,$63(a1)		;pf2unav
	bne.w	.next			;player is unavailable
	move.w	(a1),d0
	sub.w	(puckx).w,d0
	move.w	$14(a1),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa
	movem.w	(sp)+,d1-d2
	sub.w	(passdir).w,d0
	andi.w	#7,d0
	asl.b	#5,d0
	ext.w	d0
	asl.w	#3,d0
	muls.w	d0,d0
	cmp.l	#256*256,d0
	bhi.w	.next
	muls.w	d1,d1
	muls.w	d2,d2
	add.l	d1,d2
	add.l	d0,d2
	cmp.l	d4,d2
	bhi.w	.next
	move.l	d2,d4
	movea.l	a1,a0
.next	adda.w	#$80,a1			;IDA: loc_9A02
	dbf	d3,.0
	tst.l	d4
	bmi.w	.nopp			;skip if no player to pass to
	bsr.w	passtoa0
	bra.w	.exit
.nopp	move.w	(passdir).w,d0		;IDA: loc_9A18. Just hit puck in pass direction not to any player
	asl.w	#2,d0
	movea.l	#dirtab,a0
	move.w	2(a0,d0.w),d1		;y INC
	muls.w	(passspeed).w,d1
	moveq	#$A,d2
	asl.l	d2,d1
	divs.w	#$BB8,d1		;runspeed*15
	add.w	$2A(a3),d1
	move.w	d1,(puckvy).w
	move.w	(a0,d0.w),d1		;x inc
	muls.w	(passspeed).w,d1
	asl.l	d2,d1
	divs.w	#$BB8,d1
	add.w	$28(a3),d1
	move.w	d1,(puckvx).w
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,(puckvz).w
.exit	tst.w	$34(a3)			;IDA: loc_9A5E. Start animation for player passing
	bne.w	.notgoalie
	tst.w	(puckvy).w
	btst	#7,$62(a3)		;pfgoal
	beq.w	.g0
	bmi.w	.nvy
	bra.w	.notgoalie
.g0	bmi.w	.notgoalie		;IDA: loc_9A7C
.nvy	neg.w	(puckvy).w		;IDA: loc_9A80
.notgoalie	move.w	(puckvx).w,d0		;IDA: loc_9A84
	move.w	(puckvy).w,d1
	bsr.w	vtoa
	move.w	#$386,d1		;SPAgswing
	tst.w	$34(a3)
	beq.w	.e1			;goalie anim
	move.w	#$738,d1		;SPApassf
	bsr.w	Findhittype
	beq.w	.e1
	move.w	#$7AA,d1		;SPApassb
.e1	bsr.w	SetSPA			;IDA: loc_9AAC
	bset	#5,$62(a3)		;pfalock
	moveq	#$C,d0			;pass sound $10+ by puck height (92 SFXpass first)
	sub.b	(puckvz).w,d0
	lsr.w	#2,d0
	addi.w	#$10,d0
	move.w	d0,-(sp)
	bsr.w	sfx
	movem.l	(sp)+,d0-d5/a0-a1
	rts

passtoa0	;pass puck to player a0
	bsr.w	loadTeamStruct
	addq.w	#1,$12(a2)		;count passes
	move.w	$52(a0),(passReceiverPlayerNum).w
	move.w	(passspeed).w,d5	;in pix/sec
	asr.w	#2,d5
	exg	a0,a3			;tell pass rec to get puck
	move.l	#$13,d0			;apassrec
	bsr.w	assinsert
	exg	a0,a3
	move.l	a0,-(sp)		;this routine uses passspeed
	bsr.w	GetHot			;and player's a0 x/y speed to determine
	add.w	(a0),d0			;the x/y velocity of the puck so it will
	sub.w	(puckx).w,d0		;meet player a0
	add.w	$14(a0),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	movem.w	(sp),d2-d3
	asr.w	#2,d2
	asr.w	#2,d3
	move.w	$28(a0),d0
	muls.w	#$F0,d0			;x pix/(1/4)sec
	swap	d0
	move.w	$2A(a0),d1
	muls.w	#$F0,d1
	swap	d1
	movem.w	d0-d1,-(sp)
	muls.w	d2,d0
	muls.w	d3,d1
	add.w	d1,d0
	asl.w	#1,d0
	move.w	d0,d4			;j
	movem.w	(sp),d0-d1
	muls.w	d0,d0
	muls.w	d1,d1
	muls.w	d5,d5
	neg.l	d5
	add.l	d0,d5
	add.l	d1,d5			;k
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d2,d3			;a^2
	muls.w	d5,d3
	asl.l	#2,d3
	move.w	d4,d0
	muls.w	d0,d0
	sub.l	d3,d0
	bsr.w	sroot
	moveq	#1,d3			;limit inf. loop
	asr.w	#2,d5
	bne.w	.0
	moveq	#1,d5			;no div by zero
.0	move.w	d0,d2			;IDA: CalcPassTime
	neg.w	d0
	sub.w	d4,d2
	ext.l	d2
	divs.w	d5,d2
	dbpl	d3,.0
	bne.w	.1
	addq.w	#1,d2			;can't be zero
.1	cmp.w	#24,d2		;IDA: ClampPassTime. limit to 3 sec.
	bls.w	.2
	moveq	#$18,d2
.2	move.b	d2,(puckvz).w		;IDA: ClampPassTime2. d2 = time in 1/8 sec to intersection
	cmp.w	#12,d2
	blt.w	.3
	move.b	#$C,(puckvz).w
.3	move.w	d2,d0			;IDA: CalcPuckVelocities
	asl.w	#3,d0
	subi.w	#$A,d0			;92: 6
	move.b	d0,$40(a0)		;temp2
	subq.w	#6,d0			;92: 10
	move.b	d0,(byte_FFB7A8).w	;puckx+nopuck
	movem.w	(sp)+,d0-d1
	muls.w	d2,d0
	asr.l	#1,d0
	add.w	(sp)+,d0		;x distance
	move.w	(puckx).w,$44(a0)	;93: receiver target x/y in temp3/temp4
	add.w	d0,$44(a0)
	muls.w	d2,d1
	asr.l	#1,d1
	add.w	(sp)+,d1		;y distance
	move.w	(pucky).w,$46(a0)
	add.w	d1,$46(a0)
	mulu.w	#$78,d2			;60*2
	swap	d0
	divs.w	d2,d0
	move.w	d0,(puckvx).w
	swap	d1
	divs.w	d2,d1
	move.w	d1,(puckvy).w
	rts

changeplayer	;switch controller d4 (0/2) to the teammate nearest the puck,
	;or sweep check if that is the current player
	movem.l	d0-d6/a0-a1,-(sp)
	move.w	(puckvx).w,d0		;lead puck slightly
	asr.w	#8,d0
	add.w	(puckx).w,d0
	move.w	(puckvy).w,d1
	asr.w	#8,d1
	add.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	moveq	#5,d2
	move.w	d4,d3
	eori.w	#2,d3			;other controller
	moveq	#-1,d5
	movea.w	#(SortCords-M68K_RAM),a0	;start of search
	movea.w	#(cont1team-M68K_RAM),a1
	cmpi.w	#1,(a1,d4.w)
	beq.w	.t1
	adda.w	#$300,a0		;controller is on other team
.t1	movea.w	#(c1playernum-M68K_RAM),a1	;IDA: t1_CheckPlayers
.top	tst.w	$34(a0)			;IDA: top_CheckPlayerLoop
	ble.w	.next			;can't switch to goalie
	btst	#2,$63(a0)		;pf2unav
	bne.w	.next			;this player is unavailable for some reason
	btst	#5,$62(a0)		;pfalock
	bne.w	.next			;this player is locked
	movem.w	(sp),d0-d1
	sub.w	(a0),d0
	muls.w	d0,d0
	sub.w	$14(a0),d1
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	d5,d0
	bhi.w	.next
	move.w	$52(a0),d1
	cmp.w	(a1,d3.w),d1
	beq.w	.next			;this is current player
	move.l	d0,d5
	move.w	d1,d6
.next	adda.w	#$80,a0			;IDA: next_SkipPlayer
	dbf	d2,.top
	addq.w	#4,sp
	pea	(.ex).l
	cmp.w	(a1,d4.w),d6
	beq.w	Sweepcheck		;player is same so sweep check
	move.w	d6,d0
	tst.w	d4
	beq.w	setc1player
	bra.w	setc2player
.ex	movem.l	(sp)+,d0-d6/a0-a1	;IDA: ex_CheckSweep
	rts

Sweepcheck	;start sweep check on player a3
	bset	#5,$62(a3)		;pfalock
	move.w	#$B44,d1		;SPAsweepchk
	bra.w	SetSPA

setc1player	;restore old player and switch to new d0 player on cont. 1
	cmp.w	(c1playernum).w,d0
	beq.w	rtss
	movem.l	d1/a0-a1,-(sp)
	move.w	(c1playernum).w,d1
	bsr.w	restorepl
	move.w	d0,(c1playernum).w
	movem.l	(sp)+,d1/a0-a1
	rts

setc2player	;restore old player and switch to new d0 player on cont. 2
	cmp.w	(c2playernum).w,d0
	beq.w	rtss
	movem.l	d1/a0-a1,-(sp)
	move.w	(c2playernum).w,d1
	bsr.w	restorepl
	move.w	d0,(c2playernum).w
	movem.l	(sp)+,d1/a0-a1
	rts

restorepl	;IDA: retorepl. Restore old joy controlled player d1, give d0
	;the joystick. 93: if d1 is in line change mode it keeps control (d0 = d1)
	movea.w	#(SortCords-M68K_RAM),a0
	tst.w	d1
	blt.w	.spd
	cmp.w	#11,d1
	bgt.w	.spd
	asl.w	#7,d1			;scsize
	btst	#3,$63(a0,d1.w)		;pf2lcm
	beq.w	.rel
	lsr.w	#7,d1
	move.w	d1,d0
	rts
.rel	bclr	#3,$62(a0,d1.w)		;IDA: ReleaseOldPlayer. pfjoycon
	bset	#1,$62(a0,d1.w)		;pfna
.spd	tst.w	d0			;IDA: spd_SetNewPlayer
	blt.w	rtss
	cmp.w	#11,d0
	bgt.w	rtss
	move.w	d0,d1
	asl.w	#7,d1
	bset	#3,$62(a0,d1.w)		;pfjoycon
	rts

Findhittype	;look for type of swing (forhand or backhand)
	;input d0 = launch dir
	;ouput	beq	forhand
	;	bne	backhand
	neg.w	d0
	add.w	$54(a3),d0		;facedir
	andi.w	#7,d0
	btst	#3,4(a3)		;attribute x flip
	beq.w	.1
	btst	d0,#$F0			;%11110000
	rts
.1	btst	d0,#$1E			;IDA: _1. %00011110
	rts

SetShotMode	;initiate shot by player a3
	move.w	#8,(passdir).w		;default shot direction
	bset	#3,(sflags).w		;sfssdir
	clr.w	d0			;find dx/dy for shot
	move.w	#$128,d1		;296
	btst	#7,$62(a3)		;pfgoal
	bne.w	.ck0
	neg.w	d1
.ck0	sub.w	(a3),d0			;IDA: _ck0_CalcShotToGoal
	sub.w	$14(a3),d1
	bsr.w	vtoa
	move.w	#$F,(passspeed).w
	move.w	#$81C,d1		;SPAshotf
	bsr.s	Findhittype
	beq.w	.ck1
	move.w	#$94E,d1		;SPAshotb
	move.w	#$F,(passspeed).w	;minimum shot speed
.ck1	bra.w	SetSPA			;IDA: _ck1_SetShotAnim

ShotMode	;shot input
	cmpi.w	#$1C,$5A(a3)		;7*4
	bge.w	doshot			;end of animation so shoot
	btst	#3,d0
	bne.w	.ss0
	andi.w	#7,d0
	move.w	d0,(passdir).w		;set shot direction
.ss0	cmpi.w	#$10,$5A(a3)		;IDA: ShotMode_ss0. 4*4
	bge.w	rtss			;past full windup so no more passspeed
	add.w	d7,(passspeed).w
	cmpi.b	#$A,$6C(a3)		;93: shotspd >= 10 must release the button
	bge.w	.cb
	cmpi.w	#8,$5A(a3)
	bgt.w	.rev			;slow shooter: swing after 2 frames of windup
.cb	btst	#5,d2			;IDA: CheckCButton. cbut
	beq.w	rtss			;button hasn't changed so continue windup
.rev	neg.w	$5A(a3)			;IDA: ReverseShot. End wind and swing thru
	addi.w	#$1C,$5A(a3)
	rts

doshot	;stick is at puck so launch puck toward goal
	movem.l	d0-d7/a0-a3,-(sp)
	bsr.w	checkgoalp_CalcGoalShotDir	;93: aim away from the goalie
	move.w	#5,-(sp)		;sound effect (92 SFXshotwiff = 14)
	move.w	$52(a3),(shotplayer).w
	bclr	#3,(sflags).w		;sfssdir
	bset	#5,$62(a3)		;pfalock
	move.w	(puckc).w,d0
	cmp.w	$52(a3),d0
	bne.w	.ex			;wiffed shot
	move.w	#$18,(sp)		;92 SFXshotfh = 13
	bset	#4,(sflags2).w		;sf2shot
	cmpi.w	#$94E,$58(a3)		;SPAshotb
	bne.w	.nbh
	move.w	#$14,(sp)		;92 SFXshotbh = 12
	move.w	(passspeed).w,d0
	lsr.w	#2,d0			;sub 25% for backhand shots
	sub.w	d0,(passspeed).w
.nbh	move.b	$6C(a3),d0		;IDA: doshot_nbh. shotspd
	movea.l	a3,a0
	bsr.w	makepde
	addi.w	#$14,d0
	mulu.w	(passspeed).w,d0	;shot speed ranged by energy level
	mulu.w	#$5249,d0		;$4000*45/35
	swap	d0
	move.w	d0,(passspeed).w
	lsr.w	#4,d0			;93: crowd bonus 3 - speed/16
	neg.w	d0
	addq.w	#3,d0
	bpl.w	.c
	clr.w	d0
.c	add.w	d0,(sp)			;IDA: loc_9E46
	st	(puckc).w
	move.b	#$10,$5E(a3)		;nopuck
	move.w	$52(a3),(lastplayer).w
	move.w	#$108,d1		;blueline+goalline
	btst	#7,$62(a3)		;pfgoal
	bne.w	.0
	neg.w	d1
.0	move.w	(passdir).w,d2		;IDA: doshot_0
	asl.w	#2,d2
	lea	.shotsets(pc),a0	;table of shot directions
	move.w	(a0,d2.w),d0		;x offset
	move.w	2(a0,d2.w),d2		;z offset
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	movem.w	d0-d2,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	sroot
	tst.w	d0			;distance in pix to goal
	bne.w	.1
	addq.w	#1,d0
.1	move.w	d0,d3			;IDA: doshot_1
	btst	#4,(gmode).w		;gmhl
	bne.w	.perf
	cmp.w	#200,d3
	bhi.w	.notperf		;too far away for perfect shot
	moveq	#$10,d0
	add.b	$6D(a3),d0		;shotacc
	bsr.w	randomd0
	cmp.w	#14,d0		;chance of perfect shot
	bgt.w	.perf			;is perfect
.notperf	move.w	(passspeed).w,d0	;IDA: doshot_notperf
	lsr.w	#4,d0
	sub.b	$6D(a3),d0
	addi.b	#$10,d0
	mulu.w	d3,d0
	lsr.w	#6,d0			;shot accuracy adjust (92 lsr #7)
	cmp.w	#250,d3
	bhi.w	.cp
	lsr.w	#1,d0			;closer than 250: half the error
.cp	cmp.w	#$88,d0		;IDA: ClampPenalty
	blt.w	.ar
	move.w	#$88,d0
.ar	move.w	d0,-(sp)		;IDA: AddRandomError
	bsr.w	randomd0s
	add.w	d0,2(sp)		;x dist
	move.w	(sp),d0
	cmp.w	#60,d0
	bls.w	.ay
	moveq	#$3C,d0
	move.w	d0,(sp)
.ay	tst.w	4(sp)			;IDA: AddYError
	bpl.w	.am
	lsr.w	#1,d0
.am	bsr.w	randomd0s		;IDA: AddMoreRandom
	add.w	d0,4(sp)		;y dist
	move.w	(sp)+,d0
	lsr.w	#1,d0
	bsr.w	randomd0
	add.w	d0,4(sp)
.perf	move.w	(passspeed).w,d2	;IDA: doshot_perf. Shot speed
	muls.w	#$44,d2			;1024/15
	muls.w	(sp)+,d2
	divs.w	d3,d2
	move.w	d2,(puckvx).w
	move.w	(passspeed).w,d2
	muls.w	#$44,d2
	muls.w	(sp)+,d2
	divs.w	d3,d2
	move.w	d2,(puckvy).w
	move.w	(sp)+,d1		;pix height in goal
	beq.w	.ex
	mulu.w	(passspeed).w,d1
	mulu.w	#$44,d1
	divu.w	d3,d1
	mulu.w	#$B33,d3		;(1024*42)/15
	divu.w	(passspeed).w,d3
	add.w	d1,d3
	cmp.w	#$1800,d3
	bls.w	.noup
	move.w	#$1800,d3
.noup	move.w	d3,(puckvz).w		;IDA: doshot_noup
.ex	bsr.w	sfx			;IDA: doshot_ex
	movem.l	(sp)+,d0-d7/a0-a3
	rts
.shotsets	;IDA: shotsets. Offsets for different directions on the shot
	dc.w	0,$C,$10,$C,$10,6,$10,0
	dc.w	0,0,-$10,0,-$10,6,-$10,$C
	dc.w	0,6

checkgoalp_CalcGoalShotDir	;IDA name kept: 92 checkgoalp is the goal/net collision in hockey93_04. 93 only. If the opposing goalie
	;covers the middle of the net, set passdir 2 or 6 to shoot at the open
	;side, else 0. Skipped for computer players (pfjoycon clear)
	btst	#3,$62(a3)		;pfjoycon
	bne.w	rtss
	moveq	#8,d0
	moveq	#5,d1
	movea.w	#(GoalieStruct-M68K_RAM),a0
	btst	#6,$62(a3)		;pfteam
	bne.w	.g
	adda.w	#$300,a0
.g	adda.w	#$80,a0			;IDA: CheckOpponentGoalie
	tst.w	$34(a0)			;position 0 = goalie
	dbeq	d1,.g
	bne.w	.x
	move.b	$28(a0),d0		;goalie x/y + half his velocity
	ext.w	d0
	asr.w	#1,d0
	add.w	(a0),d0
	sub.w	(puckx).w,d0
	move.b	$2A(a0),d1
	ext.w	d1
	asr.w	#1,d1
	add.w	$14(a0),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	addq.l	#1,d0
	bsr.w	sroot
	move.w	d0,d2			;distance to goalie
	movem.w	(sp)+,d0-d1
	moveq	#$12,d3			;post x
	move.w	#$108,d4		;goal y
	btst	#7,$62(a3)		;pfgoal
	bne.w	.l
	neg.w	d4
.l	movem.w	d3-d4,-(sp)		;IDA: CalcLeftAngle
	bsr.w	CalcAngleOffset
	move.w	d4,d5
	movem.w	(sp)+,d3-d4
	neg.w	d3
	bsr.w	CalcAngleOffset
	add.w	d5,d4
	clr.w	d0
	cmp.w	#$2C,d4
	bgt.w	.x
	cmp.w	#-$2C,d4
	blt.w	.x
	btst	#7,$62(a3)
	beq.w	.s
	neg.w	d4
.s	moveq	#2,d0			;IDA: SetShotDirection
	tst.w	d4
	bpl.w	.x
	moveq	#6,d0
.x	move.w	d0,(passdir).w		;IDA: ReturnDefaultDir
	rts

CalcAngleOffset	;d4 = cross product of goalie vector d0/d1 and post vector
	;d3/d4 (relative to the puck), divided by d2
	sub.w	(puckx).w,d3
	sub.w	(pucky).w,d4
	muls.w	d0,d4
	muls.w	d1,d3
	sub.l	d3,d4
	divs.w	d2,d4
	rts

setpads	;copy info into pad cont so graphics knows which player/number.
	;d4 = pad index (-2 puck carrier, 0/2 controllers, 4 replay target):
	;put SCnum in that nibble of PadControlBits
	movem.l	d0-d1,-(sp)
	moveq	#2,d0
	add.w	d4,d0
	add.w	d0,d0
	move.w	#$FFF0,d1
	rol.w	d0,d1
	and.w	d1,(PadControlBits).w
	move.w	$52(a3),d1
	asl.w	d0,d1
	or.w	d1,(PadControlBits).w
	movem.l	(sp)+,d0-d1
	rts

check4bench	;check if player a3 should go to bench. Called from assbench
	;(pops its return address when it takes over)
	btst	#3,$62(a3)		;pfjoycon
	bne.w	rtss
	btst	#4,$63(a3)
	bne.w	rtss
	tst.b	$60(a3)
	bpl.w	.b
	tst.b	$61(a3)
	bmi.w	rtss
.b	move.b	$61(a3),d0		;IDA: loc_A0A8
	cmp.b	$66(a3),d0
	beq.w	.samepl			;player should just change positions
	move.w	$36(a3),d0
	cmpi.b	#$B,$38(a3,d0.w)	;already going to bench
	beq.w	rtss
	move.w	$52(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	rtss
	addq.w	#4,sp
	bset	#2,$63(a3)		;pf2unav
	clr.w	$40(a3)
	move.l	#$B,d0			;abench
	bra.w	assreplace
.samepl	addq.w	#4,sp			;IDA: loc_A0E4
	bclr	#2,$63(a3)
	bclr	#2,$62(a3)		;pfnc
	st	$61(a3)
	st	$60(a3)
	move.w	$34(a3),d0
	tst.b	$60(a3)
	bmi.w	Setplass
	move.b	$60(a3),d0
	ext.w	d0
	move.w	d0,$34(a3)
	bra.w	Setplass
