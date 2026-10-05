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

; External routines and data outside $12E26-$13951, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
Credits = $4B3A			; TeamData93 (movea.l operand)
forceblack = $D67C		; middle93_1
cramfade = $D6D6		; middle93_1 (Rev A sub_D6EE)
CopyPaletteToCRAM = $D764	; middle93_1 (Rev A sub_D77C)
randomd0 = $D7A6		; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
waitx = $D896			; middle93_1 (Rev A sub_D8AE)
orjoy = $D958			; middle93_1 (Rev A sub_D970)
ProcessInputWithRepeat = $D98E	; middle93_1 (Rev A sub_D9A6)
Readjoy1 = $D9B6		; middle93_1 (IDA readjoy1)
DoDMA = $DA94			; middle93_1 (Rev A sub_DAAC)
DoDMA_nd2 = $DB2E		; middle93_1
setVram = $DBDE			; middle93_1
setVram_0 = $DBF4		; middle93_1 (Rev A sub_DC0C)
dobitmap = $DCE4		; middle93_2
DecompressGraphicsWithCallback = $DD68	; middle93_2
DoDMA_clearCallbackPointer = $DD74	; middle93_2
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printsmallz = $E070		; middle93_2
printsmall = $E082		; middle93_2
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
PushNumberWidth = $E334		; middle93_2 (IDA pushnumber)
AddSmallFont = $E4FE		; middle93_2
AddFramer = $E50C		; middle93_2
AddTeamBlock = $E51A		; middle93_2
rtss = $110E0			; hockey93_05
vb2 = $1187E			; video93_1
SetSframe = $11B8E		; video93_1
clearTeamStats = $128CC		; hockey93_06
DisplayTeamBlock = $13F1C	; hockey93_08
ScoutingReportText = $2CEC8	; data
p_turnoff = $165D8		; sound driver (jsr abs.l, Rev A $165F0)
p_music_vblank = $166D4		; sound driver (jsr abs.l)
Titlemap = $2F0B0		; graphics data (movea.l operand, Rev A $2F0DE)
Titlemap2 = $322CE		; graphics data (movea.l operand, Rev A $322FC)
Titlemap2Plus8 = $322D6	; graphics data
Title3map = $31F10		; graphics data
Title3mapPlus8 = $31F18	; graphics data
Ronbarrmap = $7C946		; graphics data
StanleyMap = $7D304		; graphics data
StanleyMapPlus8 = $7D30C	; graphics data
EASNmap2 = $7F4F6		; graphics data
EASNmap2Plus8 = $7F4FE	; graphics data
smallfontmapPlus8 = $795BC	; graphics data
; .region code
	org	$12E26

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_07.asm
