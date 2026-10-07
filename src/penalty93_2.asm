;	NHLPA Hockey 93 (retail) segment $EFA8-$FAE1
;	92 Penalty.Asm part 2: printscores1, the 93-only PrintTeamNameAndScore
;	and PrintTeamLogoAndScore, EASNLogo (with the DrawEASNMap entry),
;	USBoard, pplpen, linebar, getlinee, AvgCline, ChkShotStat, the 93-only
;	loadTeamStruct and SetupTeamForIntermission, reenergizeteam (92
;	hockey.asm), Intermission, InitScores, UpdateScores, SetScore, NewTicker,
;	NewTicker2, the 93-only CheckGameTickerStatus, NewTicker3, GameLabels,
;	the 93-only ClearTickerArea, SetTickerAreaPosition, PrintStringFromList
;	and AdvanceStringPtr, DoHiLights, StartHL and StartHL2.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after assembly.
;	printz String control bytes $BF/$BE/$BD are 92 -$41/-$42/-$43, then x, y.
;	93 team struct (tmsize $1A2, 92 $88): 0 tmshots, $C tmscore, $16 tmline,
;	$1E tmdata, $22 tmsort, $24 tmap, $26 tmgoalie, $32 tmpde, $66 tmpdst,
;	$9A penalty box list (bytes, -1 end), $E8 per-player shot bytes,
;	$16A line sets. Sort struct ($80 each): 0 Xpos, $14 Ypos, $28 Xvel,
;	$2A Yvel, $34 position, $62 pflags, $66 pnum.
;	Game struct (gstruct, $10 each = 92 gssize): 0 gst1, 2 gst2, 8 gsper,
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
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	PrintTeamNameAndScore
	bsr.w	printz
	String	$BF,$18,$18
	adda.w	#tmsize,a2
	bsr.w	PrintTeamNameAndScore
.ex	movem.l	(sp)+,d0-d2/a0-a3	;IDA: loc_F042
	rts
.sbscreen	bsr.w	printz			;IDA: loc_F048
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
	movea.w	#(hmtmstruct-M68K_RAM),a2
	clr.w	d0			;home logo data offset
	bsr.w	PrintTeamLogoAndScore
	bsr.w	printz
	String	$BE,9,1
	adda.w	#tmsize,a2
	moveq	#$30,d0			;visitor logo data offset
	bsr.w	PrintTeamLogoAndScore
	bra.s	.ex

PrintTeamNameAndScore	;93: print the team name of team a2 at printx/printy, then its score as 2 digits at x $1C. Called twice from printscores1
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1			;skip the first string to the team name
	bsr.w	print
	move.w	#$1C,(printx).w
	move.w	tmscore(a2),d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print

PrintTeamLogoAndScore	;IDA: PrintTeamLogoAndScore?. 93: draw the team logo map (PrintTeamData, d0 = offset) 6 columns left of printx, then the score of team a2 in big font, centered 2 rows lower. Called twice from printscores1 .sbscreen
	move.w	(printx).w,-(sp)
	subq.w	#6,(printx).w
	jsr	(PrintTeamData).w
	move.w	(sp)+,(printx).w
	addq.w	#2,(printy).w
	move.w	tmscore(a2),d0
	bsr.w	PushNumber
	move.w	(a1),d0			;center on the old printx
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bra.w	printbig

EASNLogo	;IDA: DrawEASNLogo. Draw easn.map at x 1, y $19 on the vertical ice rink if no power play. Falls into DrawEASNMap
	btst	#sf2pwrplay,(sflags2).w
	bne.w	rtss
	bsr.w	printz
	String	$BF,1,$19

DrawEASNMap	;IDA: loc_F0F6. Draw the EASN logo map at the current printx/printy. Also called from stats93 ShowScores
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
	movea.w	#(hmtmstruct-M68K_RAM),a2	;IDA hid this in the string
	bsr.w	.dispen
	bsr.w	printz
	String	$BE,5,8
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize; IDA hid this in the string
	bsr.w	.dispen
	movem.l	(sp)+,d0-d7/a0-a3
	rts

.dispen	lea	$9A(a2),a0		;IDA: USBoard_dispen. penalty box list of team a2. 93 prints the players with tmpdst bit 14 clear first, then those with it set
.l1	clr.w	d0			;IDA: loc_F154
	move.b	(a0)+,d0
	bmi.w	.p2			;end of list
	btst	#6,tmpdst(a2,d0.w)		;tmpdst high byte bit 6
	bne.s	.l1
	bsr.w	pplpen
	bra.s	.l1
.p2	lea	$9A(a2),a0		;IDA: loc_F16A
.l2	clr.w	d0			;IDA: loc_F16E
	move.b	(a0)+,d0
	bmi.w	rtss
	btst	#6,tmpdst(a2,d0.w)
	beq.s	.l2
	bsr.w	pplpen
	bra.s	.l2

pplpen	;IDA: pplpen?. Print one penalty box line: player number and time remaining. a2 = team, d0 = roster offset (player*2). Only rows up to y $A are printed; printy += 1. Called from USBoard .dispen
	cmpi.w	#$A,(printy).w
	bhi.w	rtss			;no room for more rows
	move.w	tmpdst(a2,d0.w),d2
	andi.w	#$7FF,d2		;penalty time
	movea.l	tmdata(a2),a1
	adda.w	(a1),a1
	lsr.w	#1,d0
.find	adda.w	(a1),a1			;IDA: loc_F19E. skip d0+1 roster entries (name string + 8 bytes)
	addq.w	#8,a1
	dbf	d0,.find
	clr.w	d0
	move.b	-8(a1),d0		;player number (BCD)
	move.w	(printx).w,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	bsr.w	ConverByteToDigits
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
.ok	moveq	#$F,d1			;IDA: dobar. 92 dobar is a separate routine; here it is a branch target
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
.loop	clr.w	d5			;IDA: loc_F244
	move.b	(a0,d4.w),d5		;position
	beq.w	.next			;goalie energy doesn't count
	clr.w	d3
	move.b	(a1,d5.w),d3		;player number
	asl.w	#1,d3
	addq.w	#1,d1
	add.w	tmpde-2(a2,d3.w),d0
.next	dbf	d4,.loop		;IDA: loc_F25C
	divu.w	d1,d0
	movem.l	(sp)+,d1-d5/a0-a3
	rts

AvgCline	;return d0 = average energy of current line on team a2
	movem.l	d1-d3/a0,-(sp)
	clr.l	d0
	clr.w	d1
	moveq	#5,d2
	movea.w	tmsort(a2),a0
.l0	tst.w	position(a0)			;IDA: loc_F276
	ble.w	.next
	clr.w	d3
	move.b	pnum(a0),d3
	add.w	d3,d3
	add.w	tmpde(a2,d3.w),d0
	addq.w	#1,d1
.next	adda.w	#SCstruct,a0			;IDA: loc_F28C
	dbf	d2,.l0
	tst.w	d1
	beq.w	.ex
	divu.w	d1,d0
.ex	movem.l	(sp)+,d1-d3/a0		;IDA: loc_F29C
	rts

ChkShotStat	;add to shot stat if a shot was taken. 93 also raises the crowd and counts the shot for the shooter and against the other team's goalie
	bclr	#sf2shot,(sflags2).w
	beq.w	rtss
	movem.l	d0-d1/a1-a3,-(sp)
	addi.w	#$64,(crowdlevel).w	;100
	addi.w	#$A,(CwdExciteLvl).w
	move.w	(shotplayer).w,d0
	asl.w	#7,d0			;scsize
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
.ex	movem.l	(sp)+,d0-d1/a1-a3	;IDA: loc_F2EC
	rts

loadTeamStruct	;93: return a2 = team struct of player a3, a1 = the other team's struct. Called from ChkShotStat and updateplayers
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	btst	#pfteam,pflags(a3)
	beq.w	rtss
	exg	a1,a2
	rts

SetupTeamForIntermission	;93: reset the bench, then for each team refill energy and pick the starting line: 92 Pw1 (3) for the team with more players on ice, PK1 (5) for the team with fewer, else 0. Called from Intermission
	bsr.w	ResetBench
	movea.w	#(hmtmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3
	bsr.w	.r
	exg	a2,a3			;falls in for the other team
.r	bsr.w	reenergizeteam		;IDA: restoreteams (name taken by the hockey93_01 92 restoreteams)
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

reenergizeteam	;set all players to max energy on team a2. 93 also moves players marked -3 in tmpdst to the bench (-2). Called from SetupTeamForIntermission and StartHL2 .setteam
	moveq	#$32,d0			;(MaxRos-1)*2
.0	move.w	#$1000,tmpde(a2,d0.w)	;IDA: loc_F34C
	cmpi.w	#-3,tmpdst(a2,d0.w)
	bne.w	.nb
	move.w	#-2,tmpdst(a2,d0.w)	;on bench
.nb	subq.w	#2,d0			;IDA: loc_F362
	bpl.s	.0
	rts

Intermission	;end of period junk (zamboni/stats). 93 opens the pause menu screen (item list by period, +5 in playoffs), shows the ticker scores of the other games, then the highlights. Start on either pad cuts it short. Called from PeriodOver
	bsr.s	SetupTeamForIntermission
	moveq	#$F,d0
	movea.w	#(SortCords-M68K_RAM),a0
.0	clr.w	(a0)			;IDA: _0. Xpos
	adda.w	#SCstruct,a0
	dbf	d0,.0
	move.w	(ExtraChars).w,d4
	movea.l	#ZamSprites+8,a2
	bsr.w	DoDMA_clearCallbackPointer
	move.w	#$140,(zamx).w		;320
	move.w	(gsp).w,d0
	tst.w	(OptPlayMode).w
	beq.w	.ss
	addq.w	#5,d0			;playoffs
.ss	asl.w	#2,d0			;IDA: _ss
	lea	.sslist(pc),a0
	movea.l	(a0,d0.w),a0
	bset	#sfpz,(sflags).w
	movea.l	#SetupPauseScreen,a1	;Rev A $69AA
	jsr	(InitMenuState).w
	bsr.w	GetShifter
	move.w	d1,(TickerNum).w
.top	tst.w	(TickerNum).w		;IDA: loc_F3BE
	bmi.w	.doh			;no more ticker games
	bsr.w	NewTicker2
	bsr.w	NewTicker3
	move.w	#$96,d0			;150 frames
	bsr.w	IntermissionLoop
	btst	#7,d1			;sbut
	bne.w	.clrh
	bsr.w	ClearTickerArea
	move.w	#$3C,d0			;60 frames
	bsr.w	IntermissionLoop
	btst	#7,d1			;sbut
	beq.s	.top
.clrh	bset	#sf3sbut,(sflags3).w		;IDA: loc_F3F0
.doh	bsr.w	DoHiLights		;IDA: loc_F3F6
	bclr	#sf3sbut,(sflags3).w
	bne.w	.clrz
.wait	move.w	#$1E0,d0		;IDA: loc_F404. 480 frames
	bsr.w	IntermissionLoop
	btst	#7,d1			;sbut
	bne.w	.clrz
	tst.w	(cont1team).w
	bne.s	.wait			;keep waiting while a pad is on a team
	tst.w	(cont2team).w
	bne.s	.wait
.clrz	st	(zamx).w		;IDA: loc_F420
	rts

.sslist	;IDA: _sslist. Menu item lists in hockey93_11 (Rev A + $18), by period then playoff period
	dc.l	StartGameText,IntermissionText,IntermissionText,IntermissionText,ExitGameText
	dc.l	StartGameTextPO,IntermissionText,IntermissionText,IntermissionText,ExitGameTextPO

InitScores	;initialize other games scores/period in playoffs (93 has no OptPlayMode check). Called from StartGame
	cmpi.w	#1,(gamelevel).w
	bgt.w	rtss
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#$10,d0			;gssize
	mulu.w	d1,d0
	adda.w	d0,a0
.top	cmp.w	(gamenum).w,d1		;IDA: _top
	beq.w	.next
	btst	#2,$E(a0)		;gsfso
	bne.w	.next
	clr.w	8(a0)			;gsper
	moveq	#3,d0
	bsr.w	randomd0
	bra.w	.1
.0	bsr.w	SetScore		;IDA: _0
.1	dbf	d0,.0			;IDA: _1
.next	suba.w	#$10,a0			;IDA: _next. gssize
	dbf	d1,.top
	rts

UpdateScores	;update ticker score values. Called from PeriodOver
	bsr.w	GetShifter
	move.w	d1,(TickerNum).w
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#$10,d0			;gssize
	mulu.w	d1,d0
	adda.w	d0,a0
.top	cmp.w	(gamenum).w,d1		;IDA: _top
	beq.w	.next
	bclr	#1,$E(a0)		;gsfhl
	btst	#2,$E(a0)		;gsfso
	bne.w	.next
	bsr.w	SetScore
.next	suba.w	#$10,a0			;IDA: _next. gssize
	dbf	d1,.top
	rts

SetScore	;add to score for game in a0. After period 3 a game within one goal goes to OT (gsper 3) and asks for a highlight
	cmpi.w	#4,8(a0)		;gsper
	bge.w	rtss
	movem.l	d0-d1/a0-a1,-(sp)
	cmpi.w	#3,8(a0)
	bne.w	.0
	move.w	#5,8(a0)		;final
	move.w	$A(a0),d0		;gss1
	sub.w	$C(a0),d0		;gss2
	cmp.w	#1,d0
	bgt.w	.ex
	cmp.w	#-1,d0
	blt.w	.ex
	move.w	#3,8(a0)		;close game: overtime
	bset	#1,$E(a0)		;gsfhl
	bra.w	.ex
.0	addq.w	#1,8(a0)		;IDA: loc_F516
	move.w	(a0),d0			;gst1
	move.w	2(a0),d1		;gst2
	bsr.w	.getscore
	add.w	d0,$A(a0)		;gss1
	move.w	2(a0),d0
	move.w	(a0),d1
	bsr.w	.getscore
	add.w	d0,$C(a0)		;gss2
.ex	movem.l	(sp)+,d0-d1/a0-a1	;IDA: loc_F536
	rts

.getscore	asl.w	#2,d0			;IDA: SetScore_getscore. d0 = scoring team, d1 = other team. 93 adds the scoring team's (bits 4-6) and the other team's (bits 0-2) .sctab rows as weights. Return d0 = goals 0-3
	movea.w	#$314,a1		;team address table
	movea.l	(a1,d0.w),a1
	adda.w	8(a1),a1		;92 ScoreOdds
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

.sctab	;IDA: sctab. Weights for 0, 1, 2, 3 goals (92 had 4 percent bytes per row)
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

NewTicker2	;goto next ticker. Return d3 = game, or neg if none left (93 has no OptPlayMode check). Falls into CheckGameTickerStatus
	move.w	(TickerNum).w,d3
	bmi.w	rtss
	subq.w	#1,(TickerNum).w
	cmp.w	(gamenum).w,d3		;don't show current game as ticker
	beq.s	NewTicker2

CheckGameTickerStatus	;93 split from 92 NewTicker3. d3 = game. Return a0 = its gstruct; skip to the next ticker game if a highlight is coming up or the series is over. Called from StartHL2
	moveq	#$10,d0			;gssize
	mulu.w	d3,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	btst	#1,$E(a0)		;gsfhl
	bne.s	NewTicker2		;don't show if hilite coming up
	btst	#2,$E(a0)		;gsfso
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
.gl	lea	GameLabels(pc),a1	;IDA: loc_F662
	bsr.w	PrintStringFromList
	move.w	8(a0),d0		;gsper
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
	move.w	$C(a0),d1		;gss2
	bsr.w	.tn
	move.w	(a0),d0			;gst1
	move.w	$A(a0),d1		;gss1
	bsr.w	.tn
	addq.w	#2,sp
	rts

.tn	move.w	4(sp),(printx).w	;IDA: NewTicker3_tn. print team d0 name and score d1 on the next row
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

ClearTickerArea	;93: erase the ticker box. Called from Intermission and StartHL2
	bsr.w	SetTickerAreaPosition
	move.w	#$7FF,d2		;blank char
	bra.w	eraser

SetTickerAreaPosition	;93: set printx/printy/printm for the ticker box (x 3, y $17; the $BD map in pause mode). Return d0 = $1A wide, d1 = 5 high. Called from NewTicker3 and ClearTickerArea
	bsr.w	printz
	String	$BD,3,$17
	btst	#sfpz,(sflags).w
	bne.w	.1
	bsr.w	printz
	String	$BF,3,$17
.1	moveq	#$1A,d0			;IDA: loc_F756
	moveq	#5,d1
	rts

PrintStringFromList	;93: print string d0 of the String list a1 with printsmall
	bsr.w	AdvanceStringPtr
	bra.w	printsmall

AdvanceStringPtr	;93: 92 Fprint without the print. Return a1 = string d0 of the String list a1
	bra.w	.1
.0	adda.w	(a1),a1			;IDA: loc_F768
.1	dbf	d0,.0			;IDA: loc_F76A
	rts

DoHiLights	;hilites logic: search for hilite game and show hilite (93 has no OptPlayMode check). Called from Intermission
	bsr.w	GetShifter
	moveq	#$10,d3			;gssize
	mulu.w	d1,d3
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d3,a0
.top	btst	#2,$E(a0)		;IDA: _top. gsfso
	bne.w	.next
	bclr	#1,$E(a0)		;gsfhl
	beq.w	.next
	bsr.w	StartHL
.next	suba.w	#$10,a0			;IDA: _next. gssize
	dbf	d1,.top
	rts

StartHL	movem.l	d0-d7/a0-a6,-(sp)	;play hilite for game a0, d1 = game. Called from DoHiLights. Falls into StartHL2
StartHL2	;play hilite for game a0. Start skips it with a random result. A tied game is replayed (beq StartHL2)
	btst	#sf3sbut,(sflags3).w
	bne.w	.nhl0
	bsr.w	.sv
	move.w	d1,d3
	bsr.w	CheckGameTickerStatus
	bsr.w	NewTicker3		;show score from hilight game
	btst	#sf3sbut,(sflags3).w
	bne.w	.nhl1
	move.w	#4,(printx).w
	subq.w	#6,(printy).w
	moveq	#$18,d0			;24
	moveq	#3,d1
	bsr.w	Framer
	addq.w	#1,(printx).w
	subq.w	#2,(printy).w
	bsr.w	printz
	String	'Highlight from game:'
	move.w	#$B4,d0			;180 frames
	bsr.w	IntermissionLoop
	btst	#7,d1			;sbut
	bne.w	.nhl1
	st	(zamx).w
	clr.w	(CwdExciteLvl).w
	move.w	(a0),(HomeTeam).w	;set up teams for game in a0
	move.w	2(a0),(VisTeam).w
	move.l	a0,-(sp)
	clr.w	(hmtmstruct+tmgoalie).w
	clr.w	(awtmstruct+tmgoalie).w
	jsr	(clearTeamStats).l
	jsr	(restoreteams).w	;IDA: InitTeamShots
	st	(c1playernum).w
	st	(c2playernum).w
	clr.w	(cont1team).w
	clr.w	(cont2team).w
	moveq	#$78,d0			;120
	bsr.w	randomd0
	addi.w	#$3C,d0			;60
	move.w	d0,(gameclock).w
	movea.l	(sp),a0
	move.w	8(a0),(gsp).w		;gsper
	subq.w	#1,(gsp).w
	move.w	$A(a0),(hmtmstruct+tmscore).w	;gss1
	move.w	$C(a0),(awtmstruct+tmscore).w	;gss2
	move.b	#$10,(gmode).w		;1<<gmhl
	btst	#0,(gsp+1).w
	beq.w	.ndi
	bset	#gmdir,(gmode).w
.ndi	clr.b	(sflags).w		;IDA: StartHL2_ndi
	move.b	#4,(sflags2).w		;1<<sf2drec
	clr.b	(sflags3).w
	bclr	#4,(disflags).w		;93 only
	bset	#dfclock,(disflags).w
	clr.w	(glovecords).w
	clr.b	(iflags).w
	st	(RefCnt).w
	st	(puckcross+2).w
	st	(puckcross+6).w
	jsr	p_turnoff
	bsr.w	setupice_highlight
	bsr.w	ClrHor
	movea.l	#VDP_DATA,a0
	move.w	#$9100,4(a0)		;window H position 0
	move.w	#$9200,4(a0)		;window V position 0
	move.w	(ExtraChars).w,d4	;ref cam chars
	movea.l	#RefsMap+8,a2
	bsr.w	DoDMA_clearCallbackPointer
	clr.w	(Vpos).w
	clr.w	(Hpos).w
	bsr.w	ResetBench
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	.setteam
	adda.w	#tmsize,a2
	bsr.w	.setteam
	bsr.w	resetplstuff
	moveq	#$B,d0
	movea.l	#.postab,a0
	movea.w	#(SortCords-M68K_RAM),a1
.ploop	move.w	position(a1),d1		;IDA: loc_F904
	btst	#pfgoal,pflags(a1)
	bne.w	.pl0
	addq.w	#6,d1
.pl0	asl.w	#2,d1			;IDA: loc_F914
	move.w	(a0,d1.w),(a1)		;Xpos
	move.w	2(a0,d1.w),Ypos(a1)
	clr.w	Xvel(a1)
	clr.w	Yvel(a1)
	adda.w	#SCstruct,a1
	dbf	d0,.ploop
	bsr.w	SprSort
	move.w	#$18,(palcount).w	;24
	move.w	(vcount).w,(oldvcount).w
	move.w	#$B4,-(sp)		;180 frames after the clock stops
.0	jsr	(DoGameFrame).w		;IDA: loc_F944. 93 DoGameFrame waits for the vblank (92 inline)
	btst	#gmclock,(gmode).w
	beq.w	.1
	subq.w	#1,(sp)
	bmi.w	.endhl
.1	bsr.w	orjoy			;IDA: loc_F958
	btst	#5,d1			;cbut
	bne.w	.eh
	btst	#7,d1			;sbut
	beq.s	.0
.eh	move.w	(hmtmstruct+tmscore).w,d0	;IDA: loc_F96A. tied: random winner
	cmp.w	(awtmstruct+tmscore).w,d0
	bne.w	.endhl
	move.w	(VDP_CNTR).l,d0		;hvcount
	andi.w	#1,d0
	add.w	d0,(hmtmstruct+tmscore).w
	eori.w	#1,d0
	add.w	d0,(awtmstruct+tmscore).w
.endhl	addq.w	#2,sp			;IDA: loc_F98C
	movea.l	(sp)+,a0
	movem.l	d1/a0,-(sp)
	jsr	KillCrowd
	jsr	p_turnoff
	movem.l	(sp)+,d1/a0
	move.w	(hmtmstruct+tmscore).w,$A(a0)	;gss1
	move.w	(awtmstruct+tmscore).w,$C(a0)	;gss2
	bsr.w	forceblack
	moveq	#$F,d0
	movea.w	#(SortCords-M68K_RAM),a0
.clr	clr.w	(a0)			;IDA: loc_F9BA. Xpos
	adda.w	#SCstruct,a0
	dbf	d0,.clr
	bsr.w	.lo
	bsr.w	setplayercolors
	bsr.w	SetHor
	bsr.w	setvideo
	jsr	(SetupPauseScreen).w	;93: pause menu screen (92 DisplayStats)
	jsr	(DrawMenuScreen).w
	move.w	#$18,(palcount).w	;24
	move.w	#$36,-(sp)		;song $36
	bsr.w	song
	movem.l	(sp),d0-d7/a0-a6
	move.w	#4,8(a0)		;gsper: OT
	move.w	$A(a0),d0		;gss1
	cmp.w	$C(a0),d0		;gss2
	beq.w	StartHL2		;still tied: play another hilite
	move.w	#5,8(a0)		;final
	move.w	d1,d3
	bsr.w	CheckGameTickerStatus
	bsr.w	NewTicker3
	move.w	#$B4,d0			;180 frames
	bsr.w	IntermissionLoop
	btst	#7,d1			;sbut
	bne.w	.exit2
	bsr.w	ClearTickerArea
	move.w	#$3C,d0			;60 frames
	bsr.w	IntermissionLoop
	btst	#7,d1			;sbut
	beq.w	.exit
.exit2	bset	#sf3sbut,(sflags3).w		;IDA: exit2
.exit	movem.l	(sp)+,d0-d7/a0-a6	;IDA: exit
	rts
.nhl1	bsr.w	.lo			;IDA: loc_FA40
	bsr.w	.ranres
	bra.s	.exit2
.nhl0	bsr.w	.ranres			;IDA: loc_FA4A
	bra.s	.exit

.setteam	jsr	(reenergizeteam).l	;IDA: SetupTeamForReplay. 92 setpersonel / forcepldata per team; 93 refills energy first and sets $18/$1A/$1C(a2)
	bsr.w	setpersonel
	bsr.w	forcepldata
	st	$18(a2)
	st	$1A(a2)
	st	$1C(a2)
	rts

.ranres	move.w	$A(a0),d0		;IDA: StartHL2_ranres. random resolve of game (if tied = random score)
	cmp.w	$C(a0),d0
	bne.w	.rr0
	move.w	(VDP_CNTR).l,d0		;hvcount
	andi.w	#1,d0
	add.w	d0,$A(a0)
	eori.w	#1,d0
	add.w	d0,$C(a0)
.rr0	move.w	#5,8(a0)		;IDA: loc_FA8E. gsper: final
	rts

.sv	move.w	#$37E,d0		;IDA: StartHL2_sv. save $37F words from gmode to ReplayStart (92 ((gstruct-gmode)/2)-1)
	movea.w	#(gmode-M68K_RAM),a1
	movea.l	#M68K_RAM,a2		;ReplayStart
.sv1	move.w	(a1)+,(a2)+		;IDA: StartHL2_sv1
	dbf	d0,.sv1
	move.w	(ScoreSumbytes).w,(a2)+	;93 also saves ScoreSumbytes
	rts

.lo	move.w	#$37E,d0		;IDA: StartHL2_lo. restore what .sv saved
	movea.w	#(gmode-M68K_RAM),a2
	movea.l	#M68K_RAM,a1		;ReplayStart
.lo1	move.w	(a1)+,(a2)+		;IDA: StartHL2_lo1
	dbf	d0,.lo1
	move.w	(a1)+,(ScoreSumbytes).w
	rts

.postab	;IDA: _postab. Xpos,Ypos by position (goalie, l.def, r.def, l.wing, center, r.wing), pfgoal set, then clear
	dc.w	0,-240,-70,-140,20,-110,-100,-60,25,-40,70,-80
	dc.w	0,240,34,90,-55,80,100,40,-10,10,-50,0
