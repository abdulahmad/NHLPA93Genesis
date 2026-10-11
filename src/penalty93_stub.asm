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
restoreteams = $64FE
DoGameFrame = $6604
SetupPauseScreen = $699C
InitMenuState = $6A00
DrawMenuScreen = $6A10
PutTeamBlock = $6BB6
assinsert = $D03E
assreplace = $D048
WeightedRandomSelect = $D5FE
forceblack = $D67C
randomd0 = $D7A6
sfx = $D852
song = $D876
waitxsr = $D8C0
orjoy = $D958
DoFill = $DB98
dobitmap = $DCE4
DecompressGraphicsPlain = $DD74
eraser = $DFB8
Framer = $DFF2
printsmall = $E082
printz = $E1AE
print = $E1C0
PushTime = $E29C
PushNumber = $E300
PushNumberWidth = $E334
appendz = $E390
appstring = $E398
printbig = $E3EE
GetPeriodTimeRemaining = $109E4
rtss = $110E0
setpersonel = $1135C
forcepldata = $114EC
ResetBench = $11546
Setplass = $115A0
setplayer = $115BC
setvideo = $118F2
KillCrowd = $1227E
setupice_highlight = $1241A
SprSort = $127F8
resetplstuff = $1287A
clearTeamStats = $128CC
setplayercolors = $12948
GetShifter = $148B0
ShowThreeStars = $14B26
ShowGoalBox = $14D86
GetPlayerName = $14E8C
ConvertByteToDigits = $14FEA
Penaltylist = $151FE
PerLabels = $154A4
priolist = $15536
StartGameText = $15B6A
StartGameTextPO = $15BEE
IntermissionText = $15C8A
ExitGameText = $15D86
ExitGameTextPO = $15E52
p_turnoff = $165D8		; sound driver, no segment
IceRinkMap = $33864		; graphics data, no segment
RefsMap = $38906		; graphics data, no segment
RefMap2 = $39462		; graphics data, no segment
ZamSprites = $781E4	; graphics data, no segment
EnergyBarMap = $7A282		; graphics data, no segment
EASNmap = $7C7AA		; graphics data, no segment
RAMStart = $FF0000	

; .region code
	org	$E526

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	penalty93.asm
