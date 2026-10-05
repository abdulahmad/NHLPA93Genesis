;	NHLPA Hockey 93 (retail) segment $6C0A-$8AC3
;	93-only stats, line editor, roster, scoring/penalty summary, team stats,
;	crowd meter and goalie select screens. Not in NHL 92.
;	Global names from the IDA export (Rev A listing). Entry points IDA left
;	unnamed are named from the screen title they print.
;	Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	Inline print strings after printz/printsmallz/printbigz/appendz use the
;	String macro or a dc.w length (length word includes itself, padded to a word).

ShowScores	;IDA: no label (Rev A $6C18). "Scores" screen: lists the other games in
	;gstruct with both teams, scores and period. Up/down scroll, start exits.
	;Entered from outside this segment (menu item handler)
	moveq	#6,d0			;SetupScreen d0/d1: bitmap row offset / height
	moveq	#$1A,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,5,0
	moveq	#$1E,d0			;frame 30 wide, 6 high
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	String	$BD,$E,3,'Scores',$BD,$F,1
	movea.l	#unk_7CF4C,a1
	lea	8(a1),a2
	adda.l	4(a1),a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d5
	bsr.w	dobitmap
	subq.w	#8,(printx).w
	jsr	(loc_F0F6).l
	bsr.w	printsmallz
	String	$F8,4,2,4,0,0
	clr.w	(VertLineScrolling).w
	bsr.w	UpdateVertScrollReg
	jsr	(GetShifter).l		;d1 = number of games to list
	move.w	d1,d3
	ble.w	.skip
.game	bsr.w	DisplayGameInfo		;IDA: loc_6C8C
	dbf	d3,.game
.skip	clr.w	(SelectedPlayerIdx).w	;IDA: loc_6C94
	move.w	(printy).w,d0
	subi.w	#$15,d0			;rows printed past row $15 can be scrolled to
	bmi.w	.loop
	asl.w	#3,d0			;8 pixels per row
	move.w	d0,(SelectedPlayerIdx).w	;max scroll
	bsr.w	DrawScrollArrows	;IDA: loc_6CAA
.loop	bsr.w	MenuWaitVblank		;IDA: loc_6CAE
	bsr.w	getpzjoy
	btst	#7,d3			;start: leave
	bne.w	ExitAttributeScreen2
	moveq	#-2,d0			;up: scroll -2 pixels a frame
	btst	#0,d3
	bne.w	.set
	neg.w	d0			;down: +2
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;IDA: loc_6CD2
.scroll	bsr.w	UpdatePlayerScroll	;IDA: loc_6CD6
	bra.s	.loop

UpdatePlayerScroll	;called every frame by ShowScores. Add PlayerScrollCtr to
	;VertLineScrolling (0..SelectedPlayerIdx). On a 24 pixel boundary redraw the
	;arrows and stop. Falls into UpdateVertScrollReg
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss2
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divu.w	#$18,d0
	swap	d0			;remainder
	tst.w	d0
	bne.w	UpdateVertScrollReg	;not on a 3 row boundary yet
	bsr.w	DrawScrollArrows
	clr.w	(PlayerScrollCtr).w

UpdateVertScrollReg	;write VSRAM word 1 = VertLineScrolling - $30
	;(playfield B vertical scroll). Saves disflags
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng: don't int graphics
	movea.l	#VDP_DATA,a0
	move.l	#$40020010,4(a0)	;VSRAM write, address 2
	move.w	#$FFD0,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DisplayGameInfo	;print game d3 of gstruct (2 team rows and period label).
	;Skips the current game and games with gsflags bit 1 or 2 set
	cmp.w	(gamenum).w,d3
	beq.w	rtss2			;current game
	moveq	#$10,d0			;gssize
	mulu.w	d3,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	btst	#1,$E(a0)		;gsflags(a0)
	bne.w	rtss2
	btst	#2,$E(a0)
	bne.w	rtss2
	move.w	2(a0),d0		;first team / score
	move.w	$C(a0),d1
	bsr.w	PrintGameInfo
	addq.w	#1,(printy).w
	move.w	(a0),d0			;second team / score
	move.w	$A(a0),d1
	bsr.w	PrintGameInfo
	move.w	8(a0),d0		;period, 1 based
	subq.w	#1,d0
	movea.l	#PerLabels,a1
	move.w	#$1C,(printx).w
	jsr	(PrintStringFromList).l
	addq.w	#2,(printy).w
	rts

PrintGameInfo	;print team d0's name at x 6 and score d1 (2 digits) at x $18
	movea.w	#$314,a1		;team address table
	asl.w	#2,d0
	movea.l	(a1,d0.w),a1
	adda.w	4(a1),a1		;team name
	move.w	#6,(printx).w
	bsr.w	print
	move.w	#$18,(printx).w
	move.w	d1,d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print

DrawScrollArrows	;ShowScores up/down arrows. Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	bsr.w	printsmallz
	String	$F8,4,3,4,6,$F9,1,0
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0			;1 if scrolled down at all
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1			;1 if more below
	add.b	d1,d0
	add.b	d1,d0			;string = up + 2*down
	lea	ScrollArrowTable(pc),a1
	jsr	(PrintStringFromList).l
	movem.l	(sp)+,d0-d1/a1
	rts

ScrollArrowTable	;DrawScrollArrows strings: none, up, down. Only 3 entries (the
	;penalty and attribute versions have a 4th for both arrows)
	String	$20,$FB,$FF,$FA,$13,$20,$F9
	String	$7B,$FB,$FF,$FA,$13,$20,$F9
	String	$20,$FB,$FF,$FA,$13,$7D,$F9

LineEditor	;IDA: no label (Rev A $6E16). "Line Editor" screen for team a2.
	;Pick a line slot, then a player to put there. Entered from outside this
	;segment (menu item handler)
	bset	#0,tmflags(a2)		;set on entry to the line editor
	moveq	#0,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	clr.w	(DispAttribCtr).w
	clr.w	(PlayerScrollCtr).w
	move.w	#1,(TestList).w		;cursor = first slot
LineEditorRedraw	;IDA: loc_6E32. Clear the screen and redraw everything.
	;Also entered from ExitAttributeScreen when its menu returns nonzero
	bsr.w	printsmallz
	String	$FF,2,$FD,0,$FC,0
	moveq	#$28,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	st	(byte_FFBF24).w		;force DrawAttributeMenu to redraw the icons
	bsr.w	ClearMenuFlags
LineEditorMenu	;IDA: loc_6E52. Slot cursor loop. Also entered from
	;SelectAttributeItem when it is done
	bsr.w	DrawTeamScreen
	bsr.w	DrawAttributeMenu
.loop	bsr.w	MenuWaitVblankWrapper	;IDA: loc_6E5A
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	btst	#7,d1			;start: exit menu
	bne.w	ExitAttributeScreen
	btst	#5,d1			;C: pick a player for this slot
	bne.w	SelectAttributeItem
	moveq	#1,d0			;down: next slot
	btst	#1,d1
	bne.w	.move
	moveq	#-1,d0			;up: previous slot
	btst	#0,d1
	bne.w	.move
	moveq	#8,d0			;right: next line (8 slots per line)
	btst	#3,d1
	bne.w	.move
	moveq	#-8,d0			;left: previous line
	btst	#2,d1
	beq.s	.loop
.move	add.w	(TestList).w,d0		;IDA: loc_6E9C
	tst.w	(OptLine).w
	beq.w	.set
	cmp.w	#1,d0
	blt.s	.loop			;OptLine set: only slots 1-5
	cmp.w	#5,d0
	bgt.s	.loop
.set	lea	LineCursorTable(pc),a0	;IDA: loc_6EB4
	move.b	8(a0,d0.w),(TestList+1).w	;wrap/skip through the table
	bsr.w	DrawAttributeMenu
	bra.s	.loop

MenuWaitVblankWrapper	;thunk to MenuWaitVblank (menu93)
	bra.w	MenuWaitVblank

SelectAttributeItem	;line editor: C pressed on slot TestList. Build the list of
	;players that can go in the slot in Satt (roster order is goalies, forwards,
	;defense) and let the user pick one
	;(left/right pages the attribute columns). C stores the pick with
	;UpdatePlayerAttribute, start goes back. Both return to LineEditorMenu
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	bsr.w	ProcessNibble
	move.w	(TestList).w,d2
	andi.w	#7,d2			;slot within the line
	cmp.w	#2,d2
	bgt.w	.n			;slots 3-5 (forwards): after the goalies
	add.w	d0,d1			;slots 1-2 (defense): after goalies+forwards
	bsr.w	GetPlayerCount
	sub.w	d1,d0
.n	subq.w	#1,d0			;IDA: loc_6EEA
	move.w	d0,(word_FFC9D4).w
	clr.w	(PlayerScrollCtr).w
	clr.w	(VertLineScrolling).w
	movea.w	#(Satt-M68K_RAM),a0
	clr.w	d2
.fill	move.b	d1,(a0,d2.w)		;IDA: loc_6EFE
	cmp.w	d1,d6			;player now in the slot?
	bne.w	.nc
	move.w	d2,(VertLineScrolling).w	;start the cursor on him
.nc	addq.w	#1,d1			;IDA: loc_6F0C
	addq.w	#1,d2
	dbf	d0,.fill
	bsr.w	ClearAttributeArea2
	bsr.w	printsmallz
	String	$F8,0,3,1,0,0
	moveq	#$12,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printsmallz
	String	$FD,$15,$FC,0
	moveq	#$12,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printsmallz
	dc.w	$0018
	dc.b	$F8,4,2,2,1,'{Select  Player}',0
	clr.w	d0
	bra.w	.vert
.loop	bsr.w	MenuWaitVblankWrapper	;IDA: loc_6F60
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	btst	#7,d1			;start: back to slot cursor
	bne.w	LineEditorMenu
	btst	#5,d1			;C: take this player
	bne.w	.pick
	moveq	#1,d0
	btst	#1,d1			;down
	bne.w	.vert
	btst	#3,d1			;right: next attribute page
	bne.w	.horz
	moveq	#-1,d0
	btst	#0,d1			;up
	bne.w	.vert
	btst	#2,d1			;left: previous attribute page
	bne.w	.horz
	bra.s	.loop
.horz	add.w	(DispAttribCtr).w,d0	;IDA: loc_6FA2
	bmi.s	.loop
	move.w	d0,(DispAttribCtr).w
	bsr.w	PrintAttribHeader
	bra.s	.loop
.vert	add.w	(VertLineScrolling).w,d0	;IDA: loc_6FB2. Cursor row 0..word_FFC9D4
	bmi.s	.loop
	cmp.w	(word_FFC9D4).w,d0
	bgt.s	.loop
	move.w	d0,(VertLineScrolling).w
	cmp.w	(PlayerScrollCtr).w,d0	;IDA: loc_6FC2. PlayerScrollCtr = first shown row
	bgt.w	.top
	move.w	d0,(PlayerScrollCtr).w	;IDA: loc_6FCA. Cursor above the window
.top	subq.w	#5,d0			;IDA: loc_6FCE. 6 rows shown
	cmp.w	(PlayerScrollCtr).w,d0
	ble.w	.draw
	move.w	d0,(PlayerScrollCtr).w
.draw	bsr.w	PrintAttribHeader	;IDA: loc_6FDC
	bra.w	.loop
.pick	movea.w	#(Satt-M68K_RAM),a3	;IDA: loc_6FE4
	adda.w	(VertLineScrolling).w,a3
	move.b	(a3),d0
	addq.b	#1,d0
	move.w	(TestList).w,d2
	bsr.w	UpdatePlayerAttribute
	bra.w	LineEditorMenu

PrintAttribHeader	;line editor player list: column header for attribute page
	;DispAttribCtr (clamped to the last page) and 6 rows from PlayerScrollCtr.
	;The cursor row is printed with attribute d7
	bsr.w	printz
	String	$BE,$16,1,0
.0	movea.l	#PAttribColumns,a1	;IDA: loc_7006
	move.w	(DispAttribCtr).w,d0
	bra.w	.2
.1	adda.w	(a1),a1			;IDA: loc_7014
	addq.w	#4,a1
.2	tst.w	(a1)			;IDA: loc_7018. Negative = end of list
	dbmi	d0,.1
	bpl.w	.3
	subq.w	#1,(DispAttribCtr).w	;past the last page: back one
	bra.s	.0
.3	bsr.w	print			;IDA: loc_7028
	move.l	(a1),d4			;column flags for GetNameandAttrib
	movea.w	#(Satt-M68K_RAM),a3
	move.w	(PlayerScrollCtr).w,d2
	move.w	(word_FFC9D4).w,d1
	sub.w	d2,d1
	cmp.w	#5,d1
	bls.w	.4
	moveq	#5,d1
.4	move.w	#2,(printy).w		;IDA: loc_7046
.row	bsr.w	printsmallz		;IDA: loc_704C
	dc.w	$0020
	dc.b	$FE,4,$FD,5,$FA,1
	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	dc.b	$FD,5
	cmp.w	(VertLineScrolling).w,d2
	bne.w	.5
	move.w	d7,(printa).w
.5	clr.w	d0			;IDA: loc_707C
	move.b	(a3,d2.w),d0
	bsr.w	GetNameandAttrib
	addq.w	#1,d2
	dbf	d1,.row
	rts

DrawAttributeMenu	;line editor: draw the line icons for the cursor's line
	;group (bit mask from AttributeMenuTable) and the name of player d6
	moveq	#6,d5			;7 lines
	lea	AttributeMenuTable(pc),a0
	move.w	(TestList).w,d0
	lsr.w	#3,d0			;line number
	adda.w	d0,a0
	tst.w	(OptLine).w
	beq.w	.0
	subq.w	#1,a0			;OptLine set: table starts one byte earlier
.0	move.b	(a0),d0			;IDA: loc_70A6
	cmp.b	(byte_FFBF24).w,d0
	beq.w	.1			;same group as last time: no clear
	move.b	d0,(byte_FFBF24).w
	bsr.w	ClearAttributeArea
.1	btst	d5,(byte_FFBF24).w	;IDA: loc_70B8. Line d5 in this group?
	beq.w	.2
	bsr.w	DrawMenuIcon
.2	dbf	d5,.1			;IDA: loc_70C4
	bsr.w	printsmallz
	String	$F8,4,2,8,7,$F9,1,0
	moveq	#$18,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printsmallz
	String	$FD,$15,$FC,8
	move.w	d6,d0
	jsr	(getname).l
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	move.w	d7,(printa).w
	bsr.w	printsmall
	clr.w	(word_FFB030).w
	rts
	dc.b	1			;AttributeMenuTable-1, used when OptLine is set
AttributeMenuTable	;per line: bit mask of the lines drawn together
	dc.b	7,7,7,$18,$18,$60,$60

DrawMenuIcon	;line editor: draw line d5 (name from linelist, then its player
	;slots) at the x/y/count entry d5 of MenuIconPosTable. The slot matching
	;TestList is highlighted and its player number is returned in d6
	moveq	#6,d0			;6 bytes per entry
	mulu.w	d5,d0
	lea	MenuIconPosTable(pc),a0
	adda.w	d0,a0
	tst.w	(OptLine).w
	beq.w	.0
	subq.w	#6,a0			;OptLine set: use the entry before
.0	move.w	(a0),(printx).w		;IDA: loc_7122
	move.w	2(a0),(printy).w
	move.w	d5,d0
	movea.l	#linelist,a1
	move.w	#$8000,(printa).w
	jsr	(PrintStringFromList).l
	bsr.w	printsmallz
	dc.w	$0008
	dc.b	' Line',0
	move.w	(a0),(printx).w
	move.w	d5,d4
	asl.w	#3,d4			;8 slots per line
	addq.w	#1,d4			;slots are 1-5 (LD RD LW C RW)
	move.w	2(a0),(printy).w
	move.w	4(a0),d3		;slot count - 1
	lea	$16A(a2),a3		;team line table
.1	move.w	(a0),(printx).w		;IDA: loc_7164
	bsr.w	printsmallz
	String	$FB,$FF,$FA,2,$FE,6
	clr.w	d0
	move.b	(a3,d4.w),d0
	subq.w	#1,d0
	jsr	(FormatPlayerNameShort).l
	cmp.w	(TestList).w,d4		;cursor slot?
	bne.w	.2
	move.w	d0,d6			;player in the cursor slot
	move.w	(printa).w,d7
	move.w	#2,(word_FFB030).w	;highlight while printing
.2	bsr.w	printsmall		;IDA: loc_7196
	clr.w	(word_FFB030).w
	addq.w	#1,d4
	dbf	d3,.1
	rts

ClearAttributeArea	;line editor: erase the line area and print the
	;position labels (LD RD LW C RW) at the first icon position
	bsr.w	printsmallz
	String	$FF,2,$FD,0,$FC,$A
	moveq	#$28,d0			;40 x 18
	moveq	#$12,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	(MenuIconPosTable+2).l,(printy).l	;IDA: word_72A4
	move.w	(MenuIconPosTable).l,(printx).l
	tst.w	(OptLine).w
	beq.w	.0
	move.w	(MenuIconPosTable-6).l,(printx).l	;IDA: word_729C
.0	bsr.w	printsmallz		;IDA: loc_71E4
	dc.w	$0022
	dc.b	$FE,4,$FB,$FD,$FA,2,'LD',$FB,$FE,$FA,2,'RD',$FB,$FE,$FA,2,'LW'
	dc.b	$FB,$FE,$FA,2,'C ',$FB,$FE,$FA,2,'RW'
	rts

DrawTeamScreen	;line editor background: bitmap, frame, "Line Editor" title and
	;the team logo of a2 (home at map offset 0, away at $30)
	bsr.w	ClearAttributeArea2
	movem.l	d0-d5/a0-a2,-(sp)
	bsr.w	printz
	String	$FD,0,0
	movea.l	#unk_3288E,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d4
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
	clr.w	d0
	cmpa.w	#(hmtmstruct-M68K_RAM),a2	;home team?
	beq.w	PrintTeamData
	moveq	#$30,d0
	bra.w	PrintTeamData

ClearAttributeArea2	;erase 40 x 10 at the top of map 2
	bsr.w	printz
	String	$BE,0,0
	moveq	#$28,d0
	moveq	#$A,d1
	move.w	#$7FF,d2
	bra.w	eraser

ClearMenuFlags	;clear word_FFBD82 and word_FFBDA2
	clr.w	(word_FFBD82).w
	clr.w	(word_FFBDA2).w
	rts

	dc.w	$10,$C,4		;IDA: word_729C. Entry used when OptLine is set
MenuIconPosTable	;line icons: x, y, slot count - 1 per line
	dc.w	4,$C,4			;IDA: word_72A4 at +2
	dc.w	$10,$C,4
	dc.w	$1C,$C,4
	dc.w	4,$C,4
	dc.w	$10,$C,4
	dc.w	4,$C,3
	dc.w	$10,$C,3
	dc.w	$FFFF

LineCursorTable	;IDA: unk_72CE. TestList after a cursor move: indexed by
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

ExitAttributeScreen	;line editor: start pressed. Run the exit menu (AttributeScreenText,
	;or ExitAttribText if databuffer holds another team's lines). A nonzero
	;choice goes back to LineEditorRedraw, zero leaves via ExitAttributeScreen2
	bsr.w	ClearMenuFlags
	move.w	#$18,(palcount).w
	move.l	(dword_FFC9B4).w,-(sp)
	move.l	(dword_FFC9B8).w,-(sp)
	move.l	(dword_FFC9BC).w,-(sp)
	movea.l	#rtss,a1
	movea.l	#AttributeScreenText,a0
	movea.w	#$CAEE,a3		;retail databuffer (Rev A: $CAF2)
	move.w	$28(a2),d0		;team number + 1 = first databuffer byte?
	addq.w	#1,d0
	cmp.b	(a3),d0
	beq.w	.0
	movea.l	#ExitAttribText,a0
.0	bsr.w	printsmallz		;IDA: loc_734E
	String	$FF,2
	bsr.w	InitMenuState
.1	bsr.w	MenuWaitVblank		;IDA: loc_735A
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	move.w	d1,-(sp)
	bsr.w	HandleMenuInput
	move.w	(sp)+,d1
	andi.w	#$A0,d1			;start or C
	beq.s	.1
	bsr.w	printsmallz
	String	$F9,0
	move.w	(dword_FFC9B4).w,d0
	move.l	(sp)+,(dword_FFC9BC).w
	move.l	(sp)+,(dword_FFC9B8).w
	move.l	(sp)+,(dword_FFC9B4).w
	tst.w	d0
	bne.w	LineEditorRedraw
	bra.w	ExitAttributeScreen2

UpdatePlayerAttribute	;put player d0 (1 based) in line slot d2 of team a2. If he
	;is already in another slot of the same line, the old occupant of d2 is
	;moved there (swap)
	movem.l	d0-d2/a0-a1,-(sp)
	lea	$16A(a2),a0
	move.w	d2,d1
	andi.w	#$FFF8,d1
	lea	(a0,d1.w),a1
	moveq	#5,d1
.0	cmp.b	1(a1,d1.w),d0		;IDA: loc_73AA
	dbeq	d1,.0
	bne.w	.1
	move.b	(a0,d2.w),1(a1,d1.w)
.1	move.b	d0,(a0,d2.w)		;IDA: loc_73BC
	movem.l	(sp)+,d0-d2/a0-a1
	rts

DecodePlayerAttributes	;load team a2's lines from databuffer (byte 0 = team + 1,
	;then one nibble per slot in AttributeOffsetTbl order, relative to the
	;first forward, or first defenseman for slots 1-2)
	movem.l	d0-d4/a0/a3,-(sp)
	movea.w	#$CAEE,a0		;retail databuffer (Rev A: $CAF2)
	addq.w	#1,a0
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	bsr.w	ProcessNibble
	move.w	d0,d3
	movea.l	#AttributeOffsetTbl,a3
	clr.w	d4
	clr.w	d2
.next	move.b	(a3),d2			;IDA: ReadAttributeNibble (local)
	bmi.w	.done
	bchg	#0,d4
	bne.w	.hi
	move.b	(a0),d0
	bra.w	.nib
.hi	move.b	(a0)+,d0		;IDA: ReadHighNibble
	lsr.w	#4,d0
.nib	andi.w	#$F,d0			;IDA: ExtractNibble
	add.b	d1,d0
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.store
	add.b	d3,d0
.store	addq.b	#1,d0			;IDA: StoreAttribute
	andi.w	#$FF,d0
	move.b	(a3)+,d2
	bsr.w	UpdatePlayerAttribute
	bra.s	.next
.done	movem.l	(sp)+,d0-d4/a0/a3	;IDA: DecodeAttributesDone
	rts

EncodePlayerAttributes	;IDA: no label (Rev A $7426). Reverse of
	;DecodePlayerAttributes: pack team a2's lines into databuffer and convert
	;it with BitsToPW
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	#$CAEE,a0		;retail databuffer (Rev A: $CAF2)
	move.w	$28(a2),d0
	addq.w	#1,d0
	move.b	d0,(a0)+
	lea	$16A(a2),a1
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	bsr.w	ProcessNibble
	movea.l	#AttributeOffsetTbl,a3
	clr.w	d4
	clr.w	d2
.next	move.b	(a3)+,d2		;IDA: GetAttributeValue
	bmi.w	.done
	move.b	(a1,d2.w),d3
	subq.b	#1,d3
	sub.b	d1,d3
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.pack
	sub.b	d0,d3
.pack	bchg	#0,d4			;IDA: PackAttributeNibble
	bne.w	.hi
	move.b	d3,(a0)
	bra.s	.next
.hi	asl.b	#4,d3			;IDA: PackHighNibble
	or.b	d3,(a0)+
	bra.s	.next
.done	jsr	(BitsToPW).l		;IDA: EncodeAttributesDone
	movem.l	(sp)+,d0-d4/a0-a3
	rts

AttributeOffsetTbl	;line slots saved in databuffer ($FF ends)
	dc.b	1,2,3,4,5
	dc.b	9,$A,$B,$C,$D
	dc.b	$11,$12,$13,$14,$15
	dc.b	$19,$1A,$1B,$1C,$1D
	dc.b	$21,$22,$23,$24,$25
	dc.b	$29,$2A,$2B,$2C
	dc.b	$31,$32,$33,$34
	dc.b	$FF

TeamRosterScreen	;IDA: no label (Rev A $74AA). "Team Roster" screen for team a2:
	;one page per line (PlayerStatMenuTxt), scrolled sideways by 128 pixels.
	;Up/down change line, left/right attribute columns, A switches team
	moveq	#$D,d0
	moveq	#$17,d1
	bsr.w	SetupScreen
	moveq	#1,d0
	add.w	tmline(a2),d0		;start on the current line
	move.w	d0,(SelectedPlayerIdx).w
	clr.w	(DispAttribCtr).w
.redraw	bsr.w	printz			;IDA: loc_74C0
	String	$BD,7,1,0
	moveq	#$1A,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0014
	dc.b	$BD,9,4,'Team  Roster',$BD,$E,1
	clr.w	d0
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	beq.w	.home
	moveq	#$30,d0
.home	bsr.w	PrintTeamData		;IDA: loc_74F6
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
	bsr.w	DisplayPlayerList	;IDA: loc_7556
	move.w	(SelectedPlayerIdx).w,d0
	mulu.w	#$80,d0			;128 pixels per line page
	move.w	d0,(VertLineScrolling).w
	bsr.w	UpdatePlayerListScroll
	clr.w	(PlayerScrollCtr).w
.loop	bsr.w	MenuWaitVblank		;IDA: loc_756E
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	btst	#7,d3			;start: leave
	bne.w	ExitAttributeScreen2
	btst	#6,d1			;A: other team
	bne.w	.team
	bsr.w	nodiag
	moveq	#1,d0			;right/left: attribute columns
	btst	#3,d1
	bne.w	.col
	neg.w	d0
	btst	#2,d1
	bne.w	.col
	tst.w	(PlayerScrollCtr).w	;still scrolling
	bne.w	.scroll
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;IDA: loc_75BE
.scroll	bsr.w	CheckPlayerListScroll	;IDA: loc_75C2
	bra.s	.loop
.col	add.w	(DispAttribCtr).w,d0	;IDA: loc_75C8
	bmi.s	.scroll
	move.w	d0,(DispAttribCtr).w
	bsr.w	DisplayPlayerList
	bra.s	.scroll
.team	lea	tmsize(a2),a2		;IDA: loc_75D8
	cmpa.w	#(awtmstruct-M68K_RAM),a2
	beq.w	.redraw
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bra.w	.redraw

CheckPlayerListScroll	;TeamRosterScreen per frame: add PlayerScrollCtr to
	;VertLineScrolling, 0..$380 (7 line pages)
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0
	bmi.w	StopPlayerListScroll
	cmp.w	#$380,d0
	bgt.w	StopPlayerListScroll
UpdatePlayerListScroll	;set VertLineScrolling = d0. Stop on a page boundary. When
	;leaving a boundary, draw the page coming into view (2 pixels into a move).
	;Then VSRAM = VertLineScrolling - $70
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$80,d0
	swap	d0
	tst.w	d0
	bne.w	.0
	clr.w	(PlayerScrollCtr).w
.0	andi.w	#$7F,d1			;IDA: loc_761E
	bne.w	.2
	cmp.w	#$7E,d0
	bne.w	.1
	bsr.w	DisplayPlayerListUp
.1	cmp.w	#2,d0		;IDA: loc_7632
	bne.w	.2
	bsr.w	DisplayPlayerListDown
.2	move.w	(disflags).w,-(sp)	;IDA: loc_763E
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#$40020010,4(a0)
	move.w	#$FF90,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

StopPlayerListScroll	;IDA: loc_7666. Out of range: stop scrolling
	clr.w	(PlayerScrollCtr).w
	rts

DisplayPlayerListUp	;d0 = divs result (quotient in high word): draw that page
	move.l	d0,-(sp)
	swap	d0
	move.w	d0,(SelectedPlayerIdx).w
	bsr.w	DisplayPlayerList
	move.l	(sp)+,d0
	rts

DisplayPlayerListDown	;draw the page after the quotient in d0's high word
	move.l	d0,-(sp)
	swap	d0
	addq.w	#1,d0
	move.w	d0,(SelectedPlayerIdx).w
	bsr.w	DisplayPlayerList
	move.l	(sp)+,d0
	rts

DisplayPlayerList	;draw roster page SelectedPlayerIdx (0 goalies, 1-7 lines):
	;title, attribute column header DispAttribCtr (clamped) and one row per
	;position. Odd pages go 16 rows lower in the scroll map
	bsr.w	printsmallz
	String	$F8,7,3,2,9,$F9,1,0
	move.w	(SelectedPlayerIdx).w,d0
	lea	PlayerStatMenuTxt(pc),a1
	jsr	(AdvanceStringPtr).l
	bsr.w	printsmall
	bsr.w	printsmallz
	String	$FD,$16,$FC,9
.0	movea.l	#PAttribColumns,a1	;IDA: loc_76B8
	move.w	(DispAttribCtr).w,d0
	tst.w	(SelectedPlayerIdx).w
	bne.w	.2
	movea.l	#GAttribColumns,a1
	bra.w	.2
.1	adda.w	(a1),a1			;IDA: loc_76D4
	addq.w	#4,a1
.2	tst.w	(a1)			;IDA: loc_76D8
	dbmi	d0,.1
	bpl.w	.3
	subq.w	#1,(DispAttribCtr).w
	bra.s	.0
.3	bsr.w	printsmall		;IDA: loc_76E8
	move.l	(a1),d4
	bsr.w	printsmallz
	String	$F8,4,2,0,0,$F9,0,0
	btst	#0,(SelectedPlayerIdx+1).w
	beq.w	.4
	addi.w	#$10,(printy).w
.4	move.w	(printy).w,-(sp)	;IDA: loc_770C
	moveq	#$28,d0
	moveq	#$10,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	(sp)+,(printy).w
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	subq.w	#1,d1
	movea.l	#GoalieRowText,a5
	movea.w	#(Satt-M68K_RAM),a3	;goalie page: players 1-4
	move.l	#$1020304,(a3)
	move.w	(SelectedPlayerIdx).w,d0
	subq.w	#1,d0
	bmi.w	.5
	asl.w	#3,d0
	lea	$16A(a2),a3
	lea	1(a3,d0.w),a3
	movea.l	#PlayerPositionText,a5
	moveq	#4,d1			;5 positions
	cmpi.w	#5,(SelectedPlayerIdx).w
	ble.w	.5
	subq.w	#1,d1			;penalty kill lines: 4
.5	move.w	#2,(printx).w		;IDA: loc_7760
	movea.l	a5,a1
	bsr.w	print
	movea.l	a1,a5
	move.w	#7,(printx).w
	clr.w	d0
	move.b	(a3)+,d0
	subq.w	#1,d0
	bsr.w	GetNameandAttrib
	addq.w	#2,(printy).w
	dbf	d1,.5
	rts

GoalieRowText	;IDA: no label (movea.l #$7788 in Rev A). Position text for the
	;goalie page
	String	'G'
	String	'G'
	String	'G'
	String	'G'
PlayerStatMenuTxt	;roster page titles, { } are the left/right arrows
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

GetNameandAttrib	;print player d0's name, then at x $1E the column picked by
	;d4 (from PAttribColumns/GAttribColumns): low word = attribjmp offset,
	;high word = mask of rating nibbles to average (offsets > 2 only)
	movem.l	d0-d4/a0-a1,-(sp)
	pea	.x(pc)
	jsr	(getname).l
	bsr.w	print
	move.w	#$1E,(printx).w
	cmp.w	#2,d4
	bls.w	.jump			;status/energy: no ratings
	movea.l	tmdata(a2),a0		;team data, player records
	adda.w	(a0),a0
.0	adda.w	(a0),a0			;IDA: loc_784E
	addq.w	#8,a0
	dbf	d0,.0
	clr.w	d0
	clr.w	d1
	moveq	#$F,d2
	swap	d4
.1	btst	d2,d4			;IDA: loc_785E
	beq.w	.3
	move.w	d2,d3
	lsr.w	#1,d3
	neg.w	d3
	move.b	-1(a0,d3.w),d3
	btst	#0,d2
	beq.w	.2
	lsr.w	#4,d3
.2	andi.w	#$F,d3			;IDA: loc_7878
	add.w	d3,d0			;d0 = sum of ratings
	addi.w	#$F,d1			;d1 = 15 * count (max)
.3	dbf	d2,.1			;IDA: loc_7882
	swap	d4
.jump	lea	attribjmp(pc),a0	;IDA: loc_7888
	adda.w	(a0,d4.w),a0
	jmp	(a0)
.x	movem.l	(sp)+,d0-d4/a0-a1	;IDA: loc_7892
	rts

attribjmp	;GetNameandAttrib column handlers, offsets from attribjmp
	dc.w	AttribStatus-attribjmp
	dc.w	AttribEnergy-attribjmp
	dc.w	AttribHanded-attribjmp
	dc.w	AttribWeight-attribjmp
	dc.w	AttribFighting-attribjmp
	dc.w	AttribRating-attribjmp

AttribStatus	;IDA: no label ("jump for status"). Player d0's word at $66(a2):
	;negative = not'ed status 0-2 (Ice/Bench/Injury P), positive = penalty
	;time (bit $C injured G, bit $E prints C)
	add.w	d0,d0
	move.w	tmpdst(a2,d0.w),d0
	bpl.w	.pen
	not.w	d0
	cmp.w	#2,d0
	bls.w	.st
	moveq	#1,d0
	bra.w	.st
.inj	moveq	#3,d0			;IDA: loc_78BE
.st	lea	StatusTextTbl(pc),a1	;IDA: loc_78C0
	bra.w	PrintStringFromList
.pen	btst	#$C,d0			;IDA: loc_78C8
	bne.s	.inj
	subq.w	#1,(printx).w
	move.w	d0,d1
	andi.w	#$FFF,d0
	bsr.w	PushTime
	bsr.w	print
	moveq	#4,d0
	bclr	#$E,d1
	beq.w	.t
	moveq	#5,d0
.t	lea	StatusTextTbl(pc),a1	;IDA: loc_78EC
	bra.w	PrintStringFromList

StatusTextTbl	;AttribStatus strings
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

AttribEnergy	;IDA: no label ("jump for energy"). $32(a2) word / 40, max 100
	add.w	d0,d0
	move.w	tmpde(a2,d0.w),d0
	ext.l	d0
	divu.w	#$28,d0
	cmp.w	#100,d0
	ble.w	AttribPrintPct
	moveq	#$64,d0
	bra.w	AttribPrintPct

AttribFighting	;IDA: no label ("jump for fighting"). Bit 0 of the nibble is
	;handedness, so only bits 1-3 count
	andi.w	#$E,d0
	subq.w	#1,d1
AttribRating	;IDA: no label. Sum d0 of d1/15 ratings as a percentage
	mulu.w	#$64,d0
	divu.w	d1,d0
AttribPrintPct	;IDA: loc_794E. Print d0 4 wide plus padding
	moveq	#4,d1
	bsr.w	PushNumberWidth
	bsr.w	print
	bsr.w	printz
	String	$20,$20,$20,$20
	rts

AttribHanded	;IDA: no label ("jump for handedness"). Bit 0 of the sum
	andi.w	#1,d0
	lea	HandedTextTbl(pc),a1
	bra.w	PrintStringFromList

HandedTextTbl	;AttribHanded strings
	dc.w	$000A
	dc.b	'Righty  '
	dc.w	$000A
	dc.b	'Lefty   '

AttribWeight	;IDA: no label ("jump for Weight"). 140 + 8 * rating lb
	asl.w	#3,d0
	addi.w	#$8C,d0
	bsr.w	PushNumber
	bsr.w	print
	bsr.w	printz
	dc.w	$0008
	dc.b	' lb  ',0
	rts

ScoringSummaryScreen	;IDA: no label (Rev A $79A0). "Scoring Summary": one 4 row
	;entry per goal in ScoreSum (6 bytes each). Scrolls to the end first,
	;then up/down scroll, start exits
	moveq	#$A,d0
	moveq	#$1A,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,4,1,0
	moveq	#$20,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0018
	dc.b	$BD,6,4,'Scoring Summary',$BD,6,1,0
	moveq	#$30,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	bsr.w	printsmallz
	dc.w	$0034
	dc.b	$F8,6,3,0,8,$F9,1,'^Per^^Time^^Tm^^Goal/Assist^^^^^^^^P/S^^',$F9,0,0
	clr.l	d0
	move.w	(ScoreSumbytes).w,d0
	divu.w	#6,d0			;goals
	asl.w	#5,d0			;32 pixels per entry
	move.w	d0,(VertLineScrolling).w
	subi.w	#$80,d0			;4 entries fit on screen
	bpl.w	.0
	clr.w	d0
.0	move.w	d0,(SelectedPlayerIdx).w	;IDA: loc_7A38
	move.w	(VertLineScrolling).w,d0
.1	bsr.w	MenuWaitVblank		;IDA: loc_7A40
	bsr.w	UpdateGameStatScroll
	move.w	(VertLineScrolling).w,d0
	subq.w	#2,d0
	cmp.w	(SelectedPlayerIdx).w,d0
	bge.s	.1
	clr.w	(PlayerScrollCtr).w
.loop	bsr.w	MenuWaitVblank		;IDA: loc_7A58
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;IDA: loc_7A7C
.scroll	bsr.w	CheckGameStatScroll	;IDA: loc_7A80
	bra.s	.loop

CheckGameStatScroll	;ScoringSummaryScreen per frame: add PlayerScrollCtr to
	;VertLineScrolling (0..SelectedPlayerIdx)
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss2
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2
UpdateGameStatScroll	;set VertLineScrolling = d0. Stop on an entry boundary,
	;draw the entry coming into view, VSRAM = VertLineScrolling - $50
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$20,d0
	swap	d0
	tst.w	d0
	bne.w	.0
	bsr.w	DrawScrollArrowsPenalty
	clr.w	(PlayerScrollCtr).w
.0	andi.w	#$1F,d1			;IDA: loc_7ABC
	bne.w	.2
	move.l	d0,-(sp)
	cmp.w	#$1E,d0
	bne.w	.1
	bsr.w	DisplayGameStatLineUp
.1	move.l	(sp)+,d0		;IDA: loc_7AD2
	cmp.w	#2,d0
	bne.w	.2
	bsr.w	DisplayGameStatLineDown
.2	move.w	(disflags).w,-(sp)	;IDA: loc_7AE0
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#$40020010,4(a0)
	moveq	#-$50,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DisplayGameStatLineUp	;draw goal entry (d0 high word) at the top of the window
	move.l	d0,-(sp)
	swap	d0
	moveq	#6,d3
	mulu.w	d0,d3
	bsr.w	printz
	String	$BE,0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	subq.w	#3,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayGameStatEntry
	move.l	(sp)+,d0
	rts

DisplayGameStatLineDown	;draw goal entry (d0 high word) + 4 at the bottom
	move.l	d0,-(sp)
	swap	d0
	addq.w	#4,d0
	moveq	#6,d3
	mulu.w	d0,d3
	bsr.w	printz
	String	$BE,0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	addi.w	#$10,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayGameStatEntry
	move.l	(sp)+,d0
	rts

DisplayGameStatEntry	;print ScoreSum entry at offset d3: time, team (bit 7 of
	;byte 2 = away), goal type (GoalTypeTbl), scorer and two assists
	move.w	(printy).w,-(sp)
	moveq	#$28,d0
	moveq	#4,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	(sp)+,(printy).w
	movea.w	#(ScoreSum-M68K_RAM),a0
	move.w	(a0,d3.w),d0
	move.w	#1,(printx).w
	bsr.w	FormatAndPrintTime
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#7,2(a0,d3.w)
	beq.w	.0
	adda.w	#tmsize,a2
.0	movea.l	tmdata(a2),a1		;IDA: loc_7B96
	adda.w	4(a1),a1
	adda.w	(a1),a1
	move.w	#$C,(printx).w
	bsr.w	print
	move.w	#$23,(printx).w
	lea	GoalTypeTbl(pc),a1
	move.b	2(a0,d3.w),d0
	andi.w	#$7F,d0
	bsr.w	PrintStringFromList
	move.w	#$10,(printx).w
	move.b	3(a0,d3.w),d0
	bsr.w	PrintPeriodTime
	move.w	#$E000,(printa).w
	move.w	#$12,(printx).w
	move.b	4(a0,d3.w),d0
	bsr.w	PrintPeriodTime
	move.w	#$12,(printx).w
	move.b	5(a0,d3.w),d0
PrintPeriodTime	;print player d0 (byte, negative = none) and go down a row.
	;IDA name, it prints a player not a time
	ext.w	d0
	bmi.w	.0
	jsr	(FormatPlayerNameWithAttrib).l
	bsr.w	print
.0	addq.w	#1,(printy).w		;IDA: loc_7BFC
	rts

GoalTypeTbl	;ScoreSum byte 2 & $7F: SH2, SH, even, PP, PP2
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

PenaltySummaryScreen	;IDA: no label (Rev A $7C1A). "Penalty Summary": one 3 row
	;entry per penalty (4 bytes each from unk_FFC3F6). Same scroll handling as
	;ScoringSummaryScreen. IDA's DisplayPenaltyList label inside the misdecoded
	;title string is not a real entry
	moveq	#$A,d0
	moveq	#$19,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,4,1,0
	moveq	#$20,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0018
	dc.b	$BD,5,4,'Penalty  Summary',$BD,6,1
	moveq	#$30,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	bsr.w	printsmallz
	dc.w	$0034
	dc.b	$F8,6,3,0,8,$F9,1,'^Per^^Time^^Tm^^Player/Penalty^^^^min^^^',$F9,0,0
	clr.l	d0
	move.w	(word_FFC3F4).w,d0	;penalty bytes
	lsr.w	#2,d0
	mulu.w	#$18,d0			;24 pixels per entry
	move.w	d0,(VertLineScrolling).w
	subi.w	#$78,d0			;5 entries fit on screen
	bpl.w	.0
	clr.w	d0
.0	move.w	d0,(SelectedPlayerIdx).w	;IDA: loc_7CB2
	move.w	(VertLineScrolling).w,d0
.1	bsr.w	MenuWaitVblank		;IDA: loc_7CBA
	bsr.w	UpdatePenaltyScroll
	move.w	(VertLineScrolling).w,d0
	subq.w	#2,d0
	cmp.w	(SelectedPlayerIdx).w,d0
	bge.s	.1
	clr.w	(PlayerScrollCtr).w
.loop	bsr.w	MenuWaitVblank		;IDA: loc_7CD2
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;IDA: loc_7CF6
.scroll	bsr.w	CheckPenaltyScroll	;IDA: loc_7CFA
	bra.s	.loop

CheckPenaltyScroll	;PenaltySummaryScreen per frame: add PlayerScrollCtr to
	;VertLineScrolling (0..SelectedPlayerIdx)
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss2
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2
UpdatePenaltyScroll	;set VertLineScrolling = d0. Stop on an entry boundary,
	;draw the entry coming into view, VSRAM = VertLineScrolling - $50
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$18,d0
	swap	d0
	tst.w	d0
	bne.w	.0
	bsr.w	DrawScrollArrowsPenalty
	clr.w	(PlayerScrollCtr).w
.0	ext.l	d1			;IDA: loc_7D36
	divs.w	#$18,d1
	swap	d1
	tst.w	d1
	bne.w	.2
	move.l	d0,-(sp)
	cmp.w	#$16,d0
	bne.w	.1
	bsr.w	DisplayPenaltyLineUp
.1	move.l	(sp)+,d0		;IDA: loc_7D52
	cmp.w	#2,d0
	bne.w	.2
	bsr.w	DisplayPenaltyLineDown
.2	move.w	(disflags).w,-(sp)	;IDA: loc_7D60
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#$40020010,4(a0)
	move.w	#$FFB0,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DisplayPenaltyLineUp	;draw penalty entry (d0 high word) at the top of the window
	move.l	d0,-(sp)
	swap	d0
	move.w	d0,d3
	asl.w	#2,d3
	bsr.w	printz
	String	$BE,0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	subq.w	#2,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayPenaltyEntry
	move.l	(sp)+,d0
	rts

DisplayPenaltyLineDown	;draw penalty entry (d0 high word) + 5 at the bottom
	move.l	d0,-(sp)
	swap	d0
	addq.w	#5,d0
	move.w	d0,d3
	asl.w	#2,d3
	bsr.w	printz
	String	$BE,0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	addi.w	#$F,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayPenaltyEntry
	move.l	(sp)+,d0
	rts

DisplayPenaltyEntry	;print penalty entry at offset d3: time, team (bit 7 of
	;byte 2 = away), minutes and name from PenaltyList, player (byte 3)
	move.w	(printy).w,-(sp)
	moveq	#$28,d0
	moveq	#3,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	(sp)+,(printy).w
	movea.w	#(unk_FFC3F6-M68K_RAM),a0
	move.w	(a0,d3.w),d0
	move.w	#1,(printx).w
	bsr.w	FormatAndPrintTime
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#7,2(a0,d3.w)
	beq.w	.0
	adda.w	#tmsize,a2
.0	movea.l	tmdata(a2),a1		;IDA: loc_7E18
	adda.w	4(a1),a1
	adda.w	(a1),a1
	move.w	#$C,(printx).w
	bsr.w	print
	move.b	2(a0,d3.w),d0
	andi.w	#$7F,d0
	movea.l	#PenaltyList,a3
	adda.w	(a3,d0.w),a3
	clr.w	d0
	move.b	1(a3),d0
	bsr.w	PushNumber
	move.w	#$23,(printx).w
	bsr.w	print
	move.w	#$10,(printx).w
	clr.w	d0
	move.b	3(a0,d3.w),d0
	jsr	(FormatPlayerNameWithAttrib).l
	bsr.w	print
	addq.w	#1,(printy).w
	move.w	#$13,(printx).w
	move.w	#$E000,(printa).w
	lea	2(a3),a1
	bra.w	print

DrawScrollArrowsPenalty	;summary screen up/down arrows. Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	bsr.w	printsmallz
	String	$F8,4,3,4,9,$F9,1,0
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1
	add.b	d1,d0
	add.b	d1,d0
	lea	ScrollArrowTbl(pc),a1
	bsr.w	PrintStringFromList
	movem.l	(sp)+,d0-d1/a1
	rts

ScrollArrowTbl	;none, up, down, both
	String	$20,$FB,$FF,$FA,$11,$20,$F9
	String	$7B,$FB,$FF,$FA,$11,$20,$F9
	String	$20,$FB,$FF,$FA,$11,$7D,$F9
	String	$7B,$FB,$FF,$FA,$11,$7D,$F9

DisplayTeamStats	;"Playoff Stats": DisplayAttributeScreen with d7 = 1 for the
	;player's playoff team (potree), stats from ReadTeamStats
	movem.l	a2,-(sp)
	jsr	(ReadTeamStats).l
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d0
	move.b	(a0,d0.w),d0
	movea.w	#(hmtmstruct-M68K_RAM),a2
	cmp.w	$28(a2),d0
	beq.w	.0
	adda.w	#tmsize,a2
.0	moveq	#1,d7			;IDA: loc_7F06
	bsr.w	DisplayAttributeScreen
	movem.l	(sp)+,a2
	rts

PlayerStatsScreen	;IDA: no label (Rev A $7F12). "Player Stats" (d7 = 0, game
	;stats, A switches team)
	clr.w	d7
DisplayAttributeScreen	;stats screen for team a2, d7 = 0 game / 1 playoff.
	;Left/right picks the sort column (-1 goalie saves, 0-4 G A Pts SOG PIM),
	;up/down scrolls the sorted player list
	moveq	#$D,d0
	moveq	#$16,d1
	bsr.w	SetupScreen
	clr.w	(DispAttribCtr).w
	clr.w	(VertLineScrolling).w
.redraw	clr.w	(PlayerScrollCtr).w	;IDA: loc_7F24
	bsr.w	printz
	String	$BD,5,1,0
	moveq	#$1E,d0
	moveq	#6,d1
	bsr.w	Framer
	tst.w	d7
	beq.w	.title
	bsr.w	printbigz
	dc.w	$0016
	dc.b	$BD,7,4,'Playoff  Stats',$BD,$E,1
	bra.w	.team
.title	bsr.w	printsmallz		;IDA: loc_7F5E
	dc.w	$001C
	dc.b	$F8,6,3,$C,$1A,$F9,1,'A^-^Switch^Teams',$F9,0,0
	bsr.w	printbigz
	dc.w	$0016
	dc.b	$BD,8,4,'Player  Stats',$BD,$E,1,0
.team	clr.w	d0			;IDA: loc_7F98
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	beq.w	.home
	moveq	#$30,d0
.home	bsr.w	PrintTeamData		;IDA: loc_7FA4
	bsr.w	DisplayAttributeMenu
	bsr.w	DrawScrollArrowsAttribute
.loop	bsr.w	MenuWaitVblank		;IDA: loc_7FB0
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	btst	#6,d1
	bne.w	.switch
	bsr.w	nodiag
	moveq	#1,d0
	btst	#3,d1
	bne.w	.col
	neg.w	d0
	btst	#2,d1
	bne.w	.col
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set	move.w	d0,(PlayerScrollCtr).w	;IDA: loc_7FF4
.scroll	bsr.w	UpdateAttributeScroll	;IDA: loc_7FF8
	bra.s	.loop
.col	add.w	(DispAttribCtr).w,d0	;IDA: loc_7FFE
	cmp.w	#-1,d0
	blt.s	.scroll
	cmp.w	#4,d0
	bgt.s	.scroll
	move.w	d0,(DispAttribCtr).w
	bsr.w	DisplayAttributeMenu
	bsr.w	DrawScrollArrowsAttribute
	bra.s	.scroll
.switch	tst.w	d7			;IDA: loc_801C. No team switch in playoff stats
	bne.s	.scroll
	lea	tmsize(a2),a2
	cmpa.w	#(awtmstruct-M68K_RAM),a2
	beq.w	.redraw
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bra.w	.redraw

UpdateAttributeScroll	;stats screen per frame: scroll 0..SelectedPlayerIdx, stop
	;every 16 pixels (one row), draw the row coming into view
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss2
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss2
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss2
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	andi.w	#$F,d0
	bne.w	.0
	bsr.w	DrawScrollArrowsAttribute
	clr.w	(PlayerScrollCtr).w
.0	andi.w	#$F,d1			;IDA: loc_8064
	bne.w	SetAttribScrollReg
	move.w	d0,-(sp)
	cmp.w	#$E,d0
	bne.w	.1
	bsr.w	DisplayAttributeLineUp
.1	move.w	(sp)+,d0		;IDA: loc_807A
	cmp.w	#2,d0
	bne.w	SetAttribScrollReg
	bsr.w	DisplayAttributeLineDown
SetAttribScrollReg	;IDA: loc_8088. VSRAM = VertLineScrolling - $68
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#$40020010,4(a0)
	move.w	#$FF98,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts

DisplayAttributeLineUp	;draw the top row of the window
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	bra.w	DisplayAttributeEntry

DisplayAttributeLineDown	;draw the row below the window
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	addq.w	#6,d3
	bra.w	DisplayAttributeEntry

DisplayAttributeMenu	;stats screen: column headers (sort column highlighted),
	;title for column DispAttribCtr, then sort the players by that column into
	;Satt ($FF ends, goalies only when -1) and draw the visible rows
	bsr.w	printsmallz
	dc.w	$0012
	dc.b	$F8,6,3,4,$B,$F9,1,'Player',$FB,7,0
	lea	AttributeMenuTxt(pc),a1
	moveq	#5,d3
	tst.w	(DispAttribCtr).w
	bmi.w	.0
	adda.w	(a1),a1
	clr.w	d3
.0	move.w	#$8000,(printa).w	;IDA: loc_80EE
	cmp.w	(DispAttribCtr).w,d3
	bne.w	.1
	move.w	#$C000,(printa).w
.1	bsr.w	printsmall		;IDA: loc_8102
	addq.w	#1,d3
	cmp.w	#5,d3
	blt.s	.0
	bsr.w	printsmallz
	String	$F8,4,3,9,7,0
	moveq	#$16,d0
	moveq	#3,d1
	bsr.w	Framer
	bsr.w	printz
	String	$8D,$A,8,0
	lea	AttributeTitleTxt(pc),a1
	moveq	#1,d0
	add.w	(DispAttribCtr).w,d0
	bsr.w	PrintStringFromList
	clr.w	(word_FFB030).w
	movea.w	#(Satt-M68K_RAM),a3
	clr.l	d6
	tst.w	(DispAttribCtr).w
	bpl.w	.2
	bsr.w	ReadAttributeNibble	;goalie column: mark all skaters used
	bset	d0,d6
	subq.w	#1,d6
	not.l	d6
.2	moveq	#-1,d4			;IDA: loc_8156. Selection sort, best so far
	st	d5
	bsr.w	GetPlayerCount
	bra.w	.6
.3	btst	d0,d6			;IDA: loc_8162
	bne.w	.6
	clr.w	d2
	move.w	(DispAttribCtr).w,d1
	bmi.w	.4
	bsr.w	CheckAttributeValid
.4	ext.l	d2			;IDA: loc_8176
	asl.l	#8,d2
	movea.l	tmdata(a2),a1
	adda.w	(a1),a1
	move.w	d0,d1
	subq.w	#8,a1
.5	addq.w	#8,a1			;IDA: loc_8184
	adda.w	(a1),a1
	dbf	d1,.5
	move.b	#$FF,d2
	sub.b	(a1),d2			;ties: lower player byte first
	cmp.l	d4,d2
	ble.w	.6
	move.l	d2,d4
	move.w	d0,d5
.6	dbf	d0,.3			;IDA: loc_819C
	bset	d5,d6			;used
	move.b	d5,(a3)+
	bpl.s	.2			;until none left ($FF)
	moveq	#5,d0
.7	st	(a3,d0.w)		;IDA: loc_81A8. Pad with empty rows
	dbf	d0,.7
	move.w	a3,d0
	subi.w	#$BF30,d0		;rows past the first 7 in Satt
	bpl.w	.8
	clr.w	d0
.8	asl.w	#4,d0			;IDA: loc_81BC
	move.w	d0,(SelectedPlayerIdx).w
	cmp.w	(VertLineScrolling).w,d0
	bcc.w	.9
	move.w	d0,(VertLineScrolling).w
.9	moveq	#5,d4			;IDA: loc_81CE
.ent	move.w	(VertLineScrolling).w,d3	;IDA: loc_81D0
	lsr.w	#4,d3
	add.w	d4,d3
	bsr.w	DisplayAttributeEntry
	dbf	d4,.ent
	bra.w	SetAttribScrollReg

DisplayAttributeEntry	;stats screen row d3 of Satt: rank, name, then either the
	;5 stat columns or goalie saves/shots/save %
	movea.w	#(Satt-M68K_RAM),a4
	adda.w	d3,a4
	bsr.w	printz
	String	$BE,0,0
	add.w	d3,d3
	andi.w	#$1F,d3
	move.w	d3,(printy).w
	moveq	#$28,d0
	moveq	#1,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	tst.b	(a4)
	bmi.w	rtss2
	subq.w	#1,(printy).w
	move.w	#1,(printx).w
	move.w	a4,d0
	subi.w	#$BF29,d0		;rank = Satt index + 1
	moveq	#2,d1
	move.w	#$E000,(printa).w
	bsr.w	PushNumberWidth
	bsr.w	print
	clr.w	d0
	move.b	(a4),d0
	jsr	(FormatPlayerName).l
	addq.w	#1,(printx).w
	move.w	#$8000,(printa).w
	bsr.w	print
	move.w	#$11,(printx).w
	tst.w	(DispAttribCtr).w
	bmi.w	.goalie
	clr.w	d5
.0	clr.w	d0			;IDA: loc_8258
	move.b	(a4),d0
	move.w	d5,d1
	bsr.w	CheckAttributeValid
	move.w	d2,d0
	moveq	#4,d1
	bsr.w	PushNumberWidth
	move.w	#$8000,(printa).w
	cmp.w	(DispAttribCtr).w,d5
	bne.w	.1
	move.w	#$C000,(printa).w
.1	bsr.w	print			;IDA: loc_827E
	addq.w	#1,d5
	cmp.w	#5,d5
	bne.s	.0
	bra.w	.x
.goalie	clr.w	d0			;IDA: loc_828E. Shots against
	move.b	(a4),d0
	moveq	#3,d1
	bsr.w	GetAttributeValue2
	clr.w	d0
	move.b	(a4),d0
	moveq	#0,d1			;goals against
	move.w	d2,-(sp)
	bsr.w	GetAttributeValue2
	move.w	(sp)+,d0
	move.w	d0,d3
	sub.w	d2,d0
	bpl.w	.2
	clr.w	d0
.2	move.w	d0,d2			;IDA: loc_82B0
	moveq	#4,d1
	bsr.w	PushNumberWidth
	addq.w	#1,(printx).w
	bsr.w	print
	move.w	d3,d0
	moveq	#4,d1
	bsr.w	PushNumberWidth
	addq.w	#2,(printx).w
	bsr.w	print
	tst.w	d3
	beq.w	.3
	mulu.w	#$64,d2
	divu.w	d3,d2
.3	move.w	d2,d0			;IDA: loc_82DC
	moveq	#4,d1
	bsr.w	PushNumberWidth
	addq.w	#2,(printx).w
	bsr.w	print
	bsr.w	printz
	String	$25
.x	rts				;IDA: locret_82F4

CheckAttributeValid	;d2 = stat column d1 for player d0. Goalies only have PIM
	;(column 4, mapped to 1 via btst d1,#6)
	move.w	d0,-(sp)
	bsr.w	ReadAttributeNibble
	move.w	d0,d2
	move.w	(sp)+,d0
	cmp.w	d2,d0
	bge.w	GetAttributeValue2
	clr.w	d2
	btst	d1,#6
	beq.w	rtss2
	moveq	#1,d1
GetAttributeValue2	;d2 = stat column d1 for player d0. d7 = 0: team struct
	;bytes (AttributeOffsetTbl2), d7 = 1: playoff words (StatsOffsetTbl2).
	;Second offset of a pair is added ($FFFF/0 = none)
	tst.w	d7
	bne.w	.stats
	lea	AttributeOffsetTbl2(pc),a1
	asl.w	#2,d1
	adda.w	d1,a1
	move.w	(a1),d1
	add.w	d0,d1
	clr.w	d2
	move.b	(a2,d1.w),d2
	move.w	2(a1),d1
	bmi.w	rtss2
	add.w	d0,d1
	clr.w	d3
	move.b	(a2,d1.w),d3
	add.w	d3,d2
	rts
.stats	asl.w	#2,d1			;IDA: loc_833E
	add.w	d0,d0
	clr.w	d2
	bsr.w	GetStatsValue
	addq.w	#2,d1
	bsr.w	GetStatsValue
	lsr.w	#1,d0
	rts

GetStatsValue	;d2 += word d0 of the RAM table at StatsOffsetTbl2+d1 (0 = none)
	movea.l	#StatsOffsetTbl2,a1
	tst.w	(a1,d1.w)
	beq.w	rtss2
	movea.w	(a1,d1.w),a1
	add.w	(a1,d0.w),d2
	rts

StatsOffsetTbl2	;playoff stat RAM tables per column (G, A, G+A, SOG, PIM)
	dc.w	$C82A,0,$C85E,0,$C82A,$C85E,$C892,0,$C8C6,0
AttributeOffsetTbl2	;team struct byte arrays per column, same order
	dc.w	$B4,$FFFF,$CE,$FFFF,$B4,$CE,$E8,$FFFF,$102,$FFFF

AttributeMenuTxt	;stats screen column headers (goalie header, then 5 columns)
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
AttributeTitleTxt	;IDA: no label (lea at DisplayAttributeMenu+$66). Sort column
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

DrawScrollArrowsAttribute	;stats screen up/down arrows. Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	bsr.w	printsmallz
	String	$F8,4,3,2,$B,$F9,1,0
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1
	add.b	d1,d0
	add.b	d1,d0
	lea	ScrollArrowTbl2(pc),a1
	jsr	(PrintStringFromList).l
	movem.l	(sp)+,d0-d1/a1
	rts

ScrollArrowTbl2	;none, up, down, both
	String	$20,$FB,$FF,$FA,$C,$20,$F9
	String	$7B,$FB,$FF,$FA,$C,$20,$F9
	String	$20,$FB,$FF,$FA,$C,$7D,$F9
	String	$7B,$FB,$FF,$FA,$C,$7D,$F9

GameStatisticsScreen	;IDA: no label (Rev A $84AC). "Game Statistics": both
	;teams' totals. Start exits
	moveq	#9,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,4,1,0
	moveq	#$20,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0018
	dc.b	$BD,6,4,'Game  Statistics',$BD,6,1
	moveq	#$30,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	bsr.w	DisplayTeamStatsScreen
.loop	bsr.w	WaitVSyncAndReadInput	;IDA: loc_84F6
	btst	#7,d1
	bne.w	ExitAttributeScreen2
	bra.s	.loop

DisplayTeamStatsScreen	;team logos, then each TeamStatTextTbl row centred with
	;home value at x $22 and away at x 9
	bsr.w	printz
	String	$BE,2,9,0
	moveq	#$30,d0
	bsr.w	PrintTeamData
	bsr.w	printz
	String	$BE,$1A,9,0
	moveq	#0,d0
	bsr.w	PrintTeamData
	bsr.w	printz
	String	$BE,0,$C,0
	moveq	#7,d6
	lea	TeamStatTextTbl(pc),a1
.0	move.w	(a1),d0			;IDA: loc_8534
	lsr.w	#1,d0
	neg.w	d0
	addi.w	#$15,d0
	move.w	d0,(printx).w
	bsr.w	print
	movea.l	a1,a0
	move.w	#$22,(printx).w
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	FormatStatValue
	move.w	#9,(printx).w
	lea	tmsize(a2),a2
	bsr.w	FormatStatValue
	lea	4(a0),a1
	addq.w	#2,(printy).w
	dbf	d6,.0
	rts

FormatStatValue	;print TeamStatTextTbl entry a0 for team a2 centred at printx:
	;value (offset $A is a time), "/second" if any, " (pct%)" for passing
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#2,(a3)
	move.w	(a0),d0
	move.w	(a2,d0.w),d0
	cmpi.w	#$A,(a0)
	beq.w	.0
	bsr.w	PushNumber
.0	cmpi.w	#$A,(a0)		;IDA: loc_858C
	bne.w	.1
	bsr.w	PushTime
.1	bsr.w	appstring		;IDA: loc_8598
	move.w	2(a0),d0
	bmi.w	.x
	bsr.w	appendz
	String	$2F
	move.w	(a2,d0.w),d0
	bsr.w	PushNumber
	bsr.w	appstring
	cmpi.w	#$14,(a0)
	bne.w	.x
	bsr.w	appendz
	String	$20,$28
	move.w	(a0),d0
	move.w	(a2,d0.w),d0
	mulu.w	#$64,d0
	move.w	2(a0),d1
	move.w	(a2,d1.w),d1
	beq.w	.2
	divu.w	d1,d0
.2	bsr.w	PushNumber		;IDA: loc_85E0
	bsr.w	appstring
	bsr.w	appendz
	String	$25,$29
.x	movea.w	a3,a1			;IDA: loc_85F0
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bra.w	print

TeamStatTextTbl	;label, then team struct stat offset and second offset ($FFFF none)
	dc.w	$0008
	dc.b	'Score',0
	dc.w	$C,$FFFF
	dc.w	$0008
	dc.b	'Shots',0
	dc.w	0,$FFFF
	dc.w	$000C
	dc.b	'Power Play'
	dc.w	2,4
	dc.w	$000C
	dc.b	'Penalties',0
	dc.w	6,8
	dc.w	$000E
	dc.b	'Faceoffs Won'
	dc.w	$E,$FFFF
	dc.w	$000E
	dc.b	'Body Checks',0
	dc.w	$10,$FFFF
	dc.w	$000E
	dc.b	'Attack Zone',0
	dc.w	$A,$FFFF
	dc.w	$000A
	dc.b	'Passing',0
	dc.w	$14,$12

CrowdMeterScreen	;IDA: no label (Rev A $867A). "Crowd Meter": current, average
	;and peak crowd level in dB. Start exits
	moveq	#9,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	bsr.w	printz
	String	$BD,6,1,0
	moveq	#$1C,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printbigz
	dc.w	$0014
	dc.b	$BD,9,4,'Crowd  Meter',$BD,6,1
	moveq	#$30,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	bsr.w	DisplayGameStats
.loop	bsr.w	WaitVSyncAndReadInput	;IDA: loc_86C0
	btst	#7,d1
	bne.w	ExitAttributeScreen2
	bra.s	.loop

DisplayGameStats	;crowd meter rows: CwdExciteLvl, average (dword_FFB8A8 /
	;word_FFB8A6 samples) and peak (word_FFB8A4)
	bsr.w	printsmallz
	dc.w	$0016
	dc.b	$F8,4,2,4,$C,'Current Level',$FD,$1C
	move.w	(CwdExciteLvl).w,d0
	bsr.w	FormatPercentage
	bsr.w	printsmallz
	dc.w	$0016
	dc.b	$FD,4,$FA,2,'Average Level',$FD,$1C,0
	move.l	(dword_FFB8A8).w,d0
	divu.w	(word_FFB8A6).w,d0
	bsr.w	FormatPercentage
	bsr.w	printsmallz
	dc.w	$0012
	dc.b	$FD,4,$FA,2,'Peak Level',$FD,$1C
	move.w	(word_FFB8A4).w,d0
FormatPercentage	;print crowd level d0 as sqrt(d0*4) + 65 " dB"
	ext.l	d0
	asl.w	#2,d0
	bsr.w	sroot
	addi.w	#$41,d0
	moveq	#3,d1
	bsr.w	PushNumberWidth
	bsr.w	print
	bsr.w	printz
	dc.w	$0006
	dc.b	' dB',0
	rts

SetupScreen	;common start for the stats screens: blank, 40 cell mode, load
	;framer and small font, draw the background bitmap, copy rows d0-d1 of it
	;to the scroll plane and clear map 3
	movem.l	d0-d1/a2,-(sp)
	bsr.w	forceblack
	bclr	#0,(disflags).w
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	move.w	(VSPRITES).w,d0
	bsr.w	Vmaddr
	move.l	#0,(a0)			;clear first sprite
	move.w	#$8C81,4(a0)		;VDP reg 12: 40 cell mode
	move.w	#6,(Map3col).w
	move.w	(sp)+,(disflags).w
	bclr	#1,(disflags).w
	move.w	(Framercset).w,d4
	movea.l	#FramermapPlus8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$91234567,$89ABCDEF
	move.w	(smallfontchars).w,d4
	bsr.w	AddSmallFont
	bsr.w	printz
	String	$BD,0,0
	movea.l	#unk_3288E,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d4
	moveq	#0,d5
	bsr.w	dobitmap
	bsr.w	printz
	String	$FD,0,0
	movem.l	(sp),d0-d1/a2
	add.w	d0,(printy).w
	movea.l	#unk_3288E,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	move.w	d1,d3
	sub.w	d0,d3
	move.w	d0,d1
	clr.w	d0
	moveq	#$28,d2
	clr.w	d4
	moveq	#$D,d5
	bsr.w	dobitmap
	move.w	d4,(word_FFB014).w
	movea.l	#smallfontmapPlus8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$D1234567,$89ABCDEF
	bsr.w	printz
	String	$FE,0,0
	moveq	#$40,d0
	moveq	#$20,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	#$18,(palcount).w
	movem.l	(sp)+,d0-d1/a2
	rts

ExitAttributeScreen2	;leave a stats screen: back to 32 cell mode, reload the
	;rink, font and framer graphics, rebuild the rink map and player colours
	bsr.w	forceblack
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.w	#$8C00,4(a0)		;VDP reg 12: 32 cell mode
	move.w	#5,(Map3col).w
	move.w	(sp)+,(disflags).w
	bset	#1,(disflags).w
	move.w	(rinkvrcset).w,d4
	movea.l	#IceRinkMapPlus8,a2
	bsr.w	DoDMA_clearCallbackPointer
	move.w	(smallfontchars).w,d4
	movea.l	#smallfontmapPlus8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$43434567,$89ABCDEF
	move.w	(Framercset).w,d4
	bsr.w	AddFramer
	jsr	(setupIceRinkMap).l
	jmp	(setplayercolors).l

TimeoutMenu	;IDA left this code undecoded (dc.b in both listings); retail bytes.
	;Prints "Timeout" in a frame for team a2
	dc.b	$53,$78,$C9,$B4,$53,$78,$C9,$B6,$23,$FC,$00,$01,$5A,$56,$FF,$FF
	dc.b	$C9,$B8,$08,$EA,$00,$02,$00,$30,$61,$00,$59,$00,$00,$06,$BD,$05
	dc.b	$0C,$00,$70,$16,$72,$06,$61,$00,$57,$36,$61,$00,$58,$EE,$00,$10
	dc.b	$BD,$0C,$0E,$54,$69,$6D,$65,$6F,$75,$74,$BD,$11,$0F,$00,$22,$6A
	dc.b	$00,$1E,$D2,$E9,$00,$04,$30,$11,$E2,$48,$91,$78,$B0,$28,$61,$00
	dc.b	$58,$DC,$34,$7C,$C4,$E6,$61,$00,$6A,$46,$D4,$FC,$01,$A2,$61,$00
	dc.b	$6A,$3E,$70,$78,$60,$00,$4F,$9C

SelectGoalieMenu	;IDA: no label (Rev A $890A). Pick team a2's goalie from a
	;list (0 = no goalie). Start/C confirms; a change is stored in $26(a2)
	;and setpersonel is called
	move.w	(dword_FFC9B4).w,-(sp)
	move.w	(dword_FFC9B4+2).w,-(sp)
	bsr.w	ReadAttributeNibble
	move.w	d0,(dword_FFC9B4+2).w
	bsr.w	printz
	String	$BD,4,$C,0
	moveq	#$18,d0
	moveq	#3,d1
	add.w	(dword_FFC9B4+2).w,d1
	bsr.w	Framer
	move.w	tmgoalie(a2),d0
	bpl.w	.0
	moveq	#-1,d0
.0	addq.w	#1,d0			;IDA: loc_893A
	move.w	d0,(dword_FFC9B4).w
.loop	bsr.w	DisplayPlayerSelectMenu	;IDA: loc_8940
	bsr.w	WaitVSyncAndReadInput
	btst	#7,d1
	bne.w	.done
	btst	#5,d1
	bne.w	.done
	btst	#1,d1
	beq.w	.up
	move.w	(dword_FFC9B4).w,d0
	addq.w	#1,d0
	cmp.w	(dword_FFC9B4+2).w,d0
	bgt.s	.loop
	move.w	d0,(dword_FFC9B4).w
.up	btst	#0,d1			;IDA: loc_8970
	beq.s	.loop
	subq.w	#1,(dword_FFC9B4).w
	bpl.s	.loop
	clr.w	(dword_FFC9B4).w
	bra.s	.loop
.done	move.w	(dword_FFC9B4).w,d0	;IDA: loc_8982
	subq.w	#1,d0
	bpl.w	.set
	cmpi.w	#-1,tmgoalie(a2)
	blt.w	.x
.set	move.w	d0,tmgoalie(a2)		;IDA: loc_8996
	jsr	(setpersonel).l
.x	move.w	(sp)+,(dword_FFC9B4+2).w	;IDA: loc_89A0
	move.w	(sp)+,(dword_FFC9B4).w
	rts

DisplayPlayerSelectMenu	;draw the goalie list, row dword_FFC9B4 highlighted,
	;each goalie with his two digit number
	move.w	#$D,(printy).w
	move.w	(dword_FFC9B4+2).w,d1
	moveq	#0,d0
.0	move.w	#5,(printx).w		;IDA: loc_89B6
	move.w	#$A000,(printa).w
	cmp.w	(dword_FFC9B4).w,d0
	bne.w	.1
	move.w	#$8000,(printa).w
.1	bsr.w	printz			;IDA: loc_89D0
	dc.w	$0018
	dc.b	'                      '
	tst.w	d0
	bne.w	.player
	move.w	#$B,(printx).w
	bsr.w	printz
	dc.w	$000C
	dc.b	'no goalie',0
	bra.w	.next
.player	movea.l	tmdata(a2),a1		;IDA: loc_8A0A+2
	adda.w	(a1),a1
	move.w	d0,d2
	subq.w	#1,d2
	bra.w	.3
.2	adda.w	(a1),a1			;IDA: loc_8A1A
	addq.w	#8,a1
.3	dbf	d2,.2			;IDA: loc_8A1E
	move.w	#8,(printx).w
	bsr.w	print
	move.b	(a1),d2
	lsr.b	#4,d2
	addi.b	#$30,d2
	move.b	d2,(TextBuffer).w
	move.b	(a1),d2
	andi.b	#$F,d2
	addi.b	#$30,d2
	move.b	d2,(TextBuffer+1).w
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#4,(a1)
	move.w	#5,(printx).w
	bsr.w	print
.next	addq.w	#1,(printy).w
	addq.w	#1,d0
	dbf	d1,.0
	rts

ReadAttributeNibble	;d0 = goalies on team a2 (nibbles in the team data word
	;at offset $A)
	movem.l	d1/a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	$A(a0),a0
	move.w	(a0),d1
	clr.w	d0
.0	addq.w	#1,d0			;IDA: loc_8A74
	asl.w	#4,d1
	bne.s	.0
	movem.l	(sp)+,d1/a0
	rts

ProcessNibble	;d0 = forwards on team a2 (high nibble of team data byte 3 at
	;the offset in word 8)
	movem.l	a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	8(a0),a0
	move.b	3(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	movem.l	(sp)+,a0
	rts

GetPlayerCount	;d0 = players on team a2 (records until a length word of 2)
	movem.l	a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0
	clr.w	d0
loopthroughplayers
	addq.w	#1,d0
	adda.w	(a0),a0
	addq.w	#8,a0
	cmpi.w	#2,(a0)
	bne.s	loopthroughplayers
	movem.l	(sp)+,a0
	rts

WaitVSyncAndReadInput	;wait for vcount to change and a new button press (d1)
	move.w	(vcount).w,d1
.0	cmp.w	(vcount).w,d1		;IDA: loc_8ABE
	beq.s	.0
	bsr.w	getpzjoy
	bsr.w	nodiag
	tst.b	d1
	beq.s	WaitVSyncAndReadInput
	rts
