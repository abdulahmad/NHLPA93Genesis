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

; External addresses outside $165D8-$16E52, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/Bcc displacement, lea (pc) displacement or movea.l operand.
rtss = $110E0			; hockey93_05 (bgt.w at $1660C)
unk_1710C = $170DE		; Z80 blob / sound data, not covered (lea (pc) at $1692A, Rev A $1710C)
unk_28338 = $2830A		; sound data, not covered (movea.l at $169B8, Rev A $28338)
MusicTrackPointerTable = $2870A	; sound data, not covered (movea.l at $1663E, Rev A $28738)
; .region code
	org	$165D8

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	sound93.asm
