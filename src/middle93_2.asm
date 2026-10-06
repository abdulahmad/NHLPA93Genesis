;	NHLPA Hockey 93 (retail) segment $DCE4-$E525
;	92 Middle.Asm part 2: dobitmap, the 93-only tile decompressor
;	(DecompressGraphicsWithCallback, DoDMA_clearCallbackPointer,
;	DecompressGraphics, DecompressBytecode, jump_table, the Opcode_*
;	handlers, FlushOutputBuffer), xyVmMap, eraser, Framer, the 93-only
;	printsmallz/printsmall with ControlCodeJumpTable and the ControlCode_*
;	handlers, printz, print, the 93-only FormatAndPrintTime and
;	PeriodLabelTable, PushTime, PushNumber, the 93-only PushNumberWidth,
;	appendz, appstring, printbigz, printbig, AddSmallFont, AddFramer and
;	AddTeamBlock. Global names from the IDA export, 92 names where the
;	routine is the same (see the SEGMENT_AGENT.md rename table). Bytes
;	match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	disflags bits: dfng 2 (same as 92).
;	93 loads tiles through DecompressGraphics (a2 = tile data, d4 = start
;	char) instead of 92's direct DoDMA.

dobitmap	;transfer palette data/map data/tiles data to vram. a0 = palette, a1 = map, a2 = tiles (DecompressGraphics data), d0 = start x, d1 = start y, d2 = width x, d3 = width y, d4 = start char, d5 = pal used bits (0-3) for color fam 1-4. 93: printy is restored and the tiles go last through DecompressGraphics (returns d4 = end char)
	move.w	(printy).w,-(sp)	;93: keep printy
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/d5-d6/a0-a3,-(sp)
	move.w	d1,d6			;93: y start in d6 (92 used 6(a7))
	movea.w	#(palfadenew-M68K_RAM),a3
	bra.w	.00
.01	move.b	(a0,d0.w),(a3,d0.w)	;IDA: _01
	dbf	d0,.01
.02	adda.w	#$20,a0			;IDA: _02
	adda.w	#$20,a3
.00	moveq	#$1F,d0			;IDA: _00. 31
	lsr.w	#1,d5
	bcs.s	.01
	bne.s	.02

	move.w	(printa).w,d5
	andi.w	#$F800,d5
	move.w	$E(sp),d2		;width y
	subq.w	#1,d2

.loop2	bsr.w	xyVmMap			;IDA: _loop2
	move.w	d6,d0			;y start
	mulu.w	(a1),d0			;map width
	add.w	2(sp),d0		;x start
	asl.w	#1,d0
	move.w	$A(sp),d1		;width x
	subq.w	#1,d1
.loop1	move.w	4(a1,d0.w),d3		;IDA: _loop1
	add.w	d4,d3
	eor.w	d5,d3
	move.w	d3,(a0)
	addq.w	#2,d0
	dbf	d1,.loop1
	addq.w	#1,(printy).w
	addq.w	#1,d6
	dbf	d2,.loop2
	bsr.w	DoDMA_clearCallbackPointer	;93: tiles a2 to char d4
	movem.l	(sp)+,d0-d3/d5-d6/a0-a3
	move.w	(sp)+,(disflags).w
	move.w	(sp)+,(printy).w
	rts

DecompressGraphicsWithCallback	;93: DecompressGraphics through remap. The 8 bytes after the bsr are the remap color table (callbackPtr = their address); returns past them. a2 = tile data, d4 = start char
	move.l	(sp),(callbackPtr).w
	bsr.w	DecompressGraphics
	addq.l	#8,(sp)			;skip the inline remap table
	rts

DoDMA_clearCallbackPointer	;93: clear callbackPtr (plain DMA, no remap) and fall into DecompressGraphics. a2 = tile data, d4 = start char
	clr.l	(callbackPtr).w

DecompressGraphics	;93: send tiles to vram. a2 = data: word count of tiles (0 = none, bit 15 set = compressed by DecompressBytecode), then the tiles. d4 = start char, returns d4 = end char + 1. Uses remap with callbackPtr when it is set, else DoDMApro
	movem.l	d0-d1/a0-a6,-(sp)
	movea.l	a2,a0			;a0 = compressed data
	move.w	d4,d1
	asl.w	#5,d1			;d1 = vram address of start char
	move.w	(a0)+,d0		;tile count
	beq.w	.done			;no tiles
	bmi.w	.packed			;bit 15: compressed
	add.w	d0,d4
	asl.w	#4,d0			;words to transfer
	pea	(.done).l
	tst.l	(callbackPtr).w
	beq.w	DoDMApro
	movea.l	(callbackPtr).w,a1	;remap table
	bra.w	remap

.packed	andi.w	#$7FFF,d0		;IDA: _decompress. tile count
	add.w	d0,d4
	bsr.w	DecompressBytecode
.done	movem.l	(sp)+,d0-d1/a0-a6	;IDA: _enddecompression
	rts

DecompressBytecode	;93: unpack a0 into the 256 byte ring buffer at DispAttribCtr and flush each full buffer to vram d3 (FlushOutputBuffer). The high nibble of each opcode byte picks a handler from jump_table. Ends on a CopyBackwardReverseMedium code with distance 0. d1 = vram address
	movea.w	#(DispAttribCtr-M68K_RAM),a1	;output buffer
	movea.w	#(DispAttribCtr-M68K_RAM),a3
	movea.w	#(callbackPtr-M68K_RAM),a4
	movea.l	#remap,a5		;IDA: ConvertAndWriteToVDP (Rev A literal $D642)
	movea.l	#DoDMApro,a6		;(Rev A literal $DA98)
	movem.l	d0-d3/a0-a2,-(sp)
	move.w	d1,d3			;d3 = vram address
	clr.w	d1			;d1 = output buffer offset
	clr.w	d2
.loop	move.b	(a0)+,d0		;IDA: main_bytecode_intepreter_loop. read opcode
	andi.w	#$F0,d0
	lsr.w	#3,d0			;upper nibble * 2
	lea	jump_table(pc),a2
	move.w	(a2,d0.w),d0
	jsr	(a2,d0.w)		;handler, reads its count from -1(a0)
	bra.s	.loop

jump_table	;93: DecompressBytecode handler offsets, one per opcode high nibble
	dc.w	Opcode_CopyLiteral-jump_table		;0
	dc.w	Opcode_CopyLiteral-jump_table		;1
	dc.w	Opcode_ClearBytes-jump_table		;2
	dc.w	Opcode_Fillbytes-jump_table		;3
	dc.w	Opcode_CopyBackwardShort-jump_table	;4
	dc.w	Opcode_CopyBackwardShort-jump_table	;5
	dc.w	Opcode_CopyBackwardShort-jump_table	;6
	dc.w	Opcode_CopyBackwardShort-jump_table	;7
	dc.w	Opcode_CopyBackwardMedium-jump_table	;8
	dc.w	Opcode_CopyBackwardLong-jump_table	;9
	dc.w	Opcode_CopyBackwardExtended1-jump_table	;A
	dc.w	Opcode_CopyBackwardExtended2-jump_table	;B
	dc.w	Opcode_CopyBackwardReverseShort-jump_table	;C
	dc.w	Opcode_CopyBackwardReverseShort-jump_table	;D
	dc.w	Opcode_CopyBackwardReverseMedium-jump_table	;E
	dc.w	Opcode_CopyBackwardReverseLong-jump_table	;F

Opcode_CopyLiteral	;93: opcodes 0-1, copy (low 5 bits)+1 bytes from the data
	move.b	-1(a0),d0
	andi.w	#$1F,d0
.loop	move.b	(a0)+,(a1,d1.w)		;IDA: Copy_bytes_loop
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer	;buffer full
.next	dbf	d0,.loop		;IDA: loop_for_count
	rts

Opcode_ClearBytes	;93: opcode 2, write (low 4 bits)+1 zero bytes
	move.b	-1(a0),d0
	andi.w	#$F,d0
.loop	clr.b	(a1,d1.w)		;IDA: Clear_bytes_loop
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop		;IDA: loop_for_count2
	rts

Opcode_Fillbytes	;93: opcode 3, write the next data byte (low 4 bits)+3 times
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
.loop	move.b	d2,(a1,d1.w)		;IDA: Fill_bytes_loop
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop		;IDA: loop_for_count3
	rts

Opcode_CopyBackwardShort	;93: opcodes 4-7, copy (bits 0-2)+2 bytes from (bits 3-5)+1 back in the buffer
	move.b	-1(a0),d0
	andi.w	#7,d0
	addq.w	#1,d0			;count-1
	move.b	-1(a0),d2
	lsr.w	#3,d2
	andi.w	#7,d2
	addq.w	#1,d2			;distance

CopyBackwardRun	;IDA: _copybackwardloop1. 93: shared copy loop, d0 = count-1, d2 = distance back. Entered from the CopyBackward Medium/Long/Extended handlers
	neg.b	d2
	add.b	d1,d2			;source offset in the ring buffer
.loop	move.b	(a1,d2.w),(a1,d1.w)	;IDA: _copybackwardloop2
	addq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop		;IDA: _copybackwardcheckbuffer
	rts

Opcode_CopyBackwardMedium	;93: opcode 8, copy (low 4 bits)+3 bytes, distance = next data byte
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardLong	;93: opcode 9, count = 5 bits (low nibble and bit 7 of the next byte)+3, distance = (next byte bits 0-6)+1
	move.b	(a0),d0
	asl.b	#1,d0			;x = bit 7 of the next byte
	move.b	-1(a0),d0
	roxl.b	#1,d0
	andi.w	#$1F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardExtended1	;93: opcode A, count = 6 bits (low nibble and top 2 bits of the next byte)+3, distance = (next byte bits 0-5)+1
	move.b	-1(a0),d0
	asl.w	#8,d0
	move.b	(a0),d0
	lsr.w	#6,d0
	andi.w	#$3F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$3F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardExtended2	;93: opcode B, count = 7 bits (low nibble and top 3 bits of the next byte)+3, distance = (next byte bits 0-4)+1
	move.b	-1(a0),d0
	asl.w	#8,d0
	move.b	(a0),d0
	lsr.w	#5,d0
	andi.w	#$7F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$1F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardReverseShort	;93: opcodes C-D, copy (bits 0-1)+2 bytes backwards through the source, distance (bits 2-4)+1
	move.b	-1(a0),d0
	andi.w	#3,d0
	addq.w	#1,d0
	move.b	-1(a0),d2
	lsr.w	#2,d2
	andi.w	#7,d2
	addq.w	#1,d2

CopyBackwardReverseRun	;IDA: _copybackwardsreverseloop1. 93: shared reverse copy loop (source moves down), d0 = count-1, d2 = distance back. Entered from the CopyBackwardReverse Medium/Long handlers
	neg.b	d2
	add.b	d1,d2
.loop	move.b	(a1,d2.w),(a1,d1.w)	;IDA: _copybackwardsreverseloop2
	subq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop		;IDA: _chkbuf
	rts

Opcode_CopyBackwardReverseMedium	;93: opcode E, reverse copy (low 4 bits)+3 bytes, distance = next data byte. Distance 0 is the end code: flush what is left and return from DecompressBytecode
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bne.s	CopyBackwardReverseRun
	tst.w	d1			;end of data
	beq.w	.fin			;buffer empty
	bsr.w	FlushOutputBuffer
.fin	addq.w	#4,sp			;IDA: _copybackwardsreversemedium_end. drop the return into DecompressBytecode
	movem.l	(sp)+,d0-d3/a0-a2
	rts

Opcode_CopyBackwardReverseLong	;93: opcode F, reverse copy, count and distance as Opcode_CopyBackwardLong
	move.b	(a0),d0
	asl.b	#1,d0
	move.b	-1(a0),d0
	roxl.b	#1,d0
	andi.w	#$1F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardReverseRun

FlushOutputBuffer	;93: send d1 bytes (0 = 256) of the ring buffer a1 to vram d3 and advance d3. (a4) = callbackPtr: set = remap with that table (jsr (a5)), clear = DoDMApro (jsr (a6))
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	d1,d0
	bne.w	.size
	move.w	#$100,d0		;full buffer
.size	lsr.w	#1,d0			;IDA: _checksize. words
	move.w	d3,d1			;vram address
	add.w	d0,d3
	add.w	d0,d3
	movea.l	a1,a0
	tst.l	(a4)
	beq.w	.dma
	movea.l	(a4),a1			;remap table
	jsr	(a5)			;remap
	bra.w	.done
.dma	jsr	(a6)			;IDA: _nocallback. DoDMApro
.done	movem.l	(sp)+,d0-d1/a0-a1	;IDA: _done
	rts

xyVmMap	;use printx/y/m to set vram address. Returns a0 = Vdata. 93 saves d0-d2 and calls Vmaddr (92 branched to it)
	movem.l	d0-d2,-(sp)
	move.w	(printx).w,d0
	move.w	(printy).w,d1
	movea.w	#(VmMap1-M68K_RAM),a0
	adda.w	(printm).w,a0
	move.w	2(a0),d2		;map width shift
	asl.w	d2,d1
	add.w	d1,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	movem.l	(sp)+,d0-d2
	rts

eraser	;fill rectangle with char. d0/d1 = x/y size of rectangle, d2 = char word to fill with, printx/y/m define top left corner to start at
	movem.l	d0-d2/a0,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.w	d0-d1,-(sp)
.1	bsr.s	xyVmMap			;IDA: loc_DFE2
	move.w	(sp),d0
	subq.w	#1,d0
.0	move.w	d2,(a0)			;IDA: loc_DFE8
	dbf	d0,.0
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w		;31
	subq.w	#1,2(sp)
	bne.s	.1
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0
	rts

Framer	;frame and fill (uses framer.map graphics and assums tiles are already located at framercset). d0/d1 = x/y size of rectangle, printx/y/m define top left corner to start at
	movem.l	d0-d4/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.w	d0-d1,-(sp)
	move.w	(printa).w,d2
	add.w	(Framercset).w,d2
	movea.l	#Framermap,a1
	adda.l	4(a1),a1
	addq.w	#4,a1
	clr.w	d4
	bsr.w	.tbline

	subq.w	#3,2(sp)
.mtop	bsr.w	.tbline			;IDA: _mtop
	subq.w	#6,d4
	subq.w	#1,2(sp)
	bpl.s	.mtop
	addq.w	#6,d4
	bsr.w	.tbline
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d4/a0-a1
	rts

.tbline	bsr.w	xyVmMap			;IDA: Framer_tbline
	addq.w	#1,(printy).w
	bsr.w	.setter
	addq.w	#2,d4
	move.w	4(sp),d0
	subq.w	#3,d0
.tblp	bsr.w	.setter			;IDA: _tblp
	dbf	d0,.tblp
	addq.w	#2,d4
	bsr.w	.setter
	addq.w	#2,d4
	rts

.setter	move.w	(a1,d4.w),d3		;IDA: Framer_setter
	add.w	d2,d3
	move.w	d3,(a0)
	rts

printsmallz	;IDA: printz2 (Rev A lst). 93: see printsmall. String macro should follow the bsr/jsr to this routine; a1 is kept
	move.l	a1,-(sp)
	movea.l	4(sp),a1		;string after the call
	bsr.w	printsmall
	move.l	a1,4(sp)		;return past the string
	movea.l	(sp)+,a1
	rts

printsmall	;93: print string macro a1 at printx/y/m with printa. Bytes > 0 are chars ('@' = blank char $7FF, '^' = skip a column), tile = smallfontmap entry + smallfontchars[word_FFB030]. Bytes <= 0 run ControlCodeJumpTable entry -byte (0 = nothing)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2-a3,-(sp)
	movea.w	#(smallfontchars-M68K_RAM),a3	;char set bases, picked by word_FFB030
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3		;string length
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0		;IDA: loc_E0BC
	ext.w	d0
	bgt.w	.nocom
	neg.w	d0			;control code (0 = padding)
	asl.w	#2,d0
	movea.l	#ControlCodeJumpTable,a2	;(Rev A literal $E128)
	movea.l	(a2,d0.w),a2
	jsr	(a2)
	bra.w	.1

.nocom	cmp.b	#'@',d0		;IDA: loc_E0D8
	bne.w	.noblank
	move.w	#$7FF,d0		;blank char (92 moveq #1)
	bra.w	.p
.noblank	cmp.b	#'^',d0		;IDA: loc_E0E8
	beq.w	.skip
	asl.w	#1,d0
	movea.l	#smallfontmap,a2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0
	move.w	(word_FFB030).w,d1	;char set * 2
	add.w	(a3,d1.w),d0
.p	add.w	d2,d0			;IDA: loc_E108. for alternate paletes
	move.w	d0,(a0)
	addq.w	#1,(printx).w
.1	dbf	d3,.0			;IDA: loc_E110
	movem.l	(sp)+,d0-d3/a0/a2-a3
	move.w	(sp)+,(disflags).w
	rts

.skip	addq.w	#1,(printx).w		;IDA: loc_E11E. '^': skip a column
	bsr.w	xyVmMap
	bra.s	.1

ControlCodeJumpTable	;93: printsmall control codes, indexed by -byte
	dc.l	rtss				;0: padding, no-op
	dc.l	ControlCode_SetMap		;-1: map
	dc.l	ControlCode_SetAttribute	;-2: palette/priority
	dc.l	ControlCode_SetX		;-3: x
	dc.l	ControlCode_SetY		;-4: y
	dc.l	ControlCode_AddX		;-5: x offset
	dc.l	ControlCode_AddY		;-6: y offset
	dc.l	ControlCode_SetFont		;-7: char set
	dc.l	ControlCode_SetMapAndPosition	;-8: attribute, map, x, y

ControlCode_SetMapAndPosition	;93: printsmall code -8, next 4 bytes = attribute, map, x, y
	bsr.w	ControlCode_SetAttribute
	bsr.w	ControlCode_SetMap
	bsr.w	ControlCode_SetX
	bra.w	ControlCode_SetY

ControlCode_SetMap	;93: printsmall code -1, next byte = map number (1-3) -> printm
	move.b	(a1)+,d0
	subq.w	#1,d3
	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w
	bra.w	xyVmMap

ControlCode_SetAttribute	;93: printsmall code -2, next byte = palette/priority (0-7) -> printa bits 13-15 and d2
	move.b	(a1)+,d2
	andi.w	#7,d2
	subq.w	#1,d3
	ror.w	#3,d2
	move.w	d2,(printa).w
	rts

ControlCode_SetX	;93: printsmall code -3, next byte = printx
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printx).w
	bra.w	xyVmMap

ControlCode_SetY	;93: printsmall code -4, next byte = printy
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printy).w
	bra.w	xyVmMap

ControlCode_AddX	;93: printsmall code -5, add the next (signed) byte to printx
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printx).w
	bra.w	xyVmMap

ControlCode_AddY	;93: printsmall code -6, add the next (signed) byte to printy
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printy).w
	bra.w	xyVmMap

ControlCode_SetFont	;93: printsmall code -7, next byte = char set index (word_FFB030 = index*2 into smallfontchars)
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	asl.w	#1,d0
	move.w	d0,(word_FFB030).w
	rts

printz	;see print. String macro should follow the bsr/jsr to this routine. 93 keeps a1 (92 popped the return into a1)
	move.l	a1,-(sp)
	movea.l	4(sp),a1		;string after the call
	bsr.w	print
	move.l	a1,4(sp)		;return past the string
	movea.l	(sp)+,a1
	rts

print	;a1 = string macro, printx/y = x/y cordinate on map for printing, printm = map to print on, printa = attribute for characters. string \-$ab,$xx,$yy,'Sample!'\ : a = map number (1-3), b = color/priority (0-3 = color fam, prio off),(4-7 = color fam, prio on), xx/yy = x/y cord to print at. 93: '@' = char $7FF, '^' = skip a column
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0		;IDA: loc_E1F6
	beq.w	.1			;padding
	ext.w	d0
	bpl.w	.nocom
	neg.w	d0			;-$ab: new attribute, map, x, y
	move.w	d0,d2
	asl.w	#8,d2
	asl.w	#1,d2
	andi.w	#$F800,d2
	move.w	d2,(printa).w

	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w

	move.b	(a1)+,d0
	ext.w	d0
	move.w	d0,(printx).w
	move.b	(a1)+,d1
	ext.w	d1
	move.w	d1,(printy).w
	bsr.w	xyVmMap
	subq.w	#2,d3
	bra.w	.1

.nocom	cmp.b	#'@',d0		;IDA: loc_E238
	bne.w	.noblank
	move.w	#$7FF,d0		;blank char (92 moveq #1)
	bra.w	.p
.noblank	cmp.b	#'^',d0		;IDA: loc_E248 (93)
	beq.w	.skip
	asl.w	#1,d0
	movea.l	#smallfontmap,a2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0
	add.w	(smallfontchars).w,d0
.p	add.w	d2,d0			;IDA: loc_E264. for alternate paletes
	move.w	d0,(a0)
	addq.w	#1,(printx).w
.1	dbf	d3,.0			;IDA: loc_E26C
	movem.l	(sp)+,d0-d3/a0/a2
	move.w	(sp)+,(disflags).w
	rts

.skip	addq.w	#1,(printx).w		;IDA: loc_E27A. '^': skip a column
	bsr.w	xyVmMap
	bra.s	.1

FormatAndPrintTime	;93: print a period label and time. d0 bits 14-15 = period (PeriodLabelTable entry), bits 0-13 = seconds. Called from DisplayGameStatEntry and DisplayPenaltyEntry
	swap	d0
	clr.w	d0
	rol.l	#2,d0			;d0.w = period
	movea.l	#PeriodLabelTable,a1	;(Rev A literal $E2A4)
	bsr.w	PrintStringFromList
	addq.w	#2,(printx).w
	swap	d0
	lsr.w	#2,d0			;seconds
	bsr.w	PushTime
	bra.w	print

PeriodLabelTable	;93: String list for FormatAndPrintTime: " 1", " 2", " 3", "OT"
	dc.w	4
	dc.b	' 1'
	dc.w	4
	dc.b	' 2'
	dc.w	4
	dc.b	' 3'
	dc.w	4
	dc.b	'OT'

PushTime	;convert d0 into string format of minutes:seconds. Return a1 = string. 93 pads the minutes to 2 places with a space
	movea.w	#(unk_FFBED4-M68K_RAM),a1	;92 mesarea+30
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

	move.b	#' ',-(a1)		;93: leading space
	tst.w	d0
	beq.w	.noz
	addi.w	#'0',d0
	move.b	d0,(a1)			;93: over the space (92 -(a1))
.noz	move.l	(sp)+,d0		;IDA: loc_E300
	sub.l	a1,d0
	addq.w	#2,d0
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)
	addq.w	#1,d0
.1	move.w	d0,-(a1)		;IDA: loc_E312
	move.l	(sp)+,d0
	rts

PushNumber	;convert d0 into string format of base 10 number, no leading zeros. Return a1 = string
	movea.w	#(unk_FFBF22-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)
.0	ext.l	d0			;IDA: loc_E320
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0
	tst.w	d0
	bne.s	.0
	move.l	(sp)+,d0
	sub.l	a1,d0
	addq.w	#2,d0
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)
	addq.w	#1,d0
.1	move.w	d0,-(a1)		;IDA: loc_E346
	move.l	(sp)+,d0
	rts

PushNumberWidth	;IDA: pushnumber (Rev A lst DeterStrLength?). 93: convert d0 into a d1 digit base 10 string, leading zeros as spaces (the last digit always shown). Return a1 = string at unk_FFBF1A
	movem.l	d0-d3,-(sp)
	movea.w	#(unk_FFBF1C-M68K_RAM),a1
	moveq	#1,d2
	sub.w	d2,d1
	bra.w	.pw
.mul	mulu.w	#10,d2			;IDA: loc_E35C
.pw	dbf	d1,.mul			;IDA: loc_E360. d2 = 10^(d1-1)
	moveq	#' ',d3			;leading fill
.dig	ext.l	d0			;IDA: loc_E366
	divu.w	d2,d0
	bne.w	.digit
	cmp.w	#1,d2
	beq.w	.digit			;last digit: always a number
	move.w	d3,d0			;leading zero
	bra.w	.put
.digit	moveq	#'0',d3			;IDA: loc_E37C. from here on zeros are digits
	add.w	d3,d0
.put	move.b	d0,(a1)+		;IDA: loc_E380
	swap	d0
	divu.w	#10,d2
	bne.s	.dig
	move.l	a1,d0
	subi.w	#(unk_FFBF1A-M68K_RAM),d0	;length incl. the length word
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even	movea.w	#(unk_FFBF1A-M68K_RAM),a1	;IDA: loc_E39C
	move.w	d0,(a1)
	movem.l	(sp)+,d0-d3
	rts

appendz	;see appstring. String macro should follow the bsr/jsr to this routine
	movea.l	(sp)+,a1
	bsr.w	appstring
	jmp	(a1)

appstring	;append string a1 to string a3
	movem.l	d0/a0,-(sp)
	lea	2(a3),a0
	move.w	(a3),d0
	subq.w	#3,d0
	bmi.w	.1
.0	addq.w	#1,a0			;IDA: loc_E3C0
	tst.b	(a0)
	dbeq	d0,.0
.1	move.w	(a1)+,d0		;IDA: loc_E3C8
	subq.w	#3,d0
	bmi.w	.ex
.2	move.b	(a1)+,(a0)+		;IDA: loc_E3D0
	bne.w	.3
	subq.w	#1,a0
.3	dbf	d0,.2			;IDA: loc_E3D8
	move.l	a0,d0
	btst	#0,d0
	beq.w	.4
	clr.b	(a0)+
	addq.l	#1,d0
.4	sub.l	a3,d0			;IDA: loc_E3EA
	move.w	d0,(a3)
.ex	movem.l	(sp)+,d0/a0		;IDA: loc_E3EE
	rts

printbigz	;see print big. String macro should follow the bsr/jsr to this routine. 93 keeps a1 (92 popped the return into a1)
	move.l	a1,-(sp)
	movea.l	4(sp),a1		;string after the call
	bsr.w	printbig
	move.l	a1,4(sp)		;return past the string
	movea.l	(sp)+,a1
	rts

printbig	;same as print, only use bigfont.map graphics. a1 = string macro, printx/y = x/y cordinate on map for printing, printm = map to print on, printa = attribute for characters. string \-$ab,$xx,$yy,'Sample!'\ : a = map number (1-3), b = color/priority (0-3 = color fam, prio off),(4-7 = color fam, prio on), xx/yy = x/y cord to print at
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d7/a0/a2,-(sp)
	move.w	(printx).w,d4
	move.w	(printy).w,d5
	move.w	(printa).w,d6
	add.w	(BigFontChars).w,d6

	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0		;IDA: loc_E42C
	beq.w	.1
	ext.w	d0
	bpl.w	.nocom
	neg.w	d0
	move.w	d0,d6
	asl.w	#8,d6
	asl.w	#1,d6
	andi.w	#$F800,d6
	move.w	d6,(printa).w
	add.w	(BigFontChars).w,d6

	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w

	move.b	(a1)+,d4
	ext.w	d4
	move.w	d4,(printx).w
	move.b	(a1)+,d5
	ext.w	d5
	move.w	d5,(printy).w
	subq.w	#2,d3
	bra.w	.1

.nocom	cmp.b	#'a',d0		;IDA: loc_E46E
	blt.w	.2
	cmp.b	#'z',d0
	bgt.w	.2
	addi.b	#'A'-'a',d0
.2	move.w	d3,-(sp)		;IDA: loc_E482
	bsr.w	.dochar
	move.w	(sp)+,d3
.1	dbf	d3,.0			;IDA: loc_E48A
	move.w	d4,(printx).w
	move.w	d5,(printy).w
	movem.l	(sp)+,d0-d7/a0/a2
	move.w	(sp)+,(disflags).w
	rts

.dochar	subi.w	#$20,d0			;IDA: printbig_dochar. 93 has no 92 beq .space
	movea.l	#bfasciicon,a0
	moveq	#1,d2			;chars wide-1
	move.b	(a0,d0.w),d1		;brush offset
	ext.w	d1
	bpl.w	.p0
	neg.w	d1			;negative: one char wide
	clr.w	d2
.p0	asl.w	#1,d1			;IDA: loc_E4BA
	movea.l	#bigfontmap,a0
	adda.l	4(a0),a0
.p1	move.w	4(a0,d1.w),d3		;IDA: loc_E4C6
	bsr.w	.dump
	move.w	(a0),d7
	asl.w	#1,d7
	add.w	d7,d1
	move.w	4(a0,d1.w),d3
	sub.w	d7,d1
	addq.w	#1,d5
	bsr.w	.dump
	subq.w	#1,d5
	addq.w	#1,d4			;x char position
	addq.w	#2,d1
	dbf	d2,.p1
	rts

.dump	add.w	d6,d3			;IDA: printbig_dump
	movem.l	d1/a0,-(sp)
	move.w	d5,d0
	movea.l	#VmMap1,a0		;$FFFFB004
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

AddSmallFont	;transfer smallfont.map tiles to vram. d4 = char to start tiles at, return d4 = end of tiles + 1. 93 goes through DecompressGraphics
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bra.w	DoDMA_clearCallbackPointer

AddFramer	;transfer framer.map tiles to vram. d4 = char to start tiles at, return d4 = end of tiles + 1. 93 goes through DecompressGraphics
	movea.l	#FramerMap+8,a2
	move.w	d4,(Framercset).w
	bra.w	DoDMA_clearCallbackPointer

AddTeamBlock	;transfer TeamBlocks.map tiles to vram at char 2. Return d4 = end of tiles + 1. 93 goes through DecompressGraphics
	moveq	#2,d4
	movea.l	#Teamblocksmap+8,a2
	bra.w	DoDMA_clearCallbackPointer
