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

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    required this.genreIds,
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
    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      overview: json['overview'] as String? ?? '',
      posterPath:
          json['poster_path'] as String? ??
          json['posterUrl'] as String? ??
          json['poster_url'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate:
          json['release_date'] as String? ?? json['first_air_date'] as String?,
      genreIds:
          (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          (json['genres'] as List<dynamic>?)
              ?.map((e) => (e as Map)['id'] as int)
              .toList() ??
          [],
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
    };
  }
}
