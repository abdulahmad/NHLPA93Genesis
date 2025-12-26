// generate_frames_asm.js
// Node.js script to extract animation tables from NHLPA Hockey '93 (Genesis) ROM
// and generate a matching Frames.asm
// Usage: node generate_frames_asm.js path/to/nhlpa93.bin [output.asm]

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
  Hold:       345,
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
  gready2:    539,   // new
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
  "gready":       100,
  "gglover":      100,
  "gglovel":      100,
  "gstickr":      100,
  "gstickl":      100,
  "gstackr":      100,
  "gstackl":      100,
  "gswing":       100,
  "gskate":        95,
  "pflip":        100,
  "glide":        100,
  "skatewp":       95,
  "skate":         95,
  "turnl":        100,
  "turnr":        100,
  "stop":         100,
  "passf":         90,
  "passb":         90,
  "shotf":         90,
  "shotb":         90,
  "glideback":    100,
  "skateback":    100,
  "sweepchk":     100,
  "shoulderchkl": 100,
  "shoulderchkr": 100,
  "hipchkl":      100,
  "hipchkr":      100,
  "burst":        100,
  "hold":         100,
  "hold2":        100,
  "flail":        100,
  "fallfwd":      100,
  "fallback":     100,
  "celebrate":    100,
  "pump":         100,
  "fight":         95,
  "fgrab":         95,
  "fheld":         95,
  "fhigh":         95,
  "flow":          95,
  "fhith":         95,
  "fhitl":         95,
  "ffall":         95,
  "wallright":    100,
  "wallleft":     100,
  "faceoff":      100,
  "faceoffr":     100,
  "siren":        100,
  "stanley":      100,
  "gdive_r":       70,
  "gdive_l":       70,
  "onetime_f":     60,
  "onetime_b":     60,
  "injury_fall":   80,
  "injury_lie":    80,
  "bglass_shatter":90,
  "hook_anim":     70,
  "flip_pass":     70,
  "flip_shot":     60,
  "catch_puck":    70,
  "replay_icon":   90
};

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
  lines.push(`SPA${name}_table:`);
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
    pos = startOffset + tableOffsets[dir];
    while (true) {
      const frame = readWord();
      const time = readSignedWord();
      const base = getUniqueSPF(frame);
      if (base && !uniqueSPFs.has(base)) {
        uniqueSPFs.set(base, { alias: null, offset: 0 });
      }
      if (time < 0) break;
    }
  }
  pos = savedPos;

  // Assign aliases and detect offset (using dir 0 → dir 1)
  let letterCode = 'a'.charCodeAt(0);
  for (const [base, info] of uniqueSPFs) {
    info.alias = String.fromCharCode(letterCode++);

    if (tableOffsets[0] !== 0 && tableOffsets[1] !== 0) {
      let frame0 = null, frame1 = null;

      // dir 0
      pos = startOffset + tableOffsets[0];
      while (true) {
        const f = readWord();
        const t = readSignedWord();
        if (getUniqueSPF(f) === base) { frame0 = f; break; }
        if (t < 0) break;
      }

      // dir 1
      pos = startOffset + tableOffsets[1];
      while (true) {
        const f = readWord();
        const t = readSignedWord();
        if (getUniqueSPF(f) === base) { frame1 = f; break; }
        if (t < 0) break;
      }

      if (frame0 !== null && frame1 !== null && frame1 > frame0) {
        info.offset = frame1 - frame0;
      }
    }
  }
  pos = savedPos;

  // Output aliases and offsets
  for (const [base, info] of uniqueSPFs) {
    lines.push(`.${info.alias}\t=\tSPF${base}`);
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

    pos = startOffset + tableOffsets[dir];

    lines.push(`.${dir}`);

    // Advance all aliases before this direction (skip for dir 0)
    if (dir > 0) {
      for (const [base, info] of uniqueSPFs) {
        if (info.offset > 0) {
          lines.push(`.${info.alias}\tset\t.${info.alias}+.${info.alias}off`);
        }
      }
    }

    // Collect all frame/time pairs for this direction
    const frameEntries = [];

    while (true) {
      const frame = readWord();
      const time = readSignedWord();

      const base = getUniqueSPF(frame);
      if (base && uniqueSPFs.has(base)) {
        const { alias } = uniqueSPFs.get(base);
        frameEntries.push(`.${alias},${time}`);
      } else {
        // Rare fallback — use raw frame number
        frameEntries.push(`${frame},${time}`);
      }

      if (time < 0) break;
    }

    // Output all entries on one line
    if (frameEntries.length > 0) {
      lines.push(`\tdc.w\t${frameEntries.join(',')}\t;frame,time  (last entry indicated by neg. time)`);
    }

    lines.push(''); // blank line after direction
  }

  lines.push(''); // extra blank between animations
  animationIndex++;
}

// Final output
lines.push('; End of animation list');
fs.writeFileSync(outputPath, lines.join('\n'));
console.log(`Frames.asm generated: ${outputPath}`);
console.log(`Processed ${animationIndex} animations.`);