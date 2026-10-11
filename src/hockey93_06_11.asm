;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $122A8-$12E25
;	92 part 3, first half: setupice, defaultsprites, SprSort
;	resetplstuff, setteams, setplayercolors, PeriodOver, Opening, Opening2 and
;	PlayoffScreen, plus the 93 splits (setupice_highlight, setupIceRinkMap,
;	setupEASNmap, setupTeamBlocksMap, defaultsprites2, clearTeamStats,
;	InitTeamSructure) and the 93 playoff screen helpers. 92 SetSLogos and
;	SetTeamColors have no 93 counterpart here. ScoutingReport.
;Global names from the 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	92 bit names used in comments, same values in 93: disflags 0 dfok, 1 df32c,
;	2 dfng; sflags 0 sfpz, 1 sfpj, 7 sfhor; gmode 1 gmdir; pflags 6 pfteam,
;	7 pfgoal; pad bits lbut 2, rbut 3, sbut 7.
;	Object offsets, same as 92: Xpos 0, Ycord 2, attribute 4, frame 6,
;	oldframe 8, VRchar $12, Ypos $14, Zpos $18, asslist $38, radiusx $4A,
;	radiusy $4C, SCnum $52, nopuck $5E, pflags $62, pflags2 $63, pnum $66.
;	92 ffosize = $1C, ssosize = $14, SCstruct = $80, Sortobjs = 16.
;	Team struct offsets differ from 92: 93 tmdata $1E (92 $E), tmsort $22
;	(92 $12, long), tmsize $1A2 (92 $88).
;	DecompressGraphicsWithCallback is followed by its 8 byte remap table.

setupice	;set all variables, send non purgeable graphics, build sprite frame lists for ice rink.
	;Called from StartGame+42 and StartPer+A. 93 decompresses the tile sets with
	;DoDMA_clearCallbackPointer / DecompressGraphicsWithCallback (92 Buildframelist, DoDMA, ReMap)
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#df32c,(disflags).w
	move.w	#$C000,(VmMap2).w	;map 2 address
	move.w	#6,(Map2col).w		;map 2 width
	move.w	#$DC00,(VSPRITES).w	;sprites address
	move.w	#$E000,(VmMap1).w	;map 1 address
	move.w	#6,(Map1col).w		;map 1 width (same as 2 always)
	move.w	#$F000,(VmMap3).w	;map 3 address (92 $F800)
	move.w	#5,(Map3col).w		;map 3 width (dependent on df32c mode)
	move.w	#$FC00,(VSCRLPM).w	;horizontal scroll address (92 $0000, set first)
	moveq	#0,d0			;color to fade to
	bsr.w	setVram
	bclr	#sfpz,(sflags).w

	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w

	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w	;2000
	st	(zamx).w

	move.w	#$800,d0		;(92 $1000)
	move.w	(VmMap1).w,d1
	move.w	#$7FF,d2		;(92 moveq #1,d2)
	bsr.w	DoFill			;erase map 1

	clr.w	d4			;vram char 0 (92 started at 2)
	move.w	d4,(rinkvrcset).w	;1st vram char for rink map tiles
	movea.l	#IceRinkMap+8,a2
	bsr.w	DoDMA_clearCallbackPointer	;tiles to vram at d4, d4 advanced past them

	move.w	d4,(EASNcset).w		;1st vram char for easn logo tiles
	bsr.w	setupEASNmap

	move.w	d4,(energybarchars).w	;93: 1st vram char for the unk_7A2B8 tiles
	movea.l	#EnergyBarMap+8,a2
	bsr.w	DoDMA_clearCallbackPointer

	move.w	d4,(gamesetuptilesetindex).w	;1st vram char for crowd animation tiles (92 Crowdvrcset)
	movea.l	#CrowdSprites+8,a2
	bsr.w	DoDMA_clearCallbackPointer

	move.w	d4,(spritechars).w	;sprite char start, reused by setupice_highlight
	bsr.w	defaultsprites
	bsr.w	setupIceRinkMap		;transfer pal 0&1

	bsr.w	AddFramer		;93: Framer tiles (92 inline ReMap)
	move.w	d4,(smallfontchars).w	;1st vram char for smallfont tiles
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$43434567,$89ABCDEF	;remap table (92 .sfmap)
	move.w	d4,(BigFontChars).w	;1st vram char for Bigfont tiles
	movea.l	#BigFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$71234567,$89ABCDEF	;remap table (92 .bfmap)

	bsr.w	setupTeamBlocksMap	;93: team blocks for both teams (92 SetSLogos small logos)

	move.w	d4,(ExtraChars).w	;char space for extra graphics

	btst	#gmdir,(gmode).w
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0			;12 players
.l01	bchg	#pfgoal,pflags(a3)
	adda.w	#SCstruct,a3
	dbf	d0,.l01
.gok	bsr.w	setplayercolors		;(92 SetTeamColors, which falls into setplayercolors)

	move.w	#$FFFF,(PadControlBits).w	;93: no pad assignments
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	st	(c1playernum).w
	st	(c2playernum).w

	movea.w	#(DMAList-M68K_RAM),a5	;dump pad sprites so numbers
	movea.w	#(Satt-M68K_RAM),a6	;aren't written over later.
	moveq	#1,d6
	movea.w	#(pads-M68K_RAM),a3
	clr.w	d0
	clr.w	d1
	bsr.w	addframe2
	adda.w	#$1C,a3			;ffosize
	bsr.w	addframe2
	adda.w	#$1C,a3			;ffosize
	bsr.w	addframe2
	move.l	a5,(DMAListend).w
	bsr.w	DoDMAList

	move.w	(sp)+,(disflags).w	;(92 set palcount = 28 first; 93 does that in setupice_highlight only)

	move.l	#VBlank,(vbint).w
	bclr	#dfok,(disflags).w
	bclr	#dfng,(disflags).w
	move.w	#$2300,sr

	movem.l	(sp)+,d0-d7/a0-a6
	rts

setupice_highlight	;Rebuild the rink sprites after a highlight replay without reloading tiles, then fade in.
	;Called from StartHL2. Uses the sprite char start saved by setupice in spritechars
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
	bclr	#sfpz,(sflags).w
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w	;2000
	st	(zamx).w
	move.w	(spritechars).w,d4	;sprite char start from setupice
	bsr.w	defaultsprites
	bsr.w	setupIceRinkMap		;transfer pal 0&1
	btst	#gmdir,(gmode).w
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0			;12 players
.l01	bchg	#pfgoal,pflags(a3)
	adda.w	#SCstruct,a3
	dbf	d0,.l01
.gok	bsr.w	setplayercolors
	move.w	#$FFFF,(PadControlBits).w	;no pad assignments
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	st	(c1playernum).w
	st	(c2playernum).w
	bsr.w	setupEASNmap		;easn tiles at EASNcset again
	movea.w	#(DMAList-M68K_RAM),a5	;dump pad sprites
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6
	movea.w	#(pads-M68K_RAM),a3
	clr.w	d0
	clr.w	d1
	bsr.w	addframe2
	adda.w	#$1C,a3			;ffosize
	bsr.w	addframe2
	adda.w	#$1C,a3			;ffosize
	bsr.w	addframe2
	move.l	a5,(DMAListend).w
	bsr.w	DoDMAList
	move.w	#$1C,(palcount).w	;fade in new graphics now (92 setupice: 28)
	move.w	(sp)+,(disflags).w
	move.l	#VBlank,(vbint).w
	bclr	#dfok,(disflags).w
	bclr	#dfng,(disflags).w
	move.w	#$2300,sr
	movem.l	(sp)+,d0-d7/a0-a6
	rts				;(its only xref is a constant, so no label)

setupIceRinkMap	;copy the ice rink palettes (pal 0&1, 16 longs) to palfadenew. 92 setupice .ipal, split out in 93.
	;Called from setupice, setupice_highlight
	movea.l	#IceRinkMap,a0
	adda.l	(a0),a0			;palette offset in the map header
	moveq	#$F,d0
	movea.w	#(palfadenew-M68K_RAM),a1
.ipal	move.l	(a0)+,(a1)+
	dbf	d0,.ipal
	rts

setupEASNmap	;Decompress the easn logo tiles to vram at EASNcset. Called from setupice and setupice_highlight.
	;Return d4 = next free vram char
	move.w	(EASNcset).w,d4
	movea.l	#EASNmap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$71234567,$89ABCDEF	;remap table (92 .EASNmap)
	rts

setupTeamBlocksMap	;Load TeamBlocks.map tiles at d4+$30 and copy the home and visitor team blocks (24 rows each)
	;to vram at basetileoffset and basetileoffset+$18. Called from setupice. d4 = 1st vram char; return d4 = basetileoffset+$30
	move.w	d4,(basetileoffset).w
	addi.w	#$30,d4			;skip the 48 chars for the two team blocks
	movea.w	#(TeamBlockMap-M68K_RAM),a1	;map word buffer for CopyTeamBlockMapData
	movea.l	#TeamBlocksmap,a0
	lea	8(a0),a2
	bsr.w	DoDMA_clearCallbackPointer	;all team block tiles to vram at d4
	adda.l	4(a0),a0		;map data
	move.l	a0,-(sp)
	move.w	(HomeTeam).w,d0
	move.w	(basetileoffset).w,d1
	asl.w	#5,d1			;vram address of char
	bsr.w	CopyTeamBlockMapData
	movea.l	(sp)+,a0
	move.w	(VisTeam).w,d0
	move.w	(basetileoffset).w,d1
	addi.w	#$18,d1			;visitor block after the 24 home chars
	asl.w	#5,d1
	bsr.w	CopyTeamBlockMapData
	move.w	(basetileoffset).w,d4
	addi.w	#$30,d4
	rts

CopyTeamBlockMapData	;Copy one team's 24 block chars from the loaded tile set to vram at d1 by vram dma
	;and store their map words at (a1)+. a0 = map data, d0 = team, d1 = vram address. Called from setupTeamBlocksMap
	mulu.w	#$30,d0			;24 map words per team
	lea	4(a0,d0.w),a0
	moveq	#$17,d3			;24 chars
.row	moveq	#$20,d0			;32 bytes per char
	move.w	d1,-(sp)
	move.b	(a0),(a1)		;keep the map word flag bits
	andi.w	#$F800,(a1)
	lsr.w	#5,d1			;vram address back to char number
	ori.w	#$8000,d1		;priority
	or.w	d1,(a1)+
	move.w	(sp)+,d1
	move.w	(a0)+,d2
	andi.w	#$7FF,d2		;source char in the loaded tile set
	add.w	(basetileoffset).w,d2
	addi.w	#$30,d2
	asl.w	#5,d2			;source vram address
	bsr.w	DoDMA_nd2		;vram to vram copy
	addi.w	#$20,d1			;next char
	dbf	d3,.row
	rts

defaultsprites	;allocate vram and assign char area for graphic structures. d4 = char area for data.
	;Called from setupice and setupice_highlight. 93 splits off the SortCords half as defaultsprites2 (jumped to at the end)
	movea.l	#.listsso,a2
	movea.w	#(sso-M68K_RAM),a3
	moveq	#1,d0			;2 sso objects (92 ssonum = 4: 2 arrows + 2 scoreboard logos)
.ssotop	move.w	#$FFFF,oldframe(a3)		;screen objects not locked to scroll of screen
	move.w	(a2)+,(a3)		;Xcord
	move.w	(a2)+,2(a3)		;Ycord
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4		;vram char size (92 also kept it in VRsize)
	adda.w	#$14,a3			;ssosize
	dbf	d0,.ssotop

	movea.l	#.listffo,a2
	movea.l	#pads,a3		;ffo (first ffo is the pads)
	moveq	#4,d0			;ffonum-1
.ffotop	st	oldframe(a3)			;objects tied to screen scrolling (not players/net/puck)
	move.w	(a2)+,(a3)		;Xpos
	move.w	(a2)+,Ypos(a3)
	move.w	(a2)+,Zpos(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4		;vram char size
	adda.w	#$1C,a3			;ffosize
	dbf	d0,.ffotop
	bra.w	defaultsprites2

.listsso	;xcord,ycord,frame,attribute,vram char size
	dc.w	0,0,0,0,9
	dc.w	0,0,0,0,9

.listffo	;xcord,ycord,zpos,frame,attribute,vram char size
	dc.w	0,0,$FFFF,$188,0,7	;92 SPFpad+2 ($182)
	dc.w	0,0,$FFFF,$186,0,7	;92 SPFpad+0 ($180)
	dc.w	0,0,$FFFF,$187,0,7	;92 SPFpad+1 ($181)
	dc.w	0,0,$FFFF,$189,$8000,7	;92 SPFLogos, attribute 0, 12 chars
	dc.w	0,0,$FFFF,$161,0,5	;SPFgloves (92 same, $161)

defaultsprites2	;objects which are tied to screen scrolling and have velocity relative to icerink;
	;also set some variables in the structure to default settings. 92 defaultsprites .0, split out in 93.
	;Jumped to from defaultsprites, also called from setoptions. d4 = vram char; ends in SprSort
	clr.w	d6
	movea.w	#(OOlist-M68K_RAM),a1
	lea	.list(pc),a2
	movea.w	#(SortCords-M68K_RAM),a3
	movea.w	#(OOlistpos-M68K_RAM),a4
.0	moveq	#$1F,d0			;(SCstruct/4)-1
	movea.w	a3,a0
.1	clr.l	(a0)+
	dbf	d0,.1

	move.w	d6,SCnum(a3)
	st	oldframe(a3)
	st	pnum(a3)
	move.w	(a2)+,(a3)		;Xpos
	move.w	(a2)+,Ypos(a3)
	move.w	(a2)+,Zpos(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4		;vram char size
	move.w	(a2)+,radiusx(a3)
	move.w	(a2)+,radiusy(a3)
	addq.w	#1,a2
	move.b	(a2)+,asslist(a3)
	addq.w	#1,a2
	move.b	(a2)+,pflags(a3)

	adda.w	#SCstruct,a3
	asl.w	#1,d6
	move.b	d6,(a1)+		;OOlist seed
	lsr.w	#1,d6
	move.w	d6,(a4)+		;OOlistpos
	addq.w	#1,d6
	cmp.w	#$10,d6			;Sortobjs
	bne.s	.0
	bra.w	SprSort

.list	;xcord,ycord,zcord,frame,att,vrsize,radx,rady,asslist,pflags
	dc.w	$180,$C0,0,1,0,$14,8,4,0,$80	;home team, 1<<pfgoal (92 first player at -200,-120)
	dc.w	-$C8,-$64,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$50,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$3C,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$28,0,1,0,$14,8,4,0,$80
	dc.w	-$C8,-$14,0,1,0,$14,8,4,0,$80

	dc.w	$C0,$C0,0,1,1,$14,8,4,0,$40	;visitor team, 1<<pfteam (92 first player at -200,20)
	dc.w	-$C8,$28,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$3C,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$50,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$64,0,1,1,$14,8,4,0,$40
	dc.w	-$C8,$78,0,1,1,$14,8,4,0,$40

	dc.w	0,$10C,0,$195,0,$B,$14,6,0,0	;goal net (92 SPFgoal = $18E)
	dc.w	0,-$10C,0,$196,0,$11,$14,6,0,0

	dc.w	0,0,0,$18B,0,1,5,5,$18,1	;puck: pnorm, 1<<pfdoff (92 SPFpuck+1 = $184)
	dc.w	0,0,0,$18A,0,$11,3,3,$19,4	;puck shadow: pshad, 1<<pfnc (92 SPFpuck = $183, 4 chars)

SprSort	;sort objects in struct SortObj and set corresponding tables for keeping them sorted later
	movem.l	d0-d4/a0-a2,-(sp)
	movea.l	#OOlistpos,a2
	movea.l	#Ylist,a1
	movea.l	#SortCords,a0
	move.w	#$F,d3			;Sortobjs-1
.loop0	move.w	Ypos(a0),d4
	btst	#sfhor,(sflags).w
	beq.w	.l01
	move.w	(a0),d4			;Xpos
.l01	move.w	d4,(a1)+		;update ylist
	adda.w	#SCstruct,a0
	dbf	d3,.loop0

	movea.l	#Ylist,a1
.loop	clr.w	d4
	movea.l	#OOlist,a0
	move.w	#$E,d3			;Sortobjs-2
	clr.w	d0
	clr.w	d1
.0	move.b	(a0)+,d0		;object number *2
	move.b	(a0),d1
	move.w	(a1,d0.w),d2		;pos of sup lower sprite
	cmp.w	(a1,d1.w),d2
	ble.w	.1
	move.b	d0,(a0)
	move.b	d1,-1(a0)

	move.l	a0,d2
	subi.l	#OOlist,d2
	move.w	d2,(a2,d0.w)
	subq.w	#1,d2
	move.w	d2,(a2,d1.w)

	st	d4			;flag for incomplete sort
.1	dbf	d3,.0
	tst.w	d4
	bne.s	.loop
	movem.l	(sp)+,d0-d4/a0-a2
	rts

resetplstuff	;reset team variables/and players on both teams. Called from puckfaceoff2 and StartHL2
	movem.l	d0-d2/a0-a3,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	.top
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize
	bsr.w	.top
	movem.l	(sp)+,d0-d2/a0-a3
	rts

.top	bclr	#4,tmflags(a2)		;93: clear team flag bit 4
	moveq	#5,d2
	movea.w	tmsort(a2),a3
.loop	clr.b	pflags2(a3)			;pflags2 (92 also cleared pflags3)
	tst.w	position(a3)
	bmi.w	.next
	move.w	#$52C,d1		;SPAglide (92 $346)
	bsr.w	SetSPA
	clr.w	impact(a3)
	clr.b	nopuck(a3)			;93 clears a byte
	andi.b	#$C2,pflags(a3)		;keep pfteam, pfgoal, pfna in pflags
.next	adda.w	#SCstruct,a3
	dbf	d2,.loop
	rts

clearTeamStats	;the 92 setteams clear loop, split out. Clear both team structs (2 x tmsize) but keep the
	;word at tmstruct+$26 of each team, and set the byte at tmstruct+$9A of each. Falls into setteams.
	;Called from StartGame, StartHL2 and ScoutingReport
	move.w	(tmstruct+tmgoalie).w,-(sp)
	move.w	(awtmstruct+tmgoalie).w,-(sp)
	move.l	#tmsize-1,d0		;tmsize words = 2 x tmsize bytes (both team structs)
	movea.w	#(tmstruct-M68K_RAM),a0
.0	clr.w	(a0)+
	dbf	d0,.0
	move.w	(sp)+,(awtmstruct+tmgoalie).w
	move.w	(sp)+,(tmstruct+tmgoalie).w
	st	(tmstruct+$9A).w
	st	(awtmstruct+$9A).w

setteams	;use hometeam/visteam to set team structures. Falls in from clearTeamStats, also called.
	;93 sets tmsort as a word and leaves the team data setup to InitTeamSructure
	movem.l	d0/a0-a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(HomeTeam).w,d0
	move.w	#(SortCords-M68K_RAM),tmsort(a2)
	bsr.w	InitTeamSructure
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize
	move.w	(VisTeam).w,d0
	move.w	#(SortCords-M68K_RAM)+(6*SCstruct),tmsort(a2)
	bsr.w	InitTeamSructure
	movem.l	(sp)+,d0/a0-a2
	rts

InitTeamSructure	;Set up team struct a2 for team d0: store the team number at $28, the team data address
	;at tmdata ($1E, from the team address table at $314; 92 teamlist), and copy 14 longs of line data (team data +6
	;offset) to tmstruct+$16A. Called from setteams
	move.w	d0,$28(a2)
	movea.w	#$314,a0		;team address table
	asl.w	#2,d0
	move.l	(a0,d0.w),tmdata(a2)
	moveq	#$D,d0			;14 longs
	movea.l	tmdata(a2),a0
	adda.w	6(a0),a0		;lines offset in the team data
	lea	$16A(a2),a1
.copy	move.l	(a0)+,(a1)+
	dbf	d0,.copy
	rts

setplayercolors	;copy in correct color data for each team. Called from setupice, setupice_highlight, stats93 and
	;StartHL2
	clr.w	d1
	movea.w	#(tmstruct-M68K_RAM),a0
	bsr.w	.sp
	moveq	#$20,d1
	adda.w	#tmsize,a0

.sp	movea.l	tmdata(a0),a2
	adda.w	2(a2),a2		;Palettedata
	adda.w	d1,a2
	movea.w	#(palbuffer-M68K_RAM),a1	;92 palfadenew+$40 (same address)
	adda.w	d1,a1
	moveq	#7,d0
.5	move.l	(a2)+,(a1)+
	dbf	d0,.5
	rts

PeriodOver	;what to do if period over. Branched to from puckfaceoff when the clock runs out.
	;93 moves forceblack after the period count and drops the 92 SetHor / SetVideo / palcount
	addq.w	#1,(gsp).w		;period number
	bchg	#gmdir,(gmode).w
	cmpi.w	#3,(gsp).w
	blt.w	.0			;periods 1-2 done
	beq.w	.nop			;3rd period done
	move.w	#3,(gsp).w		;overtime done: stay at 3
	tst.w	(OptPlayMode).w
	bne.w	.nop			;playoffs: decided by the score check
	move.w	#4,(gsp).w		;regular season: game over after overtime
.nop	move.w	(tmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;visitor score
	beq.w	.0			;tied: play overtime
	move.w	#4,(gsp).w		;game over
.0	bsr.w	forceblack

IntermissionStart	;PeriodOver tail (92 PeriodOver.sp): reset the clock, song $36, ticker scores
	;playoff team stats at game over, then Intermission. Next period, or GameOver when gsp = 4.
	;Also jumped to from StartGame (as _sp) for the pregame intermission
	jsr	ResetClock
	move.w	#SngEOG,-(sp)		;song $36 (92 SngEOG = 3 here)
	bsr.w	song
	bsr.w	UpdateScores
	cmpi.w	#4,(gsp).w
	bne.w	.1			;not game over
	bsr.w	DisplayTeamStatsForPlayoffs
.1	bsr.w	Intermission
	cmpi.w	#4,(gsp).w
	beq.w	GameOver
	jmp	(StartPer).w

GameOver	;Save the password, show the playoff stats and playoff screen in playoff
	;mode, then song $35 and back to Opening2. Branched to from IntermissionStart
	bsr.w	EncodePW
	tst.w	(OptPlayMode).w
	beq.w	.po			;regular season
	bclr	#sfpj,(sflags).w
	jsr	(DisplayTeamStats).w	;"Playoff Stats"
.po	bsr.w	PlayoffScreen		;returns at once outside playoff mode

ExitToOpening	;Song $35, then restart at Opening2. Falls in from GameOver
	;also jumped to from HandleJoy1 (as loc_12A16) to end the demo
	move.w	#SngTitle,-(sp)		;(92 GameOver played no song)
	bsr.w	song
	bra.w	Opening2

Opening	;title screen, then into Opening2. Jumped to from Begin. Same as 92 REV A
	bsr.w	KillCrowd
	bsr.w	TitleScreen

Opening2	;reset the stack and clear the variables (92 REV A path), then options, playoff screen,
	;scouting report and on to a new game
	bsr.w	KillCrowd		;93 adds this
	move.w	#$2700,sr
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0	;varstart ($FFB000)
.0	clr.l	(a0)+
	cmpa.w	#$CAD2,a0		;varend (93 value)
	blt.s	.0
	move.l	#vb2,(vbint).w
	move.w	#$2500,sr
	bsr.w	setoptions
Opening3	bsr.w	PlayoffScreen
Opening4	bsr.w	ScoutingReport
	jmp	(ChkShortPeriods).w	;92 jmp startgame; 93 first checks pad 1 for short periods

PlayoffScreen	;bring up playoff screen if in playoff mode. Called from GameOver and Opening2.
	;93 runs its own vblank (PlayoffScreenDataTable) and scrolls the tree a page ($70 pixels) at a time.
	;Returns when start is pressed (PlayoffScreenExit)
	tst.w	(OptPlayMode).w
	beq.w	rtss

	move.l	#PlayoffScreenDataTable,(vbint).l	;(92 vb2)
	bclr	#df32c,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$BC00,(VSPRITES).w
	move.w	#$B000,(VmMap3).w
	move.w	#6,(Map3col).w
	move.w	#$C000,(VmMap2).w
	move.w	#7,(Map2col).w
	move.w	#$E000,(VmMap1).w
	move.w	#7,(Map1col).w		;128 col mode
	move.w	#0,d0			;fade to color
	bsr.w	setVram

	bsr.w	printz
	String	$FF,0,0			;(92 -$01,0,0)
	move.l	#$80,d0			;128 x 28
	moveq	#$1C,d1
	move.w	#$7FF,d2		;(92 moveq #1,d2)
	bsr.w	eraser

	bsr.w	printz
	String	$FD,0,0			;(92 -$03,0,0)
	moveq	#$28,d0			;40 x 2
	moveq	#2,d1
	move.w	#$7FF,d2
	bsr.w	eraser

	bsr.w	AddTeamBlock		;93: TeamBlocks tiles (92 did not load them here)
	bsr.w	AddSmallFont		;93: smallfont tiles (92 inline ReMap)

	movea.l	#Arrowsmap+8,a2
	move.w	d4,(ExtraChars).w
	bsr.w	DoDMA_clearCallbackPointer	;arrow tiles at ExtraChars

	bsr.w	printz
	String	$CE,0,0			;(92 -$01,60,4 before the StanleyMap bitmap)
	movea.l	#ScoutMap,a0		;bitmap map data
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2			;width and height from the map header
	move.w	2(a1),d3
	moveq	#3,d5
	bsr.w	dobitmap

	movea.l	#TitleLogoSprites,a1		;93: Titlemap2 palette to pal 0, tiles at energybarchars
	lea	8(a1),a2
	adda.l	(a1),a1
	moveq	#7,d0
	movea.w	#(palbuffer-M68K_RAM),a0
.pal	move.l	-$40(a0),$20(a0)	;pal 0 -> pal 3
	move.l	(a1)+,-$40(a0)		;Titlemap2 palette -> pal 0
	move.l	-$20(a0),(a0)+		;pal 1 -> pal 2
	dbf	d0,.pal
	move.w	d4,(energybarchars).w
	bsr.w	DoDMA_clearCallbackPointer

	move.w	#$104,(clampcounter).w	;93: RAM reused by this screen
	move.w	#$110,(playoffspritey).w

	movea.l	#VDP_CTRL,a0
	move.w	#$9202,(a0)		;window V position 2

	movea.w	#(potree-M68K_RAM),a1
	movea.l	#PlayoffTreeSetup,a0		;tree layout tables by gamelevel (92.setup, data)
	move.w	(gamelevel).w,d0
	asl.w	#1,d0
	adda.w	(a0,d0.w),a0
	clr.w	d4
	move.b	(a0)+,d4		;team count-1
.top	bsr.w	printz
	String	$FF,0,0
	move.b	(a0)+,(printx+1).w
	move.b	(a0)+,(printy+1).w
	clr.w	d1
	move.b	(a1)+,d1		;team from potree
	add.w	d1,d1
	bsr.w	DrawTeamBlocks		;92 .doteam
	dbf	d4,.top

	clr.w	d4
	move.b	(a0)+,d4		;arrow count-1
.top2	bsr.w	printz
	String	$FF,0,2			;(92 move #2,printy)
	move.b	(a0)+,(printx+1).w
	clr.w	d0
	move.b	(a0)+,d0
	bsr.w	DrawPlayoffBracket	;92 .doarrow
	dbf	d4,.top2

	bsr.w	printz
	String	$EF,0,0			;(92 -$11,0,0)
	cmpi.w	#7,(bosgames).w
	beq.w	.noscr
	clr.w	d4
	move.b	(a0)+,d4		;score count-1
	bmi.w	.noscr
	movea.w	#(gstruct-M68K_RAM),a2
.top3	move.b	(a0)+,(printx+1).w
	move.b	(a0)+,(printy+1).w
	bsr.w	FormatScore		;92 .doscores
	adda.w	#$10,a2			;gssize
	dbf	d4,.top3

.noscr	bsr.w	printsmallz		;93: round title (92 had the sharks message here)
	String	$F8,1,1,$41,$1A
	lea	PlayoffScreenText(pc),a1
	move.w	(gamelevel).w,d0
	bsr.w	AdvanceStringPtr	;a1 = string d0
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w		;center it
	bsr.w	printsmall
	tst.w	(gamelevel).w
	beq.w	.nopage			;one page only
	bsr.w	printz
	String	$CD,$A,1,'Press [ or ] to page'	;(92 .pli 4th string)
.nopage	move.w	#$18,(palcount).w	;24 ( in the string)
	move.w	#SngEOG,-(sp)		;song $36 (92 SngPO = 4)
	bsr.w	song

	clr.w	d0
	clr.w	d4
	move.w	#$FFFF,(PlayerScrollCtr).w	;scroll step (RAM shared with the stats screens)
	move.w	#1,(DispAttribCtr).w	;scroll position
	bsr.w	UpdatePlayoffScroll

.input	bsr.w	PlayoffScreen_waitvsync
	movea.l	#rtss,a0		;no animation callback
	bsr.w	CallAnimationCallback
	bsr.w	HandlePlayoffInput	;92 .jin
	bra.s	.input

HandlePlayoffInput	;read both pads: start leaves PlayoffScreen, right/left set the scroll step, then falls into
	;UpdatePlayoffScroll. Called from PlayoffScreen .input (92 PlayoffScreen .jin)
	bsr.w	Readjoy1
	move.w	d3,-(sp)
	bsr.w	Readjoy2
	or.w	(sp)+,d3		;either pad
	btst	#7,d3			;sbut
	bne.w	PlayoffScreenExit
	btst	#3,d3			;rbut
	beq.w	.nr
	move.w	#$FFFE,(PlayerScrollCtr).w	;step -2
.nr	btst	#2,d3			;lbut
	beq.w	UpdatePlayoffScroll
	move.w	#2,(PlayerScrollCtr).w	;step +2

UpdatePlayoffScroll	;move the tree one step (PlayerScrollCtr) and stop on a page boundary ($70). The position
	;(DispAttribCtr) is limited to +/- min(gamelevel,3) pages; the vblank adds it to the hscroll. Falls in from
	;HandlePlayoffInput, also called from PlayoffScreen
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss			;not scrolling
	add.w	(DispAttribCtr).w,d0
	move.w	(gamelevel).w,d1
	cmp.w	#3,d1
	bls.w	.lim
	moveq	#3,d1			;at most 3 pages each way
.lim	mulu.w	#$70,d1
	cmp.w	d1,d0
	bgt.w	rtss
	neg.w	d1
	cmp.w	d1,d0
	blt.w	rtss
	move.w	d0,(DispAttribCtr).w
	clr.w	(playoffspritex).w
	move.w	d0,d1
	addi.w	#$124,d1
	cmp.w	#$40,d1
	blt.w	.nox			;playoffspritex = position+$124 only inside $40-$200, else 0
	cmp.w	#$200,d1
	bgt.w	.nox
	move.w	d1,(playoffspritex).w
.nox	ext.l	d0
	divs.w	#$70,d0
	swap	d0			;remainder
	tst.w	d0
	bne.w	rtss			;not on a page yet
	clr.w	(PlayerScrollCtr).w	;stop
	rts

PlayoffScreenExit	;92 PlayoffScreen.exit: drop HandlePlayoffInput's return address and return
	;from PlayoffScreen. Branched to from HandlePlayoffInput on start, so it has to be global
	addq.w	#4,sp
	rts

PlayoffScreen_waitvsync	;each time palcount runs out, eor the color word at palbuffer+2 (palfadenew+$42) with $EE and
	;restart palcount at $18 (a color flash), then wait for the next vblank. Called from PlayoffScreen .input (92 used Waitxc1)
	tst.w	(palcount).w
	bpl.w	.wait			;palcount still counting
	eori.w	#$EE,(palfadenew+$42).w
	move.w	#$18,(palcount).w
.wait	move.w	(vcount).w,d0
	cmp.w	(oldvcount).w,d0
	beq.s	.wait
	move.w	d0,(oldvcount).w
	rts

FormatScore	;print best of 7 wins "t-b" for game struct a2 at printx/printy. 92 PlayoffScreen .doscores.
	;Called from PlayoffScreen .top3
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#6,(a1)+		;string length
	move.w	4(a2),d0		;gspotwins
	addi.w	#$30,d0			;'0'
	move.b	d0,(a1)+
	move.b	#$2D,(a1)+		;'-'
	move.w	6(a2),d0		;gspobwins
	addi.w	#$30,d0			;'0'
	move.b	d0,(a1)+
	clr.b	(a1)+
	movea.w	#(mesarea-M68K_RAM),a1
	bra.w	print

DrawPlayoffBracket	;draw tree arrow d0 from Arrows.map at printx/printy. 92 PlayoffScreen .doarrow.
	;Called from PlayoffScreen .top2
	movem.l	d0-d7/a0-a3,-(sp)
	movea.l	#ArrowsMap,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	4(a1),a1
	movea.w	#$310,a2		;(92 #null)
	clr.w	d1
	moveq	#2,d2
	moveq	#$17,d3			;23
	move.w	(ExtraChars).w,d4
	moveq	#0,d5			;(92 %0100)
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d7/a0-a3
	rts

DrawTeamBlocks	;draw team block d1 (team*2) from TeamBlocks.map at printx/printy; the user's team (potree entry
	;at potreeteam) gets printa $6000. 92 PlayoffScreen .doteam. Called from PlayoffScreen .top
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d0
	move.b	(a0,d0.w),d0
	add.b	d0,d0
	cmp.b	d0,d1
	bne.w	.nohi
	move.w	#$6000,(printa).w	;palette 3
.nohi	movea.l	#TeamBlocksmap,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2		;(92 #null)
	clr.w	d0
	move.w	(a1),d2			;(92 moveq #13,d2)
	moveq	#2,d3
	moveq	#2,d4
	moveq	#0,d5			;(92 %0010)
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d7/a0-a3
	rts

PlayoffScreenDataTable	;(it undecoded): the PlayoffScreen vblank handler (vbint).
	;If dfng is clear and Sattsize is set: clear Sattsize, DoDMA the sprite table (Satt) to VSPRITES, then
	;Vmaddr(VSCRLPM) and write $FEA0+DispAttribCtr to the hscroll, then cramfade. Always vcount+1, p_music_vblank, rte
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.nosat
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
	move.w	(VSCRLPM).w,d0
	bsr.w	Vmaddr
	move.w	#$FEA0,d0
	add.w	(DispAttribCtr).w,d0
	move.w	d0,(a0)
.nosat	bsr.w	cramfade
.nograph	addq.w	#1,(vcount).w
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
	rte

PlayoffScreenText	;round titles by gamelevel, printed with printsmall. Used by PlayoffScreen .noscr
	String	'Playoffs'
	String	'Quarterfinals'
	String	'Semifinals'
	String	'Finals'
	String	'Champions'

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $12E26-$13951
;	93 screens that follow 92 part 3: ScoutingReport (rewritten for 93
;	team ratings and a typed commentary), the Stanley Cup celebration screen,
;	TitleScreen with its credits scroller and vblank, the sprite list helpers
;	CallAnimationCallback / EndSpriteList / FinalizeSpriteList, and an
;	unreferenced sound test (CheckSound). setoptions.
;Global names from the 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	92 bit names used in comments, same values in 93: disflags 1 df32c, 2 dfng;
;	pad bits dbut 1, lbut 2, rbut 3, cbut 5, abut 6, sbut 7.
;	printz strings: first byte -$ab = map/attribute code (92 String -$01 = $FF),
;	then x, y. printsmallz codes: $F8 attribute,map,x,y; $F9 char set; $FC y; $FD x.
;	DecompressGraphicsWithCallback is followed by its 8 byte remap table.

ScoutingReport	;93 pregame scouting report (92 drew ScoutMap and position check marks). Called from PeriodOver.
	;Draws both team blocks, the Ron Barr picture and the scouting report ratings, then types out
	;the commentary paragraphs listed in TestList. Returns on start, or when screentimer runs out ($1E0 after the text ends)
	move.w	#SngScout,-(sp)		;song $37
	bsr.w	song
	move.l	#vb2,(vbint).w
	bsr.w	clearTeamStats		;93: (92 bsr SetTeams)
	bclr	#df32c,(disflags).w
	move.w	#6,(Map1col).w
	move.w	#6,(Map2col).w
	move.w	#0,d0			;fade to color
	bsr.w	setVram

	bsr.w	AddTeamBlock
	bsr.w	AddSmallFont
	move.w	d4,(smallfont2chars).w	;1st vram char of the 2nd small font set
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$0A234567,$89ABCDEF	;remap table (retail; / or.l)
	bsr.w	AddFramer

	bsr.w	printz
	String	$FE,0,0			;(92 -$02,0,0)
	movea.l	#ScoutMap,a0		;bitmap map data (same as PlayoffScreen)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2			;40 x 28
	moveq	#$1C,d3
	moveq	#3,d5			;color fam 1-2
	bsr.w	dobitmap

	bsr.w	printz
	String	$FE,6,3
	moveq	#$21,d0			;33 x 9 frame
	moveq	#9,d1
	bsr.w	Framer

	bsr.w	printz
	String	$FF,1,1
	movea.l	#Ronbarrmap,a0		;Ron Barr picture: palette offset, then map header offset
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0		;a0 = palette
	adda.l	(a2)+,a1		;a1 = map header
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2			;width and height from the map header
	move.w	2(a1),d3
	moveq	#$C,d5			;color fam 3-4
	bsr.w	dobitmap

	bsr.w	printz
	String	$FF,3,$D		;(92 -$01,3,6)
	move.w	(VisTeam).w,d1
	bsr.w	dotb	;92 DoTb

	bsr.w	printz
	String	$FF,$18,$D		;(92 -$01,24,6)
	move.w	(HomeTeam).w,d1
	bsr.w	dotb

	bsr.w	printsmallz
	String	CC_SetMapAndPosition,0,1,$15,$F,CC_SetFont,1	;attribute 0, map 1, x $15, y $F, char set 1
	lea	StatsText(pc),a1	;rating names (92 .pnm position names)
.pl	move.w	(a1),d0
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$15,d0			;center on column 21
	move.w	d0,(printx).w
	bsr.w	printsmall
	addq.w	#1,(printy).w
	eori.w	#2,(printfontset).w	;alternate char set each line
	tst.w	(a1)
	bpl.s	.pl			;-1 ends the list

	bsr.w	printsmallz
	String	CC_SetX,$1D,CC_SetY,$F,CC_SetFont	;x $1D, y $F, char set 0 (pad byte)
	movea.l	(HomeTeamRosterPtr).w,a0
	adda.w	8(a0),a0		;a0 = home scouting report bytes
	movea.l	(AwayTeamRosterPtr).w,a2
	adda.w	8(a2),a2		;a2 = away scouting report bytes
	bsr.w	DisplayPlayerStats	;home ratings at x $1D
	bsr.w	printsmallz
	String	CC_SetX,7,CC_SetY,$F,CC_SetFont	;x 7, y $F, char set 0 (pad byte)
	exg	a0,a2
	bsr.w	DisplayPlayerStats	;away ratings at x 7

	move.w	#$18,(palcount).w	;24
	move.l	#vb2,(vbint).w
	move	#$2500,sr

	bsr.w	InitScoutingDisplay	;a0 = TestList
	move.w	#$1A,(a0)+		;paragraph numbers into ScoutingReportText
	move.w	#$1B,(a0)+
	move.w	#$1D,(a0)+
	move.w	(HomeTeam).w,d0
	move.w	d0,(a0)+		;home team paragraph
	move.w	#$1D,(a0)+
	cmp.w	(VisTeam).w,d0
	beq.w	.same			;same team, one paragraph
	move.w	(VisTeam).w,(a0)+	;visiting team paragraph
.same	move.w	#$1D,(a0)+
	move.w	#$1C,(a0)+
	move.w	#$FFFF,(a0)		;end of list
	clr.w	(asv).w			;fast text flag
	move.w	#$7FFF,(screentimer).w	;frames left on the screen

.top	moveq	#0,d0
	bsr.w	waitx			;d1 = new presses
	btst	#7,d1			;sbut
	bne.w	rtss			;start leaves
	btst	#1,d1			;dbut
	beq.w	.upd
	st	(asv).w			;down: type the rest without delays
.upd	bsr.w	UpdateScoutingDisplay
	subq.w	#1,(screentimer).w
	bpl.s	.top
	rts

DisplayPlayerStats	;93: print the 8 rating nibbles of the scouting report long at 4(a0), one per line, at printx.
	;a0 = this team's scouting report, a2 = the other team's (for the combined line). Called from ScoutingReport
	move.l	4(a0),d5		;bytes 4-7: shooting/skating, passing/defense, checking/fighting, goalkeeping/overall
	moveq	#7,d6
.loop	eori.w	#2,(printfontset).w	;alternate char set each line
	rol.l	#4,d5			;next nibble
	move.w	d5,d0
	andi.w	#$F,d0
	bsr.w	PrintStatNumber
	cmp.w	#1,d6
	bne.w	.next
	bsr.w	DisplayCombinedStats	;after goalkeeping: power play and home team lines
.next	dbf	d6,.loop
	rts

DisplayCombinedStats	;93: print the power play line (byte 1 low nibble of a0 + byte 1 high nibble of a2), and on the right
	;column (printx >= $14) the home team line (byte 2 high nibble of a0 + low nibble of a2). Falls into PrintStatNumber
	eori.w	#2,(printfontset).w
	move.w	(a0),d0
	andi.w	#$F,d0
	move.w	(a2),d1
	lsr.w	#4,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bsr.w	PrintStatNumber
	eori.w	#2,(printfontset).w
	cmpi.w	#$14,(printx).w
	blt.w	StatNextLine		;left column: skip the home team line
	move.b	2(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	move.b	2(a2),d1
	andi.w	#$F,d1
	add.w	d1,d0

PrintStatNumber	;93: print d0 as a 2 digit number at printx/printy in the small font, then move down a line.
	;Called from DisplayPlayerStats, falls in from DisplayCombinedStats
	moveq	#2,d1			;2 digits
	bsr.w	PushNumberWidth
	move.w	(printx).w,-(sp)
	bsr.w	printsmall
	move.w	(sp)+,(printx).w
StatNextLine	;Next line; branched to from DisplayCombinedStats
	addq.w	#1,(printy).w
	rts

StatsText	;93: rating names for the scouting report, centered by ScoutingReport. -1 ends the list
	String	'Shooting'
	String	'Skating'
	String	'Passing'
	String	'Defense'
	String	'Checking'
	String	'Fighting'
	String	'Goalkeeping'
	String	'Power Play Adv.'
	String	'-    Home Team Adv.    '
	String	'Overall'
	dc.w	-1

InitScoutingDisplay	;93: reset the scouting text scroller. Return a0 = TestList (paragraph list). Called from ScoutingReport
	move.w	#$FFFF,(VertLineScrolling).w	;text line -1
	st	(PlayerScrollCtr).w	;negative: start the next paragraph
	clr.w	(SelectedPlayerIdx).w	;TestList index
	clr.w	(ScoutingReportTimer).w
	movea.w	#(TestList-M68K_RAM),a0
	rts

UpdateScoutingDisplay	;93: called every frame by ScoutingReport. When ScoutingReportTimer runs out (at once if asv
	;is set), print the next word of ScoutingReportText. '_' '{' '}' '[' ']' print a team or player name.
	;PlayerScrollCtr = offset of the next word (negative: next paragraph), DispAttribCtr = column
	cmpi.w	#$1000,(ScoutingReportTimer).w
	bgt.w	rtss			;text finished ($7FFF)
	tst.w	(asv).w
	bmi.w	.go			;fast: no delay
	subq.w	#1,(ScoutingReportTimer).w
	bpl.w	rtss
.go	movea.l	#ScoutingReportText,a1
	move.w	(PlayerScrollCtr).w,d0
	bpl.w	.cont			;in a paragraph
	clr.w	(DispAttribCtr).w	;column 0
	move.w	(SelectedPlayerIdx).w,d0
	addq.w	#2,(SelectedPlayerIdx).w
	movea.w	#(TestList-M68K_RAM),a0
	move.w	(a0,d0.w),d0		;next paragraph number
	bpl.w	.para
	move.w	#$7FFF,(ScoutingReportTimer).w	;end of list: stop typing
	move.w	#$1E0,(screentimer).w	;and leave the screen in 480 frames
	rts
.para	bsr.w	ScrollDisplayUp		;blank line between paragraphs
	movea.l	a1,a2
	bra.w	.cnt
.find	cmpi.b	#$D,(a2)+		;skip one $D ended paragraph
	bne.s	.find
.cnt	dbf	d0,.find
	suba.l	a1,a2
	move.w	a2,d0			;d0 = paragraph offset
.cont	lea	(a1,d0.w),a2
	move.w	#$A,(ScoutingReportTimer).w	;10 frames per word
	move.w	(DispAttribCtr).w,d0
	cmpi.b	#$5F,(a2)		;'_'
	beq.w	.under
	cmpi.b	#$7B,(a2)		;'{' home team name
	beq.w	.home
	cmpi.b	#$7D,(a2)		;'}' away team name
	beq.w	.away
	cmpi.b	#$5B,(a2)		;'[' home player name
	beq.w	.hmtm
	cmpi.b	#$5D,(a2)		;']' away player name
	beq.w	.awtm
	st	(PlayerScrollCtr).w	;assume end of paragraph
	movea.w	#(TextBuffer-M68K_RAM),a0
	clr.w	d1			;word length
.word	cmpi.b	#$D,(a2)
	beq.w	.eol			;end of paragraph
	addq.w	#1,d0
.copy	move.b	(a2),(a0)+		;copy the word and its trailing spaces
	addq.w	#1,d1
	cmpi.b	#$2C,(a2)		;','
	beq.w	.pause
	cmpi.b	#$2E,(a2)		;'.'
	bne.w	.nopause
.pause	addi.w	#$28,(ScoutingReportTimer).w	;40 more frames after punctuation
.nopause	cmpi.b	#$20,(a2)+
	bne.s	.word
	cmpi.b	#$20,(a2)
	beq.s	.copy
	subq.w	#1,d0
	suba.w	a1,a2
	move.w	a2,(PlayerScrollCtr).w	;offset of the next word
.eol	move.w	d1,(mesarea).w		;make a String at mesarea
	addq.w	#2,(mesarea).w
	btst	#0,d1
	beq.w	.even
	clr.b	(a0)			;pad
	addq.w	#1,(mesarea).w
.even	movea.w	#(mesarea-M68K_RAM),a1
.print	cmp.w	#$1D,d0			;past column 29?
	ble.w	.noscr
	bsr.w	ScrollDisplayUp		;wrap to a new line
.noscr	bsr.w	printz
	String	$FF,9,4
	move.w	(DispAttribCtr).w,d0
	add.w	d0,(printx).w		;x 9 + column
	move.w	(VertLineScrolling).w,d0
	add.w	d0,(printy).w		;y 4 + text line
	bsr.w	print
	add.w	d1,(DispAttribCtr).w
	rts
.awtm	movea.w	#(awtmstruct-M68K_RAM),a1
	bra.w	.team
.hmtm	movea.w	#(tmstruct-M68K_RAM),a1
.team	move.w	tmgoalie(a1),d1		;goalie's roster index
	movea.l	tmdata(a1),a1
	adda.w	(a1),a1			;player data
	bra.w	.pn
.pl	adda.w	(a1),a1			;skip name and 8 bytes of ratings
	addq.w	#8,a1
.pn	dbf	d1,.pl
	bra.w	.name
.away	movea.l	(AwayTeamRosterPtr).w,a1
	bra.w	.tname
.under	movea.l	#Montreal,a1		;team block
	cmpi.w	#$18,(tmstruct+tmgoalie+2).w
	bge.w	.tname			;used when >= $18
.home	movea.l	(HomeTeamRosterPtr).w,a1
.tname	adda.w	4(a1),a1		;team name
.name	addq.w	#1,(PlayerScrollCtr).w	;step past the escape char
	add.w	(a1),d0
	subq.w	#1,d0
	move.w	(a1),d1
	subq.w	#2,d1			;d1 = chars
	tst.b	1(a1,d1.w)
	bne.w	.print
	subq.w	#1,d1			;less the pad byte
	bra.w	.print

ScrollDisplayUp	;93: next text line for UpdateScoutingDisplay (column 0). After line 7, move the text box up
	;one row (DoDMA_nd2 copies 8 rows of $3A from VmMap1+$212, rows $80 apart) and stay on the last line
	clr.w	(DispAttribCtr).w
	addq.w	#1,(VertLineScrolling).w
	cmpi.w	#7,(VertLineScrolling).l
	blt.w	rtss
	subq.w	#1,(VertLineScrolling).w
	movem.l	d0-d3,-(sp)
	move.l	#7,d3
	move.w	(VmMap1).w,d1
	addi.w	#$212,d1		;text box top left
.loop	move.l	#$3A,d0
	move.w	d1,d2
	addi.w	#$80,d2			;from the row below
	bsr.w	DoDMA_nd2		;vram copy d2 -> d1
	move.w	d2,d1
	dbf	d3,.loop
	movem.l	(sp)+,d0-d3
	rts

SetupStanleyCupCelebrationScreen	;93: Stanley Cup screen. Five EASN bitmaps at StanleyCupPosTable with
	;StanleyMap sprites over them, $50 x 4 frames or until a button. Called from Begin+22
	move.l	#VBlank_StanleyCup,(vbint).l
	bclr	#df32c,(disflags).w
	move.w	#5,(Map3col).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d1
.clr	clr.l	(a0)+			;black palettes
	dbf	d1,.clr
	bsr.w	CopyPaletteToCRAM
	bsr.w	setVram_0

	bsr.w	printz
	String	$FE,0,0			;(the lea in this string)
	lea	StanleyCupPosTable(pc),a4
.top	move.w	(a4)+,(printx).w
	move.w	(a4)+,(printy).w
	movea.l	#EASNmap2,a0
	movea.l	a0,a1
	adda.l	(a0),a0			;palette
	adda.l	4(a1),a1		;map header
	movea.w	#$310,a2		;a zero word (92 passed #null): no tiles
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d4
	moveq	#$F,d5			;color fam 1-4
	bsr.w	dobitmap
	tst.w	(a4)
	bpl.s	.top
	movea.l	#EASNmap2+8,a2
	clr.w	d4			;tiles at vram char 0
	bsr.w	DoDMA_clearCallbackPointer
	movea.l	#Stanleymap+8,a2
	move.w	d4,(energybarchars).w	;1st vram char of the cup sprites
	bsr.w	DoDMA_clearCallbackPointer
	bsr.w	UpdateStanleyCupAnimation
	move.w	#$18,(palcount).w	;24
	move	#$2500,sr
	move.w	#$50,(seed).w
.wait	moveq	#4,d0
	bsr.w	waitx
	tst.w	d1
	bne.w	.ex			;any button
	bsr.w	UpdateStanleyCupAnimation
	subq.w	#1,(seed).w
	bpl.s	.wait
.ex	move	#$2700,sr
	rts

UpdateStanleyCupAnimation	;93: one StanleyMap sprite at each StanleyCupPosTable spot, frame 1 + asv (0-7), then
	;close the sprite list. Called from SetupStanleyCupCelebrationScreen
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6			;link counter
	addq.w	#1,(asv).w
	andi.w	#7,(asv).w
	movea.l	#StanleyMap,a0
	lea	StanleyCupPosTable(pc),a4
	move.w	(energybarchars).w,d3
.top	move.w	(a4)+,d0
	asl.w	#3,d0
	addi.w	#$58,d0			;x = column * 8 + $58
	move.w	(a4)+,d1
	asl.w	#3,d1
	addi.w	#$38,d1			;y = row * 8 + $38
	moveq	#1,d2
	add.w	(asv).w,d2
	bsr.w	SetSframe
	tst.w	(a4)
	bpl.s	.top
	bra.w	EndSpriteList

VBlank_StanleyCup	;93: vbint handler for the Stanley Cup screen: sprite table dma, cramfade, vcount
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.x
	move.w	(Sattsize).w,d0
	beq.w	.nos
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	movea.w	#(Satt-M68K_RAM),a0
	bsr.w	DoDMA
.nos	bsr.w	cramfade
.x	addq.w	#1,(vcount).w
	movem.l	(sp)+,d0-d7/a0-a6
	rte

StanleyCupPosTable	;93: column, row of the five Stanley Cup bitmaps and sprites. -1 ends
	dc.w	3,1
	dc.w	$1C,1
	dc.w	$10,9
	dc.w	3,$12
	dc.w	$1C,$12
	dc.w	-1

TitleScreen	;bring up title screen and credits. Called from PeriodOver.
	;93: Titlemap backdrop, three Title3map sprites, Titlemap2 logo sprites, scrolling credits. Start leaves
	move.w	#SngTitle,-(sp)		;song $35 (92 SngTitle = 1)
	bsr.w	song
	move.w	(VDP_CNTR).l,(seed).w	;seed randomd0 from the H/V counter
	move.w	(VDP_CNTR).l,(seed+2).w
	move.l	#VBlank_TitleScreen,(vbint).l
	bset	#df32c,(disflags).w
	move.w	#5,(Map3col).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	move.w	#0,d0			;fade to color
	bsr.w	setVram
	movea.l	#VDP_DATA,a0
	move.w	#$9100,4(a0)		;window h position 0
	move.w	#$9216,4(a0)		;window v position 22 (92 $9200+22)
	move.w	#$8B03,4(a0)		;h scroll by line
	clr.w	(Vscroll).w

	bsr.w	printz
	String	$FF,0,0			;(92 -$01,0,0)
	move.l	#$80,d0			;128 x 32
	moveq	#$20,d1
	move.l	#$7FF,d2		;(92 moveq #1,d2)
	bsr.w	eraser

	bsr.w	printz
	String	$FE,0,0
	move.l	#$80,d0
	moveq	#$20,d1
	move.l	#$7FF,d2
	bsr.w	eraser

	clr.w	d4
	bsr.w	printz
	String	$FE,0,$16
	movea.l	#Title1Map,a1		;rows $16 down of Titlemap, map only
	adda.l	4(a1),a1
	movea.w	#$310,a2		;a zero word (92 passed #null): no tiles
	clr.w	d0
	moveq	#$16,d1
	move.w	(a1),d2
	move.w	2(a1),d3
	sub.w	d1,d3
	moveq	#0,d5			;no palettes
	bsr.w	dobitmap

	bsr.w	printz
	String	$FD,0,0			;(92 -$02,0,0 Title1Map)
	movea.l	#Title1Map,a0		;whole Titlemap with palettes (retail; Rev A)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#$F,d5			;color fam 1-4
	bsr.w	dobitmap

	clr.w	(palfadenew).w
	moveq	#4,d0
	bsr.w	randomd0
	asl.w	#5,d0
	lea	TitleData2(pc),a1	;one of 4 random palettes
	adda.w	d0,a1
	movea.w	#(titleScreenState-M68K_RAM),a0
	moveq	#7,d0
.tops0	move.l	(a1)+,(a0)+
	dbf	d0,.tops0

	bsr.w	printz
	String	$FE,0,$A
	movea.l	#Title2Map,a1		;bitmap
	lea	8(a1),a2
	adda.l	4(a1),a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#0,d5			;no palettes
	bsr.w	dobitmap

	movea.l	#TitleLogoSprites+8,a2
	move.w	d4,(energybarchars).w	;1st vram char of the logo sprites
	bsr.w	DoDMA_clearCallbackPointer
	movea.l	#Title3Sprites+8,a2
	move.w	d4,(gamesetuptilesetindex).w	;1st vram char of the Title3map sprites
	bsr.w	DoDMA_clearCallbackPointer
	clr.l	(fofdata2).w		;TitleAnimCallback timers
	clr.w	(fofdata2+4).w
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$08F04567,$89ABCDEF	;remap table (retail; #$67 / or.l)

	bsr.w	printz
	String	$FF,0,0
	movea.l	#Credits,a1		;copyright lines
	bsr.w	.top4
	addi.w	#$20,(Vscroll).w
	move.w	#$104,(clampcounter).w	;FinalizeSpriteList logo slide in
	move.w	#$120,(playoffspritex).w	;logo x
	move.w	#$D0,(playoffspritey).w	;logo y
	clr.w	(asv).w
	move.w	#$FFCE,(DispAttribCtr).w	;Hscroll speed (UpdateHorizontalScroll)
	move.w	#$20,(palcount).w
	move	#$2500,sr

.top1	bsr.w	TitleScreen_wait	;wait for the logo
	tst.w	(clampcounter).w
	bne.s	.top1

	move.w	#$3C,d3			;1 second
.tops	bsr.w	TitleScreen_wait
	dbf	d3,.tops

	bsr.w	printz
	String	$FF,0,0
	movea.l	#Credits+$42,a1		;credits after the copyright lines
.top2	bsr.w	.top4
	adda.w	(a1),a1
	moveq	#$2F,d4			;scroll 6*8 lines (92 6*8-1)
.top5	bsr.w	TitleScreen_wait
	bsr.w	TitleScreen_wait
	addq.w	#1,(Vscroll).w
	dbf	d4,.top5
	moveq	#$78,d4			;120 frames (92 4*60)
.top6	bsr.w	TitleScreen_wait
	dbf	d4,.top6
	tst.w	2(a1)
	bpl.s	.top2
	rts

.top4	;92.top4: erase 6 rows below the scroll and print a1 strings centered, to -1
	move.w	(Vscroll).w,d0
	asr.w	#3,d0
	addi.w	#$1C,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	move.w	d0,-(sp)
	clr.w	(printx).w
	moveq	#$20,d0
	moveq	#6,d1
	move.w	#$7FF,d2		;(92 moveq #1,d2)
	bsr.w	eraser
	move.w	(sp)+,(printy).w
.top4x	move.w	(a1),d0
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$11,d0			;(92 16)
	move.w	d0,(printx).w
	bsr.w	print
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w
	tst.w	2(a1)
	bpl.s	.top4x
	rts

TitleAnimCallback	;93: CallAnimationCallback routine for the title screen (from TitleScreen_wait).
	;Three Title3map sprites: a running fofdata2 timer shows the sprite and counts down; a stopped one
	;restarts at 20 when Hscroll + $1EC - TitleData1 entry is within 0-20 (mod $400)
	movea.l	#Title3Sprites,a0
	movea.w	#(fofdata2-M68K_RAM),a1
	lea	TitleData1(pc),a2
	moveq	#2,d7
	move.w	(gamesetuptilesetindex).w,d3
	ori.w	#$8000,d3		;priority
.top	move.w	(a1)+,d0
	bmi.w	.chk
	subq.w	#1,-2(a1)
	moveq	#1,d2
	add.w	d7,d2
	mulu.w	#$B,d2
	lsr.w	#1,d0
	sub.w	d0,d2			;frame (sprite d7 + 1) * 11 - timer / 2
	move.w	#$80,d0
	move.w	#$80,d1
	bsr.w	SetSframe
	bra.w	.next
.chk	move.w	(Hscroll).w,d0
	addi.w	#$1EC,d0
	sub.w	(a2),d0
	andi.w	#$3FF,d0
	cmp.w	#$14,d0
	bhi.w	.next
	move.w	#$14,-2(a1)		;start this sprite
.next	addq.w	#2,a2
	dbf	d7,.top
	rts

TitleData1	;93: Hscroll trigger points for the three TitleAnimCallback sprites
	dc.w	$B2,$DA,$6C
TitleData2	;93: four 16 color palettes for titleScreenState, one picked at random by TitleScreen
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$4A4,$484,$262,$40
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$E44,$A44,$822,$400
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$44A,$228,6,4
	dc.w	$EEA,$EEE,$CCC,$AAA,$888,$666,$444,$222,0,$66A,$46A,$446,$AE,$8C,$6A,$48

UpdateHorizontalScroll	;93: title screen line scroll, called each vblank from VBlank_TitleScreen.
	;The top $AF lines scroll plane B by Hscroll, the last $31 lines and plane A stay at 0. Hscroll moves by
	;(asv += DispAttribCtr) >> 8; beyond +-8 the direction flips, else about 1 in 40 frames picks a new speed (-$32 to $32)
	move.w	#$DF,d0			;224 lines
	movea.w	#(SortCords-M68K_RAM),a0	;line scroll table
.loop	clr.l	(a0)+
	cmp.w	#$30,d0
	ble.w	.next
	move.w	(Hscroll).w,-2(a0)
.next	dbf	d0,.loop
	move.w	(DispAttribCtr).w,d0
	add.w	(asv).w,d0
	move.w	d0,(asv).w
	asr.w	#8,d0
	add.w	d0,(Hscroll).w
	cmp.w	#8,d0
	bgt.w	.rev
	cmp.w	#$FFF8,d0		;-8
	blt.w	.rev
	move.w	#$FA0,d0		;4000
	bsr.w	randomd0
	cmp.w	#$64,d0
	bhi.w	.x
	subi.w	#$32,d0
	move.w	d0,(DispAttribCtr).w
.rev	neg.w	(DispAttribCtr).w
.x	rts

TitleScreen_wait	;wait for vblank, run TitleAnimCallback through CallAnimationCallback. 92 TitleScreen .wait:
	;if start is pressed, return to TitleScreen's caller (pops the return address). Called from TitleScreen
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0
	beq.s	.0
	lea	TitleAnimCallback(pc),a0
	bsr.w	CallAnimationCallback
	bsr.w	orjoy
	btst	#7,d1			;sbut
	movem.l	(sp)+,d0-d7/a0-a6
	beq.w	rtss
	addq.w	#4,sp			;start: leave TitleScreen
	rts

VBlank_TitleScreen	;93: vbint handler for the title screen: line scroll and sprite table dma, Vscroll, cramfade,
	;vcount, UpdateHorizontalScroll and the music driver
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.x
	movea.w	#(SortCords-M68K_RAM),a0	;line scroll table
	move.w	(VSCRLPM).w,d1
	move.w	#$1C0,d0
	bsr.w	DoDMA
	movea.l	#VDP_DATA,a0
	move.l	#$40000010,4(a0)	;vsram write 0
	move.w	(Vscroll).w,(a0)
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.nos
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
.nos	bsr.w	cramfade
.x	addq.w	#1,(vcount).w
	bsr.w	UpdateHorizontalScroll
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

CallAnimationCallback	;93: build a sprite list with routine a0 (a6 = Satt, d6 = link counter), add the logo
	;sprites (FinalizeSpriteList), then close the list. Called from PlayoffScreen and TitleScreen_wait
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6			;link counter
	jsr	(a0)
	bsr.w	FinalizeSpriteList
EndSpriteList	;92 setvideo end: close the sprite list at a6 and set Sattsize (93: in words).
	;Branched to from UpdateStanleyCupAnimation
	cmpa.w	#(Satt-M68K_RAM),a6
	bne.w	.n
	clr.l	(a6)+			;no sprites: one blank entry
	clr.l	(a6)+
.n	clr.b	-5(a6)			;end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0
	move.w	d0,(Sattsize).w
	rts

FinalizeSpriteList	;93: four Titlemap2 logo sprites at playoffspritex, playoffspritey. clampcounter counts down by 2
	;and the pieces drop into place from above, each 64 later than the next. Called from CallAnimationCallback
	subq.w	#2,(clampcounter).w
	bpl.w	.0
	clr.w	(clampcounter).w
.0	movea.l	#TitleLogoSprites,a0
	moveq	#3,d7
	move.w	(energybarchars).w,d3
	ori.w	#$8000,d3		;priority
.top	move.w	(playoffspritex).w,d0
	move.w	d7,d1
	asl.w	#6,d1
	sub.w	(clampcounter).w,d1
	bmi.w	.1
	clr.w	d1			;in place
.1	add.w	(playoffspritey).w,d1
	moveq	#4,d2
	sub.w	d7,d2			;frame 1-4
	bsr.w	SetSframe
	dbf	d7,.top
	rts

CheckSound	;93: sound test, no caller found. Runs only with start+a+c held on pad 1.
	;Prints "Check Sound"; right/left change the number, c plays it with sfx, start leaves
	bsr.w	Readjoy1
	cmp.b	#$E0,d3			;held: sbut, abut, cbut
	bne.w	rtss
	move	#$2500,sr
	move.l	#vb2,(vbint).w
	jsr	p_turnoff
	bsr.w	forceblack
	move.w	#$18,(palcount).w
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,3,$C,1,'Check Sound'	;attribute 4, map 3, x $C, y 1
	moveq	#$14,d6			;sound number
.top	move.w	(vcount).w,d0
.wait	cmp.w	(vcount).w,d0
	beq.s	.wait
	bsr.w	Readjoy1
	bsr.w	ProcessInputWithRepeat
	tst.b	d1
	beq.s	.top
	btst	#7,d1			;sbut
	bne.w	rtss
	btst	#3,d1			;rbut
	beq.w	.nor
	addq.w	#1,d6
.nor	btst	#2,d1			;lbut
	beq.w	.nol
	subq.w	#1,d6
.nol	btst	#5,d1			;cbut
	beq.w	.nob
	move.w	d6,-(sp)
	bsr.w	sfx
.nob	move.w	d6,d0
	moveq	#3,d1			;3 digits
	bsr.w	PushNumberWidth
	move.w	#$17,(printx).w
	bsr.w	print
	bra.s	.top

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $13952-$14403
;	92 setoptions (game setup screen) with its 93 additions: the two team blocks with the
;	animated roster players (UpdateBothTeamDisplays ... AddTeamSpriteFrame) and its own vblank
;	handler (VBlank_SetOptions). DefaultMenus onward.
;Global names from the 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	92 bit names used in comments, same values in 93: disflags 0 dfok, 1 df32c, 2 dfng;
;	pad bits ubut 0, dbut 1, lbut 2, rbut 3, sbut 7.
;	printz strings: first byte c, -c = $ab: map = b&3, printa = (-c<<9)&$F800. $FF map 1, $FE map 2,
;	$BF map 1 + priority, $BE map 2 + priority (92 String -$01 = $FF). Then x, y.
;	Maps here: map 1 = VmMap1 ($E000), map 2 = VmMap2 ($C000).
;	DecompressGraphicsWithCallback is followed by its 8 byte remap table.

setoptions	;options screen display and input. Called from PeriodOver.
	;93: 6 minute demo timeout polling both pads, animated roster players in the team blocks,
	;random teams after a demo, ends with bra maketree
	move	#$2500,sr		;(92 Rev A order)
	move.l	#VBlank_SetOptions,(vbint).l	;(92 vb2)
	bclr	#dfok,(disflags).w
	bset	#dfng,(disflags).w
	bclr	#df32c,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$B400,(VSPRITES).w
	move.w	#$B800,(VmMap3).w
	move.w	#5,(Map3col).w
	move.w	#$C000,(VmMap2).w
	move.w	#6,(Map2col).w
	move.w	#$E000,(VmMap1).w
	move.w	#6,(Map1col).w
	move.w	#0,d0			;fade to color
	bsr.w	setVram

	bsr.w	orjoy

	bsr.w	AddTeamBlock
	move.w	d4,(Framercset).w	;93: framer tiles loaded here (92 bsr AddFramer)
	movea.l	#FramerMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$01234562,$89ABCDEF	;remap table (retail; / or.l)
	move.w	d4,(smallfontchars).w	;93: small font loaded here (92 bsr AddSmallFont)
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$0FC04567,$89ABCDEF	;remap table (retail; / or.l)

	bsr.w	printz
	String	$FF,0,0			;map 1 (92 -$02,0,0)
	moveq	#$28,d0			;40 x 28 (#$28,d0)
	moveq	#$1C,d1
	move.w	#$7FF,d2		;blank char (92 moveq #1)
	bsr.w	eraser

	bsr.w	printz
	String	$FE,0,0			;map 2 (92 -$01,0,0)
	movea.l	#GameSetUpMap,a0	;game setup bitmap
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2			;40 x 28
	moveq	#$1C,d3
	moveq	#$F,d5			;color fam 1-4 (92 %1101)
	bsr.w	dobitmap

	movea.l	#GameSetupSprites+8,a2	;93: roster player sprite tiles after the bitmap
	move.w	d4,(gamesetuptilesetindex).w	;(92 faceoffvrcset / Buildframelist)
	bsr.w	DoDMA_clearCallbackPointer
	bsr.w	defaultsprites2
	move.w	#$28,(SortCords+$1C).w	;home player x offset 40 (off the block)
	move.w	#$28,(SortCords+$31C).w	;visitor player x offset 40
	st	(tmstruct).w		;team shown = $FFxx, so UpdateTeamNameAnimation starts a new team
	st	(awtmstruct).w

	movea.l	#.text,a1		;options static text
.textlp	bsr.w	print
	tst.b	2(a1)
	bne.s	.textlp

	tst.w	(demoflag).w
	bne.w	.keep			;93: demoflag clear (a demo ran): random teams
	moveq	#$1A,d0			;26 teams
	bsr.w	randomd0
	move.w	d0,(Opt1team).w
	moveq	#$1A,d0
	bsr.w	randomd0
	move.w	d0,(Opt2team).w
.keep	st	(demoflag).w
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.notree			;regular season or continue playoffs
	bsr.w	NewPO	;new playoffs
.notree	cmpi.w	#1,(OptPlayMode).w
	bne.w	.nopo
	bsr.w	ContinuePlayoffs			;continue playoffs
.nopo	clr.w	d7			;menu line 0
	clr.w	d0
	bsr.w	.nms
	bsr.w	.ps
	move.w	#$18,(palcount).w	;24
	bclr	#dfng,(disflags).w		;fade in graphics now
;----------
.top	move.l	#$5460,d6		;21600 frames (6 minutes) before the demo (92 40*60)
.wait	move.w	(vcount).w,d1
	sub.w	(oldvcount).w,d1
	beq.s	.wait			;wait for the next vblank
	move.w	(vcount).w,(oldvcount).w
	bsr.w	UpdateBothTeamDisplays
	bsr.w	Readjoy1
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.nd			;pad 1 pressed
	bsr.w	Readjoy2
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.nd			;pad 2 pressed
	dbf	d6,.wait

	clr.w	(demoflag).w		;92 .demo
	move.w	(VDP_CNTR).l,(seed).w	;92 seed = HVcount
	move.w	(VDP_CNTR).l,(seed+2).w
	clr.w	(OptPlayMode).w		;92 .newdemo: regular season
	clr.w	(OptNOP).w
	clr.w	(OptLine).w		;line changes on
	move.w	#1,(OptPen).w		;penalties "On"
.ex	bsr.w	UpdatePlayoffLevel
	move.w	(VDP_CNTR).l,(seed).w	;random seed hopefully
	move.w	(VDP_CNTR).l,(seed+2).w
	bra.w	maketree		;(92 GetPassWord / PassWord before MakeTree)

.nd	btst	#7,d1			;sbut
	bne.s	.ex
	btst	#1,d1			;dbut
	beq.w	.2
	moveq	#2,d0
	bsr.w	.nms			;new menu line selected
	bsr.w	.ps			;print screen
	bra.w	.top

.2	btst	#0,d1			;ubut
	beq.w	.3
	moveq	#-2,d0
	bsr.w	.nms			;new menu line
	bsr.w	.ps			;print screen
	bra.w	.top

.3	moveq	#1,d2
	btst	#3,d1			;rbut
	bne.w	.4
	btst	#2,d1			;lbut
	beq.w	.top
	moveq	#-1,d2
.4	bsr.w	.IncItem		;change item
	bsr.w	.ps			;print screen
	bra.w	.top

.IncItem	;add d2 to current item d7 (d2 = 0: just limit it)
	movea.w	#(OptPlayMode-M68K_RAM),a2	;92 optionsmenu
	movea.l	#.pslim,a3
	clr.w	d5			;low limit
	move.w	(a3,d7.w),d4		;limit
	move.w	(a2,d7.w),d3		;current value
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.ii0
	cmp.w	#4,d7			;team 1 in new playoffs
	bne.w	.ii0
	moveq	#$18,d4			;24 (92 NumOfTeams-2)
.ii0	cmp.w	#2,d7			;players
	bne.w	.ii1
	moveq	#5,d5			;playoffs: player choices 5-7
	tst.w	(OptPlayMode).w
	bne.w	.ii1
	clr.w	d5			;regular season: player choices 0-4
	moveq	#5,d4
.ii1	bsr.w	.iilimit
	move.w	d3,(a2,d7.w)
	tst.w	d2
	beq.w	rtss
	cmpi.w	#1,(OptPlayMode).w
	bne.w	.npo
	tst.w	d7
	bne.w	.npo
	bsr.w	ContinuePlayoffs			;93: play mode moved onto continue playoffs
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.s	.ii1			;nothing to continue: step past it
	rts

.npo	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtss
	tst.w	d7
	beq.w	NewPO	;new playoffs: play mode or team 1 changed (92 NewPo)
	cmp.w	#4,d7
	beq.w	NewPO
	rts

.iilimit	;d3 + d2, wrapped into d5 ... d4-1
	add.w	d2,d3
	cmp.w	d5,d3
	bge.w	.iil1
	move.w	d4,d3
	subq.w	#1,d3
.iil1	cmp.w	d4,d3
	blt.w	rtss
	move.w	d5,d3
	rts

.ps	;print choices and show team icons/colors
	move.w	d7,d6
	moveq	#-2,d7
.pstop	addq.w	#2,d7
	clr.w	d2
	bsr.w	.IncItem
	bsr.w	.psd
	cmp.w	#$C,d7			;92 (menuitems-1)*2
	bne.s	.pstop
	move.w	d6,d7
	bra.w	TeamIcons

.psd	;print the choice for menu line d7
	bsr.w	printz
	String	$BE,$11,$D		;map 2 + priority (92 -$01,16,11; / btst)
	add.w	d7,(printy).w		;row $D + d7 (2 rows per item)
	moveq	#$14,d0			;93: erase 20 x 1 (92 printed .blank)
	moveq	#1,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	subq.w	#1,(printy).w		;eraser moved down a line
	move.w	#$11,(printx).w		;(92 16)
	cmp.w	#4,d7			;team 1
	beq.w	.psdtp
	cmp.w	#6,d7			;team 2
	beq.w	.psdtp
	movea.l	#OptPlayMode,a0		;92 optionsmenu
	move.w	(a0,d7.w),d3
	movea.l	#.pl,a0
	adda.w	(a0,d7.w),a0
.psd3	movea.l	a0,a1			;step to string d3
	adda.w	(a0),a0
	dbf	d3,.psd3
	bra.w	print

.psdtp	movea.l	#OptPlayMode,a1		;92 optionsmenu
	move.w	(a1,d7.w),d3
	movea.w	#$314,a1		;team address table (92 TeamList)
	asl.w	#2,d3
	movea.l	(a1,d3.w),a1
	lsr.w	#2,d3
	adda.w	4(a1),a1		;92 TeamName
	bra.w	print

.nms	;next menu by d0
	move.w	d7,d3
.nms0	add.w	d0,d7
	bpl.w	.nms1
	clr.w	d7
.nms1	cmp.w	#$E,d7			;92 menuitems*2
	blt.w	.nms2
	sub.w	d0,d7
.nms2	cmpi.w	#1,(OptPlayMode).w
	bne.w	.nms3
	tst.w	d7
	beq.w	.nms3
	cmp.w	#6,d7			;continue playoffs: skip lines 1-3
	bls.s	.nms0
.nms3	cmpi.w	#2,(OptPlayMode).w
	blt.w	.nms4
	cmp.w	#6,d7			;new playoffs: skip team 2
	beq.s	.nms0
.nms4	bsr.w	.setrect		;erase the old frame
	move.w	#$7FF,d2		;(92 moveq #1)
	bsr.w	eraser
	move.w	d7,d3
	bsr.w	.setrect
	bra.w	Framer

.setrect	;set rectangle cords for framing line d3
	bsr.w	printz
	String	$FF,$10,$C		;map 1 (92 printm 4, printx 15, printy 10)
	add.w	d3,(printy).w		;(/ cmp.b hid this and the moveq)
	moveq	#$16,d0			;22 x 3 (92 24)
	moveq	#3,d1
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtss
	cmp.w	#4,d3			;team 1 in new playoffs
	bne.w	rtss
	moveq	#5,d1			;taller frame
	rts

;limit of each item
	dc.w	0
.pslim	dc.w	4,8,$1A,$1A,3,3,2	;92 NumofTeams = $1A

;menu item names
.pl	dc.w	.pl0-.pl
	dc.w	.pl1-.pl
	dc.w	.pl2-.pl
	dc.w	.pl3-.pl
	dc.w	.pl4-.pl
	dc.w	.pl5-.pl
	dc.w	.pl6-.pl

.pl0	String	'Regular Season'
	String	'Continue Playoffs'
	String	'New Playoffs'
	String	'New Playoffs/7 game'

.pl1	String	'Demo'
	String	'One - Home'
	String	'One - Visitor'
	String	'Two - Teammates'
	String	'Two - Head to Head'

	String	'Two - Head to Head'
	String	'Two - Teammates'
	String	'One'
.pl2
.pl3
.pl4	String	'5 Minutes'
	String	'10 Minutes'
	String	'20 Minutes'
	String	'30 Seconds'

.pl5	String	'Off, Except fighting'
	String	'On'
	String	'On, Except Off-sides'
.pl6	String	'On'
	String	'Off'

.text	;static text
	String	$FE,3,$D,'Play Mode'	;(92 -$01,2,11)
	String	$FE,3,$F,'Players'
	String	$FE,3,$11,'Team 1'
	String	$FE,3,$13,'Team 2'
	String	$FE,3,$15,'Per. Length'
	String	$FE,3,$17,'Penalties'
	String	$FE,3,$19,'Line Changes'
	dc.w	4,0			;92 String 0

UpdatePlayoffLevel	;93: in new playoffs set playoffroundoffset = 7 - playofflevel. Called from setoptions .ex
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtss
	moveq	#7,d0
	sub.w	(OptNOP).w,d0
	move.w	d0,(pojoy).w
	rts

TeamIcons	;draw team name bars and set colors. Branched to from setoptions.ps.
	;93 has no continue playoffs exit and no setplayercolors (SetupNextPlayer loads the palettes)
	movem.l	d0-d7/a0-a2,-(sp)
	tst.w	(OptPlayMode).w
	bne.w	.0
	move.w	(Opt1team).w,(HomeTeam).w	;92 Opt1Team
	move.w	(Opt2team).w,(VisTeam).w	;92 Opt2Team
.0	bsr.w	printz
	String	$BE,2,1			;map 2 + priority (92 -$02,3,8; / btst)
	move.w	(VisTeam).w,d1
	bsr.w	dotb
	bsr.w	printz
	String	$BE,$1A,1		;(92 -$02,24,8)
	move.w	(HomeTeam).w,d1
	bsr.w	dotb
	bsr.w	setteams
	move.w	#$18,(palcount).w	;24
	movem.l	(sp)+,d0-d7/a0-a2
	rts

dotb	;draw team name bar d1 = team number at printx/printy. Called from TeamIcons and
	;ScoutingReport
	clr.w	d0
	asl.w	#1,d1
	movea.l	#TeamBlocksmap,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	4(a1),a1
	movea.w	#$310,a2		;tile data: word 0 at $310 = no tiles (92 null)
	move.w	(a1),d2			;width from the map header (92 13)
	moveq	#2,d3
	moveq	#2,d4			;(92 $8002)
	moveq	#2,d5			;color fam 2
	bra.w	dobitmap

ClearOptionDisplay	;93: erase the 12 x 2 player name area of team a2. Called from ClearAndSetFlag
	bsr.w	setoptions_printpos2
	moveq	#$C,d0
	moveq	#2,d1
	move.w	#$7FF,d2
	bra.w	eraser

setoptions_printpos2	;93: set the print position of team a2's player name: x 2 (visitor) or x $1A (home), y $A,
	;map 1 + priority. Called from ClearOptionDisplay and UpdateTeamNameAnimation
	bsr.w	printz
	String	$BF,2,$A
	cmpa.w	#(tmstruct-M68K_RAM),a2	;(/ mulu.w)
	bne.w	rtss
	move.w	#$1A,(printx).w		;home team on the right
	rts

SetGoalieMode	;93: ( it prints nothing) pick the goalie shown for team a2 when it changes: $26(a2) =
	;weighted random roster index from the 4 nibbles at team data +$A offset (UnpackNibbles / WeightedRandomSelect).
	;$26 stays 0 when a pad controls the team, gamelevel > 2 or OptLine is set. Called from UpdateTeamNameAnimation
	movem.l	d0/a0,-(sp)
	clr.w	tmgoalie(a2)
	bsr.w	FigureJoy		;sets cont1team / cont2team
	cmpa.w	#(tmstruct-M68K_RAM),a2
	seq	d0
	ext.w	d0
	addq.w	#2,d0			;home 1, visitor 2
	cmp.w	(cont1team).w,d0
	beq.w	.x			;pad 1 on this team
	cmp.w	(cont2team).w,d0
	beq.w	.x			;pad 2 on this team
	moveq	#0,d0
	cmpi.w	#2,(gamelevel).w
	bgt.w	.set
	tst.w	(OptLine).w
	bne.w	.set			;line changes off
	movea.w	#$314,a0		;team address table
	move.w	(a2),d0			;team shown
	asl.w	#2,d0
	movea.l	(a0,d0.w),a0
	adda.w	$A(a0),a0		;team data +$A offset: weights
	moveq	#4,d0
	bsr.w	UnpackNibbles
	bsr.w	WeightedRandomSelect	;d0 = index 0-3
.set	move.w	d0,tmgoalie(a2)
.x	movem.l	(sp)+,d0/a0
	rts

UpdateBothTeamDisplays	;93: run the roster player in both team blocks and build their sprite list.
	;Called once per frame from setoptions .wait
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#1,d7
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	UpdateTeamNameAnimation
	adda.w	#tmsize,a2		;awtmstruct
	bsr.w	UpdateTeamNameAnimation
	bsr.w	UpdateTeamSprites
	movem.l	(sp)+,d0-d7/a0-a6
	rts

UpdateTeamNameAnimation	;93: roster player of team a2 (sprite struct a3 = $22(a2), tmsort). When the team ($28, set
	;by setteams) differs from the one shown ((a2)), start over. Bit 2 of $30(a2) set: slide the player out 3 per
	;frame, then SetupNextPlayer. Else slide in 1 per frame, run updateanim, and when the animation is done step
	;the TeamNameAnimationTable script (8(a2) = script, $A(a2) = offset). A negative time also prints the
	;player's number and name. Called from UpdateBothTeamDisplays
	move.w	$28(a2),d0
	cmp.w	(a2),d0
	beq.w	.same
	move.w	d0,(a2)			;new team
	bsr.w	SetGoalieMode
	clr.w	2(a2)			;first RosterOrderTable entry
	bsr.w	ClearAndSetFlag
.same	movea.w	tmsort(a2),a3
	btst	#2,tmflags(a2)
	beq.w	.in
	addq.w	#3,$24(a3)		;sliding out
	addq.w	#3,$1C(a3)		;x offset
	cmpi.w	#$28,$1C(a3)
	bgt.w	SetupNextPlayer		;past 40: next player
	rts

.in	tst.w	$1C(a3)
	bpl.w	.anim
	addq.w	#1,$24(a3)		;sliding in from -40
	addq.w	#1,$1C(a3)
.anim	jsr	(updateanim).l
	btst	#pf2aip,pflags2(a3)
	bne.w	rtss			;animation still running
	move.w	8(a2),d0		;script number
	add.w	d0,d0
	movea.l	#TeamNameAnimationTable,a0
	adda.w	(a0,d0.w),a0
	adda.w	$A(a2),a0
	addq.w	#4,$A(a2)		;next step
	move.w	(a0),d1			;animation
	beq.w	ClearAndSetFlag		;end of script: slide out
	bsr.w	SetSPA
	bset	#pf2aip,pflags2(a3)
	move.w	2(a0),$54(a3)		;time
	bpl.w	rtss
	neg.w	$54(a3)			;negative time: also show the name

	move.w	4(a2),d0		;roster index
	bsr.w	GetTeamNamePtr
	bsr.w	setoptions_printpos2
	movea.w	#(mesarea-M68K_RAM),a3
	lea	2(a3),a1
	move.w	#6,(a3)			;string length: 2 digits and a space
	move.l	a0,-(sp)
	adda.w	(a0),a0
	move.b	(a0),d0			;player number (BCD)
	bsr.w	ConverByteToDigits
	move.w	#$2000,4(a3)		;space, end
	movea.l	(sp)+,a1
	bsr.w	appstring		;"NN " + name
	movea.w	a3,a0
	adda.w	(a0),a0
.trim	cmpi.b	#$20,-(a0)		;find the last space
	bne.s	.trim
	clr.b	(a0)			;line 1 = number and first name
	move.w	a0,d0
	sub.w	a3,d0
	btst	#0,d0
	beq.w	.even
	addq.w	#1,a0			;keep the last name word aligned
	addq.w	#1,d0
.even	move.w	(a3),d1
	sub.w	d0,d1
	addq.w	#2,d1			;length of the last name string
	move.w	d0,(a3)
	movea.w	a3,a1
	move.w	(printx).w,-(sp)
	lsr.w	#1,d0
	subq.w	#7,d0
	sub.w	d0,(printx).w		;center in 14 columns
	bsr.w	print
	move.w	d1,-(a0)		;length word in front of the last name
	tst.b	2(a0)
	bne.w	.ln2
	subq.w	#1,d1			;starts with the pad byte
.ln2	movea.w	a0,a1
	lsr.w	#1,d1
	neg.w	d1
	addq.w	#7,d1
	add.w	(sp)+,d1
	move.w	d1,(printx).w		;center in 14 columns
	addq.w	#1,(printy).w
	bra.w	print			;line 2 = last name

ClearAndSetFlag	;93: erase the name of team a2 and set bit 2 of $30(a2) (slide the player out).
	;Called and branched to from UpdateTeamNameAnimation
	bsr.w	ClearOptionDisplay
	bset	#2,tmflags(a2)
	rts

SetupNextPlayer	;93: player of team a2 slid out. Load the team palette (setplayercolors.sp), put the
	;sprite at x offset -40, take the next RosterOrderTable slot (goalie slot: $26(a2)), set the sprite flag from
	;the player data and pick his animation script from the ratings. Branched to from UpdateTeamNameAnimation
	movea.l	tmdata(a2),a0
	adda.w	2(a0),a0		;Palettedata
	movea.w	#(palbuffer-M68K_RAM),a1
	moveq	#7,d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.pal
	adda.w	#$20,a0			;visitor: second palette
	adda.w	#$20,a1
.pal	move.l	(a0)+,(a1)+
	dbf	d0,.pal
	move.w	#$18,(palcount).w	;24
	bclr	#2,tmflags(a2)
	movea.w	tmsort(a2),a3
	move.w	#$FFD8,$1C(a3)		;x offset -40
	clr.w	$58(a3)
.next	move.w	2(a2),d0
	lea	RosterOrderTable(pc),a0
	move.b	(a0,d0.w),d0
	bpl.w	.got
	clr.w	2(a2)			;end of list: start again
	bra.s	.next

.got	move.w	d0,6(a2)		;line slot
	addq.w	#1,2(a2)
	lea	$16A(a2),a0		;line data
	move.b	(a0,d0.w),d0
	subq.w	#1,d0			;roster index
	tst.w	6(a2)
	bne.w	.pn
	move.w	tmgoalie(a2),d0		;slot 0 (goalie): UpdateTeamNameisplay's pick
.pn	move.w	d0,4(a2)
	bsr.w	GetTeamNamePtr
	adda.w	(a0),a0			;past the name
	bclr	#3,attribute(a3)
	btst	#0,4(a0)
	bne.w	.r
	bset	#3,attribute(a3)		;bit 0 of player byte 4 clear
.r	addq.w	#1,a0			;rating bytes
	moveq	#6,d0			;7 bytes, 14 nibbles
	clr.w	d2			;best rating
	movea.l	#CharacterValidationTable,a1
	move.w	6(a2),d3
	andi.w	#7,d3
	bne.w	.nib
	movea.l	#AltCharValidationTable,a1	;goalie slot
.nib	move.b	(a0),d1
	lsr.b	#4,d1
	bsr.w	ValidateCharacterNibbles
	move.b	(a0)+,d1
	andi.b	#$F,d1
	bsr.w	ValidateCharacterNibbles
	dbf	d0,.nib
	clr.w	$A(a2)			;start of the script
	rts

ValidateCharacterNibbles	;93: rating d1 against the next (minimum, script) pair at a1. If d1 >= minimum and
	;>= best d2 (and the minimum is not 0 once d2 is set), d2 = d1 and 8(a2) = script. Called from SetupNextPlayer
	addq.w	#2,a1
	cmp.b	-2(a1),d1
	blt.w	rtss			;below the minimum
	cmp.b	d2,d1
	blt.w	rtss			;below the best so far
	tst.w	d2
	beq.w	.set
	tst.b	-2(a1)
	beq.w	rtss
.set	move.b	d1,d2
	clr.w	8(a2)
	move.b	-1(a1),9(a2)
	rts

GetTeamNamePtr	;93: a0 = roster entry d0 of team a2 (name string, then 8 bytes: number and ratings).
	;Called from UpdateTeamNameAnimation and SetupNextPlayer
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0			;player data
	bra.w	.cnt
.next	adda.w	(a0),a0			;skip the name
	addq.w	#8,a0
.cnt	dbf	d0,.next
	rts

CharacterValidationTable	;93: skater (minimum rating, animation script) per rating nibble, used by SetupNextPlayer
	dc.b	0,1,$B,2,0,1,0,1,$B,6,$B,3,0,1,$B,7,$B,4,0,1,0,1,0,1,0,1,0,1
AltCharValidationTable	;93: goalie (minimum rating, animation script) per rating nibble
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,$B,5,$B,5
TeamNameAnimationTable	;93: roster player animation scripts 0-7 (offsets), each (SetSPA animation, time) pairs ending in 0.
	;A negative time also prints the name. Used by UpdateTeamNameAnimation
	dc.w	.s0-TeamNameAnimationTable,.s1-TeamNameAnimationTable,.s2-TeamNameAnimationTable
	dc.w	.s3-TeamNameAnimationTable,.s4-TeamNameAnimationTable,.s5-TeamNameAnimationTable
	dc.w	.s6-TeamNameAnimationTable,.s7-TeamNameAnimationTable
.s0	dc.w	$134,3,$134,4,$134,5,$134,-4,$166,4,$134,4,$198,4,$134,4,0
.s5	dc.w	$134,3,$134,4,$134,5,$134,-4,$1CA,4,$134,4,$134,4,0
.s1	dc.w	$5F0,3,$5F0,4,$EAA,-5,$EAA,4,$52C,4,$52C,4,0
.s2	dc.w	$55E,4,$55E,4,$1452,-4,$52C,4,$52C,4,0
.s3	dc.w	$55E,5,$55E,5,$81C,-5,$52C,5,$52C,5,0
.s4	dc.w	$55E,3,$55E,3,$13A0,-3,$81C,3,$52C,3,$52C,3,0
.s6	dc.w	$5F0,4,$5F0,5,$B44,-5,$B44,5,$5F0,5,$B44,5,$52C,5,$52C,5,0
.s7	dc.w	$5F0,3,$5F0,2,$F8E,-2,$1004,2,$1036,2,$1004,2,$1036,2,0
RosterOrderTable	;93: line data slots shown in turn: C, RW, LW, G, RD, LD of line 1, then lines 2 and 3; $FF ends
	dc.b	4,5,3,0,2,1,$C,$D,$B,$A,9,$14,$15,$13,$12,$11,$FF,0

UpdateTeamSprites	;93: sprite list for the two roster players (92 setvideo end). a5 = DMAList, a6 = Satt.
	;Sets dfok for VBlank_SetOptions. Called from UpdateBothTeamDisplays
	movea.w	#(DMAList-M68K_RAM),a5
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6			;link counter
	movea.w	#(SortCords-M68K_RAM),a3	;home player
	bsr.w	AddTeamSpriteFrame
	adda.w	#6*SCstruct,a3		;visitor player
	bsr.w	AddTeamSpriteFrame
	cmpa.w	#(Satt-M68K_RAM),a6
	bne.w	.n
	clr.l	(a6)+			;no sprites: one blank entry
	clr.l	(a6)+
.n	clr.b	-5(a6)			;end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0
	move.w	d0,(Sattsize).w
	move.l	a5,(DMAListend).w
	bset	#dfok,(disflags).w
	rts

AddTeamSpriteFrame	;93: add player a3 (x = (a3) + $1C offset, y = $14) and a GameSetupMap frame 1 sprite at
	;y $80, x $80 + ($24/2 mod 48), +$C0 when $62(a3) bit 6 is clear. Called from UpdateTeamSprites
	move.w	(a3),d0
	add.w	$1C(a3),d0
	move.w	Ypos(a3),d1
	bsr.w	addframe2
	movea.l	#GameSetupSprites,a0
	clr.l	d0
	move.w	$24(a3),d0
	lsr.w	#1,d0
	divu.w	#$30,d0
	swap	d0			;remainder
	addi.w	#$80,d0
	btst	#6,pflags(a3)
	bne.w	.x
	addi.w	#$C0,d0
.x	move.w	#$80,d1
	moveq	#1,d2			;frame
	move.w	(gamesetuptilesetindex).w,d3
	bra.w	SetSframe

VBlank_SetOptions	;93: vbint handler stored by setoptions. 92 vb2 (cramfade unless dfng), plus
	;DumpSprites2 when dfok is set
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	bclr	#dfok,(disflags).w
	beq.w	.fade
	bsr.w	DumpSprites2
.fade	bsr.w	cramfade
.nograph	addq.w	#1,(vcount).w
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $14404-$1499D
;92 DefaultMenus, NewPO, MakeTree, FigureJoy and the playoff
;	password code (ReadPassBits ... SuperDiv, GetShifter), then the 93-only playoff stat packing
;	(DisplayTeamStatsForPlayoffs, ReadTeamStats). ResolveGames onward.
;Global names from the 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	93 keeps the password bits in a 5 word buffer at a3 (92 passbits, 8 words) and drops the 92
;checksum. The buffers are pwddatabuffer, tpassbits and outputbuffer at their
;	retail addresses, 4 bytes lower than in the Rev A listing (Rev A address in the comment).
;	gsflags bits (92 names, same values): 0 gsftf teams flipped, 1 gsfhl hilite, 2 gsfso series over.
;	playoffroundoffset is the 92 pojoy word (playoff joystick set-up), playofflevel the 92 OptNOP slot.

DefaultMenus	;set default menu choices for beginning of game. Called once from Begin (jsr abs.l).
	st	(demoflag).w		;93: no demo has run yet
	movea.l	#OptPlayMode,a0		;92 optionsmenu
	movea.l	#.defom,a1
	move.w	#6,d0			;92 menuitems-1
.1	move.w	(a1)+,(a0)+
	dbf	d0,.1
	rts
.defom	dc.w	0,1,$F,3,1,0,1		;play mode, players, team 1, team 2, period length
					;penalties, line changes (92 0,1,14,8,1,0,1)

ContinuePlayoffs	;93 continue playoffs: read the playoff state back from the password bits, rebuild the tree.
	;Called from setoptions when play mode becomes "continue playoffs".
	;92 does the same in GameOver (DecodePW + MakeTree). Not 92 NewPO (that is SelectRandomPlayoffTree).
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(pwddatabuffer-M68K_RAM),a3		;password bits
	bsr.w	ReadPassBits
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.w	.ex			;level 0, game 0: nothing played yet
	bsr.w	maketree
	moveq	#7,d0
	sub.w	(pojoy).w,d0	;92 pojoy
	move.w	d0,(OptNOP).w	;menu value from pojoy (92 OptNOP slot)
.ex	movem.l	(sp)+,d0-d7/a0-a3
	rts

NewPO	;body is 92 NewPO: new playoff generates tree with same team 1.
	;Called from setoptions for "new playoffs". Falls into maketree.
	moveq	#$20,d0			;32 trees
	bsr.w	randomd0
.top	addq.w	#1,d0
	andi.w	#$1F,d0
	asl.w	#4,d0			;16 teams per tree
	movea.l	#playoffseats,a0
	adda.w	d0,a0
	lsr.w	#4,d0
	moveq	#$F,d1
	move.w	(Opt1team).w,d2	;92 Opt1team
	cmp.w	#$17,d2			;92 NumOfTeams-3: all-star teams use team 23
	bls.w	.loop
	moveq	#$17,d2
.loop	cmp.b	(a0)+,d2		;find team 1 in this tree
	dbeq	d1,.loop
	bne.s	.top			;not in this tree, try the next one
	eori.w	#$F,d1
	move.w	d1,(potreeteam).w
	move.w	d0,(postarts).w
	clr.w	(gamelevel).w
	move.w	#7,(bosgames).w		;not best of seven
	cmpi.w	#2,(OptPlayMode).w
	beq.w	maketree		;2 = playoffs (single games)
	clr.w	(bosgames).w		;best of seven: game 0
	moveq	#7,d0			;clr games won
	movea.w	#(gstruct-M68K_RAM),a0
.cg	clr.w	gspotwins(a0)
	clr.w	gspobwins(a0)
	adda.w	#gssize,a0
	dbf	d0,.cg
;	falls into maketree (92 ;bra maketree)

maketree	;make playoff tree (potree) from playoffseats/winbits. 92 MakeTree.
	;Called from setoptions (bra), NewPO, EncodePW; falls in from SelectRandomPlayoffTree.
	movem.l	d0-d4/a0-a3,-(sp)
	move.w	(postarts).w,d1
	asl.w	#4,d1
	movea.w	#(potree-M68K_RAM),a0
	movea.l	#playoffseats,a1
	adda.w	d1,a1
	move.l	(a1),(a0)		;first round: 16 teams from the tree
	move.l	4(a1),4(a0)
	move.l	8(a1),8(a0)
	move.l	$C(a1),$C(a0)
	lea	$10(a0),a1
	moveq	#$E,d2			;15 winners
	move.w	(WinBits).w,d0
.0	move.w	d0,d1
	andi.w	#1,d1			;winbit picks the top or bottom team of the pair
	move.b	0(a0,d1.w),(a1)+
	addq.w	#2,a0
	lsr.w	#1,d0
	dbf	d2,.0

	bsr.w	GetShifter
	tst.w	d1
	bmi.w	.nogames		;playoffs over
	movea.w	#(potree-M68K_RAM),a0
	adda.w	d2,a0
	adda.w	d2,a0
	movea.w	#(gstruct-M68K_RAM),a1
.2	clr.w	gss1(a1)
	clr.w	gss2(a1)
	clr.w	gsper(a1)
	bclr	#gsfhl,gsflags(a1)		;hilite requested (92 gsfhl)
	bsr.w	.sett
	adda.w	#gssize,a1
	dbf	d1,.2
	bsr.w	FigureJoy
.nogames	movem.l	(sp)+,d0-d4/a0-a3
	rts

.sett	cmpi.w	#2,(bosgames).w		;series games 2, 3, 5: tree order, others swapped
	beq.w	.flip
	cmpi.w	#3,(bosgames).w
	beq.w	.flip
	cmpi.w	#5,(bosgames).w
	beq.w	.flip
	bset	#gsftf,gsflags(a1)		;teams are flipped (92 gsftf)
	move.b	(a0)+,gst2+1(a1)
	move.b	(a0)+,gst1+1(a1)
	rts
.flip	bclr	#gsftf,gsflags(a1)		;gsftf
	move.b	(a0)+,gst1+1(a1)
	move.b	(a0)+,gst2+1(a1)
	rts

FigureJoy	;set cont1team/cont2team appropriately. Called from maketree and UpdateTeamNameisplay.
	;93: after a demo (demoflag clear) fills gstruct with random matchups (InitializeGameStructures)
	movem.l	d0-d3/a0-a1,-(sp)
	clr.w	(cont1team).w
	clr.w	(cont2team).w
	tst.w	(demoflag).w
	beq.w	.init			;demo ran
	tst.w	(OptPlayMode).w
	beq.w	.fjnpo			;regular season
	bsr.w	GetShifter
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2		;po team
	movea.w	#(gstruct-M68K_RAM),a1
	moveq	#gssize,d4
	mulu.w	d1,d4
	adda.w	d4,a1
	st	(gamenum).w
	clr.w	d0
.f0	cmp.w	(a1),d2			;gst1
	beq.w	.it1
	cmp.w	gst2(a1),d2
	beq.w	.it2
	suba.w	#gssize,a1
	dbf	d1,.f0
	bra.w	.ex			;po team not in playoffs

.it2	moveq	#4,d0
	move.w	(a1),(Opt2team).w	;gst1 (92 Opt2team)
	move.w	gst2(a1),(Opt1team).w	;93 also sets team 1
	bra.w	.itx
.it1	clr.w	d0
	move.w	gst2(a1),(Opt2team).w	;92 Opt2team
	move.w	(a1),(Opt1team).w
.itx	add.w	(pojoy).w,d0	;92 pojoy
	move.w	d1,(gamenum).w
	move.w	(a1),(HomeTeam).w	;gst1
	move.w	gst2(a1),(VisTeam).w
	asl.w	#2,d0
	lea	.pojoylist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
	bra.w	.ex

.pojoylist	dc.w	1,0		;pojoy 0-3 with the po team as team 1
	dc.w	1,1
	dc.w	1,2
	dc.w	2,1

	dc.w	2,0			;pojoy 0-3 with the po team as team 2
	dc.w	2,2
	dc.w	2,1
	dc.w	1,2

.fjnpo	move.w	(OptNOP).w,d0	;92 OptNOP
	asl.w	#2,d0
	lea	.noplist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
.init	bsr.w	InitializeGameStructures
.ex	movem.l	(sp)+,d0-d3/a0-a1
	rts

.noplist
	dc.w	0,0
	dc.w	1,0
	dc.w	2,0
	dc.w	1,1
	dc.w	1,2

InitializeGameStructures	;random team pairs for all 8 gstruct games, none of them
	;HomeTeam or VisTeam. Called from FigureJoy (also after the regular season pad set-up).
	st	(gamenum).w
	clr.l	d3			;d3 = used team bits
	move.w	(HomeTeam).w,d1
	bset	d1,d3
	move.w	(VisTeam).w,d1
	bset	d1,d3
	movea.w	#(gstruct-M68K_RAM),a1
	moveq	#7,d2
.loop	bsr.w	GetRandomUnusedTeam
	move.w	d0,(a1)			;gst1
	bsr.w	GetRandomUnusedTeam
	move.w	d0,gst2(a1)
	adda.w	#gssize,a1
	dbf	d2,.loop
	rts

GetRandomUnusedTeam	;return d0 = random team 0-23 not yet set in d3, and set its bit.
	moveq	#$18,d0			;24 teams
	bsr.w	randomd0
	bset	d0,d3
	bne.s	GetRandomUnusedTeam	;already used, pick again
	rts

ReadPassBits	;translate the password bits at a3 (5 words) to the playoff variables. 92 ReadPassBits.
	;Called from NewPO and EncodePW. a3 = bits buffer, kept: the 5 words are saved and restored.
	;93 has no checksum (92 checked a 512 range checksum and set PoStarts -1 on failure)
	moveq	#4,d0
	lea	$A(a3),a0
.save	move.w	-(a0),-(sp)		;SuperDiv destroys the bits
	dbf	d0,.save
	moveq	#7,d2			;set gspobwins/gspotwins
	movea.w	#(gstruct+(7*gssize)-M68K_RAM),a1
.0	bclr	#gsfso,gsflags(a1)		;series over (92 gsfso)
	moveq	#5,d0
	bsr.w	SuperDiv
	move.w	d0,gspobwins(a1)
	cmp.w	#4,d0
	bne.w	.nsf0
	bset	#gsfso,gsflags(a1)		;4 wins: gsfso
.nsf0	moveq	#5,d0
	bsr.w	SuperDiv
	move.w	d0,gspotwins(a1)
	cmp.w	#4,d0
	bne.w	.nsf1
	bset	#gsfso,gsflags(a1)		;gsfso
.nsf1	suba.w	#gssize,a1
	dbf	d2,.0

	move.w	#$4000,d0		;set winbits (92 1<<14)
	bsr.w	SuperDiv
	move.w	d0,(WinBits).w

	moveq	#4,d0			;set POJoy
	bsr.w	SuperDiv
	move.w	d0,(pojoy).w	;92 pojoy

	moveq	#$10,d0			;set POTreeTeam
	bsr.w	SuperDiv
	move.w	d0,(potreeteam).w

	moveq	#4,d0			;set gamelevel
	bsr.w	SuperDiv
	move.w	d0,(gamelevel).w

	moveq	#8,d0			;set bosgames
	bsr.w	SuperDiv
	move.w	d0,(bosgames).w

	moveq	#$20,d0			;set PoStarts
	bsr.w	SuperDiv
	move.w	d0,(postarts).w
	moveq	#4,d0
	lea	(a3),a0
.restore	move.w	(sp)+,(a0)+	;put the bits back
	dbf	d0,.restore
	rts

EncodePW	;after playoff game compute winners and password if needed. Called from GameOver.
	tst.w	(OptPlayMode).w
	beq.w	rtss			;regular season
	move.w	#1,(OptPlayMode).w	;continue season

	bsr.w	ResolveGames
	bsr.w	maketree
	cmpi.w	#4,(gamelevel).w
	beq.w	.userwon		;finished playoffs
	tst.w	(gamenum).w
	bmi.w	.userwon		;93: po team out, same as a win (92 .userfailed / pojoy switch)
	movea.w	#(pwddatabuffer-M68K_RAM),a3		;password bits
	bsr.w	WritePassBits
	bsr.w	BitsToPW
	btst	#sf3alttree,(sflags3).w
	beq.w	rtss			;(92 retail; Rev A beq MakeTree)
	movea.w	#(tpassbits-M68K_RAM),a3		;bits before all games resolved (retail;, 92 tpassbits)
	bsr.w	ReadPassBits
	bra.w	maketree

.userwon	movea.w	#(pwddatabuffer-M68K_RAM),a3	;password bits
	bsr.w	ClrPassBits		;(92 ResetPassWord)
	bsr.w	BitsToPW
	move.w	#2,(OptPlayMode).w	;new playoffs
	cmpi.w	#7,(bosgames).w
	beq.w	rtss
	move.w	#3,(OptPlayMode).w	;new playoffs best of 7
	rts

WritePassBits	;transfer game variables to the password bits at a3. 92 WritePassBits, without the checksum.
	;Called from EncodePW and ResolveGames.
	bsr.w	ClrPassBits
	move.w	(postarts).w,d0
	moveq	#$20,d1
	bsr.w	PushBits

	move.w	(bosgames).w,d0
	moveq	#8,d1
	bsr.w	PushBits

	move.w	(gamelevel).w,d0
	moveq	#4,d1
	bsr.w	PushBits

	move.w	(potreeteam).w,d0
	moveq	#$10,d1
	bsr.w	PushBits

	move.w	(pojoy).w,d0	;92 pojoy
	moveq	#4,d1
	bsr.w	PushBits

	move.w	(WinBits).w,d0
	move.w	#$4000,d1		;92 1<<14
	bsr.w	PushBits

	moveq	#5,d1
	moveq	#7,d2
	movea.w	#(gstruct-M68K_RAM),a1
.0	move.w	gspotwins(a1),d0
	bsr.w	PushBits
	move.w	gspobwins(a1),d0
	bsr.w	PushBits
	adda.w	#gssize,a1
	dbf	d2,.0
	rts

PushBits	;bits = bits * d1 + d0.
	;d1=range	2^1-2^15
	;d0=data
	movem.l	d0-d1,-(sp)
	exg	d0,d1
	bsr.w	SuperMult
	clr.l	d0
	move.w	d1,d0
	bsr.w	SuperAdd
	movem.l	(sp)+,d0-d1
	rts

ClrPassBits	;clr the 5 words of bits at a3
	movea.w	a3,a0
	moveq	#4,d0
.0	clr.w	(a0)+
	dbf	d0,.0
	rts

SuperAdd	;1 long (d0.L) added to the 5 words at a3. 92 SuperAdd.
	movem.l	d1/a0,-(sp)
	lea	$A(a3),a0
	moveq	#3,d1
	add.l	d0,-(a0)
	bra.w	.2
.1	addq.w	#1,-(a0)		;carry into the next word up
.2	dbcc	d1,.1
	movem.l	(sp)+,d1/a0
	rts

SuperMult	;1 word (d0) multiplied by the 5 words at a3. 92 SuperMult.
	movem.l	d1-d4/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d4
.0	move.w	(a0),-(sp)
	clr.w	(a0)+
	dbf	d4,.0
	moveq	#4,d4
.1	move.w	d0,d1
	mulu.w	(sp)+,d1
	lea	2(a3),a0
	adda.w	d4,a0
	adda.w	d4,a0
	move.w	d4,d2
	add.l	d1,-(a0)
	bra.w	.3
.2	addq.w	#1,-(a0)
.3	dbcc	d2,.2
	dbf	d4,.1
	movem.l	(sp)+,d1-d4/a0
	rts

SuperDiv	;5 words at a3 divided by 1 word (d0). 92 SuperDiv.
	;d0 = remainder on exit
	movem.l	d1-d2/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d1
	clr.l	d2
.0	move.w	(a0),d2
	divu.w	d0,d2
	move.w	d2,(a0)+
	dbf	d1,.0
	swap	d2
	move.w	d2,d0
	movem.l	(sp)+,d1-d2/a0
	rts

GetShifter	;returns:
	;d1 = number of games-1
	;d2 = first bit of WinBits
	;Called from maketree, FigureJoy, ResolveGames, and the stats, intermission and penalty screens.
	move.l	d0,-(sp)
	moveq	#-$10,d2
	moveq	#$10,d1
	move.w	(gamelevel).w,d0
.3	add.w	d1,d2
	lsr.w	#1,d1
	dbf	d0,.3
	subq.w	#1,d1
	move.l	(sp)+,d0
	rts

DisplayTeamStatsForPlayoffs	;Adds the po team's game stats to its packed playoff
	;totals. Called from PeriodOver at the end of a playoff game. Unpacks the totals
	;(ReadTeamStats), adds the $68 stat bytes at team struct+$B4, then packs each total back into the
	;bit stream below $CB68, clamped to its BitWidthTable width (8, 10, 6, 6 bits, by d0 & 3).
	cmpi.w	#1,(OptPlayMode).w
	blt.w	rtss			;regular season
	bsr.w	ReadTeamStats
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2		;po team
	movea.w	#(tmstruct-M68K_RAM),a2
	cmp.w	$28(a2),d2		;team number of the home team struct
	beq.w	.area
	adda.w	#tmsize,a2		;po team is the visitor
.area	adda.w	#$B4,a2			;stat bytes in the team struct
	moveq	#$67,d0			;$68 stats
	movea.w	#(statsbuffer-M68K_RAM),a1
.acc	clr.w	d1
	move.b	(a2)+,d1
	add.w	d1,(a1)+
	dbf	d0,.acc
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2		;bit stream base
	moveq	#$67,d0
	clr.w	d4			;d4 = bit position
.loop	clr.l	d1
	move.w	(a0)+,d1
	move.w	d0,d2
	andi.w	#3,d2
	move.b	0(a1,d2.w),d2		;d2 = bit width
	clr.l	d3
	bset	d2,d3
	subq.w	#1,d3			;d3 = max value
	cmp.w	d3,d1
	ble.w	.pack
	move.w	d3,d1			;clamp
.pack	not.l	d3
	move.w	d4,d5
	andi.w	#$F,d5
	rol.l	d5,d3
	rol.l	d5,d1
	move.w	d4,d5
	lsr.w	#4,d5
	add.w	d5,d5
	neg.w	d5			;the stream runs down in words from base+$5E
	and.l	d3,$5E(a2,d5.w)
	or.l	d1,$5E(a2,d5.w)
	add.w	d2,d4
	dbf	d0,.loop
	rts

BitWidthTable	;playoff stat bit widths, indexed by stat number & 3.
	;Used by DisplayTeamStatsForPlayoffs and ReadTeamStats.
	dc.b	8,$A,6,6

ReadTeamStats	;Unpack the $68 playoff stat totals from the bit stream below $CB68
	;into statsbuffer words. Called from DisplayTeamStatsForPlayoffs and DisplayTeamStats.
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2		;bit stream base
	moveq	#$67,d0			;$68 stats
	clr.w	d4			;d4 = bit position
.loop	move.w	d4,d5
	lsr.w	#4,d5
	add.w	d5,d5
	neg.w	d5
	move.l	$5E(a2,d5.w),d1
	move.w	d4,d5
	andi.w	#$F,d5
	lsr.l	d5,d1
	move.w	d0,d2
	andi.w	#3,d2
	move.b	0(a1,d2.w),d2		;d2 = bit width
	add.w	d2,d4
	clr.w	d3
	bset	d2,d3
	subq.w	#1,d3
	and.w	d3,d1			;mask to width
	move.w	d1,(a0)+
	dbf	d0,.loop
	rts

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $1499E-$15109
;	92 ResolveGames, then the 93-only end of game "Stars of the Game" box (DisplayPeriodOver
;	FindMaxAttributeTEam, CalculateTeamAttributes/Values), the injury and goal boxes, box, the player name
;	formatters (getname ... ConverByteToDigits), and the 92 exception handlers AddError, Illinst, ZeroDiv
;	and crash. cd0 onward.
;Global names from the 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;The saved password bits are tpassbits (92 name; ).
;	gsflags bit 0 is 92 gsftf (teams flipped). Team struct bytes per roster slot (26): $B4 goals (goals
;	against for a goalie), $CE assists, $E8 shots (shots against for a goalie); word $136 frames on ice.
;	A goal entry (ScoreSum, 6 bytes): word period/time, byte 2 bit 7 away team scored, byte 3 scorer,
;	bytes 4 and 5 assists (negative: none). ChkCnt + ScoreSumbytes is the last entry.

ResolveGames	;compute winners and losers for playoff matchups. 92 ResolveGames. Called from EncodePW
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gstruct-M68K_RAM),a0
	move.w	(tmstruct+tmscore).w,gss1(a0,d0.w)	;copy score from played game into game structures
	move.w	(awtmstruct+tmscore).w,gss2(a0,d0.w)

	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	cmpi.w	#7,(bosgames).w
	beq.w	.notbos			;not best of 7
.b0	cmpi.w	#4,gspotwins(a0)
	beq.w	.b1
	cmpi.w	#4,gspobwins(a0)
	beq.w	.b1
	clr.w	d3
	btst	#gsftf,gsflags(a0)		;teams flipped (92 gsftf)
	beq.w	.nf
	eori.w	#gspobwins-gspotwins,d3
.nf	move.w	gss1(a0),d0
	sub.w	gss2(a0),d0
	bpl.w	.ns1
	eori.w	#gspobwins-gspotwins,d3
.ns1	addq.w	#1,gspotwins(a0,d3.w)
.b1	suba.w	#gssize,a0
	dbf	d1,.b0
	addq.w	#1,(bosgames).w
	cmpi.w	#7,(bosgames).w
	beq.w	.nextround
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gstruct-M68K_RAM),a0
	adda.w	d0,a0
	cmpi.w	#4,gspotwins(a0)
	beq.w	.cround
	cmpi.w	#4,gspobwins(a0)
	bne.w	rtss
.cround	cmpi.w	#3,(gamelevel).w	;finish off rest of round games here
	bge.w	.nextround
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
.cr0	cmp.w	(gamenum).w,d1
	beq.w	.crn
	cmpi.w	#4,gspotwins(a0)
	beq.w	.crn
	cmpi.w	#4,gspobwins(a0)
	beq.w	.crn
	addq.w	#1,gspotwins(a0)
	move.l	#200,d0
	bsr.w	randomd0
	andi.w	#1,d0
	beq.s	.cr0
	subq.w	#1,gspotwins(a0)
	addq.w	#1,gspobwins(a0)
	bra.s	.cr0
.crn	suba.w	#gssize,a0
	dbf	d1,.cr0
	movea.w	#(tpassbits-M68K_RAM),a3		;bits before advancing to next round (retail;, 92 tpassbits)
	bsr.w	WritePassBits		;(92 wrote passbits and copied them to tpassbits)
	bset	#sf3alttree,(sflags3).w

.nextround	clr.w	(bosgames).w	;advance to next round
	bsr.w	GetShifter
	movea.w	#(gstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	clr.w	d3
.nr0	cmpi.w	#4,gspotwins(a0)
	beq.w	.nr1
	bset	d1,d3
.nr1	clr.w	gspotwins(a0)
	clr.w	gspobwins(a0)
	suba.w	#gssize,a0
	dbf	d1,.nr0
	moveq	#1,d1			;(92 Rev A only) clear this round's winbits
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts

.notbos	clr.w	d3		;solve for no best of 7 playoffs (much simpler)
.nb0	move.w	gss1(a0),d0
	cmp.w	gss2(a0),d0
	bhi.w	.nb1
	bset	d1,d3
.nb1	btst	#gsftf,gsflags(a0)		;teams flipped (92 gsftf)
	beq.w	.nb2
	bchg	d1,d3
.nb2	suba.w	#gssize,a0
	dbf	d1,.nb0
	moveq	#1,d1			;(92 Rev A only)
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts

DisplayPeriodOver	;end of game "Stars of the Game" box. Called from UpdatePA while RefPen is
	;the game over penalty. Waits for RefCnt <= $40 and runs once (gmode bit 7). Frames the box, draws a bitmap
	;from IceRinkMap, then the three best star scores (FindMaxAttributeTEam): team data string and getname.
	;Song $F when the home team won.
	cmpi.w	#$40,(RefCnt).w
	bgt.w	rtss			;ref animation not far enough yet
	bset	#7,(gmode).w
	bne.w	rtss			;already shown
	movem.l	d0-d5/a0-a4,-(sp)
	bsr.w	printz
	String	$BF,2,$E
	moveq	#$1C,d0			;framer size
	moveq	#9,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,9,$10,'Stars of the Game',$BF,3,$F
	movea.l	#IceRinkMap,a1		;in the string. map at IceRinkMap offset 4
	movea.w	#$310,a2
	adda.l	4(a1),a1
	moveq	#$D,d0			;dobitmap d0-d5
	moveq	#$5B,d1
	moveq	#6,d2
	moveq	#4,d3
	move.w	(rinkvrcset).w,d4
	clr.w	d5
	bsr.w	dobitmap
	bsr.w	CalculateTeamAttributes
	move.w	#$12,(printy).w
	moveq	#2,d2			;3 stars
.loop	bsr.w	FindMaxAttributeTEam	;a2 = team, d0 = player
	move.w	#$1A,(printx).w
	addq.w	#1,(printy).w
	movea.l	tmdata(a2),a1		;string at team data offset 4, then its first offset
	adda.w	4(a1),a1
	adda.w	(a1),a1
	bsr.w	print
	bsr.w	getname			;a1 = number and name of player d0
	move.w	#3,(printx).w
	bsr.w	print
	dbf	d2,.loop
	move.w	(tmstruct+tmscore).w,d0	;home score
	sub.w	(awtmstruct+tmscore).w,d0	;- visitor score
	ble.w	.nosong
	move.w	#SFXhomewin,-(sp)		;song $F: home team won
	bsr.w	song
.nosong	movem.l	(sp)+,d0-d5/a0-a4
	rts

FindMaxAttributeTEam	;take the highest of the 52 star scores at DispAttribCtr (26 per team, home first)
	;and clear it. Returns d0 = player slot, a2 = its team struct. Called from DisplayPeriodOver
	movem.l	d1-d2/a1/a4,-(sp)
	movea.w	#(DispAttribCtr-M68K_RAM),a4
	clr.l	d0			;best so far
	moveq	#$33,d2			;52 scores
.find	cmp.l	(a4)+,d0
	bge.w	.next			;not higher
	lea	-4(a4),a1		;a1 = best entry
	move.l	(a1),d0
.next	dbf	d2,.find
	clr.l	(a1)			;taken
	move.w	a1,d0
	subi.w	#(DispAttribCtr-M68K_RAM),d0
	lsr.w	#2,d0			;entry number
	movea.w	#(tmstruct-M68K_RAM),a2
	cmp.w	#$1A,d0
	blt.w	.home			;0-25: home team
	subi.w	#$1A,d0
	adda.w	#tmsize,a2		;26-51: away team
.home	movem.l	(sp)+,d1-d2/a1/a4
	rts

CalculateTeamAttributes	;star score for every roster slot of both teams to DispAttribCtr (26 longs per
	;team, home first). d5 = GetPeriodTime + d2, the goalie ice time needed. If gsp is 3 and the score is
	;not tied, the scorer of the last goal gets $7FFFFFFF. Called from DisplayPeriodOver
	movea.w	#(DispAttribCtr-M68K_RAM),a4
	jsr	(GetPeriodTime).w
	move.w	d0,d5
	add.w	d2,d5
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3		;a3 = other team
	bsr.w	CalculateTeamAttributeValues	;home
	movea.w	a3,a2
	lea	-tmsize(a2),a3
	bsr.w	CalculateTeamAttributeValues	;away (d3 = away - home score)
	cmpi.w	#3,(gsp).w
	bne.w	.x
	tst.w	d3
	beq.w	.x			;tied
	movea.w	#(ChkCnt-M68K_RAM),a0	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a0
	clr.w	d0
	btst	#7,2(a0)
	beq.w	.slot			;home goal
	addi.w	#$1A,d0			;away goal: second 26 entries
.slot	add.b	3(a0),d0		;scorer
	asl.w	#2,d0
	movea.w	#(DispAttribCtr-M68K_RAM),a0
	move.l	#$7FFFFFFF,0(a0,d0.w)	;game winner is the first star
.x	rts

CalculateTeamAttributeValues	;star scores of team a2 (a3 = other team) to (a4)+, one long per roster
	;slot (26). Each starts at the goal difference. Skaters: goals*11000 + assists*10100 + shots*10, or in a
	;tied game shots*1000 + frames on ice. Goalies (the first slots) on ice at least d5 with shots against:
	;+32000 if goals against*100/shots <= 4, +75000 more for a shutout. Called from CalculateTeamAttributes
	movea.w	a2,a1
	move.w	tmscore(a2),d3
	sub.w	tmscore(a3),d3		;goal difference
	ext.l	d3
	moveq	#$19,d4			;26 slots
	jsr	(ReadAttributeNibble).l	;d0 = goalies on the team
	neg.w	d0
	add.w	d4,d0			;d4 above $19 - goalies: goalie slot
.loop	move.l	d3,(a4)
	cmp.w	d0,d4
	bhi.w	.goalie
	clr.w	d1
	move.b	$B4(a2),d1		;goals
	mulu.w	#$2AF8,d1		;11000
	add.l	d1,(a4)
	clr.w	d1
	move.b	$CE(a2),d1		;assists
	mulu.w	#$2774,d1		;10100
	add.l	d1,(a4)
	clr.w	d1
	move.b	$E8(a2),d1		;shots
	mulu.w	#$A,d1
	tst.w	d3
	bne.w	.add			;not tied: shots*10
	mulu.w	#$64,d1			;tied: shots*1000
	add.l	d1,(a4)
	clr.l	d1
	add.w	$136(a1),d1		;+ frames on ice
.add	add.l	d1,(a4)
	bra.w	.next
.goalie	cmp.w	$136(a1),d5
	bhi.w	.next			;not on ice long enough
	clr.w	d1
	move.b	$B4(a2),d1		;goals against
	mulu.w	#$64,d1
	clr.w	d2
	move.b	$E8(a2),d2		;shots against
	beq.w	.next
	divu.w	d2,d1
	cmp.w	#4,d1
	bhi.w	.next
	addi.l	#$7D00,(a4)		;32000
	tst.w	d1
	bne.w	.next
	addi.l	#$124F8,(a4)		;75000 for a shutout ( a constant, not a label)
.next	addq.w	#2,a1
	addq.w	#1,a2
	addq.w	#4,a4
	dbf	d4,.loop
	rts

ShowInjuryBox	;injury box "Injury to:" player TempPlOffset (set by setInjuryType)
	;"Out for period", or "the game" when puckx+pflags2 bit pf2fight is set. Jumped to (jmp abs.l) from
	;CheckInjury when InjCntDown runs out, so global
	movem.l	d0-d2/a0-a4,-(sp)
	bsr.w	printz
	String	$BF,$B,3
	moveq	#$12,d0			;framer size
	moveq	#5,d1
	bsr.w	Framer
	bsr.w	printz
	String	$BF,$C,4,'Injury to:',$BF,$C,6,'Out for period',$BF,$C,5
	bsr.w	GetPlayerNameWithAttrib	;in the string
	bsr.w	print
	btst	#pf2fight,(puckx+pflags2).w
	beq.w	.ex
	bsr.w	printz
	String	$BF,$14,6,'the game'	;over "period"
.ex	movem.l	(sp)+,d0-d2/a0-a4	;( in the string)
	rts

DisplayPlayerAttributeMenu	;goal box. Closes both line change boxes, then printbig "GOAL!" (or "HAT
	;TRICK!" on the scorer's third goal), the scorer and up to two assists of the last goal entry.
	;Called from SetPA for the goal penalty number
	movem.l	d0-d2/a0-a4,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	jsr	(lcfound2).l		;close lc box
	adda.w	#tmsize,a2
	jsr	(lcfound2).l
	movea.w	#(ChkCnt-M68K_RAM),a4	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a4
	bsr.w	printz
	String	$BF,$B,2
	moveq	#$13,d0			;in the string. framer size
	moveq	#5,d1			;5 rows: no assist
	tst.b	4(a4)
	bmi.w	.frame
	addq.w	#2,d1			;7: one assist
	tst.b	5(a4)
	bmi.w	.frame
	addq.w	#1,d1			;8: two assists
.frame	bsr.w	Framer
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#7,2(a4)
	beq.w	.home			;home team scored
	adda.w	#tmsize,a2
.home	lea	attrText(pc),a1
	clr.w	d0
	move.b	3(a4),d0		;scorer
	addi.w	#$B4,d0
	cmpi.b	#3,0(a2,d0.w)		;goals
	bne.w	.print
	adda.w	(a1),a1			;third goal: HAT TRICK!
.print	bsr.w	printbig
	clr.w	d0
	move.b	3(a4),d0
	bsr.w	FormatPlayerNameWithAttrib
	bsr.w	print
	clr.w	d0
	move.b	4(a4),d0		;first assist
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$E,6,'Assist by:',$BF,$C,7
	bsr.w	FormatPlayerNameWithAttrib	;in the string
	bsr.w	print
	clr.w	d0
	move.b	5(a4),d0		;second assist
	bmi.w	.ex
	bsr.w	printz
	String	$BF,$C,8
	bsr.w	FormatPlayerNameWithAttrib	;and the next line in the string
	bsr.w	print
.ex	movem.l	(sp)+,d0-d2/a0-a4
	rts

attrText	;printbig strings for DisplayPlayerAttributeMenu: GOAL!, then HAT TRICK!
	String	$BF,$F,3,'GOAL!',$BF,$C,5
	String	$BF,$C,3,'HAT TRICK!',$BF,$C,5

box	;fill a $13 x 8 rectangle at printz position $FF,$B,2 with char $7FF (eraser).
	;Called from SetLCmode2 and banner
	bsr.w	printz
	String	$FF,$B,2
	moveq	#$13,d0			;in the string
	moveq	#8,d1
	move.l	#$7FF,d2
	bra.w	eraser

GetPlayerName	;a1 = mesarea "NN First Last" (getname) for player TempPlOffset (bit 15 set: away
	;team). Called from UpdatePA
	movem.l	d0/a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2		;away team
.get	bsr.w	getname
	movem.l	(sp)+,d0/a2
	rts

getname	;a1 = mesarea string "NN First Last" for player d0 of team a2. The number is the bcd byte
	;after the name. Called from DisplayPeriodOver, GetPlayerName, banner and others
	movem.l	d0-d3/a0/a2-a3,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#4,(a3)			;length word + 2 digits
	lea	2(a3),a1
	adda.w	(a0),a0			;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	bsr.w	appendz
	String	' '
	movea.l	(sp)+,a1		;name string
	bsr.w	appstring
	movea.w	#(mesarea-M68K_RAM),a1
	movem.l	(sp)+,d0-d3/a0/a2-a3
	rts

GetPlayerNameWithAttrib	;a1 = mesarea "NN F. Last" (FormatPlayerNameWithAttrib) for player
	;TempPlOffset (bit 15 set: away team). Called from ShowInjuryBox
	movem.l	d0/a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2		;away team
.get	bsr.w	FormatPlayerNameWithAttrib
	movem.l	(sp)+,d0/a2
	rts

FormatPlayerNameWithAttrib	;a1 = mesarea string "NN F. Last" for player d0 of team a2, built in
	;TextBuffer. Called from DisplayPlayerAttributeMenu, GetPlayerNameWithAttrib, PrintPeriodTime and others
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0			;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	move.b	#$20,(a1)+		;' '
	movea.l	(sp)+,a0
	move.w	(a0)+,d0		;string length
	lea	-2(a0,d0.w),a2		;end of the name
	move.b	(a0)+,(a1)+		;first initial
	move.w	#$2E20,(a1)+		;'. '
.skip	cmpi.b	#$20,(a0)+		;skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+		;last name
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FormatPlayerName	;a1 = mesarea string "NN Last" for player d0 of team a2, built in TextBuffer.
	;Called from DisplayAttributeEntry
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0			;byte after the name: number
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	move.b	#$20,(a1)+		;' '
	movea.l	(sp)+,a0
	move.w	(a0)+,d0		;string length
	lea	-2(a0,d0.w),a2		;end of the name
.skip	cmpi.b	#$20,(a0)+		;skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+		;last name
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FormatPlayerNameShort	;a1 = mesarea string " Last" for player d0 of team a2, space padded to 12
	;characters; a 0 byte also ends the name. Called from DrawMenuIcon
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	movea.w	#(TextBuffer-M68K_RAM),a1
	move.b	#$20,(a1)+		;' '
	move.w	(a0)+,d0		;string length
	lea	-2(a0,d0.w),a2		;end of the name
.skip	cmpi.b	#$20,(a0)+		;skip the first name
	bne.s	.skip
.copy	move.b	(a0)+,(a1)+		;last name
	cmpa.l	a0,a2
	beq.w	.chk
	tst.b	(a0)
	bne.s	.copy
	bra.w	.chk
.pad	move.b	#$20,(a1)+
.chk	cmpa.w	#$BEC4,a1		;TextBuffer+12
	blt.s	.pad
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts

FinalizeTextBuffer	;mesarea length word = a1 - mesarea, with a 0 pad byte when odd. Returns
	;a1 = mesarea. Called from the FormatPlayerName routines
	move.w	a1,d0
	subi.w	#(mesarea-M68K_RAM),d0
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even	movea.w	#(mesarea-M68K_RAM),a1
	move.w	d0,(a1)
	rts

GetPlayerNamePointer	;a0 = name string of player d0 on team a2. From tmdata and its first offset
	;each record is a length word string and 8 more bytes
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0
	bra.w	.cnt
.next	adda.w	(a0),a0			;skip the name
	addq.w	#8,a0
.cnt	dbf	d0,.next
	rts

ConverByteToDigits	;two ascii digits of bcd byte d0 to (a1)+, a leading 0 becomes a space.
	;Called from getname, the FormatPlayerName routines, pplpen and others
	move.w	d0,-(sp)
	lsr.b	#4,d0
	bne.w	.digit
	move.b	#$F0,d0			;$F0+'0' = ' '
.digit	addi.b	#$30,d0			;'0'
	move.b	d0,(a1)+
	move.w	(sp)+,d0
	andi.w	#$F,d0
	addi.b	#$30,d0			;'0'
	move.b	d0,(a1)+
	rts

AddError	;address error vector. 92 AddError. 93 has no BusError: the bus error vector also points here
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Address Error'	;92 -$43
	move.l	$A(sp),d0		;pc
	move.l	2(sp),d1		;access address
	bra.w	crash

Illinst	;illegal instruction vector. 92 Illinst
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Illegal Instruction'
	move.l	2(sp),d0
	move.l	d0,d1
	bra.w	crash

ZeroDiv	;divide by zero vector. 92 ZeroDiv, falls into crash
	move.w	#$2700,sr
	bsr.w	printbigz
	String	$BD,0,0,'Division by zero'
	move.l	2(sp),d0		;and the next line in the string
	move.l	d0,d1

crash	;printbig d1 then d0 as hex, set the vdp up, load a palette and hang. 92 crash; 93 copies 8 longs from
	;IceRinkMap+$20 to cram $20 (92 wrote one colour $0EEE to cram 6)
	movea.w	#(mesarea-M68K_RAM),a0
	move.w	#2+3+8+3+8,(a0)+
	move.b	#$BD,(a0)+		;92 -$43
	move.b	#0,(a0)+
	move.b	#2,(a0)+
	move.l	d1,-(sp)
	bsr.w	.ri

	move.b	#$BD,(a0)+
	move.b	#0,(a0)+
	move.b	#4,(a0)+
	move.l	(sp)+,d0
	bsr.w	.ri

	movea.w	#(mesarea-M68K_RAM),a1
	bsr.w	printbig

	movea.l	#VDP_DATA,a0		;92 Vdata
	move.w	#$9100,4(a0)
	move.w	#$9206,4(a0)
	move.w	#$8F02,4(a0)
	move.l	#$C0200000,4(a0)	;cram write $20 (92 $C0060000)
	movea.l	#IceRinkMap,a1
	adda.l	(a1),a1
	adda.w	#$20,a1
	moveq	#7,d0
.pal	move.l	(a1)+,(a0)
	dbf	d0,.pal
.end	bra.w	.end

.ri	moveq	#7,d2			;d0 as 8 hex digits to (a0)+
.top	rol.l	#4,d0
	move.w	d0,d1
	andi.w	#$F,d1
	addi.w	#$30,d1			;'0'
	cmp.w	#$39,d1			;'9'
	ble.w	.t1
	addq.w	#7,d1			;'A'-'0'-10
.t1	move.b	d1,(a0)+
	dbf	d2,.top
	rts

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment $1510A-$15FE5
;	Data only: the 92 crowd frame table (updatecrowdf .cd0), the player logic assignment table asstab,
;	the 93 PenaltyList, bfasciicon, linelist, PlayerPositionText, PerLabels, sizetab, sublist,
;	priolist, the playoff tree layout (92 PlayoffScreen .setup), the line editor / roster attribute
;	column lists, and the menu item lists for the pause, intermission and line editor exit menus.
;	(BackupRAM_*) starts at $15FE6.
;Global names from the 92 names where the table is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	Code addresses in the tables are retail addresses of the routines in earlier segments; the
;	Rev A listing has them $E or $18 higher.
;	Menu item lists (InitMenuState): two printsmall control Strings, then per item a
;	String and the handler address (dc.l). Item 0 leaves the menu, its handler is rtss. String $FF ends.

cd0	;$fftt = frame/time for various levels of crowd excitement. 92 updatecrowdf .cd0, same bytes.
	;Global in 93: used by updatecrowdf, indexed by crowd level and crowdstep
	dc.w	$010c,$020c,$030c,$040c,$050c,$0a0c,$090c,$080c
	dc.w	$060c,$070c,$080c,$090c,$0a0c,$050c,$040c,$030c

	dc.w	$0107,$0207,$0307,$0407,$0507,$0b07,$0c07,$0d07
	dc.w	$0607,$0707,$0807,$0907,$0a07,$0b07,$0c07,$0d07

	dc.w	$0e07,$0f07,$1007,$1107,$1207,$0b07,$0c07,$0d07
	dc.w	$1207,$1107,$1007,$0f07,$0e07,$0d07,$0c07,$0b07

	dc.w	$0e03,$0f03,$1003,$1103,$1203,$0b03,$0c03,$0d03
	dc.w	$1203,$1103,$1003,$0f03,$0e03,$0d03,$0c03,$0b03

asstab	;jump table of all the player logic assignments. 92 asstab without assnothing, so from
	;assscore on the 93 numbers are one lower than 92. Used by updateplayers
	dc.l	rtss			;0
	dc.l	assdefo			;1 adefo
	dc.l	assdefd			;2 adefd
	dc.l	asswingd		;3 awingd
	dc.l	asswingo		;4 awingo
	dc.l	asscenterd		;5 acenterd
	dc.l	asscentero		;6 acentero
	dc.l	assscore		;7 ascore
	dc.l	assstanley		;8 astanley
	dc.l	asseben			;9 aeben
	dc.l	assepen			;$A aepen
	dc.l	assbench		;$B abench
	dc.l	asspenalty		;$C apenalty
	dc.l	assdopen		;$D adopen
	dc.l	assgoalie		;$E agoalie
	dc.l	assgoalietopuck		;$F
	dc.l	asspuckc		;$10 apuckc
	dc.l	assnearest		;$11 anearest
	dc.l	assshoot		;$12 ashoot
	dc.l	asspassrec		;$13 apassrec
	dc.l	assfight		;$14 afight
	dc.l	assfwatch		;$15
	dc.l	assfaceoff		;$16
	dc.l	assfaceoffpl		;$17
	dc.l	pucknorm		;$18 puck logic
	dc.l	puckshadow		;$19
	dc.l	pucknothing		;$1A (in the Rev A listing)
	dc.l	puckfaceoff		;$1B
	dc.l	puckfaceoff2		;$1C

Penaltylist	;Penalty number = word offset into this table; 93 reorders the numbers
	;and has 3 more entries. Used by AddPenalty, SetPA2, DisplayPenaltyEntry, ...
	dc.w	$0000
	dc.w	.eop-Penaltylist	;2 period over (92 PenEOP 2)
	dc.w	.eog-Penaltylist	;4 game over (92 PenEOG 4)
	dc.w	.ghold-Penaltylist	;6 (92 PenOOP $C)
	dc.w	.ghold-Penaltylist	;8 (92 PenGhold $E)
	dc.w	.whistle-Penaltylist	;$A whistle (92 PenWhistle $26)
	dc.w	.ice-Penaltylist	;$C icing (92 PenIcing 8)
	dc.w	.goal-Penaltylist	;$E goal (92 PenGoal 6)
	dc.w	.offsides-Penaltylist	;$10 offsides (92 PenOffsides $A)
	dc.w	.rough2-Penaltylist	;$12 roughing, slow down time $A
	dc.w	.p14-Penaltylist	;$14 no text
	dc.w	.charge-Penaltylist	;$16
	dc.w	.slash-Penaltylist	;$18
	dc.w	.rough-Penaltylist	;$1A
	dc.w	.cross-Penaltylist	;$1C
	dc.w	.hook-Penaltylist	;$1E
	dc.w	.trip-Penaltylist	;$20
	dc.w	.int-Penaltylist	;$22
	dc.w	.hold-Penaltylist	;$24
	dc.w	.fight-Penaltylist	;$26
	dc.w	.fight2-Penaltylist	;$28
	dc.w	.inst-Penaltylist	;$2A
	dc.w	.delay-Penaltylist	;$2C delay (92 PenDelay $24)

;format
;	dc.w	$ttmm	;tt=slow dnw time in half secs,mm=penalty min.
;	String	'penalty text'
;	dc.w	$ffdd,$ffdd,$ffdd,...	;ff = frame,dd=delay (neg for end)

.eop	dc.w	$0100
	String	'Period Over'
	dc.w	-$0510
.eog	dc.w	$0100
	String	'Game Over'
	dc.w	$0510,-$4060
.goal	dc.w	$0100
	dc.w	2			;String with no text (92 'Goal!')
	dc.w	$050a,-$4010
.p14	dc.w	$0100
	dc.w	2			;String with no text
	dc.w	$0510,-$4018
.ice	dc.w	$0100
	String	'Icing'
	dc.w	$0002,$0101,-$0206
.offsides	dc.w	$0100
	String	'Off-side'
	dc.w	$0002,$0301,-$040f
.ghold	dc.w	$0100
	String	'Face Off'
	dc.w	-$050a
.delay	dc.w	$0000
	String	'Penalty'
	dc.w	$0003,$0301,-$040f

.whistle	dc.w	$0000
	dc.w	2			;String with no text
	dc.w	-$050a

.charge	dc.w	$0402
	String	'Charging'
	dc.w	$0004,$0101,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,-$0101

.slash	dc.w	$0402
	String	'Slashing'
	dc.w	$0004,$0101,$0201,$0301,$0201,$0301,$0201,$0301,$0201,$0301,-$0101

.trip	dc.w	$0402
	String	'Tripping'
	dc.w	$0004,$0401,$0501,$0401,$0501,$0401,$0501,$0401,$0501,-$0101

.rough2	dc.w	$0a02
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

.rough	dc.w	$0402
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

.hook	dc.w	$0402
	String	'Hooking'
	dc.w	$0004,$0101,$0901,$0801,$0901,$0801,$0901,$0801,$0901,$0801,-$0101

.cross	dc.w	$0402
	String	'Cross Check'
	dc.w	$0004,$0601,$0f01,$1001,$0f01,$1001,$0f01,$1001,$0f01,$1001,-$0101

.int	dc.w	$0402
	String	'Interference'
	dc.w	$0004,$0101,$0c06,-$0101

.hold	dc.w	$0402
	String	'Holding'
	dc.w	$0004,$0101,$0706,-$0101

.fight	dc.w	$2805
	String	'Fighting'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.fight2	dc.w	$2805
	String	'Fighting *'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.inst	dc.w	$2802
	String	'Fight Instigator'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

bfasciicon	;equates to find each char definition for bigfont.map. 92 bfasciicon, 93 values.
	;Indexed by ascii - $20 in printbig.dochar
	;	 - -! " # $ % & -' * +, - -. /
	dc.b	-76,-73,00,00,00,00,00,-71,00,00,00,00,00,00,-72,00
	;	 0   1  2  3  4  5  6  7  8  9   :  ;  <  =  >  ?
	dc.b	51,-53,54,56,58,60,62,64,66,68,-71,00,00,00,00,74
	;	@  A  B  C  D  E  F  G	H  -I  J  K  L  M  N  O
	dc.b	74,00,02,04,06,08,10,12,14,-16,17,19,21,23,25,27
	;	P  Q  R  S  T  U  V  W	X  Y  Z
	dc.b	29,31,33,35,37,39,41,43,45,47,49
	IF REV=0
	dc.b	$F0			;pad, retail byte (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

linelist	String	'Sc1'	;text list for line choices. 92 linelist (93 PP1/PP2, 92 Pw1/Pw2).
	;Used by SetLCmode2, puckfaceoff2 and DrawMenuIcon
	String	'Sc2'
	String	'Chk'
	String	'PP1'
	String	'PP2'
	String	'PK1'
	String	'PK2'

PlayerPositionText	;position names for the line slots. Used by DisplayPlayerList
	String	'LD'
	String	'RD'
	String	'LW'
	String	'C'
	String	'RW'

PerLabels	String	'1',18	;text list for periods. 92 PerLabels. Used by printscores1, NewTicker3 and
	;DisplayGameInfo
	String	'2',19
	String	'3',20
	String	'OT'
	String	'Final'

sizetab	;sprite size code to tile count. 92 sizetab, used by addframe2
	dc.b	1,2,3,4,2,4,6,8,3,6,9,12,4,8,12,16

sublist	;substitution lists by position (goalie, LD, RD, LW, C, RW, extra attacker). 92 sublist;
	;93 uses word offsets from sublist (92 long pointers). Used by SetPlList
	dc.w	.defl-sublist		;goalie
	dc.w	.defl-sublist
	dc.w	.defr-sublist
	dc.w	.wingl-sublist
	dc.w	.center-sublist
	dc.w	.wingr-sublist
	dc.w	.center-sublist

.defl	dc.b	0+1,8+1,16+1,24+1,32+1,40+1,48+1	;list of players in there lines/each line = 8 bytes
	dc.b	0+2,8+2,16+2,24+2,32+2,40+2,48+2
.defr	dc.b	0+2,8+2,16+2,24+2,32+2,40+2,48+2
	dc.b	0+1,8+1,16+1,24+1,32+1,40+1,48+1
.wingl	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
.wingr	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
.center	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	-1

priolist	dc.b	0,1,2,4,3,5,6	;positions in order of importance. 92 priolist. Used by SetPlList,
	;releasepl and getlinee
	IF REV=0
	dc.b	$23			;pad, retail byte (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

PlayoffTreeSetup	;Playoff tree layout by gamelevel. 92 PlayoffScreen.setup, same layout
	;with 93 columns. Used by PlayoffScreen
	dc.w	.l0-PlayoffTreeSetup
	dc.w	.l1-PlayoffTreeSetup
	dc.w	.l2-PlayoffTreeSetup
	dc.w	.l3-PlayoffTreeSetup
	dc.w	.l4-PlayoffTreeSetup

	;tree graphics for level 0: teams-1 then x,y per team (DrawTeamBlocks), arrows-1 then x,d0 per
	;arrow (DrawPlayoffBracket), scores-1 then x,y per score (FormatScore, negative: none)
.l0	dc.b	16-1
	dc.b	45,2,45,5,45,8,45,11,45,14,45,17,45,20,45,23
	dc.b	71,2,71,5,71,8,71,11,71,14,71,17,71,20,71,23
	dc.b	1,57,0,69,10
	dc.b	7,50,4,50,10,50,16,50,22,75,4,75,10,75,16,75,22

	;tree graphics for level 1
.l1	dc.b	16+8-1
	dc.b	31,2,31,5,31,8,31,11,31,14,31,17,31,20,31,23
	dc.b	85,2,85,5,85,8,85,11,85,14,85,17,85,20,85,23
	dc.b	45,4,45,10,45,15,45,21
	dc.b	71,4,71,10,71,15,71,21
	dc.b	3,43,0,57,2,69,8,83,10
	dc.b	3,50,8,50,18,75,8,75,18

	;tree graphics for level 2
.l2	dc.b	16+8+4-1
	dc.b	17,2,17,5,17,8,17,11,17,14,17,17,17,20,17,23
	dc.b	99,2,99,5,99,8,99,11,99,14,99,17,99,20,99,23
	dc.b	31,4,31,10,31,15,31,21
	dc.b	85,4,85,10,85,15,85,21
	dc.b	45,7,45,18
	dc.b	71,7,71,18
	dc.b	5,29,0,43,2,57,4,69,6,83,8,97,10
	dc.b	1,50,13,75,13

	;tree graphics for level 3
.l3	dc.b	16+8+4+2-1
	dc.b	3,2,3,5,3,8,3,11,3,14,3,17,3,20,3,23
	dc.b	113,2,113,5,113,8,113,11,113,14,113,17,113,20,113,23
	dc.b	17,4,17,10,17,15,17,21
	dc.b	99,4,99,10,99,15,99,21
	dc.b	31,7,31,18
	dc.b	85,7,85,18
	dc.b	45,12
	dc.b	71,12
	dc.b	5,15,0,29,2,43,4,83,6,97,8,111,10
	dc.b	0,63,23

	;tree graphics for level 4
.l4	dc.b	16+8+4+2+1-1
	dc.b	3,2,3,5,3,8,3,11,3,14,3,17,3,20,3,23
	dc.b	113,2,113,5,113,8,113,11,113,14,113,17,113,20,113,23
	dc.b	17,4,17,10,17,15,17,21
	dc.b	99,4,99,10,99,15,99,21
	dc.b	31,7,31,18
	dc.b	85,7,85,18
	dc.b	45,12
	dc.b	71,12
	dc.b	58,23
	dc.b	5,15,0,29,2,43,4,83,6,97,8,111,10
	dc.b	-1			;no scores
	IF REV=0
	dc.b	$47			;pad, retail byte (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

PAttribColumns	;skater attribute columns for PrintAttribHeader / DisplayPlayerList.
	;String header, then a long for GetNameandAttrib: high word = mask of rating nibbles to
	;average, low word = attribjmp offset (0 status, 2 energy, 4 handed, 6 weight, 8 fighting,
	;$A rating). A negative word ends the list
	String	'     Status    ]'
	dc.w	$0000,0			;status
	String	'[   Overall    ]'
	dc.w	$1f3a,$a		;rating
	String	'[   Energy     ]'
	dc.w	$0000,2			;energy
	String	'[   Agility    ]'
	dc.w	$1000,$a
	String	'[    Speed     ]'
	dc.w	$0800,$a
	String	'[   Handed     ]'
	dc.w	$0040,4			;handed
	String	'[Off. Awareness]'
	dc.w	$0400,$a
	String	'[Def. Awareness]'
	dc.w	$0200,$a
	String	'[  Shot Power  ]'
	dc.w	$0100,$a
	String	'[Shot  Accuracy]'
	dc.w	$0010,$a
	String	'[Pass  Accuracy]'
	dc.w	$0002,$a
	String	'[Stick Handling]'
	dc.w	$0020,$a
	String	'[    Weight    ]'
	dc.w	$2000,6			;weight
	String	'[  Endurance   ]'
	dc.w	$0008,$a
	String	'[Aggressiveness]'
	dc.w	$0001,$a
	String	'[   Checking   ]'
	dc.w	$0080,$a
	String	'[   Fighting    '
	dc.w	$0040,8			;fighting
	dc.w	-1

GAttribColumns	;goalie attribute columns, same format as PAttribColumns. Used by
	;DisplayPlayerList
	String	'     Status    ]'
	dc.w	$0000,0			;status
	String	'[   Overall    ]'
	dc.w	$1b0f,$a		;rating
	String	'[   Agility    ]'
	dc.w	$1000,$a
	String	'[    Speed     ]'
	dc.w	$0800,$a
	String	'[  Glove Hand  ]'
	dc.w	$0040,4			;handed
	String	'[Def. Awareness]'
	dc.w	$0200,$a
	String	'[ Puck Control ]'
	dc.w	$0100,$a
	String	'[ Stick  Right ]'
	dc.w	$0008,$a
	String	'[  Stick Left  ]'
	dc.w	$0004,$a
	String	'[ Glove  Right ]'
	dc.w	$0002,$a
	String	'[  Glove Left  ]'
	dc.w	$0001,$a
	String	'[    Weight     '
	dc.w	$2000,6			;weight
	dc.w	-1

PauseText	;pause menu item list (Pausemode)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	'     Timeout      '
	dc.l	TimeoutMenu
	String	$FF

PauseText2	;pause menu item list without Timeout, used when tmflags bit 2 of the pausing
	;team is set (Pausemode)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	$FF

StartGameText	;label. Intermission menu for gsp 0 (penalty93.sslist)
	String	$FE,5
	String	$FE,4
	String	'    Start Game    '
	dc.l	rtss
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	$FF

StartGameTextPO	;label. Intermission menu for gsp 0 in the playoffs
	;(penalty93 .sslist), adds Playoff Stats
	String	$FE,5
	String	$FE,4
	String	'    Start Game    '
	dc.l	rtss
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'  Playoff Stats   '
	dc.l	DisplayTeamStats
	String	'   Other Scores   '
	dc.l	ShowScores
	String	$FF

IntermissionText	;label. Intermission menu for gsp 1-3, season and
	;playoffs (penalty93 .sslist)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	$FF

ExitGameText	;label. Intermission menu for gsp 4 (penalty93.sslist).
	;'s PlayoffScreenText2 label inside the Team Roster string is not created
	String	$FE,5
	String	$FE,4
	String	'    Exit Game     '
	dc.l	rtss
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	$FF

ExitGameTextPO	;label. Intermission menu for gsp 4 in the playoffs
	;(penalty93 .sslist), same items as ExitGameText
	String	$FE,5
	String	$FE,4
	String	'    Exit Game     '
	dc.l	rtss
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	$FF

AttributeScreenText	;line editor exit menu (ExitAttributeScreen)
	String	$FE,6,$F9,1
	String	$FE,4,$F9,1
	String	'       Exit       '
	dc.l	rtss
	String	'Set Original lines'
	dc.l	InitTeamSructure+$10	;the line copy loop of InitTeamSructure
	String	'  Save Team Line  '
	dc.l	EncodePlayerAttributes
	String	'  Load Team Line  '
	dc.l	DecodePlayerAttributes
	String	$FF

ExitAttribText	;line editor exit menu without Load Team Line (ExitAttributeScreen)
	String	$FE,6,$F9,1
	String	$FE,4,$F9,1
	String	'       Exit       '
	dc.l	rtss
	String	'Set Original lines'
	dc.l	InitTeamSructure+$10
	String	'  Save Team Line  '
	dc.l	EncodePlayerAttributes
	String	$FF
