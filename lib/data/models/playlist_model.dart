import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_model.freezed.dart';
part 'playlist_model.g.dart';

/// Type of playlist source.
enum PlaylistType {
  @JsonValue('m3u')
  m3u,
  @JsonValue('xtream')
  xtream,
}

/// A playlist containing IPTV channels from an M3U or Xtream source.
@freezed
class Playlist with _$Playlist {
  const Playlist._();

  const factory Playlist({
    required String id,
    required String name,
    required String url,
    @Default(PlaylistType.m3u) PlaylistType type,
    String? username,
    String? password,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(0) int channelCount,
    @Default(true) bool isActive,
    String? epgUrl,
    String? serverInfo,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);

  /// Whether this playlist uses Xtream Codes API.
  bool get isXtream => type == PlaylistType.xtream;

  /// Whether credentials are provided for Xtream.
  bool get hasCredentials =>
      username != null &&
      username!.isNotEmpty &&
      password != null &&
      password!.isNotEmpty;
}
