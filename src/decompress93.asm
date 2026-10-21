;	Tile decompressor, new in 93 (92 sent tiles straight to vram with DoDMA).
;	DecompressGraphics sends a graphic's tiles to vram. If the tile count has bit 15 set the tiles are packed:
;	DecompressBytecode unpacks them and FlushOutputBuffer sends each full 256 byte buffer to vram.
;
;	The packing is a byte oriented LZ77 style opcode stream: literal runs, zero and byte fills, and copies
;	from the last 256 bytes, forward or reverse. Called from dobitmap and the tile loaders.
;
;	Build note: EA's compiler emits cmp #imm,Dn as CMP (Bxxx) but SNASM emits CMPI (0Cxx). The source has the
;	real cmp / exg; fixopcodes.js patches the encoding after assembly.

DecompressGraphicsWithCallback		;DecompressGraphics through remap. The 8 bytes after the bsr are the remap
									;color table (callbackPtr = their address); returns past them. a2 = tile
									;data, d4 = start char
	move.l	(sp),(callbackPtr).w	;remap table after the call
	bsr.w	DecompressGraphics		;decompress it
	addq.l	#8,(sp)					;skip the inline remap table
	rts								;return

DecompressGraphicsPlain				;clear callbackPtr (plain DMA, no remap) and fall into DecompressGraphics.
									;a2 = tile data, d4 = start char
	clr.l	(callbackPtr).w			;no remap

DecompressGraphics					;send tiles to vram. a2 = data: word count of tiles (0 = none, bit 15 set
									;= compressed by DecompressBytecode), then the tiles. d4 = start char,
									;returns d4 = end char + 1. Uses remap with callbackPtr when it is set,
									;else DoDMApro
	movem.l	d0-d1/a0-a6,-(sp)		;save
	movea.l	a2,a0					;a0 = compressed data
	move.w	d4,d1					;start char
	asl.w	#5,d1					;d1 = vram address of start char
	move.w	(a0)+,d0				;tile count
	beq.w	.done					;no tiles
	bmi.w	.packed					;bit 15: compressed
	add.w	d0,d4					;next start char
	asl.w	#4,d0					;words to transfer
	pea	(.done).l					;return to .done
	tst.l	(callbackPtr).w			;remap table?
	beq.w	DoDMApro				;no: DMA it
	movea.l	(callbackPtr).w,a1		;remap table
	bra.w	remap					;remap it

.packed	andi.w	#$7FFF,d0			;tile count
	add.w	d0,d4					;next start char
	bsr.w	DecompressBytecode		;decompress it
.done	movem.l	(sp)+,d0-d1/a0-a6	;also the return target of the plain/remap paths (pea above)
	rts								;return

DecompressBytecode					;unpack a0 into the 256 byte ring buffer at DispAttribCtr and flush each
									;full buffer to vram d3 (FlushOutputBuffer). The high nibble of each
									;opcode byte picks a handler from jump_table. Ends on a
									;CopyBackwardReverseMedium code with distance 0. d1 = vram address
	movea.w	#(DispAttribCtr-M68K_RAM),a1	;output buffer
	movea.w	#(DispAttribCtr-M68K_RAM),a3
	movea.w	#(callbackPtr-M68K_RAM),a4	;remap table pointer
	movea.l	#remap,a5				;remap routine
	movea.l	#DoDMApro,a6			;DMA routine
	movem.l	d0-d3/a0-a2,-(sp)		;save
	move.w	d1,d3					;d3 = vram address
	clr.w	d1						;d1 = output buffer offset
	clr.w	d2
.loop	move.b	(a0)+,d0			;read opcode
	andi.w	#$F0,d0					;upper nibble
	lsr.w	#3,d0					;upper nibble * 2
	lea	jump_table(pc),a2			;opcode handlers
	move.w	(a2,d0.w),d0			;handler offset
	jsr	(a2,d0.w)					;handler, reads its count from -1(a0)
	bra.s	.loop					;next opcode

jump_table							;DecompressBytecode handler offsets, one per opcode high nibble
	dc.w	Opcode_CopyLiteral-jump_table	;0
	dc.w	Opcode_CopyLiteral-jump_table	;1
	dc.w	Opcode_ClearBytes-jump_table	;2
	dc.w	Opcode_Fillbytes-jump_table	;3
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

Opcode_CopyLiteral					;opcodes 0-1, copy (low 5 bits)+1 bytes from the data
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#$1F,d0					;count-1
.loop	move.b	(a0)+,(a1,d1.w)		;literal byte into the ring buffer
	addq.b	#1,d1					;d1 is a byte index: wraps to 0 after 256 bytes
	bne.w	.next
	bsr.w	FlushOutputBuffer		;buffer full
.next	dbf	d0,.loop				;next literal byte
	rts								;return

Opcode_ClearBytes					;opcode 2, write (low 4 bits)+1 zero bytes
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#$F,d0					;count-1
.loop	clr.b	(a1,d1.w)			;zero byte into the ring buffer
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer		;buffer full
.next	dbf	d0,.loop				;next zero byte
	rts								;return

Opcode_Fillbytes					;opcode 3, write the next data byte (low 4 bits)+3 times
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#$F,d0
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;fill byte
.loop	move.b	d2,(a1,d1.w)		;fill byte (d2) into the ring buffer
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer		;buffer full
.next	dbf	d0,.loop				;next fill byte
	rts								;return

Opcode_CopyBackwardShort			;opcodes 4-7, copy (bits 0-2)+2 bytes from (bits 3-5)+1 back in the buffer
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#7,d0					;count
	addq.w	#1,d0					;count-1
	move.b	-1(a0),d2				;step back to the opcode byte just read
	lsr.w	#3,d2
	andi.w	#7,d2					;distance
	addq.w	#1,d2					;distance

CopyBackwardRun						;shared copy loop, d0 = count-1, d2 = distance back. Entered from the
									;CopyBackward Medium/Long/Extended handlers
	neg.b	d2
	add.b	d1,d2					;source offset in the ring buffer
.loop	move.b	(a1,d2.w),(a1,d1.w)	;copy one byte from the earlier output (source walks up)
	addq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer		;buffer full
.next	dbf	d0,.loop				;next byte of the run
	rts								;return

Opcode_CopyBackwardMedium			;opcode 8, copy (low 4 bits)+3 bytes, distance = next data byte
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#$F,d0
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;distance
	bra.s	CopyBackwardRun			;copy it

Opcode_CopyBackwardLong				;opcode 9, count = 5 bits (low nibble and bit 7 of the next byte)+3,
									;distance = (next byte bits 0-6)+1
	move.b	(a0),d0					;next byte bit 7
	asl.b	#1,d0					;x = bit 7 of the next byte
	move.b	-1(a0),d0				;step back to the opcode byte just read
	roxl.b	#1,d0					;into the count
	andi.w	#$1F,d0
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;distance byte
	andi.w	#$7F,d2
	addq.w	#1,d2					;distance+1
	bra.s	CopyBackwardRun			;copy it

Opcode_CopyBackwardExtended1		;opcode A, count = 6 bits (low nibble and top 2 bits of the next byte)+3,
									;distance = (next byte bits 0-5)+1
	move.b	-1(a0),d0				;step back to the opcode byte just read
	asl.w	#8,d0
	move.b	(a0),d0					;plus the next byte
	lsr.w	#6,d0
	andi.w	#$3F,d0					;count
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;distance byte
	andi.w	#$3F,d2
	addq.w	#1,d2					;distance+1
	bra.s	CopyBackwardRun			;copy it

Opcode_CopyBackwardExtended2		;opcode B, count = 7 bits (low nibble and top 3 bits of the next byte)+3,
									;distance = (next byte bits 0-4)+1
	move.b	-1(a0),d0				;step back to the opcode byte just read
	asl.w	#8,d0
	move.b	(a0),d0					;plus the next byte
	lsr.w	#5,d0
	andi.w	#$7F,d0					;count
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;distance byte
	andi.w	#$1F,d2
	addq.w	#1,d2					;distance+1
	bra.s	CopyBackwardRun			;copy it

Opcode_CopyBackwardReverseShort		;opcodes C-D, copy (bits 0-1)+2 bytes backwards through the source,
									;distance (bits 2-4)+1
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#3,d0
	addq.w	#1,d0					;count+1
	move.b	-1(a0),d2				;step back to the opcode byte just read
	lsr.w	#2,d2
	andi.w	#7,d2
	addq.w	#1,d2					;distance+1

CopyBackwardReverseRun				;shared reverse copy loop (source moves down), d0 = count-1, d2 = distance
									;back. Entered from the CopyBackwardReverse Medium/Long handlers
	neg.b	d2
	add.b	d1,d2					;source position
.loop	move.b	(a1,d2.w),(a1,d1.w)	;copy one byte from the earlier output (source walks down)
	subq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer		;buffer full
.next	dbf	d0,.loop				;next byte of the run
	rts								;return

Opcode_CopyBackwardReverseMedium	;opcode E, reverse copy (low 4 bits)+3 bytes, distance = next data byte.
									;Distance 0 is the end code: flush what is left and return from
									;DecompressBytecode
	move.b	-1(a0),d0				;step back to the opcode byte just read
	andi.w	#$F,d0
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;distance
	bne.s	CopyBackwardReverseRun	;nonzero: copy
	tst.w	d1						;end of data
	beq.w	.fin					;buffer empty
	bsr.w	FlushOutputBuffer		;send the rest
.fin	addq.w	#4,sp				;drop the return into DecompressBytecode
	movem.l	(sp)+,d0-d3/a0-a2		;restore
	rts								;return

Opcode_CopyBackwardReverseLong		;opcode F, reverse copy, count and distance as Opcode_CopyBackwardLong
	move.b	(a0),d0					;next byte bit 7
	asl.b	#1,d0
	move.b	-1(a0),d0				;step back to the opcode byte just read
	roxl.b	#1,d0					;into the count
	andi.w	#$1F,d0
	addq.w	#2,d0					;count+2
	move.b	(a0)+,d2				;distance byte
	andi.w	#$7F,d2
	addq.w	#1,d2					;distance+1
	bra.s	CopyBackwardReverseRun	;copy it

FlushOutputBuffer					;send d1 bytes (0 = 256) of the ring buffer a1 to vram d3 and advance d3.
									;(a4) = callbackPtr: set = remap with that table (jsr (a5)), clear =
									;DoDMApro (jsr (a6))
	movem.l	d0-d1/a0-a1,-(sp)		;save
	move.w	d1,d0					;bytes in the buffer
	bne.w	.size
	move.w	#$100,d0				;full buffer
.size	lsr.w	#1,d0				;bytes to words
	move.w	d3,d1					;vram address
	add.w	d0,d3
	add.w	d0,d3					;next vram address
	movea.l	a1,a0					;source
	tst.l	(a4)					;remap table?
	beq.w	.dma					;no
	movea.l	(a4),a1					;remap table
	jsr	(a5)						;remap
	bra.w	.done
.dma	jsr	(a6)					;DoDMApro: d0 words from a0 to vram d1
.done	movem.l	(sp)+,d0-d1/a0-a1	;d3 stays advanced for the next flush
	rts								;return
