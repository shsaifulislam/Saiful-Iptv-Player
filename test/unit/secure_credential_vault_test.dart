import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/data/local/secure_credential_vault.dart';

void main() {
  group('SecureCredentialVault unit tests', () {
    test('validates uuid format for playlistId', () {
      final vault = SecureCredentialVault();

      expect(
        () => vault.save(
          'not-a-uuid',
          const ProviderCredentials(username: 'u', password: 'p'),
        ),
        throwsArgumentError,
      );

      expect(
        () => vault.save(
          '11111111-1111-4111-8111-111111111111',
          const ProviderCredentials(username: '', password: 'p'),
        ),
        throwsArgumentError,
      );
    });
  });
}

