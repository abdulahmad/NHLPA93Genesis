;	NHLPA Hockey 93 (retail) segment $D62A-$DCE3
;	92 Middle.Asm part 1: remap, forceblack, forcefade, cramfade, the
;	93-only CopyPaletteToCRAM, randomd0s, randomd0, sroot, sfx, song,
;	waitx, IntermissionLoop (93 version of waitxsr), waitjoy, orjoy,
;	nodiag, the 93-only ProcessInputWithRepeat, Readjoy1, Readjoy2,
;	ReadJoy, jdtab, DoDMApro, DoDMA, the 93-only DoDMA_nd2 (vram copy),
;	DoFill, WaitDMA, setVram, setVram_0 and Vmaddr. Global names from the
;	IDA export, 92 names where the routine is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx),
;	so those sites are written as dc.w with the instruction in the comment.
;	disflags bits: df32c 1, dfng 2 (same as 92).

remap	;IDA: ConvertAndWriteToVDP. a0 = data (char set), d0 = size in words, d1 = vram dest, a1 = mapping data (93: two color nibbles per byte, high nibble for even colors). Jumped to from DecompressGraphics
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng
	movem.l	d0-d4/a0-a2,-(sp)
	dc.w	$C340			;exg	d1,d0 (keep EA register order)
	movea.l	a0,a2
	bsr.w	Vmaddr
	subq.w	#1,d1
.1	moveq	#3,d0			;IDA: process_word. 4 pixels per word
	move.w	(a2)+,d2
	clr.w	d3
.2	move.w	d2,d4			;IDA: process_nibble
	andi.w	#$F,d4
	lsr.w	#1,d4			;93: map byte = color/2
	move.b	(a1,d4.w),d4
	btst	#0,d2
	bne.w	.lo			;odd color: low nibble
	lsr.w	#4,d4			;even color: high nibble
.lo	andi.w	#$F,d4			;IDA: pack_nibble_into_output. (92 or.b 0(a1,d4),d3)
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
.0	move.l	(a0),-(sp)		;IDA: loc_D69E
	clr.l	(a0)+
	dbf	d0,.0
	move.w	#$18,(palcount).w	;24
	bsr.w	forcefade
	moveq	#$1F,d0
.1	move.l	(sp)+,-(a0)		;IDA: loc_D6B2
	dbf	d0,.1
	movem.l	(sp)+,d0/a0
	rts

forcefade	;regardless of interupts/disflags fade in new palettes, don't upset anything else. Called from forceblack and setVram
	move.w	sr,-(sp)
	move.l	(vbint).w,-(sp)
	move.w	(disflags).w,-(sp)
	bclr	#2,(disflags).w		;dfng
	move.l	#vb2,(vbint).l
	move.w	#$2500,sr
.1	tst.w	(palcount).w		;IDA: _1
	bpl.s	.1
	move.w	(sp)+,(disflags).w
	move.l	(sp)+,(vbint).w
	move.w	(sp)+,sr
	rts

cramfade	;fade from current color in color ram to color held in palfadenew. This should be called during vblank because palette changes punch holes in video. 93: palcount 100 copies the palette with no fade (CopyPaletteToCRAM)
	tst.w	(palcount).w
	bmi.w	rtss
	cmpi.w	#$64,(palcount).w	;93: 100 = copy now
	beq.w	CopyPaletteToCRAM
	subq.w	#1,(palcount).w
	bmi.w	rtss

	clr.l	d0
	move.w	(palcount).w,d0
	dc.w	$B07C,$0018		;cmp.w	#24,d0
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
.top	move.w	d3,d2			;IDA: _top

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
.nn	add.w	d2,d0			;IDA: _nn
	and.w	d4,d7
	or.w	d0,d7

	move.l	#$C000,d0
	move.b	d6,d0
	swap	d0
	move.l	d0,4(a0)		;cram write d6
	move.w	d7,(a0)

.next	addq.w	#2,d6			;IDA: _next
	dc.w	$BC7C,$0080		;cmp.w	#$80,d6
	bne.s	.top
	rts

CopyPaletteToCRAM	;93: copy all 64 palfadenew colors straight to color ram and set palcount = -1. Protected from vblank (dfng). Entered from cramfade (palcount 100), called from SetupStanleyCupCelebrationScreen
	movem.l	d0/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng
	movea.w	#(palfadenew-M68K_RAM),a1
	movea.l	#VDP_DATA,a0
	move.l	#$C0000000,4(a0)	;cram write 0
	moveq	#$1F,d0
.0	move.l	(a1)+,(a0)		;IDA: loc_D79E
	dbf	d0,.0
	st	(palcount).w		;fade done
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0/a0-a1
	rts

;middle of code routines------------------------------------
randomd0s	;IDA: sub_D7B2 (Rev A lst). d0 = range. Return d0 = random number (-range < d0 < range)
	move.w	d0,-(sp)
	asl.w	#1,d0
	bsr.w	randomd0
	sub.w	(sp)+,d0
	rts

randomd0	;d0 = range. Return random number in d0 (0 <= d0 < range)
	movem.l	d0-d2,-(sp)
	move.w	(StanleyCupTimer+2).w,d0	;seed+2 (92)
	move.w	d0,d1
	move.w	(StanleyCupTimer).w,d2		;seed
	mulu.w	#$E62D,d0
	mulu.w	#$BB40,d1
	mulu.w	#$E62D,d2
	add.w	d2,d1
	swap	d0
	add.w	d1,d0
	swap	d0
	addq.l	#1,d0
	move.l	d0,(StanleyCupTimer).w		;seed
	asr.l	#8,d0
	mulu.w	2(sp),d0
	swap	d0
	addq.w	#4,sp
	movem.l	(sp)+,d1-d2
	rts

sroot	;Square Root, this returns (d0.L)^.5 in d0. 93: values above $F00000 use a binary search
	tst.l	d0
	beq.w	rtss			;zero^.5 = zero
	dc.w	$B0BC,$0000,$0640	;cmp.l	#40*40,d0
	bhi.w	.m2
	move.l	d1,-(sp)		;find square root of d0
	moveq	#-1,d1
.0	addq.w	#2,d1			;IDA: loc_D80A
	sub.w	d1,d0
	bcc.s	.0
	lsr.w	#1,d1
	move.w	d1,d0
	move.l	(sp)+,d1
	rts

.m2	movem.l	d1-d4,-(sp)		;IDA: loc_D818. (92 d1-d3)
	moveq	#9,d3			;max number of reps
	move.w	#$8000,d1		;92 guess for big values, unused in 93
	dc.w	$B0BC,$00F0,$0000	;cmp.l	#$F00000,d0
	bhi.w	.big			;93: binary search (92 bhi .top)
	move.l	d0,d1
	lsr.l	#8,d1
	addq.w	#2,d1
.top	move.w	d1,d2			;IDA: loc_D832
	move.l	d0,d1
	divu.w	d2,d1
	add.w	d2,d1
	lsr.w	#1,d1
	cmp.w	d1,d2
	dbeq	d3,.top
.done	move.w	d1,d0			;IDA: loc_D842
	movem.l	(sp)+,d1-d4
	rts

.big	moveq	#0,d1			;IDA: loc_D84A. 93: d1 = low, d2 = high ($FFFF)
	moveq	#-1,d2
.bs	move.w	d1,d3			;IDA: loc_D84E. d3 = (low+high)/2, carry shifted back in
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
.lo	move.w	d4,d1			;IDA: loc_D866
	bra.s	.bs

sfx	;play sound effect number. One word passed on stack
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0		;16*4(a7)
	bmi.w	.none
	move.w	d0,(lastsfx).w
	jsr	(play_sfx_or_music_track).l	;(92 p_initfx)
.none	movem.l	(sp)+,d0-d7/a0-a6	;IDA: sfx_none
	move.l	(sp),2(sp)
	addq.w	#2,sp
	rts

song	;IDA: SFX (Rev A lst). play song number. One word passed on stack
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0		;16*4(a7)
	bmi.w	.none
	jsr	(play_sfx_or_music_track).l	;(92 p_initune)
.none	movem.l	(sp)+,d0-d7/a0-a6	;IDA: _none
	move.l	(sp),2(sp)
	addq.w	#2,sp
	rts

waitx	;wait d0 vblanks or until input from either joystick. Return joystick variables (d0-d3) if any. Called from ScoutingReport and SetupStanleyCupCelebrationScreen
	neg.w	d0
	move.w	d0,(vcount).w
.wait	bsr.w	Readjoy1		;IDA: _wait
	tst.w	d1
	bne.w	rtss
	bsr.w	Readjoy2
	tst.w	d1
	bne.w	rtss
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0		;IDA: _0
	beq.s	.0
	tst.w	d0
	bmi.s	.wait
	rts

IntermissionLoop	;93 version of 92 waitxsr: wait d0 vblanks while the zamboni crosses (zamx counts up to $708) and the crowd updates. A key on either pad (sflags bit 1 = pad 2) leaves at least 120 frames and goes to HandleMenuInput; eq from it exits with d1 bit 7 set. Called from Intermission
	movem.l	d4-d7/a0-a3,-(sp)
	neg.w	d0
	move.w	d0,(vcount).w
.wait	cmpi.w	#$708,(zamx).w		;IDA: loc_D8E2. (92 tst zamx / bmi .nz)
	bhi.w	.nz
	addq.w	#1,(zamx).w
.nz	moveq	#1,d7			;IDA: loc_D8F0. one elapsed frame
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
.key	move.w	(vcount).w,d0		;IDA: loc_D91E
	dc.w	$B07C,$FF88		;cmp.w	#-120,d0
	blt.w	.menu			;more than 120 frames left: keep them
	moveq	#-$78,d0		;else wait 120 more
.menu	movem.w	d0,-(sp)		;IDA: loc_D92C
	bsr.w	HandleMenuInput
	bne.w	.resume
	addq.w	#2,sp
	bset	#7,d1
	bra.w	.ex
.resume	move.w	(sp)+,(vcount).w	;IDA: loc_D942
.vid	bsr.w	setvideo		;IDA: loc_D946
	move.w	(vcount).w,d0
.0	cmp.w	(vcount).w,d0		;IDA: loc_D94E
	beq.s	.0
	tst.w	d0
	bmi.s	.wait
.ex	movem.l	(sp)+,d4-d7/a0-a3	;IDA: loc_D958
	rts

waitjoy	;wait for either joystick input. Return d1 = new button presses. IDA left it as data (no caller found)
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
.0	clr.w	d5			;IDA: loc_D98E
	bset	d4,d5
	cmp.w	d5,d0
	dbeq	d4,.0
	beq.w	.ok
	andi.w	#$FFF0,d1
.ok	movem.l	(sp)+,d0/d4-d5		;IDA: loc_D9A0
	rts

ProcessInputWithRepeat	;93: nodiag, then key repeat on d1-d3 from Readjoy1/2. A change (d2) resets the delay to 15 frames; while the same buttons stay held, every 4 frames return d1 = held buttons (d3). Called from Pausemode, menus and IntermissionLoop
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
.chg	move.w	#$F,(repeatdelayframes).w	;IDA: loc_D9C6. first repeat delay
	rts

Readjoy1	;read controller 1. Return d0 = direction (bit 0-3) and new button (bit 4-7) presses, d1 = new presses (all 8 bits), d2 = changed buttons (all 8), d3 = current held buttons (all 8)
	move.l	a0,-(sp)
	movea.l	#$A10003,a0		;Joy1
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
	movea.l	#$A10005,a0		;Joy2
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
.z	dbf	d1,.z			;IDA: loc_DA28
	move.w	#$100,(IO_Z80BUS).l	;turn off z80
	move.b	(a0),d0
	move.b	#$40,(a0)
	move.w	#0,(IO_Z80BUS).l	;turn on z80

	asl.b	#2,d0
	andi.b	#%11000000,d0
	move.w	#10,d1
.zz	dbf	d1,.zz			;IDA: loc_DA4C
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
	movea.l	#jdtab,a0		;(Rev A literal $DA88)
	move.b	(a0,d1.w),d1
	or.w	d1,d0
	move.w	(sp)+,d1
	rts

jdtab	;convert buttons l,r,d,u into directions 0-7,8
	dc.b	8,0,4,8,6,7,5,8,2,1,3,8,8,8,8,8

DoDMApro	;IDA: loc_DA98 (Rev A lst). initiate dma transfer and protect from vblank interuption. d0 = words to transfer, d1 = initial vram address, a0 = address to transfer from. Jumped to from DecompressGraphics
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng
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
.dd	movem.l	d2/a1,-(sp)		;IDA: DoDMA_dd
.nd	lea	(VDP_CTRL).l,a1		;IDA: _nd. set d0 = num of words
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

	move.l	d0,(dword_FFCAEA).w	;dmaram
	move.w	(dword_FFCAEA+2).w,(a1)
	move.w	(dword_FFCAEA).w,(a1)

	bsr.w	WaitDMA
	move.w	#$8164,(a1)		;$8100+%01100100
	movem.l	(sp)+,d2/a1
	rts

DoDMA_nd2	;93: vram to vram copy by dma (reg 23 = $C0), protected from vblank. d0 = length, d2 = source vram address, d1 = destination vram address. Auto inc 1 during the copy, then 2 again. Called from CopyTeamBlockMapData and ScrollDisplayUp
	movem.l	d0-d3/a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng
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
.0	move.l	d3,(a1)			;IDA: loc_DBD8
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
.0	move.w	d0,(a0)+		;IDA: _0
	dbf	d1,.0
	move.w	#$18,(palcount).w	;24
	bsr.w	forcefade

setVram_0	;second half of 92 setVram (no fade): clear vram and set the VDP registers from disflags, Map1col, VmMap1-3, VSPRITES and VSCRLPM. Falls in from setVram, called from SetupStanleyCupCelebrationScreen
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w		;dfng
	move.w	#$8F02,(VDP_CTRL).l	;VmInc 2
	clr.w	d0
	bsr.w	Vmaddr
	move.w	#$3FFF,d0
	clr.l	d1
.9	move.l	d1,(a0)			;IDA: _9
	dbf	d0,.9

	move.w	#$8C00,d0		;8 for shadow mode
	btst	#1,(disflags).w		;df32c
	bne.w	.i32
	ori.w	#$81,d0			;%10000001
.i32	move.w	d0,4(a0)		;IDA: _i32. 40 column mode, no interlace, normal brightness

	move.w	#$8004,4(a0)		;512 color palette enable
	move.w	#$8164,4(a0)		;$8100+%01100100

	move.w	#$9001,d0		;Playfield is 64x32
	cmpi.w	#6,(Map1col).w
	beq.w	.i64
	move.w	#$9003,d0
.i64	move.w	d0,4(a0)		;IDA: _i64

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
