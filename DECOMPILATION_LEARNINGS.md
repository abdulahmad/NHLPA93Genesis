# DECOMPILATION_LEARNINGS.md

Notes for humans and models working on the NHLPA Hockey 93 Sega Genesis matching rebuild.
Read this before editing `src/`. A function is done only when the rebuilt ROM matches the target bytes.

Seeded from the public `NHLPA93Genesis` README / `fixopcodes.js` / `package.json`, then updated from the private disassembly tree `abdulahmad/EA-NHL-Disassembly-Project` at `NHL93-Genesis/` (commit `9a2a373`, 2026-10-04 read).

The `.idb` files were not parsed. They are IDA databases. The v1.1 `.lst` is 12MB and was not treated as current: the IDB is the up-to-date database, the listing may be stale. `rommap.md` is empty.

## Goal

Bitwise-perfect compilable source of NHLPA Hockey 93 for Sega Genesis.
This is a matching assembly rebuild, not a C decompilation. EA built it with a custom compiler.
The retail ROM is the answer key. The NHL 92 matching source is the cousin, not a file to paste over 93.

Requires the original ROM to extract assets and to validate the build. Do not commit ROMs to the public tree.

Status:

- All 68k code is source. `npm run build:retail` and `npm run build:reva` rebuild the retail and Rev A ROMs byte for byte, and every code segment also verifies on its own (`npm run seg:<name>`).
- The Z80 driver, sound data, team palettes and graphics are incbins of retail ROM slices. Slices start at the labels the code uses; a slice may still hold more than one asset.

## Where the real notes live

Private tree: `EA-NHL-Disassembly-Project/NHL93-Genesis/`

| File | What it is |
| --- | --- |
| `NHLPA Hockey 93 (USA, Europe) (v1.1).bin.idb` | Larger IDB (3.3MB). Treat as the labeled v1.1 database. |
| `nhlpa93retail.bin.idb` | Second IDB (3.0MB). Do not assume it matches the v1.1 database. |
| `NHLPA Hockey 93 (USA, Europe) (v1.1).bin.lst` | 12MB listing. May be older than the IDB. Re-export before trusting a name from it. |
| `discovery.md` | Team data, frame map, SPAList format, 92-to-93 frame shifts, cross-game anim starts. |
| `src/ram93.asm` | Ports, VDP status bits, structure fields and the named 68k RAM (retail addresses), laid out like NHL92 `ram.asm`. The only RAM map; `hockey93.asm` and every `*_stub.asm` include it. |
| `src/<segment>_stub.asm` | Single-segment build: `org` at the segment's retail address, outside labels as retail-address equates, then `include ram93.asm` and the segment. |
| `rommap.md` | Empty. |

`NHLPA Hockey 93 (USA, Europe) (Rev A) (EASN).md` is not a markdown doc. It is 524,288 bytes and has the same blob SHA as `nhlpa93retailRevA.bin`. Do not read it as notes.

ROM blobs in that private folder, for diffing only:

- `nhlpa93retail.bin` (v1.1 retail)
- `nhlpa93retailRevA.bin`
- `nhlpa93retailRevB.bin`

Rev B exists as a ROM (`1993.FEB`, version `-00`, region `UEJ`). It is not built. It is a separate later build, not a patch on Rev A: about 145 changed spots in the 68k code against Rev A (`Begin`, `ShowScores`, menus, `Readjoy1/2`, `DoDMA`, the Stanley Cup screen, the sound driver, text and tables), different team rosters, resized graphics, and the ROM ends at `$7E343`.

## Prior art

- NHL 92 matching source: `https://github.com/abdulahmad/NHL92Genesis`
- Original NHL 92 compile work: `https://github.com/Mhopkinsinc/NHLHockey`
- Chaos IDA databases and listings for NHL 92 through 95: `https://github.com/Chaos81/nhl94-disassembly`
- Asset tools: `https://github.com/abdulahmad/EA-NHL-Tools`
  - `.JIM` / `.JZIP`: `EA-NHL-Tools/JIM-Tools`
  - `.ANIM` export: `EA-NHL-Tools/ANIM94-To-BMP`

Do not relabel a function the v1.1 IDB or Chaos already named unless the bytes disagree.

## Build

Node, then `npm i` in the public `NHLPA93Genesis` repo. Copy the retail ROM in locally. Extract with:

```
npm run extractassets
```

`npm run extractassets` runs `src/extractAssets93-1.1.js` on `nhlpa93retail.bin` (CRC32 `CBBF4262`; any other file aborts with exit code 1). It is the only extractor. It writes the slices the `teamdata93.asm`, `sound93.asm` and `graphics93.asm` incbins need. Every build script runs it first.

Builds, from `package.json`:

| Script | Flags | Result |
| --- | --- | --- |
| `npm run build:retail` | `rev=0`, `checksum=1` | Retail, validation included, verified against `nhlpa93retail.bin`. Opcode-corrected output is `output/modified_nhl93.bin`. |
| `npm run build:reva` | `rev=1`, `checksum=1` | Rev A with validation, verified against `nhlpa93retailRevA.bin`. |
| `npm run build:dev` | `rev=1`, `checksum=0` | Rev A flags, no validation. Use this while editing. Not identical to `nhlpa93devRevA.bin` (that ROM has its own header and tail). |
| `npm run seg:<name>` | `rev=0` | One segment through `buildseg.bat`, `fixopcodes.js` and `verifySegment.js` against the retail ROM. |

Dev builds default to Rev A flags. Retail validation will refuse to boot if either checksum is wrong. `npm run build:reva` builds Rev A (`rev=1`, `checksum=1`) and verifies it byte for byte. There is no Rev B build.

## Checksums

There is no checksum generator in this repo (the old notes mention `generateChecksum.js`; it is not here). The retail and Rev A values are constants in the source: header word `$18E` (`sega/SegaIDTable93.asm`: retail `$2799`, Rev A `$FA57`) and the `ValidationRoutine` sum (`checksum93.asm`: retail `$EB689746`, Rev A `$C62A6024`). `ValidationRoutine` adds every ROM long from 0 up to itself, skipping the header long at `$18C`. A modified build with `checksum=1` shows a red screen at boot unless both values are recomputed.

## EA compiler opcode fixer

`fixopcodes.js` rewrites encodings in the built binary using the `.lst`, and writes `modified_<filename>`. Compare the modified file to the retail ROM, not the raw assembler output.

Known rewrites:

- `cmp` / `cmpi` family. EA encodings in `0Cxx` are rewritten to the `Bxxx` forms the ROM actually contains. Examples: `0C00` to `B03C`, `0C40` to `B07C`, `0C80` to `B0BC` (written `cmp.l` only: `cmpi.l #imm,d0` in `ValidationRoutine` is a real CMPI and keeps `0C80`), `0C07` to `BE3C`. The script is table-driven; add a row only when a new mismatch is a known EA encoding, not a logic bug.
- `exg a2, a1`: `C34A` to `C549`.
- `exg d1, d0`: `C141` to `C340`.
- Do not rewrite `exg d0, d1`. The script comment says this direction stays.

Operand order matters. A model that "fixes" an `exg` by swapping registers will match the mnemonic and miss the bytes.

## Retail vs Rev A vs Rev B

Retail vs Rev A is documented in the README ("Retail (REV=0) vs Rev A (REV=1)") and built from one source with `IF REV=1` blocks. Rev B has no notes beyond the summary above.

Do not copy NHL 92 Rev A diffs across. On 92, known examples included `move.l #Stack,sp` vs `move #Stack,sp`, an added `bsr KillCrowd`, and bitmasking in `ResolveGames`. Treat those as 92 facts until the same bytes are confirmed in 93.

## RAM and ports already named

`src/ram93.asm` is the symbol file (it replaced `stubinc/ram_addrs.inc`, `ports.inc`, `equals.inc` and `struct93.inc`). Do not invent a second RAM map.

Useful named regions, all in 68k RAM at `$FFFF....` unless noted:

- Puck: `puckx` `$B74A`, `pucky` `$B75E`, `puckz` `$B762`, `puckvx` `$B772`, `puckvy` `$B774`, `puckvz` `$B776`, `puckc` `$B7AA`.
- Camera / sort: `SortCords` `$B04A`, `Ylist` `$B84A`, `Hpos` `$BD1C`, `Vpos` `$BD18`, `CameraPosStruct` `$BE08`.
- Faceoff: `fox` `$BEA6`, `foy` `$BEA8`, `fodir1` `$BEAA`, `fodir2` `$BEAC`, `fodropx` `$B032`, `fodropy` `$B034`.
- Input: `pads` `$BDB4`, `PadControlBits` `$BE40`, `padcont` `$BE42`.
- Teams / score: `HomeTeam` `$C20C`, `VisTeam` `$C20E`, `hmtmstruct` `$C4E6`, `awtmstruct` `$C688`, `HomeTeamRosterPtr` `$C504`, `AwayTeamRosterPtr` `$C6A6`, `gameclock` `$C334`.
- Penalties: `PenBuf` `$C270`, `Penaltytimer` `$C2B4`, `InjCntDown` `$C2B8`, `icingPlayer` `$BE95`.
- Menu / season: `OptPlayMode` `$CAD6`, `playofflevel` `$CAD8`, `menuhometeam` `$CADA`, `menuawayteam` `$CADC`, `potree` `$C988`, `gamenum` `$C97A`.
- Sound bridge (retail; Rev A is 4 higher): `music_needs_z80_update` `$CB78`, `Z80_command_buffer` `$CB7A`, `fm_channel_structs` `$CD9C`, `fm_track_slots` `$CDC0`. `lastsfx` `$BF28`.
- Stack: `Stack` `$FFFFFFFE` (the reset vector uses `InitialSP` `$FFFFF6`).

The ports at the top of `ram93.asm` are standard Genesis: `VDP_DATA` `$C00000`, `VDP_CTRL` `$C00004`, `VDP_PSG` `$C00011`, `IO_Z80BUS` `$A11100`, `IO_Z80RES` `$A11200`, `IO_TMSS` `$A14000`. The VDP status bits follow them (`PAL_MODE`, `VBLANKING`, `FIFO_FULL`, and so on).

Many symbols are still `word_FF....` / `unk_FF....`. Rename those only from the IDB, then update `ram93.asm`.

## Sound

The 68000 side of the driver is source (`src/sound93.asm`); it is 93-only, not the NHL 92 driver. The Z80 driver is the extracted `z80_snd_drv93.bin`, with its FM patch bank address written as label expressions so it relocates. Do not replace the Z80 blob with a hand rebuild unless that rebuild matches the extracted bytes.

Hybrid driver: the 68000 runs 8 track slots of 4-byte events (`MusicTrackPointerTable`, sounds 0-`$2F` effects, `$30`-`$37` songs) and collects key/volume/frequency/patch changes in `Z80_command_buffer`. The Z80 drives the YM2612 and PSG, and streams PCM patches (`$60` up, `pcm_sample_table`) through the DAC. The README "Sound System Overview" has the event format and the tables.

The 92 tables in the old notes (SFX pointer table at `$1035C`, note/octave/envelope tables, FM tune table at `$10294`, `$80`-`$85` command bytes) do not exist in 93.

## Assets and file formats

Graphics, PCM, FM, event streams, team palettes and the Z80 driver come from the extract script. Slice starts are the labels the code uses. When a code reference and the extract bounds disagree, the code reference wins, then re-extract.

- `.JIM` / `.JZIP`: see EA-NHL-Tools `JIM-Tools`. 93 uses compressed `.JZIP` more aggressively than 92 because the game is packed under 512KB.
- `.ANIM`: see EA-NHL-Tools `ANIM94-To-BMP`. Default `.ANIM` palette does not color every 93 sprite (blood is the known miss).
- `.PAL`: Genesis CRAM, 2 bytes per color, `0000BBB0GGG0RRR0`.

Team data from `discovery.md` (big endian):

- `0x314`–`0x37B` team address. `0x37C`–`0x387` team 0 offsets. The 6th offset tracks something different in 93 than in 92. `0x388`–`0x3C7` home/away pals.
- 26 teams.
- Per team, relative pointers from the team block: player data `+0x00`, home palette `+0x02`, team name `+0x04`, lines `+0x06`, scouting report `+0x08`, unknown `+0x0A`.
- Home palette `0x0C`–`0x2B`, away palette `0x2C`–`0x4B`, 32 bytes each.
- Scouting report `0x4C`–`0x53`. Known nibbles: power play at byte 1 bits 7–4, shooting/skating at byte 4, passing/defense at byte 5, checking/fighting at byte 6, goalkeeping/overall at byte 7. Bytes 0, 2, 3 are still unknown.
- Unknown team data `0x54`–`0x55` (2 bytes).
- Lines `0x56`–`0x8D`: 7 x 8 bytes. G, LD, RD, LW, C, RW, extra attacker, alignment `00`.
- Player records are variable length. Name length includes alignment padding. Ratings are nibbles. Uniform number is tens in bits 7–4 and ones in bits 3–0. Goalie fields reuse the skater rating slots (glove hand, glove saves, stick saves, consistency).

`generateTeamData.js` and `generateFrameData.js` exist in the public repo. Prefer regenerating data from the ROM over hand-editing a table.

## Frames and SPAList

SPAList / Frames data: `0x4D8E`–`0x6445`. One note says the list itself starts at `0x4D90`. First observed frame value is `0x197` (407), `gready`.

92 animation record is 50 bytes (`0x32`): 16-byte pointer list, 2-byte flags, 8 directions x 4 bytes.

93 animation record is 306 bytes (`0x132`): same 16-byte pointer list and 2-byte flags, then 8 directions x 36 bytes. Do not parse 93 with the 92 stride.

92 frame record shape: 8 direction pointers, `animFlags`, then per direction a frame word and a time byte, repeated. Direction index in the 92 note skips from dir 5 to dir 7 in the header comment; the body lists dir 0–7. Check the bytes before trusting that comment.

Frame shifts from 92 to 93, from `discovery.md`:

- 93.371–376 new: fight fall and injured.
- 92.371 moves to 93.377 (+6).
- 93.393 new: instant replay cursor.
- 92.387 moves to 93.394 (+7).
- 92.486 = 93.493. 92.511 = 93.518. 92.512–535 are logos.
- 93.519–534 new goalie dive. 93.535–538 new goalie glove-wide save. 93.539–554 goalie stick-smack.
- 92.536–549 moves to 93.555–568 (+19).
- 93.569–584 new bat-puck. 93.585–600 new hook. 93.601–624 flail / off balance. 93.625–632 flip. 93.633–644 injured. 93.645–649 glass break.

SPF index constants in `discovery.md` still match the 92-style table (`SPFskatewp = 1` through `SPFSiren = 536`). Re-check them against the shifts above before using them as 93 indexes.

Animations that reuse direction pointers: `SPAwallright`, `SPAwallleft`, `SPAfaceoff`, `SPAfaceoffr`, `SPAsiren`, `SPAfight`, `SPAfgrab`, `SPAfheld`, `SPAfhigh`, `SPAflow`, `SPAfhith`, `SPAfhitl`, `SPAffall`. Animations that also repeat direction sprites: `SPAgstackr`, `SPAgstackl`, `SPApflip`.

Known extractor bugs, still open:

- Frame offset is not being added.
- The script assumes the gap between directions is constant. It must check all 8 directions before choosing an offset.
- `wallright` in 93 is being read as `0x5EB6`–`0x5F50`. The note says it should be `0x5EB6`–`0x5EF3`. 92 `wallright` is `0x44DE`–`0x451B`.

## Later games, animation starts only

Recorded in `discovery.md` so the 94/95 pass does not rediscover them. Not verified in this pass.

| Game | Animation data start |
| --- | --- |
| NHLPA 93 Genesis | `0x4D8E` |
| NHL 94 Genesis | `0x5B1C` |
| NHL 95 Genesis | `0x5A34` |
| NHL 96 Genesis | `0x5F96` |
| NHL 97 Genesis | `0x7947` |
| NHL 94 PC `Hockey.exe` | `0x358A6` |
| NHL 95 PC `Hockey.exe` | `0x110475` |
| NHL 96 PC | likely `0x1884D4`, another hit at `0x150820` |

95 skate sample was 8 frames. 96 shoot sample was 2 frames. Do not reuse the 93 36-byte direction stride on those without checking.

## Working rules

1. Build `dev` while editing. Switch to `retail` or `reva` only to prove a match.
2. Diff against NHL 92 before asking a model to write a function. Exact normalized-byte matches get ported by script.
3. Feed a model one function: disassembly, IDA name, callers, callees, strings, and the 92 cousin if one exists. Do not paste the ROM.
4. Five failed matching builds, then stop and write what differed. Do not let a session grind.
5. Commit only a change that still matches the target ROM.
6. Include `ram93.asm`. Do not rename `puckx` / `gameclock` / `PenBuf` out from under the IDB.
7. Change data through labels: an address written as a number does not move when code or data in front of it grows.
8. NHL 94 Genesis is next, using this tree as the base. NHL 95 PC is a different compiler and does not belong in this loop.

## Open items

- Re-export the v1.1 IDB to a fresh `.lst` or `functions.json` before any model session. The current listing may be stale.
- Confirm which IDB is canonical if `nhlpa93retail.bin.idb` and the v1.1 IDB disagree.
- Diff Rev B against Rev A (retail vs Rev A is done).
- Fix the frame extractor: add the frame offset, do not assume a constant direction gap, cut `wallright` at `0x5EF3`.
- Integrate a matching Z80 disassembly, or record why the blob stays.
- Tighten asset bounds from disassembly references.
- Fill `rommap.md`. It is empty.
