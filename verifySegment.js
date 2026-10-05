// Overlay one assembled and fixopcodes-patched segment onto a copy of the reference ROM and compare that range.
// Usage: node verifySegment.js <segment> <org> <reference.bin> [<first> <last>]
// Example: node verifySegment.js hockey93_01 0x6446 nhlpa93retail.bin
// <first> <last> (inclusive ROM addresses) compare only that part of the segment, for example
// node verifySegment.js sound93 0x165D8 nhlpa93retail.bin 0x165D8 0x16E52
// Reads output/modified_<segment>.bin (written by fixopcodes.js), not the raw assembler output/<segment>.bin.
// Writes output/<segment>_patched.bin.
const fs = require('fs');
const path = require('path');

const [segment, orgArg, referencePath, firstArg, lastArg] = process.argv.slice(2);
if (!segment || !orgArg || !referencePath) {
  console.error('Usage: node verifySegment.js <segment> <org> <reference.bin> [<first> <last>]');
  process.exit(1);
}

const org = Number(orgArg);
if (!Number.isInteger(org) || org < 0) {
  console.error('org must be a hex or decimal address, for example 0x6446');
  process.exit(1);
}

const builtPath = path.join('output', `modified_${segment}.bin`);
const patchedPath = path.join('output', `${segment}_patched.bin`);
const built = fs.readFileSync(builtPath);
const reference = fs.readFileSync(referencePath);

if (org + built.length > reference.length) {
  console.error(
    `segment ${built.length} bytes at ${orgArg} runs past the end of ${referencePath} (${reference.length} bytes)`
  );
  process.exit(1);
}

const patched = Buffer.from(reference);
built.copy(patched, org);
fs.writeFileSync(patchedPath, patched);

const first = firstArg === undefined ? org : Number(firstArg);
const last = lastArg === undefined ? org + built.length - 1 : Number(lastArg);
if (!Number.isInteger(first) || !Number.isInteger(last) || first < org || last < first || last >= org + built.length) {
  console.error(`range ${firstArg}-${lastArg} is not inside the ${built.length}-byte segment at ${orgArg}`);
  process.exit(1);
}
const length = last - first + 1;

const mismatches = [];
for (let a = first; a <= last; a++) {
  if (built[a - org] !== reference[a]) mismatches.push(a);
}

const start = first.toString(16).padStart(6, '0');
const end = last.toString(16).padStart(6, '0');

if (mismatches.length === 0) {
  console.log(`MATCH: ${segment} confirmed ${length} bytes at 0x${start}-0x${end}`);
  console.log(`patched ROM: ${patchedPath}`);
  process.exit(0);
}

console.error(`MISMATCH: ${mismatches.length} of ${length} bytes differ in 0x${start}-0x${end}`);
for (const offset of mismatches.slice(0, 16)) {
  const i = offset - org;
  console.error(
    `  0x${offset.toString(16).padStart(6, '0')}: built ${built[i].toString(16).padStart(2, '0')} retail ${reference[offset].toString(16).padStart(2, '0')}`
  );
}
console.error(`patched ROM still written: ${patchedPath}`);
process.exit(1);
