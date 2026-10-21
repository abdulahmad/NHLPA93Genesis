;	Player logic. Turns controller input into skater actions (passing, shooting, checking, line changes) and
;	runs the computer players, with an assignment per position and for the goalie, fights, bench and penalty
;	box. Also the puck at faceoffs, offsides and icing.
;
;	Conventions: a3 = the object being processed (a SortCords entry, player or puck), d7 = frames elapsed,
;	a2 = team struct (tmstruct, +tmsize for the visitors). Most routines exit through rtss. Field and flag
;	names (pf*, sf*, tm*, temp1-5, SPA*) are in ram93.asm.

doinput								;process controller input
									;d0 = dpad
									;d1 = new buttons
									;d2 = changed buttons
									;d3 = held buttons
									;d4 = controller 0/2
	bsr.w	setpads					;set cordinates for stars
	btst	#7,d1					;start button
	beq.w	.0
	tst.w	d4
	beq.w	startpause1
	bra.w	startpause2
	;not start: in horizontal screen mode rotate the dpad direction (d0, 0-7) by 2 (90 degrees)
.0	btst	#sfhor,(sflags).w		;is screen in horizontal mode
	beq.w	.nhor
	btst	#3,d0
	bne.w	.nhor
	addq.w	#2,d0					;add 90 degrees if in horizontal mode
	andi.w	#7,d0
.nhor	btst	#sf2faceoff,(sflags2).w	;d0 = dpad direction; faceoff in progress takes over all input
	bne.w	faceoffinput
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	bne.w	lineinput				;line change interface on
	;only a joystick-controlled player reacts below; locked animation (pfalock) only allows a player switch
	btst	#pfjoycon,pflags(a3)
	beq.w	rtss					;no joystick cont so exit
	btst	#pfalock,pflags(a3)
	bne.w	.islocked
	;fighting: punch controls
	btst	#pf2fight,pflags2(a3)
	bne.w	fightinput				;fighting in progress
	;puck carrier? (puckc = SCnum of the puck handler)
	move.w	(puckc).w,d5
	cmp.w	SCnum(a3),d5
	beq.w	.ispc					;player is puck carrier
	;not the carrier: abut = hold/hook, bbut = switch player, cbut = burst/check, else just skate
	btst	#abut,d1				;abut
	bne.w	Holdplayer				;hold button
	btst	#bbut,d1				;bbut, is not puck c
	bne.w	changeplayer			;switch players
	tst.w	position(a3)
	beq.w	rtss					;goalie can't check
	btst	#cbut,d1				;cbut
	bne.w	burst					;burst/check
	bra.w	doplayeracc				;no button, just dpad input
.ispc	bsr.w	checkob				;Player is puck handler
	tst.w	position(a3)
	bne.w	.pc1
	btst	#pf2aip,pflags2(a3)		;goalie
	bne.w	rtss
	;puck carrier: sflags pass/shot direction modes first, then bbut = pass, abut = line change, cbut = shot
.pc1	btst	#sfspdir,(sflags).w	;carrier: a pass/shot direction mode already open?
	bne.w	passmode
	btst	#sfssdir,(sflags).w
	bne.w	ShotMode
	btst	#bbut,d1				;bbut
	bne.w	setpassmode
	btst	#abut,d1				;abut
	bne.w	SetLCmode
	tst.w	position(a3)
	beq.w	rtss					;exit if goalie
	btst	#cbut,d1				;cbut
	bne.w	SetShotMode
	bra.w	doplayeracc
.islocked	move.w	(puckc).w,d5	;Animation is locked /don't interupt it/
	cmp.w	SCnum(a3),d5
	beq.w	rtss
	btst	#bbut,d1				;bbut, is not puck handler
	bne.w	changeplayer
	rts

faceoffinput						;controller processing for faceoff
									;only a player with the afaceoffpl assignment takes part in the draw
	move.w	assnum(a3),d4
	cmpi.b	#afaceoffpl,asslist(a3,d4.w)	;afaceoffpl
	bne.w	rtss					;exit if this is not a faceoff player
	;a0 = fodir1 (pfgoal clear) or fodir2: this player pull direction
	movea.w	#(fodir1-M68K_RAM),a0	;faceoff direction of puck controll variable
	btst	#pfgoal,pflags(a3)
	beq.w	.2
	movea.w	#(fodir2-M68K_RAM),a0
.2	move.w	d0,(a0)					;Store dpad for faceoff pull
	btst	#pf2aip,pflags2(a3)
	bne.w	rtss
	;bbut swings at the puck (once: pf2aip marks it); otherwise ready stance
	btst	#bbut,d1				;bbut
	beq.w	.1
	move.w	#SPAfaceoff,d1
	bset	#pf2aip,pflags2(a3)
	bra.w	SetSPA
.1	move.w	#SPAfaceoffr,d1			;no bbut: stay in the ready animation
	bra.w	SetSPA

fightinput							;controller processing for fighting
	tst.w	temp3(a3)
	bmi.w	rtss					;exit if fight is over
	tst.w	(PenCntDwn).w
	bmi.w	rtss					;exit if fight is over
	cmpi.w	#SPAfight,SPA(a3)
	beq.w	rtss					;exit if this player is not in ready position
	;skate with the dpad (unless no direction) while fighting
	move.w	d0,d2					;dpad input
	move.w	d1,-(sp)				;new button presses
	btst	#3,d2
	bne.w	.noa
	andi.w	#7,d2
	bsr.w	playeracc				;move player
	;keep the fighter face to face and near the fight scroll x (xc1): brake Xvel when it points away
.noa	move.w	(xc1).w,d0			;Keep the players face to face and in range of xc1
	addi.w	#$C,d0
	cmpi.w	#2,facedir(a3)
	bne.w	.0
	subi.w	#$18,d0					;xc1 - 12
.0	sub.w	(a3),d0					;d0 = target x - own x
	move.w	Xvel(a3),d1
	eor.w	d0,d1
	bpl.w	.ind
	tst.w	d0
	bpl.w	.1
	neg.w	d0
.1	muls.w	Xvel(a3),d0				;opposite signs: Xvel -= |dx| * Xvel / 16
	asr.l	#4,d0
	sub.w	d0,Xvel(a3)
.ind	move.w	(sp)+,d1			;d1 = new button presses again
	;start a punch animation if none is running: cbut high, bbut low, abut grab
	bset	#pf2aip,pflags2(a3)
	bne.w	rtss
	move.w	d1,d2
	move.w	#SPAfhigh,d1
	btst	#cbut,d2				;cbut
	bne.w	SetSPA					;start hit high anim
	move.w	#SPAflow,d1
	btst	#bbut,d2				;bbut
	bne.w	SetSPA					;start hit low anim
	move.w	#SPAfgrab,d1
	btst	#abut,d2				;abut
	bne.w	SetSPA					;start grab anim
	bclr	#pf2aip,pflags2(a3)		;clear anim in prog if none
	rts

SetLCmode							;Initiate line change option if available (abut
									;pressed by the puck carrier)
	tst.w	(OptLine).w
	bne.w	rtss					;exit if line changes off
	bsr.w	loadTeamStruct
	bset	#tmflcm,tmflags(a2)		;team already in lc mode?
	bne.w	rtss
	bclr	#sfspdir,(sflags).w		;terminate passing by this player
	bclr	#sfssdir,(sflags).w		;same with shooting
	bset	#pf2lcm,pflags2(a3)		;pf2lcm: this player in lc mode
SetLCmode2							;a2 = team struct for lc. Draw the lc box with
									;one row per eligible line (A/B/C + line name). Also called from lineinput
	bsr.w	setlccords				;set screen cords for this teams lc box
	cmpi.w	#$F,(printy).w
	blt.w	.box
	bset	#sf3llcs,(sflags3).w	;flag for lower (on screen) line change
	bra.w	.frame
.box	jsr	(box).l					;low box: draw the frame at the position set above
	bsr.w	setlccords
.frame	bsr.w	Framer				;Frame lc box
	subq.w	#2,(printy).w
	addq.w	#1,(printx).w
	;draw one row per button (d4 = 2..0 = c/b/a): "<A-C> <line name>" with a line bar
	moveq	#2,d4					;loop 3 times
.loop	move.w	d4,d0				;next row; d4 = row/button number
	bsr.w	getlchoice
	tst.w	d0
	bmi.w	.next					;no line for this button
	btst	#tmflcm,tmflags(a2)
	bne.w	.pr
	cmp.w	tmlcchoice(a2),d4		;box being closed: only the chosen row
	bne.w	.up
	move.w	tmline(a2),d0
.pr	movea.w	#(mesarea-M68K_RAM),a1	;a1 = message area; row letter string
	move.l	#$44120,(a1)			;String 'A '
	add.b	d4,2(a1)				;'A'-'C'
	bsr.w	print
	move.w	d0,-(sp)
	movea.l	#linelist,a1
	bsr.w	Fprintsmall
	move.w	(sp)+,d0
	bsr.w	linebar
	subq.w	#5,(printx).w
.up	subq.w	#1,(printy).w			;next row is one line up
.next	dbf	d4,.loop				;repeat for the other rows
	;finally print the team name on the box
	movea.l	tmdata(a2),a1			;team name
	adda.w	Teamname(a1),a1
	adda.w	(a1),a1
	addq.w	#2,(printx).w
	bra.w	print

setlccords							;set printx/y to cords for lc box on team a2
									;set d0/d1 for framer box size
	clr.w	d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	bne.w	.0
	eori.w	#$16,d0
.0	btst	#gmdir,(gmode).w		;reverse direction: flip to the other end
	beq.w	.noflip
	eori.w	#$16,d0
.noflip	bsr.w	printz				;set print position from the String below
	String	$BF,$16,0
	add.w	d0,(printy).w
	moveq	#2,d0
	bsr.w	getlchoice
	moveq	#6,d1					;3 rows
	tst.w	d0
	bpl.w	.ex
	subq.w	#1,d1					;no third choice: 2 rows
	addq.w	#1,(printy).w
.ex	moveq	#9,d0					;d0 = 9 wide, d1 = 6 (3 rows) or 5 (2 rows) for Framer
	rts

getlchoice							;92 getlchoice2 (92 getlchoice only picked a2 from a3 and called it; the
									;callers do that here). d0 = 0-2 (a2 = team)
									;return d0 = possible line number or -1 for none in this position
	movem.l	d1-d2,-(sp)
	;d2 = other team tmap - own tmap; selects the table section for this strength
	move.w	tmsize+tmap(a2),d2		;other team's tmap
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.0
	move.w	tmap-tmsize(a2),d2
.0	sub.w	tmap(a2),d2				;d2= number I'm short
	beq.w	.1
	;(d2 = 0: +0; d2 < 0: +21; d2 > 0: +42) one section of the table is 7 lines * 3 bytes
	addi.w	#$15,d0					;3*7
	tst.w	d2
	bmi.w	.1
	addi.w	#$15,d0
.1	move.w	tmline(a2),d1			;add 3 * current line to pick that line row
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
	;d0 = choice for this button, or -1 for none (sign extended)
	lea	.tab(pc),a0
	move.b	(a0,d0.w),d0
	ext.w	d0
	movem.l	(sp)+,d1-d2
	rts
.tab								;3 bytes per current line (0-6): choice for button a, b, c; 3 sections of
									;7 lines
;offset = 0 no power play
	dc.b	0,1,2					;line 0
	dc.b	1,2,0					;line 1
	dc.b	2,0,1					;line 2
	dc.b	0,1,2					;line 3
	dc.b	0,1,2					;line 4
	dc.b	0,1,2					;line 5
	dc.b	0,1,2					;line 6
;offset = 3/4 penalty killing
	dc.b	3,4,-1					;line 0
	dc.b	3,4,-1					;line 1
	dc.b	3,4,-1					;line 2
	dc.b	3,4,-1					;line 3
	dc.b	4,3,-1					;line 4
	dc.b	3,4,-1					;line 5
	dc.b	3,4,-1					;line 6
;offset = 5/6 power play
	dc.b	5,6,-1					;line 0
	dc.b	5,6,-1					;line 1
	dc.b	5,6,-1					;line 2
	dc.b	5,6,-1					;line 3
	dc.b	5,6,-1					;line 4
	dc.b	5,6,-1					;line 5
	dc.b	6,5,-1					;line 6
	dc.b	PadByte					;pad (92 retail $01, Rev B $FF)

lineinput							;process input for line changes
									;d1 = new button presses
	move.w	d1,-(sp)
	;a2 = own team struct
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)
	beq.w	.0
	adda.w	#tmsize,a2
.0	bclr	#tmflcc,tmflags(a2)		;Flag to start lc mode
	beq.w	.1
	bsr.w	lcfound2				;close the old box
	bsr.w	SetLCmode2				;start lc mode
.1	move.w	(sp)+,d1				;New presses
	;d2 = button 0-2 (a, b, c) newly pressed -> lcfound
	clr.w	d2						;choice made index
	btst	#abut,d1				;abut
	bne.w	lcfound
	addq.w	#1,d2
	btst	#bbut,d1				;bbut
	bne.w	lcfound
	addq.w	#1,d2
	btst	#cbut,d1				;cbut
	bne.w	lcfound
	;no choice: a free joystick player can still skate with the dpad
	btst	#pfjoycon,pflags(a3)
	beq.w	.x
	btst	#pfalock,pflags(a3)
	bne.w	.x
	btst	#pf2fight,pflags2(a3)
	beq.w	doplayeracc				;skate with dpad if not fighting
.x	rts								;nothing to do

lcfound								;d2 = choice made 0-2
	move.w	d2,d0
	move.w	d2,tmlcchoice(a2)		;chosen row: the box redraw shows only that row
	bsr.w	getlchoice				;translate choice 0-2 into line number 0-6
	tst.w	d0
	bmi.w	rtss					;not an eligible choice
	bclr	#pf2lcm,pflags2(a3)		;pf2lcm
	;accepted: leave lc mode, keep joystick, set the new line and re-pick the players
	bset	#pfjoycon,pflags(a3)
	bsr.w	loadTeamStruct
	bclr	#tmflcm,tmflags(a2)
	move.w	d0,tmline(a2)
	jsr	setpersonel
lcfound2							;from 92 lcfound .close. close lc box. Also called from lineinput
	bsr.w	setlccords
	cmpi.w	#$F,(printy).w
	blt.w	.nollcm
	bclr	#sf3llcs,(sflags3).w
.nollcm	addq.w	#1,d1				;d1 = 1 and d2 = $7FF tile: erase the box area
	move.w	#$7FF,d2
	bsr.w	eraser
	bra.w	printscores1

burst								;cbut press check/speed. Also entered from check4check burst costs energy
									;$CC (only when line changes are on, OptLine = 0)
	bsr.w	getpde					;get players energy
	tst.w	(OptLine).w
	bne.w	.0
	subi.w	#$CC,d0					;$1000/20
	bsr.w	setpde					;decrease players energy
.0	lsr.w	#7,d0					;d0 = energy/128 = speed gained
	move.w	d0,d1					;energy = speed increase (check violence)
	move.w	facedir(a3),d2
	asl.w	#2,d2
	;Xvel/Yvel += energy-speed along facedir (dirtab x,y per direction)
	movea.l	#dirtab,a0
	muls.w	(a0,d2.w),d0
	muls.w	2(a0,d2.w),d1
	add.w	d0,Xvel(a3)
	add.w	d1,Yvel(a3)
	;burst animation locks the controls until done
	bset	#pfalock,pflags(a3)		;lock in this animation
	move.w	#SPAburst,d1
	bra.w	SetSPA

Holdplayer							;abut press hold. a0 = the player this one is
									;assigned to, falls into Acheck
	bset	#pfalock,pflags(a3)
	move.w	#SPAhook,d1
	tst.w	impact(a3)
	beq.w	SetSPA
	movea.w	#(SortCords-M68K_RAM),a0
	move.w	impactp(a3),d0
	asl.w	#7,d0
	adda.w	d0,a0
Acheck								;from 92 Holdplayer. start SPAHold, or SPAhook if a0 is ahead, on player
									;a0. Also entered from check4check
	bset	#pfalock,pflags(a3)
	move.w	#SPAhook,d1
	tst.w	impact(a3)
	beq.w	.set
	move.w	Ypos(a3),d0
	sub.w	Ypos(a0),d0
	btst	#pfgoal,pflags(a3)
	beq.w	.0
	neg.w	d0
.0	bmi.w	.set					;d0 < 0: a0 is ahead (toward the goal being attacked) so keep SPAhook,
									;else SPAHold
	move.w	#SPAHold,d1
.set	bra.w	SetSPA				;start hook/hold animation

setpassmode							;initialize pass mode
	move.w	facedir(a3),(passdir).w	;default pass dir.
	andi.w	#7,(passdir).w
	bset	#sfspdir,(sflags).w
	rts

passmode							;dpad sets passdir until bbut changes
	btst	#bbut,d2				;has bbut changed?
	bne.w	dopass					;yes
	btst	#3,d0					;look for dpad
	bne.w	rtss
	andi.w	#7,d0
	move.w	d0,(passdir).w			;new pass dir
	bset	#3,d0
dopass								;pass the puck in passdir, to the best teammate there if any. Also called
									;from chk4pass pass: leave pass mode, puck no longer held (puckc = -1),
									;brief pickup lockout
	movem.l	d0-d5/a0-a1,-(sp)
	bclr	#sfspdir,(sflags).w
	st	(puckc).w					;player is not puck handler anymore
	move.b	#$10,nopuck(a3)
	move.w	SCnum(a3),(lastplayer).w
	moveq	#8,d0
	tst.w	position(a3)
	beq.w	.pa						;goalie
	move.b	passacc(a3),d0
.pa	asl.w	#2,d0					;goalie 8, else passacc: d0*4 + $A0 = passspeed
	addi.w	#$A0,d0					;160
	move.w	d0,(passspeed).w
	;find the teammate (SortCords, own 6 players) with the lowest score = dist^2 + angle^2 from passdir;
	;players more than one direction step off passdir (angle^2 > 256^2) are skipped
	moveq	#-1,d4					;look for closest and best player to pass to
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	blt.w	.0
	adda.w	#6*SCstruct,a1
.0	cmpa.l	a1,a3					;d3 = players left; a1 = candidate teammate; skip self, goalie and
									;unavailable players
	beq.w	.next					;don't pass to yourself
	tst.w	position(a1)
	beq.w	.next					;don't pass to goalie
	btst	#pf2unav,pflags2(a1)	;pf2unav
	bne.w	.next					;player is unavailable
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
.next	adda.w	#SCstruct,a1		;next teammate
	dbf	d3,.0
	tst.l	d4
	bmi.w	.nopp					;skip if no player to pass to
	bsr.w	passtoa0
	bra.w	.exit
.nopp	move.w	(passdir).w,d0		;Just hit puck in pass direction not to any player
	asl.w	#2,d0
	movea.l	#dirtab,a0
	move.w	2(a0,d0.w),d1			;y INC
	muls.w	(passspeed).w,d1
	moveq	#$A,d2
	asl.l	d2,d1
	divs.w	#runspeed*15,d1
	add.w	Yvel(a3),d1
	move.w	d1,(puckvy).w
	move.w	(a0,d0.w),d1			;x inc
	muls.w	(passspeed).w,d1
	asl.l	d2,d1
	divs.w	#runspeed*15,d1
	add.w	Xvel(a3),d1
	move.w	d1,(puckvx).w
	;random vertical velocity up to $1000
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,(puckvz).w
.exit	tst.w	position(a3)		;Start animation for player passing
	bne.w	.notgoalie
	tst.w	(puckvy).w
	btst	#pfgoal,pflags(a3)
	beq.w	.g0
	bmi.w	.nvy
	bra.w	.notgoalie
.g0	bmi.w	.notgoalie				;pfgoal clear: negative puckvy is fine
.nvy	neg.w	(puckvy).w			;goalie pass always goes up ice: force the sign of puckvy by pfgoal
.notgoalie	move.w	(puckvx).w,d0	;d0/d1 = puck velocity -> direction for the animation (goalie swing,
									;forehand or backhand pass)
	move.w	(puckvy).w,d1
	bsr.w	vtoa
	move.w	#SPAgswing,d1
	tst.w	position(a3)
	beq.w	.e1						;goalie anim
	move.w	#SPApassf,d1
	bsr.w	Findhittype
	beq.w	.e1
	move.w	#SPApassb,d1
.e1	bsr.w	SetSPA					;start the pass animation d1
	;lock, then pass sound id = SFXpass + (12 - puckvz)/4
	bset	#pfalock,pflags(a3)
	moveq	#$C,d0					;pass sound $10+ by puck height
	sub.b	(puckvz).w,d0
	lsr.w	#2,d0
	addi.w	#SFXpass,d0
	move.w	d0,-(sp)
	bsr.w	sfx
	movem.l	(sp)+,d0-d5/a0-a1
	rts

passtoa0							;pass puck to player a0
									;count a pass for the team and remember the receiver
	bsr.w	loadTeamStruct
	addq.w	#1,tmpasses(a2)			;count passes
	move.w	SCnum(a0),(passReceiverPlayerNum).w
	move.w	(passspeed).w,d5		;in pix/sec
	asr.w	#2,d5
	exg	a0,a3						;tell pass rec to get puck
	move.l	#apassrec,d0			;apassrec
	bsr.w	assinsert
	exg	a0,a3
	move.l	a0,-(sp)				;this routine uses passspeed
	bsr.w	GetHot					;and player's a0 x/y speed to determine
	add.w	(a0),d0					;the x/y velocity of the puck so it will
	sub.w	(puckx).w,d0			;meet player a0
	add.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	;(d0,d1) = vector puck -> receiver hot spot; receiver speed in pixels per 1/4 second
	movem.w	d0-d1,-(sp)
	movem.w	(sp),d2-d3
	asr.w	#2,d2
	asr.w	#2,d3
	move.w	Xvel(a0),d0
	muls.w	#$F0,d0					;x pix/(1/4)sec
	swap	d0
	move.w	Yvel(a0),d1
	muls.w	#$F0,d1
	swap	d1
	movem.w	d0-d1,-(sp)
	;solve the intercept of the puck (speed passspeed/4) with the receiver moving at constant velocity:
	;quadratic in time, j = velocity . displacement*2, k = |v|^2 - speed^2
	muls.w	d2,d0
	muls.w	d3,d1
	add.w	d1,d0
	asl.w	#1,d0
	move.w	d0,d4					;j
	movem.w	(sp),d0-d1
	muls.w	d0,d0
	muls.w	d1,d1
	muls.w	d5,d5
	neg.l	d5
	add.l	d0,d5
	add.l	d1,d5					;k
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d2,d3					;a^2
	muls.w	d5,d3
	asl.l	#2,d3
	move.w	d4,d0
	muls.w	d0,d0
	sub.l	d3,d0
	bsr.w	Sroot
	moveq	#1,d3					;limit inf. loop
	asr.w	#2,d5
	bne.w	.0
	moveq	#1,d5					;no div by zero
.0	move.w	d0,d2					;d2 = (sqrt(disc) - j) / k = intercept time; dbpl retries with the other
									;root (d0 negated)
	neg.w	d0
	sub.w	d4,d2
	ext.l	d2
	divs.w	d5,d2
	dbpl	d3,.0
	bne.w	.1
	addq.w	#1,d2					;can't be zero
.1	cmp.w	#24,d2					;limit to 3 sec.
	bls.w	.2
	moveq	#$18,d2
.2	move.b	d2,(puckvz).w			;d2 = time in 1/8 sec to intersection
	cmp.w	#12,d2
	blt.w	.3
	move.b	#$C,(puckvz).w
.3	move.w	d2,d0					;d2 = time (1/8 s): receiver temp1(a0) = d2*8-10
									;(temp1), puck lockout = that - 6
	asl.w	#3,d0
	subi.w	#$A,d0					;6
	move.b	d0,temp1(a0)			;temp1 high byte
	subq.w	#6,d0					;10
	move.b	d0,(puckx+nopuck).w
	;receiver target temp3/temp4 = puck + (relative vector + receiver motion)
	movem.w	(sp)+,d0-d1
	muls.w	d2,d0
	asr.l	#1,d0
	add.w	(sp)+,d0				;x distance
	move.w	(puckx).w,temp3(a0)		;receiver target x/y
	add.w	d0,temp3(a0)
	muls.w	d2,d1
	asr.l	#1,d1
	add.w	(sp)+,d1				;y distance
	move.w	(pucky).w,temp4(a0)
	add.w	d1,temp4(a0)
	;puck velocity = distance / (time*120)
	mulu.w	#$78,d2					;60*2
	swap	d0
	divs.w	d2,d0
	move.w	d0,(puckvx).w
	swap	d1
	divs.w	d2,d1
	move.w	d1,(puckvy).w
	rts

changeplayer						;switch controller d4 (0/2) to the teammate nearest the puck, or sweep
									;check if that is the current player
	movem.l	d0-d6/a0-a1,-(sp)
	move.w	(puckvx).w,d0			;lead puck slightly
	asr.w	#8,d0
	add.w	(puckx).w,d0
	move.w	(puckvy).w,d1
	asr.w	#8,d1
	add.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	;search the 6 teammates of controller d4 (d2 counts) for the one nearest the lead point
	moveq	#5,d2
	move.w	d4,d3
	eori.w	#2,d3					;other controller
	moveq	#-1,d5
	movea.w	#(SortCords-M68K_RAM),a0	;start of search
	movea.w	#(cont1team-M68K_RAM),a1
	cmpi.w	#1,(a1,d4.w)
	beq.w	.t1
	adda.w	#6*SCstruct,a0			;controller is on other team
.t1	movea.w	#(c1playernum-M68K_RAM),a1	;a1 = c1playernum/c2playernum
.top	tst.w	position(a0)		;skip goalie, unavailable and animation-locked players, and the controller
									;current player
	ble.w	.next					;can't switch to goalie
	btst	#pf2unav,pflags2(a0)	;pf2unav
	bne.w	.next					;this player is unavailable for some reason
	btst	#pfalock,pflags(a0)
	bne.w	.next					;this player is locked
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
	beq.w	.next					;this is current player
	move.l	d0,d5
	move.w	d1,d6
.next	adda.w	#SCstruct,a0		;next teammate
	dbf	d2,.top
	;d6 = chosen player; nearest is the current one -> sweep check, else switch the joystick to him
	addq.w	#4,sp
	pea	(.ex).l
	cmp.w	(a1,d4.w),d6
	beq.w	Sweepcheck				;player is same so sweep check
	move.w	d6,d0
	tst.w	d4
	beq.w	setc1player
	bra.w	setc2player
.ex	movem.l	(sp)+,d0-d6/a0-a1		;restore registers
	rts

Sweepcheck							;start sweep check on player a3
	bset	#pfalock,pflags(a3)
	move.w	#SPAsweepchk,d1
	bra.w	SetSPA

setc1player							;restore old player and switch to new d0 player on cont. 1
	cmp.w	(c1playernum).w,d0
	beq.w	rtss
	movem.l	d1/a0-a1,-(sp)
	move.w	(c1playernum).w,d1
	bsr.w	restorepl
	move.w	d0,(c1playernum).w
	movem.l	(sp)+,d1/a0-a1
	rts

setc2player							;restore old player and switch to new d0 player on cont. 2
	cmp.w	(c2playernum).w,d0
	beq.w	rtss
	movem.l	d1/a0-a1,-(sp)
	move.w	(c2playernum).w,d1
	bsr.w	restorepl
	move.w	d0,(c2playernum).w
	movem.l	(sp)+,d1/a0-a1
	rts

restorepl							;Restore old joy controlled player d1, give d0
									;the joystick. 93: if d1 is in line change mode it keeps control (d0 = d1)
	movea.w	#(SortCords-M68K_RAM),a0
	tst.w	d1
	blt.w	.spd
	cmp.w	#11,d1
	bgt.w	.spd
	asl.w	#scsize,d1				;scsize
	btst	#pf2lcm,pflags2(a0,d1.w)	;pf2lcm
	beq.w	.rel
	lsr.w	#7,d1
	move.w	d1,d0
	rts
.rel	bclr	#pfjoycon,pflags(a0,d1.w)	;release the old player: joystick off, new assignment (pfna)
	bset	#pfna,pflags(a0,d1.w)
.spd	tst.w	d0					;give the joystick to new player d0 (0-11), if valid
	blt.w	rtss
	cmp.w	#11,d0
	bgt.w	rtss
	move.w	d0,d1
	asl.w	#7,d1
	bset	#pfjoycon,pflags(a0,d1.w)
	rts

Findhittype							;look for type of swing (forhand or backhand)
									;input d0 = launch dir
									;ouput beq forhand
	;	bne	backhand
	neg.w	d0
	add.w	facedir(a3),d0
	andi.w	#7,d0
	btst	#3,attribute(a3)		;x flip
	beq.w	.1
	btst	d0,#$F0					;%11110000
	rts
.1	btst	d0,#$1E					;%00011110
	rts

SetShotMode							;initiate shot by player a3
	move.w	#8,(passdir).w			;default shot direction
	bset	#sfssdir,(sflags).w
	;aim at the goal being attacked: (d0,d1) = vector from player to goal ($128 beyond center)
	clr.w	d0						;find dx/dy for shot
	move.w	#$128,d1				;296
	btst	#pfgoal,pflags(a3)
	bne.w	.ck0
	neg.w	d1
.ck0	sub.w	(a3),d0				;(d0,d1) = vector to the goal -> direction
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	move.w	#$F,(passspeed).w
	move.w	#SPAshotf,d1
	bsr.s	Findhittype
	beq.w	.ck1
	move.w	#SPAshotb,d1
	move.w	#$F,(passspeed).w		;minimum shot speed
.ck1	bra.w	SetSPA				;start shot animation

ShotMode							;shot input
									;swing frame reached (anim frame 7*4): shoot, else dpad sets shot
									;direction
	cmpi.w	#$1C,SPAnum(a3)			;7*4
	bge.w	doshot					;end of animation so shoot
	btst	#3,d0
	bne.w	.ss0
	andi.w	#7,d0
	move.w	d0,(passdir).w			;set shot direction
.ss0	cmpi.w	#$10,SPAnum(a3)		;4*4
	bge.w	rtss					;past full windup so no more passspeed
	;wind-up: shot power grows by elapsed frames
	add.w	d7,(passspeed).w
	cmpi.b	#$A,shotspd(a3)			;shotspd >= 10 must release the button
	bge.w	.cb
	cmpi.w	#8,SPAnum(a3)
	bgt.w	.rev					;slow shooter: swing after 2 frames of windup
.cb	btst	#cbut,d2				;cbut
	beq.w	rtss					;button hasn't changed so continue windup
.rev	neg.w	SPAnum(a3)			;End wind and swing thru
	addi.w	#$1C,SPAnum(a3)
	rts

doshot								;stick is at puck so launch puck toward goal
	movem.l	d0-d7/a0-a3,-(sp)
	bsr.w	shotdiradj				;aim away from the goalie
	move.w	#5,-(sp)				;sound effect (92 used 14)
	move.w	SCnum(a3),(shotplayer).w
	bclr	#sfssdir,(sflags).w
	bset	#pfalock,pflags(a3)
	;did the shooter still have the puck?
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.ex						;wiffed shot
	move.w	#$18,(sp)				;92 used 13
	bset	#sf2shot,(sflags2).w
	cmpi.w	#SPAshotb,SPA(a3)
	bne.w	.nbh
	move.w	#$14,(sp)				;92 used 12
	move.w	(passspeed).w,d0
	lsr.w	#2,d0					;sub 25% for backhand shots
	sub.w	d0,(passspeed).w
.nbh	move.b	shotspd(a3),d0		;shot power scales with shotspd and player energy (makepde)
	movea.l	a3,a0
	bsr.w	makepde
	addi.w	#$14,d0
	mulu.w	(passspeed).w,d0		;shot speed ranged by energy level
	mulu.w	#$5249,d0				;$4000*45/35
	swap	d0
	move.w	d0,(passspeed).w
	lsr.w	#4,d0					;crowd bonus 3 - speed/16
	neg.w	d0
	addq.w	#3,d0
	bpl.w	.c
	clr.w	d0
.c	add.w	d0,(sp)					;sound id += crowd bonus
	st	(puckc).w
	move.b	#$10,nopuck(a3)
	move.w	SCnum(a3),(lastplayer).w
	;d1 = target goal y; (d0,d2) = x and z offsets for this direction from .shotsets
	move.w	#Blueline+goalline,d1	;blueline+goalline
	btst	#pfgoal,pflags(a3)
	bne.w	.0
	neg.w	d1
.0	move.w	(passdir).w,d2			;passdir * 4 indexes .shotsets
	asl.w	#2,d2
	lea	.shotsets(pc),a0			;table of shot directions
	move.w	(a0,d2.w),d0			;x offset
	move.w	2(a0,d2.w),d2			;z offset
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	movem.w	d0-d2,-(sp)
	;d3 = distance to the target point
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	Sroot
	tst.w	d0						;distance in pix to goal
	bne.w	.1
	addq.w	#1,d0
.1	move.w	d0,d3					;never zero
	;highlight mode: always perfect; otherwise only close shots can be perfect (accuracy dependent)
	btst	#gmhl,(gmode).w
	bne.w	.perf
	cmp.w	#200,d3
	bhi.w	.notperf				;too far away for perfect shot
	moveq	#$10,d0
	add.b	shotacc(a3),d0
	bsr.w	randomd0
	cmp.w	#14,d0					;chance of perfect shot
	bgt.w	.perf					;is perfect
.notperf	move.w	(passspeed).w,d0	;aim error = ((power/16 - shotacc + $10) * distance) / 64, halved
										;within 250, max $88
	lsr.w	#4,d0
	sub.b	shotacc(a3),d0
	addi.b	#$10,d0
	mulu.w	d3,d0
	lsr.w	#6,d0					;shot accuracy adjust (92 lsr #7)
	cmp.w	#250,d3
	bhi.w	.cp
	lsr.w	#1,d0					;closer than 250: half the error
.cp	cmp.w	#$88,d0					;cap the error
	blt.w	.ar
	move.w	#$88,d0
.ar	move.w	d0,-(sp)				;x dist += random error; 2(sp) / 4(sp) = x / y dist pushed before
	bsr.w	randomd0s
	add.w	d0,2(sp)				;x dist
	move.w	(sp),d0
	cmp.w	#60,d0
	bls.w	.ay
	moveq	#$3C,d0
	move.w	d0,(sp)
.ay	tst.w	4(sp)					;y error
	bpl.w	.am
	lsr.w	#1,d0
.am	bsr.w	randomd0s				;y dist += random error
	add.w	d0,4(sp)				;y dist
	move.w	(sp)+,d0
	lsr.w	#1,d0
	bsr.w	randomd0
	add.w	d0,4(sp)
	;puckvx/puckvy = speed * $44 * dist / distance
.perf	move.w	(passspeed).w,d2	;Shot speed
	muls.w	#$44,d2					;1024/15
	muls.w	(sp)+,d2
	divs.w	d3,d2
	move.w	d2,(puckvx).w
	move.w	(passspeed).w,d2
	muls.w	#$44,d2
	muls.w	(sp)+,d2
	divs.w	d3,d2
	move.w	d2,(puckvy).w
	;puckvz from the height in goal and flight time, capped at $1800
	move.w	(sp)+,d1				;pix height in goal
	beq.w	.ex
	mulu.w	(passspeed).w,d1
	mulu.w	#$44,d1
	divu.w	d3,d1
	mulu.w	#$B33,d3				;(1024*42)/15
	divu.w	(passspeed).w,d3
	add.w	d1,d3
	cmp.w	#$1800,d3
	bls.w	.noup
	move.w	#$1800,d3
.noup	move.w	d3,(puckvz).w		;set vertical velocity
.ex	bsr.w	sfx						;play the shot sound
	movem.l	(sp)+,d0-d7/a0-a3
	rts
.shotsets							;Offsets for different directions on the shot
	dc.w	0,$C,$10,$C,$10,6,$10,0
	dc.w	0,0,-$10,0,-$10,6,-$10,$C
	dc.w	0,6

shotdiradj							;If the opposing goalie
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
.g	adda.w	#SCstruct,a0			;scan the opposing team for the goalie (position 0)
	tst.w	position(a0)			;position 0 = goalie
	dbeq	d1,.g
	bne.w	.x
	move.b	Xvel(a0),d0				;goalie x/y + half his velocity
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
	bsr.w	Sroot
	move.w	d0,d2					;distance to goalie
	movem.w	(sp)+,d0-d1
	moveq	#$12,d3					;post x
	move.w	#$108,d4				;goal y
	btst	#pfgoal,pflags(a3)
	bne.w	.l
	neg.w	d4
.l	movem.w	d3-d4,-(sp)				;angle offset to the first post
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
	btst	#pfgoal,pflags(a3)
	beq.w	.s
	neg.w	d4
.s	moveq	#2,d0					;open side: dir 2 if d4 >= 0 else 6
	tst.w	d4
	bpl.w	.x
	moveq	#6,d0
.x	move.w	d0,(passdir).w			;passdir (8 = middle)
	rts

CalcAngleOffset						;d4 = cross product of goalie vector d0/d1 and post vector d3/d4 (relative
									;to the puck), divided by d2
	sub.w	(puckx).w,d3
	sub.w	(pucky).w,d4
	muls.w	d0,d4
	muls.w	d1,d3
	sub.l	d3,d4
	divs.w	d2,d4
	rts

setpads								;copy info into pad cont so graphics knows which player/number.
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

check4bench							;check if player a3 should go to bench. Called from assbench (pops its
									;return address when it takes over)
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	btst	#pf2pen,pflags2(a3)
	bne.w	rtss
	;newpos/newpnum = pending substitution (-1 none)
	tst.b	newpos(a3)
	bpl.w	.b
	tst.b	newpnum(a3)
	bmi.w	rtss
.b	move.b	newpnum(a3),d0			;new player number differs from current -> go to the bench; else only
									;change position
	cmp.b	pnum(a3),d0
	beq.w	.samepl					;player should just change positions
	move.w	assnum(a3),d0
	cmpi.b	#$B,asslist(a3,d0.w)	;already going to bench
	beq.w	rtss
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	rtss
	addq.w	#4,sp
	bset	#pf2unav,pflags2(a3)	;pf2unav
	clr.w	temp1(a3)
	move.l	#abench,d0				;abench
	bra.w	assreplace
.samepl	addq.w	#4,sp				;drop return address (takes over the assignment); apply new position now
	bclr	#pf2unav,pflags2(a3)
	bclr	#pfnc,pflags(a3)
	st	newpnum(a3)
	st	newpos(a3)
	move.w	position(a3),d0
	IF REV=2
	bra.w	Setplass				;Rev B: newpos was just set to -1, so the test below was dead code
	ELSE
	tst.b	newpos(a3)
	bmi.w	Setplass
	move.b	newpos(a3),d0
	ext.w	d0
	move.w	d0,position(a3)
	bra.w	Setplass
	ENDIF

;======================================================================
;======================================================================
;	Player assignments from assbench to asswingd, with the fight code (assfight, chkhit, banner). Every
;	assignment starts with "btst #pfalock / bne rtss". Field and flag names are in ram93.asm.

assbench							;player a3 should goto bench
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	cmpi.w	#$64,temp1(a3)			;temp1 = 100 flag: at the bench door
	beq.w	.done
	;may switch to a position change or reassign to abench
	bsr.w	check4bench
	btst	#pf2pen,pflags2(a3)		;pf2pen
	bne.w	assexit
	;first time: target = bench spot, x = -(Sideline+8), y = +-80 by team
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	move.w	#8,temp2(a3)
	moveq	#$50,d0					;80
	btst	#pfteam,pflags(a3)
	bne.w	.0
	neg.w	d0
.0	move.w	d0,temp4(a3)			;temp4 = bench y
	move.w	#Sideline,temp3(a3)		;sideline
	neg.w	temp3(a3)
	subq.w	#8,temp3(a3)			;temp3 = bench x
	clr.w	temp1(a3)
.nna	move.b	newpnum(a3),d0		;same player? just change position
	cmp.b	pnum(a3),d0
	beq.w	.nobench				;same player, just change position
	;temp1 counts frames; re-check arrival every 8
	sub.w	d7,temp1(a3)
	bpl.w	.nodec
	addq.w	#8,temp1(a3)
	;within 40 px of bench y and 32 px of bench x?
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
	move.w	#SPAglide,d1
	tst.w	position(a3)
	bne.w	.gli
	move.w	#SPAgready,d1
.gli	bsr.w	SetSPA				;glide (goalie: ready) animation
	;no collisions; turn step by step toward facedir 4
	bset	#pfnc,pflags(a3)
	cmpi.w	#4,facedir(a3)
	beq.w	.ok
	addq.w	#1,facedir(a3)			;turn toward the bench
	andi.w	#7,facedir(a3)
.ok	clr.w	Yvel(a3)				;drift left (Xvel -$800)
	move.w	#$F800,Xvel(a3)			;-$800
	;within 16 px of the wall: stop and climb over (SPAwallleft)
	cmp.w	#16,d0
	bgt.w	rtss
	clr.w	Xvel(a3)
	cmpi.w	#4,facedir(a3)
	bne.w	rtss
	move.w	#$F800,Xvel(a3)
	move.w	#2,facedir(a3)
	move.w	#SPAwallleft,d1
	bsr.w	SetSPA
	bset	#pfalock,pflags(a3)
	move.w	#$64,temp1(a3)			;100
	rts
.done	clr.w	frame(a3)			;at the bench door: mark this roster slot on the bench (tmpdst -2),
									;install the new player (d3)
	clr.w	d0
	move.b	pnum(a3),d0
	add.w	d0,d0
	movea.l	#tmstruct,a0
	btst	#pfteam,pflags(a3)
	beq.w	.t0
	adda.w	#tmsize,a0
.t0	move.w	#$FFFE,tmpdst(a0,d0.w)	;tmpdst: put used player on bench
	move.b	newpnum(a3),d3
	bsr.w	.nobench2
	bra.w	setplayer
.nodec	btst	#pfnc,pflags(a3)	;skate toward bench spot (temp3,temp4), unless already over the wall
	bne.w	rtss
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	movea.l	#EvadePC,a0
	bra.w	skateto
.nobench	bclr	#pf2unav,pflags2(a3)	;pf2unav
.nobench2	move.b	newpos(a3),d0	;position = newpos; clear newpos and newpnum
	ext.w	d0
	move.w	d0,position(a3)
	bsr.w	Setplass
	st	newpnum(a3)
	st	newpos(a3)
	rts

asseben								;player a3 should exit bench area
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	;first time: bench slot y = 14 * slot (slot from SCnum), x = -Sideline; step over the wall
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	move.w	SCnum(a3),d0
	subq.w	#6,d0
	bmi.w	.0
	addq.w	#1,d0
.0	muls.w	#$E,d0					;14 pixels per bench slot
	move.w	d0,Ypos(a3)
	move.w	#Sideline,(a3)			;sideline
	neg.w	(a3)
	move.w	#2,facedir(a3)
	bset	#pfalock,pflags(a3)
	move.w	#SPAwallright,d1
	bra.w	SetSPA
	;stepped out: clear bench flags and skate right (Xvel $1000), then leave the assignment
.nna	move.w	#4,facedir(a3)		;after the wall animation
	bclr	#pfnc,pflags(a3)
	bclr	#pf2npc,pflags2(a3)		;pf2npc
	bclr	#pf2unav,pflags2(a3)	;pf2unav
	clr.w	SPA(a3)
	move.w	#$1000,Xvel(a3)
	bra.w	assexit

asspenalty							;player a3 should goto penalty box
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	;first time: unavailable, joystick off him, target = box slot y, x = Sideline
	bset	#pf2unav,pflags2(a3)	;pf2unav
	bsr.w	clrplayer
	moveq	#-2,d4
	bsr.w	setpads					;put number on player leaving
	move.w	#8,temp2(a3)
	;slot y = 11 * (min(players already in this team box, 2) + 3), negative for the home side
	moveq	#$B,d0					;11*(n+3) (92 used 55 - 10*n)
	move.b	(PBnum).w,d1
	btst	#pfteam,pflags(a3)
	bne.w	.0
	lsr.w	#4,d1
	neg.w	d0
.0	andi.w	#$F,d1					;d1 = this team count of PBnum
	cmp.w	#2,d1
	bls.w	.1
	moveq	#2,d1
.1	addq.w	#3,d1					;slot number + 3
	muls.w	d0,d1
	move.w	d1,temp4(a3)
	move.w	#Sideline,temp3(a3)		;temp3 = sideline
	clr.w	temp1(a3)
	bset	#pf2npc,pflags2(a3)		;pf2npc: no player coll.
	clr.w	Wallcos(a3)
	clr.w	Wallsin(a3)
.nna	move.w	Ypos(a3),d0			;near the box door (within 12 y, not more than 24 short in x)?
	sub.w	temp4(a3),d0
	cmp.w	#12,d0
	bgt.w	.st
	cmp.w	#-12,d0
	blt.w	.st
	move.w	(a3),d0
	sub.w	temp3(a3),d0
	cmp.w	#-24,d0
	blt.w	.st
	;wait out temp1 in steps of 8
	sub.w	d7,temp1(a3)
	bpl.w	rtss
	addq.w	#8,temp1(a3)
	bset	#pfnc,pflags(a3)
	;glide in, turn toward the wall (facedir 6 or 2 by handedness)
	move.w	#SPAglide,d1
	bsr.w	SetSPA
	moveq	#6,d2
	tst.b	handed(a3)
	beq.w	.left
	moveq	#2,d2
.left	cmp.w	facedir(a3),d2		;turn one step toward d2
	beq.w	.ok
	addq.w	#1,facedir(a3)
	andi.w	#7,facedir(a3)
.ok	clr.w	Yvel(a3)				;skate right
	move.w	#$1000,Xvel(a3)
	;within 8 px: stop, step over the wall, then become adopen (player in box)
	cmp.w	#-8,d0
	blt.w	rtss
	clr.w	Xvel(a3)
	cmp.w	facedir(a3),d2
	bne.w	rtss
	bset	#pfalock,pflags(a3)
	move.w	#2,facedir(a3)
	move.w	#SPAwallright,d1
	bsr.w	SetSPA
	bclr	#pf2pen,pflags2(a3)		;pf2pen
	move.l	#adopen,d0				;adopen
	bra.w	assreplace
.st	move.w	temp3(a3),d0			;too far: keep skating to (temp3,temp4)
	move.w	temp4(a3),d1
	movea.l	#rtss,a0
	bra.w	skateto

clrplayer							;take the joystick off player a3
	btst	#pfjoycon,pflags(a3)
	beq.w	rtss
	;d4 = controller that holds this player (0 or 2); pick a new player for it
	clr.w	d4
	move.w	SCnum(a3),d0
	cmp.w	(c1playernum).w,d0
	beq.w	changeplayer
	moveq	#2,d4
	bra.w	changeplayer

assdopen							;add player a3 to penalty box
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	;PBnum: high nibble = home, low nibble = visitors; add one for this team
	moveq	#$10,d0
	btst	#pfteam,pflags(a3)
	beq.w	.1
	moveq	#1,d0
.1	add.b	d0,(PBnum).w			;Players in penalty box
	;position -1 = off the ice (in the box)
	st	position(a3)
	clr.w	frame(a3)
	rts

assepen								;player a3 should exit penalty area
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	;first time: leave the box: PBnum -= 1, place at x $86, y -60/+60, climb out (SPAwallleft)
	bset	#pfnc,pflags(a3)
	bset	#pf2unav,pflags2(a3)	;pf2unav
	moveq	#$10,d0
	moveq	#-$3C,d1				;-60
	btst	#pfteam,pflags(a3)
	beq.w	.1
	moveq	#1,d0
	neg.w	d1
.1	sub.b	d0,(PBnum).w			;Players in penalty box
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	move.w	#$86,(a3)
	move.w	#2,facedir(a3)
	bset	#pfalock,pflags(a3)
	move.w	#SPAwallleft,d1
	bsr.w	SetSPA
	jmp	SprSort
.nna	move.w	#4,facedir(a3)		;out: face left, skate left (Xvel -$1000), clear flags and leave the
									;assignment
	st	newpnum(a3)
	st	newpos(a3)
	bclr	#pfjoycon,pflags(a3)
	bclr	#pfnc,pflags(a3)
	bclr	#pf2npc,pflags2(a3)		;pf2npc
	bclr	#pf2unav,pflags2(a3)	;pf2unav
	move.w	#$F000,Xvel(a3)			;-$1000
	bra.w	assexit

assfaceoff							;players do nothing until faceoff is over
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#sf2faceoff,(sflags2).w
	beq.w	assexit					;exit once faceoff is over
	rts

assfaceoffpl						;assignment for players actually participating in faceoff a3 = player
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#sf2faceoff,(sflags2).w
	beq.w	.exit
	;first time: clear temp1
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna	movea.l	#fofdata2,a0		;a0 = fofdata2 (home) or +4 (visitor): big faceoff sprite data
	btst	#pfteam,pflags(a3)
	beq.w	.0
	addq.w	#4,a0
.0	move.w	SPAnum(a3),d0			;d0 = SPAnum/4 + 1, +3 for right handed: frame code for the big sprite
	lsr.w	#2,d0
	addq.w	#1,d0
	tst.b	handed(a3)
	bne.w	.lefty
	addq.w	#3,d0
.lefty	move.w	d0,(a0)				;store frame code
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	;computer: start the swing once; early at 1/8 chance if the puck drop timer is > $10
	bset	#pf2aip,pflags2(a3)
	bne.w	rtss
	move.w	#SPAfaceoff,d1
	cmpi.w	#$10,(puckx+temp1).w
	bls.w	.d
	moveq	#8,d0
	bsr.w	randomd0
	tst.w	d0
	beq.w	.d
	move.w	#SPAfaceoffr,d1
.d	bset	#pf2aip,pflags2(a3)		;swing animation started
	bra.w	SetSPA
.exit	move.b	#$14,nopuck(a3)		;nopuck = 20
	bra.w	assexit

assfight							;fighting logic
									;a3 = player
	btst	#pfalock,pflags(a3)		;check if animation lock
	bne.w	rtss					;exit if so
	tst.w	(PenCntDwn).w			;fight over?
	bmi.w	donothing
	bclr	#pfna,pflags(a3)		;clear new assignment
	beq.w	.nna					;not first time through
	;strength = energy * fighting / 4096, min 5
	bsr.w	getpde					;get player's energy level
	move.b	fighting(a3),d1			;fighting
	ext.w	d1
	mulu.w	d1,d0
	lsr.w	#8,d0
	lsr.w	#4,d0
	cmp.w	#5,d0
	bgt.w	.s
	moveq	#5,d0					;min strength is 5
.s	move.w	d0,temp3(a3)			;temp3 = strength
	clr.w	temp2(a3)
	move.w	#$FFFF,temp4(a3)		;temp4 = banner timer
	cmpi.w	#2,facedir(a3)
	bne.w	.nna
	move.w	#$5A,temp4(a3)			;90: one player shows the banner
.nna	sub.w	d7,temp4(a3)		;Sub frames elapsed from temp4
	bcc.w	.nna2
	bsr.w	banner					;show fighters' names
.nna2	tst.w	temp3(a3)			;temp3 < 0: fight over for this player
	bmi.w	rtss
	;a0 = opponent; scroll lock x = midpoint of both
	move.w	impactp(a3),d0
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0					;a0 = opponent
	move.w	(a3),d0
	add.w	(a0),d0
	asr.w	#1,d0
	move.w	d0,(xc1).w				;scroll lock between the fighters
	;computer fighter: punch when the opponent is within 20 px (extrapolated by velocity)
	btst	#pfjoycon,pflags(a3)
	bne.w	.j
	bset	#pf2aip,pflags2(a3)
	bne.w	.j
	move.w	(a3),d0					;computer punches only when in range
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
	;random: grab 1/8, else high or low punch
	moveq	#8,d0
	bsr.w	randomd0
	cmp.w	#2,d0
	bls.w	.p
	andi.w	#1,d0
.p	asl.w	#1,d0					;word index into .al
	lea	.al(pc),a1					;choose punch type
	move.w	(a1,d0.w),d1
	bsr.w	SetSPA
.j	bsr.w	chkhit					;check whether this punch connected
	;pull toward the fight x unless in ready stance or human controlled (held: always)
	cmpi.w	#SPAfheld,SPA(a3)
	beq.w	.njc
	cmpi.w	#SPAfight,SPA(a3)
	beq.w	.jc
	btst	#pfjoycon,pflags(a3)
	bne.w	.jc
.njc	move.w	(xc1).w,d0			;target x = xc1 + 10 (-10 when facing 2); Xvel += dx * 32
	addi.w	#$A,d0
	cmpi.w	#2,facedir(a3)
	bne.w	.0
	subi.w	#$14,d0
.0	sub.w	(a3),d0					;dx to target
	asl.w	#5,d0					;add to Xvel (92 clamped and set it)
	add.w	d0,Xvel(a3)
.jc	move.w	(yc1).w,d1				;Yvel = (yc1 - Ypos) * 256, clamped +-$1000
	sub.w	Ypos(a3),d1
	asl.w	#8,d1
	cmp.w	#$1000,d1
	blt.w	.y1
	move.w	#$1000,d1
.y1	cmp.w	#-$1000,d1				;upper clamp done
	bgt.w	.y2
	move.w	#$F000,d1
.y2	move.w	d1,Yvel(a3)				;store Yvel
	rts
.al	dc.w	SPAfhigh				;punch animations: high, low, grab
	dc.w	SPAflow
	dc.w	SPAfgrab

chkhit								;part of fight to see if player is hit
									;a3 = player, a0 = opponent
	movem.l	d0/a0-a3,-(sp)
	;evaluate only when the animation frame changed
	move.w	frame(a3),d0
	cmp.w	oldframe(a3),d0
	beq.w	.ex
	;frame fight+2 = gloves dropped
	cmp.w	#SPFfight+2,d0
	beq.w	.dropped
	;opponent must be within 22 px in x and 8 px in y
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
	;punch frame decides: +6 (and +11) high hit, +7 (+12) low hit, +4 (+9) grab
	move.w	frame(a3),d0
	cmp.w	#SPFfight+6,d0
	beq.w	.hithigh
	cmp.w	#SPFfight+6+5,d0
	beq.w	.hithigh
	cmp.w	#SPFfight+7,d0
	beq.w	.hitlow
	cmp.w	#SPFfight+7+5,d0
	beq.w	.hitlow
	cmp.w	#SPFfight+4,d0
	beq.w	.grab
	cmp.w	#SPFfight+4+5,d0
	beq.w	.grab
.ex	movem.l	(sp)+,d0/a0-a3			;restore
	rts
.dropped	bclr	#pf2npc,pflags2(a3)	;pf2npc: gloves dropped
	;glovecords = (xc1 clamped to +-90, /4, never 0 ; yc1/4)
	move.w	(xc1).w,d0
	cmp.w	#90,d0
	blt.w	.chkneg
	moveq	#$5A,d0
.chkneg	cmp.w	#-90,d0				;clamp low
	bgt.w	.drcont
	moveq	#-$5A,d0
.drcont	asr.w	#2,d0				;x/4, never zero
	bne.w	.dr0
	addq.w	#1,d0
.dr0	move.b	d0,(glovecords).w	;store glove x then y
	move.w	(yc1).w,d0
	asr.w	#2,d0
	move.b	d0,(glovecords+1).w
	bra.s	.ex
.grab	exg	a0,a3					;swap: a3 = victim, held animation
	bset	#pf2aip,pflags2(a3)
	move.w	#SPAfheld,d1
	bsr.w	SetSPA
	bra.s	.ex
.hithigh	exg	a0,a3				;swap: a3 = victim; crowd + knock back; temp3 -1 (<0: lost the fight)
	bsr.w	.cwd					;crowd reacts, knock back
	bset	#pf2aip,pflags2(a3)
	subq.w	#1,temp3(a3)
	bmi.w	.fall
	move.w	#SPAfhith,d1
	bsr.w	SetSPA
	move.w	#SFXhithigh,-(sp)		;SFXhithigh
	bsr.w	sfx
	bra.s	.ex
.hitlow	exg	a0,a3					;same for a low hit
	bsr.w	.cwd
	bset	#pf2aip,pflags2(a3)
	subq.w	#1,temp3(a3)
	bmi.w	.fall
	move.w	#SPAfhitl,d1
	bsr.w	SetSPA
	move.w	#SFXhitlow,-(sp)		;SFXhitlow
	bsr.w	sfx
	bra.w	.ex
.cwd								;Crowd reacts to a punch; push the hit player (a3) back by the puncher's
									;(a0) strength
	addi.w	#$50,(Crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
	moveq	#5,d0
	add.w	temp3(a0),d0
	mulu.w	#$1F4,d0				;500
	cmpi.w	#2,facedir(a3)
	bne.w	.xveladj
	neg.w	d0
.xveladj	add.w	d0,Xvel(a3)		;knock back Xvel by (5 + puncher strength) * 500
	rts
.fall								;a3 lost the fight: change the a0 player's penalty to fighting, maybe
									;injure a3
	movem.l	a1,-(sp)
	movea.w	#(PenaltyBufferEnd-M68K_RAM),a1	;end of the scoring summary
.loop	addq.w	#2,a1				;find the winner penalty record: byte $26 whose next byte low nibble =
									;puncher SCnum
	cmpi.b	#$26,(a1)
	bne.s	.loop
	move.b	1(a1),d0
	andi.w	#$F,d0
	cmp.w	SCnum(a0),d0
	bne.s	.loop					;find the penalty of the a0 player
	move.b	#PenFighting2,(a1)		;penalty becomes PenFighting2
	movem.l	(sp)+,a1
	move.w	#$3C,(PenCntDwn).w		;60
	move.w	#$FFFF,temp3(a0)		;temp3 = -1
	addi.w	#$258,(Crowdlevel).w	;600
	addi.w	#$1E,(CwdExciteLvl).w
	moveq	#$3C,d0
	bsr.w	randomd0
	cmp.b	checking(a0),d0			;checking value
	bgt.w	.noinj					;skip injury
	move.w	#$B4,(PenCntDwn).w		;180: player is injured
	bset	#pf2inj,pflags2(a3)
	move.w	#SPAfinjury,d1
	bsr.w	SetSPA
	bsr.w	ClearMessageLine
	movea.w	a3,a2
	bsr.w	setInjuryType
	move.w	#$112C,tmpdst(a0,d1.w)	;overwrite setInjuryType result in the team struct
	move.w	#3,(InjCntDown).w
	bra.w	.ex
.noinj	move.w	#SPAffall,d1		;no injury: loser falls, crowd cheers if loser is visitors, boos if home
	bsr.w	SetSPA
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	#SFXcrowdcheer,-(sp)	;SFXcrowdcheer
	btst	#pfteam,pflags(a3)
	bne.w	.snd
	lea	tmsize(a2),a2
	move.w	#SFXcrowdboo,(sp)		;SFXcrowdboo
.snd	bsr.w	song				;play crowd sound
	bra.w	.ex

ClearMessageLine					;(Rev A). Clear the message line
	bsr.w	printz
	String	$BF,0,1,0
	moveq	#$28,d0
	moveq	#5,d1
	move.w	#$7FF,d2
	bra.w	eraser

banner								;fight banner: close both line change boxes, frame a box with "<player>
									;<team>" for both fighters and "vs"
	movem.l	d0-d3/a0-a4,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	jsr	(lcfound2).l
	adda.w	#tmsize,a2
	jsr	(lcfound2).l
	jsr	(box).l
	movea.w	#(PenBuf-M68K_RAM),a0
	clr.w	d2						;widest line
.find	tst.w	(a0)+				;find end of penalty list
	bne.s	.find
	move.b	-3(a0),d0				;last penalty: the two fighters
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
	tst.b	d3						;stronger fighter on top
	bmi.w	.neg
	move.w	#4,(printy).w
.neg	move.b	-3(a0),d0			;print each fighter line (name, team) in turn
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

addinfo								;d0 = penalty byte (player SCnum in low nibble). Build "<name> <team>" in
									;a1, add fighting to d3, keep widest in d2,
									;centre printx
	movea.w	#(SortCords-M68K_RAM),a1
	andi.w	#$F,d0
	asl.w	#7,d0
	add.b	fighting(a1,d0.w),d3	;fighting
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a1,d0.w)
	beq.w	.0
	adda.w	#tmsize,a2
.0	move.b	pnum(a1,d0.w),d0		;player number
	ext.w	d0
	jsr	(getname).l
	movea.w	a1,a3
	bsr.w	appendz
	String	' ',0
	movea.l	tmdata(a2),a1			;team name
	adda.w	Teamname(a1),a1
	adda.w	(a1),a1
	bsr.w	appstring
	cmp.w	(a3),d2
	bgt.w	.gt
	move.w	(a3),d2
.gt	movea.w	a3,a1					;centre printx on the widest line so far
	move.w	(a1),d0
	lsr.w	#1,d0
	neg.w	d0
	addi.w	#$10,d0
	move.w	d0,(printx).w
	rts

assfwatch							;for player who is watching fight
									;a3 = player
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	;first time: temp1 = 0
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna	sub.w	d7,temp1(a3)		;every 60 frames pick a new spot
	bpl.w	.go
	addi.w	#$3C,temp1(a3)			;new spot every second
	;spot = 80 px from the fight (xc1,yc1) along the line to the player, x clamped to +-$7E
	move.w	(a3),d0
	sub.w	(xc1).w,d0
	move.w	Ypos(a3),d1
	sub.w	(yc1).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	Sroot
	move.w	d0,d2
	bne.w	.d
	moveq	#1,d2
.d	movem.w	(sp)+,d0-d1				;restore dx,dy
	muls.w	#$50,d0					;80 pixels from the fight
	divs.w	d2,d0
	add.w	(xc1).w,d0
	move.w	#$7E,d3
	cmp.w	d3,d0
	blt.w	.x0
	move.w	d3,d0
.x0	neg.w	d3						;upper clamp, then lower
	cmp.w	d3,d0
	bgt.w	.x1
	move.w	d3,d0
.x1	move.w	d0,temp3(a3)			;temp3 = target x
	muls.w	#$50,d1
	divs.w	d2,d1
	add.w	(yc1).w,d1
	move.w	d1,temp4(a3)
.go	move.w	temp3(a3),d0			;skate to the spot
	move.w	temp4(a3),d1
	lea	rtss(pc),a0
	bsr.w	skateto
	bra.w	check4check

donothing							;player should do nothing
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	moveq	#8,d0
	bra.w	doplayeracc

assstanley							;player a3 skates with stanley cup overhead
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	;target x = +-90 by Hpos, y = Vpos: skate there with the cup
	move.w	#$5A,temp3(a3)			;90
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	temp3(a3)
.0	move.w	(Vpos).w,temp4(a3)		;temp4 = y from Vpos
	move.w	#SPAstanley,d1
	bsr.w	SetSPA
.nna	move.w	temp3(a3),d0		;face and accelerate toward the target
	sub.w	(a3),d0
	move.w	temp4(a3),d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	cmp.w	#7,d0
	bgt.w	rtss
	move.w	d0,d2
	move.w	d2,facedir(a3)
	bra.w	playeracc

assscore							;player a3 celebrates, if scoring player then do arm pump
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	bsr.w	.1
	move.w	#8,temp2(a3)
	move.w	#$5A,temp3(a3)
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	temp3(a3)
.0	move.w	(Vpos).w,temp4(a3)		;target y
.nna	movea.l	#rtss,a0			;target in d0/d1, timer temp1
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	;celebration animation when timer runs out: arm pump for the scorer
	sub.w	d7,temp1(a3)
	bpl.w	.chkcon
	bset	#pfalock,pflags(a3)
	move.w	#SPAcelebrate,d1
	move.w	(shotplayer).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.nopump
	move.w	#SPApump,d1
.nopump	bsr.w	SetSPA				;start celebrate/pump animation
.1	moveq	#$78,d0					;120
	bsr.w	randomd0
	move.w	d0,temp1(a3)
	rts
.chkcon	btst	#pfjoycon,pflags(a3)	;computer players skate to the target
	beq.w	skateto
	rts

assdefo								;player a3 is defensive player on offense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	;clock stopped: do nothing
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;re-think every aioff frames
	bpl.w	.nodec
	;re-think every aioff frames: adefd if forced by the offsides flag, puck still on own side of the blue
	;line, or other team has the puck
	move.b	aioff(a3),temp1(a3)
	move.l	#adefd,d0				;adefd
	btst	#tmfoside,tmflags(a2)	;team flag forces defense
	bne.w	assreplace
	move.w	(pucky).w,d1
	btst	#pfgoal,pflags(a3)
	bne.w	.de1
	neg.w	d1
.de1	cmp.w	#$5D,d1				;blueline,d1
	blt.w	assreplace
	move.w	(puckc).w,d1
	bmi.w	.nodec
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace				;other team has puck
.nodec	lea	EvadePC(pc),a0			;target: x +-$50 by position, y +-98 by pfgoal;
	;follow the puck x or half of it
	moveq	#$50,d0
	cmpi.w	#2,position(a3)
	beq.w	.1
	neg.w	d0
.1	move.w	#$62,d1					;98
	btst	#pfgoal,pflags(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0	move.w	(puckx).w,d2			;same side as the puck?
	eor.w	d0,d2
	bmi.w	.2
	move.w	(puckx).w,d0
	bra.w	skateto
.2	move.w	(puckx).w,d2			;other side: x = target + puckx/2
	asr.w	#1,d2
	add.w	d2,d0
	bra.w	skateto

assdefd								;player a3 is defensive player on defense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;re-think every aidef frames
	;re-think every aidef frames: puck y (+lead) up ice beyond $58 and our puck -> adefo
	bpl.w	.de3
	move.b	aidef(a3),temp1(a3)
	move.w	(pucky).w,d1
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	btst	#pfgoal,pflags(a3)
	bne.w	.de00
	neg.w	d1
	neg.w	d3
.de00	tst.w	d3					;only lead when moving up ice
	bpl.w	.v
	clr.w	d3
.v	add.w	d1,d3					;d3 = puck y + lead
	cmp.w	#$58,d3
	blt.w	.de0
	btst	#tmfoside,tmflags(a2)
	bne.w	.de0
	move.w	(puckc).w,d1
	bmi.w	.de0
	bsr.w	chkpk
	beq.w	.de0
	move.l	#adefo,d0				;adefo
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace				;our team has puck
	;temp3 = x spread +-65 (sign by position)
.de0	move.w	#$41,temp3(a3)		;65
	cmpi.w	#2,position(a3)
	beq.w	.de1
	neg.w	temp3(a3)
.de1	movea.w	#(SortCords-M68K_RAM),a0	;a0 = first opponent
	cmpi.w	#6,SCnum(a3)
	bge.w	.de2
	adda.w	#6*SCstruct,a0
.de2	moveq	#5,d2				;Find furthest-up attacker
	move.w	#$FC18,d0				;-1000
	btst	#pfgoal,pflags(a3)
	beq.w	.gdwn
	neg.w	d0
.gup	btst	#pf2unav,pflags2(a0)	;pf2unav
	bne.w	.gu0
	tst.w	position(a0)
	bmi.w	.gu0
	move.w	Yvel(a0),d1
	bmi.w	.gu2
	clr.w	d1
.gu2	asr.w	#4,d1				;92 asr #5
	add.w	Ypos(a0),d1
	cmp.w	d0,d1
	bgt.w	.gu0
	move.w	d1,d0
.gu0	adda.w	#SCstruct,a0		;next opponent
	dbf	d2,.gup
	subi.w	#$32,d0					;50 back of him
	cmp.w	#-190,d0
	bgt.w	.gu1
	move.w	#$FF24,d0				;-220
.gu1	move.w	d0,temp4(a3)		;temp4 = target y
	;if the puck is on the other side, hold x at center
	move.w	(puckx).w,d0
	move.w	temp3(a3),d1
	eor.w	d0,d1
	bpl.w	.de3
	clr.w	temp3(a3)
	bra.w	.de3
.gdwn	btst	#pf2unav,pflags2(a0)	;mirror of .gup for the other goal
	bne.w	.gd0
	tst.w	position(a0)
	bmi.w	.gd0
	move.w	Yvel(a0),d1
	bpl.w	.gd2
	clr.w	d1
.gd2	asr.w	#4,d1				;Yvel/16 lead
	add.w	Ypos(a0),d1
	cmp.w	d0,d1
	blt.w	.gd0
	move.w	d1,d0
.gd0	adda.w	#SCstruct,a0		;next opponent
	dbf	d2,.gdwn
	addi.w	#$32,d0
	cmp.w	#190,d0
	blt.w	.gd1
	move.w	#$DC,d0					;220
.gd1	move.w	d0,temp4(a3)		;temp4 = target y
	neg.w	temp3(a3)
	move.w	(puckx).w,d0
	move.w	temp3(a3),d1
	eor.w	d0,d1
	bpl.w	.de3
	clr.w	temp3(a3)
.de3	move.w	temp3(a3),d0		;skate to (temp3,temp4) avoiding the puck carrier, then look for a check
	move.w	temp4(a3),d1
	movea.l	#EvadePC,a0
	bsr.w	skateto
	bra.w	check4check

asswingd							;player a3 is wing on defense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;re-think every aidef frames
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	;our team has the puck -> awingo
	move.w	(puckc).w,d1
	bmi.w	.nodec
	move.l	#awingo,d0				;awingo
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace				;our team has puck
.nodec	moveq	#$64,d0				;100
	cmpi.w	#5,position(a3)
	bne.w	.0
	neg.w	d0
.0	move.l	#$9E,d1					;d1 = default target y $9E
	btst	#pfgoal,pflags(a3)
	beq.w	.up
	neg.w	d0
	neg.w	d1
	moveq	#-$4E,d2
	btst	#tmfoside,tmflags(a2)
	bne.w	.set
	cmp.w	(pucky).w,d2
	bgt.w	.lo
	move.w	(pucky).w,d1
	bra.w	.go
.lo	move.w	#$FEF8,d2				;-264
	cmp.w	(pucky).w,d2
	blt.w	.go
	move.w	d2,d1
	bra.w	.go
.up	moveq	#$4E,d2					;mirror case: d2 = limit
	btst	#tmfoside,tmflags(a2)
	bne.w	.set
	cmp.w	(pucky).w,d2
	blt.w	.hi
	move.w	(pucky).w,d1
	bra.w	.go
.hi	move.w	#$108,d2				;264
	cmp.w	(pucky).w,d2
	bgt.w	.go
.set	move.w	d2,d1				;y = limit
.go	lea	rtss(pc),a0					;x = puck x if on the same side as the target x (d0), else the target x
	move.w	(puckx).w,d2
	eor.w	d0,d2
	bmi.w	skateto
	move.w	(puckx).w,d0
	bra.w	skateto

;======================================================================
;======================================================================
;	Player assignments from asswingo to asspuckc, then chk4lc, chkpk, chk4shot, CompShoot, chk4pass and
;	EvadePC.

asswingo							;player a3 is winger on offense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	st	temp5(a3)					;temp5 = old zone number
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;re-think every aidef frames
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.l	#awingd,d0				;awingd
	move.w	(puckc).w,d1
	bmi.w	.de0
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace				;other team has puck
.de0	move.w	(pucky).w,d0		;d0 = puck y, d3 = puck y + lead
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	add.w	d0,d3
	btst	#pfgoal,pflags(a3)
	bne.w	.de1
	neg.w	d0
	neg.w	d3
	;zones (d2): 0 own zone, 8 center, 16 opp zone, 24 past the goal line
.de1	clr.w	d2					;Set zone number
	cmp.w	#-Blueline,d3			;-blueline,d3
	blt.w	.de2
	addq.w	#8,d2
	cmp.w	#Blueline,d0			;blueline,d0
	blt.w	.de2
	btst	#tmfoside,tmflags(a2)	;team flag keeps him back
	bne.w	.de2
	addq.w	#8,d2
	cmp.w	#Blueline+goalline,d3	;blueline+goalline,d3
	blt.w	.de2
	addq.w	#8,d2
.de2	cmp.w	temp5(a3),d2		;same zone: re-pick target only at 1 in 128
	bne.w	.de3
	move.w	(HVcount).l,d0			;HV counter as random
	andi.w	#$7F,d0
	bne.w	.nodec
.de3	move.w	d2,temp5(a3)		;new zone: target temp3,temp4 = table x,y + random
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
.dedata								;x, x random, y, y random
	dc.w	80,20,-70,10			;in own zone
	dc.w	100,20,58,5				;center ice area
	dc.w	60,50,230,20			;opp zone
	dc.w	80,30,250,20			;past goalline
.nodec	move.w	temp3(a3),d0		;mirror x by position, y by pfgoal
	cmpi.w	#5,position(a3)
	beq.w	.1
	neg.w	d0
.1	move.w	temp4(a3),d1			;d1 = target y
	btst	#pfgoal,pflags(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0	lea	EvadePC(pc),a0				;skate there avoiding the puck carrier
	bra.w	skateto

asscenterd							;player a3 is center on defense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;re-think every aidef frames
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.w	(puckc).w,d1
	bmi.w	.nodec
	move.l	#acentero,d0			;acentero
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bpl.w	assreplace				;our team has puck
.nodec	move.w	(puckx).w,d0		;target x = puck x / 2; y = -$80, or halfway to the puck y when past the
									;blue line; sign by pfgoal
	asr.w	#1,d0
	move.w	(pucky).w,d2
	btst	#pfgoal,pflags(a3)
	bne.w	.0
	neg.w	d2
.0	moveq	#-$80,d1				;default y
	cmp.w	#-Blueline,d2			;-blueline,d2
	blt.w	.z0
	add.w	(pucky).w,d1
	asr.w	#1,d1
.z0	btst	#pfgoal,pflags(a3)		;flip y for pfgoal
	bne.w	.z1
	neg.w	d1
.z1	lea	rtss(pc),a0					;skate there
	bra.w	skateto

asscentero							;player a3 is center on offense
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	bsr.w	check4bench
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	st	temp5(a3)					;old zone number
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
.nna	sub.b	d7,temp1(a3)		;re-think every aidef frames
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)
	move.w	(puckc).w,d1
	bmi.w	.de0
	move.l	#acenterd,d0			;acenterd
	subq.w	#6,d1
	move.w	SCnum(a3),d2
	subq.w	#6,d2
	eor.w	d2,d1
	bmi.w	assreplace
.de0	move.w	(pucky).w,d0		;d0 = puck y flipped by pfgoal
	btst	#pfgoal,pflags(a3)
	bne.w	.de1
	neg.w	d0
.de1	clr.w	d2					;Set zone number
	cmp.w	#-Blueline,d0			;-blueline,d0
	blt.w	.de2
	addq.w	#8,d2
	cmp.w	#Blueline,d0			;blueline,d0
	blt.w	.de2
	btst	#tmfoside,tmflags(a2)
	bne.w	.de2
	addq.w	#8,d2
	cmp.w	#Blueline+goalline,d0	;blueline+goalline,d0
	blt.w	.de2
	addq.w	#8,d2
.de2	cmp.w	temp5(a3),d2		;same zone: re-pick at 1 in 128
	bne.w	.de3
	move.w	(HVcount).l,d0
	andi.w	#$7F,d0
	bne.w	.nodec
.de3	move.w	d2,temp5(a3)		;pick target
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
.dedata								;x, x random, y, y random per zone
	dc.w	0,60,-70,10
	dc.w	0,60,60,10
	dc.w	0,40,170,30
	dc.w	0,80,170,20
.nodec	move.w	temp3(a3),d0		;target from temp3,temp4
	move.w	temp4(a3),d1
	btst	#pfgoal,pflags(a3)
	bne.w	.0
	neg.w	d1
.0	lea	EvadePC(pc),a0				;skate there avoiding the puck carrier
	bra.w	skateto

assgoalie							;Player a3 is goalie. Also entered from assnearest
	btst	#pfalock,pflags(a3)
	bne.w	rtss
	bsr.w	check4bench
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
	st	temp4(a3)					;temp4 = cover countdown
	;out of position (outside the crease x/y limits or too far out) -> skate back to the net
.nna	cmpi.w	#$34,(a3)			;Outside the crease area?
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
.skate	lea	rtss(pc),a0				;Skate back to the net
	moveq	#4,d0
	tst.w	(a3)
	bpl.w	.0
	neg.w	d0
.0	move.w	#$E4,d1					;target y = $E4, negative for pfgoal
	btst	#pfgoal,pflags(a3)
	beq.w	skateto
	neg.w	d1
	bra.w	skateto
.noskate	btst	#pf2aip,pflags2(a3)	;in position: stand ready unless an animation runs
	bne.w	rtss
	move.w	#SPAgready,d1
	bsr.w	SetSPA
	btst	#gmclock,(gmode).w
	bne.w	rtss
	;temp5 = holding time: counts down while the goalie has the puck; at 0 -> PenGhold
	tst.w	temp5(a3)				;temp5 = holding time
	bmi.w	.nofo
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	.mbfo
	st	temp5(a3)
	bra.w	.nofo
.mbfo	sub.w	d7,temp5(a3)		;goalie holds the puck: countdown
	bpl.w	.nofo
	move.l	#PenGhold,d0
	bsr.w	AddPenalty2
.nofo	sub.b	d7,temp1(a3)		;re-think every aidef/4 frames
	bpl.w	.nodec
	move.b	aidef(a3),d0
	lsr.b	#2,d0					;92 lsr #1
	move.b	d0,temp1(a3)
	btst	#pfjoycon,pflags(a3)
	bne.w	.cover
	move.w	(pucky).w,d0
	move.w	Ypos(a3),d1
	eor.w	d0,d1
	bpl.w	.cnt					;puck in my half
	clr.w	d0						;puck in other half: stay at the top of the crease
	move.w	#$F4,d2
	btst	#pfgoal,pflags(a3)
	beq.w	.de5
	neg.w	d2
	bra.w	.de5
.cnt	subq.w	#1,temp4(a3)		;puck in my half: cover countdown
	bpl.w	.pc
	move.w	#$FFFF,temp4(a3)
.pc	move.w	SCnum(a3),d0			;does the goalie hold the puck?
	cmp.w	(puckc).w,d0
	bne.w	.cover
	tst.w	temp5(a3)
	bpl.w	.hold
	move.w	#$5A,temp5(a3)			;90 frames before holding penalty
.hold	st	temp4(a3)				;holding: arm the 90 frame hold timer, pass only when no opponent is near
	cmpi.w	#$5A,temp5(a3)
	bgt.w	.de1
	move.w	(HVcount).l,d0
	andi.w	#3,d0
	bne.w	.de1
	moveq	#5,d0					;pass only if no opponent is near the puck
	movea.w	#(SortCords-M68K_RAM),a0
	btst	#pfteam,pflags(a3)
	bne.w	.tl
	adda.w	#6*SCstruct,a0
.tl	btst	#pf2unav,pflags2(a0)	;pf2unav
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
.tn	adda.w	#SCstruct,a0			;next opponent
	dbf	d0,.tl
	move.w	#1,(threat).w
	bsr.w	chk4pass
	bra.w	.de1
	;loose puck close to the crease: dive on it
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
	cmp.w	#Blueline+goalline,d1	;blueline+goalline,d1
	bgt.w	.de1
	cmp.w	#-(Blueline+goalline),d1	;-(blueline+goalline),d1
	blt.w	.de1
	sub.w	Ypos(a3),d1
	cmp.w	#30,d1
	bgt.w	.de1
	cmp.w	#-30,d1
	blt.w	.de1
	bsr.w	vtoa
	move.w	d0,facedir(a3)
	move.b	#8,nopuck(a3)
	move.w	#SPAgdive,d1
	bsr.w	SetSPA
	bset	#pf2aip,pflags2(a3)
	addi.w	#$96,(Crowdlevel).w		;150
	addi.w	#$A,(CwdExciteLvl).w
	rts
.de1	movea.w	#(puckcross-M68K_RAM),a0	;a0 = puckcross for this goal, d3 = goal line y
	move.w	#$104,d3				;goal line
	btst	#pfgoal,pflags(a3)
	beq.w	.de2
	addq.w	#4,a0
	neg.w	d3
.de2	cmpi.w	#$104,Ypos(a3)		;behind the goal line -> .out, else .in
	bgt.w	.out
	cmpi.w	#$FEFC,Ypos(a3)
	bgt.w	.in
.out	clr.w	d2					;Behind the goal line
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
.in	move.w	(puckx).w,d0			;Face the puck
	move.w	(pucky).w,d1
	bsr.w	ClampYPosition
	bsr.w	vtoa
	bsr.w	AdjustFacingDirection
	move.w	(gameclock).w,d0		;lead the puck by 160-272/256 of its velocity
	andi.w	#7,d0
	asl.w	#4,d0
	addi.w	#$A0,d0
	cmpi.w	#$DB,(pucky).w
	bgt.w	.lead2
	cmpi.w	#$FF25,(pucky).w
	bgt.w	.lead
.lead2	subi.w	#$40,d0				;puck outside the crease region: smaller lead
.lead	move.w	d0,d1				;lead puck by velocity
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
.far	bsr.w	Sroot				;Scale to an 18 (26 if shooting) pixel arc
	moveq	#1,d2
	add.w	d0,d2
	moveq	#$12,d4
	btst	#sfssdir,(sflags).w
	beq.w	.f0
	addq.w	#8,d4
.f0	movem.w	(sp)+,d0-d1				;scale target to a short arc
	muls.w	d4,d1
	addq.w	#8,d4
	muls.w	d4,d0
	divs.w	d2,d0
	divs.w	d2,d1
.de4	add.w	d3,d1				;absolute target y
	move.w	d1,d2
	;crossing soon and in reach: pick a save animation from GoalieSaveList
	cmpi.w	#$22,2(a0)				;frames til crossing
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
	move.w	d3,d1					;goalline
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	sub.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,d3
	lsr.w	#2,d0					;glove
	btst	#3,attribute(a3)
	beq.w	.noflip
	eori.w	#1,d0
.noflip	cmpi.w	#8,(puckz).w		;save type: +4 stick, -2 stack when conditions hold
	bgt.w	.de7
	cmpi.w	#$800,(puckvz).w
	bgt.w	.de7
	addq.w	#4,d0					;stick
	cmpi.w	#8,2(a0)
	bls.w	.de7
	cmpi.w	#2,facedir(a3)
	beq.w	.de7
	cmpi.w	#6,facedir(a3)
	beq.w	.de7
	tst.w	(puckc).w
	bmi.w	.de7
	subq.w	#2,d0					;stack
.de7	add.w	d0,d0				;index the save list
	lea	GoalieSaveList(pc),a1
	move.w	(a1,d0.w),d1
	cmp.w	#SPAgglovel,d1
	bne.w	.set
	andi.w	#3,d3
	beq.w	.set
	cmpi.b	#$B,GGSleft(a3)
	blt.w	.set
	move.w	#SPAgglovel2,d1
.set	bsr.w	SetSPA				;start save, crowd reacts
	addi.w	#$96,(Crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
.de8	move.w	(a0),d0				;target x = crossing x, or hug the post when the puck is wide
	cmpi.w	#$FC,(pucky).w
	bgt.w	.post
	cmpi.w	#$FF04,(pucky).w
	bgt.w	.de5
.post	moveq	#$18,d0				;Hug the post
	tst.w	(puckx).w
	bpl.w	.de5
	neg.w	d0
.de5	move.w	d2,d1				;target (d0,d2) corrected by velocity; stop when within 4 px
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
.vt	bsr.w	vtoa					;direction to move
	move.b	d0,temp2+1(a3)
.nodec	move.b	temp2+1(a3),d2		;accelerate or stop
	ext.w	d2
	cmp.w	#7,d2
	ble.w	playeracc
	bra.w	stopna
	;rush a loose puck only when nobody is near it and the puck motion says so
.rush	tst.w	(puckc).w			;rush a loose puck only when the
	bpl.s	.de5					;nearest skaters of both teams are far (tmnear)
	btst	#ifok,(iflags).w
	bne.s	.de5
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	btst	#pfteam,pflags(a3)
	beq.w	.t0
	exg	a1,a2
.t0	cmpi.l	#$1324,tmnear(a1)		;own and other team's nearest distance^2 limits
	blt.w	.de5
	cmpi.l	#$9C4,tmnear(a2)
	blt.w	.de5
	cmpi.w	#$E0,(pucky).w
	bgt.w	.dir
	cmpi.w	#$FF20,(pucky).w
	bgt.w	.de5
.dir	tst.w	(puckvy).w			;puck moving toward this goal?
	btst	#pfgoal,pflags(a3)
	beq.w	.dir2
	eori	#8,ccr					;flip N
.dir2	bmi.w	.de5				;Puck moving away
	move.w	(puckvx).w,d0
	bpl.w	.ax
	neg.w	d0
.ax	move.w	(puckvy).w,d1			;|vx| vs |vy|
	bpl.w	.ay
	neg.w	d1
.ay	cmp.w	d0,d1					;sideways puck: do not rush
	blt.w	.de5
	;rush: take assignment assgoalietopuck ($F)
	move.l	#$F,d0					;assgoalietopuck
	bra.w	assinsert

ClampYPosition						;d1 = y clamped to +-$103, minus goal line d3. d0 = 0 if a3 has the puck
									;in: d1 = y, d3 = goal line y. out: d1 = clamped y - d3, d0 cleared if a3
									;is the carrier
	move.w	(puckc).w,d2
	cmp.w	SCnum(a3),d2			;is this player the puck carrier?
	bne.w	.0
	clr.w	d0						;carrier: d0 = 0
.0	cmp.w	#$103,d1				;clamp d1 to the range -$103..$103
	blt.w	.1
	move.w	#$103,d1				;upper limit
.1	cmp.w	#-$103,d1				;check the lower limit
	bgt.w	.2
	move.w	#$FEFD,d1				;lower limit (-$103)
.2	sub.w	d3,d1					;make relative to the goal line
	rts

AdjustFacingDirection				;Turn facedir one step
									;toward direction d0, two steps past the directions the goalie can't
									;face (bit masks by goal end)
									;in: d0 = wanted direction (0-7), a3 = player. out: facedir updated
	move.w	facedir(a3),d1			;d1 = current facing
	sub.w	d1,d0					;d0 = wanted - current
	beq.w	rtss					;already facing the right way
	neg.w	d0
	andi.w	#4,d0					;bit 2 of (current - wanted) picks the turn sense
	lsr.w	#1,d0
	subq.w	#1,d0					;d0 = +1/-1
	btst	d1,#$42					;facing 1 or 6
	beq.w	.add					;no: plain single step
	add.w	d0,d1					;step once and test the new facing
	btst	#pfgoal,pflags(a3)
	bne.w	.dn
	btst	d1,#$83					;0, 1 or 7
	bra.w	.t
.dn	btst	d1,#$38					;3, 4 or 5
.t	beq.w	.set					;new facing not in the mask: keep the step
	neg.w	d0						;in the mask: undo it and turn the other way instead
	add.w	d0,d1
.add	add.w	d0,d1				;apply the step
.set	andi.w	#7,d1				;wrap to 0-7
	move.w	d1,facedir(a3)
	rts

GoalieSaveList						;from 92 assgoalie .list. goalie save choices
									;word table of 6 save animations: glove right/left, pad stack right/left,
									;stick right/left
	dc.w	SPAgglover
	dc.w	SPAgglovel
	dc.w	SPAgstackr
	dc.w	SPAgstackl
	dc.w	SPAgstickr
	dc.w	SPAgstickl

assgoalietopuck						;goalie skates out to a loose puck (inserted by
									;assgoalie)
	btst	#pfjoycon,pflags(a3)	;human controlled goalie: nothing to do
	bne.w	assexit
	btst	#gmclock,(gmode).w		;clock stopped: nothing to do
	bne.w	assexit
	bsr.w	check4bench
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	clr.w	temp1(a3)				;fresh assignment: decision timer expires at once
.nna	sub.b	d7,temp1(a3)		;count the timer down by d7 (elapsed frames)
	bpl.w	.go						;still running: keep skating to the puck
	move.b	aidef(a3),d0
	lsr.b	#2,d0
	move.b	d0,temp1(a3)			;reload timer = defensive rating / 4
	tst.w	(puckc).w
	bpl.w	assexit					;someone has the puck: stay
	tst.w	(puckvy).w				;N = puck y velocity sign
	btst	#pfgoal,pflags(a3)
	beq.w	.dir
	eori	#8,ccr					;flip N for the other goal end
.dir	bmi.w	assexit				;puck moving away from this goalie
	movea.w	#(tmstruct-M68K_RAM),a1	;a1 = own team struct, a2 = the other one
	lea	tmsize(a1),a2
	btst	#pfteam,pflags(a3)
	beq.w	.t0
	exg	a1,a2
.t0	cmpi.l	#$E10,tmnear(a1)		;each team's nearest distance^2 (tmnear) vs limits
	blt.w	assexit
	cmpi.l	#$640,tmnear(a2)
	blt.w	assexit
.go	bra.w	skatetopuck				;keep skating to the puck

asspuckc							;player a3 is puck handler
									;computer logic for the puck carrier: look for check/line
									;change/shot/pass, then skate
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0			;is a3 really the carrier?
	bne.w	assexit					;no: assignment is over
	btst	#pfalock,pflags(a3)		;animation lock: leave
	bne.w	rtss
	btst	#gmclock,(gmode).w		;clock stopped: stand still
	bne.w	donothing
	btst	#pfjoycon,pflags(a3)	;human controlled: nothing to do
	bne.w	assexit
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	clr.w	temp1(a3)				;timer = 0: the decisions below run at once
	move.w	#8,temp2(a3)
	move.w	(HVcount).l,d0
	andi.w	#3,d0
	move.w	d0,temp3(a3)			;temp3 = random 0-3
.nna	sub.b	d7,temp1(a3)		;decision timer counts down by d7 (elapsed frames)
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)		;reload timer from the offensive rating
	bsr.w	checkob					;the decisions: board check, line change, shot, pass
	bsr.w	chk4lc
	bsr.w	chk4shot
	bsr.w	chk4pass
.nodec	moveq	#6,d0				;d0 = 6 + temp3: index of one of 4 random onside spots
	add.w	temp3(a3),d0
	lea	.postab(pc),a0
	btst	#sf2offsig,(sflags2).w	;someone is over the line
	beq.w	.nd1
	move.w	position(a3),d0			;offsides: use the spot for my position instead
.nd1	asl.w	#2,d0				;4 bytes per entry (x,y words)
	move.w	2(a0,d0.w),d1			;d1 = y target
	move.w	(a0,d0.w),d0			;d0 = x target
	btst	#pfgoal,pflags(a3)
	bne.w	.nd0
	neg.w	d0						;mirror both for the other goal end
	neg.w	d1
.nd0	lea	.chkdir(pc),a0			;a0 = routine skateto calls to adjust the direction
	bra.w	skateto
.chkdir	ext.w	d0					;d0 = skate direction chosen by skateto
	move.b	Xvel(a3),d2
	ext.w	d2
	add.w	(puckx).w,d2			;d2 = puck x + my x velocity (predicted spot)
	move.b	Yvel(a3),d3
	ext.w	d3
	add.w	(pucky).w,d3			;d3 = puck y + my y velocity
	clr.w	(threat).w
	moveq	#5,d4					;loop over the 6 opposing sort objects
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.cd0
	adda.w	#6*SCstruct,a0			;a3 is home (0-5): opponents are objects 6-11
.cd0	move.b	Xvel(a0),d1			;opponent x + velocity - predicted puck x
	ext.w	d1
	add.w	(a0),d1
	sub.w	d2,d1
	cmp.w	#20,d1					;within 20 units in x?
	bgt.w	.next
	cmp.w	#-20,d1
	blt.w	.next
	move.b	Yvel(a0),d1				;same test in y
	ext.w	d1
	add.w	Ypos(a0),d1
	sub.w	d3,d1
	cmp.w	#20,d1
	bgt.w	.next
	cmp.w	#-20,d1
	blt.w	.next
	addq.w	#1,(threat).w			;count an opponent close to the puck
	move.w	(a3),d0
	sub.w	(a0),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a0),d1
	bsr.w	vtoa					;d0 = direction from the opponent to me
	move.w	facedir(a3),d1
	eori.w	#4,d1					;d1 = direction opposite to my facing
	cmp.w	d0,d1
	bne.w	.next
	move.w	(HVcount).l,d1			;turn either way
	andi.w	#1,d1
	add.w	d1,d0
	andi.w	#7,d0
.next	adda.w	#SCstruct,a0		;next opponent
	dbf	d4,.cd0
	rts
.postab								;x,y by position when offsides (1-5), then 4
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

chk4lc								;see if computer should call line change
	move.w	(pucky).w,d0			;d0 = puck y, made positive toward the goal I shoot at
	btst	#pfgoal,pflags(a3)
	bne.w	.gu
	neg.w	d0
.gu	tst.w	d0						;d0 = puck y toward the goal I shoot at
	bmi.w	rtss					;puck behind the center line: no change
	cmp.w	#Blueline,d0			;blueline,d0
	bgt.w	rtss					;puck beyond the blue line: no change
	move.w	(HVcount).l,d0			;HVcount
	andi.w	#3,d0					;random: only 1 time in 4
	bne.w	rtss
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	bne.w	rtss					;already in line change mode
	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = own team struct, a1 = the other one
	lea	tmsize(a2),a1
	btst	#pfteam,pflags(a3)
	beq.w	.0
	exg	a2,a1
.0	bsr.w	AvgCline				;d0 = average energy of the current line of team a2
	cmp.w	#$C00,d0
	bhi.w	rtss					;above $C00: no line change
	bsr.w	CompLine				;pick and apply the new line
	bsr.w	setpersonel
	bsr.w	printscores1
	bra.w	CompShoot				;then clear the puck by shooting it

chkpk								;return z flag set if killing penalty
									;return z flag clr if not
	btst	#sf2pwrplay,(sflags2).w	;power play in progress?
	bne.w	chkpk2
	eori	#4,ccr					;no power play returns ne
	rts

chkpk2	movem.l	d0-d1,-(sp)			;compare the power play team flag with a3's team bit
	btst	#sf2pwrtm,(sflags2).w
	move.w	sr,d0					;d0 = ccr after the first test
	btst	#pfteam,pflags(a3)
	move.w	sr,d1					;d1 = ccr after the second
	eor.w	d1,d0					;Z set if the two bits differ (a3's team is killing)
	move.w	d0,ccr
	movem.l	(sp)+,d0-d1
	rts

chk4shot							;player a3 looks for shot (computer controlled)
									;decide whether the computer carrier shoots; rtss = no shot, else falls to
									;CompShoot
	bsr.s	chkpk
	bne.w	.npk					;not pkilling
	tst.w	(threat).w
	beq.w	.npk					;no threat
	move.w	(HVcount).l,d0
	andi.w	#3,d0
	beq.w	CompShoot				;clear puck (no icing if pkilling)
.npk	moveq	#$20,d4				;shot range d4 from the shooting odds
	sub.b	spodds(a3),d4			;shot/pass odds
	asl.w	#4,d4					;d4 = ($20 - odds) * 16: the shot "range" for randomd0
	move.w	#Blueline+goalline,d1	;blueline+goalline
	btst	#pfgoal,pflags(a3)
	bne.w	.c0
	neg.w	d1
.c0	sub.w	(pucky).w,d1			;d1 = y distance to the goal line, d0 = x distance to center
	move.w	(puckx).w,d0
	neg.w	d0
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d0,d1					;distance from goal squared
	cmp.l	#100*100,d1
	movem.w	(sp)+,d0-d1
	bhi.w	.no1					;farther than 100 from the goal: keep d4 as is
	lsr.w	#4,d4					;close: d4 = $20 - odds
	bsr.w	vtoa					;d0 = direction to the goal
	move.w	d0,d5					;d5 = shot direction
	moveq	#5,d3					;check the 6 opposing sort objects
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	bge.w	.co0
	adda.w	#6*SCstruct,a1			;a3 is home: opponents are objects 6-11
.co0	tst.w	position(a1)		;next opponent: is he in the shot line?
	beq.w	.gl						;position 0 = the goalie
	move.w	(a1),d0					;direction from puck to this skater
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
	sub.w	(pucky).w,d1
	bsr.w	vtoa
	cmp.w	d5,d0
	bne.w	.co1
	asl.w	#1,d4					;defender in the shot line
	bra.w	.co1
.gl	btst	#pf2aip,pflags2(a1)		;goalie busy, shoot now
	beq.w	.co1
	clr.w	d3						;end the loop after this object
	moveq	#1,d4					;tiny range: shot is almost certain
.co1	adda.w	#SCstruct,a1		;next opponent
	dbf	d3,.co0
.no1	move.w	d4,d0				;random roll against the shot range d4
	bsr.w	randomd0				;0 <= d0 < d4
	cmp.w	#8,d0
	bgt.w	rtss					;random roll above 8: no shot
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0	tst.w	d0					;d0 = puck y toward the goal I shoot at
	bmi.w	rtss					;don't shoot from behind center line
	move.w	#$108,d1
	sub.w	d0,d1
	bmi.w	rtss					;puck farther than $108 along the shooting direction
	btst	#sf2offsig,(sflags2).w
	bne.w	rtss					;player is offsides
CompShoot							;player a3 shoots (computer controlled player)
	addq.w	#4,sp					;don't return
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0	move.w	#$108,d1			;d0 = puck y toward the goal I shoot at
	sub.w	d0,d1					;d1 = distance to $108 along the shooting direction
	lsr.w	#3,d1
	cmp.w	#20,d1
	blt.w	.lt
	moveq	#$14,d1					;limit to 20
.lt	move.w	d1,temp2(a3)			;temp2 = swing time
	move.l	#ashoot,d0				;ashoot
	bra.w	assreplace

chk4pass							;player a3 looks for good pass (computer controlled)
	tst.w	(threat).w
	bne.w	.dp0					;an opponent is close: always consider a pass
	moveq	#$10,d0
	add.b	spodds(a3),d0
	bsr.w	randomd0				;0 <= d0 < $10 + odds
	cmp.w	#8,d0
	bgt.w	rtss					;random roll above 8: no pass
.dp0	moveq	#6,d0				;Set up pass assignment
	bsr.w	randomd0				;d0 = random teammate index 0-5
	cmpi.w	#6,SCnum(a3)
	blt.w	.dp1
	addq.w	#6,d0					;visitors are sort objects 6-11
.dp1	tst.w	position(a3)		;from the goalie, or skaters
	beq.w	.bl						;outside the slot only
	cmpi.w	#$28,(puckx).w			;slot = x within +-$28 ...
	bgt.w	.bl
	cmpi.w	#$FFD8,(puckx).w
	blt.w	.bl
	cmpi.w	#$CC,(pucky).w			;... and y within +-$CC
	bgt.w	rtss
	cmpi.w	#$FF34,(pucky).w
	blt.w	rtss
.bl	cmp.w	SCnum(a3),d0			;receiver chosen (d0): validate him
	beq.w	rtss					;don't pass to yourself
	asl.w	#7,d0					;d0 * SCstruct ($80)
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0					;a0 = receiver sort object
	tst.w	position(a0)
	ble.w	rtss					;don't pass to goalie or illegal player
	btst	#pf2unav,pflags2(a0)	;pf2unav
	bne.w	rtss
	btst	#pfalock,pflags(a0)
	bne.w	rtss					;don't pass to locked player
	move.w	Ypos(a0),d0				;check for pass across blue line
	move.w	Ypos(a3),d1				;d0 = receiver y, d1 = my y (toward the goal I shoot at)
	btst	#pfgoal,pflags(a3)
	bne.w	.f0
	neg.w	d0
	neg.w	d1
.f0	btst	#gmoffs,(gmode).w		;offsides on?
	beq.w	.oko
	movem.w	d0-d1,-(sp)
	subi.w	#$58,d0					;y relative to the blue line
	subi.w	#$58,d1
	eor.w	d0,d1					;sign differs if the pass crosses the blue line
	movem.w	(sp)+,d0-d1
	bmi.w	rtss					;(movem keeps the flags) no pass across the blue line
.oko	cmp.w	#Blueline,d0		;blueline,d0
	bgt.w	.ok
	sub.w	d1,d0					;receiver not past the blue line: d0 = his y - mine
	cmp.w	#-15,d0
	blt.w	rtss					;don't pass backward by more than 15
.ok	move.w	(a0),d0					;receiver accepted: get the pass direction
	sub.w	(puckx).w,d0
	move.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa					;direction puck -> receiver
	move.w	d0,(passdir).w
	movem.w	(sp)+,d1-d2
	muls.w	d1,d1
	muls.w	d2,d2
	add.l	d1,d2					;d2 = squared distance to the receiver
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	bge.w	.co0
	adda.w	#6*SCstruct,a1			;loop over the 6 opponents
.co0	move.w	(a1),d0				;next opponent: is he in the pass lane?
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d0,d1					;d1 = squared distance to this opponent
	cmp.l	d2,d1
	movem.w	(sp)+,d0-d1
	bhi.w	.co1					;farther than the receiver: ignore
	bsr.w	vtoa
	cmp.w	(passdir).w,d0
	beq.w	rtss					;opponent in the pass lane
.co1	adda.w	#SCstruct,a1		;next opponent
	dbf	d3,.co0
	bsr.w	dopass					;lane is clear: pass in passdir
	tst.w	position(a3)
	beq.w	rtss					;goalie returns to the caller
	addq.w	#4,sp					;skater: drop the return address and end the assignment
	bra.w	assexit

EvadePC								;player a3 should avoid the puck carrier if he's on my team out: d0 =
									;direction 0-7 pointing away from the puck (from vtoa), adjusted near the
									;blue line
	tst.w	(puckc).w
	bmi.w	rtss					;no puck handler
	move.b	Xvel(a3),d2
	sub.b	(puckvx).w,d2			;relative x velocity (a3 minus puck)
	ext.w	d2
	add.w	(a3),d2
	sub.w	(puckx).w,d2			;d2 = relative x after one step
	cmp.w	#40,d2					;farther than 40 in x: ignore
	bgt.w	rtss
	cmp.w	#-40,d2
	blt.w	rtss
	move.b	Yvel(a3),d1
	sub.b	(puckvy).w,d1
	ext.w	d1
	add.w	Ypos(a3),d1
	sub.w	(pucky).w,d1			;same for y
	cmp.w	#40,d1
	bgt.w	rtss
	cmp.w	#-40,d1
	blt.w	rtss
	move.w	(a3),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a3),d1
	sub.w	(pucky).w,d1
	bsr.w	vtoa					;d0 = direction from the puck to me
	btst	#gmoffs,(gmode).w		;with offsides on, don't skate
	beq.w	.x						;offside: go sideways near the blue line
	move.w	Ypos(a3),d1
	btst	#pfgoal,pflags(a3)
	bne.w	.y
	neg.w	d1
.y	subi.w	#$58,d1					;d1 = y relative to the blue line
	cmp.w	#10,d1
	bgt.w	.x						;more than 10 past it: keep d0
	cmp.w	#-50,d1
	blt.w	.x						;more than 50 before it: keep d0
	moveq	#2,d0					;near the blue line: go sideways, d0 = 2 if x > puck x...
	move.w	(a3),d1
	cmp.w	(puckx).w,d1
	bgt.w	.x
	moveq	#6,d0					;...else 6 (directions 2 and 6 are the two sideways ones)
.x	rts								;return d0 = direction

;======================================================================
;======================================================================
;	checkob, assnearest, check4check, asspassrec, assshoot, then the puck object: pucknothing, puckfaceoff and
;	its goalie and line helpers, puckfaceoff2, updatefaceoff, Endfaceoff and pucknorm.

checkob								;bring up little warning ref if a player on your team is over blue line.
									;Called from doinput and asspuckc
									;a3's team: if the puck is not yet across the blue line and any of its 6
									;players is, show the ref
	btst	#gmoffs,(gmode).w		;offsides rule on?
	beq.w	rtss
	movem.l	d0-d1/a0,-(sp)
	moveq	#5,d0					;6 players of a3's team
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	blt.w	.0
	adda.w	#6*SCstruct,a0			;a0 = first sort object of a3's team
.0	moveq	#$5C,d1					;blue line y (92 move blueline,d1)
	btst	#pfgoal,pflags(a3)
	bne.w	.top					;shooting at the top goal: mirrored tests below
	neg.w	d1						;d1 = -$5C
	cmp.w	(pucky).w,d1
	bgt.w	.nob					;puck already across the line: nobody can be offside
.bottom	tst.w	position(a0)		;loop over the team, skipping negative positions
	bmi.w	.bn
	cmp.w	Ypos(a0),d1
	bgt.w	.ob						;this player is over the line
.bn	adda.w	#SCstruct,a0			;next player
	dbf	d0,.bottom
.nob	moveq	#$40,d0				;no one offside: d0 = $40 = clear the ref window (PushRef)
	bclr	#sf2offsig,(sflags2).w	;clear the offsides ref flag
	bne.w	.dref					;it was on: update the ref
.ex	movem.l	(sp)+,d0-d1/a0			;restore registers and return
	rts

.ob	moveq	#6,d0					;ref frame 6 for PushRef (92 moveq #32,d0)
	bset	#sf2offsig,(sflags2).w	;someone is offsides: show the little ref
	bne.s	.ex						;already shown
.dref	tst.w	(RefCnt).w			;only when the ref queue is idle (negative)
	bpl.s	.ex
	bsr.w	PushRef
	bra.s	.ex

.top	cmp.w	(pucky).w,d1		;mirror of .bottom for y > 0
	blt.s	.nob
.top1	tst.w	position(a0)		;loop over the team's players (top goal)
	bmi.w	.tn
	cmp.w	Ypos(a0),d1
	blt.s	.ob
.tn	adda.w	#SCstruct,a0			;next player
	dbf	d0,.top1
	bra.s	.nob

assnearest							;this is a special assignment used for the player who is nearest the puck
									;but doesn't have it. Assignment anearest ($11)
									;a2 = a3's team struct, d7 = elapsed frames. temp1 = re-evaluation timer,
									;temp3 = hold timer
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	clr.w	temp3(a3)
	move.w	#8,temp2(a3)
	clr.w	temp1(a3)
.nna	move.w	SCnum(a3),d1		;new assignment handled: who has the puck?
	cmp.w	(puckc).w,d1
	bne.w	.nopc
	tst.w	position(a3)			;a3 has the puck
	beq.w	assgoalie				;goalie: use the goalie assignment
	move.l	#apuckc,d0				;apuckc
	btst	#pfjoycon,pflags(a3)
	beq.w	assinsert				;computer skater: become the puck carrier
	rts								;human controlled: leave as is
.nopc	sub.b	d7,temp1(a3)		;timer expired?
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)		;reload timer from the offensive rating
	clr.l	tmnear(a2)				;team long, set to best distance below
	move.w	(puckc).w,d1
	bmi.w	.np						;puck is loose
	asl.w	#scsize,d1				;scsize
	movea.w	#(SortCords-M68K_RAM),a1
	adda.w	d1,a1					;a1 = carrier's sort object
	move.b	pflags(a1),d0
	move.b	pflags(a3),d1
	eor.b	d0,d1
	btst	#pfteam,d1
	beq.w	.switch					;our team has the puck
.np	moveq	#-1,d2					;d2 = best (smallest) squared distance so far, unsigned max
	moveq	#5,d4					;loop over the 6 players of the team
	movea.w	tmsort(a2),a0			;tmsort: first player of the team (92 from SCnum)
.de0	tst.w	position(a0)		;loop over the 6 team players for the nearest to the puck
	ble.w	.next					;skip goalies and absent players
	tst.b	nopuck(a0)
	bne.w	.next
	btst	#pf2unav,pflags2(a0)	;pf2unav
	bne.w	.next
	move.w	assnum(a0),d0			;skip a player whose current assignment
	cmpi.b	#apassrec,asslist(a0,d0.w)	;is apassrec
	beq.w	.next
	move.l	a0,-(sp)				;GetHot takes the structure address on the stack
	bsr.w	GetHot					;d0/d1 = hot spot x/y of this player
	add.w	(a0),d0
	sub.w	(puckx).w,d0
	add.w	Ypos(a0),d1
	sub.w	(pucky).w,d1			;d0/d1 = player (plus hot spot) minus puck
	move.w	(puckvx).w,d3			;always lead the puck (if carried)
	asr.w	#6,d3
	sub.w	d3,d0
	move.w	(puckvy).w,d3
	asr.w	#6,d3
	sub.w	d3,d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0					;d0 = squared distance
	cmp.l	d2,d0
	bhi.w	.next					;not better than the best
	move.l	d0,d2
	movea.w	a0,a1					;a1 = nearest player so far
.next	adda.w	#SCstruct,a0		;next player
	dbf	d4,.de0
	tst.l	d2
	bmi.w	.de1					;nobody qualified
	move.l	d2,tmnear(a2)			;nearest distance^2
.switch	cmpa.w	a1,a3				;a1 = the player who should chase the puck
	beq.w	.de1					;that is me
	btst	#gmclock,(gmode).w		;clock stopped: no swap
	bne.w	.de1
	btst	#pf2unav,pflags2(a1)	;pf2unav
	bne.w	.de1					;the nearest is unavailable
	exg	a1,a3						;make the nearest player a3 for a moment ...
	bclr	#pfdoff,pflags(a3)
	move.l	#anearest,d0			;anearest
	bsr.w	assinsert				;... and give him the assnearest assignment
	exg	a1,a3
	bra.w	assexit					;I (old a3) drop this assignment
.de1	btst	#pfalock,pflags(a3)	;locked: skip
	bne.w	rtss
	moveq	#2,d1					;d1 = shift count for the random range below
	cmp.w	#$190,d2				;20^2,d2 (commented out in 92)
	bhi.w	.nfar					;nearest distance^2 above 400: far
	subq.w	#2,d1					;close: d1 = 0
	cmpi.w	#2,position(a3)
	bls.w	.nodec					;close and position <= 2: no new temp3
.nfar	btst	#sf2pwrplay,(sflags2).w	;power play in progress?
	beq.w	.x
	subq.w	#2,d1
	bsr.w	chkpk2
	bne.w	.x						;not killing penalty
	addq.w	#4,d1					;killing a penalty: much larger range
.x	moveq	#$14,d0					;random range ($14 - checking) << d1
	sub.b	checking(a3),d0			;checking
	asl.w	d1,d0					;range = ($14 - checking) << d1
	bsr.w	randomd0
	cmp.w	#1,d0					;(92 #2)
	bhi.w	.nodec					;usually nothing
	move.w	#$F0,temp3(a3)			;temp3 = 240
.nodec	btst	#pfalock,pflags(a3)	;locked: skip
	bne.w	rtss
	btst	#gmclock,(gmode).w
	bne.w	donothing
	btst	#pfjoycon,pflags(a3)
	bne.w	rtss
	btst	#tmfmid,tmflags(a2)		;tmflags bit 2 always takes the in-between spot
	bne.w	.mid
	tst.w	(puckc).w
	bmi.w	.topuck					;loose puck: go straight for it
	sub.w	d7,temp3(a3)			;puck is carried: temp3 counts down, then fall through to .mid
	bpl.w	.topuck
	clr.w	temp3(a3)
.mid	bsr.w	skatetopuckinit		;d0/d1 = halfway between
	movem.w	d0-d1,-(sp)				;skatetopuckinit's spot and (0,$F4),
	neg.w	d0						;or (0,-$F4) if pfgoal
	neg.w	d1
	addi.w	#$F4,d1
	btst	#pfgoal,pflags(a3)
	beq.w	.nd0
	subi.w	#$1E8,d1				;$F4 - $1E8 = -$F4
.nd0	asr.w	#1,d0				;average with the skatetopuckinit spot
	asr.w	#1,d1
	add.w	(sp)+,d0
	add.w	(sp)+,d1
	btst	#tmfmid,tmflags(a2)		;tmflags bit 2: clamp y to +-$44 from $53
	beq.w	.go
	btst	#pfgoal,pflags(a3)
	beq.w	.neg
	cmp.w	#$53,d1
	blt.w	.go
	move.w	#$44,d1					;limit y when it is beyond $53
	bra.w	.go
.neg	cmp.w	#-$53,d1			;mirrored for the other goal end
	bgt.w	.go
	move.w	#-$44,d1
.go	lea	rtss(pc),a0					;no extra routine for skateto
	bsr.w	skateto					;skate to d0/d1
	bra.w	check4check
.topuck	bsr.w	skatetopuck			;Falls into check4check

check4check							;look for good opportunity for checking opponent. Falls in from
									;assnearest; also entered from assfwatch and asswingd roll against
									;the checking rating first, then look for an opponent within 30 units
									;whom a3 is facing
	moveq	#$14,d0
	sub.b	checking(a3),d0			;checking
	tst.w	(OptPen).w				;OptPen nonzero (penalties off): double the range
	beq.w	.nopen
	asl.w	#1,d0
.nopen	bsr.w	randomd0			;0 <= d0 < ($14 - aggress) [*2]
	cmp.w	#3,d0					;(92 tst d0)
	bhi.w	rtss					;above 3: no check this time
	moveq	#5,d2					;loop over the 6 opposing sort objects
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.0
	adda.w	#6*SCstruct,a0			;a3 is home: opponents are objects 6-11
.0	tst.w	position(a0)			;test this opponent
	beq.w	.next					;skip the goalie
	btst	#pfalock,pflags(a0)		;skip
	bne.w	.next
	btst	#pf2fight,pflags2(a0)	;skip
	bne.w	.next
	move.w	(a0),d0
	sub.w	(a3),d0					;dx to the opponent
	cmp.w	#30,d0
	bgt.w	.next
	cmp.w	#-30,d0
	blt.w	.next
	move.w	Ypos(a0),d1
	sub.w	Ypos(a3),d1				;dy to the opponent
	cmp.w	#30,d1
	bgt.w	.next
	cmp.w	#-30,d1
	blt.w	.next
	bsr.w	vtoa					;d0 = direction to the opponent
	cmp.w	facedir(a3),d0
	bne.w	.next					;not facing him
	move.w	(HVcount).l,d0			;HV counter as random, 1 in 4 is a
	andi.w	#3,d0					;hold/hook instead of a check
	bne.w	burst					;3 in 4: burst/check (cbut press)
	bra.w	Acheck					;1 in 4: hold or hook on a0
.next	adda.w	#SCstruct,a0		;next opponent
	dbf	d2,.0
	rts

asspassrec							;assignment for catching pass. Assignment apassrec ($13)
	btst	#pfalock,pflags(a3)		;animation lock: leave
	bne.w	rtss
	btst	#gmclock,(gmode).w		;clock stopped: stand still
	bne.w	donothing
	btst	#pfjoycon,pflags(a3)	;human controlled: nothing to do
	bne.w	assexit
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	bset	#pfdoff,pflags(a3)		;deceleration off while waiting for the pass
	move.b	#8,temp2+1(a3)			;temp2 = 8
	clr.b	temp2(a3)				;temp2 high byte
.nna	tst.w	(puckc).w			;puck carried: assignment is over
	bpl.w	.ex						;puck is carried: assignment is over
	sub.b	d7,temp1(a3)			;puck loose: wait temp1 (92 bmi skatetopuck)
	bpl.w	rtss					;still waiting
.ex	bclr	#pfdoff,pflags(a3)		;deceleration back on
	bra.w	assexit
;unreferenced: skate to temp3/temp4
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	lea	rtss(pc),a0
	bra.w	skateto

assshoot							;assignment for computer shooting. Assignment ashoot ($12)
	btst	#pfalock,pflags(a3)		;animation lock: leave
	bne.w	rtss
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	bra.w	SetShotMode				;first frame: start the shot (temp2 = swing time set by CompShoot)
.nna	btst	#sfssdir,(sflags).w	;still in set-shot-dir mode?
	beq.w	assexit					;no: the shot is done
	clr.w	d2						;(92 also loads temp1 into d0)
	sub.w	d7,temp2(a3)			;count the swing time down
	bpl.w	ShotMode				;still swinging: feed ShotMode no buttons
	bset	#cbut,d2				;cbut
	bra.w	ShotMode				;swing time over: press the shot button (cbut)

	IF REV<2
pucknothing							;puck just slides along
	bra.w	puckunflip
	ENDIF							;Rev B has no pucknothing thunk: the puck table points at puckunflip

puckfaceoff							;this is where the action starts
									;a3 = the face off controller; first call (pfna set) checks for end of
									;period, then offers line changes; later calls (.nna) wait for both line
									;change timers, then go to pfaceoff2
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	tst.w	(gameclock).w
	beq.w	PeriodOver				;clock ran out
	btst	#gmeog,(gmode).w		;gmode bit 6 also ends the period
	bne.w	PeriodOver
	cmpi.w	#3,(gsp).w				;gsp 3 = overtime
	bne.w	.npo
	move.w	(tmstruct+tmscore).w,d0
	cmp.w	(awtmstruct+tmscore).w,d0
	bne.w	clockcont_0				;overtime and not tied: leave via clockcont_0
.npo	btst	#gmpendel,(gmode).w	;delayed penalty called?
	bne.w	Stop4Pen
	move.w	(PerTimeTotal).w,d0		;song $34 once, at the first faceoff
	asr.w	#1,d0					;past half the period with 60 s or more left,
	cmp.w	(gameclock).w,d0		;while sflags3 bit 7 is set
	bls.w	.rg
	cmpi.w	#$3C,(gameclock).w
	blt.w	.rg
	bclr	#sf3fosong,(sflags3).w
	beq.w	.rg
	btst	#gmclock,(gmode).w
	beq.w	.rg
	move.w	#SngFaceoff,-(sp)
	bsr.w	song
.rg	bsr.w	ReturnGoalies			;computer may put the goalie back / pull it
	st	temp1(a3)					;temp1/temp2 made negative: no line change timer running
	st	temp2(a3)
	tst.w	(OptLine).w				;line changes off (OptLine nonzero): go wait
	bne.w	.nna
	bclr	#tmflcm,(tmstruct+tmflags).w	;bit 1
	bclr	#tmflcm,(awtmstruct+tmflags).w	;bit 1
	movea.w	#(SortCords-M68K_RAM),a0	;clear pf2lcm on all 12 players
	moveq	#$B,d0
.lcm	bclr	#pf2lcm,pflags2(a0)	;next player
	adda.w	#SCstruct,a0
	dbf	d0,.lcm
	move.w	(cont1team).w,d0
	or.w	(cont2team).w,d0
	beq.w	.nohor					;no human team
	btst	#sfhor,(sflags).w
	beq.w	.nohor					;screen is not in horizontal mode
	bsr.w	forceblack				;leave horizontal mode: blank the screen
	bset	#sfslock,(sflags).w
	bsr.w	ClrHor
	move.w	#$18,(palcount).w
.nohor	move.w	(c1playernum).w,d0	;offer a line change to each human controlled player
	bmi.w	.nlp
	bsr.w	.slc
.nlp	move.w	(c2playernum).w,d0	;same for the second controller's player
	bmi.w	.nlp2
	bsr.w	.slc
.nlp2	movea.w	#(tmstruct-M68K_RAM),a1	;computer line change for the visitors:
	lea	tmsize(a1),a2				;a2 = visitors, a1 = home
	moveq	#2,d0					;team number 2
	bsr.w	.sclc
	bra.w	.nna					;the home team is handled at .nna

.sclc	tst.w	(OptLine).w			;computer line change for team d0 (a2 = it, a1 = other)
	bne.w	rtss
	cmp.w	(cont1team).w,d0
	beq.w	rtss					;human controlled teams choose their own
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	bsr.w	CompLine
	bsr.w	setpersonel
	bra.w	printscores1

.slc	exg	a2,a3					;in: d0 = sort object number of a human player.
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3					;a3 = that player, a2 = the face off controller
	bclr	#pf2lcm,pflags2(a3)		;pf2lcm
	move.l	a2,-(sp)
	bsr.w	SetLCmode				;try to start line change mode for him
	movea.l	(sp)+,a2
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	beq.w	.slcex					;not started (line change not available)
	btst	#pfteam,pflags(a3)
	beq.w	.t1
	move.w	#$168,temp2(a2)			;temp2 = 6*60 (92 3*60)
	move.w	SCnum(a3),temp4(a2)		;temp4 = SCnum
	bra.w	.slcex					;visitors use temp2/temp4 of the controller
.t1	move.w	#$258,temp1(a2)			;temp1 = 10*60 (92 5*60)
	move.w	SCnum(a3),temp3(a2)		;temp3 = SCnum
.slcex	exg	a2,a3					;a3 = controller again
	rts
.nna	move.w	#temp1,d0			;temp1
	bsr.w	.clc					;service the home player's line change timer
	move.w	#temp2,d0				;temp2
	bsr.w	.clc					;and the visitor's
	tst.w	temp1(a3)
	bpl.w	rtss					;a timer is still running: wait
	tst.w	temp2(a3)
	bpl.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a2	;both done: computer line change for the home team
	lea	tmsize(a2),a1
	moveq	#1,d0					;team number 1
	bsr.w	.sclc
	move.w	#pfaceoff2,d0			;pfaceoff2
	bra.w	assreplace				;go on to the face off itself

.clc	tst.w	(a3,d0.w)			;d0 = offset of temp1 or temp2 (the timer)
	bmi.w	rtss					;timer idle
	move.w	4(a3,d0.w),d1			;temp3/temp4 = SCnum
	asl.w	#7,d1					;* SCstruct
	movea.w	#(SortCords-M68K_RAM),a0
	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = his team for SetLCmode2
	btst	#pfteam,pflags(a0,d1.w)
	beq.w	.clh
	adda.w	#tmsize,a2
.clh	btst	#pf2lcm,pflags2(a0,d1.w)	;pf2lcm
	bne.w	.clnd					;still in line change mode
	st	(a3,d0.w)					;mode ended by the player: stop the timer
	bra.w	SetLCmode2				;redraw lc box
.clnd	sub.w	d7,(a3,d0.w)		;count the timer down
	bpl.w	rtss
	move.l	a3,-(sp)				;time out: choose for him
	lea	(a0,d1.w),a3
	btst	#pf2lcm,pflags2(a3)		;pf2lcm
	beq.w	.clcex
	clr.w	d2						;lcfound choice 0
	bsr.w	lcfound
	bsr.w	SetLCmode2				;redraw the line change box
.clcex	movea.l	(sp)+,a3			;restore a3 = controller
	rts

ChkGoalies							;computer pulls goalie on delayed penalty. Called from periodicevents
	btst	#gmclock,(gmode).w		;clock stopped: nothing
	bne.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = team being tested, a1 = the other team
	lea	tmsize(a2),a1
	moveq	#1,d0					;d0 = team number (1 home, 2 visitors)
	bsr.w	.CPG					;test the home team ...
	moveq	#2,d0
	exg	a1,a2						;... then fall into .CPG for the visitors
.CPG	tst.w	tmgoalie(a2)		;tmgoalie already out
	bmi.w	rtss
	move.w	(puckc).w,d1
	bmi.w	rtss					;loose puck
	subq.w	#6,d1					;home carrier 0-5 -> negative
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.0
	not.w	d1						;(92 neg)  visitors: carrier 6-11 -> negative
.0	tst.w	d1						;d1 < 0 when team a2 has the puck
	bpl.w	rtss					;exit unless team a2 has the puck
	btst	#gmpendel,(gmode).w		;delayed penalty has been called?
	beq.w	.cp
	st	tmgoalie(a2)				;pull goalie (92 move #2,tmgoalie), any team
	bra.w	setpersonel
.cp	cmp.w	(cont1team).w,d0		;rest is CPG for computer teams
	beq.w	rtss
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	move.w	(pucky).w,d1			;d1 = puck y for CPgoalie
	bra.w	CPgoalie

ReturnGoalies						;if computer pulled goalie, look to see if computer should return him.
									;Called from puckfaceoff
	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = team being tested, a1 = the other team
	lea	tmsize(a2),a1
	moveq	#1,d0					;d0 = team number
	bsr.w	.r						;home team first ...
	moveq	#2,d0
	exg	a1,a2						;... then fall into .r for the visitors
.r	cmpi.w	#-1,tmgoalie(a2)		;tmgoalie $FFFF stays out
	beq.w	rtss
	clr.b	tmgoalie(a2)			;return goalie
	cmp.w	(cont1team).w,d0
	beq.w	rtss					;human teams decide for themselves
	cmp.w	(cont2team).w,d0
	beq.w	rtss
	move.w	(foy).w,d1				;d1 = face off y, falls into CPgoalie

CPgoalie							;see if computer should pull his goalie. d1 = puck/faceoff y. Falls in
									;from ReturnGoalies; also entered from ChkGoalies
	cmpi.w	#2,(gsp).w
	bne.w	rtss					;exit if not 3rd per.
	move.w	tmscore(a1),d0
	sub.w	tmscore(a2),d0			;d0 = other team's goals - mine
	IF REV<2
	bmi.w	rtss					;exit if leading the game
	ENDIF							;(Rev B: a lead of 3 or more falls through to the next test)
	cmp.w	#2,d0
	bne.w	rtss					;exit unless behind by 2
	cmpi.w	#$3C,(gameclock).w
	bgt.w	rtss					;exit if more than 1 min left
	move.l	a0,-(sp)
	movea.w	tmsort(a2),a0			;first player of my team: which goal does he shoot at?
	btst	#pfgoal,pflags(a0)
	movea.l	(sp)+,a0
	bne.w	.0
	neg.w	d1						;make y positive toward the goal I shoot at
.0	tst.w	d1						;d1 = y toward the goal I shoot at
	bmi.w	rtss					;puck on my side of center: keep the goalie
	st	tmgoalie(a2)				;pull goalie (92 move #2,tmgoalie)
	bra.w	setpersonel

CompLine							;find good line for comp to switch to. a2 = team, a1 = other team. Called
									;from chk4lc and puckfaceoff
	movem.l	d0-d2/a0,-(sp)
	moveq	#3,d0					;d0 = first of the 2 special lines (3-4) used with a man advantage
	move.w	tmap(a2),d1
	sub.w	tmap(a1),d1				;compare the numbers of active players
	beq.w	.nopwr					;equal: normal line
	bpl.w	.0
	addq.w	#2,d0					;fewer players: lines 5-6 instead
.0	move.w	d0,-(sp)				;find pk/pwr line
	bsr.w	getlinee				;d0 = energy of the first candidate
	move.w	d0,d1
	move.w	(sp),d0
	addq.w	#1,d0
	bsr.w	getlinee				;d0 = energy of the second candidate
	cmp.w	d0,d1
	bge.w	.1
	addq.w	#1,(sp)					;second one has more energy: take it
.1	move.w	(sp)+,tmline(a2)		;set the current line
.ex	movem.l	(sp)+,d0-d2/a0			;restore registers and return
	rts

.nopwr	cmpa.w	#(tmstruct-M68K_RAM),a2	;find normal line
	bne.w	.away					;visitors use the other table
	moveq	#2,d1
	lea	.hl1(pc),a0					;a0 = row of .hl1 (7 words, indexed by the other team's line)
	cmpi.w	#2,(gsp).w
	bne.w	.h0						;not 3rd period: first row
	move.w	tmscore(a2),d2
	cmp.w	tmscore(a1),d2
	beq.w	.h0						;tied: first row
	adda.w	#$E,a0					;(adda keeps the flags of the cmp) next row ...
	bgt.w	.h0						;... if leading
	adda.w	#$E,a0					;third row if trailing
.h0	move.w	tmline(a1),d1			;line proposed for the other team's current line
	asl.w	#1,d1					;index by the other team's current line
	move.w	(a0,d1.w),d0
	bsr.w	getlinee				;energy of the proposed line
	cmp.w	#3*$1000/4,d0
	bls.w	.away					;below 3/4: try the .away method
	move.w	(a0,d1.w),tmline(a2)
	bra.s	.ex

.hl1	dc.w	0,1,2,0,1,0,1		;proposed home line per other team's line, 3 rows (tied, leading,
									;trailing)
	dc.w	2,0,1,2,0,2,0
	dc.w	0,1,0,0,1,0,1

.away	moveq	#2,d1				;try up to 3 lines in the row order
	lea	.al1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.a0
	move.w	tmscore(a2),d2
	cmp.w	tmscore(a1),d2
	beq.w	.a0						;tied or not 3rd period: first row
	addq.w	#6,a0					;(flags of the cmp are kept) next row ...
	bgt.w	.a0						;... if leading
	addq.w	#6,a0					;third row if trailing
.a0	move.w	(a0)+,d0				;next candidate line
	bsr.w	getlinee
	cmp.w	#3*$1000/4,d0			;(92 19*$1000/20)
	dbhi	d1,.a0					;energy above 3/4: stop, else try the next
	move.w	-(a0),tmline(a2)		;use the last candidate tried
	bra.w	.ex

.al1	dc.w	0,1,2				;line preference order, 3 rows (tied, leading, trailing)
	dc.w	0,2,1
	dc.w	0,1,0

puckfaceoff2						;face off control logic and general setup for action a3 = the puck. First
									;call sets the whole face off up (players, puck, scoreboard box, map);
									;later calls count temp1 down to the drop (updatefaceoff / Endfaceoff)
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna					;not first time thru
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack				;blank the screen while setting up
.p	btst	#dfok,(disflags).w		;wait for vblank (dfok clear)
	bne.s	.p						;wait for vblank
	cmpi.w	#$258,(Crowdlevel).w
	bls.w	.ntm
	move.w	#$258,(Crowdlevel).w	;limit crowd level
.ntm	bset	#dfclock,(disflags).w	;stop clock
	bclr	#sfpz,(sflags).w		;no pause
	bclr	#sf3llcs,(sflags3).w	;no line changes
	clr.w	(glovecords).w			;no fighting gloves
	clr.b	(iflags).w				;no icing
	st	(RefCnt).w					;no refs
	st	(puckcross+pcframes).w		;no goalie moes
	st	(puckcross+pcsize+pcframes).w
	bclr	#sf2refref,(sflags2).w
	bset	#sf2faceoff,(sflags2).w	;face off in progress
	bset	#sf2drec,(sflags2).w	;don't record yet
	st	(passReceiverPlayerNum).w	;no pass receiver
	bset	#dffaceoff,(disflags).w	;cleared again in updatefaceoff
	bsr.w	ClrHor					;vertical icerink
	clr.w	(Vpos).w				;center h/v pos
	clr.w	(Hpos).w
	move.w	(fox).w,(puckx).w		;puck on the face off spot (fox/foy)
	move.w	(foy).w,(pucky).w
	st	(puckz).w					;no visible puck
	clr.w	(puckvx).w
	clr.w	(puckvy).w
	clr.w	(puckvz).w
	st	(puckc).w					;nobody carries it
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a0	;reposition goal nets
	clr.w	Xvel(a0)				;net 1 (sort object 12) at x 0, y $10C
	clr.w	Yvel(a0)
	clr.w	(a0)					;Xpos
	move.w	#$10C,Ypos(a0)			;268
	adda.w	#SCstruct,a0			;net 2 (sort object 13) at x 0, y -$10C
	clr.w	Xvel(a0)
	clr.w	Yvel(a0)
	clr.w	(a0)
	move.w	#-$10C,Ypos(a0)
	movea.w	#(SortCords+(15*SCstruct)-M68K_RAM),a0	;sort object 15: frame = SPFpuck, SPA and attribute
													;cleared
	move.w	#SPFpuck,frame(a0)
	clr.w	SPA(a0)
	clr.w	attribute(a0)
	clr.w	(SortCords+(puckscnum*SCstruct)+attribute).w
	bclr	#sfslock,(sflags).w		;free up scrolling
	moveq	#$64,d4					;run the scroll window 101 times so it settles
.cw	bsr.w	checkwindow				;scroll to faceoff spot
	dbf	d4,.cw
	move.w	#$3C,(yleader).w
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2	;set personnel and player data for both teams
	bsr.w	setpersonel
	bsr.w	forcepldata
	adda.w	#tmsize,a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	bsr.w	resetplstuff
	move.l	a3,-(sp)				;keep the puck pointer
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d2					;loop over the 12 players
.l0	move.w	#-$F0,(a3)				;Xpos = -240
	clr.w	Ypos(a3)
	clr.w	frame(a3)
	move.w	position(a3),d1
	bmi.w	.next					;absent
	beq.w	.goalie1				;goalie: no assignment change
	move.l	#afaceoff,d0			;afaceoff
	cmp.w	#4,d1
	bne.w	.l1						;only the center (position 4) takes the face off
	movea.w	#(tmstruct-M68K_RAM),a2	;faceoff man resets team $18-$1C
	btst	#pfteam,pflags(a3)
	beq.w	.tm
	adda.w	#tmsize,a2
.tm	clr.w	tmtouch1(a2)			;reset the face off man's touch list of his team
	move.b	pnum(a3),tmtouch1+1(a2)
	st	tmtouch2(a2)
	st	tmtouch3(a2)
	bclr	#tmflast,tmflags(a2)	;tmflags bit 3
	move.l	#afaceoffpl,d0			;afaceoffpl
.l1	bsr.w	assinsert				;give the player his face off assignment
.goalie1	move.w	(tmstruct+tmap).w,d4	;d4 = active players of this player's team
	btst	#pfteam,pflags(a3)
	beq.w	.t0
	move.w	(awtmstruct+tmap).w,d4
.t0	neg.w	d4						;d4 = 6 - active players: formation row
	addq.w	#6,d4					;6 - active players
	asl.w	#3,d4					;8 bytes per row of .apl
	movea.l	#.apl,a1
	adda.w	d4,a1					;row for this team size ...
	move.b	(a1,d1.w),d4			;... indexed by position: formation slot
	asl.w	#2,d4
	movea.l	#.ptab,a1
	move.w	(a1,d4.w),d0			;d0/d1 = x/y of that slot (4 bytes per entry)
	move.w	2(a1,d4.w),d1
	btst	#pfgoal,pflags(a3)
	bne.w	.f0
	neg.w	d0						;mirror for the team shooting the other way
	neg.w	d1
.f0	tst.w	position(a3)			;goalie goes straight to its spot
	beq.w	.goalie2				;goalie: fixed spot, no face off offset
	cmp.w	#2*4,d4
	bgt.w	.nodef					;slots above 2 are not shifted by the spot
	move.w	(fox).w,d3
	eor.w	d0,d3
	bpl.w	.notmid					;fox and slot x on the same side
	move.w	(foy).w,d3
	asr.w	#3,d3
	sub.w	d3,d1					;opposite side: also pull y toward the spot
.notmid	move.w	(fox).w,d3			;pull x toward the spot by fox/4
	asr.w	#2,d3
	sub.w	d3,d0
.nodef	add.w	(fox).w,d0			;slot is relative to the face off spot
	add.w	(foy).w,d1
.goalie2	move.w	d0,(a3)			;Xpos
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	neg.w	d0
	neg.w	d1
	bsr.w	vtoa					;face the direction from the puck to the player
	move.w	d0,facedir(a3)
	bclr	#pf2unav,pflags2(a3)	;pf2unav
	bclr	#pfalock,pflags(a3)
	move.w	#SPAglide,d1
	bsr.w	SetSPA					;glide animation
.next	adda.w	#SCstruct,a3		;next player
	dbf	d2,.l0
	bsr.w	SprSort
	movea.l	(sp)+,a3
	bsr.w	ResetAndSelectPlayers
	bsr.w	printz
	String	$FF,0,0					;inline string data: print the face off box (control codes)
	moveq	#$36,d0					;8+46
	tst.w	(fox).w
	bpl.w	.fok
	move.w	#$BE,d0					;(18*8)+46
.fok	move.w	d0,(fodropx).w		;drop box x: left or right depending on the sign of fox
	subi.w	#$2E,d0
	asr.w	#3,d0
	move.w	d0,(printx).w			;print column = (x - 46) / 8
	moveq	#$5C,d0					;(3*8)+68
	move.w	d0,(fodropy).w
	subi.w	#$44,d0
	asr.w	#3,d0
	move.w	d0,(printy).w			;print row = (y - 68) / 8
	move.w	(ExtraChars).w,d4		;space for faceoff map
	movea.l	#FaceOffMap,a0			;a0/a1 = the two bitmaps found via the offsets at the start
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0						;d0/d1 = 0, d2/d3 = $C/$A (dobitmap size arguments)
	clr.w	d1
	moveq	#$C,d2
	moveq	#$A,d3
	moveq	#0,d5
	bsr.w	dobitmap				;draw the face off map
	move.w	d4,(faceoffvrcset).w	;space for faceoff sprites
	movea.l	#FaceOffSprites+8,a2	;replaces /DoDMA
	bsr.w	DecompressGraphicsPlain
	tst.w	(OptLine).w				;line names box when lines are on
	bne.w	.nol
	bsr.w	printsmallz
	String	CC_AddY,$A,CC_SetAttribute,4
	moveq	#$C,d0					;frame the line names box (Framer args d0 = $C, d1 = 3)
	moveq	#3,d1
	bsr.w	Framer
	move.w	(tmstruct+tmline).w,d0	;d0/d1 = current lines of home / visitors
	move.w	(awtmstruct+tmline).w,d1
	btst	#gmdir,(gmode).w		;order them like the screen (gmdir: home team goes up)
	bne.w	.nx
	exg	d0,d1
.nx	bsr.w	printsmallz				;print the two line names
	String	$FB,1,$FA,$FE
	movea.l	#linelist,a1
	bsr.w	Fprintsmall				;first line name (d0)
	addq.w	#4,(printx).w
	move.w	d1,d0
	movea.l	#linelist,a1
	bsr.w	Fprintsmall				;second line name (d1)
.nol	move.w	#$78,d0				;random time before the puck drop
	bsr.w	randomd0				;0-$77
	addi.w	#$B4,d0					;$B4-$12B frames until the drop
	move.w	d0,temp1(a3)			;time for puck drop
	move.w	#$18,(palcount).w
	movea.l	#fofdata2,a0			;second half of the big face off sprite data
	move.w	#1,(a0)
	move.w	#$8000,foattr(a0)
	move.w	#4,fosize+foframe(a0)
	move.w	#$A800,fosize+foattr(a0)
	move.w	#7,2*fosize+foframe(a0)	;frame of ref
	move.w	#$8000,fofdata-fofdata2+foattr(a0)
	btst	#gmdir,(gmode).w
	bne.w	.nfl
	eori.w	#$800,foattr(a0)		;flip attribute bit $800 (two of the sprites) when gmdir is clear
	eori.w	#$800,fosize+foattr(a0)
.nfl	move.w	#-1,(fodir1).w		;no pull directions yet
	move.w	#-1,(fodir2).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.nna	subq.w	#1,temp1(a3)		;(92 sub d7)
	bpl.w	updatefaceoff			;still counting down: update the drop animation
	bra.w	Endfaceoff				;temp1 expired: drop the puck

.apl								;formation: 3 rows (8 bytes each) selected by 6 - active players (6, 5, 4
									;skaters on ice); each byte = .ptab slot, indexed by position (0 goalie,
									;1-2 defense, 3/5 wings, 4 center)
	dc.b	0,1,2,3,4,5,6,0
	dc.b	0,1,5,3,4,2,0,0
	dc.b	0,3,5,1,4,0,0,0
.ptab								;x,y of each formation slot, relative to the face off spot (mirrored for
									;the other end)
	dc.w	0,-250
	dc.w	-35,-50
	dc.w	35,-50
	dc.w	-50,-10
	dc.w	0,-15
	dc.w	50,-10
	dc.w	0,-60

ResetAndSelectPlayers				;from 92 puckfaceoff2 (inline). c1playernum/c2playernum = -1, then
									;changeplayer for each human team. Called from puckfaceoff2
	move.w	#-1,(c1playernum).w		;nobody controlled yet
	move.w	#-1,(c2playernum).w
	tst.w	(cont1team).w
	beq.w	.nt1					;controller 1 not in use
	clr.w	d4						;d4 = controller 0 (0/2 for changeplayer)
	bsr.w	changeplayer
.nt1	tst.w	(cont2team).w		;second controller
	beq.w	.nt2					;controller 2 not in use
	moveq	#2,d4					;d4 = 2: second controller
	bsr.w	changeplayer
.nt2	rts							;done

updatefaceoff						;a3 = puck. Drop animation frame from temp1; at 0 erases the faceoff box
									;(92 did that in Endfaceoff). Entered from puckfaceoff2
	move.w	temp1(a3),d0			;frames left until the drop
	beq.w	.erase					;0: remove the face off box
	addq.w	#6,d0
	lsr.w	#3,d0					;(temp1 + 6) / 8
	cmp.w	#2,d0
	bgt.w	rtss					;more than ~2 steps from the drop: keep the current frame
	neg.w	d0
	addi.w	#$A,d0					;frame $A - d0 (8 to 10) as the drop approaches
	move.w	d0,(fofdata).w			;+8
	rts
.erase	bclr	#dffaceoff,(disflags).w	;face off display off
	bsr.w	printz
	String	$BF,0,0
	move.w	(fodropx).w,d0
	subi.w	#$2E,d0
	asr.w	#3,d0
	move.w	d0,(printx).w			;same print column as in puckfaceoff2
	moveq	#$64,d0					;(4*8)+68, overwritten (as in 92)
	move.w	(fodropy).w,d0
	subi.w	#$44,d0
	asr.w	#3,d0
	move.w	d0,(printy).w
	moveq	#$C,d0					;eraser: d0/d1 = x/y size, d2 = fill char word
	moveq	#$D,d1					;(92 10)
	move.w	#$7FF,d2				;(92 moveq #1,d2)
	bra.w	eraser

Endfaceoff							;drop the puck: pick the faceoff winner and send the puck off.
									;Entered from puckfaceoff2
	move.w	#SFXpuckice+3,-(sp)		;SFXpuckice
	bsr.w	sfx
	bclr	#sf2faceoff,(sflags2).w	;face off over
	move.w	(ExtraChars).w,d4
	movea.l	#RefsMap+8,a2
	bsr.w	DecompressGraphicsPlain	;ref cam chars
	bclr	#sf2drec,(sflags2).w	;replay recording may start
	bclr	#gmclock,(gmode).w		;start the game clock
	bclr	#pf2fight,pflags2(a3)
	bset	#sf3fo,(sflags3).w		;flag the faceoff drop
	move.w	(fodir1).w,d3			;figure out who won face off
	move.w	#$800,d4				;d4 = y velocity added to the puck: +$800 ...
	movea.l	#.ftab,a0
	movea.w	#(fofdata2-M68K_RAM),a1	;a1 = the two face off sprite records
	moveq	#$10,d2
	move.w	(a1),d1					;first record's word 0 (index into .ftab, 1-based)
	sub.b	-1(a0,d1.w),d2			;d2 = $10 - .ftab[first] ...
	move.w	fosize+foframe(a1),d1
	add.b	-1(a0,d1.w),d2			;... + .ftab[second]
	moveq	#$21,d0
	bsr.w	randomd0				;random 0-$20
	cmp.b	d0,d2
	bls.w	.p1won					;d2 <= random: stay with the first record
	addq.w	#4,a1					;else use the second record
.p1won	btst	#3,foattr(a1)		;bit 3 of the winner's attribute word ($800 flips)
	beq.w	.pos
	move.w	(fodir2).w,d3			;visiting player won: use his pull direction ...
	neg.w	d4						;... and push the puck the other way (-$800)
.pos	move.w	d3,d0				;d0 = winner's pull direction; bit 3 set = no joystick
	btst	#3,d0
	bne.w	.nojoy
	andi.w	#7,d0
	move.w	(HVcount).l,d1			;hvcount
	andi.w	#3,d1
	bne.w	.nj2					;3 in 4: use his direction as is
.nojoy	moveq	#5,d0				;no direction (or 1 in 4): random 0-4 ...
	bsr.w	randomd0
	subq.w	#2,d0
	andi.w	#7,d0					;... minus 2, wrapped to 0-7
	tst.w	d4
	bmi.w	.nj2
	eori.w	#4,d0					;home won: turn the direction around
.nj2	asl.w	#2,d0				;4 bytes per dirtab entry
	movea.l	#dirtab,a0
	move.w	(a0,d0.w),d1
	asl.w	#5,d1
	move.w	d1,Xvel(a3)				;puck x velocity = dirtab x * 32
	move.w	2(a0,d0.w),d1
	asl.w	#5,d1
	add.w	d4,d1
	move.w	d1,Yvel(a3)				;puck y velocity = dirtab y * 32 +- $800
	move.w	#$800,d0
	bsr.w	randomd0
	move.w	d0,Zvel(a3)				;random upward velocity 0-$7FF
	clr.w	(puckz).w				;puck now at ice level (visible)
	bclr	#pfnc,pflags(a3)		;collisions on
	move.l	#pnorm,d0				;pnorm
	bra.w	assreplace

.ftab	dc.b	0,8,16,0,8,16		;1-based lookup (-1(a0,d1)) by the sprite records' frame word

pucknorm							;assignment for puck most of the time. a3 = puck, d7 = elapse frames since
									;last call
	bclr	#pfna,pflags(a3)		;new assignment? (clears the flag)
	beq.w	.nna
	clr.w	temp1(a3)				;findpc timer: run at once
	move.w	#$78,temp2(a3)			;temp2 = still puck timer
.nna	movea.w	#(puckcross-M68K_RAM),a1	;table for puck crossing lines
	sub.w	d7,2(a1)				;sub elapse frames from time til crossing
	sub.w	d7,6(a1)
	sub.w	d7,temp1(a3)			;every ~5 frames recompute the crossings
	bpl.w	.0
	addq.w	#5,temp1(a3)
	bsr.w	findpc
.0	move.w	(puckc).w,d0			;is the puck carried?
	bmi.w	.nothandled				;loose puck
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a2
	adda.w	d0,a2					;a2 = the puck carrier
	bsr.w	a2touchpuck
	move.l	a2,-(sp)				;GetHot takes the structure address on the stack
	bsr.w	GetHot					;d0/d1 = hot spot of the carrier
	add.w	(a2),d0					;bunjy the puck towards the hot spot on player a2
	sub.w	(a3),d0
	asr.w	#2,d0					;move a quarter of the distance per call
	add.w	d0,(a3)
	add.w	Ypos(a2),d1
	sub.w	Ypos(a3),d1
	asr.w	#2,d1
	add.w	d1,Ypos(a3)
	move.w	Xvel(a2),Xvel(a3)		;puck takes the carrier's velocity
	move.w	Yvel(a2),Yvel(a3)
.nothandled	bsr.w	PuckIChk		;icing check
	bsr.w	ChkOffsides				;offsides check
	btst	#gmclock,(gmode).w		;loose puck that has not moved
	bne.w	.z						;(Xpos = $1C, Ypos = $20) for 120 calls
	tst.w	(puckc).w				;calls AddPenalty2 with d0 = 6
	bpl.w	.mv						;carried: reset the timer
	move.w	(a3),d0
	cmp.w	OldXpos(a3),d0
	bne.w	.mv						;moved in x
	move.w	Ypos(a3),d0
	cmp.w	OldYpos(a3),d0
	bne.w	.mv						;moved in y
	move.l	#6,d0					;argument for AddPenalty2
	subq.w	#1,temp2(a3)
	bpl.w	.np						;timer still running
	bsr.w	AddPenalty2				;puck lay still too long
.np	bra.w	.z						;continue at .z
.mv	move.w	#$78,temp2(a3)			;reset still puck timer
.z	tst.b	Zvel(a3)				;puck in the air or moving up/down?
	bne.w	checkpuckcoll
	tst.w	Zpos(a3)
	bne.w	checkpuckcoll
	bsr.w	puckunflip				;on the ice and not rising: stop the spin
	bra.w	checkpuckcoll

;======================================================================
;======================================================================
;	The puck's offsides and icing checks (ChkOffsides ... puckflip), puckshadow and findpc, then movement:
;	skateto, skatetopuck, the assignment stack, vtoa, GetHot, SetSPA, the acceleration routines and dirtab.
;
;	icing flags (iflags): ifcgl 0, ifdir 1, ifok 2; icingPlayer = +1.

ChkOffsides							;check for offsides penalty. a3 = puck. Flags the whole team (tmflags bit
									;4; 92 flagged each player). Called from pucknorm
	btst	#gmoffs,(gmode).w		;offsides rule on?
	beq.w	rtss
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2				;team 2 (tmsize)
	bsr.w	ClearOffsidesIfAllPlayers	;first drop the flag of any team with no one over the line
	exg	a1,a2
	bsr.w	ClearOffsidesIfAllPlayers
	move.w	#Blueline-4,d0			;blueline-4 (92 move blueline,d0 / sub #4,d0)
	cmp.w	Ypos(a3),d0
	bgt.w	.neg					;puck y < Blueline-4: go to the bottom line test
	cmp.w	OldYpos(a3),d0			;OldYpos: puck crossed the top line this frame?
	ble.w	rtss					;no crossing
	addi.w	#$A,d0					;d0 = Blueline+6: players must be past this
	btst	#gmdir,(gmode).w		;pick which team is attacking this end
	beq.w	.t0
	exg	a2,a1
.t0	moveq	#5,d2					;loop over the 6 players of team a2
	movea.w	tmsort(a2),a0			;tmsort: first player of the team
.0	tst.w	position(a0)			;position: skip off ice
	bmi.w	.1
	cmp.w	Ypos(a0),d0
	bge.w	.1						;not past the line
	bset	#tmfoside,tmflags(a2)	;player past the line: team offsides
	rts
.1	adda.w	#SCstruct,a0			;next player
	dbf	d2,.0
	rts

.neg	neg.w	d0					;mirrored test for the bottom blue line (d0 = -(Blueline-4))
	cmp.w	Ypos(a3),d0
	blt.w	rtss
	cmp.w	OldYpos(a3),d0			;OldYpos: puck crossed the bottom line this frame?
	bge.w	rtss					;no crossing
	subi.w	#$A,d0
	btst	#gmdir,(gmode).w
	bne.w	.t1
	exg	a2,a1
.t1	moveq	#5,d2					;loop over the 6 players of team a2
	movea.w	tmsort(a2),a0
.2	tst.w	position(a0)			;loop over the team's players (bottom line)
	bmi.w	.3
	cmp.w	Ypos(a0),d0
	ble.w	.3						;not past the line
	bset	#tmfoside,tmflags(a2)	;team offsides
	rts
.3	adda.w	#SCstruct,a0			;next player
	dbf	d2,.2
	rts

ClearOffsidesIfAllPlayers			;from 92 updateplayers pf3oside clear. a2 = team struct. Clears the team
									;offsides flag (tmflags bit 4) once no skater on ice is past the blue line
									;($58, sign by pfgoal). Called twice from ChkOffsides
	btst	#tmfoside,tmflags(a2)
	beq.w	rtss					;team is not flagged: nothing to clear
	movea.w	tmsort(a2),a0
	moveq	#5,d1					;loop over the 6 players
.top	tst.w	position(a0)		;position: off ice keeps the last d0
	bmi.w	.next
	move.w	Ypos(a0),d0				;d0 = y toward the goal this player shoots at
	btst	#pfgoal,pflags(a0)
	bne.w	.next
	neg.w	d0
.next	adda.w	#SCstruct,a0		;next player
	cmp.w	#Blueline,d0			;(blueline)
	dbgt	d1,.top					;stop at the first player past the blue line
	bgt.w	rtss					;someone still past the line
	bclr	#tmfoside,tmflags(a2)	;all clear: remove the team offsides flag
	rts

a2offsides							;player a2 touched the puck: offsides penalty if his team is flagged and
									;the puck is past the blue line. Called from a2touchpuck
	btst	#gmoffs,(gmode).w		;offsides rule on?
	beq.w	rtss
	move.w	(pucky).w,d0			;puck y toward the goal a2 shoots at
	btst	#pfgoal,pflags(a2)
	bne.w	.0
	neg.w	d0
.0	cmp.w	#Blueline,d0			;(92 cmp blueline,d0)
	blt.w	rtss					;puck not in the attack zone
	movea.w	#(tmstruct-M68K_RAM),a0	;a0 = a2's team struct
	btst	#pfteam,pflags(a2)
	beq.w	.1
	adda.w	#tmsize,a0
.1	btst	#tmfoside,tmflags(a0)	;team offsides flag
	beq.w	rtss
	btst	#gmhl,(gmode).w			;hilight (replay) mode: no penalty
	bne.w	rtss
	exg	a2,a3						;AddPenalty works on a3
	move.l	#PenOffsides,d0
	bsr.w	AddPenalty
	exg	a2,a3
	rts

a2touchpuck							;player a2 touches puck. Look for penalties/offsides/other junk. Called
									;from pucknorm, puckstick and others
	move.w	(a2),(ltx).w			;Xpos
	move.w	Ypos(a2),(lty).w		;remember where and by whom the puck was last touched
	move.w	SCnum(a2),(ltplayer).w
	movea.w	#(tmstruct-M68K_RAM),a0	;keep the last three touches per team
	btst	#pfteam,pflags(a2)
	beq.w	.t
	lea	tmsize(a0),a0				;a0 = a2's team struct
.t	clr.w	d0						;d0 = player number
	move.b	pnum(a2),d0				;d0 = player number
	cmp.w	tmtouch1(a0),d0			;same player as the last touch: no change
	beq.w	.same
	bclr	#tmflast,tmflags(a0)	;tmflags bit 3 set: overwrite the last touch only
	bne.w	.st
	move.w	tmtouch2(a0),tmtouch3(a0)	;shift the touch list down
	move.w	tmtouch1(a0),tmtouch2(a0)
.st	move.w	d0,tmtouch1(a0)			;newest touch
	cmp.w	tmtouch3(a0),d0
	bne.w	.same
	st	tmtouch3(a0)				;player was also the third touch: drop it
.same	bclr	#sf2shot,(sflags2).w	;a touch ends the "shot was taken" state
	bsr.w	a2offsides
	btst	#ifok,(iflags).w		;ifok
	beq.w	.notice					;no icing possible: only update the icing state
	btst	#ifcgl,(iflags).w		;ifcgl
	beq.w	.notice					;puck has not crossed the goal line
	tst.w	position(a2)
	beq.w	.notice					;a goalie touch: no icing call (state is reset below)
	btst	#ifdir,(iflags).w		;ifdir
	bne.w	.up
	btst	#pfgoal,pflags(a2)
	beq.w	.notice
.icing	clr.w	d0					;icing: penalize the player in icingPlayer
	move.b	(icingPlayer).w,d0		;+1
	asl.w	#scsize,d0				;scsize
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3					;a3 = the player who iced the puck
	move.w	#PenIcing,d0
	bsr.w	AddPenalty
	movea.l	(sp)+,a3
	rts
.up	btst	#pfgoal,pflags(a2)		;ifdir set: same test with pfgoal inverted
	beq.s	.icing
.notice	clr.b	(iflags).w			;start over: clear the icing state
	move.b	SCnum+1(a2),(icingPlayer).w	;remember who touched it last
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a2)
	beq.w	.0
	bset	#ifdir,(iflags).w		;ifdir
	neg.w	d0
.0	bmi.w	rtss					;puck y negative in a2's frame (probably his own half): not ifok
	move.w	(tmstruct+tmap).w,d0
	sub.w	(awtmstruct+tmap).w,d0	;d0 = home active players - visitors
	btst	#pfteam,pflags(a2)
	beq.w	.1
	neg.w	d0
.1	bmi.w	rtss					;a2's team is short handed: no icing
	bset	#ifok,(iflags).w		;ifok
	rts

PuckIChk							;check for icing of puck penalty. Called from pucknorm
	btst	#ifok,(iflags).w		;ifok
	beq.w	rtss					;icing not possible
	btst	#ifcgl,(iflags).w		;ifcgl
	bne.w	rtss					;already crossed the goal line
	tst.w	(puckc).w
	bpl.w	rtss					;someone has the puck
	move.w	#Blueline+goalline,d0	;blueline+goalline
	btst	#ifdir,(iflags).w		;ifdir
	bne.w	.0
	neg.w	d0						;other direction: d0 = -(goal line y)
	cmp.w	(pucky).w,d0
	bgt.w	.chkx					;puck y reached the goal line
	rts
.0	cmp.w	(pucky).w,d0			;ifdir set: compare against the other goal line
	bgt.w	rtss					;goal line not reached yet
.chkx	cmpi.w	#$2C,(puckx).w		;|puckx| <= $2C at the goal line
	bgt.w	.set					;outside the goal mouth: crossed the line
	cmpi.w	#-$2C,(puckx).w
	blt.w	.set
	bclr	#ifok,(iflags).w		;ifok cleared: no icing
	rts
.set	bset	#ifcgl,(iflags).w	;ifcgl
	rts

puckunflip							;stop spinning puck. a3 = puck. Entered from
									;pucknothing, called from pucknorm
	cmpi.w	#8,SPAnum(a3)			;2*4 SPAnum
	blt.w	.k
	cmpi.w	#$18,SPAnum(a3)			;6*4
	bge.w	.k
	eori.w	#2,facedir(a3)			;SPAnum 8..$17: flip bit 1 of facedir before leveling
.k	ori.w	#4,facedir(a3)			;facedir bit 2 set
	clr.w	SPAnum(a3)
	st	SPAcnt(a3)
	rts

puckflip							;start puck spinning. a3 = puck, d0 bit 0 = flip. Called from checkgoal,
									;wallcoll and others
	andi.w	#1,d0
	eor.w	d0,facedir(a3)			;toggle facedir bit 0 when d0 bit 0 is set
	andi.w	#3,facedir(a3)			;keep 0-3
	st	SPAcnt(a3)
	move.w	#SPApflip,d1
	bra.w	SetSPA					;start the puck flip animation

puckshadow							;assignment for puck shadow. a3 = puck shadow (struct after the puck)
	cmpi.w	#SPFpuck,frame(a3)
	bne.w	.siren					;shadow turns into siren on goals
	move.w	Xpos-SCstruct(a3),(a3)	;copy the puck's x/y (the object just before this one)
	move.w	Ypos-SCstruct(a3),Ypos(a3)
	clr.w	Zpos(a3)				;shadow lies on the ice
	moveq	#Ypos,d0
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	moveq	#Xpos,d0				;horizontal screen: offset along x instead of y
.nhor	addq.w	#1,(a3,d0.w)		;shadow is drawn 1 unit off the puck
	rts

.siren	tst.w	frame(a3)			;shadow object doubles as the goal siren
	beq.w	rtss					;no frame: nothing to show
	clr.w	(a3)					;Xpos
	move.w	#$12C,Ypos(a3)			;Ypos 300
	move.w	#$E,Zpos(a3)			;Zpos 14
	tst.w	Ypos-SCstruct(a3)
	bpl.w	.s0						;puck y >= 0: siren at the top, as set
	move.w	#$8000,attribute(a3)	;puck y < 0: siren at y -300, attribute $8000 (flipped)
	neg.w	Ypos(a3)
	subq.w	#1,Zpos(a3)
.s0	rts								;return

findpc								;find puck crossing lines: calculate when puck will cross goalline (if at
									;all). Called from pucknorm fills puckcross (2 entries of x word, time
									;word): top goal line first, then bottom
	movem.l	d0-d4/a1-a2,-(sp)
	movea.w	#(puckcross-M68K_RAM),a1
	move.w	#Sideline,d1			;sideline
	move.w	#Blueline+goalline,d4	;blueline+goalline
	bsr.w	.calc					;top goal line (y = d4)
	neg.w	d4
	bsr.w	.calc					;bottom goal line (y = -d4)
	movem.l	(sp)+,d0-d4/a1-a2
	rts
.calc	move.w	d4,d0				;in: d4 = goal line y, d1 = sideline x, a1 = entry
	sub.w	(pucky).w,d0			;d0 = distance in y to the goal line
	tst.w	(puckvy).w
	beq.w	.nocross				;no y velocity: never crosses
	move.w	d0,d2
	swap	d2
	clr.w	d2
	asr.l	#4,d2					;d2 = distance << 12 (32 bit)
	divs.w	(puckvy).w,d2			;d2 = time = distance / y velocity
	bmi.w	.nocross				;moving away from that line
	move.w	d2,2(a1)				;time until crossing in frames
	muls.w	(puckvx).w,d0
	divs.w	(puckvy).w,d0			;d0 = x travelled by then = distance * vx / vy
	bvs.w	.nocross
	add.w	(puckx).w,d0			;d0 = predicted x at the goal line
	cmp.w	d1,d0
	blt.w	.o1
	neg.w	d0						;x >= sideline: fold it back (d0 = 3*sideline - d0)
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
.o1	neg.w	d1						;now test the left sideline
	cmp.w	d1,d0
	bgt.w	.o2
	neg.w	d0						;x <= -sideline: same fold with d1 = -sideline
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
.o2	neg.w	d1						;restore d1 = +sideline
	move.w	d0,(a1)					;predicted x
	bra.w	.next
.nocross	move.w	#-1,2(a1)		;time -1 = no crossing
.next	addq.w	#4,a1				;next entry
	rts

skateto								;a0 = extra routine for collision avoidance, d0/d1 = x/y cord to skate to,
									;d7 = elapse frames
	sub.b	d7,temp2(a3)			;temp2 low byte = skateto timer
	bpl.w	.ex						;not due: reuse the last direction (temp2+1)
	addi.b	#$C,temp2(a3)			;only execute every 12/60 sec.
	bsr.w	avdgoal					;may change the target d0/d1 to go around the goal
	movem.w	d0-d1,-(sp)				;no deltax/deltay test
	move.w	Xvel(a3),d0
	asr.w	#8,d0
	neg.w	d0						;d0 = -(velocity / 256)
	add.w	(sp)+,d0				;+ target x
	sub.w	(a3),d0					;- my x: d0 = remaining dx
	move.w	Yvel(a3),d1
	asr.w	#8,d1
	neg.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1				;d1 = remaining dy
	cmp.w	#12,d0					;within 12 in both axes?
	bgt.w	.vt
	cmp.w	#-12,d0
	blt.w	.vt
	cmp.w	#12,d1
	bgt.w	.vt
	cmp.w	#-12,d1
	blt.w	.vt
	moveq	#9,d0					;close enough: no direction
	bra.w	.nvt
.vt	bsr.w	vtoa					;d0 = direction 0-7 to the target
.nvt	jsr	(a0)					;caller's routine may adjust the direction in d0
	move.b	d0,temp2+1(a3)			;remember it
	cmp.w	#7,d0
	ble.w	.ex						;a real direction: go accelerate
	move.w	Xvel(a3),d0				;no direction: if standing still, turn toward the puck
	or.w	Yvel(a3),d0
	bne.w	.ex						;still moving
	move.w	(puckx).w,d0
	move.w	(pucky).w,d1
	btst	#pf2fight,(puckx+pflags2).w	;puck object flagged pf2fight: look at (xc1,yc1) instead
	beq.w	.nf
	move.w	(xc1).w,d0
	move.w	(yc1).w,d1
.nf	sub.w	(a3),d0					;d0/d1 = point to face
	sub.w	Ypos(a3),d1				;face towards puck
	bsr.w	vtoa
	sub.w	facedir(a3),d0
	beq.w	.ex						;already facing it
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0					;+1/-1: one step in the shorter turn direction
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
.ex	clr.w	d0						;d0 = stored direction
	move.b	temp2+1(a3),d0			;d0 = stored direction
	bra.w	doplayeracc				;accelerate that way

avdgoal								;don't try to skate thru goal: if d0/d1 cords intersect thru goal then
									;provide new d0/d1 cords. a3 = player. .gl 254 ($FE), .yr/.ye 35 (92
									;258/30/30), .xr 80 in: d0/d1 = target x/y. out: d0/d1 moved by (deltax,
									;deltay) so the straight line from a3 to the target misses both nets (x
									;within +-$50, y within 35 of the goal lines at +-254)
	clr.w	(deltax).w
	clr.w	(deltay).w
	tst.w	position(a3)
	beq.w	rtss					;goalies may go anywhere
	move.w	(a3),d2
	eor.w	d0,d2
	bpl.w	.chbar					;target on the same side of x = 0: line does not cross the center
	move.w	d1,d2					;d2 = y where the line a3 -> target crosses x = 0
	sub.w	Ypos(a3),d2
	move.w	(a3),d3
	muls.w	d3,d2
	sub.w	d0,d3
	divs.w	d3,d2
	add.w	Ypos(a3),d2
	cmp.w	#$121,d2				;.gl+.yr,d2
	bgt.w	.chbar					;passes above the top net area
	cmp.w	#$DB,d2					;.gl-.yr,d2
	blt.w	.lower					;below the top net area: maybe the bottom one
	move.w	#$144,d3				;.gl+.yr+.ye
	cmp.w	#$FE,d2					;.gl,d2
	bgt.w	.2						;above the goal line: go around the outside
	blt.w	.1						;below it: go around the inside
	cmpi.w	#$FE,Ypos(a3)			;.gl
	bgt.w	.2						;exactly on it: decide by which side I am on
.1	move.w	#$B8,d3					;gl-.yr-.ye
.2	sub.w	d2,d3					;deltay = wanted y - crossing y
	move.w	d3,(deltay).w			;deltay = wanted y - crossing y
	bra.w	.chbar

.lower	cmp.w	#-$DB,d2			;-.gl+.yr,d2
	bgt.w	.chbar					;mirror of the above for the bottom net
	cmp.w	#-$121,d2				;-.gl-.yr,d2
	blt.w	.chbar
	move.w	#-$B8,d3				;-.gl+.yr+.ye
	cmp.w	#-$FE,d2				;-.gl,d2
	bgt.w	.4
	blt.w	.3
	cmpi.w	#-$FE,Ypos(a3)
	bgt.w	.4
.3	move.w	#-$144,d3				;-.gl-.yr-.ye
.4	sub.w	d2,d3					;deltay = wanted y - crossing y
	move.w	d3,(deltay).w

.chbar	move.w	d1,d3				;second test: does the line cross a goal line inside the net width?
	subi.w	#$FE,d3					;.gl
	move.w	Ypos(a3),d2
	subi.w	#$FE,d2
	bsr.w	.ch1					;top goal line
	move.w	d1,d3
	addi.w	#$FE,d3
	move.w	Ypos(a3),d2
	addi.w	#$FE,d2
	bsr.w	.ch1					;bottom goal line
	add.w	(deltax).w,d0			;apply the corrections to the target
	add.w	(deltay).w,d1
	rts

.ch1	move.w	d3,d4				;d3/d2 = target / player y relative to the goal line
	eor.w	d2,d4
	bpl.w	rtss					;same side of the goal line: no crossing
	move.w	d0,d4
	sub.w	(a3),d4
	muls.w	d2,d4
	sub.w	d3,d2
	divs.w	d2,d4
	add.w	(a3),d4					;d4 = x where the line crosses the goal line
	cmp.w	#$50,d4					;.xr,d4
	bgt.w	rtss					;beyond the net on the right
	cmp.w	#-$50,d4				;-.xr,d4
	blt.w	rtss					;beyond the net on the left
	moveq	#$50,d3					;.xr
	tst.w	d4
	bne.w	.ch2
	tst.w	(a3)					;crossing at x 0: use the side of my own x
.ch2	bpl.w	.ch3				;sign of the side: positive keeps +$50
	neg.w	d3						;d3 = +-$50: the net edge on that side
.ch3	sub.w	d4,d3				;deltax = net edge - crossing x
	move.w	d3,(deltax).w			;deltax = net edge - crossing x
	rts

skatetopuckinit						;from 92 skatetopuck head. d0/d1 = puck x/y plus half the high byte of its
									;velocity. Called from skatetopuck and assnearest
	move.b	(puckvx).w,d0			;high byte of the puck x velocity (signed)
	asr.b	#1,d0					;halved
	ext.w	d0
	add.w	(puckx).w,d0			;d0 = puck x + vx/2
	move.b	(puckvy).w,d1
	asr.b	#1,d1
	ext.w	d1
	add.w	(pucky).w,d1			;d1 = puck y + vy/2
	rts

skatetopuck							;player a3 should skate to puck. d7 = elapse frames
	bsr.s	skatetopuckinit			;d0/d1 = predicted puck spot
	sub.b	d7,temp2(a3)			;same temp2 timer as skateto, but every $A frames
	bpl.w	.ex						;not due: reuse the last direction
	addi.b	#$A,temp2(a3)
	bsr.w	avdgoal					;go around the nets
	movem.w	d0-d1,-(sp)				;save the target
	move.l	a3,-(sp)				;GetHot argument: this player
	bsr.w	GetHot					;d0/d1 = hot spot x/y of this player
	neg.b	d0
	neg.b	d1
	sub.b	Xvel(a3),d0				;subtract my velocity (high byte)
	ext.w	d0
	add.w	(sp)+,d0				;+ target x
	sub.w	(a3),d0					;- my x: d0 = dx
	sub.b	Yvel(a3),d1
	ext.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1				;d1 = dy
	bsr.w	vtoa					;direction to the puck
	move.b	d0,temp2+1(a3)			;remember it
	tst.w	position(a3)			;goalie skips the sweep check
	beq.w	.ex
	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	bsr.w	vtoa					;direction the puck is moving
	eori.w	#4,d0					;opposite of that
	cmp.w	facedir(a3),d0
	beq.w	.ex						;puck is coming towards players
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	move.w	(pucky).w,d1
	sub.w	Ypos(a3),d1
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa					;direction from me to the puck
	cmp.w	facedir(a3),d0
	movem.w	(sp)+,d0-d1
	bne.w	.ex						;not facing the puck
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0					;squared distance to the puck
	cmp.l	#30*30,d0
	bls.w	.ex						;closer than 30: no sweep
	cmp.l	#38*38,d0
	bls.w	Sweepcheck				;between 30 and 38: try a sweep check
.ex	move.b	temp2+1(a3),d0			;d0 = stored direction
	bra.w	doplayeracc

assexit								;exit current assignment on player a3
	addq.w	#1,assnum(a3)			;next slot of the 8 entry assignment list (wraps at 8)
	andi.w	#7,assnum(a3)
	bset	#pfna,pflags(a3)		;signal next assignment
	rts

assinsert							;insert new assignment on player a3. d0 =
									;assignment. Falls into assreplace
	subq.w	#1,assnum(a3)			;back one slot of the 8 entry list (wraps at 8)
	andi.w	#7,assnum(a3)
assreplace							;replace current assignment on player a3. d0 = assignment
	move.l	d1,-(sp)
	move.w	assnum(a3),d1
	move.b	d0,asslist(a3,d1.w)		;store the assignment number in the current slot
	bset	#pfna,pflags(a3)		;new assignment flag
	move.l	(sp)+,d1
	rts

vtoa								;d0/d1 are x/y distances which are converted into direction 0-7 and
									;returned in d0 (8 = no direction)
	movem.l	d2/a0,-(sp)
	move.w	d0,d2
	or.w	d1,d2
	beq.w	.nodir					;both zero: no direction
	clr.w	d2						;d2 = 4 bit index built from the signs and slope tests
	tst.w	d0
	bpl.w	.0
	neg.w	d0						;|dx|
	bset	#0,d2					;bit 0: dx negative
.0	tst.w	d1						;y sign
	bpl.w	.1
	neg.w	d1						;|dy|
	bset	#1,d2					;bit 1: dy negative
.1	asl.w	#1,d1					;slope test: |dx| against 2|dy|
	cmp.w	d1,d0
	bhi.w	.2						;|dx| > 2|dy|
	bset	#2,d2					;bit 2: |dx| <= 2|dy|
.2	lsr.w	#1,d1					;slope test: |dy| against 2|dx|
	asl.w	#1,d0
	cmp.w	d0,d1
	bhi.w	.3						;|dy| > 2|dx|
	bset	#3,d2					;bit 3: |dy| <= 2|dx|
.3	movea.l	#.dt,a0					;look up the direction
	clr.w	d0
	move.b	(a0,d2.w),d0			;look up the direction for that index
	movem.l	(sp)+,d2/a0
	rts

.nodir	moveq	#8,d0				;8 = no direction
	movem.l	(sp)+,d2/a0
	rts

.dt	dc.b	1,7,3,5,0,0,4,4			;direction by index (see bits above); 16 entries
	dc.b	2,6,2,6,1,7,3,5

GetHot								;push long address of structure to get hot spot from. Hot spot x/y
									;returned in d0/d1. Reads a byte pair per frame from HotList
	movem.l	a0-a1,-(sp)				;$C(sp) = the address the caller pushed (above 2 longs and the return
									;address)
	movea.l	$C(sp),a0				;a0 = structure address pushed by the caller (above the return address)
	clr.w	d0
	clr.w	d1
	tst.w	frame(a0)
	ble.w	.ex						;no frame: hot spot 0,0
	movea.l	#HotList,a1
	move.w	frame(a0),d0
	add.w	d0,d0					;2 bytes per frame
	move.b	1(a1,d0.w),d1			;hot y
	ext.w	d1
	move.b	(a1,d0.w),d0			;hot x
	ext.w	d0
	btst	#3,attribute(a0)		;attribute bit 3 set: negate hot x
	beq.w	.nox
	neg.w	d0
.nox	btst	#4,attribute(a0)	;attribute bit 4 clear: negate hot y
	bne.w	.noy
	neg.w	d1
.noy	btst	#sfhor,(sflags).w	;horizontal screen: swap the axes
	beq.w	.nhor
	exg	d0,d1
	neg.w	d1
.nhor								;no axis swap
.ex	movem.l	(sp)+,a0-a1				;restore registers, drop the argument
	move.l	(sp)+,(sp)				;drop the caller's argument (replaces it with the return address)
	rts

SetSPA								;set sprite animation on struct a3. d1 = new animation
	cmp.w	SPA(a3),d1
	beq.w	rtss					;already running it
	clr.w	SPAnum(a3)
	move.w	d1,SPA(a3)
	st	SPAcnt(a3)					;SPAcnt: restart animation
	rts

doplayeracc							;player a3 gets acc. in d0 dir
									;in: d0 = wanted direction (0-7; 8/9 = none), d7 = elapsed frames. Chooses
									;forward or backward skating, turns facedir gradually, and ends in
									;playeracc (accelerate along d2)
	tst.w	position(a3)
	beq.w	goalieacc				;goalie is special
	move.w	#SPAglide,d1			;d1 = animation to use if standing: glide
	btst	#pfrev,pflags(a3)
	beq.w	.d0
	move.w	#SPAglideback,d1		;skating backwards: glide back
.d0	andi.w	#$F,d0					;low nibble: direction or 8/9
	cmp.w	#7,d0
	ble.w	.d1						;0-7 is a real direction
	cmp.w	#9,d0
	bne.w	.cgl					;8 = no direction: just keep the animation
	move.w	Xvel(a3),d0				;9 = stop
	or.w	Yvel(a3),d0
	bne.w	dostop					;still moving: stop
.cgl	btst	#pf2aip,pflags2(a3)	;animation in progress: leave it
	beq.s	SetSPA					;else set glide animation d1
	rts

.d1	movem.w	d0-d1,-(sp)				;save wanted direction and animation
	move.w	d0,d2					;d2 = wanted direction
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	.clrrev					;the puck carrier never skates backwards
	move.w	(puckx).w,d0
	sub.w	(a3),d0					;d0 = dx to the puck
	move.w	Ypos(a3),d3
	move.b	(puckvy).w,d1			;(92 move puckvy,d1 / asr #7,d1)
	ext.w	d1
	add.w	(pucky).w,d1
	sub.w	d3,d1					;d1 = dy to the puck, led by its y velocity
	btst	#pfgoal,pflags(a3)
	bne.w	.c1
	neg.w	d0						;mirror everything into the frame of the team shooting
	neg.w	d1						;toward +y (d3 = my y, d2 = wanted direction)
	neg.w	d3
	eori.w	#4,d2
.c1	btst	#pfrev,pflags(a3)		;already skating backwards?
	bne.w	.inrev
	tst.w	d3
	bpl.w	.fwd					;skate back in own zone only
	cmp.w	#4,d2
	bne.w	.fwd					;backwards only if the mirrored wanted direction is 4
	bsr.w	vtoa					;direction to the puck (mirrored frame)
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.fwd					;forward unless the puck direction is 7, 0 or 1 ...
	bra.w	.rev					;... in which case skate backwards
.inrev	subq.w	#3,d2				;already backwards: stay so only if the wanted direction ...
	andi.w	#7,d2
	cmp.w	#2,d2
	bhi.w	.fwd					;... is 3, 4 or 5 (mirrored)
	bsr.w	vtoa
	addq.w	#2,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	bhi.w	.fwd					;and the puck direction is 6, 7, 0, 1 or 2

.rev	btst	#pfrev,pflags(a3)	;backwards wanted: already so?
	bne.w	.done					;already backwards
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	beq.w	.setrev					;standing still: start backwards
	move.w	Xvel(a3),d0
	move.w	Yvel(a3),d1
	bsr.w	vtoa					;direction of motion
	sub.w	(sp),d0					;minus the wanted direction
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.done					;motion not within one step of the wanted direction: stay forward
.setrev	bset	#pfrev,pflags(a3)	;start skating backwards
	bra.w	.done

.fwd								;skate forwards (falls into .clrrev)
.clrrev	bclr	#pfrev,pflags(a3)	;skate forwards

.done	movem.w	(sp)+,d0-d1			;d0 = wanted direction, d1 = animation
	move.w	facedir(a3),d2
	sub.w	d2,d0
	andi.w	#7,d0					;d0 = wanted - facing (0-7)
	movea.l	#.ftab,a0
	asl.w	#1,d0
	tst.w	(a0,d0.w)
	beq.w	noturn0					;facing the right way (or opposite): no turn rate

	move.w	Xvel(a3),d4
	muls.w	d4,d4
	move.w	Yvel(a3),d3
	muls.w	d3,d3
	add.l	d4,d3
	swap	d3						;d3 = (Xvel^2 + Yvel^2) >> 16: speed class
	move.w	#$300,d4
	sub.w	d3,d4					;turn rate falls as speed rises ...
	cmp.w	#$180,d4
	bge.w	.iok
	move.w	#$180,d4				;... down to $180
.iok	muls.w	(a0,d0.w),d4		;times the signed turn step (+-$10)
	btst	#pfrev,pflags(a3)
	beq.w	.i0
	neg.l	d4						;backwards: turn the other way
.i0	add.l	d4,facedir(a3)			;long add: facedir is the high word, the word at $56 is the fraction
	andi.w	#7,facedir(a3)
	move.w	facedir(a3),d2			;d2 = new facing for playeracc

	cmp.w	#20,d3
	bls.w	.s3						;slow: keep the animation passed in d1

	clr.w	d1						;fast: pick a turn animation, left or right
	tst.w	(a0,d0.w)
	bpl.w	.s1
	eori.w	#SPAturnl-SPAturnr,d1
.s1	btst	#3,attribute(a3)		;attribute bit 3 swaps the turn sense
	beq.w	.s2
	eori.w	#SPAturnl-SPAturnr,d1	;attribute bit 3 swaps the sense
.s2	addi.w	#SPAturnr,d1			;d1 = SPAturnr or SPAturnl
	bset	#pf2aip,pflags2(a3)		;animation in progress
.s3	bsr.w	SetSPA					;set the animation

	cmp.w	#2,d3
	bhi.w	noturn					;moving at some speed: accelerate (reversed when pfrev)
	rts								;almost still: no acceleration this call

.ftab	dc.w	0,$10,$10,$10,0,-$10,-$10,-$10	;turn step by (wanted - facing): 0 = no turn, sign = sense

goalieacc							;goalie gets acc. in direction d0. Turns facedir one step toward d0 (92
									;set it directly)
	move.w	#SPAgready,d1			;d1 = animation when not skating: goalie ready
	andi.w	#$F,d0
	cmp.w	#7,d0
	ble.w	.d1						;0-7 is a real direction
	cmp.w	#9,d0
	bne.w	.cgl					;8 = no direction
	move.w	Xvel(a3),d0				;9 = stop
	or.w	Yvel(a3),d0
	bne.w	stopna					;still moving: slow down
.cgl	btst	#pf2aip,pflags2(a3)	;animation in progress: leave it
	beq.w	SetSPA
	rts
.d1	sub.w	facedir(a3),d0			;d0 = wanted - facing
	beq.w	.spa					;already facing it
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0					;+1/-1: one step in the shorter turn direction
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
.spa	move.w	#SPAgskate,d1		;goalie skate animation
	bsr.w	SetSPA
	move.w	facedir(a3),d2			;accelerate along the (new) facing
	bra.w	playeracc

noturn0								;doplayeracc when the wanted direction needs no turn (.ftab entry 0). d0 =
									;direction minus facedir, times 2
	moveq	#2,d4					;d4 = 2 forwards, 6 when skating backwards
	btst	#pfrev,pflags(a3)
	beq.w	.0
	addq.w	#4,d4
	eori.w	#8,d0					;backwards: swap "straight" and "opposite"
.0	tst.w	d0						;straight ahead?
	beq.w	.nochg					;the wanted direction is already the way I skate
	move.w	Xvel(a3),d0				;opposite: look at the current motion
	move.w	Yvel(a3),d1
	bsr.w	vtoa
	btst	#3,d0					;not moving
	bne.w	.nostop
	sub.w	facedir(a3),d0
	add.w	d4,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	blt.w	dostop					;moving along the facing: brake first

.nostop	addq.w	#1,facedir(a3)		;turn one step (the way depends on attribute bit 3)
	btst	#3,attribute(a3)
	beq.w	.nos0
	subq.w	#2,facedir(a3)
.nos0	andi.w	#7,facedir(a3)		;wrap facing to 0-7
	move.w	#SPAglide,d1
	btst	#pfrev,pflags(a3)
	beq.w	SetSPA
	move.w	#SPAglideback,d1
	bra.w	SetSPA

.nochg	move.w	#SPAskateback,d1	;pick the skating animation
	btst	#pfrev,pflags(a3)
	bne.w	.ns
	move.w	#SPAskate,d1
	btst	#pf2inj,pflags2(a3)		;pflags2 bit 6 uses animation SPAstumble
	beq.w	.nb6
	move.w	#SPAstumble,d1
.nb6	move.w	(puckc).w,d4		;puck carrier check
	cmp.w	SCnum(a3),d4
	bne.w	.ns
	move.w	#SPAskatewp,d1			;carrying the puck: skate with puck animation
.ns	btst	#pf2aip,pflags2(a3)		;set the animation unless one is in progress
	bne.w	noturn					;animation in progress: leave it
	bsr.w	SetSPA

noturn								;reverse the acc. direction when skating backwards, then falls into
									;playeracc. Entered from doplayeracc and noturn0
	btst	#pfrev,pflags(a3)
	beq.w	playeracc
	eori.w	#4,d2					;opposite direction

playeracc							;d2 = direction of acc
	asl.w	#2,d2					;4 bytes per dirtab entry
	lea	dirtab(pc),a0				;(92 move.l #dirtab,a0)
	move.w	2(a0,d2.w),d1			;y inc
	move.w	(a0,d2.w),d0			;x inc
	move.w	Wallsin(a3),d2			;wallsin: check acc dir and don't push wall
	beq.w	.nox
	eor.w	d0,d2
	bpl.w	.nox					;same sign as the wall normal: allowed
	clr.w	d0						;pushing into the wall in x: cancel x
.nox	move.w	Wallcos(a3),d2		;y axis wall check
	beq.w	.noy
	eor.w	d1,d2
	bmi.w	.noy
	clr.w	d1						;same for y (the sign test is the other way round)
.noy	clr.w	d2					;acceleration factor from weight and leg strength
	move.b	weight(a3),d2
	lsr.w	#3,d2					;(92 lsr #4)
	neg.w	d2
	addi.w	#$20,d2					;32
	add.b	legstr(a3),d2			;d2 = 32 - weight/8 + leg strength: acceleration factor
	tst.w	position(a3)
	bne.w	.ng
	add.b	legstr(a3),d2			;goalie adds legstr twice plus 8
	addq.w	#8,d2

.ng	muls.w	d2,d0					;scale the increment by the factor
	muls.w	d2,d1
	asr.l	#5,d0					;increment * factor / 32
	asr.l	#5,d1

	muls.w	d7,d0					;times elapsed frames
	muls.w	d7,d1
	add.w	Xvel(a3),d0				;d0/d1 = new velocity
	add.w	Yvel(a3),d1
	move.w	d0,d2
	move.w	d1,d3
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d2,d3					;d3 = new speed squared

	movem.w	d0-d1,-(sp)
	bsr.w	getpde					;d0 = this player's energy level
	clr.w	d2
	move.b	legspd(a3),d2
	mulu.w	d0,d2
	asl.l	#4,d2
	swap	d2
	asl.w	#2,d2					;d2 = index into MaxSpeed (leg speed * energy scaled, x4 for longs)
	lea	MaxSpeed(pc),a2				;(92 move.l #MaxSpeed,a2)
	move.l	(a2,d2.w),d2			;d2 = max speed squared
	btst	#pf2inj,pflags2(a3)		;pflags2 bit 6 cuts max speed to 1/8
	beq.w	.ms
	lsr.l	#3,d2
.ms	movem.w	(sp)+,d0-d1				;restore the new velocity

	cmp.l	d2,d3					;max speed check
	bhi.w	.sube					;too fast: keep the old velocity
	move.w	d0,Xvel(a3)
	move.w	d1,Yvel(a3)

.sube	tst.w	(OptLine).w			;energy only drains when line changes are on
	bne.w	rtss
	move.w	(HVcount).l,d0			;HVcount
	andi.w	#$7F,d0
	bne.w	rtss					;only 1 call in 128 (random)
	bsr.w	getpde
	subi.w	#$21,d0					;33
	cmp.w	#$C00,d0
	blt.w	setpde					;below $C00: just lower by 33
	move.b	endurance(a3),d2
	ext.w	d2
	add.w	d2,d0					;above $C00: also add the endurance byte (signed)
	bra.w	setpde

MaxSpeed							;max speed values for each rating level 0-f. ((n+20)*275)^2 (92 used 250)
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

dostop								;player a3 stops. Entered from doplayeracc and noturn0
	cmpi.w	#$1000,Xvel(a3)			;.slim Xvel
	bgt.w	.set					;fast in any axis (|v| > $1000): play the stop animation
	cmpi.w	#-$1000,Xvel(a3)
	blt.w	.set
	cmpi.w	#$1000,Yvel(a3)
	bgt.w	.set
	cmpi.w	#-$1000,Yvel(a3)
	blt.w	.set
	bra.w	stopna					;stop with no anim
.set	move.w	#SPAglide,d1		;backwards: plain glide animation, no skid
	btst	#pfrev,pflags(a3)
	bne.w	.0
	bset	#pf2aip,pflags2(a3)		;forward: animation in progress ...
	move.w	#SPAstop,d1				;... the skid stop
.0	bsr.w	SetSPA					;then fall into stopna to slow down
stopna								;slow player a3 by 150 on each axis, no animation change. Falls in from
									;dostop, also entered from goalieacc and others
	tst.w	Xvel(a3)				;x axis: move toward zero by 150, clamp at zero
	bpl.w	.xp
	addi.w	#$96,Xvel(a3)			;150
	bmi.w	.y						;still negative: done
	clr.w	Xvel(a3)				;crossed zero: clear (the code below then also ends at 0)
.xp	subi.w	#$96,Xvel(a3)			;positive x: subtract 150
	bpl.w	.y
	clr.w	Xvel(a3)
.y	tst.w	Yvel(a3)				;same for the y axis
	bpl.w	.yp
	addi.w	#$96,Yvel(a3)
	bmi.w	rtss
	clr.w	Yvel(a3)
.yp	subi.w	#$96,Yvel(a3)			;positive y: subtract 150
	bpl.w	rtss
	clr.w	Yvel(a3)
	rts

runspeed	equ	200					;acc speed equate for table below

dirtab								;x,y speed for each direction 0-7 (8 x,y word pairs); diagonals are
									;runspeed/1.414
	dc.w	0,runspeed				;0: +y
	dc.w	runspeed*1000/1414,runspeed*1000/1414	;1: +x +y
	dc.w	runspeed,0				;2: +x
	dc.w	runspeed*1000/1414,-runspeed*1000/1414	;3: +x -y
	dc.w	0,-runspeed				;4: -y
	dc.w	-runspeed*1000/1414,-runspeed*1000/1414	;5: -x -y
	dc.w	-runspeed,0				;6: -x
	dc.w	-runspeed*1000/1414,runspeed*1000/1414	;7: -x +y
