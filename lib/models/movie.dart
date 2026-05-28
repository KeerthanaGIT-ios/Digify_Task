class Movie {
  static const String fallbackPosterUrl =
      'https://dummyimage.com/300x450/222222/ffffff.jpg&text=Movie';

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final String? category;
  final String? videoUrl;
  final dynamic createdAt;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    required this.genreIds,
    this.category,
    this.videoUrl,
    this.createdAt,
  });

  String get releaseYear {
    if (releaseDate == null || releaseDate!.length < 4) return '';
    return releaseDate!.substring(0, 4);
  }

  String get posterUrl {
    return _validHttpsUrl(posterPath) ??
        _validHttpsUrl(backdropPath) ??
        fallbackPosterUrl;
  }

  String get backdropUrl {
    return _validHttpsUrl(backdropPath) ??
        _validHttpsUrl(posterPath) ??
        fallbackPosterUrl;
  }

  List<String> get thumbnailUrls {
    final urls = <String>[];
    final poster = _validHttpsUrl(posterPath);
    final backdrop = _validHttpsUrl(backdropPath);
    if (poster != null) urls.add(poster);
    if (backdrop != null && backdrop != poster) urls.add(backdrop);
    urls.add(fallbackPosterUrl);
    return urls;
  }

  static String? _validHttpsUrl(String? url) {
    final trimmedUrl = url?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmedUrl);
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      return trimmedUrl;
    }

    return null;
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Determine category based on Firestore 'category' field or fallback to genres in movies.json
    String? categoryVal = json['category'] as String?;
    if (categoryVal == null) {
      final genres = json['genres'] as List<dynamic>?;
      if (genres != null && genres.isNotEmpty) {
        categoryVal = (genres.first as Map)['name'] as String?;
      }
    }

    // Map release year to release date format if needed
    String? releaseDateVal = json['release_date'] as String? ?? json['first_air_date'] as String?;
    if (releaseDateVal == null && json['releaseYear'] != null) {
      releaseDateVal = '${json['releaseYear']}-01-01';
    }

    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      overview: json['overview'] as String? ?? json['description'] as String? ?? '',
      posterPath: json['poster_path'] as String? ??
          json['posterUrl'] as String? ??
          json['poster_url'] as String?,
      backdropPath: json['backdrop_path'] as String? ??
          json['backdropUrl'] as String? ??
          json['backdrop_url'] as String? ??
          json['posterUrl'] as String? ??
          json['poster_url'] as String? ??
          json['poster_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      releaseDate: releaseDateVal,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          (json['genres'] as List<dynamic>?)
              ?.map((e) => (e as Map)['id'] as int)
              .toList() ??
          [],
      category: categoryVal,
      videoUrl: json['videoUrl'] as String? ?? json['video_url'] as String?,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'category': category,
      'videoUrl': videoUrl,
      'createdAt': createdAt,
    };
  }

  // Helper method to convert Movie to Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': overview,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'category': category ?? 'Action',
      'rating': voteAverage,
      'releaseYear': releaseYear,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
