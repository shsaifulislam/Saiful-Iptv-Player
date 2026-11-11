import 'dart:convert';
import '../models/iptv_channel.dart';

/// Parse result container for M3U playlists
class M3uParseResult {
  final List<IptvChannel> channels;
  final Set<String> groups;
  final int totalParsed;
  final int duplicatesSkipped;
  final int malformedSkipped;

  const M3uParseResult({
    required this.channels,
    required this.groups,
    required this.totalParsed,
    required this.duplicatesSkipped,
    required this.malformedSkipped,
  });
}

/// M3U Preview summary container
class M3uPreviewSummary {
  final int estimatedChannels;
  final List<IptvChannel> sampleChannels;
  final List<String> detectedGroups;
  final bool hasValidHeader;

  const M3uPreviewSummary({
    required this.estimatedChannels,
    required this.sampleChannels,
    required this.detectedGroups,
    required this.hasValidHeader,
  });
}

/// High-performance, memory-efficient M3U and M3U8 Playlist Parser
class M3uParser {
  /// Fast preview generation for UI before saving
  static M3uPreviewSummary generatePreview(String content, {int sampleLimit = 10, String playlistId = 'preview'}) {
    final lines = LineSplitter.split(content).iterator;
    bool hasHeader = false;
    int estimated = 0;
    final samples = <IptvChannel>[];
    final groups = <String>{};

    _ExtInfEntry? currentEntry;

    while (lines.moveNext()) {
      final line = lines.current.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        hasHeader = true;
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        currentEntry = _parseExtInfLine(line);
        continue;
      }

      if (line.startsWith('#')) {
        // Skip comment or secondary tag
        continue;
      }

      // Stream URL line
      if (currentEntry != null) {
        estimated++;
        final group = currentEntry.groupTitle.isNotEmpty ? currentEntry.groupTitle : 'General';
        groups.add(group);

        if (samples.length < sampleLimit) {
          samples.add(IptvChannel(
            id: 'sample_$estimated',
            playlistId: playlistId,
            name: currentEntry.name.isNotEmpty ? currentEntry.name : 'Channel $estimated',
            streamUrl: line,
            logoUrl: currentEntry.tvgLogo,
            groupTitle: group,
            tvgId: currentEntry.tvgId,
            tvgName: currentEntry.tvgName,
            tvgLogo: currentEntry.tvgLogo,
            tvgChno: currentEntry.tvgChno,
            tvgShift: currentEntry.tvgShift,
          ));
        }

        currentEntry = null;
      }
    }

    return M3uPreviewSummary(
      estimatedChannels: estimated,
      sampleChannels: samples,
      detectedGroups: groups.toList()..sort(),
      hasValidHeader: hasHeader,
    );
  }

  /// Parse M3U content with deduplication and error tolerance
  static M3uParseResult parse(String content, {String playlistId = 'default', bool deduplicate = true}) {
    final channels = <IptvChannel>[];
    final groups = <String>{};
    final seenUrls = <String>{};

    int totalParsed = 0;
    int duplicatesSkipped = 0;
    int malformedSkipped = 0;

    final lines = LineSplitter.split(content).iterator;
    _ExtInfEntry? currentEntry;

    while (lines.moveNext()) {
      final rawLine = lines.current;
      final line = rawLine.trim();

      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        continue;
      }

      if (line.startsWith('#EXTINF:')) {
        currentEntry = _parseExtInfLine(line);
        continue;
      }

      // If line is another comment or tag (e.g. #EXTVLCOPT), keep currentEntry for next URL
      if (line.startsWith('#')) {
        continue;
      }

      // We have a URL line
      if (currentEntry == null) {
        // Raw URL without EXTINF: still accept as basic channel
        final uri = Uri.tryParse(line);
        if (uri != null && uri.hasScheme) {
          totalParsed++;
          final channelId = '${playlistId}_ch_$totalParsed';
          final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Stream $totalParsed';
          final channel = IptvChannel(
            id: channelId,
            playlistId: playlistId,
            name: name,
            streamUrl: line,
            groupTitle: 'Uncategorized',
          );
          channels.add(channel);
          groups.add('Uncategorized');
        } else {
          malformedSkipped++;
        }
        continue;
      }

      // Validate stream URL
      final uri = Uri.tryParse(line);
      if (uri == null || !uri.hasScheme) {
        malformedSkipped++;
        currentEntry = null;
        continue;
      }

      // Deduplication check
      final normalizedUrl = line.toLowerCase();
      if (deduplicate && seenUrls.contains(normalizedUrl)) {
        duplicatesSkipped++;
        currentEntry = null;
        continue;
      }
      seenUrls.add(normalizedUrl);

      totalParsed++;
      final group = currentEntry.groupTitle.isNotEmpty ? currentEntry.groupTitle : 'General';
      groups.add(group);

      final channelName = currentEntry.name.isNotEmpty
          ? currentEntry.name
          : (currentEntry.tvgName?.isNotEmpty == true
              ? currentEntry.tvgName!
              : 'Channel $totalParsed');

      final channel = IptvChannel(
        id: '${playlistId}_${currentEntry.tvgId ?? totalParsed.toString()}',
        playlistId: playlistId,
        name: channelName,
        streamUrl: line,
        logoUrl: currentEntry.tvgLogo,
        groupTitle: group,
        tvgId: currentEntry.tvgId,
        tvgName: currentEntry.tvgName,
        tvgLogo: currentEntry.tvgLogo,
        tvgChno: currentEntry.tvgChno,
        tvgShift: currentEntry.tvgShift,
      );

      channels.add(channel);
      currentEntry = null;
    }

    return M3uParseResult(
      channels: channels,
      groups: groups,
      totalParsed: totalParsed,
      duplicatesSkipped: duplicatesSkipped,
      malformedSkipped: malformedSkipped,
    );
  }

  /// Parses `#EXTINF:-1 tvg-id="..." tvg-name="..." tvg-logo="..." group-title="...", Channel Name`
  static _ExtInfEntry _parseExtInfLine(String line) {
    // 1. Separate comma delimiter for channel title (find first comma outside quotes)
    int commaIndex = -1;
    bool insideQuotes = false;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == '"') {
        insideQuotes = !insideQuotes;
      } else if (line[i] == ',' && !insideQuotes) {
        commaIndex = i;
        break;
      }
    }

    String attributesPart = '';
    String title = '';

    if (commaIndex != -1) {
      attributesPart = line.substring(8, commaIndex).trim(); // Skip '#EXTINF:'
      title = line.substring(commaIndex + 1).trim();
    } else {
      attributesPart = line.substring(8).trim();
    }

    // 2. Parse key="value" or key=value attributes
    String? tvgId;
    String? tvgName;
    String? tvgLogo;
    String? groupTitle;
    String? tvgChno;
    String? tvgShift;

    // Regex for attribute="value" or attribute=value
    final attrRegex = RegExp(r'([a-zA-Z0-9_\-]+)=(?:"([^"]*)"|([^\s",]+))');
    final matches = attrRegex.allMatches(attributesPart);

    for (final match in matches) {
      final key = match.group(1)?.toLowerCase();
      final value = (match.group(2) ?? match.group(3) ?? '').trim();

      switch (key) {
        case 'tvg-id':
          tvgId = value;
          break;
        case 'tvg-name':
          tvgName = value;
          break;
        case 'tvg-logo':
          tvgLogo = value;
          break;
        case 'group-title':
          groupTitle = value;
          break;
        case 'tvg-chno':
          tvgChno = value;
          break;
        case 'tvg-shift':
          tvgShift = value;
          break;
      }
    }

    return _ExtInfEntry(
      name: title,
      tvgId: tvgId,
      tvgName: tvgName,
      tvgLogo: tvgLogo,
      groupTitle: groupTitle ?? '',
      tvgChno: tvgChno,
      tvgShift: tvgShift,
    );
  }
}

class _ExtInfEntry {
  final String name;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String groupTitle;
  final String? tvgChno;
  final String? tvgShift;

  const _ExtInfEntry({
    required this.name,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    required this.groupTitle,
    this.tvgChno,
    this.tvgShift,
  });
}

