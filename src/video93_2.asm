;	NHLPA Hockey 93 (retail) segment $11D0A-$122A7
;	92 Video.asm second half: showclock, checksso, setsortcords, setffo,
;	uppads, addframe, addframe2, find3d, updatesound and KillCrowd, plus the
;	93-only pad label code (FormatControllerDisplay, RenderSmallFontChar).
;	VBlank ... showcrowd is video93_1. 92 sizetab is in hockey93_11 here.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	92 bit names used in comments, same values in 93: disflags 3 dfclock;
;	sflags 7 sfhor; ubut 0, dbut 1, lbut 2, rbut 3. 92 osflag = 20000 ($4E20).
;	Object offsets, same as 92: Xpos 0, attribute 4, frame 6, oldframe 8,
;	VRoffs $A, VRchar $12, Ypos $14, Zpos $18. 92 ffosize = $1C, ssosize = $14,
;	scsize = 7 (128 byte SortCords entries).
;	DMA list entries (a5): long source, word length in words, word vram.

showclock	;put the game clock in the dma list. Called from setvideo; returns unless dfclock is set.
	;a5 = dma list, a6 = sprite table, d6 = link counter
	bclr	#dfclock,(disflags).w
	beq.w	rtss
	cmpi.w	#4,(gsp).w		;93: no clock update when gsp = 4
	beq.w	rtss
	movea.w	#(xc1-M68K_RAM),a0	;end of the 5 word clock buffer (92 clockram+(5*2)); written backward
	movea.l	#smallfontmap,a1
	adda.l	4(a1),a1

	move.w	$78(a1),d0		;4+(':'*2)
	add.w	(smallfontchars).w,d0
	ori.w	#$8000,d0
	move.w	d0,(clockram).w		;colon (92 clockram+(2*2))

	move.w	(gameclock).w,d0
	ext.l	d0
	divu.w	#$A,d0
	bsr.w	.char			;seconds ones
	divu.w	#6,d0
	bsr.w	.char			;seconds tens
	subq.w	#2,a0			;skip the colon
	divu.w	#$A,d0
	bsr.w	.char			;minutes ones
	swap	d0
	tst.l	d0
	bne.w	.0
	moveq	#-$10,d0		;' '-'0': blank leading zero
	swap	d0
.0	bsr.w	.char			;IDA: _0. minutes tens
	move.l	a0,(a5)+
	move.w	#5,(a5)+		;words to transfer

	movea.w	#(VmMap1-M68K_RAM),a1
	moveq	#$18,d0			;.clocky = 24
	moveq	#3,d2			;.clockx = 3
	btst	#sfhor,(sflags).w
	beq.w	.cv
	movea.w	#(VmMap2-M68K_RAM),a1
	moveq	#4,d0			;.clocky2 = 4
	moveq	#$D,d2			;.clockx2 = 13
.cv	move.w	2(a1),d1		;IDA: _cv. map width shift
	asl.w	d1,d0
	add.w	d2,d0
	asl.w	#1,d0
	add.w	(a1),d0
	move.w	d0,(a5)+		;vram destination
	rts

.char	swap	d0			;IDA: showclock_char. d0 high word = digit, write its tile to -(a0)
	asl.w	#1,d0
	move.w	$64(a1,d0.w),d0		;4+('0'*2)
	add.w	(smallfontchars).w,d0
	ori.w	#$8000,d0
	move.w	d0,-(a0)
	swap	d0
	ext.l	d0
	rts

checksso	;do graphics for sso structure: arrows for the two players when they are off screen.
	;Called from setvideo. a5 = dma list, a6 = sprite table, d6 = link counter.
	;93 returns in sfhor mode (92 drew the scoreboard sso objects there); falls into .ca for player 2
	btst	#sfhor,(sflags).w
	bne.w	rtss
	movea.w	#(pads+ffosize-M68K_RAM),a0	;92 pads+ffosize
	movea.w	#(sso-M68K_RAM),a3
	move.w	#$180,d3		;SPFarrow (92 $17A; 93 frames are 6 higher)
	bsr.w	.ca
	adda.w	#$1C,a0			;ffosize
	adda.w	#$14,a3			;ssosize
	move.w	#$183,d3		;SPFarrow+3

.ca	tst.w	Zpos(a0)			;IDA: checksso_ca. a0 = object, a3 = sso, d3 = first arrow frame
	bmi.w	rtss			;not on the ice
	st	frame(a3)
	move.w	(a0),d0			;Xpos
	move.w	Ypos(a0),d1
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	exg	d0,d1
	neg.w	d0
	subi.w	#$C5,d1			;horoff
	bra.w	.hord
.nhor	sub.w	(Hpos).w,d0		;IDA: _nhor
	sub.w	(Vpos).w,d1

.hord	clr.w	d2			;IDA: _hord. d2 = off screen directions as joystick bits
	cmp.w	#$74,d0			;.xoff = 116
	blt.w	.0
	bset	#3,d2			;rbut
.0	cmp.w	#-$74,d0		;IDA: _0. -.xoff
	bgt.w	.1
	bset	#2,d2			;lbut
.1	cmp.w	#$64,d1			;IDA: _1. .yoff = 100
	blt.w	.2
	bset	#0,d2			;ubut
.2	cmp.w	#-$64,d1		;IDA: _2. -.yoff
	bgt.w	.3
	bset	#1,d2			;dbut
.3	tst.w	d2			;IDA: _3
	beq.w	rtss			;on screen: no arrow
	movea.l	#jdtab,a1		;Rev A operand $DA88
	move.b	(a1,d2.w),d2		;direction 0-7
	asl.w	#3,d2
	movea.l	#.tab,a1

	move.w	(a1,d2.w),d4		;x spot, 0 = keep player x
	beq.w	.4
	move.w	d4,d0
.4	addi.w	#$100,d0		;IDA: _4. 128+128
	move.w	d0,(a3)			;Xcord

	move.w	2(a1,d2.w),d4		;y spot, 0 = keep player y
	beq.w	.5
	move.w	d4,d1
.5	neg.w	d1			;IDA: _5
	addi.w	#$F0,d1			;112+128
	move.w	d1,2(a3)		;Ycord

	add.w	4(a1,d2.w),d3
	move.w	d3,frame(a3)
	move.w	6(a1,d2.w),attribute(a3)	;flip bits
	bra.w	addframe2

.tab	dc.w	0,$64,0,$0000		;IDA: _tab. x spot, y spot, frame add, attribute per direction
	dc.w	$74,$64,1,$0000		;.xspot = 116, .yspot = 100
	dc.w	$74,0,2,$0000
	dc.w	$74,-$64,1,$1000
	dc.w	0,-$64,0,$1000
	dc.w	-$74,-$64,1,$1800
	dc.w	-$74,0,2,$0800
	dc.w	-$74,$64,1,$0800

setsortcords	;setup sort cord graphics: addframe for the 16 objects in OOlist order.
	;Called from setvideo. a5 = dma list, a6 = sprite table, d6 = link counter
	movea.w	#(OOlist-M68K_RAM),a4
	move.w	#$F,d0			;sortobjs-1
.top	clr.w	d1			;IDA: loc_11EEA
	move.b	(a4)+,d1
	asl.w	#6,d1			;scsize-1
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	bsr.w	addframe
	dbf	d0,.top
	rts

setffo	;draw the 5 objects tied to icerink scrolling (pads ...). Called from setvideo.
	;93: when an object made sprites, 2(a3) is added to the x of its first two sprites
	bsr.w	uppads
	move.w	#4,d0			;ffonum-1
	movea.w	#(pads-M68K_RAM),a3	;92 ffo
.top	movea.w	a6,a0			;IDA: loc_11F0C. a0 = first sprite this object writes
	bsr.w	addframe
	cmpa.w	a6,a0
	beq.w	.next			;no sprites added
	move.w	2(a3),d1		;x offset (set by FormatControllerDisplay)
	add.w	d1,6(a0)		;sprite 1 x
	add.w	d1,$E(a0)		;sprite 2 x
.next	adda.w	#$1C,a3			;IDA: loc_11F24. ffosize
	dbf	d0,.top
	rts

uppads	;update the gloves object and the 4 pad objects, and queue new pad labels.
	;Called from setffo. a5 = dma list. 93 reads one PadControlBits nibble per pad (92 used padcont bits)
	movea.w	#(glovestruct-M68K_RAM),a0	;pads+(4*ffosize) (92 ffo+(4*ffosize)): gloves
	st	Zpos(a0)			;hidden
	move.b	(glovecords).w,d0
	beq.w	.nogloves
	move.b	(glovecords+1).w,d1
	ext.w	d0
	asl.w	#2,d0
	move.w	d0,(a0)			;Xpos
	ext.w	d1
	asl.w	#2,d1
	move.w	d1,Ypos(a0)
	clr.w	Zpos(a0)			;shown
.nogloves	moveq	#3,d4		;IDA: loc_11F54. 4 pads (92 3)
	movea.w	#(pads-M68K_RAM),a0
	movea.w	#(padcont-M68K_RAM),a1	;last label code per pad
	movea.w	#(SortCords-M68K_RAM),a2
	move.w	(PadControlBits).w,d3
.top	move.w	d3,d0			;IDA: loc_11F66
	andi.w	#$F,d0			;this pad's nibble: player number, $E or $F
	move.w	#$F,d1			;label code for $E
	cmp.w	#$E,d0
	beq.w	.chg			;$E: leave the pad position alone
	st	Zpos(a0)			;hidden
	cmp.w	#$F,d0
	beq.w	.next			;$F: pad hidden, label unchanged
	asl.w	#7,d0			;scsize
	move.w	(a2,d0.w),(a0)		;Xpos of that player
	move.w	Ypos(a2,d0.w),Ypos(a0)
	clr.w	Zpos(a0)			;shown
	move.b	position+1(a2,d0.w),d1	;label code = position << 8 | rostnum
	asl.w	#8,d1
	move.b	rostnum(a2,d0.w),d1
.chg	cmp.w	(a1),d1			;IDA: loc_11F9E
	beq.w	.next			;same label as last time
	move.w	d1,(a1)
	bsr.w	FormatControllerDisplay
.next	lsr.w	#4,d3			;IDA: loc_11FAA. next nibble
	adda.w	#$1C,a0			;ffosize
	addq.w	#2,a1
	dbf	d4,.top
	rts

FormatControllerDisplay	;93 only: queue the 3 character label of a pad object (92 uppads .pd did 2 digits).
	;Called from uppads. d1 = label code: bits 7-4 and 3-0 are digits ($F = blank), bits 10-8 index
	;ButtonLabelCharTable. a0 = pad object, a5 = dma list. Falls into RenderSmallFontChar for the last char
	lea	ButtonLabelCharTable(pc),a4
	clr.w	2(a0)			;x offset (setffo adds it to the sprites)
	move.w	d1,d2
	lsr.w	#4,d2
	andi.w	#$F,d2
	bne.w	.hi
	move.w	#-$10,d2		;' '-'0': blank leading zero
	subq.w	#4,2(a0)		;and move the label 4 left
.hi	addi.w	#$30,d2			;IDA: loc_11FD4. '0'
	clr.w	d0			;char slot 0
	bsr.w	RenderSmallFontChar
	move.w	d1,d2
	andi.w	#$F,d2
	cmp.w	#$F,d2
	bne.w	.lo
	move.w	#-$10,d2		;$F: blank
.lo	addi.w	#$30,d2			;IDA: loc_11FF0. '0'
	moveq	#1,d0			;char slot 1
	bsr.w	RenderSmallFontChar
	move.w	d1,d2
	lsr.w	#8,d2
	andi.w	#7,d2
	bne.w	.btn
	addq.w	#4,2(a0)		;index 0 (' '): move the label 4 right
.btn	move.b	(a4,d2.w),d2		;IDA: loc_1200A
	moveq	#2,d0			;char slot 2

RenderSmallFontChar	;93 only, the 92 uppads .pd job: dma one small font tile to the object's chars.
	;d2 = ascii char, d0 = char slot, a0 = object (VRchar), a5 = dma list
	movea.l	#smallfontmap,a3
	adda.l	4(a3),a3
	add.w	d2,d2
	move.w	4(a3,d2.w),d2		;map entry for the char
	andi.w	#$7FF,d2
	asl.w	#5,d2			;32 bytes per tile
	movea.l	#smallfontmap,a3
	lea	$A(a3,d2.w),a3		;tile data
	move.l	a3,(a5)+
	move.w	#$10,(a5)+		;words to transfer
	add.w	VRchar(a0),d0
	asl.w	#5,d0
	move.w	d0,(a5)+		;vram destination
	rts

ButtonLabelCharTable	;third label character by bits 10-8 of the label code
	IF REV=0
	dc.b	' DDLCRX',$10		;retail pad $10 (Rev A: 0)
	ELSE
	dc.b	' DDLCRX',0
	ENDIF

addframe	;a3 = cords.l frame/oldframe VRsize VRchar. Project the object with find3d, then addframe2.
	;Called from setsortcords and setffo. a5 = dma trans, a6/d6 = sprite att
	movem.l	d0-d2,-(sp)
	move.w	(a3),d0			;Xpos
	move.w	Ypos(a3),d1
	move.w	Zpos(a3),d2
	bmi.w	.exit			;hidden
	bsr.w	find3d
	cmp.w	#$4E20,d1		;osflag
	beq.w	.exit
	bsr.w	addframe2
.exit	movem.l	(sp)+,d0-d2		;IDA: loc_1206A
	rts

addframe2	;d0/d1 = x/y coordinates on screen, a3 = object. a5 = dma list, a6 = sprite table, d6 = link counter.
	;Also entered from checksso .ca and setupice. 93 frame word: top 5 bits are attribute bits, low 11 the frame;
	;frames come from SpritesMap (offset table at +4) instead of 92 framelist. attribute is restored on exit
	move.w	attribute(a3),-(sp)		;save attribute
	movem.l	d0-d5/a0-a2,-(sp)
	move.w	frame(a3),d4
	bmi.w	.exit
	beq.w	.exit
	andi.w	#$F800,d4		;frame's attribute bits
	eor.w	d4,attribute(a3)		;flip them into attribute for this draw
	move.w	frame(a3),d4
	andi.w	#$7FF,d4
	movea.l	#Sprites,a2
	adda.l	4(a2),a2		;frame offset table
	asl.w	#1,d4
	cmp.w	2(a2),d4		;first offset = table size
	bge.w	.exit			;frame past the table
	move.w	2(a2,d4.w),d5
	sub.w	(a2,d4.w),d5
	lsr.w	#3,d5
	subq.w	#1,d5			;number of sprites in frame-1 (92 SprStrnum)
	adda.w	(a2,d4.w),a2		;92 SprStrdat
	clr.w	d3
	clr.w	d4
.sloop	move.w	d0,-(sp)		;IDA: _sloop
	move.w	frame(a3),d0
	andi.w	#$7FF,d0
	cmp.w	oldframe(a3),d0
	beq.w	.noref			;same frame: tiles already in vram

	tst.w	d5
	bne.w	.nn
	move.w	d0,oldframe(a3)		;last sprite: oldframe = frame
.nn	movem.w	d0-d4,-(sp)		;IDA: _nn
	move.w	4(a2),d2		;tile pointer (93 keeps it whole)
	clr.w	d4
	move.b	7(a2),d4		;size byte
	movea.l	#sizetab,a0
	move.b	(a0,d4.w),d4		;chars used in this sprite
	cmp.w	8(sp),d4
	bgt.w	.nodup			;more data in prev sprite so no dup
	cmp.w	4(sp),d2
	blt.w	.nodup
	move.w	4(sp),d0
	add.w	8(sp),d0		;end of last data
	sub.w	d2,d0
	sub.w	d4,d0
	bmi.w	.nodup
	movem.w	(sp)+,d0-d1
	addq.w	#6,sp
	bra.w	.dup

.nodup	add.w	8(sp),d3		;IDA: _nodup
	movem.w	(sp)+,d0-d1
	addq.w	#6,sp

	movem.w	d0-d4,-(sp)
	add.w	VRchar(a3),d3
	ext.l	d2
	asl.l	#5,d2
	addi.l	#Spritetiles,d2		;92 move.l Spritetiles,a0 / add.l d2,a0
	asl.w	#4,d4
	asl.w	#5,d3
	move.l	d2,(a5)+
	move.w	d4,(a5)+		;words to transfer
	move.w	d3,(a5)+		;vram destination
	movem.w	(sp)+,d0-d4
.dup	move.b	d3,VRoffs(a3,d5.w)		;IDA: _dup
.noref	move.w	(sp)+,d0		;IDA: _noref
	movem.w	d0-d2,-(sp)		;write sprite att
	move.w	2(a2),d2		;y global (93 +2, 92 +0)
	btst	#4,attribute(a3)		;y flip
	beq.w	.noyflip
	move.b	7(a2),d2
	andi.w	#3,d2
	addq.w	#1,d2
	asl.w	#3,d2
	neg.w	d2
	sub.w	2(a2),d2
.noyflip	add.w	d2,d1		;IDA: _noyflip
	move.w	d1,(a6)

	move.w	(a2),d2			;x global (93 +0, 92 +6)
	btst	#3,attribute(a3)		;x flip
	beq.w	.noxflip
	move.b	7(a2),d2
	andi.w	#$C,d2
	addq.w	#4,d2
	asl.w	#1,d2
	neg.w	d2
	sub.w	(a2),d2
.noxflip	add.w	d2,d0		;IDA: _noxflip
	move.w	d0,6(a6)
	move.b	7(a2),2(a6)		;size
	move.b	d6,3(a6)		;link
	move.w	6(a2),d2
	move.w	attribute(a3),d0
	eor.w	d0,d2
	andi.w	#$F800,d2
	btst	#0,attribute+1(a3)
	beq.w	.nospec
	btst	#$E,d2
	beq.w	.nospec
	bset	#$D,d2			;team 2 color
.nospec	or.b	VRoffs(a3,d5.w),d2		;IDA: _nospec
	add.w	VRchar(a3),d2
	move.w	d2,4(a6)
	movem.w	(sp)+,d0-d2

	addq.w	#1,d6
	addq.w	#8,a6
	addq.w	#8,a2
	dbf	d5,.sloop
.exit	movem.l	(sp)+,d0-d5/a0-a2	;IDA: _exit
	move.w	(sp)+,attribute(a3)		;restore attribute
	rts

find3d	;input - d0=xfield,d1=yfield,d2=height off field
	;output - d0=xscreen,d1=yscreen (osflag $4E20 when off screen). Called from addframe
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	exg	d0,d1
	neg.w	d0
	subi.w	#$C5,d1			;horoff
	bra.w	.crange

.nhor	sub.w	(Hpos).w,d0		;IDA: loc_121FC
	sub.w	(Vpos).w,d1
.crange	cmp.w	#$90,d0			;IDA: loc_12204. 128+16
	bgt.w	.offscr
	cmp.w	#-$90,d0		;-(128+16)
	blt.w	.offscr
	addi.w	#$100,d0		;128+128
	add.w	d2,d1
	asr.w	#1,d2
	add.w	d2,d1			;y + 1.5 * height
	cmp.w	#$90,d1			;112+32
	bgt.w	.offscr
	cmp.w	#-$90,d1		;-(112+32)
	blt.w	.offscr
	neg.w	d1
	addi.w	#$F0,d1			;112+128
	rts
.offscr	move.w	#$4E20,d1		;IDA: loc_12236. osflag
	rts

updatesound	;move the crowd noise volume (psg noise channel) toward crowdlevel.
	;Called from periodicevents
	move.w	(crowdlevel).w,d0	;92 Crowdlevel
	asl.w	#3,d0
	addi.w	#$400,d0
	cmp.w	#$EFF,d0
	bls.w	.ip
	move.w	#$EFF,d0

.ip	moveq	#$28,d2			;IDA: loc_12252. max step 40
	sub.w	(asv).w,d0
	cmp.w	d2,d0
	bgt.w	.iasv
	neg.w	d2
	cmp.w	d2,d0
	bge.w	.non			;within 40: no change
.iasv	add.w	d2,(asv).w		;IDA: loc_12266
	bpl.w	.non
	clr.w	(asv).w
.non	move.b	#$C8,(VDP_PSG).l	;IDA: loc_12272. 92 asound
	move.b	#1,(VDP_PSG).l
	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0			;noise channel attenuation
	move.b	d0,(VDP_PSG).l
	rts

KillCrowd	;silence the crowd noise (psg). Called from Reset, SetupPauseScreen, ...
	move.b	#$E7,(VDP_PSG).l	;92 asound
	move.b	#$DF,(VDP_PSG).l
	move.b	#$C8,(VDP_PSG).l
	move.b	#1,(VDP_PSG).l
	move.b	#$FF,(VDP_PSG).l	;noise channel off
	rts
