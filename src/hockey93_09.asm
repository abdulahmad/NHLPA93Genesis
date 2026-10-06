;	NHLPA Hockey 93 (retail) segment $14404-$1499D
;	92 hockey.asm DefaultMenus, NewPO (IDA SelectRandomPlayoffTree), MakeTree, FigureJoy and the playoff
;	password code (ReadPassBits ... SuperDiv, GetShifter), then the 93-only playoff stat packing
;	(DisplayTeamStatsForPlayoffs, ReadTeamStats). ResolveGames onward is hockey93_10.
;	Global names from the IDA export, 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	93 keeps the password bits in a 5 word buffer at a3 (92 passbits, 8 words) and drops the 92
;	checksum. The buffers are pwddatabuffer, tpassbits (92 name; IDA unk_FFCB72) and outputbuffer at their
;	retail addresses in ram93.asm, 4 bytes lower than in the Rev A listing (Rev A address in the comment).
;	gsflags bits (92 names, same values): 0 gsftf teams flipped, 1 gsfhl hilite, 2 gsfso series over.
;	playoffroundoffset is the 92 pojoy word (playoff joystick set-up), playofflevel the 92 OptNOP slot.

DefaultMenus	;set default menu choices for beginning of game. Called once from Begin (jsr abs.l).
	st	(demoflag).w		;93: no demo has run yet
	movea.l	#OptPlayMode,a0		;92 optionsmenu
	movea.l	#.defom,a1
	move.w	#6,d0			;92 menuitems-1
.1	move.w	(a1)+,(a0)+		;IDA: _1
	dbf	d0,.1
	rts
.defom	dc.w	0,1,$F,3,1,0,1		;IDA: _defom. play mode, players, team 1, team 2, period length,
					;penalties, line changes (92 0,1,14,8,1,0,1)

NewPO	;93 continue playoffs: read the playoff state back from the password bits, rebuild the tree.
	;Called from setoptions when play mode becomes "continue playoffs" (hockey93_08).
	;92 does the same in GameOver (DecodePW + MakeTree). Not 92 NewPO (that is SelectRandomPlayoffTree).
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(pwddatabuffer-M68K_RAM),a3		;password bits (Rev A pwddatabuffer $CB04)
	bsr.w	ReadPassBits
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.w	.ex			;level 0, game 0: nothing played yet
	bsr.w	maketree
	moveq	#7,d0
	sub.w	(playoffroundoffset).w,d0	;92 pojoy
	move.w	d0,(playofflevel).w	;menu value from pojoy (92 OptNOP slot)
.ex	movem.l	(sp)+,d0-d7/a0-a3	;IDA: loc_1446C
	rts

SelectRandomPlayoffTree	;IDA name; body is 92 NewPO: new playoff generates tree with same team 1.
	;Called from setoptions (hockey93_08) for "new playoffs". Falls into maketree.
	moveq	#$20,d0			;32 trees
	bsr.w	randomd0
.top	addq.w	#1,d0			;IDA: loc_14478
	andi.w	#$1F,d0
	asl.w	#4,d0			;16 teams per tree
	movea.l	#playoffseats,a0	;TeamData93
	adda.w	d0,a0
	lsr.w	#4,d0
	moveq	#$F,d1
	move.w	(menuhometeam).w,d2	;92 Opt1team
	cmp.w	#$17,d2			;92 NumOfTeams-3: all-star teams use team 23
	bls.w	.loop
	moveq	#$17,d2
.loop	cmp.b	(a0)+,d2		;IDA: loc_1449A. find team 1 in this tree
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
.cg	clr.w	gspotwins(a0)		;IDA: loc_144CC
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
.0	move.w	d0,d1			;IDA: loc_14510
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
.2	clr.w	gss1(a1)		;IDA: loc_14538
	clr.w	gss2(a1)
	clr.w	gsper(a1)
	bclr	#1,gsflags(a1)		;hilite requested (92 gsfhl)
	bsr.w	.sett
	adda.w	#gssize,a1
	dbf	d1,.2
	bsr.w	FigureJoy
.nogames	movem.l	(sp)+,d0-d4/a0-a3	;IDA: loc_1455A
	rts

.sett	cmpi.w	#2,(bosgames).w		;IDA: SetGameTeamOrder. series games 2, 3, 5: tree order, others swapped
	beq.w	.flip
	cmpi.w	#3,(bosgames).w
	beq.w	.flip
	cmpi.w	#5,(bosgames).w
	beq.w	.flip
	bset	#0,gsflags(a1)		;teams are flipped (92 gsftf)
	move.b	(a0)+,gst2+1(a1)
	move.b	(a0)+,gst1+1(a1)
	rts
.flip	bclr	#0,gsflags(a1)		;IDA: _flip. gsftf
	move.b	(a0)+,gst1+1(a1)
	move.b	(a0)+,gst2+1(a1)
	rts

FigureJoy	;set cont1team/cont2team appropriately. Called from maketree and UpdateTeamNameisplay (hockey93_08).
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
.f0	cmp.w	(a1),d2			;IDA: loc_145DA. gst1
	beq.w	.it1
	cmp.w	gst2(a1),d2
	beq.w	.it2
	suba.w	#gssize,a1
	dbf	d1,.f0
	bra.w	.ex			;po team not in playoffs

.it2	moveq	#4,d0			;IDA: loc_145F4
	move.w	(a1),(menuawayteam).w	;gst1 (92 Opt2team)
	move.w	gst2(a1),(menuhometeam).w	;93 also sets team 1
	bra.w	.itx
.it1	clr.w	d0			;IDA: loc_14604
	move.w	gst2(a1),(menuawayteam).w	;92 Opt2team
	move.w	(a1),(menuhometeam).w
.itx	add.w	(playoffroundoffset).w,d0	;IDA: loc_14610. 92 pojoy
	move.w	d1,(gamenum).w
	move.w	(a1),(HomeTeam).w	;gst1
	move.w	gst2(a1),(VisTeam).w
	asl.w	#2,d0
	lea	.pojoylist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
	bra.w	.ex

.pojoylist	dc.w	1,0		;IDA: _pojoylist. pojoy 0-3 with the po team as team 1
	dc.w	1,1
	dc.w	1,2
	dc.w	2,1

	dc.w	2,0			;pojoy 0-3 with the po team as team 2
	dc.w	2,2
	dc.w	2,1
	dc.w	1,2

.fjnpo	move.w	(playofflevel).w,d0	;IDA: loc_14658. 92 OptNOP
	asl.w	#2,d0
	lea	.noplist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
.init	bsr.w	InitializeGameStructures	;IDA: loc_1466E
.ex	movem.l	(sp)+,d0-d3/a0-a1	;IDA: loc_14672
	rts

.noplist			;IDA: unk_14678
	dc.w	0,0
	dc.w	1,0
	dc.w	2,0
	dc.w	1,1
	dc.w	1,2

InitializeGameStructures	;93 only: random team pairs for all 8 gstruct games, none of them
	;HomeTeam or VisTeam. Called from FigureJoy (also after the regular season pad set-up).
	st	(gamenum).w
	clr.l	d3			;d3 = used team bits
	move.w	(HomeTeam).w,d1
	bset	d1,d3
	move.w	(VisTeam).w,d1
	bset	d1,d3
	movea.w	#(gstruct-M68K_RAM),a1
	moveq	#7,d2
.loop	bsr.w	GetRandomUnusedTeam	;IDA: loc_146A4
	move.w	d0,(a1)			;gst1
	bsr.w	GetRandomUnusedTeam
	move.w	d0,gst2(a1)
	adda.w	#gssize,a1
	dbf	d2,.loop
	rts

GetRandomUnusedTeam	;93 only: return d0 = random team 0-23 not yet set in d3, and set its bit.
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
.save	move.w	-(a0),-(sp)		;IDA: loc_146CE. SuperDiv destroys the bits
	dbf	d0,.save
	moveq	#7,d2			;set gspobwins/gspotwins
	movea.w	#(gstruct+(7*gssize)-M68K_RAM),a1
.0	bclr	#2,gsflags(a1)		;IDA: _0. series over (92 gsfso)
	moveq	#5,d0
	bsr.w	SuperDiv
	move.w	d0,gspobwins(a1)
	cmp.w	#4,d0
	bne.w	.nsf0
	bset	#2,gsflags(a1)		;4 wins: gsfso
.nsf0	moveq	#5,d0			;IDA: _nsf0
	bsr.w	SuperDiv
	move.w	d0,gspotwins(a1)
	cmp.w	#4,d0
	bne.w	.nsf1
	bset	#2,gsflags(a1)		;gsfso
.nsf1	suba.w	#gssize,a1		;IDA: _nsf1
	dbf	d2,.0

	move.w	#$4000,d0		;set winbits (92 1<<14)
	bsr.w	SuperDiv
	move.w	d0,(WinBits).w

	moveq	#4,d0			;set POJoy
	bsr.w	SuperDiv
	move.w	d0,(playoffroundoffset).w	;92 pojoy

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
.restore	move.w	(sp)+,(a0)+	;IDA: loc_1475A. put the bits back
	dbf	d0,.restore
	rts

EncodePW	;after playoff game compute winners and password if needed. Called from GameOver (hockey93_06).
	tst.w	(OptPlayMode).w
	beq.w	rtss			;regular season
	move.w	#1,(OptPlayMode).w	;continue season

	bsr.w	ResolveGames
	bsr.w	maketree
	cmpi.w	#4,(gamelevel).w
	beq.w	.userwon		;finished playoffs
	tst.w	(gamenum).w
	bmi.w	.userwon		;93: po team out, same as a win (92 .userfailed / pojoy switch)
	movea.w	#(pwddatabuffer-M68K_RAM),a3		;password bits (Rev A pwddatabuffer $CB04)
	bsr.w	WritePassBits
	bsr.w	BitsToPW
	btst	#sf3alttree,(sflags3).w
	beq.w	rtss			;(92 retail; Rev A beq MakeTree)
	movea.w	#(tpassbits-M68K_RAM),a3		;bits before all games resolved (retail; Rev A unk_FFCB72, 92 tpassbits)
	bsr.w	ReadPassBits
	bra.w	maketree

.userwon	movea.w	#(pwddatabuffer-M68K_RAM),a3	;IDA: _userwon. password bits (Rev A $CB04)
	bsr.w	ClrPassBits		;(92 ResetPassWord)
	bsr.w	BitsToPW
	move.w	#2,(OptPlayMode).w	;new playoffs
	cmpi.w	#7,(bosgames).w
	beq.w	rtss
	move.w	#3,(OptPlayMode).w	;new playoffs best of 7
	rts

WritePassBits	;transfer game variables to the password bits at a3. 92 WritePassBits, without the checksum.
	;Called from EncodePW and ResolveGames (hockey93_10).
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

	move.w	(playoffroundoffset).w,d0	;92 pojoy
	moveq	#4,d1
	bsr.w	PushBits

	move.w	(WinBits).w,d0
	move.w	#$4000,d1		;92 1<<14
	bsr.w	PushBits

	moveq	#5,d1
	moveq	#7,d2
	movea.w	#(gstruct-M68K_RAM),a1
.0	move.w	gspotwins(a1),d0	;IDA: loc_1481A
	bsr.w	PushBits
	move.w	gspobwins(a1),d0
	bsr.w	PushBits
	adda.w	#gssize,a1
	dbf	d2,.0
	rts

PushBits	;IDA: EncodeValueToPassword. 92 PushBits: bits = bits * d1 + d0.
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

ClrPassBits	;IDA: ResetPassWord. 92 ClrPassBits: clr the 5 words of bits at a3
	movea.w	a3,a0
	moveq	#4,d0
.0	clr.w	(a0)+			;IDA: loc_14850
	dbf	d0,.0
	rts

SuperAdd	;IDA: AddValueToAccumulators. 1 long (d0.L) added to the 5 words at a3. 92 SuperAdd.
	movem.l	d1/a0,-(sp)
	lea	$A(a3),a0
	moveq	#3,d1
	add.l	d0,-(a0)
	bra.w	.2
.1	addq.w	#1,-(a0)		;IDA: loc_14868. carry into the next word up
.2	dbcc	d1,.1			;IDA: loc_1486A
	movem.l	(sp)+,d1/a0
	rts

SuperMult	;IDA: MultiplyValueByWeights. 1 word (d0) multiplied by the 5 words at a3. 92 SuperMult.
	movem.l	d1-d4/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d4
.0	move.w	(a0),-(sp)		;IDA: loc_1487C
	clr.w	(a0)+
	dbf	d4,.0
	moveq	#4,d4
.1	move.w	d0,d1			;IDA: loc_14886
	mulu.w	(sp)+,d1
	lea	2(a3),a0
	adda.w	d4,a0
	adda.w	d4,a0
	move.w	d4,d2
	add.l	d1,-(a0)
	bra.w	.3
.2	addq.w	#1,-(a0)		;IDA: loc_1489A
.3	dbcc	d2,.2			;IDA: loc_1489C
	dbf	d4,.1
	movem.l	(sp)+,d1-d4/a0
	rts

SuperDiv	;IDA: ReadPassBits__sd. 5 words at a3 divided by 1 word (d0). 92 SuperDiv.
	;d0 = remainder on exit
	movem.l	d1-d2/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d1
	clr.l	d2
.0	move.w	(a0),d2			;IDA: loc_148B4
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
.3	add.w	d1,d2			;IDA: loc_148D2
	lsr.w	#1,d1
	dbf	d0,.3
	subq.w	#1,d1
	move.l	(sp)+,d0
	rts

DisplayTeamStatsForPlayoffs	;93 only, IDA name. Adds the po team's game stats to its packed playoff
	;totals. Called from PeriodOver (hockey93_06) at the end of a playoff game. Unpacks the totals
	;(ReadTeamStats), adds the $68 stat bytes at team struct+$B4, then packs each total back into the
	;bit stream below $CB68, clamped to its BitWidthTable width (8, 10, 6, 6 bits, by d0 & 3).
	cmpi.w	#1,(OptPlayMode).w
	blt.w	rtss			;regular season
	bsr.w	ReadTeamStats
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2		;po team
	movea.w	#(hmtmstruct-M68K_RAM),a2
	cmp.w	$28(a2),d2		;team number of the home team struct
	beq.w	.area
	adda.w	#tmsize,a2		;po team is the visitor
.area	adda.w	#$B4,a2			;IDA: get_team_stats_area. stat bytes in the team struct
	moveq	#$67,d0			;$68 stats
	movea.w	#(statsbuffer-M68K_RAM),a1
.acc	clr.w	d1			;IDA: accumulate_team_stats
	move.b	(a2)+,d1
	add.w	d1,(a1)+
	dbf	d0,.acc
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2		;bit stream base (Rev A outputbuffer $CB0E)
	moveq	#$67,d0
	clr.w	d4			;d4 = bit position
.loop	clr.l	d1			;IDA: loop
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
.pack	not.l	d3			;IDA: pack_val_into_bitstream
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

BitWidthTable	;93 only: playoff stat bit widths, indexed by stat number & 3.
	;Used by DisplayTeamStatsForPlayoffs and ReadTeamStats.
	dc.b	8,$A,6,6

ReadTeamStats	;93 only, IDA name. Unpack the $68 playoff stat totals from the bit stream below $CB68
	;into statsbuffer words. Called from DisplayTeamStatsForPlayoffs and DisplayTeamStats (stats93).
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2		;bit stream base (Rev A outputbuffer $CB0E)
	moveq	#$67,d0			;$68 stats
	clr.w	d4			;d4 = bit position
.loop	move.w	d4,d5			;IDA: unpack_stats_from_bitstream
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
