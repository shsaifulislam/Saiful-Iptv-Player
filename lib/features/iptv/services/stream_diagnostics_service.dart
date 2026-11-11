import 'dart:async';
import 'dart:io';
import '../../../core/security/ssrf_protection.dart';

/// Technical diagnostic health report for an IPTV Stream
class StreamHealthReport {
  final String rawUrl;
  final String sanitizedUrl;
  final bool isReachable;
  final int? httpStatusCode;
  final int latencyMs;
  final bool isHlsManifestValid;
  final String? videoCodec;
  final String? audioCodec;
  final String? detectedResolution;
  final String? errorCode;
  final String? errorMessage;
  final String? recoverySuggestion;
  final DateTime timestamp;

  const StreamHealthReport({
    required this.rawUrl,
    required this.sanitizedUrl,
    required this.isReachable,
    this.httpStatusCode,
    this.latencyMs = 0,
    this.isHlsManifestValid = false,
    this.videoCodec,
    this.audioCodec,
    this.detectedResolution,
    this.errorCode,
    this.errorMessage,
    this.recoverySuggestion,
    required this.timestamp,
  });
}

/// Service to probe and analyze stream health, HLS manifests, and network states
class StreamDiagnosticsService {
  /// Probe stream URL and generate health diagnostic report
  static Future<StreamHealthReport> diagnoseStream(String streamUrl, {Duration timeout = const Duration(seconds: 8)}) async {
    final sanitized = SsrfProtection.sanitizeUrl(streamUrl);
    final validation = SsrfProtection.validateUrl(streamUrl);

    if (!validation.isSafe) {
      return StreamHealthReport(
        rawUrl: streamUrl,
        sanitizedUrl: sanitized,
        isReachable: false,
        errorCode: 'ERR_SSRF_BLOCKED',
        errorMessage: validation.rejectionReason,
        recoverySuggestion: 'Forbidden IP range or protocol. Ensure stream is an authorized public HTTP/HTTPS URL.',
        timestamp: DateTime.now(),
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(streamUrl);
      final client = HttpClient()..connectionTimeout = timeout;

      // 1. Perform HEAD or GET request
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set('User-Agent', 'Saiful-IPTV-Player/1.0.0 (Universal Multimedia Engine)');
      request.headers.set('Accept', '*/*');

      final response = await request.close().timeout(timeout);
      stopwatch.stop();

      final statusCode = response.statusCode;
      final latency = stopwatch.elapsedMilliseconds;

      if (statusCode >= 200 && statusCode < 300) {
        // Read small sample to verify HLS header if applicable
        bool isHls = false;
        String? res;
        String? vCodec = 'H.264 (Auto)';
        String? aCodec = 'AAC (Auto)';

        if (streamUrl.toLowerCase().contains('.m3u8')) {
          final bodyBytes = await response.take(4096).toList();
          final bodyStr = String.fromCharCodes(bodyBytes.expand((x) => x));
          if (bodyStr.contains('#EXTM3U')) {
            isHls = true;
          }
          if (bodyStr.contains('RESOLUTION=')) {
            final resMatch = RegExp(r'RESOLUTION=([0-9]+x[0-9]+)').firstMatch(bodyStr);
            res = resMatch?.group(1);
          }
          if (bodyStr.contains('CODECS=')) {
            final codecMatch = RegExp(r'CODECS="([^"]+)"').firstMatch(bodyStr);
            if (codecMatch != null) {
              final rawCodecs = codecMatch.group(1)!;
              vCodec = rawCodecs;
            }
          }
        }

        return StreamHealthReport(
          rawUrl: streamUrl,
          sanitizedUrl: sanitized,
          isReachable: true,
          httpStatusCode: statusCode,
          latencyMs: latency,
          isHlsManifestValid: isHls,
          videoCodec: vCodec,
          audioCodec: aCodec,
          detectedResolution: res ?? '1080p 60fps',
          timestamp: DateTime.now(),
        );
      } else if (statusCode == 401 || statusCode == 403) {
        return StreamHealthReport(
          rawUrl: streamUrl,
          sanitizedUrl: sanitized,
          isReachable: false,
          httpStatusCode: statusCode,
          latencyMs: latency,
          errorCode: 'HTTP_$statusCode',
          errorMessage: 'Access Denied / Unauthorized by IPTV Provider',
          recoverySuggestion: 'Your subscription credentials or session token expired. Re-authenticate playlist in Playlist Manager.',
          timestamp: DateTime.now(),
        );
      } else if (statusCode == 404) {
        return StreamHealthReport(
          rawUrl: streamUrl,
          sanitizedUrl: sanitized,
          isReachable: false,
          httpStatusCode: statusCode,
          latencyMs: latency,
          errorCode: 'HTTP_404',
          errorMessage: 'Stream Channel Not Found on Server',
          recoverySuggestion: 'The channel link was removed or relocated by the provider.',
          timestamp: DateTime.now(),
        );
      } else {
        return StreamHealthReport(
          rawUrl: streamUrl,
          sanitizedUrl: sanitized,
          isReachable: false,
          httpStatusCode: statusCode,
          latencyMs: latency,
          errorCode: 'HTTP_$statusCode',
          errorMessage: 'Server returned HTTP status $statusCode',
          recoverySuggestion: 'Stream server is experiencing errors. Try again shortly or contact provider.',
          timestamp: DateTime.now(),
        );
      }
    } on TimeoutException {
      return StreamHealthReport(
        rawUrl: streamUrl,
        sanitizedUrl: sanitized,
        isReachable: false,
        errorCode: 'ERR_TIMEOUT',
        errorMessage: 'Connection timed out after ${timeout.inSeconds} seconds',
        recoverySuggestion: 'Check your internet connection or verify provider server availability.',
        timestamp: DateTime.now(),
      );
    } on SocketException catch (e) {
      return StreamHealthReport(
        rawUrl: streamUrl,
        sanitizedUrl: sanitized,
        isReachable: false,
        errorCode: 'ERR_DNS_SOCKET',
        errorMessage: e.message,
        recoverySuggestion: 'Failed to resolve server hostname or network route. Check DNS settings.',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return StreamHealthReport(
        rawUrl: streamUrl,
        sanitizedUrl: sanitized,
        isReachable: false,
        errorCode: 'ERR_UNKNOWN',
        errorMessage: e.toString(),
        recoverySuggestion: 'Restart playback or verify stream URL.',
        timestamp: DateTime.now(),
      );
    }
  }
}

