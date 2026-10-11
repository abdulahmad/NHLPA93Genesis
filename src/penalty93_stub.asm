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
restoreteams = $64FE		; hockey93_01
DoGameFrame = $6604		; hockey93_01
SetupPauseScreen = $699C	; hockey93_01 (Rev A $69AA)
InitMenuState = $6A00		; menu93
DrawMenuScreen = $6A10		; menu93
PrintTeamData = $6BB6		; menu93
assinsert = $D03E		; logic93
assreplace = $D048		; logic93
WeightedRandomSelect = $D5FE	; logic93
forceblack = $D67C		; middle93
randomd0 = $D7A6		; middle93
sfx = $D852			; middle93
song = $D876			; middle93 (Rev A SFX)
waitxsr = $D8C0	; middle93
orjoy = $D958			; middle93
DoFill = $DB98			; middle93
dobitmap = $DCE4		; middle93
DoDMA_clearCallbackPointer = $DD74	; middle93
eraser = $DFB8			; middle93
Framer = $DFF2			; middle93
printsmall = $E082		; middle93
printz = $E1AE			; middle93
print = $E1C0			; middle93
PushTime = $E29C		; middle93
PushNumber = $E300		; middle93
PushNumberWidth = $E334		; middle93
appendz = $E390			; middle93
appstring = $E398		; middle93
printbig = $E3EE		; middle93
GetPeriodTimeRemaining = $109E4	; hockey93_03_05 (Rev A $109FC)
rtss = $110E0			; hockey93_03_05
setpersonel = $1135C		; hockey93_03_05
forcepldata = $114EC		; hockey93_03_05
ResetBench = $11546		; hockey93_03_05
Setplass = $115A0		; hockey93_03_05
setplayer = $115BC		; hockey93_03_05
setvideo = $118F2		; video93
KillCrowd = $1227E		; video93
setupice_highlight = $1241A	; hockey93_06_11
SprSort = $127F8		; hockey93_06_11
resetplstuff = $1287A		; hockey93_06_11
clearTeamStats = $128CC		; hockey93_06_11
setplayercolors = $12948	; hockey93_06_11
GetShifter = $148B0		; hockey93_06_11
DisplayPeriodOver = $14B26	; hockey93_06_11 (Rev A $14B3E)
DisplayPlayerAttributeMenu = $14D86	; hockey93_06_11 (Rev A $14D9E)
GetPlayerName = $14E8C		; hockey93_06_11 (Rev A $14EA4)
ConverByteToDigits = $14FEA	; hockey93_06_11
Penaltylist = $151FE		; hockey93_06_11 (Rev A $15216)
PerLabels = $154A4		; hockey93_06_11
priolist = $15536		; hockey93_06_11 (Rev A $1554E)
StartGameText = $15B6A		; hockey93_06_11
StartGameTextPO = $15BEE		; hockey93_06_11
IntermissionText = $15C8A		; hockey93_06_11
ExitGameText = $15D86		; hockey93_06_11
ExitGameTextPO = $15E52		; hockey93_06_11
p_turnoff = $165D8		; sound driver, no segment
IceRinkMap = $33864		; graphics data, no segment
RefsMap = $38906		; graphics data, no segment (Rev A $38934)
RefMap2 = $39462		; graphics data, no segment (Rev A $39490)
ZamSprites = $781E4	; graphics data, no segment
EnergyBarMap = $7A282		; graphics data, no segment (Rev A $7A2B0)
EASNmap = $7C7AA		; graphics data, no segment
RAMStart = $FF0000	

; .region code
	org	$E526

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	penalty93.asm
