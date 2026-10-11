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

; Add stubs here as the segment is decompiled.
SPAList = $4D8E
doinput = $946E
setpads = $A048
vtoa = $D05C
forceblack = $D67C
sfx = $D852
Readjoy1 = $D9B6
Readjoy2 = $D9D4
DoFill = $DB98
dobitmap = $DCE4
printz = $E1AE
ClrHor = $EEFE
SetHor = $EF3C
loadTeamStruct = $F2DA
checkcoll = $FAE2
rtss = $110E0
setvideo = $118F2
SprSort = $127F8
asstab = $1518A
IceRinkMap = $33864		; graphics

; .region code
	org	$8AC4

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	hockey93_02.Asm
