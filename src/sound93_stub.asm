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

; External addresses outside $165D8-$2EFA1, at their retail addresses (the sound data tables are labels in sound93.asm).
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/Bcc displacement, lea (pc) displacement or movea.l operand.
rtss = $110E0			; hockey93_05 (bgt.w at $1660C)
; .region code
	org	$165D8

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	sound93.asm
