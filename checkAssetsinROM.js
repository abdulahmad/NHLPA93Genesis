const fs = require('fs');
const path = require('path');

// Function to recursively get all files in a directory
function getAllFiles(dirPath, arrayOfFiles = []) {
  const files = fs.readdirSync(dirPath);

  files.forEach((file) => {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isDirectory()) {
      getAllFiles(fullPath, arrayOfFiles);
    } else {
      arrayOfFiles.push(fullPath);
    }
  });

  return arrayOfFiles;
}

// Main function to check if file contents exist in the binary file
function checkAssetsInROM(sourceDir, targetROM) {
  // Read the target ROM as a Buffer
  const romBuffer = fs.readFileSync(targetROM);

  // Get all files recursively from source directory
  const assetFiles = getAllFiles(sourceDir);

  console.log(`Checking ${assetFiles.length} assets against ${targetROM}\n`);

  assetFiles.forEach((assetFile) => {
    // Read the asset file as a Buffer
    const assetBuffer = fs.readFileSync(assetFile);

    // Check if the asset buffer is contained in the ROM buffer
    const offset = romBuffer.indexOf(assetBuffer);

    if (offset !== -1) {
      // Convert to hex with 0x prefix, uppercase
      const hexOffset = '0x' + offset.toString(16).toUpperCase().padStart(8, '0');
      console.log(`Found: ${assetFile} at offset ${hexOffset} (${offset} decimal)`);
    } else {
      console.log(`Not found: ${assetFile}`);
    }
  });
}

// Command-line usage
if (process.argv.length !== 4) {
  console.error('Usage: node check-rom-assets.js <source_directory> <target_rom_file>');
  console.error('Example: node check-rom-assets.js ./NHL92_assets NHLPA93.rom');
  process.exit(1);
}

const sourceDir = process.argv[2];
const targetROM = process.argv[3];

checkAssetsInROM(sourceDir, targetROM);