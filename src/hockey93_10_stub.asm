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

; External routines and data outside $1499E-$15109, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
GetPeriodTime = $6556		; hockey93_01 (jsr abs.w)
ReadAttributeNibble = $8A56	; stats93 (jsr abs.l)
lcfound2 = $9860		; logic93_1 (jsr abs.l)
randomd0 = $D7A6		; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
dobitmap = $DCE4		; middle93_2
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
appendz = $E390			; middle93_2
appstring = $E398		; middle93_2
printbigz = $E3DC		; middle93_2
printbig = $E3EE		; middle93_2
rtss = $110E0			; hockey93_05
WritePassBits = $147B8		; hockey93_09 (Rev A $147D0)
GetShifter = $148B0		; hockey93_09 (Rev A $148C8)
IceRinkMap = $33864		; graphics data (movea.l operand)
; .region code
	org	$1499E

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_10.asm
