import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../models/movie_details.dart';
import 'firestore_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ApiService(firestoreService);
});

class ApiService {
  final FirestoreService _firestoreService;

  ApiService(this._firestoreService);

  /// Fetch trending movies from Firestore (returns top 6 movies ordered by rating/createdAt)
  Future<List<Movie>> getTrendingMovies({int page = 1}) async {
    try {
      final list = await _firestoreService.getMovies();
      return list.take(6).toList();
    } catch (e) {
      throw Exception('Failed to load trending movies: $e');
    }
  }

  /// Fetch popular movies from Firestore (returns full list or mock pagination if desired)
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    try {
      return await _firestoreService.getMovies();
    } catch (e) {
      throw Exception('Failed to load popular movies: $e');
    }
  }

  /// Search movies using Firestore service search
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    try {
      return await _firestoreService.searchMovies(query);
    } catch (e) {
      throw Exception('Failed to execute search: $e');
    }
  }

  /// Fetch full movie details by ID from Firestore
  Future<MovieDetails> getMovieDetails(int id) async {
    try {
      return await _firestoreService.getMovieDetails(id);
    } catch (e) {
      throw Exception('Failed to load movie details: $e');
    }
  }
}
