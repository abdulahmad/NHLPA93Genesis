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

; External routines and data outside $6C0A-$8AC3, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
InitMenuState = $6A00		; menu93
HandleMenuInput = $6A4E		; menu93
PrintTeamData = $6BB6		; menu93
MenuWaitVblank = $6BF4		; menu93
getpzjoy = $8DB8
rtss2 = $9092
nodiag = $D966
ProcessInputWithRepeat = $D98E
forceblack = $D67C
sroot = $D7DE
Vmaddr = $DCCA
dobitmap = $DCE4
DecompressGraphicsWithCallback = $DD68
DoDMA_clearCallbackPointer = $DD74
eraser = $DFB8
Framer = $DFF2
printsmallz = $E070
printsmall = $E082
printz = $E1AE
print = $E1C0
FormatAndPrintTime = $E26C
PushTime = $E29C
PushNumber = $E300
PushNumberWidth = $E334		; IDA: pushnumber (SNASM is case-insensitive, clashes with PushNumber)
appendz = $E390
appstring = $E398
printbigz = $E3DC
AddSmallFont = $E4FE
AddFramer = $E50C
loc_F0F6 = $F0DE		; IDA name; retail target is $F0DE
PrintStringFromList = $F744
AdvanceStringPtr = $F74C
rtss = $110E0
setpersonel = $1135C
setupIceRinkMap = $124E2
setplayercolors = $12948
GetShifter = $148B0
ReadTeamStats = $1495C
getname = $14EAE
FormatPlayerNameWithAttrib = $14F06
FormatPlayerName = $14F44
FormatPlayerNameShort = $14F7C
PenaltyList = $151FE
linelist = $15466
PlayerPositionText = $15490
PerLabels = $154A4
PAttribColumns = $156A8
GAttribColumns = $15820
AttributeScreenText = $15F1E
ExitAttribText = $15F8E
BitsToPW = $164AC
unk_3288E = $32860		; IDA Rev A address, graphics (bitmap header) used by SetupScreen/DrawTeamScreen
FramermapPlus8 = $33390
IceRinkMapPlus8 = $3386C
smallfontmapPlus8 = $795BC
unk_7CF4C = $7CF1E		; IDA name; retail address $7CF1E (graphics used by ShowScores)

; .region code
	org	$6C0A

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"

; Main segment code
	include	stats93.Asm
