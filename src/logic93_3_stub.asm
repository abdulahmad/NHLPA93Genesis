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

; External routines and data outside $AE88-$BC6B, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
dopass = $9944			; logic93_1
check4bench = $A06C		; logic93_1
assnothing = $AA3E		; logic93_2
checkob = $BC6C			; logic93_4 (Rev A sub_BC84)
CompLine = $C328		; logic93_4 (Rev A sub_C340)
skateto = $CDAE			; logic93_5
skatetopuck = $CF88		; logic93_5
assexit = $D02C			; logic93_5
assinsert = $D03E		; logic93_5
assreplace = $D048		; logic93_5
vtoa = $D05C			; logic93_5
SetSPA = $D120			; logic93_5
playeracc = $D406		; logic93_5
StopNA = $D568			; logic93_5
randomd0s = $D79A		; middle93_1 (Rev A sub_D7B2)
randomd0 = $D7A6		; middle93_1
sroot = $D7DE			; middle93_1
AddPenalty2 = $E552		; middle93_2
printscores1 = $EFA8		; penalty93_2
AvgCline = $F250		; penalty93_2 (Rev A sub_F268)
rtss = $110E0			; hockey93_05
setpersonel = $1135C		; hockey93_05

; .region code
	org	$AE88

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"

; Main segment code
	include	logic93_3.asm
