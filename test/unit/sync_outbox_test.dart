import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/data/local/sync_outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncOutbox unit tests', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('enqueuing valid change persists to pending list', () async {
      final outbox = SyncOutbox();
      const entityId = '11111111-1111-4111-8111-111111111111';

      await outbox.enqueue(
        entityType: 'playlist',
        entityId: entityId,
        operation: 'upsert',
        payload: {'name': 'Documentaries', 'source_kind': 'm3u_file'},
      );

      final pending = await outbox.readPending();
      expect(pending.length, equals(1));
      expect(pending.first.entityType, equals('playlist'));
      expect(pending.first.entityId, equals(entityId));
      expect(pending.first.payload['name'], equals('Documentaries'));
    });

    test('enqueuing sensitive credentials throws ArgumentError', () async {
      final outbox = SyncOutbox();
      const entityId = '11111111-1111-4111-8111-111111111111';

      expect(
        () => outbox.enqueue(
          entityType: 'playlist',
          entityId: entityId,
          operation: 'upsert',
          payload: {
            'name': 'My Playlist',
            'password': 'plain_secret_password',
          },
        ),
        throwsArgumentError,
      );

      expect(
        () => outbox.enqueue(
          entityType: 'playlist',
          entityId: entityId,
          operation: 'upsert',
          payload: {
            'name': 'My Playlist',
            'stream_url': 'http://user:pass@iptv.com:8080/live.m3u',
          },
        ),
        throwsArgumentError,
      );
    });

    test('removeAccepted correctly cleans processed items', () async {
      final outbox = SyncOutbox();
      const entityId = '11111111-1111-4111-8111-111111111111';

      await outbox.enqueue(
        entityType: 'playlist',
        entityId: entityId,
        operation: 'upsert',
        payload: {'name': 'News Channels'},
      );

      final listBefore = await outbox.readPending();
      expect(listBefore.length, equals(1));

      final key = listBefore.first.idempotencyKey;
      await outbox.removeAccepted({key});

      final listAfter = await outbox.readPending();
      expect(listAfter.isEmpty, isTrue);
    });
  });
}

