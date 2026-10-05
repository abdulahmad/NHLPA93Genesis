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

; External routines and data outside $8AC4-$946D, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Add stubs here as the segment is decompiled.
SPAList = $4D8E			; Frames93
doinput = $946E			; logic93_1
setpads = $A048			; logic93_1 (Rev A sub_A060)
vtoa = $D05C			; logic93_5
forceblack = $D67C		; middle93_1
sfx = $D852			; middle93_1
Readjoy1 = $D9B6		; middle93_1
Readjoy2 = $D9D4		; middle93_1
DoFill = $DB98			; middle93_1 (Rev A sub_DBB0)
dobitmap = $DCE4		; middle93_2
printz = $E1AE			; middle93_2
ClrHor = $EEFE			; penalty93_1 (Rev A sub_EF16)
SetHor = $EF3C			; penalty93_1
loadTeamStruct = $F2DA		; penalty93_2
checkcoll = $FAE2		; hockey93_03
rtss = $110E0			; hockey93_05
setvideo = $118F2		; video93_1 (Rev A sub_1190A)
SprSort = $127F8		; hockey93_06
asstab = $1518A			; hockey93_11
IceRinkMap = $33864		; graphics

; .region code
	org	$8AC4

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_02.Asm
