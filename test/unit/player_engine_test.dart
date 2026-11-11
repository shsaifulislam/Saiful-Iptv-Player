import 'package:flutter_test/flutter_test.dart';
import '../../lib/playback/player_engine.dart';
import '../../lib/playback/subtitles/subtitle_parser.dart';
import '../../lib/playback/diagnostics/media_diagnostics.dart';

void main() {
  group('Player Engine & Diagnostics Tests', () {
    test('MediaSource URL credential sanitization', () {
      const rawUrl = 'http://saiful:pass999@provider.com/live/myuser/mypass/stream.m3u8?token=secret123';
      final sanitized = MediaSource.sanitizeMediaUri(rawUrl);

      expect(sanitized.contains('pass999'), isFalse);
      expect(sanitized.contains('mypass'), isFalse);
      expect(sanitized.contains('secret123'), isFalse);
      expect(sanitized.contains('****/****/stream.m3u8'), isTrue);
      expect(sanitized.contains('token=[REDACTED]'), isTrue);
    });

    test('SubtitleParser parses SRT and VTT cues', () {
      const srt = '''1
00:00:10,000 --> 00:00:15,000
<i>Welcome to Saiful IPTV Player</i>

2
00:00:16,000 --> 00:00:20,000
Universal Playback Verified''';

      final cues = SubtitleParser.parse(srt);
      expect(cues.length, 2);
      expect(cues[0].startTime, const Duration(seconds: 10));
      expect(cues[0].endTime, const Duration(seconds: 15));
      expect(cues[0].text, 'Welcome to Saiful IPTV Player');

      expect(cues[0].isActiveAt(const Duration(seconds: 12)), isTrue);
      expect(cues[0].isActiveAt(const Duration(seconds: 18)), isFalse);
    });

    test('MediaDiagnosticsHelper provides actionable recovery messages', () {
      final suggestion = MediaDiagnosticsHelper.getRecoverySuggestion('ERROR_CODE_DECODER_INIT_FAILED', null);
      expect(suggestion.contains('Hardware decoding failed'), isTrue);
    });
  });
}

