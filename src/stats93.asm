;	Stats and team screens: game stats, line editor and roster, scoring and penalty summaries, player and
;	team stats, crowd meter and goalie selection. Each entry point is named after the title it prints.
;
;	Most screens use SetupScreen and ExitStatsScreen and leave when start is pressed. Several routines
;	descend from 92.

ShowScores							;"Scores" screen: lists the other games in
									;gstruct with both teams, scores and period. Up/down scroll, start exits.
									;Pause menu item handler
	moveq	#6,d0					;SetupScreen d0/d1: bitmap row offset / height
	moveq	#$1A,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,5,0
	moveq	#$1E,d0					;frame 30 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	IF REV=2
	String	$BD,$E,3,'Scores',$BD,$B,1
	ELSE
	String	$BD,$E,3,'Scores',$BD,$F,1
	ENDIF
	movea.l	#ScoresMap,a1
	lea	8(a1),a2
	adda.l	4(a1),a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d5
	bsr.w	dobitmap
	IF REV<2
	subq.w	#8,(printx).w
	jsr	(DrawEASNMap).l
	ENDIF							;Rev B draws no EASN logo on this screen
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,2,4,0,0
	clr.w	(VertLineScrolling).w
	bsr.w	UpdateVertScrollReg
	jsr	(GetShifter).l				;d1 = number of games to list
	move.w	d1,d3
	ble.w	.skip
.game	bsr.w	DisplayGameInfo		;print game d3 (skipped if not eligible)
	dbf	d3,.game
.skip	clr.w	(SelectedPlayerIdx).w	;max scroll = 0 unless the list is long
	move.w	(printy).w,d0
	subi.w	#$15,d0					;rows printed past row $15 can be scrolled to
	bmi.w	.loop
	asl.w	#3,d0					;8 pixels per row
	move.w	d0,(SelectedPlayerIdx).w	;max scroll
	bsr.w	DrawScrollArrows
.loop	bsr.w	MenuWaitVblank		;per frame: read pad d3 (buttons held)
	bsr.w	getpzjoy
	btst	#7,d3					;start: leave
	bne.w	ExitStatsScreen
	moveq	#-2,d0					;up: scroll -2 pixels a frame
	btst	#0,d3
	bne.w	.set
	neg.w	d0						;down: +2
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;scroll speed/direction for this frame
.scroll	bsr.w	UpdateScoresScroll	;apply any pending scroll
	bra.s	.loop

UpdateScoresScroll					;called every frame by ShowScores. Add PlayerScrollCtr to
									;VertLineScrolling (0..SelectedPlayerIdx). On a 24 pixel boundary redraw
									;the
									;arrows and stop. Falls into UpdateVertScrollReg
	move.w	(PlayerScrollCtr).w,d0	;0 = not scrolling
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0	;new position, must stay in 0..max
	bmi.w	rtss2
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divu.w	#$18,d0
	swap	d0						;remainder
	tst.w	d0
	bne.w	UpdateVertScrollReg		;not on a 3 row boundary yet
	bsr.w	DrawScrollArrows
	clr.w	(PlayerScrollCtr).w

UpdateVertScrollReg					;write VSRAM word 1 = VertLineScrolling - $30
									;(playfield B vertical scroll). Saves disflags
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w		;don't int graphics
	movea.l	#Vdata,a0				;a0 = VDP data port, +4 = control port
	move.l	#VSRAM_W+(2<<16),4(a0)	;VSRAM write, address 2
	move.w	#$FFD0,d0				;-$30
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DisplayGameInfo						;from 92 NewTicker3. print game d3 of gstruct (2 team rows and period
									;label). Skips the current game and games with gsflags bit 1 or 2 set
	cmp.w	(gamenum).w,d3
	beq.w	rtss2					;current game
	moveq	#gssize,d0				;gssize
	mulu.w	d3,d0
	movea.w	#(gstruct-M68K_RAM),a0	;a0 = gstruct + d3 * gssize
	adda.w	d0,a0
	btst	#gsfhl,gsflags(a0)		;gsflags(a0)
	bne.w	rtss2
	btst	#2,gsflags(a0)			;bit 2: also skipped
	bne.w	rtss2
	move.w	2(a0),d0				;first team / score
	move.w	gss2(a0),d1
	bsr.w	PrintGameInfo
	addq.w	#1,(printy).w
	move.w	(a0),d0					;second team / score
	move.w	gss1(a0),d1
	bsr.w	PrintGameInfo
	move.w	8(a0),d0				;period, 1 based
	subq.w	#1,d0
	movea.l	#PerLabels,a1
	move.w	#$1C,(printx).w
	jsr	(Fprintsmall).l
	addq.w	#2,(printy).w
	rts

PrintGameInfo						;from 92 NewTicker3 .tn. print team d0's name at x 6 and score d1 (2
									;digits) at x $18
	movea.w	#TeamList,a1			;team address table
	asl.w	#2,d0
	movea.l	(a1,d0.w),a1
	adda.w	4(a1),a1				;team name
	move.w	#6,(printx).w
	bsr.w	print
	move.w	#$18,(printx).w
	move.w	d1,d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print

DrawScrollArrows					;ShowScores up/down arrows. Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,3,4,6,CC_SetFont,1,0
	clr.w	d0						;d0 = up arrow flag, d1 = down arrow flag
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0						;1 if scrolled down at all
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1						;1 if more below
	add.b	d1,d0
	add.b	d1,d0					;string = up + 2*down
	lea	ScrollArrowTable(pc),a1
	jsr	(Fprintsmall).l
	movem.l	(sp)+,d0-d1/a1
	rts

ScrollArrowTable					;DrawScrollArrows strings: none, up, down. Only 3 entries (the penalty and
									;attribute versions have a 4th for both arrows)
	String	$20,$FB,$FF,$FA,$13,$20,$F9
	String	$7B,$FB,$FF,$FA,$13,$20,$F9
	String	$20,$FB,$FF,$FA,$13,$7D,$F9

LineEditor							;"Line Editor" screen for team a2.
									;Pick a line slot, then a player to put there. Pause menu item
									;handler
	bset	#tmflcc,tmflags(a2)		;set on entry to the line editor
	moveq	#0,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	clr.w	(DispAttribCtr).w
	clr.w	(PlayerScrollCtr).w
	move.w	#1,(TestList).w			;cursor = first slot
LineEditorRedraw					;Clear the screen and redraw everything.
									;Also entered from LineEditorExit when its menu returns nonzero
	bsr.w	printsmallz
	String	CC_SetMap,2,CC_SetX,0,CC_SetY,0
	moveq	#$28,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	st	(redrawicons).w				;force DrawLineIcons to redraw the icons
	bsr.w	ClearMenuFlags
LineEditorMenu						;Slot cursor loop. Also entered from
									;SelectLinePlayer when it is done
	bsr.w	DrawTeamScreen
	bsr.w	DrawLineIcons
.loop	IF REV=2
	bsr.w	MenuWaitVblank			;per frame: d1 = pressed buttons with auto repeat (Rev B has no wrapper)
	ELSE
	bsr.w	MenuWaitVblankWrapper	;per frame: d1 = pressed buttons with auto repeat
	ENDIF
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	btst	#7,d1					;start: exit menu
	bne.w	LineEditorExit
	btst	#5,d1					;C: pick a player for this slot
	bne.w	SelectLinePlayer
	moveq	#1,d0					;down: next slot
	btst	#1,d1
	bne.w	.move
	moveq	#-1,d0					;up: previous slot
	btst	#0,d1
	bne.w	.move
	moveq	#8,d0					;right: next line (8 slots per line)
	btst	#3,d1
	bne.w	.move
	moveq	#-8,d0					;left: previous line
	btst	#2,d1
	beq.s	.loop
.move	add.w	(TestList).w,d0		;d0 = tentative new slot
	tst.w	(OptLine).w
	beq.w	.set
	cmp.w	#1,d0
	blt.s	.loop					;OptLine set: only slots 1-5
	cmp.w	#5,d0
	bgt.s	.loop
.set	lea	LineCursorTable(pc),a0	;table is indexed by slot + 8
	move.b	8(a0,d0.w),(TestList+1).w	;wrap/skip through the table
	bsr.w	DrawLineIcons
	bra.s	.loop

	IF REV<2
MenuWaitVblankWrapper				;thunk to MenuWaitVblank (Rev B calls MenuWaitVblank directly)
	bra.w	MenuWaitVblank
	ENDIF

SelectLinePlayer					;line editor: C pressed on slot TestList. Build the list of players that
									;can go in the slot in Satt (roster order is goalies, forwards, defense)
									;and let the user pick one
									;(left/right pages the attribute columns). C stores the pick with
									;SetLineSlot, start goes back. Both return to LineEditorMenu
	bsr.w	GetGoalieCount
	move.w	d0,d1
	bsr.w	GetForwardCount
	move.w	(TestList).w,d2
	andi.w	#7,d2					;slot within the line
	cmp.w	#2,d2
	bgt.w	.n						;slots 3-5 (forwards): after the goalies
	add.w	d0,d1					;slots 1-2 (defense): after goalies+forwards
	bsr.w	GetPlayerCount
	sub.w	d1,d0					;d0 = candidates, d1 = first roster index
.n	subq.w	#1,d0					;count - 1 for dbf
	move.w	d0,(screentimer).w		;last candidate row (also the dbf count)
	clr.w	(PlayerScrollCtr).w
	clr.w	(VertLineScrolling).w
	movea.w	#(Satt-M68K_RAM),a0
	clr.w	d2
.fill	move.b	d1,(a0,d2.w)		;Satt[d2] = roster index d1
	cmp.w	d1,d6					;player now in the slot?
	bne.w	.nc
	move.w	d2,(VertLineScrolling).w	;start the cursor on him
.nc	addq.w	#1,d1					;next candidate
	addq.w	#1,d2
	dbf	d0,.fill
	bsr.w	ClearLineEditorTop
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,0,3,1,0,0
	moveq	#$12,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printsmallz
	String	CC_SetX,$15,CC_SetY,0
	moveq	#$12,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printsmallz
	dc.w	$0018
	dc.b	$F8,4,2,2,1,'{Select  Player}',0
	clr.w	d0						;draw the list without moving the cursor
	bra.w	.vert
.loop	IF REV=2
	bsr.w	MenuWaitVblank			;picker input loop
	ELSE
	bsr.w	MenuWaitVblankWrapper	;picker input loop
	ENDIF
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	btst	#7,d1					;start: back to slot cursor
	bne.w	LineEditorMenu
	btst	#5,d1					;C: take this player
	bne.w	.pick
	moveq	#1,d0
	btst	#1,d1					;down
	bne.w	.vert
	btst	#3,d1					;right: next attribute page
	bne.w	.horz
	moveq	#-1,d0
	btst	#0,d1					;up
	bne.w	.vert
	btst	#2,d1					;left: previous attribute page
	bne.w	.horz
	bra.s	.loop
.horz	add.w	(DispAttribCtr).w,d0	;change attribute page (not below 0)
	bmi.s	.loop
	move.w	d0,(DispAttribCtr).w
	bsr.w	PrintAttribHeader
	bra.s	.loop
.vert	add.w	(VertLineScrolling).w,d0	;Cursor row 0..screentimer
	bmi.s	.loop
	cmp.w	(screentimer).w,d0
	bgt.s	.loop
	move.w	d0,(VertLineScrolling).w
	cmp.w	(PlayerScrollCtr).w,d0	;PlayerScrollCtr = first shown row
	bgt.w	.top
	move.w	d0,(PlayerScrollCtr).w	;Cursor above the window
.top	subq.w	#5,d0				;6 rows shown
	cmp.w	(PlayerScrollCtr).w,d0
	ble.w	.draw
	move.w	d0,(PlayerScrollCtr).w
.draw	bsr.w	PrintAttribHeader	;redraw the 6 visible rows
	bra.w	.loop
.pick	movea.w	#(Satt-M68K_RAM),a3	;C: chosen row's roster index
	adda.w	(VertLineScrolling).w,a3
	move.b	(a3),d0
	addq.b	#1,d0					;SetLineSlot wants 1 based
	move.w	(TestList).w,d2
	bsr.w	SetLineSlot
	bra.w	LineEditorMenu

PrintAttribHeader					;line editor player list: column header for attribute page DispAttribCtr
									;(clamped to the last page) and 6 rows from PlayerScrollCtr.
									;The cursor row is printed with attribute d7
	bsr.w	printz
	String	$BE,$16,1,0
.top	movea.l	#PAttribColumns,a1	;list of column entries: word length, 4 byte flags, text
	move.w	(DispAttribCtr).w,d0	;skip d0 entries
	bra.w	.2
.next	adda.w	(a1),a1				;next entry
	addq.w	#4,a1
.2	tst.w	(a1)					;Negative = end of list
	dbmi	d0,.next
	bpl.w	.found
	subq.w	#1,(DispAttribCtr).w	;past the last page: back one
	bra.s	.top
.found	bsr.w	print				;print the header text of the entry
	move.l	(a1),d4					;column flags for GetNameandAttrib
	movea.w	#(Satt-M68K_RAM),a3
	move.w	(PlayerScrollCtr).w,d2	;d2 = first row shown
	move.w	(screentimer).w,d1
	sub.w	d2,d1
	cmp.w	#5,d1
	bls.w	.4
	moveq	#5,d1					;at most 6 rows
.4	move.w	#2,(printy).w			;first row at y 2
.row	bsr.w	printsmallz			;blank the row (22 spaces), then print the player
	dc.w	$0020
	dc.b	$FE,4,$FD,5,$FA,1
	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	dc.b	$FD,5
	cmp.w	(VertLineScrolling).w,d2	;cursor row?
	bne.w	.5
	move.w	d7,(printa).w			;use the highlight attribute
.5	clr.w	d0						;(not the cursor row)
	move.b	(a3,d2.w),d0			;roster index of this row
	bsr.w	GetNameandAttrib
	addq.w	#1,d2
	dbf	d1,.row
	rts

DrawLineIcons						;line editor: draw the line icons for the cursor's line group (bit mask
									;from LineIconGroups) and the name of player d6
	moveq	#6,d5					;7 lines
	lea	LineIconGroups(pc),a0
	move.w	(TestList).w,d0
	lsr.w	#3,d0					;line number
	adda.w	d0,a0
	tst.w	(OptLine).w
	beq.w	.0
	subq.w	#1,a0					;OptLine set: table starts one byte earlier
.0	move.b	(a0),d0					;group mask for this line
	cmp.b	(redrawicons).w,d0
	beq.w	.line					;same group as last time: no clear
	move.b	d0,(redrawicons).w
	bsr.w	ClearLineArea
.line	btst	d5,(redrawicons).w	;Line d5 in this group?
	beq.w	.2
	bsr.w	DrawLineIcon
.2	dbf	d5,.line					;d5 counts 6..0 (next line)
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,2,8,7,CC_SetFont,1,0
	moveq	#$18,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printsmallz
	String	CC_SetX,$15,CC_SetY,8
	move.w	d6,d0					;name of the cursor slot's player
	jsr	(getname).l
	move.w	(a1),d0					;string length word...
	lsr.w	#1,d0
	sub.w	d0,(printx).w			;...used to centre it
	move.w	d7,(printa).w
	bsr.w	printsmall
	clr.w	(printfontset).w
	rts
	dc.b	1						;LineIconGroups-1, used when OptLine is set
LineIconGroups						;per line: bit mask of the lines drawn together (line n = bit n)
	dc.b	7,7,7,$18,$18,$60,$60

DrawLineIcon						;line editor: draw line d5 (name from linelist, then its player slots) at
									;the x/y/count entry d5 of LineIconPosTable. The slot matching TestList is
									;highlighted and its player number is returned in d6
	moveq	#6,d0					;6 bytes per entry
	mulu.w	d5,d0
	lea	LineIconPosTable(pc),a0
	adda.w	d0,a0
	tst.w	(OptLine).w
	beq.w	.0
	subq.w	#6,a0					;OptLine set: use the entry before
.0	move.w	(a0),(printx).w			;x, y of the entry
	move.w	2(a0),(printy).w
	move.w	d5,d0					;line name string index
	movea.l	#linelist,a1
	move.w	#$8000,(printa).w
	jsr	(Fprintsmall).l
	bsr.w	printsmallz
	dc.w	$0008
	dc.b	' Line',0
	move.w	(a0),(printx).w
	move.w	d5,d4
	asl.w	#3,d4					;8 slots per line
	addq.w	#1,d4					;slots are 1-5 (LD RD LW C RW)
	move.w	2(a0),(printy).w
	move.w	4(a0),d3				;slot count - 1
	lea	tmlines(a2),a3				;team line table
.slot	move.w	(a0),(printx).w		;loop over the line's slots
	bsr.w	printsmallz
	String	CC_AddX,$FF,CC_AddY,2,CC_SetAttribute,6
	clr.w	d0
	move.b	(a3,d4.w),d0			;1 based player number in slot d4
	subq.w	#1,d0
	jsr	(FormatPlayerNameShort).l
	cmp.w	(TestList).w,d4			;cursor slot?
	bne.w	.nocur
	move.w	d0,d6					;player in the cursor slot
	move.w	(printa).w,d7
	move.w	#2,(printfontset).w		;highlight while printing
.nocur	bsr.w	printsmall			;print the (formatted) name
	clr.w	(printfontset).w
	addq.w	#1,d4					;next slot
	dbf	d3,.slot
	rts

ClearLineArea						;line editor: erase the line area and print the
									;position labels (LD RD LW C RW) at the first icon position
	bsr.w	printsmallz
	String	CC_SetMap,2,CC_SetX,0,CC_SetY,$A
	moveq	#$28,d0					;40 x 18
	moveq	#$12,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	(LineIconPosTable+2).l,(printy).l
	move.w	(LineIconPosTable).l,(printx).l
	tst.w	(OptLine).w
	beq.w	.0
	move.w	(LineIconPosTable-6).l,(printx).l	;OptLine: use the entry before
.0	bsr.w	printsmallz				;labels, one column per slot
	dc.w	$0022
	dc.b	$FE,4,$FB,$FD,$FA,2,'LD',$FB,$FE,$FA,2,'RD',$FB,$FE,$FA,2,'LW'
	dc.b	$FB,$FE,$FA,2,'C ',$FB,$FE,$FA,2,'RW'
	rts

DrawTeamScreen						;line editor background: bitmap, frame, "Line Editor" title and the team
									;logo of a2 (home at map offset 0, away at $30)
	bsr.w	ClearLineEditorTop
	movem.l	d0-d5/a0-a2,-(sp)
	bsr.w	printz
	String	$FD,0,0
	movea.l	#EASNBGMap,a1			;background bitmap (map header + offset to data)
	adda.l	4(a1),a1
	movea.w	#null,a2				;a2 saved/restored around this block
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	IF REV=2
	moveq	#1,d4					;Rev B starts the tiles at char 1
	ELSE
	clr.w	d4
	ENDIF
	moveq	#0,d5
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d5/a0-a2
	bsr.w	printz
	String	$BE,7,1,0
	moveq	#$1A,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0014
	dc.b	$BE,$A,4,'Line  Editor',$BE,$E,1
	clr.w	d0						;map offset: home 0, away $30
	cmpa.w	#(tmstruct-M68K_RAM),a2	;home team?
	beq.w	PutTeamBlock
	moveq	#$30,d0
	bra.w	PutTeamBlock			;tail call: draws the team logo

ClearLineEditorTop					;erase 40 x 10 at the top of map 2
	bsr.w	printz
	String	$BE,0,0
	moveq	#$28,d0
	moveq	#$A,d1
	move.w	#$7FF,d2
	bra.w	eraser

ClearMenuFlags						;clear palbuffer+$1A and palbuffer+$3A
	clr.w	(palbuffer+$1A).w
	clr.w	(palbuffer+$3A).w
	rts

	dc.w	$10,$C,4				;Entry used when OptLine is set
LineIconPosTable					;line icons: x, y, slot count - 1 per line
	dc.w	4,$C,4					;at +2
	dc.w	$10,$C,4
	dc.w	$1C,$C,4
	dc.w	4,$C,4
	dc.w	$10,$C,4
	dc.w	4,$C,3
	dc.w	$10,$C,3
	dc.w	$FFFF

LineCursorTable						;TestList after a cursor move: indexed by
									;new TestList + 8 (8 slots per line)
	dc.b	1,1,2,3,4,5,$19,1
	dc.b	1,1,2,3,4,5,$19,1
	dc.b	9,9,$A,$B,$C,$D,$21,1
	dc.b	$11,$11,$12,$13,$14,$15,$21,1
	dc.b	5,$19,$1A,$1B,$1C,$1D,$29,1
	dc.b	$D,$21,$22,$23,$24,$25,$31,1
	dc.b	$1D,$29,$2A,$2B,$2C,$2C,1,1
	dc.b	$25,$31,$32,$33,$34,$34,1,1
	dc.b	$25,$31,$32,$33,$34,$34,1,1

LineEditorExit						;line editor: start pressed. Run the exit menu (LineEditorMenuText, or
									;LineEditorMenuNoLoad if databuffer holds another team's lines). A nonzero
									;choice goes back to LineEditorRedraw, zero leaves via ExitStatsScreen
	bsr.w	ClearMenuFlags
	move.w	#$18,(palcount).w
	move.l	(menuitem).w,-(sp)
	move.l	(menulist).w,-(sp)
	move.l	(menudraw).w,-(sp)
	movea.l	#rtss,a1				;a1 = menu callback (just an rts)
	movea.l	#LineEditorMenuText,a0
	movea.w	#(databuffer-M68K_RAM),a3
	move.w	tmteam(a2),d0			;team number + 1 = first databuffer byte?
	addq.w	#1,d0
	cmp.b	(a3),d0
	beq.w	.0
	movea.l	#LineEditorMenuNoLoad,a0	;no load option for another team's data
.0	bsr.w	printsmallz				;string $FF,2: probably selects the menu text mode
	String	$FF,2
	bsr.w	InitMenuState			;a0 = menu text, a1 = callback
.loop	bsr.w	MenuWaitVblank		;menu loop, d1 = pressed buttons
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	move.w	d1,-(sp)
	bsr.w	HandleMenuInput
	move.w	(sp)+,d1
	andi.w	#$A0,d1					;start or C
	beq.s	.loop
	bsr.w	printsmallz
	String	CC_SetFont,0
	move.w	(menuitem).w,d0
	move.l	(sp)+,(menudraw).w
	move.l	(sp)+,(menulist).w
	move.l	(sp)+,(menuitem).w
	tst.w	d0
	bne.w	LineEditorRedraw
	bra.w	ExitStatsScreen

SetLineSlot							;put player d0 (1 based) in line slot d2 of team a2. If he is already in
									;another slot of the same line, the old occupant of d2 is moved there
									;(swap)
	movem.l	d0-d2/a0-a1,-(sp)
	lea	tmlines(a2),a0				;a0 = team line table (8 bytes per line)
	move.w	d2,d1
	andi.w	#$FFF8,d1
	lea	(a0,d1.w),a1				;a1 = start of d2's line
	moveq	#5,d1
.find	cmp.b	1(a1,d1.w),d0		;is player d0 already in this line?
	dbeq	d1,.find
	bne.w	.put
	move.b	(a0,d2.w),1(a1,d1.w)	;yes: old occupant of d2 takes his slot
.put	move.b	d0,(a0,d2.w)		;store the player
	movem.l	(sp)+,d0-d2/a0-a1
	rts

DecodeTeamLines						;load team a2's lines from databuffer (byte 0 = team + 1, then one nibble
									;per slot in AttributeOffsetTbl order, relative to the first forward, or
									;first defenseman for slots 1-2)
	movem.l	d0-d4/a0/a3,-(sp)
	movea.w	#(databuffer-M68K_RAM),a0
	addq.w	#1,a0
	bsr.w	GetGoalieCount
	move.w	d0,d1
	bsr.w	GetForwardCount
	move.w	d0,d3
	movea.l	#AttributeOffsetTbl,a3
	clr.w	d4
	clr.w	d2
.next	move.b	(a3),d2				;d2 = next slot from AttributeOffsetTbl
	bmi.w	.done					;$FF: finished
	bchg	#0,d4					;d4 bit 0 toggles low/high nibble
	bne.w	.hi
	move.b	(a0),d0					;first nibble of the byte: low
	bra.w	.nib
.hi	move.b	(a0)+,d0				;second nibble: high, then advance
	lsr.w	#4,d0
.nib	andi.w	#$F,d0				;nibble value
	add.b	d1,d0					;+ goalie count
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.store					;slots 3-5 are forwards
	add.b	d3,d0					;slots 1-2 defense: + forward count
.store	addq.b	#1,d0				;1 based player number
	andi.w	#$FF,d0
	move.b	(a3)+,d2				;d2 = slot index
	bsr.w	SetLineSlot
	bra.s	.next
.done	movem.l	(sp)+,d0-d4/a0/a3	;all slots set
	rts

EncodeTeamLines						;reverse of
									;DecodeTeamLines: pack team a2's lines into databuffer and convert
									;it with BackupRAM_Save
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	#(databuffer-M68K_RAM),a0
	move.w	tmteam(a2),d0
	addq.w	#1,d0
	move.b	d0,(a0)+
	lea	tmlines(a2),a1
	bsr.w	GetGoalieCount
	move.w	d0,d1
	bsr.w	GetForwardCount
	movea.l	#AttributeOffsetTbl,a3
	clr.w	d4
	clr.w	d2
.next	move.b	(a3)+,d2			;d2 = slot index, $FF ends
	bmi.w	.done
	move.b	(a1,d2.w),d3			;player number in the slot
	subq.b	#1,d3
	sub.b	d1,d3					;relative to the first non-goalie
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.pack					;slots 3-5: forwards
	sub.b	d0,d3					;slots 1-2: also minus forward count
.pack	bchg	#0,d4				;alternate low / high nibble
	bne.w	.hi
	move.b	d3,(a0)					;low nibble (high is or'ed in next)
	bra.s	.next
.hi	asl.b	#4,d3					;second nibble goes in the high half
	or.b	d3,(a0)+
	bra.s	.next
.done	jsr	(BackupRAM_Save).l		;write the packed lines out
	movem.l	(sp)+,d0-d4/a0-a3
	rts

AttributeOffsetTbl					;line slots saved in databuffer ($FF ends)
	dc.b	1,2,3,4,5
	dc.b	9,$A,$B,$C,$D
	dc.b	$11,$12,$13,$14,$15
	dc.b	$19,$1A,$1B,$1C,$1D
	dc.b	$21,$22,$23,$24,$25
	dc.b	$29,$2A,$2B,$2C
	dc.b	$31,$32,$33,$34
	dc.b	$FF

TeamRosterScreen					;"Team Roster" screen for team a2
									;one page per line (PlayerStatMenuTxt), scrolled sideways by 128 pixels.
									;Up/down change line, left/right attribute columns, A switches team
	moveq	#$D,d0
	moveq	#$17,d1
	bsr.w	SetupScreen
	moveq	#1,d0
	add.w	tmline(a2),d0			;start on the current line
	move.w	d0,(SelectedPlayerIdx).w	;page 0 = goalies, 1.. = lines
	clr.w	(DispAttribCtr).w
.redraw	bsr.w	printz				;(re)draw the whole screen, entered again after A
	String	$BD,7,1,0
	moveq	#$1A,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0014
	dc.b	$BD,9,4,'Team  Roster',$BD,$E,1
	clr.w	d0						;logo map offset: home 0, away $30
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.home
	moveq	#$30,d0
.home	bsr.w	PutTeamBlock		;team logo block
	bsr.w	printsmallz
	dc.w	$0034
	dc.b	$F8,6,3,2,$C,$F9,1,'Pos.^Player',$FD,$1E,$FC,$C,'Rating'
	dc.b	$FD,$C,$FC,$1A,'A^-^Switch^Teams',$F9,0
	bsr.w	printz
	String	$BD,1,8,0
	moveq	#$12,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BD,$15,8,0
	moveq	#$12,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	DisplayPlayerList		;draw the current page
	move.w	(SelectedPlayerIdx).w,d0
	mulu.w	#$80,d0					;128 pixels per line page
	move.w	d0,(VertLineScrolling).w
	bsr.w	UpdatePlayerListScroll	;set the scroll register for it
	clr.w	(PlayerScrollCtr).w
.loop	bsr.w	MenuWaitVblank		;per frame: d3 held, d1 pressed with repeat
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	btst	#7,d3					;start: leave
	bne.w	ExitStatsScreen
	btst	#6,d1					;A: other team
	bne.w	.team
	bsr.w	nodiag					;filter out diagonal presses
	moveq	#1,d0					;right/left: attribute columns
	btst	#3,d1
	bne.w	.col
	neg.w	d0
	btst	#2,d1
	bne.w	.col
	tst.w	(PlayerScrollCtr).w		;still scrolling
	bne.w	.scroll
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;start a page scroll (-2/+2 pixels a frame)
.scroll	bsr.w	CheckPlayerListScroll	;apply any pending page scroll
	bra.s	.loop
.col	add.w	(DispAttribCtr).w,d0	;new attribute column page (not below 0)
	bmi.s	.scroll
	move.w	d0,(DispAttribCtr).w
	bsr.w	DisplayPlayerList
	bra.s	.scroll
.team	lea	tmsize(a2),a2			;A: next team struct; home -> away
	cmpa.w	#(awtmstruct-M68K_RAM),a2
	beq.w	.redraw
	movea.w	#(tmstruct-M68K_RAM),a2	;away -> back to home
	bra.w	.redraw

CheckPlayerListScroll				;TeamRosterScreen per frame: add PlayerScrollCtr to VertLineScrolling,
									;0..$380 (7 line pages)
	move.w	(PlayerScrollCtr).w,d0	;0 = not scrolling
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0	;new position
	bmi.w	StopPlayerListScroll
	cmp.w	#$380,d0
	bgt.w	StopPlayerListScroll
UpdatePlayerListScroll				;set VertLineScrolling = d0. Stop on a page boundary. When leaving a
									;boundary, draw the page coming into view (2 pixels into a move).
									;Then VSRAM = VertLineScrolling - $70
	move.w	(VertLineScrolling).w,d1	;d1 = old position
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$80,d0					;low word of d0 after swap = offset within the page
	swap	d0
	tst.w	d0
	bne.w	.0
	clr.w	(PlayerScrollCtr).w		;exactly on a page: stop
.0	andi.w	#$7F,d1					;was the old position on a page boundary?
	bne.w	.2
	cmp.w	#$7E,d0					;moved back 2 pixels: draw previous page
	bne.w	.1
	bsr.w	DisplayPlayerListUp
.1	cmp.w	#2,d0					;moved on 2 pixels: draw next page
	bne.w	.2
	bsr.w	DisplayPlayerListDown
.2	move.w	(disflags).w,-(sp)		;set the VSRAM scroll value
	bset	#dfng,(disflags).w
	movea.l	#Vdata,a0
	move.l	#VSRAM_W+(2<<16),4(a0)
	move.w	#$FF90,d0				;-$70
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

StopPlayerListScroll				;Out of range: stop scrolling
	clr.w	(PlayerScrollCtr).w
	rts

DisplayPlayerListUp					;d0 = divs result (quotient in high word): draw that page
	move.l	d0,-(sp)
	swap	d0
	move.w	d0,(SelectedPlayerIdx).w
	bsr.w	DisplayPlayerList
	move.l	(sp)+,d0
	rts

DisplayPlayerListDown				;draw the page after the quotient in d0's high word
	move.l	d0,-(sp)
	swap	d0
	addq.w	#1,d0
	move.w	d0,(SelectedPlayerIdx).w
	bsr.w	DisplayPlayerList
	move.l	(sp)+,d0
	rts

DisplayPlayerList					;draw roster page SelectedPlayerIdx (0 goalies, 1-7 lines):
									;title, attribute column header DispAttribCtr (clamped) and one row per
									;position. Odd pages go 16 rows lower in the scroll map
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,7,3,2,9,CC_SetFont,1,0
	move.w	(SelectedPlayerIdx).w,d0
	lea	PlayerStatMenuTxt(pc),a1
	jsr	(AdvanceStringPtr).l
	bsr.w	printsmall
	bsr.w	printsmallz
	String	CC_SetX,$16,CC_SetY,9
.top	movea.l	#PAttribColumns,a1	;skater column list (goalie page: GAttribColumns)
	move.w	(DispAttribCtr).w,d0
	tst.w	(SelectedPlayerIdx).w
	bne.w	.2
	movea.l	#GAttribColumns,a1
	bra.w	.2
.next	adda.w	(a1),a1				;skip an entry
	addq.w	#4,a1
.2	tst.w	(a1)					;negative = end of list
	dbmi	d0,.next
	bpl.w	.found
	subq.w	#1,(DispAttribCtr).w	;past the last page: back one and retry
	bra.s	.top
.found	bsr.w	printsmall			;column header text
	move.l	(a1),d4					;column flags for GetNameandAttrib
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,2,0,0,CC_SetFont,0,0
	btst	#0,(SelectedPlayerIdx+1).w	;odd pages are 16 rows lower
	beq.w	.4
	addi.w	#$10,(printy).w
.4	move.w	(printy).w,-(sp)		;erase the page area first
	moveq	#$28,d0
	moveq	#$10,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	(sp)+,(printy).w
	bsr.w	GetGoalieCount
	move.w	d0,d1
	subq.w	#1,d1					;goalie page: one row per goalie
	movea.l	#GoalieRowText,a5		;a5 = position label strings
	movea.w	#(Satt-M68K_RAM),a3		;goalie page: players 1-4
	move.l	#$1020304,(a3)
	move.w	(SelectedPlayerIdx).w,d0
	subq.w	#1,d0					;line number
	bmi.w	.row
	asl.w	#3,d0					;8 bytes per line
	lea	tmlines(a2),a3				;a3 = player numbers of that line (skip byte 0)
	lea	1(a3,d0.w),a3
	movea.l	#PlayerPositionText,a5
	moveq	#4,d1					;5 positions
	cmpi.w	#5,(SelectedPlayerIdx).w
	ble.w	.row
	subq.w	#1,d1					;penalty kill lines: 4
.row	move.w	#2,(printx).w		;position label, a5 advances to the next string
	movea.l	a5,a1
	bsr.w	print
	movea.l	a1,a5
	move.w	#7,(printx).w			;then name and column value
	clr.w	d0
	move.b	(a3)+,d0
	subq.w	#1,d0					;0 based player index
	bsr.w	GetNameandAttrib
	addq.w	#2,(printy).w			;2 text rows per player
	dbf	d1,.row
	rts

GoalieRowText						;position text for the
									;goalie page
	String	'G'
	String	'G'
	String	'G'
	String	'G'
PlayerStatMenuTxt					;roster page titles, { } are the left/right arrows
	dc.w	$0012
	dc.b	'    Goalies    }'
	dc.w	$0012
	dc.b	'{  Scoring  1  }'
	dc.w	$0012
	dc.b	'{  Scoring  2  }'
	dc.w	$0012
	dc.b	'{   Checking   }'
	dc.w	$0012
	dc.b	'{ Power Play 1 }'
	dc.w	$0012
	dc.b	'{ Power Play 2 }'
	dc.w	$0012
	dc.b	'{Penalty Kill 1}'
	dc.w	$0012
	dc.b	'{Penalty Kill 2 '

GetNameandAttrib					;print player d0's name, then at x $1E the column picked by d4 (from
									;PAttribColumns/GAttribColumns): low word = attribjmp offset, high word =
									;mask of rating nibbles to average (offsets > 2 only)
	movem.l	d0-d4/a0-a1,-(sp)
	pea	.x(pc)						;return address for the jmp below (handlers end in rts)
	jsr	(getname).l
	bsr.w	print
	move.w	#$1E,(printx).w
	cmp.w	#2,d4
	bls.w	.jump					;status/energy: no ratings
	movea.l	tmdata(a2),a0			;team data, player records
	adda.w	(a0),a0
.skip	adda.w	(a0),a0				;step over d0 records (+1 header) to player d0
	addq.w	#8,a0
	dbf	d0,.skip
	clr.w	d0
	clr.w	d1
	moveq	#$F,d2					;test mask bits 15..0, one rating nibble each
	swap	d4
.bit	btst	d2,d4				;is rating nibble d2 selected in the mask?
	beq.w	.next
	move.w	d2,d3
	lsr.w	#1,d3
	neg.w	d3
	move.b	-1(a0,d3.w),d3			;rating byte, two nibbles per byte before a0
	btst	#0,d2
	beq.w	.2
	lsr.w	#4,d3					;odd bit: high nibble
.2	andi.w	#$F,d3					;rating 0-15
	add.w	d3,d0					;d0 = sum of ratings
	addi.w	#$F,d1					;d1 = 15 * count (max)
.next	dbf	d2,.bit					;next bit
	swap	d4						;back to the handler offset
.jump	lea	attribjmp(pc),a0		;jump to the column handler; its rts lands on .x
	adda.w	(a0,d4.w),a0
	jmp	(a0)
.x	movem.l	(sp)+,d0-d4/a0-a1		;restore and return
	rts

attribjmp							;GetNameandAttrib column handlers, offsets from attribjmp
	dc.w	AttribStatus-attribjmp
	dc.w	AttribEnergy-attribjmp
	dc.w	AttribHanded-attribjmp
	dc.w	AttribWeight-attribjmp
	dc.w	AttribFighting-attribjmp
	dc.w	AttribRating-attribjmp

AttribStatus						;Roster column: status. Player d0's tmpdst word in a2 negative = not'ed
									;status 0-2 (Ice/Bench/Injury P), positive = penalty time (bit $C injured
									;G, bit $E prints C)
	add.w	d0,d0					;word index by player
	move.w	tmpdst(a2,d0.w),d0
	bpl.w	.pen					;positive: serving a penalty
	not.w	d0						;negative: status 0-2
	cmp.w	#2,d0
	bls.w	.st
	moveq	#1,d0					;anything else shown as Bench
	bra.w	.st
.inj	moveq	#3,d0				;string 3 = Injury G
.st	lea	StatusTextTbl(pc),a1		;d0 = string index
	bra.w	Fprintsmall
.pen	btst	#$C,d0				;bit $C: injured goalie
	bne.s	.inj
	subq.w	#1,(printx).w
	move.w	d0,d1
	andi.w	#$FFF,d0				;penalty time
	bsr.w	PushTime
	bsr.w	print
	moveq	#4,d0					;string 4 = blank padding
	bclr	#$E,d1					;bit $E: prints C
	beq.w	.t
	moveq	#5,d0					;string 5 = ' C  '
.t	lea	StatusTextTbl(pc),a1		;print string d0 (blank or C)
	bra.w	Fprintsmall

StatusTextTbl						;AttribStatus strings
	dc.w	$000A
	dc.b	'Ice     '
	dc.w	$000A
	dc.b	'Bench   '
	dc.w	$000A
	dc.b	'Injury P'
	dc.w	$000A
	dc.b	'Injury G'
	dc.w	$0006
	dc.b	'    '
	dc.w	$0006
	dc.b	' C  '

AttribEnergy						;Roster column: energy. tmpde word / 40, max 100
	add.w	d0,d0					;word index by player
	move.w	tmpde(a2,d0.w),d0
	ext.l	d0
	divu.w	#$28,d0
	cmp.w	#100,d0					;clamp to 100%
	ble.w	AttribPrintPct
	moveq	#$64,d0
	bra.w	AttribPrintPct

AttribFighting						;Roster column: fighting. Bit 0 of the nibble is handedness, so only bits
									;1-3 count
	andi.w	#$E,d0					;drop the handedness bit from the sum
	subq.w	#1,d1					;and one point from the maximum
AttribRating						;sum d0 of d1/15 ratings as a percentage
	mulu.w	#$64,d0					;d0 = sum * 100 / max
	divu.w	d1,d0
AttribPrintPct						;Print d0 4 wide plus padding
	moveq	#4,d1					;field width 4
	bsr.w	PushNumberWidth
	bsr.w	print
	bsr.w	printz					;trailing spaces clear the old text
	String	$20,$20,$20,$20
	rts

AttribHanded						;Roster column: handedness. Bit 0 of the sum
	andi.w	#1,d0					;0 = Righty, 1 = Lefty
	lea	HandedTextTbl(pc),a1
	bra.w	Fprintsmall

HandedTextTbl						;AttribHanded strings
	dc.w	$000A
	dc.b	'Righty  '
	dc.w	$000A
	dc.b	'Lefty   '

AttribWeight						;Roster column: Weight. 140 + 8 * rating lb
	asl.w	#3,d0
	addi.w	#$8C,d0
	bsr.w	PushNumber
	bsr.w	print
	bsr.w	printz
	dc.w	$0008
	dc.b	' lb  ',0
	rts

ScoringSummaryScreen				;"Scoring Summary": one 4 row
									;entry per goal in ScoreSum (6 bytes each). Scrolls to the end first,
									;then up/down scroll, start exits
	moveq	#$A,d0					;SetupScreen d0/d1: row offset / height
	moveq	#$1A,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,4,1,0
	moveq	#$20,d0					;title frame 32 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0018
	dc.b	$BD,6,4,'Scoring Summary',$BD,6,1,0
	moveq	#$30,d0					;away logo, then home logo
	bsr.w	PutTeamBlock
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PutTeamBlock
	bsr.w	printsmallz
	dc.w	$0034
	dc.b	$F8,6,3,0,8,$F9,1,'^Per^^Time^^Tm^^Goal/Assist^^^^^^^^P/S^^',$F9,0,0
	clr.l	d0
	move.w	(ScoreSumbytes).w,d0
	divu.w	#6,d0					;goals
	asl.w	#5,d0					;32 pixels per entry
	move.w	d0,(VertLineScrolling).w
	subi.w	#$80,d0					;4 entries fit on screen
	bpl.w	.0
	clr.w	d0
.0	move.w	d0,(SelectedPlayerIdx).w	;max scroll = end of list - 4 entries
	move.w	(VertLineScrolling).w,d0	;d0 = end position (the last goal)
.toend	bsr.w	MenuWaitVblank		;d0 = new position: first jump to the end, then -2 a frame
	bsr.w	UpdateScoringScroll
	move.w	(VertLineScrolling).w,d0
	subq.w	#2,d0
	cmp.w	(SelectedPlayerIdx).w,d0
	bge.s	.toend
	clr.w	(PlayerScrollCtr).w
.loop	bsr.w	MenuWaitVblank		;per frame: d3 = buttons held
	bsr.w	getpzjoy
	btst	#7,d3					;start: leave
	bne.w	ExitStatsScreen
	moveq	#-2,d0					;up: -2 pixels
	btst	#0,d3
	bne.w	.set
	neg.w	d0						;down: +2
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;scroll speed/direction
.scroll	bsr.w	CheckScoringScroll	;apply any pending scroll
	bra.s	.loop

CheckScoringScroll					;ScoringSummaryScreen per frame: add PlayerScrollCtr to VertLineScrolling
									;(0..SelectedPlayerIdx)
	move.w	(PlayerScrollCtr).w,d0	;0 = not scrolling
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0	;new position, must stay in 0..max
	bmi.w	rtss2
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2
UpdateScoringScroll					;set VertLineScrolling = d0. Stop on an entry boundary, draw the entry
									;coming into view, VSRAM = VertLineScrolling - $50
	move.w	(VertLineScrolling).w,d1	;d1 = old position
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$20,d0					;32 pixels per entry; remainder in the low word after swap
	swap	d0
	tst.w	d0
	bne.w	.0
	bsr.w	DrawScrollArrowsPenalty	;on an entry boundary: update arrows and stop
	clr.w	(PlayerScrollCtr).w
.0	andi.w	#$1F,d1					;was the old position on a boundary?
	bne.w	.2
	move.l	d0,-(sp)
	cmp.w	#$1E,d0					;moved back 2: draw the entry above
	bne.w	.1
	bsr.w	DrawScoringRowUp
.1	move.l	(sp)+,d0				;restore remainder
	cmp.w	#2,d0					;moved on 2: draw the entry below
	bne.w	.2
	bsr.w	DrawScoringRowDown
.2	move.w	(disflags).w,-(sp)		;set the VSRAM scroll value, as in UpdateVertScrollReg
	bset	#dfng,(disflags).w
	movea.l	#Vdata,a0
	move.l	#VSRAM_W+(2<<16),4(a0)
	moveq	#-$50,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DrawScoringRowUp					;draw goal entry (d0 high word) at the top of the window
	move.l	d0,-(sp)
	swap	d0						;d0 = entry number (quotient)
	moveq	#6,d3
	mulu.w	d0,d3					;d3 = byte offset into ScoreSum
	bsr.w	printz
	String	$BE,0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0					;scroll position in 8 pixel rows
	subq.w	#3,d0					;row just above the window, wrapped to 32 map rows
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DrawScoringRow
	move.l	(sp)+,d0
	rts

DrawScoringRowDown					;draw goal entry (d0 high word) + 4 at the bottom
	move.l	d0,-(sp)
	swap	d0
	addq.w	#4,d0					;entry 4 below the top one
	moveq	#6,d3
	mulu.w	d0,d3					;d3 = byte offset into ScoreSum
	bsr.w	printz
	String	$BE,0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0					;scroll position in 8 pixel rows
	addi.w	#$10,d0					;16 rows below the top, wrapped to 32 map rows
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DrawScoringRow
	move.l	(sp)+,d0
	rts

DrawScoringRow						;print ScoreSum entry at offset d3: time, team (bit 7 of byte 2 = away),
									;goal type (GoalTypeTbl), scorer and two assists
									;entry layout (6 bytes): word 0 = period/time, byte 2 = goal type (+ bit 7
									;away), byte 3 = scorer, bytes 4/5 = assists ($FF/negative = none)
									;clear the 4 map rows of this entry (40 wide, blank char $7FF); printy is
									;kept
	move.w	(printy).w,-(sp)
	moveq	#$28,d0					;width 40 cells
	moveq	#4,d1					;4 rows high
	move.w	#$7FF,d2				;blank tile
	bsr.w	eraser
	move.w	(sp)+,(printy).w
	;a0 = ScoreSum, d3 = byte offset of the entry; print period and time at x 1
	movea.w	#(ScoreSum-M68K_RAM),a0
	move.w	(a0,d3.w),d0
	move.w	#1,(printx).w
	bsr.w	FormatAndPrintTime
	;a2 = home or away team struct (bit 7 of byte 2 set = away)
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#7,2(a0,d3.w)
	beq.w	.0						;home goal
	adda.w	#tmsize,a2				;away team struct
.0	movea.l	tmdata(a2),a1			;team data -> team name string
	adda.w	4(a1),a1
	adda.w	(a1),a1
	move.w	#$C,(printx).w
	bsr.w	print					;team name at x $C
	;goal type text (SH2/SH/blank/PP/PP2) at x $23
	move.w	#$23,(printx).w
	lea	GoalTypeTbl(pc),a1
	move.b	2(a0,d3.w),d0
	andi.w	#$7F,d0					;strip the away bit -> string index
	bsr.w	Fprintsmall
	;scorer at x $10, then the two assists (palette attribute $E000) on the following rows at x $12
	move.w	#$10,(printx).w
	move.b	3(a0,d3.w),d0
	bsr.w	PrintScorerName
	move.w	#$E000,(printa).w
	move.w	#$12,(printx).w
	move.b	4(a0,d3.w),d0
	bsr.w	PrintScorerName			;first assist
	move.w	#$12,(printx).w
	move.b	5(a0,d3.w),d0			;second assist, falls into PrintScorerName
PrintScorerName						;print player d0 (byte, negative = none) and go down a row. it prints a
									;player not a time
	ext.w	d0						;sign extend: $FF = no player
	bmi.w	.0						;nothing to print, just advance the row
	jsr	(FormatPlayerNumInitial).l	;a1 = "NN F. Last" for player d0 of team a2
	bsr.w	print
.0	addq.w	#1,(printy).w			;next row
	rts

GoalTypeTbl							;ScoreSum byte 2 & $7F: SH2, SH, even, PP, PP2
	dc.w	$0006
	dc.b	'SH2',0
	dc.w	$0004
	dc.b	'SH'
	dc.w	$0004
	dc.b	' ',0
	dc.w	$0004
	dc.b	'PP'
	dc.w	$0006
	dc.b	'PP2',0

PenaltySummaryScreen				;"Penalty Summary": one 3 row
									;entry per penalty (4 bytes each from PenSum). Same scroll handling as
									;ScoringSummaryScreen
									;common stats screen setup (d0/d1 = first row / last row of the background
									;copied to the scroll plane)
	moveq	#$A,d0
	moveq	#$19,d1
	bsr.w	SetupScreen
	;frame (32x6) with the big title, then the two team blocks (TeamBlockMap offsets $30 and 0, 12 cells wide
	;each)
	bsr.w	printz
	String	$BD,4,1,0
	moveq	#$20,d0					;frame 32 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0018
	dc.b	$BD,5,4,'Penalty  Summary',$BD,6,1
	moveq	#$30,d0
	bsr.w	PutTeamBlock
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PutTeamBlock
	;column header line in the small font
	bsr.w	printsmallz
	dc.w	$0034
	dc.b	$F8,6,3,0,8,$F9,1,'^Per^^Time^^Tm^^Player/Penalty^^^^min^^^',$F9,0,0
	;VertLineScrolling = pixel height of all entries (entries * 24); it is the scroll position
	;of the first drawn frame, SelectedPlayerIdx = the maximum scroll (last 5 entries visible)
	clr.l	d0
	move.w	(PenSumLength).w,d0		;penalty bytes
	lsr.w	#2,d0					;/4 bytes per entry = number of penalties
	mulu.w	#$18,d0					;24 pixels per entry
	move.w	d0,(VertLineScrolling).w
	subi.w	#$78,d0					;5 entries fit on screen
	bpl.w	.0
	clr.w	d0						;fewer than 5 entries: no scrolling
.0	move.w	d0,(SelectedPlayerIdx).w	;maximum scroll position
	move.w	(VertLineScrolling).w,d0
	;intro: scroll back 2 pixels per frame from the end of the list down to the maximum scroll position
.toend	bsr.w	MenuWaitVblank		;intro scroll loop, once per frame
	bsr.w	UpdatePenaltyScroll		;set scroll to d0, drawing entries as they come into view
	move.w	(VertLineScrolling).w,d0
	subq.w	#2,d0
	cmp.w	(SelectedPlayerIdx).w,d0
	bge.s	.toend					;not there yet
	clr.w	(PlayerScrollCtr).w
	;main loop: Start leaves, up/down held set the scroll speed (-2 up, +2 down pixels per frame)
.loop	bsr.w	MenuWaitVblank		;main loop, once per frame
	bsr.w	getpzjoy				;d3 = held buttons of the pad that paused
	btst	#7,d3
	bne.w	ExitStatsScreen			;Start
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set					;up held: scroll up
	neg.w	d0						;+2
	btst	#1,d3
	beq.w	.scroll					;neither: keep the current PlayerScrollCtr (it is cleared at entry
									;boundaries)
.set	move.w	d0,(PlayerScrollCtr).w	;store the scroll step (down held: +2)
.scroll	bsr.w	CheckPenaltyScroll	;apply the step, if any
	bra.s	.loop

CheckPenaltyScroll					;PenaltySummaryScreen per frame: add PlayerScrollCtr to VertLineScrolling
									;(0..SelectedPlayerIdx)
	move.w	(PlayerScrollCtr).w,d0	;scroll step, 0 = not scrolling
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0	;new position
	bmi.w	rtss2					;above the top
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2					;past the maximum scroll
UpdatePenaltyScroll					;set VertLineScrolling = d0. Stop on an entry boundary, draw the entry
									;coming into view, VSRAM = VertLineScrolling - $50
									;d1 = old position, d0 = new position. d0 = new / 24: high word = entry
									;index, low word = pixels into it
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$18,d0
	swap	d0						;low word = remainder, high word = entry
	tst.w	d0
	bne.w	.0
	bsr.w	DrawScrollArrowsPenalty	;landed on an entry boundary: refresh arrows and stop scrolling
	clr.w	(PlayerScrollCtr).w
	;only when the old position was on a boundary does a new entry start to appear
.0	ext.l	d1						;d1 = old position / 24, remainder in the low word
	divs.w	#$18,d1
	swap	d1
	tst.w	d1
	bne.w	.2
	move.l	d0,-(sp)
	cmp.w	#$16,d0					;22 pixels in: moved up, the entry above is coming into view
	bne.w	.1
	bsr.w	DisplayPenaltyLineUp
.1	move.l	(sp)+,d0				;restore the new position quotient/remainder
	cmp.w	#2,d0					;2 pixels in: moved down, the entry below is coming into view
	bne.w	.2
	bsr.w	DisplayPenaltyLineDown
	;write the vertical scroll value (VertLineScrolling - $50) to VSRAM address 2 with graphics int disabled
.2	move.w	(disflags).w,-(sp)		;set the vertical scroll (VSRAM)
	bset	#dfng,(disflags).w		;don't int graphics while the VDP is being addressed
	movea.l	#Vdata,a0
	move.l	#VSRAM_W+(2<<16),4(a0)	;VDP command: VSRAM write, address 2
	move.w	#$FFB0,d0				;-$50
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DisplayPenaltyLineUp				;draw penalty entry (d0 high word) at the top of the window
	move.l	d0,-(sp)
	swap	d0						;d0 = entry index
	move.w	d0,d3
	asl.w	#2,d3					;d3 = byte offset into PenSum (4 per entry)
	bsr.w	printz
	String	$BE,0,0					;print on map 2 (scroll plane), priority on, x 0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0					;scroll in 8 pixel cell rows
	subq.w	#2,d0					;2 rows above the window top
	andi.w	#$1F,d0					;wrap in the 32 row map
	move.w	d0,(printy).w
	bsr.w	DisplayPenaltyEntry
	move.l	(sp)+,d0
	rts

DisplayPenaltyLineDown				;draw penalty entry (d0 high word) + 5 at the bottom
	move.l	d0,-(sp)
	swap	d0						;d0 = entry index
	addq.w	#5,d0					;the entry 5 below it
	move.w	d0,d3
	asl.w	#2,d3					;d3 = byte offset into PenSum (4 per entry)
	bsr.w	printz
	String	$BE,0,0					;print on map 2 (scroll plane), priority on, x 0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0					;scroll in 8 pixel cell rows
	addi.w	#$F,d0					;15 rows below the window top
	andi.w	#$1F,d0					;wrap in the 32 row map
	move.w	d0,(printy).w
	bsr.w	DisplayPenaltyEntry
	move.l	(sp)+,d0
	rts

DisplayPenaltyEntry					;print penalty entry at offset d3: time, team (bit 7 of byte 2 = away),
									;minutes and name from PenaltyList, player (byte 3)
									;entry layout (4 bytes): word 0 = period/time, byte 2 = penalty type (+
									;bit 7 away), byte 3 = player clear the 3 map rows of this entry (40 wide,
									;blank char $7FF); printy is kept
	move.w	(printy).w,-(sp)
	moveq	#$28,d0					;width 40 cells
	moveq	#3,d1					;3 rows high
	move.w	#$7FF,d2				;blank tile
	bsr.w	eraser
	move.w	(sp)+,(printy).w
	;a0 = PenSum, d3 = byte offset of the entry; print period and time at x 1
	movea.w	#(PenSum-M68K_RAM),a0
	move.w	(a0,d3.w),d0
	move.w	#1,(printx).w
	bsr.w	FormatAndPrintTime
	;a2 = home or away team struct (bit 7 of byte 2 set = away)
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#7,2(a0,d3.w)
	beq.w	.0						;home penalty
	adda.w	#tmsize,a2				;away team struct
.0	movea.l	tmdata(a2),a1			;team data -> team name string
	adda.w	4(a1),a1
	adda.w	(a1),a1
	move.w	#$C,(printx).w
	bsr.w	print					;team name at x $C
	;a3 = Penaltylist record for the type: byte 1 = minutes, string from +2 = penalty name
	move.b	2(a0,d3.w),d0
	andi.w	#$7F,d0					;strip the away bit
	movea.l	#Penaltylist,a3
	adda.w	(a3,d0.w),a3
	clr.w	d0
	move.b	1(a3),d0				;penalty minutes
	bsr.w	PushNumber
	move.w	#$23,(printx).w
	bsr.w	print					;minutes at x $23
	;player "NN F. Last" at x $10, then the penalty name on the next row (palette $E000)
	move.w	#$10,(printx).w
	clr.w	d0
	move.b	3(a0,d3.w),d0
	jsr	(FormatPlayerNumInitial).l
	bsr.w	print
	addq.w	#1,(printy).w
	move.w	#$13,(printx).w
	move.w	#$E000,(printa).w
	lea	2(a3),a1					;penalty name string
	bra.w	print					;print it and return

DrawScrollArrowsPenalty				;summary screen up/down arrows. Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,3,4,9,CC_SetFont,1,0	;attribute 4, map 3, x 4, y 9, font set 1 d0 = table
														;index: bit 0 = can scroll up (position > 0), bit 1 =
														;can scroll down (position < max)
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0						;1 if scrolled down at all
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1						;1 if not at the maximum
	add.b	d1,d0
	add.b	d1,d0					;+2
	lea	ScrollArrowTbl(pc),a1
	bsr.w	Fprintsmall				;print string d0 of the table
	movem.l	(sp)+,d0-d1/a1
	rts

ScrollArrowTbl						;none, up, down, both
									;each string: top glyph ($20 blank / $7B up arrow), then x-1, y+$11
									;(CC_AddX/CC_AddY), bottom glyph ($20 blank / $7D down arrow), then
									;CC_SetFont
	String	$20,$FB,$FF,$FA,$11,$20,$F9	;none
	String	$7B,$FB,$FF,$FA,$11,$20,$F9	;up arrow only
	String	$20,$FB,$FF,$FA,$11,$7D,$F9	;down arrow only
	String	$7B,$FB,$FF,$FA,$11,$7D,$F9	;both arrows

PlayoffStatsScreen					;"Playoff Stats": PlayerStatsList with d7 = 1 for the player's playoff
									;team (potree), stats from ReadTeamStats
	movem.l	a2,-(sp)
	jsr	(ReadTeamStats).l			;load the playoff team stats
	;find which team struct is the playoff team: d0 = potree[potreeteam] is compared with the word at
	;tmstruct+tmteam (the home team number); a2 = home struct if equal, else the away struct
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d0
	move.b	(a0,d0.w),d0
	movea.w	#(tmstruct-M68K_RAM),a2
	cmp.w	tmteam(a2),d0
	beq.w	.0
	adda.w	#tmsize,a2
.0	moveq	#1,d7					;playoff mode: stats come from the playoff RAM tables
	bsr.w	PlayerStatsList
	movem.l	(sp)+,a2
	rts

PlayerStatsScreen					;"Player Stats" (d7 = 0, game
									;stats, A switches team)
	clr.w	d7
PlayerStatsList						;stats screen for team a2, d7 = 0 game / 1 playoff.
									;Left/right picks the sort column (-1 goalie saves, 0-4 G A Pts SOG PIM),
									;up/down scrolls the sorted player list
									;common stats screen setup (d0/d1 = first row / last row of the background
									;copied to the scroll plane)
	moveq	#$D,d0
	moveq	#$16,d1
	bsr.w	SetupScreen
	clr.w	(DispAttribCtr).w		;sort column: -1 goalie saves, 0-4 G A Pts SOG PIM; start with goals
	clr.w	(VertLineScrolling).w	;list scrolled to the top
	;(re)draw the whole screen for team a2: frame, title, team logo, list and arrows
.redraw	clr.w	(PlayerScrollCtr).w	;redraw entry: stop any scrolling
	bsr.w	printz
	String	$BD,5,1,0
	moveq	#$1E,d0					;frame 30 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	tst.w	d7
	beq.w	.title					;game stats
	bsr.w	printbigz				;playoff stats title, no "switch teams" hint
	dc.w	$0016
	dc.b	$BD,7,4,'Playoff  Stats',$BD,$E,1
	bra.w	.team
.title	bsr.w	printsmallz			;"A - Switch Teams" hint
	dc.w	$001C
	dc.b	$F8,6,3,$C,$1A,$F9,1,'A^-^Switch^Teams',$F9,0,0
	bsr.w	printbigz
	dc.w	$0016
	dc.b	$BD,8,4,'Player  Stats',$BD,$E,1,0
.team	clr.w	d0					;TeamBlockMap offset: 0 for the home struct, $30 for the away struct
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.home
	moveq	#$30,d0
.home	bsr.w	PutTeamBlock		;draw the team block, then the list
	bsr.w	DrawStatsList
	bsr.w	DrawStatsListArrows
	;main loop per frame: Start leaves, A switches team, left/right changes the column, up/down scrolls
.loop	bsr.w	MenuWaitVblank		;input loop, once per frame
	bsr.w	getpzjoy				;d1 = new presses, d3 = held
	btst	#7,d3
	bne.w	ExitStatsScreen			;Start
	btst	#6,d1
	bne.w	.switch					;A pressed
	bsr.w	nodiag					;ignore diagonals
	moveq	#1,d0
	btst	#3,d1
	bne.w	.col					;right pressed: column +1
	neg.w	d0
	btst	#2,d1
	bne.w	.col					;left pressed: column -1
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set					;up held: scroll step -2
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll					;nothing held: keep the current scroll step
.set	move.w	d0,(PlayerScrollCtr).w	;down held: scroll step +2
.scroll	bsr.w	UpdateStatsListScroll	;apply the scroll step, if any
	bra.s	.loop
	;change the sort column, limited to -1..4 (-1 = goalie saves), then redraw the list
.col	add.w	(DispAttribCtr).w,d0	;new sort column = old +/- 1
	cmp.w	#-1,d0
	blt.s	.scroll
	cmp.w	#4,d0
	bgt.s	.scroll
	move.w	d0,(DispAttribCtr).w
	bsr.w	DrawStatsList
	bsr.w	DrawStatsListArrows
	bra.s	.scroll
	;A: toggle between the home and away team struct and redraw the screen
.switch	tst.w	d7					;No team switch in playoff stats
	bne.s	.scroll
	lea	tmsize(a2),a2
	cmpa.w	#(awtmstruct-M68K_RAM),a2
	beq.w	.redraw					;was home, now away
	movea.w	#(tmstruct-M68K_RAM),a2	;was away, back to home
	bra.w	.redraw

UpdateStatsListScroll				;stats screen per frame: scroll 0..SelectedPlayerIdx, stop every 16 pixels
									;(one row), draw the row coming into view
	move.w	(PlayerScrollCtr).w,d0	;scroll step, 0 = not scrolling
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0	;new position
	bmi.w	rtss2					;above the top
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2					;past the maximum scroll
	move.w	(VertLineScrolling).w,d1	;d1 = old position
	move.w	d0,(VertLineScrolling).w
	andi.w	#$F,d0					;pixels into the current 16 pixel row
	bne.w	.0
	bsr.w	DrawStatsListArrows		;landed on a row boundary: refresh arrows and stop scrolling
	clr.w	(PlayerScrollCtr).w
	;only when the old position was on a row boundary does a new row start to appear
.0	andi.w	#$F,d1					;old position within its row
	bne.w	SetStatsListScrollReg
	move.w	d0,-(sp)
	cmp.w	#$E,d0					;14 pixels in: moved up, draw the row above
	bne.w	.1
	bsr.w	DrawStatsRowUp
.1	move.w	(sp)+,d0				;restore the pixels into the row
	cmp.w	#2,d0					;2 pixels in: moved down, draw the row below
	bne.w	SetStatsListScrollReg
	bsr.w	DrawStatsRowDown		;falls into the scroll register write
	;write the vertical scroll value (VertLineScrolling - $68) to VSRAM address 2
SetStatsListScrollReg				;VSRAM = VertLineScrolling - $68
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w		;don't int graphics while the VDP is being addressed
	movea.l	#Vdata,a0
	move.l	#VSRAM_W+(2<<16),4(a0)	;VDP command: VSRAM write, address 2
	move.w	#$FF98,d0				;-$68
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DrawStatsRowUp						;draw the top row of the window
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3					;d3 = first visible Satt row (16 pixels per row)
	bra.w	DrawStatsRow

DrawStatsRowDown					;draw the row below the window
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3					;first visible Satt row
	addq.w	#6,d3					;6 rows further down
	bra.w	DrawStatsRow

DrawStatsList						;stats screen: column headers (sort column highlighted), title for column
									;DispAttribCtr, then sort the players by that column into Satt ($FF ends,
									;goalies only when -1) and draw the visible rows
									;"Player" column header, then the stat column headers (goalie mode: the
									;single goalie header string)
	bsr.w	printsmallz
	dc.w	$0012
	dc.b	$F8,6,3,4,$B,$F9,1,'Player',$FB,7,0
	lea	StatColumnHeaders(pc),a1
	moveq	#5,d3					;goalie mode: d3 = 5 so only the first (goalie) string is printed
	tst.w	(DispAttribCtr).w
	bmi.w	.head
	adda.w	(a1),a1					;skip the goalie header string, a1 = " G" string
	clr.w	d3						;d3 = column 0-4
.head	move.w	#$8000,(printa).w	;next column header, normal attribute
	cmp.w	(DispAttribCtr).w,d3
	bne.w	.1
	move.w	#$C000,(printa).w		;highlight the sort column
.1	bsr.w	printsmall				;print advances a1 to the next string
	addq.w	#1,d3
	cmp.w	#5,d3
	blt.s	.head
	;small frame (22x3) with the title of the sort column ("[ Goals ]" ...) from StatSortTitles
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,3,9,7,0
	moveq	#$16,d0					;frame 22 wide, 3 high
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printz
	String	$8D,$A,8,0
	lea	StatSortTitles(pc),a1
	moveq	#1,d0
	add.w	(DispAttribCtr).w,d0	;string 0 = goalie saves, 1-5 = G A Pts SOG PIM
	bsr.w	Fprintsmall
	clr.w	(printfontset).w
	;sort the players of team a2 by the chosen column into Satt (one player index per byte)
	;d6 = bit mask of players already used (bit n = player n)
	movea.w	#(Satt-M68K_RAM),a3
	clr.l	d6
	tst.w	(DispAttribCtr).w
	bpl.w	.sort
	bsr.w	GetGoalieCount			;goalie column: mark all skaters used
	bset	d0,d6					;(goalies come first in the roster: players 0 to count-1)
	subq.w	#1,d6
	not.l	d6						;bits count and up set = skaters
	;selection sort pass: find the best unused player. d4 = best key so far, d5 = its player index
.sort	moveq	#-1,d4				;Selection sort, best so far
	st	d5							;d5 = $FF: none found
	bsr.w	GetPlayerCount			;d0 = number of players, loop counts d0 down from count-1
	bra.w	.next
.player	btst	d0,d6				;candidate player d0
	bne.w	.next					;already used (or filtered out)
	clr.w	d2
	move.w	(DispAttribCtr).w,d1
	bmi.w	.4						;goalie column: key is just the tie-break byte
	bsr.w	GetStatColumn			;d2 = stat for player d0
.4	ext.l	d2						;d2 = stat value
	asl.l	#8,d2					;key = stat * 256 ...
	movea.l	tmdata(a2),a1			;walk the player records to record d0
	adda.w	(a1),a1
	move.w	d0,d1
	subq.w	#8,a1
.skip	addq.w	#8,a1				;next player record
	adda.w	(a1),a1
	dbf	d1,.skip
	move.b	#$FF,d2
	sub.b	(a1),d2					;ties: lower player byte first
	cmp.l	d4,d2					;... + ($FF - first byte of the player record)
	ble.w	.next					;not better than the best so far
	move.l	d2,d4
	move.w	d0,d5
.next	dbf	d0,.player				;next candidate
	bset	d5,d6					;used
	move.b	d5,(a3)+				;append the best player to the sorted list
	bpl.s	.sort					;until none left ($FF)
	moveq	#5,d0
.pad	st	(a3,d0.w)				;Pad with empty rows
	dbf	d0,.pad
	;SelectedPlayerIdx = maximum scroll = (entries - 7, at least 0) * 16 pixels (a3 is just past the $FF end
	;mark)
	move.w	a3,d0
	subi.w	#(Satt+6-M68K_RAM),d0	;rows past the first 7 in Satt
	bpl.w	.8
	clr.w	d0
.8	asl.w	#4,d0					;16 pixels per row
	move.w	d0,(SelectedPlayerIdx).w
	cmp.w	(VertLineScrolling).w,d0
	bcc.w	.9
	move.w	d0,(VertLineScrolling).w	;clamp the current scroll to the new maximum draw the 6 visible rows
										;starting at the current scroll position
.9	moveq	#5,d4					;6 rows
.ent	move.w	(VertLineScrolling).w,d3	;draw loop, d4 = row offset 5 to 0
	lsr.w	#4,d3
	add.w	d4,d3					;Satt row d3
	bsr.w	DrawStatsRow
	dbf	d4,.ent
	bra.w	SetStatsListScrollReg

DrawStatsRow						;stats screen row d3 of Satt: rank, name, then either the 5 stat columns
									;or goalie saves/shots/save %
									;a4 = Satt entry d3 (player index, $FF = empty row)
	movea.w	#(Satt-M68K_RAM),a4
	adda.w	d3,a4
	bsr.w	printz
	String	$BE,0,0					;print on map 2 (scroll plane), priority on, x 0
	add.w	d3,d3					;2 map rows per Satt row
	andi.w	#$1F,d3					;wrap in the 32 row map
	move.w	d3,(printy).w
	moveq	#$28,d0					;erase one row, 40 cells wide
	moveq	#1,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	tst.b	(a4)
	bmi.w	rtss2					;empty (padding) row: leave it blank
	subq.w	#1,(printy).w			;eraser moved printy down one row; back to the row rank (2 digits) at x 1
	move.w	#1,(printx).w
	move.w	a4,d0
	subi.w	#(Satt-1-M68K_RAM),d0	;rank = Satt index + 1
	moveq	#2,d1
	move.w	#$E000,(printa).w
	bsr.w	PushNumberWidth
	bsr.w	print
	;player name "NN Last" of player (a4) of team a2
	clr.w	d0
	move.b	(a4),d0
	jsr	(FormatPlayerName).l
	addq.w	#1,(printx).w
	move.w	#$8000,(printa).w
	bsr.w	print
	move.w	#$11,(printx).w			;stat columns start at x $11
	tst.w	(DispAttribCtr).w
	bmi.w	.goalie
	;skaters: the 5 stat columns (G A Pts SOG PIM), 4 digits each, sort column highlighted
	clr.w	d5
.col	clr.w	d0					;next stat column d5
	move.b	(a4),d0
	move.w	d5,d1					;column
	bsr.w	GetStatColumn
	move.w	d2,d0
	moveq	#4,d1
	bsr.w	PushNumberWidth
	move.w	#$8000,(printa).w
	cmp.w	(DispAttribCtr).w,d5
	bne.w	.1
	move.w	#$C000,(printa).w		;highlighted sort column
.1	bsr.w	print					;print the number
	addq.w	#1,d5
	cmp.w	#5,d5
	bne.s	.col
	bra.w	.x
	;goalies: saves, shots and save % (saves*100/shots)
.goalie	clr.w	d0					;Shots against
	move.b	(a4),d0
	moveq	#3,d1					;column 3 (SOG array)
	bsr.w	ReadStatColumn
	clr.w	d0
	move.b	(a4),d0
	moveq	#0,d1					;goals against
	move.w	d2,-(sp)				;keep shots
	bsr.w	ReadStatColumn
	move.w	(sp)+,d0
	move.w	d0,d3					;d3 = shots
	sub.w	d2,d0					;saves = shots - goals against
	bpl.w	.2
	clr.w	d0
.2	move.w	d0,d2					;d2 = saves
	moveq	#4,d1
	bsr.w	PushNumberWidth
	addq.w	#1,(printx).w
	bsr.w	print					;saves
	move.w	d3,d0
	moveq	#4,d1
	bsr.w	PushNumberWidth
	addq.w	#2,(printx).w
	bsr.w	print					;shots
	tst.w	d3
	beq.w	.3						;no shots: percentage is just d2 (0)
	mulu.w	#$64,d2
	divu.w	d3,d2					;saves * 100 / shots
.3	move.w	d2,d0					;d2 = save % (or 0)
	moveq	#4,d1
	bsr.w	PushNumberWidth
	addq.w	#2,(printx).w
	bsr.w	print					;save %
	bsr.w	printz
	String	$25						;'%'
.x	rts								;done

GetStatColumn						;d2 = stat column d1 for player d0. Goalies only have PIM (column 4,
									;mapped to 1 via btst d1,#6)
									;the roster lists goalies first: player index < goalie count means d0 is a
									;goalie
	move.w	d0,-(sp)
	bsr.w	GetGoalieCount
	move.w	d0,d2
	move.w	(sp)+,d0
	cmp.w	d2,d0
	bge.w	ReadStatColumn			;skater: read the column as is
	clr.w	d2						;goalie: columns 1 and 2 (A, Pts) show column 1 (assists), the rest 0
	btst	d1,#6					;bit d1 of %110: set for columns 1 and 2
	beq.w	rtss2
	moveq	#1,d1					;use the assists column
ReadStatColumn						;d2 = stat column d1 for player d0. d7 = 0: team struct bytes
									;(StatColumnOffsets), d7 = 1: playoff words (StatsOffsetTbl2).
									;Second offset of a pair is added ($FFFF/0 = none)
	tst.w	d7
	bne.w	.stats					;playoff stats
	;game stats: byte arrays in the team struct a2, indexed by player number d0
	lea	StatColumnOffsets(pc),a1
	asl.w	#2,d1					;2 words per column
	adda.w	d1,a1
	move.w	(a1),d1					;first array offset
	add.w	d0,d1
	clr.w	d2
	move.b	(a2,d1.w),d2
	move.w	2(a1),d1				;second array offset, negative = none
	bmi.w	rtss2
	add.w	d0,d1
	clr.w	d3
	move.b	(a2,d1.w),d3
	add.w	d3,d2					;d2 = first + second (Pts = G + A)
	rts
	;playoff stats: word arrays in RAM, d0 doubled to a word index
.stats	asl.w	#2,d1				;2 words per column
	add.w	d0,d0
	clr.w	d2
	bsr.w	GetStatsValue
	addq.w	#2,d1					;second table of the pair
	bsr.w	GetStatsValue
	lsr.w	#1,d0					;restore the player index
	rts

GetStatsValue						;d2 += word d0 of the RAM table at StatsOffsetTbl2+d1 (0 = none)
	movea.l	#StatsOffsetTbl2,a1
	tst.w	(a1,d1.w)
	beq.w	rtss2					;no table: add nothing
	movea.w	(a1,d1.w),a1			;RAM address of the word array (sign extended)
	add.w	(a1,d0.w),d2			;d0 = word index of the player
	rts

StatsOffsetTbl2						;playoff stat RAM tables per column (G, A, G+A, SOG, PIM) 2 words per
									;column: RAM address of the word array and an optional second one to add
									;(0 = none)
	dc.w	(statsbuffer-M68K_RAM),0,(statsbuffer+(maxros*2)-M68K_RAM),0,(statsbuffer-M68K_RAM),(statsbuffer+(maxros*2)-M68K_RAM)
	dc.w	(statsbuffer+(maxros*4)-M68K_RAM),0,(statsbuffer+(maxros*6)-M68K_RAM),0
StatColumnOffsets					;team struct byte arrays per column, same order
									;2 words per column: offset in the team struct of the first array and the
									;second one to add ($FFFF = none)
	dc.w	$B4,$FFFF,$CE,$FFFF,$B4,$CE,$E8,$FFFF,$102,$FFFF

StatColumnHeaders					;stats screen column headers (goalie header, then 5 columns) length word +
									;text per string, the first one is skipped (adda.w (a1),a1) in skater mode
	dc.w	$0016
	dc.b	'Saves Shots Save %  '
	dc.w	$0006
	dc.b	'   G'
	dc.w	$0006
	dc.b	'   A'
	dc.w	$0006
	dc.b	' Pts'
	dc.w	$0006
	dc.b	' SOG'
	dc.w	$0006
	dc.b	' PIM'
StatSortTitles						;Sort column
									;titles, [ ] are the left/right arrows
	dc.w	$0016
	dc.b	'    Goalie Saves   ]'
	dc.w	$0016
	dc.b	'[      Goals       ]'
	dc.w	$0016
	dc.b	'[     Assists      ]'
	dc.w	$0016
	dc.b	'[      Points      ]'
	dc.w	$0016
	dc.b	'[  Shots On Goal   ]'
	dc.w	$0016
	dc.b	'[ Penalty Minutes   '

DrawStatsListArrows					;stats screen up/down arrows. Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,3,2,$B,CC_SetFont,1,0	;attribute 4, map 3, x 2, y $B, font set 1 d0 =
															;table index: bit 0 = can scroll up (position >
															;0), bit 1 = can scroll down (position < max)
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0						;1 if scrolled down at all
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1						;1 if not at the maximum
	add.b	d1,d0
	add.b	d1,d0					;+2
	lea	ScrollArrowTbl2(pc),a1
	jsr	(Fprintsmall).l				;print string d0 of the table
	movem.l	(sp)+,d0-d1/a1
	rts

ScrollArrowTbl2						;none, up, down, both
									;same layout as ScrollArrowTbl but the bottom glyph is $C rows below the
									;top one
	String	$20,$FB,$FF,$FA,$C,$20,$F9	;none
	String	$7B,$FB,$FF,$FA,$C,$20,$F9	;up arrow only
	String	$20,$FB,$FF,$FA,$C,$7D,$F9	;down arrow only
	String	$7B,$FB,$FF,$FA,$C,$7D,$F9	;both arrows

StatsReport							;"Game Statistics": both teams' totals. Start
									;exits
									;common stats screen setup (d0/d1 = first row / last row of the background
									;copied to the scroll plane)
	moveq	#9,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	;frame (32x6) with the big title and the two team blocks (TeamBlockMap offsets $30 and 0)
	bsr.w	printz
	String	$BD,4,1,0
	moveq	#$20,d0					;frame 32 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0018
	dc.b	$BD,6,4,'Game  Statistics',$BD,6,1
	moveq	#$30,d0
	bsr.w	PutTeamBlock
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PutTeamBlock
	bsr.w	DisplayStats			;the table of team totals
	;wait for Start (d1 bit 7 = new press), then leave
.loop	bsr.w	WaitVSyncAndReadInput	;wait for a new button press
	btst	#7,d1
	bne.w	ExitStatsScreen
	bra.s	.loop

DisplayStats						;team logos, then each TeamStatTextTbl row
									;centred with home value at x $22 and away at x 9 team blocks
									;(TeamBlockMap offset $30 at x 2, 0 at x $1A), both at y 9
	bsr.w	printz
	String	$BE,2,9,0
	moveq	#$30,d0
	bsr.w	PutTeamBlock
	bsr.w	printz
	String	$BE,$1A,9,0
	moveq	#0,d0
	bsr.w	PutTeamBlock
	bsr.w	printz
	String	$BE,0,$C,0				;first table row at y $C
	moveq	#7,d6					;8 table rows
	lea	TeamStatTextTbl(pc),a1
	;a1 = table entry: label string, then the two stat offsets
.row	move.w	(a1),d0				;label length word
	lsr.w	#1,d0					;half the label width
	neg.w	d0
	addi.w	#$15,d0					;centre the label around x $15
	move.w	d0,(printx).w
	bsr.w	print					;print advances a1 past the label to the stat offsets
	movea.l	a1,a0					;a0 = stat offsets
	move.w	#$22,(printx).w
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	PrintStatValue			;home team value, centred at x $22
	move.w	#9,(printx).w
	lea	tmsize(a2),a2
	bsr.w	PrintStatValue			;away team value, centred at x 9
	lea	4(a0),a1					;next table entry
	addq.w	#2,(printy).w			;2 map rows per table row
	dbf	d6,.row
	rts

PrintStatValue						;from 92 DisplayStats .ss. print TeamStatTextTbl entry a0 for team a2
									;centred at printx:
									;value (offset $A is a time), "/second" if any, " (pct%)" for passing
									;a3 = mesarea, an empty string (length word 2) the value text is appended
									;to
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#2,(a3)
	move.w	(a0),d0					;first stat offset
	move.w	(a2,d0.w),d0			;value in the team struct
	cmpi.w	#$A,(a0)
	beq.w	.0						;offset $A (attack time) is formatted as a time instead
	bsr.w	PushNumber
.0	cmpi.w	#$A,(a0)				;attack time: format d0 as minutes:seconds
	bne.w	.1
	bsr.w	PushTime
.1	bsr.w	appstring				;append the value text
	move.w	2(a0),d0				;second offset, negative = none
	bmi.w	.x
	bsr.w	appendz
	String	$2F						;'/'
	move.w	(a2,d0.w),d0
	bsr.w	PushNumber
	bsr.w	appstring
	cmpi.w	#$14,(a0)				;offset $14 (passing) also gets a percentage
	bne.w	.x
	bsr.w	appendz
	String	$20,$28					;' ('
	move.w	(a0),d0
	move.w	(a2,d0.w),d0
	mulu.w	#$64,d0					;first * 100 / second
	move.w	2(a0),d1
	move.w	(a2,d1.w),d1
	beq.w	.2						;second is 0: no divide
	divu.w	d1,d0
.2	bsr.w	PushNumber				;percentage text
	bsr.w	appstring
	bsr.w	appendz
	String	$25,$29					;'%)'
	;centre: printx -= half the text length, then print the string a1 (mesarea)
.x	movea.w	a3,a1					;a1 = the built string (mesarea)
	move.w	(a1),d0					;length word
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bra.w	print

TeamStatTextTbl						;label, then team struct stat offset and second offset ($FFFF none)
	dc.w	$0008
	dc.b	'Score',0
	dc.w	$C,$FFFF				;tmscore
	dc.w	$0008
	dc.b	'Shots',0
	dc.w	0,$FFFF					;tmshots
	dc.w	$000C
	dc.b	'Power Play'
	dc.w	2,4						;tmPwrGoals / tmPwrPlays
	dc.w	$000C
	dc.b	'Penalties',0
	dc.w	6,8						;tmPenalties / tmPenmin
	dc.w	$000E
	dc.b	'Faceoffs Won'
	dc.w	$E,$FFFF				;team struct offset $E
	dc.w	$000E
	dc.b	'Body Checks',0
	dc.w	$10,$FFFF				;team struct offset $10
	dc.w	$000E
	dc.b	'Attack Zone',0
	dc.w	$A,$FFFF				;tmATOP, shown as a time
	dc.w	$000A
	dc.b	'Passing',0
	dc.w	$14,$12					;offsets $14 / $12, also shown as a percentage

CrowdMeterScreen					;"Crowd Meter": current, average
									;and peak crowd level in dB. Start exits
									;common stats screen setup (d0/d1 = first row / last row of the background
									;copied to the scroll plane)
	moveq	#9,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	;frame (28x6) with the big title and the two team blocks (TeamBlockMap offsets $30 and 0)
	bsr.w	printz
	String	$BD,6,1,0
	moveq	#$1C,d0					;frame 28 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0014
	dc.b	$BD,9,4,'Crowd  Meter',$BD,6,1
	moveq	#$30,d0
	bsr.w	PutTeamBlock
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PutTeamBlock
	bsr.w	PrintCrowdMeter			;the three level rows
	;wait for Start (d1 bit 7 = new press), then leave
.loop	bsr.w	WaitVSyncAndReadInput	;wait for a new button press
	btst	#7,d1
	bne.w	ExitStatsScreen
	bra.s	.loop

PrintCrowdMeter						;crowd meter rows: CwdExciteLvl, average (SumCwdExciteLvl /
									;NumCwdExciteLvl samples) and peak (MaxCwdExciteLvl)
	bsr.w	printsmallz
	dc.w	$0016
	dc.b	$F8,4,2,4,$C,'Current Level',$FD,$1C
	move.w	(CwdExciteLvl).w,d0		;row 1: current level
	bsr.w	PrintCrowdDB
	bsr.w	printsmallz
	dc.w	$0016
	dc.b	$FD,4,$FA,2,'Average Level',$FD,$1C,0
	move.l	(SumCwdExciteLvl).w,d0	;row 2: average = sum / number of samples
	divu.w	(NumCwdExciteLvl).w,d0
	bsr.w	PrintCrowdDB
	bsr.w	printsmallz
	dc.w	$0012
	dc.b	$FD,4,$FA,2,'Peak Level',$FD,$1C
	move.w	(MaxCwdExciteLvl).w,d0	;row 3: peak level, falls into PrintCrowdDB
PrintCrowdDB						;print crowd level d0 as sqrt(d0*4) + 65 " dB"
	ext.l	d0
	asl.w	#2,d0					;level * 4
	bsr.w	Sroot					;d0 = square root
	addi.w	#$41,d0					;+ 65
	moveq	#3,d1					;3 digits
	bsr.w	PushNumberWidth
	bsr.w	print
	bsr.w	printz
	dc.w	$0006
	dc.b	' dB',0
	rts

SetupScreen							;common start for the stats screens: blank, 40 cell mode, load framer and
									;small font, draw the background bitmap, copy rows d0-d1 of it to map 3 at
									;row printy+d0 and clear map 2
	movem.l	d0-d1/a2,-(sp)			;keep d0/d1 (first/last row) and a2 (team) for the caller
	bsr.w	forceblack
	bclr	#dfok,(disflags).w		;graphics not ready for transfer
	;video mode: clear the first sprite and switch the VDP to 40 cell mode
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	move.w	(VSPRITES).w,d0
	bsr.w	Vmaddr
	move.l	#0,(a0)					;clear first sprite
	move.w	#$8C81,4(a0)			;VDP reg 12: 40 cell mode
	move.w	#6,(Map3col).w			;map 3 is 64 cells wide in 40 cell mode
	IF REV=2
	move.w	#$8D00,4(a0)			;Rev B: VDP reg 13 = 0 (horizontal scroll table at VRAM 0)
	clr.w	d0
	bsr.w	Vmaddr
	move.l	#0,(a0)
	ENDIF
	move.w	(sp)+,(disflags).w
	bclr	#df32c,(disflags).w		;not in 32 cell mode
	;load the frame graphics and the small font tiles
	move.w	(framercset).w,d4
	movea.l	#FramerMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$91234567,$89ABCDEF		;inline 8 byte color remap table (skipped on return, not code)
	move.w	(smallfontchars).w,d4
	bsr.w	AddSmallFont
	;draw the whole EASNBGMap bitmap (map at EASNBGMap + its second long), size from its first two words,
	;on map 3 at 0,0
	bsr.w	printz
	String	$BD,0,0
	movea.l	#EASNBGMap,a1
	adda.l	4(a1),a1
	movea.w	#null,a2
	clr.w	d0						;start x/y 0 in the map
	clr.w	d1
	move.w	(a1),d2					;map width
	move.w	2(a1),d3				;map height
	IF REV=2
	moveq	#1,d4					;Rev B starts the tiles at char 1
	ELSE
	clr.w	d4
	ENDIF
	moveq	#0,d5					;no palette lines
	bsr.w	dobitmap
	;copy the rows d0 to d1 (from the caller's stack copy) of the EASNBGMap bitmap, 40 wide, to map 3 at row
	;printy+d0
	bsr.w	printz
	String	$FD,0,0					;map 3, attribute 0, x 0 y 0
	movem.l	(sp),d0-d1/a2			;peek at the saved d0/d1/a2 without popping
	add.w	d0,(printy).w
	movea.l	#EASNBGMap,a0			;a0 = palette (first long), a1 = map (second long)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	move.w	d1,d3
	sub.w	d0,d3					;height = last row - first row
	move.w	d0,d1					;start y = first row
	clr.w	d0						;start x 0
	moveq	#$28,d2					;width 40
	IF REV<2
	clr.w	d4
	ENDIF							;Rev B leaves d4 as it is
	moveq	#$D,d5					;copy palette lines 0, 2 and 3
	bsr.w	dobitmap
	;load the second small font set after the bitmap tiles (dobitmap's DecompressGraphicsPlain leaves d4 = end
	;char + 1)
	move.w	d4,(smallfont2chars).w
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$D1234567,$89ABCDEF		;inline 8 byte color remap table (skipped on return, not code) blank map 2
									;(64x32 cells of char $7FF) from 0,0
	bsr.w	printz
	String	$FE,0,0					;map 2, attribute 0, x 0 y 0
	moveq	#$40,d0
	moveq	#$20,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	#$18,(palcount).w		;start a palette fade in
	movem.l	(sp)+,d0-d1/a2
	rts

ExitStatsScreen						;leave a stats screen: back to 32 cell mode, reload the rink, font and
									;framer graphics, rebuild the rink map and player colours
	bsr.w	forceblack
	;video mode: back to 32 cell mode (undoes SetupScreen)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	IF REV=2
	move.w	(VSCRLPM).w,d0			;Rev B: clear the first sprite and set VDP reg 13 (horizontal scroll
	bsr.w	Vmaddr					;table) from VSCRLPM before going back to 32 cell mode
	move.l	#0,(a0)
	move.w	#$8D00,d0
	move.b	(VSCRLPM).w,d0
	lsr.b	#2,d0
	move.w	d0,4(a0)
	ELSE
	movea.l	#Vdata,a0
	ENDIF
	move.w	#$8C00,4(a0)			;VDP reg 12: 32 cell mode
	move.w	#5,(Map3col).w			;map 3 is 32 cells wide again
	move.w	(sp)+,(disflags).w
	bset	#df32c,(disflags).w		;32 cell mode on
	;reload the tiles the stats screen overwrote: rink, small font (with its own remap) and framer
	move.w	(rinkvrcset).w,d4
	movea.l	#IceRinkMap+8,a2
	bsr.w	DecompressGraphicsPlain
	move.w	(smallfontchars).w,d4
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$43434567,$89ABCDEF		;inline 8 byte color remap table (skipped on return, not code)
	move.w	(framercset).w,d4
	bsr.w	AddFramer
	;restore the palettes; setplayercolors returns to the caller
	jsr	(setupIceRinkPal).l
	jmp	(setplayercolors).l

TimeoutMenu							;pause menu "Timeout" for team a2: uses the
									;team's timeout (tmflags bit 2, so Pausemode shows PauseText2 from now
									;on), prints "Timeout" in a frame with the team name, re-energizes both
									;teams and waits $78 frames
									;the Timeout item is going away: both menu state words (menuitem,
									;menuitem+2) are decremented
	subq.w	#1,(menuitem).w
	subq.w	#1,(menuitem+2).w
	move.l	#PauseText2,(menulist).l	;pause menu without Timeout
	bset	#tmftimeout,tmflags(a2)	;timeout used
	;frame at x 5, y $C, then "Timeout" and the team name (centred at x $11) inside it
	bsr.w	printz
	String	$BD,5,$C
	moveq	#$16,d0					;frame 22 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BD,$C,$E,'Timeout',$BD,$11,$F
	movea.l	tmdata(a2),a1			;team name, centred
	adda.w	4(a1),a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
	;both teams get full energy
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	reenergizeteam
	adda.w	#tmsize,a2
	bsr.w	reenergizeteam
	moveq	#$78,d0					;wait $78 vblanks or until a button press; waitx returns to the caller
	bra.w	waitx

SelectGoalieMenu					;from 92 Pausemode .go. pick team a2's goalie from a
									;list (0 = no goalie). Start/C confirms; a change is stored in
									;tmgoalie(a2)
									;and setpersonel is called
									;save the pause menu state; menuitem = selected row (0 = "no goalie", n =
									;goalie n-1), menuitem+2 = number of goalies (last row) while this list is
									;up
	move.w	(menuitem).w,-(sp)
	move.w	(menuitem+2).w,-(sp)
	bsr.w	GetGoalieCount
	move.w	d0,(menuitem+2).w
	;frame at x 4, y $C: 24 wide, 3 + goalie count rows high
	bsr.w	printz
	String	$BD,4,$C,0
	moveq	#$18,d0
	moveq	#3,d1
	add.w	(menuitem+2).w,d1
	bsr.w	Framer
	;start on the team's current goalie (tmgoalie + 1, a negative tmgoalie gives row 0)
	move.w	tmgoalie(a2),d0
	bpl.w	.0
	moveq	#-1,d0
.0	addq.w	#1,d0					;row = goalie index + 1 (0 = no goalie)
	move.w	d0,(menuitem).w
	;menu loop: redraw, wait for a new press (d1)
.loop	bsr.w	DrawGoalieSelectList	;menu loop: redraw the list
	bsr.w	WaitVSyncAndReadInput
	btst	#7,d1
	bne.w	.done					;Start confirms
	btst	#5,d1
	bne.w	.done					;C confirms
	btst	#1,d1
	beq.w	.up						;down not pressed
	move.w	(menuitem).w,d0
	addq.w	#1,d0
	cmp.w	(menuitem+2).w,d0
	bgt.s	.loop					;already on the last row
	move.w	d0,(menuitem).w
.up	btst	#0,d1					;up pressed: move the selection up
	beq.s	.loop
	subq.w	#1,(menuitem).w
	bpl.s	.loop
	clr.w	(menuitem).w			;stop at the first row
	bra.s	.loop
	;confirm: d0 = chosen goalie index (row - 1, -1 = no goalie)
.done	move.w	(menuitem).w,d0		;confirmed
	subq.w	#1,d0
	bpl.w	.set
	cmpi.w	#-1,tmgoalie(a2)
	blt.w	.x						;"no goalie" chosen and tmgoalie is already below -1: no change
.set	move.w	d0,tmgoalie(a2)		;store the chosen goalie
	jsr	setpersonel					;set the players on ice of team a2 according to its registers
.x	move.w	(sp)+,(menuitem+2).w	;restore the pause menu state
	move.w	(sp)+,(menuitem).w
	rts

DrawGoalieSelectList				;from 92 Pausemode .gnum. draw the goalie list, row menuitem highlighted,
									;each goalie with his two digit number
									;rows from y $D, d0 = row 0..count (row 0 = "no goalie"), d1 = loop
									;counter (menuitem+2 + 1 rows)
	move.w	#$D,(printy).w
	move.w	(menuitem+2).w,d1
	moveq	#0,d0
.row	move.w	#5,(printx).w		;next list row d0
	move.w	#$A000,(printa).w
	cmp.w	(menuitem).w,d0
	bne.w	.1
	move.w	#$8000,(printa).w		;selected row uses attribute $8000
	;clear the row with 22 spaces
.1	bsr.w	printz					;blank the row with the chosen attribute
	dc.w	$0018
	dc.b	'                      '
	tst.w	d0
	bne.w	.player
	move.w	#$B,(printx).w
	bsr.w	printz
	dc.w	$000C
	dc.b	'no goalie',0
	bra.w	.next
	;goalie row: a1 = player record number d0-1 of team a2 (records are a length word + 8 bytes each)
.player	movea.l	tmdata(a2),a1		;goalie row: find the player record
	adda.w	(a1),a1
	move.w	d0,d2
	subq.w	#1,d2
	bra.w	.3
.skip	adda.w	(a1),a1				;next player record
	addq.w	#8,a1
.3	dbf	d2,.skip					;repeat d0-1 times
	move.w	#8,(printx).w
	bsr.w	print					;goalie name at x 8
	;number: the first record byte as two BCD digits ('0' + nibble) in TextBuffer, printed as a 2 char string
	;at x 5
	move.b	(a1),d2
	lsr.b	#4,d2
	addi.b	#$30,d2
	move.b	d2,(TextBuffer).w		;high nibble
	move.b	(a1),d2
	andi.b	#$F,d2
	addi.b	#$30,d2
	move.b	d2,(TextBuffer+1).w		;low nibble
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#4,(a1)					;string length word (2 chars + 2)
	move.w	#5,(printx).w
	bsr.w	print
.next	addq.w	#1,(printy).w		;next map row and list row
	addq.w	#1,d0
	dbf	d1,.row
	rts

GetGoalieCount						;d0 = goalies on team a2 (nibbles in the team data word at GoalieOdds)
	movem.l	d1/a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	GoalieOdds(a0),a0
	move.w	(a0),d1					;word with one nibble per goalie slot
	clr.w	d0
.count	addq.w	#1,d0				;count nibbles by shifting 4 bits out until the word is 0
	asl.w	#4,d1
	bne.s	.count
	movem.l	(sp)+,d1/a0
	rts

GetForwardCount						;d0 = forwards on team a2 (high nibble of team data byte 3 at the offset
									;in word 8)
	movem.l	a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	8(a0),a0
	move.b	3(a0),d0
	lsr.w	#4,d0					;high nibble = forward count
	andi.w	#$F,d0
	movem.l	(sp)+,a0
	rts

GetPlayerCount						;d0 = players on team a2 (records until a length word of 2)
	movem.l	a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0					;a0 = first player record
	clr.w	d0
loopthroughplayers					;one pass per record: advance by the record's length word plus 8 bytes
	addq.w	#1,d0
	adda.w	(a0),a0
	addq.w	#8,a0
	cmpi.w	#2,(a0)					;a length word of 2 marks the end (no more records)
	bne.s	loopthroughplayers
	movem.l	(sp)+,a0
	rts

WaitVSyncAndReadInput				;from 92 Pausemode .rjoy. wait for Vcount to change and a new button press
									;(d1)
	move.w	(Vcount).w,d1
.wait	cmp.w	(Vcount).w,d1		;has Vcount changed?
	beq.s	.wait					;spin until the vblank counter changes
	bsr.w	getpzjoy				;d1 = new presses, d3 = held
	bsr.w	nodiag					;drop diagonal presses
	tst.b	d1
	beq.s	WaitVSyncAndReadInput	;nothing new pressed: wait again
	rts
