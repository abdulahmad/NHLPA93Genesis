;	NHLPA Hockey 93 (retail) segment $165D8-$16E52
;	68k side of the 93 sound driver, p_turnoff ... ClearAllTrackAndSFXSlots. No NHL 92 source: 92 used a
;	different driver (NHL92Genesis/src/sound/sound.asm). Only the entry names p_turnoff, p_music_vblank and
;	p_initialZ80 are shared with 92 (92 headers: audio stop, vblank handler, initialization).
;	Global names from the IDA export (see the SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	The Z80 program (Z80_Program_Code) starts at $16E52: p_initialZ80 loads movea.l #$16E52. Its first
;	byte is the last byte of this segment; the rest of the Z80 blob and the sound data are not covered.
;	RAM from $CAEE up is 4 bytes lower in retail than in ram_addrs.inc (Rev A): retail has no
;	music_global_tick_counter / music_tick_divider words (see p_music_vblank). Every driver variable is
;	written as the retail number with the Rev A name in the comment.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real
;	cmp; fixopcodes.js patches the encoding after assembly.
;	Data seen in the bytes:
;	  track slots $CDC0 (8 x 6 bytes): +0 long event pointer (negative = free or ended), +4 word delay
;	    count (+5 = the delay byte read from the stream). Slot n (from $CDC0) is track 7-n.
;	  channel structs $CD9C (6 x 6 bytes, the 6th at $CDBA is the PCM channel): +0 key (midi channel*8 +
;	    track), +1 note, +2 patch, +3 output channel (0,1,2,4,5,6), +4 age (+1 each frame), +5 bit 0 on.
;	  voice table $CB9C (8 bytes per key): +0 word pitch bend (value - $2000), +3 patch.
;	  command buffer $CB7A (33 bytes, copied to Z80 RAM $02-$22): +0 key off bits, +1 key on bits,
;	    +2 volume bits, +3 frequency bits, +4 patch bits (one bit per output channel), $CB7F 7 volume
;	    bytes, $CB86 7 frequency words, $CB94 7 patch bytes. $CB78 = buffer changed flag.
;	  events (4 bytes): +0 delay before this event, +1 status (bits 6-4 command, bits 3-0 channel),
;	    +2/+3 data. Status 0 ends the stream; a non-negative long at +2 is a loop pointer.

p_turnoff	;92 name (audio stop). Silence everything: free all slots, key off and mute every output
		;channel, send the buffer and stop the PCM channel. Called from Begin, StartPer, game screens
	movem.l	d0-d7/a0-a2,-(sp)
	bsr.w	ClearAllTrackAndSFXSlots
	move.b	#$77,($FFFFCB7A).w	;retail Z80_command_buffer (Rev A: $CB7E). key off channels 0-2, 4-6
	move.b	#$77,($FFFFCB7C).w	;retail Z80_command_buffer+2 (Rev A: $CB80). volume change on 0-2, 4-6
	moveq	#6,d0			;7 volume bytes
	movea.w	#$CB7F,a0		;retail per_channel_attenuation_table (Rev A: $CB83)
.att	move.b	#$7F,(a0)+		;IDA: clear_attenuation_loop. $7F = silent
	dbf	d0,.att
	bsr.w	UploadCommandBufferToZ80
	bsr.w	ClearZ80SpecialEffectsFlags
	movem.l	(sp)+,d0-d7/a0-a2
	rts

play_sfx_or_music_track	;start sound d0 (0-$37) in a track slot. $30 and up are songs: the song already
			;playing is stopped first. Does the jobs of 92 p_initfx / p_initune; called from sfx and song
	cmp.w	#$37,d0
	bgt.w	rtss			;out of range
	movem.l	d0-d3/a0-a2,-(sp)
	cmp.w	#$30,d0
	blt.w	.slot			;sound effect
	bsr.w	play_new_song		;song: stop the current song
.slot	movea.w	#$CDC0,a1		;IDA: play_sfx_in_oldest_channel. retail fm_track_slots (Rev A: $CDC4)
	moveq	#7,d3
.new	move.l	(a1),d1			;IDA: find_loop. new lowest pointer
	move.w	d3,d2			;its track number
	movea.w	a1,a2
.chk	cmp.l	(a1),d1			;IDA: check_loop
	bgt.s	.new			;lower (signed) pointer here: take this slot
	addq.w	#6,a1
	dbf	d3,.chk
	tst.w	(a2)
	bpl.w	.ex			;IDA: prepare_new_track. no free slot (lowest pointer is in use): do nothing
	asl.w	#1,d0
	movea.l	#MusicTrackPointerTable,a0
	adda.w	(a0,d0.w),a0		;start of the event stream
	move.l	a0,(a2)
	clr.w	4(a2)
	move.b	(a0),5(a2)		;first delay
	movea.w	#$CB9C,a0		;retail fm_voice_usage_table (Rev A: $CBA0)
	asl.w	#3,d2
	adda.w	d2,a0
	moveq	#7,d0			;the 8 midi channels of this track
.clrv	clr.w	(a0)			;IDA: clear_voice_usage. no pitch bend
	clr.b	2(a0)
	clr.b	3(a0)			;patch 0
	adda.w	#$40,a0			;next channel (8 keys of 8 bytes)
	dbf	d0,.clrv
.ex	movem.l	(sp)+,d0-d3/a0-a2	;IDA: prepare_new_track
	rts

play_new_song	;stop the song in progress: free the first slot whose pointer is at or past the first song
		;($30) data and key off its channels. Called from play_sfx_or_music_track and checkgoal
	movem.l	d0-d3/a0-a3,-(sp)
	movea.w	#$CDC0,a1		;retail fm_track_slots (Rev A: $CDC4)
	moveq	#7,d3
	movea.l	#MusicTrackPointerTable,a0
	adda.w	$60(a0),a0		;sound $30 data
.find	cmpa.l	(a1),a0			;IDA: find_matching_slot
	addq.w	#6,a1
	dble	d3,.find		;until a slot pointer >= the song data
	bgt.w	.ex			;none: no song playing
	move.l	#$FFFFFFFF,-6(a1)	;free the slot
	moveq	#6,d1
	movea.w	#$CD9C,a2		;retail fm_channel_structs (Rev A: $CDA0)
.kill	move.b	(a2),d2			;IDA: kill_channel_loop
	andi.w	#7,d2			;track of the key
	cmp.w	d2,d3
	bne.w	.next			;IDA: next_channel. another track
	bsr.w	ReleaseChannelAndNote
	move.b	3(a2),d0		;output channel
	bset	d0,($FFFFCB7C).w	;retail Z80_command_buffer+2 (Rev A: $CB80). volume change
	movea.w	#$CB7F,a1		;retail per_channel_attenuation_table (Rev A: $CB83)
	move.b	#$7F,(a1,d0.w)		;silent
.next	addq.w	#6,a2			;IDA: next_channel
	dbf	d1,.kill
	bsr.w	UploadCommandBufferToZ80
.ex	movem.l	(sp)+,d0-d3/a0-a3	;IDA: exit_force_kill
	rts

p_music_vblank	;92 name (vblank handler). Clear the change bits, run the 8 track slots (d7 = track 7-0),
		;send the buffer if anything changed and age the channels. Called every frame from the vblank
		;handlers. Rev A runs the slots again every 6th frame while music_global_tick_counter ($CAEE)
		;is set (music_tick_divider $CAF0); retail has no such block (22 bytes shorter)
	clr.b	($FFFFCB78).w		;retail music_needs_z80_update (Rev A: $CB7C)
	clr.l	($FFFFCB7A).w		;retail Z80_command_buffer (Rev A: $CB7E). key off/on, volume, frequency bits
	clr.b	($FFFFCB7E).w		;retail Z80_command_buffer_plus2 (Rev A: $CB82). patch bits
	movea.w	#$CDC0,a5		;retail fm_track_slots (Rev A: $CDC4)
	moveq	#7,d7
.slot	bsr.w	ProcessOneMusicTrack	;IDA: process_music_slot
	addq.w	#6,a5
	dbf	d7,.slot
	tst.b	($FFFFCB78).w		;retail music_needs_z80_update (Rev A: $CB7C)
	beq.w	.age			;IDA: update_sfx_aging. nothing changed
	bsr.w	UploadCommandBufferToZ80
.age	movea.w	#$CD9C,a0		;IDA: update_sfx_aging. retail fm_channel_structs (Rev A: $CDA0)
	moveq	#5,d0
.ageloop	addq.b	#1,4(a0)		;IDA: sfx_priority_aging
	bne.w	.next			;IDA: no_overflow
	subq.b	#1,4(a0)		;hold at $FF
.next	addq.w	#6,a0			;IDA: no_overflow
	dbf	d0,.ageloop
	rts

z80_bus_release_delay	;Z80 busy: give the bus back, wait, then falls into UploadCommandBufferToZ80 to retry
	clr.w	(IO_Z80BUS).l
	moveq	#$64,d0
.delay	dbf	d0,.delay		;IDA: short_delay_loop

UploadCommandBufferToZ80	;copy the 33-byte command buffer to Z80 RAM $02 once the Z80 is idle
			;($97 = 0, $96 = $7D), and post command $D1. Called after any change
	move.w	#$100,(IO_Z80BUS).l	;request the Z80 bus
	movea.l	#$A00000,a0		;Z80_RAM
	cmpi.b	#0,$97(a0)
	bne.s	z80_bus_release_delay	;busy
	cmpi.b	#$7D,$96(a0)
	bne.s	z80_bus_release_delay	;not idle
	move.b	#$D1,$96(a0)		;command
	move.b	#0,$97(a0)
	adda.w	#2,a0
	movea.w	#$CB7A,a1		;retail Z80_command_buffer (Rev A: $CB7E)
	moveq	#$20,d0			;33 bytes
.copy	move.b	(a1)+,(a0)+		;IDA: copy_command_buffer
	dbf	d0,.copy
	clr.w	(IO_Z80BUS).l
	rts

ProcessOneMusicTrack	;count down track slot a5 (track d7) and run every event that is due. Called from p_music_vblank
	subq.w	#1,4(a5)
	bpl.w	rtss			;not due yet
.event	tst.w	(a5)			;IDA: process_next_event
	bmi.w	rtss			;slot free or ended
	movea.l	(a5),a0
	addq.l	#4,(a5)
	clr.w	4(a5)
	move.b	4(a0),5(a5)		;delay before the next event
	move.b	1(a0),d0
	bne.w	.cmd			;IDA: loc_167C6
	st	(a5)			;status 0: end of stream
	tst.w	2(a0)
	bmi.w	rtss
	move.l	2(a0),(a5)		;loop pointer
	bra.s	.event
.cmd	move.b	1(a0),d0		;IDA: loc_167C6
	andi.w	#$70,d0			;command number * 16
	lsr.w	#3,d0			;word index
	lea	command_jump_table(pc),a2
	adda.w	(a2,d0.w),a2
	jsr	(a2)
	bra.s	ProcessOneMusicTrack	;the next event may be due now (delay 0)

command_jump_table	;event handlers by status bits 6-4, as offsets from the table (IDA dc.b)
	dc.w	handle_command_00-command_jump_table
	dc.w	handle_command_10-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_40-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_60-command_jump_table
	dc.w	handle_command_skip-command_jump_table

handle_command_00	;event $0x: key off note +2 on channel +1 bits 3-0 of track d7. Also entered from
			;handle_command_10 for volume 0. Falls into ReleaseChannelAndNote
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0			;key
	asl.w	#8,d0
	move.b	2(a0),d0		;key and note, as in channel struct +0/+1
	movea.w	#$CDC0,a2		;retail fm_track_slots (Rev A: $CDC4). end of the channel structs
	moveq	#5,d1
.find	subq.w	#6,a2			;IDA: search_channel_loop
	cmp.w	(a2),d0
	dbeq	d1,.find
	bne.w	rtss			;not playing
	btst	#0,5(a2)
	dbne	d1,.find		;matched but already off: keep looking
	beq.w	rtss

ReleaseChannelAndNote	;key off channel struct a2 if it is on. The PCM patches ($60 up) stop the PCM channel
			;instead. Called from play_new_song
	bclr	#0,5(a2)
	beq.w	rtss			;was off
	cmpi.b	#$60,2(a2)
	bge.w	ClearZ80SpecialEffectsFlags	;PCM patch
	move.b	3(a2),d0		;output channel
	bset	d0,($FFFFCB7A).w	;retail Z80_command_buffer (Rev A: $CB7E). key off
	st	($FFFFCB78).w		;retail music_needs_z80_update (Rev A: $CB7C)
	rts

ClearZ80SpecialEffectsFlags	;clear Z80 RAM $8E (the PCM rate byte written by UpdateChannelFrequencyAndVolume).
			;Called from p_turnoff and for a PCM key off
	move.w	#$100,(IO_Z80BUS).l
	clr.b	($A0008E).l		;Z80_RAM_plus8E
	clr.w	(IO_Z80BUS).l
	rts

handle_command_10	;event $1x: key on note +2 at volume +3 on channel +1 bits 3-0 of track d7 (volume 0 =
			;key off). Patches $60 up play on the PCM channel. Falls into UpdateChannelFrequencyAndVolume
	tst.b	3(a0)
	beq.s	handle_command_00	;volume 0: key off
	movea.w	#$CDBA,a2		;retail unk_FFCDBE (Rev A: $CDBE). 6th channel struct
	movea.w	#$CB9C,a3		;retail fm_voice_usage_table (Rev A: $CBA0)
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0			;key
	move.w	d0,d6
	asl.w	#3,d0
	move.b	3(a3,d0.w),d0		;patch of this key
	cmp.b	#$60,d0
	bge.w	.pcm			;IDA: loc_1692A. PCM patch
	moveq	#4,d1
	bra.w	.setold			;IDA: loc_1688E
.old	cmp.b	4(a2),d2		;IDA: loc_16886
	bhi.w	.nextold		;IDA: loc_16894. a4 is older
.setold	movea.w	a2,a4			;IDA: loc_1688E. a4 = oldest channel so far, d2 = its age
	move.b	4(a4),d2
.nextold	subq.w	#6,a2			;IDA: loc_16894
	dbf	d1,.old
	moveq	#4,d1
	movea.w	#$CDBA,a2		;retail unk_FFCDBE (Rev A: $CDBE)
.free	subq.w	#6,a2			;IDA: loc_168A0
	btst	#0,5(a2)
	dbeq	d1,.free		;skip channels that are on
	bne.w	.patch			;IDA: loc_168BE. none off: take the oldest (a4)
	movea.w	a2,a4			;a4 = this off channel
	cmp.b	2(a2),d0
	dbeq	d1,.free		;look for an off channel that has the patch already
	beq.w	.keyon			;IDA: loc_168DA. found: no patch change
.patch	movea.w	a4,a2			;IDA: loc_168BE
	move.b	d0,2(a2)		;new patch
	clr.w	d1
	move.b	3(a2),d1		;output channel
	bset	d1,($FFFFCB7E).w	;retail Z80_command_buffer_plus2 (Rev A: $CB82). patch change
	movea.w	#$CB94,a4		;retail unk_FFCB98 (Rev A: $CB98). patch bytes
	move.b	d0,(a4,d1.w)
	st	($FFFFCB78).w		;retail music_needs_z80_update (Rev A: $CB7C)
.keyon	clr.b	4(a2)			;IDA: loc_168DA. age 0
	bset	#0,5(a2)		;on
	move.b	d6,(a2)			;key
	clr.w	d3
	move.b	2(a0),d3
	move.b	d3,1(a2)		;note
	clr.w	d1
	move.b	3(a2),d1		;output channel
	bset	d1,($FFFFCB7B).w	;retail Z80_command_buffer+1 (Rev A: $CB7F). key on
	lea	.veltab(pc),a4
	clr.w	d0
	move.b	3(a0),d0
	lsr.w	#3,d0			;volume / 8
	move.b	(a4,d0.w),d0
	movea.w	#$CB7F,a4		;retail per_channel_attenuation_table (Rev A: $CB83)
	move.b	d0,(a4,d1.w)
	bset	d1,($FFFFCB7C).w	;retail Z80_command_buffer+2 (Rev A: $CB80). volume change
	bra.w	UpdateChannelFrequencyAndVolume
.veltab	dc.b	$1A,$18,$16,$14,$12,$10,$0E,$0C,$0A,$08,$06,$04,$03,$02,$01,$00	;IDA: unk_1691A. attenuation by volume/8
.pcm	bset	#0,5(a2)		;IDA: loc_1692A. a2 = the PCM channel
	beq.w	.pcmon			;IDA: loc_1693C. it was off
	cmp.b	2(a2),d0
	ble.w	rtss			;a sample with the same or a higher patch number is playing
.pcmon	move.b	d0,2(a2)		;IDA: loc_1693C
	movea.w	#$CDBA,a2		;retail unk_FFCDBE (Rev A: $CDBE)
	clr.b	4(a2)
	move.b	d6,(a2)			;key
	move.b	2(a0),1(a2)		;note
	ext.w	d0
	subi.w	#$60,d0
	asl.w	#3,d0			;8 bytes per sample
	lea	unk_1710C(pc),a1
	move.l	4(a1,d0.w),d1
	move.l	(a1,d0.w),d0
	move.w	#$100,(IO_Z80BUS).l
	movea.l	#$A00000,a1		;Z80_RAM
	move.b	d0,$25(a1)		;first long to Z80 $23-$25, high byte first
	lsr.w	#8,d0
	move.b	d0,$24(a1)
	swap	d0
	move.b	d0,$23(a1)
	move.b	d1,$28(a1)		;second long to Z80 $26-$28
	lsr.w	#8,d1
	move.b	d1,$27(a1)
	swap	d1
	move.b	d1,$26(a1)
	move.b	3(a0),d1
	lsr.b	#2,d1			;volume / 4
	cmp.w	#3,d1
	bgt.w	.rate			;IDA: loc_169A2
	moveq	#3,d1			;at least 3
.rate	move.b	d1,$83(a1)		;IDA: loc_169A2
	move.b	#$29,$96(a1)		;command $29
	move.b	#0,$97(a1)
	clr.w	(IO_Z80BUS).l

UpdateChannelFrequencyAndVolume	;set the frequency of channel struct a2 from its note and the pitch bend of
			;its key (a3 = voice table). Called from handle_command_60, entered from handle_command_10
	clr.l	d3
	move.b	1(a2),d3		;note
	divu.w	#$C,d3			;d3 = octave, high word = note in the octave
	move.w	d3,-(sp)
	swap	d3
	add.w	d3,d3
	lea	.fnum(pc),a4
	move.w	(a4,d3.w),d2		;frequency number of the note
	clr.w	d1
	move.b	(a2),d1			;key
	asl.w	#3,d1
	move.w	(a3,d1.w),d3		;pitch bend
	beq.w	.nobend			;IDA: loc_16A0A
	clr.w	d1
	move.b	2(a2),d1		;patch
	asl.w	#5,d1			;32 bytes per patch
	movea.l	#unk_28338,a4
	move.b	$1E(a4,d1.w),d1		;patch byte $1E: bend scale
	ext.w	d1
	muls.w	d1,d3
	asr.l	#2,d3
	asr.w	#7,d3
	addi.w	#$C0,d3			;centre of .bendtab
	add.w	d3,d3
	lea	.bendtab(pc),a4
	mulu.w	(a4,d3.w),d2
	asl.l	#1,d2
	swap	d2			;d2 = d2 * factor / $8000
.nobend	move.w	(sp)+,d3		;IDA: loc_16A0A. octave
	cmpi.b	#$60,2(a2)
	bge.w	.pcm			;IDA: loc_16A36. PCM patch
	asl.w	#3,d3
	asl.w	#8,d3			;octave in bits 13-11
	or.w	d3,d2
	clr.w	d3
	move.b	3(a2),d3		;output channel
	bset	d3,($FFFFCB7D).w	;retail Z80_command_buffer+3 (Rev A: $CB81). frequency change
	add.w	d3,d3
	movea.w	#$CB86,a4		;retail unk_FFCB8A (Rev A: $CB8A). frequency words
	move.w	d2,(a4,d3.w)
	st	($FFFFCB78).w		;retail music_needs_z80_update (Rev A: $CB7C)
	rts
.pcm	move.w	#$100,(IO_Z80BUS).l	;IDA: loc_16A36
	neg.w	d3
	addq.w	#8,d3
	lsr.w	d3,d2			;frequency number >> (8 - octave)
	move.b	d2,($A0008E).l		;Z80_RAM_plus8E. PCM rate
	clr.w	(IO_Z80BUS).l
	rts
.fnum	;IDA: unk_16A52. frequency number of each note in the octave
	dc.w	$0146,$0159,$016E,$0184,$019B,$01B3,$01CD,$01E8,$0205,$0224,$0245,$0268
.bendtab	;IDA: unk_16A6A. 385 factors from $4000 to $FF13, entry $C0 = $8000 (no bend)
	dc.w	$4000,$403B,$4076,$40B2,$40EE,$412A,$4166,$41A3,$41E0,$421D
	dc.w	$425A,$4297,$42D5,$4313,$4351,$438F,$43CE,$440D,$444C,$448B
	dc.w	$44CA,$450A,$454A,$458A,$45CA,$460B,$464C,$468D,$46CE,$4710
	dc.w	$4752,$4794,$47D6,$4818,$485B,$489E,$48E1,$4925,$4969,$49AD
	dc.w	$49F1,$4A35,$4A7A,$4ABF,$4B04
	dc.w	$4B4A,$4B8F,$4BD5,$4C1B,$4C62,$4CA9,$4CF0,$4D37,$4D7E,$4DC6
	dc.w	$4E0E,$4E56,$4E9F,$4EE8,$4F31,$4F7A,$4FC4,$500E,$5058,$50A2
	dc.w	$50ED,$5138,$5183,$51CE,$521A,$5266,$52B2,$52FF,$534C,$5399
	dc.w	$53E6,$5434,$5482,$54D0,$551F,$556E,$55BD,$560C,$565C,$56AC
	dc.w	$56FC,$574C,$579D,$57EE,$5840,$5891,$58E3,$5936,$5988,$59DB
	dc.w	$5A2E,$5A82,$5AD6,$5B2A,$5B7E,$5BD3,$5C28,$5C7D,$5CD3,$5D29
	dc.w	$5D7F,$5DD6,$5E2D,$5E84,$5EDB,$5F33,$5F8B,$5FE4,$603D,$6096
	dc.w	$60EF,$6149,$61A3,$61FD,$6258,$62B3,$630E,$636A,$63C6,$6423
	dc.w	$647F,$64DC,$653A,$6597,$65F6,$6654,$66B3,$6712,$6771,$67D1
	dc.w	$6831,$6892,$68F2,$6954,$69B5,$6A17,$6A79,$6ADC,$6B3F,$6BA2
	dc.w	$6C06,$6C6A,$6CCE,$6D33,$6D98,$6DFD,$6E63,$6EC9,$6F30,$6F97
	dc.w	$6FFE,$7066,$70CE,$7136,$719F,$7208,$7272,$72DC,$7346,$73B1
	dc.w	$741C,$7488,$74F4,$7560,$75CD,$763A,$76A7,$7715,$7783,$77F2
	dc.w	$7861,$78D0,$7940,$79B0,$7A21,$7A92,$7B04,$7B76,$7BE8,$7C5B
	dc.w	$7CCE,$7D41,$7DB5,$7E2A,$7E9F,$7F14,$7F89,$8000,$8076,$80ED
	dc.w	$8164,$81DC,$8254,$82CD,$8346,$83C0,$843A,$84B4,$852F,$85AA
	dc.w	$8626,$86A2,$871F,$879C,$881A,$8898,$8916,$8995,$8A14,$8A94
	dc.w	$8B14,$8B95,$8C16,$8C98,$8D1A,$8D9D,$8E20,$8EA4,$8F28,$8FAC
	dc.w	$9031,$90B7,$913D,$91C3,$924A,$92D2,$935A,$93E2,$946B,$94F4
	dc.w	$957E,$9609,$9694,$971F,$97AB,$9837,$98C4,$9952,$99E0,$9A6E
	dc.w	$9AFD,$9B8D,$9C1D,$9CAD,$9D3E,$9DD0,$9E62,$9EF5,$9F88,$A01C
	dc.w	$A0B0,$A145,$A1DA,$A270,$A306,$A39D,$A435,$A4CD,$A565,$A5FE
	dc.w	$A698,$A732,$A7CD,$A868,$A904,$A9A1,$AA3E,$AADC,$AB7A,$AC18
	dc.w	$ACB8,$AD58,$ADF8,$AE99,$AF3B
	dc.w	$AFDD,$B080,$B123,$B1C7,$B26C,$B311,$B3B7,$B45D,$B504,$B5AC
	dc.w	$B654,$B6FD,$B7A7,$B851,$B8FB,$B9A6,$BA52,$BAFF,$BBAC,$BC5A
	dc.w	$BD08,$BDB7,$BE67,$BF17,$BFC8,$C07A,$C12C,$C1DF,$C292,$C346
	dc.w	$C3FB,$C4B1,$C567,$C61D,$C6D5,$C78D,$C846,$C8FF,$C9B9,$CA74
	dc.w	$CB2F,$CBEC,$CCA8,$CD66,$CE24,$CEE3,$CFA2,$D063,$D124,$D1E5
	dc.w	$D2A8,$D36B,$D42E,$D4F3,$D5B8,$D67E,$D744,$D80C,$D8D4,$D99D
	dc.w	$DA66,$DB30,$DBFB,$DCC7,$DD93,$DE60,$DF2E,$DFFD,$E0CC,$E19D
	dc.w	$E26D,$E33F,$E411,$E4E5,$E5B9,$E68D,$E763,$E839,$E910,$E9E8
	dc.w	$EAC0,$EB9A,$EC74,$ED4F,$EE2A,$EF07,$EFE4,$F0C2,$F1A1,$F281
	dc.w	$F361,$F443,$F525,$F608,$F6EC,$F7D0,$F8B6,$F99C,$FA83,$FB6B
	dc.w	$FC54,$FD3E,$FE28,$FF13,$FF13

handle_command_40	;event $4x: set the patch of channel +1 bits 3-0 of track d7 to +2 (voice table +3)
	movea.w	#$CB9C,a3		;retail fm_voice_usage_table (Rev A: $CBA0)
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0			;key
	asl.w	#3,d0
	move.b	2(a0),3(a3,d0.w)
	rts

handle_command_60	;event $6x: set the pitch bend of channel +1 bits 3-0 of track d7 to word +2 - $2000,
			;then update the frequency of every channel struct playing that key
	movea.w	#$CB9C,a3		;retail fm_voice_usage_table (Rev A: $CBA0)
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0			;key
	move.w	d0,d4
	asl.w	#3,d0
	move.w	2(a0),(a3,d0.w)
	subi.w	#$2000,(a3,d0.w)	;signed, 0 = no bend
	movea.w	#$CD9C,a2		;retail fm_channel_structs (Rev A: $CDA0)
	moveq	#5,d0
.loop	cmp.b	(a2),d4			;IDA: loc_16DAC
	bne.w	.next			;IDA: loc_16DB6. another key
	bsr.w	UpdateChannelFrequencyAndVolume
.next	addq.w	#6,a2			;IDA: loc_16DB6
	dbf	d0,.loop
	rts

handle_command_skip	;events $2x, $3x, $5x and $7x: ignored
	rts

p_initialZ80	;92 name (initialization). Free all slots, load the Z80 program into Z80 RAM, build 29 tables of
		;256 bytes below Z80 $2000 ((i-$80)*8/d + $80 for d = 8-36, byte 0 = 0) and start the Z80.
		;Called from Begin
	movem.l	d0-d2/a0-a2,-(sp)
	bsr.w	ClearAllTrackAndSFXSlots
	move.w	#$100,(IO_Z80RES).l
	move.w	#$100,(IO_Z80BUS).l	;request the Z80 bus
	movea.l	#Z80_Program_Code,a1
	movea.l	#$A00000,a2		;Z80_RAM
	move.w	#$294,d0		;$295 bytes
.copy	move.b	(a1)+,(a2)+		;IDA: loc_16DE8
	dbf	d0,.copy
	movea.l	#$A02000,a2		;IDA: unk_A02000 (Z80 RAM $2000)
	moveq	#8,d2			;first divisor
	move.l	#$1C,d3			;29 tables
.tab	move.w	#$FF,d0			;IDA: loc_16DFC
.byte	move.w	d0,d1			;IDA: loc_16E00
	subi.w	#$80,d1
	asl.w	#3,d1
	ext.l	d1
	divs.w	d2,d1
	addi.w	#$80,d1
	move.b	d1,-(a2)
	dbf	d0,.byte
	clr.b	(a2)			;entry 0 = 0
	addq.w	#1,d2
	dbf	d3,.tab
	move.w	#0,(IO_Z80RES).l	;Z80 reset
	move.w	#0,(IO_Z80BUS).l	;release the bus
	move.w	#$1F4,d0
.wait	dbf	d0,.wait		;IDA: loc_16E32
	move.w	#$100,(IO_Z80RES).l	;Z80 runs
	clr.b	($FFFFCB78).w		;retail music_needs_z80_update (Rev A: $CB7C)
	movem.l	(sp)+,d0-d2/a0-a2
	rts

ClearAllTrackAndSFXSlots	;free the 8 track slots and reset the 6 channel structs (output channels 0, 1, 2,
			;4, 5, 6, patch $FF, off). Called from p_turnoff and p_initialZ80
	movea.w	#$CDC0,a0		;retail fm_track_slots (Rev A: $CDC4)
	moveq	#7,d0
	moveq	#-1,d1
.trk	move.l	d1,(a0)			;IDA: loc_16E50. free
	addq.w	#6,a0
	dbf	d0,.trk
	moveq	#5,d0
	movea.w	#$CDC0,a0		;retail fm_track_slots (Rev A: $CDC4). end of the channel structs
.chan	subq.w	#6,a0			;IDA: loc_16E5E
	move.b	d0,3(a0)		;output channel
	cmp.w	#3,d0
	blt.w	.set			;IDA: loc_16E70
	addq.b	#1,3(a0)		;3-5 become 4-6
.set	st	2(a0)			;IDA: loc_16E70. patch $FF
	clr.w	(a0)			;key, note
	clr.b	5(a0)			;off
	dbf	d0,.chan
	rts

Z80_Program_Code	;IDA name. First byte of the Z80 program ($16E52, movea.l in p_initialZ80); the rest of the
		;Z80 blob from $16E53 is not covered yet
	dc.b	$18
