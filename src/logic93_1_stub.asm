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

; External routines and data outside $946E-$A0FB, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
startpause1 = $68EC		; hockey93_01
startpause2 = $68F6		; hockey93_01
rtss2 = $9092			; hockey93_02
checkob = $BC6C			; logic93_4 (Rev A sub_BC84)
doplayeracc = $D136		; logic93_5
SetSPA = $D120			; logic93_5
playeracc = $D406		; logic93_5
assinsert = $D03E		; logic93_5
assreplace = $D048		; logic93_5
vtoa = $D05C			; logic93_5
GetHot = $D0C6			; logic93_5
dirtab = $D5B2			; logic93_5 (Rev A movea.l #$D5CA)
randomd0s = $D79A		; middle93_1 (Rev A sub_D7B2)
randomd0 = $D7A6		; middle93_1
sroot = $D7DE			; middle93_1
sfx = $D852			; middle93_1
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
print = $E1C0			; middle93_2
printz = $E1AE			; middle93_2
printscores1 = $EFA8		; penalty93_2
linebar = $F1C0			; penalty93_2 (Rev A sub_F1D8)
loadTeamStruct = $F2DA		; penalty93_2
PrintStringFromList = $F744	; penalty93_2 (Rev A sub_F75C)
rtss = $110E0			; hockey93_05
makepde = $11312		; hockey93_05 (Rev A sub_1132A)
getpde = $1132E			; hockey93_05
setpde = $1134E			; hockey93_05 (Rev A sub_11366)
setpersonel = $1135C		; hockey93_05
Setplass = $115A0		; hockey93_05
box = $14E74			; hockey93_10
linelist = $15466		; hockey93_11 (Rev A FaceOffsprites)

; .region code
	org	$946E

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	logic93_1.asm
