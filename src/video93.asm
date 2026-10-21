;	Game play vertical blank code. Every frame it builds the sprite list and sends it and other graphics to
;	video memory, and it draws the sprites for the rink, the referee, faceoffs, the zamboni and the crowd.
;
;	The interrupt handlers (VBlank, vb2, IRQ7) and the vdp transfers (DumpSprites, dodmalist, SetScroll2) come
;	first, then setvideo, which builds the sprite and dma lists and calls the drawing routines. The sprite
;	frame data and DMA list formats are described above DumpSprites.


VBlank								;main vblank code for game play (VBint target, set by setupice).
									;Not VBjsr: that is the level 6 vector stub
	movem.l	d0-d7/a0-a6,-(sp)		;save
	btst	#dfng,(disflags).w		;dfng: don't touch the vdp
	bne.w	.nograph				;don't screw with vchip cause I'm using it
	bclr	#dfok,(disflags).w		;sprites ready?
	beq.w	.01						;no
	bsr.w	DumpSprites				;send them
.01	bsr.w	cramfade				;palette fades run every vblank unless dfng
.nograph							;game clock part: runs even with dfng set
	btst	#sfpz,(sflags).w		;paused?
	bne.w	.c						;yes
	btst	#gmclock,(gmode).w		;game clock stopped!
	bne.w	.c
	tst.w	(gameclock).w			;time left?
	beq.w	.c						;no
	subi.w	#jiffy,(gameclock+2).w	;jiffy
	bcc.w	.c
	bset	#dfclock,(disflags).w	;redraw the clock
	subq.w	#1,(gameclock).w		;one second less
	cmpi.w	#$3D,(gameclock).w		;61
	bgt.w	.c
	cmpi.w	#$3C,(gameclock).w		;60
	blt.w	.c
	move.w	#SFXbeep2,-(sp)			;SFXbeep2 (92 = 2), played when gameclock reaches 60
	bsr.w	sfx						;play it
.c	addq.w	#1,(Vcount).w			;frame counter other code waits on
	jsr	p_music_vblank				;sound driver tick
	movem.l	(sp)+,d0-d7/a0-a6		;restore
	rte

vb2									;vblank used for palfades only no dmas (VBint target). no rte here: falls
									;into IRQ7
	movem.l	d0-d7/a0-a6,-(sp)		;save
	btst	#dfng,(disflags).w		;graphics off?
	bne.w	.nograph				;yes
	bsr.w	cramfade				;palette fade step
.nograph							;no sprite or dma work in this vblank
	addq.w	#1,(Vcount).w			;frame counter
	jsr	p_music_vblank				;sound driver tick
	movem.l	(sp)+,d0-d7/a0-a6		;restore

IRQ7								;rte only. vb2 falls in; the vector table ($60, $64, ...) points here.
									;92 also counted Vcount here
	rte								;return

;------------------------------------
;	Sprite frame data (FaceOffSprites, ZamSprites, CrowdSprites): the long at +4 is the offset to a word
;	table of frame offsets. Frame n's sprites run from word n to word n+1, 8 bytes each: x 0, y 2, char 4,
;	flags 6 (top 5 bits used), size byte 7.
;
;	DMA list entries (a5): long source, word length in words, word vram.

DumpSprites							;transfer (by dma) scroll stuff, sprite table, vram data in dmalist.
									;Called from VBlank when dfok was set. Falls into DumpSprites2
	bsr.w	SetScroll2				;set the scroll

DumpSprites2						;transfer sprite table, then the dma list. Falls into dodmalist.
									;Also called from 00014404
	movea.w	#(Satt-M68K_RAM),a0		;transfer sprite table
	move.w	(Sattsize).w,d0			;words
	move.w	(VSPRITES).w,d1			;vram sprite table
	bsr.w	DoDMA					;send it

dodmalist							;transfer data from dmalist. Also called from setupice
	movea.l	(DMAlistend).w,a6		;end of the DMA list
	cmpa.l	#DMAList,a6				;empty?
	beq.w	rtss					;list empty
.0	move.w	-(a6),d1				;vram address (list is read backwards from DMAlistend)
	move.w	-(a6),d0				;words
	movea.l	-(a6),a0				;source
	bsr.w	DoDMA					;send it
	cmpa.l	#DMAList,a6				;done?
	bne.s	.0						;no
	rts								;return

SetScroll2							;write Hscroll / Vscroll to the vdp. Called from DumpSprites.
									;No tempmap column transfers (92 had them)
	move.w	(VSCRLPM).w,d0			;scroll table
	addq.w	#2,d0					;plane B entry
	bsr.w	Vmaddr					;set the vram address
	move.w	(Hscroll).w,(a0)		;horizontal scroll
	move.l	#VSRAM_W+(2<<16),4(a0)	;vsram write, address 2
	move.w	(Vscroll).w,(a0)		;vertical scroll
	rts								;return

setvideo							;this is not vblank code but sets up ram for vblank transfers.
									;Called once per game frame (DoGameFrame, Pausemode, ...)
	movem.l	d0-d7/a0-a6,-(sp)		;save
.p	btst	#dfok,(disflags).w		;wait for vblank to take the last frame
	bne.s	.p						;(VBlank clears dfok after DumpSprites)
	movea.w	#(DMAList-M68K_RAM),a5	;dma transfer list
	bsr.w	updatescroll			;after a5 is set
	movea.w	#(Satt-M68K_RAM),a6		;sprite attribute table area
	moveq	#1,d6					;link counter
	bsr.w	checkfo					;faceoff sprites
	bsr.w	checksso				;screen objects
	bsr.w	setsortcords			;player sprites
	bsr.w	setffo					;scroll objects
	bsr.w	showclock				;clock
	bsr.w	showzam					;zamboni
	bsr.w	showcrowd				;crowd
	bsr.w	showref					;ref
	cmpa.w	#(Satt-M68K_RAM),a6		;no sprites: one blank sprite
	bne.w	.n						;no
	clr.l	(a6)+					;no sprites: one blank sprite
	clr.l	(a6)+
.n	clr.b	satLink-satLen(a6)		;end sprite list: link byte of the last sprite = 0 (92 3-8(a6))
	move.l	a6,d0
	subi.l	#Satt,d0				;bytes used
	lsr.w	#1,d0					;halved (92 stored the byte count)
	move.w	d0,(Sattsize).w
	move.l	a5,(DMAlistend).w		;end of the DMA list
	bset	#dfok,(disflags).w		;sprites ready
	movem.l	(sp)+,d0-d7/a0-a6		;restore
	rts								;return

updatescroll						;using hpos and vpos set scroll cords; queue rink map rows on the dma list
									;(a5) when vertical scrolling needs new rows. Called from setvideo.
									;updatescroll:
									;rows go straight from IceRinkMap to the dma list, no tempmap
	btst	#sfhor,(sflags).w
	bne.w	rtss					;yes
	moveq	#-$40,d0				;-192+128
	sub.w	(Hpos).w,d0
	move.w	(Vpos).w,d1
	move.w	d0,(Hscroll).w			;horizontal scroll
	move.w	d1,(Vscroll).w
	neg.w	(Vscroll).w
	move.w	(Oldrow).w,d4			;last row sent
	asr.w	#3,d1					;d1 = Vpos in 8 pixel rows
	move.w	d1,(Oldrow).w			;d4 = previous row
	moveq	#$1F,d3					;max lines to update
	cmp.w	d4,d1
	beq.w	rtss					;same row as last frame
	movea.l	#IceRinkMap,a0			;(move/adda leave the cmp flags)
	adda.l	jimdata(a0),a0			;a0 = map header: (a0) = chars per row, data at 4(a0)
	blt.w	.su						;row went up
.sd	move.w	d1,d0					;scrolling down: queue map rows, one per pass (d3 = max rows)
	neg.w	d0
	addi.w	#$1E,d0
	andi.w	#$1F,d0					;wrap at 32 rows
	asl.w	#7,d0					;chars per row screen format
	add.w	(VmMAP2).w,d0			;plus map 2 base
	move.w	d0,6(a5)				;vram address
	move.w	#$1E,d0					;60-30
	sub.w	d1,d0
	move.w	(a0),4(a5)				;words = one map row
	mulu.w	(a0),d0
	add.w	d0,d0
	lea	4(a0,d0.w),a1
	move.l	a1,(a5)					;source = map row
	addq.w	#8,a5					;next DMA entry
	subq.w	#1,d1					;next row
	cmp.w	d4,d1
	dbeq	d3,.sd
	rts								;return
.su	move.w	d1,d0					;scrolling up: same as .sd with rows going the other way
	neg.w	d0
	addi.w	#$1D,d0
	andi.w	#$1F,d0					;wrap at 32 rows
	asl.w	#7,d0					;chars per row screen format
	add.w	(VmMAP2).w,d0			;plus map 2 base
	move.w	d0,6(a5)				;vram destination
	move.w	#$3D,d0
	sub.w	d1,d0
	move.w	(a0),4(a5)				;words = one map row
	mulu.w	(a0),d0
	add.w	d0,d0
	lea	4(a0,d0.w),a1
	move.l	a1,(a5)					;source = map row
	addq.w	#8,a5					;next DMA entry
	addq.w	#1,d1					;next row
	cmp.w	d4,d1
	dbeq	d3,.su
	rts								;return

showref								;draw ref graphics. Called from setvideo.
									;a5 = dma list, a6 = sprite table, d6 = link counter
	bclr	#sf2refref,(sflags2).w
	beq.w	rtss					;no
	movea.w	#(RefRamMap-M68K_RAM),a0	;ref map buffer
	movea.w	#(VmMAP1-M68K_RAM),a1	;map 1 info
	move.w	2(a1),d2				;width shift
	moveq	#2,d0					;refy
	btst	#sfhor,(sflags).w		;horizontal?
	beq.w	.1						;no
	moveq	#$F,d0					;y pos in sb screen
.1	asl.w	d2,d0					;row * map row size
	moveq	#2,d1
	asl.w	d2,d1					;d1 = vram step of 2 map rows
	addq.w	#2,d0					;refx
	btst	#sfhor,(sflags).w
	beq.w	.2						;no
	addi.w	#$B,d0
.2	asl.w	#1,d0					;cells to bytes
	add.w	(a1),d0					;d0 = vram address of the ref block in map 1
	moveq	#7,d2					;refheight-1
.0	move.l	a0,(a5)+				;one dma entry per ref row (refwidth words from RefRamMap)
	move.w	#refwidth,(a5)+			;refwidth
	move.w	d0,(a5)+				;vram destination
	adda.w	#$E,a0					;refwidth*2
	add.w	d1,d0					;next row
	dbf	d2,.0
	rts								;return

checkfo								;check for face off sprites. Called from setvideo. Falls into checkfo2
	btst	#sfpz,(sflags).w		;paused?
	bne.w	rtss					;yes
	btst	#dffaceoff,(disflags).w	;faceoff flag (92 tested an sflags2 bit)
	beq.w	rtss					;no
	movea.w	#(fofdata2-M68K_RAM),a3	;faceoff objects
	moveq	#2,d0					;3 objects
checkfo2							;face off graphics. a3 = face off data (word frame, word flags), d0 =
									;count-1. a5 = dma list, a6 = sprite table, d6 = link counter
.top	move.w	(a3),d4				;frame of this faceoff object
	bmi.w	.next
	beq.w	.next					;no frame
	movea.l	#FaceOffSprites,a2		;faceoff sprite data
	adda.l	jimdata(a2),a2			;frame offset table
	add.w	d4,d4
	IF REV=2
	move.w	(a2,d4.w),d5
	sub.w	-2(a2,d4.w),d5
	lsr.w	#3,d5					;/ 8 bytes per sprite
	subq.w	#1,d5					;number of sprites in frame
	adda.w	-2(a2,d4.w),a2			;first sprite
	ELSE
	move.w	2(a2,d4.w),d5
	sub.w	(a2,d4.w),d5
	lsr.w	#3,d5					;/ 8 bytes per sprite
	subq.w	#1,d5					;number of sprites in frame
	adda.w	(a2,d4.w),a2			;first sprite
	ENDIF
.sloop	move.w	seY(a2),d2			;one sprite of the frame: y
	addi.w	#$80,d2					;sprite coordinates start at 128
	add.w	(fodropy).w,d2			;plus drop y
	move.w	d2,(a6)					;y global
	move.w	(a2),d2					;x global
	btst	#3,2(a3)				;x flip
	beq.w	.noxflip				;no
	move.b	seSize(a2),d2			;mirror: x = -(sprite width in pixels) - x
	andi.w	#$C,d2					;size byte bits 3-2 = width-1 in tiles (*4)
	addq.w	#4,d2
	asl.w	#1,d2					;width in pixels
	neg.w	d2
	sub.w	(a2),d2
.noxflip							;d2 = x offset (mirrored or not)
	addi.w	#$80,d2
	add.w	(fodropx).w,d2			;plus drop x
	move.w	d2,satX(a6)				;sprite x
	move.b	seSize(a2),satSize(a6)	;sprite size
	move.b	d6,satLink(a6)			;link
	move.w	seAttr(a2),d2			;attribute
	andi.w	#$F800,d2				;frame flags (attribute bits)
	or.w	seTile(a2),d2			;plus char
	move.w	foattr(a3),d1
	andi.w	#$F800,d1				;object flags xor'd in (flip bits)
	eor.w	d1,d2
	add.w	(faceoffvrcset).w,d2	;plus faceoff chars
	move.w	d2,satTile(a6)			;char + flags
	addq.w	#1,d6					;next link
	addq.w	#8,a6
	addq.w	#8,a2					;next sprite
	dbf	d5,.sloop					;loop
	addq.w	#4,a3					;next faceoff object
.next	dbf	d0,.top					;d0 = objects left
	rts								;return

showzam								;zamboni. Called from setvideo.
									;a5 = dma list, a6 = sprite table, d6 = link counter.
									;draws frame 1, frame 2-4 picked by x, then frame 5 (home score not ahead)
									;or a .ftab frame
	move.w	(Zamx).w,d0
	bmi.w	rtss					;no zamboni
	movea.l	#ZamSprites,a0			;zamboni sprite data
	lsr.w	#2,d0
	move.w	#$12A,d1				;y (92 128+200)
	moveq	#1,d2					;frame
	move.w	(ExtraChars).w,d3		;first char
	bsr.w	SetSframe				;add the sprite
	move.w	d0,d2
	lsr.w	#1,d2
	ext.l	d2
	divu.w	#3,d2
	swap	d2
	addq.w	#2,d2					;frame 2 + (x/2 mod 3)
	bsr.w	SetSframe				;add the sprite
	moveq	#5,d2
	move.w	(tmstruct+tmscore).w,d4	;home score
	cmp.w	(awtmstruct+tmscore).w,d4	;away score
	bls.w	SetSframe				;home not ahead: frame 5
	move.w	d0,d2
	subi.w	#$DA,d2
	bpl.w	.pos
	clr.w	d2						;x below $DA: first entry
.pos	lsr.w	#2,d2				;(x-$DA)/4
	add.w	d2,d2					;word index
	cmp.w	#$1A,d2
	blt.w	.get
	move.l	#$18,d2					;clamp to the last entry
.get	IF REV=2					;d2 = index into .ftab
	lea	(.ftab).l,a1				;d2 = table offset
	ELSE
	movea.l	#.ftab,a1				;d2 = table offset
	ENDIF
	move.w	(a1,d2.w),d2			;frame from the table
	bra.w	SetSframe				;add the sprite
.ftab	dc.w	5,6,7,8,7,8,7,8,7,8,7,6,5	;frame by (x-$DA)/4

SetSframe							;draw one sprite frame. Called from showzam and from the screen code.
									;a0 = framelist, d0/d1 = x/y cords, d2 = frame to setup (from 0; 92
									;counted from 1), d3 = start char in vram. a6 = sprite table, d6 = link
									;counter. Also saves a0
	cmp.w	#MaxSprites,d6			;MaxSprites
	bge.w	rtss					;yes
	movem.l	d0-d5/a0,-(sp)			;save
	adda.l	jimdata(a0),a0			;frame offset table
	add.w	d2,d2					;word index
	IF REV=2
	move.w	(a0,d2.w),d4
	sub.w	-2(a0,d2.w),d4
	lsr.w	#3,d4					;/ 8 bytes per sprite
	subq.w	#1,d4					;number of sprites in frame
	adda.w	-2(a0,d2.w),a0			;first sprite
	ELSE
	move.w	2(a0,d2.w),d4
	sub.w	(a0,d2.w),d4
	lsr.w	#3,d4					;/ 8 bytes per sprite
	subq.w	#1,d4					;number of sprites in frame
	adda.w	(a0,d2.w),a0			;first sprite
	ENDIF
.loop	move.w	seY(a0),(a6)		;per sprite: y (+ d1)
	add.w	d1,(a6)+
	move.b	seSize(a0),(a6)+		;size
	move.b	d6,(a6)+				;link
	move.w	seAttr(a0),d2			;attribute
	andi.w	#$F800,d2				;flip and palette bits
	add.w	seTile(a0),d2			;plus char
	add.w	d3,d2					;plus first char
	move.w	d2,(a6)+				;char + flags
	move.w	(a0),(a6)				;x
	add.w	d0,(a6)+				;plus x
	addq.w	#1,d6					;next link
	cmp.w	#MaxSprites,d6			;MaxSprites
	beq.w	.ex						;sprite table full
	addq.w	#8,a0					;next sprite
	dbf	d4,.loop					;loop
.ex	movem.l	(sp)+,d0-d5/a0			;restore registers
	rts								;return

showcrowd							;draw crowd sprites: up to 3 frames per PBnum nibble, then the two
									;Crowdframe frames.
									;Called from setvideo. a5 = dma list, a6 = sprite table, d6 = link counter
	movea.l	#CrowdSprites,a1		;crowd sprite data
	adda.l	jimdata(a1),a1			;a1 = frame offset table
	move.w	(Hpos).w,d4				;view x
	move.w	(Vpos).w,d5				;view y
	btst	#sfhor,(sflags).w		;horizontal?
	beq.w	.v						;no
	moveq	#-$40,d4
	move.l	#$100,d5				;(92 also moved a1 by 31 frames here; here .sc does it)
.v	clr.w	d0						;d4/d5 = x/y of the view
	move.b	(PBnum).w,d2			;low nibble
	moveq	#$1A,d3					;frames 26+
	bsr.w	.pb
	move.b	(PBnum).w,d2			;penalty box count
	lsr.w	#4,d2					;high nibble
	moveq	#$1D,d3					;frames 29+
	bsr.w	.pb
	move.b	(Crowdframe).w,d0
	bsr.w	.sc
	move.b	(Crowdframe+1).w,d0
	bra.w	.sc

.pb	andi.w	#$F,d2					;d2 = count, d3 = first frame
	cmp.w	#3,d2
	bls.w	.pb0
	moveq	#3,d2					;max 3
.pb0	bra.w	.nextpb				;next sprite
.pbt	move.w	d3,d0				;frame = first frame + counter
	add.w	d2,d0
	bsr.w	.sc						;add it
.nextpb	dbf	d2,.pbt					;frames d3+count .. d3+0
	rts								;return

.sc	ext.w	d0						;d0 = frame, 0 = none
	beq.w	rtss					;none
	btst	#sfhor,(sflags).w		;horizontal?
	beq.w	.chk					;no
	addi.w	#$1F,d0					;horizontal frames are 31 later
.chk	cmp.w	#MaxSprites,d6		;MaxSprites
	bge.w	rtss					;sprite table full
	movem.l	d0-d5,-(sp)				;save
	add.w	d0,d0					;word index
	movea.l	a1,a0					;frame offset table
	IF REV=2
	move.w	(a0,d0.w),d1
	sub.w	-2(a0,d0.w),d1
	lsr.w	#3,d1					;/ 8 bytes per sprite
	subq.w	#1,d1
	move.w	d1,-(sp)				;number of sprites in frame
	adda.w	-2(a0,d0.w),a0			;first sprite
	ELSE
	move.w	2(a0,d0.w),d1
	sub.w	(a0,d0.w),d1
	lsr.w	#3,d1					;/ 8 bytes per sprite
	subq.w	#1,d1
	move.w	d1,-(sp)				;number of sprites in frame
	adda.w	(a0,d0.w),a0			;first sprite
	ENDIF

	move.w	d4,d0					;x window d0-d1
	addi.w	#$C0,d0
	move.w	d0,d1
	subi.w	#$90,d0					;128+16
	addi.w	#$80,d1
	move.w	#$170,d2				;y window d2-d3
	sub.w	d5,d2
	move.w	d2,d3
	subi.w	#$80,d2					;112+16
	addi.w	#$70,d3					;112

	move.w	(sp)+,d4				;sprite count
.loop	cmp.w	seY(a0),d2			;per sprite: skip it if outside the window d0-d3
	bgt.w	.next
	cmp.w	seY(a0),d3
	blt.w	.next
	cmp.w	(a0),d0
	bgt.w	.next
	cmp.w	(a0),d1
	blt.w	.next
	move.w	seY(a0),d5
	addi.w	#$70,d5					;128-16
	sub.w	d2,d5
	move.w	d5,(a6)+				;y
	move.b	seSize(a0),(a6)+		;size
	move.b	d6,(a6)+				;link
	move.w	seAttr(a0),d5			;attribute
	andi.w	#$F800,d5				;flip and palette bits
	add.w	seTile(a0),d5			;plus char
	add.w	(crowdvrcset).w,d5		;crowd start char
	move.w	d5,(a6)+
	move.w	(a0),d5
	addi.w	#$70,d5					;128-16
	sub.w	d0,d5
	move.w	d5,(a6)+				;x
	addq.w	#1,d6					;next link
	cmp.w	#MaxSprites,d6			;MaxSprites
	beq.w	.ex						;full
.next	addq.w	#8,a0				;next sprite of the frame
	dbf	d4,.loop					;loop
.ex	movem.l	(sp)+,d0-d5				;done: restore the registers
	rts								;return

;======================================================================
;======================================================================
;	showclock, checksso, setsortcords, setffo, uppads, addframe, addframe2, find3d, updatesound and KillCrowd,
;	plus the pad label code (QueuePadLabel, RenderSmallFontChar).
;
;	ssosize = $14 (an sso object) and scsize = 7 (128 byte SortCords entries). DMA list entries (a5): long
;	source, word length in words, word vram.

showclock							;put the game clock in the dma list. Called from setvideo; returns unless
									;dfclock is set.
									;a5 = dma list, a6 = sprite table, d6 = link counter
	bclr	#dfclock,(disflags).w
	beq.w	rtss					;no
	cmpi.w	#4,(gsp).w				;no clock update when gsp = 4
	beq.w	rtss					;yes
	movea.w	#(xc1-M68K_RAM),a0		;end of the 5 word clock buffer; written backward
	movea.l	#smallfontmap,a1
	adda.l	jimdata(a1),a1

	move.w	4+(':'*2)(a1),d0		;map entry for ':'
	add.w	(smallfontchars).w,d0	;plus first char
	ori.w	#$8000,d0				;priority
	move.w	d0,(clockram).w			;colon

	move.w	(gameclock).w,d0
	ext.l	d0
	divu.w	#$A,d0
	bsr.w	.char					;seconds ones
	divu.w	#6,d0
	bsr.w	.char					;seconds tens
	subq.w	#2,a0					;skip the colon
	divu.w	#$A,d0
	bsr.w	.char					;minutes ones
	swap	d0
	tst.l	d0						;minutes tens is zero?
	bne.w	.0
	moveq	#-$10,d0				;' '-'0': blank leading zero
	swap	d0
.0	bsr.w	.char					;minutes tens
	move.l	a0,(a5)+				;source
	move.w	#5,(a5)+				;words to transfer

	movea.w	#(VmMAP1-M68K_RAM),a1	;map 1 info
	moveq	#$18,d0					;.clocky = 24
	moveq	#3,d2					;.clockx = 3
	btst	#sfhor,(sflags).w		;sfhor (always clear here: the horizontal rink prints the clock above)
	beq.w	.cv						;no
	movea.w	#(VmMAP2-M68K_RAM),a1	;map 2 info
	moveq	#4,d0					;.clocky2 = 4
	moveq	#$D,d2					;.clockx2 = 13
.cv	move.w	2(a1),d1				;map width shift (d0 = y, d2 = x of the clock)
	asl.w	d1,d0
	add.w	d2,d0
	asl.w	#1,d0
	add.w	(a1),d0					;plus map base
	move.w	d0,(a5)+				;vram destination
	rts								;return

.char	swap	d0					;d0 high word = digit, write its tile to -(a0)
	asl.w	#1,d0					;word index
	move.w	4+('0'*2)(a1,d0.w),d0	;map entry for the digit
	add.w	(smallfontchars).w,d0	;plus first char
	ori.w	#$8000,d0				;priority
	move.w	d0,-(a0)				;store it
	swap	d0
	ext.l	d0
	rts								;return

horoff	equ	197						;subtracted from the screen y in the horizontal rink view (sfhor)

checksso							;do graphics for sso structure: arrows for the two players when they are
									;off screen.
									;Called from setvideo. a5 = dma list, a6 = sprite table, d6 = link
									;counter.
									;returns in sfhor mode (92 drew the scoreboard sso objects there); falls
									;into .ca for player 2
	btst	#sfhor,(sflags).w
	bne.w	rtss					;yes
	movea.w	#(pads+ffosize-M68K_RAM),a0	;pad 2's pad object
	movea.w	#(sso-M68K_RAM),a3		;arrow objects
	move.w	#SPFarrow,d3			;frame numbers are 6 higher than 92
	bsr.w	.ca						;pad 1's arrow
	adda.w	#ffosize,a0				;ffosize
	adda.w	#$14,a3					;ssosize
	move.w	#SPFarrow+3,d3

.ca	tst.w	Zpos(a0)				;a0 = object, a3 = sso, d3 = first arrow frame
	bmi.w	rtss					;not on the ice
	st	frame(a3)					;frame = -1: no arrow unless set below
	move.w	(a0),d0					;Xpos
	move.w	Ypos(a0),d1
	btst	#sfhor,(sflags).w
	beq.w	.nhor					;no
	exg	d0,d1						;horizontal view: swap axes
	neg.w	d0
	subi.w	#horoff,d1
	bra.w	.hord
.nhor	sub.w	(Hpos).w,d0			;position relative to the scroll
	sub.w	(Vpos).w,d1

.hord	clr.w	d2					;d2 = off screen directions as joystick bits
	cmp.w	#$74,d0					;.xoff = 116
	blt.w	.0
	bset	#rbut,d2				;rbut
.0	cmp.w	#-$74,d0				;-.xoff
	bgt.w	.1
	bset	#lbut,d2				;lbut
.1	cmp.w	#$64,d1					;yoff = 100
	blt.w	.2
	bset	#ubut,d2				;ubut
.2	cmp.w	#-$64,d1				;-.yoff
	bgt.w	.3
	bset	#dbut,d2				;dbut
.3	tst.w	d2						;test: any direction off screen?
	beq.w	rtss					;on screen: no arrow
	movea.l	#jdtab,a1
	move.b	(a1,d2.w),d2			;direction 0-7
	asl.w	#3,d2
	movea.l	#.tab,a1				;arrow table

	move.w	(a1,d2.w),d4			;x spot, 0 = keep player x
	beq.w	.4
	move.w	d4,d0
.4	addi.w	#$100,d0				;128+128 (sprite coords)
	move.w	d0,(a3)					;Xcord

	move.w	2(a1,d2.w),d4			;y spot, 0 = keep player y
	beq.w	.5
	move.w	d4,d1
.5	neg.w	d1						;y up is negative on screen
	addi.w	#$F0,d1					;112+128
	move.w	d1,2(a3)				;Ycord

	add.w	4(a1,d2.w),d3			;frame
	move.w	d3,frame(a3)
	move.w	6(a1,d2.w),attribute(a3)	;flip bits
	bra.w	addframe2				;add the frame

.tab	dc.w	0,$64,0,$0000		;x spot, y spot, frame add, attribute per direction
	dc.w	$74,$64,1,$0000			;.xspot = 116, .yspot = 100
	dc.w	$74,0,2,$0000
	dc.w	$74,-$64,1,$1000
	dc.w	0,-$64,0,$1000
	dc.w	-$74,-$64,1,$1800
	dc.w	-$74,0,2,$0800
	dc.w	-$74,$64,1,$0800

setsortcords						;setup sort cord graphics: addframe for the 16 objects in OOlist order.
									;Called from setvideo. a5 = dma list, a6 = sprite table, d6 = link counter
	movea.w	#(OOlist-M68K_RAM),a4	;move OOlist into a4
	move.w	#$F,d0					;sortobjs-1
.top	clr.w	d1					;next object number from OOlist
	move.b	(a4)+,d1				;move next sortcord into d1
	asl.w	#scsize-1,d1			;scsize-1
	movea.w	#(SortCords-M68K_RAM),a3	;SortCords into a3
	adda.w	d1,a3					;add offset to next struct
	bsr.w	addframe				;add it
	dbf	d0,.top						;loop until done
	rts								;return

setffo								;draw the 5 objects tied to icerink scrolling (pads ...). Called from
									;setvideo.
									;when an object made sprites, 2(a3) is added to the x of its first two
									;sprites
	bsr.w	uppads					;update the pads
	move.w	#4,d0					;ffonum-1
	movea.w	#(pads-M68K_RAM),a3		;move start of struct into a3
.top	movea.w	a6,a0				;per object: a0 = first sprite this object writes
	bsr.w	addframe				;add it
	cmpa.w	a6,a0					;any sprites?
	beq.w	.next					;no sprites added
	move.w	2(a3),d1				;x offset (set by QueuePadLabel)
	add.w	d1,6(a0)				;sprite 1 x
	add.w	d1,8+6(a0)				;sprite 2 x
.next	adda.w	#ffosize,a3			;ffosize: next object
	dbf	d0,.top						;loop
	rts								;return

uppads								;update the gloves object and the 4 pad objects, and queue new pad labels.
									;Called from setffo. a5 = dma list. Reads one PadControlBits nibble per
									;pad
	movea.w	#(glovestruct-M68K_RAM),a0	;pads+(4*ffosize): gloves
	st	Zpos(a0)					;hidden
	move.b	(glovecords).w,d0
	beq.w	.nogloves				;none
	move.b	(glovecords+1).w,d1
	ext.w	d0
	asl.w	#2,d0
	move.w	d0,(a0)					;Xpos
	ext.w	d1
	asl.w	#2,d1
	move.w	d1,Ypos(a0)				;move d1 into Ypos
	clr.w	Zpos(a0)				;shown
.nogloves	moveq	#3,d4			;4 pads (92 3); d4 = pads left-1
	movea.w	#(pads-M68K_RAM),a0
	movea.w	#(padcont-M68K_RAM),a1	;last label code per pad
	movea.w	#(SortCords-M68K_RAM),a2	;objects
	move.w	(PadControlBits).w,d3	;pad owners
.top	move.w	d3,d0				;per pad: d3 holds the remaining nibbles
	andi.w	#$F,d0					;this pad's nibble: player number, $E or $F
	move.w	#$F,d1					;label code for $E
	cmp.w	#$E,d0
	beq.w	.chg					;$E: leave the pad position alone
	st	Zpos(a0)					;hidden
	cmp.w	#$F,d0
	beq.w	.next					;$F: pad hidden, label unchanged
	asl.w	#scsize,d0				;scsize
	move.w	(a2,d0.w),(a0)			;Xpos of that player
	move.w	Ypos(a2,d0.w),Ypos(a0)
	clr.w	Zpos(a0)				;shown
	move.b	position+1(a2,d0.w),d1	;label code = position << 8 | rostnum
	asl.w	#8,d1
	move.b	rostnum(a2,d0.w),d1		;jersey number
.chg	cmp.w	(a1),d1				;new label code vs the last one for this pad
	beq.w	.next					;same label as last time
	move.w	d1,(a1)
	bsr.w	QueuePadLabel			;queue the new label
.next	lsr.w	#4,d3				;next nibble (next pad)
	adda.w	#ffosize,a0				;ffosize
	addq.w	#2,a1					;next label
	dbf	d4,.top						;loop
	rts								;return

QueuePadLabel						;from 92 uppads. queue the 3 character label of a pad object (92 drew 2
									;digits).
									;Called from uppads. d1 = label code: bits 7-4 and 3-0 are digits ($F =
									;blank), bits 10-8 index ButtonLabelCharTable. a0 = pad object, a5 = dma
									;list. Falls into RenderSmallFontChar for the last char
	lea	ButtonLabelCharTable(pc),a4	;label chars
	clr.w	2(a0)					;x offset (setffo adds it to the sprites)
	move.w	d1,d2
	lsr.w	#4,d2
	andi.w	#$F,d2
	bne.w	.hi
	move.w	#-$10,d2				;' '-'0': blank leading zero
	subq.w	#4,2(a0)				;and move the label 4 left
.hi	addi.w	#$30,d2					;'0' (tens digit of the label, or blank)
	clr.w	d0						;char slot 0
	bsr.w	RenderSmallFontChar		;render it
	move.w	d1,d2
	andi.w	#$F,d2
	cmp.w	#$F,d2
	bne.w	.lo
	move.w	#-$10,d2				;$F: blank
.lo	addi.w	#$30,d2					;'0' (ones digit of the label, or blank)
	moveq	#1,d0					;char slot 1
	bsr.w	RenderSmallFontChar		;render it
	move.w	d1,d2
	lsr.w	#8,d2
	andi.w	#7,d2
	bne.w	.btn
	addq.w	#4,2(a0)				;index 0 (' '): move the label 4 right
.btn	move.b	(a4,d2.w),d2		;third char from ButtonLabelCharTable
	moveq	#2,d0					;char slot 2

RenderSmallFontChar					;from 92 uppads .pd. dma one small font tile to the object's chars.
									;d2 = ascii char, d0 = char slot, a0 = object (VRchar), a5 = dma list
	movea.l	#smallfontmap,a3		;small font
	adda.l	jimdata(a3),a3			;map data
	add.w	d2,d2					;word index
	move.w	4(a3,d2.w),d2			;map entry for the char
	andi.w	#$7FF,d2				;char number
	asl.w	#5,d2					;32 bytes per tile
	movea.l	#smallfontmap,a3		;small font
	lea	jimtiles(a3,d2.w),a3		;tile data
	move.l	a3,(a5)+				;source
	move.w	#$10,(a5)+				;words to transfer
	add.w	VRchar(a0),d0			;plus the object's char
	asl.w	#5,d0					;to bytes
	move.w	d0,(a5)+				;vram destination
	rts								;return

ButtonLabelCharTable				;third label character by bits 10-8 of the label code
	IF REV=0
	dc.b	' DDLCRX',$10			;Rev 0 pad $10 (Rev A: 0)
	ELSE
	dc.b	' DDLCRX',PadByte
	ENDIF

addframe							;a3 = cords.l frame/oldframe VRsize VRchar. Project the object with
									;find3d, then addframe2.
									;Called from setsortcords and setffo. a5 = dma trans, a6/d6 = sprite att
	movem.l	d0-d2,-(sp)				;save
	move.w	(a3),d0					;Xpos
	move.w	Ypos(a3),d1				;Ypos into d1
	move.w	Zpos(a3),d2				;Zpos into d2
	bmi.w	.exit					;hidden
	bsr.w	find3d					;get position on screen
	cmp.w	#osflag,d1				;osflag
	beq.w	.exit					;exit if Sort Cord is off screen
	bsr.w	addframe2				;add it
.exit	movem.l	(sp)+,d0-d2			;hidden or off screen: nothing drawn
	rts								;return

prevtileptr	=	4					;addframe2 stack: the last sprite's tile pointer (saved d2)
prevtilecnt	=	8					;and its tile count (saved d4)
addframe2							;d0/d1 = x/y coordinates on screen, a3 = object. a5 = dma list, a6 =
									;sprite table, d6 = link counter.
									;Also entered from checksso .ca and setupice. frame word: top 5 bits are
									;attribute bits, low 11 the frame frames come from SpritesMap (offset
									;table at +4) instead of a framelist. attribute is restored on exit
	move.w	attribute(a3),-(sp)		;save attribute
	movem.l	d0-d5/a0-a2,-(sp)		;push to stack
	move.w	frame(a3),d4			;move frame into d4
	bmi.w	.exit					;exit if minus
	beq.w	.exit					;exit if 0
	andi.w	#$F800,d4				;frame's attribute bits
	eor.w	d4,attribute(a3)		;flip them into attribute for this draw
	move.w	frame(a3),d4			;move frame back into d4
	andi.w	#$7FF,d4				;pass first 11 bits
	movea.l	#Sprites,a2				;sprite frame list
	adda.l	jimdata(a2),a2			;frame offset table
	IF REV=2
	add.w	d4,d4					;Rev B: the offset table has no entry for frame 0, so index one word lower
	cmp.w	(a2),d4					;first offset = table size
	bge.w	.exit					;frame past the table
	move.w	(a2,d4.w),d5
	sub.w	-2(a2,d4.w),d5
	lsr.w	#3,d5					;/ 8 bytes per sprite
	subq.w	#1,d5					;number of sprites in frame-1
	adda.w	-2(a2,d4.w),a2			;first sprite
	ELSE
	asl.w	#1,d4					;word index
	cmp.w	2(a2),d4				;first offset = table size
	bge.w	.exit					;frame past the table
	move.w	2(a2,d4.w),d5
	sub.w	(a2,d4.w),d5
	lsr.w	#3,d5					;divide d5 by 8
	subq.w	#1,d5					;number of sprites in frame-1
	adda.w	(a2,d4.w),a2			;first sprite
	ENDIF
	clr.w	d3						;clear d3
	clr.w	d4						;clear d4
.sloop	move.w	d0,-(sp)			;per sprite of the frame; d0 = x for now, saved
	move.w	frame(a3),d0			;move frame into d0
	andi.w	#$7FF,d0				;pass first 11 bits
	cmp.w	oldframe(a3),d0			;compare old frame to d0 (current frame)
	beq.w	.noref					;same frame: tiles already in vram

	tst.w	d5						;check if d5 is 0
	bne.w	.nn						;branch if not
	move.w	d0,oldframe(a3)			;last sprite: oldframe = frame
.nn	movem.w	d0-d4,-(sp)				;work out whether this sprite's tiles overlap the previous one's;
									;prevtileptr(sp) / prevtilecnt(sp) = d2 / d4 of the last sprite
	move.w	seTile(a2),d2			;tile pointer (kept whole)
	clr.w	d4						;clear d4
	move.b	seSize(a2),d4			;size byte
	movea.l	#sizetab,a0				;move address into a0
	move.b	(a0,d4.w),d4			;chars used in this sprite
	cmp.w	prevtilecnt(sp),d4		;compare current d4 to previous d4
	bgt.w	.nodup					;more data in prev sprite so no dup
	cmp.w	prevtileptr(sp),d2		;compare current d2 to previous d2
	blt.w	.nodup					;branch if less than
	move.w	prevtileptr(sp),d0		;move previous d2 into d0
	add.w	prevtilecnt(sp),d0		;end of last data
	sub.w	d2,d0					;sub d2 from d0
	sub.w	d4,d0					;sub d4 from d0
	bmi.w	.nodup					;branch if d0 negative
	movem.w	(sp)+,d0-d1				;pop d0 and d1 from stack
	addq.w	#6,sp					;add 6 to stack pointer
	bra.w	.dup

.nodup	add.w	prevtilecnt(sp),d3	;d3 = vram char offset after the previous sprite's tiles
	movem.w	(sp)+,d0-d1				;pop d0 and d1 from stack (d0=Xpos, d1=Ypos)
	addq.w	#6,sp					;add 6 to stack pointer (moves past old d4 spot on stack)

	movem.w	d0-d4,-(sp)				;queue a dma of this sprite's new tiles
	add.w	VRchar(a3),d3			;add VRChar of player struct to d3
	ext.l	d2						;extend d2 (clears out upper word)
	asl.l	#5,d2					;mult d2 by 32
	addi.l	#Spritetiles,d2			;tile address
	asl.w	#4,d4					;mult by 16 (# of sprite tiles by 16)
	asl.w	#5,d3					;mult by 32 (# of prev sprite tiles+VrChar by 32)
	move.l	d2,(a5)+
	move.w	d4,(a5)+				;words to transfer
	move.w	d3,(a5)+				;vram destination
	movem.w	(sp)+,d0-d4				;pop from stack
.dup	move.b	d3,VRoffs(a3,d5.w)	;remember this sprite's char offset in the object
.noref	move.w	(sp)+,d0			;restore x
	movem.w	d0-d2,-(sp)				;write sprite att
	move.w	seY(a2),d2				;y global (+2; 92 used +0)
	btst	#4,attribute(a3)		;y flip
	beq.w	.noyflip				;branch if no y flip
	move.b	seSize(a2),d2			;move byte 7 (sizetab byte) into d2
	andi.w	#3,d2					;pass bit 1 and 2
	addq.w	#1,d2					;add 1
	asl.w	#3,d2					;mult by 8
	neg.w	d2						;negate d2
	sub.w	seY(a2),d2				;sub Y global from d2
.noyflip	add.w	d2,d1			;screen y + sprite y
	move.w	d1,(a6)					;move sprite's Ypos into a6 data (Satt)

	move.w	(a2),d2					;x global (+0; 92 used +6)
	btst	#3,attribute(a3)		;x flip
	beq.w	.noxflip				;branch if no x flip
	move.b	seSize(a2),d2			;move data at 7+a2 into d2
	andi.w	#$C,d2					;pass bit 3 and 4
	addq.w	#4,d2					;add 4
	asl.w	#1,d2					;mult by 2
	neg.w	d2						;negate d2
	sub.w	(a2),d2					;sub data at a2 from d2
.noxflip	add.w	d2,d0			;screen x + sprite x
	move.w	d0,satX(a6)				;move sprite's Xpos into 6+a6 position
	move.b	seSize(a2),satSize(a6)	;size
	move.b	d6,satLink(a6)			;link
	move.w	seAttr(a2),d2			;move 6+a2 into d2 (to be used to check palette and set HVFlip)
	move.w	attribute(a3),d0		;move attribute into d0
	eor.w	d0,d2					;EOR d0 with d2
	andi.w	#$F800,d2				;pass top 5 bits
	btst	#0,attribute+1(a3)		;check if bit 0 of attribute+1 is 0
	beq.w	.nospec					;branch if zero
	btst	#$E,d2					;check if bit 14 is 0
	beq.w	.nospec					;branch if zero
	bset	#$D,d2					;team 2 color
.nospec	or.b	VRoffs(a3,d5.w),d2	;char offset of this sprite
	add.w	VRchar(a3),d2			;add VRchar to d2
	move.w	d2,satTile(a6)			;move d2 into 4+a6 (Satt)
	movem.w	(sp)+,d0-d2				;pop from stack

	addq.w	#1,d6					;add 1 to d6
	addq.w	#8,a6					;add 8 to a6
	addq.w	#8,a2					;add 8 to a2
	dbf	d5,.sloop					;loop if still sprites in frame
.exit	movem.l	(sp)+,d0-d5/a0-a2	;also reached when frame is 0, negative or past the table
	move.w	(sp)+,attribute(a3)		;restore attribute
	rts								;return

find3d								;input - d0=xfield,d1=yfield,d2=height off field output -
									;d0=xscreen,d1=yscreen (osflag $4E20 when off screen). Called from
									;addframe
	btst	#sfhor,(sflags).w		;horizontal?
	beq.w	.nhor					;no
	exg	d0,d1
	neg.w	d0
	subi.w	#horoff,d1
	bra.w	.crange

.nhor	sub.w	(Hpos).w,d0			;position relative to the scroll
	sub.w	(Vpos).w,d1
.crange	cmp.w	#$90,d0				;128+16
	bgt.w	.offscr
	cmp.w	#-$90,d0				;-(128+16)
	blt.w	.offscr
	addi.w	#$100,d0				;128+128
	add.w	d2,d1
	asr.w	#1,d2
	add.w	d2,d1					;y + 1.5 * height
	cmp.w	#$90,d1					;112+32
	bgt.w	.offscr
	cmp.w	#-$90,d1				;-(112+32)
	blt.w	.offscr
	neg.w	d1
	addi.w	#$F0,d1					;112+128
	rts								;return
.offscr	move.w	#osflag,d1			;osflag: caller skips the object
	rts								;return

updatesound							;move the crowd noise volume (psg noise channel) toward Crowdlevel.
									;Called from periodicevents
	move.w	(Crowdlevel).w,d0
	asl.w	#3,d0
	addi.w	#$400,d0
	cmp.w	#$EFF,d0
	bls.w	.ip
	move.w	#$EFF,d0				;cap it

.ip	moveq	#$28,d2					;max step 40 (d0 = target level, asv = current)
	sub.w	(asv).w,d0
	cmp.w	d2,d0
	bgt.w	.iasv
	neg.w	d2
	cmp.w	d2,d0
	bge.w	.non					;within 40: no change
.iasv	add.w	d2,(asv).w			;step asv toward the target
	bpl.w	.non
	clr.w	(asv).w
.non	move.b	#$C8,(Asound).l		;psg: noise channel setup, then attenuation below
	move.b	#1,(Asound).l
	move.b	(asv).w,d0				;crowd level
	eori.b	#$F,d0
	ori.b	#$F0,d0					;noise channel attenuation
	move.b	d0,(Asound).l
	rts								;return

KillCrowd							;silence the crowd noise (psg). Called from Reset, SetupPauseScreen, ...
	move.b	#$E7,(Asound).l			;noise control
	move.b	#$DF,(Asound).l			;tone 3 off
	move.b	#$C8,(Asound).l			;noise channel
	move.b	#1,(Asound).l
	move.b	#$FF,(Asound).l			;noise channel off
	rts								;return
