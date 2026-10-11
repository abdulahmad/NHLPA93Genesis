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
Montreal = $23CA
playoffseats = $491A
Credits = $4B3A			; (movea.l operand)
ChkShortPeriods = $6490
ResetClock = $651E
GetPeriodTime = $6556		; (jsr abs.w)
StartPer = $656E
ShowScores = $6C0A
LineEditor = $6E08
DecodeTeamLines = $73B8
EncodeTeamLines = $7418
TeamRosterScreen = $749C
ScoringSummaryScreen = $7992
PenaltySummaryScreen = $7C0C
PlayoffStatsScreen = $7ED2
PlayerStatsScreen = $7F04
GameStatisticsScreen = $849E
CrowdMeterScreen = $866C
TimeoutMenu = $8894
SelectGoalieMenu = $88FC
GetGoalieCount = $8A56	; (jsr abs.l)
ReplayMode = $8AC4
updateanim = $9270		; (jsr abs.l)
lcfound2 = $9860		; (jsr abs.l)
assbench = $A0FC
asseben = $A26C
asspenalty = $A2DC
assdopen = $A418
assepen = $A43E
assfaceoff = $A4CE
assfaceoffpl = $A4E4
assfight = $A572
assfwatch = $A9A0
assstanley = $AA58
assscore = $AAB0
assdefo = $AB32
assdefd = $ABF6
asswingd = $AD98
asswingo = $AE88
asscenterd = $AFBC
asscentero = $B056
assgoalie = $B172
assgoalietopuck = $B6E6
asspuckc = $B76C
assnearest = $BD02
asspassrec = $BFAE
assshoot = $C010
pucknothing = $C044
puckfaceoff = $C048
puckfaceoff2 = $C426
pucknorm = $C91A
puckshadow = $CCD2
SetSPA = $D120
UnpackNibbles = $D5D2
WeightedRandomSelect = $D5FE
forceblack = $D67C
cramfade = $D6D6
CopyPaletteToCRAM = $D764
randomd0 = $D7A6
sfx = $D852
song = $D876
waitx = $D896
orjoy = $D958
ProcessInputWithRepeat = $D98E
Readjoy1 = $D9B6
Readjoy2 = $D9D4
DoDMA = $DA94
DoDMA_nd2 = $DB2E
DoFill = $DB98
setVram = $DBDE
setVram_0 = $DBF4
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
PushNumberWidth = $E334
appendz = $E390
appstring = $E398
printbigz = $E3DC
printbig = $E3EE
AddSmallFont = $E4FE
AddFramer = $E50C
AddTeamBlock = $E51A
Intermission = $F350
UpdateScores = $F480
AdvanceStringPtr = $F74C
rtss = $110E0
VBlank = $11802
vb2 = $1187E
DumpSprites2 = $118A4
DoDMAList = $118B4
SetSframe = $11B8E
addframe2 = $12058
KillCrowd = $1227E
BackupRAM_Save = $164AC
p_turnoff = $165D8		; sound driver (jsr abs.l)
p_music_vblank = $166D4
ScoutingReportText = $2CEC8	; data
GameSetUpMap = $2E1FC		; (game setup bitmap)
GameSetupSprites = $2EFA2		; graphics data (movea.l operand)
Title1Map = $2F0B0		; graphics data (movea.l operand)
Title2Map = $31288
Title3Sprites = $31F10		; graphics data
TitleLogoSprites = $322CE		; graphics data (movea.l operand)
ScoutMap = $32860
FramerMap = $33388		; graphics data (movea.l operand)
IceRinkMap = $33864		; graphics data
CrowdSprites = $748E2	; graphics data
BigFontMap = $78CFE	; graphics data
SmallFontMap = $795B4	; graphics data
EnergyBarMap = $7A282		; graphics data (movea.l operand)
TeamBlocksmap = $7A376		; graphics data
ArrowsMap = $7C54E		; graphics data (movea.l operand)
EASNmap = $7C7AA		; graphics data
Ronbarrmap = $7C946		; graphics data
StanleyMap = $7D304		; graphics data
EASNmap2 = $7F4F6		; graphics data
RAMStart = $FF0000	
; .region code
	org	$122A8

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	hockey93_06_11.asm
