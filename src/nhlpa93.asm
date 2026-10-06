;	nhlpa93.asm: full NHLPA Hockey 93 retail ROM ($000000-$07FFFF, 512 KB).
;	Built by build93.bat (npm run build:retail). hockey93.asm is the ROM map include list;
;	this file adds what each segment stub supplies for a single segment build (the shared
;	equates in stubinc\) and the $FF fill after checksum93 ($07FBC8-$07FFFF).
;	The incbins need npm run extractassets first (build:retail runs it).

    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

	include	hockey93.asm

;	Names that one segment (or the Main93 vectors) uses for a label another segment renamed.
;	A segment build gets these from its stub; each alias is the stub's retail address.
BusError	equ	AddError	;vector 2, $1500A. 93 has no BusError: bus and address error share AddError
Spurious	equ	IRQ7		;vectors $60-$6C, $7C, $1189E (rte)
HBlank		equ	IRQ7		;vector $70, $1189E
_sp		equ	IntermissionStart	;hockey93_01 stub _sp = $129B4
loc_14D36	equ	ShowInjuryBox	;hockey93_01 stub, $14D1E (Rev A $14D36)
loc_12A16	equ	ExitToOpening	;hockey93_01 stub, $129FE (Rev A $12A16)
loc_F0F6	equ	DrawEASNMap	;stats93 stub, $F0DE
DrawEASNLogo	equ	EASNLogo	;penalty93_1 stub, $F0CA
unk_15556	equ	PlayoffTreeSetup	;hockey93_06 stub, $1553E (Rev A $15556)
DisplayTeamBlock	equ	dotb	;hockey93_07 stub, $13F1C

	dcb.b	$80000-*,$FF		;$07FBC8-$07FFFF $FF fill
