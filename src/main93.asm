;	EA startup code: the 68000 vector table, the Sega ID header, the EA logo and the reset entry point.
;
;	In order from ROM address 0: the 93 macros (genesis93.mac), the vector table ($0-$FF), ErrorStatus, the
;	Sega ID header (sega\SegaIDTable93.asm at $100), then Start. Start runs the console init (SegaInit.asm)
;	and the optional ROM checksum, silences the crowd (KillCrowd) and branches to Begin (hockey93.asm).

	include	macros\genesis93.mac

;	68000
;	ABSOLUTE
;	A4OFF
;
;	llchar	'.'	; Change the local label character to '.'.
;	mlchar	'@'	; Change the macro label character to '@'.

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Imports and exports
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
RAMStart = $FF0000					;start of work RAM
	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Equates
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

Stack = $FFFFF6						;reset vector 0. ($FFFFFFF6, the 32-bit form). ram93.asm redefines Stack as
									;the game stack

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Vectors
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;;	.region code
	org	0
	dc.l	Stack					; 0 initial stack pointer
	dc.l	Start					; 4 initial program counter: reset enters Start
	dc.l	AddError				; 8 bus error: bus and address error share AddError
	dc.l	AddError
	dc.l	Illinst					; $10 illegal instruction
	dc.l	Zerodiv					; $14 divide by zero

	;$18-$5F: remaining exception vectors, left zero
	org     $18
	dcb.b   72,$00					; $5E - $18 = 70 bytes
	
	org	$60
	dc.l	IRQ7					; level 0-3 interrupts are not implemented.
	dc.l	IRQ7					; level 0-3 interrupts are not implemented.
	dc.l	IRQ7					; level 0-3 interrupts are not implemented.
	dc.l	IRQ7					; level 0-3 interrupts are not implemented.
	dc.l	IRQ7					; level 4: horizontal retrace (not used: IRQ7 is an rte).
	dc.l	0						; level 5: not used.
	dc.l	VBjsr					; level 6: vertical retrace. VBjsr is in hockey93.asm
	dc.l	IRQ7					; level 7 (IRQ7, an rte)

	;$90-$FF: remaining vectors (trap 0-15, ...), left zero
	org     $90
	dcb.b   112,$00					; $5E - $18 = 70 bytes

ErrorStatus							;4 longs of zero (16 bytes, ends at $110); nothing in the source
									;references it
	dc.l	0,0,0,0

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Start
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	;Sega ID header and the entry point follow at $100
	org	$100

	include	sega\SegaIDTable93.asm
Start								;reset entry point (vector 1)
	Include	sega\SegaInit.asm		;console init: Z80, VDP, PSG and RAM set up
	IF CHECKSUM=1
		jsr ValidationRoutine		;ROM checksum, hangs on a red screen if wrong
    ELSE
		nop							;checksum disabled: three nops keep the code size the same
		nop
		nop 
	ENDIF

	jsr KillCrowd					;silence the crowd noise before the game starts
	
; 	incbin ..\output\modified_EALogo.bin

	bra	Begin						;cold start in hockey93.asm: clear RAM, init menus and sound, title screen