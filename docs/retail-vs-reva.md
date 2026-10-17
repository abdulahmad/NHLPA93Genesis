# Retail (REV=0) vs Rev A (REV=1)

How the two shipped versions of the ROM differ, and what the `REV` build flag changes in the source.

Both build from the same source (`IF REV=1` blocks). Retail is `1992.JUL` version `-00`; Rev A is `1992.OCT` version `-01`.

## Overall Differences Between Retail (REV=0) vs Rev A (REV=1)
- Rev A supports 50 Hz: `Begin` stores the VDP PAL bit in `music_global_tick_counter`. When it is set, `updateplayers` moves skaters 20 units per frame instead of 16, and `p_music_vblank` runs the music track slots a second time every 6th frame.
- Rev A adds two RAM words (`music_global_tick_counter`, `music_tick_divider`) before `databuffer`, so every variable from `databuffer` up is 4 bytes higher (`ram93.asm` handles it).
- Retail has a `SecurityCheck` `$FFFF` word before `ValidationRoutine`; Rev A does not. The checksums differ (header `$2799` / `$FA57`, ROM sum `$EB689746` / `$C62A6024`).

## Specific Differences and Comments
- Header: Rev A writes the title `NHLPA HOCKEY '93` in capitals.
- Code addresses move by +`$E` after `Begin`, +`$18` after `updateplayers` and +`$2E` after `p_music_vblank`. The source uses labels, so the moves are automatic, including the sound data's absolute pointers (PCM sample table, song loop pointers, the Z80 driver's FM patch bank address).
- Pad bytes: retail has leftover values in 11 pad bytes (`Setplass .alist`, `ButtonLabelCharTable`, `bfasciicon`, `priolist`, `PlayoffTreeSetup`, the Z80 driver end, four PCM sample ends and the scouting text end); Rev A has 0.
