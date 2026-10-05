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

; External routines outside $10E66-$11801, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
setc1player = $9C7E		; logic93_1
setc2player = $9C9C		; logic93_1
chkpk2 = $B94C			; logic93_3 (Rev A sub_B964)
a2touchpuck = $CB34		; logic93_5
puckflip = $CCB8		; logic93_5 (Rev A sub_CCD0)
assinsert = $D03E		; logic93_5
assreplace = $D048		; logic93_5
vtoa = $D05C			; logic93_5
GetHot = $D0C6			; logic93_5
SetSPA = $D120			; logic93_5
randomd0s = $D79A		; middle93_1 (Rev A sub_D7B2)
randomd0 = $D7A6		; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
ChkShotStat = $F28A		; penalty93_2
FallDown = $10162		; hockey93_03
GetPeriodTime = $6556		; hockey93_01 (jsr abs.w)
GetPlayerCount = $8A8E		; stats93 (jsr abs.l)
priolist = $15536		; hockey93_11 (Rev A $1554E, movea.l operand)
sublist = $154CC		; hockey93_11 (Rev A $154E4, movea.l operand)
; .region code
	org	$10E66

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_05.asm
