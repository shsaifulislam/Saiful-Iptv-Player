import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/local_sync_store.dart';
import '../remote/device_repository.dart';

class SyncReport {
  const SyncReport({
    required this.accepted,
    required this.rejected,
    required this.conflictsResolved,
    required this.lastSyncedAt,
    this.errorCode,
  });

  final int accepted;
  final int rejected;
  final int conflictsResolved;
  final DateTime? lastSyncedAt;
  final String? errorCode;

  bool get succeeded => errorCode == null && rejected == 0;
}

class CloudSyncRepository {
  CloudSyncRepository({
    required SupabaseClient client,
    required LocalSyncStore localStore,
    required DeviceRepository deviceRepository,
  })  : _client = client,
        _localStore = localStore,
        _deviceRepository = deviceRepository;

  final SupabaseClient _client;
  final LocalSyncStore _localStore;
  final DeviceRepository _deviceRepository;
  bool _syncing = false;

  Future<void> upsert({
    required String entityType,
    required String entityId,
    required Map<String, Object?> metadata,
  }) async {
    final userId = _requireUserId();
    await _localStore.enqueueLocalChange(
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      operation: 'upsert',
      payload: metadata,
    );
  }

  Future<void> delete({
    required String entityType,
    required String entityId,
  }) async {
    final userId = _requireUserId();
    await _localStore.enqueueLocalChange(
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      operation: 'delete',
      payload: const {},
    );
  }

  Future<Map<String, dynamic>?> readLocal(
    String entityType,
    String entityId,
  ) async {
    final userId = _requireUserId();
    return _localStore.readRecord(userId, entityType, entityId);
  }

  Future<SyncReport> syncNow() async {
    if (_syncing) {
      return SyncReport(
        accepted: 0,
        rejected: 0,
        conflictsResolved: 0,
        lastSyncedAt: await _localStore.lastSyncAt(_requireUserId()),
        errorCode: 'sync_already_running',
      );
    }

    final userId = _requireUserId();
    _syncing = true;
    var acceptedCount = 0;
    var rejectedCount = 0;
    var resolvedCount = 0;
    try {
      final device = await _deviceRepository.registerCurrentDevice();
      final deviceId = device['id'];
      if (deviceId is! String || deviceId.isEmpty) {
        throw const FormatException('Device registration response is invalid.');
      }

      for (var pass = 0; pass < 2; pass++) {
        final pending = await _dueChanges(userId);
        for (var offset = 0; offset < pending.length; offset += 100) {
          final batch = pending.skip(offset).take(100).toList();
          final response = await _client.functions.invoke(
            'sync',
            body: {
              'device_id': deviceId,
              'changes': batch,
            },
          );
          final envelope = response.data;
          final result = envelope is Map ? envelope['data'] : null;
          if (result is! Map) throw const FormatException('Sync response is invalid.');

          final acceptedItems = _records(result['accepted']);
          final revisions = <String, int>{};
          for (final item in acceptedItems) {
            final key = item['idempotency_key'];
            final revision = _asInt(item['server_revision']);
            if (key is String) {
              revisions[key] = revision ?? _baseRevision(batch, key);
            }
          }
          await _localStore.markAccepted(userId, revisions);
          acceptedCount += revisions.length;

          for (final item in _records(result['rejected'])) {
            final key = item['idempotency_key'];
            final code = item['code'];
            if (key is String) {
              await _localStore.recordRejected(
                userId,
                key,
                code is String ? code : 'sync_rejected',
              );
              rejectedCount++;
            }
          }
        }

        await _pullChanges(userId);
        final conflicts = await _resolvePulledConflicts(userId);
        resolvedCount += conflicts;
        if (conflicts == 0) break;
      }

      final now = DateTime.now().toUtc();
      await _localStore.recordSyncSuccess(userId, now);
      return SyncReport(
        accepted: acceptedCount,
        rejected: rejectedCount,
        conflictsResolved: resolvedCount,
        lastSyncedAt: now,
      );
    } catch (error) {
      await _localStore.recordSyncFailure(userId, _safeErrorCode(error));
      return SyncReport(
        accepted: acceptedCount,
        rejected: rejectedCount,
        conflictsResolved: resolvedCount,
        lastSyncedAt: await _localStore.lastSyncAt(userId),
        errorCode: _safeErrorCode(error),
      );
    } finally {
      _syncing = false;
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Authentication required.');
    return id;
  }

  Future<List<Map<String, dynamic>>> _dueChanges(String userId) async {
    final now = DateTime.now().toUtc();
    return (await _localStore.readPending(userId)).where((change) {
      final nextAttempt = DateTime.tryParse('${change['next_attempt_at']}');
      return nextAttempt == null || !nextAttempt.isAfter(now);
    }).toList();
  }

  Future<void> _pullChanges(String userId) async {
    final cursor = await _localStore.readCursor(userId);
    final rows = await _client
        .from('sync_events')
        .select('id,entity_type,entity_id,operation,revision,payload,created_at')
        .gt('id', cursor)
        .order('id', ascending: true)
        .limit(500);
    for (final row in rows) {
      await _localStore.applyRemoteEvent(
        userId,
        Map<String, dynamic>.from(row),
      );
    }
  }

  Future<int> _resolvePulledConflicts(String userId) async {
    var resolved = 0;
    for (final change in await _localStore.readPending(userId)) {
      final record = await _localStore.readRecord(
        userId,
        change['entity_type'] as String,
        change['entity_id'] as String,
      );
      if (record?['conflict_revision'] is int) {
        if (await _localStore.resolvePendingConflict(
          userId,
          change['idempotency_key'] as String,
        )) {
          resolved++;
        }
      }
    }
    return resolved;
  }

  List<Map<String, dynamic>> _records(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  int? _asInt(Object? value) => value is int ? value : int.tryParse('$value');

  int _baseRevision(List<Map<String, dynamic>> batch, String key) {
    for (final change in batch) {
      if (change['idempotency_key'] == key) {
        return _asInt(change['base_revision']) ?? 0;
      }
    }
    return 0;
  }

  String _safeErrorCode(Object error) => switch (error) {
        FunctionException() => 'sync_service_unavailable',
        PostgrestException() => 'sync_service_unavailable',
        FormatException() => 'invalid_sync_response',
        StateError() => 'authentication_required',
        _ => 'network_or_service_error',
      };
}
