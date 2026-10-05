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

; External routines and data outside $E526-$EFA7, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
assinsert = $D03E		; logic93_5
assreplace = $D048		; logic93_5
forceblack = $D67C		; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
DoFill = $DB98			; middle93_1 (Rev A sub_DBB0)
dobitmap = $DCE4		; middle93_2 (Rev A sub_DCFC)
DoDMA_clearCallbackPointer = $DD74	; middle93_2 (Rev A sub_DD8C)
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
PushTime = $E29C		; middle93_2 (Rev A sub_E2B4)
appendz = $E390			; middle93_2
appstring = $E398		; middle93_2
printscores1 = $EFA8		; penalty93_2
DrawEASNLogo = $F0CA		; penalty93_2 (Rev A $F0E2)
USBoard = $F100			; penalty93_2 (Rev A $F118)
NewTicker = $F5BA		; penalty93_2 (Rev A $F5D2)
NewTicker3 = $F5F4		; penalty93_2 (Rev A $F60C)
GetPeriodTimeRemaining = $109E4	; hockey93_04 (Rev A $109FC)
rtss = $110E0			; hockey93_05
Setplass = $115A0		; hockey93_05
setplayer = $115BC		; hockey93_05 (Rev A sub_115D4)
SprSort = $127F8		; hockey93_06
DisplayPeriodOver = $14B26	; hockey93_10 (Rev A $14B3E)
DisplayPlayerAttributeMenu = $14D86	; hockey93_10 (Rev A $14D9E)
GetPlayerName = $14E8C		; hockey93_10 (Rev A $14EA4)
PenaltyList = $151FE		; hockey93_11 (Rev A $15216)
priolist = $15536		; hockey93_11 (Rev A $1554E)
IceRinkMap = $33864		; graphics data, no segment
RefsMap = $38906		; graphics data, no segment (Rev A $38934)
RefMap2 = $39462		; graphics data, no segment (Rev A $39490)
RefMap2Plus8 = $3946A		; graphics data, no segment (Rev A $39498)

; .region code
	org	$E526

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	penalty93_1.asm
