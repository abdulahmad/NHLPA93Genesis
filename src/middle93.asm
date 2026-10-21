;	Shared helpers used all over the game: palette fades, random numbers and square roots, sound requests,
;	joypad reads, DMA and vram fills, vdp setup and bitmap drawing (dobitmap).
;
;	decompress93.asm and print93.asm are included at the end of this file.

UnpackNibbles						;a0 = packed data, d0 = count. Unpacks d0 4-bit values (high nibble first)
									;into words at nibblebuffer. Called from PickStartingGoalie
	movem.l	d0-d2/a0-a1,-(sp)		;save
	movea.w	#(nibblebuffer-M68K_RAM),a1	;a1 = output words
	clr.w	d2						;d2 bit 0 = which nibble is next
	bra.w	.next					;start
.loop	move.b	(a0)+,d1			;next nibble (one count per pass)
	bchg	#0,d2					;toggle high/low nibble
	bne.w	.lo						;low nibble?
	subq.w	#1,a0					;high nibble: read the same byte again next time
	lsr.w	#4,d1					;high nibble down
.lo	andi.w	#$F,d1					;keep one nibble
	move.w	d1,(a1)+				;store it
.next	dbf	d0,.loop				;loop count in d0
	movem.l	(sp)+,d0-d2/a0-a1		;restore
	rts

WeightedRandomSelect				;from 92 SetScore .getscore. d0 = number of word weights at nibblebuffer.
									;Return d0 = random index, picked with those weights. Called from
									;SetScore_getscore and PickStartingGoalie
	movem.l	d1/a1,-(sp)				;save
	movea.w	#(nibblebuffer-M68K_RAM),a1	;weights
	clr.w	d1						;d1 = running total of the weights
	bra.w	.next
.sum	add.w	(a1)+,d1			;add the next weight
.next	dbf	d0,.sum					;loop over the weights
	move.w	d1,d0					;d0 = total weight
	bsr.w	randomd0				;d0 = random 0 <= d0 < total
.find	sub.w	-(a1),d0			;walk back from the last weight
	bpl.s	.find					;still >= 0: this weight is not the one
	suba.w	#(nibblebuffer-M68K_RAM),a1	;minus the start
	move.w	a1,d0					;byte offset
	lsr.w	#1,d0					;word offset -> index
	movem.l	(sp)+,d1/a1				;restore
	rts

remap								;a0 = data (char set), d0 = size in words, d1 = vram dest, a1 = mapping
									;data (two color nibbles per byte, high nibble for even colors). Jumped to
									;from DecompressGraphics
	move.w	(disflags).w,-(sp)		;save the flags
	bset	#dfng,(disflags).w		;no graphics
	movem.l	d0-d4/a0-a2,-(sp)		;save
	exg	d1,d0						;(keep EA register order)
	movea.l	a0,a2					;a2 = source tile words
	bsr.w	Vmaddr					;set vram write address; a0 = Vdata
	subq.w	#1,d1					;d1 = word count - 1
.1	moveq	#3,d0					;4 pixels per word (one pass per source word)
	move.w	(a2)+,d2				;source word
	clr.w	d3						;d3 = remapped word being built
.2	move.w	d2,d4					;one pixel (low nibble of d2) per pass
	andi.w	#$F,d4					;4 bits
	lsr.w	#1,d4					;map byte = color/2
	move.b	(a1,d4.w),d4
	btst	#0,d2					;odd color?
	bne.w	.lo						;odd color: low nibble
	lsr.w	#4,d4					;even color: high nibble
.lo	andi.w	#$F,d4					;(92 or.b 0(a1,d4),d3)
	or.b	d4,d3					;put the new color into the result
	ror.w	#4,d3					;into the top
	ror.w	#4,d2					;next pixel
	dbf	d0,.2
	move.w	d3,(a0)					;write the word to vram
	dbf	d1,.1						;loop
	movem.l	(sp)+,d0-d4/a0-a2		;restore
	move.w	(sp)+,(disflags).w		;restore the flags
	rts

forceblack							;fade all colors to black but don't upset palfadenew
	movem.l	d0/a0,-(sp)				;save
	movea.w	#(palfadenew-M68K_RAM),a0	;palette fade target
	moveq	#$1F,d0					;31
.0	move.l	(a0),-(sp)				;save the target palette while blacking it
	clr.l	(a0)+					;black
	dbf	d0,.0						;loop
	move.w	#$18,(palcount).w		;24
	bsr.w	forcefade				;fade to the all-black palfadenew
	moveq	#$1F,d0					;32 longs
.1	move.l	(sp)+,-(a0)				;put the saved palette back (reverse order)
	dbf	d0,.1						;loop
	movem.l	(sp)+,d0/a0				;restore
	rts

forcefade							;regardless of interupts/disflags fade in new palettes, don't upset
									;anything else. Called from forceblack and setVram
	move.w	sr,-(sp)				;save sr, vblank handler and disflags
	move.l	(VBint).w,-(sp)			;save the vblank routine
	move.w	(disflags).w,-(sp)		;save the flags
	bclr	#dfng,(disflags).w		;graphics on
	move.l	#vb2,(VBint).l			;minimal vblank handler (vb2) that runs the fade
	move.w	#$2500,sr				;enable vblank interrupts (mask level 5)
.1	tst.w	(palcount).w			;wait until the fade has finished (palcount < 0)
	bpl.s	.1						;loop
	move.w	(sp)+,(disflags).w		;restore the flags
	move.l	(sp)+,(VBint).w			;restore the vblank routine
	move.w	(sp)+,sr
	rts

cramfade							;fade from current color in color ram to color held in palfadenew. This
									;should be called during vblank because palette changes punch holes in
									;video. palcount 100 copies the palette with no fade (CopyPaletteToCRAM)
	tst.w	(palcount).w			;fading?
	bmi.w	rtss					;negative = no fade running
	cmpi.w	#$64,(palcount).w		;100 = copy now
	beq.w	CopyPaletteToCRAM		;yes
	subq.w	#1,(palcount).w			;count down
	bmi.w	rtss

	;palcount 24..0 counts the fade down; each step moves one of the three color
	;components (red, green, blue = shift 0/4/8) by one level, chosen by palcount mod 3
	clr.l	d0						;clear
	move.w	(palcount).w,d0
	cmp.w	#24,d0
	bgt.w	rtss					;above 24: nothing to do yet
	divu.w	#3,d0
	swap	d0						;d0 = palcount mod 3
	asl.w	#2,d0					;shifter 0/4/8
	moveq	#2,d3					;d3 = one step of the component (2 << shift)
	asl.w	d0,d3					;step into place
	moveq	#$E,d5					;d5 = component mask ($E << shift)
	asl.w	d0,d5					;mask into place
	move.w	d5,d4					;copy
	not.w	d4						;d4 = mask of the other components
	movea.l	#palfadenew,a1			;a1 = destination colors
	movea.l	#Vdata,a0				;Vdata
	clr.w	d6						;d6 = cram address, 2 per color
.top	move.w	d3,d2				;d2 = signed step for this color

	move.w	d6,d0					;cram address
	swap	d0						;to the high word
	move.w	#$20,d0					;cram read
	move.l	d0,4(a0)				;cram read d6
	move.w	(a0),d7					;current color

	move.w	d7,d0					;current color
	and.w	d5,d0					;this component
	move.w	(a1)+,d1				;dest color
	and.w	d5,d1					;target component
	cmp.w	d1,d0					;same?
	beq.w	.next					;component already at target
	blt.w	.nn						;below target: step up
	neg.w	d2						;above target: step down
.nn	add.w	d2,d0					;apply the step to the component
	and.w	d4,d7					;other components
	or.w	d0,d7					;merge the new component into the color

	move.l	#$C000,d0				;cram write
	move.b	d6,d0					;address
	swap	d0						;to the high word
	move.l	d0,4(a0)				;cram write d6
	move.w	d7,(a0)					;write the color

.next	addq.w	#2,d6				;next color
	cmp.w	#$80,d6					;64 colors done?
	bne.s	.top					;loop
	rts

CopyPaletteToCRAM					;copy all 64 palfadenew colors straight to color ram and set palcount =
									;-1. Protected from vblank. Entered from cramfade (palcount 100), called
									;from
									;SetupStanleyCupCelebrationScreen
	movem.l	d0/a0-a1,-(sp)			;save
	move.w	(disflags).w,-(sp)		;save the flags
	bset	#dfng,(disflags).w		;no graphics
	movea.w	#(palfadenew-M68K_RAM),a1	;palette
	movea.l	#Vdata,a0				;vdp data port
	move.l	#CRAM_W,4(a0)			;cram write 0
	moveq	#$1F,d0					;32 longs = 64 colors
.0	move.l	(a1)+,(a0)				;two colors per long
	dbf	d0,.0						;loop
	st	(palcount).w				;fade done
	move.w	(sp)+,(disflags).w		;restore the flags
	movem.l	(sp)+,d0/a0-a1			;restore
	rts

;middle of code routines------------------------------------
randomd0s							;d0 = range. Return d0 = random number (-range < d0 < range)
	move.w	d0,-(sp)				;save the range
	asl.w	#1,d0					;range*2
	bsr.w	randomd0				;0 .. 2*range-1
	sub.w	(sp)+,d0				;shift down to -range+1 .. range-1
	rts

randomd0							;d0 = range. Return random number in d0 (0 <= d0 < range)
	movem.l	d0-d2,-(sp)				;2(sp) = range (the saved d0 low word)
	;32-bit linear congruential generator: seed = seed * $BB40E62D + 1 (built from 16-bit mulu)
	move.w	(seed+2).w,d0			;seed+2 (92)
	move.w	d0,d1					;seed low
	move.w	(seed).w,d2				;seed
	mulu.w	#$E62D,d0
	mulu.w	#$BB40,d1
	mulu.w	#$E62D,d2
	add.w	d2,d1					;add the cross term
	swap	d0						;to the high word
	add.w	d1,d0					;add it
	swap	d0						;back
	addq.l	#1,d0					;plus 1
	move.l	d0,(seed).w				;seed
	;scale: take bits 8-23 of the new seed, times the range (saved d0 at 2(sp)), high word
	asr.l	#8,d0					;/ 256
	mulu.w	2(sp),d0				;times the range
	swap	d0						;d0 = result 0 <= d0 < range
	addq.w	#4,sp					;skip the saved d0 so the result survives
	movem.l	(sp)+,d1-d2				;restore
	rts

Sroot								;Square Root, this returns (d0.L)^.5 in d0. Large values use a binary
									;search
	tst.l	d0						;zero?
	beq.w	rtss					;zero^.5 = zero
	cmp.l	#40*40,d0
	bhi.w	.m2						;large value: Newton iteration / binary search below
	move.l	d1,-(sp)				;find square root of d0
	moveq	#-1,d1					;small value: subtract successive odd numbers (1,3,5,..)
.0	addq.w	#2,d1					;next odd number
	sub.w	d1,d0					;minus the odd number
	bcc.s	.0						;loop
	lsr.w	#1,d1					;d1 = 2*root+1 -> root
	move.w	d1,d0					;root
	move.l	(sp)+,d1				;restore
	rts

.m2	movem.l	d1-d4,-(sp)				;(92 d1-d3)
	moveq	#9,d3					;max number of reps
	move.w	#$8000,d1				;unused (92 guess for big values)
	cmp.l	#$F00000,d0
	bhi.w	.big					;too big for divu: binary search
	move.l	d0,d1					;value
	lsr.l	#8,d1					;first guess = d0/256 + 2
	addq.w	#2,d1					;plus 2
.top	move.w	d1,d2				;Newton step: d1 = (d0/guess + guess)/2
	move.l	d0,d1					;value
	divu.w	d2,d1					;/ guess
	add.w	d2,d1					;plus the guess
	lsr.w	#1,d1					;/ 2
	cmp.w	d1,d2					;stop when the guess stops changing, or after 10 steps
	dbeq	d3,.top					;loop
.done	move.w	d1,d0				;d1 = root (shared exit of both methods)
	movem.l	(sp)+,d1-d4				;restore
	rts

.big	moveq	#0,d1				;d1 = low, d2 = high ($FFFF)
	moveq	#-1,d2
.bs	move.w	d1,d3					;d3 = (low+high)/2, carry shifted back in
	add.w	d2,d3					;low + high
	roxr.w	#1,d3					;/ 2
	cmp.w	d3,d1					;same as low?
	beq.s	.done					;no step left: d1 is the root
	move.w	d3,d4					;save mid
	mulu.w	d3,d3					;squared
	cmp.l	d3,d0					;compare
	bcc.w	.lo						;d0 >= mid^2: raise low
	move.w	d4,d2					;else lower high
	bra.s	.bs						;loop
.lo	move.w	d4,d1					;low = mid
	bra.s	.bs

sfxarg		=	16*4				;sfx / song: stack offset of the number word after the movem
sfx									;play sound effect number. One word passed on stack
	movem.l	d0-d7/a0-a6,-(sp)		;sfxarg(sp) = the number word (above 15 longs and the return address)
	clr.l	d0						;clear
	move.w	sfxarg(sp),d0			;sound number
	bmi.w	.none					;negative = no sound
	move.w	d0,(lastsfx).w			;remember the last effect
	jsr	(play_sfx_or_music_track).l	;play it
.none	movem.l	(sp)+,d0-d7/a0-a6	;restore registers
	move.l	(sp),2(sp)				;slide the return address over the argument word
	addq.w	#2,sp					;(callee pops its own argument)
	rts

song								;play song number. One word passed on stack
	movem.l	d0-d7/a0-a6,-(sp)		;sfxarg(sp) = the number word (above 15 longs and the return address)
	clr.l	d0						;clear
	move.w	sfxarg(sp),d0			;sound number
	bmi.w	.none					;negative = no song
	jsr	(play_sfx_or_music_track).l	;same call as sfx, without lastsfx
.none	movem.l	(sp)+,d0-d7/a0-a6	;restore registers
	move.l	(sp),2(sp)				;drop the argument word, as in sfx
	addq.w	#2,sp					;drop the number word
	rts

waitx								;wait d0 vblanks or until input from either joystick. Return joystick
									;variables (d0-d3) if any. Called from ScoutingReport and
									;SetupStanleyCupCelebrationScreen
	neg.w	d0						;Vcount counts up from -d0 to 0
	move.w	d0,(Vcount).w			;frame counter
.wait	bsr.w	ReadJoy1			;either pad with a new press ends the wait
	tst.w	d1						;any press?
	bne.w	rtss
	bsr.w	ReadJoy2				;read pad 2
	tst.w	d1						;any press?
	bne.w	rtss
	move.w	(Vcount).w,d0			;frame counter
.0	cmp.w	(Vcount).w,d0			;wait for the next vblank to change Vcount
	beq.s	.0						;wait for a new frame
	tst.w	d0						;time left?
	bmi.s	.wait					;still counting up to zero
	rts

waitxsr								;d0 vblanks while the zamboni crosses (Zamx counts up to $708) and the
									;crowd updates. A key on either pad (sflags bit 1 = pad 2) leaves at least
									;120 frames and goes to HandleMenuInput; eq from it exits with d1 bit 7
									;set. Called from Intermission
	movem.l	d4-d7/a0-a3,-(sp)		;save
	neg.w	d0						;Vcount counts up from -d0 to 0
	move.w	d0,(Vcount).w			;frame counter
.wait	cmpi.w	#$708,(Zamx).w		;(92 tst Zamx / bmi.nz)
	bhi.w	.nz						;zamboni past $708: stop moving it
	addq.w	#1,(Zamx).w				;move it
.nz	moveq	#1,d7					;one elapsed frame
	bsr.w	updatecrowdf			;animate the crowd
	bclr	#sfpj,(sflags).w		;pad 1
	bsr.w	ReadJoy1				;read it
	bsr.w	ProcessInputWithRepeat
	tst.w	d1						;any press?
	bne.w	.key					;yes
	bset	#sfpj,(sflags).w		;pad 2
	bsr.w	ReadJoy2				;read it
	bsr.w	ProcessInputWithRepeat
	tst.w	d1						;any press?
	beq.w	.vid					;no key on either pad
.key	move.w	(Vcount).w,d0		;a key was pressed: d0 = frames left (negative)
	cmp.w	#-120,d0
	blt.w	.menu					;more than 120 frames left: keep them
	moveq	#-$78,d0				;else wait 120 more
.menu	movem.w	d0,-(sp)			;keep the new frame count while the menu runs
	bsr.w	HandleMenuInput
	bne.w	.resume					;menu did not end the screen: carry on waiting
	addq.w	#2,sp					;drop it
	bset	#7,d1					;tell the caller the menu ended it
	bra.w	.ex						;exit
.resume	move.w	(sp)+,(Vcount).w	;restore the frame count
.vid	bsr.w	setvideo			;update video for this frame
	move.w	(Vcount).w,d0			;frame counter
.0	cmp.w	(Vcount).w,d0			;wait for the next vblank
	beq.s	.0						;wait for a new frame
	tst.w	d0						;time left?
	bmi.s	.wait
.ex	movem.l	(sp)+,d4-d7/a0-a3		;exit
	rts

waitjoy								;wait for either joystick input. Return d1 = new button presses. it as
									;data (no caller found)
	move.w	(Vcount).w,d0			;frame counter
.0	cmp.w	(Vcount).w,d0			;wait one vblank
	beq.s	.0						;wait for a new frame
	bsr.w	orjoy					;read the pads
	beq.s	waitjoy					;no new press: wait again
	rts

orjoy								;return d1 = new button presses from either joystick
	bsr.w	ReadJoy1				;pad 1
	move.w	d1,-(sp)				;pad 1 new presses
	bsr.w	ReadJoy2				;pad 2
	or.w	(sp)+,d1				;combine with pad 2
	rts

nodiag								;eliminate diagonal direction presses: if held directions (d3 bits 0-3)
									;are not one direction, clear the d1 direction bits
	movem.l	d0/d4-d5,-(sp)			;save
	moveq	#3,d4					;d4 = direction bit 3..0
	move.w	d3,d0					;held
	andi.w	#$F,d0					;held directions
	beq.w	.ok						;none held
.0	clr.w	d5						;test each single-bit direction against the held set
	bset	d4,d5					;single direction bit
	cmp.w	d5,d0					;matches?
	dbeq	d4,.0					;loop
	beq.w	.ok						;exactly one direction held
	andi.w	#$FFF0,d1				;diagonal: drop the direction presses
.ok	movem.l	(sp)+,d0/d4-d5			;done
	rts

ProcessInputWithRepeat				;nodiag, then key repeat on d1-d3 from ReadJoy1/2. A change (d2) resets
									;the delay to 15 frames; while the same buttons stay held, every 4 frames
									;return d1 = held buttons (d3).
									;Called from Pausemode, menus and IntermissionLoop
	bsr.s	nodiag					;no diagonals
	tst.w	d3						;anything held?
	beq.w	rtss					;nothing held
	tst.w	d2						;changed?
	bne.w	.chg					;buttons changed: restart the delay
	subq.w	#1,(repeatdelayframes).w	;count down
	bpl.w	rtss					;delay not over yet
	move.w	#4,(repeatdelayframes).w	;repeat rate
	move.w	d3,d1					;repeat the held buttons
	rts
.chg	move.w	#$F,(repeatdelayframes).w	;first repeat delay
	rts

	IF REV=2
ReadJoy1							;read controller 1 from the byte ReadPads left in PadRaw1. Return d0 =
									;direction (bit 0-3) and new button (bit 4-7) presses, d1 = new presses
									;(all 8 bits), d2 = changed buttons (all 8), d3 = held buttons (all 8)
	move.b	(PadRaw1).w,d0
	bsr.w	ReadJoy					;d1 = buttons down now
	move.w	(lj1).w,d2				;last frame's buttons
	move.w	d1,(lj1).w				;store it
	move.w	d1,d3					;d3 = held
	eor.w	d1,d2					;d2 = changed
	and.w	d2,d1					;d1 = changed and now down = new presses
	rts

ReadJoy2							;read controller 2 from PadRaw2 (same as ReadJoy1 with lj2)
	move.b	(PadRaw2).w,d0
	bsr.w	ReadJoy					;read it
	move.w	(lj2).w,d2				;last state
	move.w	d1,(lj2).w				;store the new one
	move.w	d1,d3					;d3 = held
	eor.w	d1,d2					;changed bits
	and.w	d2,d1					;d1 = new presses
	rts

ReadJoy								;translate a raw controller byte d0 (active low). Return d0 = direction
									;(bit 0-3) and new button (bit 4-7) presses, d1 = buttons down (all 8)
	not.b	d0						;now active high
	clr.w	d1
	move.b	d0,d1
	move.w	d1,-(sp)				;keep all buttons for d1
	andi.w	#$F0,d0					;d0 = button bits (4-7)
	andi.w	#$F,d1					;d1 = direction bits
	lea	(jdtab).l,a0
	move.b	(a0,d1.w),d1			;translate to direction 0-7 (8 = none)
	or.w	d1,d0					;d0 = buttons + direction code
	move.w	(sp)+,d1
	rts

	ELSE
ReadJoy1							;read controller 1. Return d0 = direction (bit 0-3) and new button (bit
									;4-7) presses, d1 = new presses (all 8 bits), d2 = changed buttons (all
									;8), d3 = current held buttons (all 8)
	move.l	a0,-(sp)
	movea.l	#Joy1,a0
	bsr.w	ReadJoy					;d1 = buttons down now
	movea.l	(sp)+,a0
	move.w	(lj1).w,d2				;last frame's buttons
	move.w	d1,(lj1).w
	move.w	d1,d3					;d3 = held
	eor.w	d1,d2					;d2 = changed
	and.w	d2,d1					;d1 = changed and now down = new presses
	rts

ReadJoy2							;read controller 2. Return d0 = direction (bit 0-3) and new button (bit
									;4-7) presses, d1 = new presses (all 8 bits), d2 = changed buttons (all
									;8), d3 = current held buttons (all 8)
	move.l	a0,-(sp)
	movea.l	#Joy2,a0
	bsr.w	ReadJoy					;same as ReadJoy1 with lj2
	movea.l	(sp)+,a0
	move.w	(lj2).w,d2
	move.w	d1,(lj2).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts

ReadJoy								;read controller a0. Return d0 = direction (bit 0-3) and new button (bit
									;4-7) presses, d1 = buttons down (all 8 bits)
	move.w	#$100,(IO_Z80BUS).l		;turn off z80
	move.b	#$40,6(a0)				;control port: TH as output
	move.b	#0,(a0)					;TH low: the next read gives start and A
	move.w	#0,(IO_Z80BUS).l		;turn on z80
	move.w	#10,d1
.z	dbf	d1,.z						;let the pad settle
	move.w	#$100,(IO_Z80BUS).l		;turn off z80
	move.b	(a0),d0					;TH low read: bit 5 = start, bit 4 = A
	move.b	#$40,(a0)				;TH high for the next read
	move.w	#0,(IO_Z80BUS).l		;turn on z80

	asl.b	#2,d0					;start/A up to bits 7-6
	andi.b	#%11000000,d0
	move.w	#10,d1
.zz	dbf	d1,.zz						;settle delay
	move.w	#$100,(IO_Z80BUS).l		;turn off z80
	move.b	(a0),d1					;TH high read: bits 0-3 up/down/left/right, bit 4 = B, bit 5 = C
	move.w	#0,(IO_Z80BUS).l		;turn on z80
	andi.b	#%00111111,d1
	or.b	d1,d0					;d0 = 8 button bits, active low
	not.b	d0						;now active high
	clr.w	d1						;clear
	move.b	d0,d1					;copy
	move.w	d1,-(sp)				;keep all buttons for d1
	andi.w	#$F0,d0					;d0 = button bits (4-7)
	andi.w	#$F,d1					;d1 = direction bits
	movea.l	#jdtab,a0				;direction table
	move.b	(a0,d1.w),d1			;translate to direction 0-7 (8 = none)
	or.w	d1,d0					;d0 = buttons + direction code
	move.w	(sp)+,d1				;restore
	rts

	ENDIF

jdtab								;convert buttons l,r,d,u into directions 0-7,8
	dc.b	8,0,4,8,6,7,5,8,2,1,3,8,8,8,8,8

DoDMApro							;initiate dma transfer and protect from vblank interuption. d0 = words to
									;transfer, d1 = initial vram address, a0 = address to transfer from.
									;Jumped to from DecompressGraphics
	move.w	(disflags).w,-(sp)		;save the flags
	bset	#dfng,(disflags).w		;no graphics
	bsr.w	DoDMA					;DMA it
	move.w	(sp)+,(disflags).w		;restore the flags
	rts

DoDMA								;initiate dma transfer (dma transfer bug is compensated for). d0 = words
									;to transfer, d1 = destination vram address, a0 = source address
	IF REV=2
	movem.l	d2-d3/a1,-(sp)			;save
	ELSE
	movem.l	d2/a1,-(sp)
	ENDIF
	move.w	d0,d2					;word count
	add.w	d2,d2					;length in bytes
	add.w	a0,d2					;carry out = source+length crosses a 64k boundary
	bcc.w	.nd						;no boundary crossed
	beq.w	.nd						;ends exactly on the boundary: one transfer
	lsr.w	#1,d2					;do two transfers if source address crosses 64k boundary
	sub.w	d2,d0					;d0 = words before the boundary, d2 = words after it
	move.w	d0,-(sp)				;save
	bsr.w	.dd						;first part
	move.w	(sp)+,d0				;restore
	add.w	d0,d0					;advance vram dest and source by the words done
	add.w	d0,d1					;plus the bytes done
	adda.w	d0,a0
	move.w	d2,d0					;second part: the rest, falls into .nd
	bra.w	.nd						;second part
.dd	IF REV=2						;first part entry: save the registers its rts pops
	movem.l	d2-d3/a1,-(sp)			;entry for the first part (so its rts pops the same registers)
	ELSE
	movem.l	d2/a1,-(sp)				;entry for the first part (so its rts pops the same registers)
	ENDIF
.nd	lea	(Vctrl).l,a1				;set d0 = num of words
	move.w	#$8154,(a1)				;$8100+%01010100
	move.w	#$8F02,(a1)				;d1 = video address
	move.w	#$9300,d2				;a0 = source address
	move.b	d0,d2					;reg 19: length low
	move.w	d2,(a1)					;set it
	move.w	#$9400,d2				;reg 20
	lsr.w	#8,d0					;high byte
	move.b	d0,d2					;reg 20: length high
	move.w	d2,(a1)					;set it
	move.l	a0,d0					;source
	lsr.l	#1,d0					;source in words
	move.w	#$9500,d2				;reg 21
	move.b	d0,d2					;reg 21: source low
	move.w	d2,(a1)					;set it
	lsr.l	#8,d0					;next byte
	move.w	#$9600,d2				;reg 22
	move.b	d0,d2					;reg 22: source mid
	move.w	d2,(a1)					;set it
	lsr.l	#8,d0					;next byte
	andi.b	#$7F,d0					;7 bits
	move.w	#$9700,d2				;reg 23
	move.b	d0,d2					;reg 23: source high (dma mode bits 7-6 = 0: 68k to vram)
	move.w	d2,(a1)					;set it

	clr.l	d0						;clear
	move.w	d1,d0					;build the vdp command long for a vram write with dma
	asl.l	#2,d0					;address bits up
	lsr.w	#2,d0					;back
	IF REV=2
	move.l	d0,d3					;Rev B: keep the plain address for the ram source fix below
	ori.l	#$804000,d0				;low word: vram write command + address, high word: dma bit ($0080)
	move.l	d0,(dmaram).w			;the last command word is written from ram (dma bug workaround)
	move.w	sr,-(sp)
	move.w	#$2700,sr				;no interrupt while the Z80 is off the bus
	move.w	#$100,(IO_Z80BUS).l		;turn off z80
.zw	btst	#0,(IO_Z80BUS).l		;wait for the Z80 to give up the bus
	bne.b	.zw
	move.w	(dmaram+2).w,(a1)		;command word 1
	move.w	(dmaram).w,(a1)			;this write starts the dma
	bsr.w	WaitDMA					;wait for the DMA
	move.w	#$8164,(a1)				;$8100+%01100100: vblank int back on, dma off
	clr.w	(IO_Z80BUS).l			;turn on z80
	cmpa.w	#0,a0					;ram source?
	bge.w	.ok						;a source in ram: the first word is lost, so write it again by hand
	ori.w	#$4000,d3				;vram write
	swap	d3						;to the high word
	andi.w	#3,d3					;address bits 14-15
	move.l	d3,(a1)					;vram write command, no dma
	move.w	(a0),-4(a1)				;write the first word again
.ok	move.w	(sp)+,sr				;restore the interrupt level
	movem.l	(sp)+,d2-d3/a1			;restore
	rts
	ELSE
	ori.l	#$804000,d0				;low word: vram write command + address, high word: dma bit ($0080)

	move.l	d0,(dmaram).w			;the last command word is written from ram (dma bug workaround)
	move.w	(dmaram+2).w,(a1)
	move.w	(dmaram).w,(a1)			;this write starts the dma

	bsr.w	WaitDMA
	move.w	#$8164,(a1)				;$8100+%01100100: vblank int back on, dma off (during the transfer $54 =
									;vint off, dma on)
	movem.l	(sp)+,d2/a1
	rts
	ENDIF

DoDMA_nd2							;vram to vram copy by dma (reg 23 = $C0), protected from vblank. d0 =
									;length, d2 = source vram address, d1 = destination vram address. Auto inc
									;1 during the copy, then 2 again. Called from CopyTeamBlockMapData and
									;ScrollDisplayUp
	movem.l	d0-d3/a1,-(sp)			;save
	move.w	(disflags).w,-(sp)		;save the flags
	bset	#dfng,(disflags).w		;no graphics
	lea	(Vctrl).l,a1				;vdp control port
	move.w	#$8154,(a1)				;$8100+%01010100: vint off, dma on
	move.w	#$8F01,(a1)				;auto inc 1
	move.w	#$9300,d3				;length low
	move.b	d0,d3					;low byte
	move.w	d3,(a1)					;set it
	move.w	#$9400,d3				;length high
	lsr.w	#8,d0					;high byte
	move.b	d0,d3
	move.w	d3,(a1)					;set it
	move.w	#$9500,d3				;source low
	move.b	d2,d3					;low byte
	move.w	d3,(a1)					;set it
	move.w	#$9600,d3				;source high
	lsr.w	#8,d2					;high byte
	move.b	d2,d3
	move.w	d3,(a1)					;set it
	move.w	#$97C0,(a1)				;dma mode: vram copy
	clr.l	d0						;clear
	move.w	d1,d0					;destination address -> vdp command (address bits 14-15 go to the second
									;word)
	asl.l	#2,d0					;address bits up
	lsr.w	#2,d0					;back
	swap	d0						;to the high word
	ori.w	#$C0,d0					;vram copy command
	IF REV=2
	move.l	d0,(dmaram).w			;save the command
	move.w	#$100,(IO_Z80BUS).l		;turn off z80
.zw	btst	#0,(IO_Z80BUS).l		;wait for the Z80 to give up the bus
	bne.b	.zw
	move.w	(dmaram).w,(a1)			;command word 0
	move.w	(dmaram+2).w,(a1)		;command word 1
	bsr.w	WaitDMA					;wait for the DMA
	move.w	#$8164,(a1)
	move.w	#$8F02,(a1)
	clr.w	(IO_Z80BUS).l			;turn on z80
	ELSE
	move.l	d0,(a1)
	bsr.w	WaitDMA
	move.w	#$8164,(a1)				;$8100+%01100100
	move.w	#$8F02,(a1)				;auto inc 2
	ENDIF
	move.w	(sp)+,(disflags).w		;restore the flags
	movem.l	(sp)+,d0-d3/a1			;restore
	rts

DoFill								;fill vram. d0 = words to fill, d1 = vram address, d2 = data to fill with
	movem.l	d3/a1,-(sp)				;save
	movea.l	#Vdata,a1				;Vdata
	andi.l	#$FFFF,d1				;word
	asl.l	#2,d1					;build the vram write command for address d1
	lsr.w	#2,d1					;back
	ori.w	#$4000,d1				;vram write
	swap	d1						;to the high word
	move.l	d1,4(a1)				;set vram write address
	move.w	d2,d3					;fill word
	swap	d3						;to the high word
	move.w	d2,d3					;d3 = fill word twice, for long writes
	lsr.w	#1,d0					;words -> longs
	subq.w	#1,d0					;minus 1
.0	IF REV=2						;loop: fill one long
	move.l	d3,(dmaram).w			;Rev B writes the long from ram, as DoDMA does
	move.w	(dmaram).w,(a1)			;first word
	move.w	(dmaram+2).w,(a1)		;second word
	ELSE
	move.l	d3,(a1)					;two words per write
	ENDIF
	dbf	d0,.0						;loop
	movem.l	(sp)+,d3/a1				;restore
	rts

WaitDMA								;wait for dma completion
	move.w	(Vctrl).l,-(sp)			;read the vdp status; 1(sp) is its low byte
	btst	#1,1(sp)				;status bit 1 = dma busy
	addq.w	#2,sp					;drop it
	bne.s	WaitDMA					;busy: wait
	rts

setVram								;initialize all necesary video parameters based on my variables. d0 =
									;color to fade to. Falls into setVram_0
	movea.w	#(palfadenew-M68K_RAM),a0	;palette fade target
	moveq	#$3F,d1					;63
.0	move.w	d0,(a0)+				;fill the 64 target colors with d0
	dbf	d1,.0						;loop
	move.w	#$18,(palcount).w		;24
	bsr.w	forcefade				;fade the screen to that color

setVram_0							;from 92 setVram second half. second half of setVram without the fade:
									;clear vram and set the VDP registers from disflags, Map1col, VmMAP1-3,
									;VSPRITES and VSCRLPM. Falls in from setVram, called from
									;SetupStanleyCupCelebrationScreen
	move.w	(disflags).w,-(sp)		;save the flags
	bset	#dfng,(disflags).w		;no graphics
	move.w	#$8F02,(Vctrl).l		;VmInc 2
	clr.w	d0						;address 0
	bsr.w	Vmaddr					;vram address 0, a0 = Vdata
	move.w	#$3FFF,d0				;$4000 longs = all 64k of vram
	clr.l	d1						;clear
.9	move.l	d1,(a0)					;clear vram
	dbf	d0,.9						;loop

	move.w	#$8C00,d0				;8 for shadow mode
	btst	#df32c,(disflags).w
	bne.w	.i32					;32 column flag set: leave bits 0 and 7 clear
	ori.w	#$81,d0					;%10000001
.i32	move.w	d0,4(a0)			;reg 12: 40 column mode (unless df32c), no interlace, normal brightness

	move.w	#$8004,4(a0)			;512 color palette enable
	move.w	#$8164,4(a0)			;$8100+%01100100

	move.w	#$9001,d0				;Playfield is 64x32
	cmpi.w	#6,(Map1col).w			;64 wide?
	beq.w	.i64					;Map1col 6 = 64 columns wide
	move.w	#$9003,d0				;otherwise 128x32
.i64	move.w	d0,4(a0)			;reg 16: scroll plane size

	move.w	#$8200,d0				;reg 2: map 1 address
	move.b	(VmMAP1).w,d0			;address
	lsr.b	#2,d0					;/ 1024
	andi.b	#%00111000,d0
	move.w	d0,4(a0)				;reg 2: plane A name table address from VmMAP1

	move.w	#$8400,d0				;reg 4: map 2 address
	move.b	(VmMAP2).w,d0			;address
	lsr.b	#5,d0					;/ 8192
	move.w	d0,4(a0)				;reg 4: plane B name table address from VmMAP2

	move.w	#$8300,d0				;reg 3: map 3 address
	move.b	(VmMAP3).w,d0			;address
	lsr.b	#2,d0					;/ 1024
	andi.b	#%00111110,d0
	move.w	d0,4(a0)				;reg 3: window name table address from VmMAP3

	move.w	#$8500,d0				;reg 5: sprite table
	move.b	(VSPRITES).w,d0			;address
	lsr.b	#1,d0					;/ 512
	move.w	d0,4(a0)				;reg 5: sprite attribute table address

	move.w	#$8D00,d0				;reg $D: scroll table
	move.b	(VSCRLPM).w,d0			;address
	lsr.b	#2,d0					;/ 1024
	move.w	d0,4(a0)				;reg 13: horizontal scroll table address

	move.w	#$9100,4(a0)			;disable plane 3 graphics
	move.w	#$9200,4(a0)			;disable plane 3 graphics
	move.w	#$8700,4(a0)			;Palette # 0 is border/transparent.
	move.w	#$8B00,4(a0)			;Scroll mode. (entire scroll)

	move.l	#VSRAM_W,4(a0)			;vsram write 0
	move.l	#0,(a0)					;vertical scroll 0 for playfield 1/2
	move.w	(sp)+,(disflags).w		;restore the flags
	rts

Vmaddr								;set video port to address d0. d0 = vram address, returns a0 = Vdata!!!
	movea.l	#Vdata,a0				;vdp data port
	asl.l	#2,d0					;split the address: bits 0-13 in the first word, 14-15 in the second
	lsr.w	#2,d0					;back
	ori.w	#$4000,d0				;vram write command
	swap	d0						;to the high word
	andi.w	#3,d0					;address bits 14-15
	move.l	d0,4(a0)				;write to the control port
	rts


dobitmap							;transfer palette data/map data/tiles data to vram. a0 = palette, a1 =
									;map, a2 = tiles (DecompressGraphics data), d0 = start x, d1 = start y, d2
									;= width x, d3 = width y, d4 = start char, d5 = pal used bits (0-3) for
									;color fam 1-4. printy is restored and the tiles go last through
									;DecompressGraphics (returns d4 = end char)
	move.w	(printy).w,-(sp)		;keep printy
	move.w	(disflags).w,-(sp)		;save the flags
	bset	#dfng,(disflags).w		;no graphics
	movem.l	d0-d3/d5-d6/a0-a3,-(sp)	;2(sp) start x, $A(sp) width x, $E(sp) width y (low words of d0, d2, d3)
	move.w	d1,d6					;y start in d6 (92 used 6(a7))
	movea.w	#(palfadenew-M68K_RAM),a3	;a3 = target palette, a0 = palette data
	bra.w	.00						;start
.01	move.b	(a0,d0.w),(a3,d0.w)		;copy one 32 byte palette line backwards
	dbf	d0,.01						;loop
.02	adda.w	#$20,a0					;next palette line (source and target)
	adda.w	#$20,a3
.00	moveq	#$1F,d0					;31
	lsr.w	#1,d5					;d5 bit n = copy palette line n; stop when no bits left
	bcs.s	.01						;copy this line
	bne.s	.02						;skip this line

	move.w	(printa).w,d5			;d5 = tile attribute bits (priority/palette/flip) from printa
	andi.w	#$F800,d5				;attribute bits
	move.w	$E(sp),d2				;width y
	subq.w	#1,d2					;minus 1

.loop2	bsr.w	xyVmMap				;set vram address from printx/printy/printm, a0 = Vdata
	move.w	d6,d0					;y start
	mulu.w	(a1),d0					;map width
	add.w	2(sp),d0				;x start
	asl.w	#1,d0					;d0 = byte offset of the first map word wanted
	move.w	$A(sp),d1				;width x
	subq.w	#1,d1					;minus 1
.loop1	move.w	4(a1,d0.w),d3		;map word (map data starts 4 bytes in)
	add.w	d4,d3					;add the start char
	eor.w	d5,d3					;xor the attribute bits
	move.w	d3,(a0)					;write the name table entry
	addq.w	#2,d0					;next word
	dbf	d1,.loop1
	addq.w	#1,(printy).w			;next row
	addq.w	#1,d6					;next row
	dbf	d2,.loop2
	bsr.w	DecompressGraphicsPlain	;tiles a2 to char d4
	movem.l	(sp)+,d0-d3/d5-d6/a0-a3	;restore
	move.w	(sp)+,(disflags).w		;restore the flags
	move.w	(sp)+,(printy).w		;restore printy
	rts

	include decompress93.asm		;$00DD68-$00DF8D DecompressGraphicsWithCallback ...
	;FlushOutputBuffer (new in 93)
	include print93.asm				;$00DF8E-$00E525 xyVmMap ... AddTeamBlock
