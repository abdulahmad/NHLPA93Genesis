;	Game play vertical blank code. Every frame it builds the sprite list and sends it and other
;	graphics to video memory, and it draws the sprites for the rink, the referee, faceoffs, the
;	zamboni and the crowd.

;	Sprite frame data (FaceOffSprites, ZamSprites, CrowdSprites): the long at +4 is the
;	offset to a word table of frame offsets; frame n sprites run from word n to word n+1,
;	8 bytes each: x 0, y 2, char 4, flags 6 (top 5 bits used), size byte 7.
;	DMA list entries (a5): long source, word length in words, word vram.

VBlank	;main vblank code for game play (vbint target, set by setupice).
	;Not VBjsr: that is the level 6 vector stub
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph		;don't screw with vchip cause I'm using it
	bclr	#dfok,(disflags).w
	beq.w	.01
	bsr.w	DumpSprites
.01	bsr.w	cramfade
.nograph
	btst	#sfpz,(sflags).w
	bne.w	.c
	btst	#gmclock,(gmode).w		;game clock stopped!
	bne.w	.c
	tst.w	(gameclock).w
	beq.w	.c
	subi.w	#$AAA,(gameclock+2).w	;jiffy
	bcc.w	.c
	bset	#dfclock,(disflags).w
	subq.w	#1,(gameclock).w
	cmpi.w	#$3D,(gameclock).w	;61
	bgt.w	.c
	cmpi.w	#$3C,(gameclock).w	;60
	blt.w	.c
	move.w	#SFXbeep2,-(sp)		;SFXbeep2 (92 = 2), played when gameclock reaches 60
	bsr.w	sfx
.c	addq.w	#1,(vcount).w
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

vb2	;vblank used for palfades only no dmas (vbint target).
	;no rte here: falls into IRQ7
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	bsr.w	cramfade
.nograph
	addq.w	#1,(vcount).w
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6

IRQ7	;rte only. vb2 falls in; the vector table ($60, $64, ...) points here.
	;92 also counted Vcount here
	rte

;------------------------------------
DumpSprites	;transfer (by dma) scroll stuff, sprite table, vram data in dmalist.
	;Called from VBlank when dfok was set. Falls into DumpSprites2
	bsr.w	SetScroll2

DumpSprites2	;transfer sprite table, then the dma list. Falls into DoDMAList.
	;Also called from 00014404
	movea.w	#(Satt-M68K_RAM),a0	;transfer sprite table
	move.w	(Sattsize).w,d0
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA

DoDMAList	;transfer data from dmalist. Also called from setupice
	movea.l	(DMAListend).w,a6
	cmpa.l	#DMAList,a6
	beq.w	rtss			;list empty
.0	move.w	-(a6),d1		;vram address
	move.w	-(a6),d0		;words
	movea.l	-(a6),a0		;source
	bsr.w	DoDMA
	cmpa.l	#DMAList,a6
	bne.s	.0
	rts

SetScroll2	;write Hscroll / Vscroll to the vdp. Called from DumpSprites.
	;No tempmap column transfers (92 had them)
	move.w	(VSCRLPM).w,d0
	addq.w	#2,d0
	bsr.w	Vmaddr
	move.w	(Hscroll).w,(a0)
	move.l	#$40020010,4(a0)	;vsram write, address 2
	move.w	(Vscroll).w,(a0)
	rts

setvideo	;this is not vblank code but sets up ram for vblank transfers.
	;Called once per game frame (DoGameFrame, Pausemode, ...)
	movem.l	d0-d7/a0-a6,-(sp)
.p	btst	#dfok,(disflags).w		;wait for vblank to take the last frame
	bne.s	.p
	movea.w	#(DMAList-M68K_RAM),a5	;dma transfer list
	bsr.w	updatescroll		;after a5 is set
	movea.w	#(Satt-M68K_RAM),a6	;sprite attribute table area
	moveq	#1,d6			;link counter
	bsr.w	checkfo
	bsr.w	checksso
	bsr.w	setsortcords
	bsr.w	setffo
	bsr.w	showclock
	bsr.w	showzam
	bsr.w	showcrowd
	bsr.w	showref
	cmpa.w	#(Satt-M68K_RAM),a6
	bne.w	.n
	clr.l	(a6)+			;no sprites: one blank sprite
	clr.l	(a6)+
.n	clr.b	-5(a6)			;end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0			;halved (92 stored the byte count)
	move.w	d0,(Sattsize).w
	move.l	a5,(DMAListend).w
	bset	#dfok,(disflags).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts

updatescroll	;using hpos and vpos set scroll cords; queue rink map rows on the dma list (a5)
	;when vertical scrolling needs new rows. Called from setvideo. updatescroll:
	;rows go straight from IceRinkMap to the dma list, no tempmap
	btst	#sfhor,(sflags).w
	bne.w	rtss
	moveq	#-$40,d0		;-192+128
	sub.w	(Hpos).w,d0
	move.w	(Vpos).w,d1
	move.w	d0,(Hscroll).w
	move.w	d1,(Vscroll).w
	neg.w	(Vscroll).w
	move.w	(Oldrow).w,d4
	asr.w	#3,d1
	move.w	d1,(Oldrow).w
	moveq	#$1F,d3			;max lines to update
	cmp.w	d4,d1
	beq.w	rtss			;same row as last frame
	movea.l	#IceRinkMap,a0		;(move/adda leave the cmp flags)
	adda.l	4(a0),a0		;a0 = map header: (a0) = chars per row, data at 4(a0)
	blt.w	.su			;row went up
.sd	move.w	d1,d0
	neg.w	d0
	addi.w	#$1E,d0
	andi.w	#$1F,d0
	asl.w	#7,d0			;chars per row screen format
	add.w	(VmMap2).w,d0
	move.w	d0,6(a5)		;vram address
	move.w	#$1E,d0			;60-30
	sub.w	d1,d0
	move.w	(a0),4(a5)		;words = one map row
	mulu.w	(a0),d0
	add.w	d0,d0
	lea	4(a0,d0.w),a1
	move.l	a1,(a5)			;source = map row
	addq.w	#8,a5
	subq.w	#1,d1
	cmp.w	d4,d1
	dbeq	d3,.sd
	rts
.su	move.w	d1,d0
	neg.w	d0
	addi.w	#$1D,d0
	andi.w	#$1F,d0
	asl.w	#7,d0
	add.w	(VmMap2).w,d0
	move.w	d0,6(a5)
	move.w	#$3D,d0
	sub.w	d1,d0
	move.w	(a0),4(a5)
	mulu.w	(a0),d0
	add.w	d0,d0
	lea	4(a0,d0.w),a1
	move.l	a1,(a5)
	addq.w	#8,a5
	addq.w	#1,d1
	cmp.w	d4,d1
	dbeq	d3,.su
	rts

showref	;draw ref graphics. Called from setvideo.
	;a5 = dma list, a6 = sprite table, d6 = link counter
	bclr	#sf2refref,(sflags2).w
	beq.w	rtss
	movea.w	#(RefRamMap-M68K_RAM),a0
	movea.w	#(VmMap1-M68K_RAM),a1
	move.w	2(a1),d2
	moveq	#2,d0			;refy
	btst	#sfhor,(sflags).w
	beq.w	.1
	moveq	#$F,d0			;y pos in sb screen
.1	asl.w	d2,d0
	moveq	#2,d1
	asl.w	d2,d1
	addq.w	#2,d0			;refx
	btst	#sfhor,(sflags).w
	beq.w	.2
	addi.w	#$B,d0
.2	asl.w	#1,d0
	add.w	(a1),d0
	moveq	#7,d2			;refheight-1
.0	move.l	a0,(a5)+
	move.w	#7,(a5)+		;refwidth
	move.w	d0,(a5)+
	adda.w	#$E,a0			;refwidth*2
	add.w	d1,d0
	dbf	d2,.0
	rts

checkfo	;check for face off sprites. Called from setvideo. Falls into checkfo2
	btst	#sfpz,(sflags).w
	bne.w	rtss
	btst	#4,(disflags).w		;faceoff flag (92 tested an sflags2 bit)
	beq.w	rtss
	movea.w	#(fofdata2-M68K_RAM),a3
	moveq	#2,d0
checkfo2	;face off graphics. a3 = face off data (word frame, word flags),
	;d0 = count-1. a5 = dma list, a6 = sprite table, d6 = link counter
.top	move.w	(a3),d4
	bmi.w	.next
	beq.w	.next			;no frame
	movea.l	#FaceOffSprites,a2
	adda.l	4(a2),a2		;frame offset table
	add.w	d4,d4
	move.w	2(a2,d4.w),d5
	sub.w	(a2,d4.w),d5
	lsr.w	#3,d5
	subq.w	#1,d5			;number of sprites in frame
	adda.w	(a2,d4.w),a2
.sloop	move.w	2(a2),d2
	addi.w	#$80,d2
	add.w	(fodropy).w,d2
	move.w	d2,(a6)			;y global
	move.w	(a2),d2			;x global
	btst	#3,2(a3)		;x flip
	beq.w	.noxflip
	move.b	7(a2),d2
	andi.w	#$C,d2
	addq.w	#4,d2
	asl.w	#1,d2
	neg.w	d2
	sub.w	(a2),d2
.noxflip
	addi.w	#$80,d2
	add.w	(fodropx).w,d2
	move.w	d2,6(a6)
	move.b	7(a2),2(a6)
	move.b	d6,3(a6)
	move.w	6(a2),d2
	andi.w	#$F800,d2
	or.w	4(a2),d2
	move.w	2(a3),d1
	andi.w	#$F800,d1
	eor.w	d1,d2
	add.w	(faceoffvrcset).w,d2
	move.w	d2,4(a6)
	addq.w	#1,d6
	addq.w	#8,a6
	addq.w	#8,a2
	dbf	d5,.sloop
	addq.w	#4,a3
.next	dbf	d0,.top
	rts

showzam	;zamboni. Called from setvideo.
	;a5 = dma list, a6 = sprite table, d6 = link counter.
	;draws frame 1, frame 2-4 picked by x, then frame 5 (home score not ahead) or a .ftab frame
	move.w	(zamx).w,d0
	bmi.w	rtss			;no zamboni
	movea.l	#ZamSprites,a0
	lsr.w	#2,d0
	move.w	#$12A,d1		;y (92 128+200)
	moveq	#1,d2			;frame
	move.w	(ExtraChars).w,d3
	bsr.w	SetSframe
	move.w	d0,d2
	lsr.w	#1,d2
	ext.l	d2
	divu.w	#3,d2
	swap	d2
	addq.w	#2,d2			;frame 2 + (x/2 mod 3)
	bsr.w	SetSframe
	moveq	#5,d2
	move.w	(tmstruct+tmscore).w,d4	;home score
	cmp.w	(awtmstruct+tmscore).w,d4	;away score
	bls.w	SetSframe		;home not ahead: frame 5
	move.w	d0,d2
	subi.w	#$DA,d2
	bpl.w	.pos
	clr.w	d2			;x below $DA: first entry
.pos	lsr.w	#2,d2
	add.w	d2,d2
	cmp.w	#$1A,d2
	blt.w	.get
	move.l	#$18,d2			;clamp to the last entry
.get	movea.l	#.ftab,a1
	move.w	(a1,d2.w),d2
	bra.w	SetSframe
.ftab	dc.w	5,6,7,8,7,8,7,8,7,8,7,6,5	;frame by (x-$DA)/4

SetSframe	;draw one sprite frame. Called from showzam and from the screen code.
	;a0 = framelist, d0/d1 = x/y cords, d2 = frame to setup (from 0; 92 counted from 1),
	;d3 = start char in vram. a6 = sprite table, d6 = link counter. Also saves a0
	cmp.w	#$40,d6			;MaxSprites
	bge.w	rtss
	movem.l	d0-d5/a0,-(sp)
	adda.l	4(a0),a0		;frame offset table
	add.w	d2,d2
	move.w	2(a0,d2.w),d4
	sub.w	(a0,d2.w),d4
	lsr.w	#3,d4
	subq.w	#1,d4			;number of sprites in frame
	adda.w	(a0,d2.w),a0
.loop	move.w	2(a0),(a6)		;y
	add.w	d1,(a6)+
	move.b	7(a0),(a6)+		;size
	move.b	d6,(a6)+		;link
	move.w	6(a0),d2
	andi.w	#$F800,d2
	add.w	4(a0),d2
	add.w	d3,d2
	move.w	d2,(a6)+		;char + flags
	move.w	(a0),(a6)		;x
	add.w	d0,(a6)+
	addq.w	#1,d6
	cmp.w	#$40,d6			;MaxSprites
	beq.w	.ex
	addq.w	#8,a0
	dbf	d4,.loop
.ex	movem.l	(sp)+,d0-d5/a0
	rts

showcrowd	;draw crowd sprites: up to 3 frames per PBnum nibble, then the two crowdframe frames.
	;Called from setvideo. a5 = dma list, a6 = sprite table, d6 = link counter
	movea.l	#CrowdSprites,a1
	adda.l	4(a1),a1		;a1 = frame offset table
	move.w	(Hpos).w,d4
	move.w	(Vpos).w,d5
	btst	#sfhor,(sflags).w
	beq.w	.v
	moveq	#-$40,d4
	move.l	#$100,d5		;(92 also moved a1 by 31 frames here; here .sc does it)
.v	clr.w	d0
	move.b	(PBnum).w,d2		;low nibble
	moveq	#$1A,d3			;frames 26+
	bsr.w	.pb
	move.b	(PBnum).w,d2
	lsr.w	#4,d2			;high nibble
	moveq	#$1D,d3			;frames 29+
	bsr.w	.pb
	move.b	(crowdframe).w,d0
	bsr.w	.sc
	move.b	(crowdframe+1).w,d0
	bra.w	.sc

.pb	andi.w	#$F,d2			;d2 = count, d3 = first frame
	cmp.w	#3,d2
	bls.w	.pb0
	moveq	#3,d2			;max 3
.pb0	bra.w	.nextpb
.pbt	move.w	d3,d0
	add.w	d2,d0
	bsr.w	.sc
.nextpb	dbf	d2,.pbt
	rts

.sc	ext.w	d0			;d0 = frame, 0 = none
	beq.w	rtss
	btst	#sfhor,(sflags).w
	beq.w	.chk
	addi.w	#$1F,d0			;horizontal frames are 31 later
.chk	cmp.w	#$40,d6			;MaxSprites
	bge.w	rtss
	movem.l	d0-d5,-(sp)
	add.w	d0,d0
	movea.l	a1,a0
	move.w	2(a0,d0.w),d1
	sub.w	(a0,d0.w),d1
	lsr.w	#3,d1
	subq.w	#1,d1
	move.w	d1,-(sp)		;number of sprites in frame
	adda.w	(a0,d0.w),a0

	move.w	d4,d0			;x window d0-d1
	addi.w	#$C0,d0
	move.w	d0,d1
	subi.w	#$90,d0			;128+16
	addi.w	#$80,d1
	move.w	#$170,d2		;y window d2-d3
	sub.w	d5,d2
	move.w	d2,d3
	subi.w	#$80,d2			;112+16
	addi.w	#$70,d3			;112

	move.w	(sp)+,d4
.loop	cmp.w	2(a0),d2		;skip sprites off screen
	bgt.w	.next
	cmp.w	2(a0),d3
	blt.w	.next
	cmp.w	(a0),d0
	bgt.w	.next
	cmp.w	(a0),d1
	blt.w	.next
	move.w	2(a0),d5
	addi.w	#$70,d5			;128-16
	sub.w	d2,d5
	move.w	d5,(a6)+
	move.b	7(a0),(a6)+
	move.b	d6,(a6)+
	move.w	6(a0),d5
	andi.w	#$F800,d5
	add.w	4(a0),d5
	add.w	(animchars).w,d5
	move.w	d5,(a6)+
	move.w	(a0),d5
	addi.w	#$70,d5			;128-16
	sub.w	d0,d5
	move.w	d5,(a6)+
	addq.w	#1,d6
	cmp.w	#$40,d6			;MaxSprites
	beq.w	.ex
.next	addq.w	#8,a0
	dbf	d4,.loop
.ex	movem.l	(sp)+,d0-d5
	rts

;======================================================================
;======================================================================
;	showclock, checksso, setsortcords, setffo, uppads, addframe, addframe2,
;	find3d, updatesound and KillCrowd, plus the pad label code
;	(QueuePadLabel, RenderSmallFontChar).
;	Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	Bits: disflags 3 dfclock; sflags 7 sfhor; ubut 0, dbut 1, lbut 2, rbut 3.
;	Object offsets: Xpos 0, attribute 4, frame 6, oldframe 8, VRoffs $A,
;	VRchar $12, Ypos $14, Zpos $18. ssosize = $14, scsize = 7 (128 byte
;	SortCords entries).
;	DMA list entries (a5): long source, word length in words, word vram.

showclock	;put the game clock in the dma list. Called from setvideo; returns unless dfclock is set.
	;a5 = dma list, a6 = sprite table, d6 = link counter
	bclr	#dfclock,(disflags).w
	beq.w	rtss
	cmpi.w	#4,(gsp).w		;no clock update when gsp = 4
	beq.w	rtss
	movea.w	#(xc1-M68K_RAM),a0	;end of the 5 word clock buffer; written backward
	movea.l	#smallfontmap,a1
	adda.l	4(a1),a1

	move.w	$78(a1),d0		;4+(':'*2)
	add.w	(smallfontchars).w,d0
	ori.w	#$8000,d0
	move.w	d0,(clockram).w		;colon

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
.0	bsr.w	.char			;minutes tens
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
.cv	move.w	2(a1),d1		;map width shift
	asl.w	d1,d0
	add.w	d2,d0
	asl.w	#1,d0
	add.w	(a1),d0
	move.w	d0,(a5)+		;vram destination
	rts

.char	swap	d0			;d0 high word = digit, write its tile to -(a0)
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
	;returns in sfhor mode (92 drew the scoreboard sso objects there); falls into .ca for player 2
	btst	#sfhor,(sflags).w
	bne.w	rtss
	movea.w	#(pads+ffosize-M68K_RAM),a0	;+ffosize
	movea.w	#(sso-M68K_RAM),a3
	move.w	#$180,d3		;SPFarrow (frame numbers are 6 higher than 92)
	bsr.w	.ca
	adda.w	#$1C,a0			;ffosize
	adda.w	#$14,a3			;ssosize
	move.w	#$183,d3		;SPFarrow+3

.ca	tst.w	Zpos(a0)			;a0 = object, a3 = sso, d3 = first arrow frame
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
.nhor	sub.w	(Hpos).w,d0
	sub.w	(Vpos).w,d1

.hord	clr.w	d2			;d2 = off screen directions as joystick bits
	cmp.w	#$74,d0			;.xoff = 116
	blt.w	.0
	bset	#3,d2			;rbut
.0	cmp.w	#-$74,d0		;-.xoff
	bgt.w	.1
	bset	#2,d2			;lbut
.1	cmp.w	#$64,d1			;yoff = 100
	blt.w	.2
	bset	#0,d2			;ubut
.2	cmp.w	#-$64,d1		;-.yoff
	bgt.w	.3
	bset	#1,d2			;dbut
.3	tst.w	d2
	beq.w	rtss			;on screen: no arrow
	movea.l	#jdtab,a1		;Rev A operand $DA88
	move.b	(a1,d2.w),d2		;direction 0-7
	asl.w	#3,d2
	movea.l	#.tab,a1

	move.w	(a1,d2.w),d4		;x spot, 0 = keep player x
	beq.w	.4
	move.w	d4,d0
.4	addi.w	#$100,d0		;128+128
	move.w	d0,(a3)			;Xcord

	move.w	2(a1,d2.w),d4		;y spot, 0 = keep player y
	beq.w	.5
	move.w	d4,d1
.5	neg.w	d1
	addi.w	#$F0,d1			;112+128
	move.w	d1,2(a3)		;Ycord

	add.w	4(a1,d2.w),d3
	move.w	d3,frame(a3)
	move.w	6(a1,d2.w),attribute(a3)	;flip bits
	bra.w	addframe2

.tab	dc.w	0,$64,0,$0000		;x spot, y spot, frame add, attribute per direction
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
.top	clr.w	d1
	move.b	(a4)+,d1
	asl.w	#6,d1			;scsize-1
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	bsr.w	addframe
	dbf	d0,.top
	rts

setffo	;draw the 5 objects tied to icerink scrolling (pads ...). Called from setvideo.
	;when an object made sprites, 2(a3) is added to the x of its first two sprites
	bsr.w	uppads
	move.w	#4,d0			;ffonum-1
	movea.w	#(pads-M68K_RAM),a3
.top	movea.w	a6,a0			;a0 = first sprite this object writes
	bsr.w	addframe
	cmpa.w	a6,a0
	beq.w	.next			;no sprites added
	move.w	2(a3),d1		;x offset (set by QueuePadLabel)
	add.w	d1,6(a0)		;sprite 1 x
	add.w	d1,$E(a0)		;sprite 2 x
.next	adda.w	#$1C,a3			;ffosize
	dbf	d0,.top
	rts

uppads	;update the gloves object and the 4 pad objects, and queue new pad labels.
	;Called from setffo. a5 = dma list. Reads one PadControlBits nibble per pad
	movea.w	#(glovestruct-M68K_RAM),a0	;pads+(4*ffosize): gloves
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
.nogloves	moveq	#3,d4		;4 pads (92 3)
	movea.w	#(pads-M68K_RAM),a0
	movea.w	#(padcont-M68K_RAM),a1	;last label code per pad
	movea.w	#(SortCords-M68K_RAM),a2
	move.w	(PadControlBits).w,d3
.top	move.w	d3,d0
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
.chg	cmp.w	(a1),d1
	beq.w	.next			;same label as last time
	move.w	d1,(a1)
	bsr.w	QueuePadLabel
.next	lsr.w	#4,d3			;next nibble
	adda.w	#$1C,a0			;ffosize
	addq.w	#2,a1
	dbf	d4,.top
	rts

QueuePadLabel	;queue the 3 character label of a pad object (92 drew 2 digits).
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
.hi	addi.w	#$30,d2			;'0'
	clr.w	d0			;char slot 0
	bsr.w	RenderSmallFontChar
	move.w	d1,d2
	andi.w	#$F,d2
	cmp.w	#$F,d2
	bne.w	.lo
	move.w	#-$10,d2		;$F: blank
.lo	addi.w	#$30,d2			;'0'
	moveq	#1,d0			;char slot 1
	bsr.w	RenderSmallFontChar
	move.w	d1,d2
	lsr.w	#8,d2
	andi.w	#7,d2
	bne.w	.btn
	addq.w	#4,2(a0)		;index 0 (' '): move the label 4 right
.btn	move.b	(a4,d2.w),d2
	moveq	#2,d0			;char slot 2

RenderSmallFontChar	;dma one small font tile to the object's chars.
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
.exit	movem.l	(sp)+,d0-d2
	rts

addframe2	;d0/d1 = x/y coordinates on screen, a3 = object. a5 = dma list, a6 = sprite table, d6 = link counter.
	;Also entered from checksso .ca and setupice. frame word: top 5 bits are attribute bits, low 11 the frame
	;frames come from SpritesMap (offset table at +4) instead of a framelist. attribute is restored on exit
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
	subq.w	#1,d5			;number of sprites in frame-1
	adda.w	(a2,d4.w),a2
	clr.w	d3
	clr.w	d4
.sloop	move.w	d0,-(sp)
	move.w	frame(a3),d0
	andi.w	#$7FF,d0
	cmp.w	oldframe(a3),d0
	beq.w	.noref			;same frame: tiles already in vram

	tst.w	d5
	bne.w	.nn
	move.w	d0,oldframe(a3)		;last sprite: oldframe = frame
.nn	movem.w	d0-d4,-(sp)
	move.w	4(a2),d2		;tile pointer (kept whole)
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

.nodup	add.w	8(sp),d3
	movem.w	(sp)+,d0-d1
	addq.w	#6,sp

	movem.w	d0-d4,-(sp)
	add.w	VRchar(a3),d3
	ext.l	d2
	asl.l	#5,d2
	addi.l	#Spritetiles,d2		;tile address
	asl.w	#4,d4
	asl.w	#5,d3
	move.l	d2,(a5)+
	move.w	d4,(a5)+		;words to transfer
	move.w	d3,(a5)+		;vram destination
	movem.w	(sp)+,d0-d4
.dup	move.b	d3,VRoffs(a3,d5.w)
.noref	move.w	(sp)+,d0
	movem.w	d0-d2,-(sp)		;write sprite att
	move.w	2(a2),d2		;y global (+2; 92 used +0)
	btst	#4,attribute(a3)		;y flip
	beq.w	.noyflip
	move.b	7(a2),d2
	andi.w	#3,d2
	addq.w	#1,d2
	asl.w	#3,d2
	neg.w	d2
	sub.w	2(a2),d2
.noyflip	add.w	d2,d1
	move.w	d1,(a6)

	move.w	(a2),d2			;x global (+0; 92 used +6)
	btst	#3,attribute(a3)		;x flip
	beq.w	.noxflip
	move.b	7(a2),d2
	andi.w	#$C,d2
	addq.w	#4,d2
	asl.w	#1,d2
	neg.w	d2
	sub.w	(a2),d2
.noxflip	add.w	d2,d0
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
.nospec	or.b	VRoffs(a3,d5.w),d2
	add.w	VRchar(a3),d2
	move.w	d2,4(a6)
	movem.w	(sp)+,d0-d2

	addq.w	#1,d6
	addq.w	#8,a6
	addq.w	#8,a2
	dbf	d5,.sloop
.exit	movem.l	(sp)+,d0-d5/a0-a2
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

.nhor	sub.w	(Hpos).w,d0
	sub.w	(Vpos).w,d1
.crange	cmp.w	#$90,d0			;128+16
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
.offscr	move.w	#$4E20,d1		;osflag
	rts

updatesound	;move the crowd noise volume (psg noise channel) toward crowdlevel.
	;Called from periodicevents
	move.w	(crowdlevel).w,d0
	asl.w	#3,d0
	addi.w	#$400,d0
	cmp.w	#$EFF,d0
	bls.w	.ip
	move.w	#$EFF,d0

.ip	moveq	#$28,d2			;max step 40
	sub.w	(asv).w,d0
	cmp.w	d2,d0
	bgt.w	.iasv
	neg.w	d2
	cmp.w	d2,d0
	bge.w	.non			;within 40: no change
.iasv	add.w	d2,(asv).w
	bpl.w	.non
	clr.w	(asv).w
.non	move.b	#$C8,(VDP_PSG).l
	move.b	#1,(VDP_PSG).l
	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0			;noise channel attenuation
	move.b	d0,(VDP_PSG).l
	rts

KillCrowd	;silence the crowd noise (psg). Called from Reset, SetupPauseScreen, ...
	move.b	#$E7,(VDP_PSG).l
	move.b	#$DF,(VDP_PSG).l
	move.b	#$C8,(VDP_PSG).l
	move.b	#1,(VDP_PSG).l
	move.b	#$FF,(VDP_PSG).l	;noise channel off
	rts
