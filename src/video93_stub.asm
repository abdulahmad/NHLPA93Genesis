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
cramfade = $D6D6
sfx = $D852
jdtab = $DA70			; (movea.l operand)
DoDMA = $DA94
Vmaddr = $DCCA
rtss = $110E0
sizetab = $154BC		; (movea.l operand)
p_music_vblank = $166D4		; sound driver (jsr abs.l)
IceRinkMap = $33864		; graphics data (movea.l operand)
Sprites = $3A378		; graphics data (movea.l operand)
Spritetiles = $3A382		; graphics data (addi.l operand)
CrowdSprites = $748E2		; graphics data (movea.l operand)
FaceOffSprites = $77170		; graphics data (movea.l operand)
ZamSprites = $781E4		; graphics data (movea.l operand)
smallfontmap = $795B4		; graphics data (movea.l operand)
RAMStart = $FF0000	
; .region code
	org	$11802

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates

; Main segment code
	include	video93.asm
