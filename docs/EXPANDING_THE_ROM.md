# Expanding the ROM

`main` is a faithful disassembly of the retail cartridge: a stock build matches the retail 512 KB image. Changes a bigger ROM needs belong on a mod branch, not on `main`.

- `src/hockey93.asm` ends with `dcb.b $80000-*,$FF`, the fill to the 512 KB ROM end. Includes placed after that fill start at $80000 and do not move any retail code. A larger image also needs the header ROM end ($1A4) and the boot checksum updated (or `CHECKSUM=0`) on a mod branch.
- `CHECKSUM=0` skips the boot check (`build:dev`).

## Short jumps

### PC-relative branches (branch out of range)

SNASM's **Branch (n bytes) is out of range** is the ~±32 KB limit on **PC-relative** branches: **`bsr.w`**, **`bra.w`** and **`bxx.w`**. `tools/build.js` stops at the assemble step with `branch out of range` and points here.

Two patterns that break mod builds:

1. **New ROM inserted between existing modules.** Later files move forward in the image. Retail code may already branch with `.w` into a module far enough away that a few hundred bytes of insert pushes the branch past the limit. Put new code and data after the 512 KB fill in `src/hockey93.asm` instead.
2. **Hooks into post-fill code.** Includes after the 512 KB fill in `src/hockey93.asm` start at $80000. Any call from retail code into that region needs **`jsr (label).l`** / **`jmp (label).l`**. Code in the new region should not **`bsr.w`** distant retail helpers (for example shared `rts` labels); use **`.l`** calls or a **local `rts`**.

When the build prints branch out of range, fix placement and call mode using this section before changing unrelated branches.
