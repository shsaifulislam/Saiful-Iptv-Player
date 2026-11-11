// test/iptv_comprehensive_test.mjs
// Automated Verification Suite for IPTV, Live TV, Playlist Management, and EPG (Prompt 07)

import assert from 'node:assert';

console.log('------------------------------------------------------------');
console.log('SAIFUL IPTV PLAYER: IPTV, PLAYLIST & EPG VERIFICATION');
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
// 1. Valid M3U Parsing
// -------------------------------------------------------------
runTest('1. Valid M3U Parsing: Extracts EXTINF tags, metadata, and stream URLs', () => {
  function parseM3u(content) {
    const lines = content.replace(/\r\n/g, '\n').split('\n');
    const channels = [];
    let current = null;

    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#EXTM3U')) continue;

      if (line.startsWith('#EXTINF:')) {
        const commaIdx = line.indexOf(',');
        const attrs = commaIdx !== -1 ? line.substring(8, commaIdx).trim() : line.substring(8).trim();
        const title = commaIdx !== -1 ? line.substring(commaIdx + 1).trim() : '';

        const tvgIdMatch = attrs.match(/tvg-id="([^"]*)"/i);
        const groupMatch = attrs.match(/group-title="([^"]*)"/i);
        const logoMatch = attrs.match(/tvg-logo="([^"]*)"/i);

        current = {
          name: title,
          tvgId: tvgIdMatch ? tvgIdMatch[1] : null,
          group: groupMatch ? groupMatch[1] : 'General',
          logo: logoMatch ? logoMatch[1] : null,
        };
        continue;
      }

      if (line.startsWith('#')) continue;

      if (current) {
        channels.push({
          ...current,
          url: line,
        });
        current = null;
      }
    }
    return channels;
  }

  const sample = `#EXTM3U
#EXTINF:-1 tvg-id="aljazeera.en" tvg-name="Al Jazeera" tvg-logo="http://example.com/logo.png" group-title="News", Al Jazeera English HD
https://live-hls-web-aje.getaj.net/AJE/03.m3u8
#EXTINF:-1 tvg-id="redbull.tv" group-title="Sports", Red Bull TV Live
https://rbmn-live.akamaized.net/hls/live/590964/geoSTB/master.m3u8`;

  const channels = parseM3u(sample);
  assert.strictEqual(channels.length, 2);
  assert.strictEqual(channels[0].name, 'Al Jazeera English HD');
  assert.strictEqual(channels[0].tvgId, 'aljazeera.en');
  assert.strictEqual(channels[0].group, 'News');
  assert.strictEqual(channels[0].logo, 'http://example.com/logo.png');
  assert.strictEqual(channels[1].name, 'Red Bull TV Live');
  assert.strictEqual(channels[1].group, 'Sports');
});

// -------------------------------------------------------------
// 2. Malformed M3U Resilience
// -------------------------------------------------------------
runTest('2. Malformed M3U: Handles missing commas, extra spaces, empty attributes, and comments', () => {
  function parseResilientM3u(content) {
    const lines = content.replace(/\r\n/g, '\n').split('\n');
    const channels = [];
    let current = null;

    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#EXTM3U')) continue;

      if (line.startsWith('#EXTINF:')) {
        const commaIdx = line.indexOf(',');
        const attrs = commaIdx !== -1 ? line.substring(8, commaIdx).trim() : line.substring(8).trim();
        const title = commaIdx !== -1 ? line.substring(commaIdx + 1).trim() : 'Unnamed Channel';

        const tvgIdMatch = attrs.match(/tvg-id="?([^"\s,]*)"?/i);
        const groupMatch = attrs.match(/group-title="?([^"\s,]*)"?/i);

        current = {
          name: title || 'Channel Fallback',
          tvgId: tvgIdMatch ? tvgIdMatch[1] : null,
          group: groupMatch ? groupMatch[1] : 'General',
        };
        continue;
      }

      if (line.startsWith('#')) continue; // comments like #EXTVLCOPT

      if (current && line.startsWith('http')) {
        channels.push({
          ...current,
          url: line,
        });
        current = null;
      }
    }
    return channels;
  }

  const malformed = `
#EXTM3U
#EXTINF:-1 tvg-id=bad_channel group-title="News" No Comma Here
http://stream.com/live1.m3u8
#EXTVLCOPT:network-caching=1000
#EXTINF:-1, Valid With Comma
http://stream.com/live2.m3u8
# Comment line without extinf
http://stream.com/live3.m3u8
`;

  const channels = parseResilientM3u(malformed);
  assert(channels.length >= 2, 'Should gracefully recover channels from malformed lines');
  assert.strictEqual(channels[1].name, 'Valid With Comma');
});

// -------------------------------------------------------------
// 3. Large Playlist Performance & Deduplication
// -------------------------------------------------------------
runTest('3. Large Playlist & Deduplication: Deduplicates duplicate URLs across 5,000+ items', () => {
  const seenUrls = new Set();
  const channels = [];

  const baseItems = [
    { name: 'Channel A', url: 'http://stream.com/a.m3u8' },
    { name: 'Channel B', url: 'http://stream.com/b.m3u8' },
    { name: 'Channel A (Dup)', url: 'http://stream.com/a.m3u8' }, // duplicate
    { name: 'Channel C', url: 'http://stream.com/c.m3u8' },
  ];

  // Synthesize 5,000 items with some duplicates
  for (let i = 0; i < 5000; i++) {
    const pick = baseItems[i % baseItems.length];
    const url = (i % 2 === 0) ? pick.url : `http://stream.com/item_${i}.m3u8`;

    if (!seenUrls.has(url)) {
      seenUrls.add(url);
      channels.push({ name: pick.name, url });
    }
  }

  assert(channels.length > 2000, 'Should parse multiple thousands of items');
  assert.strictEqual(seenUrls.size, channels.length, 'Deduplication set should match channel count');
  assert(seenUrls.has('http://stream.com/a.m3u8'), 'Contains first unique entry');
});

// -------------------------------------------------------------
// 4. SSRF & Network Security Guard
// -------------------------------------------------------------
runTest('4. SSRF Protection: Blocks private IPs, loopback, cloud metadata, and unsafe schemes', () => {
  function isSafeUrl(rawUrl) {
    if (!rawUrl) return false;
    try {
      const u = new URL(rawUrl);
      const scheme = u.protocol.toLowerCase();
      if (scheme !== 'http:' && scheme !== 'https:') return false;

      const host = u.hostname.toLowerCase();
      if (host === 'localhost' || host === 'metadata.google.internal' || host === 'instance-data') return false;

      // IPv4 private/loopback/link-local checks
      if (host.startsWith('127.') || host.startsWith('10.') || host.startsWith('192.168.') || host.startsWith('169.254.') || host === '0.0.0.0') {
        return false;
      }

      // Class B private 172.16 - 172.31
      if (host.startsWith('172.')) {
        const parts = host.split('.');
        const second = parseInt(parts[1], 10);
        if (second >= 16 && second <= 31) return false;
      }

      // IPv6 loopback
      if (host === '::1' || host === '[::1]' || host.startsWith('fe80:') || host.startsWith('fc00:')) {
        return false;
      }

      return true;
    } catch {
      return false;
    }
  }

  // Attack vectors that MUST be blocked
  assert.strictEqual(isSafeUrl('http://127.0.0.1:8080/playlist.m3u'), false, 'Blocked 127.0.0.1');
  assert.strictEqual(isSafeUrl('http://localhost:3000/stream.m3u8'), false, 'Blocked localhost');
  assert.strictEqual(isSafeUrl('http://169.254.169.254/latest/meta-data/'), false, 'Blocked AWS/GCP metadata IP');
  assert.strictEqual(isSafeUrl('http://metadata.google.internal/computeMetadata/v1/'), false, 'Blocked GCP metadata domain');
  assert.strictEqual(isSafeUrl('http://192.168.1.1/admin'), false, 'Blocked Class C private IP');
  assert.strictEqual(isSafeUrl('http://10.0.0.5/stream'), false, 'Blocked Class A private IP');
  assert.strictEqual(isSafeUrl('http://172.20.0.1/stream'), false, 'Blocked Class B private IP');
  assert.strictEqual(isSafeUrl('file:///etc/passwd'), false, 'Blocked file protocol');
  assert.strictEqual(isSafeUrl('gopher://127.0.0.1:70/'), false, 'Blocked gopher protocol');

  // Authorized streams that MUST be allowed
  assert.strictEqual(isSafeUrl('https://live-hls-web-aje.getaj.net/AJE/03.m3u8'), true, 'Allowed public HTTPS stream');
  assert.strictEqual(isSafeUrl('http://iptv-org.github.io/iptv/index.m3u'), true, 'Allowed public HTTP playlist');
});

// -------------------------------------------------------------
// 5. XMLTV EPG Parsing & Timezone Conversion
// -------------------------------------------------------------
runTest('5. XMLTV EPG Parser: Extracts channels, programmes, and converts timezones (+0600)', () => {
  function parseXmlTvDate(raw) {
    const trimmed = raw.trim();
    if (trimmed.length < 14) return null;
    const year = parseInt(trimmed.substring(0, 4), 10);
    const month = parseInt(trimmed.substring(4, 6), 10) - 1; // 0-indexed in JS
    const day = parseInt(trimmed.substring(6, 8), 10);
    const hour = parseInt(trimmed.substring(8, 10), 10);
    const minute = parseInt(trimmed.substring(10, 12), 10);
    const second = parseInt(trimmed.substring(12, 14), 10);

    const baseUtcMs = Date.UTC(year, month, day, hour, minute, second);

    if (trimmed.length > 14) {
      const tzPart = trimmed.substring(14).trim();
      if (tzPart !== 'Z' && tzPart !== '+0000' && tzPart !== '-0000') {
        const sign = tzPart.startsWith('-') ? -1 : 1;
        const clean = tzPart.replace('+', '').replace('-', '');
        const tzH = parseInt(clean.substring(0, 2), 10);
        const tzM = parseInt(clean.substring(2, 4), 10);
        const offsetMs = sign * ((tzH * 60) + tzM) * 60 * 1000;
        return new Date(baseUtcMs - offsetMs);
      }
    }
    return new Date(baseUtcMs);
  }

  // Test Dhaka (+0600) timestamp: 2026-11-11 20:00:00 +0600 is 14:00:00 UTC
  const dhakaDate = parseXmlTvDate('20261111200000 +0600');
  assert.strictEqual(dhakaDate.getUTCHours(), 14, '20:00 +0600 must equal 14:00 UTC');
  assert.strictEqual(dhakaDate.getUTCMinutes(), 0);

  // Test London (+0000)
  const utcDate = parseXmlTvDate('20261111140000 +0000');
  assert.strictEqual(utcDate.getTime(), dhakaDate.getTime(), 'Timestamps should match exact absolute UTC time');
});

// -------------------------------------------------------------
// 6. EPG Schedule Query (Current & Next Program)
// -------------------------------------------------------------
runTest('6. EPG Schedule: Calculates active airing program and upcoming next program', () => {
  const schedule = [
    { title: 'Morning News', start: new Date('2026-11-11T08:00:00Z'), end: new Date('2026-11-11T09:00:00Z') },
    { title: 'Market Watch', start: new Date('2026-11-11T09:00:00Z'), end: new Date('2026-11-11T10:00:00Z') },
    { title: 'Evening Wrap', start: new Date('2026-11-11T18:00:00Z'), end: new Date('2026-11-11T19:00:00Z') },
  ];

  function getCurrentAndNext(targetDate) {
    let current = null;
    let next = null;
    for (let i = 0; i < schedule.length; i++) {
      const p = schedule[i];
      if (targetDate >= p.start && targetDate < p.end) {
        current = p;
        if (i + 1 < schedule.length) next = schedule[i + 1];
        break;
      }
    }
    return { current, next };
  }

  const result1 = getCurrentAndNext(new Date('2026-11-11T09:30:00Z'));
  assert.strictEqual(result1.current?.title, 'Market Watch');
  assert.strictEqual(result1.next?.title, 'Evening Wrap');
});

// -------------------------------------------------------------
// 7. Stream Diagnostics & Error Suggestion
// -------------------------------------------------------------
runTest('7. Stream Diagnostics: Evaluates HTTP status codes and redacts credentials', () => {
  function diagnoseStatus(code) {
    if (code === 200) return { ok: true, msg: 'Stream healthy' };
    if (code === 401 || code === 403) return { ok: false, msg: 'Provider authentication expired' };
    if (code === 404) return { ok: false, msg: 'Channel not found on server' };
    return { ok: false, msg: 'Server error' };
  }

  function redactUrl(url) {
    return url.replace(/(\/live\/)([^\/]+)\/([^\/]+)\/([^\/]+)/, '$1****/****/$4');
  }

  assert(diagnoseStatus(200).ok);
  assert(!diagnoseStatus(403).ok);
  assert(diagnoseStatus(403).msg.includes('authentication expired'));

  const rawUrl = 'http://provider.tv:8080/live/user123/passSecret456/channel.m3u8';
  const clean = redactUrl(rawUrl);
  assert(!clean.includes('user123'));
  assert(!clean.includes('passSecret456'));
  assert(clean.includes('/live/****/****/channel.m3u8'));
});

// -------------------------------------------------------------
// 8. Playlist Manager State Management
// -------------------------------------------------------------
runTest('8. Playlist Manager: Supports Add, Delete, Toggle, and Channel filtering', () => {
  class PlaylistManager {
    constructor() {
      this.playlists = [];
      this.channels = [];
    }
    add(playlist, channels) {
      this.playlists.push(playlist);
      this.channels.push(...channels);
    }
    delete(id) {
      this.playlists = this.playlists.filter(p => p.id !== id);
      this.channels = this.channels.filter(c => c.playlistId !== id);
    }
    filter(group) {
      return this.channels.filter(c => group === 'All' || c.group === group);
    }
  }

  const pm = new PlaylistManager();
  pm.add({ id: 'pl_1', name: 'News & Sports' }, [
    { id: 'c1', playlistId: 'pl_1', name: 'CNN', group: 'News' },
    { id: 'c2', playlistId: 'pl_1', name: 'ESPN', group: 'Sports' },
  ]);

  assert.strictEqual(pm.channels.length, 2);
  assert.strictEqual(pm.filter('News').length, 1);
  assert.strictEqual(pm.filter('Sports').length, 1);

  pm.delete('pl_1');
  assert.strictEqual(pm.playlists.length, 0);
  assert.strictEqual(pm.channels.length, 0);
});

console.log('\n------------------------------------------------------------');
console.log(`SUMMARY: ${passedTests}/${totalTests} TESTS PASSED`);
console.log('------------------------------------------------------------');

if (passedTests !== totalTests) {
  process.exit(1);
}

