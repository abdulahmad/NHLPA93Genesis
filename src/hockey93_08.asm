;	NHLPA Hockey 93 (retail) segment $13952-$14403
;	92 hockey.asm setoptions (game setup screen) with its 93 additions: the two team blocks with the
;	animated roster players (UpdateBothTeamDisplays ... AddTeamSpriteFrame) and its own vblank
;	handler (VBlank_SetOptions). DefaultMenus onward is hockey93_09.
;	Global names from the IDA export, 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	92 bit names used in comments, same values in 93: disflags 0 dfok, 1 df32c, 2 dfng;
;	pad bits ubut 0, dbut 1, lbut 2, rbut 3, sbut 7.
;	printz strings: first byte c, -c = $ab: map = b&3, printa = (-c<<9)&$F800. $FF map 1, $FE map 2,
;	$BF map 1 + priority, $BE map 2 + priority (92 String -$01 = $FF). Then x, y.
;	Maps here: map 1 = VmMap1 ($E000), map 2 = VmMap2 ($C000).
;	DecompressGraphicsWithCallback is followed by its 8 byte remap table.

setoptions	;options screen display and input. Called from PeriodOver (hockey93_06).
	;93: 6 minute demo timeout polling both pads, animated roster players in the team blocks,
	;random teams after a demo, ends with bra maketree (hockey93_09)
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
	dc.l	$01234562,$89ABCDEF	;remap table (retail; IDA btst / or.l, Rev A $01234567)
	move.w	d4,(smallfontchars).w	;93: small font loaded here (92 bsr AddSmallFont)
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$0FC04567,$89ABCDEF	;remap table (retail; IDA bset / or.l)

	bsr.w	printz
	String	$FF,0,0			;map 1 (92 -$02,0,0)
	moveq	#$28,d0			;40 x 28 (IDA ori.b #$28,d0)
	moveq	#$1C,d1
	move.w	#$7FF,d2		;blank char (92 moveq #1)
	bsr.w	eraser

	bsr.w	printz
	String	$FE,0,0			;map 2 (92 -$01,0,0)
	movea.l	#GameSetUpMap,a0	;game setup bitmap (Rev A $2E22A, IDA ori.b)
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
	st	(hmtmstruct).w		;team shown = $FFxx, so UpdateTeamNameAnimation starts a new team
	st	(awtmstruct).w

	movea.l	#.text,a1		;options static text
.textlp	bsr.w	print			;IDA: loc_13A5E
	tst.b	2(a1)
	bne.s	.textlp

	tst.w	(demoflag).w
	bne.w	.keep			;93: demoflag clear (a demo ran): random teams
	moveq	#$1A,d0			;26 teams
	bsr.w	randomd0
	move.w	d0,(menuhometeam).w
	moveq	#$1A,d0
	bsr.w	randomd0
	move.w	d0,(menuawayteam).w
.keep	st	(demoflag).w		;IDA: loc_13A84
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.notree			;regular season or continue playoffs
	bsr.w	SelectRandomPlayoffTree	;new playoffs
.notree	cmpi.w	#1,(OptPlayMode).w	;IDA: loc_13A96
	bne.w	.nopo
	bsr.w	NewPO			;continue playoffs
.nopo	clr.w	d7			;IDA: loc_13AA4. menu line 0
	clr.w	d0
	bsr.w	.nms
	bsr.w	.ps
	move.w	#$18,(palcount).w	;24
	bclr	#dfng,(disflags).w		;fade in graphics now
;----------
.top	move.l	#$5460,d6		;IDA: loc_13ABC. 21600 frames (6 minutes) before the demo (92 40*60)
.wait	move.w	(vcount).w,d1		;IDA: loc_13AC2
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
	move.w	(VDP_CNTR).l,(StanleyCupTimer).w	;92 seed = HVcount
	move.w	(VDP_CNTR).l,(StanleyCupTimer+2).w
	clr.w	(OptPlayMode).w		;92 .newdemo: regular season
	clr.w	(playofflevel).w
	clr.w	(OptLine).w		;line changes on
	move.w	#1,(OptPen).w		;penalties "On"
.ex	bsr.w	UpdatePlayoffLevel	;IDA: loc_13B1C
	move.w	(VDP_CNTR).l,(StanleyCupTimer).w	;random seed hopefully
	move.w	(VDP_CNTR).l,(StanleyCupTimer+2).w
	bra.w	maketree		;(92 GetPassWord / PassWord before MakeTree)

.nd	btst	#7,d1			;IDA: loc_13B34. sbut
	bne.s	.ex
	btst	#1,d1			;dbut
	beq.w	.2
	moveq	#2,d0
	bsr.w	.nms			;new menu line selected
	bsr.w	.ps			;print screen
	bra.w	.top

.2	btst	#0,d1			;IDA: loc_13B50. ubut
	beq.w	.3
	moveq	#-2,d0
	bsr.w	.nms			;new menu line
	bsr.w	.ps			;print screen
	bra.w	.top

.3	moveq	#1,d2			;IDA: loc_13B66
	btst	#3,d1			;rbut
	bne.w	.4
	btst	#2,d1			;lbut
	beq.w	.top
	moveq	#-1,d2
.4	bsr.w	.IncItem		;IDA: loc_13B7A. change item
	bsr.w	.ps			;print screen
	bra.w	.top

.IncItem	;IDA: setoptions_updateoptionvalue. add d2 to current item d7 (d2 = 0: just limit it)
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
.ii0	cmp.w	#2,d7			;IDA: loc_13BAE. players
	bne.w	.ii1
	moveq	#5,d5			;playoffs: player choices 5-7
	tst.w	(OptPlayMode).w
	bne.w	.ii1
	clr.w	d5			;regular season: player choices 0-4
	moveq	#5,d4
.ii1	bsr.w	.iilimit		;IDA: loc_13BC4
	move.w	d3,(a2,d7.w)
	tst.w	d2
	beq.w	rtss
	cmpi.w	#1,(OptPlayMode).w
	bne.w	.npo
	tst.w	d7
	bne.w	.npo
	bsr.w	NewPO			;93: play mode moved onto continue playoffs
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.s	.ii1			;nothing to continue: step past it
	rts

.npo	cmpi.w	#2,(OptPlayMode).w	;IDA: loc_13BF2
	blt.w	rtss
	tst.w	d7
	beq.w	SelectRandomPlayoffTree	;new playoffs: play mode or team 1 changed (92 NewPo)
	cmp.w	#4,d7
	beq.w	SelectRandomPlayoffTree
	rts

.iilimit	;IDA: setoptions_clampoptionvalue. d3 + d2, wrapped into d5 ... d4-1
	add.w	d2,d3
	cmp.w	d5,d3
	bge.w	.iil1
	move.w	d4,d3
	subq.w	#1,d3
.iil1	cmp.w	d4,d3			;IDA: loc_13C18
	blt.w	rtss
	move.w	d5,d3
	rts

.ps	;IDA: setoptions_updatealloptions. print choices and show team icons/colors
	move.w	d7,d6
	moveq	#-2,d7
.pstop	addq.w	#2,d7			;IDA: loc_13C26
	clr.w	d2
	bsr.w	.IncItem
	bsr.w	.psd
	cmp.w	#$C,d7			;92 (menuitems-1)*2
	bne.s	.pstop
	move.w	d6,d7
	bra.w	TeamIcons

.psd	;IDA: setoptions_displayoptionvalue. print the choice for menu line d7
	bsr.w	printz
	String	$BE,$11,$D		;map 2 + priority (92 -$01,16,11; IDA ori.b / btst)
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
.psd3	movea.l	a0,a1			;IDA: loc_13C86. step to string d3
	adda.w	(a0),a0
	dbf	d3,.psd3
	bra.w	print

.psdtp	movea.l	#OptPlayMode,a1		;IDA: loc_13C92. 92 optionsmenu
	move.w	(a1,d7.w),d3
	movea.w	#$314,a1		;team address table (92 TeamList)
	asl.w	#2,d3
	movea.l	(a1,d3.w),a1
	lsr.w	#2,d3
	adda.w	4(a1),a1		;92 TeamName
	bra.w	print

.nms	;IDA: setoptions_navigate. next menu by d0
	move.w	d7,d3
.nms0	add.w	d0,d7			;IDA: loc_13CB2
	bpl.w	.nms1
	clr.w	d7
.nms1	cmp.w	#$E,d7			;IDA: loc_13CBA. 92 menuitems*2
	blt.w	.nms2
	sub.w	d0,d7
.nms2	cmpi.w	#1,(OptPlayMode).w	;IDA: loc_13CC4
	bne.w	.nms3
	tst.w	d7
	beq.w	.nms3
	cmp.w	#6,d7			;continue playoffs: skip lines 1-3
	bls.s	.nms0
.nms3	cmpi.w	#2,(OptPlayMode).w	;IDA: loc_13CDA
	blt.w	.nms4
	cmp.w	#6,d7			;new playoffs: skip team 2
	beq.s	.nms0
.nms4	bsr.w	.setrect		;IDA: loc_13CEA. erase the old frame
	move.w	#$7FF,d2		;(92 moveq #1)
	bsr.w	eraser
	move.w	d7,d3
	bsr.w	.setrect
	bra.w	Framer

.setrect	;IDA: setoptions_printpos. set rectangle cords for framing line d3
	bsr.w	printz
	String	$FF,$10,$C		;map 1 (92 printm 4, printx 15, printy 10; IDA ori.b)
	add.w	d3,(printy).w		;(IDA cmpi.b / cmp.b hid this and the moveq)
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
.pslim	dc.w	4,8,$1A,$1A,3,3,2	;IDA: MaxValuesTable. 92 NumofTeams = $1A

;menu item names
.pl	dc.w	.pl0-.pl		;IDA: OptionsTextOffsetTable
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

.text	;IDA: MenuTextData. static text
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
	sub.w	(playofflevel).w,d0
	move.w	d0,(playoffroundoffset).w
	rts

TeamIcons	;IDA: loc_13EE8. draw team name bars and set colors. Branched to from setoptions .ps.
	;93 has no continue playoffs exit and no setplayercolors (SetupNextPlayer loads the palettes)
	movem.l	d0-d7/a0-a2,-(sp)
	tst.w	(OptPlayMode).w
	bne.w	.0
	move.w	(menuhometeam).w,(HomeTeam).w	;92 Opt1Team
	move.w	(menuawayteam).w,(VisTeam).w	;92 Opt2Team
.0	bsr.w	printz			;IDA: loc_13F00
	String	$BE,2,1			;map 2 + priority (92 -$02,3,8; IDA ori.b / btst)
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

dotb	;IDA: DisplayTeamBlock. draw team name bar d1 = team number at printx/printy. Called from TeamIcons and
	;ScoutingReport (hockey93_07)
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
	String	$BF,2,$A		;(IDA ori.b)
	cmpa.w	#(hmtmstruct-M68K_RAM),a2	;(IDA eori.b / mulu.w)
	bne.w	rtss
	move.w	#$1A,(printx).w		;home team on the right
	rts

UpdateTeamNameisplay	;93: (IDA name, it prints nothing) pick the goalie shown for team a2 when it changes: $26(a2) =
	;weighted random roster index from the 4 nibbles at team data +$A offset (UnpackNibbles / WeightedRandomSelect).
	;$26 stays 0 when a pad controls the team, gamelevel > 2 or OptLine is set. Called from UpdateTeamNameAnimation
	movem.l	d0/a0,-(sp)
	clr.w	tmgoalie(a2)
	bsr.w	FigureJoy		;sets cont1team / cont2team
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
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
.set	move.w	d0,tmgoalie(a2)		;IDA: loc_13FD4
.x	movem.l	(sp)+,d0/a0		;IDA: loc_13FD8
	rts

UpdateBothTeamDisplays	;93: run the roster player in both team blocks and build their sprite list.
	;Called once per frame from setoptions .wait
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#1,d7
	movea.w	#(hmtmstruct-M68K_RAM),a2
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
	bsr.w	UpdateTeamNameisplay
	clr.w	2(a2)			;first RosterOrderTable entry
	bsr.w	ClearAndSetFlag
.same	movea.w	tmsort(a2),a3		;IDA: loc_14016
	btst	#2,tmflags(a2)
	beq.w	.in
	addq.w	#3,$24(a3)		;sliding out
	addq.w	#3,$1C(a3)		;x offset
	cmpi.w	#$28,$1C(a3)
	bgt.w	SetupNextPlayer		;past 40: next player
	rts

.in	tst.w	$1C(a3)			;IDA: loc_14038
	bpl.w	.anim
	addq.w	#1,$24(a3)		;sliding in from -40
	addq.w	#1,$1C(a3)
.anim	jsr	(updateanim).l		;IDA: loc_14048
	btst	#1,pflags2(a3)
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
	bset	#1,pflags2(a3)
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
.trim	cmpi.b	#$20,-(a0)		;IDA: loc_140C0. find the last space
	bne.s	.trim
	clr.b	(a0)			;line 1 = number and first name
	move.w	a0,d0
	sub.w	a3,d0
	btst	#0,d0
	beq.w	.even
	addq.w	#1,a0			;keep the last name word aligned
	addq.w	#1,d0
.even	move.w	(a3),d1			;IDA: loc_140D8
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
.ln2	movea.w	a0,a1			;IDA: loc_140FE
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

SetupNextPlayer	;IDA: loc_14120. 93: player of team a2 slid out. Load the team palette (setplayercolors .sp), put the
	;sprite at x offset -40, take the next RosterOrderTable slot (goalie slot: $26(a2)), set the sprite flag from
	;the player data and pick his animation script from the ratings. Branched to from UpdateTeamNameAnimation
	movea.l	tmdata(a2),a0
	adda.w	2(a0),a0		;Palettedata
	movea.w	#(palbuffer-M68K_RAM),a1
	moveq	#7,d0
	cmpa.w	#(hmtmstruct-M68K_RAM),a2
	beq.w	.pal
	adda.w	#$20,a0			;visitor: second palette
	adda.w	#$20,a1
.pal	move.l	(a0)+,(a1)+		;IDA: loc_1413E
	dbf	d0,.pal
	move.w	#$18,(palcount).w	;24
	bclr	#2,tmflags(a2)
	movea.w	tmsort(a2),a3
	move.w	#$FFD8,$1C(a3)		;x offset -40
	clr.w	$58(a3)
.next	move.w	2(a2),d0		;IDA: loc_1415E
	lea	RosterOrderTable(pc),a0
	move.b	(a0,d0.w),d0
	bpl.w	.got
	clr.w	2(a2)			;end of list: start again
	bra.s	.next

.got	move.w	d0,6(a2)		;IDA: loc_14174. line slot
	addq.w	#1,2(a2)
	lea	$16A(a2),a0		;line data
	move.b	(a0,d0.w),d0
	subq.w	#1,d0			;roster index
	tst.w	6(a2)
	bne.w	.pn
	move.w	tmgoalie(a2),d0		;slot 0 (goalie): UpdateTeamNameisplay's pick
.pn	move.w	d0,4(a2)		;IDA: loc_14192
	bsr.w	GetTeamNamePtr
	adda.w	(a0),a0			;past the name
	bclr	#3,attribute(a3)
	btst	#0,4(a0)
	bne.w	.r
	bset	#3,attribute(a3)		;bit 0 of player byte 4 clear
.r	addq.w	#1,a0			;IDA: loc_141B2. rating bytes
	moveq	#6,d0			;7 bytes, 14 nibbles
	clr.w	d2			;best rating
	movea.l	#CharacterValidationTable,a1
	move.w	6(a2),d3
	andi.w	#7,d3
	bne.w	.nib
	movea.l	#AltCharValidationTable,a1	;goalie slot
.nib	move.b	(a0),d1			;IDA: loc_141D0
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
.set	move.b	d1,d2			;IDA: loc_1420A
	clr.w	8(a2)
	move.b	-1(a1),9(a2)
	rts

GetTeamNamePtr	;93: a0 = roster entry d0 of team a2 (name string, then 8 bytes: number and ratings).
	;Called from UpdateTeamNameAnimation and SetupNextPlayer
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0			;player data
	bra.w	.cnt
.next	adda.w	(a0),a0			;IDA: loc_14222. skip the name
	addq.w	#8,a0
.cnt	dbf	d0,.next		;IDA: loc_14226
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
.n	clr.b	-5(a6)			;IDA: loc_1438C. end sprite list (92 3-8(a6))
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
.x	move.w	#$80,d1			;IDA: loc_143DE
	moveq	#1,d2			;frame
	move.w	(gamesetuptilesetindex).w,d3
	bra.w	SetSframe

VBlank_SetOptions	;IDA: loc_143EC. 93: vbint handler stored by setoptions. 92 vb2 (cramfade unless dfng), plus
	;DumpSprites2 when dfok is set
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	bclr	#dfok,(disflags).w
	beq.w	.fade
	bsr.w	DumpSprites2
.fade	bsr.w	cramfade		;IDA: loc_14408
.nograph	addq.w	#1,(vcount).w	;IDA: loc_1440C
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte
