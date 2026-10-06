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

; External routines and data outside $BC6C-$C9E9, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
clockcont_0 = $67C0		; hockey93_01
checkwindow = $9350		; hockey93_02 (Rev A sub_9368)
SetLCmode = $9648		; logic93_1 (Rev A loc_9660)
SetLCmode2 = $9670		; logic93_1 (Rev A showfaceoff, sub_9688)
lcfound = $9830			; logic93_1
burst = $9882			; logic93_1
Acheck = $98E2			; logic93_1
changeplayer = $9BC4		; logic93_1 (Rev A sub_9BDC)
SetShotMode = $9D24		; logic93_1 (Rev A loc_9D3C)
ShotMode = $9D6A		; logic93_1 (Rev A loc_9D82)
assnothing = $AA3E		; logic93_2
assgoalie = $B172		; logic93_3 (Rev A loc_B18A)
chkpk2 = $B94C			; logic93_3 (Rev A sub_B964)
ChkOffsides = $C9EA		; logic93_5
a2touchpuck = $CB34		; logic93_5
puckIChk = $CC2C		; logic93_5
puckunflip = $CC8E		; logic93_5 (Rev A puckunflip2)
findpc = $CD2C			; logic93_5 (Rev A sub_CD44)
skateto = $CDAE			; logic93_5
skatetopuckinit = $CF6E		; logic93_5
skatetopuck = $CF88		; logic93_5
assexit = $D02C			; logic93_5
assinsert = $D03E		; logic93_5
assreplace = $D048		; logic93_5
vtoa = $D05C			; logic93_5
GetHot = $D0C6			; logic93_5
SetSPA = $D120			; logic93_5
dirtab = $D5B2			; logic93_5
forceblack = $D67C		; middle93_1
randomd0 = $D7A6		; middle93_1
sfx = $D852			; middle93_1
song = $D876			; middle93_1 (Rev A SFX)
dobitmap = $DCE4		; middle93_2 (Rev A sub_DCFC)
DoDMA_clearCallbackPointer = $DD74	; middle93_2 (Rev A sub_DD8C)
eraser = $DFB8			; middle93_2
Framer = $DFF2			; middle93_2
printsmallz = $E070		; middle93_2 (Rev A printz2)
printz = $E1AE			; middle93_2
AddPenalty2 = $E552		; penalty93_1
Stop4Pen = $E8CE		; penalty93_1 (Rev A sub_E8E6)
PushRef = $EAD4			; penalty93_1
ClrHor = $EEFE			; penalty93_1 (Rev A sub_EF16)
printscores1 = $EFA8		; penalty93_2
getlinee = $F20E		; penalty93_2 (Rev A sub_F226)
PrintStringFromList = $F744	; penalty93_2 (Rev A sub_F75C)
checkpuckcoll = $10CAE		; hockey93_04
rtss = $110E0			; hockey93_05
forcepldata = $114EC		; hockey93_05 (Rev A sub_11504)
setpersonel = $1135C		; hockey93_05
ResetBench = $11546		; hockey93_05 (Rev A sub_1155E)
SprSort = $127F8		; hockey93_06
resetplstuff = $1287A		; hockey93_06
PeriodOver = $12972		; hockey93_06 (Rev A loc_1298A)
linelist = $15466		; hockey93_11 (Rev A FaceOffsprites)
FaceOffMap = $33400		; graphics data (Rev A unk_3342E)
RefsMap = $38906		; graphics data (Rev A unk_3893C)
FaceOffSprites = $77170	; graphics data (Rev A unk_771A6)

; .region code
	org	$BC6C

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	logic93_4.asm
