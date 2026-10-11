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
updatecrowdf = $6710		; hockey93_01
HandleMenuInput = $6A4E		; menu93
PrintStringFromList = $F744	; penalty93
rtss = $110E0			; hockey93_03_05
vb2 = $1187E			; video93
setvideo = $118F2		; video93
bfasciicon = $1542A		; hockey93_06_11
play_sfx_or_music_track = $16608	; sound driver, no segment
Framermap = $33388		; graphics data, no segment
bigfontmap = $78CFE		; graphics data, no segment
smallfontmap = $795B4		; graphics data, no segment
Teamblocksmap = $7A376	; graphics data, no segment
RAMStart = $FF0000	

; .region code
	org	$D62A

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	middle93.asm
