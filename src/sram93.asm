;	NHLPA Hockey 93 (retail) segment $15FE6-$165D7
;	93 only, no NHL 92 source: the serial backup RAM (cartridge EEPROM) driver, the save/load of the
;	128-byte databuffer (BackupRAM_Read, BitsToPW, BackupRAM_Load), the ClearRAMBuffer status screen
;	and BackupRAM_DetectDevice. p_turnoff (sound driver) starts at $165D8.
;	Global names from the IDA export (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin. IDA's Read/Write names are kept as they are; the headers say what each one does.
;	The device is a word port at $200000. Low byte bit 7 is the data line (SDA, read back in bit 7)
;	and bit 6 the clock (SCL): $C0 = both high, $80 = data high clock low, $40 = data low clock high.
;	The control byte sent after a start is address<<1 + 1 to read (sequential read from that address)
;	or address<<1 to write one byte. Addresses are 0-127.
;	RAM from $CB00 up (and databuffer) is 4 bytes lower in retail than in ram_addrs.inc (Rev A): every
;	backup RAM variable is written as the retail number with the Rev A name in the comment.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	Saved block (databuffer, 128 bytes): bytes 0-125 data, byte 126 = not(sum of 0-125), byte 127 = sum.

BackupRAM_WriteControl	;start condition: data falls while the clock is high, then clock low. Called before every control byte
	nop
	nop
	nop
	nop
	nop
	move.w	#$C0,($200000).l	;data high, clock high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$40,($200000).l	;data low, clock high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#0,($200000).l		;clock low
	nop
	rts

BackupRAM_ControlSequenceData	;stop condition: data rises while the clock is high, then clock low with data released.
	;IDA decoded the first instruction as dc.b + ori.b (its BackupRAM_InitSequence label is inside it). Code, not data
	move.w	#0,($200000).l		;data low, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$40,($200000).l	;clock high
	nop
	nop
	nop
	nop
	nop
	move.w	#$C0,($200000).l	;data high while clock high
	nop
	nop
	nop
	nop
	nop
	move.w	#$80,($200000).l	;clock low, data released
	nop
	rts

BackupRAM_WriteBit	;send d0 bit 15 on the data line and pulse the clock. d0 is shifted left one bit, d1 = port image
	lsl.w	#1,d0
	roxr.b	#1,d1			;bit into d1 bit 7 (data line)
	bclr	#6,d1			;clock low
	move.w	d1,($200000).l
	nop
	nop
	nop
	nop
	bset	#6,d1			;clock high
	move.w	d1,($200000).l
	nop
	nop
	nop
	nop
	bclr	#6,d1			;clock low
	move.w	d1,($200000).l
	rts

BackupRAM_ReadBit	;release the data line, pulse the clock and shift the data bit into d0 bit 0. d1 = port read
	move.w	#$80,($200000).l	;data released, clock low
	nop
	nop
	nop
	nop
	move.w	#$C0,($200000).l	;clock high
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	($200000).l,d1
	move.w	#$80,($200000).l	;clock low
	asl.b	#1,d1			;data bit 7 into x
	roxl.w	#1,d0
	rts

BackupRAM_EndRead	;acknowledge a received byte (data low for one clock) so the sequential read goes on. Called by BackupRAM_WriteBlock
	move.w	#0,($200000).l		;data low, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$40,($200000).l	;clock high with data low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#0,($200000).l		;clock low
	nop
	rts

BackupRAM_EndWrite	;no acknowledge after the last received byte (data high for one clock). Called by BackupRAM_WriteBlock before the stop
	move.w	#$80,($200000).l	;data high, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$C0,($200000).l	;clock high with data high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$80,($200000).l	;clock low
	nop
	rts

BackupRAM_ReadAck	;clock in the device acknowledge after a sent byte. Return d1 bit 7 clear = acknowledged, set = no answer
	move.w	#$80,($200000).l	;data released, clock low
	nop
	move.w	#$C0,($200000).l	;clock high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	($200000).l,d1
	move.w	#$80,($200000).l	;clock low
	nop
	rts

InitBackupRAM	;retry limit 10, clear the error count, then falls into BackupRAM_WaitReady. Called from BackupRAM_Read
	move.w	#$A,($FFFFCDF2).w	;retail retrycount (Rev A: $CDF6)
	move.w	#0,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8)

BackupRAM_WaitReady	;wait $1965 nops, then 9 x (clock high/low with data released + start), then a stop. Bus reset before a retry
	move.w	#$1964,d0
.delay	nop				;IDA: loc_161A2
	dbf	d0,.delay
	move.w	#8,d0			;9 times
.clk	move.w	#$80,($200000).l	;IDA: loc_161AC. data released, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	bsr.w	BackupRAM_WriteControl	;clock high, start, clock low
	dbf	d0,.clk
	bsr.w	BackupRAM_ControlSequenceData	;stop
	rts

BackupRAM_WriteBlock	;IDA name; reads: d1 bytes from backup RAM address d0 into a0 (sequential read).
	;Retries from a bus reset while the device does not acknowledge, up to retrycount. Return a0, d0, d1 as passed,
	;errorflag = retries used, or -1 when it failed. Called from BackupRAM_Read, BackupRAM_ReadBlock and BackupRAM_Load
	move.w	#0,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8)
	move.w	d1,($FFFFCE02).w	;retail bytecount (Rev A: $CE06)
	move.l	a0,($FFFFCDF6).w	;retail sramdataptr (Rev A: $CDFA)
	move.l	d0,($FFFFCDFA).w	;retail address (Rev A: $CDFE)
	move.l	d1,($FFFFCDFE).w	;retail byecount (Rev A: $CE02)
	bra.w	.start
.retry	bsr.s	BackupRAM_WaitReady	;IDA: loc_161E8
.start	movea.l	($FFFFCDF6).w,a0	;IDA: loc_161EA. retail sramdataptr (Rev A: $CDFA)
	move.l	($FFFFCDFA).w,d0	;retail address (Rev A: $CDFE)
	bsr.w	BackupRAM_WriteControl	;start
	andi.w	#$7F,d0
	lsl.w	#1,d0
	ori.w	#1,d0			;address<<1 + 1 = read
	lsl.w	#8,d0			;control byte to bits 15-8
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_ReadAck
	tst.b	d1
	bpl.w	.byte			;acknowledged
	addq.w	#1,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8). count the retry
	bmi.w	.fail
	move.w	($FFFFCDF4).w,d1	;retail errorflag (Rev A: $CDF8)
	cmp.w	($FFFFCDF2).w,d1	;retail retrycount (Rev A: $CDF6)
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.s	.retry
.byte	bsr.w	BackupRAM_ReadBit	;IDA: loc_16246. 8 bits into d0.b
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	move.b	d0,(a0)+
	subq.w	#1,($FFFFCE02).w	;retail bytecount (Rev A: $CE06)
	beq.w	.last
	bsr.w	BackupRAM_EndRead	;acknowledge, read the next byte
	bra.s	.byte
.last	bsr.w	BackupRAM_EndWrite	;IDA: loc_16276. no acknowledge after the last byte
	bsr.w	BackupRAM_ControlSequenceData	;stop
.ex	movea.l	($FFFFCDF6).w,a0	;IDA: loc_1627E. retail sramdataptr (Rev A: $CDFA)
	move.l	($FFFFCDFA).w,d0	;retail address (Rev A: $CDFE)
	move.l	($FFFFCDFE).w,d1	;retail byecount (Rev A: $CE02)
	rts
.fail	move.w	#$FFFF,($FFFFCDF4).w	;IDA: loc_1628C. retail errorflag (Rev A: $CDF8) = -1, failed
	bra.s	.ex

BackupRAM_ReadBlock	;IDA name; writes: byte (a0) to backup RAM address d0, waits, reads it back with BackupRAM_WriteBlock.
	;Retries as BackupRAM_WriteBlock does. Return a0, d0, d1 as passed, errorflag -1 when it failed.
	;Called from BackupRAM_Read and BitsToPW, once per byte
	move.w	#0,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8)
	move.l	a0,($FFFFCE06).w	;retail bufferptr (Rev A: $CE0A)
	move.l	d0,($FFFFCE0A).w	;retail address2 (Rev A: $CE0E)
	move.l	d1,-(sp)
	bra.w	.start
.retry	bsr.w	BackupRAM_WaitReady	;IDA: loc_162A8
.start	movea.l	($FFFFCE06).w,a0	;IDA: loc_162AC. retail bufferptr (Rev A: $CE0A)
	move.l	($FFFFCE0A).w,d0	;retail address2 (Rev A: $CE0E)
	bsr.w	BackupRAM_WriteControl	;start
	andi.w	#$7F,d0
	lsl.w	#1,d0			;address<<1 + 0 = write
	lsl.w	#8,d0			;control byte to bits 15-8
	move.w	d0,($FFFFCE04).w	;retail command (Rev A: $CE08)
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_ReadAck
	tst.b	d1
	bpl.w	.data			;acknowledged
	addq.w	#1,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8). count the retry
	bmi.w	.fail
	move.w	($FFFFCDF4).w,d1	;retail errorflag (Rev A: $CDF8)
	cmp.w	($FFFFCDF2).w,d1	;retail retrycount (Rev A: $CDF6)
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.s	.retry
.data	move.b	(a0),d0			;IDA: loc_16308. data byte to bits 15-8
	lsl.w	#8,d0
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_WriteBit
	bsr.w	BackupRAM_ReadAck
	tst.b	d1
	bpl.w	.stop			;acknowledged
	addq.w	#1,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8). count the retry
	bmi.w	.fail
	move.w	($FFFFCDF4).w,d1	;retail errorflag (Rev A: $CDF8)
	cmp.w	($FFFFCDF2).w,d1	;retail retrycount (Rev A: $CDF6)
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.w	.retry
.stop	bsr.w	BackupRAM_ControlSequenceData	;IDA: loc_16352. stop starts the device write
	move.w	#$1518,d0		;wait $1519 nops for the write
.delay	nop				;IDA: loc_1635A
	dbf	d0,.delay
	clr.l	d0
	move.b	($FFFFCE04).w,d0	;retail command (Rev A: $CE08). control byte
	lsr.l	#1,d0			;address (overwritten below)
	moveq	#1,d1			;read 1 byte back
	move.l	($FFFFCE0A).w,d0	;retail address2 (Rev A: $CE0E)
	lea	($FFFFCE05).w,a0	;retail command+1 (Rev A: $CE09)
	bsr.w	BackupRAM_WriteBlock
	tst.w	($FFFFCDF4).w		;retail errorflag (Rev A: $CDF8)
	bmi.w	.fail			;read back failed
	movea.l	($FFFFCE06).w,a0	;retail bufferptr (Rev A: $CE0A)
	move.b	($FFFFCE05).w,d0	;retail command+1 (Rev A: $CE09). byte read back
	cmp.b	(a0),d0
	bpl.w	.ex			;read back minus written byte not negative: accept
	addq.w	#1,($FFFFCDF4).w	;retail errorflag (Rev A: $CDF8). count the retry
	bmi.w	.fail
	move.w	($FFFFCDF4).w,d1	;retail errorflag (Rev A: $CDF8)
	cmp.w	($FFFFCDF2).w,d1	;retail retrycount (Rev A: $CDF6)
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.w	.retry
.ex	movea.l	($FFFFCE06).w,a0	;IDA: loc_163A8. retail bufferptr (Rev A: $CE0A)
	move.l	($FFFFCE0A).w,d0	;retail address2 (Rev A: $CE0E)
	move.l	(sp)+,d1
	rts
.fail	move.w	#$FFFF,($FFFFCDF4).w	;IDA: loc_163B4. retail errorflag (Rev A: $CDF8) = -1, failed
	bra.s	.ex

BackupRAM_Read	;load the saved block into databuffer at power on. Called once from Begin (hockey93_01).
	;Bad checksum: the block is cleared and rewritten. Pad 1 held: Start+A+C ($E0) clears it first; Start+C+B ($B0) or
	;Start+A+C show the ClearRAMBuffer screen at the end (green = good, red = failed). Return a0 = databuffer, d0-d1 kept,
	;errorflag2 = 0 loaded, 1 cleared, -1 failed
	movem.l	d0-d1,-(sp)
	clr.w	($FFFFCE0E).w		;retail errorflag2 (Rev A: $CE12)
	bsr.w	InitBackupRAM
	bsr.w	BackupRAM_DetectDevice
	cmp.b	#$E0,d0
	beq.w	.erase			;Start+A+C held: clear the saved block
	moveq	#0,d0			;from address 0
	move.l	#$80,d1			;128 bytes
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
	bsr.w	BackupRAM_WriteBlock
	tst.w	($FFFFCDF4).w		;retail errorflag (Rev A: $CDF8)
	bmi.w	.error
	move.w	#$7D,d1			;sum bytes 0-125
	clr.w	d0
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
.sum	add.b	(a0)+,d0		;IDA: loc_163F6
	dbf	d1,.sum
	clr.w	d1			;d1 = failed checks
	cmp.b	1(a0),d0
	beq.w	.c1			;byte 127 = sum
	addq.w	#1,d1
.c1	not.w	d0			;IDA: loc_16408
	cmp.b	(a0),d0
	beq.w	.c2			;byte 126 = not sum
	addq.w	#1,d1
.c2	swap	d0			;IDA: loc_16412
	move.b	(a0),d0
	not.b	d0
	cmp.b	1(a0),d0
	beq.w	.c3			;byte 127 = not byte 126
	addq.w	#1,d1
.c3	swap	d0			;IDA: loc_16422
	tst.w	d1
	beq.w	.ok
	bsr.w	BackupRAM_DetectDevice
	cmp.b	#$B0,d0
	beq.w	.error			;Start+C+B held: report the bad block, do not clear it
.erase	move.w	#1,($FFFFCE0E).w	;IDA: loc_16436. retail errorflag2 (Rev A: $CE12) = 1, cleared
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
	move.w	#$7F,d0
	clr.l	d1
.clr	move.b	d1,(a0)+		;IDA: loc_16446
	dbf	d0,.clr
	move.b	#$FF,($FFFFCB6C).w	;retail marker (Rev A: $CB70) = databuffer+126: not(sum) of the cleared block
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
	move.w	#0,d0
.wr	bsr.w	BackupRAM_ReadBlock	;IDA: loc_1645A. write byte d0
	tst.w	($FFFFCDF4).w		;retail errorflag (Rev A: $CDF8)
	bmi.w	.error
	addq.l	#1,a0
	addq.w	#1,d0
	andi.w	#$7F,d0
	bne.s	.wr			;until all 128 written
	bra.w	.ok
.error	move.w	#$FFFF,($FFFFCE0E).w	;IDA: loc_16474. retail errorflag2 (Rev A: $CE12) = -1, failed
	bsr.w	BackupRAM_DetectDevice
	cmp.b	#$B0,d0
	beq.w	.red
	cmp.b	#$E0,d0
	bne.w	.ex			;no test buttons held: return
.red	move.w	#$F,d0			;IDA: loc_1648E. red backdrop
	jmp	(ClearRAMBuffer).l
	bra.w	.ex			;not reached (IDA dc.b $60,0,0,$20)
.ok	bsr.w	BackupRAM_DetectDevice	;IDA: loc_1649C
	cmp.b	#$B0,d0
	beq.w	.green
	cmp.b	#$E0,d0
	bne.w	.ex			;no test buttons held: return
.green	move.w	#$F0,d0			;IDA: loc_164B0. green backdrop
	jmp	(ClearRAMBuffer).l
.ex	lea	($FFFFCAEE).w,a0	;IDA: loc_164BA. retail databuffer (Rev A: $CAF2)
	movem.l	(sp)+,d0-d1
	rts

BitsToPW	;IDA name. 92 BitstoPW made the password text from passbits; 93 saves databuffer to backup RAM instead.
	;Sets byte 127 = sum of bytes 0-125 and byte 126 = not sum, then writes the 128 bytes one at a time.
	;Called from EncodePW (hockey93_09) and EncodePlayerAttributes (stats93). d0-d1/a0 kept, errorflag2 = -1 when it failed
	movem.l	d0-d1/a0,-(sp)
	clr.w	($FFFFCE0E).w		;retail errorflag2 (Rev A: $CE12)
	move.w	#$7D,d1			;sum bytes 0-125
	clr.w	d0
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
.sum	add.b	(a0)+,d0		;IDA: loc_164D6
	dbf	d1,.sum
	move.b	d0,1(a0)		;byte 127 = sum
	not.w	d0
	move.b	d0,(a0)			;byte 126 = not sum
	move.w	#$7F,d1			;128 bytes
	moveq	#0,d0			;from address 0
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
.wr	bsr.w	BackupRAM_ReadBlock	;IDA: loc_164EE. write byte d0
	move.w	($FFFFCDF4).w,($FFFFCE0E).w	;retail errorflag to errorflag2 (Rev A: $CDF8, $CE12)
	bmi.w	.ex			;failed
	addq.l	#1,d0
	addq.l	#1,a0
	dbf	d1,.wr
.ex	movem.l	(sp)+,d0-d1/a0		;IDA: loc_16504
	rts

BackupRAM_Load	;read the 128-byte block into databuffer and check bytes 126-127 (not sum, sum of bytes 0-125).
	;Unlabeled in IDA, no caller found. d0-d1/a0 kept, errorflag2 = -1 on a read error or a bad checksum
	movem.l	d0-d1/a0,-(sp)
	clr.w	($FFFFCE0E).w		;retail errorflag2 (Rev A: $CE12)
	moveq	#0,d0			;from address 0
	move.l	#$80,d1			;128 bytes
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
	bsr.w	BackupRAM_WriteBlock
	move.w	($FFFFCDF4).w,($FFFFCE0E).w	;retail errorflag to errorflag2 (Rev A: $CDF8, $CE12)
	bmi.w	.ex			;read failed
	move.w	#$7D,d1			;sum bytes 0-125
	clr.w	d0
	lea	($FFFFCAEE).w,a0	;retail databuffer (Rev A: $CAF2)
.sum	add.b	(a0)+,d0		;IDA: loc_16536
	dbf	d1,.sum
	cmp.b	1(a0),d0
	bne.w	.bad			;byte 127 is not the sum
	not.w	d0
	cmp.b	(a0),d0
	beq.w	.ex			;byte 126 = not sum: good
.bad	move.w	#$FFFF,($FFFFCE0E).w	;IDA: loc_1654C. retail errorflag2 (Rev A: $CE12) = -1
.ex	movem.l	(sp)+,d0-d1/a0		;IDA: loc_16552
	rts

ClearRAMBuffer	;IDA name; backup RAM status screen. Interrupts off, display off, backdrop colour 0 = d0,
	;clears $4000 bytes of VRAM, display on, then loops forever. Jumped to from BackupRAM_Read (d0 = $F red, $F0 green)
	move.w	#$2700,sr		;interrupts off
	movea.l	#VDP_CTRL,a0
	move.w	#$8004,(a0)
	move.w	#$8104,(a0)		;display off
	move.w	#$8200,(a0)
	move.w	#$8300,(a0)
	move.w	#$8400,(a0)
	move.w	#$8500,(a0)
	move.w	#$8600,(a0)
	move.w	#$8700,(a0)		;backdrop = colour 0
	move.w	#$8800,(a0)
	move.w	#$8900,(a0)
	move.w	#$8AFF,(a0)
	move.w	#$8B00,(a0)
	move.w	#$8C00,(a0)
	move.w	#$8D00,(a0)
	move.w	#$8E00,(a0)
	move.w	#$8F02,(a0)		;auto increment 2
	move.w	#$9000,(a0)
	move.w	#$9100,(a0)
	move.w	#$9200,(a0)
	move.l	#$C0000000,(VDP_CTRL).l	;cram write, colour 0
	move.w	d0,(VDP_DATA).l
	move.l	#$40000000,(VDP_CTRL).l	;vram write, address 0
	move.w	#$FFF,d1		;$1000 longs
	moveq	#0,d0
ClearVRAM	;IDA name; clear loop of ClearRAMBuffer, then display on and hang
	move.l	d0,(VDP_DATA).l
	dbf	d1,ClearVRAM
	move.w	#$8144,(a0)		;display on
.hang	bra.s	.hang			;IDA: loc_165DC

BackupRAM_DetectDevice	;IDA name; reads pad 1 (Readjoy1). Return d0 = held buttons (bit 7 Start, 6 A, 5 C, 4 B). Called from BackupRAM_Read
	movem.l	d1-d7,-(sp)
	jsr	(Readjoy1).l
	move.w	d3,d0
	movem.l	(sp)+,d1-d7
	rts
