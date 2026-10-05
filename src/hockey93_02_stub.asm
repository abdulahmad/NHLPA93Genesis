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

; External routines and data outside $68B4-$6C09, at their v1.1 retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
rtss2 = $9092
readjoy1 = $D9B6
readjoy2 = $D9D4
loc_12a16 = $129FE	; IDA name; retail target is $129FE
p_turnoff = $165D8
forceblack = $D67C
pausetext = $1592A
pausetext2 = $15A56
getpzjoy = $8DB8
processinputwithrepeat = $D98E
clrhor = $EEFE
printscores1 = $EFA8
setvideo = $118F2
sethor = $EF3C
killcrowd = $1227E
printsmallz = $E070
printsmall = $E082
eraser = $DFB8
framer = $DFF2
xyvmmap = $DF8E

; .region code
	org	$68B4

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"

; Main segment code
	include	hockey93_02.Asm
