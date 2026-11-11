import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class PendingSyncChange {
  const PendingSyncChange({
    required this.idempotencyKey,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.baseRevision,
  });

  final String idempotencyKey;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int? baseRevision;

  Map<String, Object?> toJson() => {
        'idempotency_key': idempotencyKey,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': createdAt.toUtc().toIso8601String(),
        if (baseRevision != null) 'base_revision': baseRevision,
      };
}

class SyncOutbox {
  SyncOutbox({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'cloud_sync.outbox.v1';
  static const _maxQueuedChanges = 1000;
  static const _allowedEntities = {
    'playlist',
    'channel',
    'favorite',
    'watch_history',
    'watch_progress',
    'setting',
  };
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final RegExp _credentialUrl = RegExp(r'https?://[^/\s:@]+:[^/\s@]+@', caseSensitive: false);
  static const _forbiddenKeys = {
    'password',
    'username',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'api_key',
    'service_role_key',
    'credentials',
    'source_url',
    'playlist_url',
    'stream_url',
    'epg_url',
  };

  final SharedPreferencesAsync _preferences;

  Future<List<PendingSyncChange>> readPending() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map(_fromMap).whereType<PendingSyncChange>().toList();
    } on FormatException {
      await _preferences.remove(_key);
      return const [];
    }
  }

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, Object?> payload,
    int? baseRevision,
  }) async {
    if (!_allowedEntities.contains(entityType) ||
        !_uuidPattern.hasMatch(entityId) ||
        (operation != 'upsert' && operation != 'delete') ||
        (baseRevision != null && baseRevision < 0) ||
        _containsSecret(payload)) {
      throw ArgumentError('Sync change failed client-side validation.');
    }

    final pending = await readPending();
    if (pending.length >= _maxQueuedChanges) {
      throw StateError('Offline sync queue is full.');
    }
    final change = PendingSyncChange(
      idempotencyKey: _newUuid(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
      baseRevision: baseRevision,
    );
    await _preferences.setString(
      _key,
      jsonEncode([...pending.map((item) => item.toJson()), change.toJson()]),
    );
  }

  Future<void> removeAccepted(Set<String> idempotencyKeys) async {
    if (idempotencyKeys.isEmpty) return;
    final remaining = (await readPending())
        .where((change) => !idempotencyKeys.contains(change.idempotencyKey))
        .map((change) => change.toJson())
        .toList();
    await _preferences.setString(_key, jsonEncode(remaining));
  }

  Future<void> clear() => _preferences.remove(_key);

  PendingSyncChange? _fromMap(Map value) {
    final id = value['idempotency_key'];
    final entity = value['entity_type'];
    final entityId = value['entity_id'];
    final operation = value['operation'];
    final payload = value['payload'];
    final createdAt = DateTime.tryParse('${value['created_at']}');
    if (id is! String || !_uuidPattern.hasMatch(id) ||
        entity is! String || !_allowedEntities.contains(entity) ||
        entityId is! String || !_uuidPattern.hasMatch(entityId) ||
        operation is! String || (operation != 'upsert' && operation != 'delete') ||
        payload is! Map || createdAt == null) {
      return null;
    }
    final safePayload = <String, Object?>{};
    for (final entry in payload.entries) {
      if (entry.key is! String) return null;
      safePayload[entry.key as String] = entry.value;
    }
    if (_containsSecret(safePayload)) return null;
    return PendingSyncChange(
      idempotencyKey: id,
      entityType: entity,
      entityId: entityId,
      operation: operation,
      payload: safePayload,
      createdAt: createdAt.toUtc(),
      baseRevision: value['base_revision'] is int ? value['base_revision'] as int : null,
    );
  }

  bool _containsSecret(Object? value, [String key = '']) {
    if (_forbiddenKeys.contains(key.toLowerCase())) return true;
    if (value is String && _credentialUrl.hasMatch(value)) return true;
    if (value is Map) {
      return value.entries.any((entry) =>
          entry.key is String && _containsSecret(entry.value, entry.key as String));
    }
    if (value is Iterable) return value.any((item) => _containsSecret(item));
    return false;
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
