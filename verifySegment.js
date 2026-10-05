// Overlay one assembled segment onto a copy of the reference ROM and compare that range.
// Usage: node verifySegment.js <segment> <org> <reference.bin>
// Example: node verifySegment.js hockey93_01 0x6446 nhlpa93retail.bin
// Reads output/<segment>.bin. Writes output/<segment>_patched.bin.
const fs = require('fs');
const path = require('path');

const [segment, orgArg, referencePath] = process.argv.slice(2);
if (!segment || !orgArg || !referencePath) {
  console.error('Usage: node verifySegment.js <segment> <org> <reference.bin>');
  process.exit(1);
}

const org = Number(orgArg);
if (!Number.isInteger(org) || org < 0) {
  console.error('org must be a hex or decimal address, for example 0x6446');
  process.exit(1);
}

const builtPath = path.join('output', `${segment}.bin`);
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

const mismatches = [];
for (let i = 0; i < built.length; i++) {
  if (built[i] !== reference[org + i]) mismatches.push(org + i);
}

const start = org.toString(16).padStart(6, '0');
const end = (org + built.length - 1).toString(16).padStart(6, '0');

if (mismatches.length === 0) {
  console.log(`MATCH: ${segment} confirmed ${built.length} bytes at 0x${start}-0x${end}`);
  console.log(`patched ROM: ${patchedPath}`);
  process.exit(0);
}

console.error(`MISMATCH: ${mismatches.length} of ${built.length} bytes differ in 0x${start}-0x${end}`);
for (const offset of mismatches.slice(0, 16)) {
  const i = offset - org;
  console.error(
    `  0x${offset.toString(16).padStart(6, '0')}: built ${built[i].toString(16).padStart(2, '0')} retail ${reference[offset].toString(16).padStart(2, '0')}`
  );
}
console.error(`patched ROM still written: ${patchedPath}`);
process.exit(1);
