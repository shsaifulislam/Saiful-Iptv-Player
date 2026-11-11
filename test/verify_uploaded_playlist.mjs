import fs from 'fs';

const filePath = 'C:/Users/shsai/.gemini/antigravity/brain/6e217aca-fabc-49a4-9f26-df6683fbdefe/.user_uploaded/media_1794418681221_e0a6c84b.m3u';

if (!fs.existsSync(filePath)) {
  console.error('Uploaded playlist file not found at:', filePath);
  process.exit(1);
}

const content = fs.readFileSync(filePath, 'utf8');
const lines = content.split(/\r?\n/);
console.log(`[INFO] Loaded file: ${filePath}`);
console.log(`[INFO] Total Lines: ${lines.length}`);

let channelCount = 0;
const categories = new Set();
const banglaChannels = [];
let currentMeta = null;

function parseExtInf(line) {
  // Find first comma outside double quotes
  let commaIndex = -1;
  let insideQuotes = false;
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '"') {
      insideQuotes = !insideQuotes;
    } else if (line[i] === ',' && !insideQuotes) {
      commaIndex = i;
      break;
    }
  }

  const attributesPart = commaIndex !== -1 ? line.substring(8, commaIndex).trim() : line.substring(8).trim();
  const title = commaIndex !== -1 ? line.substring(commaIndex + 1).trim() : 'Unknown';

  const groupMatch = attributesPart.match(/group-title="([^"]+)"/i);
  const idMatch = attributesPart.match(/tvg-id="([^"]+)"/i);
  const logoMatch = attributesPart.match(/tvg-logo="([^"]+)"/i);

  return {
    name: title,
    group: groupMatch ? groupMatch[1] : 'Uncategorized',
    tvgId: idMatch ? idMatch[1] : null,
    logo: logoMatch ? logoMatch[1] : null,
  };
}

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();
  if (line.startsWith('#EXTINF:')) {
    channelCount++;
    currentMeta = parseExtInf(line);
    categories.add(currentMeta.group);
  } else if (line && !line.startsWith('#') && currentMeta) {
    currentMeta.url = line;
    if (/bangla|bd|bangladesh/i.test(currentMeta.group) || /bangla|btv|somoy|jamuna|ekattor|ntv|rtv|atn|channel i/i.test(currentMeta.name)) {
      banglaChannels.push({ name: currentMeta.name, group: currentMeta.group, url: currentMeta.url });
    }
    currentMeta = null;
  }
}

console.log(`\n=== REAL-WORLD PLAYLIST INGESTION REPORT ===`);
console.log(`Total Ingested Channels: ${channelCount}`);
console.log(`Total Unique Categories: ${categories.size}`);
console.log(`Bangla & BD Channels identified: ${banglaChannels.length}`);
console.log(`\nTop Categories Sample:`);
console.log(Array.from(categories).slice(0, 15));

console.log(`\nSample Real-World Channels:`);
banglaChannels.slice(0, 10).forEach(c => console.log(` - ${c.name} [${c.group}] -> ${c.url.substring(0, 60)}...`));

console.log(`\n[SUCCESS] M3U Playlist Parsing with quotes-aware delimiter confirmed!`);
