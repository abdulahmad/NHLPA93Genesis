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

; External routines and data outside $EFA8-$FAE1, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/jsr displacement or movea immediate.
restoreteams = $64FE		; hockey93_01 (IDA InitTeamShots)
DoGameFrame = $6604		; hockey93_01
SetupPauseScreen = $699C	; hockey93_01 (Rev A $69AA)
InitMenuState = $6A00		; menu93
DrawMenuScreen = $6A10		; menu93
PrintTeamData = $6BB6		; menu93
WeightedRandomSelect = $D5FE	; logic93_5 (Rev A sub_D616)
forceblack = $D67C		; middle93_1
randomd0 = $D7A6		; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
IntermissionLoop = $D8C0	; middle93_1 (Rev A sub_D8D8)
orjoy = $D958			; middle93_1 (Rev A sub_D970)
dobitmap = $DCE4		; middle93_2 (Rev A sub_DCFC)
DoDMA_clearCallbackPointer = $DD74	; middle93_2 (Rev A sub_DD8C)
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printsmall = $E082		; middle93_2 (Rev A sub_E09A)
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
PushTime = $E29C		; middle93_2 (Rev A sub_E2B4)
PushNumber = $E300		; middle93_2 (Rev A sub_E318)
PushNumberWidth = $E334		; middle93_2 (IDA pushnumber)
printbig = $E3EE		; middle93_2 (Rev A sub_E406)
ClrHor = $EEFE			; penalty93_1
SetHor = $EF3C			; penalty93_1
rtss = $110E0			; hockey93_05
setpersonel = $1135C		; hockey93_05
forcepldata = $114EC		; hockey93_05 (Rev A sub_11504)
ResetBench = $11546		; hockey93_05 (Rev A sub_1155E)
setvideo = $118F2		; video93_1
KillCrowd = $1227E		; video93_2
setupice_highlight = $1241A	; hockey93_06
SprSort = $127F8		; hockey93_06
resetplstuff = $1287A		; hockey93_06
clearTeamStats = $128CC		; hockey93_06
setplayercolors = $12948	; hockey93_06
GetShifter = $148B0		; hockey93_09
ConverByteToDigits = $14FEA	; hockey93_10
PerLabels = $154A4		; hockey93_11
priolist = $15536		; hockey93_11 (Rev A $1554E)
p_turnoff = $165D8		; sound driver, no segment
ZamSpritesPlus8 = $781EC	; graphics data, no segment
RefsMapPlus8 = $3890E		; graphics data, no segment (Rev A unk_3893C)
unk_7A2B0 = $7A282		; graphics data, no segment (Rev A $7A2B0)
EASNmap = $7C7AA		; graphics data, no segment

; .region code
	org	$EFA8

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	penalty93_2.asm
