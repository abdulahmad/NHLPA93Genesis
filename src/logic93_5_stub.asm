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

; External routines and data outside $C9EA-$D629, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
Sweepcheck = $9C70		; logic93_1
randomd0 = $D7A6		; middle93_1
AddPenalty = $E526		; penalty93_1
rtss = $110E0			; hockey93_05
getpde = $1132E			; hockey93_05
setpde = $1134E			; hockey93_05 (Rev A sub_11366)
HotList = $743CE		; graphics data (Rev A $743FC)

; .region code
	org	$C9EA

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	logic93_5.asm
