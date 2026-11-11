import '../../../core/security/ssrf_protection.dart';

/// Type of IPTV playlist format
enum PlaylistType {
  m3u,
  m3u8,
  xtreamCodes,
  xmltvOnly,
}

/// Online / health status of playlist endpoint
enum ConnectionStatus {
  online,
  offline,
  error,
  unverified,
}

/// Represents an IPTV Playlist item
class IptvPlaylist {
  final String id;
  final String name;
  final PlaylistType type;
  final String? sourceUrl;
  final String? localFilePath;
  final int channelCount;
  final String? epgUrl;
  final bool isEnabled;
  final DateTime lastUpdated;
  final DateTime? lastSuccessfulCheck;
  final ConnectionStatus connectionStatus;
  final String? errorMessage;
  final Map<String, String>? customHeaders;

  const IptvPlaylist({
    required this.id,
    required this.name,
    this.type = PlaylistType.m3u,
    this.sourceUrl,
    this.localFilePath,
    this.channelCount = 0,
    this.epgUrl,
    this.isEnabled = true,
    required this.lastUpdated,
    this.lastSuccessfulCheck,
    this.connectionStatus = ConnectionStatus.unverified,
    this.errorMessage,
    this.customHeaders,
  });

  /// Sanitized source URL for display
  String get sanitizedSourceUrl {
    if (sourceUrl == null) return localFilePath ?? 'Local File';
    return SsrfProtection.sanitizeUrl(sourceUrl!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'sourceUrl': sourceUrl,
        'localFilePath': localFilePath,
        'channelCount': channelCount,
        'epgUrl': epgUrl,
        'isEnabled': isEnabled,
        'lastUpdated': lastUpdated.toIso8601String(),
        'lastSuccessfulCheck': lastSuccessfulCheck?.toIso8601String(),
        'connectionStatus': connectionStatus.name,
        'errorMessage': errorMessage,
        'customHeaders': customHeaders,
      };

  factory IptvPlaylist.fromJson(Map<String, dynamic> json) => IptvPlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        type: PlaylistType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PlaylistType.m3u,
        ),
        sourceUrl: json['sourceUrl'] as String?,
        localFilePath: json['localFilePath'] as String?,
        channelCount: json['channelCount'] as int? ?? 0,
        epgUrl: json['epgUrl'] as String?,
        isEnabled: json['isEnabled'] as bool? ?? true,
        lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ?? DateTime.now(),
        lastSuccessfulCheck: DateTime.tryParse(json['lastSuccessfulCheck'] as String? ?? ''),
        connectionStatus: ConnectionStatus.values.firstWhere(
          (s) => s.name == json['connectionStatus'],
          orElse: () => ConnectionStatus.unverified,
        ),
        errorMessage: json['errorMessage'] as String?,
        customHeaders: (json['customHeaders'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );

  IptvPlaylist copyWith({
    String? name,
    PlaylistType? type,
    String? sourceUrl,
    String? localFilePath,
    int? channelCount,
    String? epgUrl,
    bool? isEnabled,
    DateTime? lastUpdated,
    DateTime? lastSuccessfulCheck,
    ConnectionStatus? connectionStatus,
    String? errorMessage,
    Map<String, String>? customHeaders,
  }) {
    return IptvPlaylist(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      channelCount: channelCount ?? this.channelCount,
      epgUrl: epgUrl ?? this.epgUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastSuccessfulCheck: lastSuccessfulCheck ?? this.lastSuccessfulCheck,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      customHeaders: customHeaders ?? this.customHeaders,
    );
  }
}

