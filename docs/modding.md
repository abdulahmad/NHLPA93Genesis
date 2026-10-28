# Modding

Building your own version, supported ROMs, known limitations and tips.

## Developing on this build
Build with `build:dev` (`checksum=0`): `Start` skips `jsr ValidationRoutine` and the header checksum is 0, so changed code still boots. With `checksum=1` the validation routine sums the ROM, and any change turns the screen red. There is no checksum generator in this repo. `build:dev` is not identical to `nhlpa93devRevA.bin`: that ROM has its own header (`1992.MAY`, titles `NHLPA HOCKEY` / `NHL HOCKEY`, product `T-50236`) and different bytes from `$7FBA4` to the end.

Because the source uses labels, code and data can grow or move. Add new RAM to `src/ram93.asm`. Sound and graphics files come from `Extracted/`; replace a file there (keeping its name) to change an asset, or add an `incbin` with a label.

## Player names
`src/teamdata93.asm` is anonymized: each `Player` row has a placeholder (`P001___`) instead of the real NHLPA name, followed by the real ratings. The extractor reads the names from your ROM into `Extracted/PlayerNames.txt` (one per line, in row order) and the build's `names` step assembles a copy with them put back (`output/obj/teamdata93.asm`). To change a player's name, edit that line of `Extracted/PlayerNames.txt` (keep its length: the row length is written into the data) and build; `npm run clean` or a changed ROM re-extracts the original. To add a player, add a `Player` row with a placeholder of the new name's length and the matching line in the names file. To change ratings, edit the row in `src/teamdata93.asm`.

## Supported ROMs
`tools/extractAssets93.js` finds the version of the ROM it is given by SHA-1 and reads each slice at that version's address (Rev A: every slice from the Z80 driver at `$16E52` on is `$2E` bytes higher). Both give the same `Extracted/` files. Any other ROM (a bad dump, a hack, a prototype such as the `1993.FEB` or `1992.MAY` builds) is refused with its SHA-1, size and header.

| Version | Header | File | SHA-1 |
| --- | --- | --- | --- |
| Rev 0 (v1.0, "retail") | `1992.JUL`, `GM T-50396 -00` | `nhlpa93retail.bin` (usual name) | `8efc1cacb079ea223966dda065c16c49e584cac2` |
| Rev A (v1.1) | `1992.OCT`, `GM T-50396 -01` | `nhlpa93retailRevA.bin` (usual name) | `2ab048fc7209df28b00ef47f2f686f5b7208466e` |
| Rev B (v1.2) | `1993.FEB`, `GM T-50396 -00` | `nhlpa93retailRevB.bin` (usual name) | `76c0f3d4665ffcd53adfffaa27fc4dded694f8f7` |

`npm run extractassets` extracts from the retail ROM, `npm run extractassets:reva` from the Rev A ROM and `npm run extractassets:revb` from the Rev B ROM. The builds extract automatically when needed (`tools/prebuild.js`).

## Known Issues/Limitations
- **Z80 sound driver**: source in `src/sound/z80_snd_drv93.asm` (asm80). A changed driver no longer matches the ROM bytes, so the build's z80 step reports a mismatch.
- **Asset boundaries**: graphics and sound slices start at the labels the code uses; a few files may contain more than one asset.
- **Checksum sensitivity**: `build:retail` / `build:reva` / `build:revb` need the exact retail ROM for the extracted files; with validation on, any change stops the game at boot.

## Modding Tips
- **Custom music / SFX**: add an event stream file and an `incbin` with a label in `sound93.asm`, then point a `MusicTrackPointerTable` entry at it (`dc.w <label>-MusicTrackPointerTable`).
- **New samples**: add the sample with a label and use it in `pcm_sample_table` (patch `$60` + index).
- **Testing**: build `build:dev` so checksum validation does not lock the game.
