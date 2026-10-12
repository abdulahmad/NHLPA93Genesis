@echo off
setlocal

REM Get the directory of this batch file
set "workspaceFolder=%~dp0"

REM Set default values for rev and checksum if not provided
if not defined rev set rev=0
if not defined checksum set checksum=1

REM Pre-step: tools\prebuild.js checks the ROM and Extracted/ and extracts the assets if they are missing
REM or incomplete; it stops the build with the ROM path, SHA-1 and size if the ROM is missing. The npm
REM scripts run it first and set NHL_PREBUILD_DONE; tools/verify_all.sh does the same under wine.
set "prebuildTarget=retail"
if "%rev%"=="1" set "prebuildTarget=reva"
if not defined NHL_PREBUILD_DONE (
    node "%workspaceFolder%tools\prebuild.js" %prebuildTarget% || exit /b 1
)

@REM echo Using rev=%rev% and checksum=%checksum%

REM Create the output directory
if not exist "%workspaceFolder%output" mkdir "%workspaceFolder%output"

REM Change to the workspace src directory
cd /d "%workspaceFolder%src"

REM Determine revision flag: 0 = retail (1992.JUL -00), 1 = Rev A (1992.OCT -01)
set revFlag="/e REV=0"
set revName=retail
if "%REV%"=="1" (
    set revFlag="/e REV=1"
    set revName=reva
)
ECHO building %revName%

REM Determine checksum flag
if "%checksum%"=="0" (
    set checksumFlag="/e CHECKSUM=0"
) else (
    set checksumFlag="/e CHECKSUM=1"
)

REM Run the assembler with all flags. hockey93.asm is the top level (92 hockey.asm): ROM map includes + $FF fill.
REM Relative paths keep SNASM's summary line readable (it garbles it with long paths). SNASM always
REM exits 0 and writes no .bin when there are errors, so a missing or empty .bin means the build failed.
if exist "..\output\nhl93.bin" del "..\output\nhl93.bin"
"%workspaceFolder%assembler\Assembler.exe" ^
  /p /m /g ^
  /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ ^
  %revFlag% %checksumFlag% ^
  "hockey93.asm,..\output\nhl93.bin,..\output\nhl93,..\output\nhl93" ^
  > "..\output\Build93.log"

set "built=0"
for %%A in ("..\output\nhl93.bin") do if %%~zA GTR 0 set "built=1"
if not "%built%"=="1" (
    echo *** ASSEMBLY FAILED *** see output\Build93.log
    type "..\output\Build93.log"
    exit /b 1
)
type "..\output\Build93.log"
echo Assembled output\nhl93.bin

endlocal
