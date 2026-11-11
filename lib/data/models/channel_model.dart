import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_model.freezed.dart';
part 'channel_model.g.dart';

/// The type of stream content.
enum StreamType {
  @JsonValue('live')
  live,
  @JsonValue('movie')
  movie,
  @JsonValue('series')
  series,
}

/// A single IPTV channel or stream entry.
@freezed
class Channel with _$Channel {
  const Channel._();

  const factory Channel({
    required String id,
    required String name,
    required String streamUrl,
    String? logoUrl,
    String? groupTitle,
    String? tvgId,
    String? tvgName,
    String? tvgLogo,
    String? catchupType,
    @Default(0) int catchupDays,
    @Default(false) bool isFavorite,
    @Default(StreamType.live) StreamType streamType,
    String? playlistId,
    int? streamId,
    String? containerExtension,
    @Default(0) int sortOrder,
  }) = _Channel;

  factory Channel.fromJson(Map<String, dynamic> json) =>
      _$ChannelFromJson(json);

  /// Effective logo URL, preferring tvgLogo over logoUrl.
  String? get effectiveLogo => tvgLogo ?? logoUrl;

  /// Whether catchup/timeshift is supported.
  bool get hasCatchup =>
      catchupType != null && catchupType!.isNotEmpty && catchupDays > 0;
}
