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
clockcont_0 = $67C0		; hockey93_01
startpause1 = $68EC		; hockey93_01
startpause2 = $68F6		; hockey93_01
rtss2 = $9092			; hockey93_02
checkwindow = $9350		; hockey93_02 (Rev A sub_9368)
forceblack = $D67C		; middle93
randomd0s = $D79A		; middle93 (Rev A sub_D7B2)
randomd0 = $D7A6		; middle93
sroot = $D7DE			; middle93
sfx = $D852			; middle93
song = $D876			; middle93 (Rev A SFX)
dobitmap = $DCE4		; middle93 (Rev A sub_DCFC)
DoDMA_clearCallbackPointer = $DD74	; middle93 (Rev A sub_DD8C)
eraser = $DFB8			; middle93
Framer = $DFF2			; middle93
printsmallz = $E070		; middle93 (Rev A printz2)
printz = $E1AE			; middle93
print = $E1C0			; middle93
appendz = $E390			; middle93
appstring = $E398		; middle93
AddPenalty = $E526		; penalty93
AddPenalty2 = $E552		; middle93
Stop4Pen = $E8CE		; penalty93 (Rev A sub_E8E6)
PushRef = $EAD4			; penalty93
ClrHor = $EEFE			; penalty93 (Rev A sub_EF16)
printscores1 = $EFA8		; penalty93
linebar = $F1C0			; penalty93 (Rev A sub_F1D8)
getlinee = $F20E		; penalty93 (Rev A sub_F226)
AvgCline = $F250		; penalty93 (Rev A sub_F268)
loadTeamStruct = $F2DA		; penalty93
PrintStringFromList = $F744	; penalty93 (Rev A sub_F75C)
setInjuryType = $10332		; hockey93_03_05
checkpuckcoll = $10CAE		; hockey93_03_05
rtss = $110E0			; hockey93_03_05
makepde = $11312		; hockey93_03_05 (Rev A sub_1132A)
getpde = $1132E			; hockey93_03_05
setpde = $1134E			; hockey93_03_05 (Rev A sub_11366)
setpersonel = $1135C		; hockey93_03_05
forcepldata = $114EC		; hockey93_03_05 (Rev A sub_11504)
ResetBench = $11546		; hockey93_03_05 (Rev A sub_1155E)
Setplass = $115A0		; hockey93_03_05
setplayer = $115BC		; hockey93_03_05 (Rev A sub_115D4)
SprSort = $127F8		; hockey93_06_11
resetplstuff = $1287A		; hockey93_06_11
PeriodOver = $12972		; hockey93_06_11 (Rev A loc_1298A)
box = $14E74			; hockey93_06_11
getname = $14EAE		; hockey93_06_11
linelist = $15466		; hockey93_06_11 (Rev A FaceOffsprites)
FaceOffMap = $33400		; graphics data (Rev A unk_3342E)
RefsMap = $38906		; graphics data (Rev A unk_3893C)
HotList = $743CE		; graphics data (Rev A $743FC)
FaceOffSprites = $77170	; graphics data (Rev A unk_771A6)
RAMStart = $FF0000	

; .region code
	org	$946E

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	logic93.asm
