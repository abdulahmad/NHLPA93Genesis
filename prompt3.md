I want you to help me reverse engineer NHLPA93 for Sega Genesis. I will give you some context and what resources we have at our disposal.

NHL Hockey for Sega Genesis is interchangably known as NHL92. NHLPA93 is interchangably known as NHL93. NHLPA93 is the sequel to NHL92.

NHL92Genesis - this is the bitwise perfect source code for NHL Hockey for Sega Genesis. Code is compiled with SNASM68K
NHL92Genesis\extractAssets92.js - extracts the data assets from the NHL92 ROM
NHL92Genesis\fixopcodes.js - does a patch to the built rom by SNASM68K to change some opcodes as the compiler that EA used for NHL92 made some different decisions for certain operations
NHL92Genesis\NHL92Genesis Back Cover.md - back cover of NHL 92 box. Gives an idea of the feature set of NHL92 and is a comparison point to NHLPA93.
NHL92Genesis\NHL92Genesis Manual - manual for NHL92. Another document that gives an idea of the feature set of NHL92 and is a comparison point to NHLPA93.
NHL92Genesis\src - contains the source code
NHL92Genesis\nhl92retail.bin - the final retail binary for NHL92
NHL92Genesis\nhl92  retail.lst - the code listing for NHL92-- helps line up the source code with the binary

NHLPA93Genesis - this is an in progress reverse engineering of NHLPA93.
NHLPA93Genesis\extractAssets93.js - extracts the data assets from the NHLPA93 ROM-- some data assets are not defined, and some assets may be off by a few bytes
NHLPA93Genesis\fixopcodes.js - does a patch to the built rom by SNASM68K to change some opcodes as the compiler that EA used for NHLPA93 made some different decisions for certain operations
NHLPA93Genesis\NHLPA93Genesis Back Cover.md - back cover of NHLPA93 box. Gives an idea of the feature set of NHLPA93 and is a comparison point to NHL92.
NHLPA93Genesis\NHLPA93Genesis Manual - manual for NHLPA93. Another document that gives an idea of the feature set of NHLPA93 and is a comparison point to NHL92.
NHLPA93Genesis\src - contains the source code which is a partial reverse engineering. It's accurate up to the end of frames93.asm as compared to nhlpa93retail.bin
NHLPA93Genesis\nhlpa93retail.bin - the first revision retail binary for NHLPA93 -- dated July 1992
NHLPA93Genesis\nhlpa93retailRevA.bin - the second revision retail binary for NHLPA93 -- dated October 1992
NHLPA93Genesis\nhlpa93retailRevB.bin - the third revision retail binary for NHLPA93 -- dated February 1993. This one removes the references to EASN/EA Sports Network as ESPN threatened a lawsuit due to EASN being too close to ESPN.
NHLPA93Genesis\nhl93  .lst - the code listing for the source code so far for NHLPA93. Built using the build:dev package script. Other than some shifted addresses and missing checksum check, the code is accurate with v1.0 up to 0x6445. It is also similarly in line with v1.1/Rev A other than some shifted address, missing checksum check and the ROM header/info being slightly different.
NHLPA93Genesis\nhlpa93.bin - the build for the reverse engineered source code so far for NHLPA93. Built using the build:dev package script. Other than some shifted addresses and missing checksum check, the code is accurate with v1.0 up to 0x6445. It is also similarly in line with v1.1/Rev A other than some shifted address, missing checksum check and the ROM header/info being slightly different.

chaos-93-94gen-disasm\NHLPA Hockey 93*.* -- these are IDA Pro files for reverse engineering NHLPA Hockey 93. In particular, some of the functions and variables have been labelled in this.
NHLPA93Genesis\nhlpa93retailRevA.lst -- partially labelled code listing for 1.1/REV A of NHLPA93. This is extracted from the IDA Pro files.

I want you to understand the feature differences to expect between NHL92 and NHLPA93 from the back covers and manuals. 
I want you to understand the NHL92 code base from NHL92Genesis\src. 
I want you to understand the labelled code listing of NHLPA93 from NHLPA93Genesis\nhlpa93retailRevA.lst.
I want you to understand the code that has been reverse engineered so far by looking at NHLPA93Genesis\src and NHLPA93Genesis\nhlpa93retailRevA.lst

Please do whatever else you need to do to understand the task.

Then I want you to finish reverse engineering NHLPA93 Genesis based on all the data above-- the source code from after frame93.asm and onwards needs to be completed.