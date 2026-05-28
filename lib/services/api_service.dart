import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../models/movie_details.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  /// Private helper to load and decode the movies.json asset
  Future<List<Map<String, dynamic>>> _loadMoviesData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/movies.json');
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw Exception('Failed to load local offline database. Please check if assets/movies.json exists.');
    }
  }

  /// Fetch trending movies (simulated network delay, returns first 6 movies)
  Future<List<Movie>> getTrendingMovies({int page = 1}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate loading delay
      final data = await _loadMoviesData();
      
      // Return first 6 movies as trending
      final trendingData = data.take(6).toList();
      return trendingData.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load trending movies: $e');
    }
  }

  /// Fetch popular movies (simulated network delay, paginated 6 items per page)
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate loading delay
      final data = await _loadMoviesData();
      
      const pageSize = 6;
      final startIndex = (page - 1) * pageSize;
      
      if (startIndex >= data.length) return [];
      
      final pagedData = data.skip(startIndex).take(pageSize).toList();
      return pagedData.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load popular movies: $e');
    }
  }

  /// Search movies with a query (simulated network delay, paginated 6 items per page)
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return const [];
    
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate loading delay
      final data = await _loadMoviesData();
      
      // Filter by title matching query
      final filtered = data.where((item) {
        final title = (item['title'] as String? ?? '').toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
      
      const pageSize = 6;
      final startIndex = (page - 1) * pageSize;
      
      if (startIndex >= filtered.length) return [];
      
      final pagedData = filtered.skip(startIndex).take(pageSize).toList();
      return pagedData.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to execute search: $e');
    }
  }

  /// Fetch full movie details by ID (simulated network delay)
  Future<MovieDetails> getMovieDetails(int id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400)); // Simulate loading delay
      final data = await _loadMoviesData();
      
      final movieData = data.firstWhere(
        (item) => item['id'] == id,
        orElse: () => throw Exception('Movie details not found for ID $id'),
      );
      
      return MovieDetails.fromJson(movieData);
    } catch (e) {
      throw Exception('Failed to load movie details: $e');
    }
  }
}
