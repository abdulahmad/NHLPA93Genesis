;	NHLPA Hockey 93 (retail) segment $10E66-$11801
;	92 hockey.asm part 2 tail (puckstick, setd0player, puckbody, puckgoalie,
;	deflect), then the 92 part 3 player-roster code that 93 moved here
;	(makepde ... setplayer) and the 93-only TryAddPlayerToList / ClampNibble.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	93 SortCords offsets ($80 per object), 92 names in comments where the
;	use matches: Xpos 0, attribute 4, frame 6, Ypos $14, Zpos $18, Xvel $28,
;	Yvel $2A, Zvel $2C, position $34, temp4 $46, temp5 $48, SCnum $52,
;	facedir $54, SPA $58, nopuck $5E (byte), newpos $60, newpnum $61,
;	pflags $62, pflags2 $63, pnum $66.
;	Player attributes written by setplayer: weight $67, legstr $68, legspd
;	$69, aioff $6A, aidef $6B, shotspd $6C, shotacc $6D, passacc $6E,
;	rostnum $6F, spodds $70, stickhand $71, endurance $72, aggress $73,
;	$74 (4(a0) & $E; hockey93_04 reads it as the fight rating), $75 (93
;	only), handed $76 (bit 0 set is left handed).
;	pflags bits match 92 (0 pfdoff, 5 pfalock, 6 pfteam). pflags2 bit 2 is
;	unavailable (92 pf2unav = 4).
;	93 team struct (tmsize $1A2, home at hmtmstruct): $C score (92 tmscore),
;	$16 tmline, $1E tmdata (long), $22 tmsort (word), $24 tmap, $26
;	tmgoalie (negative = no goalie), $30 tmflags, $32 tmpde, $66 tmpdst
;	(92 -2 bench / -1 ice / >0 penalty box; 93 adds -3), $16A line sets.
;	Assignment numbers are 93 asstab indexes; sound numbers are 93 sfx/song
;	numbers. The 92 name in a comment gives the role and the 92 value.

puckstick	;puck collides with stick
	;a2 = player who collided, a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx)
	;93: a goalie skips the steal roll, a goalie needs a loose puck within
	;8, and the catch speed limit is 13000 + 700 * stickhand
	tst.w	$34(a2)			;position
	bne.w	.0
	btst	#4,(gmode).w		;gmhl
	bne.w	rtss
.0	bclr	#0,pflags(a2)		;IDA: loc_10E90. pfdoff
	move.w	(puckc).w,d1
	bmi.w	.nosteal		;nobody has the puck
	asl.w	#7,d1			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d1,a0			;a0 = puck carrier
	move.b	pflags(a0),d1
	move.b	pflags(a2),d2
	eor.w	d1,d2
	btst	#6,d2			;pfteam
	beq.w	rtss			;no steal from team member
	cmp.l	#$24,d0			;6*6
	bhi.w	rtss			;smaller range for stealing puck
	tst.w	$34(a2)			;position
	beq.w	.steal			;93: a goalie always steals
	tst.w	$34(a0)
	beq.w	rtss			;no steal from goalie
	move.b	$71(a0),d0		;stickhand
	bsr.w	makepde
	move.w	d0,-(sp)
	exg	a0,a2
	move.b	$71(a0),d0		;stickhand
	bsr.w	makepde
	exg	a0,a2
	neg.w	d0
	add.w	(sp)+,d0		;carrier - stealer
	addi.w	#$24,d0			;36
	bsr.w	randomd0
	cmp.w	#2,d0
	bhi.w	rtss			;steal fails
.steal	move.b	$71(a0),d0		;IDA: loc_10EFC. stickhand
	bsr.w	makepde
	addi.w	#$14,d0			;20
	move.b	d0,$5E(a0)		;nopuck
	exg	a0,a2
	move.b	$71(a0),d0		;stickhand
	bsr.w	makepde
	addi.w	#$14,d0
	move.b	d0,$5E(a0)		;nopuck
	exg	a0,a2
	move.w	$52(a0),(lastplayer).w	;SCnum
	bclr	#2,(sflags).w		;sfspdir
	bclr	#3,(sflags).w		;sfssdir
.stdef	move.w	#6,-(sp)		;IDA: loc_10F32. stick deflect sound (92 SFXstdef = 5)
	bsr.w	sfx
	bsr.w	a2touchpuck
	bra.w	deflect

.nosteal	tst.w	$34(a2)		;IDA: loc_10F42. position
	bne.w	.spd			;skater: any range
	cmp.l	#$40,d0			;8*8 (93 only)
	bhi.w	rtss			;goalie too far from a loose puck
.spd	move.w	(puckvx).w,d0		;IDA: loc_10F54
	move.w	(puckvy).w,d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0			;puck speed^2 (92 scaled each by 1/64)
	clr.w	d1
	btst	#4,(sflags2).w
	bne.w	.nohand			;sflags2 bit 4 set: no stickhand bonus
	move.b	$71(a2),d1		;stickhand
	mulu.w	#$2BC,d1		;* 700
.nohand	addi.w	#$32C8,d1		;IDA: loc_10F76. + 13000
	mulu.w	d1,d1
	cmp.l	d1,d0
	bls.w	puckglue		;slow enough to catch (92 320*64)
	move.b	#8,$5E(a2)		;nopuck
	bra.s	.stdef

puckglue	;IDA: loc_10F8A. Player a2 takes the puck (92 puckstick .glue)
	;Global because puckgoalie .nopc also branches here. Plays song 7, or $C
	;($B for the home team) when sflags3 bit 4 was set, and counts a pass
	;completion when a2 is passReceiverPlayerNum. Falls into setd0player
	move.w	#7,-(sp)		;song 7 (92 sfx SFXpuckget = 8)
	move.w	$52(a2),d0		;SCnum
	move.w	d0,(puckc).w
	movea.w	#(hmtmstruct-M68K_RAM),a0
	lea	$1A2(a0),a1		;tmsize
	btst	#6,pflags(a2)		;pfteam
	bne.w	.tm
	exg	a0,a1
.tm	st	$1A(a0)			;IDA: loc_10FAA. a0 = other team, a1 = a2's team
	st	$1C(a0)
	bset	#3,$30(a0)		;tmflags bit 3
	bclr	#4,(sflags3).w
	beq.w	.snd			;sflags3 bit 4 was clear
	addq.w	#1,$E(a1)		;team word $E + 1
	addi.w	#$C8,(crowdlevel).w	;+200
	move.w	#$C,(sp)		;song $C
	cmpa.w	#(hmtmstruct-M68K_RAM),a1
	bne.w	.snd			;away team
	addi.w	#$A,(CwdExciteLvl).w
	move.w	#$B,(sp)		;song $B for the home team
.snd	bsr.w	song			;IDA: loc_10FE2
	move.w	$52(a2),d0		;SCnum
	cmp.w	(passReceiverPlayerNum).w,d0
	bne.w	.nrec
	addq.w	#1,$14(a1)		;pass reached its receiver: team word $14 + 1
.nrec	st	(passReceiverPlayerNum).w	;IDA: loc_10FF6
	bclr	#2,(sflags).w		;sfspdir
	bclr	#3,(sflags).w		;sfssdir
	tst.w	$34(a2)			;position
	bne.w	setd0player
	bsr.w	ChkShotStat
	move.w	#$8C,$48(a2)		;temp5 = 140, count down for faceoff (92 120)
	cmpi.w	#$314,$58(a2)		;SPA
	bne.w	setd0player
	move.w	#5,$48(a2)		;temp5 = 5 for SPA $314

setd0player	;give control of player d0 to a controller if his team is controlled
	;d0 = SCnum. Also called by checkfight .sf (hockey93_04)
	cmp.w	(c1playernum).w,d0
	beq.w	rtss			;already on controller 1
	cmp.w	(c2playernum).w,d0
	beq.w	rtss			;already on controller 2
	cmp.w	#6,d0
	slt	d1
	ext.w	d1
	addq.w	#2,d1			;d1 = 1 home (SCnum < 6), 2 visitors
	move.w	(lastplayer).w,d2
	cmp.w	(c2playernum).w,d2
	beq.w	.1			;last player was controller 2's: try cont 2 first
	cmp.w	(cont1team).w,d1
	beq.w	setc1player
.1	cmp.w	(cont2team).w,d1	;IDA: loc_11056
	beq.w	setc2player
	cmp.w	(cont1team).w,d1
	beq.w	setc1player
	rts

puckbody	;puck hits player a2. a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx)
	;93 keeps the old puck speed: a fast puck above 12 knocks a2 down
	;(FallDown), a slower one above 8 plays SPA $128A on a2
	cmpi.w	#8,Zpos(a3)		;Zpos, 3*8/3
	bgt.w	.hit
	move.w	d0,d1
	andi.w	#$F,d1			;radius^2 from center
	bne.w	rtss
.hit	bsr.w	a2touchpuck		;IDA: loc_1107C
	move.w	#$24,-(sp)		;puck body sound (92 SFXpuckbody = 5)
	bsr.w	sfx
	clr.w	$2C(a3)			;Zvel
	move.b	#8,$5E(a2)		;nopuck
	move.w	(a3),d0			;Xpos
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0	move.w	Xvel(a3),d2		;IDA: loc_110A8. old Xvel
	move.w	$2A(a3),d3		;old Yvel
	move.b	d0,Xvel(a3)
	move.b	d1,$2A(a3)		;Yvel
	bsr.w	puckflip
	cmpi.w	#8,Zpos(a3)
	ble.w	rtss			;puck low: no effect on a2
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d3,d2			;old speed^2
	cmp.l	#$9000000,d2		;$3000^2
	bls.w	.slow
	cmpi.w	#$C,Zpos(a3)		;Zpos 12
	bgt.w	FallDown
	rts
.slow	bset	#5,pflags(a2)		;IDA: loc_110E2. pfalock
	bne.w	rtss			;already in a locked anim
	move.w	#$128A,d1		;SPA for a2
	exg	a2,a3
	bsr.w	SetSPA
	exg	a2,a3
rtss	rts				;shared rts, branched to from many segments

puckgoalie	;puck hits goalie a2. a3 = puck, d0/d1 = goalie - puck x/y
	;Save odds from the goalie's save attribute and the frame table .list2.
	;93: song on a hard shot, a puck carrier loses the puck, and a slow
	;loose puck (.nopc) is caught through puckglue
	btst	#4,(gmode).w		;gmhl
	bne.s	rtss
	clr.w	d2			;puck region
	cmpi.w	#8,Zpos(a3)		;Zpos, 3*8/3
	bgt.w	.1
	addq.w	#2,d2
.1	neg.w	d0
	neg.w	d1
	bsr.w	vtoa
	sub.w	$54(a2),d0		;facedir
	andi.w	#7,d0
;0 puck straight in front of goalie
;1-3 puck to goalies right
;4 puck straight behind goalie
;5-7 puck to goalies left
	move.w	d0,d1
	andi.w	#3,d1
	bne.w	.2
	move.w	(VDP_CNTR).l,d0		;HV counter, just for random bit
.2	andi.w	#4,d0
	lsr.w	#2,d0
	eori.w	#1,d0
	add.w	d0,d2
	add.w	d2,d2
	lea	.list(pc),a0
	move.w	(a0,d2.w),d0
	moveq	#$F,d1
	add.b	(a2,d0.w),d1		;save odds
	lea	.list2(pc),a0
	btst	#3,attribute(a2)		;x flip?
	beq.w	.3
	eori.w	#2,d2
.3	move.w	frame(a2),d0
	subi.w	#$197,d0		;first goalie frame (92 SPFgoalie)
	move.b	(a0,d0.w),d0
	lsr.w	d2,d0
	andi.w	#3,d0
	mulu.w	d1,d0
	beq.s	rtss
	bsr.w	randomd0
	cmp.w	#8,d0
	blt.w	rtss			;no save
	bsr.w	ChkShotStat
	bsr.w	a2touchpuck
	cmpi.w	#$3000,(puckvy).w
	bgt.w	.setsfx
	cmpi.w	#$D000,(puckvy).w
	bgt.w	.nosong			;-$3000 < Yvel <= $3000: no song
.setsfx	move.w	#$B,-(sp)		;song $B (home goalie)
	btst	#6,pflags(a2)		;pfteam
	beq.w	.song
	move.w	#$D,(sp)		;song $D (visiting goalie)
.song	bsr.w	song			;IDA: loc_111AE
.nosong	move.w	#$24,-(sp)		;IDA: loc_111B2. puck body sound (92 SFXpuckbody = 5)
	bsr.w	sfx
	move.w	(puckc).w,d2
	bmi.w	.nopc			;loose puck
	st	(puckc).w		;carrier loses the puck
	asl.w	#7,d2			;scsize
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d2,a0
	move.b	#$14,$5E(a0)		;carrier nopuck = 20
	move.w	$52(a0),(lastplayer).w	;SCnum
	bclr	#2,(sflags).w		;sfspdir
	bclr	#3,(sflags).w		;sfssdir
.bounce	clr.w	$2C(a3)			;IDA: loc_111E6. Zvel
	move.b	#$A,$5E(a2)		;nopuck (92 8)
	move.w	#4,$46(a2)		;temp4
	move.w	(a3),d0			;Xpos
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0	move.b	d0,Xvel(a3)		;IDA: loc_1120C
	move.b	d1,$2A(a3)		;Yvel
	bra.w	puckflip
.nopc	cmpi.w	#$314,$58(a2)		;IDA: loc_11218. SPA
	beq.s	.bounce
	moveq	#2,d0
	add.b	$6C(a2),d0		;shotspd byte
	asl.w	#8,d0
	asl.w	#1,d0			;d0 = (2 + $6C) * 512
	bsr.w	randomd0
	addi.w	#$C00,d0		;catch speed limit
	cmp.w	(puckvx).w,d0
	blt.s	.bounce			;too fast in x
	cmp.w	(puckvy).w,d0
	blt.s	.bounce			;too fast in y
	neg.w	d0
	cmp.w	(puckvx).w,d0
	bgt.s	.bounce
	cmp.w	(puckvy).w,d0
	bgt.s	.bounce
	btst	#2,pflags2(a2)		;unavailable (92 pf2unav = 4)
	bne.s	.bounce
	clr.w	$2C(a3)			;Zvel
	bra.w	puckglue		;goalie holds the puck

.list	dc.b	0,$73,0,$6E,0,$70,0,$72	;IDA: _list. save attribute offsets (92 GGSleft, GGSright, GSSleft, GSSright)

.list2	;IDA: _list2. odds for stopping puck in each quadrant for each possible goalie frame
	dc.b	$55,$9D,$67,$55,$9D,$67,$55,$9D,$67,$55,$9D,$67	;ready/glover/glovel (92 pix 1111,2131,1213)
	dc.b	$55,$9D,$67,$55,$9D,$67,$55,$9D,$67,$55,$9D,$67
	dc.b	$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55	;goalie swing
	dc.b	$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0	;goalie stack right
	dc.b	$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0,$55,$F0	;goalie stack left
	dc.b	$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75,$D5,$75	;goalie stick right/left
	dc.b	$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55	;93 only from here
	dc.b	$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55
	dc.b	$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
	dc.b	$57,$57,$57,$57
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5

deflect	;random puck direction on deflection puck = a3. Entered from puckstick .stdef
	st	(puckc).w
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,$2A(a3)		;Yvel
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,$2C(a3)		;Zvel
	bra.w	puckflip

makepde	;pass d0 as value to be scaled by player a0's energy level
	;return d0 as result. Called from puckstick and logic93_1 (ShotMode)
	ext.w	d0
	move.w	d0,-(sp)
	movem.l	d1/a2-a3,-(sp)
	movea.l	a0,a3
	bsr.w	getpde
	movem.l	(sp)+,d1/a2-a3
	muls.w	(sp)+,d0
	asl.l	#4,d0
	swap	d0
	ext.l	d0			;d0 = d0 * energy / 4096
	rts

getpde	;get player a3's energy level into d0. Return a2 = his team struct, d1 = pnum*2
	movea.w	#(hmtmstruct-M68K_RAM),a2
	btst	#6,pflags(a3)		;pfteam
	beq.w	.0
	adda.w	#$1A2,a2		;tmsize
.0	move.b	$66(a3),d1		;IDA: loc_11358. pnum
	ext.w	d1
	add.w	d1,d1
	move.w	$32(a2,d1.w),d0		;tmpde
	rts

setpde	;d1 = rostnum of player * 2, a2 = team struct
	;d0 = new energy level. 93 drops the 92 d1 range check
	tst.w	d0
	bpl.w	.0
	clr.w	d0
.0	move.w	d0,$32(a2,d1.w)		;IDA: loc_1136E. tmpde
	rts

setpersonel	;this will set personel on team a2 according to team a2's registers
	;Asks SetPlList for the wanted players, keeps the ones already on the
	;ice, and puts the rest in sort objs with no requested player
	movem.l	d0-d5/a0-a4,-(sp)
	movea.w	$22(a2),a3		;tmsort
	moveq	#5,d4
.l0	st	$60(a3)			;newpos
	st	$61(a3)			;newpnum
	adda.w	#SCstruct,a3
	dbf	d4,.l0
	bsr.w	SetPlList
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4	;list of players we want on ice
.1	clr.w	d5
	move.b	(a4,d4.w),d5
	beq.w	.next
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	$22(a2),a3		;tmsort
	suba.w	#SCstruct,a3
.2	adda.w	#SCstruct,a3
	cmp.b	$66(a3),d5		;pnum
	dbeq	d3,.2
	bne.w	.next			;not on the ice now
	move.b	6(a4,d4.w),$60(a3)	;newpos
	move.b	d5,$61(a3)		;newpnum
	clr.b	(a4,d4.w)
.next	dbf	d4,.1
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4
.3	clr.w	d5			;IDA: loc_113D6
	move.b	(a4,d4.w),d5
	beq.w	.next2
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	$22(a2),a3		;tmsort
	suba.w	#SCstruct,a3
.4	adda.w	#SCstruct,a3			;IDA: loc_113EC
	tst.b	$61(a3)			;newpnum
	dbmi	d3,.4			;find a sort obj with no requested player
	bpl.w	.chkpos			;none left
	movea.w	a3,a0			;a0 = free sort obj
.chkpos	tst.w	$34(a3)			;IDA: loc_113FE. position
	dbpl	d3,.4			;93: keep looking while that obj has no position
	move.b	6(a4,d4.w),$60(a0)	;newpos
	move.b	d5,$61(a0)		;newpnum
	clr.b	(a4,d4.w)
.next2	dbf	d4,.3			;IDA: loc_11414
	movem.l	(sp)+,d0-d5/a0-a4
	rts

SetPlList	;create list (PlList) of players who we want on the ice now
	;a2 = team struct. 93 reads the lines from the team struct ($16A), and
	;falls back to every roster player when sublist has no free player
	movea.w	#(PlList-M68K_RAM),a4
	clr.l	(a4)
	clr.w	4(a4)
	movea.l	#priolist,a0
	tst.w	$26(a2)			;tmgoalie
	bpl.w	.gin
	addq.w	#1,a0			;no goalie: skip priolist goalie entry
.gin	lea	$16A(a2),a1		;line sets (92 tmdata LineSets)
	move.w	$16(a2),d0		;tmline
	asl.w	#3,d0
	adda.w	d0,a1
	move.w	$24(a2),d4		;tmap, active players 4-6
	bra.w	.next
.0	clr.w	d5
	move.b	(a0,d4.w),d5		;position
	move.b	(a1,d5.w),(a4,d4.w)	;player number
	move.b	d5,6(a4,d4.w)
	bne.w	.next
	moveq	#1,d3
	add.w	$26(a2),d3		;goalie: 1 + tmgoalie (92 adds 1 for the 2nd goalie only)
	move.b	d3,(a4,d4.w)
.next	dbf	d4,.0
	moveq	#5,d4			;now check to see if player is avail
.1	move.b	(a4,d4.w),d3
	beq.w	.next1
	ext.w	d3
	subq.w	#1,d3
	add.w	d3,d3
	cmpi.w	#$FFFD,$66(a2,d3.w)	;tmpdst -3 (93)
	beq.w	.sub
	tst.w	$66(a2,d3.w)		;tmpdst
	ble.w	.next1			;player is ok
.sub	lea	$16A(a2),a1		;IDA: loc_11490. now find player of similar position who is available
	move.b	6(a4,d4.w),d0		;position
	ext.w	d0
	asl.w	#1,d0
	movea.l	#sublist,a0
	adda.w	(a0,d0.w),a0		;93 sublist is word offsets (92 long pointers)
.s1	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.all			;end of list
	move.b	(a1,d0.w),d0
	bsr.w	TryAddPlayerToList
	beq.s	.s1			;not available
.next1	dbf	d4,.1
	rts
.all	jsr	(GetPlayerCount).l	;IDA: loc_114BE. 93: try every roster player, last first
	move.w	d0,d3
.try	move.w	d3,d0			;IDA: loc_114C6
	subq.w	#1,d3
	bmi.s	.next1			;none available
	bsr.w	TryAddPlayerToList
	beq.s	.try
	bra.s	.next1

TryAddPlayerToList	;93 split of 92 SetPlList .s1/.s2. d0 = player number (1 based), d4 = PlList slot
	;a2 = team struct, a4 = PlList. Return Z clear = added, Z set (d1 = 0) = not available
	move.w	d0,d1
	subq.w	#1,d0
	add.w	d0,d0
	tst.w	$66(a2,d0.w)		;tmpdst
	bgt.w	.no			;in penalty box
	cmpi.w	#$FFFD,$66(a2,d0.w)	;-3 (93)
	beq.w	.no
	moveq	#5,d0
.s2	cmp.b	(a4,d0.w),d1		;IDA: loc_114EE
	dbeq	d0,.s2
	beq.w	.no			;already in PlList
	move.b	d1,(a4,d4.w)
	rts
.no	clr.w	d1			;IDA: loc_11500
	rts

forcepldata	;no skating on/off force players to correct data (for faceoffs only)
	;a2 = team struct
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	$22(a2),a3		;tmsort
	moveq	#5,d4
.top	move.b	$60(a3),d0		;newpos
	ext.w	d0
	move.w	d0,$34(a3)		;position
	bmi.w	.next
	bsr.w	Setplass
	cmpi.w	#4,$34(a3)		;center
	bne.w	.notnear
	move.l	#$11,d0			;anearest (92 17)
	bsr.w	assinsert
.notnear	clr.w	d3
	move.b	$61(a3),d3		;newpnum
	add.w	d3,d3
	move.w	#$FFFF,$66(a2,d3.w)	;tmpdst, put player on the ice
	lsr.w	#1,d3
	bsr.w	setplayer
.next	st	$61(a3)			;newpnum
	st	$60(a3)			;newpos
	adda.w	#SCstruct,a3
	dbf	d4,.top
	movem.l	(sp)+,d0-d4/a0-a3
	rts

ResetBench	;remove all players from penalty box/ put all players on their own bench
	;PBnum = players left in the box, home * 16 + visitors. 93 keeps -3 players
	;and drops box players with tmpdst bit 12 set and no time left from the count
	clr.b	(PBnum).w
	moveq	#$10,d1
	movea.w	#(hmtmstruct-M68K_RAM),a0
	bsr.w	.rb
	moveq	#1,d1
	adda.w	#$1A2,a0		;tmsize, falls in for the visitors
.rb	moveq	#$32,d0			;IDA: ResetBench_rb. (MaxRos-1)*2
.rb1	add.b	d1,(PBnum).w
	tst.w	$66(a0,d0.w)		;tmpdst
	ble.w	.nopen
	btst	#4,$66(a0,d0.w)		;bit 12 of tmpdst
	beq.w	.next			;stays in the box
	move.w	$66(a0,d0.w),d2
	andi.w	#$7FF,d2
	bne.w	.next			;time left
	sub.b	d1,(PBnum).w
	bra.w	.next
.nopen	sub.b	d1,(PBnum).w		;IDA: loc_1159E
	cmpi.w	#$FFFD,$66(a0,d0.w)	;-3 (93)
	beq.w	.next
	move.w	#$FFFE,$66(a0,d0.w)	;-2 bench
.next	subq.w	#2,d0
	bpl.s	.rb1
	rts

Setplass	;set players (a3) initial assignment
	move.w	$34(a3),d0		;position
	bmi.w	rtss
	lea	.alist(pc),a0
	move.b	(a0,d0.w),d0
	bra.w	assreplace

.alist	;IDA: _alist. 93 asstab numbers
	dc.b	$E			;agoalie (92 15)
	dc.b	2			;adefd
	dc.b	2			;adefd
	dc.b	3			;awingd
	dc.b	5			;acenterd
	dc.b	3			;awingd
	dc.b	5			;acenterd
	dc.b	$FA			;retail pad (Rev A: 0)

setplayer	;bring player onto the ice and set his stats
	;d3 = player number, a3 = sortcord of player. 93 reads each attribute
	;nibble from a variable-length roster record and, for skaters, adds the
	;modifier bytes at dword_FFC9C2 (+0/+1 from sflags2 bit 5 and chkpk2,
	;+3 home bonus / visitor penalty, +2 = 2 when tied or trailing with at
	;least half of the 3rd period left, or after the 3rd period), clamped to
	;0-15 by ClampNibble
	bclr	#6,pflags2(a3)		;pflags2 bit 6 (93)
	movea.w	#(hmtmstruct-M68K_RAM),a0
	btst	#6,pflags(a3)		;pfteam
	beq.w	.0
	adda.w	#$1A2,a0		;tmsize
.0	move.b	d3,$66(a3)		;pnum
	move.l	#$A,d0			;aepen (92 11)
	ext.w	d3
	add.w	d3,d3
	move.w	$66(a0,d3.w),d1		;tmpdst
	bpl.w	.da			;from the penalty box
	move.l	#9,d0			;aeben (92 10)
	cmp.w	#$FFFE,d1		;-2 bench
	bne.w	.nda
.da	bsr.w	assinsert
	bclr	#5,pflags(a3)		;pfalock
	clr.w	$58(a3)			;SPA
.nda	move.w	#$FFFF,$66(a0,d3.w)	;tmpdst -1 on the ice (93)
	lsr.w	#1,d3
	movea.l	$1E(a0),a0		;tmdata
	move.l	a0,-(sp)
	adda.w	8(a0),a0		;team data + word at team data+8 (92 LineSets offset)
	clr.l	(dword_FFC9C2).w	;modifiers
	tst.w	$34(a3)			;position
	beq.w	.nomod			;goalie: no modifiers
	btst	#5,(sflags2).w
	beq.w	.nda3
	bsr.w	chkpk2
	beq.w	.nda2
	move.b	1(a0),(dword_FFC9C2).w	;+0 = low nibble of byte 1
	andi.b	#$F,(dword_FFC9C2).w
	bra.w	.nda3
.nda2	move.b	1(a0),d0
	lsr.b	#4,d0
	neg.b	d0
	move.b	d0,(dword_FFC9C2+1).w	;+1 = -high nibble of byte 1
.nda3	move.b	2(a0),d0
	andi.b	#$F,d0
	neg.b	d0			;visitors: -low nibble of byte 2
	btst	#6,pflags(a3)		;pfteam
	bne.w	.tm
	move.b	2(a0),d0
	lsr.b	#4,d0			;home: high nibble of byte 2
.tm	move.b	d0,(dword_FFC9C2+3).w	;IDA: loc_11684
	cmpi.w	#2,(gsp).w		;period
	blt.w	.nomod			;1st or 2nd period
	bgt.w	.score			;after the 3rd period
	jsr	(GetPeriodTime).w
	lsr.w	#1,d0
	cmp.w	(gameclock).w,d0
	bgt.w	.nomod			;under half of the 3rd period left (clock counts down)
.score	move.w	(tmstructtmscore).w,d0	;IDA: loc_116A4. home score
	sub.w	(tmstructtmscoretmsize).w,d0	;- visitor score
	beq.w	.close			;tied
	btst	#6,pflags(a3)		;pfteam
	beq.w	.side
	eori	#8,ccr			;visitors: flip N
.side	bpl.w	.nomod			;IDA: loc_116BE. leading
.close	move.b	#2,(dword_FFC9C2+2).w	;IDA: loc_116C2
.nomod	movea.l	(sp)+,a0		;IDA: loc_116C8. tmdata
	adda.w	(a0),a0			;roster records (92 Playerdata)
.find	adda.w	(a0),a0			;IDA: loc_116CC. skip name
	addq.w	#8,a0			;skip 8 attribute bytes
	dbf	d3,.find
	subq.w	#8,a0			;a0 = player d3's attribute bytes
	move.b	(a0),$6F(a3)		;rostnum
	move.b	1(a0),d3
	andi.w	#$F0,d3
	lsr.w	#1,d3			;(92 no shift)
	move.b	d3,$67(a3)		;weight
	move.b	1(a0),d3
	andi.b	#$F,d3
	move.b	d3,$68(a3)		;legstr
	move.b	2(a0),d3
	lsr.b	#4,d3
	move.b	d3,$69(a3)		;legspd
	move.b	2(a0),d3
	andi.b	#$F,d3
	add.b	(dword_FFC9C2).w,d3
	add.b	(dword_FFC9C2+1).w,d3
	add.b	(dword_FFC9C2+3).w,d3
	add.b	(dword_FFC9C2+2).w,d3
	bsr.w	ClampNibble
	eori.b	#$F,d3
	addi.b	#$F,d3			;frames to skip
	lsr.b	#1,d3
	move.b	d3,$6A(a3)		;aioff
	move.b	3(a0),d3
	lsr.b	#4,d3
	add.b	(dword_FFC9C2+3).w,d3
	bsr.w	ClampNibble
	eori.b	#$F,d3
	addi.b	#$F,d3			;frames to skip
	lsr.b	#1,d3
	move.b	d3,$6B(a3)		;aidef
	move.b	3(a0),$6C(a3)		;shotspd
	andi.b	#$F,$6C(a3)
	move.b	4(a0),d3
	lsr.b	#4,d3
	add.b	(dword_FFC9C2+2).w,d3
	bsr.w	ClampNibble
	move.b	d3,$75(a3)		;93 only attribute
	bclr	#3,attribute(a3)
	move.b	4(a0),$76(a3)		;handed
	andi.b	#1,$76(a3)		;bit 0 set is left handed
	bne.w	.ha
	bset	#3,attribute(a3)
.ha	move.b	4(a0),$74(a3)		;IDA: loc_1177E
	andi.b	#$E,$74(a3)
	move.b	5(a0),d3
	lsr.b	#4,d3
	add.b	(dword_FFC9C2).w,d3
	add.b	(dword_FFC9C2+1).w,d3
	add.b	(dword_FFC9C2+3).w,d3
	bsr.w	ClampNibble
	move.b	d3,$71(a3)		;stickhand
	move.b	5(a0),d3
	andi.b	#$F,d3
	add.b	(dword_FFC9C2).w,d3
	add.b	(dword_FFC9C2+1).w,d3
	add.b	(dword_FFC9C2+3).w,d3
	bsr.w	ClampNibble
	move.b	d3,$6D(a3)		;shotacc
	move.b	6(a0),d3
	lsr.b	#4,d3
	move.b	d3,$72(a3)		;endurance
	move.b	6(a0),d3
	andi.b	#$F,d3
	add.b	(dword_FFC9C2+2).w,d3
	add.b	(dword_FFC9C2+2).w,d3
	bsr.w	ClampNibble
	move.b	d3,$70(a3)		;spodds
	move.b	7(a0),d3
	lsr.b	#4,d3
	add.b	(dword_FFC9C2).w,d3
	add.b	(dword_FFC9C2+3).w,d3
	bsr.w	ClampNibble
	move.b	d3,$6E(a3)		;passacc
	move.b	7(a0),$73(a3)		;aggress
	andi.b	#$F,$73(a3)
	rts

ClampNibble	;93 only: clamp byte d3 to 0-15. Called by setplayer
	tst.b	d3
	bpl.w	.hi
	clr.w	d3			;negative: 0
.hi	cmp.b	#$F,d3			;IDA: loc_1180E
	ble.w	.x
	moveq	#$F,d3
.x	rts				;IDA: locret_11818
