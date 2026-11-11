import '../models/epg_program.dart';

/// EPG Database & Query Index for XMLTV Data
class EpgIndex {
  final Map<String, EpgChannelHeader> channels;
  final Map<String, List<EpgProgram>> programsByChannel;

  EpgIndex({
    required this.channels,
    required this.programsByChannel,
  });

  /// Get currently airing program for a channel
  EpgProgram? getCurrentProgram(String channelTvgId, [DateTime? now]) {
    final list = programsByChannel[channelTvgId];
    if (list == null || list.isEmpty) return null;

    final target = now?.toUtc() ?? DateTime.now().toUtc();
    for (final prog in list) {
      if (prog.isCurrentlyAiring(target)) {
        return prog;
      }
    }
    return null;
  }

  /// Get next scheduled program for a channel
  EpgProgram? getNextProgram(String channelTvgId, [DateTime? now]) {
    final list = programsByChannel[channelTvgId];
    if (list == null || list.isEmpty) return null;

    final target = now?.toUtc() ?? DateTime.now().toUtc();
    for (int i = 0; i < list.length; i++) {
      if (list[i].isCurrentlyAiring(target)) {
        if (i + 1 < list.length) {
          return list[i + 1];
        }
      }
    }

    // If no program is currently airing, return the first program in the future
    for (final prog in list) {
      if (prog.startTime.isAfter(target)) {
        return prog;
      }
    }

    return null;
  }

  /// Get full schedule for a channel on a specific date (in local/UTC)
  List<EpgProgram> getScheduleForDate(String channelTvgId, DateTime date) {
    final list = programsByChannel[channelTvgId];
    if (list == null) return [];

    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return list.where((p) {
      return (p.startTime.isAfter(startOfDay) || p.endTime.isAfter(startOfDay)) &&
          p.startTime.isBefore(endOfDay);
    }).toList();
  }
}

/// Secure XMLTV EPG Parser
class XmlTvParser {
  /// Parse XMLTV XML content string
  static EpgIndex parse(String xmlContent) {
    final channels = <String, EpgChannelHeader>{};
    final programs = <String, List<EpgProgram>>{};

    // XXE / Entity injection protection: strip any <!DOCTYPE or <!ENTITY declarations
    final sanitizedXml = xmlContent
        .replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<!ENTITY[^>]*>', caseSensitive: false), '');

    // 1. Parse Channels: <channel id="xxx">...</channel>
    final channelRegex = RegExp(r'<channel\s+id="([^"]+)"[^>]*>(.*?)</channel>', dotAll: true);
    final channelMatches = channelRegex.allMatches(sanitizedXml);

    for (final m in channelMatches) {
      final channelId = m.group(1)!;
      final body = m.group(2)!;

      final nameMatch = RegExp(r'<display-name[^>]*>([^<]+)</display-name>').firstMatch(body);
      final displayName = nameMatch?.group(1)?.trim() ?? channelId;

      final iconMatch = RegExp(r'<icon\s+src="([^"]+)"').firstMatch(body);
      final iconUrl = iconMatch?.group(1)?.trim();

      channels[channelId] = EpgChannelHeader(
        id: channelId,
        displayName: displayName,
        iconUrl: iconUrl,
      );
    }

    // 2. Parse Programmes: <programme start="..." stop="..." channel="...">...</programme>
    final progRegex = RegExp(
      r'<programme\s+start="([^"]+)"\s+stop="([^"]+)"\s+channel="([^"]+)"[^>]*>(.*?)</programme>',
      dotAll: true,
    );
    final progMatches = progRegex.allMatches(sanitizedXml);

    int progCounter = 1;
    for (final m in progMatches) {
      final startStr = m.group(1)!;
      final stopStr = m.group(2)!;
      final channelId = m.group(3)!;
      final body = m.group(4)!;

      final startTime = parseXmlTvDate(startStr);
      final endTime = parseXmlTvDate(stopStr);

      if (startTime == null || endTime == null) continue;

      final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>').firstMatch(body);
      final title = titleMatch?.group(1)?.trim() ?? 'Untitled Program';

      final descMatch = RegExp(r'<desc[^>]*>([^<]+)</desc>').firstMatch(body);
      final desc = descMatch?.group(1)?.trim();

      final catMatch = RegExp(r'<category[^>]*>([^<]+)</category>').firstMatch(body);
      final category = catMatch?.group(1)?.trim();

      final iconMatch = RegExp(r'<icon\s+src="([^"]+)"').firstMatch(body);
      final iconUrl = iconMatch?.group(1)?.trim();

      final program = EpgProgram(
        id: 'prog_${channelId}_${progCounter++}',
        channelTvgId: channelId,
        title: title,
        description: desc,
        category: category,
        startTime: startTime,
        endTime: endTime,
        iconUrl: iconUrl,
      );

      programs.putIfAbsent(channelId, () => []).add(program);
    }

    // Sort all channel programs chronologically
    for (final list in programs.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return EpgIndex(
      channels: channels,
      programsByChannel: programs,
    );
  }

  /// Parses XMLTV timestamp `YYYYMMDDHHMMSS +HHMM` or `YYYYMMDDHHMMSS -HHMM` or `YYYYMMDDHHMMSS Z`
  /// and returns accurate UTC DateTime
  static DateTime? parseXmlTvDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 14) return null;

    try {
      final year = int.parse(trimmed.substring(0, 4));
      final month = int.parse(trimmed.substring(4, 6));
      final day = int.parse(trimmed.substring(6, 8));
      final hour = int.parse(trimmed.substring(8, 10));
      final minute = int.parse(trimmed.substring(10, 12));
      final second = int.parse(trimmed.substring(12, 14));

      var utcDate = DateTime.utc(year, month, day, hour, minute, second);

      // Check timezone offset if present
      if (trimmed.length > 14) {
        final tzPart = trimmed.substring(14).trim();
        if (tzPart == 'Z' || tzPart == '+0000' || tzPart == '-0000') {
          return utcDate;
        }

        // Format e.g. +0600 or -0500
        final sign = tzPart.startsWith('-') ? -1 : 1;
        final cleanTz = tzPart.replaceAll('+', '').replaceAll('-', '');
        if (cleanTz.length >= 4) {
          final tzHours = int.parse(cleanTz.substring(0, 2));
          final tzMinutes = int.parse(cleanTz.substring(2, 4));
          final totalOffsetMinutes = sign * (tzHours * 60 + tzMinutes);

          // Convert to UTC: subtract the offset
          utcDate = utcDate.subtract(Duration(minutes: totalOffsetMinutes));
        }
      }

      return utcDate;
    } catch (_) {
      return null;
    }
  }
}

