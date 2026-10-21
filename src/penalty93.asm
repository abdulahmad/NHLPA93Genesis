;	Penalty logic. Calls penalties and the other stoppages of play (whistle, icing, offsides, goals), sends
;	players to the penalty box, runs power plays, shows the referee's messages and switches the rink between
;	its horizontal and vertical views.
;
;	After the penalty code come the scoreboard, ticker and intermission routines (printscores1 onward) and,
;	at the very end of the file, the intermission highlights (DoHiLights, StartHL, StartHL2).

AddPenalty							;add penalty d0 (PenaltyList offset) for player a3. Ignored while the
									;clock is stopped, when penalties are off, or offsides when offsides are
									;off. Falls into AddPenalty2
	btst	#gmclock,(gmode).w
	bne.w	rtss					;clock stopped: ignore
	cmp.w	#$C,d0					;icing (92 used 8)
	beq.w	AddPenalty2				;icing is always called
	tst.w	(OptPen).w
	beq.w	rtss					;penalties off
	btst	#gmoffs,(gmode).w
	bne.w	AddPenalty2
	cmp.w	#$10,d0					;offsides (92 used $A)
	beq.w	rtss					;offsides off: ignore

AddPenalty2							;forced penalties like face off and game over. d0 = penalty number, a3 =
									;player or player on penalized team. Penalty numbers from $E (goal) up
									;raise the crowd and play a song
	btst	#sfhor,(sflags).w
	bne.w	rtss					;horizontal (penalty box) mode: no new penalties
	movem.l	d1/a0-a1,-(sp)
	cmp.w	#$E,d0					;goal (92 used 6) and up
	blt.w	.nosnd					;lesser stoppages: no crowd noise or song
	addi.w	#$C8,(Crowdlevel).w		;200
	move.w	#$C,-(sp)				;song $C for the home team
	btst	#pfteam,pflags(a3)		;which team's player
	beq.w	.snd
	addi.w	#$14,(CwdExciteLvl).w	;visitors: +20 excitement
	move.w	#$B,(sp)				;song $B
.snd	bsr.w	song				;play it (song pops its argument)
.nosnd	movea.w	#(PenBuf-M68K_RAM),a1	;a1 = PenBuf: 2 bytes per entry (penalty, player)
	moveq	#$1F,d1					;MaxPen-1
.0	tst.w	(a1)+					;find free slot
	dbeq	d1,.0
	bne.w	.noplayer				;buffer full
	move.b	SCnum+1(a3),-(a1)		;store the player's sort number (second byte of the entry)
	move.b	d0,-(a1)				;and the penalty number (first byte)
	movea.l	#Penaltylist,a0
	adda.w	(a0,d0.w),a0			;a0 = this penalty's record
	tst.b	1(a0)					;penalty minutes
	beq.w	.noplayer				;no minutes: no penalty box time, keep the entry mark the player as
									;penalized; if the flag was already set he already has one
	bset	#pf2pen,pflags2(a3)		;92 used bit 6
	beq.w	.noplayer
	clr.w	(a1)					;player already has a penalty, drop this one
.noplayer	movem.l	(sp)+,d1/a0-a1	;buffer full or done: restore and return
	rts

PenaltyManager						;called periodically. d7 = elapsed time since last call
	bsr.w	updatepentime			;count down the penalty clocks (once a second)
	bsr.w	checkfornewpen			;call any newly queued penalty
	bsr.w	chkprogress				;step the stoppage / ref / penalty box sequence
	bra.w	UpdatePA				;animate the ref and return

chkprogress							;control progress of ref and game control thru penalty events. When the
									;stop delay runs out and a penalty with minutes is in PenBuf, switch to
									;the horizontal rink for the player to enter the penalty box
	btst	#gmpen,(gmode).w
	beq.w	rtss					;no penalty stoppage in progress
	tst.w	(PenCntDwn).w
	bmi.w	InProgress				;countdown finished earlier: run the ref sequence
	sub.w	d7,(PenCntDwn).w
	bpl.w	rtss					;still waiting out the stop delay
	bclr	#gmpendel,(gmode).w		;delayed call (if any) is over
	movea.w	#(PenBuf-M68K_RAM),a0
.find	tst.w	(a0)+				;look for any penalty with minutes (next PenBuf entry; 0 = end)
	beq.w	rtss					;end of list: no penalty with minutes, stay in the vertical view
	clr.w	d0
	move.b	-2(a0),d0				;d0 = penalty number
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	tst.b	1(a1)					;penalty minutes
	beq.s	.find
	;a penalty with minutes: show the horizontal view so the player can enter the penalty box
	bset	#sf2drec,(sflags2).w	;switch to horizontal mode for player to enter penalty box
	move.w	(Vcount).w,-(sp)		;keep Vcount across the fade to black
	bsr.w	forceblack
	move.w	(sp)+,(Vcount).w
	bsr.w	SetHor					;horizontal rink graphics
	move.w	(ExtraChars).w,d4		;load horizontal ref tiles
	movea.l	#RefMap2+8,a2
	bsr.w	DecompressGraphicsPlain
	bsr.w	NewTicker				;ticker score of another game, if the clock allows
	bsr.w	NewTicker3
	st	(puckc).w					;puck carrier = none
	movea.w	#(puckx-M68K_RAM),a3	;a3 = puck object
	move.l	#pnothing,d0			;pnothing
	bsr.w	assinsert				;puck does nothing during the sequence
	move.w	#$1C20,temp1(a3)		;temp1 = 120*60

	st	(RefStep).w					;ref idle until the first frame is pushed
	clr.w	(RefCnt).w
	bsr.w	UpdatePA
	move.w	#$32,(RefCnt).w			;50
	clr.w	d0
	bsr.w	PushRef					;ref frame 0
	move.w	#$18,(palcount).w		;24, fade in
	rts

InProgress							;ref in progress-- update graphics and stats and penalty information.
									;Takes the last PenBuf entry: the first pass logs a penalty with minutes
									;and sends the player to the box, later passes wait until he is off the
									;ice and drop the entry. When PenBuf is empty, recount players and go to
									;the face off. Entered from chkprogress
	tst.w	(RefCnt).w
	bpl.w	rtss					;animation in progress
	tst.w	(RefStep).w
	bpl.w	rtss					;ref not idle yet
	movem.l	d0/a0-a3,-(sp)
.top	movea.w	#(PenBuf-M68K_RAM),a0	;process the last PenBuf entry
	tst.w	(a0)+
	beq.w	.exit					;list empty: all done
.0	tst.w	(a0)+					;find end of list
	bne.s	.0
	subq.w	#4,a0					;a0 = last entry (penalty byte, player byte)
	bclr	#7,1(a0)				;bit 7 of the player byte = called but not yet
									;logged (set in checkfornewpen)
	bne.w	.Sa						;first pass: log it
	;later pass: wait until the penalized player has left the ice (position negative), then drop the entry
	move.l	a3,-(sp)
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#scsize,d1				;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3					;a3 = the player
	tst.w	position(a3)
	movea.l	(sp)+,a3
	bpl.w	.ex						;still on the ice
	clr.w	(a0)					;gone: remove the entry
	bra.w	.ex

.Sa	clr.w	d0						;first pass: d0 = penalty number
	move.b	(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	clr.w	d2
	move.b	1(a1),d2				;penalty minutes
	beq.w	.sa2					;no player involved
	movem.l	d0-d1/a1-a4,-(sp)
	bsr.w	GetPeriodTimeRemaining	;log time, penalty and player
	;PenSum entry (4 bytes): time word, penalty byte, player byte (bit 7 = visitors)
	movea.w	#(PenSum-M68K_RAM),a4
	adda.w	(PenSumLength).w,a4
	cmpi.w	#$EC,(PenSumLength).w	;log full: keep overwriting the last entry
	beq.w	.full
	addq.w	#4,(PenSumLength).w
.full	move.w	d0,(a4)+			;time
	move.b	(a0),(a4)+				;penalty
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#scsize,d1				;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3					;a3 = the guilty player
	clr.w	d0						;d0 = player id (bit 15 = visitors)
	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = his team, a1 = the other team
	lea	tmsize(a2),a1
	btst	#pfteam,pflags(a3)
	beq.w	.sa1
	bset	#7,-1(a4)				;log: visitors
	move.w	#$8000,d0
	exg	a1,a2
.sa1	addq.w	#1,tmPenalties(a2)	;team penalty count
	add.w	d2,tmPenmin(a2)			;team penalty minutes
	move.b	pnum(a3),d0
	move.b	d0,(a4)					;log: player
	move.w	d0,(TempPlOffset).w
	ext.w	d0
	addi.w	#$102,d0				;per-player penalty minutes byte at $102+pnum
	add.b	d2,(a2,d0.w)
	subi.w	#$102,d0
	asl.w	#1,d0					;d0 = roster offset (player*2) for tmpdst
	ext.w	d2
	mulu.w	#$3C,d2					;60: minutes -> seconds
	bset	#$D,d2					;bit 13 = just called (cleared again by coinsearch)
	tst.w	tmpdst(a2,d0.w)
	bmi.w	.st						;on the ice/bench: plain value
	btst	#4,tmpdst(a2,d0.w)
	beq.w	.st
	bset	#$C,d2					;keep bit 4 of an old penalty time as bit 12
.st	move.w	d2,tmpdst(a2,d0.w)		;store the penalty time (seconds) for this player
	andi.w	#$EFFF,d2				;drop bit 12 for the comparison below
	moveq	#(maxros-1)*2+2,d1		;(MaxRos-1)*2+2
.ctop	subq.w	#2,d1				;same time on the other team
	bmi.w	.nocoin
	move.w	tmpdst(a1,d1.w),d3
	andi.w	#$EFFF,d3
	cmp.w	d3,d2
	bne.s	.ctop
	bset	#6,tmpdst(a1,d1.w)		;coincidental (both players)
	bset	#6,tmpdst(a2,d0.w)
.nocoin	movem.l	a0,-(sp)			;add player to penalty box list
	lea	tmboxlist(a2),a0
	moveq	#$18,d1
.pl	tst.b	(a0)+					;find end of list
	dbmi	d1,.pl
	move.b	d0,-1(a0)				;append the roster offset
	st	(a0)						;and a new -1 terminator
	movem.l	(sp)+,a0

	move.w	#apenalty,d0			;apenalty
	bsr.w	assreplace				;a3 = the player: send him to the penalty box
	movem.l	(sp)+,d0-d1/a1-a4
	bsr.w	SetPA					;ref animation and message for this penalty
	bsr.w	USBoard					;update the penalty box lines on the score board
	bra.w	.ex
.sa2	clr.w	(a0)				;no player involved: drop the entry
	btst	#sfhor,(sflags).w
	bne.w	.top					;horizontal mode: go on with the next entry
	bsr.w	SetPA
	bra.w	.ex

.exit	movea.w	#(tmstruct-M68K_RAM),a2	;PenBuf empty: recount the players on ice for both teams
	bsr.w	coinsearch
	adda.w	#tmsize,a2
	bsr.w	coinsearch
	
	bclr	#gmpen,(gmode).w		;penalty stoppage is over
	movea.w	#(puckx-M68K_RAM),a3	;a3 = puck object
	move.w	#pfaceoff,d0			;pfaceoff
	bsr.w	assreplace				;go to the face off
.ex	movem.l	(sp)+,d0/a0-a3			;restore and return
	rts

coinsearch							;a2 = team. Clears tmpdst bit 5, counts players kept off the ice by
									;penalties (coincidental and bit 4 times do not count, at most 2) and sets
									;tmap. Called twice from InProgress
	moveq	#6,d1					;d1 = players on ice, starts at 6
	moveq	#(maxros-1)*2,d0		;(MaxRos-1)*2
.top	tst.w	tmpdst(a2,d0.w)		;loop over the roster (d0 = player*2, counting down)
	ble.w	.nap					;not in the penalty box
	bclr	#5,tmpdst(a2,d0.w)		;clear the "just called" bit
	btst	#6,tmpdst(a2,d0.w)		;coincidental
	bne.w	.nap
	btst	#4,tmpdst(a2,d0.w)
	bne.w	.nap
	cmp.w	#4,d1					;never below 4 players
	beq.w	.nap
	subq.w	#1,d1					;this player keeps the team one man short
.nap	subq.w	#2,d0				;next player
	bpl.s	.top
	move.w	d1,tmap(a2)				;players on ice
	rts

checkfornewpen						;look for new penalty (entered thru addpenalty(2)). Stops play at once for
									;penalties without minutes or when the guilty player's team has the puck,
									;otherwise (other team or loose puck) starts a delayed penalty call
	btst	#sfhor,(sflags).w
	bne.w	rtss					;horizontal mode: nothing to call
	movea.w	#(PenBuf-M68K_RAM),a0
.next	tst.w	(a0)+				;next PenBuf entry (0 = end)
	beq.w	rtss
	btst	#gmpen,(gmode).w
	bne.w	.iscalled				;stoppage already running: just mark it called
	clr.w	d0
	move.b	-2(a0),d0				;d0 = penalty number
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	tst.b	1(a1)					;time for penalty
	beq.w	.callit					;no minutes (whistle, goal, icing ...): stop play now penalty with
									;minutes: puckc and the player number are both compared as (number - 6),
									;so the sign tells the team; different teams (or a loose puck) = delayed
									;call, play goes on
	move.w	(puckc).w,d0
	bmi.w	.dc						;loose puck
	subq.w	#6,d0
	move.b	-1(a0),d1				;player penalized
	ext.w	d1
	subq.w	#6,d1
	eor.w	d1,d0
	bmi.w	.dc						;delayed penalty call

.callit	bsr.w	Stop4Pen			;stop the clock and blow the whistle

.iscalled	bset	#7,-1(a0)		;mark the entry as called (InProgress logs it)
	bne.s	.next					;was already marked: next entry
	clr.w	d0
	move.b	-2(a0),d0				;penalty called
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	clr.w	d1
	move.b	(a1),d1					;delay for stopping action
	asl.w	#5,d1					;delay * 32 frames
	cmp.w	(PenCntDwn).w,d1
	ble.s	.next
	move.w	d1,(PenCntDwn).w		;keep the longest delay of the called penalties
	bra.s	.next

.dc	bset	#gmpendel,(gmode).w		;delayed penalty: remember it
	bne.s	.next					;already signalled
	move.w	#$2C,d0					;delayed penalty (92 used $24)
	bsr.w	SetPA
	bra.s	.next

Stop4Pen							;a0 = penaltylist penalty +2. Stop the clock, set the face off spot from
									;the penalty type, blow the whistle. Also entered from puckfaceoff+38
	bset	#gmclock,(gmode).w		;stop the clock
	bne.w	.skipfo					;already stopped: keep the face off spot
	;d0/d1 = face off spot x/y (puck coordinates): center ice for a goal, last touch for 6 (OOP),
	;the puck for other stoppages, and for icing the puck x with y = +-600 (clamped below)
	clr.w	d0
	clr.w	d1
	cmpi.b	#$E,-2(a0)				;goal (92 used 6): center ice
	beq.w	.noticing
	move.w	(ltx).w,d0
	move.w	(lty).w,d1
	cmpi.b	#6,-2(a0)				;OOP (92 used $C)
	beq.w	.noticing
	move.w	(puckx).w,d0
	move.w	(pucky).w,d1
	cmpi.b	#$C,-2(a0)				;icing (92 used 8)
	bne.w	.noticing
	move.l	a3,-(sp)				;icing: the sign of y depends on the pfgoal flag of the icing player
	movea.w	#(SortCords-M68K_RAM),a3
	move.b	-1(a0),d1
	ext.w	d1
	asl.w	#scsize,d1				;scsize
	adda.w	d1,a3					;a3 = the icing player
	move.w	#$258,d1				;600
	btst	#pfgoal,pflags(a3)		;which end he shoots at
	movea.l	(sp)+,a3
	beq.w	.noticing
	neg.w	d1
	;clamp the spot to the face off dots: |x| <= 70; if y is within 40 of the end line
	;(beyond +-166) use the end zone dot at y +-206 and x +-70
.noticing	movem.w	d0-d1,-(sp)		;keep the unclamped x/y (x sign is tested below)
	cmp.w	#$46,d0					;.xspot = 70
	blt.w	.0
	move.w	#$46,d0
.0	cmp.w	#$FFBA,d0				;-.xspot
	bgt.w	.1
	move.w	#$FFBA,d0
.1	cmp.w	#$A6,d1					;yspot-.ygive = 206-40
	blt.w	.2
	move.w	#$CE,d1					;.yspot = 206
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.2
	neg.w	d0
.2	cmp.w	#$FF5A,d1				;-.yspot+.ygive
	bgt.w	.3
	move.w	#$FF32,d1				;-.yspot
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.3
	neg.w	d0
.3	move.w	d0,(fox).w				;store the face off spot
	move.w	d1,(foy).w
	addq.w	#4,sp
	bsr.w	limitfo					;pull it away from walls near any penalized player's end

.skipfo	clr.w	(PenCntDwn).w		;start the stop delay count from 0
	bset	#gmpen,(gmode).w		;penalty stoppage
	move.w	#SFXwhistle,-(sp)		;whistle (92 used 10)
	bsr.w	sfx
	move.w	#$A,d0					;whistle (92 used $26)
	bra.w	SetPA

limitfo								;limit face off to 5-20 feet from walls of rink.
									;Checks every player in PenBuf
	movem.l	d0-d1/a0-a1,-(sp)
	movea.w	#(PenBuf-M68K_RAM),a0
.loop	bsr.w	.lf					;adjust for this entry's player
	addq.w	#2,a0					;next entry
	tst.w	(a0)
	bne.s	.loop
	movem.l	(sp)+,d0-d1/a0-a1
	rts

.lf	move.b	1(a0),d0				;player of this entry (bit 7 = called flag masked off)
	andi.w	#$7F,d0
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a1
	move.w	#$58,d1					;limit +-88 on foy, by the player's pfgoal side
	btst	#pfgoal,pflags(a1,d0.w)
	bne.w	.0
	neg.w	d1
	cmp.w	(foy).w,d1
	blt.w	rtss					;foy inside the limit: leave it
	move.w	#$FFBF,(foy).w			;-.nuy = -65
	bra.w	.sx
.0	cmp.w	(foy).w,d1				;pfgoal set: positive side
	bgt.w	rtss
	move.w	#$41,(foy).w			;(xref is string bytes).nuy = 65
.sx	move.w	#$46,d0					;nux = 70
	tst.w	(fox).w
	bpl.w	.1
	neg.w	d0						;keep the sign of fox
.1	move.w	d0,(fox).w				;x = +-70
	rts

UpdatePA							;animate ref in ref window. Also runs ShowThreeStars for game over and
									;reprints the horizontal penalty message line when penmsgtimer runs out
	tst.w	(RefCnt).w
	bmi.w	rtss					;ref animation idle
	sub.w	d7,(RefCnt).w
	bpl.w	.0						;frame delay not over
	bsr.w	SetPA2					;next frame
.0	cmpi.w	#4,(RefPen).l			;game over (92 used 4)
	bne.w	.1
	bsr.w	ShowThreeStars
.1	sub.w	d7,(penmsgtimer).w		;message line timer
	bpl.w	rtss
	move.w	#$7FFF,(penmsgtimer).w	;timer ran out (horizontal mode): reprint the line again
	bsr.w	ClearPenaltyMessage		;with the penalized player's name (TempPlOffset) at x $11, row $B
	bsr.w	printz
	String	$BF,$11,$B
	bsr.w	GetPlayerName
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w			;center it
	bra.w	print

SetPA								;start ref animation. d0 = animation (penalty number). goal also calls
									;ShowGoalBox, and penmsgtimer is set to 60 in horizontal mode. Falls into
									;SetPA2
	move.w	d0,(RefPen).w			;penalty number the ref is calling
	clr.w	(RefStep).w				;start the animation list from the beginning
	bsr.w	prefmes					;print its message
	cmp.w	#$E,d0					;goal (92 used 6)
	bne.w	.0
	bsr.w	ShowGoalBox
.0	move.w	#$7FFF,(penmsgtimer).w	;vertical mode: never reprint
	btst	#sfhor,(sflags).w
	beq.w	SetPA2
	move.w	#$3C,(penmsgtimer).w	;60

SetPA2								;update animation for ref. Next frame/delay pair from the PenaltyList
									;animation of RefPen. Also called from UpdatePA
	movem.l	d0-d2/a0-a1,-(sp)
	moveq	#$40,d0					;clear ref window
	tst.w	(RefStep).w
	bmi.w	.pr						;idle: clear the window
	move.w	(RefStep).w,d0			;d0 = offset into the animation list
	addq.w	#2,(RefStep).w
	move.w	(RefPen).w,d1
	movea.l	#Penaltylist,a0
	adda.w	(a0,d1.w),a0			;a0 = penalty record
	addq.w	#2,a0					;+2 = message string (its length word)
	adda.w	(a0),a0					;skip the string: the animation list follows
	move.w	(a0,d0.w),d0			;list word: frame number << 8 | delay
	bpl.w	.0
	neg.w	d0						;negative = last frame
	st	(RefStep).w					;ref idle after this frame
.0	clr.w	d1						;low byte = delay
	move.b	d0,d1					;delay
	asl.w	#3,d1					;delay * 8 = frames to show this ref frame
	move.w	d1,(RefCnt).w
	lsr.w	#8,d0					;d0 = ref frame
.pr	bsr.w	PushRef					;show the frame (d0 = $40 clears the window)
	movem.l	(sp)+,d0-d2/a0-a1
	rts

PushRef								;tell vblank what to display. d0 = ref frame, $40 clears the window. The
									;horizontal ref uses RefMap2
	movem.l	d0-d2/a0-a1,-(sp)
	cmp.w	#$40,d0
	beq.w	.clearit
	mulu.w	#$70,d0					;refwidth*refheight*2
	movea.l	#RefsMap,a0				;vertical ref map
	btst	#sfhor,(sflags).w
	beq.w	.m1
	movea.l	#RefMap2,a0				;horizontal ref map
.m1	adda.l	4(a0),a0				;skip to the map data (offset in the header)
	addq.w	#4,a0
	adda.w	d0,a0					;+ frame offset
	movea.w	#(RefRamMap-M68K_RAM),a1	;a1 = ram copy of the ref map that vblank sends to vram
	move.w	(ExtraChars).w,d2		;d2 = start char of the ref tiles
	btst	#sfhor,(sflags).w
	bne.w	.4
	ori.w	#$8000,d2				;priority
.4	moveq	#$37,d0					;(refheight*refwidth)-1
.1	move.w	(a0)+,(a1)				;map word + start char/attributes
	add.w	d2,(a1)+
	dbf	d0,.1
	bset	#sf2refref,(sflags2).w	;ref needs refresh
	bra.w	.ex

.clearit	btst	#sfhor,(sflags).w	;horizontal mode only clears the line
	bne.w	.cl
	movea.w	#(RefRamMap-M68K_RAM),a1
	moveq	#$37,d0					;(refheight*refwidth)-1
.2	move.w	#$7FF,(a1)+				;blank tile (92 1)
	dbf	d0,.2
	bset	#sf2refref,(sflags2).w
.cl	moveq	#-1,d0					;clear line
	bsr.w	prefmes					;negative = clear the message

.ex	movem.l	(sp)+,d0-d2/a0-a1		;restore and return
	rts

prefmes								;print message for penalty d0 (negative clears it). Vertical mode: framed
									;under the ref. Horizontal mode: one centered line on row $B
	movem.l	d0-d2/a1,-(sp)
	btst	#sfhor,(sflags).w
	bne.w	.hor
	tst.w	d0
	bpl.w	.noblank
	bsr.w	printz					;negative d0: erase the 13x3 message area at x 0, y $A
	String	$BF,0,$A
	moveq	#$D,d0
	moveq	#3,d1
	move.w	#$7FF,d2				;blank tile (92 1)
	bsr.w	eraser
	bra.w	.ex

.noblank	bsr.w	printz			;print the framed message for penalty d0
	String	$BF,5,$A				;x 5 (92 6)
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1					;a1 = message string (length word first)
	move.w	(a1),d0
	subq.w	#2,d0					;empty string (92 cmp #4 / bls)
	beq.w	.ex
	lsr.w	#1,d0
	sub.w	d0,(printx).w			;center: back up by half the text length
	bpl.w	.nb0
	clr.w	(printx).w
.nb0	move.w	(a1),d0				;d0 = frame width from the string length
	tst.b	-1(a1,d0.w)
	bne.w	.nb1
	subq.w	#1,d0					;one less when the last string byte is 0 (padding)
.nb1	moveq	#3,d1				;frame height 3
	bsr.w	Framer
	subq.w	#2,(printy).w			;back inside the frame
	addq.w	#1,(printx).w
	bsr.w	print
	bra.w	.ex

.hor	bsr.w	ClearPenaltyMessage	;clears the line first
	tst.w	d0
	bmi.w	.ex
	bsr.w	printz					;print the message centered on x $11, row $B
	String	$BF,$11,$B
	movea.l	#Penaltylist,a1
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
.ex	movem.l	(sp)+,d0-d2/a1			;restore and return
	rts

ClearPenaltyMessage					;blank the horizontal mode penalty message line (22 spaces at x 5, y $B).
									;Called from UpdatePA and prefmes
	bsr.w	printz
	String	$BF,5,$B,'                      ',0
	rts

PenGoalStuff						;do this stuff after a goal. a1 = scored on team, a2 = scoring team. If
									;the scoring team had more players on ice, the first scored on player in
									;the box without a coincidental penalty is released
	movem.l	d0-d2/a0,-(sp)
	bsr.w	ClearPenaltyBuffer		;a goal drops any queued penalties

	move.w	tmap(a2),d2				;end p.killing by scored on team
	cmp.w	tmap(a1),d2
	ble.w	.ex						;scoring team did not have more players on the ice
	lea	tmboxlist(a1),a0			;penalty box list of the scored on team
.0	clr.w	d2						;next box list entry
	move.b	(a0)+,d2				;d2 = roster offset of the next player in the box
	bmi.w	.ex						;end of list
	btst	#6,tmpdst(a1,d2.w)		;coincidental
	bne.s	.0						;skip those
	clr.w	tmpdst(a1,d2.w)			;release this player
	bsr.w	RemovePlayerFromList
	addq.w	#1,tmap(a1)				;one more player on ice
	addq.w	#1,tmPwrGoals(a2)		;power play goal stat for the scoring team
	bset	#tmflcc,(tmstruct+tmflags).w	;tmflcc
	bset	#tmflcc,(awtmstruct+tmflags).w	;tmflcc
.ex	movem.l	(sp)+,d0-d2/a0			;restore and return
	rts

ClearPenaltyBuffer					;clear PenBuf (92 inlined this in PenGoalStuff).
									;Also called from clockcont
	moveq	#$1F,d0					;MaxPen-1
	movea.w	#(PenBuf-M68K_RAM),a0
.0	clr.w	(a0)+					;clear every entry
	dbf	d0,.0
	rts

updatepentime						;update the time remaining on all penalized players, once a second. Sets
									;sflags3 bit 6 on that tick. Falls into ProcessPenaltyList for team 2
	bclr	#sf3icetime,(sflags3).w	;clear last second's tick flag
	btst	#gmclock,(gmode).w
	bne.w	rtss					;clock stopped: no time passes
	sub.w	d7,(Penaltytimer).w
	bpl.w	rtss					;second not over
	addi.w	#jps,(Penaltytimer).w	;jps
	bset	#sf3icetime,(sflags3).w	;tick for this second
	bsr.w	chkatop					;attack time stat
	movea.w	#(tmstruct-M68K_RAM),a2	;team 1, then fall through for team 2
	bsr.w	ProcessPenaltyList
	adda.w	#tmsize,a2

ProcessPenaltyList					;from 92 updatepentime .ut. a2 = team. Walks the penalty box list ($9A):
									;the first two players without a coincidental penalty count down one
									;second and the rest wait. Beeps when the first served time gets to 5 or
									;less and releases the player at 0. Coincidental penalties count down on
									;their own
	lea	tmboxlist(a2),a0			;a0 = box list (roster offsets, -1 ends)
	movea.w	#(mesarea-M68K_RAM),a1	;serving players
	moveq	#2,d1					;two can serve at once
	moveq	#2,d3
.next	clr.w	d0					;next list entry
	move.b	(a0)+,d0
	bmi.w	.done					;end of list
	btst	#6,tmpdst(a2,d0.w)		;coincidental
	bne.w	.coinpen
	subq.w	#1,d1
	bmi.s	.next					;third or later player waits
	move.w	d0,(a1)+				;remember the serving player
	subq.w	#1,tmpdst(a2,d0.w)		;one second off
	bne.w	.cont
	bsr.w	RemovePlayerFromList	;time is up
.cont	bra.s	.next				;continue with the list

.done	move.w	(mesarea).w,d0		;first serving player
	cmp.w	#1,d1					;one serving
	beq.w	.chk
	tst.w	d1
	bne.w	.n1
	bsr.w	.chk					;two serving: check the first, then the second
	bra.w	.two
.n1	cmp.w	#$FFFF,d1				;exactly three in the list: check the second only
	bne.w	rtss
.two	move.w	(TextBuffer).w,d0	;second serving player (mesarea+2)

.chk	cmpi.w	#5,tmpdst(a2,d0.w)	;d0 = serving player; 5 seconds or less left?
	bgt.w	rtss
	move.w	#SFXbeep1,-(sp)			;SFXbeep1
	tst.w	tmpdst(a2,d0.w)
	bne.w	.snd
	bsr.w	releasepl				;time is 0: let him out
	move.w	#SFXbeep2,(sp)			;SFXbeep2
.snd	bsr.w	sfx					;countdown beep (beep2 on release)
	rts

.coinpen	subq.w	#1,tmpdst(a2,d0.w)	;coincidental penalties count down on their own
	btst	#3,tmpdst(a2,d0.w)		;high byte bit 3 (word bit 11), probably set when the count has run out
	beq.s	.next
	btst	#4,tmpdst(a2,d0.w)		;high byte bit 4 (word bit 12)
	bne.w	.clr
	move.w	#$1000,tmpdst(a2,d0.w)	;bit 12 clear: leave just bit 12 set
	bra.w	RemovePlayerFromList
.clr	clr.w	tmpdst(a2,d0.w)		;falls into RemovePlayerFromList

RemovePlayerFromList				;remove the entry before a0 from a penalty box list by shifting the rest
									;down (list ends with a negative byte). Return a0 = removed slot. Called
									;from PenGoalStuff, ProcessPenaltyList
	moveq	#-1,d2
.shift	addq.w	#1,d2				;next byte
	move.b	(a0,d2.w),-1(a0,d2.w)	;move each following byte down one, including the -1 terminator
	bpl.s	.shift
	subq.w	#1,a0					;a0 = the slot that was removed
	rts

chkatop								;attack time of possession stat update. Called once a second from
									;updatepentime
	moveq	#0,d1					;d1 = struct offset of the team credited
	move.w	(pucky).w,d0
	cmp.w	#$58,d0
	bgt.w	.1						;puck beyond y +$58: team 1 (d1 = 0)
	move.l	#tmsize,d1				;otherwise team 2 if beyond y -$58
	neg.w	d0
	cmp.w	#$58,d0
	blt.w	rtss					;between: nobody
.1	btst	#gmdir,(gmode).w		;direction decides which team is credited
	beq.w	.0
	eori.w	#tmsize,d1				;gmdir set: swap the teams
.0	movea.w	#(tmstruct-M68K_RAM),a2	;a2 = team 1; d1 = offset of the credited team
	addq.w	#1,tmATOP(a2,d1.w)		;attack time
	rts

releasepl							;player's penalty time is up so let him out (if appropriate). a2 = team,
									;d0 = player*2. Called from ProcessPenaltyList
	movem.l	d0-d3/a0-a3,-(sp)
	movea.w	tmsort(a2),a3			;walk the team's sort objects
	suba.w	#SCstruct,a3
.0	adda.w	#SCstruct,a3			;first sort obj not on the ice
	tst.w	position(a3)
	bpl.s	.0						;position >= 0 = on the ice

	move.w	d0,d3
	lsr.w	#1,d3					;d3 = player number
	move.w	tmap(a2),d1				;d1 = players on ice = index of the next position to fill
	addq.w	#1,tmap(a2)				;one more on the ice
	bset	#tmflcc,(tmstruct+tmflags).w	;tmflcc
	bset	#tmflcc,(awtmstruct+tmflags).w	;tmflcc
	movea.l	#priolist,a0			;position priority list
	tst.w	tmgoalie(a2)			;92 cmp #2
	bpl.w	.gin
	addq.w	#1,a0					;tmgoalie negative: use the list one byte on
.gin	clr.w	position(a3)		;set the returning player into his position
	move.b	(a0,d1.w),position+1(a3)	;position = priolist entry d1
	bsr.w	Setplass				;initial assignment
	bsr.w	setplayer				;bring him onto the ice
	bset	#pf2unav,pflags2(a3)	;92 used bit 4
	movem.l	(sp)+,d0-d3/a0-a3
	rts

GetLowestPen						;a2 = shorthanded team (its penalty box list is walked, as set up by
									;updatepwrplay), a3 = the other team. Return d0 = power play time left
									;from the penalty box times. Called from updatepwrplay
	clr.w	d0						;d0 = running total, d3 = previous time
	clr.w	d3
	lea	tmboxlist(a2),a0
.top	clr.w	d2					;add up the steps between successive non-coincidental times
	move.b	(a0)+,d2
	bmi.w	.t2						;end of list
	move.w	tmpdst(a2,d2.w),d2
	btst	#$E,d2					;coincidental (word bit 14): skip
	bne.s	.top
	sub.w	d3,d2
	add.w	d2,d0
	move.w	d2,d3
	bra.s	.top
.t2	cmpi.w	#6,tmap(a3)				;6 on ice, done
	beq.w	rtss
	sub.w	d3,d0
	lea	tmboxlist(a3),a0			;then the other team's box list
	clr.w	d2
.t3	move.b	(a0)+,d2				;next player of the other team
	bmi.w	rtss
	btst	#6,tmpdst(a3,d2.w)		;coincidental
	bne.s	.t3
	cmp.w	tmpdst(a3,d2.w),d0
	blt.w	rtss
	add.w	d3,d0
	rts

updatepwrplay						;show graphic and time remaining for power plays. Plays song $33 at the
									;start of a home power play, then prints the time and the team on the
									;power play
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3
	move.w	tmap(a2),d0
	sub.w	tmap(a3),d0				;players on ice: team 1 minus team 2
	beq.w	.clrpwrplay				;equal: no power play
	bpl.w	.t0						;team 1 has more
	;team 2 has more: afterwards a2 = shorthanded team 1, a3 = power play team 2
	btst	#sf2pwrtm,(sflags2).w	;sf2pwrtm: 0 for team 1 in power play
	bne.w	.upp
	bsr.w	.clrpwrplay				;power play team changed: remove the old display
	bset	#sf2pwrtm,(sflags2).w
	bra.w	.upp

.t0	exg	a2,a3						;a2 = shorthanded team 2, a3 = power play team 1
	btst	#sf2pwrtm,(sflags2).w
	beq.w	.upp
	bsr.w	.clrpwrplay
	bclr	#sf2pwrtm,(sflags2).w

.upp	bset	#sf2pwrplay,(sflags2).w	;power play display on
	bne.w	.uppt					;already showing a power play
	addq.w	#1,tmPwrPlays(a3)		;new power play: count it for a3
	cmpa.w	#(tmstruct-M68K_RAM),a3
	bne.w	.uppt
	move.w	#SngPP,-(sp)			;song only when team 1 (home) is on the power play
	bsr.w	song
.uppt	bsr.w	printz				;power play marker string at x 1, y $19, then the time left and the team
									;name
	String	$BF,1,$19,'   ',$16,$17,$18,$19,$BF,1,$1A,'  ',0
	bsr.w	GetLowestPen			;d0 = time left
	bsr.w	PushTime				;a1 = m:ss string
	bsr.w	print
	movea.l	tmdata(a3),a0			;power play team's data
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#2,(a3)					;empty string in mesarea, then append the position string and name
	bsr.w	appendz
	String	$BF,1,$19
	adda.w	4(a0),a0				;team name
	adda.w	(a0),a0
	movea.l	a0,a1
	bsr.w	appstring
	movea.w	a3,a1
	bra.w	print

.clrpwrplay	bclr	#sf2pwrplay,(sflags2).w	;no power play (or display changing)
	IF REV=2
	bne.w	EASNLogo				;put the logo back (Rev B shows the EA Sports one)
	rts
	ELSE
	beq.w	rtss					;none was shown
	bra.w	EASNLogo				;put the EASN logo back
	ENDIF

ClrHor								;revert the graphics back to vertical ice rink
									;mode. Does not remap the fonts
	movem.l	d0-d7/a0-a6,-(sp)
	bclr	#sfhor,(sflags).w
	move.w	#$3E8,(Oldrow).w		;1000 (not a real row, probably so the map is redrawn)

	bsr.w	SprSort					;rebuild the sprite sort for the vertical view

	btst	#sfpz,(sflags).w
	bne.w	.0						;pause mode: leave the screen
	bsr.w	printz
	String	$FF,0,0
	moveq	#$20,d0					;32
	moveq	#$1C,d1					;28
	move.w	#$7FF,d2				;blank tile (92 1)
	bsr.w	eraser					;blank the 32x28 area
	bsr.w	printscores1			;redraw the score board
.0	movem.l	(sp)+,d0-d7/a0-a6		;restore and return
	rts

SetHor								;switch graphics to horizontal ice rink graphics mode. Does not remap the
									;fonts
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#sfhor,(sflags).w

.p	btst	#dfok,(disflags).w		;wait while graphics are ready for transfer (dfok set)
	bne.s	.p

	clr.w	(Hscroll).w
	clr.w	(Vscroll).w
	bsr.w	SprSort

	bsr.w	printz
	String	$FE,0,0
	movea.l	#IceRinkMap,a1			;draw the horizontal rink map with dobitmap
	adda.l	4(a1),a1
	movea.w	#null,a2				;tile pointer null: a zero word, so nothing to decompress
	clr.w	d0						;start x 0
	moveq	#$55,d1					;85: start y in the map
	moveq	#$20,d2					;32 wide
	moveq	#$1C,d3					;28 high
	move.w	(rinkvrcset).w,d4		;start char of the rink tiles
	moveq	#0,d5					;no palette lines
	bsr.w	dobitmap

	bsr.w	USBoard					;draw the score board and penalty box lines
	btst	#sfpz,(sflags).w
	bne.w	.ex
	move.w	#$800,d0				;92 $1000
	move.w	(VmMAP1).w,d1
	move.w	#$7FF,d2				;blank tile (92 1)
	bsr.w	DoFill					;fill d0 words at VmMAP1 with the blank tile

.ex	movem.l	(sp)+,d0-d7/a0-a6		;restore and return
	rts

;======================================================================
;======================================================================
;	Scoreboard, ticker and intermission code: printscores1 and the team name and logo score displays, USBoard,
;	pplpen, linebar, the line and shot stat helpers, Intermission, the score and ticker updates and their
;	labels, then Fprintsmall, AdvanceStringPtr and the highlights (DoHiLights, StartHL, StartHL2).
;
;	printz String control bytes $BF/$BE/$BD (-$41/-$42/-$43), then x, y. Game struct (gstruct): 0 gst1, 2
;	gst2, 8 gsper, $A gss1, $C gss2, $E gsflags (bit 1 gsfhl, bit 2 gsfso).

printscores1						;draw scoreboard. Vertical rink: period box and the score box (team names
									;and scores). Horizontal rink (.sbscreen): period and both team logos with
									;big scores. Called from USBoard, Pausemode, lcfound2 and others
	movem.l	d0-d2/a0-a3,-(sp)
	btst	#sfhor,(sflags).w
	bne.w	.sbscreen
	bsr.w	printz
	String	$BF,0,$17
	moveq	#9,d0					;period box: 9x5 frame at x 0, y $17
	moveq	#5,d1
	bsr.w	Framer
	bset	#dfclock,(disflags).w	;clock needs update
	bsr.w	printz
	String	$BF,1,$18
	move.w	(gsp).w,d0				;period name (92 .pp)
	movea.l	#PerLabels,a1
	bsr.w	Fprintsmall				;print the period name in the box
	bsr.w	EASNLogo				;logo under it (unless a power play is shown)
	btst	#sf3llcs,(sflags3).w	;lower line change box is up
	bne.w	.ex
	bsr.w	printz
	String	$BF,$17,$17
	moveq	#8,d0					;score box: 8x5 frame at x $17, y $17
	moveq	#5,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,$18,$1A				;home team on the lower row
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	PrintTeamNameAndScore
	bsr.w	printz
	String	$BF,$18,$18				;visitors on the row above
	adda.w	#tmsize,a2
	bsr.w	PrintTeamNameAndScore
.ex	movem.l	(sp)+,d0-d2/a0-a3		;restore and return
	rts
.sbscreen	bsr.w	printz			;horizontal rink: score board screen
	String	$BE,$11,5
	move.w	(gsp).w,d0				;period name
	movea.l	#PerLabels,a1
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0					;center the period name on x $11
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
	bsr.w	printz
	String	$BE,$17,1				;home logo and score at x $17
	movea.w	#(tmstruct-M68K_RAM),a2
	clr.w	d0						;home logo data offset
	bsr.w	PrintTeamLogoAndScore
	bsr.w	printz
	String	$BE,9,1					;visitors at x 9
	adda.w	#tmsize,a2
	moveq	#$30,d0					;visitor logo data offset
	bsr.w	PrintTeamLogoAndScore
	bra.s	.ex

PrintTeamNameAndScore				;from 92 printscores1 .ps. print the team name of team a2 at
									;printx/printy, then its score as 2 digits at x $1C. Called twice from
									;printscores1
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1					;skip the first string to the team name
	bsr.w	print
	move.w	#$1C,(printx).w			;score column
	move.w	tmscore(a2),d0
	moveq	#2,d1					;2 digits
	bsr.w	PushNumberWidth
	bra.w	print					;print the score and return

PrintTeamLogoAndScore				;from 92 printscores1 .sbscreen. draw the team logo map (PutTeamBlock, d0
									;= offset) 6 columns left of printx, then the score of team a2 in big
									;font, centered 2 rows lower. Called twice from printscores1.sbscreen
	move.w	(printx).w,-(sp)		;keep the column
	subq.w	#6,(printx).w
	jsr	(PutTeamBlock).w			;team logo block
	move.w	(sp)+,(printx).w
	addq.w	#2,(printy).w
	move.w	tmscore(a2),d0
	bsr.w	PushNumber				;a1 = score string
	move.w	(a1),d0					;center on the old printx
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bra.w	printbig				;big font score and return

EASNLogo							;Draw easn.map at x 1, y $19 on the vertical ice rink if no power play.
									;Falls into DrawEASNMap
	btst	#sf2pwrplay,(sflags2).w
	bne.w	rtss
	bsr.w	printz
	String	$BF,1,$19

DrawEASNMap							;Draw the EASN logo map at the current printx/printy.
									;Also called from ShowScores
	movea.l	#EASNmap,a1
	adda.l	4(a1),a1
	movea.w	#null,a2				;tile pointer null (as in SetHor)
	clr.w	d0						;start x/y 0
	clr.w	d1
	move.w	(a1),d2					;width and height from the map header (92: 7, 2)
	move.w	2(a1),d3
	move.w	(EASNcset).w,d4			;start char
	clr.w	d5						;no palette lines
	bra.w	dobitmap

USBoard								;update score board, including the players in the penalty box and their
									;time remaining. Called from InProgress and SetHor
	movem.l	d0-d7/a0-a3,-(sp)
	bset	#dfclock,(disflags).w	;clock needs update
	bsr.w	printscores1
	bsr.w	printz
	String	$BE,$14,8				;team 1 penalty lines at x $14, row 8
	movea.w	#(tmstruct-M68K_RAM),a2	;in the string
	bsr.w	.dispen
	bsr.w	printz
	String	$BE,5,8					;team 2 penalty lines at x 5, row 8
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize; in the string
	bsr.w	.dispen
	movem.l	(sp)+,d0-d7/a0-a3
	rts

.dispen	lea	tmboxlist(a2),a0		;penalty box list of team a2. Prints the players with tmpdst bit 14 clear
									;first, then those with it set
.l1	clr.w	d0						;pass 1: players with bit 14 (coincidental) clear
	move.b	(a0)+,d0
	bmi.w	.p2						;end of list
	btst	#6,tmpdst(a2,d0.w)		;tmpdst high byte bit 6
	bne.s	.l1
	bsr.w	pplpen
	bra.s	.l1
.p2	lea	tmboxlist(a2),a0			;pass 2: the players with the bit set
.l2	clr.w	d0						;next entry
	move.b	(a0)+,d0
	bmi.w	rtss					;end of list: done
	btst	#6,tmpdst(a2,d0.w)
	beq.s	.l2
	bsr.w	pplpen
	bra.s	.l2

pplpen								;?. Print one penalty box line: player number and time remaining. a2 =
									;team, d0 = roster offset (player*2). Only rows up to y $A are printed;
									;printy += 1. Called from USBoard.dispen
	cmpi.w	#$A,(printy).w
	bhi.w	rtss					;no room for more rows
	move.w	tmpdst(a2,d0.w),d2
	andi.w	#$7FF,d2				;penalty time
	movea.l	tmdata(a2),a1
	adda.w	(a1),a1					;a1 = roster in the team data
	lsr.w	#1,d0					;d0 = player index
.find	adda.w	(a1),a1				;skip d0+1 roster entries (name string + 8 bytes)
	addq.w	#8,a1
	dbf	d0,.find
	clr.w	d0
	move.b	-8(a1),d0				;player number (BCD)
	move.w	(printx).w,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	bsr.w	ConvertByteToDigits		;two digits to TextBuffer
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#4,(a1)					;string length: 2 digits
	bsr.w	print					;print the number
	move.w	d2,d0
	bsr.w	PushTime				;m:ss string
	bsr.w	print					;print the time next to it
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w			;next row
	rts

linebar								;draw the energy bar of line d0 for team a2 at printx/printy (bitmap from
									;the bar map, 16 steps). Called from SetLCmode2
	movem.l	d0-d5/a0-a2,-(sp)
	bsr.w	getlinee				;d0 = energy of the line (0-$1000, max set in reenergizeteam)
	move.w	(printa).w,-(sp)
	move.w	#$8000,(printa).w		;priority attribute for the bar
	ext.l	d0
	divu.w	#$100,d0				;4096/16
	cmp.w	#$F,d0
	bls.w	.ok
	moveq	#$F,d0					;clamp to 15
.ok									;d0 = energy step 0-15
dobar	equ	*						;92 dobar (draw energy bar for energy level d0); in 92 this is a separate
									;routine, here it is a branch target
	moveq	#$F,d1
	sub.w	d0,d1					;d1 = bar frame (15 = empty)
	clr.w	d0
	movea.l	#EnergyBarMap,a1
	adda.l	4(a1),a1
	movea.w	#null,a2				;tile pointer null (as in SetHor)
	move.w	(a1),d2					;map width
	moveq	#1,d3					;1 row high
	move.w	(energybarchars).w,d4
	moveq	#0,d5
	bsr.w	dobitmap				;d1 = start row in the map = frame
	move.w	(sp)+,(printa).w
	movem.l	(sp)+,d0-d5/a0-a2
	rts

getlinee							;d0 = line number, a2 = team struct. Return d0 = energy level of this line
	movem.l	d1-d5/a0-a3,-(sp)
	lea	tmlines(a2),a1				;line sets
	asl.w	#3,d0					;8 bytes per line
	adda.w	d0,a1					;a1 = this line (one player number per position)
	clr.l	d0						;d0 = energy sum
	clr.w	d1						;d1 = players counted
	movea.l	#priolist,a0
	move.w	tmap(a2),d4				;players on ice (loop counter, walks priolist)
	bra.w	.next
.loop	clr.w	d5					;next player on ice
	move.b	(a0,d4.w),d5			;position
	beq.w	.next					;goalie energy doesn't count
	clr.w	d3
	move.b	(a1,d5.w),d3			;player number
	asl.w	#1,d3
	addq.w	#1,d1
	add.w	tmpde-2(a2,d3.w),d0		;add his energy (tmpde word, offset by the player number)
.next	dbf	d4,.loop				;loop over tmap players
	divu.w	d1,d0					;average energy
	movem.l	(sp)+,d1-d5/a0-a3
	rts

AvgCline							;return d0 = average energy of current line on team a2
	movem.l	d1-d3/a0,-(sp)
	clr.l	d0						;d0 = energy sum
	clr.w	d1						;d1 = skaters counted
	moveq	#5,d2					;6 sort objects of the team
	movea.w	tmsort(a2),a0
.l0	tst.w	position(a0)			;position 0 (goalie) and negative (off ice) are skipped
	ble.w	.next
	clr.w	d3
	move.b	pnum(a0),d3
	add.w	d3,d3
	add.w	tmpde(a2,d3.w),d0
	addq.w	#1,d1
.next	adda.w	#SCstruct,a0		;next sort object
	dbf	d2,.l0
	tst.w	d1
	beq.w	.ex						;nobody: avoid the divide
	divu.w	d1,d0					;average
.ex	movem.l	(sp)+,d1-d3/a0			;restore and return
	rts

ChkShotStat							;add to shot stat if a shot was taken. Also raises the crowd and counts
									;the shot for the shooter and against the other team's goalie
	bclr	#sf2shot,(sflags2).w
	beq.w	rtss					;no shot taken
	movem.l	d0-d1/a1-a3,-(sp)
	addi.w	#$64,(Crowdlevel).w		;100
	addi.w	#$A,(CwdExciteLvl).w	;+10 excitement
	move.w	(shotplayer).w,d0
	asl.w	#scsize,d0				;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3					;a3 = the shooter
	bsr.w	loadTeamStruct			;a2 = his team, a1 = the other team
	addq.w	#1,(a2)					;tmshots
	clr.w	d0
	move.b	pnum(a3),d0
	addi.w	#$E8,d0
	addq.b	#1,(a2,d0.w)			;shooter's shot count
	move.w	tmgoalie(a1),d0			;other team's tmgoalie
	bmi.w	.ex						;empty net
	addi.w	#$E8,d0
	addq.b	#1,(a1,d0.w)			;goalie's shots against
.ex	movem.l	(sp)+,d0-d1/a1-a3		;restore and return
	rts

loadTeamStruct						;from 92 AddStat team select. return a2 = team struct of player a3, a1 =
									;the other team's struct. Called from ChkShotStat and updateplayers
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	btst	#pfteam,pflags(a3)
	beq.w	rtss					;home player: a2 = team 1
	exg	a1,a2						;visitor: swap
	rts

SetupTeamForIntermission			;reset the bench, then for each team refill energy and pick the starting
									;line: power play line 1 (3) for the team with more players on ice, PK1
									;(5) for the team with fewer, else 0. Called from Intermission
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3
	bsr.w	.r
	exg	a2,a3						;falls in for the other team
.r	bsr.w	reenergizeteam			;refill energy for this team
	clr.w	tmline(a3)				;a3 starts on line 0 unless a man advantage decides otherwise
	tst.w	(OptLine).w
	bne.w	rtss					;line changes off
	move.w	tmap(a3),d0
	sub.w	tmap(a2),d0				;a3's players on ice minus a2's
	beq.w	rtss					;even
	move.w	#3,tmline(a3)			;Pw1
	tst.w	d0
	bpl.w	rtss					;a3 has more players: power play line
	move.w	#5,tmline(a3)			;PK1
	rts

reenergizeteam						;set all players to max energy on team a2. Also moves players marked -3 in
									;tmpdst to the bench (-2). Called from SetupTeamForIntermission and
									;StartHL2 .setteam
	moveq	#(maxros-1)*2,d0		;(MaxRos-1)*2
.0	move.w	#$1000,tmpde(a2,d0.w)	;full energy for the player at roster offset d0
	cmpi.w	#-3,tmpdst(a2,d0.w)
	bne.w	.nb
	move.w	#-2,tmpdst(a2,d0.w)		;on bench
.nb	subq.w	#2,d0					;next player (counting down)
	bpl.s	.0
	rts

Intermission						;end of period junk (zamboni/stats). Opens the pause menu screen (item
									;list by period, +5 in playoffs), shows the ticker scores of the other
									;games, then the highlights. Start on either pad cuts it short. Called
									;from PeriodOver
	bsr.s	SetupTeamForIntermission
	moveq	#$F,d0					;clear Xpos of the 16 sort objects
	movea.w	#(SortCords-M68K_RAM),a0
.0	clr.w	(a0)					;Xpos
	adda.w	#SCstruct,a0
	dbf	d0,.0
	move.w	(ExtraChars).w,d4
	movea.l	#ZamSprites+8,a2		;zamboni sprite tiles
	bsr.w	DecompressGraphicsPlain
	move.w	#$140,(Zamx).w			;320
	move.w	(gsp).w,d0
	tst.w	(OptPlayMode).w
	beq.w	.ss
	addq.w	#5,d0					;playoffs
.ss	asl.w	#2,d0					;d0 = period (+5 in playoffs) * 4
	lea	.sslist(pc),a0
	movea.l	(a0,d0.w),a0			;a0 = menu item list for this period
	bset	#sfpz,(sflags).w		;pause mode
	movea.l	#SetupPauseScreen,a1
	jsr	(InitMenuState).w
	bsr.w	GetShifter				;d1 = highest game index
	move.w	d1,(TickerNum).w		;ticker starts from the last game
.top	tst.w	(TickerNum).w		;one ticker game per pass
	bmi.w	.doh					;no more ticker games
	bsr.w	NewTicker2				;d3 = next game to show
	bsr.w	NewTicker3				;show its score
	move.w	#$96,d0					;150 frames
	bsr.w	waitxsr
	btst	#sbut,d1				;sbut
	bne.w	.clrh
	bsr.w	ClearTickerArea			;blank pause, then the next game
	move.w	#$3C,d0					;60 frames
	bsr.w	waitxsr
	btst	#sbut,d1				;sbut
	beq.s	.top
.clrh	bset	#sf3sbut,(sflags3).w	;start was pressed: highlights get skipped
.doh	bsr.w	DoHiLights			;show the requested highlights
	bclr	#sf3sbut,(sflags3).w
	bne.w	.clrz					;start pressed (flag set by .clrh or by a highlight): leave
.wait	move.w	#$1E0,d0			;480 frames
	bsr.w	waitxsr
	btst	#sbut,d1				;sbut
	bne.w	.clrz
	tst.w	(cont1team).w
	bne.s	.wait					;keep waiting while a pad is on a team
	tst.w	(cont2team).w
	bne.s	.wait
.clrz	st	(Zamx).w				;zamboni off
	rts

.sslist								;Menu item lists, by period then playoff period
	dc.l	StartGameText,IntermissionText,IntermissionText,IntermissionText,ExitGameText
	dc.l	StartGameTextPO,IntermissionText,IntermissionText,IntermissionText,ExitGameTextPO

InitScores							;initialize other games scores/period in playoffs (no OptPlayMode check).
									;Called from StartGame
	cmpi.w	#1,(gamelevel).w
	bgt.w	rtss					;gamelevel above 1: no other games to simulate
	bsr.w	GetShifter				;d1 = highest game index
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d0				;gssize
	mulu.w	d1,d0
	adda.w	d0,a0					;a0 = gstruct of game d1, counting down
.top	cmp.w	(gamenum).w,d1		;per game
	beq.w	.next					;not the game being played
	btst	#gsfso,gsflags(a0)		;gsfso
	bne.w	.next					;series already over
	clr.w	gsper(a0)				;gsper
	moveq	#3,d0
	bsr.w	randomd0				;random 0-2: score that many plus one periods
	bra.w	.1
.0	bsr.w	SetScore				;one period of scoring
.1	dbf	d0,.0						;repeat for each period
.next	suba.w	#gssize,a0			;gssize
	dbf	d1,.top						;next game
	rts

UpdateScores						;update ticker score values. Called from PeriodOver
	bsr.w	GetShifter				;d1 = highest game index
	move.w	d1,(TickerNum).w		;restart the ticker
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d0				;gssize
	mulu.w	d1,d0
	adda.w	d0,a0					;a0 = gstruct of game d1, counting down
.top	cmp.w	(gamenum).w,d1		;per game
	beq.w	.next					;not the game being played
	bclr	#gsfhl,gsflags(a0)		;gsfhl: forget old highlight request
	btst	#gsfso,gsflags(a0)		;gsfso
	bne.w	.next					;series over
	bsr.w	SetScore				;one more period for this game
.next	suba.w	#gssize,a0			;gssize
	dbf	d1,.top
	rts

SetScore							;add to score for game in a0. After period 3 a game within one goal goes
									;to OT (gsper 3) and asks for a highlight
	cmpi.w	#4,gsper(a0)			;gsper
	bge.w	rtss					;OT/final already
	movem.l	d0-d1/a0-a1,-(sp)
	cmpi.w	#3,8(a0)				;gsper
	bne.w	.0						;periods 0-2: add normal scoring
	move.w	#5,8(a0)				;final
	move.w	gss1(a0),d0				;gss1
	sub.w	gss2(a0),d0				;gss2
	cmp.w	#1,d0
	bgt.w	.ex
	cmp.w	#-1,d0
	blt.w	.ex
	move.w	#3,8(a0)				;close game: overtime
	bset	#gsfhl,gsflags(a0)		;gsfhl
	bra.w	.ex
.0	addq.w	#1,8(a0)				;next period
	move.w	(a0),d0					;gst1
	move.w	2(a0),d1				;gst2
	bsr.w	.getscore				;goals for team 1 this period
	add.w	d0,gss1(a0)				;gss1
	move.w	2(a0),d0
	move.w	(a0),d1
	bsr.w	.getscore				;goals for team 2
	add.w	d0,gss2(a0)				;gss2
.ex	movem.l	(sp)+,d0-d1/a0-a1		;restore and return
	rts

.getscore	asl.w	#2,d0			;d0 = scoring team, d1 = other team. Adds the scoring team's (bits 4-6)
									;and the other team's (bits 0-2) .sctab rows as weights. Return d0 = goals
									;0-3
	movea.w	#TeamList,a1			;team address table
	movea.l	(a1,d0.w),a1
	adda.w	8(a1),a1
	move.b	(a1),d0
	andi.w	#$70,d0
	lsr.w	#1,d0					;row * 8
	lea	.sctab(pc),a1
	move.l	(a1,d0.w),(nibblebuffer).w
	move.l	4(a1,d0.w),(nibblebuffer+4).w
	asl.w	#2,d1
	movea.w	#TeamList,a1
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
	moveq	#4,d0					;4 weights
	bra.w	WeightedRandomSelect

.sctab								;Weights for 0, 1, 2, 3 goals (92 had 4 percent bytes per row)
	dc.w	$2B,$1E,$17,4
	dc.w	$27,$20,$18,5
	dc.w	$23,$21,$1A,6
	dc.w	$1E,$22,$1E,6
	dc.w	$1A,$24,$1E,8
	dc.w	$16,$25,$1F,$A
	dc.w	$13,$26,$1F,$C
	dc.w	$F,$26,$20,$F

NewTicker							;show the next ticker score once the clock is at 8:00 or less. d3 = -1 if
									;not. Called from chkprogress. Falls into NewTicker2
	moveq	#-1,d3					;none yet
	cmpi.w	#$1E0,(gameclock).w		;480
	bgt.w	rtss					;more than 8:00 left: not yet

NewTicker2							;goto next ticker. Return d3 = game, or neg if none left (no OptPlayMode
									;check). Falls into CheckGameTickerStatus
	move.w	(TickerNum).w,d3
	bmi.w	rtss					;no ticker games left
	subq.w	#1,(TickerNum).w
	cmp.w	(gamenum).w,d3			;don't show current game as ticker
	beq.s	NewTicker2

CheckGameTickerStatus				;from 92 NewTicker3 head. d3 = game. Return a0 = its gstruct; skip to the
									;next ticker game if a highlight is coming up or the series is over.
									;Called from StartHL2
	moveq	#gssize,d0				;gssize
	mulu.w	d3,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	btst	#gsfhl,gsflags(a0)		;gsfhl
	bne.s	NewTicker2				;don't show if hilite coming up
	btst	#gsfso,gsflags(a0)		;gsfso
	bne.s	NewTicker2				;don't show if the series is over for this game
	rts

NewTicker3							;display ticker score for game d3 (a0 = gstruct entry), skip if d3 is
									;negative. Called from chkprogress, Intermission and StartHL2
	tst.w	d3
	bmi.w	rtss
	bsr.w	SetTickerAreaPosition	;d0/d1 = box size
	bsr.w	Framer					;draw the ticker box
	addq.w	#1,(printx).w			;inside the frame, top row
	subq.w	#4,(printy).w
	move.w	(printx).w,-(sp)		;keep the left edge (4(sp) in .tn after its return address)
	bsr.w	GetShifter
	move.w	#$A000,(printa).w
	bsr.w	printz
	String	'                        '	;24 spaces (92 26)
	move.w	(sp),(printx).w
	moveq	#1,d0
	add.w	(gamelevel).w,d0		;playoffs: label 1 + round
	tst.w	(OptPlayMode).w
	bne.w	.gl
	clr.w	d0						;not playoffs: 'EASN Hockey Night'
.gl	lea	GameLabels(pc),a1			;a1 = ticker title list
	bsr.w	Fprintsmall				;print the ticker title
	move.w	gsper(a0),d0			;gsper
	subq.w	#1,d0
	movea.l	#PerLabels,a1
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0					;period name centered on x+$17
	lsr.w	#1,d0
	neg.w	d0
	add.w	(sp),d0
	addi.w	#$17,d0
	move.w	d0,(printx).w
	bsr.w	print
	move.w	#$8000,(printa).w
	move.w	2(a0),d0				;gst2
	move.w	gss2(a0),d1				;gss2
	bsr.w	.tn						;team 2 on the first row
	move.w	(a0),d0					;gst1
	move.w	gss1(a0),d1				;gss1
	bsr.w	.tn						;team 1 on the second row
	addq.w	#2,sp					;drop the saved printx
	rts

.tn	move.w	4(sp),(printx).w		;print team d0 name and score d1 on the next row
	addq.w	#1,(printy).w
	movea.w	#TeamList,a1			;team address table
	asl.w	#2,d0
	movea.l	(a1,d0.w),a1
	adda.w	4(a1),a1				;TeamName
	bsr.w	print
	move.w	4(sp),(printx).w
	addi.w	#$15,(printx).w			;92 23
	move.w	d1,d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print

GameLabels							;ticker titles, by OptPlayMode and gamelevel
	IF REV=2
	String	'EA Hockey Night'		;Rev B: the EASN branding is gone
	ELSE
	String	'EASN Hockey Night'
	ENDIF
	String	'EA Cup Qualifier'
	String	'EA Quarterfinal'
	String	'EA Cup Semifinal'

ClearTickerArea						;erase the ticker box. Called from Intermission and StartHL2
	bsr.w	SetTickerAreaPosition
	move.w	#$7FF,d2				;blank char
	bra.w	eraser

SetTickerAreaPosition				;from 92 NewTicker3 position setup. set printx/printy/printm for the
									;ticker box (x 3, y $17; the $BD map in pause mode). Return d0 = $1A wide,
									;d1 = 5 high. Called from NewTicker3 and ClearTickerArea
	bsr.w	printz
	String	$BD,3,$17
	btst	#sfpz,(sflags).w
	bne.w	.1
	bsr.w	printz
	String	$BF,3,$17
.1	moveq	#$1A,d0					;box size 26x5
	moveq	#5,d1
	rts

Fprintsmall							;from 92 Fprint, but printing with printsmall (92 used print). Print
									;string d0 of the String list a1
	bsr.w	AdvanceStringPtr
	bra.w	printsmall

AdvanceStringPtr					;like 92's string-list print, without the print. Return a1 = string d0 of
									;the String list a1
	bra.w	.1
.0	adda.w	(a1),a1					;skip one string (first word = its length)
.1	dbf	d0,.0						;d0 strings to skip
	rts

DoHiLights							;hilites logic: search for hilite game and show hilite (no OptPlayMode
									;check). Called from Intermission
	bsr.w	GetShifter				;d1 = highest game index
	moveq	#gssize,d3				;gssize
	mulu.w	d1,d3
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d3,a0					;a0 = gstruct of game d1, counting down
.top	btst	#gsfso,gsflags(a0)	;gsfso
	bne.w	.next					;series over
	bclr	#gsfhl,gsflags(a0)		;gsfhl
	beq.w	.next					;no highlight requested
	bsr.w	StartHL
.next	suba.w	#gssize,a0			;gssize
	dbf	d1,.top
	rts

StartHL	movem.l	d0-d7/a0-a6,-(sp)	;play hilite for game a0, d1 = game. Called from DoHiLights. Falls into
									;StartHL2
StartHL2							;play hilite for game a0. Start skips it with a random result. A tied game
									;is replayed (beq StartHL2)
	btst	#sf3sbut,(sflags3).w
	bne.w	.nhl0					;start already pressed: just pick a random result
	bsr.w	.sv						;save the real game state (gmode ... ScoreSumbytes)
	move.w	d1,d3
	bsr.w	CheckGameTickerStatus
	bsr.w	NewTicker3				;show score from hilight game
	btst	#sf3sbut,(sflags3).w
	bne.w	.nhl1
	move.w	#4,(printx).w			;"Highlight from game:" box, 24x3 above the ticker
	subq.w	#6,(printy).w
	moveq	#$18,d0					;24
	moveq	#3,d1
	bsr.w	Framer
	addq.w	#1,(printx).w
	subq.w	#2,(printy).w
	bsr.w	printz
	String	'Highlight from game:'
	move.w	#$B4,d0					;180 frames
	bsr.w	waitxsr
	btst	#sbut,d1				;sbut
	bne.w	.nhl1					;start: skip the highlight
	st	(Zamx).w					;zamboni off
	clr.w	(CwdExciteLvl).w
	move.w	(a0),(HomeTeam).w		;set up teams for game in a0
	move.w	2(a0),(VisTeam).w
	move.l	a0,-(sp)				;keep the gstruct pointer
	clr.w	(tmstruct+tmgoalie).w
	clr.w	(awtmstruct+tmgoalie).w
	jsr	(clearTeamStats).l
	jsr	(restoreteams).w			;load both teams' data
	st	(c1playernum).w				;no human players
	st	(c2playernum).w
	clr.w	(cont1team).w
	clr.w	(cont2team).w
	moveq	#$78,d0					;120
	bsr.w	randomd0
	addi.w	#$3C,d0					;60
	move.w	d0,(gameclock).w		;random clock, 60 + 0-119
	movea.l	(sp),a0
	move.w	gsper(a0),(gsp).w		;gsper
	subq.w	#1,(gsp).w
	move.w	gss1(a0),(tmstruct+tmscore).w	;gss1
	move.w	gss2(a0),(awtmstruct+tmscore).w	;gss2
	move.b	#$10,(gmode).w			;1<<gmhl
	btst	#0,(gsp+1).w			;odd period: gmdir set (home team goes the other way)
	beq.w	.ndi
	bset	#gmdir,(gmode).w
.ndi	clr.b	(sflags).w			;fresh state flags for the highlight
	move.b	#4,(sflags2).w			;1<<sf2drec
	clr.b	(sflags3).w
	bclr	#dffaceoff,(disflags).w
	bset	#dfclock,(disflags).w
	clr.w	(glovecords).w
	clr.b	(iflags).w
	st	(RefCnt).w
	st	(puckcross+2).w
	st	(puckcross+6).w
	jsr	p_turnoff
	bsr.w	setupice_highlight
	bsr.w	ClrHor					;vertical rink
	movea.l	#Vdata,a0
	move.w	#$9100,4(a0)			;window H position 0
	move.w	#$9200,4(a0)			;window V position 0
	move.w	(ExtraChars).w,d4		;ref cam chars
	movea.l	#RefsMap+8,a2
	bsr.w	DecompressGraphicsPlain
	clr.w	(Vpos).w
	clr.w	(Hpos).w
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	.setteam
	adda.w	#tmsize,a2
	bsr.w	.setteam
	bsr.w	resetplstuff
	moveq	#$B,d0					;12 players: put each on his face off spot
	movea.l	#.postab,a0
	movea.w	#(SortCords-M68K_RAM),a1
.ploop	move.w	position(a1),d1		;position 0-5 (goalie, defense, wings, center)
	btst	#pfgoal,pflags(a1)
	bne.w	.pl0
	addq.w	#6,d1
.pl0	asl.w	#2,d1				;4 bytes (x, y) per table entry
	move.w	(a0,d1.w),(a1)			;Xpos
	move.w	2(a0,d1.w),Ypos(a1)
	clr.w	Xvel(a1)
	clr.w	Yvel(a1)
	adda.w	#SCstruct,a1
	dbf	d0,.ploop
	bsr.w	SprSort
	move.w	#$18,(palcount).w		;24
	move.w	(Vcount).w,(OldVcount).w
	move.w	#$B4,-(sp)				;180 frames after the clock stops
.0	jsr	(DoGameFrame).w				;DoGameFrame waits for the vblank (92 inline)
	btst	#gmclock,(gmode).w
	beq.w	.1						;clock running
	subq.w	#1,(sp)
	bmi.w	.endhl					;clock stopped for 180 frames: highlight over
.1	bsr.w	orjoy					;check both pads
	btst	#cbut,d1				;cbut
	bne.w	.eh						;C or Start ends the highlight early
	btst	#sbut,d1				;sbut
	beq.s	.0
.eh	move.w	(tmstruct+tmscore).w,d0	;tied: random winner
	cmp.w	(awtmstruct+tmscore).w,d0
	bne.w	.endhl
	move.w	(HVcount).l,d0			;hvcount
	andi.w	#1,d0
	add.w	d0,(tmstruct+tmscore).w
	eori.w	#1,d0
	add.w	d0,(awtmstruct+tmscore).w
.endhl	addq.w	#2,sp				;drop the frame counter
	movea.l	(sp)+,a0				;a0 = gstruct
	movem.l	d1/a0,-(sp)
	jsr	KillCrowd
	jsr	p_turnoff
	movem.l	(sp)+,d1/a0
	move.w	(tmstruct+tmscore).w,gss1(a0)	;gss1: the highlight's score becomes the game's score
	move.w	(awtmstruct+tmscore).w,gss2(a0)	;gss2
	bsr.w	forceblack
	moveq	#$F,d0					;clear Xpos of the 16 sort objects
	movea.w	#(SortCords-M68K_RAM),a0
.clr	clr.w	(a0)				;Xpos
	adda.w	#SCstruct,a0
	dbf	d0,.clr
	bsr.w	.lo						;restore the saved game state
	bsr.w	setplayercolors
	bsr.w	SetHor					;back to the intermission screen
	bsr.w	setvideo
	jsr	(SetupPauseScreen).w		;pause menu screen
	jsr	(DrawMenuScreen).w
	move.w	#$18,(palcount).w		;24
	move.w	#SngEOP,-(sp)			;song $36
	bsr.w	song
	movem.l	(sp),d0-d7/a0-a6		;reload the registers StartHL pushed (a0 = gstruct, d1 = game)
	move.w	#4,gsper(a0)			;gsper: OT
	move.w	gss1(a0),d0				;gss1
	cmp.w	gss2(a0),d0				;gss2
	beq.w	StartHL2				;still tied: play another hilite
	move.w	#5,8(a0)				;final
	move.w	d1,d3
	bsr.w	CheckGameTickerStatus	;show the final score in the ticker
	bsr.w	NewTicker3
	move.w	#$B4,d0					;180 frames
	bsr.w	waitxsr
	btst	#sbut,d1				;sbut
	bne.w	.exit2
	bsr.w	ClearTickerArea
	move.w	#$3C,d0					;60 frames
	bsr.w	waitxsr
	btst	#sbut,d1				;sbut
	beq.w	.exit
.exit2	bset	#sf3sbut,(sflags3).w	;start pressed: skip the remaining highlights
.exit	movem.l	(sp)+,d0-d7/a0-a6	;restore and return
	rts
.nhl1	bsr.w	.lo					;start pressed after .sv: restore the state, random result
	bsr.w	.ranres
	bra.s	.exit2
.nhl0	bsr.w	.ranres				;start already pressed: random result only
	bra.s	.exit

.setteam	jsr	(reenergizeteam).l	;refill energy and set tmtouch1/2/3(a2) per team (a2 = team)
	bsr.w	setpersonel
	bsr.w	forcepldata
	st	tmtouch1(a2)
	st	tmtouch2(a2)
	st	tmtouch3(a2)
	rts

.ranres	move.w	gss1(a0),d0			;random resolve of game (if tied = random score)
	cmp.w	gss2(a0),d0
	bne.w	.rr0
	move.w	(HVcount).l,d0			;hvcount
	andi.w	#1,d0
	add.w	d0,gss1(a0)
	eori.w	#1,d0
	add.w	d0,gss2(a0)
.rr0	move.w	#5,gsper(a0)		;gsper: final
	rts

.sv	move.w	#$37E,d0				;save $37F words from gmode to ReplayStart (92 ((gstruct-gmode)/2)-1)
	movea.w	#(gmode-M68K_RAM),a1
	movea.l	#replaystart,a2			;ReplayStart
.sv1	move.w	(a1)+,(a2)+			;copy words from gmode to ReplayStart
	dbf	d0,.sv1
	move.w	(ScoreSumbytes).w,(a2)+	;also save ScoreSumbytes
	rts

.lo	move.w	#$37E,d0				;restore what .sv saved
	movea.w	#(gmode-M68K_RAM),a2
	movea.l	#replaystart,a1			;ReplayStart
.lo1	move.w	(a1)+,(a2)+			;copy the saved words back
	dbf	d0,.lo1
	move.w	(a1)+,(ScoreSumbytes).w
	rts

.postab								;Xpos,Ypos by position (goalie, l.def, r.def, l.wing, center, r.wing),
									;pfgoal set, then clear
	dc.w	0,-240,-70,-140,20,-110,-100,-60,25,-40,70,-80
	dc.w	0,240,34,90,-55,80,100,40,-10,10,-50,0
