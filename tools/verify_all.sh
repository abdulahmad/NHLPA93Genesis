#!/bin/bash
export WINEDEBUG=-all
# tools/prebuild.js runs here with Linux node (fresh extract, ROM check); the .bat files skip it (no node under wine).
export NHL_PREBUILD_DONE=1
cd "$(dirname "$0")/.."
fail=0
for rev in 0 1; do
  t=nhlpa93retail.bin; p=retail; [ $rev = 1 ] && { t=nhlpa93retailRevA.bin; p=reva; }
  rm -rf Extracted; node tools/prebuild.js $p >/tmp/x93.log 2>&1 || { echo "PREBUILD FAIL $t"; cat /tmp/x93.log; fail=1; continue; }
  rm -f output/nhl93.bin output/modified_nhl93.bin
  wine cmd /c "set rev=$rev&& set checksum=1&& build93.bat" >/tmp/b93.log 2>&1 || { echo "ASM FAIL rev$rev"; fail=1; continue; }
  grep -q '^[1-9][0-9]* error' output/Build93.log && { fail=1; echo "ERR in log rev$rev"; grep -i error output/Build93.log|head; }
  [ -s output/nhl93.bin ] || { echo "no bin rev$rev"; fail=1; continue; }
  node tools/fixopcodes.js "output/nhl93 .lst" output/nhl93.bin >/dev/null 2>&1
  node tools/verifyRom.js output/modified_nhl93.bin $t 2>&1 | tail -2
done
rm -rf Extracted; node tools/prebuild.js retail >/tmp/x93.log 2>&1 || { echo 'PREBUILD FAIL retail'; cat /tmp/x93.log; fail=1; }
for s in $(node -e 'for(const k in require("./package.json").scripts) if(k.startsWith("seg:")&&k!="seg:sound93-data") console.log(k)'); do
  cmd=$(node -e "console.log(require('./package.json').scripts['$s'])")
  seg=$(echo "$cmd" | grep -oP 'buildseg.bat \K\S+'); off=$(echo "$cmd" | grep -oP 'bin \K0x[0-9A-F]+' | head -1)
  rm -f output/$seg.bin
  wine cmd /c "buildseg.bat $seg" >/tmp/bs.log 2>&1
  [ -s output/$seg.bin ] || { echo "$seg ASM FAIL"; fail=1; continue; }
  grep -q "^[1-9][0-9]* error" output/Build_$seg.log 2>/dev/null && { echo "$seg ASM ERRORS"; fail=1; }
  node tools/fixopcodes.js "output/$seg .lst" output/$seg.bin $off >/dev/null 2>&1
  rest=$(echo "$cmd" | grep -oP 'tools/verifySegment.js \K.*')
  r=$(node tools/verifySegment.js $rest 2>&1 | grep -iE "match|differ|fail" | head -2 | tr "\n" " "); echo "$seg: $r"
done
