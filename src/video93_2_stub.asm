	include	macros\genesis93.mac

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

; External routines and data outside $11D0A-$122A7, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
jdtab = $DA70			; middle93_1 (movea.l operand, Rev A $DA88)
rtss = $110E0			; hockey93_05
sizetab = $154BC		; hockey93_11 (movea.l operand, Rev A $154D4)
smallfontmap = $795B4		; graphics data (movea.l operand, Rev A unk_795E2)
SpritesMap = $3A378		; graphics data (movea.l operand, Rev A $3A3A6)
Spritetiles = $3A382		; graphics data (addi.l operand, Rev A $3A3B0)
; .region code
	org	$11D0A

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	video93_2.asm
