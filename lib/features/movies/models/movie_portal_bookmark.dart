/// Model representing a movie web portal or download website bookmark
class MoviePortalBookmark {
  final String id;
  final String title;
  final String url;
  final String description;
  final String category;
  final String? iconUrl;
  final bool isUserAdded;
  final DateTime addedAt;

  const MoviePortalBookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    required this.category,
    this.iconUrl,
    this.isUserAdded = false,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'description': description,
        'category': category,
        'iconUrl': iconUrl,
        'isUserAdded': isUserAdded,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MoviePortalBookmark.fromJson(Map<String, dynamic> json) =>
      MoviePortalBookmark(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        iconUrl: json['iconUrl'] as String?,
        isUserAdded: json['isUserAdded'] as bool? ?? false,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

