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

; External routines outside $10388-$10E65, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra displacement.
freezewindow = $933C		; hockey93_02
puckflip = $CCB8		; logic93_5 (Rev A sub_CCD0)
assinsert = $D03E		; logic93_5
assreplace = $D048		; logic93_5
GetHot = $D0C6			; logic93_5
SetSPA = $D120			; logic93_5
randomd0s = $D79A		; middle93_1 (Rev A sub_D7B2)
randomd0 = $D7A6		; middle93_1
sroot = $D7DE			; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
AddPenalty2 = $E552		; penalty93_1
PenGoalStuff = $EC26		; penalty93_1
printscores1 = $EFA8		; penalty93_2
ChkShotStat = $F28A		; penalty93_2
puckstick = $10E66		; hockey93_05
setd0player = $11010		; hockey93_05
puckbody = $11050		; hockey93_05
rtss = $110E0			; hockey93_05
puckgoalie = $110E2		; hockey93_05
play_new_song = $16674		; sound driver (sound93.asm)

; .region code
	org	$10388

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"

; Main segment code
	include	hockey93_04.asm
