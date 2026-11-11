import 'dart:ui';
import '../player_engine.dart';

/// Diagnostics service and utility for video playback
class MediaDiagnosticsHelper {
  /// Strips sensitive credentials from URLs
  static String sanitizeUrl(String url) {
    return MediaSource.sanitizeMediaUri(url);
  }

  /// Suggests a concrete user/operator recovery action based on error details
  static String getRecoverySuggestion(String errorCode, String? errorMessage) {
    final code = errorCode.toUpperCase();
    final msg = (errorMessage ?? '').toLowerCase();

    if (code.contains('DECODER') || msg.contains('codec') || msg.contains('decode')) {
      return 'Hardware decoding failed for this format. Switch to Software Decoder in Player Settings or verify device codec profile.';
    }
    if (code.contains('TIMEOUT') || msg.contains('timeout') || msg.contains('timed out')) {
      return 'Network connection timed out while loading media buffer. Check your internet connection or verify stream host availability.';
    }
    if (code.contains('HTTP_401') || code.contains('HTTP_403') || msg.contains('unauthorized') || msg.contains('forbidden')) {
      return 'Access denied by IPTV provider. Your subscription playlist token or credentials may have expired. Please re-authenticate your playlist.';
    }
    if (code.contains('HTTP_404') || msg.contains('not found')) {
      return 'Stream channel or media file not found on the server. The stream link may have changed or been removed by the provider.';
    }
    if (code.contains('SSL') || msg.contains('certificate') || msg.contains('handshake')) {
      return 'Secure TLS handshake failed. Check your device system date/time or configure HTTPS verification settings.';
    }
    if (code.contains('CORRUPT') || msg.contains('demux') || msg.contains('parse')) {
      return 'Container file header is corrupted or incomplete. Try re-downloading or playing through an alternate decoder adapter.';
    }

    return 'Try restarting playback. If the issue persists, inspect playlist source or report this error in Settings -> Support.';
  }

  /// Calculates buffer health score from 0.0 to 1.0
  static double calculateBufferHealth(Duration buffered, Duration position, {Duration targetBuffer = const Duration(seconds: 30)}) {
    final lead = buffered - position;
    if (lead <= Duration.zero) return 0.0;
    final ratio = lead.inMilliseconds / targetBuffer.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }
}

