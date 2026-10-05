;	NHLPA Hockey 93 (retail) segment $8AC4-$946D
;	92 hockey.asm part 1, second half: ReplayMode, getpzjoy, suba4/adda4,
;	RestoreReplayFrame (92 SetRCords + nonshift), updatereplay, rtss2 ($9092),
;	updateplayers ($9094), updateanim, freezewindow ($933C), checkwindow ($9350).
;	Bytes match nhlpa93retail.bin. Rev A has a 10-byte insertion inside
;	updateplayers (speed x$14 when music_global_tick_counter is set); retail
;	has the 92 code there.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	Struct offsets are 93 SortCords offsets; 92 names in comments where the
;	use matches 92 (Xpos 0, attribute 4, frame 6, Ypos $14, Zpos $18,
;	OldXpos $1C, Xvel $28, Yvel $2A, Zvel $2C, impact $32, position $34,
;	assnum $36, asslist $38, SCnum $52, facedir $54, SPA $58, SPAnum $5A,
;	SPAcnt $5C, pflags $62, pflags2 $63, glitch $65).
;	Replay frames are $62 bytes (92 replaysize = 84) from $FFFF0000
;	(replaystart) to $FFFFAF54 (replayend).

ReplayMode	;this is instant replay play-back control and display code.
	;Called from the pause menu. 93 adds tracking: a d-pad press picks the
	;nearest object in that direction and the camera follows it
	bsr.w	forceblack
	move.w	(disflags).w,-(sp)
	bset	#3,(sflags2).w		;sf2replay: flag that replay is on
	bsr.w	ClrHor			;goto vertical icerink
	move.w	#$400,d0
	move.w	(VmMap3).w,d1
	move.w	#$7FF,d2
	bsr.w	DoFill			;clear map 3
	bsr.w	printz
	String	$BD,2,2
	moveq	#$20,d0
	moveq	#$55,d1
	moveq	#8,d2
	moveq	#4,d3
	move.w	(rinkvrcset).w,d4
	move.w	#0,d5
	movea.l	#IceRinkMap,a1
	adda.l	4(a1),a1
	movea.w	#$310,a2		;92 null
	bsr.w	dobitmap		;display replay icon
	bclr	#5,(sflags).w		;sfscrl: manual scroll is off
	bclr	#5,(sflags3).w		;no tracked object
	st	(byte_FFBE1E).w
	movea.l	(ReplayBufferPtr).w,a4	;92 recbpr, record buffer pointer (current frame)
.rwd	bsr.w	suba4			;IDA: RewindToStart. Rewind to first frame
	tst.w	d7
	bne.s	.rwd
	jsr	(SprSort).l
	jsr	(setvideo).l
	bclr	#1,(sflags3).w		;sf3rmplay: play mode is off
	move.w	#$18,(palcount).w	;fade in colors now/graphics are ready
	moveq	#1,d7
.top	move.w	(vcount).w,d0		;IDA: ReplayMainLoop
	sub.w	(oldvcount).w,d0
	cmp.w	d0,d7
	bhi.s	.top			;wait d7 frames
	move.w	(vcount).w,(oldvcount).w
	moveq	#1,d7
	bsr.w	getpzjoy
	movea.w	#(CameraPosStruct-M68K_RAM),a5
	btst	#5,(sflags3).w		;tracking an object?
	beq.w	.dir
	move.w	d1,d5
	andi.w	#$F,d5			;new d-pad press?
	beq.w	.nomans			;no: keep tracking
.dir	btst	#3,d0			;IDA: CheckDirectionInput
	bne.w	.nomans			;no d-pad input
	bset	#5,(sflags).w		;sfscrl: manual scrolling is on
	bne.w	.man
	move.w	(Hpos).w,(a5)		;first frame: camera starts at the screen
	move.w	(Vpos).w,$14(a5)
.man	move.w	d0,d5			;IDA: ManualScroll. d5 = d-pad direction
	andi.w	#7,d5
	eori.w	#4,d5
	movea.w	#(SortCords-M68K_RAM),a1
	st	d3			;no object to skip
	bclr	#5,(sflags3).w
	beq.w	.find
	move.w	$16(a5),d3		;skip the object tracked now
.find	move.w	(a5),d0			;IDA: FindTrackingTarget
	move.w	$14(a5),d1
	moveq	#$B,d2			;12 players
	move.l	#$100,d4		;nearest distance squared so far
	movem.w	d0-d1,-(sp)
.obj	cmp.w	$52(a1),d3		;IDA: CheckObjectLoop
	beq.w	.skip
	movem.w	(sp),d0-d1
	sub.w	(a1),d0
	sub.w	$14(a1),d1
	jsr	(vtoa).l		;direction to object
	btst	#3,d0
	bne.w	.skip
	sub.w	d5,d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.skip			;not within 45 degrees of the d-pad
	movem.w	(sp),d0-d1
	sub.w	(a1),d0
	sub.w	$14(a1),d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#4,d0
	bls.w	.skip			;too close
	cmp.l	d4,d0
	bhi.w	.skip			;not nearer
	move.l	d0,d4
	move.w	$52(a1),$16(a5)		;SCnum of new target
	bset	#5,(sflags3).w
.skip	adda.w	#$80,a1			;IDA: SkipObject. SCstruct size
	dbf	d2,.obj
	addq.w	#4,sp
	btst	#5,(sflags3).w
	beq.w	.scrl			;nothing found: scroll by hand
	move.w	$16(a5),d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	moveq	#4,d4
	bsr.w	setpads
	bsr.w	UpdateCameraPos
	jsr	(setvideo).l
	bra.w	.top
.scrl	bset	#5,(sflags).w		;IDA: UpdateManualScroll
	eori.w	#4,d5
	asl.w	#2,d5
	lea	.stab(pc),a0
	move.w	(a0,d5.w),d0
	add.w	(a5),d0
	cmp.w	#$88,d0
	bgt.w	.nox
	cmp.w	#-$88,d0
	blt.w	.nox
	move.w	d0,(a5)
.nox	move.w	2(a0,d5.w),d1		;IDA: ClampCameraX
	add.w	$14(a5),d1
	cmp.w	#$126,d1
	bgt.w	.noy
	cmp.w	#-$126,d1
	blt.w	.noy
	move.w	d1,$14(a5)
.noy	movea.w	a5,a3			;IDA: ClampCameraY
	clr.w	$18(a5)
	andi.w	#$FFF,(PadControlBits).w
	ori.w	#$E000,(PadControlBits).w
	bsr.w	UpdateCameraPos
	jsr	(setvideo).l
	bra.w	.top
.stab	dc.w	0,2,2,2,2,0,2,-2,0,-2,-2,-2,-2,0,-2,2	;IDA: ScrollDirTbl. 92 steps * 2

.nomans	st	$18(a5)			;IDA: HandleNoInput
	btst	#5,d1			;cbut
	beq.w	.00
	bchg	#1,(sflags3).w		;sf3rmplay: switch play mode
.00	btst	#6,d3			;IDA: CheckRewind. abut
	beq.w	.0
	bsr.w	suba4			;fast rewind
	bsr.w	suba4
	bsr.w	suba4
	bsr.w	suba4
	jsr	(SprSort).l
	jsr	(setvideo).l
	moveq	#1,d7
	bclr	#1,(sflags3).w		;turn off play mode
.0	btst	#4,d3			;IDA: CheckAdvance. bbut
	beq.w	.1
	btst	#6,d3			;abut
	beq.w	.f1
	bclr	#5,(sflags3).w
	bclr	#5,(sflags).w		;a+b but = manual scroll off (hidden feature)
	bra.w	.top
.f1	bsr.w	adda4			;IDA: AdvanceOneFrame. Advance 1 frame
	jsr	(SprSort).l
	jsr	(setvideo).l
	asl.w	#1,d7			;double delay time between frames = 1/2 speed slow motion
	bclr	#1,(sflags3).w		;turn off play mode
.1	btst	#1,(sflags3).w		;IDA: CheckPlayMode. sf3rmplay
	beq.w	.noplay
	st	(lastsfx).w		;play mode is on = advance one frame at original speed
	bsr.w	adda4
	move.w	(lastsfx).w,-(sp)	;play sound effects
	bsr.w	sfx
	jsr	(SprSort).l
.noplay	jsr	(setvideo).l		;IDA: CheckExit
	btst	#7,d1			;sbut
	beq.w	.top			;no exit yet
	bsr.w	forceblack
	ori.w	#$F000,(PadControlBits).w
	bclr	#5,(sflags).w
	movea.l	(ReplayBufferPtr).w,a4	;back to the current frame
	bsr.w	RestoreReplayFrame
	jsr	(SprSort).l
	bclr	#3,(sflags2).w		;sf2replay
	move.w	(sp)+,(disflags).w
	bsr.w	SetHor
	jsr	(setvideo).l		;restore old video
	move.w	#$18,(palcount).w
	rts				;exit replay mode

getpzjoy	;read the joystick of the pad that paused
	btst	#1,(sflags).w		;sfpj
	bne.w	Readjoy2
	bra.w	Readjoy1

suba4	;IDA: suba4_reverseReplayFrame. a4 = address in replay buffer of current
	;frame. Back up 1 frame and set video parameters for display.
	;d7 will be set to delay between frames or zero if at the end of replay
	cmpa.l	#$FFFF0000,a4		;replaystart
	bne.w	.1
	btst	#4,(sflags).w		;sfwrap
	beq.w	.end
	movea.l	#$FFFFAF54,a4		;replayend
.1	suba.w	#$62,a4			;replaysize
	cmpa.l	(ReplayBufferPtr).w,a4
	bne.w	RestoreReplayFrame
	adda.w	#$62,a4			;reached the record point
.end	bsr.w	RestoreReplayFrame	;IDA: loc_8DFE
	clr.w	d7
	rts

adda4	;IDA: adda4_advanceReplayFrame. a4 = address in replay buffer of current
	;frame. Step forward 1 frame and set video parameters for display.
	;d7 will be set to delay between frames or zero if at the end of replay
	clr.w	d7
	btst	#2,(sflags2).w		;sf2drec
	beq.w	adda42
	move.l	a4,-(sp)
	bsr.w	adda43
	cmpa.l	(ReplayBufferPtr).w,a4
	movea.l	(sp)+,a4
	beq.w	rtss2
adda42	;adda4 without the sf2drec look-ahead. Stop at the record point,
	;else show the frame and fall into adda43
	cmpa.l	(ReplayBufferPtr).w,a4
	beq.w	rtss2
	bsr.w	RestoreReplayFrame
adda43	;a4 += replaysize, wrapping from replayend to replaystart
	adda.w	#$62,a4			;replaysize
	cmpa.l	#$FFFFAF54,a4		;replayend
	bne.w	rtss2
	movea.l	#$FFFF0000,a4		;replaystart
	rts

UpdateCameraPos	;93 only. Camera struct a5 = object a3's x/y, Hpos/Vpos =
	;that position clamped to the scroll limits
	movem.l	d0-d2,-(sp)
	move.w	(a3),d0
	move.w	d0,(a5)
	move.w	$14(a3),d1
	move.w	d1,$14(a5)
	cmp.w	#$3C,d0
	blt.w	.0
	move.w	#$3C,d0			;92 checkwindow .xslim
.0	cmp.w	#-$3C,d0		;IDA: loc_8E60
	bgt.w	.1
	move.w	#$FFC4,d0
.1	move.w	d0,(Hpos).w		;IDA: loc_8E6C
	cmp.w	#$100,d1
	blt.w	.2
	move.w	#$100,d1		;92 .yslimu
.2	cmp.w	#-200,d1		;IDA: loc_8E7C
	bgt.w	.3
	move.w	#$FF38,d1		;92 .yslimd
.3	move.w	d1,(Vpos).w		;IDA: loc_8E88
	movem.l	(sp)+,d0-d2
	rts

RestoreReplayFrame	;a4 = current replay frame address to convert into normal
	;cordinates (92 SetRCords), then set the other replay variables (92
	;nonshift). Returns d7 = frame delay. Hpos/Vpos come from the frame unless
	;scrolling by hand (sfscrl), then from the camera or tracked object.
	;Also the tail of suba4
	movem.l	d0-d2/a0,-(sp)
	movea.l	a4,a0
	moveq	#$F,d1			;16 objects to convert (12 players/puck/shadow/2 goal nets)
	movea.w	#(SortCords-M68K_RAM),a3
.top	move.w	2(a0),d2		;IDA: loc_8E9E
	andi.w	#$3FF,d2
	btst	#9,d2
	beq.w	.p
	ori.w	#$FC00,d2
.p	move.w	d2,(a3)			;IDA: loc_8EB2. Xpos
	move.l	(a0),d2
	asr.l	#4,d2
	asr.w	#6,d2
	btst	#9,d2
	beq.w	.p1
	ori.w	#$FC00,d2
.p1	move.w	d2,$14(a3)		;IDA: loc_8EC6. Ypos
	move.w	(a0),d2
	asr.w	#4,d2
	andi.w	#$3FF,d2
	move.w	d2,6(a3)		;frame
	move.w	(a0),d2
	asr.w	#3,d2
	andi.w	#$1800,d2
	andi.w	#$E7FF,4(a3)		;attribute flip bits
	or.w	d2,4(a3)
	addq.w	#4,a0
	adda.w	#$80,a3
	dbf	d1,.top
	moveq	#5,d2			;6 pairs of players
	movea.w	#(SortCords-M68K_RAM),a3
.pl	move.b	(a0)+,$6F(a3)		;IDA: loc_8EF8
	move.b	(a0),d0
	andi.w	#$F,d0
	cmp.w	#$F,d0
	bne.w	.n0
	moveq	#-1,d0			;$F = not on ice
.n0	move.w	d0,$34(a3)		;IDA: loc_8F0C. position
	adda.w	#$80,a3
	move.b	(a0)+,d0
	lsr.b	#4,d0
	move.b	d0,$6F(a3)
	move.b	(a0),d0
	asl.b	#4,d0
	or.b	d0,$6F(a3)
	move.b	(a0)+,d0
	lsr.b	#4,d0
	andi.w	#$F,d0
	cmp.w	#$F,d0
	bne.w	.n1
	moveq	#-1,d0
.n1	move.w	d0,$34(a3)		;IDA: loc_8F36
	adda.w	#$80,a3
	dbf	d2,.pl
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(puckz).w		;puck z cord
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(puckzSCstructShadow).w	;puck shadow zcord
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(lastsfx).w		;sound effect cue
	clr.w	d7
	move.b	(a0)+,d7		;frame delay
	move.w	(a0)+,d0
	andi.w	#$FFF,d0
	andi.w	#$F000,(PadControlBits).w
	or.w	d0,(PadControlBits).w
	move.w	(a0)+,(crowdframe).w
	move.w	(a0)+,(glovecords).w
	move.b	(a0)+,(PBnum).w
	addq.w	#1,a0
	btst	#5,(sflags).w		;sfscrl
	beq.w	.pos
	movea.w	a5,a3
	btst	#5,(sflags3).w		;tracking an object?
	beq.w	.cam
	clr.w	$18(a5)
	move.w	$16(a5),d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
.cam	bsr.w	UpdateCameraPos		;IDA: loc_8FA2
	bra.w	.x
.pos	move.w	(a0)+,(Hpos).w		;IDA: loc_8FAA
	move.w	(a0)+,(Vpos).w
.x	movem.l	(sp)+,d0-d2/a0		;IDA: loc_8FB2
	rts

updatereplay	;called every frame to save replay events, d7 = elapsed frames
	btst	#4,(gmode).w		;gmhl: no recording in highlight mode
	bne.w	rtss2
	btst	#2,(sflags2).w		;sf2drec
	bne.w	.rec			;record off: keep overwriting this frame
	addi.l	#$62,(ReplayBufferPtr).w	;replaysize
	cmpi.l	#$FFFFAF54,(ReplayBufferPtr).w	;replayend
	bne.w	.rec
	bset	#4,(sflags).w		;sfwrap
	move.l	#$FFFF0000,(ReplayBufferPtr).w	;replaystart
.rec	movea.l	(ReplayBufferPtr).w,a0	;IDA: loc_8FEE
	moveq	#$F,d2			;16 objects (92 record)
	movea.w	#(SortCords-M68K_RAM),a3
.top	clr.l	(a0)			;IDA: loc_8FF8
	move.w	(a3),d1			;Xpos
	andi.w	#$3FF,d1
	move.w	d1,2(a0)
	clr.l	d1
	move.w	$14(a3),d1		;Ypos
	asl.w	#6,d1
	asl.l	#4,d1
	or.l	d1,(a0)
	move.w	6(a3),d1		;frame
	asl.w	#4,d1
	or.w	d1,(a0)
	move.w	4(a3),d1		;attribute
	andi.w	#$1800,d1
	asl.w	#3,d1
	or.w	d1,(a0)
	addq.w	#4,a0
	adda.w	#$80,a3
	dbf	d2,.top
	moveq	#5,d2			;6 pairs of players
	movea.w	#(SortCords-M68K_RAM),a3
.pl	move.b	$6F(a3),(a0)+		;IDA: loc_9034
	move.w	$34(a3),d0		;position
	bpl.w	.n0
	moveq	#$F,d0			;not on ice
.n0	andi.w	#$F,d0			;IDA: loc_9042
	move.b	d0,(a0)
	adda.w	#$80,a3
	move.b	$6F(a3),d0
	asl.w	#4,d0
	or.b	d0,(a0)+
	move.b	$6F(a3),d0
	lsr.b	#4,d0
	move.b	d0,(a0)
	move.w	$34(a3),d0
	bpl.w	.n1
	moveq	#$F,d0
.n1	asl.w	#4,d0			;IDA: nonshift (misplaced name, not 92 nonshift)
	or.b	d0,(a0)+
	adda.w	#$80,a3
	dbf	d2,.pl
	move.b	(puckz+1).w,(a0)+
	move.b	(puckZSCStruct).w,(a0)+	;puckz+SCstruct+1
	move.b	(lastsfx+1).w,(a0)+	;sound effect cue
	bset	#7,(lastsfx+1).w
	move.b	d7,(a0)+		;save elapsed frames
	move.w	(PadControlBits).w,(a0)+
	move.w	(crowdframe).w,(a0)+
	move.w	(glovecords).w,(a0)+
	move.b	(PBnum).w,(a0)+
	addq.w	#1,a0
	move.w	(Hpos).w,(a0)+
	move.w	(Vpos).w,(a0)+
rtss2	rts				;shared rts, called from many segments

updateplayers
	;this routine calls all collision/animation/assignment code for all the players
	;d7 = elapse frames since last call
	btst	#7,(sflags).w		;sfhor
	bne.w	.u0
	ori.w	#$F,(PadControlBits).w
.u0	movea.w	#(SortCords-M68K_RAM),a3	;IDA: _scload
.top	move.l	(a3),$1C(a3)		;IDA: _top. Xpos -> OldXpos
	move.l	$14(a3),$20(a3)		;Ypos -> OldYpos
	move.l	$18(a3),$24(a3)		;Zpos -> OldZpos
	tst.w	$34(a3)			;position
	bmi.w	.nf1			;player is not on ice
	bsr.w	updateanim
	sub.b	d7,$5E(a3)		;puck control (92 nopuck)
	bpl.w	.np
	clr.b	$5E(a3)
.np	sub.b	d7,$5F(a3)		;IDA: loc_90DE
	bpl.w	.np2
	clr.b	$5F(a3)
.np2	btst	#6,(sflags3).w		;IDA: loc_90EA. Check line change mode
	beq.w	.vel
	clr.w	d0
	move.b	$66(a3),d0
	bmi.w	.vel
	add.w	d0,d0
	addi.w	#$136,d0
	bsr.w	loadTeamStruct
	addq.w	#1,(a2,d0.w)		;count frames on ice for this player
.vel	cmpi.w	#$1616,$58(a3)		;IDA: loc_910C. SPA $1616: skip movement and bounce
	beq.w	.done
;----------------------------------	now update velocity
	move.w	d7,d4			;Rev A: moveq #$10 or #$14 (music_global_tick_counter), mulu d7
	asl.w	#4,d4
	tst.w	$18(a3)			;Zpos
	bne.w	.y2			;no deceleration
	moveq	#6,d2
	btst	#0,$62(a3)		;pfdoff
	beq.w	.off
	moveq	#9,d2
.off	move.w	$28(a3),d0		;Xvel
	beq.w	.x2
	asr.w	d2,d0
	bne.w	.x1
	moveq	#1,d0
.x1	sub.w	d0,$28(a3)
.x2	move.w	$2A(a3),d0		;Yvel
	beq.w	.y2
	asr.w	d2,d0
	bne.w	.y1
	moveq	#1,d0
.y1	sub.w	d0,$2A(a3)
.y2	move.w	$28(a3),d0
	beq.w	.x3
	muls.w	d4,d0
	add.l	d0,(a3)
.x3	move.w	$2A(a3),d0
	beq.w	.y3
	muls.w	d4,d0
	add.l	d0,$14(a3)
.y3	tst.w	$18(a3)
	bmi.w	.done
	bne.w	.z1
	tst.w	$2C(a3)			;Zvel
	beq.w	.done
.z1	asl.w	#1,d4			;*32	gravity
	sub.w	d4,$2C(a3)
	asl.w	#1,d4			;*64
	sub.w	d4,$2C(a3)
	lsr.w	#2,d4
	move.w	$2C(a3),d0
	muls.w	d4,d0
	add.l	d0,$18(a3)
	bpl.w	.done
	clr.l	$18(a3)			;bounce off the ice
	neg.w	$2C(a3)
	asr.w	$2C(a3)			;92: lsr
	moveq	#5,d0
	sub.b	$2C(a3),d0
	bpl.w	.snd
	clr.w	d0
.snd	cmp.w	#3,d0		;IDA: loc_91C4
	bhi.w	.done
	addi.w	#$2C,d0			;bounce sound $2C-$2F by speed (92 SFXpuckice once)
	move.w	d0,-(sp)
	bsr.w	sfx
.done	move.w	$52(a3),d6		;IDA: loc_91D6. SCnum
	cmp.w	(puckc).w,d6
	bne.w	.tp			;not puck carrier
	btst	#0,$63(a3)		;pf2fight
	bne.w	.tp
	btst	#7,(sflags).w		;sfhor
	bne.w	.tp
	moveq	#-2,d4			;pad index for puck carrier
	bsr.w	setpads
.tp	cmp.w	(c1playernum).w,d6	;IDA: loc_91FC
	bne.w	.t0
	bsr.w	Readjoy1
	clr.w	d4			;pad index for cont 1 player
	bsr.w	doinput
	bra.w	.t1
.t0	cmp.w	(c2playernum).w,d6	;IDA: loc_9212
	bne.w	.t1
	bsr.w	Readjoy2
	moveq	#2,d4			;pad index for cont 2 player
	bsr.w	doinput
.t1	move.w	$36(a3),d0		;IDA: loc_9224. assnum (93 has no pfalock test here)
	clr.w	d1
	move.b	$38(a3,d0.w),d1		;asslist
	asl.w	#2,d1
	movea.l	#asstab,a0
	movea.l	(a0,d1.w),a0
	bsr.w	loadTeamStruct
	jsr	(a0)			;call assignment for this player
	clr.w	$4E(a3)
	clr.w	$50(a3)
	move.w	(a3),d2
	move.w	$14(a3),d3
	cmp.w	$1C(a3),d2
	bne.w	.cc
	cmp.w	$20(a3),d3
	beq.w	.nf
.cc	bsr.w	checkcoll		;IDA: loc_925E. Check for coll if moved by at least 1 pix
.nf	move.w	d7,d0			;IDA: loc_9262
	asl.w	#1,d0
	sub.w	d0,$32(a3)		;reduce impact at constant rate
	bpl.w	.nf1
	clr.w	$32(a3)
.nf1	move.w	$32(a3),$30(a3)		;IDA: loc_9272. limpact = impact
	adda.w	#$80,a3
	cmpi.w	#$F,-$2E(a3)		;SCnum of the struct just done
	blt.w	.top			;loop for all Sort objects
	rts

updateanim	;frame switch control on struct a3. Also called from
	;UpdateTeamNameAnimation
	tst.w	$58(a3)			;SPA
	bne.w	.ia
	bclr	#5,$62(a3)		;pfalock
	bclr	#1,$63(a3)		;pf2aip
	rts
.ia	movea.l	#SPAList,a0		;IDA: loc_929E. Animation data tables (frames)
	adda.w	$58(a3),a0
	move.w	$10(a0),d1		;attributes for anim
	move.w	$54(a3),d0		;facedir
	btst	#7,(sflags).w		;sfhor
	beq.w	.nhor
	cmpi.w	#$C,$52(a3)
	bge.w	.nhor
	subq.w	#2,d0			;direction adj for horizontal rink
	andi.w	#7,d0
.nhor	btst	#3,4(a3)		;IDA: loc_92CA. X flip flag
	beq.w	.nox
	neg.w	d0
	addq.w	#8,d0
	andi.w	#7,d0
.nox	asl.w	#1,d0			;IDA: loc_92DC
	adda.w	(a0,d0.w),a0
	move.w	$5A(a3),d0		;SPAnum
	move.w	(a0,d0.w),d2		;new frame
	tst.w	$5C(a3)			;SPAcnt
	bmi.w	.1
	sub.w	d7,$5C(a3)
	bpl.w	.cframe
	addq.w	#4,$5A(a3)
	addq.w	#4,d0
	tst.w	-2(a0,d0.w)
	bpl.w	.1
	clr.w	d0
	clr.w	$5A(a3)
	bclr	#5,$62(a3)
	bclr	#1,$63(a3)
	btst	#0,d1
	bne.w	.1			;looper
	clr.w	$58(a3)
.1	move.w	2(a0,d0.w),d0		;IDA: loc_9326
	bpl.w	.0
	neg.w	d0
.0	move.w	d0,$5C(a3)		;IDA: loc_9330
.cframe	sub.b	d7,$65(a3)		;IDA: loc_9334. Limit minimum time between frame switches
	bpl.w	rtss
	clr.b	$65(a3)
	cmp.w	6(a3),d2
	beq.w	rtss
	move.w	d2,6(a3)
	move.b	#4,$65(a3)		;/60 sec min frame switch time
	rts

freezewindow	;lock scrolling to current position
	move.w	(Vpos).w,(yc1).w
	move.w	(Hpos).w,(xc1).w
	bset	#6,(sflags).w		;sfslock
	rts

checkwindow	;set hpos and vpos according to how screen should follow puck
	move.w	(yc1).w,d2
	move.w	(xc1).w,d3		;if locked, use these cordinates
	btst	#6,(sflags).w		;sfslock
	bne.w	.dd
	movea.w	#(puckx-M68K_RAM),a3
	move.w	(puckc).w,d0
	bmi.w	.ok
	asl.w	#7,d0			;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.w	d7,d0
	add.w	d0,d0
	btst	#7,$62(a3)		;pfgoal
	beq.w	.gd
	add.w	d0,(yleader).w
	cmpi.w	#$32,(yleader).w	;.ylmax = 50
	blt.w	.ok
	move.w	#$32,(yleader).w
	bra.w	.ok
.gd	sub.w	d0,(yleader).w		;IDA: loc_93B4
	cmpi.w	#$FFCE,(yleader).w	;-.ylmax
	bgt.w	.ok
	move.w	#$FFCE,(yleader).w
.ok	move.w	$2A(a3),d2		;IDA: loc_93C8. Yvel
	asr.w	#7,d2
	add.w	$14(a3),d2		;Ypos
	add.w	(yleader).w,d2
	move.w	(a3),d3			;Xpos
	move.w	d2,(yc1).w
	move.w	d3,(xc1).w
.dd	move.w	d2,d0			;IDA: loc_93E0
	sub.w	(Vpos).w,d0
	cmp.w	#-10,d0		;-.ylim
	bge.w	.1
	move.w	d2,d1
	subi.w	#$FFF6,d1		;-.ylim
	cmp.w	#-200,d1		;.yslimd
	bgt.w	.2
	move.w	#$FF38,d1
	bra.w	.2
.1	cmp.w	#10,d0		;IDA: loc_9404. .ylim
	ble.w	.2x
	move.w	d2,d1
	subi.w	#$A,d1
	cmp.w	#256,d1		;.yslimu
	blt.w	.2
	move.w	#$100,d1
.2	sub.w	(Vpos).w,d1		;IDA: loc_941E
	beq.w	.2x
	asr.w	#4,d1
	bne.w	.v2
	addq.w	#1,d1
.v2	add.w	d1,(Vpos).w		;IDA: loc_942E
.2x	move.w	d3,d0			;IDA: loc_9432
	sub.w	(Hpos).w,d0
	cmp.w	#-40,d0		;-.xlim
	bge.w	.3
	move.w	d3,d1
	subi.w	#$FFD8,d1
	cmp.w	#-60,d1		;-.xslim
	bge.w	.4
	move.w	#$FFC4,d1
	bra.w	.4
.3	cmp.w	#40,d0		;IDA: loc_9456. .xlim
	ble.w	rtss
	move.w	d3,d1
	subi.w	#$28,d1
	cmp.w	#60,d1		;.xslim
	ble.w	.4
	move.w	#$3C,d1
.4	sub.w	(Hpos).w,d1		;IDA: loc_9470
	beq.w	rtss
	asr.w	#4,d1
	bne.w	.h2
	addq.w	#1,d1
.h2	add.w	d1,(Hpos).w		;IDA: loc_9480
	rts
