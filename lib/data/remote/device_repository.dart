import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/device_identity.dart';

class DeviceRepository {
  DeviceRepository({
    required SupabaseClient client,
    required DeviceIdentity identity,
  })  : _client = client,
        _identity = identity;

  final SupabaseClient _client;
  final DeviceIdentity _identity;

  Future<Map<String, dynamic>> registerCurrentDevice() async {
    final response = await _client.functions.invoke(
      'device-register',
      body: {
        'installation_id_hash': await _identity.installationIdHash,
        'device_name': _deviceName,
        'platform': _platformName,
        'app_version': const String.fromEnvironment(
          'APP_VERSION',
          defaultValue: '1.0.0',
        ),
      },
    );
    final data = response.data;
    if (data is! Map || data['data'] is! Map) {
      throw const FormatException('Device registration returned an invalid response.');
    }
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<void> revoke(String deviceId) async {
    await _client.functions.invoke(
      'device-revoke',
      body: {'device_id': deviceId},
    );
  }

  String get _platformName => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.windows => 'windows',
        TargetPlatform.macOS => 'macos',
        TargetPlatform.linux => 'linux',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.fuchsia => 'android',
      };

  String get _deviceName => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'Android device',
        TargetPlatform.windows => 'Windows device',
        TargetPlatform.macOS => 'Mac',
        TargetPlatform.linux => 'Linux device',
        TargetPlatform.iOS => 'iOS device',
        TargetPlatform.fuchsia => 'Flutter device',
      };
}
