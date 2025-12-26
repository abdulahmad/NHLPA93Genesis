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
 * Returns the SPF animation key that corresponds to the given frame number.
 * @param {number} frame - The frame number to look up.
 * @returns {string|null} The matching key, or null if the frame is before the first animation.
 */
function getSPF(frame) {
  if (typeof frame !== 'number' || frame < 1) return null;

  const entries = Object.entries(SPF)
    .sort((a, b) => a[1] - b[1]); // sort by start frame

  for (let i = entries.length - 1; i >= 0; i--) {
    const [key, start] = entries[i];
    const nextStart = i + 1 < entries.length ? entries[i + 1][1] : Infinity;

    if (frame >= start && frame < nextStart) {
      const offset = frame - start;
      return offset === 0 ? key : `${key}+${offset}`;
    }
  }

  return null; // before first animation
}

/**
 * Returns the Unique SPF animation key that corresponds to the given frame number.
 * @param {number} frame - The frame number to look up.
 * @returns {string|null} The matching key, or null if the frame is before the first animation.
 */
function getUniqueSPF(frame) {
  if (typeof frame !== 'number' || frame < 1) return null;

  const entries = Object.entries(SPF)
    .sort((a, b) => a[1] - b[1]); // sort by start frame

  for (let i = entries.length - 1; i >= 0; i--) {
    const [key, start] = entries[i];
    const nextStart = i + 1 < entries.length ? entries[i + 1][1] : Infinity;

    if (frame >= start && frame < nextStart) {
      // const offset = frame - start;
      // return offset === 0 ? key : `${key}+${offset}`;
      return key;
    }
  }

  return null; // before first animation
}

// Ordered list of SPA (Sprite Animation) names with confidence vs NHL '92
// Confidence: 100% = identical binary to '92 version, 90% = minor timing change, etc.
const SPA = {
  "gready":       100, // goalie ready, but longer cycle in '93
  "gglover":      100,
  "gglovel":      100,
  "gstickr":      100,
  "gstickl":      100,
  "gstackr":      100,
  "gstackl":      100,
  "gswing":       100,
  "gskate":        95, // longer skate cycle
  "pflip":        100, // puck flip
  "glide":        100,
  "skatewp":       95, // different cycle length
  "skate":         95,
  "turnl":        100,
  "turnr":        100,
  "stop":         100,
  "passf":         90, // possibly one-timer variant
  "passb":         90,
  "shotf":         90, // likely includes one-timer
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
  "hold2":        100, // (being held)
  "flail":        100,
  "fallfwd":      100,
  "fallback":     100,
  "celebrate":    100,
  "pump":         100,
  "fight":         95, // extended in '93
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
  "gdive_r":       70, // new goalie dive right (guess)
  "gdive_l":       70, // new goalie dive left (guess)
  "onetime_f":     60, // one-timer forehand (guess)
  "onetime_b":     60, // one-timer backhand (guess)
  "injury_fall":   80, // injury collapse
  "injury_lie":    80, // lying injured
  "bglass_shatter":90, // board glass break
  "hook_anim":     70, // stick hook
  "flip_pass":     70, // flip/saucer pass
  "flip_shot":     60, // flip shot (guess)
  "catch_puck":    70, // glove catch (guess)
  "replay_icon":   90  // replay overlay
};

// ======================================================

if (process.argv.length < 3) {
  console.log('Usage: node generateFrameData.js <rom_path> [output.asm]');
  process.exit(1);
}

const romPath = process.argv[2];
const outputPath = process.argv[3] || 'frames_data.asm';

const rom = fs.readFileSync(romPath);
let pos = ANIMATION_LIST_OFFSET;

function readWord() {
  const w = rom.readUInt16BE(pos);
  console.log(`Read word 0x${w.toString(16).padStart(4,'0')} at pos 0x${pos.toString(16).padStart(6,'0')}`);
  pos += 2;
  return w;
}

function readSignedWord() {
  const w = rom.readInt16BE(pos);
  console.log(`Read signed word ${w} at pos 0x${pos.toString(16).padStart(6,'0')}`);
  pos += 2;
  return w;
}

const lines = [];

// Header
lines.push('; NHLPA Hockey \'93 (Sega Genesis) - Auto-generated Frames.asm');
lines.push('; Generated on ' + new Date().toISOString().split('T')[0]);
lines.push('; Matches ROM binary exactly');
lines.push('');
lines.push(';This is a data table for animating the graphics in Sprites.anim\n;This list equates the sections of the alice animation file Sprites.anim\n');
lines.push('; Sprite Frame (SPF) base indices');
let lastVal = 0;
let lastKey = '';
for (const [key, val] of Object.entries(SPF)) {
  if(val === 1) {
    lines.push(`SPF${key}\t=\t${val}`);
  } else {
    if (key === 'finjury' || key === 'replay' || key === 'gdive' || key === 'glovel2' || key === 'gready2' || key === 'catch' || key === 'hook' || key === 'stumble' || key === 'flip' || key === 'injury1' || key === 'bglass') {
      lines.push(`SPF${key}\t=\tSPF${lastKey}+${val-lastVal}; ${val} - New in NHLPA93`);
    } else {
      lines.push(`SPF${key}\t=\tSPF${lastKey}+${val-lastVal}; ${val}`);
    }
  }
  lastKey = key;
  lastVal = val;
  if (key === 'sweep' || key === 'Hold' || key === 'Pen' || key === 'Siren') {
    lines.push('');
  }
}
lines.push('');

lines.push('SPAlist');
lines.push(`\tdc.w\t${readWord()}`);
lines.push('');

let animationIndex = 0;

while (true) {  // changed to a proper loop that stops at the null entry
  const startOffset = pos;

  // Read 8 direction offsets + flags word
  const tableOffsets = [];
  for (let i = 0; i < 8; i++) {
    tableOffsets.push(readWord());
  }
  const flags = readWord();

  // Detect end of list: all offsets 0 and flags 0
  if (tableOffsets.every(o => o === 0) && flags === 0) {
    break;
  }

  // Find the corresponding SPA name by index (we rely on Object.keys order)
  const name = Object.keys(SPA)[animationIndex];
  if (!name) {
    console.warn(`Warning: More animations in ROM than expected SPA entries (index ${animationIndex})`);
    break;
  }
  const confidence = SPA[name];

  lines.push(`SPA${name}\t=\t*-SPAlist\t; ${confidence} match to NHL '92`);
  lines.push(`SPA${name}_table:`);
  lines.push('.t\t;offset to each direction of animation (0-7)');

  // Output direction offset table
  for (let direction = 0; direction < 8; direction++) {
    lines.push(`\tdc.w\t.${direction}-.t ; 0x${tableOffsets[direction].toString(16).padStart(4,'0')}`);
  }
  lines.push(`\tdc.w\t${flags}\n`);

  // === Analyze all directions to collect unique SPFs and compute offsets ===
  const uniqueSPFs = new Map(); // baseName → {baseFrame: number, alias: string}

  // First pass: collect every used base SPF across all directions
  const savedPos = pos;
  for (let dir = 0; dir < 8; dir++) {
    if (tableOffsets[dir] === 0) continue;

    pos = startOffset + tableOffsets[dir];

    while (true) {
      const frame = readWord();
      const time = readSignedWord();
      const base = getUniqueSPF(frame);
      if (base) {
        if (!uniqueSPFs.has(base)) {
          uniqueSPFs.set(base, { baseFrame: frame - (frame - SPF[base]), alias: null });
        }
      }
      if (time < 0) break;
    }
  }
  pos = savedPos;

  // Assign aliases .a, .b, ...
  let letter = 'a'.charCodeAt(0);
  for (const base of uniqueSPFs.keys()) {
    uniqueSPFs.get(base).alias = String.fromCharCode(letter++);
  }

  // Compute regular offset for each alias (difference between consecutive directions)
  const aliasOffsets = new Map(); // alias → offset
  for (const [base, info] of uniqueSPFs) {
    const alias = info.alias;
    // Look at direction 0 and direction 1 to detect pattern
    let offset = 0;
    let found = false;

    if (tableOffsets[0] !== 0 && tableOffsets[1] !== 0) {
      const pos0 = startOffset + tableOffsets[0];
      const pos1 = startOffset + tableOffsets[1];
      let tempPos = pos0;
      pos = pos0;
      let frame0 = null;
      while (true) {
        const f = readWord();
        const t = readSignedWord();
        if (getUniqueSPF(f) === base) { frame0 = f; break; }
        if (t < 0) break;
      }

      tempPos = pos1;
      pos = pos1;
      while (true) {
        const f = readWord();
        const t = readSignedWord();
        if (getUniqueSPF(f) === base) {
          offset = f - frame0;
          found = true;
          break;
        }
        if (t < 0) break;
      }
    }
    pos = savedPos;

    aliasOffsets.set(alias, found ? offset : 0);
  }

  // === Output aliases and offsets ===
  for (const [base, info] of uniqueSPFs) {
    lines.push(`.${info.alias}\t=\tSPF${base}`);
  }
  for (const [alias, offset] of aliasOffsets) {
    if (offset !== 0) {
      lines.push(`.${alias}off\t=\t${offset}`);
    }
  }
  if (uniqueSPFs.size > 0) lines.push('');

  // === Output each direction using aliases ===
  for (let dir = 0; dir < 8; dir++) {
    if (tableOffsets[dir] === 0) {
      lines.push(`.${dir}\t; (empty)`);
      continue;
    }

    const dirPos = startOffset + tableOffsets[dir];
    pos = dirPos;

    let frameSeq = [];

    while (true) {
      const frame = readWord();
      const time = readSignedWord();

      const base = getUniqueSPF(frame);
      if (base) {
        const info = uniqueSPFs.get(base);
        const alias = info.alias;
        const offsetInDir = frame - info.baseFrame;
        const offsetFromOff = aliasOffsets.get(alias);
        let expr = `.${alias}`;
        if (offsetFromOff !== 0) {
          const relative = offsetInDir / offsetFromOff;
          if (relative !== 0 && Number.isInteger(relative)) {
            expr += relative > 0 ? `+${relative}*${alias}off` : `${relative}*${alias}off`;
          } else if (offsetInDir !== 0) {
            expr += `+${offsetInDir}`;
          }
        } else if (offsetInDir !== 0) {
          expr += `+${offsetInDir}`;
        }
        frameSeq.push(`${expr},${time}`);
      } else {
        // fallback if somehow no base found
        frameSeq.push(`SPF${getSPF(frame)},${time}`);
      }

      if (time < 0) break;
    }

    lines.push(`.${dir}`);
    lines.push('\tdc.w\t' + frameSeq.join(','));
  }

  lines.push('');
  animationIndex++;
}

// Final output
lines.push('; End of animation list');
fs.writeFileSync(outputPath, lines.join('\n'));
console.log(`Frames.asm generated: ${outputPath}`);
console.log(`Processed ${animationIndex} animations.`);