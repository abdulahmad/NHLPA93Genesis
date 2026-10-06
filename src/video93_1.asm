;	NHLPA Hockey 93 (retail) segment $11802-$11D09
;	92 Video.asm first half: VBlank, vb2, DumpSprites, setvideo and the
;	sprite builders it calls (show_rink, showref, checkfo, showzam,
;	SetSframe, showcrowd). showclock ... KillCrowd is video93_2.
;	Global names from the IDA export, 92 names where the routine is the
;	same (see the SEGMENT_AGENT.md rename table). Bytes match
;	nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp; fixopcodes.js patches the encoding after
;	assembly.
;	92 bit names used in comments, same values in 93 unless noted:
;	disflags 0 dfok, 2 dfng, 3 dfclock; sflags 0 sfpz, 7 sfhor;
;	gmode 0 gmclock; sflags2 1 sf2refref. 92 MaxSprites = 64 ($40).
;	93 sprite frame data (FaceOffSprites, ZamSprites, CrowdSprites): long
;	at +4 is the offset to a word table of frame offsets; frame n sprites
;	run from word n to word n+1, 8 bytes each: x 0, y 2, char 4,
;	flags 6 (top 5 bits used), size byte 7. 92 used a long pointer list.
;	DMA list entries (a5): long source, word length in words, word vram.

VBlank	;IDA: VBlank_org. main vblank code for game play (vbint target, set by setupice).
	;Not VBjsr: that is the level 6 vector stub in hockey93_01
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph		;don't screw with vchip cause I'm using it
	bclr	#dfok,(disflags).w
	beq.w	.01
	bsr.w	DumpSprites
.01	bsr.w	cramfade		;IDA: _01
.nograph	;IDA: _nograph
	btst	#sfpz,(sflags).w
	bne.w	.c
	btst	#gmclock,(gmode).w		;game clock stopped!
	bne.w	.c
	tst.w	(gameclock).w
	beq.w	.c
	subi.w	#$AAA,(gameclock+2).w	;jiffy ($10000/24)
	bcc.w	.c
	bset	#dfclock,(disflags).w
	subq.w	#1,(gameclock).w
	cmpi.w	#$3D,(gameclock).w	;61
	bgt.w	.c
	cmpi.w	#$3C,(gameclock).w	;60
	blt.w	.c
	move.w	#2,-(sp)		;SFXbeep2 (92 = 2), played when gameclock reaches 60
	bsr.w	sfx
.c	addq.w	#1,(vcount).w		;IDA: _c. 92 Vcount
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6
	rte

vb2	;vblank used for palfades only no dmas (vbint target).
	;93 has no rte here: falls into IRQ7
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	bsr.w	cramfade
.nograph	;IDA: _nograph
	addq.w	#1,(vcount).w
	jsr	p_music_vblank
	movem.l	(sp)+,d0-d7/a0-a6

IRQ7	;rte only. vb2 falls in; the vector table ($60, $64, ...) points here.
	;Not 92 VBcount (that also counts Vcount)
	rte

;------------------------------------
DumpSprites	;transfer (by dma) scroll stuff, sprite table, vram data in dmalist.
	;Called from VBlank when dfok was set. Falls into DumpSprites2
	bsr.w	SetScroll2

DumpSprites2	;transfer sprite table, then the dma list. Falls into DoDMAList.
	;Also called from IDA ROM:00014404 (retail $143EC)
	movea.w	#(Satt-M68K_RAM),a0	;transfer sprite table
	move.w	(Sattsize).w,d0
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA

DoDMAList	;transfer data from dmalist (92 dodmalist). Also called from setupice
	movea.l	(DMAListend).w,a6
	cmpa.l	#DMAList,a6
	beq.w	rtss			;list empty
.0	move.w	-(a6),d1		;IDA: _0. vram address
	move.w	-(a6),d0		;words
	movea.l	-(a6),a0		;source
	bsr.w	DoDMA
	cmpa.l	#DMAList,a6
	bne.s	.0
	rts

SetScroll2	;IDA: DoScroller. write Hscroll / Vscroll to the vdp. Called from DumpSprites.
	;Same body as 92 SetScroll2; 93 dropped 92 DoScroller's tempmap column transfers
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
.p	btst	#dfok,(disflags).w		;IDA: _p. wait for vblank to take the last frame
	bne.s	.p
	movea.w	#(DMAList-M68K_RAM),a5	;dma transfer list
	bsr.w	show_rink		;93: after a5 is set (92 updatescroll came first)
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
.n	clr.b	-5(a6)			;IDA: _n. end sprite list (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0			;93: halved (92 stored the byte count)
	move.w	d0,(Sattsize).w
	move.l	a5,(DMAListend).w
	bset	#dfok,(disflags).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts

show_rink	;using hpos and vpos set scroll cords; queue rink map rows on the dma list (a5)
	;when vertical scrolling needs new rows. Called from setvideo. 93 version of 92
	;updatescroll: rows go straight from IceRinkMap to the dma list, no tempmap
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
.sd	move.w	d1,d0			;IDA: loc_119B2
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
.su	move.w	d1,d0			;IDA: loc_119E8
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
.1	asl.w	d2,d0			;IDA: loc_11A42
	moveq	#2,d1
	asl.w	d2,d1
	addq.w	#2,d0			;refx
	btst	#sfhor,(sflags).w
	beq.w	.2
	addi.w	#$B,d0
.2	asl.w	#1,d0			;IDA: loc_11A58
	add.w	(a1),d0
	moveq	#7,d2			;refheight-1
.0	move.l	a0,(a5)+		;IDA: loc_11A5E
	move.w	#7,(a5)+		;refwidth
	move.w	d0,(a5)+
	adda.w	#$E,a0			;refwidth*2
	add.w	d1,d0
	dbf	d2,.0
	rts

checkfo	;check for face off sprites. Called from setvideo. Falls into checkfo2
	btst	#sfpz,(sflags).w
	bne.w	rtss
	btst	#4,(disflags).w		;93 faceoff flag (92 tests sflags2 sf2faceoff)
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
.sloop	move.w	2(a2),d2		;IDA: _sloop
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
.noxflip	;IDA: _noxflip
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
.next	dbf	d0,.top			;IDA: _next
	rts

showzam	;zamboni. Called from setvideo.
	;a5 = dma list, a6 = sprite table, d6 = link counter.
	;93 draws frame 1, frame 2-4 picked by x, then frame 5 (home score not ahead) or a .ftab frame
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
	move.w	(hmtmstruct+tmscore).w,d4	;home score
	cmp.w	(awtmstruct+tmscore).w,d4	;away score
	bls.w	SetSframe		;home not ahead: frame 5
	move.w	d0,d2
	subi.w	#$DA,d2
	bpl.w	.pos
	clr.w	d2			;x below $DA: first entry
.pos	lsr.w	#2,d2			;IDA: loc_11B6C
	add.w	d2,d2
	cmp.w	#$1A,d2
	blt.w	.get
	move.l	#$18,d2			;clamp to the last entry
.get	movea.l	#.ftab,a1		;IDA: loc_11B7E
	move.w	(a1,d2.w),d2
	bra.w	SetSframe
.ftab	dc.w	5,6,7,8,7,8,7,8,7,8,7,6,5	;IDA: unk_11B8C. frame by (x-$DA)/4

SetSframe	;draw one sprite frame. Called from showzam and from code outside this segment.
	;a0 = framelist, d0/d1 = x/y cords, d2 = frame to setup (93 from 0, 92 from 1),
	;d3 = start char in vram. a6 = sprite table, d6 = link counter. 93 also saves a0
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
.loop	move.w	2(a0),(a6)		;IDA: write_sprite_piece. y
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
.ex	movem.l	(sp)+,d0-d5/a0		;IDA: exit_sprite_write
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
	move.l	#$100,d5		;(92 also moved a1 by 31 frames here; 93 does it in .sc)
.v	clr.w	d0			;IDA: _v
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

.pb	andi.w	#$F,d2			;IDA: showcrowd_pb. d2 = count, d3 = first frame
	cmp.w	#3,d2
	bls.w	.pb0
	moveq	#3,d2			;max 3
.pb0	bra.w	.nextpb			;IDA: _pb0
.pbt	move.w	d3,d0			;IDA: _pbt
	add.w	d2,d0
	bsr.w	.sc
.nextpb	dbf	d2,.pbt			;IDA: _nextpb
	rts

.sc	ext.w	d0			;IDA: showcrowd_sc. d0 = frame, 0 = none
	beq.w	rtss
	btst	#sfhor,(sflags).w
	beq.w	.chk
	addi.w	#$1F,d0			;horizontal frames are 31 later
.chk	cmp.w	#$40,d6			;IDA: loc_11C7E. MaxSprites
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
.loop	cmp.w	2(a0),d2		;IDA: _loop. skip sprites off screen
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
	add.w	(gamesetuptilesetindex).w,d5	;92 crowdvrcset
	move.w	d5,(a6)+
	move.w	(a0),d5
	addi.w	#$70,d5			;128-16
	sub.w	d0,d5
	move.w	d5,(a6)+
	addq.w	#1,d6
	cmp.w	#$40,d6			;MaxSprites
	beq.w	.ex
.next	addq.w	#8,a0			;IDA: _next
	dbf	d4,.loop
.ex	movem.l	(sp)+,d0-d5		;IDA: loc_11D1C
	rts
