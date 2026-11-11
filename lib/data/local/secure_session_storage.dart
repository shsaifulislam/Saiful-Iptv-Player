import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SecureSessionStorage implements supabase.LocalStorage, supabase.GotrueAsyncStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'supabase.auth.session';
  static const _pkcePrefix = 'supabase.auth.pkce.';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    final stored = await _storage.read(key: _sessionKey);
    if (stored == null) return null;
    try {
      final value = jsonDecode(stored);
      if (value is Map<String, dynamic>) {
        final token = value['access_token'];
        return token is String ? token : null;
      }
      if (value is Map) {
        final token = value['access_token'];
        return token is String ? token : null;
      }
    } on FormatException {
      await _storage.delete(key: _sessionKey);
    }
    return null;
  }

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$_pkcePrefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_pkcePrefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$_pkcePrefix$key');
}
