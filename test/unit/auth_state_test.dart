import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/services/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('AuthState unit tests', () {
    test('unauthenticated state maps correctly', () {
      const state = AuthState.unauthenticated();
      var called = false;
      state.map(
        authenticated: (_) => fail('Should not be authenticated'),
        unauthenticated: (_) => called = true,
        loading: (_) => fail('Should not be loading'),
        error: (_) => fail('Should not be error'),
      );
      expect(called, isTrue);
    });

    test('loading state maps correctly', () {
      const state = AuthState.loading();
      var called = false;
      state.maybeMap(
        loading: (_) => called = true,
        orElse: () => fail('Should have matched loading'),
      );
      expect(called, isTrue);
    });

    test('error state maps correctly with message', () {
      const state = AuthState.error(message: 'Invalid email or password');
      final msg = state.when(
        authenticated: (_) => 'auth',
        unauthenticated: () => 'unauth',
        loading: () => 'loading',
        error: (message) => message,
      );
      expect(msg, equals('Invalid email or password'));
    });

    test('authenticated equality and hashing', () {
      final user1 = supabase.User(
        id: '11111111-1111-4111-8111-111111111111',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-11T00:00:00Z',
      );
      final user2 = supabase.User(
        id: '11111111-1111-4111-8111-111111111111',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-11T00:00:00Z',
      );

      final state1 = AuthState.authenticated(user: user1);
      final state2 = AuthState.authenticated(user: user2);
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });
}

