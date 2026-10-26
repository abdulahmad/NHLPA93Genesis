; =============================================================================
; NHLPA Hockey 93 Sega Genesis - Z80 sound driver
; =============================================================================
; Source for the Z80 program that p_initialZ80 (src/sound93.asm) copies into
; Z80 RAM at $0000 ($A00000 on the 68000 side). In the Rev 0 (retail) ROM
; these bytes sit at $16E52-$170DC (Z80_Program_Code). Built with asm80 (npm
; package, see README) into output/<mode>/obj/z80_snd_drv93.bin, which
; sound93.asm includes. This is a different driver from NHL 92's
; (src/sound/z80_snd_drv.asm in NHL92Genesis); names are shared where the
; job is the same (SetBank, the YM2612 equates).
;
; What the driver does
;   - Plays one 8-bit PCM sample on the YM2612 DAC (channel 6), reading it
;     straight out of 68000 ROM through the bank window ($8000-$FFFF). Each
;     sample byte is looked up in a 256-byte volume table (z80_dac_vol_page is the
;     table's page) before it is written to the DAC.
;   - The 68000 posts a command by writing the low byte of the jump at
;     z80_cmd (the operand of "jp nc" in the sample loop): $D1 makes the
;     loop jump to UpdateFmChannels (take the command buffer at z80_cmdbuf),
;     $29 makes it jump to Z80_Init (restart with the sample at z80_dac_start_addr).
;     Both put Z80Idle ($7D, MainLoop) back when they are done.
;   - Unlike NHL 92's driver it waits on the YM2612 busy flag (status bit 7)
;     before every register write.
;
; Shared RAM used by the 68000 (names as in src/sound93.asm):
;   $0002-$0022  z80_cmdbuf         copy of Z80_command_buffer (33 bytes)
;   $0023-$0025  z80_dac_start_addr       sample start address (high byte first)
;   $0026-$0028  z80_dac_next_addr  where playback continues after a 0 byte
;   $0083        z80_dac_vol_page        volume table page ($03-$1F)
;   $008E        z80_dac_step       sample step (fraction of a byte per pass)
;   $0096-$0097  z80_cmd, z80_cmd_high  target of the sample loop's jump
;
; The 68000 copies Z80ProgramLen ($295) bytes, 10 more than this image
; ($28B bytes): the pad byte after it and the first 9 bytes of
; pcm_sample_table land at $028B-$0294, below the stack top ($0295), and are
; never read as data.
;
; Assembler notes: asm80 labels are not case sensitive. Every byte of the
; output must equal the ROM except the FM patch address operands (see
; LoadPatchAddress), which sound93.asm supplies from fm_instrument_patches;
; the build compares the rest with the bytes extracted from the ROM.
; =============================================================================

        .binfrom 0
        .binto   Z80_DriverEnd-1       ; $28B bytes

; -----------------------------------------------------------------------------
; Hardware (Z80 address space on the Genesis)
; -----------------------------------------------------------------------------
YM2612_ADDR1        EQU $4000   ; YM2612 part I register select / status
YM2612_DATA1        EQU $4001   ; YM2612 part I data
BANK_REGISTER       EQU $6000   ; 68000 bank select: 9 serial writes of bit 0
BANK_WINDOW         EQU $8000   ; 32 KB window onto 68000 memory

; IX points at YM2612_ADDR1 (part I) or, after SelectPart, at $4002 (part II):
; (ix+0) register select, (ix+1) data.
YM_LFO              EQU $22     ; LFO enable and frequency
YM_LFO_TIMER_KEY    EQU $28     ; Key on/off: bits 0-2 channel code, bits 4-7 operators
YM_DAC_DATA         EQU $2A     ; DAC sample byte
YM_DAC_ENABLE       EQU $2B     ; Bit 7: channel 6 plays the DAC
YM_DT_MUL           EQU $30     ; First per-operator register (+ channel 0-2)
YM_TL_OP1           EQU $40     ; Total level, operator 1 (+ channel 0-2)
YM_TL_OP4           EQU $4C     ; Total level, operator 4 (+ channel 0-2)
YM_FNUM_LOW         EQU $A0     ; Frequency number low 8 bits (+ channel 0-2)
YM_FNUM_HIGH        EQU $A4     ; Block (octave) and frequency high bits (+ channel 0-2)

YM_KEY_ON_ALL_OPS   EQU $F0     ; Added to the channel code: all 4 operators on
DAC_ENABLED         EQU $80     ; YM_DAC_ENABLE value: DAC on
DAC_DISABLED        EQU $00     ; YM_DAC_ENABLE value: DAC off
LFO_ON_4            EQU $0C     ; YM_LFO value: LFO on, frequency 4

Z80_STACK_TOP       EQU $0295   ; = Z80ProgramLen; the stack grows down from here
VOLUME_PAGE_FULL    EQU $1F     ; Loudest volume table (divisor 8, unchanged)

; Command buffer layout (cb_* in sound93.asm, here as Z80 addresses)
CB_KEYOFF           EQU z80_cmdbuf+0    ; bit per output channel: key off
CB_KEYON            EQU z80_cmdbuf+1    ; bit per output channel: key on (bit 6 also turns the DAC off)
CB_VOLUME           EQU z80_cmdbuf+2    ; bit per output channel: write the volume
CB_FREQ             EQU z80_cmdbuf+3    ; bit per output channel: write the frequency
CB_PATCH            EQU z80_cmdbuf+4    ; bit per output channel: load the patch
CB_VOLUMES          EQU z80_cmdbuf+5    ; 7 bytes: attenuation per output channel
CB_FREQS            EQU z80_cmdbuf+12   ; 7 words: block/frequency high byte, then low byte
CB_PATCHES          EQU z80_cmdbuf+26   ; 7 bytes: patch number per output channel

PATCH_FB_ALG        EQU $1C     ; Patch byte written to register $B0 (feedback/algorithm)
PATCH_REG_BYTES     EQU $1E     ; Patch bytes written to the YM2612 (registers $30-$9C, $B0, $B4)

; FM patch address, patched by sound93.asm (see LoadPatchAddress). The
; values here are the Rev 0 ones so the image matches that ROM.
FM_PATCHES_WINDOW   EQU $830A   ; $8000 + (fm_instrument_patches & $7FFF)
FM_PATCHES_BANK     EQU $05     ; fm_instrument_patches >> 15

; -----------------------------------------------------------------------------
; $0000: entry point
; -----------------------------------------------------------------------------
        org $0000
Z80_DriverStart:
        jr Z80_Init

; -----------------------------------------------------------------------------
; Shared data
; -----------------------------------------------------------------------------
z80_cmdbuf:                     ; $0002: Z80_command_buffer and its tables (33 bytes)
        db $00,$00,$00,$00,$00  ; key off, key on, volume, frequency, patch bits
        db $FF,$FF,$FF,$FF,$FF,$FF,$FF                      ; volumes
        db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; frequencies
        db $FF,$FF,$FF,$FF,$FF,$FF,$FF                      ; patches
z80_dac_start_addr:                   ; $0023: sample start, 24-bit, high byte first
        db $00,$00,$00
z80_dac_next_addr:              ; $0026: read when a sample byte is 0 (the second long of the
        db $00,$00,$00          ; pcm_sample_table entry, 0 in every entry). What playing on from
                                ; there is meant to do is unclear.

; -----------------------------------------------------------------------------
; $0029: Z80_Init. Reset target and the 68000's "play sample" command ($29).
; -----------------------------------------------------------------------------
Z80_Init:
        di
        ld sp,Z80_STACK_TOP
        im 0
        ld hl,MainLoop
        ld (z80_cmd),hl                 ; no command pending
        ld ix,YM2612_ADDR1
Start_Wait1:
        bit 7,(ix+0)
        jr nz,Start_Wait1
        ld (ix+0),YM_DAC_ENABLE
Start_Wait2:
        bit 7,(ix+0)
        jr nz,Start_Wait2
        ld (ix+1),DAC_ENABLED
Start_Wait3:
        bit 7,(ix+0)
        jr nz,Start_Wait3
        ld (ix+0),YM_LFO
Start_Wait4:
        bit 7,(ix+0)
        jr nz,Start_Wait4
        ld (ix+1),LFO_ON_4
        ld iy,z80_dac_start_addr
        jr DacStartSample

DacSampleEnd:                           ; a 0 byte: carry on from z80_dac_next_addr
        ld iy,z80_dac_next_addr
DacStartSample:                          ; HL = address & $FFFF, bank = address >> 15
        ld h,(iy+1)
        ld l,(iy+2)
        ld a,h
        rla                             ; carry = address bit 15
        ld a,(iy+0)
        rla
        ld (z80_dac_start_bank),a
        jp DacStartSample_load_bank

; -----------------------------------------------------------------------------
; $007D: sample loop (Z80Idle). One DAC byte per pass.
; -----------------------------------------------------------------------------
MainLoop:
        ld (ix+0),YM_DAC_DATA
        ld e,(hl)                       ; sample byte
        db $16                          ; ld d,n
z80_dac_vol_page:                            ; $0083: volume table page, set by the 68000
        db VOLUME_PAGE_FULL
        ld a,(de)                       ; byte through the volume table
        or a
        jp z,DacSampleEnd               ; 0 ends the sample data
        ld (YM2612_DATA1),a
        ld a,c
        db $C6                          ; add a,n
z80_dac_step:                           ; $008E: step, set by the 68000; the carry out of
        db $00                          ; C advances HL by one byte (0: HL never moves)
        ld c,a
        ld de,$0000
        adc hl,de
        db $D2                          ; jp nc,nn
z80_cmd:                                ; $0096: jump target. Low byte: Z80Idle ($7D, MainLoop) or a
        dw MainLoop                      ; command from the 68000 ($D1 UpdateFmChannels, $29 Z80_Init)
z80_cmd_high        EQU z80_cmd+1       ; $0097: jump target high byte, always 0

DacStartSample_load_bank:                             ; HL ran past $FFFF (or a new address): next bank
        ld a,h
        or $80                          ; back into the bank window
        ld h,a
        db $3E                          ; ld a,n
z80_dac_start_bank:                           ; $009D: bank of the sample data
        db $00
        call SetBank
        inc a
        ld (z80_dac_start_bank),a             ; the bank to select when HL wraps again
        scf
        ccf                             ; clear carry
        jp z80_cmd-1                    ; to the jp nc in MainLoop

; -----------------------------------------------------------------------------
; $00AA: SetBank. Select the 32 KB 68000 bank A for the window: nine writes
; of bit 0, low bit first. A is unchanged on return.
; -----------------------------------------------------------------------------
SetBank:
        scf
        ccf
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra
        ld (BANK_REGISTER),a
        rra                             ; nine RRAs through a cleared carry: A restored
        ret

; -----------------------------------------------------------------------------
; $00D1: UpdateFmChannels (command $D1). The 68000 has copied Z80_command_buffer
; to z80_cmdbuf. E counts the output channel (0-2 part I, 4-6 part II).
; -----------------------------------------------------------------------------
UpdateFmChannels:
        push hl
        push bc
        ld e,$FF                        ; key off
        ld a,(CB_KEYOFF)
KeyOffChannel_next:
        inc e
        srl a
        jr nc,KeyOffChannel_skip
KeyOffChannel_wait1:
        bit 7,(ix+0)
        jr nz,KeyOffChannel_wait1
        ld (ix+0),YM_LFO_TIMER_KEY
KeyOffChannel_wait2:
        bit 7,(ix+0)
        jr nz,KeyOffChannel_wait2
        ld (ix+1),e                     ; channel E, no operators: key off
        or a
KeyOffChannel_skip:
        jr nz,KeyOffChannel_next

        ld e,$FF                        ; patch load
        ld a,(CB_PATCH)
LoadPatch_next:
        inc e
        srl a
        jr nc,LoadPatch_skip
        push af
        call LoadPatchAddress           ; HL = patch in the bank window
        call SelectPart
        add a,YM_DT_MUL
        ld d,a                          ; register
        ld b,PATCH_REG_BYTES
LoadPatch_wait1:
        bit 7,(ix+0)
        jr nz,LoadPatch_wait1
        ld (ix+0),d
        ld c,(hl)
        inc hl
LoadPatch_wait2:
        bit 7,(ix+0)
        jr nz,LoadPatch_wait2
        ld (ix+1),c
        inc d
        inc d
        inc d
        inc d                           ; next operator / register group
        ld a,b
        cp 3
        jr nz,LoadPatch_no_gap
        ld a,d
        add a,$10                       ; after $9C: skip to $B0, $B4
        ld d,a
LoadPatch_no_gap:
        djnz LoadPatch_wait1
        ld ix,YM2612_ADDR1
        pop af
LoadPatch_skip:
        jr nz,LoadPatch_next

        ld e,$FF                        ; frequency
        ld a,(CB_FREQ)
SetChannelFrequency_next:
        inc e
        srl a
        jr nc,SetChannelFrequency_skip
        push af
        ld hl,CB_FREQS
        ld a,e
        sla a
        add a,l
        ld l,a                          ; HL = the channel's frequency word
        call SelectPart
        add a,YM_FNUM_HIGH
SetChannelFrequency_wait1:
        bit 7,(ix+0)
        jr nz,SetChannelFrequency_wait1
        ld (ix+0),a
        ld d,(hl)
SetChannelFrequency_wait2:
        bit 7,(ix+0)
        jr nz,SetChannelFrequency_wait2
        ld (ix+1),d
        sub YM_FNUM_HIGH-YM_FNUM_LOW
SetChannelFrequency_wait3:
        bit 7,(ix+0)
        jr nz,SetChannelFrequency_wait3
        ld (ix+0),a
        inc hl
        ld d,(hl)
SetChannelFrequency_wait4:
        bit 7,(ix+0)
        jr nz,SetChannelFrequency_wait4
        ld (ix+1),d
        ld ix,YM2612_ADDR1
        pop af
SetChannelFrequency_skip:
        jr nz,SetChannelFrequency_next

        ld e,$FF                        ; volume: the total level of every carrier
        ld a,(CB_VOLUME)
SetChannelVolume_next:
        inc e
        srl a
        jp nc,SetChannelVolume_skip
        push af
        call LoadPatchAddress
        ld a,l
        add a,PATCH_FB_ALG
        ld l,a
        ld a,h
        adc a,0
        ld h,a
        ld a,(hl)
        and 7                           ; algorithm
        ld c,1                          ; carriers: 1 for algorithms 0-3,
        cp 4
        jr c,SetChannelVolume_count
        inc c                           ; 2 for 4,
        cp 5
        jr c,SetChannelVolume_count
        inc c                           ; 3 for 5-6,
        cp 7
        jr c,SetChannelVolume_count
        inc c                           ; 4 for 7
SetChannelVolume_count:
        ld hl,CB_VOLUMES
        ld a,e
        add a,l
        ld l,a
        call SelectPart
        add a,YM_TL_OP4                 ; operator 4, then 3, 2, 1 (register -4 each)
SetChannelVolume_wait1:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait1
        ld (ix+0),a
        ld d,(hl)
SetChannelVolume_wait2:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait2
        ld (ix+1),d
        dec c
        jr z,SetChannelVolume_done
        sub 4
SetChannelVolume_wait3:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait3
        ld (ix+0),a
SetChannelVolume_wait4:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait4
        ld (ix+1),d
        dec c
        jr z,SetChannelVolume_done
        sub 4
SetChannelVolume_wait5:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait5
        ld (ix+0),a
SetChannelVolume_wait6:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait6
        ld (ix+1),d
        dec c
        jr z,SetChannelVolume_done
        sub 4
SetChannelVolume_wait7:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait7
        ld (ix+0),a
SetChannelVolume_wait8:
        bit 7,(ix+0)
        jr nz,SetChannelVolume_wait8
        ld (ix+1),d
SetChannelVolume_done:
        ld ix,YM2612_ADDR1
        pop af
SetChannelVolume_skip:
        jp nz,SetChannelVolume_next

        ld e,YM_KEY_ON_ALL_OPS-1        ; key on
        ld a,(CB_KEYON)
        bit 6,a
        jr z,KeyOnChannel_next                 ; channel 6 key on: DAC off first
KeyOnChannel_wait1:
        bit 7,(ix+0)
        jr nz,KeyOnChannel_wait1
        ld (ix+0),YM_DAC_ENABLE
KeyOnChannel_wait2:
        bit 7,(ix+0)
        jr nz,KeyOnChannel_wait2
        ld (ix+1),DAC_DISABLED
KeyOnChannel_next:
        inc e
        srl a
        jr nc,KeyOnChannel_skip
KeyOnChannel_wait3:
        bit 7,(ix+0)
        jr nz,KeyOnChannel_wait3
        ld (ix+0),YM_LFO_TIMER_KEY
KeyOnChannel_wait4:
        bit 7,(ix+0)
        jr nz,KeyOnChannel_wait4
        ld (ix+1),e                     ; channel E, all operators on
        or a
KeyOnChannel_skip:
        jr nz,KeyOnChannel_next

        ld a,(z80_dac_start_bank)             ; the patch loads moved the bank: select
        dec a                           ; the sample's bank again
        ld (z80_dac_start_bank),a
        ld hl,MainLoop
        ld (z80_cmd),hl                 ; command done
        pop bc
        pop hl
        jp DacStartSample_load_bank

; -----------------------------------------------------------------------------
; $025B: LoadPatchAddress. HL = the window address of the patch of channel E
; (CB_PATCHES), its bank selected. The ld bc / ld a operands are
; FM_PATCHES_WINDOW and FM_PATCHES_BANK; sound93.asm writes them from
; fm_instrument_patches, so they follow the data in every revision.
; -----------------------------------------------------------------------------
LoadPatchAddress:
        ld hl,CB_PATCHES
        ld a,e
        add a,l
        ld l,a
        ld a,(hl)                       ; patch number (H is 0)
        ld l,a
        sla l
        rl h
        sla l
        rl h
        sla l
        rl h
        sla l
        rl h
        sla l
        rl h                            ; * 32 bytes
        db $01                          ; ld bc,nn
z80_fm_patches_window:                  ; $0278 (68000: Z80_Program_Code+$278)
        dw FM_PATCHES_WINDOW
        add hl,bc
        db $3E                          ; ld a,n
z80_fm_patches_bank:                    ; $027C
        db FM_PATCHES_BANK
        jp SetBank

; -----------------------------------------------------------------------------
; $0280: SelectPart. Channel E 0-2: A = E, IX = part I. 4-6: A = E-4,
; IX = part II ($4002).
; -----------------------------------------------------------------------------
SelectPart:
        ld a,e
        cp 3
        ret c
        inc ix
        inc ix
        sub 4
        ret
Z80_DriverEnd:
