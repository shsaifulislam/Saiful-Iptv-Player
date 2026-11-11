import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/utils/result.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';

/// Service responsible for all authentication operations via Supabase Auth.
///
/// Wraps Supabase GoTrueClient to provide a clean, typed interface for
/// sign-up, sign-in, social auth, password reset, and session management.
/// All fallible operations return [Result] types for explicit error handling.
class AuthService {
  /// Creates an [AuthService] backed by the given Supabase client.
  AuthService({
    required supabase.SupabaseClient supabaseClient,
    required AppLogger logger,
  })  : _client = supabaseClient,
        _logger = logger;

  final supabase.SupabaseClient _client;
  final AppLogger _logger;

  /// The underlying Supabase auth client.
  supabase.GoTrueClient get _auth => _client.auth;

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  /// Creates a new account with [email] and [password].
  ///
  /// Returns the authenticated [User] on success, or a [Failure] describing
  /// what went wrong (e.g. duplicate email, weak password).
  Future<Result<supabase.User>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return Result.failure(
          const AuthException('Sign-up succeeded but no user was returned.'),
        );
      }
      return Result.success(user);
    } on supabase.AuthException catch (e, st) {
      _logger.error('AuthService.signUp failed', error: e, stackTrace: st);
      return Result.failure(
        AuthException(e.message),
      );
    } catch (e, st) {
      _logger.error('AuthService.signUp unexpected error',
          error: e, stackTrace: st);
      return Result.failure(
        AuthException('Sign-up failed (${e.runtimeType}).'),
      );
    }
  }

  /// Signs in an existing user with [email] and [password].
  ///
  /// Returns the authenticated [User] on success.
  Future<Result<supabase.User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return Result.failure(
          const AuthException('Sign-in succeeded but no user was returned.'),
        );
      }
      return Result.success(user);
    } on supabase.AuthException catch (e, st) {
      _logger.error('AuthService.signIn failed', error: e, stackTrace: st);
      return Result.failure(
        AuthException(e.message),
      );
    } catch (e, st) {
      _logger.error('AuthService.signIn unexpected error',
          error: e, stackTrace: st);
      return Result.failure(
        AuthException('Sign-in failed (${e.runtimeType}).'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Social / OAuth
  // ---------------------------------------------------------------------------

  /// Initiates Google OAuth sign-in flow.
  ///
  /// On mobile platforms this opens the in-app browser; on web it redirects.
  /// Returns `true` when the OAuth flow was successfully launched.
  Future<Result<bool>> signInWithGoogle() async {
    try {
      _logger.info('AuthService.signInWithGoogle: initiating');
      await _auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: 'com.saiful.iptv_player://login-callback',
      );
      return const Result.success(true);
    } on supabase.AuthException catch (e, st) {
      _logger.error('AuthService.signInWithGoogle failed',
          error: e, stackTrace: st);
      return Result.failure(AuthException(e.message));
    } catch (e, st) {
      _logger.error('AuthService.signInWithGoogle unexpected error',
          error: e, stackTrace: st);
      return Result.failure(
        AuthException('Google sign-in failed (${e.runtimeType}).'),
      );
    }
  }

  /// Initiates Apple OAuth sign-in flow (iOS / macOS).
  ///
  /// Returns `true` when the OAuth flow was successfully launched.
  Future<Result<bool>> signInWithApple() async {
    try {
      _logger.info('AuthService.signInWithApple: initiating');
      await _auth.signInWithOAuth(
        supabase.OAuthProvider.apple,
        redirectTo: 'com.saiful.iptv_player://login-callback',
      );
      return const Result.success(true);
    } on supabase.AuthException catch (e, st) {
      _logger.error('AuthService.signInWithApple failed',
          error: e, stackTrace: st);
      return Result.failure(AuthException(e.message));
    } catch (e, st) {
      _logger.error('AuthService.signInWithApple unexpected error',
          error: e, stackTrace: st);
      return Result.failure(
        AuthException('Apple sign-in failed (${e.runtimeType}).'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Signs out the current user, clearing the local session.
  Future<Result<void>> signOut() async {
    try {
      _logger.info('AuthService.signOut: signing out');
      await _auth.signOut();
      _logger.info('AuthService.signOut: success');
      return const Result.success(null);
    } on supabase.AuthException catch (e, st) {
      _logger.error('AuthService.signOut failed', error: e, stackTrace: st);
      return Result.failure(AuthException(e.message));
    } catch (e, st) {
      _logger.error('AuthService.signOut unexpected error',
          error: e, stackTrace: st);
      return Result.failure(
        AuthException('Sign-out failed (${e.runtimeType}).'),
      );
    }
  }

  Future<Result<void>> deleteAccount({required String currentPassword}) async {
    final email = _auth.currentUser?.email;
    if (email == null || currentPassword.isEmpty) {
      return Result.failure(
        const AuthException('Account deletion requires a signed-in email account.'),
      );
    }

    try {
      await _client.functions.invoke(
        'account-delete',
        body: {'password': currentPassword},
      );
      await _auth.signOut(scope: supabase.SignOutScope.local);
      return const Result.success(null);
    } on supabase.FunctionException catch (error, stackTrace) {
      _logger.error('AuthService.deleteAccount rejected',
          error: error, stackTrace: stackTrace);
      return Result.failure(
        const AuthException('Account deletion could not be completed.'),
      );
    } catch (error, stackTrace) {
      _logger.error('AuthService.deleteAccount failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(
        const AuthException('Account deletion could not be completed.'),
      );
    }
  }

  /// Sends a password-reset email to [email].
  ///
  /// Returns `true` when the email was sent successfully.
  Future<Result<bool>> resetPassword({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
      return const Result.success(true);
    } on supabase.AuthException catch (e, st) {
      _logger.error('AuthService.resetPassword failed',
          error: e, stackTrace: st);
      return Result.failure(AuthException(e.message));
    } catch (e, st) {
      _logger.error('AuthService.resetPassword unexpected error',
          error: e, stackTrace: st);
      return Result.failure(
        AuthException('Password reset failed (${e.runtimeType}).'),
      );
    }
  }

  /// Returns the currently authenticated [User], or `null` if no session
  /// exists.
  supabase.User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Emits a new [AuthState] whenever the Supabase auth state changes
  /// (e.g. sign-in, sign-out, token refresh).
  ///
  /// This is the primary reactive hook for auth-aware UI.
  Stream<supabase.AuthState> onAuthStateChange() {
    return _auth.onAuthStateChange.map((event) {
      return event;
    });
  }
}
