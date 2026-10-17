;	Battery backup. This file drives the save chip on the cartridge, saves and loads the game's
;	save block with a checksum, shows the screen for clearing saved data and reads the first pad.

;	The device is a word port (BackupRAM_Port). Low byte bit 7 is the data line (SDA, read
;	back in bit 7) and bit 6 the clock (SCL): $C0 = both high, $80 = data high clock low,
;	$40 = data low clock high. The control byte sent after a start is address<<1 + 1 to read
;	(sequential read from that address) or address<<1 to write one byte. Addresses are 0-127.
;	Saved block (databuffer, 128 bytes): bytes 0-125 data, byte 126 = not(sum of 0-125),
;	byte 127 = sum.

BackupRAM_Start	;start condition: data falls while the clock is high, then clock low. Called before every control byte
	nop
	nop
	nop
	nop
	nop
	move.w	#$C0,(BackupRAM_Port).l	;data high, clock high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$40,(BackupRAM_Port).l	;data low, clock high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#0,(BackupRAM_Port).l		;clock low
	nop
	rts

BackupRAM_Stop	;stop condition: data rises while the clock is high, then clock low with data released.
	;the first instruction as dc.b + ori.b (its BackupRAM_InitSequence label is inside it). Code, not data
	move.w	#0,(BackupRAM_Port).l		;data low, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$40,(BackupRAM_Port).l	;clock high
	nop
	nop
	nop
	nop
	nop
	move.w	#$C0,(BackupRAM_Port).l	;data high while clock high
	nop
	nop
	nop
	nop
	nop
	move.w	#$80,(BackupRAM_Port).l	;clock low, data released
	nop
	rts

BackupRAM_WriteBit	;send d0 bit 15 on the data line and pulse the clock. d0 is shifted left one bit, d1 = port image
	lsl.w	#1,d0
	roxr.b	#1,d1			;bit into d1 bit 7 (data line)
	bclr	#6,d1			;clock low
	move.w	d1,(BackupRAM_Port).l
	nop
	nop
	nop
	nop
	bset	#6,d1			;clock high
	move.w	d1,(BackupRAM_Port).l
	nop
	nop
	nop
	nop
	bclr	#6,d1			;clock low
	move.w	d1,(BackupRAM_Port).l
	rts

BackupRAM_ReadBit	;release the data line, pulse the clock and shift the data bit into d0 bit 0. d1 = port read
	move.w	#$80,(BackupRAM_Port).l	;data released, clock low
	nop
	nop
	nop
	nop
	move.w	#$C0,(BackupRAM_Port).l	;clock high
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	(BackupRAM_Port).l,d1
	move.w	#$80,(BackupRAM_Port).l	;clock low
	asl.b	#1,d1			;data bit 7 into x
	roxl.w	#1,d0
	rts

BackupRAM_SendAck	;acknowledge a received byte (data low for one clock) so the sequential read goes on. Called by BackupRAM_ReadBlock
	move.w	#0,(BackupRAM_Port).l		;data low, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$40,(BackupRAM_Port).l	;clock high with data low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#0,(BackupRAM_Port).l		;clock low
	nop
	rts

BackupRAM_SendNoAck	;no acknowledge after the last received byte (data high for one clock). Called by BackupRAM_ReadBlock before the stop
	move.w	#$80,(BackupRAM_Port).l	;data high, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$C0,(BackupRAM_Port).l	;clock high with data high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	#$80,(BackupRAM_Port).l	;clock low
	nop
	rts

BackupRAM_ReadAck	;clock in the device acknowledge after a sent byte. Return d1 bit 7 clear = acknowledged, set = no answer
	move.w	#$80,(BackupRAM_Port).l	;data released, clock low
	nop
	move.w	#$C0,(BackupRAM_Port).l	;clock high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	move.w	(BackupRAM_Port).l,d1
	move.w	#$80,(BackupRAM_Port).l	;clock low
	nop
	rts

InitBackupRAM	;retry limit 10, clear the error count, then falls into BackupRAM_WaitReady. Called from BackupRAM_Read
	move.w	#$A,(retrycount).w
	move.w	#0,(errorflag).w

BackupRAM_WaitReady	;wait $1965 nops, then 9 x (clock high/low with data released + start), then a stop. Bus reset before a retry
	move.w	#$1964,d0
.delay	nop
	dbf	d0,.delay
	move.w	#8,d0			;9 times
.clk	move.w	#$80,(BackupRAM_Port).l	;data released, clock low
	nop
	nop
	nop
	nop
	nop
	nop
	bsr.w	BackupRAM_Start	;clock high, start, clock low
	dbf	d0,.clk
	bsr.w	BackupRAM_Stop	;stop
	rts

BackupRAM_ReadBlock	;reads: d1 bytes from backup RAM address d0 into a0 (sequential read).
	;Retries from a bus reset while the device does not acknowledge, up to retrycount. Return a0, d0, d1 as passed,
	;errorflag = retries used, or -1 when it failed. Called from BackupRAM_Read, BackupRAM_WriteBlock and BackupRAM_Load
	move.w	#0,(errorflag).w
	move.w	d1,(bytecount).w
	move.l	a0,(sramdataptr).w
	move.l	d0,(address).w
	move.l	d1,(byecount).w
	bra.w	.start
.retry	bsr.s	BackupRAM_WaitReady
.start	movea.l	(sramdataptr).w,a0
	move.l	(address).w,d0
	bsr.w	BackupRAM_Start	;start
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
	addq.w	#1,(errorflag).w	;count the retry
	bmi.w	.fail
	move.w	(errorflag).w,d1
	cmp.w	(retrycount).w,d1
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.s	.retry
.byte	bsr.w	BackupRAM_ReadBit	;8 bits into d0.b
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	bsr.w	BackupRAM_ReadBit
	move.b	d0,(a0)+
	subq.w	#1,(bytecount).w
	beq.w	.last
	bsr.w	BackupRAM_SendAck	;acknowledge, read the next byte
	bra.s	.byte
.last	bsr.w	BackupRAM_SendNoAck	;no acknowledge after the last byte
	bsr.w	BackupRAM_Stop	;stop
.ex	movea.l	(sramdataptr).w,a0
	move.l	(address).w,d0
	move.l	(byecount).w,d1
	rts
.fail	move.w	#$FFFF,(errorflag).w	;= -1, failed
	bra.s	.ex

BackupRAM_WriteBlock	;writes: byte (a0) to backup RAM address d0, waits, reads it back with BackupRAM_ReadBlock.
	;Retries as BackupRAM_ReadBlock does. Return a0, d0, d1 as passed, errorflag -1 when it failed.
	;Called from BackupRAM_Read and BackupRAM_Save, once per byte
	move.w	#0,(errorflag).w
	move.l	a0,(bufferptr).w
	move.l	d0,(address2).w
	move.l	d1,-(sp)
	bra.w	.start
.retry	bsr.w	BackupRAM_WaitReady
.start	movea.l	(bufferptr).w,a0
	move.l	(address2).w,d0
	bsr.w	BackupRAM_Start	;start
	andi.w	#$7F,d0
	lsl.w	#1,d0			;address<<1 + 0 = write
	lsl.w	#8,d0			;control byte to bits 15-8
	move.w	d0,(command).w
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
	addq.w	#1,(errorflag).w	;count the retry
	bmi.w	.fail
	move.w	(errorflag).w,d1
	cmp.w	(retrycount).w,d1
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.s	.retry
.data	move.b	(a0),d0			;data byte to bits 15-8
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
	addq.w	#1,(errorflag).w	;count the retry
	bmi.w	.fail
	move.w	(errorflag).w,d1
	cmp.w	(retrycount).w,d1
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.w	.retry
.stop	bsr.w	BackupRAM_Stop	;stop starts the device write
	move.w	#$1518,d0		;wait $1519 nops for the write
.delay	nop
	dbf	d0,.delay
	clr.l	d0
	move.b	(command).w,d0	;control byte
	lsr.l	#1,d0			;address (overwritten below)
	moveq	#1,d1			;read 1 byte back
	move.l	(address2).w,d0
	lea	(command+1).w,a0
	bsr.w	BackupRAM_ReadBlock
	tst.w	(errorflag).w
	bmi.w	.fail			;read back failed
	movea.l	(bufferptr).w,a0
	move.b	(command+1).w,d0	;byte read back
	cmp.b	(a0),d0
	bpl.w	.ex			;read back minus written byte not negative: accept
	addq.w	#1,(errorflag).w	;count the retry
	bmi.w	.fail
	move.w	(errorflag).w,d1
	cmp.w	(retrycount).w,d1
	bpl.w	.fail			;retries used up
	bsr.w	BackupRAM_WaitReady
	bra.w	.retry
.ex	movea.l	(bufferptr).w,a0
	move.l	(address2).w,d0
	move.l	(sp)+,d1
	rts
.fail	move.w	#$FFFF,(errorflag).w	;= -1, failed
	bra.s	.ex

BackupRAM_Read	;load the saved block into databuffer at power on. Called once from Begin.
	;Bad checksum: the block is cleared and rewritten. Pad 1 held: Start+A+C ($E0) clears it first; Start+C+B ($B0) or
	;Start+A+C show the ClearRAMBuffer screen at the end (green = good, red = failed). Return a0 = databuffer, d0-d1 kept,
	;errorflag2 = 0 loaded, 1 cleared, -1 failed
	movem.l	d0-d1,-(sp)
	clr.w	(errorflag2).w
	bsr.w	InitBackupRAM
	bsr.w	ReadPad1Held
	cmp.b	#$E0,d0
	beq.w	.erase			;Start+A+C held: clear the saved block
	moveq	#0,d0			;from address 0
	move.l	#$80,d1			;128 bytes
	lea	(databuffer).w,a0
	bsr.w	BackupRAM_ReadBlock
	tst.w	(errorflag).w
	bmi.w	.error
	move.w	#$7D,d1			;sum bytes 0-125
	clr.w	d0
	lea	(databuffer).w,a0
.sum	add.b	(a0)+,d0
	dbf	d1,.sum
	clr.w	d1			;d1 = failed checks
	cmp.b	1(a0),d0
	beq.w	.c1			;byte 127 = sum
	addq.w	#1,d1
.c1	not.w	d0
	cmp.b	(a0),d0
	beq.w	.c2			;byte 126 = not sum
	addq.w	#1,d1
.c2	swap	d0
	move.b	(a0),d0
	not.b	d0
	cmp.b	1(a0),d0
	beq.w	.c3			;byte 127 = not byte 126
	addq.w	#1,d1
.c3	swap	d0
	tst.w	d1
	beq.w	.ok
	bsr.w	ReadPad1Held
	cmp.b	#$B0,d0
	beq.w	.error			;Start+C+B held: report the bad block, do not clear it
.erase	move.w	#1,(errorflag2).w	;= 1, cleared
	lea	(databuffer).w,a0
	move.w	#$7F,d0
	clr.l	d1
.clr	move.b	d1,(a0)+
	dbf	d0,.clr
	move.b	#$FF,(marker).w	;= databuffer+126: not(sum) of the cleared block
	lea	(databuffer).w,a0
	move.w	#0,d0
.wr	bsr.w	BackupRAM_WriteBlock	;write byte d0
	tst.w	(errorflag).w
	bmi.w	.error
	addq.l	#1,a0
	addq.w	#1,d0
	andi.w	#$7F,d0
	bne.s	.wr			;until all 128 written
	bra.w	.ok
.error	move.w	#$FFFF,(errorflag2).w	;= -1, failed
	bsr.w	ReadPad1Held
	cmp.b	#$B0,d0
	beq.w	.red
	cmp.b	#$E0,d0
	bne.w	.ex			;no test buttons held: return
.red	move.w	#$F,d0			;red backdrop
	jmp	(ClearRAMBuffer).l
	bra.w	.ex			;not reached ($60,0,0,$20)
.ok	bsr.w	ReadPad1Held
	cmp.b	#$B0,d0
	beq.w	.green
	cmp.b	#$E0,d0
	bne.w	.ex			;no test buttons held: return
.green	move.w	#$F0,d0			;green backdrop
	jmp	(ClearRAMBuffer).l
.ex	lea	(databuffer).w,a0
	movem.l	(sp)+,d0-d1
	rts

BackupRAM_Save	;save databuffer to backup RAM (92 made the password text from passbits here).
	;Sets byte 127 = sum of bytes 0-125 and byte 126 = not sum, then writes the 128 bytes one at a time.
	;Called from EncodePW and EncodeTeamLines. d0-d1/a0 kept, errorflag2 = -1 when it failed
	movem.l	d0-d1/a0,-(sp)
	clr.w	(errorflag2).w
	move.w	#$7D,d1			;sum bytes 0-125
	clr.w	d0
	lea	(databuffer).w,a0
.sum	add.b	(a0)+,d0
	dbf	d1,.sum
	move.b	d0,1(a0)		;byte 127 = sum
	not.w	d0
	move.b	d0,(a0)			;byte 126 = not sum
	move.w	#$7F,d1			;128 bytes
	moveq	#0,d0			;from address 0
	lea	(databuffer).w,a0
.wr	bsr.w	BackupRAM_WriteBlock	;write byte d0
	move.w	(errorflag).w,(errorflag2).w
	bmi.w	.ex			;failed
	addq.l	#1,d0
	addq.l	#1,a0
	dbf	d1,.wr
.ex	movem.l	(sp)+,d0-d1/a0
	rts

BackupRAM_Load	;read the 128-byte block into databuffer and check bytes 126-127 (not sum, sum of bytes 0-125).
	;Unlabeled in, no caller found. d0-d1/a0 kept, errorflag2 = -1 on a read error or a bad checksum
	movem.l	d0-d1/a0,-(sp)
	clr.w	(errorflag2).w
	moveq	#0,d0			;from address 0
	move.l	#$80,d1			;128 bytes
	lea	(databuffer).w,a0
	bsr.w	BackupRAM_ReadBlock
	move.w	(errorflag).w,(errorflag2).w
	bmi.w	.ex			;read failed
	move.w	#$7D,d1			;sum bytes 0-125
	clr.w	d0
	lea	(databuffer).w,a0
.sum	add.b	(a0)+,d0
	dbf	d1,.sum
	cmp.b	1(a0),d0
	bne.w	.bad			;byte 127 is not the sum
	not.w	d0
	cmp.b	(a0),d0
	beq.w	.ex			;byte 126 = not sum: good
.bad	move.w	#$FFFF,(errorflag2).w	;= -1
.ex	movem.l	(sp)+,d0-d1/a0
	rts

ClearRAMBuffer	;backup RAM status screen. Interrupts off, display off, backdrop colour 0 = d0
	;clears $4000 bytes of VRAM, display on, then loops forever. Jumped to from BackupRAM_Read (d0 = $F red, $F0 green)
	move.w	#$2700,sr		;interrupts off
	movea.l	#Vctrl,a0
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
	move.l	#$C0000000,(Vctrl).l	;cram write, colour 0
	move.w	d0,(Vdata).l
	move.l	#$40000000,(Vctrl).l	;vram write, address 0
	move.w	#$FFF,d1		;$1000 longs
	moveq	#0,d0
ClearVRAM	;clear loop of ClearRAMBuffer, then display on and hang
	move.l	d0,(Vdata).l
	dbf	d1,ClearVRAM
	move.w	#$8144,(a0)		;display on
.hang	bra.s	.hang

ReadPad1Held	;reads pad 1 (Readjoy1). Return d0 = held buttons (bit 7 Start, 6 A, 5 C, 4 B). Called from BackupRAM_Read
	movem.l	d1-d7,-(sp)
	jsr	(Readjoy1).l
	move.w	d3,d0
	movem.l	(sp)+,d1-d7
	rts
