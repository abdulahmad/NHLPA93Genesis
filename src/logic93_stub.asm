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
clockcont_0 = $67C0
startpause1 = $68EC
startpause2 = $68F6
rtss2 = $9092
checkwindow = $9350
forceblack = $D67C
randomd0s = $D79A
randomd0 = $D7A6
sroot = $D7DE
sfx = $D852
song = $D876
dobitmap = $DCE4
DecompressGraphicsPlain = $DD74
eraser = $DFB8
Framer = $DFF2
printsmallz = $E070
printz = $E1AE
print = $E1C0
appendz = $E390
appstring = $E398
AddPenalty = $E526
AddPenalty2 = $E552
Stop4Pen = $E8CE
PushRef = $EAD4
ClrHor = $EEFE
printscores1 = $EFA8
linebar = $F1C0
getlinee = $F20E
AvgCline = $F250
loadTeamStruct = $F2DA
PrintStringFromList = $F744
setInjuryType = $10332
checkpuckcoll = $10CAE
rtss = $110E0
makepde = $11312
getpde = $1132E
setpde = $1134E
setpersonel = $1135C
forcepldata = $114EC
ResetBench = $11546
Setplass = $115A0
setplayer = $115BC
SprSort = $127F8
resetplstuff = $1287A
PeriodOver = $12972
box = $14E74
getname = $14EAE
linelist = $15466
FaceOffMap = $33400		; graphics data
RefsMap = $38906		; graphics data
HotList = $743CE		; graphics data
FaceOffSprites = $77170	; graphics data
RAMStart = $FF0000	

; .region code
	org	$946E

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	logic93.asm
