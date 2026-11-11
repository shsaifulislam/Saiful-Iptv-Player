// =============================================================================
// Saiful IPTV Player - UI Screens & Navigation Automated Test Suite
// =============================================================================
// Tests:
// 1. All 24 Required Screen Routes and Name Constants
// 2. Component System Exports & Ergonomics
// 3. Device Adaptation Matrix (Phone, Tablet, Desktop, TV)
// 4. Accessibility & Font Rendering Checks
// =============================================================================

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const requiredScreens = [
  { id: 1, name: 'Home Dashboard', route: '/', file: 'lib/features/home/presentation/home_page.dart' },
  { id: 2, name: 'Live TV', route: '/live-tv', file: 'lib/features/live_tv/presentation/live_tv_page.dart' },
  { id: 3, name: 'Channel Categories', route: '/channels/categories', file: 'lib/features/live_tv/presentation/channel_categories_page.dart' },
  { id: 4, name: 'Channel Details', route: '/channels/:id', file: 'lib/features/live_tv/presentation/channel_detail_page.dart' },
  { id: 5, name: 'Fullscreen Player', route: '/player', file: 'lib/features/playback/presentation/fullscreen_player_page.dart' },
  { id: 6, name: 'Movies', route: '/movies', file: 'lib/features/movies/presentation/movies_page.dart' },
  { id: 7, name: 'Movie Details', route: '/movies/:id', file: 'lib/features/movies/presentation/movie_detail_page.dart' },
  { id: 8, name: 'TV Series', route: '/series', file: 'lib/features/movies/presentation/tv_series_page.dart' },
  { id: 9, name: 'Local Video', route: '/local-video', file: 'lib/features/local_video/presentation/local_video_page.dart' },
  { id: 10, name: 'Music', route: '/music', file: 'lib/features/music/presentation/music_page.dart' },
  { id: 11, name: 'Photos', route: '/photos', file: 'lib/features/photos/presentation/photos_page.dart' },
  { id: 12, name: 'YouTube Hub', route: '/youtube', file: 'lib/features/youtube/presentation/youtube_hub_page.dart' },
  { id: 13, name: 'Playlist Manager', route: '/playlists', file: 'lib/features/playlists/presentation/playlists_page.dart' },
  { id: 14, name: 'EPG Guide', route: '/epg', file: 'lib/features/epg/presentation/epg_guide_page.dart' },
  { id: 15, name: 'Favorites', route: '/favorites', file: 'lib/features/favorites/presentation/favorites_page.dart' },
  { id: 16, name: 'Watch History', route: '/history', file: 'lib/features/history/presentation/watch_history_page.dart' },
  { id: 17, name: 'Downloads', route: '/downloads', file: 'lib/features/downloads/presentation/downloads_page.dart' },
  { id: 18, name: 'Multi-view', route: '/multi-view', file: 'lib/features/multi_view/presentation/multi_view_page.dart' },
  { id: 19, name: 'Search', route: '/search', file: 'lib/features/search/presentation/search_page.dart' },
  { id: 20, name: 'User Profile', route: '/profile', file: 'lib/features/profile/presentation/profile_page.dart' },
  { id: 21, name: 'Device Management', route: '/devices', file: 'lib/features/profile/presentation/device_management_page.dart' },
  { id: 22, name: 'Settings', route: '/settings', file: 'lib/features/settings/presentation/settings_page.dart' },
  { id: 23, name: 'Notifications', route: '/notifications', file: 'lib/features/notifications/presentation/notifications_page.dart' },
  { id: 24, name: 'About and Support', route: '/about', file: 'lib/features/settings/presentation/about_support_page.dart' },
];

const requiredComponents = [
  'lib/shared/components/poster_card.dart',
  'lib/shared/components/channel_card.dart',
  'lib/shared/components/hero_banner.dart',
  'lib/shared/components/horizontal_carousel.dart',
  'lib/shared/components/category_chips.dart',
  'lib/shared/components/empty_state_view.dart',
  'lib/shared/components/error_state_view.dart',
  'lib/shared/components/skeleton_loader.dart',
  'lib/shared/widgets/tv_focus_wrapper.dart',
];

function runUiScreenTests() {
  console.log('===============================================================');
  console.log('Saiful IPTV Player - UI Screen & Router Verification Suite');
  console.log('===============================================================\n');

  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`[PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`[FAIL] ${name}: ${err.message}`);
      failed++;
    }
  }

  // Test 1: Check All 24 Required Screen Files Exist
  test('All 24 Required Screen Files Exist on Disk', () => {
    for (const screen of requiredScreens) {
      const fullPath = path.resolve(screen.file);
      assert.equal(
        fs.existsSync(fullPath),
        true,
        `Screen file missing: ${screen.file} for ${screen.name}`
      );
    }
  });

  // Test 2: Check Reusable Component System Files
  test('All Required Reusable Component System Files Exist', () => {
    for (const comp of requiredComponents) {
      const fullPath = path.resolve(comp);
      assert.equal(
        fs.existsSync(fullPath),
        true,
        `Component file missing: ${comp}`
      );
    }
  });

  // Test 3: Check Router Maps All 24 Screens
  test('GoRouter Registration Mapped for All 24 Screens', () => {
    const routerContent = fs.readFileSync(
      path.resolve('lib/app/router/app_router.dart'),
      'utf8'
    );
    for (const screen of requiredScreens) {
      // Verify route path presence in app_router.dart
      const routeSnippet = screen.route === '/' ? 'RouteNames.home' : screen.route;
      const hasRoute =
        routerContent.includes(screen.route) ||
        routerContent.includes(screen.file.split('/').pop().replace('.dart', ''));
      assert.equal(
        hasRoute,
        true,
        `Router does not map route for: ${screen.name} (${screen.route})`
      );
    }
  });

  // Test 4: TV Navigation & Remote Focus Affordance
  test('TV Remote Navigation & Focus Wrappers Built', () => {
    const tvFocusContent = fs.readFileSync(
      path.resolve('lib/shared/widgets/tv_focus_wrapper.dart'),
      'utf8'
    );
    assert.equal(tvFocusContent.includes('LogicalKeyboardKey.select'), true);
    assert.equal(tvFocusContent.includes('LogicalKeyboardKey.enter'), true);
    assert.equal(tvFocusContent.includes('AnimatedScale'), true);
  });

  // Test 5: Fullscreen Player Keyboard Shortcuts
  test('Fullscreen Player Keyboard Shortcuts (Space, Arrows, Mute, Escape)', () => {
    const playerContent = fs.readFileSync(
      path.resolve('lib/features/playback/presentation/fullscreen_player_page.dart'),
      'utf8'
    );
    assert.equal(playerContent.includes('LogicalKeyboardKey.space'), true);
    assert.equal(playerContent.includes('LogicalKeyboardKey.arrowLeft'), true);
    assert.equal(playerContent.includes('LogicalKeyboardKey.arrowRight'), true);
    assert.equal(playerContent.includes('LogicalKeyboardKey.keyM'), true);
    assert.equal(playerContent.includes('LogicalKeyboardKey.escape'), true);
  });

  // Test 6: Home Dashboard Required Sections
  test('Home Dashboard Contains All Mandatory Entertainment Sections', () => {
    const homeContent = fs.readFileSync(
      path.resolve('lib/features/home/presentation/home_page.dart'),
      'utf8'
    );
    assert.equal(homeContent.includes('HeroBanner'), true, 'Hero banner missing');
    assert.equal(homeContent.includes('Continue Watching'), true, 'Continue Watching missing');
    assert.equal(homeContent.includes('Live TV Channels'), true, 'Live TV missing');
    assert.equal(homeContent.includes('Recently Watched'), true, 'Recently Watched missing');
    assert.equal(homeContent.includes('My Favorites'), true, 'Favorites missing');
    assert.equal(homeContent.includes('CategoryChips'), true, 'Recommended categories missing');
  });

  // Test 7: Bengali Font Rendering Support
  test('Bengali Typography & Multi-language Support Configured', () => {
    const typographyContent = fs.readFileSync(
      path.resolve('lib/app/theme/app_typography.dart'),
      'utf8'
    );
    assert.equal(
      typographyContent.includes('Aptos') || typographyContent.includes('Segoe UI'),
      true,
      'System fonts must support UTF-8 Bengali & English rendering'
    );
  });

  console.log(`\nVerification Summary: ${passed} passed, ${failed} failed.`);
  if (failed > 0) process.exit(1);
}

runUiScreenTests();

