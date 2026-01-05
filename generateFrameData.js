// generate_frames_asm.js
// Node.js script to extract animation tables from NHLPA Hockey '93 (Genesis) ROM
// and generate a matching Frames.asm
// Usage: node generate_frames_asm.js path/to/nhlpa93.bin [output.asm]

const { table } = require('console');
const fs = require('fs');
const path = require('path');

// ==================== CONFIGURATION ====================

// ROM offset where the animation list starts (SPAlist)
const ANIMATION_LIST_OFFSET = 0x4D8E;

// SPF (Sprite Frame) base offsets - MUST match your reversed values exactly
const SPF = {
  skatewp:     1,
  skate:       41,
  turnl:       81,
  turnr:       89,
  swing:       97,
  stop:       145,
  skateb:     161,
  celebrate:  185,
  pump:       201,
  cup:        217,
  hipl:       225,
  hipr:        233,
  shoulderl:  241,
  shoulderr:  249,
  sweep:      257,
  fallback:   273,
  fallfwd:    305,
  duck:       337,
  hold:       345,
  gloves:     353,
  fight:      354,
  finjury:    371,   // new in '93
  Pen:        377,
  arrow:      384,
  pad:        390,
  replay:     393,   // new
  puck:       394,
  goal:       405,
  Goalie:     407,
  gdive:      519,   // new/extended
  glovel2:    535,   // new
  gready:    539,   // new
  Siren:      555,
  catch:      569,   // new
  hook:       585,   // new
  stumble:    601,   // new
  flip:       625,   // new
  injury1:    633,   // new
  bglass:     645    // new
};

/**
 * Returns the Unique SPF animation key that corresponds to the given frame number.
 */
function getUniqueSPF(frame) {
  // console.log('getUniqueSPF called with frame', frame);
  if (typeof frame !== 'number' || frame < 1) return null;

  const entries = Object.entries(SPF)
    .sort((a, b) => a[1] - b[1]); // sort by start frame

  for (let i = entries.length - 1; i >= 0; i--) {
    const [key, start] = entries[i];
    const nextStart = i + 1 < entries.length ? entries[i + 1][1] : Infinity;

    if (frame >= start && frame < nextStart) {
      return key;
    }
  }

  return null;
}

// Ordered list of SPA (Sprite Animation) names with confidence vs NHL '92
const SPA = {
  "gready":       100, // changed from 92
  "gready2":      100, // similar to 92 gready
  "gglover":      100,
  "gglovel":      100,
  "gglovel2":     100, // new in '93
  "gstickr":      100,
  "gstickl":      100,
  "gstackr":      100,
  "gstackl":      100,
  "gdive":        100, // new in '93
  "gswing":       100,
  "gskate":       100,
  "pflip":        100,
  "glide":        100,
  "skatewp":      100, // change to end of animation cycle
  "skate":        100, // change to end of animation cycle
  "turnl":        100, // change to end of animation cycle
  "turnr":        100, // change to end of animation cycle
  "stop":         100,
  "passf":        100,
  "passb":        100,
  "shotf":        100,
  "shotb":        100,
  "glideback":    100,
  "skateback":    100,
  "sweepchk":     100,
  "shoulderchkl": 100,
  "shoulderchkr": 100,
  "hipchkl":      100,
  "hipchkr":      100,
  "burst":        100,
  "Hold":         100,
  "Hold2":        100,
  "flail":        100,
  "fallfwd":      100,
  "fallback":     100,
  "celebrate":    100,
  "pump":         100,
  "fight":        100,
  "fgrab":        100,
  "fheld":        100,
  "fhigh":        100,
  "flow":         100,
  "fhith":        100,
  "fhitl":        100,
  "ffall":        100,
  "finjury":      100, // new in '93
  "wallright":    100,
  "wallleft":     100,
  "faceoff":      100,
  "faceoffr":     100,
  "siren":        100, 
  "bglass":       100, // new in '93
  "stanley":      100, // verified up to here
  "catch":        100, // is this catch?
  "hook":         100, // new in '93
  "hook2":        100, // new in '93
  "stumble":      100, // new in '93
  "fake":         100, // new in '93
  "flip":         100, // new in '93
  "injury1":      100, // new in '93
};

// the pointer at direction 7 is invalid for these animations
const skipDirList = ["wallright", "wallleft"]; 

// ======================================================

if (process.argv.length < 3) {
  console.log('Usage: node generate_frames_asm.js <rom_path> [output.asm]');
  process.exit(1);
}

const romPath = process.argv[2];
const outputPath = process.argv[3] || 'frames_data.asm';

const rom = fs.readFileSync(romPath);
let pos = ANIMATION_LIST_OFFSET;

function readWord() {
  const w = rom.readUInt16BE(pos);
  pos += 2;
  return w;
}

function readSignedWord() {
  const w = rom.readInt16BE(pos);
  pos += 2;
  return w;
}

const lines = [];

// Header
lines.push('; NHLPA Hockey \'93 (Sega Genesis) - Auto-generated Frames.asm');
lines.push('; Generated on ' + new Date().toISOString().split('T')[0]);
lines.push('; Matches ROM binary exactly');
lines.push('');
lines.push(';This is a data table for animating the graphics in Sprites.anim');
lines.push(';This list equates the sections of the alice animation file Sprites.anim');
lines.push('');
lines.push('; Sprite Frame (SPF) base indices');
let lastVal = 0;
let lastKey = '';
for (const [key, val] of Object.entries(SPF)) {
  if (val === 1) {
    lines.push(`SPF${key}\t=\t${val}`);
  } else {
    const comment = (key === 'finjury' || key === 'replay' || key === 'gdive' || key === 'glovel2' || key === 'gready2' || key === 'catch' || key === 'hook' || key === 'stumble' || key === 'flip' || key === 'injury1' || key === 'bglass')
      ? `; ${val} - New in NHLPA93`
      : `; ${val}`;
    lines.push(`SPF${key}\t=\tSPF${lastKey}+${val - lastVal}${comment}`);
  }
  lastKey = key;
  lastVal = val;
  if (key === 'sweep' || key === 'Hold' || key === 'Pen' || key === 'Siren') {
    lines.push('');
  }
}
lines.push('');

lines.push('SPAlist');
lines.push(`\tdc.w\t${readWord()}`);  // first pointer (usually points to first animation)
lines.push('');

let animationIndex = 0;
const spaNames = Object.keys(SPA);

while (true) {
  console.log('starting animation index', animationIndex);
  const startOffset = pos;

  // Read 8 direction offsets + flags
  const tableOffsets = [];
  for (let i = 0; i < 8; i++) {
    tableOffsets.push(readWord());
  }
  const flags = readWord();

  // End of list detection
  if (tableOffsets.every(o => o === 0) && flags === 0) {
    break;
  }

  const name = spaNames[animationIndex];
  if (!name) {
    console.warn(`Warning: More animations found than SPA entries (index ${animationIndex})`);
    break;
  }
  const confidence = SPA[name];

  lines.push(`SPA${name}\t=\t*-SPAlist\t; ${confidence} match to NHL '92`);
  lines.push(`SPA${name}_table: ; 0x${(startOffset).toString(16).padStart(6,'0')}`);
  lines.push('.t\t;offset to each direction of animation (0-7)');

  for (let direction = 0; direction < 8; direction++) {
    lines.push(`\tdc.w\t.${direction}-.t ; 0x${tableOffsets[direction].toString(16).padStart(4,'0')}`);
  }
  lines.push(`\tdc.w\t${flags}\n`);

  // === Collect unique SPFs and detect offsets ===
  const uniqueSPFs = new Map(); // baseName → {alias: string, offset: number}

  const savedPos = pos;
  for (let dir = 0; dir < 8; dir++) {
    if (tableOffsets[dir] === 0) continue;
    if (skipDirList.includes(spaNames[animationIndex]) && dir === 7) continue;
    pos = startOffset + tableOffsets[dir];
    while (true) {
      const frame = readWord();
      // console.log('frame read', frame, 'pos', pos.toString(16));
      const time = readSignedWord();
      const base = getUniqueSPF(frame);
      if (base && !uniqueSPFs.has(base)) {
        uniqueSPFs.set(base, { alias: null, offset: 0, originalFrame: frame, baseFrame: SPF[base]});
      }
      if (time < 0) break;
    }
  }
  pos = savedPos;

  // Assign aliases and detect offset (using dir 0 → dir 1)
  let letterCode = 'a'.charCodeAt(0);
  for (const [base, info] of uniqueSPFs) { // TODO ensure that offset is used across all 8 directions
    info.alias = String.fromCharCode(letterCode++);
    // console.log(info, 'aatest');
    if (tableOffsets[0] !== 0 && tableOffsets[1] !== 0  && tableOffsets[2] !== 0 && tableOffsets[3] !== 0 && tableOffsets[4] !== 0 && tableOffsets[5] !== 0 && tableOffsets[6] !== 0 && tableOffsets[7] !== 0) {
      // let frame0 = null;
      // let frame1 = null;
      let frame = [];
      for (let dir = 0; dir <= 7; dir++) {
        // dir 0
        pos = startOffset + tableOffsets[dir];
        while (true) {
          const f = readWord();
          const t = readSignedWord();
          if (getUniqueSPF(f) === base) { frame[dir] = f; break; }
          if (t < 0) break;
        }

      // // dir 1
      // pos = startOffset + tableOffsets[1];
      // while (true) {
      //   const f = readWord();
      //   const t = readSignedWord();
      //   if (getUniqueSPF(f) === base) { frame1 = f; break; }
      //   if (t < 0) break;
      // }
      }
      if (frame[0] !== null && frame[1] !== null && frame[2] !== null && frame[3] !== null && frame[4] !== null && frame[5] !== null && frame[6] !== null && frame[7] !== null && frame[1] - frame[0] === frame[2] - frame[1] && frame[1] - frame[0] === frame[3] - frame[2] && frame[1] - frame[0] === frame[4] - frame[3] && frame[1] - frame[0] === frame[5] - frame[4] && frame[1] - frame[0] === frame[6] - frame[5] && frame[1] - frame[0] === frame[7] - frame[6]) {
        info.offset = frame[1] - frame[0];
      }
    }
  }
  pos = savedPos;

  console.log(uniqueSPFs);
  const aliasMap = new Map();

  for (const [frameName, data] of uniqueSPFs.entries()) {
      aliasMap.set(data.alias, {
          ...data,
          baseSPF: frameName
      });
  }
  // console.log('Alias Map:', aliasMap);
  // Output aliases and offsets
  for (const [base, info] of uniqueSPFs) {
    // console.log(info, 'AA TESTX');
    if (info.originalFrame > info.baseFrame) { // Animation uses offset frame of SPF as it's base
      lines.push(`.${info.alias}\t=\tSPF${base}+${info.originalFrame - info.baseFrame}`);
    } else { // Animation uses first frame of SPF as it's base
      lines.push(`.${info.alias}\t=\tSPF${base}`);
    }
    if (info.offset > 0) {
      lines.push(`.${info.alias}off\t=\t${info.offset}`);
    }
  }
  if (uniqueSPFs.size > 0) lines.push('');

    // Output each direction: advance aliases at start of direction (except dir 0)
  for (let dir = 0; dir < 8; dir++) {
    if (tableOffsets[dir] === 0) {
      lines.push(`.${dir}\t; (empty)`);
      continue;
    } 
    
    if (dir < 7 && tableOffsets[dir] === tableOffsets[dir + 1]) { // group together animation frame data when pointers are shared between directions
      lines.push(`.${dir}`);
      continue;
    }

    console.log('Processing direction', dir, 'of animation', name, animationIndex, spaNames[animationIndex]);
    if (skipDirList.includes(spaNames[animationIndex]) && dir === 7) {
      lines.push(`.${dir}\t; (skipped)`);
      continue;
    }

    pos = startOffset + tableOffsets[dir];

    // Advance all aliases before this direction (skip for dir 0)
    if (dir > 0) {
      for (const [base, info] of uniqueSPFs) {
        if (info.offset > 0) {
          lines.push(`.${info.alias}\tset\t.${info.alias}+.${info.alias}off`);
        }
      }
    }

    // lines.push(`.${dir}`);
    // console.log(aliasMap)
    // Collect all frame/time pairs for this direction
    // console.log('Processing direction', dir);
    const frameEntries = [];
    while (true) {
      const frame = readWord();
      const time = readSignedWord();

      const base = getUniqueSPF(frame);
      if (base && uniqueSPFs.has(base)) {
        const { alias } = uniqueSPFs.get(base);
        // console.log('found base', base, alias, frame, time, uniqueSPFs.get(base).baseFrame);
        const offsetWithinAnimation = frame - uniqueSPFs.get(base).originalFrame;
        const offsetAcrossDirections = uniqueSPFs.get(base).offset * dir;
        // console.log(frame, uniqueSPFs.get(base).baseFrame);
        // console.log('offsetWithinAnimation', offsetWithinAnimation, 'offsetAcrossDirections', offsetAcrossDirections);
        // originalFrame = 408
        // baseFrame = 407
        
        const finalOffset = offsetWithinAnimation - offsetAcrossDirections;
        // console.log('finalOffset', finalOffset, 'for frame', frame, 'dir', dir);
        if (finalOffset > 0) {
          frameEntries.push(`.${alias}+${finalOffset},${time}`);
        } else if (finalOffset < 0) {
          frameEntries.push(`.${alias}${finalOffset},${time}`);
        }
        else {
          frameEntries.push(`.${alias},${time}`);
        }
        // frameEntries.push(`.${alias},${time}`); // TODO-- need to handle offset between alias and this frame
      } else {
        // Rare fallback — use raw frame number
        frameEntries.push(`${frame},${time}`);
      }

      if (time < 0) break;
    }

    // Output all entries on one line
    if (frameEntries.length > 0) {
      lines.push(`.${dir}\tdc.w\t${frameEntries.join(',')}`);
    }

    // lines.push(''); // blank line after direction
  }

  lines.push(''); // extra blank between animations
  animationIndex++;
  // if (animationIndex == 49) break; // TODO
}

// Final output
lines.push('; End of animation list');
fs.writeFileSync(outputPath, lines.join('\n'));
console.log(`Frames.asm generated: ${outputPath}`);
console.log(`Processed ${animationIndex} animations.`);