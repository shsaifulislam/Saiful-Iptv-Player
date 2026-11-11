import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authentication required.');
    final response = await _client
        .from('profiles')
        .select('id,display_name,avatar_url,locale,created_at,updated_at')
        .eq('id', userId)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? locale,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authentication required.');
    final changes = <String, Object?>{};
    if (displayName != null) changes['display_name'] = displayName.trim();
    if (avatarUrl != null) changes['avatar_url'] = avatarUrl;
    if (locale != null) changes['locale'] = locale;
    if (changes.isEmpty) return getProfile();

    return await _client
        .from('profiles')
        .update(changes)
        .eq('id', userId)
        .select('id,display_name,avatar_url,locale,created_at,updated_at')
        .single();
  }
}
