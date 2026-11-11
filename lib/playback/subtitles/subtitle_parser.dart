/// A single subtitle cue representation
class SubtitleCue {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;

  const SubtitleCue({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  /// Check if the cue is active at the given playback position with an applied sync delay
  bool isActiveAt(Duration position, {int delayMs = 0}) {
    final adjusted = position - Duration(milliseconds: delayMs);
    return adjusted >= startTime && adjusted <= endTime;
  }

  @override
  String toString() => 'SubtitleCue($index, $startTime --> $endTime: $text)';
}

/// Robust Subtitle Parser supporting SubRip (.srt) and WebVTT (.vtt)
class SubtitleParser {
  /// Parse raw subtitle text content
  static List<SubtitleCue> parse(String content) {
    if (content.trim().isEmpty) return [];

    final cleanContent = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    if (cleanContent.startsWith('WEBVTT') || cleanContent.contains('-->') && cleanContent.contains('.')) {
      return _parseVtt(cleanContent);
    } else {
      return _parseSrt(cleanContent);
    }
  }

  static List<SubtitleCue> _parseSrt(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.split('\n\n');
    int cueIndex = 1;

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      int timeLineIndex = 0;
      // Sometimes index number is on the first line
      if (int.tryParse(lines[0].trim()) != null && lines.length >= 2) {
        timeLineIndex = 1;
      }

      if (timeLineIndex >= lines.length) continue;
      final timeLine = lines[timeLineIndex];
      if (!timeLine.contains('-->')) continue;

      final times = timeLine.split('-->');
      if (times.length != 2) continue;

      final start = _parseTimestamp(times[0].trim());
      final end = _parseTimestamp(times[1].trim());

      if (start == null || end == null) continue;

      final textLines = lines.sublist(timeLineIndex + 1);
      final text = _sanitizeSubtitleText(textLines.join('\n'));

      if (text.isNotEmpty) {
        cues.add(SubtitleCue(
          index: cueIndex++,
          startTime: start,
          endTime: end,
          text: text,
        ));
      }
    }

    return cues;
  }

  static List<SubtitleCue> _parseVtt(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split('\n');
    int cueIndex = 1;
    int i = 0;

    // Skip WEBVTT header
    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }

    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.contains('-->')) {
        final times = line.split('-->');
        final start = _parseTimestamp(times[0].trim().split(' ').first);
        final end = _parseTimestamp(times[1].trim().split(' ').first);

        i++;
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i]);
          i++;
        }

        if (start != null && end != null) {
          final text = _sanitizeSubtitleText(textLines.join('\n'));
          if (text.isNotEmpty) {
            cues.add(SubtitleCue(
              index: cueIndex++,
              startTime: start,
              endTime: end,
              text: text,
            ));
          }
        }
      }
      i++;
    }

    return cues;
  }

  static Duration? _parseTimestamp(String raw) {
    try {
      // Normalize comma to dot for milliseconds
      final cleaned = raw.replaceAll(',', '.').trim();
      final parts = cleaned.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secParts = parts[2].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;

        return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
      } else if (parts.length == 2) {
        // mm:ss.fff format
        final minutes = int.parse(parts[0]);
        final secParts = parts[1].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;

        return Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Strips formatting tags like <i>, <b>, <font color="...">, etc.
  static String _sanitizeSubtitleText(String raw) {
    final tagRegex = RegExp(r'<[^>]*>');
    return raw.replaceAll(tagRegex, '').trim();
  }
}

