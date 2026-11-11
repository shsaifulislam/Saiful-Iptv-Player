import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import 'player_engine.dart';
import 'media_kit/media_kit_adapter.dart';
import 'android_media3/media3_adapter.dart';
import 'tizen_adapter/tizen_player_adapter.dart';
import 'webos_adapter/webos_player_adapter.dart';

/// Factory for instantiating the optimal PlayerEngine for the target platform
class PlayerAdapterFactory {
  /// Create the optimal platform player engine
  static PlayerEngine create({String? forcedAdapter}) {
    if (forcedAdapter != null) {
      switch (forcedAdapter.toLowerCase()) {
        case 'media3':
        case 'android':
          return Media3Adapter();
        case 'mediakit':
        case 'mpv':
          return MediaKitAdapter();
        case 'tizen':
          return TizenPlayerAdapter();
        case 'webos':
          return WebOSPlayerAdapter();
      }
    }

    if (kIsWeb) {
      return MediaKitAdapter();
    }

    try {
      if (Platform.isAndroid) {
        return Media3Adapter();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return MediaKitAdapter();
      } else if (Platform.isIOS) {
        return MediaKitAdapter();
      }
    } catch (_) {
      // If Platform check fails (e.g. customized embedded OS), check environment
    }

    return MediaKitAdapter();
  }

  /// List of supported adapter descriptions and capabilities
  static List<Map<String, dynamic>> getSupportedAdapters() {
    return [
      {
        'id': 'mediakit',
        'name': 'MediaKit (libmpv)',
        'platforms': ['Windows', 'macOS', 'Linux', 'Android', 'iOS'],
        'hardwareAcceleration': 'D3D11VA, VideoToolbox, VAAPI, MediaCodec',
        'protocols': ['HLS', 'DASH', 'HTTP', 'HTTPS', 'RTSP', 'RTMP', 'UDP', 'RTP'],
        'containers': ['MKV', 'MP4', 'AVI', 'TS', 'MOV', 'WebM', 'FLV'],
        'status': 'Production Ready',
      },
      {
        'id': 'media3',
        'name': 'Android Media3 / ExoPlayer',
        'platforms': ['Android Phone', 'Android Tablet', 'Android TV', 'Google TV'],
        'hardwareAcceleration': 'Android MediaCodec, Audio Tunneling',
        'protocols': ['HLS', 'DASH', 'SmoothStreaming', 'Progressive HTTP'],
        'containers': ['MP4', 'MKV', 'TS', 'WebM', 'M4A', 'MP3'],
        'status': 'Production Ready',
      },
      {
        'id': 'tizen',
        'name': 'Samsung Tizen AVPlay',
        'platforms': ['Samsung Smart TV (Tizen 4.0+)'],
        'hardwareAcceleration': 'Samsung Hardware Pipeline, 4K UHD 60fps',
        'protocols': ['HLS', 'SmoothStreaming', 'MPEG-DASH'],
        'containers': ['TS', 'MP4', 'MKV'],
        'status': 'Production Ready (Tizen Native Bridge)',
      },
      {
        'id': 'webos',
        'name': 'LG webOS Luna Media Pipeline',
        'platforms': ['LG Smart TV (webOS 4.0+)'],
        'hardwareAcceleration': 'LG Hardware Pipeline, Dolby Vision/Atmos',
        'protocols': ['HLS', 'DASH', 'HTTP/HTTPS'],
        'containers': ['TS', 'MP4', 'MKV'],
        'status': 'Production Ready (Luna Bus Bridge)',
      },
    ];
  }
}

