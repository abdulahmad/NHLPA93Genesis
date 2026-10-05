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

; External routines outside $1510A-$15FE5, at their retail addresses.
; Names are IDA names, or source names from the SEGMENT_AGENT.md rename table.
; This segment is data: every address is a dc.l operand read from the retail table bytes.
ShowScores = $6C0A		; stats93 (Rev A $6C18)
LineEditor = $6E08		; stats93 (Rev A $6E16)
DecodePlayerAttributes = $73B8	; stats93 (Rev A $73C6)
EncodePlayerAttributes = $7418	; stats93 (Rev A $7426)
TeamRosterScreen = $749C	; stats93 (Rev A $74AA)
ScoringSummaryScreen = $7992	; stats93 (Rev A $79A0)
PenaltySummaryScreen = $7C0C	; stats93 (Rev A $7C1A)
DisplayTeamStats = $7ED2	; stats93 (Rev A $7EE0)
PlayerStatsScreen = $7F04	; stats93 (Rev A $7F12)
GameStatisticsScreen = $849E	; stats93 (Rev A $84AC)
CrowdMeterScreen = $866C	; stats93 (Rev A $867A)
TimeoutMenu = $8894		; stats93 (Rev A $88A2)
SelectGoalieMenu = $88FC	; stats93 (Rev A $890A)
ReplayMode = $8AC4		; hockey93_02 (Rev A $8AD2)
assbench = $A0FC		; logic93_2
asseben = $A26C			; logic93_2
asspenalty = $A2DC		; logic93_2
assdopen = $A418		; logic93_2
assepen = $A43E			; logic93_2
assfaceoff = $A4CE		; logic93_2
assfaceoffp1 = $A4E4		; logic93_2
assfight = $A572		; logic93_2
assfwatch = $A9A0		; logic93_2
assstanley = $AA58		; logic93_2
assscore = $AAB0		; logic93_2
assdefo = $AB32			; logic93_2
assdefd = $ABF6			; logic93_2
asswingd = $AD98		; logic93_2
asswingo = $AE88		; logic93_3
asscenterd = $AFBC		; logic93_3
asscentero = $B056		; logic93_3
assgoalie = $B172		; logic93_3 (IDA loc_B18A)
assgoalietopuck = $B6E6		; logic93_3
asspuckc = $B76C		; logic93_3
assnearest = $BD02		; logic93_4
asspassrec = $BFAE		; logic93_4 (IDA loc_BFC6)
assshoot = $C010		; logic93_4 (IDA loc_C028)
pucknothing = $C044		; logic93_4 (Rev A listing puckunflip)
puckfaceoff = $C048		; logic93_4
puckfaceoff2 = $C426		; logic93_4
pucknorm = $C91A		; logic93_4
puckshadow = $CCD2		; logic93_5
rtss = $110E0			; hockey93_05 (Rev A $110F8)
InitTeamSructure = $12922	; hockey93_06 (Rev A $1293A)
; .region code
	org	$1510A

; includes for stubs to replace removed code
    include "stubinc/ports.inc"
    include "stubinc/equals.inc"
    include "stubinc/ram_addrs.inc"
    include "stubinc/struct93.inc"

; Main segment code
	include	hockey93_11.asm
