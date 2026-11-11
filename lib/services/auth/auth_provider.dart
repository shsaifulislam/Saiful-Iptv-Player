import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../data/local/device_identity.dart';
import '../../data/local/local_sync_store.dart';
import '../../data/remote/device_repository.dart';
import '../../data/repositories/cloud_sync_repository.dart';
import '../../data/repositories/profile_repository.dart';
import 'auth_service.dart';
import 'auth_state.dart' as app;

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) => DeviceIdentity());

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    client: Supabase.instance.client,
    identity: ref.watch(deviceIdentityProvider),
  );
});

final authServiceProvider = Provider<AuthService?>((ref) {
  if (!Supabase.instance.isInitialized) return null;
  final supabase = Supabase.instance.client;
  final logger = ref.watch(appLoggerProvider);
  return AuthService(supabaseClient: supabase, logger: logger);
});

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  if (!Supabase.instance.isInitialized) return null;
  return ProfileRepository(Supabase.instance.client);
});

final localSyncStoreProvider = Provider<LocalSyncStore>((ref) {
  return LocalSyncStore();
});

final cloudSyncRepositoryProvider = Provider<CloudSyncRepository?>((ref) {
  if (!Supabase.instance.isInitialized) return null;
  return CloudSyncRepository(
    client: Supabase.instance.client,
    localStore: ref.watch(localSyncStoreProvider),
    deviceRepository: ref.watch(deviceRepositoryProvider),
  );
});

/// Reactive stream of [app.AuthState] changes.
///
/// Automatically maps Supabase [AuthState] events to the application-level
/// [app.AuthState] union type so the UI can pattern-match exhaustively.
final authStateProvider = StreamProvider<app.AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  if (authService == null) {
    return Stream<app.AuthState>.value(const app.AuthState.unauthenticated());
  }

  final deviceRepository = ref.watch(deviceRepositoryProvider);
  final logger = ref.watch(appLoggerProvider);
  return authService.onAuthStateChange().asyncMap((event) async {
    final user = event.session?.user;
    if (user != null) {
      if (event.event == AuthChangeEvent.initialSession ||
          event.event == AuthChangeEvent.signedIn) {
        try {
          await deviceRepository.registerCurrentDevice();
        } catch (error, stackTrace) {
          logger.error('Device registration failed',
              error: error, stackTrace: stackTrace);
        }
      }
      return app.AuthState.authenticated(user: user);
    }
    return const app.AuthState.unauthenticated();
  });
});

/// Convenience provider that exposes the currently authenticated [User],
/// or `null` when no session is active.
///
/// Prefer [authStateProvider] when you need the full state (loading, error).
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.whenData((s) {
    return s.map(
      authenticated: (a) => a.user,
      unauthenticated: (_) => null,
      loading: (_) => null,
      error: (_) => null,
    );
  }).value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
