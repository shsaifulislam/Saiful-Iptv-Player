import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LocalSyncStore {
  LocalSyncStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _prefix = 'cloud_sync.local.v1.';
  static const _maximumQueueLength = 1000;
  static const _entityTypes = {
    'playlist',
    'channel',
    'favorite',
    'watch_history',
    'watch_progress',
    'setting',
  };
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
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _credentialUrl = RegExp(r'https?://[^/\s:@]+:[^/\s@]+@', caseSensitive: false);

  final SharedPreferencesAsync _preferences;

  Future<List<Map<String, dynamic>>> readPending(String userId) async {
    final state = await _read(userId);
    return (state['pending'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>?> readRecord(
    String userId,
    String entityType,
    String entityId,
  ) async {
    final state = await _read(userId);
    final record = (state['records'] as Map<String, dynamic>? ?? const {})[
        _recordKey(entityType, entityId)];
    return record is Map ? Map<String, dynamic>.from(record) : null;
  }

  Future<Map<String, dynamic>> enqueueLocalChange({
    required String userId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    if (!_uuidPattern.hasMatch(userId) ||
        !_uuidPattern.hasMatch(entityId) ||
        !_entityTypes.contains(entityType) ||
        (operation != 'upsert' && operation != 'delete') ||
        _containsSecret(payload)) {
      throw ArgumentError('Local sync change failed validation.');
    }

    final state = await _read(userId);
    final pending = List<Map<String, dynamic>>.from(
      (state['pending'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    if (pending.length >= _maximumQueueLength) {
      throw StateError('Offline sync queue is full.');
    }

    final key = _recordKey(entityType, entityId);
    final records = Map<String, dynamic>.from(
      state['records'] as Map<String, dynamic>? ?? const {},
    );
    final current = records[key] is Map
        ? Map<String, dynamic>.from(records[key] as Map)
        : <String, dynamic>{'server_revision': 0};
    final change = <String, dynamic>{
      'idempotency_key': _newUuid(),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'base_revision': current['server_revision'] ?? 0,
      'payload': operation == 'upsert' ? payload : <String, Object?>{},
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    records[key] = {
      ...current,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': operation == 'upsert' ? payload : <String, Object?>{},
      'deleted': operation == 'delete',
      'dirty': true,
      'updated_at': change['created_at'],
    };
    pending.add(change);
    state['records'] = records;
    state['pending'] = pending;
    await _write(userId, state);
    return change;
  }

  Future<void> markAccepted(
    String userId,
    Map<String, int> acceptedRevisions,
  ) async {
    if (acceptedRevisions.isEmpty) return;
    final state = await _read(userId);
    final pending = List<Map<String, dynamic>>.from(
      (state['pending'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    final accepted = pending
        .where((change) => acceptedRevisions.containsKey(change['idempotency_key']))
        .toList();
    pending.removeWhere(
      (change) => acceptedRevisions.containsKey(change['idempotency_key']),
    );
    final records = Map<String, dynamic>.from(
      state['records'] as Map<String, dynamic>? ?? const {},
    );

    for (final change in accepted) {
      final entityType = change['entity_type'] as String;
      final entityId = change['entity_id'] as String;
      final key = _recordKey(entityType, entityId);
      final record = records[key];
      if (record is! Map) continue;
      final hasMorePending = pending.any((item) =>
          item['entity_type'] == entityType && item['entity_id'] == entityId);
      if (record['deleted'] == true && !hasMorePending) {
        records.remove(key);
      } else {
        records[key] = {
          ...Map<String, dynamic>.from(record),
          'server_revision': acceptedRevisions[change['idempotency_key']],
          'dirty': hasMorePending,
        };
      }
    }

    state['records'] = records;
    state['pending'] = pending;
    await _write(userId, state);
  }

  Future<void> recordRejected(String userId, String idempotencyKey, String code) async {
    final state = await _read(userId);
    final pending = List<Map<String, dynamic>>.from(
      (state['pending'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    final change = pending.firstWhere(
      (item) => item['idempotency_key'] == idempotencyKey,
      orElse: () => <String, dynamic>{},
    );
    if (change.isNotEmpty) {
      change['attempts'] = (change['attempts'] as int? ?? 0) + 1;
      change['last_error_code'] = code;
      final exponent = (change['attempts'] as int).clamp(0, 8);
      change['next_attempt_at'] = DateTime.now()
          .toUtc()
          .add(Duration(seconds: min(3600, 5 * (1 << exponent))))
          .toIso8601String();
    }
    state['pending'] = pending;
    await _write(userId, state);
  }

  Future<int> readCursor(String userId) async {
    final state = await _read(userId);
    return state['cursor'] is int ? state['cursor'] as int : 0;
  }

  Future<void> applyRemoteEvent(String userId, Map<String, dynamic> event) async {
    final entityType = event['entity_type'];
    final entityId = event['entity_id'];
    final revision = event['revision'];
    final cursor = event['id'];
    if (entityType is! String || !_entityTypes.contains(entityType) ||
        entityId is! String || !_uuidPattern.hasMatch(entityId) ||
        revision is! int || cursor is! int) {
      throw const FormatException('Invalid cloud sync event.');
    }

    final state = await _read(userId);
    final key = _recordKey(entityType, entityId);
    final records = Map<String, dynamic>.from(
      state['records'] as Map<String, dynamic>? ?? const {},
    );
    final current = records[key] is Map
        ? Map<String, dynamic>.from(records[key] as Map)
        : <String, dynamic>{'server_revision': 0};
    final pending = (state['pending'] as List<dynamic>? ?? const []).whereType<Map>();
    final hasPendingForEntity = pending.any((change) =>
        change['entity_type'] == entityType && change['entity_id'] == entityId);

    if (!hasPendingForEntity && revision >= (current['server_revision'] as int? ?? 0)) {
      records[key] = {
        ...current,
        'entity_type': entityType,
        'entity_id': entityId,
        'server_revision': revision,
        'payload': event['payload'] is Map ? event['payload'] : <String, dynamic>{},
        'deleted': event['operation'] == 'delete',
        'dirty': false,
        'updated_at': event['created_at'],
      };
    } else if (hasPendingForEntity) {
      current['conflict_revision'] = revision;
      current['conflict_payload'] = event['payload'];
      current['conflict_operation'] = event['operation'];
      current['conflict_updated_at'] = event['created_at'];
      records[key] = current;
    }

    state['records'] = records;
    state['cursor'] = max(cursor, state['cursor'] as int? ?? 0);
    await _write(userId, state);
  }

  Future<void> rebasePendingChange(
    String userId,
    String idempotencyKey,
    int serverRevision,
  ) async {
    final state = await _read(userId);
    final pending = List<Map<String, dynamic>>.from(
      (state['pending'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    final index = pending.indexWhere((item) => item['idempotency_key'] == idempotencyKey);
    if (index < 0) return;
    pending[index]['base_revision'] = serverRevision;
    pending[index]['idempotency_key'] = _newUuid();
    pending[index].remove('attempts');
    pending[index].remove('next_attempt_at');
    pending[index].remove('last_error_code');
    state['pending'] = pending;
    await _write(userId, state);
  }

  Future<bool> resolvePendingConflict(String userId, String idempotencyKey) async {
    final state = await _read(userId);
    final pending = List<Map<String, dynamic>>.from(
      (state['pending'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    final index = pending.indexWhere((item) => item['idempotency_key'] == idempotencyKey);
    if (index < 0) return false;

    final change = pending[index];
    final entityType = change['entity_type'] as String;
    final entityId = change['entity_id'] as String;
    final key = _recordKey(entityType, entityId);
    final records = Map<String, dynamic>.from(
      state['records'] as Map<String, dynamic>? ?? const {},
    );
    final recordValue = records[key];
    if (recordValue is! Map || recordValue['conflict_revision'] is! int) return false;
    final record = Map<String, dynamic>.from(recordValue);
    final serverRevision = record['conflict_revision'] as int;
    final localTime = DateTime.tryParse('${record['updated_at']}');
    final remoteTime = DateTime.tryParse('${record['conflict_updated_at']}');
    final keepLocal = localTime != null && remoteTime != null && localTime.isAfter(remoteTime);

    if (keepLocal) {
      change['base_revision'] = serverRevision;
      change['idempotency_key'] = _newUuid();
      change['attempts'] = 0;
      change.remove('next_attempt_at');
      change.remove('last_error_code');
      record['server_revision'] = serverRevision;
      record['dirty'] = true;
    } else {
      pending.removeAt(index);
      record['server_revision'] = serverRevision;
      record['payload'] = record['conflict_payload'] is Map
          ? record['conflict_payload']
          : <String, dynamic>{};
      record['deleted'] = record['conflict_operation'] == 'delete';
      record['updated_at'] = record['conflict_updated_at'];
      record['dirty'] = false;
    }
    record.remove('conflict_revision');
    record.remove('conflict_payload');
    record.remove('conflict_operation');
    record.remove('conflict_updated_at');
    if (record['deleted'] == true && !keepLocal) {
      records.remove(key);
    } else {
      records[key] = record;
    }
    state['records'] = records;
    state['pending'] = pending;
    await _write(userId, state);
    return true;
  }

  Future<void> recordSyncSuccess(String userId, DateTime timestamp) async {
    final state = await _read(userId);
    state['last_sync_at'] = timestamp.toUtc().toIso8601String();
    state.remove('last_sync_error');
    await _write(userId, state);
  }

  Future<void> recordSyncFailure(String userId, String errorCode) async {
    final state = await _read(userId);
    state['last_sync_error'] = errorCode;
    await _write(userId, state);
  }

  Future<DateTime?> lastSyncAt(String userId) async {
    final state = await _read(userId);
    return DateTime.tryParse('${state['last_sync_at']}')?.toUtc();
  }

  Future<String?> lastSyncError(String userId) async {
    final state = await _read(userId);
    final value = state['last_sync_error'];
    return value is String ? value : null;
  }

  Future<void> clearUser(String userId) => _preferences.remove(_key(userId));

  Future<Map<String, dynamic>> _read(String userId) async {
    if (!_uuidPattern.hasMatch(userId)) throw ArgumentError.value(userId, 'userId');
    final value = await _preferences.getString(_key(userId));
    if (value == null) return {'records': <String, dynamic>{}, 'pending': <dynamic>[], 'cursor': 0};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      await _preferences.remove(_key(userId));
    }
    return {'records': <String, dynamic>{}, 'pending': <dynamic>[], 'cursor': 0};
  }

  Future<void> _write(String userId, Map<String, dynamic> state) async {
    await _preferences.setString(_key(userId), jsonEncode(state));
  }

  String _key(String userId) => 'cloud_sync.local.v1.$userId';

  String _recordKey(String entityType, String entityId) => '$entityType:$entityId';

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
