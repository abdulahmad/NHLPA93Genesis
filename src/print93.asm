;	Text and box drawing. xyVmMap sets the vram address from the print position, eraser and Framer fill and
;	frame rectangles, and printsmall, printz, print and printbig draw text with their control codes. AddSmallFont,
;	AddFramer and AddTeamBlock load the font, frame and team block tiles.
;
;	Build note: EA's compiler emits cmp #imm,Dn as CMP (Bxxx) but SNASM emits CMPI (0Cxx). The source has the
;	real cmp / exg; fixopcodes.js patches the encoding after assembly.

xyVmMap								;use printx/y/m to set vram address. Returns a0 = Vdata.
									;Saves d0-d2 and calls Vmaddr
	movem.l	d0-d2,-(sp)
	move.w	(printx).w,d0
	move.w	(printy).w,d1
	movea.w	#(VmMAP1-M68K_RAM),a0
	adda.w	(printm).w,a0
	move.w	2(a0),d2				;map width shift
	asl.w	d2,d1
	add.w	d1,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	movem.l	(sp)+,d0-d2
	rts

eraser								;fill rectangle with char. d0/d1 = x/y size of rectangle, d2 = char word
									;to fill with, printx/y/m define top left corner to start at
	movem.l	d0-d2/a0,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.w	d0-d1,-(sp)
.1	bsr.s	xyVmMap					;one row: a0 = vram port at printx/y
	move.w	(sp),d0					;width
	subq.w	#1,d0
.0	move.w	d2,(a0)					;fill one cell
	dbf	d0,.0
	addq.w	#1,(printy).w			;next row
	andi.w	#$1F,(printy).w			;31
	subq.w	#1,2(sp)				;rows left
	bne.s	.1
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0
	rts

Framer								;frame and fill (uses framer.map graphics and assums tiles are already
									;located at framercset). d0/d1 = x/y size of rectangle, printx/y/m define
									;top left corner to start at
	movem.l	d0-d4/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.w	d0-d1,-(sp)
	move.w	(printa).w,d2
	add.w	(framercset).w,d2
	movea.l	#Framermap,a1
	adda.l	4(a1),a1
	addq.w	#4,a1
	clr.w	d4						;d4 = offset of the frame map row (6 bytes per row: left, middle, right)
	bsr.w	.tbline					;top row

	subq.w	#3,2(sp)				;height-3: loop counter for the middle rows
.mtop	bsr.w	.tbline				;middle row (height-2 times)
	subq.w	#6,d4					;stay on the middle map row
	subq.w	#1,2(sp)
	bpl.s	.mtop
	addq.w	#6,d4					;step to the bottom map row
	bsr.w	.tbline					;bottom row
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d4/a0-a1
	rts

.tbline	bsr.w	xyVmMap				;draw one frame row: left cell, width-2 middle cells, right cell
	addq.w	#1,(printy).w
	bsr.w	.setter					;left cell
	addq.w	#2,d4
	move.w	4(sp),d0				;width
	subq.w	#3,d0
.tblp	bsr.w	.setter				;middle cells
	dbf	d0,.tblp
	addq.w	#2,d4
	bsr.w	.setter					;right cell
	addq.w	#2,d4					;d4 = next map row
	rts

.setter	move.w	(a1,d4.w),d3		;frame map word + char base/attribute (d2), written to vram
	add.w	d2,d3
	move.w	d3,(a0)
	rts

printsmallz							;92 printz. see printsmall. String macro should follow the bsr/jsr to this
									;routine; a1 is kept
	move.l	a1,-(sp)
	movea.l	4(sp),a1				;string after the call
	bsr.w	printsmall
	move.l	a1,4(sp)				;return past the string
	movea.l	(sp)+,a1
	rts

printsmall							;92 print. print string macro a1 at printx/y/m with printa. Bytes > 0 are
									;chars ('@' = blank char $7FF, '^' = skip a column), tile = smallfontmap
									;entry + smallfontchars[printfontset]. Bytes <= 0 run ControlCodeJumpTable
									;entry -byte (0 = nothing)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2-a3,-(sp)
	movea.w	#(smallfontchars-M68K_RAM),a3	;char set bases, picked by printfontset
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3				;string length
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0				;next string byte
	ext.w	d0
	bgt.w	.nocom					;> 0: character
	neg.w	d0						;control code (0 = padding)
	asl.w	#2,d0
	movea.l	#ControlCodeJumpTable,a2
	movea.l	(a2,d0.w),a2
	jsr	(a2)
	bra.w	.1

.nocom	cmp.b	#'@',d0				;ordinary character
	bne.w	.noblank
	move.w	#$7FF,d0				;blank char (92 moveq #1)
	bra.w	.p
.noblank	cmp.b	#'^',d0			;not blank; '^' = skip a column
	beq.w	.skip
	asl.w	#1,d0					;ascii -> word index into the font map
	movea.l	#smallfontmap,a2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0			;tile number of this char
	move.w	(printfontset).w,d1		;char set * 2
	add.w	(a3,d1.w),d0
.p	add.w	d2,d0					;for alternate paletes
	move.w	d0,(a0)					;write the cell
	addq.w	#1,(printx).w
.1	dbf	d3,.0						;d3 = bytes left in the string
	movem.l	(sp)+,d0-d3/a0/a2-a3
	move.w	(sp)+,(disflags).w
	rts

.skip	addq.w	#1,(printx).w		;'^': skip a column
	bsr.w	xyVmMap
	bra.s	.1

ControlCodeJumpTable				;printsmall control codes, indexed by -byte
	dc.l	rtss					;0: padding, no-op
	dc.l	ControlCode_SetMap		;-1: map
	dc.l	ControlCode_SetAttribute	;-2: palette/priority
	dc.l	ControlCode_SetX		;-3: x
	dc.l	ControlCode_SetY		;-4: y
	dc.l	ControlCode_AddX		;-5: x offset
	dc.l	ControlCode_AddY		;-6: y offset
	dc.l	ControlCode_SetFont		;-7: char set
	dc.l	ControlCode_SetMapAndPosition	;-8: attribute, map, x, y

ControlCode_SetMapAndPosition		;92 print negative-byte block. printsmall code -8, next 4 bytes =
									;attribute, map, x, y
	bsr.w	ControlCode_SetAttribute
	bsr.w	ControlCode_SetMap
	bsr.w	ControlCode_SetX
	bra.w	ControlCode_SetY

ControlCode_SetMap					;printsmall code -1, next byte = map number (1-3) -> printm
	move.b	(a1)+,d0
	subq.w	#1,d3
	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w
	bra.w	xyVmMap

ControlCode_SetAttribute			;printsmall code -2, next byte = palette/priority (0-7) -> printa bits
									;13-15 and d2
	move.b	(a1)+,d2
	andi.w	#7,d2
	subq.w	#1,d3
	ror.w	#3,d2
	move.w	d2,(printa).w
	rts

ControlCode_SetX					;printsmall code -3, next byte = printx
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printx).w
	bra.w	xyVmMap

ControlCode_SetY					;printsmall code -4, next byte = printy
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printy).w
	bra.w	xyVmMap

ControlCode_AddX					;printsmall code -5, add the next (signed) byte to printx
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printx).w
	bra.w	xyVmMap

ControlCode_AddY					;printsmall code -6, add the next (signed) byte to printy
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printy).w
	bra.w	xyVmMap

ControlCode_SetFont					;printsmall code -7, next byte = char set index (printfontset = index*2
									;into smallfontchars)
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	asl.w	#1,d0
	move.w	d0,(printfontset).w
	rts

printz								;see print. String macro should follow the bsr/jsr to this routine. Keeps
									;a1 (92 popped the return into a1)
	move.l	a1,-(sp)
	movea.l	4(sp),a1				;string after the call
	bsr.w	print
	move.l	a1,4(sp)				;return past the string
	movea.l	(sp)+,a1
	rts

print								;a1 = string macro, printx/y = x/y cordinate on map for printing, printm =
									;map to print on, printa = attribute for characters. string
									;\-$ab,$xx,$yy,'Sample!'\ : a = map number (1-3), b = color/priority (0-3
									;= color fam, prio off),(4-7 = color fam, prio on), xx/yy = x/y cord to
									;print at. '@' = char $7FF, '^' = skip a column
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0				;next string byte
	beq.w	.1						;padding
	ext.w	d0
	bpl.w	.nocom					;> 0: character
	neg.w	d0						;-$ab: new attribute, map, x, y
	move.w	d0,d2
	asl.w	#8,d2
	asl.w	#1,d2
	andi.w	#$F800,d2				;b (bits 7-4 of the code) -> palette/priority bits 15-11
	move.w	d2,(printa).w

	andi.w	#3,d0					;a = map number
	asl.w	#2,d0
	subq.w	#4,d0					;printm = (map-1)*4
	move.w	d0,(printm).w

	move.b	(a1)+,d0				;xx
	ext.w	d0
	move.w	d0,(printx).w
	move.b	(a1)+,d1
	ext.w	d1
	move.w	d1,(printy).w
	bsr.w	xyVmMap
	subq.w	#2,d3
	bra.w	.1

.nocom	cmp.b	#'@',d0				;ordinary character
	bne.w	.noblank
	move.w	#$7FF,d0				;blank char (92 moveq #1)
	bra.w	.p
.noblank	cmp.b	#'^',d0			;'^' = skip a column
	beq.w	.skip
	asl.w	#1,d0					;ascii -> word index into the font map
	movea.l	#smallfontmap,a2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0			;tile number of this char
	add.w	(smallfontchars).w,d0	;plus first small font char in vram
.p	add.w	d2,d0					;for alternate paletes
	move.w	d0,(a0)					;write the cell
	addq.w	#1,(printx).w
.1	dbf	d3,.0						;d3 = bytes left in the string
	movem.l	(sp)+,d0-d3/a0/a2
	move.w	(sp)+,(disflags).w
	rts

.skip	addq.w	#1,(printx).w		;'^': skip a column
	bsr.w	xyVmMap
	bra.s	.1

FormatAndPrintTime					;print a period label and time. d0 bits 14-15 = period (PeriodLabelTable
									;entry), bits 0-13 = seconds. Called from DrawScoringRow and
									;DisplayPenaltyEntry
	swap	d0
	clr.w	d0
	rol.l	#2,d0					;d0.w = period
	movea.l	#PeriodLabelTable,a1
	bsr.w	Fprintsmall
	addq.w	#2,(printx).w
	swap	d0
	lsr.w	#2,d0					;seconds
	bsr.w	PushTime
	bra.w	print

PeriodLabelTable					;String list for FormatAndPrintTime: " 1", " 2", " 3", "OT"
	dc.w	4
	dc.b	' 1'
	dc.w	4
	dc.b	' 2'
	dc.w	4
	dc.b	' 3'
	dc.w	4
	dc.b	'OT'

PushTime							;convert d0 into string format of minutes:seconds. Return a1 = string.
									;pads the minutes to 2 places with a space
	movea.w	#(mesarea+30-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)

	ext.l	d0
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0

	ext.l	d0
	divu.w	#6,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0

	move.b	#':',-(a1)

	ext.l	d0
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0

	move.b	#' ',-(a1)				;leading space
	tst.w	d0
	beq.w	.noz					;minutes tens = 0: keep the space
	addi.w	#'0',d0
	move.b	d0,(a1)					;over the space (92 -(a1))
.noz	move.l	(sp)+,d0			;d0 = end address of the string
	sub.l	a1,d0
	addq.w	#2,d0					;length incl. the length word
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)					;pad to an even length
	addq.w	#1,d0
.1	move.w	d0,-(a1)				;string length word in front
	move.l	(sp)+,d0
	rts

PushNumber							;convert d0 into string format of base 10 number, no leading zeros. Return
									;a1 = string
	movea.w	#(PushNumberBuf-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)
.0	ext.l	d0						;next digit: remainder of /10, written backwards
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0
	tst.w	d0
	bne.s	.0						;quotient left: more digits
	move.l	(sp)+,d0				;d0 = end address of the string
	sub.l	a1,d0
	addq.w	#2,d0					;length incl. the length word
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)					;pad to an even length
	addq.w	#1,d0
.1	move.w	d0,-(a1)				;string length word in front
	move.l	(sp)+,d0
	rts

PushNumberWidth						;convert d0 into a d1 digit base 10 string, leading zeros as spaces (the
									;last digit always shown). Return a1 = string at PushWidthBuf
	movem.l	d0-d3,-(sp)
	movea.w	#(PushWidthBuf+2-M68K_RAM),a1
	moveq	#1,d2
	sub.w	d2,d1
	bra.w	.pw
.mul	mulu.w	#10,d2				;d2 *= 10
.pw	dbf	d1,.mul						;d2 = 10^(d1-1)
	moveq	#' ',d3					;leading fill
.dig	ext.l	d0					;next digit: d0 / d2, high digit first
	divu.w	d2,d0
	bne.w	.digit
	cmp.w	#1,d2
	beq.w	.digit					;last digit: always a number
	move.w	d3,d0					;leading zero
	bra.w	.put
.digit	moveq	#'0',d3				;from here on zeros are digits
	add.w	d3,d0
.put	move.b	d0,(a1)+			;store the char (digit or space)
	swap	d0						;d0.w = remainder for the next digit
	divu.w	#10,d2					;next lower power of ten
	bne.s	.dig
	move.l	a1,d0
	subi.w	#(PushWidthBuf-M68K_RAM),d0	;length incl. the length word
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even	movea.w	#(PushWidthBuf-M68K_RAM),a1	;store the length word at the front
	move.w	d0,(a1)
	movem.l	(sp)+,d0-d3
	rts

appendz								;see appstring. String macro should follow the bsr/jsr to this routine
	movea.l	(sp)+,a1
	bsr.w	appstring
	jmp	(a1)

appstring							;append string a1 to string a3
	movem.l	d0/a0,-(sp)
	lea	2(a3),a0					;a0 scans a3's text for its terminating zero
	move.w	(a3),d0					;a3 length word
	subq.w	#3,d0
	bmi.w	.1
.0	addq.w	#1,a0					;next byte of the destination
	tst.b	(a0)
	dbeq	d0,.0					;stop at the zero byte
.1	move.w	(a1)+,d0				;a1 length word
	subq.w	#3,d0
	bmi.w	.ex						;empty source: nothing to append
.2	move.b	(a1)+,(a0)+				;copy one char
	bne.w	.3
	subq.w	#1,a0					;a zero byte is not kept, so it gets overwritten next
.3	dbf	d0,.2
	move.l	a0,d0
	btst	#0,d0
	beq.w	.4
	clr.b	(a0)+					;pad to an even length
	addq.l	#1,d0
.4	sub.l	a3,d0					;new total length
	move.w	d0,(a3)
.ex	movem.l	(sp)+,d0/a0				;restore registers and return
	rts

printbigz							;see print big. String macro should follow the bsr/jsr to this routine.
									;Keeps a1 (92 popped the return into a1)
	move.l	a1,-(sp)
	movea.l	4(sp),a1				;string after the call
	bsr.w	printbig
	move.l	a1,4(sp)				;return past the string
	movea.l	(sp)+,a1
	rts

printbig							;same as print, only use bigfont.map graphics. a1 = string macro, printx/y
									;= x/y cordinate on map for printing, printm = map to print on, printa =
									;attribute for characters. string \-$ab,$xx,$yy,'Sample!'\ : a = map
									;number (1-3), b = color/priority (0-3 = color fam, prio off),(4-7 = color
									;fam, prio on), xx/yy = x/y cord to print at
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d7/a0/a2,-(sp)
	move.w	(printx).w,d4
	move.w	(printy).w,d5
	move.w	(printa).w,d6
	add.w	(BigFontchars).w,d6

	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0				;next string byte
	beq.w	.1						;padding
	ext.w	d0
	bpl.w	.nocom					;> 0: character
	neg.w	d0						;-$ab: new attribute, map, x, y
	move.w	d0,d6
	asl.w	#8,d6
	asl.w	#1,d6
	andi.w	#$F800,d6				;b -> palette/priority bits
	move.w	d6,(printa).w
	add.w	(BigFontchars).w,d6		;d6 = attribute + big font char base

	andi.w	#3,d0					;a = map number
	asl.w	#2,d0
	subq.w	#4,d0					;printm = (map-1)*4
	move.w	d0,(printm).w

	move.b	(a1)+,d4				;xx
	ext.w	d4
	move.w	d4,(printx).w
	move.b	(a1)+,d5				;yy
	ext.w	d5
	move.w	d5,(printy).w
	subq.w	#2,d3					;two extra bytes consumed
	bra.w	.1

.nocom	cmp.b	#'a',d0				;big font has no lower case: fold to upper
	blt.w	.2
	cmp.b	#'z',d0
	bgt.w	.2
	addi.b	#'A'-'a',d0
.2	move.w	d3,-(sp)				;.dochar uses d3
	bsr.w	.dochar
	move.w	(sp)+,d3
.1	dbf	d3,.0						;d3 = bytes left in the string
	move.w	d4,(printx).w
	move.w	d5,(printy).w
	movem.l	(sp)+,d0-d7/a0/a2
	move.w	(sp)+,(disflags).w
	rts

.dochar	subi.w	#$20,d0				;no special case for space
	movea.l	#bfasciicon,a0			;per-char table of brush offsets into the big font map
	moveq	#1,d2					;chars wide-1
	move.b	(a0,d0.w),d1			;brush offset
	ext.w	d1
	bpl.w	.p0
	neg.w	d1						;negative: one char wide
	clr.w	d2
.p0	asl.w	#1,d1					;word offset into the map
	movea.l	#bigfontmap,a0
	adda.l	4(a0),a0
.p1	move.w	4(a0,d1.w),d3			;top tile of this column
	bsr.w	.dump
	move.w	(a0),d7					;map width
	asl.w	#1,d7
	add.w	d7,d1					;same column, row below
	move.w	4(a0,d1.w),d3			;bottom tile
	sub.w	d7,d1
	addq.w	#1,d5
	bsr.w	.dump
	subq.w	#1,d5
	addq.w	#1,d4					;x char position
	addq.w	#2,d1					;next column of the brush
	dbf	d2,.p1						;chars are two tiles tall, one or two wide
	rts

.dump	add.w	d6,d3				;write tile d3 (+ attribute/char base d6) at d4/d5 of map printm
	movem.l	d1/a0,-(sp)
	move.w	d5,d0
	movea.l	#VmMAP1,a0				;$FFFFB004
	adda.w	(printm).w,a0
	move.w	2(a0),d1
	asl.w	d1,d0
	add.w	d4,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	move.w	d3,(a0)
	movem.l	(sp)+,d1/a0
	rts

AddSmallFont						;transfer smallfont.map tiles to vram. d4 = char to start tiles at, return
									;d4 = end of tiles + 1. Goes through DecompressGraphics
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bra.w	DecompressGraphicsPlain

AddFramer							;transfer framer.map tiles to vram. d4 = char to start tiles at, return d4
									;= end of tiles + 1. Goes through DecompressGraphics
	movea.l	#FramerMap+8,a2
	move.w	d4,(framercset).w
	bra.w	DecompressGraphicsPlain

AddTeamBlock						;transfer TeamBlocks.map tiles to vram at char 2. Return d4 = end of tiles
									;+ 1. Goes through DecompressGraphics
	moveq	#2,d4
	movea.l	#Teamblocksmap+8,a2
	bra.w	DecompressGraphicsPlain
