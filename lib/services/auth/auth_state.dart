import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Represents the current authentication state of the application.
///
/// Implemented as a sealed class hierarchy providing pattern matching,
/// [map], and [maybeMap] operations matching Freezed-style conventions.
sealed class AuthState {
  const AuthState();

  /// The user is successfully authenticated.
  const factory AuthState.authenticated({
    required supabase.User user,
  }) = AuthStateAuthenticated;

  /// No user is currently authenticated.
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  /// An authentication operation is in progress.
  const factory AuthState.loading() = AuthStateLoading;

  /// An authentication error has occurred.
  const factory AuthState.error({
    required String message,
  }) = AuthStateError;

  T map<T>({
    required T Function(AuthStateAuthenticated state) authenticated,
    required T Function(AuthStateUnauthenticated state) unauthenticated,
    required T Function(AuthStateLoading state) loading,
    required T Function(AuthStateError state) error,
  });

  T maybeMap<T>({
    T Function(AuthStateAuthenticated state)? authenticated,
    T Function(AuthStateUnauthenticated state)? unauthenticated,
    T Function(AuthStateLoading state)? loading,
    T Function(AuthStateError state)? error,
    required T Function() orElse,
  });

  T when<T>({
    required T Function(supabase.User user) authenticated,
    required T Function() unauthenticated,
    required T Function() loading,
    required T Function(String message) error,
  });
}

final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({required this.user});

  final supabase.User user;

  @override
  T map<T>({
    required T Function(AuthStateAuthenticated state) authenticated,
    required T Function(AuthStateUnauthenticated state) unauthenticated,
    required T Function(AuthStateLoading state) loading,
    required T Function(AuthStateError state) error,
  }) => authenticated(this);

  @override
  T maybeMap<T>({
    T Function(AuthStateAuthenticated state)? authenticated,
    T Function(AuthStateUnauthenticated state)? unauthenticated,
    T Function(AuthStateLoading state)? loading,
    T Function(AuthStateError state)? error,
    required T Function() orElse,
  }) => authenticated != null ? authenticated(this) : orElse();

  @override
  T when<T>({
    required T Function(supabase.User user) authenticated,
    required T Function() unauthenticated,
    required T Function() loading,
    required T Function(String message) error,
  }) => authenticated(user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateAuthenticated && other.user.id == user.id;

  @override
  int get hashCode => user.id.hashCode;
}

final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();

  @override
  T map<T>({
    required T Function(AuthStateAuthenticated state) authenticated,
    required T Function(AuthStateUnauthenticated state) unauthenticated,
    required T Function(AuthStateLoading state) loading,
    required T Function(AuthStateError state) error,
  }) => unauthenticated(this);

  @override
  T maybeMap<T>({
    T Function(AuthStateAuthenticated state)? authenticated,
    T Function(AuthStateUnauthenticated state)? unauthenticated,
    T Function(AuthStateLoading state)? loading,
    T Function(AuthStateError state)? error,
    required T Function() orElse,
  }) => unauthenticated != null ? unauthenticated(this) : orElse();

  @override
  T when<T>({
    required T Function(supabase.User user) authenticated,
    required T Function() unauthenticated,
    required T Function() loading,
    required T Function(String message) error,
  }) => unauthenticated();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateUnauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AuthStateLoading extends AuthState {
  const AuthStateLoading();

  @override
  T map<T>({
    required T Function(AuthStateAuthenticated state) authenticated,
    required T Function(AuthStateUnauthenticated state) unauthenticated,
    required T Function(AuthStateLoading state) loading,
    required T Function(AuthStateError state) error,
  }) => loading(this);

  @override
  T maybeMap<T>({
    T Function(AuthStateAuthenticated state)? authenticated,
    T Function(AuthStateUnauthenticated state)? unauthenticated,
    T Function(AuthStateLoading state)? loading,
    T Function(AuthStateError state)? error,
    required T Function() orElse,
  }) => loading != null ? loading(this) : orElse();

  @override
  T when<T>({
    required T Function(supabase.User user) authenticated,
    required T Function() unauthenticated,
    required T Function() loading,
    required T Function(String message) error,
  }) => loading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AuthStateError extends AuthState {
  const AuthStateError({required this.message});

  final String message;

  @override
  T map<T>({
    required T Function(AuthStateAuthenticated state) authenticated,
    required T Function(AuthStateUnauthenticated state) unauthenticated,
    required T Function(AuthStateLoading state) loading,
    required T Function(AuthStateError state) error,
  }) => error(this);

  @override
  T maybeMap<T>({
    T Function(AuthStateAuthenticated state)? authenticated,
    T Function(AuthStateUnauthenticated state)? unauthenticated,
    T Function(AuthStateLoading state)? loading,
    T Function(AuthStateError state)? error,
    required T Function() orElse,
  }) => error != null ? error(this) : orElse();

  @override
  T when<T>({
    required T Function(supabase.User user) authenticated,
    required T Function() unauthenticated,
    required T Function() loading,
    required T Function(String message) error,
  }) => error(message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
