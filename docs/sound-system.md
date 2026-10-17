# Sound System

The 68000 sound driver, the sound numbers, the event streams and the data the Z80 and the samples use.

## Overview
The 68k side of the driver is source (`src/sound93.asm`, `p_turnoff` ... `ClearAllTrackAndSFXSlots`); the Z80 side is the incbin `z80_snd_drv93.bin`. There is no NHL 92 code in it: 92 used a different driver.

- **Sound numbers**: `sfx` and `song` both call `play_sfx_or_music_track`. Sounds 0-`$2F` are effects, `$30`-`$37` are songs (`$30` goal, `$31` period start, `$32` third period, `$33` power play, `$34` faceoff, `$35` title, `$36` end of game / playoffs / highlights, `$37` scouting report). Starting a song stops the one already playing.
- **Track slots**: 8 slots at `fm_track_slots` (long event pointer, delay). `p_music_vblank` runs every slot once per frame; in Rev A, at 50 Hz, it runs them again every 6th frame.
- **Event streams**: `MusicTrackPointerTable` holds word offsets of the 56 streams (`sfx_<name>_cmdstream`, `fmtune_<name>_cmdstream`). An event is 4 bytes: delay before it, status (bits 6-4 command, bits 3-0 MIDI channel), two data bytes. Commands: `$0x` key off, `$1x` key on (note, volume; volume 0 = key off), `$4x` set the channel's patch, `$6x` pitch bend; `$2x`, `$3x`, `$5x`, `$7x` are ignored. Status 0 ends the stream; a non-negative long after it is a loop pointer (songs `$35`-`$37`).
- **Channels**: 6 channel structs (`fm_channel_structs`; the 6th, `pcm_channel_struct`, is the PCM channel). A key on takes an off channel that already has the patch, else the oldest channel.
- **FM patches**: `fm_instrument_patches`, 32 patches of 32 bytes (byte `$1E` is the pitch bend scale). The Z80 reads them through the 32K bank window (bank `fm_instrument_patches>>15`).
- **PCM**: patches `$60` and up are samples. `pcm_sample_table` has 15 entries (sample address, 0); the 68k copies them to Z80 RAM `$23`-`$28` and posts command `$29`. The 12 samples are `sfx_<name>_pcm` (signed 8-bit).
- **68k to Z80**: changes collect in `Z80_command_buffer` (key off / key on / volume / frequency / patch bits, then 7 volumes, 7 frequency words, 7 patches) and are copied to Z80 RAM `$02` with command `$D1` when the Z80 is idle.
- **Z80 start**: `p_initialZ80` copies `$295` bytes from `Z80_Program_Code` (`$16E52`) to Z80 RAM and builds 29 volume tables of 256 bytes below Z80 `$2000`.
