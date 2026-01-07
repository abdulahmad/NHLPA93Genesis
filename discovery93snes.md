93SNES .80:BF9C-C16B -- part of penalty.asm (strings)
92Genesis 0x966C-0x9830 -- same part of penalty.asm

93 SNES .80:FFC0-FFFE -- cart header
92Genesis 0x0000-01F0 -- cart header

93SNES .83:80F8-C4A9 -- Teamdata.asm
92Genesis 0x116C-32DA -- same part of Teamdata.asm

93SNES .83:D630 -- start of scouting report intro text
93Genesis 0x2CEC8 -- start of scouting report intro text

93SNES .84:FAEC -- part of penalty.asm:DisplayStats
92Genesis 0xA784 -- part of penalty.asm:DisplayStats

93SNES .84:FDC8 -- 'Ice','Bench','Inj P','Inj G','Right','Left
93Gen 0x78E8-7972 -- 'Ice','Bench','Injury P','Injury G','Righty','Lefty

93SNES .84:FAAA-FCF4 -- Title Screen Credits
93Gen 0x4B3C-4D7E -- Title screen credits

93SNES .8D:F8D7 -- part of penalty.asm:StartHL2 'Highlight from game:"
92Gen 0xAC98 -- part of penalty.asm:StartHL2 'Highlight from game:"

93SNES .8F:8248 -- part of penalty.asm:PerLabels 'Final'
92Gen 0xA34E -- part of penalty.asm:PerLabels 'Final'

93SNES .8F:89A5 - part of penalty.asm:GameLabels 'EASN Hockey Night'
92 Gen 0xAB16 - start of GameLabels
93Gen 0xF6CC - part of penalty.asm:GameLabels 'EASN Hockey Night'

93SNES .8F:D7A3 - part of ???? 'Status ]'
93Gen 0x156AF  - part of ???? 'Status ]'

93SNES .8F:DF68 - Scouting Report labels
93Gen 0x13050 - Scouting Report labels
92Gen 0xE00E hockey.asm:ScoutingReport.pnm -- Scouting Report Labels

935NES .8F:EDC8 - part of hockey.asm:PauseMode:.mlist 'Resume game'
92Gen 0x4D60 - part of hockey.asm:PauseMode:.mlist 'Resume game'
93Gen 0x15937 - part of hockey.asm:PauseMode:.mlist 'Resume game'

92Gen 0xE878 - part of hockey.asm:setoptions:cpo 'Continue Playoffs
93SNES .8F:F395 - part of hockey.asm:setoptions:cpo 'Cont. Playoffs
93Gen 0x13D49 - part of hockey.asm:setoptions:cpo 'Continue Playoffs

93 Gen 0x14E59 - 'GOAL' 'HAT TRICK!'
93SNES .8F:FFE1 - 'GOAL' 'HAT TRICK!'

93SNES tile data is 4bpp planar composite (2x2bpp) -- starts around 0x709A7
94 SNES tile data is same -- starts around 0x10F4C-0x75880
94 SNES Frame Data - 0x10000-0x10F3F


Frame 1 frame data starts 0x10F40-0x10F6A -- 9 tiles, 2B in length (43) - 7 bytes extra
Frame 1 tile data starts 0x10F6B
03 80 09 00 FA FF 07 00 E2 FF 04 00 A0 00 80 00 2B 00 02 E4 00 00 FA FF E2 FF 00 08 FF FA FF F2 FF 02 08 FF FE FF 02 00 04 08 00

03 80 09 00 FA FF 07 00 E2 FF 04 00 A0 00 80 00 2B 00 02 E4 00 00 FA FF E2 FF 00 08 FF FA FF F2 FF 02 08 FF FE FF 02 00 04 08 00

Frame 2 frame data starts 0x1108B-0x110C3 -- 11 tiles, 39 in length (57) - 13 bytes extra
Frame 2 tile data starts 0x110C4
05 80 0B 00 F7 FF 09 00 E3 FF 05 00 C0 00 A0 00 39 00 01 E5 00 00 FD FF E3 FF 00 08 FF F7 FF F3 FF 02 08 FF 07 00 FB FF 04 08 00 F8 FF 03 00 05 08 00 00 00 03 00 14 08 00

0x10584 - frame header for frame 353, points to
DC 63 04
AKA 563DC

 0xEEA0A-EEA19 in SNES 94 is part of the PFLIP animation (direction 4-7)
 93GEN 0x52AA-52B9 is the equivalent of above

 0xEE0FC-EFF6E (1E73) = 94 SNES animation data

 93GEN is 0x4D83-6445 (16B8) 

 .9B:C002 read_frame_header_and_adjust_hotspot: ; CODE XREF: sub_9E8C35+43↓P
.9B:C002                               ; sub_9EEB2E+66↓P
.9B:C002                               ; Reads frame data pointer from table, extracts signed byte hotspot/offset values at +$12/+$13,
.9B:C002                               ; applies flip negations based on orientation flags, and optional 90-degree rotation transform.
.9B:C002                               ; Input: A = index (transferred to Y for RAM lookup)
.9B:C002                               ; Output: Adjusted X/Y hotspots in word_7E00A5 (X) and word_7E00A9 (Y)
.9B:C002                               ; Uses: X (preserved), Y (temp), word_7E000C/000E (temp long pointer)
.9B:C002
.9B:C002               PHX             ; Preserve original X
.9B:C003               TAY             ; Y = input index
.9B:C004               LDA word_7E0D97,Y ; Load frame number or state from RAM table
.9B:C007               DEC             ; frame_index - 1
.9B:C008               ASL             ; \
.9B:C009               ASL             ; / *4 for table offset (assuming 4-byte entries)
.9B:C00A               TAX             ; X = table index
.9B:C00B               LDA frame_data_header,X ; Load low 16-bit offset to frame data
.9B:C00F               CLC
.9B:C010               ADC #$8000      ; Add base address low
.9B:C013               STA D,word_7E000C ; Store to temp pointer low
.9B:C015               LDA word_828002,X ; Load high/bank offset
.9B:C019               ADC #$82        ; Add base bank
.9B:C01C               STA D,word_7E000E ; Store to temp pointer bank (forms 24-bit pointer)
.9B:C01E               TYX             ; Y = original X (unused here?)
.9B:C01F               LDY #$12        ; Y = $12 (offset 18 decimal into frame data)
.9B:C022               LDA [D,word_7E000C],Y ; Load byte at frame_data + $12 (likely X hotspot/offset)
.9B:C024               AND #$FF        ; Mask to byte
.9B:C027               CMP #$80        ; Check if signed negative (>= $80)
.9B:C02A               BCC sign_extend_x_done ; If < $80, positive - skip sign extend
.9B:C02C               ORA #$FF00      ; Else, sign extend to negative word
.9B:C02F
.9B:C02F sign_extend_x_done:             ; CODE XREF: read_frame_header_and_adjust_hotspot+28↑j
.9B:C02F               STA D,word_7E00A5 ; Store adjusted X hotspot/offset
.9B:C031               INY             ; Y = $13 (offset 19 decimal)
.9B:C032               LDA [D,word_7E000C],Y ; Load byte at frame_data + $13 (likely Y hotspot/offset)
.9B:C034               AND #$FF        ; Mask to byte
.9B:C037               CMP #$80        ; Check if signed negative
.9B:C03A               BCC sign_extend_y_done ; If < $80, positive - skip
.9B:C03C               ORA #$FF00      ; Else, sign extend
.9B:C03F
.9B:C03F sign_extend_y_done:             ; CODE XREF: read_frame_header_and_adjust_hotspot+38↑j
.9B:C03F               STA D,word_7E00A9 ; Store adjusted Y hotspot/offset
.9B:C041               LDA word_7E0E03,X ; Load orientation flags for this frame
.9B:C044               BIT #$800       ; Test bit 11 (horizontal flip/mirror flag?)
.9B:C047               BEQ no_hflip    ; If clear, skip negate
.9B:C049               LDA #0
.9B:C04C               SEC
.9B:C04D               SBC D,word_7E00A5 ; Negate X
.9B:C04F               STA D,word_7E00A5
.9B:C051
.9B:C051 no_hflip:                       ; CODE XREF: read_frame_header_and_adjust_hotspot+45↑j
.9B:C051               LDA word_7E0E03,X ; Reload flags (redundant, but original)
.9B:C054               BIT #$1000      ; Test bit 12 (vertical flip/mirror flag?)
.9B:C057               BNE no_vflip    ; If set, skip negate (inverted logic: clear = apply flip)
.9B:C059               LDA #0
.9B:C05C               SEC
.9B:C05D               SBC D,word_7E00A9 ; Negate Y
.9B:C05F               STA D,word_7E00A9
.9B:C061
.9B:C061 no_vflip:                       ; CODE XREF: read_frame_header_and_adjust_hotspot+55↑j
.9B:C061               LDA word_7E15DA ; Load potential rotation/mode flag
.9B:C064               BEQ no_rotation ; If zero, skip transform
.9B:C066               LDA D,word_7E00A5 ; Load current X
.9B:C068               LDY D,word_7E00A9 ; Load current Y to Y reg
.9B:C06A               EOR #$FFFF
.9B:C06D               INC             ; Negate X (+1 for two's complement)
.9B:C06E               STA D,word_7E00A9 ; Store -old_X as new Y
.9B:C070               STY D,word_7E00A5 ; Store old_Y as new X (90° clockwise rotation)
.9B:C072
.9B:C072 no_rotation:                    ; CODE XREF: read_frame_header_and_adjust_hotspot+62↑j
.9B:C072               PLX             ; Restore original X
.9B:C073               RTL             ; Return long
.9B:C073 ; End of function read_frame_header_and_adjust_hotspot

0xF4820 -- found patterns 49 FF FF 1A 29 03 00
0xF4F40 found 49 FF FF 1A 48 29 30 00 0A 0A 0A 0A 0A 0A
Search for flip calculation patterns: The position adjustment for flips is distinctive and likely shared.
For y flip: AND #$03, INC, ASL A thrice (*8), EOR #$FFFF, INC, SEC, SBC y_rel
Hex pattern: 29 03 00, 1A, 0A 0A 0A, 49 FF FF, 1A, 38, E5 xx (or ED xx xx for absolute)

For x flip: AND #$C0, ADC #$40, ASL A, EOR #$FFFF, INC, SEC, SBC x_rel
Hex pattern: 29 C0 00, 69 40 00, 0A, 49 FF FF, 1A, 38, E5 xx

These are close to the Genesis logic and appear in the provided SNES function for hotspots (negation with #0 SEC SBC). Search for clusters of ASL, EOR #$FFFF, INC, SEC, SBC.