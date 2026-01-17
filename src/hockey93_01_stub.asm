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

; Stack = $FFFFFE = $0
setupstanleycupcelebrationscreen = $0
backupram_read = $0
defaultmenus = $0
orjoy = $0
p_initialz80 = $0
p_turnoff = $0
p_music_vblank = $0
opening = $0
readjoy1 = $0
clearteamstats = $0
initscores = $0
setupice = $0
_sp = $0
randomd0 = $0
assreplace = $0
song = $0
demoread = $0
pausemode = $0
updateplayers = $0
checkwindow = $0
updatereplay = $0
setvideo = $0
penaltymanager = $0
updatesound = $0
rtss2 = $0
chkgoalies = $0
updatepwrplay = $0
loc_14d36 = $0
cd0 = $0
sfx = $0
freezewindow = $0
assinsert = $0
clearpenaltybuffer = $0
addpenalty2 = $0

;;	.region code
	org	$6446

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"


; External Functions
	include	hockey93_01.Asm		;EA provided code for startup and EA logo
