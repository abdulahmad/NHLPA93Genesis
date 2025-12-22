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
    let array = [];
    for (let i = 0; i < buf.length; i++) {
        array[i] = buf[i].toString().padStart(2, '0');
    }
  return array.join(',');
}

// Function to parse string from buffer, stop at length
function parseString(buf, offset, length) {
  let str = '';
  for (let i = 0; i < length; i++) {
    const char = buf[offset + i];
    // console.log(char, i, char === 0x00, i=== length - 1);
    if (char === 0x00) { // Skip trailing null padding
      continue;
    }
    str += String.fromCharCode(char);
    // console.log(str);
  }
  return str.trim(); // Trim any trailing whitespace if present
}

function getSortedIndices(arr) {
  // Create an array of indices [0, 1, 2, ..., arr.length - 1]
  const indices = Array.from({ length: arr.length }, (_, i) => i);
  
  // Sort the indices based on the corresponding values in arr (smallest to largest)
  indices.sort((a, b) => arr[a] - arr[b]);
  
  return indices;
}

function convertAttrs(buffer) {
  if (buffer.length < 8) return '';
  const uniform = buffer[0].toString(16).toUpperCase().padStart(2, '0');
  const weight = buffer[1].toString(16).toUpperCase().padStart(2, '0');
  const first = uniform + weight;
  const word1 = ((buffer[2] << 8) | buffer[3]).toString(16).toUpperCase().padStart(4, '0');
  const word2 = ((buffer[4] << 8) | buffer[5]).toString(16).toUpperCase().padStart(4, '0');
  const word3 = ((buffer[6] << 8) | buffer[7]).toString(16).toUpperCase().padStart(4, '0');
  return `${first},${word1},${word2},${word3}`;
}

// Main function to parse and generate source
function generateTeamSource(romPath) {
  let maxNameLength = 0;
  let maxName = '';
  const rom = fs.readFileSync(romPath);
  const startOffset = 0x314;
  const numTeams = 26;
  const teamLabels = [
    'Boston', 'Buffalo', 'Calgary', 'Chicago', 'Detroit', 'Edmonton', 'Hartford', 'LongIsland',
    'LosAngeles', 'Minnesota', 'Montreal', 'NewJersey', 'NewYork', 'Ottawa', 'Philadelphia',
    'Pittsburgh', 'Quebec', 'SanJose', 'StLouis', 'TampaBay', 'Toronto', 'Vancouver',
    'Washington', 'Winnipeg', 'AllStarsEast', 'AllStarsWest'
  ];
  const palNames = [
    'Bruins', 'sabres', 'flames', 'Blackhawks', 'redwings', 'oilers', 'whalers', 'islanders',
    'Kings', 'northstars', 'canadiens', 'devils', 'rangers', 'ott', 'flyers',
    'penguins', 'nordiques', 'Sharks', 'blues', 'tb', 'mapleleafs', 'canucks',
    'capitals', 'jets', 'Wales', 'Campbell'
  ];

  let output = '\tdc.l\t$0000\n\n';
  output += 'TeamList\n';

  for (let i = 0; i < numTeams; i++) {
    output += `\tdc.l\t${teamLabels[i]}\n`;
  }
  output += `\nNumofTeams\t=\t(*-TeamList)/4\n`;
  output += 'Playerdata\t=\t0\nPalettedata\t=\t2\nTeamname\t=\t4\nLineSets\t=\t6\nScoutReport\t=\t8\nScoreOdds\t=\t10\n\n';

  let teamPtrArray = [];
  // Parse pointer table
  for (let teamIdx = 0; teamIdx < numTeams; teamIdx++) {
    const ptrOffset = startOffset + teamIdx * 4;
    // console.log(ptrOffset.toString(16).toUpperCase().padStart(6, '0'));
    teamPtrArray[teamIdx] = rom.readUInt32BE(ptrOffset); // Absolute pointer to team data
  }
  let sortedTeamIndices = getSortedIndices(teamPtrArray);

//   console.log(teamPtrArray);
//   console.log(sortedTeamIndices);

  // Process each team in sorted order
  for (let teamIdx = 0; teamIdx < numTeams; teamIdx++) {
    let teamOutput = `${teamLabels[sortedTeamIndices[teamIdx]]}\n.0\n`;

    // Read relative offsets
    const teamPtr = teamPtrArray[sortedTeamIndices[teamIdx]];
    const relPlayer = rom.readUInt16BE(teamPtr);
    const relPalette = rom.readUInt16BE(teamPtr + 2);
    const relTeamName = rom.readUInt16BE(teamPtr + 4);
    const relLines = rom.readUInt16BE(teamPtr + 6);
    const relScout = rom.readUInt16BE(teamPtr + 8);
    const relScoringOdds = rom.readUInt16BE(teamPtr + 10);

    teamOutput += `\tdc.w\t.pld-.0\n\tdc.w\t.pad-.0\n\tdc.w\t.tn-.0\n\tdc.w\t.ls-.0\n\tdc.w\t.sr-.0\n\tdc.w\t.sodds-.0\n`;

    // Palettes (32 bytes home + 32 away)
    const paletteStart = teamPtr + relPalette;
    const homePal = rom.slice(paletteStart, paletteStart + 32);
    const awayPal = rom.slice(paletteStart + 32, paletteStart + 64);

    teamOutput += '.pad\n';
    // Instead of incbin, output as dc.b for self-contained
    // teamOutput += `\tdc.b\t${bufferToDcB(homePal)}\n`;
    // teamOutput += `\tdc.b\t${bufferToDcB(awayPal)}\n`;
    teamOutput += `\tincbin\t..\\Extracted\\Graphics\\Pals\\${palNames[sortedTeamIndices[teamIdx]]}h.pal\n`;
    teamOutput += `\tincbin\t..\\Extracted\\Graphics\\Pals\\${palNames[sortedTeamIndices[teamIdx]]}v.pal\n`;

    // Scouting Report (8 bytes)
    const scoutStart = teamPtr + relScout;
    const scoutBuf = rom.slice(scoutStart, scoutStart + 8);
    if (teamIdx === 0) {
        teamOutput += `;------------------------\n`;
        teamOutput += `;u - unknown\n`;
        teamOutput += `;u - unknown\n`;
        teamOutput += `;p - power play advantage\n`;
        teamOutput += `;u - unknown\n\n`;
        teamOutput += `;u - unknown\n`;
        teamOutput += `;u - unknown\n`;
        teamOutput += `;u - unknown\n`;
        teamOutput += `;u - unknown\n\n`;
        teamOutput += `;s - shooting\n`;
        teamOutput += `;k - skating\n`;
        teamOutput += `;p - passing\n`;
        teamOutput += `;d - defense\n\n`;
        teamOutput += `;c - checking\n`;
        teamOutput += `;f - fighting\n`;
        teamOutput += `;g - goalkeeping\n`;
        teamOutput += `;o - overall\n`;
        teamOutput += `;------------------------\n`;
    }
    teamOutput += `.sr\t;\t\tuupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes\n`;
    teamOutput += `\thex2\t${bufferToHexWords(scoutBuf)}\n`;

    // Scoring Odds (2 bytes)
    const scoringOddsStart = teamPtr + relScoringOdds;
    const scoringOddsBuf = rom.slice(scoringOddsStart, scoringOddsStart + 2);
    teamOutput += `.sodds\t; TODO - rename this once unknowns/sodds are confirmed\n`;
    teamOutput += `\tdc.b\t${bufferToDcB(scoringOddsBuf)}\n`;

    // Lines (56 bytes)
    const linesStart = teamPtr + relLines;
    const linesBuf = rom.slice(linesStart, linesStart + 56);
    teamOutput += '.ls\t;\t\t-G,LD,RD,LW,-C,RW,XA,00\n';
    // Output as dc.b in groups of 8 for each line
    for (let line = 0; line < 7; line++) {
      const lineBuf = linesBuf.slice(line * 8, (line + 1) * 8);
      console.log(lineBuf,bufferToDcB(lineBuf));
      teamOutput += `\tdc.b\t${bufferToDcB(lineBuf)}\t;line ${line+1}\n`;
    }

    // Player Data
    const playerStart = teamPtr + relPlayer;
    const teamNameStart = teamPtr + relTeamName;
    let currentPos = playerStart;
    
    if (teamIdx === 0) {
        teamOutput += `;------------------------\n`;
        teamOutput += `;u - uniform # x10\n`;
        teamOutput += `;n - uniform # x1\n`;
        teamOutput += `;w - weight\n`;
        teamOutput += `;l - leg power\n`;

        teamOutput += `;s - speed\n`;
        teamOutput += `;o - offensive awareness\n`;
        teamOutput += `;d - defensive awareness\n`;
        teamOutput += `;p - shot power / NA for goalie\n\n`;

        teamOutput += `;c - checking strength / NA\n`;
        teamOutput += `;h - shooting hand / glove hand\n`;
        teamOutput += `;g - stickhandling / glove left saves\n`;
        teamOutput += `;a - shooting accuracy / glove right saves\n\n`;

        teamOutput += `;e - endurance / stick right saves\n`;
        teamOutput += `;y - shot/pass decision / stick left saves\n`;
        teamOutput += `;t - passing accuracy / consistency\n`;
        teamOutput += `;m - aggressiveness (PIM) / NA\n`;
        teamOutput += `;------------------------\n`;
    }
    teamOutput += '.pld\t;\t\t\t\t\t\t\tunwl,sodp,chga,eytm\n';

    let playerCount = 1;
    while (currentPos < teamNameStart-2) {
    //   console.log(currentPos, teamNameStart);
      const nameLenPlus2 = rom.readUInt16BE(currentPos);
    //   console.log(`NameLenPlus2: ${nameLenPlus2} at ${currentPos.toString(16).toUpperCase().padStart(6, '0')}`);
      const nameLen = nameLenPlus2 - 2;
      const nameStart = currentPos + 2;
      const name = parseString(rom, nameStart, nameLen);
      const attrStart = nameStart + nameLen;
      const playerAttributes = rom.slice(attrStart, attrStart + 8);
    //   console.log(playerAttributes);
        if (nameLen > maxNameLength) {
            maxNameLength = nameLen;
            maxName = name;
        }
      let tabs = '';
      if (nameLen >= 17) {
        tabs = '\t';
      } else if (nameLen >= 13) {
        tabs = '\t\t';
      } else if (nameLen >= 9) {
        tabs = '\t\t\t';
      } else if (nameLen >= 5) {
        tabs = '\t\t\t\t';
      }
      teamOutput += `\tPlayer\t'${name}',${tabs}${convertAttrs(playerAttributes)}\t;${playerCount}\n`;

      currentPos = attrStart + 8;
      playerCount++;
    }
    //output += teamOutput;
    // break;
    // Team Name Section
    const tnLenPlus1 = rom.readUInt16BE(teamNameStart);
    const tnLen = tnLenPlus1 - 1;
    const tnStrStart = teamNameStart + 2;
    const teamNameStr = parseString(rom, tnStrStart, tnLen);

    const abbrevStart = tnStrStart + tnLen;
    const abLenPlus1 = rom.readUInt8(abbrevStart); // Fix this 8-bit
    const abLen = abLenPlus1 - 2;
    const abStrStart = abbrevStart + 1;
    const abbrevStr = parseString(rom, abStrStart, abLen);

    console.log(tnLenPlus1, tnLen, tnStrStart, teamNameStr, abbrevStart, abLenPlus1);
    // console.log(tnLenPlus1, tnLen, teamNameStr, abLenPlus1, abLen, abbrevStr);
    teamOutput += `\tdc.b 0,2\t; TODO not sure why this is here\n`;
    teamOutput += `.tn\n`;
    teamOutput += `\tStringB\t'${teamNameStr}'\n.ta\n\tStringB\t'${abbrevStr}'\n\n`;

    output += teamOutput;
    // break;
  }

  // Write to file instead of just console
  fs.writeFileSync('team_data.asm', output, 'utf8');
  console.log('Output written to team_data.asm'); // Optional: confirm in console
  console.log('Max player name length:', maxNameLength);
  console.log('Max player name:', maxName);
}

// Usage: node script.js path_to_nhlpa93_rom.bin
if (process.argv.length < 3) {
  console.error('Usage: node script.js <rom_path>');
  process.exit(1);
}
generateTeamSource(process.argv[2]);