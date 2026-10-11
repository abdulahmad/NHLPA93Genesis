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
GetPeriodTime = $6556		; hockey93_01 (jsr abs.w)
GetPlayerCount = $8A8E		; stats93 (jsr abs.l)
freezewindow = $933C		; hockey93_02
setc1player = $9C7E		; logic93
setc2player = $9C9C		; logic93
chkpk2 = $B94C			; logic93
a2touchpuck = $CB34		; logic93
puckflip = $CCB8		; logic93
assinsert = $D03E		; logic93
assreplace = $D048		; logic93
vtoa = $D05C			; logic93
GetHot = $D0C6			; logic93
SetSPA = $D120			; logic93
randomd0s = $D79A		; middle93
randomd0 = $D7A6		; middle93
sroot = $D7DE			; middle93
sfx = $D852			; middle93
song = $D876			; middle93 (Rev A SFX)
AddPenalty = $E526		; penalty93
AddPenalty2 = $E552		; penalty93
Stop4Pen = $E8CE		; penalty93
PenGoalStuff = $EC26		; penalty93
printscores1 = $EFA8		; penalty93
ChkShotStat = $F28A		; penalty93
sublist = $154CC		; hockey93_06_11 (Rev A $154E4, movea.l operand)
priolist = $15536		; hockey93_06_11 (Rev A $1554E, movea.l operand)
play_new_song = $16674		; sound driver (sound93.asm)
RAMStart = $FF0000	

; .region code
	org	$FAE2

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	hockey93_03_05.asm
