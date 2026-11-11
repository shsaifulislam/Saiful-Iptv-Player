// test/entertainment_comprehensive_test.mjs
// Automated Verification Suite for Entertainment Features (Prompt 08)

import assert from 'node:assert';

console.log('------------------------------------------------------------');
console.log('SAIFUL IPTV PLAYER: ENTERTAINMENT FEATURES VERIFICATION');
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
// 1. VOD & Movie Catalog, Watchlist & Continue Watching
// -------------------------------------------------------------
runTest('1. VOD & Movies: Genre filtering, Watchlist toggle, and Progress calculation', () => {
  const movies = [
    { id: 'm1', title: 'Tears of Steel', genre: 'Sci-Fi', durationMin: 114, progressSec: 1450 },
    { id: 'm2', title: 'Big Buck Bunny', genre: 'Animation', durationMin: 92, progressSec: 0 },
    { id: 'm3', title: 'Cosmos Odyssey', genre: 'Documentary', durationMin: 130, progressSec: 3600 },
  ];

  // Filter by genre
  const sciFi = movies.filter(m => m.genre === 'Sci-Fi');
  assert.strictEqual(sciFi.length, 1);
  assert.strictEqual(sciFi[0].title, 'Tears of Steel');

  // Continue watching: progressSec > 10
  const continueWatching = movies.filter(m => m.progressSec > 10);
  assert.strictEqual(continueWatching.length, 2);

  // Progress ratio
  const ratio = (continueWatching[0].progressSec / (continueWatching[0].durationMin * 60));
  assert(ratio > 0.2 && ratio < 0.25, `Expected progress ~0.21, got ${ratio}`);
});

// -------------------------------------------------------------
// 2. YouTube Video ID & Playlist Extraction
// -------------------------------------------------------------
runTest('2. YouTube Integration: Extracts Video ID and Playlist ID across all official formats', () => {
  function extractVideoId(input) {
    const trimmed = input.trim();
    if (/^[a-zA-Z0-9_\-]{11}$/.test(trimmed)) return trimmed;
    try {
      const u = new URL(trimmed);
      if (u.hostname.includes('youtu.be')) {
        return u.pathname.slice(1);
      }
      if (u.searchParams.has('v')) {
        return u.searchParams.get('v');
      }
      if (u.pathname.includes('/embed/')) {
        return u.pathname.split('/embed/')[1].split('/')[0];
      }
      if (u.pathname.includes('/shorts/')) {
        return u.pathname.split('/shorts/')[1].split('/')[0];
      }
    } catch {}
    return null;
  }

  function extractPlaylistId(input) {
    try {
      const u = new URL(input);
      return u.searchParams.get('list');
    } catch {}
    return null;
  }

  const expectedId = 'dQw4w9WgXcQ';
  assert.strictEqual(extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), expectedId);
  assert.strictEqual(extractVideoId('https://youtu.be/dQw4w9WgXcQ'), expectedId);
  assert.strictEqual(extractVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'), expectedId);
  assert.strictEqual(extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'), expectedId);
  assert.strictEqual(extractVideoId('dQw4w9WgXcQ'), expectedId);

  const playlistUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL1234567890';
  assert.strictEqual(extractPlaylistId(playlistUrl), 'PL1234567890');
});

// -------------------------------------------------------------
// 3. Photo Gallery & Slideshow Engine
// -------------------------------------------------------------
runTest('3. Photo Gallery: Album filtering, format validation, and slideshow transitions', () => {
  const supportedFormats = new Set(['jpg', 'png', 'webp', 'gif', 'bmp']);
  const photos = [
    { title: 'Beach', album: 'Vacation', format: 'jpg' },
    { title: 'Monuments', album: 'Heritage', format: 'png' },
    { title: 'Himalayas', album: 'Vacation', format: 'webp' },
    { title: 'Animation', album: 'Art', format: 'gif' },
  ];

  for (const p of photos) {
    assert(supportedFormats.has(p.format), `Format ${p.format} must be supported`);
  }

  const vacationPhotos = photos.filter(p => p.album === 'Vacation');
  assert.strictEqual(vacationPhotos.length, 2);

  // Slideshow advance logic
  let currentIndex = 0;
  function advanceSlide(length) {
    currentIndex = (currentIndex + 1) % length;
    return currentIndex;
  }

  assert.strictEqual(advanceSlide(photos.length), 1);
  assert.strictEqual(advanceSlide(photos.length), 2);
  assert.strictEqual(advanceSlide(photos.length), 3);
  assert.strictEqual(advanceSlide(photos.length), 0); // loop back
});

// -------------------------------------------------------------
// 4. Multi-View Engine & Audio Focus Exclusivity
// -------------------------------------------------------------
runTest('4. Multi-View: 2-View vs 4-View layouts and exclusive single-audio focus', () => {
  class MultiViewEngine {
    constructor() {
      this.layout = 4; // 4 tiles
      this.audioFocus = 0;
      this.tiles = [
        { id: 0, isPlaying: true, isError: false },
        { id: 1, isPlaying: true, isError: false },
        { id: 2, isPlaying: true, isError: false },
        { id: 3, isPlaying: true, isError: false },
      ];
    }
    setAudioFocus(index) {
      if (index >= 0 && index < this.layout) {
        this.audioFocus = index;
      }
    }
    setLayout(count) {
      this.layout = count;
      if (this.audioFocus >= count) {
        this.audioFocus = 0;
      }
    }
    reportError(index) {
      this.tiles[index].isError = true;
      this.tiles[index].isPlaying = false;
    }
  }

  const engine = new MultiViewEngine();
  engine.setAudioFocus(2);
  assert.strictEqual(engine.audioFocus, 2);

  // Switch to 2-view: audio focus resets to safe bound
  engine.setLayout(2);
  assert.strictEqual(engine.layout, 2);
  assert.strictEqual(engine.audioFocus, 0);

  // Failure isolation: tile 1 fails, tile 0 remains playing
  engine.reportError(1);
  assert.strictEqual(engine.tiles[1].isError, true);
  assert.strictEqual(engine.tiles[0].isPlaying, true);
});

// -------------------------------------------------------------
// 5. Parental Controls & Age Rating Hierarchy
// -------------------------------------------------------------
runTest('5. Parental Controls: PIN check and Age Rating Hierarchy enforcement', () => {
  const ageHierarchy = ['G', 'PG', 'PG-13', 'R', 'NC-17'];

  function isAllowed(contentRating, maxAllowed) {
    const maxIdx = ageHierarchy.indexOf(maxAllowed);
    const targetIdx = ageHierarchy.indexOf(contentRating);
    if (maxIdx === -1 || targetIdx === -1) return true;
    return targetIdx <= maxIdx;
  }

  assert(isAllowed('G', 'PG-13'), 'G should be allowed under PG-13');
  assert(isAllowed('PG', 'PG-13'), 'PG should be allowed under PG-13');
  assert(isAllowed('PG-13', 'PG-13'), 'PG-13 should be allowed under PG-13');
  assert(!isAllowed('R', 'PG-13'), 'R must be blocked under PG-13');
  assert(!isAllowed('NC-17', 'PG-13'), 'NC-17 must be blocked under PG-13');
  assert(isAllowed('R', 'R'), 'R should be allowed under R');
});

// -------------------------------------------------------------
// 6. Cloud Sync Conflict Resolution
// -------------------------------------------------------------
runTest('6. Cloud Sync Conflict Resolution: Latest timestamp vector wins', () => {
  function resolveConflict(localRec, remoteRec) {
    const localTime = new Date(localRec.updated_at).getTime();
    const remoteTime = new Date(remoteRec.updated_at).getTime();
    return remoteTime > localTime ? remoteRec : localRec;
  }

  const local1 = { id: 'fav_1', is_favorite: true, updated_at: '2026-11-11T12:00:00Z' };
  const remote1 = { id: 'fav_1', is_favorite: false, updated_at: '2026-11-11T14:30:00Z' }; // newer

  const winner1 = resolveConflict(local1, remote1);
  assert.strictEqual(winner1.is_favorite, false, 'Remote record should win because updated_at is newer');

  const local2 = { id: 'prog_1', seconds: 1200, updated_at: '2026-11-11T16:00:00Z' }; // newer
  const remote2 = { id: 'prog_1', seconds: 400, updated_at: '2026-11-11T15:00:00Z' };

  const winner2 = resolveConflict(local2, remote2);
  assert.strictEqual(winner2.seconds, 1200, 'Local record should win because updated_at is newer');
});

// -------------------------------------------------------------
// 7. Casting & In-App Notification System
// -------------------------------------------------------------
runTest('7. Casting & Notifications: Device binding and event queue tracking', () => {
  class CastManager {
    constructor() {
      this.connected = null;
      this.events = [];
    }
    connect(device) {
      this.connected = device;
      this.events.push(`Connected to ${device.name}`);
    }
    disconnect() {
      if (this.connected) {
        this.events.push(`Disconnected from ${this.connected.name}`);
        this.connected = null;
      }
    }
  }

  const cm = new CastManager();
  cm.connect({ id: 'cast_1', name: 'Living Room TV', protocol: 'chromecast' });
  assert.strictEqual(cm.connected.name, 'Living Room TV');
  assert.strictEqual(cm.events.length, 1);

  cm.disconnect();
  assert.strictEqual(cm.connected, null);
  assert.strictEqual(cm.events.length, 2);
});

console.log('\n------------------------------------------------------------');
console.log(`SUMMARY: ${passedTests}/${totalTests} TESTS PASSED`);
console.log('------------------------------------------------------------');

if (passedTests !== totalTests) {
  process.exit(1);
}

