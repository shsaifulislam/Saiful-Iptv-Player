import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/data/local/local_sync_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalSyncStore unit tests', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    const userId = '11111111-1111-4111-8111-111111111111';
    const entityId = '22222222-2222-4222-8222-222222222222';

    test('enqueueLocalChange stores dirty record and pending item', () async {
      final store = LocalSyncStore();

      final change = await store.enqueueLocalChange(
        userId: userId,
        entityType: 'playlist',
        entityId: entityId,
        operation: 'upsert',
        payload: {'name': 'World News'},
      );

      expect(change['entity_id'], equals(entityId));
      expect(change['entity_type'], equals('playlist'));

      final pending = await store.readPending(userId);
      expect(pending.length, equals(1));
      expect(pending.first['entity_id'], equals(entityId));

      final record = await store.readRecord(userId, 'playlist', entityId);
      expect(record, isNotNull);
      expect(record!['dirty'], isTrue);
      expect(record['server_revision'], equals(0));
    });

    test('rejects forbidden secret keys on enqueue', () async {
      final store = LocalSyncStore();

      expect(
        () => store.enqueueLocalChange(
          userId: userId,
          entityType: 'playlist',
          entityId: entityId,
          operation: 'upsert',
          payload: {'password': 'leaked_secret'},
        ),
        throwsArgumentError,
      );
    });

    test('markAccepted updates server revision and clears dirty state', () async {
      final store = LocalSyncStore();

      final change = await store.enqueueLocalChange(
        userId: userId,
        entityType: 'playlist',
        entityId: entityId,
        operation: 'upsert',
        payload: {'name': 'World News'},
      );

      final idempotencyKey = change['idempotency_key'] as String;
      await store.markAccepted(userId, {idempotencyKey: 1});

      final pending = await store.readPending(userId);
      expect(pending.isEmpty, isTrue);

      final record = await store.readRecord(userId, 'playlist', entityId);
      expect(record!['dirty'], isFalse);
      expect(record['server_revision'], equals(1));
    });
  });
}

