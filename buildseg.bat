@echo off
setlocal EnableDelayedExpansion

REM ==============================================
REM  Usage: build.bat <rom_name>
REM  Example: build.bat hockey93_01
REM
REM  Builds: src\<rom_name>.asm  →  output\<rom_name>.bin
REM ==============================================

if "%~1"=="" (
    echo.
    echo ERROR: No rom name provided
    echo.
    echo Usage:
    echo   %~nx0 ^<rom_name^>
    echo.
    echo Example:
    echo   %~nx0 hockey93_01
    echo.
    exit /b 1
)

set "ROM_NAME=%~1"
set "WORKSPACE=%~dp0"

REM Create output folder if missing
if not exist "%WORKSPACE%output" mkdir "%WORKSPACE%output"

REM Optional: disable checksum with environment variable
REM Example: set checksum=0 & build.bat hockey93_01
if not defined checksum set "checksum=1"

set "CHECKSUM_FLAG=/e CHECKSUM=1"
if "%checksum%"=="0" set "CHECKSUM_FLAG=/e CHECKSUM=0"

echo.
echo Building: %ROM_NAME%
echo ------------------------------
echo.

cd /d "%WORKSPACE%src" || (
    echo ERROR: Cannot find src folder
    exit /b 1
)

REM ──────────────────────────────────────────────
REM Main assembly command
REM ──────────────────────────────────────────────

"%WORKSPACE%assembler\Assembler.exe" ^
  /p /m /g ^
  /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ ^
  %CHECKSUM_FLAG% ^
  "%ROM_NAME%_stub.asm,%WORKSPACE%output\%ROM_NAME%.bin,%WORKSPACE%output\%ROM_NAME%,%WORKSPACE%output\%ROM_NAME%" ^
  > "%WORKSPACE%output\Build_%ROM_NAME%.log"

if errorlevel 1 (
    echo.
    echo *** ASSEMBLY FAILED ***
    echo Check output\Build_%ROM_NAME%.log
    echo.
) else (
    echo.
    echo Build completed.
    echo Output: output\%ROM_NAME%.bin
    echo Log:    output\Build_%ROM_NAME%.log
    echo.
)

cd /d "%WORKSPACE%"

endlocal