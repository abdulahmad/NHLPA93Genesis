;	Sound driver, 68000 side. Starts the Z80, plays songs and sound effects frame by frame and turns the sound
;	off. The Z80 program and the sound data the driver plays follow the code.
;
;	92's sound.asm has p_turnoff, p_music_vblank, p_initialZ80 and p_initune as a branch table to _fn
;	routines. 93 has the first three directly and starts sounds with play_sfx_or_music_track.
;
;	Sound numbers are in ram93.asm (SFX*, Sng*). The data layout is described above p_music_vblank.


;	Sound numbers and the data the driver works on, named as in 92's sound.asm. The SFX* and Sng* sound
;	numbers are in ram93.asm; the sizes and offsets below are the ones the driver code uses.

;	Sound numbers
SoundLast			=	SngScouting	;last sound number: sounds $0-$37, effects below $30, songs from $30
FirstSong			=	SngGoal		;the first song; a new song stops the one playing

;	Track slots (rs.b in ram93.asm, 8 of them; slot n plays track 7-n): an event pointer and a delay
NumSlots			=	8			;track slots
SlotSize			=	6			;bytes per slot
sl_delay			=	4			;word: frames until the next event (+5 is its delay byte)
sl_delaybyte		=	5

;	Channel structs (6, the 6th is the PCM channel)
NumChans			=	6			;channel structs
NumFMChans			=	5			;the FM ones
ChanSize			=	6			;bytes per channel struct
ch_key				=	0			;midi channel * 8 + track
ch_note				=	1
ch_patch			=	2			;PCMPatch and up play on the PCM channel
ch_out				=	3			;output channel (0, 1, 2, 4, 5, 6)
ch_age				=	4			;frames since key on, held at $FF
ch_flags			=	5
ch_on				=	0			;ch_flags bit: the key is on

;	Voice table: 8 bytes per key (key = midi channel * 8 + track)
NumMidiChans		=	8			;midi channels per track
KeyShift			=	3			;key = midi channel << 3 | track
VoiceShift			=	3			;voice table offset = key << 3
VoiceSize			=	1<<VoiceShift
vc_bend				=	0			;word: pitch bend (stored as the stream word - BendCentre)
vc_spare			=	2			;cleared with the key, never read
vc_patch			=	3
BendCentre			=	$2000		;stream pitch bend word for no bend

;	Events: 4 bytes. Status bits 6-4 are the command, bits 3-0 the midi channel
EventSize			=	4
ev_delay			=	0
ev_status			=	1
ev_data				=	2			;note, patch or bend word; the byte after it is the volume
EvCmdMask			=	$70
EvChanMask			=	$F

;	FM patches: 32 bytes each; patch numbers from PCMPatch are PCM samples (pcm_sample_table)
PCMPatch			=	$60
PatchShift			=	5			;32 bytes per patch
patch_bendscale		=	$1E			;patch byte: pitch bend scale

;	Command buffer sent to the Z80 (Z80_command_buffer in ram93.asm, then the volume, frequency and patch
;	tables)
cb_keyoff			=	0			;bit per output channel
cb_keyon			=	1
cb_volume			=	2
cb_freq				=	3
cb_patch			=	4
CmdBufSize			=	33			;bytes copied to the Z80

;	Z80 memory map (offsets from Z80_RAM)
z80_cmdbuf			=	$02			;where the command buffer is copied to
z80_dac_start_addr		=	$23		;3 bytes: PCM sample start (high byte first)
z80_dac_next_addr	=	$26			;3 bytes: where the Z80 carries on after a 0 sample byte (high byte first)
z80_dac_vol_page			=	$83	;volume table page ($03-$1F, $1F loudest)
z80_dac_step		=	$8E			;sample step per DAC write; 0 holds the current byte (no advance)
z80_cmd				=	$96			;low byte of the sample loop's jump target: Z80Idle when the Z80 can take
									;a command
z80_cmd_high		=	$97			;high byte of that jump target; the Z80 always leaves 0 here
z80_tables			=	$2000		;end of the 29 tables of 256 bytes below it
Z80Idle				=	$7D			;the sample loop (MainLoop in z80_snd_drv93.asm): no command pending
Z80Cmd_Upload		=	$D1			;UpdateFmChannels: take the command buffer
Z80Cmd_PCM			=	$29			;Z80_Init: restart with the PCM sample set up at z80_dac_start_addr
Z80ProgramLen		=	$295		;bytes of the Z80 program copied to Z80 RAM
Z80Tables			=	29			;tables of 256 bytes built by p_initialZ80


p_turnoff							;(audio stop). Silence everything: free all slots, key off and mute every
									;output
									;channel, send the buffer and stop the PCM channel. Called from Begin,
									;StartPer, game screens
	movem.l	d0-d7/a0-a2,-(sp)
	bsr.w	ClearAllTrackAndSFXSlots
	move.b	#$77,(Z80_command_buffer).w	;key off channels 0-2, 4-6
	move.b	#$77,(Z80_command_buffer+2).w	;volume change on 0-2, 4-6
	moveq	#6,d0					;7 volume bytes
	movea.w	#(per_channel_attenuation_table-M68K_RAM),a0
.att	move.b	#$7F,(a0)+			;$7F = silent
	dbf	d0,.att
	bsr.w	UploadCommandBufferToZ80
	bsr.w	StopPCMChannel
	movem.l	(sp)+,d0-d7/a0-a2
	rts

play_sfx_or_music_track				;start sound d0 (0-$37) in a track slot. $30 and up are songs: the song
									;already
									;playing is stopped first. Does the jobs of / p_initune; called from sfx
									;and song
	cmp.w	#SoundLast,d0
	bgt.w	rtss					;out of range
	movem.l	d0-d3/a0-a2,-(sp)
	cmp.w	#FirstSong,d0
	blt.w	.slot					;sound effect
	bsr.w	stop_current_song		;song: stop the current song
.slot	movea.w	#(fm_track_slots-M68K_RAM),a1	;scan the 8 track slots for the lowest pointer (free slots are
												;negative)
	moveq	#NumSlots-1,d3
.new	move.l	(a1),d1				;new lowest pointer
	move.w	d3,d2					;its track number
	movea.w	a1,a2
.chk	cmp.l	(a1),d1				;next slot: is its pointer lower than the lowest so far?
	bgt.s	.new					;lower (signed) pointer here: take this slot
	addq.w	#SlotSize,a1
	dbf	d3,.chk
	tst.w	(a2)
	bpl.w	.ex						;no free slot (lowest pointer is in use): do nothing
	asl.w	#1,d0
	movea.l	#SoundStreamTable,a0
	adda.w	(a0,d0.w),a0			;start of the event stream
	move.l	a0,(a2)
	clr.w	sl_delay(a2)
	move.b	(a0),sl_delaybyte(a2)	;first delay
	movea.w	#(fm_voice_usage_table-M68K_RAM),a0
	asl.w	#VoiceShift,d2
	adda.w	d2,a0
	moveq	#NumMidiChans-1,d0		;the 8 midi channels of this track
.clrv	clr.w	(a0)				;no pitch bend
	clr.b	vc_spare(a0)
	clr.b	vc_patch(a0)			;patch 0
	adda.w	#NumSlots*VoiceSize,a0	;next channel (8 keys of 8 bytes)
	dbf	d0,.clrv
.ex	movem.l	(sp)+,d0-d3/a0-a2		;restore registers
	rts

stop_current_song					;stop the song in progress: free the first slot whose pointer is at or
									;past the first song
									;data and key off its channels. Called from play_sfx_or_music_track
									;and checkgoal
	movem.l	d0-d3/a0-a3,-(sp)
	movea.w	#(fm_track_slots-M68K_RAM),a1
	moveq	#NumSlots-1,d3
	movea.l	#SoundStreamTable,a0
	adda.w	FirstSong*2(a0),a0		;sound $30 data
.find	cmpa.l	(a1),a0				;look for a slot whose pointer is at or past the first song data
	addq.w	#SlotSize,a1
	dble	d3,.find				;until a slot pointer >= the song data
	bgt.w	.ex						;none: no song playing
	move.l	#$FFFFFFFF,-SlotSize(a1)	;free the slot
	moveq	#NumChans,d1			;7 passes: one more than there are structs
	movea.w	#(fm_channel_structs-M68K_RAM),a2
.kill	move.b	ch_key(a2),d2		;each channel struct: release the ones that belong to this track
	andi.w	#NumSlots-1,d2			;track of the key
	cmp.w	d2,d3
	bne.w	.next					;another track
	bsr.w	ReleaseChannelAndNote
	move.b	ch_out(a2),d0			;output channel
	bset	d0,(Z80_command_buffer+cb_volume).w	;volume change
	movea.w	#(per_channel_attenuation_table-M68K_RAM),a1
	move.b	#$7F,(a1,d0.w)			;silent
.next	addq.w	#ChanSize,a2		;next channel struct
	dbf	d1,.kill
	bsr.w	UploadCommandBufferToZ80
.ex	movem.l	(sp)+,d0-d3/a0-a3		;restore registers
	rts

;	Data layout:
;
;	  track slots (8 x 6 bytes): +0 long event pointer (negative = free or ended), +4 word delay count
;	    (+5 = the delay byte read from the stream). Slot n is track 7-n.
;
;	  channel structs (6 x 6 bytes, the 6th is the PCM channel): +0 key (midi channel*8 + track), +1 note,
;	    +2 patch, +3 output channel (0,1,2,4,5,6), +4 age (+1 each frame), +5 bit 0 on.
;
;	  voice table (8 bytes per key): +0 word pitch bend (value - $2000), +3 patch.
;
;	  command buffer (33 bytes, copied to Z80 RAM $02-$22): +0 key off bits, +1 key on bits, +2 volume bits,
;	    +3 frequency bits, +4 patch bits (one bit per output channel), then 7 volume bytes, 7 frequency
;	    words, 7 patch bytes.
;
;	  events (4 bytes): +0 delay before this event, +1 status (bits 6-4 command, bits 3-0 channel),
;	    +2/+3 data. Status 0 ends the stream; a non-negative long at +2 is a loop pointer.

	IF REV=2
ReadPads							;Rev B: read both controllers once a frame, from the vblank, with the Z80
									;bus held. The raw bytes go to PadRaw1/PadRaw2 for ReadJoy1/ReadJoy2
	move.w	#$100,(IO_Z80BUS).l		;turn off z80
.wait	btst	#0,(IO_Z80BUS).l	;wait for the Z80 to give up the bus
	bne.b	.wait
	lea	(Joy1).l,a0
	bsr.w	ReadPadByte
	move.b	d0,(PadRaw1).w
	lea	(Joy2).l,a0
	bsr.w	ReadPadByte
	clr.w	(IO_Z80BUS).l			;turn on z80
	move.b	d0,(PadRaw2).w
	rts

ReadPadByte							;read the pad at a0. Return d0 = the 8 button bits, active low
	move.b	#$40,6(a0)				;control port: TH as output
	move.b	#0,(a0)					;TH low: the next read gives start and A
	move.w	#10,d1
.z	dbf	d1,.z						;let the pad settle
	move.b	(a0),d0					;TH low read: bit 5 = start, bit 4 = A
	move.b	#$40,(a0)				;TH high for the next read
	asl.b	#2,d0					;start/A up to bits 7-6
	andi.b	#%11000000,d0
	move.w	#10,d1
.zz	dbf	d1,.zz						;settle delay
	move.b	(a0),d1					;TH high read: bits 0-3 up/down/left/right, bit 4 = B, bit 5 = C
	andi.b	#%00111111,d1
	or.b	d1,d0					;d0 = 8 button bits, active low
	rts
	ENDIF

p_music_vblank						;(vblank handler). Clear the change bits, run the 8 track slots (d7 =
									;track 7-0)
									;send the buffer if anything changed and age the channels. Called every
									;frame from the vblank handlers. Rev A runs the slots again every 6th
									;frame while PalMode
									;is set (music_tick_divider); Rev 0 has no such block (22 bytes
									;shorter)
	IF REV=2
	bsr.b	ReadPads				;Rev B: poll the controllers first
	ENDIF
	clr.b	(music_needs_z80_update).w
	clr.l	(Z80_command_buffer).w	;key off/on, volume, frequency bits
	clr.b	(Z80_command_buffer+cb_patch).w	;patch bits
.refresh	movea.w	#(fm_track_slots-M68K_RAM),a5	;run all 8 track slots (Rev A loops back here at 50 Hz)
	moveq	#NumSlots-1,d7
.slot	bsr.w	ProcessOneMusicTrack	;process track slot a5, track d7
	addq.w	#SlotSize,a5
	dbf	d7,.slot
	IF REV>=1
	tst.w	(PalMode).w				;Rev A: at 50 Hz run the slots again every 6th frame
	beq.w	.tick
	subq.w	#1,(music_tick_divider).w
	bpl.w	.tick
	addq.w	#6,(music_tick_divider).w
	bra.s	.refresh
.tick								;end of the Rev A only block
	ENDIF
	tst.b	(music_needs_z80_update).w
	beq.w	.age					;nothing changed
	bsr.w	UploadCommandBufferToZ80
.age	movea.w	#(fm_channel_structs-M68K_RAM),a0	;age the 6 channel structs
	moveq	#NumChans-1,d0
.ageloop	addq.b	#1,ch_age(a0)	;age +1 per frame
	bne.w	.next
	subq.b	#1,ch_age(a0)			;hold at $FF
.next	addq.w	#ChanSize,a0		;next channel struct
	dbf	d0,.ageloop
	rts

z80_bus_release_delay				;Z80 still on a command: give the bus back, wait, then falls into
									;UploadCommandBufferToZ80 to retry
	clr.w	(IO_Z80BUS).l
	moveq	#$64,d0
.delay	dbf	d0,.delay				;short wait before the bus is requested again

UploadCommandBufferToZ80			;copy the 33-byte command buffer to Z80 RAM $02 once the Z80 is idle ($97
									;= 0, $96 = $7D), and post command $D1. Called after any change
	move.w	#$100,(IO_Z80BUS).l		;request the Z80 bus
	IF REV=2
.zb1	btst	#0,(IO_Z80BUS).l	;Rev B waits for the Z80 to grant the bus
	bne.b	.zb1
	ENDIF
	movea.l	#Z80_RAM,a0
	cmpi.b	#0,z80_cmd_high(a0)
	bne.s	z80_bus_release_delay	;not idle
	cmpi.b	#Z80Idle,z80_cmd(a0)
	bne.s	z80_bus_release_delay	;not idle
	move.b	#Z80Cmd_Upload,z80_cmd(a0)	;the sample loop jumps to UpdateFmChannels next
	move.b	#0,z80_cmd_high(a0)
	adda.w	#z80_cmdbuf,a0
	movea.w	#(Z80_command_buffer-M68K_RAM),a1
	moveq	#CmdBufSize-1,d0		;33 bytes
.copy	move.b	(a1)+,(a0)+			;copy the buffer to Z80 RAM
	dbf	d0,.copy
	clr.w	(IO_Z80BUS).l
	rts

ProcessOneMusicTrack				;count down track slot a5 (track d7) and run every event that is due.
									;Called from p_music_vblank
	subq.w	#1,sl_delay(a5)
	bpl.w	rtss					;not due yet
.event	tst.w	(a5)				;run the next event of this slot
	bmi.w	rtss					;slot free or ended
	movea.l	(a5),a0
	addq.l	#EventSize,(a5)
	clr.w	sl_delay(a5)
	move.b	EventSize+ev_delay(a0),sl_delaybyte(a5)	;delay before the next event
	move.b	ev_status(a0),d0
	bne.w	.cmd
	st	(a5)						;status 0: end of stream
	tst.w	ev_data(a0)
	bmi.w	rtss
	move.l	ev_data(a0),(a5)		;loop pointer
	bra.s	.event
.cmd	move.b	ev_status(a0),d0	;dispatch on the command number in status bits 6-4
	andi.w	#EvCmdMask,d0			;command number * 16
	lsr.w	#3,d0					;word index
	lea	command_jump_table(pc),a2
	adda.w	(a2,d0.w),a2
	jsr	(a2)
	bra.s	ProcessOneMusicTrack	;the next event may be due now (delay 0)

command_jump_table					;event handlers by status bits 6-4, as offsets from the table
	dc.w	handle_command_00-command_jump_table
	dc.w	handle_command_10-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_40-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_60-command_jump_table
	dc.w	handle_command_skip-command_jump_table

handle_command_00					;event $0x: key off note +2 on channel +1 bits 3-0 of track d7. Also
									;entered from
									;handle_command_10 for volume 0. Falls into ReleaseChannelAndNote
	move.b	ev_status(a0),d0
	andi.w	#EvChanMask,d0
	asl.w	#KeyShift,d0
	or.w	d7,d0					;key
	asl.w	#8,d0
	move.b	ev_data(a0),d0			;key and note, as in channel struct +0/+1
	movea.w	#(fm_track_slots-M68K_RAM),a2	;end of the channel structs
	moveq	#NumChans-1,d1
.find	subq.w	#ChanSize,a2		;search the channel structs (last to first) for this key and note
	cmp.w	(a2),d0
	dbeq	d1,.find
	bne.w	rtss					;not playing
	btst	#ch_on,ch_flags(a2)
	dbne	d1,.find				;matched but already off: keep looking
	beq.w	rtss

ReleaseChannelAndNote				;key off channel struct a2 if it is on. The PCM patches ($60 up) stop the
									;PCM channel
									;instead. Called from stop_current_song
	bclr	#ch_on,ch_flags(a2)
	beq.w	rtss					;was off
	cmpi.b	#PCMPatch,ch_patch(a2)
	bge.w	StopPCMChannel			;PCM patch
	move.b	ch_out(a2),d0			;output channel
	bset	d0,(Z80_command_buffer).w	;key off
	st	(music_needs_z80_update).w
	rts

StopPCMChannel						;clear Z80 RAM $8E (the PCM rate byte written by
									;UpdateChannelFrequencyAndVolume).
									;Called from p_turnoff and for a PCM key off
	move.w	#$100,(IO_Z80BUS).l
	IF REV=2
.zb2	btst	#0,(IO_Z80BUS).l	;Rev B waits for the Z80 to grant the bus
	bne.b	.zb2
	ENDIF
	clr.b	(Z80_RAM+z80_dac_step).l
	clr.w	(IO_Z80BUS).l
	rts

handle_command_10					;event $1x: key on note +2 at volume +3 on channel +1 bits 3-0 of track d7
									;(volume 0 =
									;key off). Patches $60 up play on the PCM channel. Falls into
									;UpdateChannelFrequencyAndVolume
	tst.b	ev_data+1(a0)
	beq.s	handle_command_00		;volume 0: key off
	movea.w	#(pcm_channel_struct-M68K_RAM),a2	;6th channel struct
	movea.w	#(fm_voice_usage_table-M68K_RAM),a3
	move.b	ev_status(a0),d0
	andi.w	#EvChanMask,d0
	asl.w	#KeyShift,d0
	or.w	d7,d0					;key
	move.w	d0,d6
	asl.w	#KeyShift,d0
	move.b	vc_patch(a3,d0.w),d0	;patch of this key
	cmp.b	#PCMPatch,d0
	bge.w	.pcm					;PCM patch
	moveq	#NumFMChans-1,d1
	bra.w	.setold
.old	cmp.b	ch_age(a2),d2		;is this channel older than the oldest so far (age in d2)?
	bhi.w	.nextold				;a4 is older
.setold	movea.w	a2,a4				;a4 = oldest channel so far, d2 = its age
	move.b	ch_age(a4),d2
.nextold	subq.w	#ChanSize,a2	;next channel struct
	dbf	d1,.old
	moveq	#NumFMChans-1,d1
	movea.w	#(pcm_channel_struct-M68K_RAM),a2
.free	subq.w	#ChanSize,a2		;look for a channel struct that is off
	btst	#ch_on,ch_flags(a2)
	dbeq	d1,.free				;skip channels that are on
	bne.w	.patch					;none off: take the oldest (a4)
	movea.w	a2,a4					;a4 = this off channel
	cmp.b	ch_patch(a2),d0
	dbeq	d1,.free				;look for an off channel that has the patch already
	beq.w	.keyon					;found: no patch change
.patch	movea.w	a4,a2				;give the chosen channel its new patch
	move.b	d0,ch_patch(a2)			;new patch
	clr.w	d1
	move.b	ch_out(a2),d1			;output channel
	bset	d1,(Z80_command_buffer+cb_patch).w	;patch change
	movea.w	#(per_channel_patch_table-M68K_RAM),a4	;patch bytes
	move.b	d0,(a4,d1.w)
	st	(music_needs_z80_update).w
.keyon	clr.b	ch_age(a2)			;age 0
	bset	#ch_on,ch_flags(a2)		;on
	move.b	d6,ch_key(a2)			;key
	clr.w	d3
	move.b	ev_data(a0),d3
	move.b	d3,ch_note(a2)			;note
	clr.w	d1
	move.b	ch_out(a2),d1			;output channel
	bset	d1,(Z80_command_buffer+cb_keyon).w	;key on
	lea	.veltab(pc),a4
	clr.w	d0
	move.b	ev_data+1(a0),d0
	lsr.w	#3,d0					;volume / 8
	move.b	(a4,d0.w),d0
	movea.w	#(per_channel_attenuation_table-M68K_RAM),a4
	move.b	d0,(a4,d1.w)
	bset	d1,(Z80_command_buffer+cb_volume).w	;volume change
	bra.w	UpdateChannelFrequencyAndVolume
.veltab	dc.b	$1A,$18,$16,$14,$12,$10,$0E,$0C,$0A,$08,$06,$04,$03,$02,$01,$00	;attenuation by volume/8
.pcm	bset	#ch_on,ch_flags(a2)	;a2 = the PCM channel
	beq.w	.pcmon					;it was off
	cmp.b	ch_patch(a2),d0
	ble.w	rtss					;a sample with the same or a higher patch number is playing
.pcmon	move.b	d0,ch_patch(a2)		;mark the PCM channel with the new patch
	movea.w	#(pcm_channel_struct-M68K_RAM),a2
	clr.b	ch_age(a2)
	move.b	d6,ch_key(a2)			;key
	move.b	ev_data(a0),ch_note(a2)	;note
	ext.w	d0
	subi.w	#PCMPatch,d0
	asl.w	#KeyShift,d0			;8 bytes per sample
	lea	pcm_sample_table(pc),a1
	move.l	4(a1,d0.w),d1
	move.l	(a1,d0.w),d0
	move.w	#$100,(IO_Z80BUS).l
	IF REV=2
.zb3	btst	#0,(IO_Z80BUS).l	;Rev B waits for the Z80 to grant the bus
	bne.b	.zb3
	ENDIF
	movea.l	#Z80_RAM,a1
	move.b	d0,z80_dac_start_addr+2(a1)	;first long to Z80 $23-$25, high byte first
	lsr.w	#8,d0
	move.b	d0,z80_dac_start_addr+1(a1)
	swap	d0
	move.b	d0,z80_dac_start_addr(a1)
	move.b	d1,z80_dac_next_addr+2(a1)	;second long to Z80 $26-$28
	lsr.w	#8,d1
	move.b	d1,z80_dac_next_addr+1(a1)
	swap	d1
	move.b	d1,z80_dac_next_addr(a1)
	move.b	ev_data+1(a0),d1
	lsr.b	#2,d1					;volume / 4
	cmp.w	#3,d1
	bgt.w	.rate
	moveq	#3,d1					;at least 3
.rate	move.b	d1,z80_dac_vol_page(a1)	;volume/4 (at least 3): the Z80's volume table page
	move.b	#Z80Cmd_PCM,z80_cmd(a1)	;command $29: the Z80 restarts at Z80_Init
	move.b	#0,z80_cmd_high(a1)
	clr.w	(IO_Z80BUS).l

UpdateChannelFrequencyAndVolume		;set the frequency of channel struct a2 from its note and the pitch bend
									;of
									;its key (a3 = voice table). Called from handle_command_60, entered from
									;handle_command_10
	clr.l	d3
	move.b	ch_note(a2),d3			;note
	divu.w	#$C,d3					;d3 = octave, high word = note in the octave
	move.w	d3,-(sp)
	swap	d3
	add.w	d3,d3
	lea	.fnum(pc),a4
	move.w	(a4,d3.w),d2			;frequency number of the note
	clr.w	d1
	move.b	ch_key(a2),d1			;key
	asl.w	#VoiceShift,d1
	move.w	(a3,d1.w),d3			;pitch bend
	beq.w	.nobend
	clr.w	d1
	move.b	ch_patch(a2),d1			;patch
	asl.w	#PatchShift,d1			;32 bytes per patch
	movea.l	#fm_instrument_patches,a4
	move.b	patch_bendscale(a4,d1.w),d1	;patch byte $1E: bend scale
	ext.w	d1
	muls.w	d1,d3
	asr.l	#2,d3
	asr.w	#7,d3
	addi.w	#$C0,d3					;centre of .bendtab
	add.w	d3,d3
	lea	.bendtab(pc),a4
	mulu.w	(a4,d3.w),d2
	asl.l	#1,d2
	swap	d2						;d2 = d2 * factor / $8000
.nobend	move.w	(sp)+,d3			;octave
	cmpi.b	#PCMPatch,ch_patch(a2)
	bge.w	.pcm					;PCM patch
	asl.w	#3,d3
	asl.w	#8,d3					;octave in bits 13-11
	or.w	d3,d2
	clr.w	d3
	move.b	ch_out(a2),d3			;output channel
	bset	d3,(Z80_command_buffer+cb_freq).w	;frequency change
	add.w	d3,d3
	movea.w	#(per_channel_frequency_table-M68K_RAM),a4	;frequency words
	move.w	d2,(a4,d3.w)
	st	(music_needs_z80_update).w
	rts
.pcm	move.w	#$100,(IO_Z80BUS).l	;PCM patch: set the sample rate in Z80 RAM
	IF REV=2
.zb4	btst	#0,(IO_Z80BUS).l	;Rev B waits for the Z80 to grant the bus
	bne.b	.zb4
	ENDIF
	neg.w	d3
	addq.w	#8,d3
	lsr.w	d3,d2					;frequency number >> (8 - octave)
	move.b	d2,(Z80_RAM+z80_dac_step).l	;PCM rate
	clr.w	(IO_Z80BUS).l
	rts
.fnum								;frequency number of each note in the octave
	dc.w	$0146,$0159,$016E,$0184,$019B,$01B3,$01CD,$01E8,$0205,$0224,$0245,$0268
.bendtab							;385 factors from $4000 to $FF13, entry $C0 = $8000 (no bend)
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

handle_command_40					;event $4x: set the patch of channel +1 bits 3-0 of track d7 to +2 (voice
									;table +3)
	movea.w	#(fm_voice_usage_table-M68K_RAM),a3
	move.b	ev_status(a0),d0
	andi.w	#EvChanMask,d0
	asl.w	#KeyShift,d0
	or.w	d7,d0					;key
	asl.w	#KeyShift,d0
	move.b	ev_data(a0),vc_patch(a3,d0.w)
	rts

handle_command_60					;event $6x: set the pitch bend of channel +1 bits 3-0 of track d7 to word
									;+2 - $2000,
									;then update the frequency of every channel struct playing that key
	movea.w	#(fm_voice_usage_table-M68K_RAM),a3
	move.b	ev_status(a0),d0
	andi.w	#EvChanMask,d0
	asl.w	#KeyShift,d0
	or.w	d7,d0					;key
	move.w	d0,d4
	asl.w	#KeyShift,d0
	move.w	ev_data(a0),vc_bend(a3,d0.w)
	subi.w	#BendCentre,vc_bend(a3,d0.w)	;signed, 0 = no bend
	movea.w	#(fm_channel_structs-M68K_RAM),a2
	moveq	#NumChans-1,d0
.loop	cmp.b	ch_key(a2),d4		;find the channel structs playing this key
	bne.w	.next					;another key
	bsr.w	UpdateChannelFrequencyAndVolume
.next	addq.w	#ChanSize,a2		;next channel struct
	dbf	d0,.loop
	rts

handle_command_skip					;events $2x, $3x, $5x and $7x: ignored
	rts

p_initialZ80						;(initialization). Free all slots, load the Z80 program into Z80 RAM,
									;build 29 tables of
									;256 bytes below Z80 $2000 ((i-$80)*8/d + $80 for d = 8-36, byte 0 = 0)
									;and start the Z80.
									;Called from Begin
	movem.l	d0-d2/a0-a2,-(sp)
	bsr.w	ClearAllTrackAndSFXSlots
	move.w	#$100,(IO_Z80RES).l
	move.w	#$100,(IO_Z80BUS).l		;request the Z80 bus
	IF REV=2
.zb5	btst	#0,(IO_Z80BUS).l	;Rev B waits for the Z80 to grant the bus
	bne.b	.zb5
	ENDIF
	movea.l	#Z80_Program_Code,a1
	movea.l	#Z80_RAM,a2
	move.w	#Z80ProgramLen-1,d0		;$295 bytes
.copy	move.b	(a1)+,(a2)+			;copy the Z80 program to Z80 RAM
	dbf	d0,.copy
	movea.l	#Z80_RAM+z80_tables,a2	;(Z80 RAM $2000)
	moveq	#8,d2					;first divisor
	move.l	#Z80Tables-1,d3			;29 tables
.tab	move.w	#$FF,d0				;start one 256-byte table
.byte	move.w	d0,d1				;one table byte: ((i-$80)*8)/divisor + $80
	subi.w	#$80,d1
	asl.w	#3,d1
	ext.l	d1
	divs.w	d2,d1
	addi.w	#$80,d1
	move.b	d1,-(a2)
	dbf	d0,.byte
	clr.b	(a2)					;entry 0 = 0
	addq.w	#1,d2
	dbf	d3,.tab
	move.w	#0,(IO_Z80RES).l		;Z80 reset
	move.w	#0,(IO_Z80BUS).l		;release the bus
	move.w	#$1F4,d0
.wait	dbf	d0,.wait				;wait for the Z80 reset to finish
	move.w	#$100,(IO_Z80RES).l		;Z80 runs
	clr.b	(music_needs_z80_update).w
	movem.l	(sp)+,d0-d2/a0-a2
	rts

ClearAllTrackAndSFXSlots			;free the 8 track slots and reset the 6 channel structs (output channels
									;0, 1, 2,
									;4, 5, 6, patch $FF, off). Called from p_turnoff and p_initialZ80
	movea.w	#(fm_track_slots-M68K_RAM),a0
	moveq	#NumSlots-1,d0
	moveq	#-1,d1
.trk	move.l	d1,(a0)				;free
	addq.w	#SlotSize,a0
	dbf	d0,.trk
	moveq	#NumChans-1,d0
	movea.w	#(fm_track_slots-M68K_RAM),a0	;end of the channel structs
.chan	subq.w	#ChanSize,a0		;set up channel struct d0 (last to first)
	move.b	d0,ch_out(a0)			;output channel
	cmp.w	#3,d0
	blt.w	.set
	addq.b	#1,ch_out(a0)			;3-5 become 4-6
.set	st	ch_patch(a0)			;patch $FF
	clr.w	(a0)					;key, note
	clr.b	ch_flags(a0)			;off
	dbf	d0,.chan
	rts

Z80_Program_Code					;The Z80 sound driver, $28B bytes, built by asm80 from
									;src/sound/z80_snd_drv93.asm (output/obj/z80_snd_drv93.bin).
									;p_initialZ80 copies Z80ProgramLen ($295) bytes from here: the 10 bytes
									;after the driver (the pad byte and the start of pcm_sample_table) land
									;below the Z80 stack top and are never read as data.
	;Z80 $0000-$0277
	incbin	..\output\obj\z80_snd_drv93.bin,0,$278
	;Z80 $0278 (z80_fm_patches_window): ld bc operand, the bank window address of the FM patches
	dc.b	fm_instrument_patches&$FF,((fm_instrument_patches>>8)&$7F)|$80
	;Z80 $027A: add hl,bc / ld a,n; $027C (z80_fm_patches_bank): the 32K bank of the FM patches
	dc.b	$09,$3E,fm_instrument_patches>>15
	incbin	..\output\obj\z80_snd_drv93.bin,$27D,$E	;Z80 $027D-$028A: jp SetBank, SelectPart
	IF REV=0
	dc.b	$83						;pad: Rev 0 leftover byte
	ELSE
	dc.b	PadByte
	ENDIF
pcm_sample_table					;(sample address, 0) for PCM patches $60-$6E (lea in handle_command_10)
	dc.l	sfx_puckget_pcm,0		;patch $60
	dc.l	sfx_pass_pcm,0			;patch $61
	dc.l	sfx_shotbh_pcm,0		;patch $62
	dc.l	sfx_shotfh_pcm,0		;patch $63
	dc.l	sfx_check2_pcm,0		;patch $64
	dc.l	sfx_check_pcm,0			;patch $65
	dc.l	sfx_playerwall_pcm,0	;patch $66
	dc.l	sfx_hithigh_pcm,0		;patch $67
	dc.l	0,0						;patch $68
	dc.l	0,0						;patch $69
	dc.l	sfx_hithigh_pcm,0		;patch $6A
	dc.l	sfx_crowdboo_pcm,0		;patch $6B
	dc.l	sfx_oooh_pcm,0			;patch $6C
	dc.l	sfx_crowdcheer_pcm,0	;patch $6D
	dc.l	sfx_bglass_pcm,0		;patch $6E
sfx_shotbh_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_shotbh_pcm.bin	;sample 2: shotbh
	even
sfx_pass_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_pass_pcm.bin	;sample 1: pass
	IF REV=0
	dc.b	$7D						;pad: Rev 0 leftover byte
	ELSE
	dc.b	PadByte
	ENDIF
sfx_oooh_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_oooh_pcm.bin	;sample 12: oooh, sfx_oooh2, sfx_bglass
	even
sfx_crowdboo_pcm					;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_crowdboo_pcm.bin	;sample 11: crowdboo
	IF REV=0
	dc.b	$7B						;pad: Rev 0 leftover byte
	ELSE
	dc.b	PadByte
	ENDIF
sfx_check_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_check_pcm.bin	;sample 5: check1, check3
	even
sfx_crowdcheer_pcm					;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_crowdcheer_pcm.bin	;sample 13: crowdcheer, homewin
	even
sfx_bglass_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_bglass_pcm.bin	;sample 14: sfx_bglass
	IF REV=0
	dc.b	$7D						;pad: Rev 0 leftover byte
	ELSE
	dc.b	PadByte
	ENDIF
sfx_playerwall_pcm					;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_playerwall_pcm.bin	;sample 6: playerwall, sfx_playerwall2-23
	even
sfx_check2_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_check2_pcm.bin	;sample 4: check2, check4
	IF REV=0
	dc.b	$7A						;pad: Rev 0 leftover byte
	ELSE
	dc.b	PadByte
	ENDIF
sfx_hithigh_pcm						;PCM samples 7 and 10: hithigh, hitlow, check1-4, songs $32 and $35-$37
	incbin	..\Extracted\Sound\sfx_hithigh_pcm.bin	;samples 7 and 10: hithigh, hitlow, check1-4, songs $32
													;and $35-$37
	even
sfx_shotfh_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_shotfh_pcm.bin	;sample 3: shotfh
	even
sfx_puckget_pcm						;raw PCM sample, played through the Z80 (pcm_sample_table)
	incbin	..\Extracted\Sound\sfx_puckget_pcm.bin	;sample 0: puckget
	even
fm_instrument_patches				;32 FM patches x 32 bytes, byte $1E = pitch bend scale
									;(UpdateChannelFrequencyAndVolume)
	incbin	..\Extracted\Sound\fm_instrument_patches.bin	;32 FM patches x 32 bytes (byte $1E = pitch bend
															;scale)
	even
SoundStreamTable					;event stream of sounds 0-$37 as offsets from the table
									;(play_sfx_or_music_track, stop_current_song)
	dc.w	sfx_siren_cmdstream-SoundStreamTable	;sound $0
	dc.w	sfx_beep1_cmdstream-SoundStreamTable	;sound $1
	dc.w	sfx_beep2_cmdstream-SoundStreamTable	;sound $2
	dc.w	sfx_whistle_cmdstream-SoundStreamTable	;sound $3
	dc.w	sfx_horn_cmdstream-SoundStreamTable	;sound $4
	dc.w	sfx_shotwiff_cmdstream-SoundStreamTable	;sound $5
	dc.w	sfx_stdef_cmdstream-SoundStreamTable	;sound $6
	dc.w	sfx_puckget_cmdstream-SoundStreamTable	;sound $7
	dc.w	sfx_oooh_cmdstream-SoundStreamTable	;sound $8
	dc.w	sfx_hithigh_cmdstream-SoundStreamTable	;sound $9
	dc.w	sfx_hitlow_cmdstream-SoundStreamTable	;sound $A
	dc.w	sfx_crowdcheer_cmdstream-SoundStreamTable	;sound $B
	dc.w	sfx_crowdboo_cmdstream-SoundStreamTable	;sound $C
	dc.w	sfx_oooh2_cmdstream-SoundStreamTable	;sound $D
	dc.w	sfx_bglass_cmdstream-SoundStreamTable	;sound $E
	dc.w	sfx_homewin_cmdstream-SoundStreamTable	;sound $F
	dc.w	sfx_pass1_cmdstream-SoundStreamTable	;sound $10
	dc.w	sfx_pass2_cmdstream-SoundStreamTable	;sound $11
	dc.w	sfx_pass3_cmdstream-SoundStreamTable	;sound $12
	dc.w	sfx_pass4_cmdstream-SoundStreamTable	;sound $13
	dc.w	sfx_shotbh1_cmdstream-SoundStreamTable	;sound $14
	dc.w	sfx_shotbh2_cmdstream-SoundStreamTable	;sound $15
	dc.w	sfx_shotbh3_cmdstream-SoundStreamTable	;sound $16
	dc.w	sfx_shotbh4_cmdstream-SoundStreamTable	;sound $17
	dc.w	sfx_shotfh1_cmdstream-SoundStreamTable	;sound $18
	dc.w	sfx_shotfh2_cmdstream-SoundStreamTable	;sound $19
	dc.w	sfx_shotfh3_cmdstream-SoundStreamTable	;sound $1A
	dc.w	sfx_shotfh4_cmdstream-SoundStreamTable	;sound $1B
	dc.w	sfx_check1_cmdstream-SoundStreamTable	;sound $1C
	dc.w	sfx_check2_cmdstream-SoundStreamTable	;sound $1D
	dc.w	sfx_check3_cmdstream-SoundStreamTable	;sound $1E
	dc.w	sfx_check4_cmdstream-SoundStreamTable	;sound $1F
	dc.w	sfx_playerwall_cmdstream-SoundStreamTable	;sound $20
	dc.w	sfx_playerwall2_cmdstream-SoundStreamTable	;sound $21
	dc.w	sfx_playerwall3_cmdstream-SoundStreamTable	;sound $22
	dc.w	sfx_playerwall4_cmdstream-SoundStreamTable	;sound $23
	dc.w	sfx_puckbody_cmdstream-SoundStreamTable	;sound $24
	dc.w	sfx_puckpost_cmdstream-SoundStreamTable	;sound $25
	dc.w	sfx_empty_cmdstream-SoundStreamTable	;sound $26
	dc.w	sfx_empty_cmdstream-SoundStreamTable	;sound $27
	dc.w	sfx_puckwall1_cmdstream-SoundStreamTable	;sound $28
	dc.w	sfx_puckwall2_cmdstream-SoundStreamTable	;sound $29
	dc.w	sfx_puckwall3_cmdstream-SoundStreamTable	;sound $2A
	dc.w	sfx_puckwall4_cmdstream-SoundStreamTable	;sound $2B
	dc.w	sfx_puckice1_cmdstream-SoundStreamTable	;sound $2C
	dc.w	sfx_puckice2_cmdstream-SoundStreamTable	;sound $2D
	dc.w	sfx_puckice3_cmdstream-SoundStreamTable	;sound $2E
	dc.w	sfx_puckice4_cmdstream-SoundStreamTable	;sound $2F
	dc.w	fmtune_goal_cmdstream-SoundStreamTable	;song $30
	dc.w	fmtune_periodstart_cmdstream-SoundStreamTable	;song $31
	dc.w	fmtune_lategame_cmdstream-SoundStreamTable	;song $32
	dc.w	fmtune_powerplay_cmdstream-SoundStreamTable	;song $33
	dc.w	fmtune_faceoff_cmdstream-SoundStreamTable	;song $34
	dc.w	fmtune_title_cmdstream-SoundStreamTable	;song $35
	dc.w	fmtune_eop_cmdstream-SoundStreamTable	;song $36
	dc.w	fmtune_scouting_cmdstream-SoundStreamTable	;song $37
sfx_beep1_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_beep1_cmdstream.bin	;sound 1 (SFXbeep1)
	even
sfx_empty_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_empty_cmdstream.bin	;sounds $26 and $27: empty stream
	even
sfx_beep2_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_beep2_cmdstream.bin	;sound 2 (SFXbeep2)
	even
sfx_horn_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_horn_cmdstream.bin	;sound 4
	even
sfx_stdef_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_stdef_cmdstream.bin	;sound 6
	even
sfx_puckget_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckget_cmdstream.bin	;sound 7, puckglue
	even
sfx_puckice1_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckice1_cmdstream.bin	;sound $2C: puck bounce by speed
	even
sfx_puckice2_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckice2_cmdstream.bin	;sound $2D
	even
sfx_puckice3_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckice3_cmdstream.bin	;sound $2E
	even
sfx_puckice4_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckice4_cmdstream.bin	;sound $2F (SFXpuckice, Endfaceoff)
	even
sfx_puckbody_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckbody_cmdstream.bin	;sound $24
	even
sfx_oooh_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_oooh_cmdstream.bin	;sound 8, off the post with the clock running
	even
sfx_puckpost_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckpost_cmdstream.bin	;sound $25
	even
sfx_playerwall_cmdstream			;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_playerwall_cmdstream.bin	;sound $20
	even
sfx_playerwall2_cmdstream			;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_playerwall2_cmdstream.bin	;sound $21: no caller found, same patches as
																;playerwall
	even
sfx_playerwall3_cmdstream			;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_playerwall3_cmdstream.bin	;sound $22: no caller found, same patches as
																;playerwall
	even
sfx_playerwall4_cmdstream			;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_playerwall4_cmdstream.bin	;sound $23: no caller found, same patches as
																;playerwall
	even
sfx_puckwall1_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckwall1_cmdstream.bin	;sound $28: puck off the wall by speed (wallcoll)
	even
sfx_puckwall2_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckwall2_cmdstream.bin	;sound $29
	even
sfx_puckwall3_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckwall3_cmdstream.bin	;sound $2A
	even
sfx_puckwall4_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_puckwall4_cmdstream.bin	;sound $2B
	even
sfx_whistle_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_whistle_cmdstream.bin	;sound 3
	even
sfx_shotwiff_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotwiff_cmdstream.bin	;sound 5
	even
sfx_check1_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_check1_cmdstream.bin	;sound $1C: tackle sounds in turn
	even
sfx_check2_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_check2_cmdstream.bin	;sound $1D
	even
sfx_check3_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_check3_cmdstream.bin	;sound $1E
	even
sfx_check4_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_check4_cmdstream.bin	;sound $1F
	even
sfx_pass1_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_pass1_cmdstream.bin	;sound $10: pass by puck height
	even
sfx_pass2_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_pass2_cmdstream.bin	;sound $11
	even
sfx_pass3_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_pass3_cmdstream.bin	;sound $12
	even
sfx_pass4_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_pass4_cmdstream.bin	;sound $13
	even
sfx_shotbh1_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotbh1_cmdstream.bin	;sound $14: backhand shot by speed
	even
sfx_shotbh2_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotbh2_cmdstream.bin	;sound $15
	even
sfx_shotbh3_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotbh3_cmdstream.bin	;sound $16
	even
sfx_shotbh4_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotbh4_cmdstream.bin	;sound $17
	even
sfx_shotfh1_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotfh1_cmdstream.bin	;sound $18: forehand shot by speed
	even
sfx_shotfh2_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotfh2_cmdstream.bin	;sound $19
	even
sfx_shotfh3_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotfh3_cmdstream.bin	;sound $1A
	even
sfx_shotfh4_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_shotfh4_cmdstream.bin	;sound $1B
	even
sfx_hithigh_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_hithigh_cmdstream.bin	;sound 9 (SFXhithigh)
	even
sfx_hitlow_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_hitlow_cmdstream.bin	;sound $A (SFXhitlow)
	even
sfx_homewin_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_homewin_cmdstream.bin	;sound $F: home team won (game end)
	even
sfx_crowdcheer_cmdstream			;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_crowdcheer_cmdstream.bin	;sound $B (SFXcrowdcheer)
	even
sfx_crowdboo_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_crowdboo_cmdstream.bin	;sound $C (SFXcrowdboo)
	even
sfx_bglass_cmdstream				;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_bglass_cmdstream.bin	;sound $E: wallcollb (puck over the wall)
	even
sfx_oooh2_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_oooh2_cmdstream.bin	;sound $D: injury
	;(setInjuryType), visiting goalie save
	even
sfx_siren_cmdstream					;sound effect event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\sfx_siren_cmdstream.bin	;sound 0
	even
fmtune_goal_cmdstream				;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_goal_cmdstream.bin	;song $30: Goal
	even
fmtune_periodstart_cmdstream		;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_periodstart_cmdstream.bin	;song $31: StartPer
	even
fmtune_lategame_cmdstream			;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_lategame_cmdstream.bin	;song $32: CheckLateGameSong, 3rd period
	even
fmtune_powerplay_cmdstream			;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_powerplay_cmdstream.bin	;song $33: updatepwrplay, home power play
	even
fmtune_faceoff_cmdstream			;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_faceoff_cmdstream.bin	;song $34: puckfaceoff
	even
fmtune_title_cmdstream				;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_title_cmdstream.bin	;song $35: TitleScreen, ExitToOpening
	even
	dc.l	fmtune_title_loop		;end of the intro: loop pointer
fmtune_title_loop					;looping body of the title song event stream
	incbin	..\Extracted\Sound\fmtune_title_loop_cmdstream.bin	;song $35 loop body
	even
	dc.l	fmtune_title_loop		;loop pointer
fmtune_eop_cmdstream				;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_eop_cmdstream.bin	;song $36: PeriodOver_sp, PlayoffScreen, StartHL2
	even
	dc.l	fmtune_eop_cmdstream+4	;loop pointer (past the first event)
fmtune_scouting_cmdstream			;song event stream (SoundStreamTable)
	incbin	..\Extracted\Sound\fmtune_scouting_cmdstream.bin	;song $37: ScoutingReport
	even
	dc.l	fmtune_scouting_cmdstream+4	;loop pointer (past the first event)
ScoutingReportText					;scouting report text
	incbin	..\Extracted\Text\ScoutingReportText.bin	;ScoutingReportText: scouting report paragraphs
	IF REV=0
	dc.b	$72						;pad: Rev 0 leftover byte
	ELSEIF REV=2
	dc.b	$0D						;pad: Rev B byte
	ELSE
	dc.b	0
	ENDIF
