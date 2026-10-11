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
Montreal = $23CA		; TeamData93
playoffseats = $491A		; TeamData93
Credits = $4B3A			; TeamData93 (movea.l operand)
ChkShortPeriods = $6490		; hockey93_01
ResetClock = $651E		; hockey93_01
GetPeriodTime = $6556		; hockey93_01 (jsr abs.w)
StartPer = $656E		; hockey93_01
ShowScores = $6C0A		; stats93 (Rev A $6C18)
LineEditor = $6E08		; stats93 (Rev A $6E16)
DecodePlayerAttributes = $73B8	; stats93 (Rev A $73C6)
EncodePlayerAttributes = $7418	; stats93 (Rev A $7426)
TeamRosterScreen = $749C	; stats93 (Rev A $74AA)
ScoringSummaryScreen = $7992	; stats93 (Rev A $79A0)
PenaltySummaryScreen = $7C0C	; stats93 (Rev A $7C1A)
DisplayTeamStats = $7ED2	; stats93
PlayerStatsScreen = $7F04	; stats93 (Rev A $7F12)
GameStatisticsScreen = $849E	; stats93 (Rev A $84AC)
CrowdMeterScreen = $866C	; stats93 (Rev A $867A)
TimeoutMenu = $8894		; stats93 (Rev A $88A2)
SelectGoalieMenu = $88FC	; stats93 (Rev A $890A)
ReadAttributeNibble = $8A56	; stats93 (jsr abs.l)
ReplayMode = $8AC4		; hockey93_02 (Rev A $8AD2)
updateanim = $9270		; hockey93_02 (jsr abs.l)
lcfound2 = $9860		; logic93 (jsr abs.l)
assbench = $A0FC		; logic93
asseben = $A26C			; logic93
asspenalty = $A2DC		; logic93
assdopen = $A418		; logic93
assepen = $A43E			; logic93
assfaceoff = $A4CE		; logic93
assfaceoffpl = $A4E4		; logic93
assfight = $A572		; logic93
assfwatch = $A9A0		; logic93
assstanley = $AA58		; logic93
assscore = $AAB0		; logic93
assdefo = $AB32			; logic93
assdefd = $ABF6			; logic93
asswingd = $AD98		; logic93
asswingo = $AE88		; logic93
asscenterd = $AFBC		; logic93
asscentero = $B056		; logic93
assgoalie = $B172		; logic93
assgoalietopuck = $B6E6		; logic93
asspuckc = $B76C		; logic93
assnearest = $BD02		; logic93
asspassrec = $BFAE		; logic93
assshoot = $C010		; logic93
pucknothing = $C044		; logic93 (Rev A listing puckunflip)
puckfaceoff = $C048		; logic93
puckfaceoff2 = $C426		; logic93
pucknorm = $C91A		; logic93
puckshadow = $CCD2		; logic93
SetSPA = $D120			; logic93
UnpackNibbles = $D5D2		; logic93
WeightedRandomSelect = $D5FE	; logic93
forceblack = $D67C		; middle93
cramfade = $D6D6		; middle93
CopyPaletteToCRAM = $D764	; middle93
randomd0 = $D7A6		; middle93
sfx = $D852			; middle93
song = $D876			; middle93 (Rev A SFX)
waitx = $D896			; middle93
orjoy = $D958			; middle93
ProcessInputWithRepeat = $D98E	; middle93
Readjoy1 = $D9B6		; middle93
Readjoy2 = $D9D4		; middle93
DoDMA = $DA94		; middle93
DoDMA_nd2 = $DB2E		; middle93
DoFill = $DB98			; middle93
setVram = $DBDE			; middle93
setVram_0 = $DBF4		; middle93
Vmaddr = $DCCA		; middle93
dobitmap = $DCE4		; middle93
DecompressGraphicsWithCallback = $DD68	; middle93
DoDMA_clearCallbackPointer = $DD74	; middle93
eraser = $DFB8			; middle93
Framer = $DFF2			; middle93
printsmallz = $E070		; middle93
printsmall = $E082		; middle93
printz = $E1AE			; middle93
print = $E1C0			; middle93
PushNumberWidth = $E334		; middle93
appendz = $E390			; middle93
appstring = $E398		; middle93
printbigz = $E3DC		; middle93
printbig = $E3EE		; middle93
AddSmallFont = $E4FE		; middle93
AddFramer = $E50C		; middle93
AddTeamBlock = $E51A		; middle93
Intermission = $F350		; penalty93
UpdateScores = $F480		; penalty93
AdvanceStringPtr = $F74C	; penalty93
rtss = $110E0			; hockey93_03_05
VBlank = $11802			; video93
vb2 = $1187E			; video93
DumpSprites2 = $118A4		; video93
DoDMAList = $118B4		; video93
SetSframe = $11B8E		; video93
addframe2 = $12058		; video93
KillCrowd = $1227E		; video93
BitsToPW = $164AC		; sram93 (Rev A $164C4)
p_turnoff = $165D8		; sound driver (jsr abs.l, Rev A $165F0)
p_music_vblank = $166D4		; sound93
ScoutingReportText = $2CEC8	; data
GameSetUpMap = $2E1FC		; sound93 (game setup bitmap)
GameSetupSprites = $2EFA2		; graphics data (movea.l operand)
Title1Map = $2F0B0		; graphics data (movea.l operand, Rev A $2F0DE)
Title2Map = $31288		; graphics93
Title3Sprites = $31F10		; graphics data
TitleLogoSprites = $322CE		; graphics data (movea.l operand, Rev A $322FC)
ScoutMap = $32860		; graphics93
FramerMap = $33388		; graphics data (movea.l operand)
IceRinkMap = $33864		; graphics data
CrowdSprites = $748E2	; graphics data
BigFontMap = $78CFE	; graphics data
SmallFontMap = $795B4	; graphics data
EnergyBarMap = $7A282		; graphics data (movea.l operand, Rev A $7A2B8)
TeamBlocksmap = $7A376		; graphics data
ArrowsMap = $7C54E		; graphics data (movea.l operand, Rev A $7C57C)
EASNmap = $7C7AA		; graphics data
Ronbarrmap = $7C946		; graphics data
StanleyMap = $7D304		; graphics data
EASNmap2 = $7F4F6		; graphics data
RAMStart = $FF0000	
; .region code
	org	$122A8

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	hockey93_06_11.asm
