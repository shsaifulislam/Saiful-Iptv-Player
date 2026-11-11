import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentity {
  DeviceIdentity({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _seedKey = 'device.installation.seed.v1';
  final FlutterSecureStorage _storage;
  Future<String>? _cachedHash;

  Future<String> get installationIdHash =>
      _cachedHash ??= _loadOrCreateHash();

  Future<String> _loadOrCreateHash() async {
    var seed = await _storage.read(key: _seedKey);
    if (seed == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      seed = base64UrlEncode(bytes);
      await _storage.write(key: _seedKey, value: seed);
    }
    return sha256.convert(utf8.encode(seed)).toString();
  }
}
