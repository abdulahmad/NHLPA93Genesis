const fs = require('fs');

// Function to convert buffer to hex string with comma-separated words for hex2
function bufferToHexWords(buf, bytesPerWord = 2) {
  const words = [];
  for (let i = 0; i < buf.length; i += bytesPerWord) {
    let word = 0;
    for (let j = 0; j < bytesPerWord; j++) {
      word = (word << 8) | buf[i + j];
    }
    words.push(word.toString(16).toUpperCase().padStart(bytesPerWord * 2, '0'));
  }
  return words.join(',');
}

// Function to buffer to dc.b string
function bufferToDcB(buf) {
  return buf.map(b => '0x' + b.toString(16).toUpperCase().padStart(2, '0')).join(',');
}

// Function to parse string from buffer, stop at length
function parseString(buf, offset, length) {
  let str = '';
  for (let i = 0; i < length; i++) {
    const char = buf[offset + i];
    if (char === 0x20 && i === length - 1 && length % 2 === 0) { // Padding space if uneven
      continue;
    }
    str += String.fromCharCode(char);
  }
  return str.trim(); // Trim trailing space if any
}

// Main function to parse and generate source
function generateTeamSource(romPath) {
  const rom = fs.readFileSync(romPath);
  const startOffset = 0x37C;
  const numTeams = 26;
  const teamLabels = [
    'Boston', 'Buffalo', 'Calgary', 'Chicago', 'Detroit', 'Edmonton', 'Hartford', 'LongIsland',
    'LosAngeles', 'Minnesota', 'Montreal', 'NewJersey', 'NewYork', 'Ottawa', 'Philadelphia',
    'Pittsburgh', 'Quebec', 'SanJose', 'StLouis', 'TampaBay', 'Toronto', 'Vancouver',
    'Washington', 'Winnipeg', 'Wales', 'Campbell'
  ];

  let output = 'TeamList\n';
  for (let i = 0; i < numTeams; i++) {
    output += `\tdc.l\t${teamLabels[i]}\n`;
  }
  output += `\nNumofTeams\t=\t(*-TeamList)/4\n`;
  output += 'Playerdata\t=\t0\nPalettedata\t=\t2\nTeamname\t=\t4\nScoutReport\t=\t6\nLineSets\t=\t8\nScoreOdds\t=\t10\n\n';

  // Parse pointer table
  for (let teamIdx = 0; teamIdx < numTeams; teamIdx++) {
    const ptrOffset = startOffset + teamIdx * 2;
    const teamPtr = rom.readUInt16BE(ptrOffset); // Absolute pointer to team data

    let teamOutput = `${teamLabels[teamIdx]}\n.0\n`;

    // Read relative offsets
    const relPlayer = rom.readUInt16BE(teamPtr);
    const relPalette = rom.readUInt16BE(teamPtr + 2);
    const relTeamName = rom.readUInt16BE(teamPtr + 4);
    const relLines = rom.readUInt16BE(teamPtr + 6);
    const relScout = rom.readUInt16BE(teamPtr + 8);
    const relUnknown = rom.readUInt16BE(teamPtr + 10);

    teamOutput += `\tdc.w\t.pld-.0\n\tdc.w\t.pad-.0\n\tdc.w\t.tn-.0\n\tdc.w\t.ls-.0\n\tdc.w\t.sr-.0\n\tdc.w\t.unknown-.0\n`;

    // Palettes (32 bytes home + 32 away)
    const paletteStart = teamPtr + relPalette;
    const homePal = rom.slice(paletteStart, paletteStart + 32);
    const awayPal = rom.slice(paletteStart + 32, paletteStart + 64);

    teamOutput += '.pad\n';
    // Instead of incbin, output as dc.b for self-contained
    teamOutput += `\tdc.b\t${bufferToDcB(homePal)}\n`;
    teamOutput += `\tdc.b\t${bufferToDcB(awayPal)}\n`;

    // Scouting Report (8 bytes)
    const scoutStart = teamPtr + relScout;
    const scoutBuf = rom.slice(scoutStart, scoutStart + 8);
    teamOutput += `.sr\n\thex2\t${bufferToHexWords(scoutBuf)}\n`;

    // Unknown (2 bytes)
    const unknownStart = teamPtr + relUnknown;
    const unknownBuf = rom.slice(unknownStart, unknownStart + 2);
    teamOutput += `.unknown\n\tdc.b\t${bufferToDcB(unknownBuf)}\n`;

    // Lines (56 bytes)
    const linesStart = teamPtr + relLines;
    const linesBuf = rom.slice(linesStart, linesStart + 56);
    teamOutput += '.ls\n';
    // Output as dc.b in groups of 8 for each line
    for (let line = 0; line < 7; line++) {
      const lineBuf = linesBuf.slice(line * 8, (line + 1) * 8);
      teamOutput += `\tdc.b\t${bufferToDcB(lineBuf)}\n`;
    }

    // Player Data
    const playerStart = teamPtr + relPlayer;
    const teamNameStart = teamPtr + relTeamName;
    let currentPos = playerStart;
    teamOutput += '.pld\n';

    while (currentPos < teamNameStart) {
      const nameLenPlus2 = rom.readUInt16BE(currentPos);
      const nameLen = nameLenPlus2 - 2;
      const nameStart = currentPos + 2;
      const name = parseString(rom, nameStart, nameLen);
      const attrStart = nameStart + nameLen + (nameLen % 2 === 1 ? 1 : 0); // Padding if odd
      const attrs = rom.slice(attrStart, attrStart + 9);

      // Convert attrs to 4 hex words: first byte uniform, then 8 bytes as 4 words
      const uniform = attrs[0].toString(16).toUpperCase().padStart(2, '0');
      const attrWords = bufferToHexWords(attrs.slice(1), 2);

      teamOutput += `\tPlayer\t'${name}',${uniform}${attrs[1].toString(16).toUpperCase().padStart(2, '0')},${attrWords}\n`;

      currentPos = attrStart + 9;
    }

    // Team Name Section
    const tnLenPlus1 = rom.readUInt16BE(teamNameStart);
    const tnLen = tnLenPlus1 - 1;
    const tnStrStart = teamNameStart + 2;
    const teamNameStr = parseString(rom, tnStrStart, tnLen);

    const abbrevStart = tnStrStart + tnLen + (tnLen % 2 === 1 ? 1 : 0);
    const abLenPlus1 = rom.readUInt16BE(abbrevStart);
    const abLen = abLenPlus1 - 1;
    const abStrStart = abbrevStart + 2;
    const abbrevStr = parseString(rom, abStrStart, abLen);

    teamOutput += `.tn\n\tStringB\t'${teamNameStr}'\n.ta\n\tStringB\t'${abbrevStr}'\n\n`;

    output += teamOutput;
  }

  // Write to file instead of just console
  fs.writeFileSync('team_data.asm', output, 'utf8');
  console.log('Output written to team_data.asm'); // Optional: confirm in console
}

// Usage: node script.js path_to_nhlpa93_rom.bin
if (process.argv.length < 3) {
  console.error('Usage: node script.js <rom_path>');
  process.exit(1);
}
generateTeamSource(process.argv[2]);