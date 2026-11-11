import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Subscription tier for the user.
enum SubscriptionTier {
  @JsonValue('free')
  free,
  @JsonValue('basic')
  basic,
  @JsonValue('premium')
  premium,
}

/// User profile and subscription information.
@freezed
class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    String? email,
    String? displayName,
    String? avatarUrl,
    @Default(SubscriptionTier.free) SubscriptionTier subscription,
    required DateTime createdAt,
    DateTime? lastLoginAt,
    @Default(false) bool isEmailVerified,
    @Default({}) Map<String, dynamic> preferences,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Whether the user has a paid subscription.
  bool get isPremium => subscription != SubscriptionTier.free;

  /// Display name or email fallback.
  String get displayLabel => displayName ?? email ?? 'User';
}
