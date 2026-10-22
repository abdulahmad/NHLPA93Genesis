;	Menu engine shared by the whole game, plus two screen helpers. The engine is a generic scrolling menu:
;	an item list plus a screen draw routine. The pause menu, line editor and summary screens all run on it,
;	so they share the pause menu's frame (22 wide, 6 high).
;
;	PutTeamBlock (team name bitmap) and MenuWaitVblank (vblank wait for screen loops) are not menu code. They
;	sit here because they lie between the menu engine and stats93.asm in the ROM.

InitMenuState						;from 92 Pausemode .top. start a menu. a0 = item list, a1 = screen draw
									;routine falls into DrawMenuScreen
	move.l	a0,(menulist).w			;item list
	move.l	a1,(menudraw).w			;draw routine
	clr.w	(menuitem).w			;selected item
	clr.w	(menuitem+2).w			;first visible item

DrawMenuScreen						;from 92 Pausemode setup. call the draw routine, frame the menu box, print
									;the items, fade in
	movea.l	(menudraw).w,a0
	jsr	(a0)
	bsr.w	printsmallz
	String	CC_SetAttribute,4,CC_SetY,$C
	bsr.w	SetMenuPrintX
	moveq	#$16,d0					;22 wide
	moveq	#6,d1					;6 high
	bsr.w	Framer
	bsr.w	UpdateMenuSelection
	move.w	#$18,(palcount).w		;fade in
	rts

SetMenuPrintX						;printx = left edge of menu box: 5 in 32 column mode, else 9
	move.w	#5,(printx).w
	btst	#df32c,(disflags).w		;32 column mode on
	bne.w	rtss2
	addq.w	#4,(printx).w
	rts

HandleMenuInput						;from 92 Pausemode input. process one controller read (d1) for the current
									;menu return eq = leave menu, ne = stay
	btst	#sbut,d1				;sbut
	bne.w	.flip					;start: Z clear, flipped to eq
	btst	#dbut,d1				;dbut
	beq.w	.up
	addq.w	#1,(menuitem).w			;next lower menu item
	bra.w	UpdateMenuSelection
.up	btst	#ubut,d1				;ubut
	beq.w	.sel
	subq.w	#1,(menuitem).w			;next higher menu item
	bra.w	UpdateMenuSelection
.sel	btst	#cbut,d1			;cbut
	beq.w	.flip					;nothing: Z set, flipped to ne
	bsr.w	seta2
	move.w	(menuitem).w,d0			;find handler for selected item
	movea.l	(menulist).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.3
.next	addq.w	#4,a0				;step to the next item entry (4 bytes)
.3	adda.w	(a0),a0					;add the entry's word offset to reach the following one
	dbf	d0,.next					;d0 = selected item number: repeat until the selected entry
	movea.l	(a0),a0
	jsr	(a0)						;goto routine for current menu item
	bsr.w	DrawMenuScreen
	tst.w	(menuitem).w			;item 0 (resume) leaves the menu
	rts
.flip	eori	#4,ccr				;invert Z
	rts

UpdateMenuSelection					;from 92 Pausemode .Pmenu. clamp the selection, scroll the 4 visible rows,
									;print the menu
	move.w	(menuitem).w,d0
	bpl.w	.0
	clr.w	(menuitem).w			;no item above the first
	clr.w	d0
.0	movea.l	(menulist).w,a0			;walk the item list d0 entries, stopping at the last one
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.2
.next	adda.w	(a0),a0				;advance to the next item entry
	addq.w	#4,a0
	tst.w	2(a0)					;negative = last item
.2	dbmi	d0,.next				;stop after d0 items or at the last item
	addq.w	#1,d0					;d0 = items left unwalked (-1 if all walked), +1 = overshoot
	sub.w	d0,(menuitem).w			;no item below the last
	move.w	(menuitem).w,d0
	cmp.w	(menuitem+2).w,d0
	bge.w	.3
	move.w	d0,(menuitem+2).w		;scroll up
.3	subq.w	#3,d0					;selection - 3 = first visible item if it is on the bottom row
	cmp.w	(menuitem+2).w,d0
	ble.w	.print
	move.w	d0,(menuitem+2).w		;scroll down
.print	bsr.w	SetMenuPrintX		;print the menu: title, then marker columns, then the 4 rows
	move.w	#$D,(printy).w
	movea.l	(menulist).w,a1
	bsr.w	printsmall				;menu title
	bsr.w	printsmallz				;blank the selection marker columns left and right of the 4 item rows
	dc.w	$0026					;String length word: 2 + 36 data bytes (too long for the String macro)
	dc.b	CC_AddX,$01,$20,CC_AddX,$FF,CC_AddY,$01,$20	;left column: blank, down a row, blank ...
	dc.b	CC_AddX,$FF,CC_AddY,$01,$20,CC_AddX,$FF,CC_AddY,$01,$20	;.. 4 rows
	dc.b	CC_AddX,$12,$20,CC_AddX,$FF,CC_AddY,$FF,$20	;right column (18 columns over), blank, up a row ...
	dc.b	CC_AddX,$FF,CC_AddY,$FF,$20,CC_AddX,$FF,CC_AddY,$FF,$20	;.. back to the top row
	adda.w	(a1),a1
	move.w	(menuitem+2).w,d0		;skip to first visible item
	bra.w	.6
.skip	adda.w	(a1),a1				;skip one item entry
	addq.w	#4,a1
.6	dbf	d0,.skip					;loop until a1 = first visible item
	moveq	#3,d1					;4 rows
	move.w	#$C,(printy).w
	bsr.w	SetMenuPrintX
	move.w	(menuitem+2).w,d0
	beq.w	.row
	bsr.w	printsmallz				;more items above
	String	CC_SetAttribute,5,CC_AddX,1,CC_AddY,1,$7B,CC_AddY,$FF
.row	bsr.w	SetMenuPrintX		;one row per visible item; d0 = item number, d1 = rows left-1
	bsr.w	printsmallz
	String	CC_AddX,2,CC_AddY,1
	move.l	a1,-(sp)
	movea.l	(menulist).w,a1
	bsr.w	printsmall
	cmp.w	(menuitem).w,d0
	bne.w	.nosel
	bsr.w	printsmall				;selected item marker
.nosel	movea.l	(sp)+,a1			;a1 = this item's text entry
	bsr.w	printsmall				;item text
	addq.w	#1,d0
	addq.w	#4,a1
	tst.w	2(a1)					;negative = last item
	dbmi	d1,.row
	bmi.w	.x
	bsr.w	SetMenuPrintX
	bsr.w	printsmallz				;more items below
	String	CC_SetAttribute,5,CC_AddX,1,$7D
.x	rts								;last item reached: no more-below marker

PutTeamBlock						;copy 2 rows of 12 map words from TeamBlockMap+d0 to printx/printy, then
									;printx += 12. Saves d0-d2/a0-a1
	movem.l	d0-d2/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w		;don't int graphics
	movea.w	#(TeamBlockMap-M68K_RAM),a1
	adda.w	d0,a1
	moveq	#1,d2					;2 rows
.row	bsr.w	xyVmMap				;a0 = vram data port at printx/y
	moveq	#$B,d1					;12 words
.1	move.w	(a1)+,(a0)				;write one map word
	dbf	d1,.1
	addq.w	#1,(printy).w
	dbf	d2,.row
	addi.w	#$C,(printx).w
	subq.w	#2,(printy).w
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0-a1
	rts

MenuWaitVblank						;from 92 Pausemode .rjoy wait. wait for the next vblank, then resync
									;Vcount. Saves d0
	move.w	d0,-(sp)
	move.w	(OldVcount).w,d0
.wait	cmp.w	(Vcount).w,d0		;Vcount is bumped by the vblank handler
	beq.s	.wait
	move.w	(OldVcount).w,(Vcount).w	;puts the old count back: possible original bug
	move.w	(sp)+,d0
	rts
