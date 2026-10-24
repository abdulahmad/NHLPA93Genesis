# NHLPA93Genesis

See [CONTRIBUTING.md](CONTRIBUTING.md) for how changes are made (names, comments, layout, verification).

> **Work in progress:** this disassembly is unfinished and unpolished, and is being actively worked on. Expect labels, file layout and docs to change.

## 🚧 Current Status

- 99% done.
- Remaining: any changes to make it consistent with the downstream disassemblies (93S, 94G, etc.).

A work-in-progress attempt at reverse engineering a bitwise perfect compilable source of NHLPA Hockey 93 for Sega Genesis. Requires original ROM file to build.

Built on the work that McMarkis (https://github.com/Mhopkinsinc/NHLHockey) did to get the NHL 92 source compiling, and my work to make the code bitwise perfect to the retail version. Also references chaos' disassembly work of NHL 92-94 (https://github.com/Chaos81/nhl94-disassembly).

Status: all 68k code is source and the Rev 0 (v1.0, the "retail" ROM), Rev A (v1.1) and Rev B (v1.2) ROMs build bitwise perfect from it. The Z80 sound driver, the sound data (PCM samples, FM patches, event streams), the team palettes and the graphics are incbins of slices extracted from the retail ROM; anything in them that holds a ROM address is source, so the data follows the code.

## Features of this version:
- Rev 0 / v1.0 (`1992.JUL -00`, build mode `retail`), Rev A / v1.1 (`1992.OCT -01`, build mode `reva`) and Rev B / v1.2 (`1993.FEB -00`, build mode `revb`) ROMs build bitwise perfect from the same source (`IF REV` blocks)
- Label-based source: RAM, ports and structure equates live in `src/ram93.asm` (laid out like NHL 92 `ram.asm`), and the code and data use labels instead of addresses
- Script which changes opcodes to match the custom compiler EA used to build the game (`tools/fixopcodes.js`)
- Disassembled Retail Validation Check code (`checksum93.asm`) included via the checksum env variable
- Script to extract assets from the retail ROM (team palettes, graphics, PCM samples, FM patches, sound event streams, Z80 sound driver, scouting report text)
- One build script, `tools/build.js`, for Windows and Linux/macOS (wine)
- Documentation of the file formats used within the game
- Requires the retail ROM

## Instructions

1. Install node from https://nodejs.org/en/download if it isn't already installed on your machine

2. In the `NHLPA93Genesis` folder, run `npm i` to install `node_modules`

3. Copy the NHLPA Hockey 93 Sega Genesis retail ROM file into the `NHLPA93Genesis` folder as `nhlpa93retail.bin`. Copy the Rev A ROM as `nhlpa93retailRevA.bin` if you want to verify Rev A builds

    | ROM | File name | SHA-1 | Size |
    | --- | --- | --- | --- |
    | Rev 0, v1.0 "retail" (`1992.JUL`, `GM T-50396 -00`) | `nhlpa93retail.bin` | `8efc1cacb079ea223966dda065c16c49e584cac2` | 524288 bytes |
    | Rev A, v1.1 (`1992.OCT`, `GM T-50396 -01`) | `nhlpa93retailRevA.bin` | `2ab048fc7209df28b00ef47f2f686f5b7208466e` | 524288 bytes |
    | Rev B, v1.2 (`1993.FEB`, `GM T-50396 -00`) | `nhlpa93retailRevB.bin` | `76c0f3d4665ffcd53adfffaa27fc4dded694f8f7` | 524288 bytes |

4. Build one of 4 versions. Everything runs through `tools/build.js` (node; on Windows it runs the assembler directly, on Linux/macOS under wine). Each build first runs `tools/prebuild.js`, which checks the ROM by SHA-1 and size (and stops with the expected file name, SHA-1 and size if it is missing or wrong), then extracts the assets into `Extracted/` if they are missing or incomplete. It then assembles `src/hockey93.asm`, fixes the opcodes and verifies the result.

    - `npm run build:retail`: the Rev 0 (v1.0) ROM (`REV=0`), verified byte for byte against `nhlpa93retail.bin`
    - `npm run build:reva`: the `Rev A` ROM (`REV=1`), verified byte for byte against `nhlpa93retailRevA.bin`
    - `npm run build:revb`: the `Rev B` ROM (`REV=2`), verified byte for byte against `nhlpa93retailRevB.bin`
    - `npm run build:dev`: for developing your own version. `Rev A` code without the checksum validation check (not verified against any ROM)

    Each version has its own folder: the built ROM is `output/retail/nhl93.bin`, `output/reva/nhl93.bin`, `output/revb/nhl93.bin` or `output/dev/nhl93.bin`, and that folder's `obj/` holds the intermediates (the assembler's binary, listing and log).

Other scripts:
- `npm run assets`: ROM check and asset extraction only (`npm run extractassets`, `extractassets:reva` and `extractassets:revb` run the extractor directly)
- `npm run clean`: delete `output/` and `Extracted/` (re-extracted by the next build)
- `tools/verify_all.sh`: extracts fresh and builds retail and Rev A, printing MATCH for each
- Add `--verbose` to `node tools/build.js ...` for the full tool output

## Build steps explained

`tools/build.js` prints one line per step with a short note under it, and the step's result under that:

1. **prebuild**: check the ROM and extract graphics, sound and text assets into `Extracted/`.
2. **assemble**: SNASM68k turns `src/hockey93.asm` into a raw ROM image.
3. **fixopcodes**: patch the instructions where SNASM picks a different encoding than EA's original assembler.
4. **verify**: compare byte-for-byte with the retail or Rev A ROM. Dev builds are not verified.

In a terminal, each step turns a spinner while it runs and is redrawn with a green check or a red cross when it ends. The colours are off when the output is not a terminal, with `NO_COLOR` set, or with `--no-color`. A failing step prints `FAILED` (or `MISMATCH`), the relevant log lines (`output/<mode>/obj/Build_nhl93.log` for the assembler) and `BUILD FAILED at <step>`, and exits 1.

# Documentation

The documentation lives in [`docs/`](docs/README.md):

- [Rev 0, Rev A and Rev B](docs/retail-vs-reva.md): what differs between the three ROM versions (v1.0, v1.1 and v1.2) and what `REV` changes
- [Sound system](docs/sound-system.md): the 68000 driver, sound numbers, event streams, patches and samples
- [File formats](docs/file-formats.md): `.map.jim`, `.anim`, `.pal`, packed tiles, strings, sound files and the team data layout
- [Modding](docs/modding.md): developing on this build, supported ROMs, known issues, tips
- [Conventions](docs/conventions.md): naming lineage, comment rules, local labels

## AI assistance

This project is AI-assisted. The work is directed by a strict ruleset and curated by hand, with the aim of producing correctly labelled and commented code that matches the spirit of what the original source code would have been. We can't guarantee it's perfect, and ultimately this will always be a work in progress. If you see something that needs fixing, raise an issue, or even better, raise a PR.

## Credits

Thanks to chaos, StaticEck, McMarkis and Drezz for their help with the disassembly.

Special thanks to smozoma and kingraph, whose past contributions to the NHL modding community made this work easier.
