;	Segment build for checksum93.asm: defines the outside routines and data it uses as equates,
;	then includes checksum93.asm on its own for checking against the ROM.

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

; External addresses outside: none. Every branch in the segment is a bra.s / Bcc.s / dbf
; to a label inside it (checked against the retail displacements), and the only absolute addresses are
; the VDP ports.
; .region code
	org	$7FB76

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	checksum93.asm
