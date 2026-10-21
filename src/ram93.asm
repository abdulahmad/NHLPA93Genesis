;	RAM map. Names the work RAM variables, the hardware ports and the offsets inside the game's structures.
;	Equates only: it adds nothing to the ROM. Rev A adds PalMode/music_tick_divider.
;
;	Hardware ports, screen and sound constants, button bits and rink distances come first. Then the work RAM
;	map from M68K_RAM (the replay frame buffer up to varstart), then the variables allocated with rs
;	from varstart: video and print state, sort objects, flags, team and game structures, menu and sound state.

;video and sound ports
Asound	=	$c00011					;analog sound (PSG)
Vdata	=	$c00000					;video ports
Vctrl	=	Vdata+4					;video control port (Vdata+4)
VRAM_W	=	$40000000				;VDP command: VRAM write, address 0 (address bits 16-29 and 0-1)
CRAM_W	=	$C0000000				;VDP command: CRAM write, address 0
VSRAM_W	=	$40000010				;VDP command: VSRAM write, address 0
jimtiles	=	$A					;JIM graphics file header size: the tile data starts here
HVcount	=	$c00008					;Video port

;record and field offsets (names shared with 93S, 94G and 94S; docs/file-formats.md)
jimpalette	=	0					;container header: long, offset of the palette ($FFFFFFFF none)
jimdata		=	4					;long: offset of the map (.map.jim) or the frame table (.anim)
jimtilecount	=	8				;word: tile count (bit 15 packed); the tiles follow (jimtiles)
mapwidth	=	0					;map section: word width in tiles
mapheight	=	2					;word height in tiles
mapwords	=	4					;the map words
seX			=	0					;.anim sprite entry (8 bytes): word x, signed, from the frame origin
seY			=	2					;word y, signed
seTile		=	4					;word tile, from the set's first tile
seAttr		=	6					;word priority, palette, vflip, hflip (bits 15-11), size code (low byte)
seSize		=	7					;byte VDP size code (low byte of seAttr)
seLen		=	8
satY		=	0					;VDP sprite attribute entry (Satt, 8 bytes): word y + 128
satSize		=	2					;byte size code
satLink		=	3					;byte next sprite (0 ends the list)
satTile		=	4					;word priority, palette, flips, tile
satX		=	6					;word x + 128
satLen		=	8
sstime		=	0					;ScoreSum entry (6 bytes per goal): word period / time
ssflags		=	2					;byte 2 + skater difference (goal type); bit 7 = away team scored
ssscorer	=	3					;byte scorer
ssassist1	=	4					;byte first assist (negative none)
ssassist2	=	5					;byte second assist (negative none)
sssize		=	6
pstime		=	0					;PenSum entry (4 bytes per penalty): word period / time
pspen		=	2					;byte penalty (Penaltylist offset); bit 7 = away team
psplayer	=	3					;byte penalized player
pssize		=	4
pbpen		=	0					;PenBuf entry (2 bytes): penalty number (0 = free)
pbscnum		=	1					;SCnum of the player
pcx			=	0					;puckcross entry (4 bytes; entry 0 top, 1 bottom): word x
pcframes	=	2					;word frames
pcsize		=	4
foframe		=	0					;fofdata2, fofdata: 4 bytes per big faceoff sprite (2 centers, ref): frame
foattr		=	2					;word attribute (bit 11 x flip)
fosize		=	4
plpos		=	6					;PlList: 6 wanted roster players, then their positions

;hardware
IO_Z80BUS		=	$A11100			;Z80 bus request port ($100 requests the bus, 0 releases it)
IO_Z80RES		=	$A11200			;Z80 reset port (0 holds the Z80 in reset, $100 releases it)
Z80_RAM			=	$A00000			;Z80 RAM as seen from the 68000 (Z80_RAM+$8E is the PCM rate byte)
BackupRAM_Port	=	$200000			;serial backup RAM port: low byte bit 7 data, bit 6 clock
Joy1			=	$a10003			;controller ports
Joy2			=	$a10005			;controller port 2 data

MaxSprites	=	64					;max sprites during game (64 because 32 col mode)

refwidth	=	7					;width of ref.map frames
refheight	=	8					;height of ref.map frames

Stack	=	$FFFFFFFE				;game stack (Begin, StartPer, Opening2)
;$FFFFFFFF: not used

;joystick button equates (bit numbers)
ubut	=	0						;up
dbut	=	1						;down
lbut	=	2						;left
rbut	=	3						;right
bbut	=	4						;b button
cbut	=	5						;c button
abut	=	6						;a button
sbut	=	7						;start button
osflag	=	20000					;flag for off screen graphic ($4E20)

;sfx / song numbers
SngGoal			=	$30				;home goal tune (fmtune_goal)
SngPeriodStart	=	$31				;period start tune (fmtune_periodstart)
SngLateGame		=	$32				;late game tune, once in the 3rd period
									;(CheckLateGameSong, fmtune_lategame)
SngPP		=	$33					;home team power play tune (fmtune_powerplay)
SngFaceoff		=	$34				;face off tune, once per period (fmtune_faceoff)
SngTitle		=	$35				;title screen song (92 SngTitle)
SngEOP			=	$36				;plays at every period end and the end of the game (IntermissionStart), on
									;the playoff screen and when the highlights start (fmtune_eop). 92 had
									;SngEOP, SngEOG and SngPO for these
SngScouting		=	$37				;scouting report
SFXsiren		=	$0				;goal siren (92 SFXsiren)
SFXbeep1		=	$1				;short beep (92 SFXbeep1)
SFXbeep2		=	$2				;short beep, also the last minute warning when the clock reaches 60 (92
									;SFXbeep2)
SFXwhistle		=	$3				;referee whistle (92 SFXwhistle)
SFXhorn			=	$4				;horn at the end of a period (92 SFXhorn)
SFXshotwiff		=	$5				;whiff, a miss on a slap shot (92 SFXshotwiff)
SFXstdef		=	$6				;stick deflects the puck (92 SFXstdef)
SFXpuckget		=	$7				;puck pickup, the puck hits the ice on the face off (92 SFXpuckget)
SFXoooh			=	$8				;crowd oooh (92 SFXoooh)
SFXhithigh		=	$9				;fight punch (92 SFXhithigh)
SFXhitlow		=	$A				;fight punch at a different rate (92 SFXhitlow)
SFXcrowdcheer	=	$B				;crowd cheer (92 SFXcrowdcheer)
SFXcrowdboo		=	$C				;crowd boo (92 SFXcrowdboo)
SFXoooh2		=	$D				;second, lower crowd oooh: an injury, the visiting goalie making a save
SFXbglass		=	$E				;puck hits the glass over the wall (wallcollb):
									;glass bang with a crowd oooh
SFXhomewin		=	$F				;home team won: crowd roar with a short tune (song $F, played from
									;ShowThreeStars)
SFXpass			=	$10				;pass, 4 variants $10-$13 picked by puck height (92 SFXpass)
SFXshotbh		=	$14				;backhand shot, 4 variants $14-$17 (92 SFXshotbh)
SFXshotfh		=	$18				;forehand/slap shot, 4 variants $18-$1B (92 SFXshotfh)
SFXcheck		=	$1C				;body check, 4 variants $1C-$1F, never the same one twice in a row (92
									;SFXcheck; 92 had a second group, SFXcheck2)
SFXplayerwall	=	$20				;player hits the boards (92 SFXplayerwall)
SFXplayerwall2	=	$21				;player hits the boards, quieter (never played; same patches as
									;SFXplayerwall)
SFXplayerwall3	=	$22				;quieter again (never played)
SFXplayerwall4	=	$23				;quietest (never played)
SFXpuckbody		=	$24				;puck hits a player (92 SFXpuckbody)
SFXpuckpost		=	$25				;puck hits the goal post (92 SFXpuckpost)
SFX26			=	$26				;empty 4-byte stream, no sound (never played)
SFX27			=	$27				;same empty stream as SFX26 (never played)
SFXpuckwall1	=	$28				;puck hits the boards, loud (92 SFXpuckwall1, hitboard2). $28-$2B are one
									;sound at 4 volumes
SFXpuckwall2	=	$29				;medium (92 SFXpuckwall2, hitboard2volm)
SFXpuckwall3	=	$2A				;soft (92 SFXpuckwall3, hitboard2vols)
SFXpuckwall4	=	$2B				;softest (new in 93)
SFXpuckice		=	$2C				;puck bounces on the ice, 4 variants $2C-$2F by speed (92 SFXpuckice)
goalline		=	176				;distance from blue line to goalline
Blueline		=	$58				;distance from center line to blueline (92 kept it in a variable)
Sideline		=	$88				;distance from center to side boards (92 kept it in a variable)

replaystart		=	$FFFF0000		;start of ram area for replay frames, also the start of RAM
M68K_RAM		=	replaystart		;start of the 68000 work RAM, the same as replaystart
varstart		=	$FFFFB000		;start of variable space (end of replay)
GoalieStruct	=	$FFFFAFCA		;below varstart

replaysize	=	98					;number of bytes per replay frame (92 84)
replaynum	=	((varstart-replaystart)/replaysize)-1	;number of frames for replay
replayend	=	replaystart+(replaynum*replaysize)	;end of replay ram

Sortobjs	=	16					;number of sorted graphics objects- these are arranged so sprites lower on
									;the screen are of higher priority
scsize		=	7					;2 to this power indicates ram needed for each sortobj
SCstruct	=	1<<scsize			;ram for each sortobj
RAMSTART	=	varstart			;start of the variables, the same as varstart (92)
	RSSET	varstart				;variables from here on are allocated upwards from varstart with rs
VSCRLPM			rs.w	1			;location in vram of scroll parameters
VSPRITES		rs.w	1			;location in vram of sprite attributes
VmMAP1			rs.w	1			;location in vram of playfield 1
Map1col			rs.w	1			;2 to this power = width in char of playfield 1
VmMAP2			rs.w	1			;location in vram of playfield 2
Map2col			rs.w	1			;2 to this power = width in char of playfield 2
VmMAP3			rs.w	1			;location in vram of playfield 3
Map3col			rs.w	1			;2 to this power = width in char of playfield 3
BigFontchars	rs.w	1			;vram tiles for BigFont.map
smallfontchars	rs.w	1			;vram tiles for SmallFont.map
smallfont2chars	rs.w	1			;vram tiles for the 2nd small font set.
energybarchars	rs.w	1			;vram tiles for the energy bar (also logo / cup
									;sprites on the title screens).
rinkvrcset		rs.w	1			;vram tiles for IceRink.map
crowdvrcset		rs.w	1			;vram tiles for the crowd animation (also the Title3map sprites)
faceoffvrcset	rs.w	1			;vram tiles for FaceOff graphics
framercset		rs.w	1			;vram tiles for framer.map
EASNcset		rs.w	1			;vram tiles for EASN.map
basetileoffset	rs.w	1			;vram char of the home team block tiles; the visitor block is at +$18
									;(setupTeamBlocksMap)
spritechars		rs.w	1			;vram tiles for the sprites.
ExtraChars		rs.w	1			;vram tiles for extra graphics
printx			rs.w	1			;x cordinate for printing
printy			rs.w	1			;y cordinate for printing
printa			rs.w	1			;attribute for print characters
printm			rs.w	1			;map to use (0 = map 1, 4 = map 2, 8 = map 3)
printfontset	rs.w	1			;printsmall char set (index*2 into smallfontchars).
;printsmall control codes (byte value = -(ControlCodeJumpTable entry); names match the ControlCode_* routines)
CC_SetMap			=	$FF			;-1: next byte = map number -> printm
CC_SetAttribute		=	$FE			;-2: next byte = palette/priority -> printa
CC_SetX				=	$FD			;-3: next byte = printx
CC_SetY				=	$FC			;-4: next byte = printy
CC_AddX				=	$FB			;-5: add next signed byte to printx
CC_AddY				=	$FA			;-6: add next signed byte to printy
CC_SetFont			=	$F9			;-7: next byte = char set index
CC_SetMapAndPosition	=	$F8		;-8: next 4 bytes = attribute, map, x, y
fodropx				rs.w	1		;face off drop spot x/y
fodropy				rs.w	1		;face off drop spot y (see fodropx)
recbpr				rs.l	1		;replay record buffer pointer: the frame being recorded (92 recbpr)
VBint				rs.l	1		;address of vblank interupt code
Vcount				rs.w	1		;counter for vblank
OldVcount			rs.w	1		;Vcount at the last game frame: the frame loop waits d7 frames from it
repeatdelayframes	rs.w	1		;frames until the menu cursor repeats (first delay $F, then 4)
asv					rs.w	1		;analog sound volume (crowd noise)
lldisp				rs.w	1		;line level disp update counter
periodendtime		rs.w	1		;CheckLateGameSong trigger time.

;the following are equates for the sort object structure (SCstruct bytes each)

Xpos		=	$0					;x position (the first word of a sort object)
attribute	=	$4					;frame attribute switch bits
frame		=	$6					;alice frame number
oldframe	=	$8					;last frame
VRoffs		=	$A					;offsets to find each sprites start char. (max of 6 sprites / frame)
VRchar		=	$12					;vram char for graphic
Ypos		=	$14					;y position
Zpos		=	$18					;height above the ice
OldXpos		=	$1C					;x position before the last move
OldYpos		=	$20					;y position before the last move
OldZpos		=	$24					;height before the last move
rosxoff		=	OldXpos				;roster screen: sprite x offset from Xpos (slides -40..+40)
rosslide	=	OldZpos				;roster screen: slide counter, sets the x of the name block sprite
Xvel		=	$28					;x velocity
Yvel		=	$2A					;y velocity
Zvel		=	$2C					;z velocity (vertical)
impactp		=	$2E					;last player to cause impact
limpact		=	$30					;last impact value
impact		=	$32					;impact value
position	=	$34					;player's position (0=goalie,1=l.def,2=r.def,3=l.wing,4=center,5=r.wing)
assnum		=	$36					;index to current assignment
asslist		=	$38					;list of assignments in order of execution
temp1		=	$40					;scratch word; its meaning depends on the assignment (timers, targets)
temp2		=	$42					;scratch word (see temp1)
temp3		=	$44					;scratch word (see temp1)
temp4		=	$46					;scratch word (see temp1)
temp5		=	$48					;scratch word (see temp1)
radiusx		=	$4A					;width of this graphic
radiusy		=	$4C					;height of this graphic
Wallcos		=	$4E					;cos of angle of last collision
Wallsin		=	$50					;sin of angle of last collision
SCnum		=	$52					;index number for this struct
facedir		=	$54					;direction of facing
SPA			=	$58					;animation
SPAnum		=	$5A					;index into animation
SPAcnt		=	$5C					;count down to next frame of animation
SPAattr		=	$10					;SPA table: attribute word after the 8 direction offsets (bit 0 = loop)
nopuck		=	$5E					;no puck coll until zero
nopuckb		=	$5F					;second count down (low byte of nopuck)
newpos		=	$60					;requested next position of this player
newpnum		=	$61					;requested next player (from roster) for this player
pflags		=	$62					;player flags (pfdoff, pfna, pfnc, pfjoycon,
									;pfrev, pfalock, pfteam, pfgoal)
pfdoff		=	0					;bit0-deceleration off
pfna		=	1					;bit1-new assignment
pfnc		=	2					;bit2-no collision mode
pfjoycon	=	3					;is player joystick controlled
pfrev		=	4					;skating backwards
pfalock		=	5					;lock out until anim is done
pfteam		=	6					;0-home(sprite0-5)/1-visitors(sprite6-11)
pfgoal		=	7					;0=bottom, 1=top (to shoot at)
pflags2		=	$63					;player flags 2 (pf2fight, pf2aip, pf2unav,
									;pf2lcm, pf2pen, pf2npc, pf2inj)
pf2fight	=	0					;player is fighting
pf2aip		=	1					;animation in progress wait
pf2unav		=	2					;player is unavailable (going to/from bench/penalty). 92 bit 4
pf2lcm		=	3					;line change mode. 92 bit 5
pf2pen		=	4					;player has caused a penalty. 92 bit 6
pf2npc		=	5					;no player collision. 92 bit 7
pf2inj		=	6					;player is injured (SPAfinjury animation, max speed 1/8). 93 only
pflags3		=	$64					;player flags 3 (92 pf3oside; unused in 93, offsides is a team flag)
pf3oside	=	0					;player is offsides (offsides is now flagged per team in tmflags bit 4)
glitch		=	$65					;counter to eliminate quick frame changes (de-glitch graphics)
pnum		=	$66					;player's team location number 0-22
weight		=	$67					;player weight (collision oomph and checking)
legstr		=	$68					;leg strength (checking power)
legspd		=	$69					;leg speed (skating speed)
aioff		=	$6A					;offensive rating (CPU offense)
aidef		=	$6B					;defensive rating (CPU defense)
shotspd		=	$6C					;shot speed
shotacc		=	$6D					;shot accuracy (goalies: 92 GGSright)
passacc		=	$6E					;pass accuracy
rostnum		=	$6F					;roster number of the player
spodds		=	$70					;attribute byte set by setplayer (goalies: 92 GSSleft)
stickhand	=	$71					;stick handling (puck control and steal odds; goalies: 92 GGSleft)
endurance	=	$72					;endurance (how fast the energy runs out; goalies: 92 GSSright)
aggress		=	$73					;aggression: penalty odds (goalies: glove save left)
fighting	=	$74					;fighting rating (fight strength and fight odds)
checking	=	$75					;checking rating (check odds)
handed		=	$76					;bit0 set is left handed. 92 $74
SortCords	rs.b	Sortobjs*SCstruct	;the sort objects: 12 players, the puck and its shadow, 2 spare
										;(SCstruct bytes each)
puckscnum	=	14					;puck is sort obj number 14
puckx	=	SortCords+(puckscnum*SCstruct)+Xpos	;puck x position in its sort object
puckvx	=	SortCords+(puckscnum*SCstruct)+Xvel	;puck x velocity
pucky	=	SortCords+(puckscnum*SCstruct)+Ypos	;puck y position
puckvy	=	SortCords+(puckscnum*SCstruct)+Yvel	;puck y velocity
puckz	=	SortCords+(puckscnum*SCstruct)+Zpos	;puck height above the ice
puckvz	=	SortCords+(puckscnum*SCstruct)+Zvel	;puck z velocity
puckc	=	SortCords+(puckscnum*SCstruct)+newpos	;puck carrier: SCnum of the player with the puck (newpos
													;slot of the puck object), negative = loose
Ylist			rs.w	Sortobjs	;list of y cords for each sortobj
OOlistpos		rs.w	Sortobjs	;objects pos in OOlist
OOlist			rs.b	Sortobjs	;object order list for sort objs
Crowdframe		rs.w	1			;current crowd frame number
Crowdlevel		rs.w	1			;level of crowd excitement
Crowdstep		rs.w	1			;animation step for crowd
Crowdcnt		rs.w	1			;count down to next step.
CwdExciteLvl	rs.w	1			;crowd excitement level (starts at gamelevel*16, +$1E on an injury, +$28
									;on a goal; peaks tracked below)
MaxCwdExciteLvl	rs.w	1			;peak crowd level.
NumCwdExciteLvl	rs.w	1			;crowd level sample count.
SumCwdExciteLvl	rs.l	1			;crowd level running total.
Zamx			rs.w	1			;zamboni x cord
playoffspritex	rs.w	1			;logo sprite x (title / playoff screens).
playoffspritey	rs.w	1			;logo sprite y.
clampcounter	rs.w	1			;title screen: logo slide-in timer (RAM reused by the title screens)
DMAList			rs.l	2*140		;dma transfer list
DMAlistend		rs.l	1			;end of the DMA list: the address the next entry is written to
Vpos			rs.w	1			;ice rink vertical position
Oldrow			rs.w	1			;last row (used in vertical scrolling of the map data)
Hpos			rs.w	1			;ice rink horizontal position
Hscroll			rs.w	1			;horizontal scroll value
Vscroll			rs.w	1			;vertical scroll value
wcradiusx		rs.w	1			;variables used in wall collisions
wcradiusy		rs.w	1			;wall collision radius y (see wcradiusx)
palcount		rs.w	1			;counter for fading in color palettes
palfadenew		rs.w	16*4		;palettes to fade into (+$20 the title palette, +$40 palettes 2-3)
fofdata2	rs.l	2				;title screen: TitleAnimCallback timers; also the 2nd half of the face off
									;frame/attribute data (see fofdata)
fofdata				rs.l	1		;data for frame/att of big face off sprites
pads				rs.w	42		;face off objects tied to the rink scroll: the 3 pads and the centre ice
									;logo (ffo, ffosize bytes each; 92 pads = ffo)
ffosize				=	OldXpos		;field objects tied to icerink scrolling, OldXpos bytes each
CameraPosStruct		rs.w	11		;scroll camera: tracked object, target and the lead on the scroll
									;(UpdateCameraPos). Really 14 words: camtrack and camidle lie past
									;these 11 and overlap replayactive (camtrack is the replayactive word)
camtrack			=	$16			;camera struct: SCnum of the object tracked in replay (the struct
									;stands in for a sort object: Xpos/Ypos are its position)
camidle				=	$18			;camera struct: $FF while the replay d-pad is idle, cleared on scroll
									;or track (never read)
replayactive		rs.w	3		;set by ReplayMode.
glovestruct			rs.w	14		;gloves object, pads+(4*ffosize).
PadControlBits		rs.w	1		;pad assignment bits: $FFFF = no pad assignments (set at game setup); the
									;top 4 bits are masked and set around the camera and start-up code
padcont				rs.w	4		;pad assignment data (4 words), cleared together with PadControlBits
ffonum				=	5			;5 objects tied to icerink scrolling (3 pads + centre ice logo + gloves)
ssonum				=	2			;2 objects not tied to icerink scrolling (the 2 arrows for off screen
									;players; 92 had 4, with 2 scoreboard logos)
ssosize				=	Ypos		;bytes per sso object
Xcord				=	0			;x and y words at the start of an sso object (the defaultsprites sso
									;lists)
Ycord				=	2			;y word of an sso object
sso					rs.w	20		;screen objects not tied to the rink scroll: 2 arrows for off screen
									;players (92 had 4, with 2 scoreboard logos)
shotplayer			rs.w	1		;player who shot last
lastplayer			rs.w	1		;last player who touched puck
passdir				rs.w	1		;direction for pass/shot
passspeed			rs.w	1		;speed of pass/shot
passReceiverPlayerNum	rs.w	1	;SCnum of the intended receiver of the last pass, -1 = none (counts a
									;completed pass)
glovecords			rs.w	1		;cordinates of glove/sticks (fighting)
threat				rs.w	1		;direction of threat on puck handler
puckcross			rs.w	4		;xcord/frames top to bottom (for goalies to react to)
lj1					rs.w	1		;used in joystick debounce
lj2					rs.w	1		;joystick debounce for pad 2 (see lj1)
	IF REV=2
PadRaw1				rs.b	1		;Rev B: controller 1 as read by ReadPads in the vblank (active low)
PadRaw2				rs.b	1		;Rev B: controller 2 (ReadJoy1/ReadJoy2 only translate these)
	ENDIF
disflags			rs.w	1		;display flags
dfok				=	0			;graphics are ready for transfer
df32c				=	1			;32 column mode on
dfng				=	2			;don't int graphics
dfclock				=	3			;clock needs update
dffaceoff			=	4			;face off sprites on (92 tested sf2faceoff). 93 only
ltplayer			rs.w	1		;last touch player
ltx					rs.w	1		;last touch x cord
lty					rs.w	1		;last touch y cord
iflags				rs.b	1		;icing
ifcgl				=	0			;crossed goalline
ifdir				=	1			;1=must cross top line
ifok				=	2			;iflags: icing possible
icingPlayer			rs.b	5		;icing: the SCnum+1 of the last player to touch the puck (iflags+1), then
									;4 more bytes
jps					=	24			;jiffys per second
jiffy				=	$10000/jps	;one jiffy as a fraction of a second ($10000/jps)
clockram			rs.w	3		;ram for dma transfer of clock digits
xc1					rs.w	1		;scroll lock x cord
yc1					rs.w	1		;scroll lock y cord
yleader				rs.w	1		;lead distance on scrolling
fox					rs.w	1		;faceoff spot x/y
foy					rs.w	1		;face off spot y (see fox)
fodir1				rs.w	1		;pull directions for each player on face off
fodir2				rs.w	1		;pull direction for the visiting player on the face off (see fodir1)
deltax				rs.w	1		;used lots of places for x/y stuff
deltay				rs.w	1		;y difference, used in many places (see deltax)
collflag			rs.w	1		;collision has occured
evalue				rs.w	1		;elasticity value (parameter of collisions)
mesarea				rs.w	1		;temp area for mes chars
TextBuffer			rs.w	49		;to mesarea+100
PushWidthBuf	rs.w	4			;PushNumberWidth string: length word, then digits.
PushNumberBuf		rs.w	1		;PushNumber builds its string down from here.
redrawicons			rs.w	1		;DrawLineIcons: last icon group drawn ($FF = redraw).
ltack				rs.w	1		;last tackle sound.
lastsfx				rs.w	1		;last sound played
Satt				rs.l	180		;sprite attribute table (for dma transfer
Sattsize			rs.w	1		;size of transfer
gmode				rs.w	1		;game mode flag
gmclock				=	0			;game clock is stopped
gmdir				=	1			;0 = home team goes up
gmpen				=	2			;penalty has been called
gmpendel			=	3			;delayed penalty has been called
gmhl				=	4			;hilight mode
gmoffs				=	5			;offsides on
gmeog				=	6			;game over reached: the next face off goes to PeriodOver. 93 only (92
									;worked this out from gsp and the score)
gmstars				=	7			;the Stars of the Game box was already shown
									;(ShowThreeStars runs once). 93 only
sflags				rs.w	1		;game state flags (sfpz, sfpj, sfspdir, sfssdir, sfwrap, sfscrl, sfslock,
									;sfhor)
sfpz				=	0			;pause mode
sfpj				=	1			;pause cont (0 for cont 1)
sfspdir				=	2			;set pass dir mode
sfssdir				=	3			;set shot dir mode
sfwrap				=	4			;replay has wrapped around
sfscrl				=	5			;replay scroll is manual cont
sfslock				=	6			;scroll lock to xc1/yc1
sfhor				=	7			;screen is in horizontal mode
sflags2				rs.w	1		;game state flags 2 (sf2faceoff, sf2refref, sf2drec, sf2replay, sf2shot,
									;sf2pwrplay, sf2pwrtm, sf2offsig)
sf2faceoff			=	0			;face off in progress
sf2refref			=	1			;ref needs refresh
sf2drec				=	2			;disable replay record
sf2replay			=	3			;replay in progress
sf2shot				=	4			;shot was taken
sf2pwrplay			=	5			;power play in progress
sf2pwrtm			=	6			;0 for team 1 in power play
sf2offsig			=	7			;offsides little ref on
sflags3				rs.w	1		;game state flags 3 (sf3llcs, sf3rmplay, sf3alttree, sf3sbut, sf3fo,
									;sf3track, sf3icetime, sf3fosong)
sf3llcs				=	0			;lower line change sel.
sf3rmplay			=	1			;play mode on for replay
sf3alttree			=	2			;alt. tree
sf3sbut				=	3			;flag for start button
sf3fo				=	4			;face off just ended (set by the drop): the next puck pickup wins it, with
									;a crowd cheer. 93 only
sf3track			=	5			;the scroll window tracks an object. 93 only
sf3icetime			=	6			;set once a second by updatepentime: each player on the ice adds 1 to its
									;time on ice. 93 only
sf3fosong			=	7			;set for periods 1 and 2: play SngFaceoff once, at the first face off past
									;half the period with 60 s or more left. 93 only
c1playernum			rs.w	1		;player in control or neg for none
c2playernum			rs.w	1		;player controlled by pad 2, negative = none (see c1playernum)
cont1team			rs.w	1		;cont1 team 0=none 1=team1 2=team2
cont2team			rs.w	1		;team of controller 2: 0 = none (see cont1team)
HomeTeam			rs.w	1		;number 0-24
VisTeam				rs.w	1		;visiting team number (0-24, see HomeTeam)
TeamBlockMap		rs.w	47		;map word buffer for CopyTeamBlockMapData and PutTeamBlock.
PenaltyBufferEnd	rs.w	1		;the word before PenBuf: the end of the scoring summary, searched back to
									;find a player's penalty entry
MaxPen				=	32			;penalties kept in PenBuf

PenBuf			rs.w	MaxPen+1	;upto x penalties saved
PenCntDwn		rs.w	1			;frames until the penalty or stoppage message ends (fights 60, an injury
									;180)
Penaltytimer	rs.w	1			;counts down the second for the penalty clocks (jps frames)
PBnum			rs.w	1			;$HV00 h=home players in pb
InjCntDown		rs.w	1			;frames until the injury box is shown after an injury
penmsgtimer		rs.w	1			;UpdatePA: reprint the horizontal penalty message line when this runs out.
RefCnt			rs.w	1			;ref graphics control
RefStep			rs.w	1			;ref animation step: word offset into the ref frames, -1 = ref idle
RefPen			rs.w	1			;penalty number the ref is calling (4 = game over)
RefRamMap		rs.w	refwidth*refheight	;ref cam map words (refwidth x refheight)
gsp				rs.w	1			;game period
gameclock		rs.l	1			;game clock
PerTimeTotal	rs.w	1			;length of the period in seconds; the face off tune and the late game tune
									;key off it
ChkCnt			rs.w	1			;check counter for the player check stat (+1 per check, +3 if byte $74 of
									;the checker is 0)
TempPlOffset	rs.w	1			;roster offset of the player to print (bit 15 =
									;visiting team) for GetPlayerName
ScoreSumbytes	rs.w	1			;bytes used in ScoreSum (6 per goal)
ScoreSum		rs.w	90			;scoring summary: 6 bytes per goal (scorer, assists, time)
PenSumLength	rs.w	1			;bytes used in PenSum (4 per penalty).
PenSum			rs.w	120			;penalty summary log, 4 bytes per penalty.

;team variables (hmtmstruct, awtmstruct = hmtmstruct+tmsize)
tmshots		=	$0					;shots stat
tmPwrGoals	=	$2					;power play goals stat
tmPwrPlays	=	$4					;power plays stat
tmPenalties	=	$6					;penalties stat
tmPenmin	=	$8					;penalty min. stat
tmATOP		=	$A					;attack time of possesion stat. 92 $C
tmdata		=	$1E					;team data address. 92 $E
tmsort		=	$22					;address of first sort obj. 92 $12 (long in 92)
tmscore		=	$C					;score. 92 $16
tmline		=	$16					;current line. 92 $18
tmap		=	$24					;active players on ice 4-6. 92 $1A
tmgoalie	=	$26					;goalie 1/2/none. 92 $1C
tmflags		=	$30					;flags. 92 $1E
tmflcc		=	0					;line change on
tmflcm		=	1					;team is in line change mode (92 scanned the players for pf2lcm). 93 only
tmflast		=	3					;next touch overwrites the last touch only. 93 only
tmfoside	=	4					;team is offsides (92 flagged the player with pf3oside). 93 only
tmftimeout	=	2					;timeout used (the pause menu drops Timeout from then on). The same bit is
									;also tmfmid and tmfslide. 93 only
tmfmid		=	tmftimeout			;nearest player always takes the in-between spot (assnearest), so a team
									;that used its timeout does too
tmfslide	=	tmftimeout			;roster screen: the player name is sliding out (UpdateRosterPlayer)
tmrosstep	=	tmATOP				;roster screen: byte offset of the current RosterAnimScripts step
tmfowon		=	$E					;face-offs won stat
tmchecks	=	$10					;checks stat
tmpasses	=	$12					;passes stat
tmpasscomp	=	$14					;completed passes stat
tmtouch1	=	$18					;last touch (team/pnum word): the scorer
tmtouch2	=	$1A					;second last touch (first assist)
tmtouch3	=	$1C					;third last touch (second assist)
tmteam		=	$28					;team number (TeamList index) of this team struct
tmnear		=	$2A					;long: nearest skater's distance^2 to the puck (assnearest)
tmlcchoice	=	$2E					;line change box row chosen (0-2)
tmpde		=	$32					;energy level of each roster player. 92 $20
maxros		=	26					;roster slots per team
tmpdst		=	tmpde+(2*maxros)	;-2=bench/-1=ice/0+=penalty box. 92 $54
tmboxlist	=	tmpdst+(2*maxros)	;penalty box list of roster players (bytes, negative ends)
tmgoals		=	$B4					;goals per roster player (goalies: goals against), bytes
tmassists	=	tmgoals+maxros		;assists per roster player (bytes)
tmpshots	=	tmgoals+(2*maxros)	;shots per roster player (goalies: shots against), bytes
pchecks		=	$11C				;checks per roster player (bytes)
tmpice		=	$136				;frames on ice per roster player (words)
tmlines		=	$16A				;line sets copied from the team data (LineSets), 7 lines x 8 bytes
tmsize		=	$1A2				;92 $88
tmstruct	rs.b	tmsize			;home team structure (tmsize bytes)
HomeTeamRosterPtr	=	tmstruct+tmdata	;home team roster address (tmdata of the home team)
awtmstruct	rs.b	tmsize			;visiting team structure (tmstruct+tmsize)
AwayTeamRosterPtr	=	awtmstruct+tmdata	;visiting team roster address (tmdata of the visiting team)
statsbuffer	rs.w	104				;playoff team stat totals: $68 words summed from the stat bytes of the
									;team struct (+$B4)

;game structure variables (one per playoff matchup)
gst1				=	$0			;team 1
gst2				=	$2			;team 2
gspotwins			=	$4			;play off top team (on tree) wins (for best of 7)
gspobwins			=	$6			;play off bottom team (on tree) wins (for best of 7)
gsper				=	$8			;period
gss1				=	$A			;team 1 score
gss2				=	$C			;team 2 score
gsflags				=	$E			;flags
gsftf				=	0			;teams are flipped
gsfhl				=	1			;hilite requested
gsfso				=	2			;series over
gssize				=	$10			;bytes per game structure
gstruct				rs.b	gssize*8	;game structures: one per playoff matchup (8)
gamenum				rs.w	1		;index for current game in game struct
postarts			rs.w	1		;0-31 for which playoff tree to use as frame
bosgames			rs.w	1		;0-6 game of series or 7 if not in best of seven
gamelevel			rs.w	1		;0-3 for the depth into the play off tree
potreeteam			rs.w	1		;which team you are on the intial playoff tree
pojoy				rs.w	1		;playoff joystick indicator (92 pojoy)
WinBits				rs.w	1		;bits which indicat the continuing teams on the playoff tree
potree				rs.b	16+8+4+2+1+1	;team in the tree
PlList				rs.b	12		;list of players used differently
menuitem			rs.l	1		;menu state: selected item, then (+2) first item shown.
menulist			rs.l	1		;menu item list.
menudraw			rs.l	1		;menu screen draw routine.
TickerNum			rs.w	1		;intermission ticker: index of the game being shown, negative = no more
									;ticker games
PPBonus				rs.b	1		;check bonuses, cleared together by clr.l.
PKBonus				rs.b	1		;penalty kill bonus
ThirdPBonus			rs.b	1		;third period bonus (2 when tied or trailing with half or more of the
									;period left)
HmAwBonus			rs.b	1		;home / visitor bonus
callbackPtr			rs.l	1		;remap table for DecompressGraphicsWithCallback; 0 = plain DMA
DispAttribCtr		rs.w	1		;scouting report: scroll position (RAM shared with the stats screens)
VertLineScrolling	rs.w	1		;scouting report: text line being drawn, -1 = none (RAM shared with the
									;stats screens)
PlayerScrollCtr		rs.w	1		;scouting report: scroll step per frame (RAM
									;shared with the stats screens)
SelectedPlayerIdx	rs.w	1		;scouting report: index into TestList (RAM shared with the stats screens)
ScoutingReportTimer	rs.w	1		;scouting report: frames elapsed; the screen ends at $1000
screentimer			rs.w	1		;frames left on a screen (ScoutingReport); last cursor row.
TestList			rs.w	122		;scouting report: list of the lines to show (also the line editor cursor
									;and slots)
nibblebuffer		rs.w	6		;UnpackNibbles words, WeightedRandomSelect weights.
varend		=	nibblebuffer+8		;end of the variables cleared by Opening2. 92 had a varend
									;label after TickerNum
OptPlayMode	rs.w	1				;play mode
OptNOP		rs.w	1				;number of players (92 OptNOP)
Opt1team	rs.w	1				;team 1 (92 Opt1team)
Opt2team	rs.w	1				;team 2 (92 Opt2team)
Optperlen	rs.w	1				;period length index.
OptPen		rs.w	1				;penalties 1 for off
OptLine		rs.w	1				;line changes 0 for on
demoflag	rs.w	1				;demo flag
seed		rs.l	1				;seed for the random number generator (92 seed)
dmaram		rs.l	1				;dma ram area.
	IF REV>=1
PalMode				rs.w	1		;Rev A only: VDP PAL bit (Begin). Set = 50 Hz: faster skating
									;(updateplayers) and music (p_music_vblank)
music_tick_divider	rs.w	1		;Rev A only: p_music_vblank runs the track slots again every 6th frame
	ENDIF
databuffer			rs.w	9		;the saved block, 128 bytes (data + checksum; marker is its checksum byte)
passbits			rs.w	5		;playoff password bits (5 words; no checksum in 93)
outputbuffer		rs.w	49		;work buffer, also the shot data kept between games
marker				rs.w	1		;databuffer+126: not(sum) of the saved block
tpassbits			rs.w	5		;temporary storage of passbits.
music_needs_z80_update	rs.w	1	;nonzero when the Z80 must be sent the channel changes
Z80_command_buffer	rs.b	5		;key off/on, volume, frequency and patch bits for the Z80 (5 bytes)
per_channel_attenuation_table	rs.b	7	;FM channel attenuation (7 bytes, 6 FM + the DAC)
per_channel_frequency_table	rs.w	7	;FM channel frequency values (7 words)
per_channel_patch_table	rs.w	4	;FM channel patch numbers (4 words)
fm_voice_usage_table	rs.w	256	;which track slot uses each FM voice (256 words)
fm_channel_structs	rs.w	15		;FM channel state (15 words)
pcm_channel_struct	rs.w	3		;PCM (DAC) channel state (3 words)
fm_track_slots		rs.w	25		;track slots that play the sounds and songs (25 words)
retrycount			rs.w	1		;backup RAM retries left (10 at InitBackupRAM)
errorflag			rs.w	1		;backup RAM error count / flag (cleared at InitBackupRAM)
sramdataptr			rs.l	1		;pointer to the data being read or written in backup RAM
address				rs.l	1		;backup RAM address being accessed
byecount			rs.l	1		;backup RAM byte counter (long)
bytecount			rs.w	1		;backup RAM byte counter
command				rs.w	1		;backup RAM command byte being sent
bufferptr			rs.l	1		;backup RAM buffer pointer
address2			rs.l	1		;backup RAM second address
errorflag2			rs.w	1		;backup RAM second error flag

