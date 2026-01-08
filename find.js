// find-pattern.js
const fs = require('fs');

// The pattern to search for (without the wildcards)
// Positions with ?? are ignored during comparison
const pattern = [
  0x00, 0xF0, /*??*/, /*??*/, 
  0x00, 0xF0, /*??*/, /*??*/, 
  0x00, 0xF0
];

// Helper: returns true if buffer matches pattern at given offset
function matchesAt(buf, offset) {
  for (let i = 0; i < pattern.length; i++) {
    // skip wildcards (undefined in our pattern array)
    if (pattern[i] === undefined) continue;
    
    if (buf[offset + i] !== pattern[i]) {
      return false;
    }
  }
  return true;
}

function findPatternInFile(filename) {
  try {
    const data = fs.readFileSync(filename);
    console.log(`File size: ${data.length.toLocaleString()} bytes`);

    const matches = [];

    // We can skip by 1 byte each time (brute force but usually fast enough)
    for (let i = 0; i <= data.length - pattern.length; i++) {
      if (matchesAt(data, i)) {
        // Show context: 8 bytes before + match + 8 bytes after
        const start = Math.max(0, i - 8);
        const end = Math.min(data.length, i + pattern.length + 8);

        const hexContext = data
          .slice(start, end)
          .toString('hex')
          .match(/.{2}/g)
          .join(' ')
          .toUpperCase();

        const offsetStr = `0x${i.toString(16).toUpperCase().padStart(8, '0')}`;

        matches.push({
          offset: i,
          offsetHex: offsetStr,
          context: hexContext,
          contextStart: start
        });

        console.log(`Match at ${offsetStr}  →  ${hexContext}`);
      }
    }

    console.log(`\nFound ${matches.length} match${matches.length === 1 ? '' : 'es'}`);

    if (matches.length === 0) {
      console.log("No matches found.");
    }

  } catch (err) {
    if (err.code === 'ENOENT') {
      console.error(`Error: File not found → ${filename}`);
    } else {
      console.error('Error:', err.message);
    }
    process.exit(1);
  }
}

// ────────────────────────────────────────────────
// Usage
// ────────────────────────────────────────────────

if (process.argv.length < 3) {
  console.log(`
  Usage:
    node find-pattern.js <binary-file>
    
  Example:
    node find-pattern.js game.exe
    node find-pattern.js dump.bin
  `);
  process.exit(1);
}

const filename = process.argv[2];
console.log(`Searching for pattern 00 F0 ?? ?? 00 F0 ?? ?? 00 F0`);
console.log(`in file: ${filename}\n`);

findPatternInFile(filename);