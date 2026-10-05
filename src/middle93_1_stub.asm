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

; External routines and data outside $D62A-$DCE3, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
updatecrowdf = $6710		; hockey93_01
HandleMenuInput = $6A4E		; menu93 (Rev A sub_6A5C)
rtss = $110E0			; hockey93_05
vb2 = $1187E			; video93_1 (Rev A loc_11896)
setvideo = $118F2		; video93_1 (Rev A sub_1190A)
play_sfx_or_music_track = $16608	; sound driver, no segment (Rev A sub_16620)

; .region code
	org	$D62A

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"

; Main segment code
	include	middle93_1.asm
