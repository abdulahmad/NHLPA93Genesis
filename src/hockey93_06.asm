;	NHLPA Hockey 93 (retail) segment $122A8-$12E25
;	92 hockey.asm part 3, first half: setupice, defaultsprites, SprSort,
;	resetplstuff, setteams, setplayercolors, PeriodOver, Opening, Opening2 and
;	PlayoffScreen, plus the 93 splits (setupice_highlight, setupIceRinkMap,
;	setupEASNmap, setupTeamBlocksMap, defaultsprites2, clearTeamStats,
;	InitTeamSructure) and the 93 playoff screen helpers. 92 SetSLogos and
;	SetTeamColors have no 93 counterpart here. ScoutingReport is hockey93_07.
;	Global names from the IDA export, 92 names where the routine is the
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
	bset	#1,(disflags).w		;df32c
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
	bclr	#0,(sflags).w		;sfpz

	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng

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
	movea.l	#IceRinkMapPlus8,a2
	bsr.w	DoDMA_clearCallbackPointer	;tiles to vram at d4, d4 advanced past them

	move.w	d4,(EASNcset).w		;1st vram char for easn logo tiles
	bsr.w	setupEASNmap

	move.w	d4,(word_FFB016).w	;93: 1st vram char for the unk_7A2B8 tiles
	movea.l	#unk_7A2B8,a2
	bsr.w	DoDMA_clearCallbackPointer

	move.w	d4,(gamesetuptilesetindex).w	;1st vram char for crowd animation tiles (92 Crowdvrcset)
	movea.l	#CrowdSpritesPlus8,a2
	bsr.w	DoDMA_clearCallbackPointer

	move.w	d4,(word_FFB024).w	;sprite char start, reused by setupice_highlight
	bsr.w	defaultsprites
	bsr.w	setupIceRinkMap		;transfer pal 0&1

	bsr.w	AddFramer		;93: Framer tiles (92 inline ReMap)
	move.w	d4,(smallfontchars).w	;1st vram char for smallfont tiles
	movea.l	#smallfontmapPlus8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$43434567,$89ABCDEF	;remap table (92 .sfmap)
	move.w	d4,(BigFontChars).w	;1st vram char for Bigfont tiles
	movea.l	#bigfontmapPlus8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$71234567,$89ABCDEF	;remap table (92 .bfmap)

	bsr.w	setupTeamBlocksMap	;93: team blocks for both teams (92 SetSLogos small logos)

	move.w	d4,(ExtraChars).w	;char space for extra graphics

	btst	#1,(gmode).w		;gmdir
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0			;12 players
.l01	bchg	#7,pflags(a3)		;IDA: loc_123BA. pfgoal in pflags
	adda.w	#SCstruct,a3
	dbf	d0,.l01
.gok	bsr.w	setplayercolors		;IDA: loc_123C8. (92 SetTeamColors, which falls into setplayercolors)

	move.w	#$FFFF,(PadControlBits).w	;93: no pad assignments
	clr.l	(padcont).w
	clr.l	(padcontPlus4).w
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
	bclr	#0,(disflags).w		;dfok
	bclr	#2,(disflags).w		;dfng
	move.w	#$2300,sr

	movem.l	(sp)+,d0-d7/a0-a6
	rts

setupice_highlight	;93 only. Rebuild the rink sprites after a highlight replay without reloading tiles, then fade in.
	;Called from StartHL2 (penalty93_2). Uses the sprite char start saved by setupice in word_FFB024
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
	bclr	#0,(sflags).w		;sfpz
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng
	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w	;2000
	st	(zamx).w
	move.w	(word_FFB024).w,d4	;sprite char start from setupice
	bsr.w	defaultsprites
	bsr.w	setupIceRinkMap		;transfer pal 0&1
	btst	#1,(gmode).w		;gmdir
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0			;12 players
.l01	bchg	#7,pflags(a3)		;IDA: loc_12478. pfgoal in pflags
	adda.w	#SCstruct,a3
	dbf	d0,.l01
.gok	bsr.w	setplayercolors		;IDA: loc_12486
	move.w	#$FFFF,(PadControlBits).w	;no pad assignments
	clr.l	(padcont).w
	clr.l	(padcontPlus4).w
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
	bclr	#0,(disflags).w		;dfok
	bclr	#2,(disflags).w		;dfng
	move.w	#$2300,sr
	movem.l	(sp)+,d0-d7/a0-a6
	rts				;IDA: locret_124F8 (its only xref is a constant, so no label)

setupIceRinkMap	;copy the ice rink palettes (pal 0&1, 16 longs) to palfadenew. 92 setupice .ipal, split out in 93.
	;Called from setupice, setupice_highlight and stats93
	movea.l	#IceRinkMap,a0
	adda.l	(a0),a0			;palette offset in the map header
	moveq	#$F,d0
	movea.w	#(palfadenew-M68K_RAM),a1
.ipal	move.l	(a0)+,(a1)+		;IDA: loc_12508
	dbf	d0,.ipal
	rts

setupEASNmap	;93 only. Decompress the easn logo tiles to vram at EASNcset. Called from setupice and setupice_highlight.
	;Return d4 = next free vram char
	move.w	(EASNcset).w,d4
	movea.l	#EASNmapPlus8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$71234567,$89ABCDEF	;remap table (92 .EASNmap)
	rts

setupTeamBlocksMap	;93 only. Load TeamBlocks.map tiles at d4+$30 and copy the home and visitor team blocks (24 rows each)
	;to vram at basetileoffset and basetileoffset+$18. Called from setupice. d4 = 1st vram char; return d4 = basetileoffset+$30
	move.w	d4,(basetileoffset).w
	addi.w	#$30,d4			;skip the 48 chars for the two team blocks
	movea.w	#(unk_FFC210-M68K_RAM),a1	;map word buffer for CopyTeamBlockMapData
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

CopyTeamBlockMapData	;93 only. Copy one team's 24 block chars from the loaded tile set to vram at d1 by vram dma,
	;and store their map words at (a1)+. a0 = map data, d0 = team, d1 = vram address. Called from setupTeamBlocksMap
	mulu.w	#$30,d0			;24 map words per team
	lea	4(a0,d0.w),a0
	moveq	#$17,d3			;24 chars
.row	moveq	#$20,d0			;IDA: loc_1257E. 32 bytes per char
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
.ssotop	move.w	#$FFFF,oldframe(a3)		;IDA: _ssotop. screen objects not locked to scroll of screen
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
.ffotop	st	oldframe(a3)			;IDA: _ffotop. objects tied to screen scrolling (not players/net/puck)
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

.listsso	;IDA: _listsso. xcord,ycord,frame,attribute,vram char size
	dc.w	0,0,0,0,9
	dc.w	0,0,0,0,9

.listffo	;IDA: _listffo. xcord,ycord,zpos,frame,attribute,vram char size
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
.0	moveq	#$1F,d0			;IDA: loc_12676. (SCstruct/4)-1
	movea.w	a3,a0
.1	clr.l	(a0)+			;IDA: loc_1267A
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

.list	;IDA: _list. xcord,ycord,zcord,frame,att,vrsize,radx,rady,asslist,pflags
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
.loop0	move.w	Ypos(a0),d4		;IDA: loc_1282A
	btst	#7,(sflags).w		;sfhor
	beq.w	.l01
	move.w	(a0),d4			;Xpos
.l01	move.w	d4,(a1)+		;IDA: loc_1283A. update ylist
	adda.w	#SCstruct,a0
	dbf	d3,.loop0

	movea.l	#Ylist,a1
.loop	clr.w	d4			;IDA: loc_1284A
	movea.l	#OOlist,a0
	move.w	#$E,d3			;Sortobjs-2
	clr.w	d0
	clr.w	d1
.0	move.b	(a0)+,d0		;IDA: loc_1285A. object number *2
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
.1	dbf	d3,.0			;IDA: loc_12884
	tst.w	d4
	bne.s	.loop
	movem.l	(sp)+,d0-d4/a0-a2
	rts

resetplstuff	;reset team variables/and players on both teams. Called from puckfaceoff2 (logic93_4) and StartHL2 (penalty93_2)
	movem.l	d0-d2/a0-a3,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	bsr.w	.top
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize
	bsr.w	.top
	movem.l	(sp)+,d0-d2/a0-a3
	rts

.top	bclr	#4,tmflags(a2)		;IDA: resetplstuff_top. 93: clear team flag bit 4
	moveq	#5,d2
	movea.w	tmsort(a2),a3
.loop	clr.b	pflags2(a3)			;IDA: resetplstuff_loop. pflags2 (92 also cleared pflags3)
	tst.w	position(a3)
	bmi.w	.next
	move.w	#$52C,d1		;SPAglide (92 $346)
	bsr.w	SetSPA
	clr.w	impact(a3)
	clr.b	nopuck(a3)			;93 clears a byte
	andi.b	#$C2,pflags(a3)		;keep pfteam, pfgoal, pfna in pflags
.next	adda.w	#SCstruct,a3			;IDA: resetplstuff_next
	dbf	d2,.loop
	rts

clearTeamStats	;93 only: the 92 setteams clear loop, split out. Clear both team structs (2 x tmsize) but keep the
	;word at tmstruct+$26 of each team, and set the byte at tmstruct+$9A of each. Falls into setteams.
	;Called from StartGame, StartHL2 and ScoutingReport
	move.w	(word_FFC50C).w,-(sp)	;home tmstruct+$26
	move.w	(word_FFC6AE).w,-(sp)	;visitor tmstruct+$26
	move.l	#tmsize-1,d0		;tmsize words = 2 x tmsize bytes (both team structs)
	movea.w	#(hmtmstruct-M68K_RAM),a0
.0	clr.w	(a0)+			;IDA: loc_128F6
	dbf	d0,.0
	move.w	(sp)+,(word_FFC6AE).w
	move.w	(sp)+,(word_FFC50C).w
	st	(byte_FFC580).w		;home tmstruct+$9A
	st	(byte_FFC722).w		;visitor tmstruct+$9A

setteams	;use hometeam/visteam to set team structures. Falls in from clearTeamStats, also called from hockey93_08.
	;93 sets tmsort as a word and leaves the team data setup to InitTeamSructure
	movem.l	d0/a0-a2,-(sp)
	movea.w	#(hmtmstruct-M68K_RAM),a2
	move.w	(HomeTeam).w,d0
	move.w	#(SortCords-M68K_RAM),tmsort(a2)
	bsr.w	InitTeamSructure
	movea.w	#(awtmstruct-M68K_RAM),a2	;tmstruct+tmsize
	move.w	(VisTeam).w,d0
	move.w	#(SortCords-M68K_RAM)+(6*SCstruct),tmsort(a2)
	bsr.w	InitTeamSructure
	movem.l	(sp)+,d0/a0-a2
	rts

InitTeamSructure	;93 only. Set up team struct a2 for team d0: store the team number at $28, the team data address
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
.copy	move.l	(a0)+,(a1)+		;IDA: loc_12958
	dbf	d0,.copy
	rts

setplayercolors	;copy in correct color data for each team. Called from setupice, setupice_highlight, stats93 and
	;StartHL2 (penalty93_2)
	clr.w	d1
	movea.w	#(hmtmstruct-M68K_RAM),a0
	bsr.w	.sp
	moveq	#$20,d1
	adda.w	#tmsize,a0

.sp	movea.l	tmdata(a0),a2		;IDA: setplayercolors_sp
	adda.w	2(a2),a2		;Palettedata
	adda.w	d1,a2
	movea.w	#(palbuffer-M68K_RAM),a1	;92 palfadenew+$40 (same address)
	adda.w	d1,a1
	moveq	#7,d0
.5	move.l	(a2)+,(a1)+		;IDA: setplayercolors_s
	dbf	d0,.5
	rts

PeriodOver	;what to do if period over. Branched to from puckfaceoff (logic93_4) when the clock runs out.
	;93 moves forceblack after the period count and drops the 92 SetHor / SetVideo / palcount
	addq.w	#1,(gsp).w		;period number
	bchg	#1,(gmode).w		;gmdir
	cmpi.w	#3,(gsp).w
	blt.w	.0			;periods 1-2 done
	beq.w	.nop			;3rd period done
	move.w	#3,(gsp).w		;overtime done: stay at 3
	tst.w	(OptPlayMode).w
	bne.w	.nop			;playoffs: decided by the score check
	move.w	#4,(gsp).w		;regular season: game over after overtime
.nop	move.w	(tmstructtmscore).w,d0	;IDA: _nop. home score
	sub.w	(tmstructtmscoretmsize).w,d0	;visitor score
	beq.w	.0			;tied: play overtime
	move.w	#4,(gsp).w		;game over
.0	bsr.w	forceblack		;IDA: _0

IntermissionStart	;IDA: _sp. PeriodOver tail (92 PeriodOver .sp): reset the clock, song $36, ticker scores,
	;playoff team stats at game over, then Intermission. Next period, or GameOver when gsp = 4.
	;Also jumped to from StartGame (hockey93_01, as _sp) for the pregame intermission
	jsr	(ResetClock).w
	move.w	#$36,-(sp)		;song $36 (92 SngEOG = 3 here)
	bsr.w	song
	bsr.w	UpdateScores
	cmpi.w	#4,(gsp).w
	bne.w	.1			;not game over
	bsr.w	DisplayTeamStatsForPlayoffs
.1	bsr.w	Intermission		;IDA: _1
	cmpi.w	#4,(gsp).w
	beq.w	GameOver
	jmp	(StartPer).w

GameOver	;IDA: loc_129FC. 92 name. Save the password, show the playoff stats and playoff screen in playoff
	;mode, then song $35 and back to Opening2. Branched to from IntermissionStart
	bsr.w	EncodePW
	tst.w	(OptPlayMode).w
	beq.w	.po			;regular season
	bclr	#1,(sflags).w		;sfpj
	jsr	(DisplayTeamStats).w	;"Playoff Stats"
.po	bsr.w	PlayoffScreen		;IDA: loc_12A12. returns at once outside playoff mode

ExitToOpening	;IDA: loc_12A16. Song $35, then restart at Opening2. Falls in from GameOver,
	;also jumped to from HandleJoy1 (hockey93_01, as loc_12A16) to end the demo
	move.w	#$35,-(sp)		;93 only (92 GameOver played no song)
	bsr.w	song
	bra.w	Opening2

Opening	;title screen, then into Opening2. Jumped to from Begin (hockey93_01). Same as 92 REV A
	bsr.w	KillCrowd
	bsr.w	TitleScreen

Opening2	;reset the stack and clear the variables (92 REV A path), then options, playoff screen,
	;scouting report and on to a new game
	bsr.w	KillCrowd		;93 adds this
	move.w	#$2700,sr
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0	;varstart ($FFB000)
.0	clr.l	(a0)+			;IDA: loc_12A3A
	cmpa.w	#$CAD2,a0		;varend (93 value)
	blt.s	.0
	move.l	#vb2,(vbint).w
	move.w	#$2500,sr
	bsr.w	setoptions
	bsr.w	PlayoffScreen		;(92 Opening3)
	bsr.w	ScoutingReport		;(92 Opening4)
	jmp	(ChkShortPeriods).w	;92 jmp startgame; 93 first checks pad 1 for short periods

PlayoffScreen	;bring up playoff screen if in playoff mode. Called from GameOver and Opening2.
	;93 runs its own vblank (PlayoffScreenDataTable) and scrolls the tree a page ($70 pixels) at a time.
	;Returns when start is pressed (PlayoffScreenExit)
	tst.w	(OptPlayMode).w
	beq.w	rtss

	move.l	#PlayoffScreenDataTable,(vbint).l	;(92 vb2)
	bclr	#1,(disflags).w		;df32c
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

	movea.l	#ArrowsMapPlus8,a2
	move.w	d4,(ExtraChars).w
	bsr.w	DoDMA_clearCallbackPointer	;arrow tiles at ExtraChars

	bsr.w	printz
	String	$CE,0,0			;(92 -$01,60,4 before the StanleyMap bitmap)
	movea.l	#$32860,a0		;bitmap map data (retail; Rev A $3288E)
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

	movea.l	#Titlemap2,a1		;93: Titlemap2 palette to pal 0, tiles at word_FFB016
	lea	8(a1),a2
	adda.l	(a1),a1
	moveq	#7,d0
	movea.w	#(palbuffer-M68K_RAM),a0
.pal	move.l	-$40(a0),$20(a0)	;IDA: loc_12B2E. pal 0 -> pal 3
	move.l	(a1)+,-$40(a0)		;Titlemap2 palette -> pal 0
	move.l	-$20(a0),(a0)+		;pal 1 -> pal 2
	dbf	d0,.pal
	move.w	d4,(word_FFB016).w
	bsr.w	DoDMA_clearCallbackPointer

	move.w	#$104,(clampcounter).w	;93: RAM reused by this screen
	move.w	#$110,(word_FFB8B0).w

	movea.l	#VDP_CTRL,a0
	move.w	#$9202,(a0)		;window V position 2

	movea.w	#(potree-M68K_RAM),a1
	movea.l	#unk_15556,a0		;tree layout tables by gamelevel (92 .setup, data in hockey93_11)
	move.w	(gamelevel).w,d0
	asl.w	#1,d0
	adda.w	(a0,d0.w),a0
	clr.w	d4
	move.b	(a0)+,d4		;team count-1
.top	bsr.w	printz			;IDA: loc_12B76
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
.top2	bsr.w	printz			;IDA: loc_12B9A
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
.top3	move.b	(a0)+,(printx+1).w	;IDA: loc_12BD4
	move.b	(a0)+,(printy+1).w
	bsr.w	FormatScore		;92 .doscores
	adda.w	#$10,a2			;gssize
	dbf	d4,.top3

.noscr	bsr.w	printsmallz		;IDA: loc_12BE8. 93: round title (92 had the sharks message here)
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
.nopage	move.w	#$18,(palcount).w	;IDA: loc_12C30+2. 24 (IDA hid this in the string)
	move.w	#$36,-(sp)		;song $36 (92 SngPO = 4)
	bsr.w	song

	clr.w	d0
	clr.w	d4
	move.w	#$FFFF,(PlayerScrollCtr).w	;scroll step (RAM shared with the stats screens)
	move.w	#1,(DispAttribCtr).w	;scroll position
	bsr.w	UpdatePlayoffScroll

.input	bsr.w	PlayoffScreen_waitvsync	;IDA: loc_12C54
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
.nr	btst	#2,d3			;IDA: loc_12C8A. lbut
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
.lim	mulu.w	#$70,d1			;IDA: loc_12CB2
	cmp.w	d1,d0
	bgt.w	rtss
	neg.w	d1
	cmp.w	d1,d0
	blt.w	rtss
	move.w	d0,(DispAttribCtr).w
	clr.w	(word_FFB8AE).w
	move.w	d0,d1
	addi.w	#$124,d1
	cmp.w	#$40,d1
	blt.w	.nox			;word_FFB8AE = position+$124 only inside $40-$200, else 0
	cmp.w	#$200,d1
	bgt.w	.nox
	move.w	d1,(word_FFB8AE).w
.nox	ext.l	d0			;IDA: loc_12CE6
	divs.w	#$70,d0
	swap	d0			;remainder
	tst.w	d0
	bne.w	rtss			;not on a page yet
	clr.w	(PlayerScrollCtr).w	;stop
	rts

PlayoffScreenExit	;IDA: loc_12CFA. 92 PlayoffScreen .exit: drop HandlePlayoffInput's return address and return
	;from PlayoffScreen. Branched to from HandlePlayoffInput on start, so it has to be global
	addq.w	#4,sp
	rts

PlayoffScreen_waitvsync	;each time palcount runs out, eor the color word at palbuffer+2 (word_FFBD6A) with $EE and
	;restart palcount at $18 (a color flash), then wait for the next vblank. Called from PlayoffScreen .input (92 used Waitxc1)
	tst.w	(palcount).w
	bpl.w	.wait			;palcount still counting
	eori.w	#$EE,(word_FFBD6A).w
	move.w	#$18,(palcount).w
.wait	move.w	(vcount).w,d0		;IDA: loc_12D12
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
.nohi	movea.l	#TeamBlocksmap,a1	;IDA: loc_12D96
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

PlayoffScreenDataTable	;not data: the PlayoffScreen vblank handler (vbint). IDA left it undecoded, kept as retail words.
	;If dfng is clear and Sattsize is set: clear Sattsize, DoDMA the sprite table (Satt) to VSPRITES, then
	;Vmaddr(VSCRLPM) and write $FEA0+DispAttribCtr to the hscroll. Then cramfade, vcount+1, p_music_vblank, rte
	dc.w	$48E7,$FFFE,$0838,$0002,$BE8C,$6600,$0030,$307C
	dc.w	$BF2A,$3038,$C1FA,$6700,$0020,$4278,$C1FA,$3238
	dc.w	$B002,$6100,$ACD0,$3038,$B000,$6100,$AEFE,$303C
	dc.w	$FEA0,$D078,$C9CA,$3080,$6100,$A8FC,$5278,$B03E
	dc.w	$4EB9,$0001,$66D4,$4CDF,$7FFF,$4E73	;jsr ($166D4).l p_music_vblank (Rev A $166EC)

PlayoffScreenText	;round titles by gamelevel, printed with printsmall. Used by PlayoffScreen .noscr
	String	'Playoffs'
	String	'Quarterfinals'
	String	'Semifinals'
	String	'Finals'
	String	'Champions'
