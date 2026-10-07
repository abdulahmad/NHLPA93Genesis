;	NHLPA Hockey 93 (retail) segment $6A00-$6C09
;	93-only menu engine: InitMenuState through MenuWaitVblank. The generic
;	scrolling menu used by the pause screen (Pausemode in hockey93_01).
;	Not in NHL 92; names are IDA names (Rev A listing).
;	Bytes match nhlpa93retail.bin.
;	92 equate names in comments are only used where the 93 value is the same.
;	Inline print strings after printsmallz/printsmall use the String macro
;	(length word includes itself, odd data is padded to a word).

InitMenuState	;start a menu. a0 = item list, a1 = screen draw routine
	;falls into DrawMenuScreen
	move.l	a0,(menulist).w	;item list
	move.l	a1,(menudraw).w	;draw routine
	clr.w	(menuitem).w	;selected item
	clr.w	(menuitem+2).w	;first visible item

DrawMenuScreen	;call the draw routine, frame the menu box, print the items, fade in
	movea.l	(menudraw).w,a0
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
	btst	#df32c,(disflags).w		;32 column mode on
	bne.w	rtss2
	addq.w	#4,(printx).w
	rts

HandleMenuInput	;process one controller read (d1) for the current menu
	;return eq = leave menu, ne = stay
	btst	#7,d1			;sbut
	bne.w	.flip			;start: Z clear, flipped to eq
	btst	#1,d1			;dbut
	beq.w	.1
	addq.w	#1,(menuitem).w	;next lower menu item
	bra.w	UpdateMenuSelection
.1	btst	#0,d1			;ubut
	beq.w	.2
	subq.w	#1,(menuitem).w	;next higher menu item
	bra.w	UpdateMenuSelection
.2	btst	#5,d1			;cbut
	beq.w	.flip			;nothing: Z set, flipped to ne
	bsr.w	seta2
	move.w	(menuitem).w,d0	;find handler for selected item
	movea.l	(menulist).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.3
.4	addq.w	#4,a0
.3	adda.w	(a0),a0
	dbf	d0,.4
	movea.l	(a0),a0
	jsr	(a0)			;goto routine for current menu item
	bsr.w	DrawMenuScreen
	tst.w	(menuitem).w	;item 0 (resume) leaves the menu
	rts
.flip	eori	#4,ccr			;invert Z
	rts

UpdateMenuSelection	;clamp the selection, scroll the 4 visible rows, print the menu
	move.w	(menuitem).w,d0
	bpl.w	.0
	clr.w	(menuitem).w	;no item above the first
	clr.w	d0
.0	movea.l	(menulist).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.2
.1	adda.w	(a0),a0
	addq.w	#4,a0
	tst.w	2(a0)			;negative = last item
.2	dbmi	d0,.1
	addq.w	#1,d0
	sub.w	d0,(menuitem).w	;no item below the last
	move.w	(menuitem).w,d0
	cmp.w	(menuitem+2).w,d0
	bge.w	.3
	move.w	d0,(menuitem+2).w	;scroll up
.3	subq.w	#3,d0
	cmp.w	(menuitem+2).w,d0
	ble.w	.4
	move.w	d0,(menuitem+2).w	;scroll down
.4	bsr.w	SetMenuPrintX
	move.w	#$D,(printy).w
	movea.l	(menulist).w,a1
	bsr.w	printsmall		;menu title
	bsr.w	printsmallz		;clear the 4 item rows
	dc.w	$0026			;String length, 36 bytes too long for the macro
	dc.b	$FB,$01,$20,$FB,$FF,$FA,$01,$20,$FB,$FF,$FA,$01
	dc.b	$20,$FB,$FF,$FA,$01,$20,$FB,$12,$20,$FB,$FF,$FA
	dc.b	$FF,$20,$FB,$FF,$FA,$FF,$20,$FB,$FF,$FA,$FF,$20
	adda.w	(a1),a1
	move.w	(menuitem+2).w,d0	;skip to first visible item
	bra.w	.6
.5	adda.w	(a1),a1
	addq.w	#4,a1
.6	dbf	d0,.5
	moveq	#3,d1			;4 rows
	move.w	#$C,(printy).w
	bsr.w	SetMenuPrintX
	move.w	(menuitem+2).w,d0
	beq.w	.7
	bsr.w	printsmallz		;more items above
	String	$FE,5,$FB,1,$FA,1,$7B,$FA,$FF
.7	bsr.w	SetMenuPrintX
	bsr.w	printsmallz
	String	$FB,2,$FA,1
	move.l	a1,-(sp)
	movea.l	(menulist).w,a1
	bsr.w	printsmall
	cmp.w	(menuitem).w,d0
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
	bset	#dfng,(disflags).w		;don't int graphics
	movea.w	#(TeamBlockMap-M68K_RAM),a1
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
