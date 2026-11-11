import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

/// The content type a category belongs to.
enum CategoryType {
  @JsonValue('live')
  live,
  @JsonValue('vod')
  vod,
  @JsonValue('series')
  series,
}

/// A category or group of channels/content.
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    @Default(0) int channelCount,
    @Default(CategoryType.live) CategoryType type,
    String? parentId,
    String? iconUrl,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
