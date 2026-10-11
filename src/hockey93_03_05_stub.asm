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
GetPeriodTime = $6556		; (jsr abs.w)
GetPlayerCount = $8A8E		; (jsr abs.l)
freezewindow = $933C
setc1player = $9C7E
setc2player = $9C9C
chkpk2 = $B94C
a2touchpuck = $CB34
puckflip = $CCB8
assinsert = $D03E
assreplace = $D048
vtoa = $D05C
GetHot = $D0C6
SetSPA = $D120
randomd0s = $D79A
randomd0 = $D7A6
sroot = $D7DE
sfx = $D852
song = $D876
AddPenalty = $E526
AddPenalty2 = $E552
Stop4Pen = $E8CE
PenGoalStuff = $EC26
printscores1 = $EFA8
ChkShotStat = $F28A
sublist = $154CC		; (movea.l operand)
priolist = $15536		; (movea.l operand)
play_new_song = $16674		; sound driver
RAMStart = $FF0000	

; .region code
	org	$FAE2

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	hockey93_03_05.asm
