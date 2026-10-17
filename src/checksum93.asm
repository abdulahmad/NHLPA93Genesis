;	ROM security check. When the checksum is enabled, ValidationRoutine adds up the ROM and stops the
;	game if the sum is wrong. The fill that pads the ROM out to its full size follows it.

	IF REV=0
SecurityCheck	;Retail only: the $FFFF word before ValidationRoutine (Rev A has no word here). Data, not code
	dc.w	$FFFF
	ENDIF

ValidationRoutine	;Called once at power on from Start (jsr). Adds every ROM long from 0 up to
	;this routine, skipping the header long at $18C. Returns if the sum is right, else turns the screen red and hangs. Uses d0-d1/a0/a4
	;d0 = running sum, a0 = read pointer, d1 = longs left
	moveq	#0,d0					;sum
	suba.l	a0,a0					;a0 = ROM address 0
	move.l	#ValidationRoutine/4,d1	;number of longs below this routine
ValidationLoop	cmpa.w	#$18C,a0	;header long $18C-$18F holds the checksum word $18E
	bne.s	SkipIncrement
	addq.w	#4,a0					;skip it, not summed
	bra.s	ContinueValidation
SkipIncrement	add.l	(a0)+,d0	;sum += next ROM long (a0 advances)
ContinueValidation	subq.l	#1,d1	;loop back until d1 longs have been counted
	bgt.s	ValidationLoop
	;compare the finished sum with the expected value for this ROM revision
	IF REV=1
	cmpi.l	#$C62A6024,d0			;Rev A sum. Real CMPI (0C80), not EA cmp
	ELSE
	cmpi.l	#$EB689746,d0			;retail sum. Real CMPI (0C80), not EA cmp
	ENDIF
	bne.s	VDPErrorSetup			;wrong sum: red screen
	rts
VDPErrorSetup	movea.l	#Vctrl,a4	;a4 = VDP control port; set up a plain red screen
	;blank the VDP and flood all of colour RAM with red
	move.w	#$8F02,(a4)				;auto increment 2
	move.w	#$8004,(a4)				;mode 1: h interrupt off
	move.w	#$8700,(a4)				;backdrop = colour 0
	move.w	#$8144,(a4)				;mode 2: display on, v interrupt off, dma off
	move.w	#$C000,(a4)				;cram write, colour 0 (first command word only)
	move.w	#$3F,d1					;64 colours
VRAMWriteLoop	move.w	#$E,(Vdata).l	;colour = $00E, full red
	dbf	d1,VRAMWriteLoop
Halt	bra.s	Halt				;hang