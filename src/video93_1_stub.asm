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

; External routines outside $11802-$11D09, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; Every address was read from the retail bsr/bra/jsr displacement or operand.
cramfade = $D6D6		; middle93_1 (Rev A sub_D6EE)
sfx = $D852			; middle93_1
DoDMA = $DA94			; middle93_1 (Rev A sub_DAAC)
Vmaddr = $DCCA			; middle93_1 (Rev A sub_DCE2)
rtss = $110E0			; hockey93_05
showclock = $11D0A		; video93_2
checksso = $11DB4		; video93_2
setsortcords = $11ECA		; video93_2
setffo = $11EE8			; video93_2
p_music_vblank = $166D4		; sound driver (jsr abs.l)
IceRinkMap = $33864		; graphics data (movea.l operand)
FaceOffSprites = $77170		; graphics data (movea.l operand)
ZamSprites = $781E4		; graphics data (movea.l operand)
CrowdSprites = $748E2		; graphics data (movea.l operand)
; .region code
	org	$11802

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	video93_1.asm
