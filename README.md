# NHLPA93Genesis

> **📀 Game data is not included.** This repository has the assembly code only. The graphics, team palettes, sound samples, music and the NHLPA player names are extracted from your own copy of the original ROM when you build, and are not in the repo. You need the NHLPA Hockey 93 Genesis ROM for the build you want (Rev 0, Rev A or Rev B), with the file names and SHA-1s listed under [Instructions](#instructions), or the build stops.

> **🤝 Making a mod, hack, port or other derivative work from this repo? You must credit me and everyone credited in this repo, clearly, in your own repo and in every release. See [Credits and derivative works](#credits-and-derivative-works).**

See [CONTRIBUTING.md](CONTRIBUTING.md) for how changes are made (names, comments, layout, verification).

> **Work in progress:** this disassembly is unfinished and unpolished, and is being actively worked on. Expect labels, file layout and docs to change.

## 🚧 Current Status

- 99% done.
- Remaining: any changes to make it consistent with the downstream disassemblies (93S, 94G, etc.).

Reverse engineered source of NHLPA Hockey 93 for Sega Genesis NHLPA Hockey 93 for Sega Genesis. Requires original ROM file to build.

Built on the work that McMarkis (https://github.com/Mhopkinsinc/NHLHockey) did to get the NHL 92 source compiling, and my work to make the code bitwise perfect to the retail version. Also references chaos' disassembly work of NHL 92-94 (https://github.com/Chaos81/nhl94-disassembly).

Status: all 68k code is source and the Rev 0 (v1.0, the "retail" ROM), Rev A (v1.1) and Rev B (v1.2) ROMs build bitwise perfect from it. The Z80 sound driver is commented Z80 source (`src/sound/z80_snd_drv93.asm`, assembled with asm80). The sound data (PCM samples, FM patches, event streams), the team palettes and the graphics are incbins of slices extracted from the retail ROM, and the player names are put back from the ROM at build time (the source has placeholders); anything in them that holds a ROM address is source, so the data follows the code.

## Features of this version:
- Rev 0 / v1.0 (`1992.JUL -00`, build mode `retail`), Rev A / v1.1 (`1992.OCT -01`, build mode `reva`) and Rev B / v1.2 (`1993.FEB -00`, build mode `revb`) ROMs build bitwise perfect from the same source (`IF REV` blocks)
- Label-based source: RAM, ports and structure equates live in `src/ram93.asm` (laid out like NHL 92 `ram.asm`), and the code and data use labels instead of addresses
- Script which changes opcodes to match the custom compiler EA used to build the game (`tools/fixopcodes.js`)
- Disassembled Retail Validation Check code (`checksum93.asm`) included via the checksum env variable
- Z80 sound driver is real, commented Z80 source (`src/sound/z80_snd_drv93.asm`), assembled with asm80 and checked byte-for-byte against the ROM
- Script to extract assets from the retail ROM (team palettes, graphics, PCM samples, FM patches, sound event streams, scouting report text)
- One build script, `tools/build.js`, for Windows and Linux/macOS (wine)
- Documentation of the file formats used within the game
- Requires the retail ROM

## Instructions

1. Install node from https://nodejs.org/en/download if it isn't already installed on your machine

2. In the `NHLPA93Genesis` folder, run `npm i` to install `node_modules` (this includes [asm80](https://www.npmjs.com/package/asm80), pinned in `package.json`, the Z80 assembler for the sound driver)

3. Copy the NHLPA Hockey 93 Sega Genesis retail ROM file into the `NHLPA93Genesis` folder (`nhlpa93retail.bin` is the usual name, but any file name works: the build finds each ROM by its SHA-1 and size, `tools/roms.js`). Copy the Rev A ROM there too if you want to verify Rev A builds

    | ROM | File name | SHA-1 | Size |
    | --- | --- | --- | --- |
    | Rev 0, v1.0 "retail" (`1992.JUL`, `GM T-50396 -00`) | `nhlpa93retail.bin` (usual name) | `8efc1cacb079ea223966dda065c16c49e584cac2` | 524288 bytes |
    | Rev A, v1.1 (`1992.OCT`, `GM T-50396 -01`) | `nhlpa93retailRevA.bin` (usual name) | `2ab048fc7209df28b00ef47f2f686f5b7208466e` | 524288 bytes |
    | Rev B, v1.2 (`1993.FEB`, `GM T-50396 -00`) | `nhlpa93retailRevB.bin` (usual name) | `76c0f3d4665ffcd53adfffaa27fc4dded694f8f7` | 524288 bytes |

4. Build one of 4 versions. Everything runs through `tools/build.js` (node; on Windows it runs the assembler directly, on Linux/macOS under wine). Each build first runs `tools/prebuild.js`, which checks the ROM by SHA-1 and size (and stops with the expected file name, SHA-1 and size if it is missing or wrong), then extracts the assets into `Extracted/` if they are missing or incomplete. It then assembles the Z80 sound driver with asm80 and `src/hockey93.asm`, fixes the opcodes and verifies the result.

    - `npm run build:retail`: the Rev 0 (v1.0) ROM (`REV=0`), verified byte for byte against `nhlpa93retail.bin`
    - `npm run build:reva`: the `Rev A` ROM (`REV=1`), verified byte for byte against `nhlpa93retailRevA.bin`
    - `npm run build:revb`: the `Rev B` ROM (`REV=2`), verified byte for byte against `nhlpa93retailRevB.bin`
    - `npm run build:dev`: for developing your own version. `Rev A` code without the checksum validation check (not verified against any ROM)

    The built ROM is `output/retail/nhl93.bin`, `output/reva/nhl93.bin`, `output/revb/nhl93.bin` or `output/dev/nhl93.bin`. The intermediates (Z80 driver, team data with names, the assembler's binary, listing and log) go to one shared `output/obj/` folder, which every build empties and regenerates for its own mode; run builds one at a time.

Other scripts:
- `npm run assets`: ROM check and asset extraction only (`npm run extractassets`, `extractassets:reva` and `extractassets:revb` run the extractor directly)
- `npm run clean`: delete `output/` and `Extracted/` (re-extracted by the next build)
- `tools/verify_all.sh`: extracts fresh and builds retail and Rev A, printing MATCH for each
- Add `--verbose` to `node tools/build.js ...` for the full tool output

## Build steps explained

`tools/build.js` prints one line per step with a short note under it, and the step's result under that:

1. **prebuild**: check the ROM and extract graphics, sound and text assets into `Extracted/`.
2. **z80**: asm80 assembles the Z80 sound driver `src/sound/z80_snd_drv93.asm` into `output/obj/z80_snd_drv93.bin` (asm80 writes its listing `z80_snd_drv93.lst` next to it) and checks it byte-for-byte against the driver bytes at `Z80_Program_Code`, which the prebuild extracts to `Extracted/Sound/z80_snd_drv93.bin` only for this check. The FM patch address operands (Z80 `$278`-`$27C`) are skipped: `src/sound/sound93.asm` writes them from `fm_instrument_patches`, so they differ between revisions. `src/sound/sound93.asm` includes the assembled file around them.
3. **names**: `src/teamdata93.asm` has placeholders instead of the NHLPA player names (they are licensed data and are not in the repository). The prebuild extracts the real names from your ROM into `Extracted/PlayerNames.txt`, and this step writes them into a copy, `output/obj/teamdata93.asm`, which `src/hockey93.asm` includes. A name must have the length of its placeholder.
4. **assemble**: SNASM68k turns `src/hockey93.asm` into a raw ROM image.
5. **fixopcodes**: patch the instructions where SNASM picks a different encoding than EA's original assembler.
6. **verify**: compare byte-for-byte with the Rev 0, Rev A or Rev B ROM. Dev builds are not verified.

In a terminal, each step turns a spinner while it runs and is redrawn with a green check or a red cross when it ends. The colours are off when the output is not a terminal, with `NO_COLOR` set, or with `--no-color`. A failing step prints `FAILED` (or `MISMATCH`), the relevant log lines (`output/obj/Build_nhl93.log` for the assembler) and `BUILD FAILED at <step>`, and exits 1.

# Documentation

The documentation lives in [`docs/`](docs/README.md):

- [Rev 0, Rev A and Rev B](docs/retail-vs-reva.md): what differs between the three ROM versions (v1.0, v1.1 and v1.2) and what `REV` changes
- [Sound system](docs/sound-system.md): the 68000 driver, sound numbers, event streams, patches and samples
- [File formats](docs/file-formats.md): `.map.jim`, `.anim`, `.pal`, packed tiles, strings, sound files and the team data layout
- [Modding](docs/modding.md): developing on this build, supported ROMs, known issues, tips
- [Conventions](docs/conventions.md): naming lineage, comment rules, local labels

## AI assistance

This project is AI-assisted. The work is directed by a strict ruleset and curated by hand, with the aim of producing correctly labelled and commented code that matches the spirit of what the original source code would have been. We can't guarantee it's perfect, and ultimately this will always be a work in progress. If you see something that needs fixing, raise an issue, or even better, raise a PR.

## Credits and derivative works

Thanks to chaos, StaticEck, McMarkis and Drezz for their help with the disassembly.

Special thanks to smozoma and kingraph, whose past contributions to the NHL modding community made this work easier.

And thank you to the [original developers of the game](https://www.mobygames.com/game/11455/nhlpa-hockey-93/credits/genesis/).

This project is the result of my work and the work of the people credited above. If you build anything from it, including mods, ROM or EXE hacks, ports, released forks, tools, or any other derivative work, you must credit us:

- Put the credit in your repo's README, near the top and not buried in a footer, and in the notes of every release you publish, including any text file shipped inside a release archive.
- Name me and link to this repository.
- Name everyone credited here: chaos, StaticEck, McMarkis (Mhopkinsinc) and Drezz, with special thanks to smozoma and kingraph.
- If you only use part of this repo (docs, a tool, labels, a file format description), the credit still applies.
- If you are unsure, over-credit.

Credit is the condition for using this work. Please do not release a derivative without it.
