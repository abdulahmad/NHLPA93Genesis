;	NHLPA Hockey 93 (retail) segment $E526-$EFA7
;	92 Penalty.Asm part 1: AddPenalty, AddPenalty2, PenaltyManager,
;	chkprogress, InProgress, the 93 coinsearch (92 InProgress .ap job),
;	checkfornewpen, Stop4Pen, limitfo, UpdatePA, SetPA, SetPA2, PushRef,
;	prefmes, the 93-only PrintPenaltyMessagesString, PenGoalStuff, the
;	93-only ClearPenaltyBuffer, updatepentime, the 93-only ProcessPenaltyList
;	and RemovePlayerFromList, chkatop, releasepl, GetLowestPen,
;	updatepwrplay, ClrHor and SetHor. The Penaltylist data is in hockey93_11.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after assembly.
;	Penalty numbers are PenaltyList word offsets. 93 reorders them; the ones
;	used here (92 value in brackets): EOG 4 (4), OOP 6 ($C), whistle $A ($26),
;	icing $C (8), goal $E (6), offsides $10 ($A), delay $2C ($24).
;	93 team struct (tmsize $1A2, 92 $88): 2 tmPwrGoals, 4 tmPwrPlays,
;	6 tmPenalties, 8 tmPenmin, $A attack time (92 tmATOP $C), $1E tmdata,
;	$22 tmsort, $24 tmap, $26 tmgoalie, $30 tmflags, $66 tmpdst, $9A penalty
;	box list (bytes, -1 end). Sort struct: $34 position, $40 temp1,
;	$53 SCnum+1, $62 pflags, $63 pflags2, $66 pnum.

AddPenalty	;add penalty d0 (PenaltyList offset) for player a3. Ignored while the clock is stopped, when penalties are off, or offsides when offsides are off. Falls into AddPenalty2
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	cmp.w	#$C,d0			;icing (92 PenIcing = 8)
	beq.w	AddPenalty2
	tst.w	(OptPen).w
	beq.w	rtss			;penalties off
	btst	#5,(gmode).w		;gmoffs
	bne.w	AddPenalty2
	cmp.w	#$10,d0			;offsides (92 PenOffsides = $A)
	beq.w	rtss

AddPenalty2	;forced penalties like face off and game over. d0 = penalty number, a3 = player or player on penalized team. 93: penalty numbers from $E (goal) up raise the crowd and play a song
	btst	#7,(sflags).w		;sfhor
	bne.w	rtss
	movem.l	d1/a0-a1,-(sp)
	cmp.w	#$E,d0			;goal (92 PenGoal = 6) and up
	blt.w	.nosnd
	addi.w	#$C8,(crowdlevel).w	;200
	move.w	#$C,-(sp)		;song $C for the home team
	btst	#6,pflags(a3)		;pfteam
	beq.w	.snd
	addi.w	#$14,(CwdExciteLvl).w	;visitors: +20 excitement
	move.w	#$B,(sp)		;song $B
.snd	bsr.w	song			;IDA: loc_E59E
.nosnd	movea.w	#(PenBuf-M68K_RAM),a1	;IDA: loc_E5A2
	moveq	#$1F,d1			;MaxPen-1
.0	tst.w	(a1)+			;IDA: loc_E5A8. find free slot
	dbeq	d1,.0
	bne.w	.noplayer		;buffer full
	move.b	$53(a3),-(a1)		;SCnum+1
	move.b	d0,-(a1)
	movea.l	#PenaltyList,a0
	adda.w	(a0,d0.w),a0
	tst.b	1(a0)			;penalty minutes
	beq.w	.noplayer
	bset	#4,pflags2(a3)		;92 pf2pen (bit 6 in 92)
	beq.w	.noplayer
	clr.w	(a1)			;player already has a penalty, drop this one
.noplayer	movem.l	(sp)+,d1/a0-a1		;IDA: loc_E5D6
	rts

PenaltyManager	;called periodically. d7 = elapsed time since last call
	bsr.w	updatepentime
	bsr.w	checkfornewpen
	bsr.w	chkprogress
	bra.w	UpdatePA

chkprogress	;control progress of ref and game control thru penalty events. When the stop delay runs out and a penalty with minutes is in PenBuf, switch to the horizontal rink for the player to enter the penalty box
	btst	#2,(gmode).w		;gmpen
	beq.w	rtss
	tst.w	(Pencntdwn).w
	bmi.w	InProgress
	sub.w	d7,(Pencntdwn).w
	bpl.w	rtss
	bclr	#3,(gmode).w		;gmpendel
	movea.w	#(PenBuf-M68K_RAM),a0
.find	tst.w	(a0)+			;IDA: loc_E610. 93 looks for any penalty with minutes
	beq.w	rtss
	clr.w	d0
	move.b	-2(a0),d0
	movea.l	#PenaltyList,a1
	adda.w	(a1,d0.w),a1
	tst.b	1(a1)			;penalty minutes
	beq.s	.find
	bset	#2,(sflags2).w		;sf2drec: switch to horizontal mode for player to enter penalty box
	move.w	(vcount).w,-(sp)
	bsr.w	forceblack
	move.w	(sp)+,(vcount).w
	bsr.w	SetHor
	move.w	(ExtraChars).w,d4	;93: load horizontal ref tiles
	movea.l	#RefMap2Plus8,a2
	bsr.w	DoDMA_clearCallbackPointer
	bsr.w	NewTicker
	bsr.w	NewTicker3
	st	(puckc).w
	movea.w	#(puckx-M68K_RAM),a3
	move.l	#$1A,d0			;pnothing
	bsr.w	assinsert
	move.w	#$1C20,$40(a3)		;temp1 = 120*60

	st	(RefStep).w
	clr.w	(RefCnt).w
	bsr.w	UpdatePA
	move.w	#$32,(RefCnt).w		;50
	clr.w	d0
	bsr.w	PushRef			;93: ref frame 0
	move.w	#$18,(palcount).w	;24
	rts

InProgress	;ref in progress-- update graphics and stats and penalty information. Takes the last PenBuf entry: the first pass logs a penalty with minutes and sends the player to the box, later passes wait until he is off the ice and drop the entry. When PenBuf is empty, recount players and go to the face off. Entered from chkprogress
	tst.w	(RefCnt).w
	bpl.w	rtss			;animation in progress
	tst.w	(RefStep).w
	bpl.w	rtss
	movem.l	d0/a0-a3,-(sp)
.top	movea.w	#(PenBuf-M68K_RAM),a0	;IDA: _top
	tst.w	(a0)+
	beq.w	.exit
.0	tst.w	(a0)+			;IDA: _0. find end of list
	bne.s	.0
	subq.w	#4,a0
	bclr	#7,1(a0)		;player who is guilty
	bne.w	.Sa
	move.l	a3,-(sp)
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#7,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	tst.w	$34(a3)			;position
	movea.l	(sp)+,a3
	bpl.w	.ex			;still on the ice
	clr.w	(a0)
	bra.w	.ex

.Sa	clr.w	d0			;IDA: _Sa
	move.b	(a0),d0
	movea.l	#PenaltyList,a1
	adda.w	(a1,d0.w),a1
	clr.w	d2
	move.b	1(a1),d2		;penalty minutes
	beq.w	.sa2			;no player involved
	movem.l	d0-d1/a1-a4,-(sp)
	bsr.w	GetPeriodTimeRemaining	;93: log time, penalty and player
	movea.w	#(unk_FFC3F6-M68K_RAM),a4
	adda.w	(word_FFC3F4).w,a4
	cmpi.w	#$EC,(word_FFC3F4).w	;log full: keep overwriting the last entry
	beq.w	.full
	addq.w	#4,(word_FFC3F4).w
.full	move.w	d0,(a4)+		;IDA: loc_E714. time
	move.b	(a0),(a4)+		;penalty
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#7,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	clr.w	d0
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	$1A2(a2),a1		;tmsize
	btst	#6,pflags(a3)		;pfteam
	beq.w	.sa1
	bset	#7,-1(a4)		;log: visitors
	move.w	#$8000,d0
	exg	a1,a2
.sa1	addq.w	#1,6(a2)		;IDA: loc_E746. tmpenalties
	add.w	d2,8(a2)		;tmpenmin
	move.b	$66(a3),d0		;pnum
	move.b	d0,(a4)			;log: player
	move.w	d0,(TempPlOffset).w
	ext.w	d0
	addi.w	#$102,d0		;93: per-player penalty minutes byte at $102+pnum
	add.b	d2,(a2,d0.w)
	subi.w	#$102,d0
	asl.w	#1,d0
	ext.w	d2
	mulu.w	#$3C,d2			;60
	bset	#$D,d2
	tst.w	$66(a2,d0.w)		;tmpdst
	bmi.w	.st
	btst	#4,$66(a2,d0.w)
	beq.w	.st
	bset	#$C,d2			;keep bit 4 of an old penalty time as bit 12
.st	move.w	d2,$66(a2,d0.w)		;IDA: loc_E788. tmpdst
	andi.w	#$EFFF,d2
	moveq	#$34,d1			;(MaxRos-1)*2+2
.ctop	subq.w	#2,d1			;IDA: loc_E792. 92 coinsearch: same time on the other team
	bmi.w	.nocoin
	move.w	$66(a1,d1.w),d3
	andi.w	#$EFFF,d3
	cmp.w	d3,d2
	bne.s	.ctop
	bset	#6,$66(a1,d1.w)		;coincidental
	bset	#6,$66(a2,d0.w)
.nocoin	movem.l	a0,-(sp)		;IDA: loc_E7B0. 93: add player to penalty box list
	lea	$9A(a2),a0
	moveq	#$18,d1
.pl	tst.b	(a0)+			;IDA: loc_E7BA. find end of list
	dbmi	d1,.pl
	move.b	d0,-1(a0)
	st	(a0)
	movem.l	(sp)+,a0

	move.w	#$C,d0			;apenalty
	bsr.w	assreplace
	movem.l	(sp)+,d0-d1/a1-a4
	bsr.w	SetPA
	bsr.w	USBoard
	bra.w	.ex
.sa2	clr.w	(a0)			;IDA: _sa2
	btst	#7,(sflags).w		;sfhor
	bne.w	.top
	bsr.w	SetPA
	bra.w	.ex

.exit	movea.w	#(hmtmstruct-M68K_RAM),a2	;IDA: _exit
	bsr.w	coinsearch
	adda.w	#$1A2,a2		;tmsize
	bsr.w	coinsearch
	
	bclr	#2,(gmode).w		;gmpen
	movea.w	#(puckx-M68K_RAM),a3
	move.w	#$1B,d0			;pfaceoff
	bsr.w	assreplace
.ex	movem.l	(sp)+,d0/a0-a3		;IDA: _ex
	rts

coinsearch	;IDA name; does the job of 92 InProgress .ap (92 coinsearch is inlined in InProgress). a2 = team. Clears tmpdst bit 5, counts players kept off the ice by penalties (coincidental and bit 4 times do not count, at most 2) and sets tmap. Called twice from InProgress
	moveq	#6,d1
	moveq	#$32,d0			;(MaxRos-1)*2
.top	tst.w	$66(a2,d0.w)		;IDA: loc_E822. tmpdst
	ble.w	.nap
	bclr	#5,$66(a2,d0.w)
	btst	#6,$66(a2,d0.w)		;coincidental
	bne.w	.nap
	btst	#4,$66(a2,d0.w)
	bne.w	.nap
	cmp.w	#4,d1			;never below 4 players
	beq.w	.nap
	subq.w	#1,d1
.nap	subq.w	#2,d0			;IDA: loc_E84E
	bpl.s	.top
	move.w	d1,$24(a2)		;tmap
	rts

checkfornewpen	;look for new penalty (entered thru addpenalty(2)). Stops play at once for penalties without minutes or when the guilty team does not have the puck, otherwise starts a delayed penalty call
	btst	#7,(sflags).w		;sfhor
	bne.w	rtss
	movea.w	#(PenBuf-M68K_RAM),a0
.next	tst.w	(a0)+			;IDA: _next
	beq.w	rtss
	btst	#2,(gmode).w		;gmpen
	bne.w	.iscalled
	clr.w	d0
	move.b	-2(a0),d0
	movea.l	#PenaltyList,a1
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

.callit	bsr.w	Stop4Pen		;IDA: _callit

.iscalled	bset	#7,-1(a0)		;IDA: _iscalled
	bne.s	.next
	clr.w	d0
	move.b	-2(a0),d0		;penalty called
	movea.l	#PenaltyList,a1
	adda.w	(a1,d0.w),a1
	clr.w	d1
	move.b	(a1),d1			;delay for stopping action
	asl.w	#5,d1
	cmp.w	(Pencntdwn).w,d1
	ble.s	.next
	move.w	d1,(Pencntdwn).w
	bra.s	.next

.dc	bset	#3,(gmode).w		;IDA: _dc. gmpendel
	bne.s	.next
	move.w	#$2C,d0			;delayed penalty (92 PenDelay = $24)
	bsr.w	SetPA
	bra.s	.next

Stop4Pen	;a0 = penaltylist penalty +2. Stop the clock, set the face off spot from the penalty type, blow the whistle. Also entered from puckfaceoff+38
	bset	#0,(gmode).w		;gmclock
	bne.w	.skipfo
	clr.w	d0
	clr.w	d1
	cmpi.b	#$E,-2(a0)		;goal (92 PenGoal = 6): center ice
	beq.w	.noticing
	move.w	(ltx).w,d0
	move.w	(lty).w,d1
	cmpi.b	#6,-2(a0)		;OOP (92 PenOOP = $C)
	beq.w	.noticing
	move.w	(puckx).w,d0
	move.w	(pucky).w,d1
	cmpi.b	#$C,-2(a0)		;icing (92 PenIcing = 8)
	bne.w	.noticing
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	move.b	-1(a0),d1
	ext.w	d1
	asl.w	#7,d1			;scsize
	adda.w	d1,a3
	move.w	#$258,d1		;600
	btst	#7,pflags(a3)		;pfgoal
	movea.l	(sp)+,a3
	beq.w	.noticing
	neg.w	d1
.noticing	movem.w	d0-d1,-(sp)		;IDA: _noticing
	cmp.w	#$46,d0			;.xspot = 70
	blt.w	.0
	move.w	#$46,d0
.0	cmp.w	#$FFBA,d0		;IDA: _0. -.xspot
	bgt.w	.1
	move.w	#$FFBA,d0
.1	cmp.w	#$A6,d1			;IDA: _1. .yspot-.ygive = 206-40
	blt.w	.2
	move.w	#$CE,d1			;.yspot = 206
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.2
	neg.w	d0
.2	cmp.w	#$FF5A,d1		;IDA: _2. -.yspot+.ygive
	bgt.w	.3
	move.w	#$FF32,d1		;-.yspot
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.3
	neg.w	d0
.3	move.w	d0,(fox).w		;IDA: _3
	move.w	d1,(foy).w
	addq.w	#4,sp
	bsr.w	limitfo

.skipfo	clr.w	(Pencntdwn).w		;IDA: _skipfo
	bset	#2,(gmode).w		;gmpen
	move.w	#3,-(sp)		;whistle (92 SFXwhistle = 10)
	bsr.w	sfx
	move.w	#$A,d0			;whistle (92 PenWhistle = $26)
	bra.w	SetPA

limitfo	;limit face off to 5-20 feet from walls of rink. Checks every player in PenBuf
	movem.l	d0-d1/a0-a1,-(sp)
	movea.w	#(PenBuf-M68K_RAM),a0
.loop	bsr.w	.lf			;IDA: loop
	addq.w	#2,a0
	tst.w	(a0)
	bne.s	.loop
	movem.l	(sp)+,d0-d1/a0-a1
	rts

.lf	move.b	1(a0),d0		;IDA: limitfo_lf
	andi.w	#$7F,d0
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a1
	move.w	#$58,d1			;92 blueline
	btst	#7,pflags(a1,d0.w)		;pfgoal
	bne.w	.0
	neg.w	d1
	cmp.w	(foy).w,d1
	blt.w	rtss
	move.w	#$FFBF,(foy).w		;-.nuy = -65
	bra.w	.sx
.0	cmp.w	(foy).w,d1		;IDA: _0
	bgt.w	rtss
	move.w	#$41,(foy).w		;IDA: loc_EA08 (xref is stats93 string bytes). .nuy = 65
.sx	move.w	#$46,d0			;IDA: _sx. .nux = 70
	tst.w	(fox).w
	bpl.w	.1
	neg.w	d0
.1	move.w	d0,(fox).w		;IDA: _1
	rts

UpdatePA	;animate ref in ref window. 93: also runs DisplayPeriodOver for game over and reprints the horizontal penalty message line when word_FFC2BA runs out
	tst.w	(RefCnt).w
	bmi.w	rtss
	sub.w	d7,(RefCnt).w
	bpl.w	.0
	bsr.w	SetPA2
.0	cmpi.w	#4,(RefPen).l		;IDA: loc_EA36. game over (92 PenEOG = 4)
	bne.w	.1
	bsr.w	DisplayPeriodOver
.1	sub.w	d7,(word_FFC2BA).w	;IDA: loc_EA46
	bpl.w	rtss
	move.w	#$7FFF,(word_FFC2BA).w
	bsr.w	PrintPenaltyMessagesString
	bsr.w	printz
	String	$BF,$11,$B
	bsr.w	GetPlayerName
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w		;center it
	bra.w	print

SetPA	;start ref animation. d0 = animation (penalty number). 93: goal also calls DisplayPlayerAttributeMenu, and word_FFC2BA is set to 60 in horizontal mode. Falls into SetPA2
	move.w	d0,(RefPen).w
	clr.w	(RefStep).w
	bsr.w	prefmes
	cmp.w	#$E,d0			;goal (92 PenGoal = 6)
	bne.w	.0
	bsr.w	DisplayPlayerAttributeMenu
.0	move.w	#$7FFF,(word_FFC2BA).w	;IDA: loc_EA8A
	btst	#7,(sflags).w		;sfhor
	beq.w	SetPA2
	move.w	#$3C,(word_FFC2BA).w	;60

SetPA2	;update animation for ref. Next frame/delay pair from the PenaltyList animation of RefPen. Also called from UpdatePA
	movem.l	d0-d2/a0-a1,-(sp)
	moveq	#$40,d0			;clear ref window
	tst.w	(RefStep).w
	bmi.w	.pr
	move.w	(RefStep).w,d0
	addq.w	#2,(RefStep).w
	move.w	(RefPen).w,d1
	movea.l	#PenaltyList,a0
	adda.w	(a0,d1.w),a0
	addq.w	#2,a0
	adda.w	(a0),a0
	move.w	(a0,d0.w),d0
	bpl.w	.0
	neg.w	d0			;negative = last frame
	st	(RefStep).w
.0	clr.w	d1			;IDA: loc_EAD6
	move.b	d0,d1
	asl.w	#3,d1
	move.w	d1,(RefCnt).w
	lsr.w	#8,d0
.pr	bsr.w	PushRef			;IDA: loc_EAE2
	movem.l	(sp)+,d0-d2/a0-a1
	rts

PushRef	;tell vblank what to display. d0 = ref frame, $40 clears the window. 93: the horizontal ref uses RefMap2
	movem.l	d0-d2/a0-a1,-(sp)
	cmp.w	#$40,d0
	beq.w	.clearit
	mulu.w	#$70,d0			;refwidth*refheight*2
	movea.l	#RefsMap,a0
	btst	#7,(sflags).w		;sfhor
	beq.w	.m1
	movea.l	#RefMap2,a0
.m1	adda.l	4(a0),a0		;IDA: loc_EB12
	addq.w	#4,a0
	adda.w	d0,a0
	movea.w	#(RefRamMap-M68K_RAM),a1
	move.w	(ExtraChars).w,d2
	btst	#7,(sflags).w		;sfhor
	bne.w	.4
	ori.w	#$8000,d2		;priority
.4	moveq	#$37,d0			;IDA: loc_EB30. (refheight*refwidth)-1
.1	move.w	(a0)+,(a1)		;IDA: loc_EB32
	add.w	d2,(a1)+
	dbf	d0,.1
	bset	#1,(sflags2).w		;sf2refref
	bra.w	.ex

.clearit	btst	#7,(sflags).w		;IDA: _clearit. 93: horizontal mode only clears the line
	bne.w	.cl
	movea.w	#(RefRamMap-M68K_RAM),a1
	moveq	#$37,d0			;(refheight*refwidth)-1
.2	move.w	#$7FF,(a1)+		;IDA: loc_EB54. blank tile (92 1)
	dbf	d0,.2
	bset	#1,(sflags2).w		;sf2refref
.cl	moveq	#-1,d0			;IDA: loc_EB62. clear line
	bsr.w	prefmes

.ex	movem.l	(sp)+,d0-d2/a0-a1	;IDA: loc_EB68
	rts

prefmes	;print message for penalty d0 (negative clears it). Vertical mode: framed under the ref. Horizontal mode: one centered line on row $B
	movem.l	d0-d2/a1,-(sp)
	btst	#7,(sflags).w		;sfhor
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

.noblank	bsr.w	printz			;IDA: loc_EB9C
	String	$BF,5,$A		;x 5 (92 6)
	movea.l	#PenaltyList,a1
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	subq.w	#2,d0			;empty string (92 cmp #4 / bls)
	beq.w	.ex
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bpl.w	.nb0
	clr.w	(printx).w
.nb0	move.w	(a1),d0			;IDA: loc_EBC8
	tst.b	-1(a1,d0.w)
	bne.w	.nb1
	subq.w	#1,d0
.nb1	moveq	#3,d1			;IDA: loc_EBD4
	bsr.w	Framer
	subq.w	#2,(printy).w
	addq.w	#1,(printx).w
	bsr.w	print
	bra.w	.ex

.hor	bsr.w	PrintPenaltyMessagesString	;IDA: loc_EBEA. 93 clears the line first
	tst.w	d0
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$11,$B
	movea.l	#PenaltyList,a1
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
.ex	movem.l	(sp)+,d0-d2/a1		;IDA: loc_EC16
	rts

PrintPenaltyMessagesString	;93: blank the horizontal mode penalty message line (22 spaces at x 5, y $B; 92 prefmes .hor printed 16 at x 8). Called from UpdatePA and prefmes
	bsr.w	printz
	String	$BF,5,$B,'                      ',0
	rts

PenGoalStuff	;do this stuff after a goal. a1 = scored on team, a2 = scoring team. If the scoring team had more players on ice, the first scored on player in the box without a coincidental penalty is released
	movem.l	d0-d2/a0,-(sp)
	bsr.w	ClearPenaltyBuffer

	move.w	$24(a2),d2		;tmap: end p.killing by scored on team
	cmp.w	$24(a1),d2
	ble.w	.ex
	lea	$9A(a1),a0
.0	clr.w	d2			;IDA: loc_EC56
	move.b	(a0)+,d2
	bmi.w	.ex
	btst	#6,$66(a1,d2.w)		;coincidental
	bne.s	.0
	clr.w	$66(a1,d2.w)		;tmpdst
	bsr.w	RemovePlayerFromList
	addq.w	#1,$24(a1)		;tmap
	addq.w	#1,2(a2)		;tmPwrGoals
	bset	#0,(byte_FFC516).w	;tmstruct+tmflags: tmflcc
	bset	#0,(byte_FFC6B8).w	;tmstruct+tmsize+tmflags: tmflcc
.ex	movem.l	(sp)+,d0-d2/a0		;IDA: _ex
	rts

ClearPenaltyBuffer	;93: clear PenBuf (92 inlined this in PenGoalStuff). Also called from clockcont
	moveq	#$1F,d0			;MaxPen-1
	movea.w	#(PenBuf-M68K_RAM),a0
.0	clr.w	(a0)+			;IDA: loc_EC8E
	dbf	d0,.0
	rts

updatepentime	;update the time remaining on all penalized players, once a second. 93: sets sflags3 bit 6 on that tick. Falls into ProcessPenaltyList for team 2
	bclr	#6,(sflags3).w
	btst	#0,(gmode).w		;gmclock
	bne.w	rtss
	sub.w	d7,(Penaltytimer).w
	bpl.w	rtss
	addi.w	#$18,(Penaltytimer).w	;jps
	bset	#6,(sflags3).w
	bsr.w	chkatop
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	ProcessPenaltyList
	adda.w	#$1A2,a2		;tmsize

ProcessPenaltyList	;93 version of 92 updatepentime .ut. a2 = team. Walks the penalty box list ($9A): the first two players without a coincidental penalty count down one second and the rest wait. Beeps when the first served time gets to 5 or less and releases the player at 0. Coincidental penalties count down on their own
	lea	$9A(a2),a0
	movea.w	#(mesarea-M68K_RAM),a1	;serving players
	moveq	#2,d1			;two can serve at once
	moveq	#2,d3
.next	clr.w	d0			;IDA: process_next_player
	move.b	(a0)+,d0
	bmi.w	.done
	btst	#6,$66(a2,d0.w)		;coincidental
	bne.w	.coinpen
	subq.w	#1,d1
	bmi.s	.next			;third or later player waits
	move.w	d0,(a1)+
	subq.w	#1,$66(a2,d0.w)		;tmpdst
	bne.w	.cont
	bsr.w	RemovePlayerFromList	;time is up
.cont	bra.s	.next			;IDA: continue_if_time_greater_than_zero

.done	move.w	(mesarea).w,d0		;IDA: loc_ECFC. first serving player
	cmp.w	#1,d1			;one serving
	beq.w	.chk
	tst.w	d1
	bne.w	.n1
	bsr.w	.chk			;two serving: check the first, then the second
	bra.w	.two
.n1	cmp.w	#$FFFF,d1		;IDA: loc_ED16. exactly three in the list: check the second only
	bne.w	rtss
.two	move.w	(TextBuffer).w,d0	;IDA: loc_ED1E. second serving player (mesarea+2)

.chk	cmpi.w	#5,$66(a2,d0.w)		;IDA: CheckAndReleasePlayer. tmpdst
	bgt.w	rtss
	move.w	#1,-(sp)		;SFXbeep1
	tst.w	$66(a2,d0.w)
	bne.w	.snd
	bsr.w	releasepl
	move.w	#2,(sp)			;SFXbeep2
.snd	bsr.w	sfx			;IDA: loc_ED40
	rts

.coinpen	subq.w	#1,$66(a2,d0.w)		;IDA: handle_coincidental_penalty
	btst	#3,$66(a2,d0.w)
	beq.s	.next
	btst	#4,$66(a2,d0.w)
	bne.w	.clr
	move.w	#$1000,$66(a2,d0.w)
	bra.w	RemovePlayerFromList
.clr	clr.w	$66(a2,d0.w)		;IDA: loc_ED66. falls into RemovePlayerFromList

RemovePlayerFromList	;93: remove the entry before a0 from a penalty box list by shifting the rest down (list ends with a negative byte). Return a0 = removed slot. Called from PenGoalStuff, ProcessPenaltyList
	moveq	#-1,d2
.shift	addq.w	#1,d2			;IDA: shift_entries
	move.b	(a0,d2.w),-1(a0,d2.w)
	bpl.s	.shift
	subq.w	#1,a0
	rts

chkatop	;attack time of possession stat update. Called once a second from updatepentime
	moveq	#0,d1
	move.w	(pucky).w,d0
	cmp.w	#$58,d0			;92 blueline
	bgt.w	.1
	move.l	#$1A2,d1		;tmsize
	neg.w	d0
	cmp.w	#$58,d0			;92 blueline
	blt.w	rtss
.1	btst	#1,(gmode).w		;IDA: loc_ED98. gmdir
	beq.w	.0
	eori.w	#$1A2,d1		;tmsize
.0	movea.w	#(hmtmstruct-M68K_RAM),a2	;IDA: loc_EDA6
	addq.w	#1,$A(a2,d1.w)		;attack time (92 tmATOP = $C)
	rts

releasepl	;player's penalty time is up so let him out (if appropriate). a2 = team, d0 = player*2. Called from ProcessPenaltyList
	movem.l	d0-d3/a0-a3,-(sp)
	movea.w	$22(a2),a3		;tmsort
	suba.w	#SCstruct,a3
.0	adda.w	#SCstruct,a3			;IDA: loc_EDBC. first sort obj not on the ice
	tst.w	$34(a3)			;position
	bpl.s	.0

	move.w	d0,d3
	lsr.w	#1,d3
	move.w	$24(a2),d1		;tmap
	addq.w	#1,$24(a2)
	bset	#0,(byte_FFC516).w	;tmstruct+tmflags: tmflcc
	bset	#0,(byte_FFC6B8).w	;tmstruct+tmsize+tmflags: tmflcc
	movea.l	#priolist,a0
	tst.w	$26(a2)			;tmgoalie (92 cmp #2)
	bpl.w	.gin
	addq.w	#1,a0
.gin	clr.w	$34(a3)			;IDA: loc_EDEE. position
	move.b	(a0,d1.w),$35(a3)
	bsr.w	Setplass
	bsr.w	setplayer
	bset	#2,pflags2(a3)		;92 pf2unav (bit 4 in 92)
	movem.l	(sp)+,d0-d3/a0-a3
	rts

GetLowestPen	;92 name; 93 body differs (92 built a release-order PlList). a2 = team on the power play, a3 = shorthanded team. Return d0 = power play time left from the penalty box times. Called from updatepwrplay
	clr.w	d0
	clr.w	d3
	lea	$9A(a2),a0
.top	clr.w	d2			;IDA: loc_EE14
	move.b	(a0)+,d2
	bmi.w	.t2
	move.w	$66(a2,d2.w),d2		;tmpdst
	btst	#$E,d2
	bne.s	.top
	sub.w	d3,d2
	add.w	d2,d0
	move.w	d2,d3
	bra.s	.top
.t2	cmpi.w	#6,$24(a3)		;IDA: loc_EE2E. tmap: 6 on ice, done
	beq.w	rtss
	sub.w	d3,d0
	lea	$9A(a3),a0
	clr.w	d2
.t3	move.b	(a0)+,d2		;IDA: loc_EE40
	bmi.w	rtss
	btst	#6,$66(a3,d2.w)		;coincidental
	bne.s	.t3
	cmp.w	$66(a3,d2.w),d0
	blt.w	rtss
	add.w	d3,d0
	rts

updatepwrplay	;show graphic and time remaining for power plays. 93: plays song $33 at the start of a home power play, then prints the time and the team on the power play
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	$1A2(a2),a3		;tmsize
	move.w	$24(a2),d0		;tmap
	sub.w	$24(a3),d0
	beq.w	.clrpwrplay
	bpl.w	.t0
	btst	#6,(sflags2).w		;sf2pwrtm
	bne.w	.upp
	bsr.w	.clrpwrplay
	bset	#6,(sflags2).w		;sf2pwrtm
	bra.w	.upp

.t0	exg	a2,a3			;IDA: loc_EE8A
	btst	#6,(sflags2).w		;sf2pwrtm
	beq.w	.upp
	bsr.w	.clrpwrplay
	bclr	#6,(sflags2).w		;sf2pwrtm

.upp	bset	#5,(sflags2).w		;IDA: loc_EEA0. sf2pwrplay
	bne.w	.uppt
	addq.w	#1,4(a3)		;tmpwrplays
	cmpa.w	#(hmtmstruct-M68K_RAM),a3
	bne.w	.uppt
	move.w	#$33,-(sp)
	bsr.w	song
.uppt	bsr.w	printz			;IDA: loc_EEBE
	String	$BF,1,$19,'   ',$16,$17,$18,$19,$BF,1,$1A,'  ',0
	bsr.w	GetLowestPen
	bsr.w	PushTime
	bsr.w	print
	movea.l	$1E(a3),a0		;tmdata
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

.clrpwrplay	bclr	#5,(sflags2).w		;IDA: updatepwrplay_clr. sf2pwrplay
	beq.w	rtss
	bra.w	DrawEASNLogo

ClrHor	;revert the graphics back to vertical ice rink mode. 93 does not remap the fonts
	movem.l	d0-d7/a0-a6,-(sp)
	bclr	#7,(sflags).w		;sfhor
	move.w	#$3E8,(Oldrow).w	;1000

	bsr.w	SprSort

	btst	#0,(sflags).w		;sfpz
	bne.w	.0
	bsr.w	printz
	String	$FF,0,0
	moveq	#$20,d0			;32
	moveq	#$1C,d1			;28
	move.w	#$7FF,d2		;blank tile (92 1)
	bsr.w	eraser
	bsr.w	printscores1
.0	movem.l	(sp)+,d0-d7/a0-a6	;IDA: loc_EF4E
	rts

SetHor	;switch graphics to horizontal ice rink graphics mode. 93 does not remap the fonts
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#7,(sflags).w		;sfhor

.p	btst	#0,(disflags).w		;IDA: loc_EF5E. dfok
	bne.s	.p

	clr.w	(Hscroll).w
	clr.w	(Vscroll).w
	bsr.w	SprSort

	bsr.w	printz
	String	$FE,0,0
	movea.l	#IceRinkMap,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2		;92 null
	clr.w	d0
	moveq	#$55,d1			;85
	moveq	#$20,d2			;32
	moveq	#$1C,d3			;28
	move.w	(rinkvrcset).w,d4
	moveq	#0,d5
	bsr.w	dobitmap

	bsr.w	USBoard
	btst	#0,(sflags).w		;sfpz
	bne.w	.ex
	move.w	#$800,d0		;92 $1000
	move.w	(VmMap1).w,d1
	move.w	#$7FF,d2		;blank tile (92 1)
	bsr.w	DoFill

.ex	movem.l	(sp)+,d0-d7/a0-a6	;IDA: loc_EFBA
	rts
