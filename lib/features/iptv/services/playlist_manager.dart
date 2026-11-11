import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/security/ssrf_protection.dart';
import '../models/iptv_playlist.dart';
import '../models/iptv_channel.dart';
import '../models/epg_program.dart';
import '../parsers/m3u_parser.dart';
import '../parsers/xmltv_parser.dart';

/// Central state coordinator for Playlists, Channels, and EPG Guide
class PlaylistManager extends ChangeNotifier {
  static final PlaylistManager instance = PlaylistManager._internal();

  PlaylistManager._internal() {
    _initDefaultSeedData();
  }

  final List<IptvPlaylist> _playlists = [];
  final List<IptvChannel> _channels = [];
  final Set<String> _favoriteChannelIds = {};
  final List<IptvChannel> _recentlyWatched = [];
  EpgIndex? _epgIndex;

  // Active channel selection
  IptvChannel? _activeChannel;

  // Getters
  List<IptvPlaylist> get playlists => List.unmodifiable(_playlists);
  List<IptvChannel> get allChannels => List.unmodifiable(_channels);
  List<IptvChannel> get favoriteChannels =>
      _channels.where((c) => _favoriteChannelIds.contains(c.id)).toList();
  List<IptvChannel> get recentlyWatched => List.unmodifiable(_recentlyWatched);
  IptvChannel? get activeChannel => _activeChannel;
  EpgIndex? get epgIndex => _epgIndex;

  List<String> get categories {
    final set = <String>{'All', 'Favorites'};
    for (final ch in _channels) {
      if (ch.groupTitle.isNotEmpty) {
        set.add(ch.groupTitle);
      }
    }
    return set.toList();
  }

  void _initDefaultSeedData() {
    // Initial authorized sample playlist
    final defaultPlaylist = IptvPlaylist(
      id: 'pl_licensed_broadcast',
      name: 'Global Public News & Broadcast',
      type: PlaylistType.m3u8,
      sourceUrl: 'https://iptv-org.github.io/iptv/index.m3u',
      channelCount: 5,
      isEnabled: true,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
      lastSuccessfulCheck: DateTime.now().subtract(const Duration(hours: 3)),
      connectionStatus: ConnectionStatus.online,
    );
    _playlists.add(defaultPlaylist);

    // Initial seed channels with licensed public streams
    _channels.addAll([
      const IptvChannel(
        id: 'ch_aljazeera_en',
        playlistId: 'pl_licensed_broadcast',
        name: 'Al Jazeera English HD',
        streamUrl: 'https://live-hls-web-aje.getaj.net/AJE/03.m3u8',
        logoUrl: 'https://i.imgur.com/Gj8u98L.png',
        groupTitle: 'News',
        tvgId: 'aljazeera.en',
        tvgName: 'Al Jazeera English',
        isFavorite: true,
      ),
      const IptvChannel(
        id: 'ch_dw_en',
        playlistId: 'pl_licensed_broadcast',
        name: 'Deutsche Welle English (DW)',
        streamUrl: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
        logoUrl: 'https://i.imgur.com/Z4wVj04.png',
        groupTitle: 'News',
        tvgId: 'dw.en',
        tvgName: 'DW English',
      ),
      const IptvChannel(
        id: 'ch_france24_en',
        playlistId: 'pl_licensed_broadcast',
        name: 'France 24 English HD',
        streamUrl: 'https://static.france24.com/live/F24_EN_LO_HLS/live_tv.m3u8',
        logoUrl: 'https://i.imgur.com/1mO9XjA.png',
        groupTitle: 'News',
        tvgId: 'france24.en',
        tvgName: 'France 24 English',
      ),
      const IptvChannel(
        id: 'ch_redbull_tv',
        playlistId: 'pl_licensed_broadcast',
        name: 'Red Bull TV Live',
        streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/geoSTB/master.m3u8',
        logoUrl: 'https://i.imgur.com/yU4E9V7.png',
        groupTitle: 'Sports',
        tvgId: 'redbull.tv',
        tvgName: 'Red Bull TV',
        isFavorite: true,
      ),
      const IptvChannel(
        id: 'ch_nasa_tv',
        playlistId: 'pl_licensed_broadcast',
        name: 'NASA TV Public HD',
        streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
        logoUrl: 'https://i.imgur.com/b9r8a3s.png',
        groupTitle: 'Documentary',
        tvgId: 'nasa.public',
        tvgName: 'NASA TV',
      ),
    ]);

    _favoriteChannelIds.addAll(['ch_aljazeera_en', 'ch_redbull_tv']);
    _activeChannel = _channels.first;

    // Load sample EPG
    _loadSampleEpg();
  }

  void _loadSampleEpg() {
    const sampleXml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv generator-info-name="Saiful IPTV Engine">
  <channel id="aljazeera.en">
    <display-name>Al Jazeera English</display-name>
    <icon src="https://i.imgur.com/Gj8u98L.png"/>
  </channel>
  <channel id="redbull.tv">
    <display-name>Red Bull TV</display-name>
    <icon src="https://i.imgur.com/yU4E9V7.png"/>
  </channel>
  <programme start="20261111000000 +0000" stop="20261111235959 +0000" channel="aljazeera.en">
    <title>Newshour Live</title>
    <desc>Live global news reporting and investigative journalism from international bureaus.</desc>
    <category>News</category>
  </programme>
  <programme start="20261111000000 +0000" stop="20261111235959 +0000" channel="redbull.tv">
    <title>Action Sports World Championship</title>
    <desc>Extreme downhill mountain biking, cliff diving, and rally racing highlights.</desc>
    <category>Sports</category>
  </programme>
</tv>''';
    _epgIndex = XmlTvParser.parse(sampleXml);
  }

  /// Preview M3U content before importing
  M3uPreviewSummary previewM3u(String content) {
    return M3uParser.generatePreview(content);
  }

  /// Add new playlist and ingest channels
  Future<IptvPlaylist> addPlaylist({
    required String name,
    required PlaylistType type,
    String? sourceUrl,
    String? localContent,
    String? epgUrl,
  }) async {
    // Validate SSRF if remote URL
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      final validation = SsrfProtection.validateUrl(sourceUrl);
      if (!validation.isSafe) {
        throw ArgumentError(validation.rejectionReason ?? 'Unsafe URL');
      }
    }

    final id = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = IptvPlaylist(
      id: id,
      name: name,
      type: type,
      sourceUrl: sourceUrl,
      epgUrl: epgUrl,
      lastUpdated: DateTime.now(),
      lastSuccessfulCheck: DateTime.now(),
      connectionStatus: ConnectionStatus.online,
    );

    _playlists.add(playlist);

    // Parse and add channels if content supplied
    if (localContent != null && localContent.isNotEmpty) {
      final result = M3uParser.parse(localContent, playlistId: id);
      _channels.addAll(result.channels);
      // Update channel count
      final updated = playlist.copyWith(channelCount: result.channels.length);
      final idx = _playlists.indexWhere((p) => p.id == id);
      if (idx != -1) _playlists[idx] = updated;
    }

    notifyListeners();
    return playlist;
  }

  /// Edit existing playlist
  void editPlaylist(String id, {String? name, String? sourceUrl, String? epgUrl, bool? isEnabled}) {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final existing = _playlists[index];
    _playlists[index] = existing.copyWith(
      name: name,
      sourceUrl: sourceUrl,
      epgUrl: epgUrl,
      isEnabled: isEnabled,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// Delete playlist and associated channels
  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _channels.removeWhere((c) => c.playlistId == id);
    if (_activeChannel != null && _activeChannel!.playlistId == id) {
      _activeChannel = _channels.isNotEmpty ? _channels.first : null;
    }
    notifyListeners();
  }

  /// Toggle playlist active state
  void togglePlaylistEnabled(String id) {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final existing = _playlists[index];
    _playlists[index] = existing.copyWith(isEnabled: !existing.isEnabled);
    notifyListeners();
  }

  /// Toggle channel favorite state
  void toggleFavorite(String channelId) {
    if (_favoriteChannelIds.contains(channelId)) {
      _favoriteChannelIds.remove(channelId);
    } else {
      _favoriteChannelIds.add(channelId);
    }
    notifyListeners();
  }

  bool isChannelFavorite(String channelId) => _favoriteChannelIds.contains(channelId);

  /// Select active channel for playback
  void setActiveChannel(IptvChannel channel) {
    _activeChannel = channel;
    _recordRecentlyWatched(channel);
    notifyListeners();
  }

  void _recordRecentlyWatched(IptvChannel channel) {
    _recentlyWatched.removeWhere((c) => c.id == channel.id);
    _recentlyWatched.insert(0, channel);
    if (_recentlyWatched.length > 20) {
      _recentlyWatched.removeLast();
    }
  }

  /// Switch to next channel in list
  void nextChannel() {
    if (_channels.isEmpty) return;
    if (_activeChannel == null) {
      setActiveChannel(_channels.first);
      return;
    }
    final index = _channels.indexWhere((c) => c.id == _activeChannel!.id);
    if (index != -1 && index + 1 < _channels.length) {
      setActiveChannel(_channels[index + 1]);
    } else {
      setActiveChannel(_channels.first); // Wrap around
    }
  }

  /// Switch to previous channel in list
  void previousChannel() {
    if (_channels.isEmpty) return;
    if (_activeChannel == null) {
      setActiveChannel(_channels.first);
      return;
    }
    final index = _channels.indexWhere((c) => c.id == _activeChannel!.id);
    if (index > 0) {
      setActiveChannel(_channels[index - 1]);
    } else {
      setActiveChannel(_channels.last); // Wrap around
    }
  }

  /// Get current program for a channel from EPG
  EpgProgram? getCurrentProgram(String? tvgId) {
    if (tvgId == null || _epgIndex == null) return null;
    return _epgIndex!.getCurrentProgram(tvgId);
  }

  /// Get next program for a channel from EPG
  EpgProgram? getNextProgram(String? tvgId) {
    if (tvgId == null || _epgIndex == null) return null;
    return _epgIndex!.getNextProgram(tvgId);
  }

  /// Filter channels by category and search query
  List<IptvChannel> filterChannels({String category = 'All', String query = ''}) {
    var result = _channels;

    if (category == 'Favorites') {
      result = favoriteChannels;
    } else if (category != 'All') {
      result = result.where((c) => c.groupTitle.toLowerCase() == category.toLowerCase()).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((c) => c.name.toLowerCase().contains(q) || c.groupTitle.toLowerCase().contains(q)).toList();
    }

    return result;
  }
}

