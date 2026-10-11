;======================================================================
;======================================================================
;	Controller input for skaters (doinput
;	... setpads) and check4bench.
;	Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	SortCords offsets in comments: Xpos 0, attribute 4, Ypos $14
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
.0	btst	#sfhor,(sflags).w		;is screen in horizontal mode
	beq.w	.nhor
	btst	#3,d0
	bne.w	.nhor
	addq.w	#2,d0			;add 90 degrees if in horizontal mode
	andi.w	#7,d0
.nhor	btst	#sf2faceoff,(sflags2).w
	bne.w	faceoffinput
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	bne.w	lineinput		;line change interface on
	btst	#pfjoycon,pflags(a3)
	beq.w	rtss			;no joystick cont so exit
	btst	#pfalock,pflags(a3)
	bne.w	.islocked
	btst	#pf2fight,pflags2(a3)
	bne.w	fightinput		;fighting in progress
	move.w	(puckc).w,d5
	cmp.w	SCnum(a3),d5
	beq.w	.ispc			;player is puck carrier
	btst	#6,d1			;abut
	bne.w	holdplayer		;hold button
	btst	#4,d1			;bbut, is not puck c
	bne.w	changeplayer		;switch players
	tst.w	position(a3)
	beq.w	rtss			;goalie can't check
	btst	#5,d1			;cbut
	bne.w	burst			;burst/check
	bra.w	doplayeracc		;no button, just dpad input
.ispc	bsr.w	checkob			;Player is puck handler
	tst.w	position(a3)
	bne.w	.pc1
	btst	#pf2aip,pflags2(a3)		;goalie
	bne.w	rtss
.pc1	btst	#sfspdir,(sflags).w
	bne.w	passmode
	btst	#sfssdir,(sflags).w
	bne.w	ShotMode
	btst	#4,d1			;bbut
	bne.w	setpassmode
	btst	#6,d1			;abut
	bne.w	SetLCmode
	tst.w	position(a3)
	beq.w	rtss			;exit if goalie
	btst	#5,d1			;cbut
	bne.w	SetShotMode
	bra.w	doplayeracc
.islocked	move.w	(puckc).w,d5		;Animation is locked /don't interupt it/
	cmp.w	SCnum(a3),d5
	beq.w	rtss
	btst	#4,d1			;bbut, is not puck handler
	bne.w	changeplayer
	rts

faceoffinput	;controller processing for faceoff
	move.w	assnum(a3),d4
	cmpi.b	#$17,asslist(a3,d4.w)	;afaceoffpl
	bne.w	rtss			;exit if this is not a faceoff player
	movea.w	#(fodir1-M68K_RAM),a0	;faceoff direction of puck controll variable
	btst	#pfgoal,pflags(a3)
	beq.w	.2
	movea.w	#(fodir2-M68K_RAM),a0
.2	move.w	d0,(a0)			;Store dpad for faceoff pull
	btst	#pf2aip,pflags2(a3)
	bne.w	rtss
	btst	#4,d1			;bbut
	beq.w	.1
	move.w	#$11A4,d1		;SPAfaceoff
	bset	#pf2aip,pflags2(a3)
	bra.w	SetSPA
.1	move.w	#$11CE,d1		;SPAfaceoffr
	bra.w	SetSPA

fightinput	;controller processing for fighting
	tst.w	temp3(a3)
	bmi.w	rtss			;exit if fight is over
	tst.w	(Pencntdwn).w
	bmi.w	rtss			;exit if fight is over
	cmpi.w	#$F8E,SPA(a3)		;SPAfight
	beq.w	rtss			;exit if this player is not in ready position
	move.w	d0,d2			;dpad input
	move.w	d1,-(sp)		;new button presses
	btst	#3,d2
	bne.w	.noa
	andi.w	#7,d2
	bsr.w	playeracc		;move player
.noa	move.w	(xc1).w,d0		;Keep the players face to face and in range of xc1
	addi.w	#$C,d0
	cmpi.w	#2,facedir(a3)
	bne.w	.0
	subi.w	#$18,d0			;xc1 - 12
.0	sub.w	(a3),d0
	move.w	Xvel(a3),d1
	eor.w	d0,d1
	bpl.w	.ind
	tst.w	d0
	bpl.w	.1
	neg.w	d0
.1	muls.w	Xvel(a3),d0
	asr.l	#4,d0
	sub.w	d0,Xvel(a3)
.ind	move.w	(sp)+,d1
	bset	#pf2aip,pflags2(a3)
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
	bclr	#pf2aip,pflags2(a3)		;clear anim in prog if none
	rts

SetLCmode	;Initiate line change option if available (abut
	;pressed by the puck carrier)
	tst.w	(OptLine).w
	bne.w	rtss			;exit if line changes off
	bsr.w	loadTeamStruct
	bset	#1,tmflags(a2)		;team already in lc mode?
	bne.w	rtss
	bclr	#2,(sflags).w		;terminate passing by this player
	bclr	#3,(sflags).w		;same with shooting
	bset	#pf2lcm,pflags2(a3)		;pf2lcm: this player in lc mode
SetLCmode2	;a2 = team struct for lc. Draw the lc box with
	;one row per eligible line (A/B/C + line name). Also called from lineinput
	bsr.w	setlccords		;set screen cords for this teams lc box
	cmpi.w	#$F,(printy).w
	blt.w	.box
	bset	#sf3llcs,(sflags3).w		;flag for lower (on screen) line change
	bra.w	.frame
.box	jsr	(box).l
	bsr.w	setlccords
.frame	bsr.w	Framer			;Frame lc box
	subq.w	#2,(printy).w
	addq.w	#1,(printx).w
	moveq	#2,d4			;loop 3 times
.loop	move.w	d4,d0
	bsr.w	getlchoice
	tst.w	d0
	bmi.w	.next			;no line for this button
	btst	#1,tmflags(a2)
	bne.w	.pr
	cmp.w	$2E(a2),d4		;box being closed: only the chosen row
	bne.w	.up
	move.w	tmline(a2),d0
.pr	movea.w	#(mesarea-M68K_RAM),a1
	move.l	#$44120,(a1)		;String 'A '
	add.b	d4,2(a1)		;'A'-'C'
	bsr.w	print
	move.w	d0,-(sp)
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
	move.w	(sp)+,d0
	bsr.w	linebar
	subq.w	#5,(printx).w
.up	subq.w	#1,(printy).w
.next	dbf	d4,.loop
	movea.l	tmdata(a2),a1		;team name
	adda.w	4(a1),a1
	adda.w	(a1),a1
	addq.w	#2,(printx).w
	bra.w	print

setlccords	;set printx/y to cords for lc box on team a2
	;set d0/d1 for framer box size
	clr.w	d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	bne.w	.0
	eori.w	#$16,d0
.0	btst	#gmdir,(gmode).w
	beq.w	.noflip
	eori.w	#$16,d0
.noflip	bsr.w	printz
	String	$BF,$16,0
	add.w	d0,(printy).w
	moveq	#2,d0
	bsr.w	getlchoice
	moveq	#6,d1			;3 rows
	tst.w	d0
	bpl.w	.ex
	subq.w	#1,d1			;no third choice: 2 rows
	addq.w	#1,(printy).w
.ex	moveq	#9,d0
	rts

getlchoice	;d0 = 0-2 (a2 = team)
	;return d0 = possible line number or -1 for none in this position
	movem.l	d1-d2,-(sp)
	move.w	tmsize+tmap(a2),d2	;other team's tmap
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.0
	move.w	tmap-tmsize(a2),d2
.0	sub.w	tmap(a2),d2		;d2= number I'm short
	beq.w	.1
	addi.w	#$15,d0			;3*7
	tst.w	d2
	bmi.w	.1
	addi.w	#$15,d0
.1	move.w	tmline(a2),d1
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
	lea	.tab(pc),a0
	move.b	(a0,d0.w),d0
	ext.w	d0
	movem.l	(sp)+,d1-d2
	rts
.tab
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
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)
	beq.w	.0
	adda.w	#tmsize,a2
.0	bclr	#0,tmflags(a2)		;Flag to start lc mode
	beq.w	.1
	bsr.w	lcfound2		;close the old box
	bsr.w	SetLCmode2		;start lc mode
.1	move.w	(sp)+,d1		;New presses
	clr.w	d2			;choice made index
	btst	#6,d1			;abut
	bne.w	lcfound
	addq.w	#1,d2
	btst	#4,d1			;bbut
	bne.w	lcfound
	addq.w	#1,d2
	btst	#5,d1			;cbut
	bne.w	lcfound
	btst	#pfjoycon,pflags(a3)
	beq.w	.x
	btst	#pfalock,pflags(a3)
	bne.w	.x
	btst	#pf2fight,pflags2(a3)
	beq.w	doplayeracc		;skate with dpad if not fighting
.x	rts

lcfound	;d2 = choice made 0-2
	move.w	d2,d0
	move.w	d2,$2E(a2)
	bsr.w	getlchoice		;translate choice 0-2 into line number 0-6
	tst.w	d0
	bmi.w	rtss			;not an eligible choice
	bclr	#pf2lcm,pflags2(a3)		;pf2lcm
	bset	#pfjoycon,pflags(a3)
	bsr.w	loadTeamStruct
	bclr	#1,tmflags(a2)
	move.w	d0,tmline(a2)
	jsr	setpersonel
lcfound2	;close lc box. Also called from lineinput
	bsr.w	setlccords
	cmpi.w	#$F,(printy).w
	blt.w	.nollcm
	bclr	#sf3llcs,(sflags3).w
.nollcm	addq.w	#1,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	bra.w	printscores1

burst	;cbut press check/speed. Also entered from check4check
	bsr.w	getpde			;get players energy
	tst.w	(OptLine).w
	bne.w	.0
	subi.w	#$CC,d0			;$1000/20
	bsr.w	setpde			;decrease players energy
.0	lsr.w	#7,d0
	move.w	d0,d1			;energy = speed increase (check violence)
	move.w	facedir(a3),d2
	asl.w	#2,d2
	movea.l	#dirtab,a0
	muls.w	(a0,d2.w),d0
	muls.w	2(a0,d2.w),d1
	add.w	d0,Xvel(a3)
	add.w	d1,Yvel(a3)
	bset	#pfalock,pflags(a3)		;lock in this animation
	move.w	#$C7E,d1		;SPAburst
	bra.w	SetSPA

holdplayer	;abut press hold. a0 = the player this one is
	;assigned to, falls into Acheck
	bset	#5,pflags(a3)
	move.w	#$12DC,d1		;SPAHold
	tst.w	impact(a3)
	beq.w	SetSPA
	movea.w	#(SortCords-M68K_RAM),a0
	move.w	impactp(a3),d0
	asl.w	#7,d0
	adda.w	d0,a0
Acheck	;start hold (or hook if a0 is ahead, $CB0) on player a0. Also entered
	;from check4check
	bset	#pfalock,pflags(a3)
	move.w	#$12DC,d1		;SPAHold
	tst.w	impact(a3)
	beq.w	.set
	move.w	Ypos(a3),d0
	sub.w	Ypos(a0),d0
	btst	#pfgoal,pflags(a3)
	beq.w	.0
	neg.w	d0
.0	bmi.w	.set
	move.w	#$CB0,d1
.set	bra.w	SetSPA

setpassmode	;initialize pass mode
	move.w	facedir(a3),(passdir).w	;default pass dir.
	andi.w	#7,(passdir).w
	bset	#sfspdir,(sflags).w
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
	bclr	#sfspdir,(sflags).w
	st	(puckc).w		;player is not puck handler anymore
	move.b	#$10,nopuck(a3)
	move.w	SCnum(a3),(lastplayer).w
	moveq	#8,d0
	tst.w	position(a3)
	beq.w	.pa			;goalie
	move.b	passacc(a3),d0
.pa	asl.w	#2,d0
	addi.w	#$A0,d0			;160
	move.w	d0,(passspeed).w
	moveq	#-1,d4			;look for closest and best player to pass to
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	blt.w	.0
	adda.w	#6*SCstruct,a1
.0	cmpa.l	a1,a3
	beq.w	.next			;don't pass to yourself
	tst.w	position(a1)
	beq.w	.next			;don't pass to goalie
	btst	#pf2unav,pflags2(a1)		;pf2unav
	bne.w	.next			;player is unavailable
	move.w	(a1),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
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
.next	adda.w	#SCstruct,a1
	dbf	d3,.0
	tst.l	d4
	bmi.w	.nopp			;skip if no player to pass to
	bsr.w	passtoa0
	bra.w	.exit
.nopp	move.w	(passdir).w,d0		;Just hit puck in pass direction not to any player
	asl.w	#2,d0
	movea.l	#dirtab,a0
	move.w	2(a0,d0.w),d1		;y INC
	muls.w	(passspeed).w,d1
	moveq	#$A,d2
	asl.l	d2,d1
	divs.w	#$BB8,d1		;runspeed*15
	add.w	Yvel(a3),d1
	move.w	d1,(puckvy).w
	move.w	(a0,d0.w),d1		;x inc
	muls.w	(passspeed).w,d1
	asl.l	d2,d1
	divs.w	#$BB8,d1
	add.w	Xvel(a3),d1
	move.w	d1,(puckvx).w
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,(puckvz).w
.exit	tst.w	position(a3)			;Start animation for player passing
	bne.w	.notgoalie
	tst.w	(puckvy).w
	btst	#pfgoal,pflags(a3)
	beq.w	.g0
	bmi.w	.nvy
	bra.w	.notgoalie
.g0	bmi.w	.notgoalie
.nvy	neg.w	(puckvy).w
.notgoalie	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	bsr.w	vtoa
	move.w	#$386,d1		;SPAgswing
	tst.w	position(a3)
	beq.w	.e1			;goalie anim
	move.w	#$738,d1		;SPApassf
	bsr.w	Findhittype
	beq.w	.e1
	move.w	#$7AA,d1		;SPApassb
.e1	bsr.w	SetSPA
	bset	#pfalock,pflags(a3)
	moveq	#$C,d0			;pass sound $10+ by puck height
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
	move.w	SCnum(a0),(passReceiverPlayerNum).w
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
	add.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	movem.w	(sp),d2-d3
	asr.w	#2,d2
	asr.w	#2,d3
	move.w	Xvel(a0),d0
	muls.w	#$F0,d0			;x pix/(1/4)sec
	swap	d0
	move.w	Yvel(a0),d1
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
.0	move.w	d0,d2
	neg.w	d0
	sub.w	d4,d2
	ext.l	d2
	divs.w	d5,d2
	dbpl	d3,.0
	bne.w	.1
	addq.w	#1,d2			;can't be zero
.1	cmp.w	#24,d2		;limit to 3 sec.
	bls.w	.2
	moveq	#$18,d2
.2	move.b	d2,(puckvz).w		;d2 = time in 1/8 sec to intersection
	cmp.w	#12,d2
	blt.w	.3
	move.b	#$C,(puckvz).w
.3	move.w	d2,d0
	asl.w	#3,d0
	subi.w	#$A,d0			;6
	move.b	d0,$40(a0)		;temp2
	subq.w	#6,d0			;10
	move.b	d0,(puckx+nopuck).w
	movem.w	(sp)+,d0-d1
	muls.w	d2,d0
	asr.l	#1,d0
	add.w	(sp)+,d0		;x distance
	move.w	(puckx).w,temp3(a0)	;receiver target x/y
	add.w	d0,temp3(a0)
	muls.w	d2,d1
	asr.l	#1,d1
	add.w	(sp)+,d1		;y distance
	move.w	(pucky).w,temp4(a0)
	add.w	d1,temp4(a0)
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
	adda.w	#6*SCstruct,a0		;controller is on other team
.t1	movea.w	#(c1playernum-M68K_RAM),a1
.top	tst.w	position(a0)
	ble.w	.next			;can't switch to goalie
	btst	#pf2unav,pflags2(a0)		;pf2unav
	bne.w	.next			;this player is unavailable for some reason
	btst	#pfalock,pflags(a0)
	bne.w	.next			;this player is locked
	movem.w	(sp),d0-d1
	sub.w	(a0),d0
	muls.w	d0,d0
	sub.w	Ypos(a0),d1
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	d5,d0
	bhi.w	.next
	move.w	SCnum(a0),d1
	cmp.w	(a1,d3.w),d1
	beq.w	.next			;this is current player
	move.l	d0,d5
	move.w	d1,d6
.next	adda.w	#SCstruct,a0
	dbf	d2,.top
	addq.w	#4,sp
	pea	(.ex).l
	cmp.w	(a1,d4.w),d6
	beq.w	Sweepcheck		;player is same so sweep check
	move.w	d6,d0
	tst.w	d4
	beq.w	setc1player
	bra.w	setc2player
.ex	movem.l	(sp)+,d0-d6/a0-a1
	rts

Sweepcheck	;start sweep check on player a3
	bset	#pfalock,pflags(a3)
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

restorepl	;Restore old joy controlled player d1, give d0
	;the joystick. 93: if d1 is in line change mode it keeps control (d0 = d1)
	movea.w	#(SortCords-M68K_RAM),a0
	tst.w	d1
	blt.w	.spd
	cmp.w	#11,d1
	bgt.w	.spd
	asl.w	#7,d1			;scsize
	btst	#pf2lcm,pflags2(a0,d1.w)		;pf2lcm
	beq.w	.rel
	lsr.w	#7,d1
	move.w	d1,d0
	rts
.rel	bclr	#pfjoycon,pflags(a0,d1.w)
	bset	#pfna,pflags(a0,d1.w)
.spd	tst.w	d0
	blt.w	rtss
	cmp.w	#11,d0
	bgt.w	rtss
	move.w	d0,d1
	asl.w	#7,d1
	bset	#pfjoycon,pflags(a0,d1.w)
	rts

Findhittype	;look for type of swing (forhand or backhand)
	;input d0 = launch dir
	;ouput	beq	forhand
	;	bne	backhand
	neg.w	d0
	add.w	facedir(a3),d0
	andi.w	#7,d0
	btst	#3,attribute(a3)		;x flip
	beq.w	.1
	btst	d0,#$F0			;%11110000
	rts
.1	btst	d0,#$1E			;%00011110
	rts

SetShotMode	;initiate shot by player a3
	move.w	#8,(passdir).w		;default shot direction
	bset	#sfssdir,(sflags).w
	clr.w	d0			;find dx/dy for shot
	move.w	#$128,d1		;296
	btst	#pfgoal,pflags(a3)
	bne.w	.ck0
	neg.w	d1
.ck0	sub.w	(a3),d0
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	move.w	#$F,(passspeed).w
	move.w	#$81C,d1		;SPAshotf
	bsr.s	Findhittype
	beq.w	.ck1
	move.w	#$94E,d1		;SPAshotb
	move.w	#$F,(passspeed).w	;minimum shot speed
.ck1	bra.w	SetSPA

ShotMode	;shot input
	cmpi.w	#$1C,SPAnum(a3)		;7*4
	bge.w	doshot			;end of animation so shoot
	btst	#3,d0
	bne.w	.ss0
	andi.w	#7,d0
	move.w	d0,(passdir).w		;set shot direction
.ss0	cmpi.w	#$10,SPAnum(a3)		;4*4
	bge.w	rtss			;past full windup so no more passspeed
	add.w	d7,(passspeed).w
	cmpi.b	#$A,shotspd(a3)		;shotspd >= 10 must release the button
	bge.w	.cb
	cmpi.w	#8,SPAnum(a3)
	bgt.w	.rev			;slow shooter: swing after 2 frames of windup
.cb	btst	#5,d2			;cbut
	beq.w	rtss			;button hasn't changed so continue windup
.rev	neg.w	SPAnum(a3)			;End wind and swing thru
	addi.w	#$1C,SPAnum(a3)
	rts

doshot	;stick is at puck so launch puck toward goal
	movem.l	d0-d7/a0-a3,-(sp)
	bsr.w	shotdiradj	;aim away from the goalie
	move.w	#5,-(sp)		;sound effect (92 used 14)
	move.w	SCnum(a3),(shotplayer).w
	bclr	#sfssdir,(sflags).w
	bset	#pfalock,pflags(a3)
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.ex			;wiffed shot
	move.w	#$18,(sp)		;92 used 13
	bset	#sf2shot,(sflags2).w
	cmpi.w	#$94E,SPA(a3)		;SPAshotb
	bne.w	.nbh
	move.w	#$14,(sp)		;92 used 12
	move.w	(passspeed).w,d0
	lsr.w	#2,d0			;sub 25% for backhand shots
	sub.w	d0,(passspeed).w
.nbh	move.b	shotspd(a3),d0
	movea.l	a3,a0
	bsr.w	makepde
	addi.w	#$14,d0
	mulu.w	(passspeed).w,d0	;shot speed ranged by energy level
	mulu.w	#$5249,d0		;$4000*45/35
	swap	d0
	move.w	d0,(passspeed).w
	lsr.w	#4,d0			;crowd bonus 3 - speed/16
	neg.w	d0
	addq.w	#3,d0
	bpl.w	.c
	clr.w	d0
.c	add.w	d0,(sp)
	st	(puckc).w
	move.b	#$10,nopuck(a3)
	move.w	SCnum(a3),(lastplayer).w
	move.w	#$108,d1		;blueline+goalline
	btst	#pfgoal,pflags(a3)
	bne.w	.0
	neg.w	d1
.0	move.w	(passdir).w,d2
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
.1	move.w	d0,d3
	btst	#gmhl,(gmode).w
	bne.w	.perf
	cmp.w	#200,d3
	bhi.w	.notperf		;too far away for perfect shot
	moveq	#$10,d0
	add.b	shotacc(a3),d0
	bsr.w	randomd0
	cmp.w	#14,d0		;chance of perfect shot
	bgt.w	.perf			;is perfect
.notperf	move.w	(passspeed).w,d0
	lsr.w	#4,d0
	sub.b	shotacc(a3),d0
	addi.b	#$10,d0
	mulu.w	d3,d0
	lsr.w	#6,d0			;shot accuracy adjust (92 lsr #7)
	cmp.w	#250,d3
	bhi.w	.cp
	lsr.w	#1,d0			;closer than 250: half the error
.cp	cmp.w	#$88,d0
	blt.w	.ar
	move.w	#$88,d0
.ar	move.w	d0,-(sp)
	bsr.w	randomd0s
	add.w	d0,2(sp)		;x dist
	move.w	(sp),d0
	cmp.w	#60,d0
	bls.w	.ay
	moveq	#$3C,d0
	move.w	d0,(sp)
.ay	tst.w	4(sp)
	bpl.w	.am
	lsr.w	#1,d0
.am	bsr.w	randomd0s
	add.w	d0,4(sp)		;y dist
	move.w	(sp)+,d0
	lsr.w	#1,d0
	bsr.w	randomd0
	add.w	d0,4(sp)
.perf	move.w	(passspeed).w,d2	;Shot speed
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
.noup	move.w	d3,(puckvz).w
.ex	bsr.w	sfx
	movem.l	(sp)+,d0-d7/a0-a3
	rts
.shotsets	;Offsets for different directions on the shot
	dc.w	0,$C,$10,$C,$10,6,$10,0
	dc.w	0,0,-$10,0,-$10,6,-$10,$C
	dc.w	0,6

shotdiradj	;If the opposing goalie
	;covers the middle of the net, set passdir 2 or 6 to shoot at the open
	;side, else 0. Skipped for computer players (pfjoycon clear)
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	moveq	#8,d0
	moveq	#5,d1
	movea.w	#(GoalieStruct-M68K_RAM),a0
	btst	#pfteam,pflags(a3)
	bne.w	.g
	adda.w	#6*SCstruct,a0
.g	adda.w	#SCstruct,a0
	tst.w	position(a0)			;position 0 = goalie
	dbeq	d1,.g
	bne.w	.x
	move.b	Xvel(a0),d0		;goalie x/y + half his velocity
	ext.w	d0
	asr.w	#1,d0
	add.w	(a0),d0
	sub.w	(puckx).w,d0
	move.b	Yvel(a0),d1
	ext.w	d1
	asr.w	#1,d1
	add.w	Ypos(a0),d1
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
	btst	#pfgoal,pflags(a3)
	bne.w	.l
	neg.w	d4
.l	movem.w	d3-d4,-(sp)
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
	btst	#7,pflags(a3)
	beq.w	.s
	neg.w	d4
.s	moveq	#2,d0
	tst.w	d4
	bpl.w	.x
	moveq	#6,d0
.x	move.w	d0,(passdir).w
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
	move.w	SCnum(a3),d1
	asl.w	d0,d1
	or.w	d1,(PadControlBits).w
	movem.l	(sp)+,d0-d1
	rts

check4bench	;check if player a3 should go to bench. Called from assbench
	;(pops its return address when it takes over)
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	btst	#pf2pen,pflags2(a3)
	bne.w	rtss
	tst.b	newpos(a3)
	bpl.w	.b
	tst.b	newpnum(a3)
	bmi.w	rtss
.b	move.b	newpnum(a3),d0
	cmp.b	pnum(a3),d0
	beq.w	.samepl			;player should just change positions
	move.w	assnum(a3),d0
	cmpi.b	#$B,asslist(a3,d0.w)	;already going to bench
	beq.w	rtss
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	rtss
	addq.w	#4,sp
	bset	#pf2unav,pflags2(a3)		;pf2unav
	clr.w	temp1(a3)
	move.l	#$B,d0			;abench
	bra.w	assreplace
.samepl	addq.w	#4,sp
	bclr	#pf2unav,pflags2(a3)
	bclr	#pfnc,pflags(a3)
	st	newpnum(a3)
	st	newpos(a3)
	move.w	position(a3),d0
	tst.b	newpos(a3)
	bmi.w	Setplass
	move.b	newpos(a3),d0
	ext.w	d0
	move.w	d0,position(a3)
	bra.w	Setplass

;======================================================================
;======================================================================
;	Player assignments assbench ...
;	asswingd, with the fight code (assfight, chkhit, banner). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	SortCords offsets in comments: Xpos 0, frame 6, oldframe 8
;	Xvel $28, Yvel $2A, impactp $2E, position $34, temp1 $40, temp2 $42,
;	temp3 $44, temp4 $46, wallcos $4E, wallsin $50, SCnum $52, facedir $54,
;	SPA $58, SPAnum $5A, nopuck $5E, newpos $60, newpnum $61, pflags $62
;	(pfna 1, pfnc 2, pfjoycon 3, pfalock 5, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2aip 1, pf2unav 2, pf2pen 4, pf2npc 5), pnum $66, aioff $6A,
;	aidef $6B, aggress $74, checking $75, handed $76.
;	Every assignment starts with "btst #pfalock / bne rtss".

assbench	;player a3 should goto bench
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	cmpi.w	#$64,temp1(a3)		;temp1 = 100 flag: at the bench door
	beq.w	.done
	bsr.w	check4bench
	btst	#pf2pen,pflags2(a3)		;pf2pen
	bne.w	assexit
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	move.w	#8,temp2(a3)
	moveq	#$50,d0			;80
	btst	#pfteam,pflags(a3)
	bne.w	.0
	neg.w	d0
.0	move.w	d0,temp4(a3)		;temp4 = bench y
	move.w	#$88,temp3(a3)		;sideline
	neg.w	temp3(a3)
	subq.w	#8,temp3(a3)		;temp3 = bench x
	clr.w	temp1(a3)
.nna	move.b	newpnum(a3),d0
	cmp.b	pnum(a3),d0
	beq.w	.nobench		;same player, just change position
	sub.w	d7,temp1(a3)
	bpl.w	.nodec
	addq.w	#8,temp1(a3)
	move.w	Ypos(a3),d0
	sub.w	temp4(a3),d0
	cmp.w	#40,d0
	bgt.w	.nodec
	cmp.w	#-40,d0
	blt.w	.nodec
	move.w	(a3),d0
	sub.w	temp3(a3),d0
	cmp.w	#32,d0
	bgt.w	.nodec
	move.w	#$52C,d1		;SPAglide
	tst.w	position(a3)
	bne.w	.gli
	move.w	#2,d1			;SPAgready
.gli	bsr.w	SetSPA
	bset	#pfnc,pflags(a3)
	cmpi.w	#4,facedir(a3)
	beq.w	.ok
	addq.w	#1,facedir(a3)		;turn toward the bench
	andi.w	#7,facedir(a3)
.ok	clr.w	Yvel(a3)
	move.w	#$F800,Xvel(a3)		;-$800
	cmp.w	#16,d0
	bgt.w	rtss
	clr.w	Xvel(a3)
	cmpi.w	#4,facedir(a3)
	bne.w	rtss
	move.w	#$F800,Xvel(a3)
	move.w	#2,facedir(a3)
	move.w	#$1166,d1		;SPAwallleft
	bsr.w	SetSPA
	bset	#pfalock,pflags(a3)
	move.w	#$64,temp1(a3)		;100
	rts
.done	clr.w	frame(a3)
	clr.w	d0
	move.b	pnum(a3),d0
	add.w	d0,d0
	movea.l	#tmstruct,a0
	btst	#6,pflags(a3)
	beq.w	.t0
	adda.w	#tmsize,a0
.t0	move.w	#$FFFE,tmpdst(a0,d0.w)	;tmpdst: put used player on bench
	move.b	newpnum(a3),d3
	bsr.w	.nobench2
	bra.w	setplayer
.nodec	btst	#pfnc,pflags(a3)
	bne.w	rtss
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	movea.l	#EvadePC,a0
	bra.w	skateto
.nobench	bclr	#pf2unav,pflags2(a3)		;pf2unav
.nobench2	move.b	newpos(a3),d0
	ext.w	d0
	move.w	d0,position(a3)
	bsr.w	Setplass
	st	newpnum(a3)
	st	newpos(a3)
	rts

asseben	;player a3 should exit bench area
	btst	#5,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	move.w	SCnum(a3),d0
	subq.w	#6,d0
	bmi.w	.0
	addq.w	#1,d0
.0	muls.w	#$E,d0
	move.w	d0,Ypos(a3)
	move.w	#$88,(a3)		;sideline
	neg.w	(a3)
	move.w	#2,facedir(a3)
	bset	#5,pflags(a3)
	move.w	#$1128,d1		;SPAwallright
	bra.w	SetSPA
.nna	move.w	#4,facedir(a3)
	bclr	#pfnc,pflags(a3)
	bclr	#pf2npc,pflags2(a3)		;pf2npc
	bclr	#pf2unav,pflags2(a3)		;pf2unav
	clr.w	SPA(a3)
	move.w	#$1000,Xvel(a3)
	bra.w	assexit

asspenalty	;player a3 should goto penalty box
	btst	#5,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	bset	#pf2unav,pflags2(a3)		;pf2unav
	bsr.w	clrplayer
	moveq	#-2,d4
	bsr.w	setpads			;put number on player leaving
	move.w	#8,temp2(a3)
	moveq	#$B,d0			;11*(n+3) (92 used 55 - 10*n)
	move.b	(PBnum).w,d1
	btst	#6,pflags(a3)
	bne.w	.0
	lsr.w	#4,d1
	neg.w	d0
.0	andi.w	#$F,d1
	cmp.w	#2,d1
	bls.w	.1
	moveq	#2,d1
.1	addq.w	#3,d1
	muls.w	d0,d1
	move.w	d1,temp4(a3)
	move.w	#$88,temp3(a3)		;temp3 = sideline
	clr.w	temp1(a3)
	bset	#pf2npc,pflags2(a3)		;pf2npc: no player coll.
	clr.w	Wallcos(a3)
	clr.w	Wallsin(a3)
.nna	move.w	Ypos(a3),d0
	sub.w	temp4(a3),d0
	cmp.w	#12,d0
	bgt.w	.st
	cmp.w	#-12,d0
	blt.w	.st
	move.w	(a3),d0
	sub.w	temp3(a3),d0
	cmp.w	#-24,d0
	blt.w	.st
	sub.w	d7,temp1(a3)
	bpl.w	rtss
	addq.w	#8,temp1(a3)
	bset	#pfnc,pflags(a3)
	move.w	#$52C,d1		;SPAglide
	bsr.w	SetSPA
	moveq	#6,d2
	tst.b	handed(a3)
	beq.w	.left
	moveq	#2,d2
.left	cmp.w	facedir(a3),d2
	beq.w	.ok
	addq.w	#1,facedir(a3)
	andi.w	#7,facedir(a3)
.ok	clr.w	Yvel(a3)
	move.w	#$1000,Xvel(a3)
	cmp.w	#-8,d0
	blt.w	rtss
	clr.w	Xvel(a3)
	cmp.w	facedir(a3),d2
	bne.w	rtss
	bset	#5,pflags(a3)
	move.w	#2,facedir(a3)
	move.w	#$1128,d1		;SPAwallright
	bsr.w	SetSPA
	bclr	#pf2pen,pflags2(a3)		;pf2pen
	move.l	#$D,d0			;adopen
	bra.w	assreplace
.st	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	movea.l	#rtss,a0
	bra.w	skateto

clrplayer	;take the joystick off player a3
	btst	#3,pflags(a3)
	beq.w	rtss
	clr.w	d4
	move.w	SCnum(a3),d0
	cmp.w	(c1playernum).w,d0
	beq.w	changeplayer
	moveq	#2,d4
	bra.w	changeplayer

assdopen	;add player a3 to penalty box
	btst	#5,pflags(a3)
	bne.w	rtss
	moveq	#$10,d0
	btst	#6,pflags(a3)
	beq.w	.1
	moveq	#1,d0
.1	add.b	d0,(PBnum).w		;Players in penalty box
	st	position(a3)
	clr.w	frame(a3)
	rts

assepen	;player a3 should exit penalty area
	btst	#5,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	bset	#pfnc,pflags(a3)
	bset	#pf2unav,pflags2(a3)		;pf2unav
	moveq	#$10,d0
	moveq	#-$3C,d1		;-60
	btst	#6,pflags(a3)
	beq.w	.1
	moveq	#1,d0
	neg.w	d1
.1	sub.b	d0,(PBnum).w		;Players in penalty box
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	move.w	#$86,(a3)
	move.w	#2,facedir(a3)
	bset	#5,pflags(a3)
	move.w	#$1166,d1		;SPAwallleft
	bsr.w	SetSPA
	jmp	SprSort
.nna	move.w	#4,facedir(a3)
	st	newpnum(a3)
	st	newpos(a3)
	bclr	#pfjoycon,pflags(a3)
	bclr	#pfnc,pflags(a3)
	bclr	#pf2npc,pflags2(a3)		;pf2npc
	bclr	#pf2unav,pflags2(a3)		;pf2unav
	move.w	#$F000,Xvel(a3)		;-$1000
	bra.w	assexit

assfaceoff	;players do nothing until faceoff is over
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#sf2faceoff,(sflags2).w
	beq.w	assexit			;exit once faceoff is over
	rts

assfaceoffpl	;assignment for players actually participating in faceoff
	;a3 = player
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(sflags2).w
	beq.w	.exit
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna	movea.l	#fofdata2,a0
	btst	#6,pflags(a3)
	beq.w	.0
	addq.w	#4,a0
.0	move.w	SPAnum(a3),d0
	lsr.w	#2,d0
	addq.w	#1,d0
	tst.b	handed(a3)
	bne.w	.lefty
	addq.w	#3,d0
.lefty	move.w	d0,(a0)
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bset	#pf2aip,pflags2(a3)
	bne.w	rtss
	move.w	#$11A4,d1		;SPAfaceoff
	cmpi.w	#$10,(puckx+temp1).w
	bls.w	.d
	moveq	#8,d0
	bsr.w	randomd0
	tst.w	d0
	beq.w	.d
	move.w	#$11CE,d1		;SPAfaceoffr
.d	bset	#pf2aip,pflags2(a3)
	bra.w	SetSPA
.exit	move.b	#$14,nopuck(a3)		;nopuck = 20
	bra.w	assexit

assfight	;fighting logic
	;a3 = player
	btst	#5,pflags(a3)		;check if animation lock
	bne.w	rtss			;exit if so
	tst.w	(Pencntdwn).w		;fight over?
	bmi.w	donothing
	bclr	#1,pflags(a3)		;clear new assignment
	beq.w	.nna			;not first time through
	bsr.w	getpde			;get player's energy level
	move.b	$74(a3),d1		;aggress
	ext.w	d1
	mulu.w	d1,d0
	lsr.w	#8,d0
	lsr.w	#4,d0
	cmp.w	#5,d0
	bgt.w	.s
	moveq	#5,d0			;min strength is 5
.s	move.w	d0,temp3(a3)		;temp3 = strength
	clr.w	temp2(a3)
	move.w	#$FFFF,temp4(a3)		;temp4 = banner timer
	cmpi.w	#2,facedir(a3)
	bne.w	.nna
	move.w	#$5A,temp4(a3)		;90: one player shows the banner
.nna	sub.w	d7,temp4(a3)		;Sub frames elapsed from temp4
	bcc.w	.nna2
	bsr.w	banner			;show fighters' names
.nna2	tst.w	temp3(a3)
	bmi.w	rtss
	move.w	impactp(a3),d0
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0			;a0 = opponent
	move.w	(a3),d0
	add.w	(a0),d0
	asr.w	#1,d0
	move.w	d0,(xc1).w		;scroll lock between the fighters
	btst	#pfjoycon,pflags(a3)
	bne.w	.j
	bset	#pf2aip,pflags2(a3)
	bne.w	.j
	move.w	(a3),d0			;computer punches only when in range
	sub.w	(a0),d0
	move.w	Xvel(a3),d1
	asr.w	#8,d1
	add.w	d1,d0
	move.w	Xvel(a0),d1
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
.p	asl.w	#1,d0
	lea	.al(pc),a1		;choose punch type
	move.w	(a1,d0.w),d1
	bsr.w	SetSPA
.j	bsr.w	chkhit
	cmpi.w	#$FE2,SPA(a3)		;SPAfheld
	beq.w	.njc
	cmpi.w	#$F8E,SPA(a3)		;SPAfight
	beq.w	.jc
	btst	#3,pflags(a3)
	bne.w	.jc
.njc	move.w	(xc1).w,d0
	addi.w	#$A,d0
	cmpi.w	#2,facedir(a3)
	bne.w	.0
	subi.w	#$14,d0
.0	sub.w	(a3),d0
	asl.w	#5,d0			;add to Xvel (92 clamped and set it)
	add.w	d0,Xvel(a3)
.jc	move.w	(yc1).w,d1
	sub.w	Ypos(a3),d1
	asl.w	#8,d1
	cmp.w	#$1000,d1
	blt.w	.y1
	move.w	#$1000,d1
.y1	cmp.w	#-$1000,d1
	bgt.w	.y2
	move.w	#$F000,d1
.y2	move.w	d1,Yvel(a3)
	rts
.al	dc.w	$1004			;SPAfhigh
	dc.w	$1036			;SPAflow
	dc.w	$FC0			;SPAfgrab

chkhit	;part of fight to see if player is hit
	;a3 = player, a0 = opponent
	movem.l	d0/a0-a3,-(sp)
	move.w	frame(a3),d0
	cmp.w	oldframe(a3),d0
	beq.w	.ex
	cmp.w	#$164,d0		;SPFfight+2,d0
	beq.w	.dropped
	move.w	(a3),d0
	sub.w	(a0),d0
	cmp.w	#22,d0
	bgt.w	.ex
	cmp.w	#-22,d0
	blt.w	.ex
	move.w	Ypos(a3),d0
	sub.w	Ypos(a0),d0
	cmp.w	#8,d0
	bgt.w	.ex
	cmp.w	#-8,d0
	blt.w	.ex
	move.w	frame(a3),d0
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
.dropped	bclr	#pf2npc,pflags2(a3)		;pf2npc: gloves dropped
	move.w	(xc1).w,d0
	cmp.w	#90,d0
	blt.w	.chkneg
	moveq	#$5A,d0
.chkneg	cmp.w	#-90,d0
	bgt.w	.drcont
	moveq	#-$5A,d0
.drcont	asr.w	#2,d0
	bne.w	.dr0
	addq.w	#1,d0
.dr0	move.b	d0,(glovecords).w
	move.w	(yc1).w,d0
	asr.w	#2,d0
	move.b	d0,(glovecords+1).w
	bra.s	.ex
.grab	exg	a0,a3
	bset	#pf2aip,pflags2(a3)
	move.w	#$FE2,d1		;SPAfheld
	bsr.w	SetSPA
	bra.s	.ex
.hithigh	exg	a0,a3
	bsr.w	.cwd			;crowd reacts, knock back
	bset	#pf2aip,pflags2(a3)
	subq.w	#1,temp3(a3)
	bmi.w	.fall
	move.w	#$1068,d1		;SPAfhith
	bsr.w	SetSPA
	move.w	#SFXhithigh,-(sp)		;SFXhithigh
	bsr.w	sfx
	bra.s	.ex
.hitlow	exg	a0,a3
	bsr.w	.cwd
	bset	#pf2aip,pflags2(a3)
	subq.w	#1,temp3(a3)
	bmi.w	.fall
	move.w	#$108A,d1		;SPAfhitl
	bsr.w	SetSPA
	move.w	#SFXhitlow,-(sp)		;SFXhitlow
	bsr.w	sfx
	bra.w	.ex
.cwd	;Crowd reacts to a punch; push the hit player (a3)
	;back by the puncher's (a0) strength
	addi.w	#$50,(crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
	moveq	#5,d0
	add.w	temp3(a0),d0
	mulu.w	#$1F4,d0		;500
	cmpi.w	#2,facedir(a3)
	bne.w	.xveladj
	neg.w	d0
.xveladj	add.w	d0,Xvel(a3)
	rts
.fall	;a3 lost the fight: change the a0 player's penalty to
	;fighting, maybe injure a3
	movem.l	a1,-(sp)
	movea.w	#(PenaltyBufferEnd-M68K_RAM),a1	;end of the scoring summary
.loop	addq.w	#2,a1
	cmpi.b	#$26,(a1)
	bne.s	.loop
	move.b	1(a1),d0
	andi.w	#$F,d0
	cmp.w	SCnum(a0),d0
	bne.s	.loop			;find the penalty of the a0 player
	move.b	#$28,(a1)		;penalty becomes PenFighting
	movem.l	(sp)+,a1
	move.w	#$3C,(Pencntdwn).w	;60
	move.w	#$FFFF,temp3(a0)		;temp3 = -1
	addi.w	#$258,(crowdlevel).w	;600
	addi.w	#$1E,(CwdExciteLvl).w
	moveq	#$3C,d0
	bsr.w	randomd0
	cmp.b	$75(a0),d0		;checking value
	bgt.w	.noinj			;skip injury
	move.w	#$B4,(Pencntdwn).w	;180: player is injured
	bset	#6,pflags2(a3)
	move.w	#$10CE,d1		;SPAffall
	bsr.w	SetSPA
	bsr.w	ShowInjuryMsg
	movea.w	a3,a2
	bsr.w	setInjuryType
	move.w	#$112C,tmpdst(a0,d1.w)	;overwrite setInjuryType result in the team struct
	move.w	#3,(InjCntDown).w
	bra.w	.ex
.noinj	move.w	#$10AC,d1		;SPAbfall
	bsr.w	SetSPA
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	#$B,-(sp)		;SFXcrowdcheer
	btst	#6,pflags(a3)
	bne.w	.snd
	lea	tmsize(a2),a2
	move.w	#$C,(sp)		;SFXcrowdboo
.snd	bsr.w	song
	bra.w	.ex

ShowInjuryMsg	;(Rev A). Clear the message line
	bsr.w	printz
	String	$BF,0,1,0
	moveq	#$28,d0
	moveq	#5,d1
	move.w	#$7FF,d2
	bra.w	eraser

banner	;fight banner: close both line change boxes, frame a box with
	;"<player> <team>" for both fighters and "vs"
	movem.l	d0-d3/a0-a4,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	jsr	(lcfound2).l
	adda.w	#tmsize,a2
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
.neg	move.b	-3(a0),d0
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
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#6,pflags(a1,d0.w)
	beq.w	.0
	adda.w	#tmsize,a2
.0	move.b	pnum(a1,d0.w),d0
	ext.w	d0
	jsr	(getname).l
	movea.w	a1,a3
	bsr.w	appendz
	String	' ',0
	movea.l	tmdata(a2),a1		;team name
	adda.w	4(a1),a1
	adda.w	(a1),a1
	bsr.w	appstring
	cmp.w	(a3),d2
	bgt.w	.gt
	move.w	(a3),d2
.gt	movea.w	a3,a1
	move.w	(a1),d0
	lsr.w	#1,d0
	neg.w	d0
	addi.w	#$10,d0
	move.w	d0,(printx).w
	rts

assfwatch	;for player who is watching fight
	;a3 = player
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna	sub.w	d7,temp1(a3)
	bpl.w	.go
	addi.w	#$3C,temp1(a3)		;new spot every second
	move.w	(a3),d0
	sub.w	(xc1).w,d0
	move.w	Ypos(a3),d1
	sub.w	(yc1).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	sroot
	move.w	d0,d2
	bne.w	.d
	moveq	#1,d2
.d	movem.w	(sp)+,d0-d1
	muls.w	#$50,d0			;80 pixels from the fight
	divs.w	d2,d0
	add.w	(xc1).w,d0
	move.w	#$7E,d3
	cmp.w	d3,d0
	blt.w	.x0
	move.w	d3,d0
.x0	neg.w	d3
	cmp.w	d3,d0
	bgt.w	.x1
	move.w	d3,d0
.x1	move.w	d0,temp3(a3)
	muls.w	#$50,d1
	divs.w	d2,d1
	add.w	(yc1).w,d1
	move.w	d1,temp4(a3)
.go	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	lea	rtss(pc),a0
	bsr.w	skateto
	bra.w	check4check

donothing	;player should do nothing
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#3,pflags(a3)
	bne.w	rtss
	moveq	#8,d0
	bra.w	doplayeracc

assstanley	;player a3 skates with stanley cup overhead
	btst	#5,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	move.w	#$5A,temp3(a3)		;90
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	temp3(a3)
.0	move.w	(Vpos).w,temp4(a3)
	move.w	#$1258,d1		;SPAStanley
	bsr.w	SetSPA
.nna	move.w	temp3(a3),d0
	sub.w	(a3),d0
	move.w	temp4(a3),d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	cmp.w	#7,d0
	bgt.w	rtss
	move.w	d0,d2
	move.w	d2,facedir(a3)
	bra.w	playeracc

assscore	;player a3 celebrates, if scoring player then do arm pump
	btst	#5,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	bsr.w	.1
	move.w	#8,temp2(a3)
	move.w	#$5A,temp3(a3)
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	temp3(a3)
.0	move.w	(Vpos).w,temp4(a3)
.nna	movea.l	#rtss,a0
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	sub.w	d7,temp1(a3)
	bpl.w	.chkcon
	bset	#5,pflags(a3)
	move.w	#$EAA,d1		;SPAcelebrate
	move.w	(shotplayer).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.nopump
	move.w	#$F1C,d1		;SPApump
.nopump	bsr.w	SetSPA
.1	moveq	#$78,d0			;120
	bsr.w	randomd0
	move.w	d0,temp1(a3)
	rts
.chkcon	btst	#3,pflags(a3)
	beq.w	skateto
	rts

assdefo	;player a3 is defensive player on offense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)
	move.l	#2,d0			;adefd
	btst	#4,tmflags(a2)		;team flag forces defense
	bne.w	assreplace
	move.w	(pucky).w,d1
	btst	#7,pflags(a3)
	bne.w	.de1
	neg.w	d1
.de1	cmp.w	#$5D,d1		;blueline,d1
	blt.w	assreplace
	move.w	(puckc).w,d1
	bmi.w	.nodec
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace		;other team has puck
.nodec	lea	EvadePC(pc),a0
	moveq	#$50,d0
	cmpi.w	#2,position(a3)
	beq.w	.1
	neg.w	d0
.1	move.w	#$62,d1			;98
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0	move.w	(puckx).w,d2
	eor.w	d0,d2
	bmi.w	.2
	move.w	(puckx).w,d0
	bra.w	skateto
.2	move.w	(puckx).w,d2
	asr.w	#1,d2
	add.w	d2,d0
	bra.w	skateto

assdefd	;player a3 is defensive player on defense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)
	bpl.w	.de3
	move.b	aidef(a3),temp1(a3)
	move.w	(pucky).w,d1
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	btst	#7,pflags(a3)
	bne.w	.de00
	neg.w	d1
	neg.w	d3
.de00	tst.w	d3			;only lead when moving up ice
	bpl.w	.v
	clr.w	d3
.v	add.w	d1,d3
	cmp.w	#$58,d3
	blt.w	.de0
	btst	#4,tmflags(a2)
	bne.w	.de0
	move.w	(puckc).w,d1
	bmi.w	.de0
	bsr.w	chkpk
	beq.w	.de0
	move.l	#1,d0			;adefo
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace		;our team has puck
.de0	move.w	#$41,temp3(a3)		;65
	cmpi.w	#2,position(a3)
	beq.w	.de1
	neg.w	temp3(a3)
.de1	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.de2
	adda.w	#6*SCstruct,a0
.de2	moveq	#5,d2			;Find furthest-up attacker
	move.w	#$FC18,d0		;-1000
	btst	#7,pflags(a3)
	beq.w	.gdwn
	neg.w	d0
.gup	btst	#pf2unav,pflags2(a0)		;pf2unav
	bne.w	.gu0
	tst.w	position(a0)
	bmi.w	.gu0
	move.w	Yvel(a0),d1
	bmi.w	.gu2
	clr.w	d1
.gu2	asr.w	#4,d1			;92 asr #5
	add.w	Ypos(a0),d1
	cmp.w	d0,d1
	bgt.w	.gu0
	move.w	d1,d0
.gu0	adda.w	#SCstruct,a0
	dbf	d2,.gup
	subi.w	#$32,d0			;50 back of him
	cmp.w	#-190,d0
	bgt.w	.gu1
	move.w	#$FF24,d0		;-220
.gu1	move.w	d0,temp4(a3)
	move.w	(puckx).w,d0
	move.w	temp3(a3),d1
	eor.w	d0,d1
	bpl.w	.de3
	clr.w	temp3(a3)
	bra.w	.de3
.gdwn	btst	#pf2unav,pflags2(a0)
	bne.w	.gd0
	tst.w	position(a0)
	bmi.w	.gd0
	move.w	Yvel(a0),d1
	bpl.w	.gd2
	clr.w	d1
.gd2	asr.w	#4,d1
	add.w	Ypos(a0),d1
	cmp.w	d0,d1
	blt.w	.gd0
	move.w	d1,d0
.gd0	adda.w	#SCstruct,a0
	dbf	d2,.gdwn
	addi.w	#$32,d0
	cmp.w	#190,d0
	blt.w	.gd1
	move.w	#$DC,d0			;220
.gd1	move.w	d0,temp4(a3)
	neg.w	temp3(a3)
	move.w	(puckx).w,d0
	move.w	temp3(a3),d1
	eor.w	d0,d1
	bpl.w	.de3
	clr.w	temp3(a3)
.de3	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	movea.l	#EvadePC,a0
	bsr.w	skateto
	bra.w	check4check

asswingd	;player a3 is wing on defense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.w	(puckc).w,d1
	bmi.w	.nodec
	move.l	#4,d0			;awingo
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace		;our team has puck
.nodec	moveq	#$64,d0			;100
	cmpi.w	#5,position(a3)
	bne.w	.0
	neg.w	d0
.0	move.l	#$9E,d1
	btst	#7,pflags(a3)
	beq.w	.up
	neg.w	d0
	neg.w	d1
	moveq	#-$4E,d2
	btst	#4,tmflags(a2)
	bne.w	.set
	cmp.w	(pucky).w,d2
	bgt.w	.lo
	move.w	(pucky).w,d1
	bra.w	.go
.lo	move.w	#$FEF8,d2		;-264
	cmp.w	(pucky).w,d2
	blt.w	.go
	move.w	d2,d1
	bra.w	.go
.up	moveq	#$4E,d2
	btst	#4,tmflags(a2)
	bne.w	.set
	cmp.w	(pucky).w,d2
	blt.w	.hi
	move.w	(pucky).w,d1
	bra.w	.go
.hi	move.w	#$108,d2		;264
	cmp.w	(pucky).w,d2
	bgt.w	.go
.set	move.w	d2,d1
.go	lea	rtss(pc),a0
	move.w	(puckx).w,d2
	eor.w	d0,d2
	bmi.w	skateto
	move.w	(puckx).w,d0
	bra.w	skateto

;======================================================================
;======================================================================
;	asswingo ... asspuckc, chk4lc, chkpk,
;	chk4shot, CompShoot, chk4pass, EvadePC. Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	SortCords offsets in comments: Xpos 0, attribute 4
;	Ypos $14, Xvel $28, Yvel $2A, position $34, temp1 $40, temp2 $42,
;	temp3 $44, temp4 $46, temp5 $48, SCnum $52, facedir $54, nopuck $5E,
;	pflags $62 (pfalock 5, pfjoycon 3, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2aip 1, pf2unav 2, pf2lcm 3), aioff $6A, aidef $6B, spodds $70.
;	Team struct: tmflags $30, $2A = long stat. blueline = $58,
;	goalline+blueline = $108.

asswingo	;player a3 is winger on offense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	st	temp5(a3)			;temp5 = old zone number
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)
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
.de0	move.w	(pucky).w,d0
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	add.w	d0,d3
	btst	#pfgoal,pflags(a3)
	bne.w	.de1
	neg.w	d0
	neg.w	d3
.de1	clr.w	d2			;Set zone number
	cmp.w	#-$58,d3		;-blueline,d3
	blt.w	.de2
	addq.w	#8,d2
	cmp.w	#$58,d0		;blueline,d0
	blt.w	.de2
	btst	#4,tmflags(a2)		;team flag keeps him back
	bne.w	.de2
	addq.w	#8,d2
	cmp.w	#$108,d3		;blueline+goalline,d3
	blt.w	.de2
	addq.w	#8,d2
.de2	cmp.w	temp5(a3),d2
	bne.w	.de3
	move.w	(VDP_CNTR).l,d0		;HV counter as random
	andi.w	#$7F,d0
	bne.w	.nodec
.de3	move.w	d2,temp5(a3)
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
.dedata	;x, x random, y, y random
	dc.w	80,20,-70,10		;in own zone
	dc.w	100,20,58,5		;center ice area
	dc.w	60,50,230,20		;opp zone
	dc.w	80,30,250,20		;past goalline
.nodec	move.w	temp3(a3),d0
	cmpi.w	#5,position(a3)
	beq.w	.1
	neg.w	d0
.1	move.w	temp4(a3),d1
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0	lea	EvadePC(pc),a0
	bra.w	skateto

asscenterd	;player a3 is center on defense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)
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
.nodec	move.w	(puckx).w,d0
	asr.w	#1,d0
	move.w	(pucky).w,d2
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d2
.0	moveq	#-$80,d1
	cmp.w	#-$58,d2		;-blueline,d2
	blt.w	.z0
	add.w	(pucky).w,d1
	asr.w	#1,d1
.z0	btst	#7,pflags(a3)
	bne.w	.z1
	neg.w	d1
.z1	lea	rtss(pc),a0
	bra.w	skateto

asscentero	;player a3 is center on offense
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#3,pflags(a3)
	bne.w	rtss
	bclr	#1,pflags(a3)
	beq.w	.nna
	st	temp5(a3)			;old zone number
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)
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
.de0	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.de1
	neg.w	d0
.de1	clr.w	d2			;Set zone number
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
.de2	cmp.w	temp5(a3),d2
	bne.w	.de3
	move.w	(VDP_CNTR).l,d0
	andi.w	#$7F,d0
	bne.w	.nodec
.de3	move.w	d2,temp5(a3)
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
.dedata
	dc.w	0,60,-70,10
	dc.w	0,60,60,10
	dc.w	0,40,170,30
	dc.w	0,80,170,20
.nodec	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d1
.0	lea	EvadePC(pc),a0
	bra.w	skateto

assgoalie	;Player a3 is goalie. Also entered from assnearest
	btst	#5,pflags(a3)
	bne.w	rtss
	bsr.w	check4bench
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
	st	temp4(a3)			;temp4 = cover countdown
.nna	cmpi.w	#$34,(a3)		;Outside the crease area?
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
.skate	lea	rtss(pc),a0		;Skate back to the net
	moveq	#4,d0
	tst.w	(a3)
	bpl.w	.0
	neg.w	d0
.0	move.w	#$E4,d1
	btst	#7,pflags(a3)
	beq.w	skateto
	neg.w	d1
	bra.w	skateto
.noskate	btst	#pf2aip,pflags2(a3)
	bne.w	rtss
	move.w	#2,d1			;SPAgready
	bsr.w	SetSPA
	btst	#gmclock,(gmode).w
	bne.w	rtss
	tst.w	temp5(a3)			;temp5 = holding time
	bmi.w	.nofo
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	.mbfo
	st	temp5(a3)
	bra.w	.nofo
.mbfo	sub.w	d7,temp5(a3)
	bpl.w	.nofo
	move.l	#8,d0			;PenGhold
	bsr.w	AddPenalty2
.nofo	sub.b	d7,temp1(a3)
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
.cnt	subq.w	#1,temp4(a3)
	bpl.w	.pc
	move.w	#$FFFF,temp4(a3)
.pc	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	bne.w	.cover
	tst.w	temp5(a3)
	bpl.w	.hold
	move.w	#$5A,temp5(a3)		;90 frames before holding penalty
.hold	st	temp4(a3)
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
.tl	btst	#pf2unav,pflags2(a0)		;pf2unav
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
.tn	adda.w	#SCstruct,a0
	dbf	d0,.tl
	move.w	#1,(threat).w
	bsr.w	chk4pass
	bra.w	.de1
.cover	tst.w	temp4(a3)			;cover a loose puck at the crease
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
	bset	#pf2aip,pflags2(a3)
	addi.w	#$96,(crowdlevel).w	;150
	addi.w	#$A,(CwdExciteLvl).w
	rts
.de1	movea.w	#(puckcross-M68K_RAM),a0
	move.w	#$104,d3		;goal line
	btst	#7,pflags(a3)
	beq.w	.de2
	addq.w	#4,a0
	neg.w	d3
.de2	cmpi.w	#$104,Ypos(a3)
	bgt.w	.out
	cmpi.w	#$FEFC,Ypos(a3)
	bgt.w	.in
.out	clr.w	d2			;Behind the goal line
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
.in	move.w	(puckx).w,d0		;Face the puck
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
.lead2	subi.w	#$40,d0
.lead	move.w	d0,d1
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
.far	bsr.w	sroot			;Scale to an 18 (26 if shooting) pixel arc
	moveq	#1,d2
	add.w	d0,d2
	moveq	#$12,d4
	btst	#sfssdir,(sflags).w
	beq.w	.f0
	addq.w	#8,d4
.f0	movem.w	(sp)+,d0-d1
	muls.w	d4,d1
	addq.w	#8,d4
	muls.w	d4,d0
	divs.w	d2,d0
	divs.w	d2,d1
.de4	add.w	d3,d1
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
	bset	#pf2aip,pflags2(a3)
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
.noflip	cmpi.w	#8,(puckz).w
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
.de7	add.w	d0,d0
	lea	GoalieSaveList(pc),a1
	move.w	(a1,d0.w),d1
	cmp.w	#$198,d1
	bne.w	.set
	andi.w	#3,d3
	beq.w	.set
	cmpi.b	#$B,aggress(a3)
	blt.w	.set
	move.w	#$1CA,d1
.set	bsr.w	SetSPA
	addi.w	#$96,(crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
.de8	move.w	(a0),d0
	cmpi.w	#$FC,(pucky).w
	bgt.w	.post
	cmpi.w	#$FF04,(pucky).w
	bgt.w	.de5
.post	moveq	#$18,d0			;Hug the post
	tst.w	(puckx).w
	bpl.w	.de5
	neg.w	d0
.de5	move.w	d2,d1
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
.vt	bsr.w	vtoa
	move.b	d0,temp2+1(a3)
.nodec	move.b	temp2+1(a3),d2
	ext.w	d2
	cmp.w	#7,d2
	ble.w	playeracc
	bra.w	StopNA
.rush	tst.w	(puckc).w		;rush a loose puck when
	bpl.s	.de5			;the score/time stats say so
	btst	#2,(iflags).w
	bne.s	.de5
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	btst	#6,pflags(a3)
	beq.w	.t0
	exg	a1,a2
.t0	cmpi.l	#$1324,$2A(a1)
	blt.w	.de5
	cmpi.l	#$9C4,$2A(a2)
	blt.w	.de5
	cmpi.w	#$E0,(pucky).w
	bgt.w	.dir
	cmpi.w	#$FF20,(pucky).w
	bgt.w	.de5
.dir	tst.w	(puckvy).w
	btst	#7,pflags(a3)
	beq.w	.dir2
	eori	#8,ccr			;flip N
.dir2	bmi.w	.de5			;Puck moving away
	move.w	(puckvx).w,d0
	bpl.w	.ax
	neg.w	d0
.ax	move.w	(puckvy).w,d1
	bpl.w	.ay
	neg.w	d1
.ay	cmp.w	d0,d1
	blt.w	.de5
	move.l	#$F,d0			;assgoalietopuck
	bra.w	assinsert

ClampYPosition	;d1 = y clamped to +-$103, minus goal line d3. d0 = 0 if a3
	;has the puck
	move.w	(puckc).w,d2
	cmp.w	SCnum(a3),d2
	bne.w	.0
	clr.w	d0
.0	cmp.w	#$103,d1
	blt.w	.1
	move.w	#$103,d1
.1	cmp.w	#-$103,d1
	bgt.w	.2
	move.w	#$FEFD,d1
.2	sub.w	d3,d1
	rts

AdjustFacingDirection	;Turn facedir one step
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
	btst	#pfgoal,pflags(a3)
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

GoalieSaveList	;goalie save choices
	dc.w	$166			;SPAgglover
	dc.w	$198			;SPAgglovel
	dc.w	$270			;SPAgstackr
	dc.w	$2C2			;SPAgstackl
	dc.w	$20C			;SPAgstickr
	dc.w	$23E			;SPAgstickl

assgoalietopuck	;goalie skates out to a loose puck (inserted by
	;assgoalie)
	btst	#3,pflags(a3)
	bne.w	assexit
	btst	#0,(gmode).w
	bne.w	assexit
	bsr.w	check4bench
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna	sub.b	d7,temp1(a3)
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
.dir	bmi.w	assexit
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	btst	#6,pflags(a3)
	beq.w	.t0
	exg	a1,a2
.t0	cmpi.l	#$E10,$2A(a1)
	blt.w	assexit
	cmpi.l	#$640,$2A(a2)
	blt.w	assexit
.go	bra.w	skatetopuck

asspuckc	;player a3 is puck handler
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	assexit
	btst	#5,pflags(a3)
	bne.w	rtss
	btst	#0,(gmode).w
	bne.w	donothing
	btst	#3,pflags(a3)
	bne.w	assexit
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	move.w	d0,temp3(a3)		;temp3 = random 0-3
.nna	sub.b	d7,temp1(a3)
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)
	bsr.w	checkob
	bsr.w	chk4lc
	bsr.w	chk4shot
	bsr.w	chk4pass
.nodec	moveq	#6,d0
	add.w	temp3(a3),d0
	lea	.postab(pc),a0
	btst	#sf2offsig,(sflags2).w		;someone is over the line
	beq.w	.nd1
	move.w	position(a3),d0
.nd1	asl.w	#2,d0
	move.w	2(a0,d0.w),d1
	move.w	(a0,d0.w),d0
	btst	#7,pflags(a3)
	bne.w	.nd0
	neg.w	d0
	neg.w	d1
.nd0	lea	.chkdir(pc),a0
	bra.w	skateto
.chkdir	ext.w	d0
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
.cd0	move.b	Xvel(a0),d1
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
	move.w	(VDP_CNTR).l,d1		;turn either way
	andi.w	#1,d1
	add.w	d1,d0
	andi.w	#7,d0
.next	adda.w	#SCstruct,a0
	dbf	d4,.cd0
	rts
.postab	;x,y by position when offsides (1-5), then 4
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
.gu	tst.w	d0
	bmi.w	rtss
	cmp.w	#$58,d0		;blueline,d0
	bgt.w	rtss
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#3,d0
	bne.w	rtss
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	bne.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	btst	#6,pflags(a3)
	beq.w	.0
	exg	a2,a1
.0	bsr.w	AvgCline
	cmp.w	#$C00,d0
	bhi.w	rtss
	bsr.w	CompLine
	bsr.w	setpersonel
	bsr.w	printscores1
	bra.w	CompShoot

chkpk	;return z flag set if killing penalty
	;return z flag clr if not
	btst	#sf2pwrplay,(sflags2).w
	bne.w	chkpk2
	eori	#4,ccr			;no power play returns ne
	rts

chkpk2	movem.l	d0-d1,-(sp)
	btst	#sf2pwrtm,(sflags2).w
	move.w	sr,d0
	btst	#pfteam,pflags(a3)
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
.npk	moveq	#$20,d4
	sub.b	spodds(a3),d4		;shot/pass odds
	asl.w	#4,d4
	move.w	#$108,d1		;blueline+goalline
	btst	#7,pflags(a3)
	bne.w	.c0
	neg.w	d1
.c0	sub.w	(pucky).w,d1
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
.co0	tst.w	position(a1)
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
.gl	btst	#pf2aip,pflags2(a1)		;goalie busy, shoot now
	beq.w	.co1
	clr.w	d3
	moveq	#1,d4
.co1	adda.w	#SCstruct,a1
	dbf	d3,.co0
.no1	move.w	d4,d0
	bsr.w	randomd0
	cmp.w	#8,d0
	bgt.w	rtss
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0	tst.w	d0
	bmi.w	rtss			;don't shoot from behind center line
	move.w	#$108,d1
	sub.w	d0,d1
	bmi.w	rtss
	btst	#sf2offsig,(sflags2).w
	bne.w	rtss			;player is offsides
CompShoot	;player a3 shoots (computer controlled player)
	addq.w	#4,sp			;don't return
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0	move.w	#$108,d1
	sub.w	d0,d1
	lsr.w	#3,d1
	cmp.w	#20,d1
	blt.w	.lt
	moveq	#$14,d1
.lt	move.w	d1,temp2(a3)		;temp2 = swing time
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
.dp0	moveq	#6,d0			;Set up pass assignment
	bsr.w	randomd0
	cmpi.w	#6,SCnum(a3)
	blt.w	.dp1
	addq.w	#6,d0
.dp1	tst.w	position(a3)			;from the goalie, or skaters
	beq.w	.bl			;outside the slot only
	cmpi.w	#$28,(puckx).w
	bgt.w	.bl
	cmpi.w	#$FFD8,(puckx).w
	blt.w	.bl
	cmpi.w	#$CC,(pucky).w
	bgt.w	rtss
	cmpi.w	#$FF34,(pucky).w
	blt.w	rtss
.bl	cmp.w	SCnum(a3),d0
	beq.w	rtss			;don't pass to yourself
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0
	tst.w	position(a0)
	ble.w	rtss			;don't pass to goalie or illegal player
	btst	#pf2unav,pflags2(a0)		;pf2unav
	bne.w	rtss
	btst	#pfalock,pflags(a0)
	bne.w	rtss			;don't pass to locked player
	move.w	Ypos(a0),d0		;check for pass across blue line
	move.w	Ypos(a3),d1
	btst	#7,pflags(a3)
	bne.w	.f0
	neg.w	d0
	neg.w	d1
.f0	btst	#gmoffs,(gmode).w
	beq.w	.oko
	movem.w	d0-d1,-(sp)
	subi.w	#$58,d0
	subi.w	#$58,d1
	eor.w	d0,d1
	movem.w	(sp)+,d0-d1
	bmi.w	rtss
.oko	cmp.w	#$58,d0		;blueline,d0
	bgt.w	.ok
	sub.w	d1,d0
	cmp.w	#-15,d0
	blt.w	rtss
.ok	move.w	(a0),d0
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
.co0	move.w	(a1),d0
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
.co1	adda.w	#SCstruct,a1
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
	btst	#5,(gmode).w		;with offsides on, don't skate
	beq.w	.x			;offside: go sideways near the blue line
	move.w	Ypos(a3),d1
	btst	#7,pflags(a3)
	bne.w	.y
	neg.w	d1
.y	subi.w	#$58,d1
	cmp.w	#10,d1
	bgt.w	.x
	cmp.w	#-50,d1
	blt.w	.x
	moveq	#2,d0
	move.w	(a3),d1
	cmp.w	(puckx).w,d1
	bgt.w	.x
	moveq	#6,d0
.x	rts

;======================================================================
;======================================================================
;	checkob, assnearest, check4check,
;	asspassrec, assshoot, pucknothing, puckfaceoff, ChkGoalies,
;	ReturnGoalies, CPgoalie, CompLine, puckfaceoff2, updatefaceoff,
;	Endfaceoff, pucknorm. Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	SortCords offsets in comments: Xpos 0, attribute 4
;	frame 6, Ypos $14, Zpos $18, Xvel $28, Yvel $2A, Zvel $2C,
;	position $34, assnum $36, asslist $38, temp1 $40, temp2 $42,
;	temp3 $44, temp4 $46, SCnum $52, facedir $54, SPA $58, nopuck $5E,
;	pflags $62 (pfdoff 0, pfna 1, pfnc 2, pfjoycon 3, pfalock 5,
;	pfteam 6, pfgoal 7), pflags2 $63 (pf2fight 0, pf2unav 2, pf2lcm 3),
;	aioff $6A, aggress $75.
;	Team struct (hmtmstruct, tmsize $1A2): tmscore $C, tmline $16,
;	tmsort $22 (word), tmap $24, tmgoalie $26, $2A = long,
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
.0	moveq	#$5C,d1			;blue line y (92 move blueline,d1)
	btst	#pfgoal,pflags(a3)
	bne.w	.top
	neg.w	d1
	cmp.w	(pucky).w,d1
	bgt.w	.nob
.bottom	tst.w	position(a0)
	bmi.w	.bn
	cmp.w	Ypos(a0),d1
	bgt.w	.ob
.bn	adda.w	#SCstruct,a0
	dbf	d0,.bottom
.nob	moveq	#$40,d0
	bclr	#sf2offsig,(sflags2).w
	bne.w	.dref
.ex	movem.l	(sp)+,d0-d1/a0
	rts

.ob	moveq	#6,d0			;(92 moveq #32,d0)
	bset	#sf2offsig,(sflags2).w
	bne.s	.ex
.dref	tst.w	(RefCnt).w
	bpl.s	.ex
	bsr.w	PushRef
	bra.s	.ex

.top	cmp.w	(pucky).w,d1
	blt.s	.nob
.top1	tst.w	position(a0)
	bmi.w	.tn
	cmp.w	Ypos(a0),d1
	blt.s	.ob
.tn	adda.w	#SCstruct,a0
	dbf	d0,.top1
	bra.s	.nob

assnearest	;this is a special assignment used for the player who is nearest the puck but doesn't have it. Assignment anearest ($11)
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp3(a3)
	move.w	#8,temp2(a3)
	clr.w	temp1(a3)
.nna	move.w	SCnum(a3),d1
	cmp.w	(puckc).w,d1
	bne.w	.nopc
	tst.w	position(a3)
	beq.w	assgoalie
	move.l	#$10,d0			;apuckc
	btst	#pfjoycon,pflags(a3)
	beq.w	assinsert
	rts
.nopc	sub.b	d7,temp1(a3)
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)
	clr.l	$2A(a2)			;team long, set to best distance below
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
.np	moveq	#-1,d2
	moveq	#5,d4
	movea.w	tmsort(a2),a0		;tmsort: first player of the team (92 from SCnum)
.de0	tst.w	position(a0)
	ble.w	.next
	tst.b	nopuck(a0)
	bne.w	.next
	btst	#pf2unav,pflags2(a0)		;pf2unav
	bne.w	.next
	move.w	assnum(a0),d0		;skip a player whose current assignment
	cmpi.b	#$13,asslist(a0,d0.w)	;is apassrec
	beq.w	.next
	move.l	a0,-(sp)
	bsr.w	GetHot
	add.w	(a0),d0
	sub.w	(puckx).w,d0
	add.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	move.w	(puckvx).w,d3		;always lead the puck (if carried)
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
.next	adda.w	#SCstruct,a0
	dbf	d4,.de0
	tst.l	d2
	bmi.w	.de1
	move.l	d2,$2A(a2)		;nearest distance^2
.switch	cmpa.w	a1,a3
	beq.w	.de1
	btst	#gmclock,(gmode).w
	bne.w	.de1
	btst	#pf2unav,pflags2(a1)		;pf2unav
	bne.w	.de1
	exg	a1,a3
	bclr	#pfdoff,pflags(a3)
	move.l	#$11,d0			;anearest
	bsr.w	assinsert
	exg	a1,a3
	bra.w	assexit
.de1	btst	#pfalock,pflags(a3)		;locked: skip
	bne.w	rtss
	moveq	#2,d1
	cmp.w	#$190,d2		;20^2,d2 (commented out in 92)
	bhi.w	.nfar
	subq.w	#2,d1
	cmpi.w	#2,position(a3)
	bls.w	.nodec			;close and position <= 2: no new temp3
.nfar	btst	#sf2pwrplay,(sflags2).w
	beq.w	.x
	subq.w	#2,d1
	bsr.w	chkpk2
	bne.w	.x			;not killing penalty
	addq.w	#4,d1
.x	moveq	#$14,d0
	sub.b	$75(a3),d0		;aggress
	asl.w	d1,d0
	bsr.w	randomd0
	cmp.w	#1,d0		;(92 #2)
	bhi.w	.nodec
	move.w	#$F0,temp3(a3)		;temp3 = 240
.nodec	btst	#pfalock,pflags(a3)		;locked: skip
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	btst	#2,tmflags(a2)		;tmflags bit 2 always takes the in-between spot
	bne.w	.mid
	tst.w	(puckc).w
	bmi.w	.topuck
	sub.w	d7,temp3(a3)
	bpl.w	.topuck
	clr.w	temp3(a3)
.mid	bsr.w	skatetopuckinit		;d0/d1 = halfway between
	movem.w	d0-d1,-(sp)		;skatetopuckinit's spot and (0,$F4),
	neg.w	d0			;or (0,-$F4) if pfgoal
	neg.w	d1
	addi.w	#$F4,d1
	btst	#pfgoal,pflags(a3)
	beq.w	.nd0
	subi.w	#$1E8,d1
.nd0	asr.w	#1,d0
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
.neg	cmp.w	#-$53,d1
	bgt.w	.go
	move.w	#-$44,d1
.go	lea	rtss(pc),a0
	bsr.w	skateto
	bra.w	check4check
.topuck	bsr.w	skatetopuck		;Falls into check4check

check4check	;look for good opportunity for checking opponent. Falls in from assnearest; also entered from assfwatch and asswingd
	moveq	#$14,d0
	sub.b	$75(a3),d0		;aggress
	tst.w	(OptPen).w
	beq.w	.nopen
	asl.w	#1,d0
.nopen	bsr.w	randomd0
	cmp.w	#3,d0		;(92 tst d0)
	bhi.w	rtss
	moveq	#5,d2
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.0
	adda.w	#6*SCstruct,a0
.0	tst.w	position(a0)
	beq.w	.next
	btst	#pfalock,pflags(a0)		;skip
	bne.w	.next
	btst	#pf2fight,pflags2(a0)		;skip
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
	move.w	(VDP_CNTR).l,d0		;HV counter as random, 1 in 4 is a
	andi.w	#3,d0			;hold/hook instead of a check
	bne.w	burst
	bra.w	Acheck
.next	adda.w	#SCstruct,a0
	dbf	d2,.0
	rts

asspassrec	;assignment for catching pass. Assignment apassrec ($13)
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	btst	#pfjoycon,pflags(a3)
	bne.w	assexit
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	bset	#pfdoff,pflags(a3)
	move.b	#8,temp2+1(a3)
	clr.b	temp2(a3)			;temp2 high byte
.nna	tst.w	(puckc).w
	bpl.w	.ex
	sub.b	d7,temp1(a3)		;puck loose: wait temp1 (92 bmi skatetopuck)
	bpl.w	rtss
.ex	bclr	#pfdoff,pflags(a3)
	bra.w	assexit
;unreferenced: skate to temp3/temp4
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	lea	rtss(pc),a0
	bra.w	skateto

assshoot	;assignment for computer shooting. Assignment ashoot ($12)
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	bra.w	SetShotMode
.nna	btst	#sfssdir,(sflags).w
	beq.w	assexit
	clr.w	d2			;(92 also loads temp1 into d0)
	sub.w	d7,temp2(a3)
	bpl.w	ShotMode
	bset	#5,d2			;cbut
	bra.w	ShotMode

pucknothing	;puck just slides along
	bra.w	puckunflip

puckfaceoff	;this is where the action starts
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	tst.w	(gameclock).w
	beq.w	PeriodOver
	btst	#6,(gmode).w		;gmode bit 6 also ends the period
	bne.w	PeriodOver
	cmpi.w	#3,(gsp).w
	bne.w	.npo
	move.w	(tmstruct+tmscore).w,d0
	cmp.w	(awtmstruct+tmscore).w,d0
	bne.w	clockcont_0
.npo	btst	#gmpendel,(gmode).w
	bne.w	Stop4Pen
	move.w	(PerTimeTotal).w,d0	;song $34 once, at the first faceoff
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
.rg	bsr.w	ReturnGoalies
	st	temp1(a3)
	st	temp2(a3)
	tst.w	(OptLine).w
	bne.w	.nna
	bclr	#1,(tmstruct+tmflags).w	;bit 1
	bclr	#1,(awtmstruct+tmflags).w	;bit 1
	movea.w	#(SortCords-M68K_RAM),a0	;clear pf2lcm on all 12 players
	moveq	#$B,d0
.lcm	bclr	#pf2lcm,pflags2(a0)
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
.nohor	move.w	(c1playernum).w,d0
	bmi.w	.nlp
	bsr.w	.slc
.nlp	move.w	(c2playernum).w,d0
	bmi.w	.nlp2
	bsr.w	.slc
.nlp2	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	moveq	#2,d0
	bsr.w	.sclc
	bra.w	.nna

.sclc	tst.w	(OptLine).w
	bne.w	rtss
	cmp.w	(cont1team).w,d0
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	bsr.w	CompLine
	bsr.w	setpersonel
	bra.w	printscores1

.slc	exg	a2,a3
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	bclr	#pf2lcm,pflags2(a3)		;pf2lcm
	move.l	a2,-(sp)
	bsr.w	SetLCmode
	movea.l	(sp)+,a2
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	beq.w	.slcex
	btst	#pfteam,pflags(a3)
	beq.w	.t1
	move.w	#$168,temp2(a2)		;temp2 = 6*60 (92 3*60)
	move.w	SCnum(a3),temp4(a2)		;temp4 = SCnum
	bra.w	.slcex
.t1	move.w	#$258,temp1(a2)		;temp1 = 10*60 (92 5*60)
	move.w	SCnum(a3),temp3(a2)		;temp3 = SCnum
.slcex	exg	a2,a3
	rts
.nna	move.w	#$40,d0			;temp1
	bsr.w	.clc
	move.w	#$42,d0			;temp2
	bsr.w	.clc
	tst.w	temp1(a3)
	bpl.w	rtss
	tst.w	temp2(a3)
	bpl.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.sclc
	move.w	#$1C,d0			;pfaceoff2
	bra.w	assreplace

.clc	tst.w	(a3,d0.w)
	bmi.w	rtss
	move.w	4(a3,d0.w),d1		;temp3/temp4 = SCnum
	asl.w	#7,d1
	movea.w	#(SortCords-M68K_RAM),a0
	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = his team for SetLCmode2
	btst	#pfteam,pflags(a0,d1.w)
	beq.w	.clh
	adda.w	#tmsize,a2
.clh	btst	#pf2lcm,pflags2(a0,d1.w)		;pf2lcm
	bne.w	.clnd
	st	(a3,d0.w)
	bra.w	SetLCmode2		;redraw lc box
.clnd	sub.w	d7,(a3,d0.w)
	bpl.w	rtss
	move.l	a3,-(sp)
	lea	(a0,d1.w),a3
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	beq.w	.clcex
	clr.w	d2
	bsr.w	lcfound
	bsr.w	SetLCmode2		;redraw the line change box
.clcex	movea.l	(sp)+,a3
	rts

ChkGoalies	;computer pulls goalie on delayed penalty. Called from periodicevents
	btst	#gmclock,(gmode).w
	bne.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.CPG
	moveq	#2,d0
	exg	a1,a2
.CPG	tst.w	tmgoalie(a2)			;tmgoalie already out
	bmi.w	rtss
	move.w	(puckc).w,d1
	bmi.w	rtss
	subq.w	#6,d1
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.0
	not.w	d1			;(92 neg)
.0	tst.w	d1
	bpl.w	rtss			;exit unless team a2 has the puck
	btst	#gmpendel,(gmode).w
	beq.w	.cp
	st	tmgoalie(a2)			;pull goalie (92 move #2,tmgoalie), any team
	bra.w	setpersonel
.cp	cmp.w	(cont1team).w,d0	;rest is CPG for computer teams
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	move.w	(pucky).w,d1
	bra.w	CPgoalie

ReturnGoalies	;if computer pulled goalie, look to see if computer should return him. Called from puckfaceoff
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.r
	moveq	#2,d0
	exg	a1,a2
.r	cmpi.w	#-1,tmgoalie(a2)		;tmgoalie $FFFF stays out
	beq.w	rtss
	clr.b	tmgoalie(a2)			;return goalie
	cmp.w	(cont1team).w,d0
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	move.w	(foy).w,d1

CPgoalie	;see if computer should pull his goalie. d1 = puck/faceoff y. Falls in from ReturnGoalies; also entered from ChkGoalies
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
.0	tst.w	d1
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
.0	move.w	d0,-(sp)		;find pk/pwr line
	bsr.w	getlinee
	move.w	d0,d1
	move.w	(sp),d0
	addq.w	#1,d0
	bsr.w	getlinee
	cmp.w	d0,d1
	bge.w	.1
	addq.w	#1,(sp)
.1	move.w	(sp)+,tmline(a2)
.ex	movem.l	(sp)+,d0-d2/a0
	rts

.nopwr	cmpa.w	#(tmstruct-M68K_RAM),a2	;find normal line
	bne.w	.away
	moveq	#2,d1
	lea	.hl1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.h0
	move.w	tmscore(a2),d2
	cmp.w	tmscore(a1),d2
	beq.w	.h0
	adda.w	#$E,a0
	bgt.w	.h0
	adda.w	#$E,a0
.h0	move.w	tmline(a1),d1
	asl.w	#1,d1
	move.w	(a0,d1.w),d0
	bsr.w	getlinee
	cmp.w	#3*$1000/4,d0
	bls.w	.away
	move.w	(a0,d1.w),tmline(a2)
	bra.s	.ex

.hl1	dc.w	0,1,2,0,1,0,1
	dc.w	2,0,1,2,0,2,0
	dc.w	0,1,0,0,1,0,1

.away	moveq	#2,d1
	lea	.al1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.a0
	move.w	tmscore(a2),d2
	cmp.w	tmscore(a1),d2
	beq.w	.a0
	addq.w	#6,a0
	bgt.w	.a0
	addq.w	#6,a0
.a0	move.w	(a0)+,d0
	bsr.w	getlinee
	cmp.w	#3*$1000/4,d0		;(92 19*$1000/20)
	dbhi	d1,.a0
	move.w	-(a0),tmline(a2)
	bra.w	.ex

.al1	dc.w	0,1,2
	dc.w	0,2,1
	dc.w	0,1,0

puckfaceoff2	;face off control logic and general setup for action
	bclr	#pfna,pflags(a3)
	beq.w	.nna			;not first time thru
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
.p	btst	#dfok,(disflags).w
	bne.s	.p			;wait for vblank
	cmpi.w	#$258,(crowdlevel).w
	bls.w	.ntm
	move.w	#$258,(crowdlevel).w	;limit crowd level
.ntm	bset	#dfclock,(disflags).w		;stop clock
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
	st	(passReceiverPlayerNum).w	;no pass receiver
	bset	#4,(disflags).w		;cleared again in updatefaceoff
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
	clr.w	(SortCords+(puckscnum*SCstruct)+attribute).w
	bclr	#sfslock,(sflags).w		;free up scrolling
	moveq	#$64,d4
.cw	bsr.w	checkwindow		;scroll to faceoff spot
	dbf	d4,.cw
	move.w	#$3C,(yleader).w
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	adda.w	#tmsize,a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	bsr.w	resetplstuff
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d2
.l0	move.w	#-$F0,(a3)		;Xpos = -240
	clr.w	Ypos(a3)
	clr.w	frame(a3)
	move.w	position(a3),d1
	bmi.w	.next
	beq.w	.goalie1
	move.l	#$16,d0			;afaceoff
	cmp.w	#4,d1
	bne.w	.l1
	movea.w	#(tmstruct-M68K_RAM),a2	;faceoff man resets team $18-$1C
	btst	#pfteam,pflags(a3)
	beq.w	.tm
	adda.w	#tmsize,a2
.tm	clr.w	$18(a2)
	move.b	pnum(a3),$19(a2)
	st	$1A(a2)
	st	$1C(a2)
	bclr	#3,tmflags(a2)		;tmflags bit 3
	move.l	#$17,d0			;afaceoffpl
.l1	bsr.w	assinsert
.goalie1	move.w	(tmstruct+tmap).w,d4
	btst	#pfteam,pflags(a3)
	beq.w	.t0
	move.w	(awtmstruct+tmap).w,d4
.t0	neg.w	d4
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
.f0	tst.w	position(a3)
	beq.w	.goalie2
	cmp.w	#2*4,d4
	bgt.w	.nodef
	move.w	(fox).w,d3
	eor.w	d0,d3
	bpl.w	.notmid
	move.w	(foy).w,d3
	asr.w	#3,d3
	sub.w	d3,d1
.notmid	move.w	(fox).w,d3
	asr.w	#2,d3
	sub.w	d3,d0
.nodef	add.w	(fox).w,d0
	add.w	(foy).w,d1
.goalie2	move.w	d0,(a3)			;Xpos
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	neg.w	d0
	neg.w	d1
	bsr.w	vtoa
	move.w	d0,facedir(a3)
	bclr	#pf2unav,pflags2(a3)		;pf2unav
	bclr	#pfalock,pflags(a3)
	move.w	#$52C,d1		;SPAglide
	bsr.w	SetSPA
.next	adda.w	#$80,a3
	dbf	d2,.l0
	bsr.w	SprSort
	movea.l	(sp)+,a3
	bsr.w	ResetAndSelectPlayers
	bsr.w	printz
	String	$FF,0,0
	moveq	#$36,d0			;8+46
	tst.w	(fox).w
	bpl.w	.fok
	move.w	#$BE,d0			;(18*8)+46
.fok	move.w	d0,(fodropx).w
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
	movea.l	#FaceOffSprites+8,a2	;replaces /DoDMA
	bsr.w	DoDMA_clearCallbackPointer
	tst.w	(OptLine).w		;line names box when lines are on
	bne.w	.nol
	bsr.w	printsmallz
	String	CC_AddY,$A,CC_SetAttribute,4
	moveq	#$C,d0
	moveq	#3,d1
	bsr.w	Framer
	move.w	(tmstruct+tmline).w,d0
	move.w	(awtmstruct+tmline).w,d1
	btst	#gmdir,(gmode).w
	bne.w	.nx
	exg	d0,d1
.nx	bsr.w	printsmallz
	String	$FB,1,$FA,$FE
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
	addq.w	#4,(printx).w
	move.w	d1,d0
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
.nol	move.w	#$78,d0
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
.nfl	move.w	#-1,(fodir1).w
	move.w	#-1,(fodir2).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.nna	subq.w	#1,temp1(a3)		;(92 sub d7)
	bpl.w	updatefaceoff
	bra.w	Endfaceoff

.apl
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

ResetAndSelectPlayers	;c1playernum/c2playernum = -1, then changeplayer for each human team. Called from puckfaceoff2
	move.w	#-1,(c1playernum).w
	move.w	#-1,(c2playernum).w
	tst.w	(cont1team).w
	beq.w	.nt1
	clr.w	d4
	bsr.w	changeplayer
.nt1	tst.w	(cont2team).w
	beq.w	.nt2
	moveq	#2,d4
	bsr.w	changeplayer
.nt2	rts

updatefaceoff	;a3 = puck. Drop animation frame from temp1; at 0 erases the faceoff box (92 did that in Endfaceoff). Entered from puckfaceoff2
	move.w	temp1(a3),d0
	beq.w	.erase
	addq.w	#6,d0
	lsr.w	#3,d0
	cmp.w	#2,d0
	bgt.w	rtss
	neg.w	d0
	addi.w	#$A,d0
	move.w	d0,(fofdata).w		;+8
	rts
.erase	bclr	#4,(disflags).w
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
	move.w	#SFXpuckice+3,-(sp)		;SFXpuckice
	bsr.w	sfx
	bclr	#sf2faceoff,(sflags2).w
	move.w	(ExtraChars).w,d4
	movea.l	#RefsMap+8,a2
	bsr.w	DoDMA_clearCallbackPointer	;ref cam chars
	bclr	#sf2drec,(sflags2).w
	bclr	#gmclock,(gmode).w
	bclr	#pf2fight,pflags2(a3)
	bset	#4,(sflags3).w		;flag the faceoff drop
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
.p1won	btst	#3,2(a1)
	beq.w	.pos
	move.w	(fodir2).w,d3
	neg.w	d4
.pos	move.w	d3,d0
	btst	#3,d0
	bne.w	.nojoy
	andi.w	#7,d0
	move.w	(VDP_CNTR).l,d1		;hvcount
	andi.w	#3,d1
	bne.w	.nj2
.nojoy	moveq	#5,d0
	bsr.w	randomd0
	subq.w	#2,d0
	andi.w	#7,d0
	tst.w	d4
	bmi.w	.nj2
	eori.w	#4,d0
.nj2	asl.w	#2,d0
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
	move.w	#$78,temp2(a3)		;temp2 = still puck timer
.nna	movea.w	#(puckcross-M68K_RAM),a1	;table for puck crossing lines
	sub.w	d7,2(a1)		;sub elapse frames from time til crossing
	sub.w	d7,6(a1)
	sub.w	d7,temp1(a3)
	bpl.w	.0
	addq.w	#5,temp1(a3)
	bsr.w	findpc
.0	move.w	(puckc).w,d0
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
.nothandled	bsr.w	puckIChk
	bsr.w	ChkOffsides
	btst	#0,(gmode).w		;loose puck that has not moved
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
.np	bra.w	.z
.mv	move.w	#$78,temp2(a3)		;reset still puck timer
.z	tst.b	Zvel(a3)
	bne.w	checkpuckcoll
	tst.w	Zpos(a3)
	bne.w	checkpuckcoll
	bsr.w	puckunflip
	bra.w	checkpuckcoll

;======================================================================
;======================================================================
;	ChkOffsides, a2offsides, a2touchpuck,
;	PuckIChk, puckunflip, puckflip, puckshadow, findpc, skateto, avdgoal,
;	skatetopuck, assexit, assinsert, assreplace, vtoa, GetHot, SetSPA,
;	doplayeracc, goalieacc, noturn0, noturn, playeracc, MaxSpeed, dostop,
;	stopna, dirtab, UnpackNibbles and WeightedRandomSelect. Bytes
;	match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	SortCords offsets in comments: Xpos 0, attribute 4
;	frame 6, Ypos $14, Zpos $18, OldYpos $20, Xvel $28, Yvel $2A,
;	position $34, assnum $36, asslist $38, temp2 $42, wallcos $4E,
;	wallsin $50, SCnum $52, facedir $54, SPA $58, SPAnum $5A, SPAcnt $5C,
;	pflags $62 (pfna 1, pfrev 4, pfteam 6, pfgoal 7), pflags2 $63
;	(pf2fight 0, pf2aip 1), pnum $66, weight $67, legstr $68, legspd $69.
;	Team struct (hmtmstruct, tmsize $1A2): $18/$1A/$1C last touches,
;	tmsort $22, tmap $24, tmflags $30 (bit 4 = team offsides).
;	iflags: ifcgl 0, ifdir 1, ifok 2; icingPlayer = +1.

ChkOffsides	;check for offsides penalty. a3 = puck. Flags the whole team (tmflags bit 4; 92 flagged each player). Called from pucknorm
	btst	#gmoffs,(gmode).w
	beq.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a1
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
.t0	moveq	#5,d2
	movea.w	tmsort(a2),a0		;tmsort: first player of the team
.0	tst.w	position(a0)			;position: skip off ice
	bmi.w	.1
	cmp.w	Ypos(a0),d0
	bge.w	.1
	bset	#4,tmflags(a2)		;player past the line: team offsides
	rts
.1	adda.w	#SCstruct,a0
	dbf	d2,.0
	rts

.neg	neg.w	d0
	cmp.w	Ypos(a3),d0
	blt.w	rtss
	cmp.w	OldYpos(a3),d0		;OldYpos: puck crossed the bottom line this frame?
	bge.w	rtss
	subi.w	#$A,d0
	btst	#gmdir,(gmode).w
	bne.w	.t1
	exg	a2,a1
.t1	moveq	#5,d2
	movea.w	tmsort(a2),a0
.2	tst.w	position(a0)
	bmi.w	.3
	cmp.w	Ypos(a0),d0
	ble.w	.3
	bset	#4,tmflags(a2)		;team offsides
	rts
.3	adda.w	#SCstruct,a0
	dbf	d2,.2
	rts

ClearOffsidesIfAllPlayers	;a2 = team struct. Clears the team offsides flag (tmflags bit 4) once no skater on ice is past the blue line ($58, sign by pfgoal). Called twice from ChkOffsides
	btst	#4,tmflags(a2)
	beq.w	rtss
	movea.w	tmsort(a2),a0
	moveq	#5,d1
.top	tst.w	position(a0)			;position: off ice keeps the last d0
	bmi.w	.next
	move.w	Ypos(a0),d0
	btst	#pfgoal,pflags(a0)
	bne.w	.next
	neg.w	d0
.next	adda.w	#SCstruct,a0
	cmp.w	#$58,d0		;(blueline)
	dbgt	d1,.top
	bgt.w	rtss			;someone still past the line
	bclr	#4,tmflags(a2)
	rts

a2offsides	;player a2 touched the puck: offsides penalty if his team is flagged and the puck is past the blue line. Called from a2touchpuck
	btst	#gmoffs,(gmode).w
	beq.w	rtss
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a2)
	bne.w	.0
	neg.w	d0
.0	cmp.w	#$58,d0		;(92 cmp blueline,d0)
	blt.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a2)
	beq.w	.1
	adda.w	#tmsize,a0
.1	btst	#4,tmflags(a0)		;team offsides flag
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
	movea.w	#(tmstruct-M68K_RAM),a0	;keep the last three touches per team
	btst	#pfteam,pflags(a2)
	beq.w	.t
	lea	tmsize(a0),a0
.t	clr.w	d0
	move.b	pnum(a2),d0
	cmp.w	$18(a0),d0		;same player as the last touch: no change
	beq.w	.same
	bclr	#3,tmflags(a0)		;tmflags bit 3 set: overwrite the last touch only
	bne.w	.st
	move.w	$1A(a0),$1C(a0)		;shift the touch list down
	move.w	$18(a0),$1A(a0)
.st	move.w	d0,$18(a0)
	cmp.w	$1C(a0),d0
	bne.w	.same
	st	$1C(a0)			;player was also the third touch: drop it
.same	bclr	#sf2shot,(sflags2).w
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
.icing	clr.w	d0
	move.b	(icingPlayer).w,d0	;+1
	asl.w	#7,d0			;scsize
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.w	#$C,d0			;PenIcing
	bsr.w	AddPenalty
	movea.l	(sp)+,a3
	rts
.up	btst	#pfgoal,pflags(a2)
	beq.s	.icing
.notice	clr.b	(iflags).w
	move.b	SCnum+1(a2),(icingPlayer).w
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a2)
	beq.w	.0
	bset	#1,(iflags).w		;ifdir
	neg.w	d0
.0	bmi.w	rtss
	move.w	(tmstruct+tmap).w,d0
	sub.w	(awtmstruct+tmap).w,d0
	btst	#pfteam,pflags(a2)
	beq.w	.1
	neg.w	d0
.1	bmi.w	rtss
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
.0	cmp.w	(pucky).w,d0
	bgt.w	rtss
.chkx	cmpi.w	#$2C,(puckx).w		;|puckx| <= $2C at the goal line
	bgt.w	.set
	cmpi.w	#-$2C,(puckx).w
	blt.w	.set
	bclr	#2,(iflags).w		;ifok cleared: no icing
	rts
.set	bset	#0,(iflags).w		;ifcgl
	rts

puckunflip	;stop spinning puck. a3 = puck. Entered from pucknothing, called from pucknorm
	cmpi.w	#8,SPAnum(a3)		;2*4 SPAnum
	blt.w	.k
	cmpi.w	#$18,SPAnum(a3)		;6*4
	bge.w	.k
	eori.w	#2,facedir(a3)
.k	ori.w	#4,facedir(a3)
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
.nhor	addq.w	#1,(a3,d0.w)
	rts

.siren	tst.w	frame(a3)
	beq.w	rtss
	clr.w	(a3)			;Xpos
	move.w	#$12C,Ypos(a3)		;Ypos 300
	move.w	#$E,Zpos(a3)		;Zpos 14
	tst.w	Ypos-SCstruct(a3)
	bpl.w	.s0
	move.w	#$8000,attribute(a3)
	neg.w	Ypos(a3)
	subq.w	#1,Zpos(a3)
.s0	rts

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
.calc	move.w	d4,d0
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
.o1	neg.w	d1
	cmp.w	d1,d0
	bgt.w	.o2
	neg.w	d0
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
.o2	neg.w	d1
	move.w	d0,(a1)
	bra.w	.next
.nocross	move.w	#-1,2(a1)
.next	addq.w	#4,a1
	rts

skateto	;a0 = extra routine for collision avoidance, d0/d1 = x/y cord to skate to, d7 = elapse frames
	sub.b	d7,temp2(a3)
	bpl.w	.ex
	addi.b	#$C,temp2(a3)		;only execute every 12/60 sec.
	bsr.w	avdgoal
	movem.w	d0-d1,-(sp)		;no deltax/deltay test
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
.vt	bsr.w	vtoa
.nvt	jsr	(a0)
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
.nf	sub.w	(a3),d0
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
.ex	clr.w	d0
	move.b	temp2+1(a3),d0
	bra.w	doplayeracc

avdgoal	;don't try to skate thru goal: if d0/d1 cords intersect thru goal then provide new d0/d1 cords. a3 = player. .gl 254 ($FE), .yr/.ye 35 (92 258/30/30), .xr 80
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
.1	move.w	#$B8,d3			;gl-.yr-.ye
.2	sub.w	d2,d3
	move.w	d3,(deltay).w
	bra.w	.chbar

.lower	cmp.w	#-$DB,d2		;-.gl+.yr,d2
	bgt.w	.chbar
	cmp.w	#-$121,d2		;-.gl-.yr,d2
	blt.w	.chbar
	move.w	#-$B8,d3		;-.gl+.yr+.ye
	cmp.w	#-$FE,d2		;-.gl,d2
	bgt.w	.4
	blt.w	.3
	cmpi.w	#-$FE,Ypos(a3)
	bgt.w	.4
.3	move.w	#-$144,d3		;-.gl-.yr-.ye
.4	sub.w	d2,d3
	move.w	d3,(deltay).w

.chbar	move.w	d1,d3
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

.ch1	move.w	d3,d4
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
.ch2	bpl.w	.ch3
	neg.w	d3
.ch3	sub.w	d4,d3
	move.w	d3,(deltax).w
	rts

skatetopuckinit	;d0/d1 = puck x/y plus half the high byte of its velocity. Called from skatetopuck and assnearest
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
	tst.w	position(a3)			;goalie skips the sweep check
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
.ex	move.b	temp2+1(a3),d0
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
.0	tst.w	d1
	bpl.w	.1
	neg.w	d1
	bset	#1,d2
.1	asl.w	#1,d1
	cmp.w	d1,d0
	bhi.w	.2
	bset	#2,d2
.2	lsr.w	#1,d1
	asl.w	#1,d0
	cmp.w	d0,d1
	bhi.w	.3
	bset	#3,d2
.3	movea.l	#.dt,a0
	clr.w	d0
	move.b	(a0,d2.w),d0
	movem.l	(sp)+,d2/a0
	rts

.nodir	moveq	#8,d0
	movem.l	(sp)+,d2/a0
	rts

.dt	dc.b	1,7,3,5,0,0,4,4
	dc.b	2,6,2,6,1,7,3,5

GetHot	;push long address of structure to get hot spot from. Hot spot x/y returned in d0/d1. Reads a byte pair per frame from HotList
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
.nox	btst	#4,attribute(a0)
	bne.w	.noy
	neg.w	d1
.noy	btst	#sfhor,(sflags).w
	beq.w	.nhor
	exg	d0,d1
	neg.w	d1
.nhor
.ex	movem.l	(sp)+,a0-a1
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
.d0	andi.w	#$F,d0
	cmp.w	#7,d0
	ble.w	.d1
	cmp.w	#9,d0
	bne.w	.cgl
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	bne.w	dostop
.cgl	btst	#pf2aip,pflags2(a3)
	beq.s	SetSPA
	rts

.d1	movem.w	d0-d1,-(sp)
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
.c1	btst	#pfrev,pflags(a3)
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
.inrev	subq.w	#3,d2
	andi.w	#7,d2
	cmp.w	#2,d2
	bhi.w	.fwd
	bsr.w	vtoa
	addq.w	#2,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	bhi.w	.fwd

.rev	btst	#pfrev,pflags(a3)
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
.setrev	bset	#pfrev,pflags(a3)
	bra.w	.done

.fwd
.clrrev	bclr	#pfrev,pflags(a3)

.done	movem.w	(sp)+,d0-d1
	move.w	facedir(a3),d2
	sub.w	d2,d0
	andi.w	#7,d0
	movea.l	#.ftab,a0
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
.iok	muls.w	(a0,d0.w),d4
	btst	#pfrev,pflags(a3)
	beq.w	.i0
	neg.l	d4
.i0	add.l	d4,facedir(a3)
	andi.w	#7,facedir(a3)
	move.w	facedir(a3),d2

	cmp.w	#20,d3
	bls.w	.s3

	clr.w	d1
	tst.w	(a0,d0.w)
	bpl.w	.s1
	eori.w	#-$32,d1		;SPAturnl-SPAturnr
.s1	btst	#3,attribute(a3)
	beq.w	.s2
	eori.w	#-$32,d1		;SPAturnl-SPAturnr
.s2	addi.w	#$6B4,d1		;SPAturnr
	bset	#pf2aip,pflags2(a3)
.s3	bsr.w	SetSPA

	cmp.w	#2,d3
	bhi.w	noturn
	rts

.ftab	dc.w	0,$10,$10,$10,0,-$10,-$10,-$10

goalieacc	;goalie gets acc. in direction d0. Turns facedir one step toward d0 (92 set it directly)
	move.w	#2,d1			;SPAgready
	andi.w	#$F,d0
	cmp.w	#7,d0
	ble.w	.d1
	cmp.w	#9,d0
	bne.w	.cgl
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	bne.w	StopNA
.cgl	btst	#pf2aip,pflags2(a3)
	beq.w	SetSPA
	rts
.d1	sub.w	facedir(a3),d0
	beq.w	.spa
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
.spa	move.w	#$3F8,d1		;SPAgskate
	bsr.w	SetSPA
	move.w	facedir(a3),d2
	bra.w	playeracc

noturn0	;doplayeracc when the wanted direction needs no turn (.ftab entry 0). d0 = direction minus facedir, times 2
	moveq	#2,d4
	btst	#pfrev,pflags(a3)
	beq.w	.0
	addq.w	#4,d4
	eori.w	#8,d0
.0	tst.w	d0
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

.nostop	addq.w	#1,facedir(a3)
	btst	#3,attribute(a3)
	beq.w	.nos0
	subq.w	#2,facedir(a3)
.nos0	andi.w	#7,facedir(a3)
	move.w	#$52C,d1		;SPAglide
	btst	#pfrev,pflags(a3)
	beq.w	SetSPA
	move.w	#$A80,d1		;SPAglideback
	bra.w	SetSPA

.nochg	move.w	#$AB2,d1		;SPAskateback
	btst	#pfrev,pflags(a3)
	bne.w	.ns
	move.w	#$5F0,d1		;SPAskate
	btst	#6,pflags2(a3)		;pflags2 bit 6 uses animation $13A0
	beq.w	.nb6
	move.w	#$13A0,d1
.nb6	move.w	(puckc).w,d4
	cmp.w	SCnum(a3),d4
	bne.w	.ns
	move.w	#$55E,d1		;SPAskatewp
.ns	btst	#pf2aip,pflags2(a3)
	bne.w	noturn
	bsr.w	SetSPA

noturn	;reverse the acc. direction when skating backwards, then falls into playeracc. Entered from doplayeracc and noturn0
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
.nox	move.w	Wallcos(a3),d2
	beq.w	.noy
	eor.w	d1,d2
	bmi.w	.noy
	clr.w	d1
.noy	clr.w	d2
	move.b	weight(a3),d2
	lsr.w	#3,d2			;(92 lsr #4)
	neg.w	d2
	addi.w	#$20,d2			;32
	add.b	legstr(a3),d2
	tst.w	position(a3)
	bne.w	.ng
	add.b	legstr(a3),d2		;goalie adds legstr twice plus 8
	addq.w	#8,d2

.ng	muls.w	d2,d0
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
	btst	#6,pflags2(a3)		;pflags2 bit 6 cuts max speed to 1/8
	beq.w	.ms
	lsr.l	#3,d2
.ms	movem.w	(sp)+,d0-d1

	cmp.l	d2,d3			;max speed check
	bhi.w	.sube
	move.w	d0,Xvel(a3)
	move.w	d1,Yvel(a3)

.sube	tst.w	(OptLine).w
	bne.w	rtss
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#$7F,d0
	bne.w	rtss
	bsr.w	getpde
	subi.w	#$21,d0			;33
	cmp.w	#$C00,d0
	blt.w	setpde
	move.b	endurance(a3),d2
	ext.w	d2
	add.w	d2,d0
	bra.w	setpde

MaxSpeed	;max speed values for each rating level 0-f. ((n+20)*275)^2 (92 used 250)
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

dostop	;player a3 stops. Entered from doplayeracc and noturn0
	cmpi.w	#$1000,Xvel(a3)		;.slim Xvel
	bgt.w	.set
	cmpi.w	#-$1000,Xvel(a3)
	blt.w	.set
	cmpi.w	#$1000,Yvel(a3)
	bgt.w	.set
	cmpi.w	#-$1000,Yvel(a3)
	blt.w	.set
	bra.w	StopNA			;stop with no anim
.set	move.w	#$52C,d1		;SPAglide
	btst	#pfrev,pflags(a3)
	bne.w	.0
	bset	#pf2aip,pflags2(a3)
	move.w	#$6E6,d1		;SPAstop
.0	bsr.w	SetSPA
StopNA	;slow player a3 by 150 on each axis, no animation change. Falls in from dostop, also entered from goalieacc and others
	tst.w	Xvel(a3)
	bpl.w	.xp
	addi.w	#$96,Xvel(a3)		;150
	bmi.w	.y
	clr.w	Xvel(a3)
.xp	subi.w	#$96,Xvel(a3)
	bpl.w	.y
	clr.w	Xvel(a3)
.y	tst.w	Yvel(a3)
	bpl.w	.yp
	addi.w	#$96,Yvel(a3)
	bmi.w	rtss
	clr.w	Yvel(a3)
.yp	subi.w	#$96,Yvel(a3)
	bpl.w	rtss
	clr.w	Yvel(a3)
	rts

dirtab	;x,y speed for each direction 0-7
	dc.w	0,200
	dc.w	141,141
	dc.w	200,0
	dc.w	141,-141
	dc.w	0,-200
	dc.w	-141,-141
	dc.w	-200,0
	dc.w	-141,141

UnpackNibbles	;a0 = packed data, d0 = count. Unpacks d0 4-bit values (high nibble first) into words at nibblebuffer. Called from UpdateTeamNameisplay
	movem.l	d0-d2/a0-a1,-(sp)
	movea.w	#(nibblebuffer-M68K_RAM),a1
	clr.w	d2
	bra.w	.next
.loop	move.b	(a0)+,d1
	bchg	#0,d2			;toggle high/low nibble
	bne.w	.lo
	subq.w	#1,a0			;high nibble: read the same byte again next time
	lsr.w	#4,d1
.lo	andi.w	#$F,d1
	move.w	d1,(a1)+
.next	dbf	d0,.loop
	movem.l	(sp)+,d0-d2/a0-a1
	rts

WeightedRandomSelect	;d0 = number of word weights at nibblebuffer. Return d0 = random index, picked with those weights. Called from SetScore_getscore and UpdateTeamNameisplay
	movem.l	d1/a1,-(sp)
	movea.w	#(nibblebuffer-M68K_RAM),a1
	clr.w	d1
	bra.w	.next
.sum	add.w	(a1)+,d1
.next	dbf	d0,.sum
	move.w	d1,d0			;d0 = total weight
	bsr.w	randomd0
.find	sub.w	-(a1),d0		;walk back from the last weight
	bpl.s	.find
	suba.w	#(nibblebuffer-M68K_RAM),a1
	move.w	a1,d0
	lsr.w	#1,d0			;word offset -> index
	movem.l	(sp)+,d1/a1
	rts
