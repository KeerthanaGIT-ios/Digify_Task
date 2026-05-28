import 'genre.dart';
import 'movie.dart';

class MovieDetails {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final List<Genre> genres;
  final int? runtime;
  final String? tagline;
  final String? status;
  final String? videoUrl;

  MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    required this.genres,
    this.runtime,
    this.tagline,
    this.status,
    this.videoUrl,
  });

  String get releaseYear {
    if (releaseDate == null || releaseDate!.length < 4) return '';
    return releaseDate!.substring(0, 4);
  }
  
  String get formattedRuntime {
    if (runtime == null || runtime == 0) return '';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      overview: json['overview'] as String? ?? json['description'] as String? ?? '',
      posterPath: json['poster_path'] as String? ??
          json['posterUrl'] as String? ??
          json['poster_url'] as String?,
      backdropPath: json['backdrop_path'] as String? ??
          json['backdropUrl'] as String? ??
          json['backdrop_url'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      releaseDate: json['release_date'] as String? ?? json['releaseYear'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      runtime: json['runtime'] as int?,
      tagline: json['tagline'] as String?,
      status: json['status'] as String?,
      videoUrl: json['videoUrl'] as String? ?? json['video_url'] as String?,
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
      'genres': genres.map((e) => e.toJson()).toList(),
      'runtime': runtime,
      'tagline': tagline,
      'status': status,
      'videoUrl': videoUrl,
    };
  }

  // Utility method to convert details into a simplified Movie model
  Movie toMovie() {
    return Movie(
      id: id,
      title: title,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
      genreIds: genres.map((e) => e.id).toList(),
      videoUrl: videoUrl,
    );
  }
}
