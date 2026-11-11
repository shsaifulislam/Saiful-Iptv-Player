/// Represents a single TV program schedule from XMLTV EPG
class EpgProgram {
  final String id;
  final String channelTvgId;
  final String title;
  final String? description;
  final String? category;
  final DateTime startTime; // UTC
  final DateTime endTime; // UTC
  final String? iconUrl;

  const EpgProgram({
    required this.id,
    required this.channelTvgId,
    required this.title,
    this.description,
    this.category,
    required this.startTime,
    required this.endTime,
    this.iconUrl,
  });

  /// Check if the program is currently airing
  bool isCurrentlyAiring([DateTime? now]) {
    final current = now?.toUtc() ?? DateTime.now().toUtc();
    return current.isAfter(startTime) && current.isBefore(endTime);
  }

  /// Progress ratio from 0.0 to 1.0 of current airing program
  double progressRatio([DateTime? now]) {
    final current = now?.toUtc() ?? DateTime.now().toUtc();
    if (current.isBefore(startTime)) return 0.0;
    if (current.isAfter(endTime)) return 1.0;
    final total = endTime.difference(startTime).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = current.difference(startTime).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Total program duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelTvgId': channelTvgId,
        'title': title,
        'description': description,
        'category': category,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'iconUrl': iconUrl,
      };

  factory EpgProgram.fromJson(Map<String, dynamic> json) => EpgProgram(
        id: json['id'] as String,
        channelTvgId: json['channelTvgId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        iconUrl: json['iconUrl'] as String?,
      );
}

/// Represents an EPG Channel header entry
class EpgChannelHeader {
  final String id;
  final String displayName;
  final String? iconUrl;

  const EpgChannelHeader({
    required this.id,
    required this.displayName,
    this.iconUrl,
  });
}

