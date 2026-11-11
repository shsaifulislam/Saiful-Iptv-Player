import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProviderCredentials {
  const ProviderCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class SecureCredentialVault {
  SecureCredentialVault({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'provider.playlist.';
  static final RegExp _playlistIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final FlutterSecureStorage _storage;

  Future<void> save(String playlistId, ProviderCredentials credentials) async {
    _validateId(playlistId);
    if (credentials.username.isEmpty || credentials.password.isEmpty) {
      throw ArgumentError('Provider credentials must not be empty.');
    }
    await _storage.write(
      key: '$_prefix$playlistId',
      value: jsonEncode({
        'username': credentials.username,
        'password': credentials.password,
      }),
    );
  }

  Future<ProviderCredentials?> read(String playlistId) async {
    _validateId(playlistId);
    final stored = await _storage.read(key: '$_prefix$playlistId');
    if (stored == null) return null;
    try {
      final value = jsonDecode(stored);
      if (value is Map &&
          value['username'] is String &&
          value['password'] is String) {
        return ProviderCredentials(
          username: value['username'] as String,
          password: value['password'] as String,
        );
      }
    } on FormatException {
      await delete(playlistId);
    }
    return null;
  }

  Future<void> delete(String playlistId) async {
    _validateId(playlistId);
    await _storage.delete(key: '$_prefix$playlistId');
  }

  void _validateId(String playlistId) {
    if (!_playlistIdPattern.hasMatch(playlistId)) {
      throw ArgumentError.value(playlistId, 'playlistId');
    }
  }
}
