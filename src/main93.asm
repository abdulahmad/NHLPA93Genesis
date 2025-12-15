	include	macros\genesis.mac

;	68000
;	ABSOLUTE
;	A4OFF
;	llchar	'.'	; Change the local label character to '.'.
;	mlchar	'@'	; Change the macro label character to '@'.

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Imports and exports
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
RAMStart = $FF0000	
	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Equates
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

Stack = $FFFFF6	

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Vectors
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;;	.region code
	org	0
	dc.l	Stack		; 0 initial stack pointer
	dc.l	Start		; 4 initial program counter
	dc.l	BusError
	dc.l	AddError
	dc.l	Illinst
	dc.l	Zerodiv

	org     $18
	dcb.b   72,$00      ; $5E - $18 = 70 bytes
	
	org	$60
	dc.l	Spurious	; level 0-3 interrupts are not implemented.
	dc.l	Spurious	; level 0-3 interrupts are not implemented.
	dc.l	Spurious	; level 0-3 interrupts are not implemented.
	dc.l	Spurious	; level 0-3 interrupts are not implemented.
	dc.l	HBlank		; level 4: horizontal retrace.
	dc.l	0			; level 5: not used.
	dc.l	VBjsr		; level 6: vertical retrace.
	dc.l	Spurious	;

	org     $90
	dcb.b   112,$00      ; $5E - $18 = 70 bytes

ErrorStatus
	dc.l	0,0,0,0

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Start
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	org	$100

	include	sega\SegaIDTable.asm
Start
	Include	sega\SegaInit.asm
	; IF CHECKSUM=1
		jsr ValidationRoutine
		jsr KillCrowd
; 	ELSE
	;	nop
	;	nop
	;	nop
;	ENDIF
	
; 	incbin ..\output\modified_EALogo.bin

	bra	Begin

	IF REV=0 ; RETAIL
		HBlank:	
			rte
		Spurious:
			rte
	ELSE ; REV A
		HBlank:
		Spurious:	
			rte
	ENDIF
