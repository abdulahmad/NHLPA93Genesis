const fs = require('fs').promises;
const path = require('path');
const crc32 = require('crc-32'); // Requires 'crc-32' package: npm install crc-32

// Asset definitions from the .lst file
const assets = [
    { name: 'ASEh.pal', folder: 'Graphics/Pals', start: 0x388, end: 0x3A8 }, // ASE
    { name: 'ASEv.pal', folder: 'Graphics/Pals', start: 0x3A8, end: 0x3C8 },
    { name: 'ASWh.pal', folder: 'Graphics/Pals', start: 0x624, end: 0x644 }, // ASW
    { name: 'ASWv.pal', folder: 'Graphics/Pals', start: 0x644, end: 0x664 },
    { name: 'BOSh.pal', folder: 'Graphics/Pals', start: 0x8C4, end: 0x8E4 },
    { name: 'BOSv.pal', folder: 'Graphics/Pals', start: 0x8E4, end: 0x904 },
    { name: 'BUFh.pal', folder: 'Graphics/Pals', start: 0xB7C, end: 0xB9C },
    { name: 'BUFv.pal', folder: 'Graphics/Pals', start: 0xB9C, end: 0xBBC },
    { name: 'CGYh.pal', folder: 'Graphics/Pals', start: 0xE3E, end: 0xE5E },
    { name: 'CGYv.pal', folder: 'Graphics/Pals', start: 0xE5E, end: 0xE7E },
    { name: 'CHIh.pal', folder: 'Graphics/Pals', start: 0x10E4, end: 0x1104 },
    { name: 'CHIv.pal', folder: 'Graphics/Pals', start: 0x1104, end: 0x1124 },
    { name: 'DETh.pal', folder: 'Graphics/Pals', start: 0x13A4, end: 0x13C4 },
    { name: 'DETv.pal', folder: 'Graphics/Pals', start: 0x13C4, end: 0x13E4 },
    { name: 'EDMh.pal', folder: 'Graphics/Pals', start: 0x165C, end: 0x167C },
    { name: 'EDMv.pal', folder: 'Graphics/Pals', start: 0x167C, end: 0x169C },
    { name: 'HFDh.pal', folder: 'Graphics/Pals', start: 0x190A, end: 0x192A },
    { name: 'HFDv.pal', folder: 'Graphics/Pals', start: 0x192A, end: 0x194A },
    { name: 'LAh.pal', folder: 'Graphics/Pals', start: 0x1BBE, end: 0x1BDE },
    { name: 'LAv.pal', folder: 'Graphics/Pals', start: 0x1BDE, end: 0x1BFE },
    { name: 'LIh.pal', folder: 'Graphics/Pals', start: 0x1E88, end: 0x1EA8 }, // LI
    { name: 'LIv.pal', folder: 'Graphics/Pals', start: 0x1EA8, end: 0x1EC8 },
    { name: 'MINh.pal', folder: 'Graphics/Pals', start: 0x2134, end: 0x2154 },
    { name: 'MINv.pal', folder: 'Graphics/Pals', start: 0x2154, end: 0x2174 },
    { name: 'MTLh.pal', folder: 'Graphics/Pals', start: 0x23D6, end: 0x23F6 },
    { name: 'MTLv.pal', folder: 'Graphics/Pals', start: 0x23F6, end: 0x2416 },
    { name: 'NJh.pal', folder: 'Graphics/Pals', start: 0x26AE, end: 0x26CE },
    { name: 'NJv.pal', folder: 'Graphics/Pals', start: 0x26CE, end: 0x26EE },
    { name: 'NYh.pal', folder: 'Graphics/Pals', start: 0x2966, end: 0x2986 },
    { name: 'NYv.pal', folder: 'Graphics/Pals', start: 0x2986, end: 0x29A6 },
    { name: 'OTWh.pal', folder: 'Graphics/Pals', start: 0x2C2E, end: 0x2C4E }, // OTT
    { name: 'OTWv.pal', folder: 'Graphics/Pals', start: 0x2C4E, end: 0x2C6E },
    { name: 'PHIh.pal', folder: 'Graphics/Pals', start: 0x2E4C, end: 0x2E6C },
    { name: 'PHIv.pal', folder: 'Graphics/Pals', start: 0x2E6C, end: 0x2E8C },
    { name: 'PITh.pal', folder: 'Graphics/Pals', start: 0x3108, end: 0x3128 },
    { name: 'PITv.pal', folder: 'Graphics/Pals', start: 0x3128, end: 0x3148 },
    { name: 'QUEh.pal', folder: 'Graphics/Pals', start: 0x33AC, end: 0x33CC },
    { name: 'QUEv.pal', folder: 'Graphics/Pals', start: 0x33CC, end: 0x33EC },
    { name: 'SJh.pal', folder: 'Graphics/Pals', start: 0x3686, end: 0x36A6 },
    { name: 'SJv.pal', folder: 'Graphics/Pals', start: 0x36A6, end: 0x36C6 },
    { name: 'STLh.pal', folder: 'Graphics/Pals', start: 0x3940, end: 0x3960 },
    { name: 'STLv.pal', folder: 'Graphics/Pals', start: 0x3960, end: 0x3980 },
    { name: 'TBYh.pal', folder: 'Graphics/Pals', start: 0x3BF6, end: 0x3C16 }, // TB
    { name: 'TBYv.pal', folder: 'Graphics/Pals', start: 0x3C16, end: 0x3C36 },
    { name: 'TORh.pal', folder: 'Graphics/Pals', start: 0x3E34, end: 0x3E54 },
    { name: 'TORv.pal', folder: 'Graphics/Pals', start: 0x3E54, end: 0x3E74 },
    { name: 'VANh.pal', folder: 'Graphics/Pals', start: 0x40EE, end: 0x410E },
    { name: 'VANv.pal', folder: 'Graphics/Pals', start: 0x410E, end: 0x412E },
    { name: 'WPGh.pal', folder: 'Graphics/Pals', start: 0x43A8, end: 0x43C8 },
    { name: 'WPGv.pal', folder: 'Graphics/Pals', start: 0x43C8, end: 0x43E8 },
    { name: 'WSHh.pal', folder: 'Graphics/Pals', start: 0x4666, end: 0x4686 },
    { name: 'WSHv.pal', folder: 'Graphics/Pals', start: 0x4686, end: 0x46A6 },
    // Sound and graphics data: contiguous retail slices (end is exclusive) for the incbins in
    // src/sound93.asm ($16E53-$2EFA1) and src/graphics93.asm ($2EFA2-$7FB75). Graphics slices start at an
    // IDA or stub label (retail address = Rev A - $2E) and are named after it; an unlabeled slice is named by its address.
    // The ...Plus8 labels (and unk_7A2B8) are offsets into a map, not slices: graphics93.asm defines them as label+8.
    { name: 'sound93_16E53.bin', folder: 'Sound', start: 0x016E53, end: 0x02EFA2 }, // Z80 program after Z80_Program_Code ($16E52), then sound data
    { name: 'GameSetupMap.bin', folder: 'Graphics', start: 0x02EFA2, end: 0x02F0B0 }, // GameSetupMapPlus8 = GameSetupMap+8
    { name: 'Titlemap.bin', folder: 'Graphics', start: 0x02F0B0, end: 0x031288 },
    { name: 'Gfx_31288.bin', folder: 'Graphics', start: 0x031288, end: 0x031F10 }, // no IDA or stub label (Rev A $312B6); 92 Title2Map
    { name: 'Title3map.bin', folder: 'Graphics', start: 0x031F10, end: 0x0322CE }, // Title3mapPlus8 = Title3map+8
    { name: 'Titlemap2.bin', folder: 'Graphics', start: 0x0322CE, end: 0x032860 }, // Titlemap2Plus8 = Titlemap2+8
    { name: 'unk_3288E.bin', folder: 'Graphics', start: 0x032860, end: 0x033388 }, // stats93 stub name (IDA Rev A address)
    { name: 'Framermap.bin', folder: 'Graphics', start: 0x033388, end: 0x033400 }, // FramermapPlus8 = Framermap+8
    { name: 'FaceOffMap.bin', folder: 'Graphics', start: 0x033400, end: 0x033864 },
    { name: 'IceRinkMap.bin', folder: 'Graphics', start: 0x033864, end: 0x03571C }, // IceRinkMapPlus8 = IceRinkMap+8
    { name: 'unk_3574A.bin', folder: 'Graphics', start: 0x03571C, end: 0x038906 }, // IDA name (Rev A address)
    { name: 'RefsMap.bin', folder: 'Graphics', start: 0x038906, end: 0x039462 }, // RefsMapPlus8 = RefsMap+8
    { name: 'RefMap2.bin', folder: 'Graphics', start: 0x039462, end: 0x03A378 }, // RefMap2Plus8 = RefMap2+8
    { name: 'SpritesMap.bin', folder: 'Graphics', start: 0x03A378, end: 0x03A382 },
    { name: 'Spritetiles.bin', folder: 'Graphics', start: 0x03A382, end: 0x0440F2 },
    { name: 'unk_44120.bin', folder: 'Graphics', start: 0x0440F2, end: 0x06FAC2 }, // IDA name (Rev A address)
    { name: 'FrameDataOff.bin', folder: 'Graphics', start: 0x06FAC2, end: 0x06FFD8 },
    { name: 'SprDataBytes.bin', folder: 'Graphics', start: 0x06FFD8, end: 0x0743CE },
    { name: 'HotList.bin', folder: 'Graphics', start: 0x0743CE, end: 0x0748E2 },
    { name: 'CrowdSprites.bin', folder: 'Graphics', start: 0x0748E2, end: 0x077170 }, // CrowdSpritesPlus8 = CrowdSprites+8
    { name: 'FaceOffSprites.bin', folder: 'Graphics', start: 0x077170, end: 0x0781E4 }, // FaceOffSpritesPlus8 = FaceOffSprites+8
    { name: 'ZamSprites.bin', folder: 'Graphics', start: 0x0781E4, end: 0x078CFE }, // ZamSpritesPlus8 = ZamSprites+8
    { name: 'bigfontmap.bin', folder: 'Graphics', start: 0x078CFE, end: 0x0795B4 }, // bigfontmapPlus8 = bigfontmap+8
    { name: 'smallfontmap.bin', folder: 'Graphics', start: 0x0795B4, end: 0x07A282 }, // smallfontmapPlus8 = smallfontmap+8
    { name: 'unk_7A2B0.bin', folder: 'Graphics', start: 0x07A282, end: 0x07A376 }, // IDA name (Rev A address); unk_7A2B8 = unk_7A2B0+8
    { name: 'TeamBlocksmap.bin', folder: 'Graphics', start: 0x07A376, end: 0x07C54E }, // TeamBlocksmapPlus8 = TeamBlocksmap+8
    { name: 'ArrowsMap.bin', folder: 'Graphics', start: 0x07C54E, end: 0x07C7AA }, // ArrowsMapPlus8 = ArrowsMap+8
    { name: 'EASNmap.bin', folder: 'Graphics', start: 0x07C7AA, end: 0x07C946 }, // EASNmapPlus8 = EASNmap+8
    { name: 'Ronbarrmap.bin', folder: 'Graphics', start: 0x07C946, end: 0x07CF1E },
    { name: 'unk_7CF4C.bin', folder: 'Graphics', start: 0x07CF1E, end: 0x07D304 }, // IDA name (Rev A address)
    { name: 'StanleyMap.bin', folder: 'Graphics', start: 0x07D304, end: 0x07F4F6 }, // StanleyMapPlus8 = StanleyMap+8
    { name: 'EASNmap2.bin', folder: 'Graphics', start: 0x07F4F6, end: 0x07FB76 }, // EASNmap2Plus8 = EASNmap2+8
];

// Expected CRC32 checksum (996931775 in hexadecimal)
const EXPECTED_CRC32 = 0xCBBF4262;

async function verifyCRC32(filePath) {
    try {
        const data = await fs.readFile(filePath);
        const calculatedCRC = crc32.buf(data) >>> 0; // Convert to unsigned 32-bit integer
        console.log('Caclulated CRC32:', calculatedCRC, EXPECTED_CRC32);
        return calculatedCRC === EXPECTED_CRC32;
    } catch (error) {
        console.error(`Error reading ROM file for CRC32 check: ${error.message}`);
        return false;
    }
}

async function extractAssets(romPath, options = {}) {
    // Set default options
    const extractOptions = {
        outputDir: options.outputDir || 'Extracted',
        verbose: options.verbose || false
    };
    
    try {
        // Verify CRC32
        const isValid = await verifyCRC32(romPath);
        if (!isValid) {
            console.error('CRC32 checksum mismatch. Expected 3B6BF8BF. Aborting extraction.');
            return;
        }

        // Read the ROM file
        const romData = await fs.readFile(romPath);

        // Create base Extracted directory
        const baseDir = extractOptions.outputDir;
        await fs.mkdir(baseDir, { recursive: true });

        // Extract each asset
        for (const asset of assets) {
            // Create output directory
            const outputDir = path.join(baseDir, asset.folder);
            await fs.mkdir(outputDir, { recursive: true });

            // Extract data
            const assetData = romData.slice(asset.start, asset.end);

            // Write to file
            const outputPath = path.join(outputDir, asset.name);
            await fs.writeFile(outputPath, assetData);
            
            if (extractOptions.verbose) {
                console.log(`Extracted ${asset.name} (${assetData.length} bytes) from offset 0x${asset.start.toString(16)} to 0x${asset.end.toString(16)}`);
                console.log(`Saved to ${outputPath}`);
            } else {
                console.log(`Extracted ${asset.name} to ${outputPath}`);
            }
        }

        console.log('Extraction completed successfully.');
        console.log(`Extracted ${assets.length} assets from NHLPA 93 ROM.`);
    } catch (error) {
        console.error(`Error during extraction: ${error.message}`);
    }
}

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        romFile: null,
        outputDir: 'Extracted',
        verbose: false
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        
        if (arg === '-h' || arg === '--help') {
            displayHelp();
            process.exit(0);
        } else if (arg === '-v' || arg === '--verbose') {
            options.verbose = true;
        } else if (arg === '-o' || arg === '--output') {
            if (i + 1 < args.length) {
                options.outputDir = args[++i];
            } else {
                console.error('Error: Output directory not specified');
                displayHelp();
                process.exit(1);
            }
        } else if (!options.romFile) {
            options.romFile = arg;
        }
    }

    return options;
}

// Display help information
function displayHelp() {
    console.log(`
NHL 93 Asset Extractor
======================

This script extracts assets from NHLPA Hockey 93 ROM files.

Usage: node src/extractAssets93-1.1.js [options] <rom_file_path>

Options:
  -h, --help              Display this help message
  -v, --verbose           Display detailed extraction information
  -o, --output <dir>      Specify output directory (default: 'Extracted')

Notes:
  - This script extracts all known assets from the NHLPA 93 retail ROM (nhlpa93retail.bin)
  - ROM checksums are verified to ensure correct ROM is used

Examples:
  node src/extractAssets93-1.1.js nhlpa93retail.bin
  node src/extractAssets93-1.1.js --verbose --output NHL93Assets nhlpa93retail.bin
    `);
}

// Main execution
const options = parseArgs();

if (!options.romFile) {
    console.error('Error: ROM file path not provided');
    displayHelp();
    process.exit(1);
}

console.log(`Extracting assets from: ${options.romFile}`);
console.log(`Output directory: ${options.outputDir}`);
if (options.verbose) {
    console.log('Verbose mode enabled');
}

extractAssets(options.romFile, {
    outputDir: options.outputDir,
    verbose: options.verbose
});