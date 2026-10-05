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

; External routines and data outside $13952-$14403, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
updateanim = $9270		; hockey93_02 (jsr abs.l)
UnpackNibbles = $D5D2		; logic93_5
WeightedRandomSelect = $D5FE	; logic93_5
SetSPA = $D120			; logic93_5
cramfade = $D6D6		; middle93_1
randomd0 = $D7A6		; middle93_1
orjoy = $D958			; middle93_1
ProcessInputWithRepeat = $D98E	; middle93_1
Readjoy1 = $D9B6		; middle93_1
Readjoy2 = $D9D4		; middle93_1
setVram = $DBDE			; middle93_1
dobitmap = $DCE4		; middle93_2
DecompressGraphicsWithCallback = $DD68	; middle93_2
DoDMA_clearCallbackPointer = $DD74	; middle93_2
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
appstring = $E398		; middle93_2
AddTeamBlock = $E51A		; middle93_2
rtss = $110E0			; hockey93_05
DumpSprites2 = $118A4		; video93_1
SetSframe = $11B8E		; video93_1
addframe2 = $12058		; video93_2
defaultsprites2 = $1264C	; hockey93_06
setteams = $128F4		; hockey93_06
NewPO = $1442E			; hockey93_09
SelectRandomPlayoffTree = $1445A	; hockey93_09
maketree = $144C4		; hockey93_09
FigureJoy = $14586		; hockey93_09
ConverByteToDigits = $14FEA	; hockey93_10
p_music_vblank = $166D4		; sound driver (jsr abs.l)
GameSetupMap = $2EFA2		; graphics data (movea.l operand)
GameSetupMapPlus8 = $2EFAA	; graphics data (movea.l operand)
FramermapPlus8 = $33390		; graphics data (movea.l operand)
smallfontmapPlus8 = $795BC	; graphics data (movea.l operand)
TeamBlocksmap = $7A376		; graphics data (movea.l operand)
; .region code
	org	$13952

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_08.asm
