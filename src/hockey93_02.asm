;	NHLPA Hockey 93 (v1.1 retail) segment $68B4-$6C09
;	demoread through the end of MenuWaitVblank: demo/pause input, the pause
;	screen, and the generic scrolling menu used by the pause screen.
;	Global names from the v1.1 IDA export, renamed to the NHL 92 name where the
;	same routine exists in 92 (IDA name kept in an ;IDA: comment).
;	Local labels and comments follow NHL 92 hockey.asm where the code matches.
;	Bytes match nhlpa93retail.bin.
;	92 equate names in comments are only used where the 93 value is the same.
;	Inline print strings after printsmallz/printsmall use the String macro
;	(length word includes itself, odd data is padded to a word).

demoread	;monitor joystick if in demo mode (called every game loop)
	tst.w	(cont1team).w
	bne.w	rtss2			;not demo
	tst.w	(cont2team).w
	bne.w	rtss2			;not demo
	bsr.w	Readjoy1
	btst	#7,d1			;sbut
	bne.w	startpause1		;start on pad 1 pauses (92 went to Opening)
	bsr.w	HandleJoy1
	bsr.w	Readjoy2
	btst	#7,d1			;sbut
	bne.w	startpause2
	;falls into HandleJoy1 with pad 2 in d1

HandleJoy1	;any button on the pad just read (d1) ends the demo
	;falls in from demoread for pad 2
	tst.w	d1
	beq.w	rtss2			;nothing pressed
	jmp	(loc_12A16).l		;exit demo

startpause1	;pause intiated by cont 1
	bclr	#1,(sflags).w		;sfpj
	bra.w	startpause
startpause2	;pause intiated by cont 2
	bset	#1,(sflags).w		;sfpj
startpause
	bset	#0,(sflags).w		;sfpz
	rts

Pausemode	;game is in pause mode now
	jsr	(p_turnoff).l		;shut off sound
	move.w	(sflags).w,-(sp)
	bsr.w	forceblack		;fade screen to black
	bsr.w	seta2			;a2 = team of pausing controller
	movea.l	#PauseText,a0		;menu item list
	lea	SetupPauseScreen(pc),a1	;screen draw routine
	btst	#2,$30(a2)
	beq.w	.0
	movea.l	#PauseText2,a0		;alternate item list
.0	bsr.w	InitMenuState
.1	bsr.w	MenuWaitVblank		;wait for vblank and read controller
	bsr.w	getpzjoy
	bsr.w	ProcessInputWithRepeat
	bsr.w	HandleMenuInput
	bne.s	.1			;eq = leave pause

	;92 PauseExit: restore graphics and return from pause mode
	bsr.w	forceblack
	move.w	(sp)+,(sflags).w
	btst	#7,(sflags).w		;sfhor
	bne.w	.hor
	jsr	(ClrHor).l
.hor	movea.l	#VDP_DATA,a0
	move.w	#$9100,4(a0)
	move.w	#$9200,4(a0)
	bset	#3,(disflags).w		;dfclock: clock needs update
	bclr	#0,(sflags).w		;sfpz
	jsr	(printscores1).l
	jsr	(setvideo).l
	move.w	#$18,(palcount).w
.wait	tst.w	(palcount).w
	bpl.s	.wait
	move.w	(vcount).w,(oldvcount).w
	rts

SetupPauseScreen	;draw routine for the pause menu (92 Pausemode .pall / .top)
	;also called from $F9D4
	movea.l	#VDP_DATA,a0
	move.w	#$9100,4(a0)		;playfield 3 width
	move.w	#$921C,4(a0)		;playfield 3 height
	jsr	(SetHor).l
	jsr	(setvideo).l
	jsr	(KillCrowd).l
	bsr.w	printsmallz		;erase playfield 3
	String	$FF,3,$FD,0,$FC,0
	moveq	#$20,d0			;32
	moveq	#$1C,d1			;28
	move.w	#$7FF,d2
	bra.w	eraser

seta2	;IDA: GetTeamFromPause. Set a2 to tmstruct of pause joystick
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#1,(sflags).w		;sfpj
	beq.w	.seta20
	cmpi.w	#1,(cont2team).w
	bra.w	.seta21
.seta20	cmpi.w	#1,(cont1team).w
.seta21	beq.w	.x
	adda.w	#$1A2,a2		;tmsize
.x	rts

InitMenuState	;start a menu. a0 = item list, a1 = screen draw routine
	;falls into DrawMenuScreen
	move.l	a0,(dword_FFC9B8).w	;item list
	move.l	a1,(dword_FFC9BC).w	;draw routine
	clr.w	(dword_FFC9B4).w	;selected item
	clr.w	(dword_FFC9B4+2).w	;first visible item

DrawMenuScreen	;call the draw routine, frame the menu box, print the items, fade in
	movea.l	(dword_FFC9BC).w,a0
	jsr	(a0)
	bsr.w	printsmallz
	String	$FE,4,$FC,$C
	bsr.w	SetMenuPrintX
	moveq	#$16,d0			;22 wide
	moveq	#6,d1			;6 high
	bsr.w	Framer
	bsr.w	UpdateMenuSelection
	move.w	#$18,(palcount).w	;fade in
	rts

SetMenuPrintX	;printx = left edge of menu box: 5 in 32 column mode, else 9
	move.w	#5,(printx).w
	btst	#1,(disflags).w		;df32c: 32 column mode on
	bne.w	rtss2
	addq.w	#4,(printx).w
	rts

HandleMenuInput	;process one controller read (d1) for the current menu
	;return eq = leave menu, ne = stay
	btst	#7,d1			;sbut
	bne.w	.flip			;start: Z clear, flipped to eq
	btst	#1,d1			;dbut
	beq.w	.1
	addq.w	#1,(dword_FFC9B4).w	;next lower menu item
	bra.w	UpdateMenuSelection
.1	btst	#0,d1			;ubut
	beq.w	.2
	subq.w	#1,(dword_FFC9B4).w	;next higher menu item
	bra.w	UpdateMenuSelection
.2	btst	#5,d1			;cbut
	beq.w	.flip			;nothing: Z set, flipped to ne
	bsr.w	seta2
	move.w	(dword_FFC9B4).w,d0	;find handler for selected item
	movea.l	(dword_FFC9B8).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.3
.4	addq.w	#4,a0
.3	adda.w	(a0),a0
	dbf	d0,.4
	movea.l	(a0),a0
	jsr	(a0)			;goto routine for current menu item
	bsr.w	DrawMenuScreen
	tst.w	(dword_FFC9B4).w	;item 0 (resume) leaves the menu
	rts
.flip	eori	#4,ccr			;invert Z
	rts

UpdateMenuSelection	;clamp the selection, scroll the 4 visible rows, print the menu
	move.w	(dword_FFC9B4).w,d0
	bpl.w	.0
	clr.w	(dword_FFC9B4).w	;no item above the first
	clr.w	d0
.0	movea.l	(dword_FFC9B8).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.2
.1	adda.w	(a0),a0
	addq.w	#4,a0
	tst.w	2(a0)			;negative = last item
.2	dbmi	d0,.1
	addq.w	#1,d0
	sub.w	d0,(dword_FFC9B4).w	;no item below the last
	move.w	(dword_FFC9B4).w,d0
	cmp.w	(dword_FFC9B4+2).w,d0
	bge.w	.3
	move.w	d0,(dword_FFC9B4+2).w	;scroll up
.3	subq.w	#3,d0
	cmp.w	(dword_FFC9B4+2).w,d0
	ble.w	.4
	move.w	d0,(dword_FFC9B4+2).w	;scroll down
.4	bsr.w	SetMenuPrintX
	move.w	#$D,(printy).w
	movea.l	(dword_FFC9B8).w,a1
	bsr.w	printsmall		;menu title
	bsr.w	printsmallz		;clear the 4 item rows
	dc.w	$0026			;String length, 36 bytes too long for the macro
	dc.b	$FB,$01,$20,$FB,$FF,$FA,$01,$20,$FB,$FF,$FA,$01
	dc.b	$20,$FB,$FF,$FA,$01,$20,$FB,$12,$20,$FB,$FF,$FA
	dc.b	$FF,$20,$FB,$FF,$FA,$FF,$20,$FB,$FF,$FA,$FF,$20
	adda.w	(a1),a1
	move.w	(dword_FFC9B4+2).w,d0	;skip to first visible item
	bra.w	.6
.5	adda.w	(a1),a1
	addq.w	#4,a1
.6	dbf	d0,.5
	moveq	#3,d1			;4 rows
	move.w	#$C,(printy).w
	bsr.w	SetMenuPrintX
	move.w	(dword_FFC9B4+2).w,d0
	beq.w	.7
	bsr.w	printsmallz		;more items above
	String	$FE,5,$FB,1,$FA,1,$7B,$FA,$FF
.7	bsr.w	SetMenuPrintX
	bsr.w	printsmallz
	String	$FB,2,$FA,1
	move.l	a1,-(sp)
	movea.l	(dword_FFC9B8).w,a1
	bsr.w	printsmall
	cmp.w	(dword_FFC9B4).w,d0
	bne.w	.8
	bsr.w	printsmall		;selected item marker
.8	movea.l	(sp)+,a1
	bsr.w	printsmall		;item text
	addq.w	#1,d0
	addq.w	#4,a1
	tst.w	2(a1)			;negative = last item
	dbmi	d1,.7
	bmi.w	.x
	bsr.w	SetMenuPrintX
	bsr.w	printsmallz		;more items below
	String	$FE,5,$FB,1,$7D
.x	rts

PrintTeamData	;copy 2 rows of 12 map words from $FFC210+d0 to printx/printy,
	;then printx += 12. Saves d0-d2/a0-a1
	movem.l	d0-d2/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng: don't int graphics
	movea.w	#(unk_FFC210-M68K_RAM),a1
	adda.w	d0,a1
	moveq	#1,d2			;2 rows
.0	bsr.w	xyVmMap
	moveq	#$B,d1			;12 words
.1	move.w	(a1)+,(a0)
	dbf	d1,.1
	addq.w	#1,(printy).w
	dbf	d2,.0
	addi.w	#$C,(printx).w
	subq.w	#2,(printy).w
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0-a1
	rts

MenuWaitVblank	;wait for the next vblank, then resync vcount. Saves d0
	move.w	d0,-(sp)
	move.w	(oldvcount).w,d0
.0	cmp.w	(vcount).w,d0
	beq.s	.0
	move.w	(oldvcount).w,(vcount).w
	move.w	(sp)+,d0
	rts
