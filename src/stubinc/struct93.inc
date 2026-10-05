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
; Game struct (gstruct, one per playoff matchup, 8 of them). Same offsets as
; NHL92Genesis/src/ram.asm; hockey93_09 maketree / ReadPassBits use them.
gst1 equ 0
gst2 equ 2
gspotwins equ 4
gspobwins equ 6
gsper equ 8
gss1 equ $A
gss2 equ $C
gsflags equ $E
gssize equ $10
; Bit numbers from NHL92Genesis/src/ram.asm, used where a finished segment
; comment names the bit and the 93 bit number is the 92 value (see
; SEGMENT_AGENT.md "Bit names"). The flag word is whatever the 93 bytes use.
; 93 moved pflags2 bits are not defined here: 93 bit 2 is unavailable (92
; pf2unav = 4), bit 3 line change (92 pf2lcm = 5), bit 4 penalty (92 pf2pen
; = 6), bit 5 no player coll (92 pf2npc = 7).
; gmode
gmclock equ 0
gmdir equ 1
gmpen equ 2
gmpendel equ 3
gmhl equ 4
gmoffs equ 5
; sflags
sfpz equ 0
sfpj equ 1
sfspdir equ 2
sfssdir equ 3
sfwrap equ 4
sfscrl equ 5
sfslock equ 6
sfhor equ 7
; sflags2
sf2faceoff equ 0
sf2refref equ 1
sf2drec equ 2
sf2replay equ 3
sf2shot equ 4
sf2pwrplay equ 5
sf2pwrtm equ 6
sf2offsig equ 7
; sflags3
sf3llcs equ 0
sf3rmplay equ 1
sf3alttree equ 2
sf3sbut equ 3
; disflags
dfok equ 0
df32c equ 1
dfng equ 2
dfclock equ 3
; pflags
pfdoff equ 0
pfna equ 1
pfnc equ 2
pfjoycon equ 3
pfrev equ 4
pfalock equ 5
pfteam equ 6
pfgoal equ 7
; pflags2
pf2fight equ 0
pf2aip equ 1
; ----------------------------------
