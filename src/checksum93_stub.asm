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

; External addresses outside $7FB76-$7FBC7: none. Every branch in the segment is a bra.s / Bcc.s / dbf
; to a label inside it (checked against the retail displacements), and the only absolute addresses are
; the VDP ports from ram93.asm.
; .region code
	org	$7FB76

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	checksum93.asm
