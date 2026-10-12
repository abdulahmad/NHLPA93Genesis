;	RAM map. This file names the work RAM variables, the hardware ports and the offsets inside
;	the game's structures. It holds equates only and adds nothing to the ROM.

;hardware
Asound	=	$c00011	;analog sound (VDP_PSG)
IO_CT1_CTRL	=	$A10008
IO_CT1_DATA	=	$A10002
IO_CT1_RX	=	$A1000E
IO_CT1_SMODE	=	$A10012
IO_CT1_TX	=	$A10010
IO_CT2_CTRL	=	$A1000A
IO_CT2_DATA	=	$A10004
IO_CT2_RX	=	$A10014
IO_CT2_SMODE	=	$A10018
IO_CT2_TX	=	$A10016
IO_EXT_CTRL	=	$A1000C
IO_EXT_DATA	=	$A10006
IO_EXT_RX	=	$A1001A
IO_EXT_SMODE	=	$A1001E
IO_EXT_TX	=	$A1001C
IO_FDC	=	$A12000
IO_PCBVER	=	$A10000
IO_RAMMODE	=	$A11000
IO_TIME	=	$A13000
IO_TMSS	=	$A14000
IO_Z80BUS	=	$A11100
IO_Z80RES	=	$A11200
VDP_CNTR	=	$C00008
VDP_CTRL	=	$C00004
VDP_DATA	=	$C00000
VDP_PSG	=	$C00011
VDP__CNTR	=	$C0000A
VDP__CTRL	=	$C00006
VDP__DATA	=	$C00002
VDP___CNTR	=	$C0000C
VDP____CNTR	=	$C0000E
Z80_RAM	=	$A00000	;Z80 RAM as seen from the 68000 (Z80_RAM+$8E is the PCM rate byte)
BackupRAM_Port	=	$200000	;serial backup RAM port: low byte bit 7 data, bit 6 clock
Joy1	=	$a10003	;controller ports
Joy2	=	$a10005

;VDP status register bits
PAL_MODE	=	0
DMA_IN_PROGRESS	=	1
HBLANKING	=	2
VBLANKING	=	3
ODD_FRAME	=	4
SPRITE_COLLISION	=	5
SPRITE_OVERFLOW	=	6
VBLANK_PENDING	=	7
FIFO_FULL	=	8
FIFO_EMPTY	=	9

refwidth	=	7	;width of ref.map frames
refheight	=	8	;height of ref.map frames

M68K_RAM	=	$FFFF0000	;start of RAM, also the start of the replay frames
replayend	=	$FFFFAF54	;end of replay ram (92 computed replaystart+(replaynum*replaysize))
GoalieStruct	=	$FFFFAFCA	;below varstart
varstart	=	$FFFFB000	;start of variable space (end of replay)
Stack	=	$FFFFFFFE	;game stack (Begin, StartPer, Opening2). 92 $fffffdf0
InitialSP	=	$FFFFF6	;reset vector 0. ($FFFFFFF6, the 32-bit form)
;$FFFFFFFF: not used

Sortobjs	=	16	;number of sorted graphics objects- these are arranged so sprites lower on the screen are of higher priority
SCstruct	=	$80	;ram for each sortobj
MaxPen	=	32

	RSSET	varstart
VSCRLPM	rs.w	1	;location in vram of scroll parameters
VSPRITES	rs.w	1	;location in vram of sprite attributes
VmMap1	rs.w	1	;location in vram of playfield 1
Map1col	rs.w	1	;2 to this power = width in char of playfield 1
VmMap2	rs.w	1	;location in vram of playfield 2
Map2col	rs.w	1	;2 to this power = width in char of playfield 2
VmMap3	rs.w	1	;location in vram of playfield 3
Map3col	rs.w	1	;2 to this power = width in char of playfield 3
BigFontChars	rs.w	1	;vram tiles for BigFont.map
smallfontchars	rs.w	1	;vram tiles for SmallFont.map
smallfont2chars	rs.w	1	;vram tiles for the 2nd small font set.
energybarchars	rs.w	1	;vram tiles for the energy bar (also logo / cup sprites on the title screens).
rinkvrcset	rs.w	1	;vram tiles for IceRink.map
animchars	rs.w	1
faceoffvrcset	rs.w	1	;vram tiles for FaceOff graphics
Framercset	rs.w	1	;vram tiles for framer.map
EASNcset	rs.w	1	;vram tiles for EASN.map
basetileoffset	rs.w	1
spritechars	rs.w	1	;vram tiles for the sprites.
ExtraChars	rs.w	1	;vram tiles for extra graphics
printx	rs.w	1	;x cordinate for printing
printy	rs.w	1	;y cordinate for printing
printa	rs.w	1	;attribute for print characters
printm	rs.w	1	;map to use (0 = map 1, 4 = map 2, 8 = map 3)
printfontset	rs.w	1	;printsmall char set (index*2 into smallfontchars).
fodropx	rs.w	1	;face off drop spot x/y
fodropy	rs.w	1
recbpr	rs.l	1
vbint	rs.l	1	;address of vblank interupt code
vcount	rs.w	1	;counter for vblank
oldvcount	rs.w	1
repeatdelayframes	rs.w	1
asv	rs.w	1	;analog sound volume (crowd noise)
lldisp	rs.w	1	;line level disp update counter
periodendtime	rs.w	1	;CheckLateGameSong trigger time.

;the following are equates for the sort object structure (SCstruct bytes each)
Xpos	=	$0
attribute	=	$4	;frame attribute switch bits
frame	=	$6	;alice frame number
oldframe	=	$8	;last frame
VRoffs	=	$A	;offsets to find each sprites start char. (max of 6 sprites / frame)
VRchar	=	$12	;vram char for graphic
Ypos	=	$14
Zpos	=	$18
OldXpos	=	$1C
OldYpos	=	$20
OldZpos	=	$24
Xvel	=	$28
Yvel	=	$2A
Zvel	=	$2C
impactp	=	$2E	;last player to cause impact
limpact	=	$30	;last impact value
impact	=	$32	;impact value
position	=	$34	;player's position (0=goalie,1=l.def,2=r.def,3=l.wing,4=center,5=r.wing)
assnum	=	$36	;index to current assignment
asslist	=	$38	;list of assignments in order of execution
temp1	=	$40
temp2	=	$42
temp3	=	$44
temp4	=	$46
temp5	=	$48
radiusx	=	$4A	;width of this graphic
radiusy	=	$4C	;height of this graphic
Wallcos	=	$4E	;cos of angle of last collision
Wallsin	=	$50	;sin of angle of last collision
SCnum	=	$52	;index number for this struct
facedir	=	$54	;direction of facing
SPA	=	$58	;animation
SPAnum	=	$5A	;index into animation
SPAcnt	=	$5C	;count down to next frame of animation
nopuck	=	$5E	;no puck coll until zero
newpos	=	$60	;requested next position of this player
newpnum	=	$61	;requested next player (from roster) for this player
pflags	=	$62
pfdoff	=	0	;bit0-deceleration off
pfna	=	1	;bit1-new assignment
pfnc	=	2	;bit2-no collision mode
pfjoycon	=	3	;is player joystick controlled
pfrev	=	4	;skating backwards
pfalock	=	5	;lock out until anim is done
pfteam	=	6	;0-home(sprite0-5)/1-visitors(sprite6-11)
pfgoal	=	7	;0=bottom, 1=top (to shoot at)
pflags2	=	$63
pf2fight	=	0	;player is fighting
pf2aip	=	1	;animation in progress wait
pf2unav	=	2	;player is unavailable (going to/from bench/penalty). 92 bit 4
pf2lcm	=	3	;line change mode. 92 bit 5
pf2pen	=	4	;player has caused a penalty. 92 bit 6
pf2npc	=	5	;no player collision. 92 bit 7
glitch	=	$65	;counter to eliminate quick frame changes (de-glitch graphics)
pnum	=	$66	;player's team location number 0-22
weight	=	$67
legstr	=	$68
legspd	=	$69
aioff	=	$6A
aidef	=	$6B
shotspd	=	$6C
shotacc	=	$6D
passacc	=	$6E
rostnum	=	$6F
spodds	=	$70
stickhand	=	$71
endurance	=	$72
handed	=	$76	;bit0 set is left handed. 92 $74
pflags3	=	$64
pf3oside	=	0	;player is offsides (offsides is now flagged per team in tmflags bit 4)
aggress	=	$73	;and offset
;sfx / song numbers
SFXsiren	=	$0
SFXbeep1	=	$1
SFXbeep2	=	$2
SFXwhistle	=	$3
SFXhorn	=	$4
SFXshotwiff	=	$5
SFXstdef	=	$6
SFXpuckget	=	$7
SFXoooh	=	$8
SFXhithigh	=	$9
SFXhitlow	=	$A
SFXcrowdcheer	=	$B
SFXcrowdboo	=	$C
SFX0D	=	$D
SFX0E	=	$E
SFXhomewin	=	$F
SFXpass	=	$10
SFXshotbh	=	$14
SFXshotfh	=	$18
SFXcheck	=	$1C
SFXplayerwall	=	$20
SFX21	=	$21
SFX22	=	$22
SFX23	=	$23
SFXpuckbody	=	$24
SFXpuckpost	=	$25
SFX26	=	$26
SFX27	=	$27
SFXpuckwall1	=	$28
SFXpuckice	=	$2C
SngTitle	=	$35
SngEOG	=	$36
SngScout	=	$37	;scouting report

;printsmall control codes (byte value = -(ControlCodeJumpTable entry); names match the ControlCode_* routines)
CC_SetMap	=	$FF	;-1: next byte = map number -> printm
CC_SetAttribute	=	$FE	;-2: next byte = palette/priority -> printa
CC_SetX	=	$FD	;-3: next byte = printx
CC_SetY	=	$FC	;-4: next byte = printy
CC_AddX	=	$FB	;-5: add next signed byte to printx
CC_AddY	=	$FA	;-6: add next signed byte to printy
CC_SetFont	=	$F9	;-7: next byte = char set index
CC_SetMapAndPosition	=	$F8	;-8: next 4 bytes = attribute, map, x, y
Vdata	=	VDP_DATA	;video ports
Vctrl	=	Vdata+4

SortCords	rs.b	Sortobjs*SCstruct
puckscnum	=	14	;puck is sort obj number 14
;$FFFFB066 is SortCords+$1C
;$FFFFB366 is SortCords+$31C
;$FFFFB6CA is SortCords+(13*SCstruct)
puckx	=	SortCords+(puckscnum*SCstruct)+Xpos
;$FFFFB74E is SortCords+(puckscnum*SCstruct)+attribute
pucky	=	SortCords+(puckscnum*SCstruct)+Ypos
puckz	=	SortCords+(puckscnum*SCstruct)+Zpos
puckvx	=	SortCords+(puckscnum*SCstruct)+Xvel
puckvy	=	SortCords+(puckscnum*SCstruct)+Yvel
puckvz	=	SortCords+(puckscnum*SCstruct)+Zvel
;$FFFFB78A is puckx+temp1
;$FFFFB7A8 is puckx+nopuck
puckc	=	SortCords+(puckscnum*SCstruct)+newpos
;$FFFFB7AD is puckx+pflags2
Ylist	rs.w	Sortobjs	;list of y cords for each sortobj
OOlistpos	rs.w	Sortobjs	;objects pos in OOlist
OOlist	rs.b	Sortobjs	;object order list for sort objs
crowdframe	rs.w	1	;current crowd frame number
crowdlevel	rs.w	1	;level of crowd excitement
crowdstep	rs.w	1	;animation step for crowd
crowdcnt	rs.w	1	;count down to next step.
CwdExciteLvl	rs.w	1
MaxCwdExciteLvl	rs.w	1	;peak crowd level.
NumCwdExciteLvl	rs.w	1	;crowd level sample count.
SumCwdExciteLvl	rs.l	1	;crowd level running total.
zamx	rs.w	1	;zamboni x cord
playoffspritex	rs.w	1	;logo sprite x (title / playoff screens).
playoffspritey	rs.w	1	;logo sprite y.
clampcounter	rs.w	1
DMAList	rs.l	2*140	;dma transfer list
DMAListend	rs.l	1
Vpos	rs.w	1	;ice rink vertical position
Oldrow	rs.w	1	;last row (used in vertical scrolling of the map data)
Hpos	rs.w	1	;ice rink horizontal position
Hscroll	rs.w	1	;horizontal scroll value
Vscroll	rs.w	1	;vertical scroll value
wcradiusx	rs.w	1	;variables used in wall collisions
wcradiusy	rs.w	1
palcount	rs.w	1	;counter for fading in color palettes
palfadenew	rs.w	16	;palettes to fade into
TitlePalBuffer	rs.w	16
palbuffer	rs.w	32	;to palfadenew+$80
;$FFFFBD6A is palfadenew+$42
;$FFFFBD82 is palfadenew+$5A
;$FFFFBDA2 is palfadenew+$7A
fofdata2	rs.l	2
;$FFFFBDAC is fofdata2+4
fofdata	rs.l	1	;data for frame/att of big face off sprites
pads	rs.w	42
ffosize	=	OldXpos	;field objects tied to icerink scrolling, OldXpos bytes each
CameraPosStruct	rs.w	11
replayactive	rs.w	3	;set by ReplayMode.
glovestruct	rs.w	14	;gloves object, pads+(4*ffosize).
PadControlBits	rs.w	1
padcont	rs.w	4
sso	rs.w	20
shotplayer	rs.w	1	;player who shot last
lastplayer	rs.w	1	;last player who touched puck
passdir	rs.w	1	;direction for pass/shot
passspeed	rs.w	1	;speed of pass/shot
passReceiverPlayerNum	rs.w	1
glovecords	rs.w	1	;cordinates of glove/sticks (fighting)
threat	rs.w	1	;direction of threat on puck handler
puckcross	rs.w	4	;xcord/frames top to bottom (for goalies to react to)
lj1	rs.w	1	;used in joystick debounce
lj2	rs.w	1
disflags	rs.w	1	;display flags
dfok	=	0	;graphics are ready for transfer
df32c	=	1	;32 column mode on
dfng	=	2	;don't int graphics
dfclock	=	3	;clock needs update
ltplayer	rs.w	1	;last touch player
ltx	rs.w	1	;last touch x cord
lty	rs.w	1	;last touch y cord
iflags	rs.b	1	;icing
icingPlayer	rs.b	5
clockram	rs.w	3	;ram for dma transfer of clock digits
xc1	rs.w	1	;scroll lock x cord
yc1	rs.w	1	;scroll lock y cord
yleader	rs.w	1	;lead distance on scrolling
fox	rs.w	1	;faceoff spot x/y
foy	rs.w	1
fodir1	rs.w	1	;pull directions for each player on face off
fodir2	rs.w	1
deltax	rs.w	1	;used lots of places for x/y stuff
deltay	rs.w	1
collflag	rs.w	1	;collision has occured
evalue	rs.w	1	;elasticity value (parameter of collisions)
mesarea	rs.w	1	;temp area for mes chars
TextBuffer	rs.w	49	;to mesarea+100
;$FFFFBED4 is mesarea+30
PushWidthBuf	rs.w	4	;PushNumberWidth string: length word, then digits.
;$FFFFBF1C is PushWidthBuf+2
PushNumberBuf	rs.w	1	;PushNumber builds its string down from here.
redrawicons	rs.w	1	;DrawLineIcons: last icon group drawn ($FF = redraw).
ltack	rs.w	1	;last tackle sound.
lastsfx	rs.w	1	;last sound played
Satt	rs.l	180	;sprite attribute table (for dma transfer
Sattsize	rs.w	1	;size of transfer
gmode	rs.w	1	;game mode flag
gmclock	=	0	;game clock is stopped
gmdir	=	1	;0 = home team goes up
gmpen	=	2	;penalty has been called
gmpendel	=	3	;delayed penalty has been called
gmhl	=	4	;hilight mode
gmoffs	=	5	;offsides on
sflags	rs.w	1
sfpz	=	0	;pause mode
sfpj	=	1	;pause cont (0 for cont 1)
sfspdir	=	2	;set pass dir mode
sfssdir	=	3	;set shot dir mode
sfwrap	=	4	;replay has wrapped around
sfscrl	=	5	;replay scroll is manual cont
sfslock	=	6	;scroll lock to xc1/yc1
sfhor	=	7	;screen is in horizontal mode
sflags2	rs.w	1
sf2faceoff	=	0	;face off in progress
sf2refref	=	1	;ref needs refresh
sf2drec	=	2	;disable replay record
sf2replay	=	3	;replay in progress
sf2shot	=	4	;shot was taken
sf2pwrplay	=	5	;power play in progress
sf2pwrtm	=	6	;0 for team 1 in power play
sf2offsig	=	7	;offsides little ref on
sflags3	rs.w	1
sf3llcs	=	0	;lower line change sel.
sf3rmplay	=	1	;play mode on for replay
sf3alttree	=	2	;alt. tree
sf3sbut	=	3	;flag for start button
c1playernum	rs.w	1	;player in control or neg for none
c2playernum	rs.w	1
cont1team	rs.w	1	;cont1 team 0=none 1=team1 2=team2
cont2team	rs.w	1
HomeTeam	rs.w	1	;number 0-24
VisTeam	rs.w	1
TeamBlockMap	rs.w	47	;map word buffer for CopyTeamBlockMapData and PutTeamBlock.
PenaltyBufferEnd	rs.w	1
PenBuf	rs.w	MaxPen+1	;upto x penalties saved
Pencntdwn	rs.w	1
Penaltytimer	rs.w	1
PBnum	rs.w	1	;$HV00 h=home players in pb
InjCntDown	rs.w	1
penmsgtimer	rs.w	1	;UpdatePA: reprint the horizontal penalty message line when this runs out.
RefCnt	rs.w	1	;ref graphics control
RefStep	rs.w	1
RefPen	rs.w	1
RefRamMap	rs.w	refwidth*refheight
gsp	rs.w	1	;game period
gameclock	rs.l	1	;game clock
PerTimeTotal	rs.w	1
ChkCnt	rs.w	1
TempPlOffset	rs.w	1
ScoreSumbytes	rs.w	1
ScoreSum	rs.w	90
PenSumLength	rs.w	1	;bytes used in PenSum (4 per penalty).
PenSum	rs.w	120	;penalty summary log, 4 bytes per penalty.

;team variables (hmtmstruct, awtmstruct = hmtmstruct+tmsize)
tmshots	=	$0	;shots stat
tmPwrGoals	=	$2	;power play goals stat
tmPwrPlays	=	$4	;power plays stat
tmPenalties	=	$6	;penalties stat
tmPenmin	=	$8	;penalty min. stat
tmATOP	=	$A	;attack time of possesion stat. 92 $C
tmscore	=	$C	;score. 92 $16
tmline	=	$16	;current line. 92 $18
tmdata	=	$1E	;team data address. 92 $E
tmsort	=	$22	;address of first sort obj. 92 $12 (long in 92)
tmap	=	$24	;active players on ice 4-6. 92 $1A
tmgoalie	=	$26	;goalie 1/2/none. 92 $1C
tmflags	=	$30	;flags. 92 $1E
tmpde	=	$32	;energy level of each roster player. 92 $20
tmpdst	=	$66	;-2=bench/-1=ice/0+=penalty box. 92 $54
tmsize	=	$1A2	;92 $88
tmstruct	rs.b	tmsize
;$FFFFC4FC is hmtmstruct+tmline
HomeTeamRosterPtr	=	tmstruct+tmdata
;$FFFFC50C is hmtmstruct+tmgoalie
;$FFFFC50E is hmtmstruct+tmgoalie+2
;$FFFFC516 is hmtmstruct+tmflags
;$FFFFC580 is hmtmstruct+$9A
;$FFFFC602 is hmtmstruct+$11C
awtmstruct	rs.b	tmsize
;$FFFFC69E is awtmstruct+tmline
AwayTeamRosterPtr	=	awtmstruct+tmdata
;$FFFFC6AE is awtmstruct+tmgoalie
;$FFFFC6B8 is awtmstruct+tmflags
;$FFFFC722 is awtmstruct+$9A
statsbuffer	rs.w	104

;game structure variables (one per playoff matchup)
gst1	=	$0	;team 1
gst2	=	$2	;team 2
gspotwins	=	$4	;play off top team (on tree) wins (for best of 7)
gspobwins	=	$6	;play off bottom team (on tree) wins (for best of 7)
gsper	=	$8	;period
gss1	=	$A	;team 1 score
gss2	=	$C	;team 2 score
gsflags	=	$E	;flags
gsftf	=	0	;teams are flipped
gsfhl	=	1	;hilite requested
gsfso	=	2	;series over
gssize	=	$10
gstruct	rs.b	gssize*8
gamenum	rs.w	1	;index for current game in game struct
postarts	rs.w	1	;0-31 for which playoff tree to use as frame
bosgames	rs.w	1	;0-6 game of series or 7 if not in best of seven
gamelevel	rs.w	1	;0-3 for the depth into the play off tree
potreeteam	rs.w	1	;which team you are on the intial playoff tree
pojoy	rs.w	1
WinBits	rs.w	1	;bits which indicat the continuing teams on the playoff tree
potree	rs.b	16+8+4+2+1+1	;team in the tree
PlList	rs.b	12	;list of players used differently
menuitem	rs.l	1	;menu state: selected item, then (+2) first item shown.
menulist	rs.l	1	;menu item list.
menudraw	rs.l	1	;menu screen draw routine.
TickerNum	rs.w	1
PPBonus	rs.b	1	;check bonuses, cleared together by clr.l.
PKBonus	rs.b	1
ThirdPBonus	rs.b	1
HmAwBonus	rs.b	1
callbackPtr	rs.l	1
DispAttribCtr	rs.w	1
VertLineScrolling	rs.w	1
PlayerScrollCtr	rs.w	1
SelectedPlayerIdx	rs.w	1
ScoutingReportTimer	rs.w	1
screentimer	rs.w	1	;frames left on a screen (ScoutingReport); last cursor row.
TestList	rs.w	122
nibblebuffer	rs.w	6	;UnpackNibbles words, WeightedRandomSelect weights.
;$FFFFCACE is nibblebuffer+4
OptPlayMode	rs.w	1	;play mode
OptNOP	rs.w	1
Opt1team	rs.w	1
Opt2team	rs.w	1
OptPerlen	rs.w	1	;period length index.
OptPen	rs.w	1	;penalties 1 for off
OptLine	rs.w	1	;line changes 0 for on
demoflag	rs.w	1	;demo flag
seed	rs.l	1
dmaram	rs.l	1	;dma ram area.
	IF REV=1
PalMode	rs.w	1	;Rev A only: VDP PAL bit (Begin). Set = 50 Hz: faster skating (updateplayers) and music (p_music_vblank)
music_tick_divider	rs.w	1	;Rev A only: p_music_vblank runs the track slots again every 6th frame
	ENDIF
databuffer	rs.w	9
pwddatabuffer	rs.w	5
outputbuffer	rs.w	49
marker	rs.w	1
tpassbits	rs.w	5	;temporary storage of passbits.
music_needs_z80_update	rs.w	1
Z80_command_buffer	rs.b	5
per_channel_attenuation_table	rs.b	7
per_channel_frequency_table	rs.w	7
per_channel_patch_table	rs.w	4
fm_voice_usage_table	rs.w	256
fm_channel_structs	rs.w	15
pcm_channel_struct	rs.w	3
fm_track_slots	rs.w	25
retrycount	rs.w	1
errorflag	rs.w	1
sramdataptr	rs.l	1
address	rs.l	1
byecount	rs.l	1
bytecount	rs.w	1
command	rs.w	1
bufferptr	rs.l	1
address2	rs.l	1
errorflag2	rs.w	1

