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
cramfade = $D6D6		; middle93 (Rev A sub_D6EE)
sfx = $D852			; middle93
jdtab = $DA70			; middle93 (movea.l operand, Rev A $DA88)
DoDMA = $DA94			; middle93 (Rev A sub_DAAC)
Vmaddr = $DCCA			; middle93 (Rev A sub_DCE2)
rtss = $110E0			; hockey93_03_05
sizetab = $154BC		; hockey93_06_11 (movea.l operand, Rev A $154D4)
p_music_vblank = $166D4		; sound driver (jsr abs.l)
IceRinkMap = $33864		; graphics data (movea.l operand)
Sprites = $3A378		; graphics data (movea.l operand, Rev A $3A3A6)
Spritetiles = $3A382		; graphics data (addi.l operand, Rev A $3A3B0)
CrowdSprites = $748E2		; graphics data (movea.l operand)
FaceOffSprites = $77170		; graphics data (movea.l operand)
ZamSprites = $781E4		; graphics data (movea.l operand)
smallfontmap = $795B4		; graphics data (movea.l operand, Rev A unk_795E2)
RAMStart = $FF0000	
; .region code
	org	$11802

; includes for stubs to replace removed code
    include "ram93.asm"		;ports, RAM map and structure equates (92 ram.asm)

; Main segment code
	include	video93.asm
