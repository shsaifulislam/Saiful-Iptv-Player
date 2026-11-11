import '../../../core/security/ssrf_protection.dart';

/// Represents a live IPTV Channel
class IptvChannel {
  final String id;
  final String playlistId;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String groupTitle;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? tvgChno;
  final String? tvgShift;
  final bool isFavorite;
  final DateTime? lastWatchedAt;
  final Map<String, String>? httpHeaders;

  const IptvChannel({
    required this.id,
    required this.playlistId,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.groupTitle = 'General',
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.tvgChno,
    this.tvgShift,
    this.isFavorite = false,
    this.lastWatchedAt,
    this.httpHeaders,
  });

  /// Sanitized stream URL for safe logs / diagnostics
  String get sanitizedStreamUrl => SsrfProtection.sanitizeUrl(streamUrl);

  Map<String, dynamic> toJson() => {
        'id': id,
        'playlistId': playlistId,
        'name': name,
        'streamUrl': streamUrl,
        'logoUrl': logoUrl,
        'groupTitle': groupTitle,
        'tvgId': tvgId,
        'tvgName': tvgName,
        'tvgLogo': tvgLogo,
        'tvgChno': tvgChno,
        'tvgShift': tvgShift,
        'isFavorite': isFavorite,
        'lastWatchedAt': lastWatchedAt?.toIso8601String(),
        'httpHeaders': httpHeaders,
      };

  factory IptvChannel.fromJson(Map<String, dynamic> json) => IptvChannel(
        id: json['id'] as String,
        playlistId: json['playlistId'] as String? ?? 'default',
        name: json['name'] as String,
        streamUrl: json['streamUrl'] as String,
        logoUrl: json['logoUrl'] as String?,
        groupTitle: json['groupTitle'] as String? ?? 'General',
        tvgId: json['tvgId'] as String?,
        tvgName: json['tvgName'] as String?,
        tvgLogo: json['tvgLogo'] as String?,
        tvgChno: json['tvgChno'] as String?,
        tvgShift: json['tvgShift'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        lastWatchedAt: DateTime.tryParse(json['lastWatchedAt'] as String? ?? ''),
        httpHeaders: (json['httpHeaders'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );

  IptvChannel copyWith({
    String? name,
    String? streamUrl,
    String? logoUrl,
    String? groupTitle,
    String? tvgId,
    String? tvgName,
    String? tvgLogo,
    String? tvgChno,
    String? tvgShift,
    bool? isFavorite,
    DateTime? lastWatchedAt,
    Map<String, String>? httpHeaders,
  }) {
    return IptvChannel(
      id: id,
      playlistId: playlistId,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      groupTitle: groupTitle ?? this.groupTitle,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      tvgLogo: tvgLogo ?? this.tvgLogo,
      tvgChno: tvgChno ?? this.tvgChno,
      tvgShift: tvgShift ?? this.tvgShift,
      isFavorite: isFavorite ?? this.isFavorite,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      httpHeaders: httpHeaders ?? this.httpHeaders,
    );
  }
}

