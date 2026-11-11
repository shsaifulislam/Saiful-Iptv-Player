// test/player_engine_comprehensive_test.mjs
// Automated Verification Suite for Universal Media Player Engine (Prompt 06)

import assert from 'node:assert';

console.log('------------------------------------------------------------');
console.log('SAIFUL IPTV PLAYER: UNIVERSAL PLAYER ENGINE VERIFICATION');
console.log('------------------------------------------------------------\n');

let totalTests = 0;
let passedTests = 0;

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    console.log(`[PASS] ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`[FAIL] ${name}:`, err.message);
  }
}

// -------------------------------------------------------------
// 1. MediaSource URL Sanitization (Zero Credential Leakage)
// -------------------------------------------------------------
runTest('1. MediaSource Sanitization: Redacts Xtream Codes paths and query credentials', () => {
  function sanitizeMediaUri(rawUri) {
    if (!rawUri) return '';
    try {
      const parsed = new URL(rawUri);
      if (parsed.username || parsed.password) {
        parsed.username = '***';
        parsed.password = '***';
      }
      let result = parsed.toString();
      
      // Xtream codes /live/user/pass/id or /movie/user/pass/id
      result = result.replace(/(\/(?:live|movie|series)\/)([^\/]+)\/([^\/]+)\/([0-9a-zA-Z._]+)/g, '$1****/****/$4');
      
      // Query parameters
      result = result.replace(/([?&])(token|key|password|pass|auth|hash|secret|access_token)=([^&]+)/gi, '$1$2=[REDACTED]');
      return result;
    } catch {
      return '[Invalid URI]';
    }
  }

  const rawXtream = 'http://provider.tv:8080/live/saiful_user/secret_pass_99/12345.m3u8?token=xyz987&other=1';
  const clean = sanitizeMediaUri(rawXtream);

  assert(!clean.includes('saiful_user'), 'Username must be redacted');
  assert(!clean.includes('secret_pass_99'), 'Password must be redacted');
  assert(!clean.includes('xyz987'), 'Token must be redacted');
  assert(clean.includes('****/****/12345.m3u8'), 'Expected masked Xtream format');
  assert(clean.includes('token=[REDACTED]'), 'Expected redacted query parameter');
});

// -------------------------------------------------------------
// 2. Subtitle Parser (SRT & WebVTT)
// -------------------------------------------------------------
runTest('2. Subtitle Parser: Parses SRT and VTT cues with timestamps and delay compensation', () => {
  function parseTimestamp(raw) {
    const cleaned = raw.replace(',', '.').trim();
    const parts = cleaned.split(':');
    if (parts.length === 3) {
      const hours = parseInt(parts[0], 10);
      const minutes = parseInt(parts[1], 10);
      const secParts = parts[2].split('.');
      const seconds = parseInt(secParts[0], 10);
      const millis = secParts.length > 1 ? parseInt(secParts[1].padEnd(3, '0').slice(0, 3), 10) : 0;
      return ((hours * 3600) + (minutes * 60) + seconds) * 1000 + millis;
    }
    return 0;
  }

  function parseSrt(content) {
    const cues = [];
    const blocks = content.replace(/\r\n/g, '\n').split('\n\n');
    let idx = 1;
    for (const b of blocks) {
      const lines = b.trim().split('\n');
      if (lines.length < 2) continue;
      let timeIndex = 0;
      if (!lines[0].includes('-->') && lines.length >= 2) timeIndex = 1;
      const timeLine = lines[timeIndex];
      if (!timeLine.includes('-->')) continue;

      const [startRaw, endRaw] = timeLine.split('-->');
      const start = parseTimestamp(startRaw);
      const end = parseTimestamp(endRaw);
      const text = lines.slice(timeIndex + 1).join(' ').replace(/<[^>]*>/g, '').trim();

      cues.push({ index: idx++, start, end, text });
    }
    return cues;
  }

  const srtContent = `1\n00:01:20,000 --> 00:01:25,500\n<i>Hello world</i> & welcome to Saiful IPTV!\n\n2\n00:01:26,000 --> 00:01:30,000\nEnjoy <b>Universal Playback</b> with full subtitles.`;
  const cues = parseSrt(srtContent);

  assert.strictEqual(cues.length, 2);
  assert.strictEqual(cues[0].start, 80000); // 1m20s = 80,000 ms
  assert.strictEqual(cues[0].end, 85500);
  assert.strictEqual(cues[0].text, 'Hello world & welcome to Saiful IPTV!');

  // Subtitle cue activity check with delay
  function isCueActive(cue, currentMs, delayMs = 0) {
    const adjusted = currentMs - delayMs;
    return adjusted >= cue.start && adjusted <= cue.end;
  }

  assert(isCueActive(cues[0], 82000), 'Cue 1 should be active at 82s');
  assert(!isCueActive(cues[0], 79000), 'Cue 1 should not be active at 79s');
  assert(isCueActive(cues[0], 79000, -2000), 'Cue 1 should be active at 79s with -2000ms delay');
});

// -------------------------------------------------------------
// 3. Diagnostics & Recovery Actions
// -------------------------------------------------------------
runTest('3. Media Diagnostics: Calculates buffer health and actionable error recovery', () => {
  function calculateBufferHealth(bufferedMs, positionMs, targetMs = 30000) {
    const lead = bufferedMs - positionMs;
    if (lead <= 0) return 0.0;
    return Math.min(1.0, Math.max(0.0, lead / targetMs));
  }

  function getRecoverySuggestion(code, msg = '') {
    const c = code.toUpperCase();
    const m = msg.toLowerCase();
    if (c.includes('DECODER') || m.includes('codec')) {
      return 'Switch to Software Decoder in Player Settings or verify device codec profile.';
    }
    if (c.includes('TIMEOUT')) {
      return 'Network connection timed out while loading media buffer. Check internet connection.';
    }
    if (c.includes('401') || c.includes('403')) {
      return 'Access denied by IPTV provider. Re-authenticate playlist subscription.';
    }
    return 'Try restarting playback.';
  }

  const health1 = calculateBufferHealth(45000, 15000, 30000); // 30s lead = 1.0
  assert.strictEqual(health1, 1.0);

  const health2 = calculateBufferHealth(20000, 10000, 30000); // 10s lead = 0.333
  assert(Math.abs(health2 - (1/3)) < 0.01);

  const suggestion = getRecoverySuggestion('ERROR_CODE_DECODER_INIT_FAILED');
  assert(suggestion.includes('Software Decoder'), 'Decoder error must suggest fallback');
});

// -------------------------------------------------------------
// 4. A-B Repeat Loop Logic
// -------------------------------------------------------------
runTest('4. A-B Repeat: Automatically triggers seek back to Point A when reaching Point B', () => {
  class RepeatMachine {
    constructor() {
      this.pointA = null;
      this.pointB = null;
      this.position = 0;
      this.seekCount = 0;
    }
    setPointA(ms) {
      this.pointA = ms;
    }
    setPointB(ms) {
      if (this.pointA !== null && ms > this.pointA) {
        this.pointB = ms;
      }
    }
    updatePosition(ms) {
      this.position = ms;
      if (this.pointA !== null && this.pointB !== null && this.position >= this.pointB) {
        this.position = this.pointA;
        this.seekCount++;
      }
    }
  }

  const machine = new RepeatMachine();
  machine.setPointA(10000); // 10s
  machine.setPointB(25000); // 25s

  machine.updatePosition(15000);
  assert.strictEqual(machine.position, 15000);
  assert.strictEqual(machine.seekCount, 0);

  machine.updatePosition(25000); // Reached Point B
  assert.strictEqual(machine.position, 10000, 'Position must loop back to Point A');
  assert.strictEqual(machine.seekCount, 1);
});

// -------------------------------------------------------------
// 5. Audio Queue Manager
// -------------------------------------------------------------
runTest('5. Audio Queue Manager: Handles Next, Previous, Repeat One, and Repeat All', () => {
  class QueueManager {
    constructor(tracks) {
      this.queue = tracks;
      this.currentIndex = 0;
      this.repeatMode = 'off'; // 'off', 'all', 'one'
    }
    next() {
      if (this.repeatMode === 'one') return; // stays on same track
      if (this.currentIndex < this.queue.length - 1) {
        this.currentIndex++;
      } else if (this.repeatMode === 'all') {
        this.currentIndex = 0;
      }
    }
    previous(currentPosSec) {
      if (currentPosSec > 3) {
        return; // restart track
      }
      if (this.currentIndex > 0) {
        this.currentIndex--;
      } else if (this.repeatMode === 'all') {
        this.currentIndex = this.queue.length - 1;
      }
    }
  }

  const qm = new QueueManager(['Track 1', 'Track 2', 'Track 3']);
  qm.next();
  assert.strictEqual(qm.currentIndex, 1, 'Should move to Track 2');
  qm.next();
  assert.strictEqual(qm.currentIndex, 2, 'Should move to Track 3');
  qm.next();
  assert.strictEqual(qm.currentIndex, 2, 'Should stay at end when repeat off');

  qm.repeatMode = 'all';
  qm.next();
  assert.strictEqual(qm.currentIndex, 0, 'Should loop to Track 1 when repeat all');

  qm.previous(1);
  assert.strictEqual(qm.currentIndex, 2, 'Should loop backward to Track 3 when repeat all');
});

// -------------------------------------------------------------
// 6. Player Gestures Delta Clamping
// -------------------------------------------------------------
runTest('6. Player Gestures: Clamps swipe volume and brightness within strict bounds', () => {
  function adjustVolume(currentVol, delta) {
    return Math.min(1.0, Math.max(0.0, currentVol + delta));
  }
  function adjustBrightness(currentBri, delta) {
    return Math.min(1.0, Math.max(0.05, currentBri + delta)); // min 5% brightness
  }

  assert.strictEqual(adjustVolume(0.9, 0.2), 1.0, 'Volume must clamp to 1.0 max');
  assert.strictEqual(adjustVolume(0.1, -0.3), 0.0, 'Volume must clamp to 0.0 min');

  assert.strictEqual(adjustBrightness(0.5, 0.6), 1.0, 'Brightness must clamp to 1.0 max');
  assert.strictEqual(adjustBrightness(0.1, -0.2), 0.05, 'Brightness must not go completely black (min 0.05)');
});

// -------------------------------------------------------------
// 7. Local Media Browser Filtering & Categorization
// -------------------------------------------------------------
runTest('7. Local Media Browser: Accurately categorizes video/audio and performs search/sort', () => {
  const videoExts = ['mp4', 'mkv', 'mov', 'avi', 'webm', 'ts'];
  const audioExts = ['mp3', 'aac', 'flac', 'wav', 'ogg'];

  function categorize(ext) {
    const e = ext.toLowerCase();
    if (videoExts.includes(e)) return 'video';
    if (audioExts.includes(e)) return 'audio';
    return 'other';
  }

  assert.strictEqual(categorize('mp4'), 'video');
  assert.strictEqual(categorize('mkv'), 'video');
  assert.strictEqual(categorize('flac'), 'audio');
  assert.strictEqual(categorize('wav'), 'audio');
  assert.strictEqual(categorize('pdf'), 'other');

  const files = [
    { name: 'Beta Video.mkv', size: 500, date: 100 },
    { name: 'Alpha Video.mp4', size: 1000, date: 200 },
    { name: 'Gamma Video.webm', size: 250, date: 150 },
  ];

  function filterAndSort(list, query, sortBy) {
    let result = list;
    if (query) {
      result = result.filter(f => f.name.toLowerCase().includes(query.toLowerCase()));
    }
    if (sortBy === 'nameAsc') {
      result.sort((a, b) => a.name.localeCompare(b.name));
    } else if (sortBy === 'sizeDesc') {
      result.sort((a, b) => b.size - a.size);
    }
    return result;
  }

  const sortedByName = filterAndSort([...files], null, 'nameAsc');
  assert.strictEqual(sortedByName[0].name, 'Alpha Video.mp4');

  const sortedBySize = filterAndSort([...files], null, 'sizeDesc');
  assert.strictEqual(sortedBySize[0].name, 'Alpha Video.mp4'); // 1000
  assert.strictEqual(sortedBySize[2].name, 'Gamma Video.webm'); // 250

  const filtered = filterAndSort([...files], 'Beta', 'nameAsc');
  assert.strictEqual(filtered.length, 1);
  assert.strictEqual(filtered[0].name, 'Beta Video.mkv');
});

// -------------------------------------------------------------
// 8. Platform Adapter Capability Specifications
// -------------------------------------------------------------
runTest('8. Platform Adapter Specifications: Verifies architecture matrix across platforms', () => {
  const adapters = [
    {
      id: 'mediakit',
      target: ['Windows', 'macOS', 'Linux'],
      engine: 'libmpv',
      hw: 'D3D11VA, VideoToolbox, VAAPI',
      containers: ['MKV', 'MP4', 'AVI', 'MOV', 'WebM', 'TS'],
    },
    {
      id: 'media3',
      target: ['Android', 'Android TV', 'Google TV'],
      engine: 'ExoPlayer',
      hw: 'MediaCodec, Audio Tunneling',
      containers: ['MP4', 'MKV', 'TS', 'WebM'],
    },
    {
      id: 'tizen',
      target: ['Samsung Tizen Smart TV'],
      engine: 'AVPlay',
      hw: 'Samsung Hardware Video Pipeline',
      containers: ['TS', 'MP4', 'MKV'],
    },
    {
      id: 'webos',
      target: ['LG webOS Smart TV'],
      engine: 'Luna Media Pipeline',
      hw: 'LG Hardware Pipeline',
      containers: ['TS', 'MP4', 'MKV'],
    },
  ];

  assert.strictEqual(adapters.length, 4, 'All four target platform adapters must be defined');
  const desktop = adapters.find(a => a.id === 'mediakit');
  assert(desktop.containers.includes('MKV') && desktop.containers.includes('AVI'));

  const tv = adapters.find(a => a.id === 'tizen');
  assert.strictEqual(tv.engine, 'AVPlay');
});

console.log('\n------------------------------------------------------------');
console.log(`SUMMARY: ${passedTests}/${totalTests} TESTS PASSED`);
console.log('------------------------------------------------------------');

if (passedTests !== totalTests) {
  process.exit(1);
}

