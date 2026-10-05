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

; External routines outside $FAE2-$10387, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra displacement.
vtoa = $D05C			; logic93_5
GetHot = $D0C6			; logic93_5
SetSPA = $D120			; logic93_5
randomd0 = $D7A6		; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
AddPenalty = $E526		; penalty93_1
AddPenalty2 = $E552		; penalty93_1
Stop4Pen = $E8CE		; penalty93_1 (Rev A sub_E8E6)
checkfight = $10388		; hockey93_04
checkwallcoll = $10608		; hockey93_04 (Rev A $10620)
rtss = $110E0			; hockey93_05

; .region code
	org	$FAE2

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"

; Main segment code
	include	hockey93_03.asm
