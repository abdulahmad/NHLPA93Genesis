;	Penalty logic. This file calls penalties and the other stoppages of play, such as the
;	whistle, icing, offsides and goals. It sends players to the penalty box, runs power plays,
;	shows the referee's messages and switches the rink between its horizontal and vertical views.

AddPenalty	;add penalty d0 (PenaltyList offset) for player a3. Ignored while the clock is stopped, when penalties are off, or offsides when offsides are off. Falls into AddPenalty2
	btst	#gmclock,(gmode).w
	bne.w	rtss
	cmp.w	#$C,d0			;icing (92 used 8)
	beq.w	AddPenalty2
	tst.w	(OptPen).w
	beq.w	rtss			;penalties off
	btst	#gmoffs,(gmode).w
	bne.w	AddPenalty2
	cmp.w	#$10,d0			;offsides (92 used $A)
	beq.w	rtss

AddPenalty2	;forced penalties like face off and game over. d0 = penalty number, a3 = player or player on penalized team. Penalty numbers from $E (goal) up raise the crowd and play a song
	btst	#sfhor,(sflags).w
	bne.w	rtss
	movem.l	d1/a0-a1,-(sp)
	cmp.w	#$E,d0			;goal (92 used 6) and up
	blt.w	.nosnd
	addi.w	#$C8,(crowdlevel).w	;200
	move.w	#$C,-(sp)		;song $C for the home team
	btst	#pfteam,pflags(a3)
	beq.w	.snd
	addi.w	#$14,(CwdExciteLvl).w	;visitors: +20 excitement
	move.w	#$B,(sp)		;song $B
.snd	bsr.w	song
.nosnd	movea.w	#(PenBuf-M68K_RAM),a1
	moveq	#$1F,d1			;MaxPen-1
.0	tst.w	(a1)+			;find free slot
	dbeq	d1,.0
	bne.w	.noplayer		;buffer full
	move.b	SCnum+1(a3),-(a1)
	move.b	d0,-(a1)
	movea.l	#Penaltylist,a0
	adda.w	(a0,d0.w),a0
	tst.b	1(a0)			;penalty minutes
	beq.w	.noplayer
	bset	#pf2pen,pflags2(a3)		;92 used bit 6
	beq.w	.noplayer
	clr.w	(a1)			;player already has a penalty, drop this one
.noplayer	movem.l	(sp)+,d1/a0-a1
	rts

PenaltyManager	;called periodically. d7 = elapsed time since last call
	bsr.w	updatepentime
	bsr.w	checkfornewpen
	bsr.w	chkprogress
	bra.w	UpdatePA

chkprogress	;control progress of ref and game control thru penalty events. When the stop delay runs out and a penalty with minutes is in PenBuf, switch to the horizontal rink for the player to enter the penalty box
	btst	#gmpen,(gmode).w
	beq.w	rtss
	tst.w	(Pencntdwn).w
	bmi.w	InProgress
	sub.w	d7,(Pencntdwn).w
	bpl.w	rtss
	bclr	#gmpendel,(gmode).w
	movea.w	#(PenBuf-M68K_RAM),a0
.find	tst.w	(a0)+			;look for any penalty with minutes
	beq.w	rtss
	clr.w	d0
	move.b	-2(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	tst.b	1(a1)			;penalty minutes
	beq.s	.find
	bset	#sf2drec,(sflags2).w		;switch to horizontal mode for player to enter penalty box
	move.w	(vcount).w,-(sp)
	bsr.w	forceblack
	move.w	(sp)+,(vcount).w
	bsr.w	SetHor
	move.w	(ExtraChars).w,d4	;load horizontal ref tiles
	movea.l	#RefMap2+8,a2
	bsr.w	DecompressGraphicsPlain
	bsr.w	NewTicker
	bsr.w	NewTicker3
	st	(puckc).w
	movea.w	#(puckx-M68K_RAM),a3
	move.l	#pnothing,d0			;pnothing
	bsr.w	assinsert
	move.w	#$1C20,temp1(a3)		;temp1 = 120*60

	st	(RefStep).w
	clr.w	(RefCnt).w
	bsr.w	UpdatePA
	move.w	#$32,(RefCnt).w		;50
	clr.w	d0
	bsr.w	PushRef			;ref frame 0
	move.w	#$18,(palcount).w	;24
	rts

InProgress	;ref in progress-- update graphics and stats and penalty information. Takes the last PenBuf entry: the first pass logs a penalty with minutes and sends the player to the box, later passes wait until he is off the ice and drop the entry. When PenBuf is empty, recount players and go to the face off. Entered from chkprogress
	tst.w	(RefCnt).w
	bpl.w	rtss			;animation in progress
	tst.w	(RefStep).w
	bpl.w	rtss
	movem.l	d0/a0-a3,-(sp)
.top	movea.w	#(PenBuf-M68K_RAM),a0
	tst.w	(a0)+
	beq.w	.exit
.0	tst.w	(a0)+			;find end of list
	bne.s	.0
	subq.w	#4,a0
	bclr	#7,1(a0)		;player who is guilty
	bne.w	.Sa
	move.l	a3,-(sp)
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#scsize,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	tst.w	position(a3)
	movea.l	(sp)+,a3
	bpl.w	.ex			;still on the ice
	clr.w	(a0)
	bra.w	.ex

.Sa	clr.w	d0
	move.b	(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	clr.w	d2
	move.b	1(a1),d2		;penalty minutes
	beq.w	.sa2			;no player involved
	movem.l	d0-d1/a1-a4,-(sp)
	bsr.w	GetPeriodTimeRemaining	;log time, penalty and player
	movea.w	#(PenSum-M68K_RAM),a4
	adda.w	(PenSumLength).w,a4
	cmpi.w	#$EC,(PenSumLength).w	;log full: keep overwriting the last entry
	beq.w	.full
	addq.w	#4,(PenSumLength).w
.full	move.w	d0,(a4)+		;time
	move.b	(a0),(a4)+		;penalty
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#scsize,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	clr.w	d0
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	btst	#pfteam,pflags(a3)
	beq.w	.sa1
	bset	#7,-1(a4)		;log: visitors
	move.w	#$8000,d0
	exg	a1,a2
.sa1	addq.w	#1,tmPenalties(a2)
	add.w	d2,tmPenmin(a2)
	move.b	pnum(a3),d0
	move.b	d0,(a4)			;log: player
	move.w	d0,(TempPlOffset).w
	ext.w	d0
	addi.w	#$102,d0		;per-player penalty minutes byte at $102+pnum
	add.b	d2,(a2,d0.w)
	subi.w	#$102,d0
	asl.w	#1,d0
	ext.w	d2
	mulu.w	#$3C,d2			;60
	bset	#$D,d2
	tst.w	tmpdst(a2,d0.w)
	bmi.w	.st
	btst	#4,tmpdst(a2,d0.w)
	beq.w	.st
	bset	#$C,d2			;keep bit 4 of an old penalty time as bit 12
.st	move.w	d2,tmpdst(a2,d0.w)
	andi.w	#$EFFF,d2
	moveq	#(maxros-1)*2+2,d1			;(MaxRos-1)*2+2
.ctop	subq.w	#2,d1			;same time on the other team
	bmi.w	.nocoin
	move.w	tmpdst(a1,d1.w),d3
	andi.w	#$EFFF,d3
	cmp.w	d3,d2
	bne.s	.ctop
	bset	#6,tmpdst(a1,d1.w)		;coincidental
	bset	#6,tmpdst(a2,d0.w)
.nocoin	movem.l	a0,-(sp)		;add player to penalty box list
	lea	$9A(a2),a0
	moveq	#$18,d1
.pl	tst.b	(a0)+			;find end of list
	dbmi	d1,.pl
	move.b	d0,-1(a0)
	st	(a0)
	movem.l	(sp)+,a0

	move.w	#apenalty,d0			;apenalty
	bsr.w	assreplace
	movem.l	(sp)+,d0-d1/a1-a4
	bsr.w	SetPA
	bsr.w	USBoard
	bra.w	.ex
.sa2	clr.w	(a0)
	btst	#sfhor,(sflags).w
	bne.w	.top
	bsr.w	SetPA
	bra.w	.ex

.exit	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	coinsearch
	adda.w	#tmsize,a2
	bsr.w	coinsearch
	
	bclr	#gmpen,(gmode).w
	movea.w	#(puckx-M68K_RAM),a3
	move.w	#pfaceoff,d0			;pfaceoff
	bsr.w	assreplace
.ex	movem.l	(sp)+,d0/a0-a3
	rts

coinsearch	;a2 = team. Clears tmpdst bit 5, counts players kept off the ice by penalties (coincidental and bit 4 times do not count, at most 2) and sets tmap. Called twice from InProgress
	moveq	#6,d1
	moveq	#(maxros-1)*2,d0			;(MaxRos-1)*2
.top	tst.w	tmpdst(a2,d0.w)
	ble.w	.nap
	bclr	#5,tmpdst(a2,d0.w)
	btst	#6,tmpdst(a2,d0.w)		;coincidental
	bne.w	.nap
	btst	#4,tmpdst(a2,d0.w)
	bne.w	.nap
	cmp.w	#4,d1			;never below 4 players
	beq.w	.nap
	subq.w	#1,d1
.nap	subq.w	#2,d0
	bpl.s	.top
	move.w	d1,tmap(a2)
	rts

checkfornewpen	;look for new penalty (entered thru addpenalty(2)). Stops play at once for penalties without minutes or when the guilty team does not have the puck, otherwise starts a delayed penalty call
	btst	#sfhor,(sflags).w
	bne.w	rtss
	movea.w	#(PenBuf-M68K_RAM),a0
.next	tst.w	(a0)+
	beq.w	rtss
	btst	#gmpen,(gmode).w
	bne.w	.iscalled
	clr.w	d0
	move.b	-2(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	tst.b	1(a1)			;time for penalty
	beq.w	.callit
	move.w	(puckc).w,d0
	bmi.w	.dc
	subq.w	#6,d0
	move.b	-1(a0),d1		;player penalized
	ext.w	d1
	subq.w	#6,d1
	eor.w	d1,d0
	bmi.w	.dc			;delayed penalty call

.callit	bsr.w	Stop4Pen

.iscalled	bset	#7,-1(a0)
	bne.s	.next
	clr.w	d0
	move.b	-2(a0),d0		;penalty called
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	clr.w	d1
	move.b	(a1),d1			;delay for stopping action
	asl.w	#5,d1
	cmp.w	(Pencntdwn).w,d1
	ble.s	.next
	move.w	d1,(Pencntdwn).w
	bra.s	.next

.dc	bset	#gmpendel,(gmode).w
	bne.s	.next
	move.w	#$2C,d0			;delayed penalty (92 used $24)
	bsr.w	SetPA
	bra.s	.next

Stop4Pen	;a0 = penaltylist penalty +2. Stop the clock, set the face off spot from the penalty type, blow the whistle. Also entered from puckfaceoff+38
	bset	#gmclock,(gmode).w
	bne.w	.skipfo
	clr.w	d0
	clr.w	d1
	cmpi.b	#$E,-2(a0)		;goal (92 used 6): center ice
	beq.w	.noticing
	move.w	(ltx).w,d0
	move.w	(lty).w,d1
	cmpi.b	#6,-2(a0)		;OOP (92 used $C)
	beq.w	.noticing
	move.w	(puckx).w,d0
	move.w	(pucky).w,d1
	cmpi.b	#$C,-2(a0)		;icing (92 used 8)
	bne.w	.noticing
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	move.b	-1(a0),d1
	ext.w	d1
	asl.w	#scsize,d1			;scsize
	adda.w	d1,a3
	move.w	#$258,d1		;600
	btst	#pfgoal,pflags(a3)
	movea.l	(sp)+,a3
	beq.w	.noticing
	neg.w	d1
.noticing	movem.w	d0-d1,-(sp)
	cmp.w	#$46,d0			;.xspot = 70
	blt.w	.0
	move.w	#$46,d0
.0	cmp.w	#$FFBA,d0		;-.xspot
	bgt.w	.1
	move.w	#$FFBA,d0
.1	cmp.w	#$A6,d1			;yspot-.ygive = 206-40
	blt.w	.2
	move.w	#$CE,d1			;.yspot = 206
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.2
	neg.w	d0
.2	cmp.w	#$FF5A,d1		;-.yspot+.ygive
	bgt.w	.3
	move.w	#$FF32,d1		;-.yspot
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.3
	neg.w	d0
.3	move.w	d0,(fox).w
	move.w	d1,(foy).w
	addq.w	#4,sp
	bsr.w	limitfo

.skipfo	clr.w	(Pencntdwn).w
	bset	#gmpen,(gmode).w
	move.w	#SFXwhistle,-(sp)		;whistle (92 used 10)
	bsr.w	sfx
	move.w	#$A,d0			;whistle (92 used $26)
	bra.w	SetPA

limitfo	;limit face off to 5-20 feet from walls of rink. Checks every player in PenBuf
	movem.l	d0-d1/a0-a1,-(sp)
	movea.w	#(PenBuf-M68K_RAM),a0
.loop	bsr.w	.lf
	addq.w	#2,a0
	tst.w	(a0)
	bne.s	.loop
	movem.l	(sp)+,d0-d1/a0-a1
	rts

.lf	move.b	1(a0),d0
	andi.w	#$7F,d0
	asl.w	#scsize,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a1
	move.w	#$58,d1
	btst	#pfgoal,pflags(a1,d0.w)
	bne.w	.0
	neg.w	d1
	cmp.w	(foy).w,d1
	blt.w	rtss
	move.w	#$FFBF,(foy).w		;-.nuy = -65
	bra.w	.sx
.0	cmp.w	(foy).w,d1
	bgt.w	rtss
	move.w	#$41,(foy).w		;(xref is string bytes).nuy = 65
.sx	move.w	#$46,d0			;nux = 70
	tst.w	(fox).w
	bpl.w	.1
	neg.w	d0
.1	move.w	d0,(fox).w
	rts

UpdatePA	;animate ref in ref window. Also runs ShowThreeStars for game over and reprints the horizontal penalty message line when penmsgtimer runs out
	tst.w	(RefCnt).w
	bmi.w	rtss
	sub.w	d7,(RefCnt).w
	bpl.w	.0
	bsr.w	SetPA2
.0	cmpi.w	#4,(RefPen).l		;game over (92 used 4)
	bne.w	.1
	bsr.w	ShowThreeStars
.1	sub.w	d7,(penmsgtimer).w
	bpl.w	rtss
	move.w	#$7FFF,(penmsgtimer).w
	bsr.w	ClearPenaltyMessage
	bsr.w	printz
	String	$BF,$11,$B
	bsr.w	GetPlayerName
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w		;center it
	bra.w	print

SetPA	;start ref animation. d0 = animation (penalty number). goal also calls ShowGoalBox, and penmsgtimer is set to 60 in horizontal mode. Falls into SetPA2
	move.w	d0,(RefPen).w
	clr.w	(RefStep).w
	bsr.w	prefmes
	cmp.w	#$E,d0			;goal (92 used 6)
	bne.w	.0
	bsr.w	ShowGoalBox
.0	move.w	#$7FFF,(penmsgtimer).w
	btst	#sfhor,(sflags).w
	beq.w	SetPA2
	move.w	#$3C,(penmsgtimer).w	;60

SetPA2	;update animation for ref. Next frame/delay pair from the PenaltyList animation of RefPen. Also called from UpdatePA
	movem.l	d0-d2/a0-a1,-(sp)
	moveq	#$40,d0			;clear ref window
	tst.w	(RefStep).w
	bmi.w	.pr
	move.w	(RefStep).w,d0
	addq.w	#2,(RefStep).w
	move.w	(RefPen).w,d1
	movea.l	#Penaltylist,a0
	adda.w	(a0,d1.w),a0
	addq.w	#2,a0
	adda.w	(a0),a0
	move.w	(a0,d0.w),d0
	bpl.w	.0
	neg.w	d0			;negative = last frame
	st	(RefStep).w
.0	clr.w	d1
	move.b	d0,d1
	asl.w	#3,d1
	move.w	d1,(RefCnt).w
	lsr.w	#8,d0
.pr	bsr.w	PushRef
	movem.l	(sp)+,d0-d2/a0-a1
	rts

PushRef	;tell vblank what to display. d0 = ref frame, $40 clears the window. The horizontal ref uses RefMap2
	movem.l	d0-d2/a0-a1,-(sp)
	cmp.w	#$40,d0
	beq.w	.clearit
	mulu.w	#$70,d0			;refwidth*refheight*2
	movea.l	#RefsMap,a0
	btst	#sfhor,(sflags).w
	beq.w	.m1
	movea.l	#RefMap2,a0
.m1	adda.l	4(a0),a0
	addq.w	#4,a0
	adda.w	d0,a0
	movea.w	#(RefRamMap-M68K_RAM),a1
	move.w	(ExtraChars).w,d2
	btst	#sfhor,(sflags).w
	bne.w	.4
	ori.w	#$8000,d2		;priority
.4	moveq	#$37,d0			;(refheight*refwidth)-1
.1	move.w	(a0)+,(a1)
	add.w	d2,(a1)+
	dbf	d0,.1
	bset	#sf2refref,(sflags2).w
	bra.w	.ex

.clearit	btst	#sfhor,(sflags).w		;horizontal mode only clears the line
	bne.w	.cl
	movea.w	#(RefRamMap-M68K_RAM),a1
	moveq	#$37,d0			;(refheight*refwidth)-1
.2	move.w	#$7FF,(a1)+		;blank tile (92 1)
	dbf	d0,.2
	bset	#sf2refref,(sflags2).w
.cl	moveq	#-1,d0			;clear line
	bsr.w	prefmes

.ex	movem.l	(sp)+,d0-d2/a0-a1
	rts

prefmes	;print message for penalty d0 (negative clears it). Vertical mode: framed under the ref. Horizontal mode: one centered line on row $B
	movem.l	d0-d2/a1,-(sp)
	btst	#sfhor,(sflags).w
	bne.w	.hor
	tst.w	d0
	bpl.w	.noblank
	bsr.w	printz
	String	$BF,0,$A
	moveq	#$D,d0
	moveq	#3,d1
	move.w	#$7FF,d2		;blank tile (92 1)
	bsr.w	eraser
	bra.w	.ex

.noblank	bsr.w	printz
	String	$BF,5,$A		;x 5 (92 6)
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	subq.w	#2,d0			;empty string (92 cmp #4 / bls)
	beq.w	.ex
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bpl.w	.nb0
	clr.w	(printx).w
.nb0	move.w	(a1),d0
	tst.b	-1(a1,d0.w)
	bne.w	.nb1
	subq.w	#1,d0
.nb1	moveq	#3,d1
	bsr.w	Framer
	subq.w	#2,(printy).w
	addq.w	#1,(printx).w
	bsr.w	print
	bra.w	.ex

.hor	bsr.w	ClearPenaltyMessage	;clears the line first
	tst.w	d0
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$11,$B
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
.ex	movem.l	(sp)+,d0-d2/a1
	rts

ClearPenaltyMessage	;blank the horizontal mode penalty message line (22 spaces at x 5, y $B). Called from UpdatePA and prefmes
	bsr.w	printz
	String	$BF,5,$B,'                      ',0
	rts

PenGoalStuff	;do this stuff after a goal. a1 = scored on team, a2 = scoring team. If the scoring team had more players on ice, the first scored on player in the box without a coincidental penalty is released
	movem.l	d0-d2/a0,-(sp)
	bsr.w	ClearPenaltyBuffer

	move.w	tmap(a2),d2		;end p.killing by scored on team
	cmp.w	tmap(a1),d2
	ble.w	.ex
	lea	$9A(a1),a0
.0	clr.w	d2
	move.b	(a0)+,d2
	bmi.w	.ex
	btst	#6,tmpdst(a1,d2.w)		;coincidental
	bne.s	.0
	clr.w	tmpdst(a1,d2.w)
	bsr.w	RemovePlayerFromList
	addq.w	#1,tmap(a1)
	addq.w	#1,tmPwrGoals(a2)
	bset	#tmflcc,(tmstruct+tmflags).w	;tmflcc
	bset	#tmflcc,(awtmstruct+tmflags).w	;tmflcc
.ex	movem.l	(sp)+,d0-d2/a0
	rts

ClearPenaltyBuffer	;clear PenBuf (92 inlined this in PenGoalStuff). Also called from clockcont
	moveq	#$1F,d0			;MaxPen-1
	movea.w	#(PenBuf-M68K_RAM),a0
.0	clr.w	(a0)+
	dbf	d0,.0
	rts

updatepentime	;update the time remaining on all penalized players, once a second. Sets sflags3 bit 6 on that tick. Falls into ProcessPenaltyList for team 2
	bclr	#sf3icetime,(sflags3).w
	btst	#gmclock,(gmode).w
	bne.w	rtss
	sub.w	d7,(Penaltytimer).w
	bpl.w	rtss
	addi.w	#jps,(Penaltytimer).w	;jps
	bset	#sf3icetime,(sflags3).w
	bsr.w	chkatop
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	ProcessPenaltyList
	adda.w	#tmsize,a2

ProcessPenaltyList	;a2 = team. Walks the penalty box list ($9A): the first two players without a coincidental penalty count down one second and the rest wait. Beeps when the first served time gets to 5 or less and releases the player at 0. Coincidental penalties count down on their own
	lea	$9A(a2),a0
	movea.w	#(mesarea-M68K_RAM),a1	;serving players
	moveq	#2,d1			;two can serve at once
	moveq	#2,d3
.next	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.done
	btst	#6,tmpdst(a2,d0.w)		;coincidental
	bne.w	.coinpen
	subq.w	#1,d1
	bmi.s	.next			;third or later player waits
	move.w	d0,(a1)+
	subq.w	#1,tmpdst(a2,d0.w)
	bne.w	.cont
	bsr.w	RemovePlayerFromList	;time is up
.cont	bra.s	.next

.done	move.w	(mesarea).w,d0		;first serving player
	cmp.w	#1,d1			;one serving
	beq.w	.chk
	tst.w	d1
	bne.w	.n1
	bsr.w	.chk			;two serving: check the first, then the second
	bra.w	.two
.n1	cmp.w	#$FFFF,d1		;exactly three in the list: check the second only
	bne.w	rtss
.two	move.w	(TextBuffer).w,d0	;second serving player (mesarea+2)

.chk	cmpi.w	#5,tmpdst(a2,d0.w)
	bgt.w	rtss
	move.w	#SFXbeep1,-(sp)	;SFXbeep1
	tst.w	tmpdst(a2,d0.w)
	bne.w	.snd
	bsr.w	releasepl
	move.w	#SFXbeep2,(sp)		;SFXbeep2
.snd	bsr.w	sfx
	rts

.coinpen	subq.w	#1,tmpdst(a2,d0.w)
	btst	#3,tmpdst(a2,d0.w)
	beq.s	.next
	btst	#4,tmpdst(a2,d0.w)
	bne.w	.clr
	move.w	#$1000,tmpdst(a2,d0.w)
	bra.w	RemovePlayerFromList
.clr	clr.w	tmpdst(a2,d0.w)		;falls into RemovePlayerFromList

RemovePlayerFromList	;remove the entry before a0 from a penalty box list by shifting the rest down (list ends with a negative byte). Return a0 = removed slot. Called from PenGoalStuff, ProcessPenaltyList
	moveq	#-1,d2
.shift	addq.w	#1,d2
	move.b	(a0,d2.w),-1(a0,d2.w)
	bpl.s	.shift
	subq.w	#1,a0
	rts

chkatop	;attack time of possession stat update. Called once a second from updatepentime
	moveq	#0,d1
	move.w	(pucky).w,d0
	cmp.w	#$58,d0
	bgt.w	.1
	move.l	#tmsize,d1
	neg.w	d0
	cmp.w	#$58,d0
	blt.w	rtss
.1	btst	#gmdir,(gmode).w
	beq.w	.0
	eori.w	#tmsize,d1
.0	movea.w	#(tmstruct-M68K_RAM),a2
	addq.w	#1,tmATOP(a2,d1.w)		;attack time
	rts

releasepl	;player's penalty time is up so let him out (if appropriate). a2 = team, d0 = player*2. Called from ProcessPenaltyList
	movem.l	d0-d3/a0-a3,-(sp)
	movea.w	tmsort(a2),a3
	suba.w	#SCstruct,a3
.0	adda.w	#SCstruct,a3			;first sort obj not on the ice
	tst.w	position(a3)
	bpl.s	.0

	move.w	d0,d3
	lsr.w	#1,d3
	move.w	tmap(a2),d1
	addq.w	#1,tmap(a2)
	bset	#tmflcc,(tmstruct+tmflags).w	;tmflcc
	bset	#tmflcc,(awtmstruct+tmflags).w	;tmflcc
	movea.l	#priolist,a0
	tst.w	tmgoalie(a2)			;92 cmp #2
	bpl.w	.gin
	addq.w	#1,a0
.gin	clr.w	position(a3)
	move.b	(a0,d1.w),position+1(a3)
	bsr.w	Setplass
	bsr.w	setplayer
	bset	#pf2unav,pflags2(a3)		;92 used bit 4
	movem.l	(sp)+,d0-d3/a0-a3
	rts

GetLowestPen	;a2 = team on the power play, a3 = shorthanded team. Return d0 = power play time left from the penalty box times. Called from updatepwrplay
	clr.w	d0
	clr.w	d3
	lea	$9A(a2),a0
.top	clr.w	d2
	move.b	(a0)+,d2
	bmi.w	.t2
	move.w	tmpdst(a2,d2.w),d2
	btst	#$E,d2
	bne.s	.top
	sub.w	d3,d2
	add.w	d2,d0
	move.w	d2,d3
	bra.s	.top
.t2	cmpi.w	#6,tmap(a3)		;6 on ice, done
	beq.w	rtss
	sub.w	d3,d0
	lea	$9A(a3),a0
	clr.w	d2
.t3	move.b	(a0)+,d2
	bmi.w	rtss
	btst	#6,tmpdst(a3,d2.w)		;coincidental
	bne.s	.t3
	cmp.w	tmpdst(a3,d2.w),d0
	blt.w	rtss
	add.w	d3,d0
	rts

updatepwrplay	;show graphic and time remaining for power plays. Plays song $33 at the start of a home power play, then prints the time and the team on the power play
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3
	move.w	tmap(a2),d0
	sub.w	tmap(a3),d0
	beq.w	.clrpwrplay
	bpl.w	.t0
	btst	#sf2pwrtm,(sflags2).w
	bne.w	.upp
	bsr.w	.clrpwrplay
	bset	#sf2pwrtm,(sflags2).w
	bra.w	.upp

.t0	exg	a2,a3
	btst	#sf2pwrtm,(sflags2).w
	beq.w	.upp
	bsr.w	.clrpwrplay
	bclr	#sf2pwrtm,(sflags2).w

.upp	bset	#sf2pwrplay,(sflags2).w
	bne.w	.uppt
	addq.w	#1,tmPwrPlays(a3)
	cmpa.w	#(tmstruct-M68K_RAM),a3
	bne.w	.uppt
	move.w	#SngPowerPlay,-(sp)
	bsr.w	song
.uppt	bsr.w	printz
	String	$BF,1,$19,'   ',$16,$17,$18,$19,$BF,1,$1A,'  ',0
	bsr.w	GetLowestPen
	bsr.w	PushTime
	bsr.w	print
	movea.l	tmdata(a3),a0
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#2,(a3)
	bsr.w	appendz
	String	$BF,1,$19
	adda.w	4(a0),a0		;team name
	adda.w	(a0),a0
	movea.l	a0,a1
	bsr.w	appstring
	movea.w	a3,a1
	bra.w	print

.clrpwrplay	bclr	#sf2pwrplay,(sflags2).w
	beq.w	rtss
	bra.w	EASNLogo

ClrHor	;revert the graphics back to vertical ice rink mode. Does not remap the fonts
	movem.l	d0-d7/a0-a6,-(sp)
	bclr	#sfhor,(sflags).w
	move.w	#$3E8,(Oldrow).w	;1000

	bsr.w	SprSort

	btst	#sfpz,(sflags).w
	bne.w	.0
	bsr.w	printz
	String	$FF,0,0
	moveq	#$20,d0			;32
	moveq	#$1C,d1			;28
	move.w	#$7FF,d2		;blank tile (92 1)
	bsr.w	eraser
	bsr.w	printscores1
.0	movem.l	(sp)+,d0-d7/a0-a6
	rts

SetHor	;switch graphics to horizontal ice rink graphics mode. Does not remap the fonts
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#sfhor,(sflags).w

.p	btst	#dfok,(disflags).w
	bne.s	.p

	clr.w	(Hscroll).w
	clr.w	(Vscroll).w
	bsr.w	SprSort

	bsr.w	printz
	String	$FE,0,0
	movea.l	#IceRinkMap,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2
	clr.w	d0
	moveq	#$55,d1			;85
	moveq	#$20,d2			;32
	moveq	#$1C,d3			;28
	move.w	(rinkvrcset).w,d4
	moveq	#0,d5
	bsr.w	dobitmap

	bsr.w	USBoard
	btst	#sfpz,(sflags).w
	bne.w	.ex
	move.w	#$800,d0		;92 $1000
	move.w	(VmMap1).w,d1
	move.w	#$7FF,d2		;blank tile (92 1)
	bsr.w	DoFill

.ex	movem.l	(sp)+,d0-d7/a0-a6
	rts

;======================================================================
;======================================================================
;	printscores1, PrintTeamNameAndScore, PrintTeamLogoAndScore, EASNLogo
;	(with the DrawEASNMap entry), USBoard, pplpen, linebar, getlinee,
;	AvgCline, ChkShotStat, loadTeamStruct, SetupTeamForIntermission,
;	reenergizeteam, Intermission, InitScores, UpdateScores, SetScore,
;	NewTicker, NewTicker2, CheckGameTickerStatus, NewTicker3, GameLabels,
;	ClearTickerArea, SetTickerAreaPosition, PrintStringFromList,
;	AdvanceStringPtr, DoHiLights, StartHL and StartHL2.
;	Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after assembly.
;	printz String control bytes $BF/$BE/$BD (-$41/-$42/-$43), then x, y.
;	Team struct (tmsize $1A2, 92 used $88): 0 tmshots, $C tmscore, $16 tmline,
;	$1E tmdata, $22 tmsort, $24 tmap, $26 tmgoalie, $32 tmpde, $66 tmpdst,
;	$9A penalty box list (bytes, -1 end), $E8 per-player shot bytes,
;	$16A line sets. Sort struct ($80 each): 0 Xpos, $14 Ypos, $28 Xvel,
;	$2A Yvel, $34 position, $62 pflags, $66 pnum.
;	Game struct (gstruct): 0 gst1, 2 gst2, 8 gsper
;	$A gss1, $C gss2, $E gsflags (bit 1 gsfhl, bit 2 gsfso).

printscores1	;draw scoreboard. Vertical rink: period box and the score box (team names and scores). Horizontal rink (.sbscreen): period and both team logos with big scores. Called from USBoard, Pausemode, lcfound2 and others
	movem.l	d0-d2/a0-a3,-(sp)
	btst	#sfhor,(sflags).w
	bne.w	.sbscreen
	bsr.w	printz
	String	$BF,0,$17
	moveq	#9,d0
	moveq	#5,d1
	bsr.w	Framer
	bset	#dfclock,(disflags).w
	bsr.w	printz
	String	$BF,1,$18
	move.w	(gsp).w,d0		;period name (92 .pp)
	movea.l	#PerLabels,a1
	bsr.w	PrintStringFromList
	bsr.w	EASNLogo
	btst	#sf3llcs,(sflags3).w		;lower line change box is up
	bne.w	.ex
	bsr.w	printz
	String	$BF,$17,$17
	moveq	#8,d0
	moveq	#5,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,$18,$1A		;home team on the lower row
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	PrintTeamNameAndScore
	bsr.w	printz
	String	$BF,$18,$18
	adda.w	#tmsize,a2
	bsr.w	PrintTeamNameAndScore
.ex	movem.l	(sp)+,d0-d2/a0-a3
	rts
.sbscreen	bsr.w	printz
	String	$BE,$11,5
	move.w	(gsp).w,d0
	movea.l	#PerLabels,a1
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0			;center the period name on x $11
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
	bsr.w	printz
	String	$BE,$17,1
	movea.w	#(tmstruct-M68K_RAM),a2
	clr.w	d0			;home logo data offset
	bsr.w	PrintTeamLogoAndScore
	bsr.w	printz
	String	$BE,9,1
	adda.w	#tmsize,a2
	moveq	#$30,d0			;visitor logo data offset
	bsr.w	PrintTeamLogoAndScore
	bra.s	.ex

PrintTeamNameAndScore	;print the team name of team a2 at printx/printy, then its score as 2 digits at x $1C. Called twice from printscores1
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1			;skip the first string to the team name
	bsr.w	print
	move.w	#$1C,(printx).w
	move.w	tmscore(a2),d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print

PrintTeamLogoAndScore	;draw the team logo map (PutTeamBlock, d0 = offset) 6 columns left of printx, then the score of team a2 in big font, centered 2 rows lower. Called twice from printscores1.sbscreen
	move.w	(printx).w,-(sp)
	subq.w	#6,(printx).w
	jsr	(PutTeamBlock).w
	move.w	(sp)+,(printx).w
	addq.w	#2,(printy).w
	move.w	tmscore(a2),d0
	bsr.w	PushNumber
	move.w	(a1),d0			;center on the old printx
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bra.w	printbig

EASNLogo	;Draw easn.map at x 1, y $19 on the vertical ice rink if no power play. Falls into DrawEASNMap
	btst	#sf2pwrplay,(sflags2).w
	bne.w	rtss
	bsr.w	printz
	String	$BF,1,$19

DrawEASNMap	;Draw the EASN logo map at the current printx/printy. Also called from ShowScores
	movea.l	#EASNmap,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2			;width and height from the map header (92: 7, 2)
	move.w	2(a1),d3
	move.w	(EASNcset).w,d4
	clr.w	d5
	bra.w	dobitmap

USBoard	;update score board, including the players in the penalty box and their time remaining. Called from InProgress and SetHor
	movem.l	d0-d7/a0-a3,-(sp)
	bset	#dfclock,(disflags).w
	bsr.w	printscores1
	bsr.w	printz
	String	$BE,$14,8
	movea.w	#(tmstruct-M68K_RAM),a2	;in the string
	bsr.w	.dispen
	bsr.w	printz
	String	$BE,5,8
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize; in the string
	bsr.w	.dispen
	movem.l	(sp)+,d0-d7/a0-a3
	rts

.dispen	lea	$9A(a2),a0		;penalty box list of team a2. Prints the players with tmpdst bit 14 clear first, then those with it set
.l1	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.p2			;end of list
	btst	#6,tmpdst(a2,d0.w)		;tmpdst high byte bit 6
	bne.s	.l1
	bsr.w	pplpen
	bra.s	.l1
.p2	lea	$9A(a2),a0
.l2	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	rtss
	btst	#6,tmpdst(a2,d0.w)
	beq.s	.l2
	bsr.w	pplpen
	bra.s	.l2

pplpen	;?. Print one penalty box line: player number and time remaining. a2 = team, d0 = roster offset (player*2). Only rows up to y $A are printed; printy += 1. Called from USBoard.dispen
	cmpi.w	#$A,(printy).w
	bhi.w	rtss			;no room for more rows
	move.w	tmpdst(a2,d0.w),d2
	andi.w	#$7FF,d2		;penalty time
	movea.l	tmdata(a2),a1
	adda.w	(a1),a1
	lsr.w	#1,d0
.find	adda.w	(a1),a1			;skip d0+1 roster entries (name string + 8 bytes)
	addq.w	#8,a1
	dbf	d0,.find
	clr.w	d0
	move.b	-8(a1),d0		;player number (BCD)
	move.w	(printx).w,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	bsr.w	ConvertByteToDigits
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#4,(a1)			;string length: 2 digits
	bsr.w	print
	move.w	d2,d0
	bsr.w	PushTime
	bsr.w	print
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	rts

linebar	;draw the energy bar of line d0 for team a2 at printx/printy (bitmap from the bar map, 16 steps). Called from SetLCmode2
	movem.l	d0-d5/a0-a2,-(sp)
	bsr.w	getlinee
	move.w	(printa).w,-(sp)
	move.w	#$8000,(printa).w
	ext.l	d0
	divu.w	#$100,d0		;4096/16
	cmp.w	#$F,d0
	bls.w	.ok
	moveq	#$F,d0
.ok	moveq	#$F,d1			;in 92 this is a separate routine; here it is a branch target
	sub.w	d0,d1			;d1 = bar frame (15 = empty)
	clr.w	d0
	movea.l	#EnergyBarMap,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2
	move.w	(a1),d2
	moveq	#1,d3
	move.w	(energybarchars).w,d4
	moveq	#0,d5
	bsr.w	dobitmap
	move.w	(sp)+,(printa).w
	movem.l	(sp)+,d0-d5/a0-a2
	rts

getlinee	;d0 = line number, a2 = team struct. Return d0 = energy level of this line
	movem.l	d1-d5/a0-a3,-(sp)
	lea	$16A(a2),a1		;line sets
	asl.w	#3,d0
	adda.w	d0,a1
	clr.l	d0
	clr.w	d1
	movea.l	#priolist,a0
	move.w	tmap(a2),d4
	bra.w	.next
.loop	clr.w	d5
	move.b	(a0,d4.w),d5		;position
	beq.w	.next			;goalie energy doesn't count
	clr.w	d3
	move.b	(a1,d5.w),d3		;player number
	asl.w	#1,d3
	addq.w	#1,d1
	add.w	tmpde-2(a2,d3.w),d0
.next	dbf	d4,.loop
	divu.w	d1,d0
	movem.l	(sp)+,d1-d5/a0-a3
	rts

AvgCline	;return d0 = average energy of current line on team a2
	movem.l	d1-d3/a0,-(sp)
	clr.l	d0
	clr.w	d1
	moveq	#5,d2
	movea.w	tmsort(a2),a0
.l0	tst.w	position(a0)
	ble.w	.next
	clr.w	d3
	move.b	pnum(a0),d3
	add.w	d3,d3
	add.w	tmpde(a2,d3.w),d0
	addq.w	#1,d1
.next	adda.w	#SCstruct,a0
	dbf	d2,.l0
	tst.w	d1
	beq.w	.ex
	divu.w	d1,d0
.ex	movem.l	(sp)+,d1-d3/a0
	rts

ChkShotStat	;add to shot stat if a shot was taken. Also raises the crowd and counts the shot for the shooter and against the other team's goalie
	bclr	#sf2shot,(sflags2).w
	beq.w	rtss
	movem.l	d0-d1/a1-a3,-(sp)
	addi.w	#$64,(crowdlevel).w	;100
	addi.w	#$A,(CwdExciteLvl).w
	move.w	(shotplayer).w,d0
	asl.w	#scsize,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	bsr.w	loadTeamStruct
	addq.w	#1,(a2)			;tmshots
	clr.w	d0
	move.b	pnum(a3),d0
	addi.w	#$E8,d0
	addq.b	#1,(a2,d0.w)		;shooter's shot count
	move.w	tmgoalie(a1),d0		;other team's tmgoalie
	bmi.w	.ex			;empty net
	addi.w	#$E8,d0
	addq.b	#1,(a1,d0.w)		;goalie's shots against
.ex	movem.l	(sp)+,d0-d1/a1-a3
	rts

loadTeamStruct	;return a2 = team struct of player a3, a1 = the other team's struct. Called from ChkShotStat and updateplayers
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	btst	#pfteam,pflags(a3)
	beq.w	rtss
	exg	a1,a2
	rts

SetupTeamForIntermission	;reset the bench, then for each team refill energy and pick the starting line: power play line 1 (3) for the team with more players on ice, PK1 (5) for the team with fewer, else 0. Called from Intermission
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3
	bsr.w	.r
	exg	a2,a3			;falls in for the other team
.r	bsr.w	reenergizeteam		;refill energy for this team
	clr.w	tmline(a3)
	tst.w	(OptLine).w
	bne.w	rtss			;line changes off
	move.w	tmap(a3),d0
	sub.w	tmap(a2),d0
	beq.w	rtss
	move.w	#3,tmline(a3)		;Pw1
	tst.w	d0
	bpl.w	rtss
	move.w	#5,tmline(a3)		;PK1
	rts

reenergizeteam	;set all players to max energy on team a2. Also moves players marked -3 in tmpdst to the bench (-2). Called from SetupTeamForIntermission and StartHL2 .setteam
	moveq	#(maxros-1)*2,d0			;(MaxRos-1)*2
.0	move.w	#$1000,tmpde(a2,d0.w)
	cmpi.w	#-3,tmpdst(a2,d0.w)
	bne.w	.nb
	move.w	#-2,tmpdst(a2,d0.w)	;on bench
.nb	subq.w	#2,d0
	bpl.s	.0
	rts

Intermission	;end of period junk (zamboni/stats). Opens the pause menu screen (item list by period, +5 in playoffs), shows the ticker scores of the other games, then the highlights. Start on either pad cuts it short. Called from PeriodOver
	bsr.s	SetupTeamForIntermission
	moveq	#$F,d0
	movea.w	#(SortCords-M68K_RAM),a0
.0	clr.w	(a0)			;Xpos
	adda.w	#SCstruct,a0
	dbf	d0,.0
	move.w	(ExtraChars).w,d4
	movea.l	#ZamSprites+8,a2
	bsr.w	DecompressGraphicsPlain
	move.w	#$140,(zamx).w		;320
	move.w	(gsp).w,d0
	tst.w	(OptPlayMode).w
	beq.w	.ss
	addq.w	#5,d0			;playoffs
.ss	asl.w	#2,d0
	lea	.sslist(pc),a0
	movea.l	(a0,d0.w),a0
	bset	#sfpz,(sflags).w
	movea.l	#SetupPauseScreen,a1
	jsr	(InitMenuState).w
	bsr.w	GetShifter
	move.w	d1,(TickerNum).w
.top	tst.w	(TickerNum).w
	bmi.w	.doh			;no more ticker games
	bsr.w	NewTicker2
	bsr.w	NewTicker3
	move.w	#$96,d0			;150 frames
	bsr.w	waitxsr
	btst	#sbut,d1			;sbut
	bne.w	.clrh
	bsr.w	ClearTickerArea
	move.w	#$3C,d0			;60 frames
	bsr.w	waitxsr
	btst	#sbut,d1			;sbut
	beq.s	.top
.clrh	bset	#sf3sbut,(sflags3).w
.doh	bsr.w	DoHiLights
	bclr	#sf3sbut,(sflags3).w
	bne.w	.clrz
.wait	move.w	#$1E0,d0		;480 frames
	bsr.w	waitxsr
	btst	#sbut,d1			;sbut
	bne.w	.clrz
	tst.w	(cont1team).w
	bne.s	.wait			;keep waiting while a pad is on a team
	tst.w	(cont2team).w
	bne.s	.wait
.clrz	st	(zamx).w
	rts

.sslist	;Menu item lists, by period then playoff period
	dc.l	StartGameText,IntermissionText,IntermissionText,IntermissionText,ExitGameText
	dc.l	StartGameTextPO,IntermissionText,IntermissionText,IntermissionText,ExitGameTextPO

InitScores	;initialize other games scores/period in playoffs (no OptPlayMode check). Called from StartGame
	cmpi.w	#1,(gamelevel).w
	bgt.w	rtss
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d0			;gssize
	mulu.w	d1,d0
	adda.w	d0,a0
.top	cmp.w	(gamenum).w,d1
	beq.w	.next
	btst	#gsfso,gsflags(a0)		;gsfso
	bne.w	.next
	clr.w	gsper(a0)			;gsper
	moveq	#3,d0
	bsr.w	randomd0
	bra.w	.1
.0	bsr.w	SetScore
.1	dbf	d0,.0
.next	suba.w	#gssize,a0			;gssize
	dbf	d1,.top
	rts

UpdateScores	;update ticker score values. Called from PeriodOver
	bsr.w	GetShifter
	move.w	d1,(TickerNum).w
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d0			;gssize
	mulu.w	d1,d0
	adda.w	d0,a0
.top	cmp.w	(gamenum).w,d1
	beq.w	.next
	bclr	#gsfhl,gsflags(a0)		;gsfhl
	btst	#gsfso,gsflags(a0)		;gsfso
	bne.w	.next
	bsr.w	SetScore
.next	suba.w	#gssize,a0			;gssize
	dbf	d1,.top
	rts

SetScore	;add to score for game in a0. After period 3 a game within one goal goes to OT (gsper 3) and asks for a highlight
	cmpi.w	#4,gsper(a0)		;gsper
	bge.w	rtss
	movem.l	d0-d1/a0-a1,-(sp)
	cmpi.w	#3,8(a0)
	bne.w	.0
	move.w	#5,8(a0)		;final
	move.w	gss1(a0),d0		;gss1
	sub.w	gss2(a0),d0		;gss2
	cmp.w	#1,d0
	bgt.w	.ex
	cmp.w	#-1,d0
	blt.w	.ex
	move.w	#3,8(a0)		;close game: overtime
	bset	#gsfhl,gsflags(a0)		;gsfhl
	bra.w	.ex
.0	addq.w	#1,8(a0)
	move.w	(a0),d0			;gst1
	move.w	2(a0),d1		;gst2
	bsr.w	.getscore
	add.w	d0,gss1(a0)		;gss1
	move.w	2(a0),d0
	move.w	(a0),d1
	bsr.w	.getscore
	add.w	d0,gss2(a0)		;gss2
.ex	movem.l	(sp)+,d0-d1/a0-a1
	rts

.getscore	asl.w	#2,d0			;d0 = scoring team, d1 = other team. Adds the scoring team's (bits 4-6) and the other team's (bits 0-2) .sctab rows as weights. Return d0 = goals 0-3
	movea.w	#$314,a1		;team address table
	movea.l	(a1,d0.w),a1
	adda.w	8(a1),a1
	move.b	(a1),d0
	andi.w	#$70,d0
	lsr.w	#1,d0			;row * 8
	lea	.sctab(pc),a1
	move.l	(a1,d0.w),(nibblebuffer).w
	move.l	4(a1,d0.w),(nibblebuffer+4).w
	asl.w	#2,d1
	movea.w	#$314,a1
	movea.l	(a1,d1.w),a1
	adda.w	8(a1),a1
	move.b	(a1),d0
	andi.w	#7,d0
	asl.w	#3,d0
	lea	.sctab(pc),a1
	move.l	(a1,d0.w),d1
	add.l	d1,(nibblebuffer).w
	move.l	4(a1,d0.w),d1
	add.l	d1,(nibblebuffer+4).w
	moveq	#4,d0			;4 weights
	bra.w	WeightedRandomSelect

.sctab	;Weights for 0, 1, 2, 3 goals (92 had 4 percent bytes per row)
	dc.w	$2B,$1E,$17,4
	dc.w	$27,$20,$18,5
	dc.w	$23,$21,$1A,6
	dc.w	$1E,$22,$1E,6
	dc.w	$1A,$24,$1E,8
	dc.w	$16,$25,$1F,$A
	dc.w	$13,$26,$1F,$C
	dc.w	$F,$26,$20,$F

NewTicker	;show the next ticker score once the clock is at 8:00 or less. d3 = -1 if not. Called from chkprogress. Falls into NewTicker2
	moveq	#-1,d3
	cmpi.w	#$1E0,(gameclock).w	;480
	bgt.w	rtss

NewTicker2	;goto next ticker. Return d3 = game, or neg if none left (no OptPlayMode check). Falls into CheckGameTickerStatus
	move.w	(TickerNum).w,d3
	bmi.w	rtss
	subq.w	#1,(TickerNum).w
	cmp.w	(gamenum).w,d3		;don't show current game as ticker
	beq.s	NewTicker2

CheckGameTickerStatus	;d3 = game. Return a0 = its gstruct; skip to the next ticker game if a highlight is coming up or the series is over. Called from StartHL2
	moveq	#gssize,d0			;gssize
	mulu.w	d3,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	btst	#gsfhl,gsflags(a0)		;gsfhl
	bne.s	NewTicker2		;don't show if hilite coming up
	btst	#gsfso,gsflags(a0)		;gsfso
	bne.s	NewTicker2		;don't show if the series is over for this game
	rts

NewTicker3	;display ticker score for game d3 (a0 = gstruct entry), skip if d3 is negative. Called from chkprogress, Intermission and StartHL2
	tst.w	d3
	bmi.w	rtss
	bsr.w	SetTickerAreaPosition
	bsr.w	Framer
	addq.w	#1,(printx).w
	subq.w	#4,(printy).w
	move.w	(printx).w,-(sp)
	bsr.w	GetShifter
	move.w	#$A000,(printa).w
	bsr.w	printz
	String	'                        '	;24 spaces (92 26)
	move.w	(sp),(printx).w
	moveq	#1,d0
	add.w	(gamelevel).w,d0
	tst.w	(OptPlayMode).w
	bne.w	.gl
	clr.w	d0			;not playoffs: 'EASN Hockey Night'
.gl	lea	GameLabels(pc),a1
	bsr.w	PrintStringFromList
	move.w	gsper(a0),d0		;gsper
	subq.w	#1,d0
	movea.l	#PerLabels,a1
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0			;period name centered on x+$17
	lsr.w	#1,d0
	neg.w	d0
	add.w	(sp),d0
	addi.w	#$17,d0
	move.w	d0,(printx).w
	bsr.w	print
	move.w	#$8000,(printa).w
	move.w	2(a0),d0		;gst2
	move.w	gss2(a0),d1		;gss2
	bsr.w	.tn
	move.w	(a0),d0			;gst1
	move.w	gss1(a0),d1		;gss1
	bsr.w	.tn
	addq.w	#2,sp
	rts

.tn	move.w	4(sp),(printx).w	;print team d0 name and score d1 on the next row
	addq.w	#1,(printy).w
	movea.w	#$314,a1		;team address table
	asl.w	#2,d0
	movea.l	(a1,d0.w),a1
	adda.w	4(a1),a1		;TeamName
	bsr.w	print
	move.w	4(sp),(printx).w
	addi.w	#$15,(printx).w		;92 23
	move.w	d1,d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print

GameLabels	;ticker titles, by OptPlayMode and gamelevel
	String	'EASN Hockey Night'
	String	'EA Cup Qualifier'
	String	'EA Quarterfinal'
	String	'EA Cup Semifinal'

ClearTickerArea	;erase the ticker box. Called from Intermission and StartHL2
	bsr.w	SetTickerAreaPosition
	move.w	#$7FF,d2		;blank char
	bra.w	eraser

SetTickerAreaPosition	;set printx/printy/printm for the ticker box (x 3, y $17; the $BD map in pause mode). Return d0 = $1A wide, d1 = 5 high. Called from NewTicker3 and ClearTickerArea
	bsr.w	printz
	String	$BD,3,$17
	btst	#sfpz,(sflags).w
	bne.w	.1
	bsr.w	printz
	String	$BF,3,$17
.1	moveq	#$1A,d0
	moveq	#5,d1
	rts

PrintStringFromList	;print string d0 of the String list a1 with printsmall
	bsr.w	AdvanceStringPtr
	bra.w	printsmall

AdvanceStringPtr	;like 92's string-list print, without the print. Return a1 = string d0 of the String list a1
	bra.w	.1
.0	adda.w	(a1),a1
.1	dbf	d0,.0
	rts
