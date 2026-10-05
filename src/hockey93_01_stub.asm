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

; External routines outside $6446-$69FF, at their retail addresses.
; Stack comes from stubinc/ram_addrs.inc ($FFFFFFFE).
setupstanleycupcelebrationscreen = $132BA
backupram_read = $163A4
defaultmenus = $14404
orjoy = $D958
p_initialz80 = $16D92
p_turnoff = $165D8
p_music_vblank = $166D4
opening = $12A0A
readjoy1 = $D9B6
clearteamstats = $128CC
initscores = $F436
setupice = $122A8
_sp = $129B4
randomd0 = $D7A6
assreplace = $D048
song = $D876
updateplayers = $9094
checkwindow = $9350
updatereplay = $8FAA
setvideo = $118F2
penaltymanager = $E5C4
updatesound = $12224
rtss2 = $9092
chkgoalies = $C242
updatepwrplay = $EE42
loc_14d36 = $14D1E	; IDA name; retail target is $14D1E
cd0 = $1510A
sfx = $D852
freezewindow = $933C
assinsert = $D03E
clearpenaltybuffer = $EC70
addpenalty2 = $E552
readjoy2 = $D9D4
loc_12a16 = $129FE	; IDA name; retail target is $129FE
forceblack = $D67C
pausetext = $1592A
pausetext2 = $15A56
getpzjoy = $8DB8
processinputwithrepeat = $D98E
clrhor = $EEFE
printscores1 = $EFA8
sethor = $EF3C
killcrowd = $1227E
printsmallz = $E070
eraser = $DFB8
initmenustate = $6A00	; menu93
handlemenuinput = $6A4E	; menu93
menuwaitvblank = $6BF4	; menu93

; .region code
	org	$6446

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_01.Asm		;EA provided code for startup and EA logo
