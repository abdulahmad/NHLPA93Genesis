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

; External routines and data outside $122A8-$12E25, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
ChkShortPeriods = $6490		; hockey93_01 (IDA loc_649E)
ResetClock = $651E		; hockey93_01
StartPer = $656E		; hockey93_01
DisplayTeamStats = $7ED2	; stats93
SetSPA = $D120			; logic93_5
forceblack = $D67C		; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
Readjoy1 = $D9B6		; middle93_1
Readjoy2 = $D9D4		; middle93_1
DoDMA_nd2 = $DB2E		; middle93_1
DoFill = $DB98			; middle93_1
setVram = $DBDE			; middle93_1
dobitmap = $DCE4		; middle93_2
DecompressGraphicsWithCallback = $DD68	; middle93_2
DoDMA_clearCallbackPointer = $DD74	; middle93_2
eraser = $DFB8			; middle93_2
printsmallz = $E070		; middle93_2
printsmall = $E082		; middle93_2
printz = $E1AE			; middle93_2
print = $E1C0			; middle93_2
AddSmallFont = $E4FE		; middle93_2
AddFramer = $E50C		; middle93_2
AddTeamBlock = $E51A		; middle93_2
Intermission = $F350		; penalty93_2
UpdateScores = $F480		; penalty93_2
AdvanceStringPtr = $F74C	; penalty93_2
rtss = $110E0			; hockey93_05
VBlank = $11802			; video93_1 (IDA VBlank_org)
vb2 = $1187E			; video93_1
DoDMAList = $118B4		; video93_1
addframe2 = $12058		; video93_2
KillCrowd = $1227E		; video93_2
ScoutingReport = $12E26		; hockey93_07
TitleScreen = $13420		; hockey93_07 (Rev A $13438)
CallAnimationCallback = $13852	; hockey93_07 (Rev A $1386A)
DisplayTeamStatsForPlayoffs = $148C8	; hockey93_09 (Rev A $148E0)
setoptions = $13952		; hockey93_08
EncodePW = $1474A		; hockey93_09
unk_15556 = $1553E		; hockey93_11 (movea.l operand, Rev A $15556)
Titlemap2 = $322CE		; graphics data (movea.l operand, Rev A $322FC)
IceRinkMap = $33864		; graphics data
IceRinkMapPlus8 = $3386C	; graphics data
CrowdSpritesPlus8 = $748EA	; graphics data
bigfontmapPlus8 = $78D06	; graphics data
smallfontmapPlus8 = $795BC	; graphics data
unk_7A2B8 = $7A28A		; graphics data (movea.l operand, Rev A $7A2B8)
TeamBlocksmap = $7A376		; graphics data
ArrowsMap = $7C54E		; graphics data (movea.l operand, Rev A $7C57C)
ArrowsMapPlus8 = $7C556		; graphics data
EASNmapPlus8 = $7C7B2		; graphics data
; .region code
	org	$122A8

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_06.asm
