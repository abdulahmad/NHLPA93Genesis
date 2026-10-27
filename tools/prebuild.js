// prebuild.js: run before every build (tools/build.js, npm run build:*, assets).
// Usage: node tools/prebuild.js [retail|reva|revb|any]
//   retail / reva / revb: the ROM that build is verified against must be present (and the right version).
//   any: either ROM (build:dev, not verified).
// Then makes sure Extracted/ is complete, and runs the extractor if it is not. If the ROM is
// missing or wrong, stops with the path, file name, SHA-1 and size it must have.

const GAME = 'NHLPA Hockey 93 (Sega Genesis)';
const EXTRACTOR = 'tools/extractAssets93.js';
const { ROMS, findRom, sha1Of } = require('./roms');
const TARGETS = { retail: ['retail'], reva: ['reva'], revb: ['revb'], any: ['retail', 'reva'] };
// ---------------------------------------------------------------------------------------------
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const EXTRACTED = path.join(ROOT, 'Extracted');
const MARKER = path.join(EXTRACTED, '.extract-complete.json');

const sizeText = (n) => `${n} bytes (0x${n.toString(16).toUpperCase()}, ${n / 0x100000 >= 1 ? n / 0x100000 + ' MB' : n / 1024 + ' KB'})`;

// Check one ROM: a file in the repo folder with this SHA-1 and size, whatever its name (tools/roms.js).
const checkRom = findRom;

function romBlock(rom) {
    return [
        `  ${rom.label}`,
        `    Put it in:  ${ROOT}`,
        `                (any file name: it is found by its SHA-1 and size; ${rom.file} is the usual name)`,
        `    SHA-1:      ${rom.sha1}`,
        `    Size:       ${sizeText(rom.size)}`,
    ].join('\n');
}

function stop(lines) {
    console.error('');
    console.error('*** BUILD STOPPED: ROM file needed ***');
    console.error(lines.join('\n'));
    console.error('');
    console.error(`ROMs are not included in the repo. Use your own dump of the ${GAME} cartridge,`);
    console.error('in the repo folder (any file name), then run the build again. The assets in Extracted/');
    console.error('are then extracted from it automatically.');
    console.error('');
    process.exit(1);
}

// Is Extracted/ complete? The extractor writes the marker last, listing every file it wrote, the
// ROM it read and its own SHA-1. Any missing or resized file, an unknown ROM or a changed extractor
// means the folder has to be extracted again. Rev B has pictures and sound data of its own, so Rev 0 and Rev A
// (identical slices) share Extracted/ but Rev B needs it extracted from its own ROM, and the other way round.
function extractedState(wantRevB) {
    if (!fs.existsSync(EXTRACTED)) return 'Extracted/ is missing';
    if (!fs.existsSync(MARKER)) return 'Extracted/ is incomplete (no .extract-complete.json marker)';
    let m;
    try { m = JSON.parse(fs.readFileSync(MARKER, 'utf8')); } catch (e) { return 'the Extracted/ marker is unreadable'; }
    if (m.extractorSha1 !== sha1Of(fs.readFileSync(path.join(ROOT, EXTRACTOR)))) return `${EXTRACTOR} changed since the last extraction`;
    if (!Object.values(ROMS).some((r) => r.sha1 === m.romSha1)) return 'Extracted/ came from an unknown ROM';
    if ((m.romSha1 === ROMS.revb.sha1) !== wantRevB) return wantRevB ? 'Extracted/ came from another revision than Rev B' : 'Extracted/ came from Rev B';
    if (!Array.isArray(m.files) || m.files.length === 0) return 'the Extracted/ marker lists no files';
    for (const f of m.files) {
        const p = path.join(EXTRACTED, f.path);
        if (!fs.existsSync(p)) return `Extracted/${f.path} is missing`;
        if (fs.statSync(p).size !== f.size) return `Extracted/${f.path} has the wrong size`;
    }
    return null;
}

const target = process.argv[2] || 'retail';
if (!TARGETS[target]) {
    console.error(`prebuild: unknown target '${target}'. Use one of: ${Object.keys(TARGETS).join(', ')}`);
    process.exit(1);
}

// 1. The ROM this build needs (for 'any', the first known ROM present).
const candidates = TARGETS[target].map((id) => ROMS[id]);
let romPath = null;
const problems = [];
for (const rom of candidates) {
    const r = checkRom(rom);
    if (r.ok) { romPath = r.path; break; }
    problems.push({ rom, r });
}
if (!romPath) {
    const lines = [];
    const wrong = problems.filter((x) => x.r.reason === 'wrong');
    for (const { rom, r } of wrong) {
        lines.push(`Found ${r.path}, but it is not the right ROM:`);
        lines.push(`    its SHA-1 is ${r.sha1}, size ${sizeText(r.size)}.`);
        lines.push('    (a bad dump, a hack, another revision, or a byte-swapped / interleaved file)');
    }
    lines.push(candidates.length > 1
        ? `This build needs one of these ROMs, each exactly the version shown:`
        : `This build needs this ROM, exactly the version shown:`);
    for (const rom of candidates) lines.push(romBlock(rom));
    stop(lines);
}

// 2. Extracted/ assets: extract again if missing or incomplete.
const wantRevB = target === 'revb';
const why = extractedState(wantRevB);
if (!why) {
    console.log('prebuild: ROM OK, Extracted/ assets complete.');
    process.exit(0);
}
console.log(`prebuild: ${why}; extracting assets from ${path.relative(ROOT, romPath)} ...`);
const res = spawnSync(process.execPath, [path.join(ROOT, EXTRACTOR), romPath], { cwd: ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
const out = (res.stdout || '') + (res.stderr || '');
const after = res.status === 0 ? extractedState(wantRevB) : 'the extractor failed';
if (after) {
    console.error(out);
    console.error(`*** BUILD STOPPED: asset extraction failed (${after}) ***`);
    process.exit(1);
}
const summary = out.split(/\r?\n/).filter((l) => /^ROM:|^Extracted \d+ (assets|slices)/.test(l));
for (const l of summary) console.log('prebuild: ' + l);
console.log('prebuild: Extracted/ assets complete.');
