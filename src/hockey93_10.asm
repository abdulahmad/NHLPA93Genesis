;	NHLPA Hockey 93 (retail) segment $1499E-$15109
;	92 hockey.asm ResolveGames, then the 93-only end of game "Stars of the Game" box (DisplayPeriodOver,
;	FindMaxAttributeTEam, CalculateTeamAttributes/Values), the injury and goal boxes, box, the player name
;	formatters (getname ... ConverByteToDigits), and the 92 exception handlers AddError, Illinst, ZeroDiv
;	and crash. cd0 onward is hockey93_11.
;	Global names from the IDA export, 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	The saved password bits are tpassbits (92 name; IDA unk_FFCB72, Rev A $CB72, retail $CB6E in ram93.asm).
;	gsflags bit 0 is 92 gsftf (teams flipped). Team struct bytes per roster slot (26): $B4 goals (goals
;	against for a goalie), $CE assists, $E8 shots (shots against for a goalie); word $136 frames on ice.
;	A goal entry (ScoreSum, 6 bytes): word period/time, byte 2 bit 7 away team scored, byte 3 scorer,
;	bytes 4 and 5 assists (negative: none). ChkCnt + ScoreSumbytes is the last entry.

ResolveGames	;compute winners and losers for playoff matchups. 92 ResolveGames. Called from EncodePW (hockey93_09)
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gstruct-M68K_RAM),a0
	move.w	(hmtmstruct+tmscore).w,gss1(a0,d0.w)	;copy score from played game into game structures
	move.w	(awtmstruct+tmscore).w,gss2(a0,d0.w)

	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	cmpi.w	#7,(bosgames).w
	beq.w	.notbos			;not best of 7
.b0	cmpi.w	#4,gspotwins(a0)	;IDA: check_if_series_complete
	beq.w	.b1
	cmpi.w	#4,gspobwins(a0)
	beq.w	.b1
	clr.w	d3
	btst	#0,gsflags(a0)		;teams flipped (92 gsftf)
	beq.w	.nf
	eori.w	#gspobwins-gspotwins,d3
.nf	move.w	gss1(a0),d0		;IDA: determine_winner
	sub.w	gss2(a0),d0
	bpl.w	.ns1
	eori.w	#gspobwins-gspotwins,d3
.ns1	addq.w	#1,gspotwins(a0,d3.w)	;IDA: update_win_count
.b1	suba.w	#gssize,a0		;IDA: advance_to_next_game
	dbf	d1,.b0
	addq.w	#1,(bosgames).w
	cmpi.w	#7,(bosgames).w
	beq.w	.nextround
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	cmpi.w	#4,gspotwins(a0)
	beq.w	.cround
	cmpi.w	#4,gspobwins(a0)
	bne.w	rtss
.cround	cmpi.w	#3,(gamelevel).w	;IDA: check_if_final_round. finish off rest of round games here
	bge.w	.nextround
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
.cr0	cmp.w	(gamenum).w,d1		;IDA: loc_14A6E
	beq.w	.crn
	cmpi.w	#4,gspotwins(a0)
	beq.w	.crn
	cmpi.w	#4,gspobwins(a0)
	beq.w	.crn
	addq.w	#1,gspotwins(a0)
	move.l	#200,d0
	bsr.w	randomd0
	andi.w	#1,d0
	beq.s	.cr0
	subq.w	#1,gspotwins(a0)
	addq.w	#1,gspobwins(a0)
	bra.s	.cr0
.crn	suba.w	#gssize,a0		;IDA: loc_14AA8
	dbf	d1,.cr0
	movea.w	#(tpassbits-M68K_RAM),a3		;bits before advancing to next round (retail; Rev A unk_FFCB72, 92 tpassbits)
	bsr.w	WritePassBits		;(92 wrote passbits and copied them to tpassbits)
	bset	#sf3alttree,(sflags3).w

.nextround	clr.w	(bosgames).w	;IDA: resolve_remaining_games_in_round. advance to next round
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	clr.w	d3
.nr0	cmpi.w	#4,gspotwins(a0)	;IDA: loc_14AD2
	beq.w	.nr1
	bset	d1,d3
.nr1	clr.w	gspotwins(a0)		;IDA: loc_14ADE
	clr.w	gspobwins(a0)
	suba.w	#gssize,a0
	dbf	d1,.nr0
	moveq	#1,d1			;(92 Rev A only) clear this round's winbits
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts

.notbos	clr.w	d3		;IDA: loc_14B04. solve for no best of 7 playoffs (much simpler)
.nb0	move.w	gss1(a0),d0		;IDA: loc_14B06
	cmp.w	gss2(a0),d0
	bhi.w	.nb1
	bset	d1,d3
.nb1	btst	#0,gsflags(a0)		;IDA: loc_14B14. teams flipped (92 gsftf)
	beq.w	.nb2
	bchg	d1,d3
.nb2	suba.w	#gssize,a0		;IDA: loc_14B20
	dbf	d1,.nb0
	moveq	#1,d1			;(92 Rev A only)
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts

DisplayPeriodOver	;93 only: end of game "Stars of the Game" box. Called from UpdatePA (penalty93_1) while RefPen is
	;the game over penalty. Waits for RefCnt <= $40 and runs once (gmode bit 7). Frames the box, draws a bitmap
	;from IceRinkMap, then the three best star scores (FindMaxAttributeTEam): team data string and getname.
	;Song $F when the home team won.
	cmpi.w	#$40,(RefCnt).w
	bgt.w	rtss			;ref animation not far enough yet
	bset	#7,(gmode).w
	bne.w	rtss			;already shown
	movem.l	d0-d5/a0-a4,-(sp)
	bsr.w	printz
	String	$BF,2,$E
	moveq	#$1C,d0			;framer size
	moveq	#9,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,9,$10,'Stars of the Game',$BF,3,$F
	movea.l	#IceRinkMap,a1		;IDA hid this in the string. map at IceRinkMap offset 4
	movea.w	#$310,a2
	adda.l	4(a1),a1
	moveq	#$D,d0			;dobitmap d0-d5
	moveq	#$5B,d1
	moveq	#6,d2
	moveq	#4,d3
	move.w	(rinkvrcset).w,d4
	clr.w	d5
	bsr.w	dobitmap
	bsr.w	CalculateTeamAttributes
	move.w	#$12,(printy).w
	moveq	#2,d2			;3 stars
.loop	bsr.w	FindMaxAttributeTEam	;IDA: loop. a2 = team, d0 = player
	move.w	#$1A,(printx).w
	addq.w	#1,(printy).w
	movea.l	tmdata(a2),a1		;string at team data offset 4, then its first offset
	adda.w	4(a1),a1
	adda.w	(a1),a1
	bsr.w	print
	bsr.w	getname			;a1 = number and name of player d0
	move.w	#3,(printx).w
	bsr.w	print
	dbf	d2,.loop
	move.w	(hmtmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;- visitor score
	ble.w	.nosong
	move.w	#$F,-(sp)		;song $F: home team won
	bsr.w	song
.nosong	movem.l	(sp)+,d0-d5/a0-a4	;IDA: skip_if_away_wins_or_tie
	rts

FindMaxAttributeTEam	;93 only: take the highest of the 52 star scores at DispAttribCtr (26 per team, home first)
	;and clear it. Returns d0 = player slot, a2 = its team struct. Called from DisplayPeriodOver
	movem.l	d1-d2/a1/a4,-(sp)
	movea.w	#(DispAttribCtr-M68K_RAM),a4
	clr.l	d0			;best so far
	moveq	#$33,d2			;52 scores
.find	cmp.l	(a4)+,d0		;IDA: loc_14C06
	bge.w	.next			;not higher
	lea	-4(a4),a1		;a1 = best entry
	move.l	(a1),d0
.next	dbf	d2,.find		;IDA: loc_14C12
	clr.l	(a1)			;taken
	move.w	a1,d0
	subi.w	#(DispAttribCtr-M68K_RAM),d0
	lsr.w	#2,d0			;entry number
	movea.w	#(hmtmstruct-M68K_RAM),a2
	cmp.w	#$1A,d0
	blt.w	.home			;0-25: home team
	subi.w	#$1A,d0
	adda.w	#tmsize,a2		;26-51: away team
.home	movem.l	(sp)+,d1-d2/a1/a4	;IDA: loc_14C34
	rts

CalculateTeamAttributes	;93 only: star score for every roster slot of both teams to DispAttribCtr (26 longs per
	;team, home first). d5 = GetPeriodTime + d2, the goalie ice time needed. If gsp is 3 and the score is
	;not tied, the scorer of the last goal gets $7FFFFFFF. Called from DisplayPeriodOver
	movea.w	#(DispAttribCtr-M68K_RAM),a4
	jsr	(GetPeriodTime).w
	move.w	d0,d5
	add.w	d2,d5
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3		;a3 = other team
	bsr.w	CalculateTeamAttributeValues	;home
	movea.w	a3,a2
	lea	-tmsize(a2),a3
	bsr.w	CalculateTeamAttributeValues	;away (d3 = away - home score)
	cmpi.w	#3,(gsp).w
	bne.w	.x
	tst.w	d3
	beq.w	.x			;tied
	movea.w	#(ChkCnt-M68K_RAM),a0	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a0
	clr.w	d0
	btst	#7,2(a0)
	beq.w	.slot			;home goal
	addi.w	#$1A,d0			;away goal: second 26 entries
.slot	add.b	3(a0),d0		;IDA: loc_14C84. scorer
	asl.w	#2,d0
	movea.w	#(DispAttribCtr-M68K_RAM),a0
	move.l	#$7FFFFFFF,0(a0,d0.w)	;game winner is the first star
.x	rts				;IDA: locret_14C96

CalculateTeamAttributeValues	;93 only: star scores of team a2 (a3 = other team) to (a4)+, one long per roster
	;slot (26). Each starts at the goal difference. Skaters: goals*11000 + assists*10100 + shots*10, or in a
	;tied game shots*1000 + frames on ice. Goalies (the first slots) on ice at least d5 with shots against:
	;+32000 if goals against*100/shots <= 4, +75000 more for a shutout. Called from CalculateTeamAttributes
	movea.w	a2,a1
	move.w	tmscore(a2),d3
	sub.w	tmscore(a3),d3		;goal difference
	ext.l	d3
	moveq	#$19,d4			;26 slots
	jsr	(ReadAttributeNibble).l	;d0 = goalies on the team
	neg.w	d0
	add.w	d4,d0			;d4 above $19 - goalies: goalie slot
.loop	move.l	d3,(a4)			;IDA: calc_for_each_player
	cmp.w	d0,d4
	bhi.w	.goalie
	clr.w	d1
	move.b	$B4(a2),d1		;goals
	mulu.w	#$2AF8,d1		;11000
	add.l	d1,(a4)
	clr.w	d1
	move.b	$CE(a2),d1		;assists
	mulu.w	#$2774,d1		;10100
	add.l	d1,(a4)
	clr.w	d1
	move.b	$E8(a2),d1		;shots
	mulu.w	#$A,d1
	tst.w	d3
	bne.w	.add			;not tied: shots*10
	mulu.w	#$64,d1			;tied: shots*1000
	add.l	d1,(a4)
	clr.l	d1
	add.w	$136(a1),d1		;+ frames on ice
.add	add.l	d1,(a4)			;IDA: add_pen_minutes
	bra.w	.next
.goalie	cmp.w	$136(a1),d5		;IDA: skip_if_above_threshold
	bhi.w	.next			;not on ice long enough
	clr.w	d1
	move.b	$B4(a2),d1		;goals against
	mulu.w	#$64,d1
	clr.w	d2
	move.b	$E8(a2),d2		;shots against
	beq.w	.next
	divu.w	d2,d1
	cmp.w	#4,d1
	bhi.w	.next
	addi.l	#$7D00,(a4)		;32000
	tst.w	d1
	bne.w	.next
	addi.l	#$124F8,(a4)		;75000 for a shutout (IDA locret_124F8: a constant, not a label)
.next	addq.w	#2,a1			;IDA: advance_next_player
	addq.w	#1,a2
	addq.w	#4,a4
	dbf	d4,.loop
	rts

ShowInjuryBox	;IDA: loc_14D36. 93 only: injury box "Injury to:" player TempPlOffset (set by setInjuryType),
	;"Out for period", or "the game" when puckx+pflags2 bit pf2fight is set. Jumped to (jmp abs.l) from
	;CheckInjury (hockey93_01) when InjCntDown runs out, so global
	movem.l	d0-d2/a0-a4,-(sp)
	bsr.w	printz
	String	$BF,$B,3
	moveq	#$12,d0			;framer size
	moveq	#5,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,$C,4,'Injury to:',$BF,$C,6,'Out for period',$BF,$C,5
	bsr.w	GetPlayerNameWithAttrib	;IDA hid this in the string
	bsr.w	print
	btst	#pf2fight,(puckx+pflags2).w
	beq.w	.ex
	bsr.w	printz
	String	$BF,$14,6,'the game'	;over "period"
.ex	movem.l	(sp)+,d0-d2/a0-a4	;IDA: loc_14D96+2 (IDA hid this in the string)
	rts

DisplayPlayerAttributeMenu	;93 only: goal box. Closes both line change boxes, then printbig "GOAL!" (or "HAT
	;TRICK!" on the scorer's third goal), the scorer and up to two assists of the last goal entry.
	;Called from SetPA (penalty93_1) for the goal penalty number
	movem.l	d0-d2/a0-a4,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	jsr	(lcfound2).l		;close lc box
	adda.w	#tmsize,a2
	jsr	(lcfound2).l
	movea.w	#(ChkCnt-M68K_RAM),a4	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a4
	bsr.w	printz
	String	$BF,$B,2
	moveq	#$13,d0			;IDA hid this in the string. framer size
	moveq	#5,d1			;5 rows: no assist
	tst.b	4(a4)
	bmi.w	.frame
	addq.w	#2,d1			;7: one assist
	tst.b	5(a4)
	bmi.w	.frame
	addq.w	#1,d1			;8: two assists
.frame	bsr.w	Framer			;IDA: loc_14DE0
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#7,2(a4)
	beq.w	.home			;home team scored
	adda.w	#tmsize,a2
.home	lea	attrText(pc),a1		;IDA: loc_14DF6
	clr.w	d0
	move.b	3(a4),d0		;scorer
	addi.w	#$B4,d0
	cmpi.b	#3,0(a2,d0.w)		;goals
	bne.w	.print
	adda.w	(a1),a1			;third goal: HAT TRICK!
.print	bsr.w	printbig		;IDA: print_attr
	clr.w	d0
	move.b	3(a4),d0
	bsr.w	FormatPlayerNameWithAttrib
	bsr.w	print
	clr.w	d0
	move.b	4(a4),d0		;first assist
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$E,6,'Assist by:',$BF,$C,7
	bsr.w	FormatPlayerNameWithAttrib	;IDA hid this in the string
	bsr.w	print
	clr.w	d0
	move.b	5(a4),d0		;second assist
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$C,8
	bsr.w	FormatPlayerNameWithAttrib	;IDA hid this and the next line in the string
	bsr.w	print
.ex	movem.l	(sp)+,d0-d2/a0-a4	;IDA: loc_14E66
	rts

attrText	;printbig strings for DisplayPlayerAttributeMenu: GOAL!, then HAT TRICK!
	String	$BF,$F,3,'GOAL!',$BF,$C,5
	String	$BF,$C,3,'HAT TRICK!',$BF,$C,5

box	;93 only: fill a $13 x 8 rectangle at printz position $FF,$B,2 with char $7FF (eraser).
	;Called from SetLCmode2 (logic93_1) and banner (logic93_2)
	bsr.w	printz
	String	$FF,$B,2
	moveq	#$13,d0			;IDA hid this in the string
	moveq	#8,d1
	move.l	#$7FF,d2
	bra.w	eraser

GetPlayerName	;93 only: a1 = mesarea "NN First Last" (getname) for player TempPlOffset (bit 15 set: away
	;team). Called from UpdatePA (penalty93_1)
	movem.l	d0/a2,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2		;away team
.get	bsr.w	getname			;IDA: loc_14EBC
	movem.l	(sp)+,d0/a2
	rts

getname	;93 only: a1 = mesarea string "NN First Last" for player d0 of team a2. The number is the bcd byte
	;after the name. Called from DisplayPeriodOver, GetPlayerName, banner (logic93_2) and others
	movem.l	d0-d3/a0/a2-a3,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#4,(a3)			;length word + 2 digits
	lea	2(a3),a1
	adda.w	(a0),a0			;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	bsr.w	appendz
	String	' '
	movea.l	(sp)+,a1		;name string
	bsr.w	appstring
	movea.w	#(mesarea-M68K_RAM),a1
	movem.l	(sp)+,d0-d3/a0/a2-a3
	rts

GetPlayerNameWithAttrib	;93 only: a1 = mesarea "NN F. Last" (FormatPlayerNameWithAttrib) for player
	;TempPlOffset (bit 15 set: away team). Called from ShowInjuryBox
	movem.l	d0/a2,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2		;away team
.get	bsr.w	FormatPlayerNameWithAttrib	;IDA: loc_14F14
	movem.l	(sp)+,d0/a2
	rts

FormatPlayerNameWithAttrib	;93 only: a1 = mesarea string "NN F. Last" for player d0 of team a2, built in
	;TextBuffer. Called from DisplayPlayerAttributeMenu, GetPlayerNameWithAttrib, PrintPeriodTime and others
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0			;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	move.b	#$20,(a1)+		;' '
	movea.l	(sp)+,a0
	move.w	(a0)+,d0		;string length
	lea	-2(a0,d0.w),a2		;end of the name
	move.b	(a0)+,(a1)+		;first initial
	move.w	#$2E20,(a1)+		;'. '
.skip	cmpi.b	#$20,(a0)+		;IDA: loc_14F46. skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+		;IDA: loc_14F4C. last name
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FormatPlayerName	;93 only: a1 = mesarea string "NN Last" for player d0 of team a2, built in TextBuffer.
	;Called from DisplayAttributeEntry (stats93)
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0			;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	move.b	#$20,(a1)+		;' '
	movea.l	(sp)+,a0
	move.w	(a0)+,d0		;string length
	lea	-2(a0,d0.w),a2		;end of the name
.skip	cmpi.b	#$20,(a0)+		;IDA: loc_14F7E. skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+		;IDA: loc_14F84. last name
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FormatPlayerNameShort	;93 only: a1 = mesarea string " Last" for player d0 of team a2, space padded to 12
	;characters; a 0 byte also ends the name. Called from DrawMenuIcon (stats93)
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	movea.w	#(TextBuffer-M68K_RAM),a1
	move.b	#$20,(a1)+		;' '
	move.w	(a0)+,d0		;string length
	lea	-2(a0,d0.w),a2		;end of the name
.skip	cmpi.b	#$20,(a0)+		;IDA: loc_14FAA. skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+		;IDA: loc_14FB0. last name
	cmpa.l	a0,a2
	beq.w	.chk
	tst.b	(a0)
	bne.s	.copy
	bra.w	.chk
.pad	move.b	#$20,(a1)+		;IDA: loc_14FC0
.chk	cmpa.w	#$BEC4,a1		;IDA: loc_14FC4. TextBuffer+12
	blt.s	.pad
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FinalizeTextBuffer	;93 only: mesarea length word = a1 - mesarea, with a 0 pad byte when odd. Returns
	;a1 = mesarea. Called from the FormatPlayerName routines
	move.w	a1,d0
	subi.w	#(mesarea-M68K_RAM),d0
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even	movea.w	#(mesarea-M68K_RAM),a1	;IDA: loc_14FE6
	move.w	d0,(a1)
	rts

GetPlayerNamePointer	;93 only: a0 = name string of player d0 on team a2. From tmdata and its first offset,
	;each record is a length word string and 8 more bytes
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0
	bra.w	.cnt
.next	adda.w	(a0),a0			;IDA: loc_14FF8. skip the name
	addq.w	#8,a0
.cnt	dbf	d0,.next		;IDA: loc_14FFC
	rts

ConverByteToDigits	;93 only: two ascii digits of bcd byte d0 to (a1)+, a leading 0 becomes a space.
	;Called from getname, the FormatPlayerName routines, pplpen (penalty93_2) and others
	move.w	d0,-(sp)
	lsr.b	#4,d0
	bne.w	.digit
	move.b	#$F0,d0			;$F0+'0' = ' '
.digit	addi.b	#$30,d0			;IDA: loc_1500E. '0'
	move.b	d0,(a1)+
	move.w	(sp)+,d0
	andi.w	#$F,d0
	addi.b	#$30,d0			;'0'
	move.b	d0,(a1)+
	rts

AddError	;address error vector. 92 AddError. 93 has no BusError: the bus error vector also points here
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Address Error'	;92 -$43
	move.l	$A(sp),d0		;pc
	move.l	2(sp),d1		;access address
	bra.w	crash

Illinst	;illegal instruction vector. 92 Illinst
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Illegal Instruction'
	move.l	2(sp),d0
	move.l	d0,d1
	bra.w	crash

ZeroDiv	;divide by zero vector. 92 ZeroDiv, falls into crash
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Division by zero'
	move.l	2(sp),d0		;IDA hid this and the next line in the string
	move.l	d0,d1

crash	;printbig d1 then d0 as hex, set the vdp up, load a palette and hang. 92 crash; 93 copies 8 longs from
	;IceRinkMap+$20 to cram $20 (92 wrote one colour $0EEE to cram 6)
	movea.w	#(mesarea-M68K_RAM),a0
	move.w	#2+3+8+3+8,(a0)+
	move.b	#$BD,(a0)+		;92 -$43
	move.b	#0,(a0)+
	move.b	#2,(a0)+
	move.l	d1,-(sp)
	bsr.w	.ri

	move.b	#$BD,(a0)+
	move.b	#0,(a0)+
	move.b	#4,(a0)+
	move.l	(sp)+,d0
	bsr.w	.ri

	movea.w	#(mesarea-M68K_RAM),a1
	bsr.w	printbig

	movea.l	#VDP_DATA,a0		;92 Vdata
	move.w	#$9100,4(a0)
	move.w	#$9206,4(a0)
	move.w	#$8F02,4(a0)
	move.l	#$C0200000,4(a0)	;cram write $20 (92 $C0060000)
	movea.l	#IceRinkMap,a1
	adda.l	(a1),a1
	adda.w	#$20,a1
	moveq	#7,d0
.pal	move.l	(a1)+,(a0)		;IDA: loc_150F8
	dbf	d0,.pal
.end	bra.w	.end			;IDA: loc_150FE

.ri	moveq	#7,d2			;IDA: crash_ri. d0 as 8 hex digits to (a0)+
.top	rol.l	#4,d0			;IDA: top
	move.w	d0,d1
	andi.w	#$F,d1
	addi.w	#$30,d1			;'0'
	cmp.w	#$39,d1			;'9'
	ble.w	.t1
	addq.w	#7,d1			;'A'-'0'-10
.t1	move.b	d1,(a0)+		;IDA: t1
	dbf	d2,.top
	rts
