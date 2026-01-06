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