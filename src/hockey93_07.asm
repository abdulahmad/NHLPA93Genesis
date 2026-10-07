;	NHLPA Hockey 93 (retail) segment $12E26-$13951
;	93 screens that follow 92 hockey.asm part 3: ScoutingReport (rewritten for 93:
;	team ratings and a typed commentary), the Stanley Cup celebration screen,
;	TitleScreen with its credits scroller and vblank, the sprite list helpers
;	CallAnimationCallback / EndSpriteList / FinalizeSpriteList, and an
;	unreferenced sound test (CheckSound). setoptions is hockey93_08.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	92 bit names used in comments, same values in 93: disflags 1 df32c, 2 dfng;
;	pad bits dbut 1, lbut 2, rbut 3, cbut 5, abut 6, sbut 7.
;	printz strings: first byte -$ab = map/attribute code (92 String -$01 = $FF),
;	then x, y. printsmallz codes: $F8 attribute,map,x,y; $F9 char set; $FC y; $FD x.
;	DecompressGraphicsWithCallback is followed by its 8 byte remap table.

ScoutingReport	;93 pregame scouting report (92 drew ScoutMap and position check marks). Called from PeriodOver.
	;Draws both team blocks, the Ron Barr picture and the scouting report ratings, then types out
	;the commentary paragraphs listed in TestList. Returns on start, or when screentimer runs out ($1E0 after the text ends)
	move.w	#$37,-(sp)		;song $37
	bsr.w	song
	move.l	#vb2,(vbint).w
	bsr.w	clearTeamStats		;93: (92 bsr SetTeams)
	bclr	#df32c,(disflags).w
	move.w	#6,(Map1col).w
	move.w	#6,(Map2col).w
	move.w	#0,d0			;fade to color
	bsr.w	setVram

	bsr.w	AddTeamBlock
	bsr.w	AddSmallFont
	move.w	d4,(smallfont2chars).w	;1st vram char of the 2nd small font set
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$0A234567,$89ABCDEF	;remap table (retail; IDA eori.b / or.l)
	bsr.w	AddFramer

	bsr.w	printz
	String	$FE,0,0			;(92 -$02,0,0)
	movea.l	#ScoutMap,a0		;bitmap map data (Rev A $3288E, same as PlayoffScreen)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2			;40 x 28
	moveq	#$1C,d3
	moveq	#3,d5			;color fam 1-2
	bsr.w	dobitmap

	bsr.w	printz
	String	$FE,6,3
	moveq	#$21,d0			;33 x 9 frame
	moveq	#9,d1
	bsr.w	Framer

	bsr.w	printz
	String	$FF,1,1
	movea.l	#Ronbarrmap,a0		;Ron Barr picture: palette offset, then map header offset
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0		;a0 = palette
	adda.l	(a2)+,a1		;a1 = map header
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2			;width and height from the map header
	move.w	2(a1),d3
	moveq	#$C,d5			;color fam 3-4
	bsr.w	dobitmap

	bsr.w	printz
	String	$FF,3,$D		;(92 -$01,3,6)
	move.w	(VisTeam).w,d1
	bsr.w	dotb	;92 DoTb

	bsr.w	printz
	String	$FF,$18,$D		;(92 -$01,24,6)
	move.w	(HomeTeam).w,d1
	bsr.w	dotb

	bsr.w	printsmallz
	String	$F8,0,1,$15,$F,$F9,1	;attribute 0, map 1, x $15, y $F, char set 1
	lea	StatsText(pc),a1	;rating names (92 .pnm position names)
.pl	move.w	(a1),d0			;IDA: loc_12F22+2
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$15,d0			;center on column 21
	move.w	d0,(printx).w
	bsr.w	printsmall
	addq.w	#1,(printy).w
	eori.w	#2,(printfontset).w	;alternate char set each line
	tst.w	(a1)
	bpl.s	.pl			;-1 ends the list

	bsr.w	printsmallz
	String	$FD,$1D,$FC,$F,$F9	;x $1D, y $F, char set 0 (pad byte)
	movea.l	(HomeTeamRosterPtr).w,a0
	adda.w	8(a0),a0		;a0 = home scouting report bytes
	movea.l	(AwayTeamRosterPtr).w,a2
	adda.w	8(a2),a2		;a2 = away scouting report bytes
	bsr.w	DisplayPlayerStats	;home ratings at x $1D
	bsr.w	printsmallz
	String	$FD,7,$FC,$F,$F9	;x 7, y $F, char set 0 (pad byte)
	exg	a0,a2
	bsr.w	DisplayPlayerStats	;away ratings at x 7

	move.w	#$18,(palcount).w	;24
	move.l	#vb2,(vbint).w
	move	#$2500,sr

	bsr.w	InitScoutingDisplay	;a0 = TestList
	move.w	#$1A,(a0)+		;paragraph numbers into ScoutingReportText
	move.w	#$1B,(a0)+
	move.w	#$1D,(a0)+
	move.w	(HomeTeam).w,d0
	move.w	d0,(a0)+		;home team paragraph
	move.w	#$1D,(a0)+
	cmp.w	(VisTeam).w,d0
	beq.w	.same			;same team, one paragraph
	move.w	(VisTeam).w,(a0)+	;visiting team paragraph
.same	move.w	#$1D,(a0)+		;IDA: loc_12FAE
	move.w	#$1C,(a0)+
	move.w	#$FFFF,(a0)		;end of list
	clr.w	(asv).w			;fast text flag
	move.w	#$7FFF,(screentimer).w	;frames left on the screen

.top	moveq	#0,d0			;IDA: loc_12FC4
	bsr.w	waitx			;d1 = new presses
	btst	#7,d1			;sbut
	bne.w	rtss			;start leaves
	btst	#1,d1			;dbut
	beq.w	.upd
	st	(asv).w			;down: type the rest without delays
.upd	bsr.w	UpdateScoutingDisplay	;IDA: loc_12FDE
	subq.w	#1,(screentimer).w
	bpl.s	.top
	rts

DisplayPlayerStats	;93: print the 8 rating nibbles of the scouting report long at 4(a0), one per line, at printx.
	;a0 = this team's scouting report, a2 = the other team's (for the combined line). Called from ScoutingReport
	move.l	4(a0),d5		;bytes 4-7: shooting/skating, passing/defense, checking/fighting, goalkeeping/overall
	moveq	#7,d6
.loop	eori.w	#2,(printfontset).w	;IDA: loc_12FF0. alternate char set each line
	rol.l	#4,d5			;next nibble
	move.w	d5,d0
	andi.w	#$F,d0
	bsr.w	PrintStatNumber
	cmp.w	#1,d6
	bne.w	.next
	bsr.w	DisplayCombinedStats	;after goalkeeping: power play and home team lines
.next	dbf	d6,.loop		;IDA: loc_1300E
	rts

DisplayCombinedStats	;93: print the power play line (byte 1 low nibble of a0 + byte 1 high nibble of a2), and on the right
	;column (printx >= $14) the home team line (byte 2 high nibble of a0 + low nibble of a2). Falls into PrintStatNumber
	eori.w	#2,(printfontset).w
	move.w	(a0),d0
	andi.w	#$F,d0
	move.w	(a2),d1
	lsr.w	#4,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bsr.w	PrintStatNumber
	eori.w	#2,(printfontset).w
	cmpi.w	#$14,(printx).w
	blt.w	StatNextLine		;left column: skip the home team line
	move.b	2(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	move.b	2(a2),d1
	andi.w	#$F,d1
	add.w	d1,d0

PrintStatNumber	;93: print d0 as a 2 digit number at printx/printy in the small font, then move down a line.
	;Called from DisplayPlayerStats, falls in from DisplayCombinedStats
	moveq	#2,d1			;2 digits
	bsr.w	PushNumberWidth
	move.w	(printx).w,-(sp)
	bsr.w	printsmall
	move.w	(sp)+,(printx).w
StatNextLine	;IDA: loc_13064. Next line; branched to from DisplayCombinedStats
	addq.w	#1,(printy).w
	rts

StatsText	;93: rating names for the scouting report, centered by ScoutingReport. -1 ends the list
	String	'Shooting'
	String	'Skating'
	String	'Passing'
	String	'Defense'
	String	'Checking'
	String	'Fighting'
	String	'Goalkeeping'
	String	'Power Play Adv.'
	String	'-    Home Team Adv.    '
	String	'Overall'
	dc.w	-1

InitScoutingDisplay	;93: reset the scouting text scroller. Return a0 = TestList (paragraph list). Called from ScoutingReport
	move.w	#$FFFF,(VertLineScrolling).w	;text line -1
	st	(PlayerScrollCtr).w	;negative: start the next paragraph
	clr.w	(SelectedPlayerIdx).w	;TestList index
	clr.w	(ScoutingReportTimer).w
	movea.w	#(TestList-M68K_RAM),a0
	rts

UpdateScoutingDisplay	;93: called every frame by ScoutingReport. When ScoutingReportTimer runs out (at once if asv
	;is set), print the next word of ScoutingReportText. '_' '{' '}' '[' ']' print a team or player name.
	;PlayerScrollCtr = offset of the next word (negative: next paragraph), DispAttribCtr = column
	cmpi.w	#$1000,(ScoutingReportTimer).w
	bgt.w	rtss			;text finished ($7FFF)
	tst.w	(asv).w
	bmi.w	.go			;fast: no delay
	subq.w	#1,(ScoutingReportTimer).w
	bpl.w	rtss
.go	movea.l	#ScoutingReportText,a1	;IDA: loc_1311E
	move.w	(PlayerScrollCtr).w,d0
	bpl.w	.cont			;in a paragraph
	clr.w	(DispAttribCtr).w	;column 0
	move.w	(SelectedPlayerIdx).w,d0
	addq.w	#2,(SelectedPlayerIdx).w
	movea.w	#(TestList-M68K_RAM),a0
	move.w	(a0,d0.w),d0		;next paragraph number
	bpl.w	.para
	move.w	#$7FFF,(ScoutingReportTimer).w	;end of list: stop typing
	move.w	#$1E0,(screentimer).w	;and leave the screen in 480 frames
	rts
.para	bsr.w	ScrollDisplayUp		;IDA: loc_13152. blank line between paragraphs
	movea.l	a1,a2
	bra.w	.cnt
.find	cmpi.b	#$D,(a2)+		;IDA: loc_1315C. skip one $D ended paragraph
	bne.s	.find
.cnt	dbf	d0,.find		;IDA: loc_13162
	suba.l	a1,a2
	move.w	a2,d0			;d0 = paragraph offset
.cont	lea	(a1,d0.w),a2		;IDA: loc_1316A
	move.w	#$A,(ScoutingReportTimer).w	;10 frames per word
	move.w	(DispAttribCtr).w,d0
	cmpi.b	#$5F,(a2)		;'_'
	beq.w	.under
	cmpi.b	#$7B,(a2)		;'{' home team name
	beq.w	.home
	cmpi.b	#$7D,(a2)		;'}' away team name
	beq.w	.away
	cmpi.b	#$5B,(a2)		;'[' home player name
	beq.w	.hmtm
	cmpi.b	#$5D,(a2)		;']' away player name
	beq.w	.awtm
	st	(PlayerScrollCtr).w	;assume end of paragraph
	movea.w	#(TextBuffer-M68K_RAM),a0
	clr.w	d1			;word length
.word	cmpi.b	#$D,(a2)		;IDA: loc_131AA
	beq.w	.eol			;end of paragraph
	addq.w	#1,d0
.copy	move.b	(a2),(a0)+		;IDA: loc_131B4. copy the word and its trailing spaces
	addq.w	#1,d1
	cmpi.b	#$2C,(a2)		;','
	beq.w	.pause
	cmpi.b	#$2E,(a2)		;'.'
	bne.w	.nopause
.pause	addi.w	#$28,(ScoutingReportTimer).w	;IDA: loc_131C8. 40 more frames after punctuation
.nopause	cmpi.b	#$20,(a2)+		;IDA: loc_131CE
	bne.s	.word
	cmpi.b	#$20,(a2)
	beq.s	.copy
	subq.w	#1,d0
	suba.w	a1,a2
	move.w	a2,(PlayerScrollCtr).w	;offset of the next word
.eol	move.w	d1,(mesarea).w		;IDA: loc_131E2. make a String at mesarea
	addq.w	#2,(mesarea).w
	btst	#0,d1
	beq.w	.even
	clr.b	(a0)			;pad
	addq.w	#1,(mesarea).w
.even	movea.w	#(mesarea-M68K_RAM),a1	;IDA: loc_131F8
.print	cmp.w	#$1D,d0			;IDA: loc_131FC. past column 29?
	ble.w	.noscr
	bsr.w	ScrollDisplayUp		;wrap to a new line
.noscr	bsr.w	printz			;IDA: loc_13208
	String	$FF,9,4
	move.w	(DispAttribCtr).w,d0
	add.w	d0,(printx).w		;x 9 + column
	move.w	(VertLineScrolling).w,d0
	add.w	d0,(printy).w		;y 4 + text line
	bsr.w	print
	add.w	d1,(DispAttribCtr).w
	rts
.awtm	movea.w	#(awtmstruct-M68K_RAM),a1	;IDA: loc_1322C
	bra.w	.team
.hmtm	movea.w	#(hmtmstruct-M68K_RAM),a1	;IDA: loc_13234
.team	move.w	tmgoalie(a1),d1		;IDA: loc_13238. goalie's roster index
	movea.l	tmdata(a1),a1
	adda.w	(a1),a1			;player data
	bra.w	.pn
.pl	adda.w	(a1),a1			;IDA: loc_13246. skip name and 8 bytes of ratings
	addq.w	#8,a1
.pn	dbf	d1,.pl			;IDA: loc_1324A
	bra.w	.name
.away	movea.l	(AwayTeamRosterPtr).w,a1	;IDA: loc_13252
	bra.w	.tname
.under	movea.l	#Montreal,a1		;IDA: loc_1325A. TeamData93 team block
	cmpi.w	#$18,(hmtmstruct+tmgoalie+2).w
	bge.w	.tname			;used when >= $18
.home	movea.l	(HomeTeamRosterPtr).w,a1	;IDA: loc_1326A
.tname	adda.w	4(a1),a1		;IDA: loc_1326E. team name
.name	addq.w	#1,(PlayerScrollCtr).w	;IDA: loc_13272. step past the escape char
	add.w	(a1),d0
	subq.w	#1,d0
	move.w	(a1),d1
	subq.w	#2,d1			;d1 = chars
	tst.b	1(a1,d1.w)
	bne.w	.print
	subq.w	#1,d1			;less the pad byte
	bra.w	.print

ScrollDisplayUp	;93: next text line for UpdateScoutingDisplay (column 0). After line 7, move the text box up
	;one row (DoDMA_nd2 copies 8 rows of $3A from VmMap1+$212, rows $80 apart) and stay on the last line
	clr.w	(DispAttribCtr).w
	addq.w	#1,(VertLineScrolling).w
	cmpi.w	#7,(VertLineScrolling).l
	blt.w	rtss
	subq.w	#1,(VertLineScrolling).w
	movem.l	d0-d3,-(sp)
	move.l	#7,d3
	move.w	(VmMap1).w,d1
	addi.w	#$212,d1		;text box top left
.loop	move.l	#$3A,d0			;IDA: loc_132B6
	move.w	d1,d2
	addi.w	#$80,d2			;from the row below
	bsr.w	DoDMA_nd2		;vram copy d2 -> d1
	move.w	d2,d1
	dbf	d3,.loop
	movem.l	(sp)+,d0-d3
	rts

SetupStanleyCupCelebrationScreen	;93: Stanley Cup screen. Five EASN bitmaps at StanleyCupPosTable with
	;StanleyMap sprites over them, $50 x 4 frames or until a button. Called from Begin+22
	move.l	#VBlank_StanleyCup,(vbint).l
	bclr	#df32c,(disflags).w
	move.w	#5,(Map3col).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d1
.clr	clr.l	(a0)+			;IDA: loc_13318. black palettes
	dbf	d1,.clr
	bsr.w	CopyPaletteToCRAM
	bsr.w	setVram_0

	bsr.w	printz
	String	$FE,0,0			;(IDA hid the lea in this string)
	lea	StanleyCupPosTable(pc),a4
.top	move.w	(a4)+,(printx).w	;IDA: loc_13332+2
	move.w	(a4)+,(printy).w
	movea.l	#EASNmap2,a0
	movea.l	a0,a1
	adda.l	(a0),a0			;palette
	adda.l	4(a1),a1		;map header
	movea.w	#$310,a2		;a zero word (92 passed #null): no tiles
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d4
	moveq	#$F,d5			;color fam 1-4
	bsr.w	dobitmap
	tst.w	(a4)
	bpl.s	.top
	movea.l	#EASNmap2+8,a2
	clr.w	d4			;tiles at vram char 0
	bsr.w	DoDMA_clearCallbackPointer
	movea.l	#Stanleymap+8,a2
	move.w	d4,(energybarchars).w	;1st vram char of the cup sprites
	bsr.w	DoDMA_clearCallbackPointer
	bsr.w	UpdateStanleyCupAnimation
	move.w	#$18,(palcount).w	;24
	move	#$2500,sr
	move.w	#$50,(StanleyCupTimer).w
.wait	moveq	#4,d0			;IDA: loc_13392
	bsr.w	waitx
	tst.w	d1
	bne.w	.ex			;any button
	bsr.w	UpdateStanleyCupAnimation
	subq.w	#1,(StanleyCupTimer).w
	bpl.s	.wait
.ex	move	#$2700,sr		;IDA: loc_133A8
	rts

UpdateStanleyCupAnimation	;93: one StanleyMap sprite at each StanleyCupPosTable spot, frame 1 + asv (0-7), then
	;close the sprite list. Called from SetupStanleyCupCelebrationScreen
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6			;link counter
	addq.w	#1,(asv).w
	andi.w	#7,(asv).w
	movea.l	#StanleyMap,a0
	lea	StanleyCupPosTable(pc),a4
	move.w	(energybarchars).w,d3
.top	move.w	(a4)+,d0		;IDA: loc_133CC
	asl.w	#3,d0
	addi.w	#$58,d0			;x = column * 8 + $58
	move.w	(a4)+,d1
	asl.w	#3,d1
	addi.w	#$38,d1			;y = row * 8 + $38
	moveq	#1,d2
	add.w	(asv).w,d2
	bsr.w	SetSframe
	tst.w	(a4)
	bpl.s	.top
	bra.w	EndSpriteList

VBlank_StanleyCup	;IDA: loc_133EE. 93: vbint handler for the Stanley Cup screen: sprite table dma, cramfade, vcount
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.x
	move.w	(Sattsize).w,d0
	beq.w	.nos
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	movea.w	#(Satt-M68K_RAM),a0
	bsr.w	DoDMA
.nos	bsr.w	cramfade		;IDA: loc_13414
.x	addq.w	#1,(vcount).w		;IDA: loc_13418
	movem.l	(sp)+,d0-d7/a0-a6
	rte

StanleyCupPosTable	;IDA: unk_13422. 93: column, row of the five Stanley Cup bitmaps and sprites. -1 ends
	dc.w	3,1
	dc.w	$1C,1
	dc.w	$10,9
	dc.w	3,$12
	dc.w	$1C,$12
	dc.w	-1

TitleScreen	;bring up title screen and credits. Called from PeriodOver.
	;93: Titlemap backdrop, three Title3map sprites, Titlemap2 logo sprites, scrolling credits. Start leaves
	move.w	#$35,-(sp)		;song $35 (92 SngTitle = 1)
	bsr.w	song
	move.w	(VDP_CNTR).l,(StanleyCupTimer).w	;seed randomd0 from the H/V counter
	move.w	(VDP_CNTR).l,(StanleyCupTimer+2).w
	move.l	#VBlank_TitleScreen,(vbint).l
	bset	#df32c,(disflags).w
	move.w	#5,(Map3col).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	move.w	#0,d0			;fade to color
	bsr.w	setVram
	movea.l	#VDP_DATA,a0
	move.w	#$9100,4(a0)		;window h position 0
	move.w	#$9216,4(a0)		;window v position 22 (92 $9200+22)
	move.w	#$8B03,4(a0)		;h scroll by line
	clr.w	(Vscroll).w

	bsr.w	printz
	String	$FF,0,0			;(92 -$01,0,0)
	move.l	#$80,d0			;128 x 32
	moveq	#$20,d1
	move.l	#$7FF,d2		;(92 moveq #1,d2)
	bsr.w	eraser

	bsr.w	printz
	String	$FE,0,0
	move.l	#$80,d0
	moveq	#$20,d1
	move.l	#$7FF,d2
	bsr.w	eraser

	clr.w	d4
	bsr.w	printz
	String	$FE,0,$16
	movea.l	#Title1Map,a1		;rows $16 down of Titlemap, map only
	adda.l	4(a1),a1
	movea.w	#$310,a2		;a zero word (92 passed #null): no tiles
	clr.w	d0
	moveq	#$16,d1
	move.w	(a1),d2
	move.w	2(a1),d3
	sub.w	d1,d3
	moveq	#0,d5			;no palettes
	bsr.w	dobitmap

	bsr.w	printz
	String	$FD,0,0			;(92 -$02,0,0 Title1Map)
	movea.l	#Title1Map,a0		;whole Titlemap with palettes (retail; IDA $2F0DE Rev A)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#$F,d5			;color fam 1-4
	bsr.w	dobitmap

	clr.w	(palfadenew).w
	moveq	#4,d0
	bsr.w	randomd0
	asl.w	#5,d0
	lea	TitleData2(pc),a1	;one of 4 random palettes
	adda.w	d0,a1
	movea.w	#(titleScreenState-M68K_RAM),a0
	moveq	#7,d0
.tops0	move.l	(a1)+,(a0)+		;IDA: _tops0
	dbf	d0,.tops0

	bsr.w	printz
	String	$FE,0,$A
	movea.l	#Title2Map,a1		;bitmap (Rev A $312B6)
	lea	8(a1),a2
	adda.l	4(a1),a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#0,d5			;no palettes
	bsr.w	dobitmap

	movea.l	#TitleLogoSprites+8,a2
	move.w	d4,(energybarchars).w	;1st vram char of the logo sprites
	bsr.w	DoDMA_clearCallbackPointer
	movea.l	#Title3Sprites+8,a2
	move.w	d4,(gamesetuptilesetindex).w	;1st vram char of the Title3map sprites
	bsr.w	DoDMA_clearCallbackPointer
	clr.l	(fofdata2).w		;TitleAnimCallback timers
	clr.w	(fofdata2+4).w
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$08F04567,$89ABCDEF	;remap table (retail; IDA #$67 / or.l)

	bsr.w	printz
	String	$FF,0,0
	movea.l	#Credits,a1		;copyright lines
	bsr.w	.top4
	addi.w	#$20,(Vscroll).w
	move.w	#$104,(clampcounter).w	;FinalizeSpriteList logo slide in
	move.w	#$120,(playoffspritex).w	;logo x
	move.w	#$D0,(playoffspritey).w	;logo y
	clr.w	(asv).w
	move.w	#$FFCE,(DispAttribCtr).w	;Hscroll speed (UpdateHorizontalScroll)
	move.w	#$20,(palcount).w
	move	#$2500,sr

.top1	bsr.w	TitleScreen_wait	;IDA: _top1. wait for the logo
	tst.w	(clampcounter).w
	bne.s	.top1

	move.w	#$3C,d3			;1 second
.tops	bsr.w	TitleScreen_wait	;IDA: _tops
	dbf	d3,.tops

	bsr.w	printz
	String	$FF,0,0
	movea.l	#Credits+$42,a1		;credits after the copyright lines
.top2	bsr.w	.top4			;IDA: _top2
	adda.w	(a1),a1
	moveq	#$2F,d4			;scroll 6*8 lines (92 6*8-1)
.top5	bsr.w	TitleScreen_wait	;IDA: _top5
	bsr.w	TitleScreen_wait
	addq.w	#1,(Vscroll).w
	dbf	d4,.top5
	moveq	#$78,d4			;120 frames (92 4*60)
.top6	bsr.w	TitleScreen_wait	;IDA: _top6
	dbf	d4,.top6
	tst.w	2(a1)
	bpl.s	.top2
	rts

.top4	;IDA: TitleScreen_top4. 92 .top4: erase 6 rows below the scroll and print a1 strings centered, to -1
	move.w	(Vscroll).w,d0
	asr.w	#3,d0
	addi.w	#$1C,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	move.w	d0,-(sp)
	clr.w	(printx).w
	moveq	#$20,d0
	moveq	#6,d1
	move.w	#$7FF,d2		;(92 moveq #1,d2)
	bsr.w	eraser
	move.w	(sp)+,(printy).w
.top4x	move.w	(a1),d0			;IDA: _top4x
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$11,d0			;(92 16)
	move.w	d0,(printx).w
	bsr.w	print
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w
	tst.w	2(a1)
	bpl.s	.top4x
	rts

TitleAnimCallback	;IDA: loc_1369C. 93: CallAnimationCallback routine for the title screen (from TitleScreen_wait).
	;Three Title3map sprites: a running fofdata2 timer shows the sprite and counts down; a stopped one
	;restarts at 20 when Hscroll + $1EC - TitleData1 entry is within 0-20 (mod $400)
	movea.l	#Title3Sprites,a0
	movea.w	#(fofdata2-M68K_RAM),a1
	lea	TitleData1(pc),a2
	moveq	#2,d7
	move.w	(gamesetuptilesetindex).w,d3
	ori.w	#$8000,d3		;priority
.top	move.w	(a1)+,d0		;IDA: loc_136B4
	bmi.w	.chk
	subq.w	#1,-2(a1)
	moveq	#1,d2
	add.w	d7,d2
	mulu.w	#$B,d2
	lsr.w	#1,d0
	sub.w	d0,d2			;frame (sprite d7 + 1) * 11 - timer / 2
	move.w	#$80,d0
	move.w	#$80,d1
	bsr.w	SetSframe
	bra.w	.next
.chk	move.w	(Hscroll).w,d0		;IDA: loc_136DA
	addi.w	#$1EC,d0
	sub.w	(a2),d0
	andi.w	#$3FF,d0
	cmp.w	#$14,d0
	bhi.w	.next
	move.w	#$14,-2(a1)		;start this sprite
.next	addq.w	#2,a2			;IDA: loc_136F6
	dbf	d7,.top
	rts

TitleData1	;93: Hscroll trigger points for the three TitleAnimCallback sprites
	dc.w	$B2,$DA,$6C
TitleData2	;93: four 16 color palettes for titleScreenState, one picked at random by TitleScreen
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$4A4,$484,$262,$40
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$E44,$A44,$822,$400
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$44A,$228,6,4
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$AE,$8C,$6A,$48

UpdateHorizontalScroll	;93: title screen line scroll, called each vblank from VBlank_TitleScreen.
	;The top $AF lines scroll plane B by Hscroll, the last $31 lines and plane A stay at 0. Hscroll moves by
	;(asv += DispAttribCtr) >> 8; beyond +-8 the direction flips, else about 1 in 40 frames picks a new speed (-$32 to $32)
	move.w	#$DF,d0			;224 lines
	movea.w	#(SortCords-M68K_RAM),a0	;line scroll table
.loop	clr.l	(a0)+			;IDA: loc_1378C
	cmp.w	#$30,d0
	ble.w	.next
	move.w	(Hscroll).w,-2(a0)
.next	dbf	d0,.loop		;IDA: loc_1379C
	move.w	(DispAttribCtr).w,d0
	add.w	(asv).w,d0
	move.w	d0,(asv).w
	asr.w	#8,d0
	add.w	d0,(Hscroll).w
	cmp.w	#8,d0
	bgt.w	.rev
	cmp.w	#$FFF8,d0		;-8
	blt.w	.rev
	move.w	#$FA0,d0		;4000
	bsr.w	randomd0
	cmp.w	#$64,d0
	bhi.w	.x
	subi.w	#$32,d0
	move.w	d0,(DispAttribCtr).w
.rev	neg.w	(DispAttribCtr).w	;IDA: loc_137DA
.x	rts				;IDA: locret_137DE

TitleScreen_wait	;wait for vblank, run TitleAnimCallback through CallAnimationCallback. 92 TitleScreen .wait:
	;if start is pressed, return to TitleScreen's caller (pops the return address). Called from TitleScreen
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0		;IDA: loc_137E8
	beq.s	.0
	lea	TitleAnimCallback(pc),a0
	bsr.w	CallAnimationCallback
	bsr.w	orjoy
	btst	#7,d1			;sbut
	movem.l	(sp)+,d0-d7/a0-a6
	beq.w	rtss
	addq.w	#4,sp			;start: leave TitleScreen
	rts

VBlank_TitleScreen	;93: vbint handler for the title screen: line scroll and sprite table dma, Vscroll, cramfade,
	;vcount, UpdateHorizontalScroll and the music driver
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.x
	movea.w	#(SortCords-M68K_RAM),a0	;line scroll table
	move.w	(VSCRLPM).w,d1
	move.w	#$1C0,d0
	bsr.w	DoDMA
	movea.l	#VDP_DATA,a0
	move.l	#$40000010,4(a0)	;vsram write 0
	move.w	(Vscroll).w,(a0)
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.nos
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
.nos	bsr.w	cramfade		;IDA: loc_13852
.x	addq.w	#1,(vcount).w		;IDA: loc_13856
	bsr.w	UpdateHorizontalScroll
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

CallAnimationCallback	;93: build a sprite list with routine a0 (a6 = Satt, d6 = link counter), add the logo
	;sprites (FinalizeSpriteList), then close the list. Called from PlayoffScreen and TitleScreen_wait
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6			;link counter
	jsr	(a0)
	bsr.w	FinalizeSpriteList
EndSpriteList	;IDA: loc_13876. 92 setvideo end: close the sprite list at a6 and set Sattsize (93: in words).
	;Branched to from UpdateStanleyCupAnimation
	cmpa.w	#(Satt-M68K_RAM),a6
	bne.w	.n
	clr.l	(a6)+			;no sprites: one blank entry
	clr.l	(a6)+
.n	clr.b	-5(a6)			;IDA: loc_13882. end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0
	move.w	d0,(Sattsize).w
	rts

FinalizeSpriteList	;93: four Titlemap2 logo sprites at playoffspritex, playoffspritey. clampcounter counts down by 2
	;and the pieces drop into place from above, each 64 later than the next. Called from CallAnimationCallback
	subq.w	#2,(clampcounter).w
	bpl.w	.0
	clr.w	(clampcounter).w
.0	movea.l	#TitleLogoSprites,a0		;IDA: loc_138A2
	moveq	#3,d7
	move.w	(energybarchars).w,d3
	ori.w	#$8000,d3		;priority
.top	move.w	(playoffspritex).w,d0	;IDA: loc_138B2
	move.w	d7,d1
	asl.w	#6,d1
	sub.w	(clampcounter).w,d1
	bmi.w	.1
	clr.w	d1			;in place
.1	add.w	(playoffspritey).w,d1	;IDA: loc_138C4
	moveq	#4,d2
	sub.w	d7,d2			;frame 1-4
	bsr.w	SetSframe
	dbf	d7,.top
	rts

CheckSound	;93: sound test, no caller found (IDA dc.b, Rev A $138D6). Runs only with start+a+c held on pad 1.
	;Prints "Check Sound"; right/left change the number, c plays it with sfx, start leaves
	bsr.w	Readjoy1
	cmp.b	#$E0,d3			;held: sbut, abut, cbut
	bne.w	rtss
	move	#$2500,sr
	move.l	#vb2,(vbint).w		;(Rev A $11896)
	jsr	p_turnoff		;(Rev A $165F0)
	bsr.w	forceblack
	move.w	#$18,(palcount).w
	bsr.w	printsmallz
	String	$F8,4,3,$C,1,'Check Sound'	;attribute 4, map 3, x $C, y 1
	moveq	#$14,d6			;sound number
.top	move.w	(vcount).w,d0
.wait	cmp.w	(vcount).w,d0
	beq.s	.wait
	bsr.w	Readjoy1
	bsr.w	ProcessInputWithRepeat
	tst.b	d1
	beq.s	.top
	btst	#7,d1			;sbut
	bne.w	rtss
	btst	#3,d1			;rbut
	beq.w	.nor
	addq.w	#1,d6
.nor	btst	#2,d1			;lbut
	beq.w	.nol
	subq.w	#1,d6
.nol	btst	#5,d1			;cbut
	beq.w	.nob
	move.w	d6,-(sp)
	bsr.w	sfx
.nob	move.w	d6,d0
	moveq	#3,d1			;3 digits
	bsr.w	PushNumberWidth
	move.w	#$17,(printx).w
	bsr.w	print
	bra.s	.top