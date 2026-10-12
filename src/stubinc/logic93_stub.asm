;	Segment build for logic93.asm: defines the outside routines and data it uses as equates,
;	then includes logic93.asm on its own for checking against the ROM.

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

; frames93 animation and sprite-frame offsets (segment build does not include the frame data)
SPAgready = 2
SPAgglover = $166
SPAgglovel = $198
SPAgglovel2 = $1CA
SPAgstickr = $20C
SPAgstickl = $23E
SPAgstackr = $270
SPAgstackl = $2C2
SPAgdive = $314
SPAgswing = $386
SPAgskate = $3F8
SPApflip = $48A
SPAglide = $52C
SPAskatewp = $55E
SPAskate = $5F0
SPAturnl = $682
SPAturnr = $6B4
SPAstop = $6E6
SPApassf = $738
SPApassb = $7AA
SPAshotf = $81C
SPAshotb = $94E
SPAglideback = $A80
SPAskateback = $AB2
SPAsweepchk = $B44
SPAburst = $C7E
SPAHold = $CB0
SPAcelebrate = $EAA
SPApump = $F1C
SPAfight = $F8E
SPAfgrab = $FC0
SPAfheld = $FE2
SPAfhigh = $1004
SPAflow = $1036
SPAfhith = $1068
SPAfhitl = $108A
SPAffall = $10AC
SPAfinjury = $10CE
SPAwallright = $1128
SPAwallleft = $1166
SPAfaceoff = $11A4
SPAfaceoffr = $11CE
SPAstanley = $1258
SPAhook = $12DC
SPAstumble = $13A0
SPFfight = $162
SPFpuck = $18A

; .region code
	org	$946E

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	logic93.asm
