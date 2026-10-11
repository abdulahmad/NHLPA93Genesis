;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment
;	remap, forceblack, forcefade, cramfade, the
;	CopyPaletteToCRAM, randomd0s, randomd0, sroot, sfx, song,
;	waitx, waitxsr, waitjoy, orjoy,
;	nodiag, the ProcessInputWithRepeat, Readjoy1, Readjoy2,
;	ReadJoy, jdtab, DoDMApro, DoDMA, the DoDMA_nd2 (vram copy),
;	DoFill, WaitDMA, setVram, setVram_0 and Vmaddr.
;	Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	disflags bits: df32c 1, dfng 2 (same as 92).

remap	;a0 = data (char set), d0 = size in words, d1 = vram dest, a1 = mapping data (93: two color nibbles per byte, high nibble for even colors). Jumped to from DecompressGraphics
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d4/a0-a2,-(sp)
	exg	d1,d0		;(keep EA register order)
	movea.l	a0,a2
	bsr.w	Vmaddr
	subq.w	#1,d1
.1	moveq	#3,d0			;4 pixels per word
	move.w	(a2)+,d2
	clr.w	d3
.2	move.w	d2,d4
	andi.w	#$F,d4
	lsr.w	#1,d4			;map byte = color/2
	move.b	(a1,d4.w),d4
	btst	#0,d2
	bne.w	.lo			;odd color: low nibble
	lsr.w	#4,d4			;even color: high nibble
.lo	andi.w	#$F,d4			;(92 or.b 0(a1,d4),d3)
	or.b	d4,d3
	ror.w	#4,d3
	ror.w	#4,d2
	dbf	d0,.2
	move.w	d3,(a0)
	dbf	d1,.1
	movem.l	(sp)+,d0-d4/a0-a2
	move.w	(sp)+,(disflags).w
	rts

forceblack	;fade all colors to black but don't upset palfadenew
	movem.l	d0/a0,-(sp)
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d0			;31
.0	move.l	(a0),-(sp)
	clr.l	(a0)+
	dbf	d0,.0
	move.w	#$18,(palcount).w	;24
	bsr.w	forcefade
	moveq	#$1F,d0
.1	move.l	(sp)+,-(a0)
	dbf	d0,.1
	movem.l	(sp)+,d0/a0
	rts

forcefade	;regardless of interupts/disflags fade in new palettes, don't upset anything else. Called from forceblack and setVram
	move.w	sr,-(sp)
	move.l	(vbint).w,-(sp)
	move.w	(disflags).w,-(sp)
	bclr	#dfng,(disflags).w
	move.l	#vb2,(vbint).l
	move.w	#$2500,sr
.1	tst.w	(palcount).w
	bpl.s	.1
	move.w	(sp)+,(disflags).w
	move.l	(sp)+,(vbint).w
	move.w	(sp)+,sr
	rts

cramfade	;fade from current color in color ram to color held in palfadenew. This should be called during vblank because palette changes punch holes in video. palcount 100 copies the palette with no fade (CopyPaletteToCRAM)
	tst.w	(palcount).w
	bmi.w	rtss
	cmpi.w	#$64,(palcount).w	;100 = copy now
	beq.w	CopyPaletteToCRAM
	subq.w	#1,(palcount).w
	bmi.w	rtss

	clr.l	d0
	move.w	(palcount).w,d0
	cmp.w	#24,d0
	bgt.w	rtss
	divu.w	#3,d0
	swap	d0
	asl.w	#2,d0			;shifter 0/4/8
	moveq	#2,d3
	asl.w	d0,d3
	moveq	#$E,d5
	asl.w	d0,d5
	move.w	d5,d4
	not.w	d4
	movea.l	#palfadenew,a1
	movea.l	#VDP_DATA,a0		;Vdata
	clr.w	d6
.top	move.w	d3,d2

	move.w	d6,d0
	swap	d0
	move.w	#$20,d0
	move.l	d0,4(a0)		;cram read d6
	move.w	(a0),d7			;current color

	move.w	d7,d0
	and.w	d5,d0
	move.w	(a1)+,d1		;dest color
	and.w	d5,d1
	cmp.w	d1,d0
	beq.w	.next
	blt.w	.nn
	neg.w	d2
.nn	add.w	d2,d0
	and.w	d4,d7
	or.w	d0,d7

	move.l	#$C000,d0
	move.b	d6,d0
	swap	d0
	move.l	d0,4(a0)		;cram write d6
	move.w	d7,(a0)

.next	addq.w	#2,d6
	cmp.w	#$80,d6
	bne.s	.top
	rts

CopyPaletteToCRAM	;copy all 64 palfadenew colors straight to color ram and set palcount = -1. Protected from vblank. Entered from cramfade (palcount 100), called from SetupStanleyCupCelebrationScreen
	movem.l	d0/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movea.w	#(palfadenew-M68K_RAM),a1
	movea.l	#VDP_DATA,a0
	move.l	#$C0000000,4(a0)	;cram write 0
	moveq	#$1F,d0
.0	move.l	(a1)+,(a0)
	dbf	d0,.0
	st	(palcount).w		;fade done
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0/a0-a1
	rts

;middle of code routines------------------------------------
randomd0s	;d0 = range. Return d0 = random number (-range < d0 < range)
	move.w	d0,-(sp)
	asl.w	#1,d0
	bsr.w	randomd0
	sub.w	(sp)+,d0
	rts

randomd0	;d0 = range. Return random number in d0 (0 <= d0 < range)
	movem.l	d0-d2,-(sp)
	move.w	(seed+2).w,d0	;seed+2 (92)
	move.w	d0,d1
	move.w	(seed).w,d2		;seed
	mulu.w	#$E62D,d0
	mulu.w	#$BB40,d1
	mulu.w	#$E62D,d2
	add.w	d2,d1
	swap	d0
	add.w	d1,d0
	swap	d0
	addq.l	#1,d0
	move.l	d0,(seed).w		;seed
	asr.l	#8,d0
	mulu.w	2(sp),d0
	swap	d0
	addq.w	#4,sp
	movem.l	(sp)+,d1-d2
	rts

sroot	;Square Root, this returns (d0.L)^.5 in d0. 93: values above use a binary search
	tst.l	d0
	beq.w	rtss			;zero^.5 = zero
	cmp.l	#40*40,d0
	bhi.w	.m2
	move.l	d1,-(sp)		;find square root of d0
	moveq	#-1,d1
.0	addq.w	#2,d1
	sub.w	d1,d0
	bcc.s	.0
	lsr.w	#1,d1
	move.w	d1,d0
	move.l	(sp)+,d1
	rts

.m2	movem.l	d1-d4,-(sp)		;(92 d1-d3)
	moveq	#9,d3			;max number of reps
	move.w	#$8000,d1		;92 guess for big values, unused in 93
	cmp.l	#$F00000,d0
	bhi.w	.big			;binary search (92 bhi .top)
	move.l	d0,d1
	lsr.l	#8,d1
	addq.w	#2,d1
.top	move.w	d1,d2
	move.l	d0,d1
	divu.w	d2,d1
	add.w	d2,d1
	lsr.w	#1,d1
	cmp.w	d1,d2
	dbeq	d3,.top
.done	move.w	d1,d0
	movem.l	(sp)+,d1-d4
	rts

.big	moveq	#0,d1			;d1 = low, d2 = high ($FFFF)
	moveq	#-1,d2
.bs	move.w	d1,d3			;d3 = (low+high)/2, carry shifted back in
	add.w	d2,d3
	roxr.w	#1,d3
	cmp.w	d3,d1
	beq.s	.done			;no step left: d1 is the root
	move.w	d3,d4
	mulu.w	d3,d3
	cmp.l	d3,d0
	bcc.w	.lo			;d0 >= mid^2: raise low
	move.w	d4,d2			;else lower high
	bra.s	.bs
.lo	move.w	d4,d1
	bra.s	.bs

sfx	;play sound effect number. One word passed on stack
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0		;16*4(a7)
	bmi.w	.none
	move.w	d0,(lastsfx).w
	jsr	(play_sfx_or_music_track).l
.none	movem.l	(sp)+,d0-d7/a0-a6
	move.l	(sp),2(sp)
	addq.w	#2,sp
	rts

song	;play song number. One word passed on stack
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0		;16*4(a7)
	bmi.w	.none
	jsr	(play_sfx_or_music_track).l
.none	movem.l	(sp)+,d0-d7/a0-a6
	move.l	(sp),2(sp)
	addq.w	#2,sp
	rts

waitx	;wait d0 vblanks or until input from either joystick. Return joystick variables (d0-d3) if any. Called from ScoutingReport and SetupStanleyCupCelebrationScreen
	neg.w	d0
	move.w	d0,(vcount).w
.wait	bsr.w	Readjoy1
	tst.w	d1
	bne.w	rtss
	bsr.w	Readjoy2
	tst.w	d1
	bne.w	rtss
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0
	beq.s	.0
	tst.w	d0
	bmi.s	.wait
	rts

waitxsr	;d0 vblanks while the zamboni crosses (zamx counts up to $708) and the crowd updates. A key on either pad (sflags bit 1 = pad 2) leaves at least 120 frames and goes to HandleMenuInput; eq from it exits with d1 bit 7 set. Called from Intermission
	movem.l	d4-d7/a0-a3,-(sp)
	neg.w	d0
	move.w	d0,(vcount).w
.wait	cmpi.w	#$708,(zamx).w		;(92 tst zamx / bmi.nz)
	bhi.w	.nz
	addq.w	#1,(zamx).w
.nz	moveq	#1,d7			;one elapsed frame
	bsr.w	updatecrowdf
	bclr	#1,(sflags).w		;pad 1
	bsr.w	Readjoy1
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.key
	bset	#1,(sflags).w		;pad 2
	bsr.w	Readjoy2
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	beq.w	.vid
.key	move.w	(vcount).w,d0
	cmp.w	#-120,d0
	blt.w	.menu			;more than 120 frames left: keep them
	moveq	#-$78,d0		;else wait 120 more
.menu	movem.w	d0,-(sp)
	bsr.w	HandleMenuInput
	bne.w	.resume
	addq.w	#2,sp
	bset	#7,d1
	bra.w	.ex
.resume	move.w	(sp)+,(vcount).w
.vid	bsr.w	setvideo
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0
	beq.s	.0
	tst.w	d0
	bmi.s	.wait
.ex	movem.l	(sp)+,d4-d7/a0-a3
	rts

waitjoy	;wait for either joystick input. Return d1 = new button presses. it as data (no caller found)
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0
	beq.s	.0
	bsr.w	orjoy
	beq.s	waitjoy
	rts

orjoy	;return d1 = new button presses from either joystick
	bsr.w	Readjoy1
	move.w	d1,-(sp)
	bsr.w	Readjoy2
	or.w	(sp)+,d1
	rts

nodiag	;eliminate diagonal direction presses: if held directions (d3 bits 0-3) are not one direction, clear the d1 direction bits
	movem.l	d0/d4-d5,-(sp)
	moveq	#3,d4
	move.w	d3,d0
	andi.w	#$F,d0
	beq.w	.ok
.0	clr.w	d5
	bset	d4,d5
	cmp.w	d5,d0
	dbeq	d4,.0
	beq.w	.ok
	andi.w	#$FFF0,d1
.ok	movem.l	(sp)+,d0/d4-d5
	rts

ProcessInputWithRepeat	;nodiag, then key repeat on d1-d3 from Readjoy1/2. A change (d2) resets the delay to 15 frames; while the same buttons stay held, every 4 frames return d1 = held buttons (d3). Called from Pausemode, menus and IntermissionLoop
	bsr.s	nodiag
	tst.w	d3
	beq.w	rtss			;nothing held
	tst.w	d2
	bne.w	.chg
	subq.w	#1,(repeatdelayframes).w
	bpl.w	rtss
	move.w	#4,(repeatdelayframes).w	;repeat rate
	move.w	d3,d1			;repeat the held buttons
	rts
.chg	move.w	#$F,(repeatdelayframes).w	;first repeat delay
	rts

Readjoy1	;read controller 1. Return d0 = direction (bit 0-3) and new button (bit 4-7) presses, d1 = new presses (all 8 bits), d2 = changed buttons (all 8), d3 = current held buttons (all 8)
	move.l	a0,-(sp)
	movea.l	#Joy1,a0
	bsr.w	ReadJoy
	movea.l	(sp)+,a0
	move.w	(lj1).w,d2
	move.w	d1,(lj1).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts

Readjoy2	;read controller 2. Return d0 = direction (bit 0-3) and new button (bit 4-7) presses, d1 = new presses (all 8 bits), d2 = changed buttons (all 8), d3 = current held buttons (all 8)
	move.l	a0,-(sp)
	movea.l	#Joy2,a0
	bsr.w	ReadJoy
	movea.l	(sp)+,a0
	move.w	(lj2).w,d2
	move.w	d1,(lj2).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts

ReadJoy	;read controller a0. Return d0 = direction (bit 0-3) and new button (bit 4-7) presses, d1 = buttons down (all 8 bits)
	move.w	#$100,(IO_Z80BUS).l	;turn off z80
	move.b	#$40,6(a0)
	move.b	#0,(a0)
	move.w	#0,(IO_Z80BUS).l	;turn on z80
	move.w	#10,d1
.z	dbf	d1,.z
	move.w	#$100,(IO_Z80BUS).l	;turn off z80
	move.b	(a0),d0
	move.b	#$40,(a0)
	move.w	#0,(IO_Z80BUS).l	;turn on z80

	asl.b	#2,d0
	andi.b	#%11000000,d0
	move.w	#10,d1
.zz	dbf	d1,.zz
	move.w	#$100,(IO_Z80BUS).l	;turn off z80
	move.b	(a0),d1
	move.w	#0,(IO_Z80BUS).l	;turn on z80
	andi.b	#%00111111,d1
	or.b	d1,d0
	not.b	d0
	clr.w	d1
	move.b	d0,d1
	move.w	d1,-(sp)
	andi.w	#$F0,d0
	andi.w	#$F,d1
	movea.l	#jdtab,a0
	move.b	(a0,d1.w),d1
	or.w	d1,d0
	move.w	(sp)+,d1
	rts

jdtab	;convert buttons l,r,d,u into directions 0-7,8
	dc.b	8,0,4,8,6,7,5,8,2,1,3,8,8,8,8,8

DoDMApro	;initiate dma transfer and protect from vblank interuption. d0 = words to transfer, d1 = initial vram address, a0 = address to transfer from. Jumped to from DecompressGraphics
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	bsr.w	DoDMA
	move.w	(sp)+,(disflags).w
	rts

DoDMA	;initiate dma transfer (dma transfer bug is compensated for). d0 = words to transfer, d1 = destination vram address, a0 = source address
	movem.l	d2/a1,-(sp)
	move.w	d0,d2
	add.w	d2,d2
	add.w	a0,d2
	bcc.w	.nd
	beq.w	.nd
	lsr.w	#1,d2			;do two transfers if source address crosses 64k boundary
	sub.w	d2,d0
	move.w	d0,-(sp)
	bsr.w	.dd
	move.w	(sp)+,d0
	add.w	d0,d0
	add.w	d0,d1
	adda.w	d0,a0
	move.w	d2,d0
	bra.w	.nd
.dd	movem.l	d2/a1,-(sp)
.nd	lea	(VDP_CTRL).l,a1		;set d0 = num of words
	move.w	#$8154,(a1)		;$8100+%01010100
	move.w	#$8F02,(a1)		;d1 = video address
	move.w	#$9300,d2		;a0 = source address
	move.b	d0,d2
	move.w	d2,(a1)
	move.w	#$9400,d2
	lsr.w	#8,d0
	move.b	d0,d2
	move.w	d2,(a1)
	move.l	a0,d0
	lsr.l	#1,d0
	move.w	#$9500,d2
	move.b	d0,d2
	move.w	d2,(a1)
	lsr.l	#8,d0
	move.w	#$9600,d2
	move.b	d0,d2
	move.w	d2,(a1)
	lsr.l	#8,d0
	andi.b	#$7F,d0
	move.w	#$9700,d2
	move.b	d0,d2
	move.w	d2,(a1)

	clr.l	d0
	move.w	d1,d0
	asl.l	#2,d0
	lsr.w	#2,d0
	ori.l	#$804000,d0

	move.l	d0,(dmaram).w
	move.w	(dmaram+2).w,(a1)
	move.w	(dmaram).w,(a1)

	bsr.w	WaitDMA
	move.w	#$8164,(a1)		;$8100+%01100100
	movem.l	(sp)+,d2/a1
	rts

DoDMA_nd2	;vram to vram copy by dma (reg 23 = $C0), protected from vblank. d0 = length, d2 = source vram address, d1 = destination vram address. Auto inc 1 during the copy, then 2 again. Called from CopyTeamBlockMapData and ScrollDisplayUp
	movem.l	d0-d3/a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	lea	(VDP_CTRL).l,a1
	move.w	#$8154,(a1)		;$8100+%01010100
	move.w	#$8F01,(a1)		;auto inc 1
	move.w	#$9300,d3		;length low
	move.b	d0,d3
	move.w	d3,(a1)
	move.w	#$9400,d3		;length high
	lsr.w	#8,d0
	move.b	d0,d3
	move.w	d3,(a1)
	move.w	#$9500,d3		;source low
	move.b	d2,d3
	move.w	d3,(a1)
	move.w	#$9600,d3		;source high
	lsr.w	#8,d2
	move.b	d2,d3
	move.w	d3,(a1)
	move.w	#$97C0,(a1)		;dma mode: vram copy
	clr.l	d0
	move.w	d1,d0
	asl.l	#2,d0
	lsr.w	#2,d0
	swap	d0
	ori.w	#$C0,d0			;vram copy command
	move.l	d0,(a1)
	bsr.w	WaitDMA
	move.w	#$8164,(a1)		;$8100+%01100100
	move.w	#$8F02,(a1)		;auto inc 2
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d3/a1
	rts

DoFill	;fill vram. d0 = words to fill, d1 = vram address, d2 = data to fill with
	movem.l	d3/a1,-(sp)
	movea.l	#VDP_DATA,a1		;Vdata
	andi.l	#$FFFF,d1
	asl.l	#2,d1
	lsr.w	#2,d1
	ori.w	#$4000,d1
	swap	d1
	move.l	d1,4(a1)
	move.w	d2,d3
	swap	d3
	move.w	d2,d3
	lsr.w	#1,d0
	subq.w	#1,d0
.0	move.l	d3,(a1)
	dbf	d0,.0
	movem.l	(sp)+,d3/a1
	rts

WaitDMA	;wait for dma completion
	move.w	(VDP_CTRL).l,-(sp)
	btst	#1,1(sp)
	addq.w	#2,sp
	bne.s	WaitDMA
	rts

setVram	;initialize all necesary video parameters based on my variables. d0 = color to fade to. Falls into setVram_0
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$3F,d1			;63
.0	move.w	d0,(a0)+
	dbf	d1,.0
	move.w	#$18,(palcount).w	;24
	bsr.w	forcefade

setVram_0	;second half of setVram without the fade: clear vram and set the VDP registers from disflags, Map1col, VmMap1-3, VSPRITES and VSCRLPM. Falls in from setVram, called from SetupStanleyCupCelebrationScreen
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	move.w	#$8F02,(VDP_CTRL).l	;VmInc 2
	clr.w	d0
	bsr.w	Vmaddr
	move.w	#$3FFF,d0
	clr.l	d1
.9	move.l	d1,(a0)
	dbf	d0,.9

	move.w	#$8C00,d0		;8 for shadow mode
	btst	#df32c,(disflags).w
	bne.w	.i32
	ori.w	#$81,d0			;%10000001
.i32	move.w	d0,4(a0)		;40 column mode, no interlace, normal brightness

	move.w	#$8004,4(a0)		;512 color palette enable
	move.w	#$8164,4(a0)		;$8100+%01100100

	move.w	#$9001,d0		;Playfield is 64x32
	cmpi.w	#6,(Map1col).w
	beq.w	.i64
	move.w	#$9003,d0
.i64	move.w	d0,4(a0)

	move.w	#$8200,d0
	move.b	(VmMap1).w,d0
	lsr.b	#2,d0
	andi.b	#%00111000,d0
	move.w	d0,4(a0)

	move.w	#$8400,d0
	move.b	(VmMap2).w,d0
	lsr.b	#5,d0
	move.w	d0,4(a0)

	move.w	#$8300,d0
	move.b	(VmMap3).w,d0
	lsr.b	#2,d0
	andi.b	#%00111110,d0
	move.w	d0,4(a0)

	move.w	#$8500,d0
	move.b	(VSPRITES).w,d0
	lsr.b	#1,d0
	move.w	d0,4(a0)

	move.w	#$8D00,d0
	move.b	(VSCRLPM).w,d0
	lsr.b	#2,d0
	move.w	d0,4(a0)

	move.w	#$9100,4(a0)		;disable plane 3 graphics
	move.w	#$9200,4(a0)		;disable plane 3 graphics
	move.w	#$8700,4(a0)		;Palette # 0 is border/transparent.
	move.w	#$8B00,4(a0)		;Scroll mode. (entire scroll)

	move.l	#$40000010,4(a0)	;vsram
	move.l	#0,(a0)			;playfield 1/2
	move.w	(sp)+,(disflags).w
	rts

Vmaddr	;set video port to address d0. d0 = vram address, returns a0 = Vdata!!!
	movea.l	#VDP_DATA,a0
	asl.l	#2,d0
	lsr.w	#2,d0
	ori.w	#$4000,d0
	swap	d0
	andi.w	#3,d0
	move.l	d0,4(a0)
	rts

;======================================================================
;======================================================================
;	NHLPA Hockey 93 (retail) segment dobitmap, the tile decompressor
;	(DecompressGraphicsWithCallback, DoDMA_clearCallbackPointer,
;	DecompressGraphics, DecompressBytecode, jump_table, the Opcode_*
;	handlers, FlushOutputBuffer), xyVmMap, eraser, Framer, the 93-only
;	printsmallz/printsmall with ControlCodeJumpTable and the ControlCode_*
;	handlers, printz, print, the FormatAndPrintTime and PeriodLabelTable,
;	PushTime, PushNumber, the PushNumberWidth, appendz, appstring,
;	printbigz, printbig, AddSmallFont, AddFramer and AddTeamBlock. Bytes
;	match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx).
;	The source has the real cmp / exg; fixopcodes.js patches the encoding after assembly.
;	disflags bits: dfng 2 (same as 92).
;	93 loads tiles through DecompressGraphics (a2 = tile data, d4 = start
;	char) instead of 92's direct DoDMA.

dobitmap	;transfer palette data/map data/tiles data to vram. a0 = palette, a1 = map, a2 = tiles (DecompressGraphics data), d0 = start x, d1 = start y, d2 = width x, d3 = width y, d4 = start char, d5 = pal used bits (0-3) for color fam 1-4. printy is restored and the tiles go last through DecompressGraphics (returns d4 = end char)
	move.w	(printy).w,-(sp)	;keep printy
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/d5-d6/a0-a3,-(sp)
	move.w	d1,d6			;y start in d6 (92 used 6(a7))
	movea.w	#(palfadenew-M68K_RAM),a3
	bra.w	.00
.01	move.b	(a0,d0.w),(a3,d0.w)
	dbf	d0,.01
.02	adda.w	#$20,a0
	adda.w	#$20,a3
.00	moveq	#$1F,d0			;31
	lsr.w	#1,d5
	bcs.s	.01
	bne.s	.02

	move.w	(printa).w,d5
	andi.w	#$F800,d5
	move.w	$E(sp),d2		;width y
	subq.w	#1,d2

.loop2	bsr.w	xyVmMap
	move.w	d6,d0			;y start
	mulu.w	(a1),d0			;map width
	add.w	2(sp),d0		;x start
	asl.w	#1,d0
	move.w	$A(sp),d1		;width x
	subq.w	#1,d1
.loop1	move.w	4(a1,d0.w),d3
	add.w	d4,d3
	eor.w	d5,d3
	move.w	d3,(a0)
	addq.w	#2,d0
	dbf	d1,.loop1
	addq.w	#1,(printy).w
	addq.w	#1,d6
	dbf	d2,.loop2
	bsr.w	DoDMA_clearCallbackPointer	;tiles a2 to char d4
	movem.l	(sp)+,d0-d3/d5-d6/a0-a3
	move.w	(sp)+,(disflags).w
	move.w	(sp)+,(printy).w
	rts

DecompressGraphicsWithCallback	;DecompressGraphics through remap. The 8 bytes after the bsr are the remap color table (callbackPtr = their address); returns past them. a2 = tile data, d4 = start char
	move.l	(sp),(callbackPtr).w
	bsr.w	DecompressGraphics
	addq.l	#8,(sp)			;skip the inline remap table
	rts

DoDMA_clearCallbackPointer	;clear callbackPtr (plain DMA, no remap) and fall into DecompressGraphics. a2 = tile data, d4 = start char
	clr.l	(callbackPtr).w

DecompressGraphics	;send tiles to vram. a2 = data: word count of tiles (0 = none, bit 15 set = compressed by DecompressBytecode), then the tiles. d4 = start char, returns d4 = end char + 1. Uses remap with callbackPtr when it is set, else DoDMApro
	movem.l	d0-d1/a0-a6,-(sp)
	movea.l	a2,a0			;a0 = compressed data
	move.w	d4,d1
	asl.w	#5,d1			;d1 = vram address of start char
	move.w	(a0)+,d0		;tile count
	beq.w	.done			;no tiles
	bmi.w	.packed			;bit 15: compressed
	add.w	d0,d4
	asl.w	#4,d0			;words to transfer
	pea	(.done).l
	tst.l	(callbackPtr).w
	beq.w	DoDMApro
	movea.l	(callbackPtr).w,a1	;remap table
	bra.w	remap

.packed	andi.w	#$7FFF,d0		;tile count
	add.w	d0,d4
	bsr.w	DecompressBytecode
.done	movem.l	(sp)+,d0-d1/a0-a6
	rts

DecompressBytecode	;unpack a0 into the 256 byte ring buffer at DispAttribCtr and flush each full buffer to vram d3 (FlushOutputBuffer). The high nibble of each opcode byte picks a handler from jump_table. Ends on a CopyBackwardReverseMedium code with distance 0. d1 = vram address
	movea.w	#(DispAttribCtr-M68K_RAM),a1	;output buffer
	movea.w	#(DispAttribCtr-M68K_RAM),a3
	movea.w	#(callbackPtr-M68K_RAM),a4
	movea.l	#remap,a5
	movea.l	#DoDMApro,a6
	movem.l	d0-d3/a0-a2,-(sp)
	move.w	d1,d3			;d3 = vram address
	clr.w	d1			;d1 = output buffer offset
	clr.w	d2
.loop	move.b	(a0)+,d0		;read opcode
	andi.w	#$F0,d0
	lsr.w	#3,d0			;upper nibble * 2
	lea	jump_table(pc),a2
	move.w	(a2,d0.w),d0
	jsr	(a2,d0.w)		;handler, reads its count from -1(a0)
	bra.s	.loop

jump_table	;DecompressBytecode handler offsets, one per opcode high nibble
	dc.w	Opcode_CopyLiteral-jump_table		;0
	dc.w	Opcode_CopyLiteral-jump_table		;1
	dc.w	Opcode_ClearBytes-jump_table		;2
	dc.w	Opcode_Fillbytes-jump_table		;3
	dc.w	Opcode_CopyBackwardShort-jump_table	;4
	dc.w	Opcode_CopyBackwardShort-jump_table	;5
	dc.w	Opcode_CopyBackwardShort-jump_table	;6
	dc.w	Opcode_CopyBackwardShort-jump_table	;7
	dc.w	Opcode_CopyBackwardMedium-jump_table	;8
	dc.w	Opcode_CopyBackwardLong-jump_table	;9
	dc.w	Opcode_CopyBackwardExtended1-jump_table	;A
	dc.w	Opcode_CopyBackwardExtended2-jump_table	;B
	dc.w	Opcode_CopyBackwardReverseShort-jump_table	;C
	dc.w	Opcode_CopyBackwardReverseShort-jump_table	;D
	dc.w	Opcode_CopyBackwardReverseMedium-jump_table	;E
	dc.w	Opcode_CopyBackwardReverseLong-jump_table	;F

Opcode_CopyLiteral	;opcodes 0-1, copy (low 5 bits)+1 bytes from the data
	move.b	-1(a0),d0
	andi.w	#$1F,d0
.loop	move.b	(a0)+,(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer	;buffer full
.next	dbf	d0,.loop
	rts

Opcode_ClearBytes	;opcode 2, write (low 4 bits)+1 zero bytes
	move.b	-1(a0),d0
	andi.w	#$F,d0
.loop	clr.b	(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_Fillbytes	;opcode 3, write the next data byte (low 4 bits)+3 times
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
.loop	move.b	d2,(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_CopyBackwardShort	;opcodes 4-7, copy (bits 0-2)+2 bytes from (bits 3-5)+1 back in the buffer
	move.b	-1(a0),d0
	andi.w	#7,d0
	addq.w	#1,d0			;count-1
	move.b	-1(a0),d2
	lsr.w	#3,d2
	andi.w	#7,d2
	addq.w	#1,d2			;distance

CopyBackwardRun	;shared copy loop, d0 = count-1, d2 = distance back. Entered from the CopyBackward Medium/Long/Extended handlers
	neg.b	d2
	add.b	d1,d2			;source offset in the ring buffer
.loop	move.b	(a1,d2.w),(a1,d1.w)
	addq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_CopyBackwardMedium	;opcode 8, copy (low 4 bits)+3 bytes, distance = next data byte
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardLong	;opcode 9, count = 5 bits (low nibble and bit 7 of the next byte)+3, distance = (next byte bits 0-6)+1
	move.b	(a0),d0
	asl.b	#1,d0			;x = bit 7 of the next byte
	move.b	-1(a0),d0
	roxl.b	#1,d0
	andi.w	#$1F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardExtended1	;opcode A, count = 6 bits (low nibble and top 2 bits of the next byte)+3, distance = (next byte bits 0-5)+1
	move.b	-1(a0),d0
	asl.w	#8,d0
	move.b	(a0),d0
	lsr.w	#6,d0
	andi.w	#$3F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$3F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardExtended2	;opcode B, count = 7 bits (low nibble and top 3 bits of the next byte)+3, distance = (next byte bits 0-4)+1
	move.b	-1(a0),d0
	asl.w	#8,d0
	move.b	(a0),d0
	lsr.w	#5,d0
	andi.w	#$7F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$1F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun

Opcode_CopyBackwardReverseShort	;opcodes C-D, copy (bits 0-1)+2 bytes backwards through the source, distance (bits 2-4)+1
	move.b	-1(a0),d0
	andi.w	#3,d0
	addq.w	#1,d0
	move.b	-1(a0),d2
	lsr.w	#2,d2
	andi.w	#7,d2
	addq.w	#1,d2

CopyBackwardReverseRun	;shared reverse copy loop (source moves down), d0 = count-1, d2 = distance back. Entered from the CopyBackwardReverse Medium/Long handlers
	neg.b	d2
	add.b	d1,d2
.loop	move.b	(a1,d2.w),(a1,d1.w)
	subq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next	dbf	d0,.loop
	rts

Opcode_CopyBackwardReverseMedium	;opcode E, reverse copy (low 4 bits)+3 bytes, distance = next data byte. Distance 0 is the end code: flush what is left and return from DecompressBytecode
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bne.s	CopyBackwardReverseRun
	tst.w	d1			;end of data
	beq.w	.fin			;buffer empty
	bsr.w	FlushOutputBuffer
.fin	addq.w	#4,sp			;drop the return into DecompressBytecode
	movem.l	(sp)+,d0-d3/a0-a2
	rts

Opcode_CopyBackwardReverseLong	;opcode F, reverse copy, count and distance as Opcode_CopyBackwardLong
	move.b	(a0),d0
	asl.b	#1,d0
	move.b	-1(a0),d0
	roxl.b	#1,d0
	andi.w	#$1F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardReverseRun

FlushOutputBuffer	;send d1 bytes (0 = 256) of the ring buffer a1 to vram d3 and advance d3. (a4) = callbackPtr: set = remap with that table (jsr (a5)), clear = DoDMApro (jsr (a6))
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	d1,d0
	bne.w	.size
	move.w	#$100,d0		;full buffer
.size	lsr.w	#1,d0			;words
	move.w	d3,d1			;vram address
	add.w	d0,d3
	add.w	d0,d3
	movea.l	a1,a0
	tst.l	(a4)
	beq.w	.dma
	movea.l	(a4),a1			;remap table
	jsr	(a5)			;remap
	bra.w	.done
.dma	jsr	(a6)			;DoDMApro
.done	movem.l	(sp)+,d0-d1/a0-a1
	rts

xyVmMap	;use printx/y/m to set vram address. Returns a0 = Vdata. 93 saves d0-d2 and calls Vmaddr (92 branched to it)
	movem.l	d0-d2,-(sp)
	move.w	(printx).w,d0
	move.w	(printy).w,d1
	movea.w	#(VmMap1-M68K_RAM),a0
	adda.w	(printm).w,a0
	move.w	2(a0),d2		;map width shift
	asl.w	d2,d1
	add.w	d1,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	movem.l	(sp)+,d0-d2
	rts

eraser	;fill rectangle with char. d0/d1 = x/y size of rectangle, d2 = char word to fill with, printx/y/m define top left corner to start at
	movem.l	d0-d2/a0,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.w	d0-d1,-(sp)
.1	bsr.s	xyVmMap
	move.w	(sp),d0
	subq.w	#1,d0
.0	move.w	d2,(a0)
	dbf	d0,.0
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w		;31
	subq.w	#1,2(sp)
	bne.s	.1
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0
	rts

Framer	;frame and fill (uses framer.map graphics and assums tiles are already located at framercset). d0/d1 = x/y size of rectangle, printx/y/m define top left corner to start at
	movem.l	d0-d4/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.w	d0-d1,-(sp)
	move.w	(printa).w,d2
	add.w	(Framercset).w,d2
	movea.l	#Framermap,a1
	adda.l	4(a1),a1
	addq.w	#4,a1
	clr.w	d4
	bsr.w	.tbline

	subq.w	#3,2(sp)
.mtop	bsr.w	.tbline
	subq.w	#6,d4
	subq.w	#1,2(sp)
	bpl.s	.mtop
	addq.w	#6,d4
	bsr.w	.tbline
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d4/a0-a1
	rts

.tbline	bsr.w	xyVmMap
	addq.w	#1,(printy).w
	bsr.w	.setter
	addq.w	#2,d4
	move.w	4(sp),d0
	subq.w	#3,d0
.tblp	bsr.w	.setter
	dbf	d0,.tblp
	addq.w	#2,d4
	bsr.w	.setter
	addq.w	#2,d4
	rts

.setter	move.w	(a1,d4.w),d3
	add.w	d2,d3
	move.w	d3,(a0)
	rts

printsmallz	;see printsmall. String macro should follow the bsr/jsr to this routine; a1 is kept
	move.l	a1,-(sp)
	movea.l	4(sp),a1		;string after the call
	bsr.w	printsmall
	move.l	a1,4(sp)		;return past the string
	movea.l	(sp)+,a1
	rts

printsmall	;print string macro a1 at printx/y/m with printa. Bytes > 0 are chars ('@' = blank char $7FF, '^' = skip a column), tile = smallfontmap entry + smallfontchars[printfontset]. Bytes <= 0 run ControlCodeJumpTable entry -byte (0 = nothing)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2-a3,-(sp)
	movea.w	#(smallfontchars-M68K_RAM),a3	;char set bases, picked by printfontset
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3		;string length
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0
	ext.w	d0
	bgt.w	.nocom
	neg.w	d0			;control code (0 = padding)
	asl.w	#2,d0
	movea.l	#ControlCodeJumpTable,a2
	movea.l	(a2,d0.w),a2
	jsr	(a2)
	bra.w	.1

.nocom	cmp.b	#'@',d0
	bne.w	.noblank
	move.w	#$7FF,d0		;blank char (92 moveq #1)
	bra.w	.p
.noblank	cmp.b	#'^',d0
	beq.w	.skip
	asl.w	#1,d0
	movea.l	#smallfontmap,a2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0
	move.w	(printfontset).w,d1	;char set * 2
	add.w	(a3,d1.w),d0
.p	add.w	d2,d0			;for alternate paletes
	move.w	d0,(a0)
	addq.w	#1,(printx).w
.1	dbf	d3,.0
	movem.l	(sp)+,d0-d3/a0/a2-a3
	move.w	(sp)+,(disflags).w
	rts

.skip	addq.w	#1,(printx).w		;'^': skip a column
	bsr.w	xyVmMap
	bra.s	.1

ControlCodeJumpTable	;printsmall control codes, indexed by -byte
	dc.l	rtss				;0: padding, no-op
	dc.l	ControlCode_SetMap		;-1: map
	dc.l	ControlCode_SetAttribute	;-2: palette/priority
	dc.l	ControlCode_SetX		;-3: x
	dc.l	ControlCode_SetY		;-4: y
	dc.l	ControlCode_AddX		;-5: x offset
	dc.l	ControlCode_AddY		;-6: y offset
	dc.l	ControlCode_SetFont		;-7: char set
	dc.l	ControlCode_SetMapAndPosition	;-8: attribute, map, x, y

ControlCode_SetMapAndPosition	;printsmall code -8, next 4 bytes = attribute, map, x, y
	bsr.w	ControlCode_SetAttribute
	bsr.w	ControlCode_SetMap
	bsr.w	ControlCode_SetX
	bra.w	ControlCode_SetY

ControlCode_SetMap	;printsmall code -1, next byte = map number (1-3) -> printm
	move.b	(a1)+,d0
	subq.w	#1,d3
	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w
	bra.w	xyVmMap

ControlCode_SetAttribute	;printsmall code -2, next byte = palette/priority (0-7) -> printa bits 13-15 and d2
	move.b	(a1)+,d2
	andi.w	#7,d2
	subq.w	#1,d3
	ror.w	#3,d2
	move.w	d2,(printa).w
	rts

ControlCode_SetX	;printsmall code -3, next byte = printx
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printx).w
	bra.w	xyVmMap

ControlCode_SetY	;printsmall code -4, next byte = printy
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printy).w
	bra.w	xyVmMap

ControlCode_AddX	;printsmall code -5, add the next (signed) byte to printx
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printx).w
	bra.w	xyVmMap

ControlCode_AddY	;printsmall code -6, add the next (signed) byte to printy
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printy).w
	bra.w	xyVmMap

ControlCode_SetFont	;printsmall code -7, next byte = char set index (printfontset = index*2 into smallfontchars)
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	asl.w	#1,d0
	move.w	d0,(printfontset).w
	rts

printz	;see print. String macro should follow the bsr/jsr to this routine. 93 keeps a1 (92 popped the return into a1)
	move.l	a1,-(sp)
	movea.l	4(sp),a1		;string after the call
	bsr.w	print
	move.l	a1,4(sp)		;return past the string
	movea.l	(sp)+,a1
	rts

print	;a1 = string macro, printx/y = x/y cordinate on map for printing, printm = map to print on, printa = attribute for characters. string \-$ab,$xx,$yy,'Sample!'\ : a = map number (1-3), b = color/priority (0-3 = color fam, prio off),(4-7 = color fam, prio on), xx/yy = x/y cord to print at. 93: '@' = char $7FF, '^' = skip a column
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0
	beq.w	.1			;padding
	ext.w	d0
	bpl.w	.nocom
	neg.w	d0			;-$ab: new attribute, map, x, y
	move.w	d0,d2
	asl.w	#8,d2
	asl.w	#1,d2
	andi.w	#$F800,d2
	move.w	d2,(printa).w

	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w

	move.b	(a1)+,d0
	ext.w	d0
	move.w	d0,(printx).w
	move.b	(a1)+,d1
	ext.w	d1
	move.w	d1,(printy).w
	bsr.w	xyVmMap
	subq.w	#2,d3
	bra.w	.1

.nocom	cmp.b	#'@',d0
	bne.w	.noblank
	move.w	#$7FF,d0		;blank char (92 moveq #1)
	bra.w	.p
.noblank	cmp.b	#'^',d0		;(93)
	beq.w	.skip
	asl.w	#1,d0
	movea.l	#smallfontmap,a2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0
	add.w	(smallfontchars).w,d0
.p	add.w	d2,d0			;for alternate paletes
	move.w	d0,(a0)
	addq.w	#1,(printx).w
.1	dbf	d3,.0
	movem.l	(sp)+,d0-d3/a0/a2
	move.w	(sp)+,(disflags).w
	rts

.skip	addq.w	#1,(printx).w		;'^': skip a column
	bsr.w	xyVmMap
	bra.s	.1

FormatAndPrintTime	;print a period label and time. d0 bits 14-15 = period (PeriodLabelTable entry), bits 0-13 = seconds. Called from DisplayGameStatEntry and DisplayPenaltyEntry
	swap	d0
	clr.w	d0
	rol.l	#2,d0			;d0.w = period
	movea.l	#PeriodLabelTable,a1
	bsr.w	PrintStringFromList
	addq.w	#2,(printx).w
	swap	d0
	lsr.w	#2,d0			;seconds
	bsr.w	PushTime
	bra.w	print

PeriodLabelTable	;String list for FormatAndPrintTime: " 1", " 2", " 3", "OT"
	dc.w	4
	dc.b	' 1'
	dc.w	4
	dc.b	' 2'
	dc.w	4
	dc.b	' 3'
	dc.w	4
	dc.b	'OT'

PushTime	;convert d0 into string format of minutes:seconds. Return a1 = string. pads the minutes to 2 places with a space
	movea.w	#(mesarea+30-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)

	ext.l	d0
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0

	ext.l	d0
	divu.w	#6,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0

	move.b	#':',-(a1)

	ext.l	d0
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0

	move.b	#' ',-(a1)		;leading space
	tst.w	d0
	beq.w	.noz
	addi.w	#'0',d0
	move.b	d0,(a1)			;over the space (92 -(a1))
.noz	move.l	(sp)+,d0
	sub.l	a1,d0
	addq.w	#2,d0
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)
	addq.w	#1,d0
.1	move.w	d0,-(a1)
	move.l	(sp)+,d0
	rts

PushNumber	;convert d0 into string format of base 10 number, no leading zeros. Return a1 = string
	movea.w	#(PushNumberBuf-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)
.0	ext.l	d0
	divu.w	#10,d0
	swap	d0
	addi.w	#'0',d0
	move.b	d0,-(a1)
	swap	d0
	tst.w	d0
	bne.s	.0
	move.l	(sp)+,d0
	sub.l	a1,d0
	addq.w	#2,d0
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)
	addq.w	#1,d0
.1	move.w	d0,-(a1)
	move.l	(sp)+,d0
	rts

PushNumberWidth	;convert d0 into a d1 digit base 10 string, leading zeros as spaces (the last digit always shown). Return a1 = string at PushWidthBuf
	movem.l	d0-d3,-(sp)
	movea.w	#(PushWidthBuf+2-M68K_RAM),a1
	moveq	#1,d2
	sub.w	d2,d1
	bra.w	.pw
.mul	mulu.w	#10,d2
.pw	dbf	d1,.mul			;d2 = 10^(d1-1)
	moveq	#' ',d3			;leading fill
.dig	ext.l	d0
	divu.w	d2,d0
	bne.w	.digit
	cmp.w	#1,d2
	beq.w	.digit			;last digit: always a number
	move.w	d3,d0			;leading zero
	bra.w	.put
.digit	moveq	#'0',d3			;from here on zeros are digits
	add.w	d3,d0
.put	move.b	d0,(a1)+
	swap	d0
	divu.w	#10,d2
	bne.s	.dig
	move.l	a1,d0
	subi.w	#(PushWidthBuf-M68K_RAM),d0	;length incl. the length word
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even	movea.w	#(PushWidthBuf-M68K_RAM),a1
	move.w	d0,(a1)
	movem.l	(sp)+,d0-d3
	rts

appendz	;see appstring. String macro should follow the bsr/jsr to this routine
	movea.l	(sp)+,a1
	bsr.w	appstring
	jmp	(a1)

appstring	;append string a1 to string a3
	movem.l	d0/a0,-(sp)
	lea	2(a3),a0
	move.w	(a3),d0
	subq.w	#3,d0
	bmi.w	.1
.0	addq.w	#1,a0
	tst.b	(a0)
	dbeq	d0,.0
.1	move.w	(a1)+,d0
	subq.w	#3,d0
	bmi.w	.ex
.2	move.b	(a1)+,(a0)+
	bne.w	.3
	subq.w	#1,a0
.3	dbf	d0,.2
	move.l	a0,d0
	btst	#0,d0
	beq.w	.4
	clr.b	(a0)+
	addq.l	#1,d0
.4	sub.l	a3,d0
	move.w	d0,(a3)
.ex	movem.l	(sp)+,d0/a0
	rts

printbigz	;see print big. String macro should follow the bsr/jsr to this routine. 93 keeps a1 (92 popped the return into a1)
	move.l	a1,-(sp)
	movea.l	4(sp),a1		;string after the call
	bsr.w	printbig
	move.l	a1,4(sp)		;return past the string
	movea.l	(sp)+,a1
	rts

printbig	;same as print, only use bigfont.map graphics. a1 = string macro, printx/y = x/y cordinate on map for printing, printm = map to print on, printa = attribute for characters. string \-$ab,$xx,$yy,'Sample!'\ : a = map number (1-3), b = color/priority (0-3 = color fam, prio off),(4-7 = color fam, prio on), xx/yy = x/y cord to print at
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d7/a0/a2,-(sp)
	move.w	(printx).w,d4
	move.w	(printy).w,d5
	move.w	(printa).w,d6
	add.w	(BigFontChars).w,d6

	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1

.0	move.b	(a1)+,d0
	beq.w	.1
	ext.w	d0
	bpl.w	.nocom
	neg.w	d0
	move.w	d0,d6
	asl.w	#8,d6
	asl.w	#1,d6
	andi.w	#$F800,d6
	move.w	d6,(printa).w
	add.w	(BigFontChars).w,d6

	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w

	move.b	(a1)+,d4
	ext.w	d4
	move.w	d4,(printx).w
	move.b	(a1)+,d5
	ext.w	d5
	move.w	d5,(printy).w
	subq.w	#2,d3
	bra.w	.1

.nocom	cmp.b	#'a',d0
	blt.w	.2
	cmp.b	#'z',d0
	bgt.w	.2
	addi.b	#'A'-'a',d0
.2	move.w	d3,-(sp)
	bsr.w	.dochar
	move.w	(sp)+,d3
.1	dbf	d3,.0
	move.w	d4,(printx).w
	move.w	d5,(printy).w
	movem.l	(sp)+,d0-d7/a0/a2
	move.w	(sp)+,(disflags).w
	rts

.dochar	subi.w	#$20,d0			;93 has no 92 beq.space
	movea.l	#bfasciicon,a0
	moveq	#1,d2			;chars wide-1
	move.b	(a0,d0.w),d1		;brush offset
	ext.w	d1
	bpl.w	.p0
	neg.w	d1			;negative: one char wide
	clr.w	d2
.p0	asl.w	#1,d1
	movea.l	#bigfontmap,a0
	adda.l	4(a0),a0
.p1	move.w	4(a0,d1.w),d3
	bsr.w	.dump
	move.w	(a0),d7
	asl.w	#1,d7
	add.w	d7,d1
	move.w	4(a0,d1.w),d3
	sub.w	d7,d1
	addq.w	#1,d5
	bsr.w	.dump
	subq.w	#1,d5
	addq.w	#1,d4			;x char position
	addq.w	#2,d1
	dbf	d2,.p1
	rts

.dump	add.w	d6,d3
	movem.l	d1/a0,-(sp)
	move.w	d5,d0
	movea.l	#VmMap1,a0		;$FFFFB004
	adda.w	(printm).w,a0
	move.w	2(a0),d1
	asl.w	d1,d0
	add.w	d4,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	move.w	d3,(a0)
	movem.l	(sp)+,d1/a0
	rts

AddSmallFont	;transfer smallfont.map tiles to vram. d4 = char to start tiles at, return d4 = end of tiles + 1. 93 goes through DecompressGraphics
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bra.w	DoDMA_clearCallbackPointer

AddFramer	;transfer framer.map tiles to vram. d4 = char to start tiles at, return d4 = end of tiles + 1. 93 goes through DecompressGraphics
	movea.l	#FramerMap+8,a2
	move.w	d4,(Framercset).w
	bra.w	DoDMA_clearCallbackPointer

AddTeamBlock	;transfer TeamBlocks.map tiles to vram at char 2. Return d4 = end of tiles + 1. 93 goes through DecompressGraphics
	moveq	#2,d4
	movea.l	#Teamblocksmap+8,a2
	bra.w	DoDMA_clearCallbackPointer
