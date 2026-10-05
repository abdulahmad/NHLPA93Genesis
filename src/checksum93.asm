;	92 checksum.asm (included from 92 hockey.asm under IF CHECKSUM=1). Retail $7FB76-$7FBC7; the $FF fill
;	to $7FFFF follows. Retail has a different sum constant and loop count from Rev A, and a word Rev A lacks.

SecurityCheck	;92 name, no IDA label. Retail only: the $FFFF word before ValidationRoutine (Rev A has no word here). Data, not code
	dc.w	$FFFF

ValidationRoutine	;IDA and 92 name. Called once at power on from Start (main93 jsr, IDA Reset+100). Adds every ROM long from 0 up to
	;this routine, skipping the header long at $18C. Returns if the sum is right, else turns the screen red and hangs. Uses d0-d1/a0/a4
	moveq	#0,d0			;sum
	suba.l	a0,a0			;a0 = ROM address 0
	move.l	#ValidationRoutine/4,d1	;number of longs below this routine (Rev A $1FEE9)
.loop	cmpa.w	#$18C,a0		;IDA: loc_7FBAE (92 ValidationLoop). header long $18C-$18F holds the checksum word $18E
	bne.s	.add
	addq.w	#4,a0			;skip it, not summed
	bra.s	.next
.add	add.l	(a0)+,d0		;IDA: loc_7FBB8 (92 SkipIncrement)
.next	subq.l	#1,d1			;IDA: loc_7FBBA (92 ContinueValidation)
	bgt.s	.loop
	cmpi.l	#$EB689746,d0		;retail sum (Rev A: $C62A6024). Real CMPI (0C80), not EA cmp
	bne.s	.bad			;wrong sum: red screen
	rts
.bad	movea.l	#VDP_CTRL,a4		;IDA: loc_7FBC8 (92 VDPErrorSetup)
	move.w	#$8F02,(a4)		;auto increment 2
	move.w	#$8004,(a4)		;mode 1: h interrupt off
	move.w	#$8700,(a4)		;backdrop = colour 0
	move.w	#$8144,(a4)		;mode 2: display on, v interrupt off, dma off
	move.w	#$C000,(a4)		;cram write, colour 0 (first command word only)
	move.w	#$3F,d1			;64 colours
.fill	move.w	#$E,(VDP_DATA).l	;IDA: loc_7FBE6 (92 VRAMWriteLoop). colour = $00E, full red
	dbf	d1,.fill
.halt	bra.s	.halt			;IDA: loc_7FBF2 (92 Halt). hang