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

; External routines and data outside $A0FC-$AE87, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
lcfound2 = $9860		; logic93_1
changeplayer = $9BC4		; logic93_1 (Rev A sub_9BDC)
setpads = $A048			; logic93_1 (Rev A sub_A060)
check4bench = $A06C		; logic93_1
chkpk = $B93C			; logic93_3 (Rev A sub_B954)
EvadePC = $BBD2			; logic93_3 (Rev A loc_BBEA)
check4check = $BF0E		; logic93_4
skateto = $CDAE			; logic93_5
assexit = $D02C			; logic93_5
assreplace = $D048		; logic93_5
vtoa = $D05C			; logic93_5
SetSPA = $D120			; logic93_5
doplayeracc = $D136		; logic93_5
playeracc = $D406		; logic93_5
randomd0 = $D7A6		; middle93_1
sroot = $D7DE			; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
appendz = $E390			; middle93_2
appstring = $E398		; middle93_2
setInjuryType = $10332		; hockey93_03
rtss = $110E0			; hockey93_05
getpde = $1132E			; hockey93_05
Setplass = $115A0		; hockey93_05
setplayer = $115BC		; hockey93_05 (Rev A sub_115D4)
SprSort = $127F8		; hockey93_06
box = $14E74			; hockey93_10
getname = $14EAE		; hockey93_10

; .region code
	org	$A0FC

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	logic93_2.asm
