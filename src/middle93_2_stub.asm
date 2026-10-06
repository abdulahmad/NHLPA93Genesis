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

; External routines and data outside $DCE4-$E525, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
remap = $D62A			; middle93_1 (Rev A ConvertAndWriteToVDP, loc_D642)
DoDMApro = $DA80		; middle93_1 (Rev A loc_DA98)
Vmaddr = $DCCA			; middle93_1 (Rev A sub_DCE2)
PrintStringFromList = $F744	; penalty93_2 (Rev A sub_F75C)
rtss = $110E0			; hockey93_05
bfasciicon = $1542A		; hockey93_11 (Rev A unk_15442)
Framermap = $33388		; graphics data, no segment (Rev A unk_333B6)
bigfontmap = $78CFE		; graphics data, no segment (Rev A unk_78D2C)
smallfontmap = $795B4		; graphics data, no segment (Rev A unk_795E2)
Teamblocksmap = $7A376	; graphics data, no segment (Rev A unk_7A3AC)

; .region code
	org	$DCE4

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	middle93_2.asm
