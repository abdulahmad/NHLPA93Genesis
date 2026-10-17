;	Tile decompressor. NHLPA 93 added it; 92 sent the tiles straight to vram with DoDMA. A graphic whose tile count
;	has bit 15 set is packed: DecompressGraphics sends the tiles to vram (a plain graphic through the callbackPtr remap
;	if one is set), DecompressBytecode unpacks the packed ones, and FlushOutputBuffer sends each full 256 byte
;	buffer to vram. The packing is a byte oriented LZ77 style opcode stream: literal runs, zero and byte fills, and
;	copies from the last 256 bytes, forward or reverse. Called from dobitmap and the tile loaders.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / exg;
;	fixopcodes.js patches the encoding after assembly.

DecompressGraphicsWithCallback	;DecompressGraphics through remap. The 8 bytes after the bsr are the remap color table (callbackPtr = their address); returns past them. a2 = tile data, d4 = start char
	move.l	(sp),(callbackPtr).w
	bsr.w	DecompressGraphics
	addq.l	#8,(sp)			;skip the inline remap table
	rts

DecompressGraphicsPlain	;clear callbackPtr (plain DMA, no remap) and fall into DecompressGraphics. a2 = tile data, d4 = start char
	clr.l	(callbackPtr).w

DecompressGraphics	;send tiles to vram. a2 = data: word count of tiles (0 = none, bit 15 set = compressed by DecompressBytecode), then the tiles. d4 = start char, returns d4 = end char + 1. Uses remap with callbackPtr when it is set, else DoDMApro
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

.packed	andi.w	#$7FFF,d0		;tile count
	add.w	d0,d4
	bsr.w	DecompressBytecode
.done	movem.l	(sp)+,d0-d1/a0-a6
	rts

DecompressBytecode	;unpack a0 into the 256 byte ring buffer at DispAttribCtr and flush each full buffer to vram d3 (FlushOutputBuffer). The high nibble of each opcode byte picks a handler from jump_table. Ends on a CopyBackwardReverseMedium code with distance 0. d1 = vram address
	movea.w	#(DispAttribCtr-M68K_RAM),a1	;output buffer
	movea.w	#(DispAttribCtr-M68K_RAM),a3
	movea.w	#(callbackPtr-M68K_RAM),a4
	movea.l	#remap,a5
	movea.l	#DoDMApro,a6
	movem.l	d0-d3/a0-a2,-(sp)
	move.w	d1,d3			;d3 = vram address
	clr.w	d1			;d1 = output buffer offset
	clr.w	d2
.loop	move.b	(a0)+,d0		;read opcode
	andi.w	#$F0,d0
	lsr.w	#3,d0			;upper nibble * 2
	lea	jump_table(pc),a2
	move.w	(a2,d0.w),d0
	jsr	(a2,d0.w)		;handler, reads its count from -1(a0)
	bra.s	.loop

jump_table	;DecompressBytecode handler offsets, one per opcode high nibble
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

Opcode_CopyLiteral	;opcodes 0-1, copy (low 5 bits)+1 bytes from the data
	move.b	-1(a0),d0
	andi.w	#$1F,d0
.loop	move.b	(a0)+,(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer	;buffer full
.next	dbf	d0,.loop
	rts

Opcode_ClearBytes	;opcode 2, write (low 4 bits)+1 zero bytes
	move.b	-1(a0),d0
	andi.w	#$F,d0
.loop	clr.b	(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_Fillbytes	;opcode 3, write the next data byte (low 4 bits)+3 times
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
.loop	move.b	d2,(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_CopyBackwardShort	;opcodes 4-7, copy (bits 0-2)+2 bytes from (bits 3-5)+1 back in the buffer
	move.b	-1(a0),d0
	andi.w	#7,d0
	addq.w	#1,d0			;count-1
	move.b	-1(a0),d2
	lsr.w	#3,d2
	andi.w	#7,d2
	addq.w	#1,d2			;distance

CopyBackwardRun	;shared copy loop, d0 = count-1, d2 = distance back. Entered from the CopyBackward Medium/Long/Extended handlers
	neg.b	d2
	add.b	d1,d2			;source offset in the ring buffer
.loop	move.b	(a1,d2.w),(a1,d1.w)
	addq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_CopyBackwardMedium	;opcode 8, copy (low 4 bits)+3 bytes, distance = next data byte
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardLong	;opcode 9, count = 5 bits (low nibble and bit 7 of the next byte)+3, distance = (next byte bits 0-6)+1
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

Opcode_CopyBackwardExtended1	;opcode A, count = 6 bits (low nibble and top 2 bits of the next byte)+3, distance = (next byte bits 0-5)+1
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

Opcode_CopyBackwardExtended2	;opcode B, count = 7 bits (low nibble and top 3 bits of the next byte)+3, distance = (next byte bits 0-4)+1
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

Opcode_CopyBackwardReverseShort	;opcodes C-D, copy (bits 0-1)+2 bytes backwards through the source, distance (bits 2-4)+1
	move.b	-1(a0),d0
	andi.w	#3,d0
	addq.w	#1,d0
	move.b	-1(a0),d2
	lsr.w	#2,d2
	andi.w	#7,d2
	addq.w	#1,d2

CopyBackwardReverseRun	;shared reverse copy loop (source moves down), d0 = count-1, d2 = distance back. Entered from the CopyBackwardReverse Medium/Long handlers
	neg.b	d2
	add.b	d1,d2
.loop	move.b	(a1,d2.w),(a1,d1.w)
	subq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_CopyBackwardReverseMedium	;opcode E, reverse copy (low 4 bits)+3 bytes, distance = next data byte. Distance 0 is the end code: flush what is left and return from DecompressBytecode
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bne.s	CopyBackwardReverseRun
	tst.w	d1			;end of data
	beq.w	.fin			;buffer empty
	bsr.w	FlushOutputBuffer
.fin	addq.w	#4,sp			;drop the return into DecompressBytecode
	movem.l	(sp)+,d0-d3/a0-a2
	rts

Opcode_CopyBackwardReverseLong	;opcode F, reverse copy, count and distance as Opcode_CopyBackwardLong
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

FlushOutputBuffer	;send d1 bytes (0 = 256) of the ring buffer a1 to vram d3 and advance d3. (a4) = callbackPtr: set = remap with that table (jsr (a5)), clear = DoDMApro (jsr (a6))
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	d1,d0
	bne.w	.size
	move.w	#$100,d0		;full buffer
.size	lsr.w	#1,d0			;words
	move.w	d3,d1			;vram address
	add.w	d0,d3
	add.w	d0,d3
	movea.l	a1,a0
	tst.l	(a4)
	beq.w	.dma
	movea.l	(a4),a1			;remap table
	jsr	(a5)			;remap
	bra.w	.done
.dma	jsr	(a6)			;DoDMApro
.done	movem.l	(sp)+,d0-d1/a0-a1
	rts
