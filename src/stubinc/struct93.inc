; ------------- struct93 -------------
; SortCords sort object fields (SCstruct bytes each) and team struct fields.
; The SortCords values match NHL92Genesis/src/ram.asm except handed. Checked
; against the 93 puck equates in ram_addrs.inc: puckx =
; SortCords+14*SCstruct, pucky-puckx = Ypos, puckz-puckx = Zpos,
; puckvx-puckx = Xvel.
; The 92 name is the field; each equate holds the 93 value. Where 93 moved a
; field, the comment gives the 92 value. Every name below is used for that
; offset in a finished segment comment (see SEGMENT_AGENT.md "Names").
; 92 aggress is not defined: finished comments put it at $73, $74 and $75.
Xpos equ 0
attribute equ 4
frame equ 6
oldframe equ 8
VRoffs equ $A
VRchar equ $12
Ypos equ $14
Zpos equ $18
OldXpos equ $1C
OldYpos equ $20
OldZpos equ $24
Xvel equ $28
Yvel equ $2A
Zvel equ $2C
impactp equ $2E
limpact equ $30
impact equ $32
position equ $34
assnum equ $36
asslist equ $38
temp1 equ $40
temp2 equ $42
temp3 equ $44
temp4 equ $46
temp5 equ $48
radiusx equ $4A
radiusy equ $4C
Wallcos equ $4E
Wallsin equ $50
SCnum equ $52
facedir equ $54
SPA equ $58
SPAnum equ $5A
SPAcnt equ $5C
nopuck equ $5E
newpos equ $60
newpnum equ $61
pflags equ $62
pflags2 equ $63
glitch equ $65
pnum equ $66
weight equ $67
legstr equ $68
legspd equ $69
aioff equ $6A
aidef equ $6B
shotspd equ $6C
shotacc equ $6D
passacc equ $6E
rostnum equ $6F
spodds equ $70
stickhand equ $71
endurance equ $72
handed equ $76		;92 $74
SCstruct equ $80
; Team struct (hmtmstruct, awtmstruct = hmtmstruct+tmsize).
tmshots equ 0
tmPwrGoals equ 2
tmPwrPlays equ 4
tmPenalties equ 6
tmPenmin equ 8
tmATOP equ $A		;92 $C
tmscore equ $C		;92 $16
tmline equ $16		;92 $18
tmdata equ $1E		;92 $E
tmsort equ $22		;92 $12 (long in 92, word in 93)
tmap equ $24		;92 $1A
tmgoalie equ $26	;92 $1C
tmflags equ $30		;92 $1E
tmpde equ $32		;92 $20
tmpdst equ $66		;92 $54
tmsize equ $1A2		;92 $88
; ----------------------------------
