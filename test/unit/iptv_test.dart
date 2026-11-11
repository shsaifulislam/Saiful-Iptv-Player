import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/security/ssrf_protection.dart';
import '../../lib/features/iptv/parsers/m3u_parser.dart';
import '../../lib/features/iptv/parsers/xmltv_parser.dart';

void main() {
  group('IPTV and EPG Unit Tests', () {
    test('SSRF Protection blocks loopback and private IPs', () {
      final res1 = SsrfProtection.validateUrl('http://127.0.0.1:8080/test.m3u');
      expect(res1.isSafe, isFalse);

      final res2 = SsrfProtection.validateUrl('http://169.254.169.254/latest/meta-data');
      expect(res2.isSafe, isFalse);

      final res3 = SsrfProtection.validateUrl('https://live-hls-web-aje.getaj.net/AJE/03.m3u8');
      expect(res3.isSafe, isTrue);
    });

    test('M3uParser correctly parses EXTINF tags and metadata', () {
      const sample = '''#EXTM3U
#EXTINF:-1 tvg-id="ch1" tvg-name="Channel One" tvg-logo="http://logo.png" group-title="News", Channel One HD
http://stream.org/ch1.m3u8''';

      final res = M3uParser.parse(sample);
      expect(res.channels.length, 1);
      expect(res.channels.first.name, 'Channel One HD');
      expect(res.channels.first.tvgId, 'ch1');
      expect(res.channels.first.groupTitle, 'News');
    });

    test('XmlTvParser handles timezone offsets properly', () {
      final date = XmlTvParser.parseXmlTvDate('20261111200000 +0600');
      expect(date, isNotNull);
      // 20:00 +0600 should equal 14:00 UTC
      expect(date!.isUtc, isTrue);
      expect(date.hour, 14);
    });
  });
}

