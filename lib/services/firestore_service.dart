import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../models/movie_details.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final service = FirestoreService();
  service.seedInitialMovies(); // Seeding runs asynchronously on startup
  return service;
});

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if the movies collection is empty and seed it from the offline JSON asset if so
  Future<void> seedInitialMovies() async {
    try {
      final CollectionReference moviesRef = _db.collection('movies');
      
      // Get limit of 1 to check if any records exist
      final snapshot = await moviesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('FirestoreService: Collection is not empty. Skipping database seeding.');
        return;
      }

      debugPrint('FirestoreService: Collection is empty! Seeding default movies from assets/movies.json...');
      
      // Load offline json asset
      final jsonString = await rootBundle.loadString('assets/movies.json');
      final List<dynamic> decoded = json.decode(jsonString);
      final List<Map<String, dynamic>> rawMovies = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Upload movies in batch or sequence using their mock IDs
      final WriteBatch batch = _db.batch();
      
      for (final raw in rawMovies) {
        final movie = Movie.fromJson(raw);
        final docRef = moviesRef.doc(movie.id.toString());
        
        final firestoreMap = movie.toJson();
        // Set creation timestamp
        firestoreMap['createdAt'] = DateTime.now().toIso8601String();
        
        batch.set(docRef, firestoreMap);
      }

      await batch.commit();
      debugPrint('FirestoreService: Successfully seeded ${rawMovies.length} movies to Firestore!');
    } catch (e) {
      debugPrint('FirestoreService: Error seeding movies: $e');
    }
  }

  /// Listen to all movies in real time, ordered by rating/date
  Stream<List<Movie>> watchMovies() {
    return _db
        .collection('movies')
        .snapshots()
        .map((snapshot) {
          final movies = snapshot.docs.map((doc) {
            final data = doc.data();
            return Movie.fromJson(data);
          }).toList();
          
          // Sort by ID or createdAt descending
          movies.sort((a, b) {
            final aCreated = a.createdAt?.toString() ?? '';
            final bCreated = b.createdAt?.toString() ?? '';
            if (aCreated.isEmpty || bCreated.isEmpty) {
              return b.id.compareTo(a.id);
            }
            return bCreated.compareTo(aCreated);
          });
          
          return movies;
        });
  }

  /// Get list of movies once
  Future<List<Movie>> getMovies() async {
    try {
      final snapshot = await _db.collection('movies').get();
      final movies = snapshot.docs.map((doc) => Movie.fromJson(doc.data())).toList();
      
      movies.sort((a, b) {
        final aCreated = a.createdAt?.toString() ?? '';
        final bCreated = b.createdAt?.toString() ?? '';
        if (aCreated.isEmpty || bCreated.isEmpty) {
          return b.id.compareTo(a.id);
        }
        return bCreated.compareTo(aCreated);
      });
      
      return movies;
    } catch (e) {
      debugPrint('FirestoreService.getMovies error: $e');
      return [];
    }
  }

  /// Search movies dynamically
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final list = await getMovies();
      return list.where((movie) {
        return movie.title.toLowerCase().contains(query.toLowerCase()) ||
            (movie.category ?? '').toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('FirestoreService.searchMovies error: $e');
      return [];
    }
  }

  /// Get detailed movie information by ID
  Future<MovieDetails> getMovieDetails(int id) async {
    try {
      final doc = await _db.collection('movies').doc(id.toString()).get();
      if (!doc.exists) {
        throw Exception('Movie with ID $id not found in Firestore.');
      }
      
      final data = doc.data()!;
      return MovieDetails.fromJson(data);
    } catch (e) {
      debugPrint('FirestoreService.getMovieDetails error: $e');
      throw Exception('Failed to load movie details: $e');
    }
  }

  /// Add a movie to Firestore
  Future<void> addMovie(Movie movie) async {
    try {
      final docRef = _db.collection('movies').doc(movie.id.toString());
      final map = movie.toJson();
      map['createdAt'] = DateTime.now().toIso8601String();
      await docRef.set(map);
      debugPrint('FirestoreService: Added movie "${movie.title}" successfully.');
    } catch (e) {
      debugPrint('FirestoreService.addMovie error: $e');
      throw Exception('Failed to save movie: $e');
    }
  }

  /// Update an existing movie in Firestore
  Future<void> updateMovie(Movie movie) async {
    try {
      final docRef = _db.collection('movies').doc(movie.id.toString());
      final map = movie.toJson();
      if (map['createdAt'] == null) {
        map['createdAt'] = DateTime.now().toIso8601String();
      }
      await docRef.update(map);
      debugPrint('FirestoreService: Updated movie "${movie.title}" successfully.');
    } catch (e) {
      debugPrint('FirestoreService.updateMovie error: $e');
      throw Exception('Failed to update movie: $e');
    }
  }

  /// Delete a movie from Firestore
  Future<void> deleteMovie(int id) async {
    try {
      await _db.collection('movies').doc(id.toString()).delete();
      debugPrint('FirestoreService: Deleted movie ID $id successfully.');
    } catch (e) {
      debugPrint('FirestoreService.deleteMovie error: $e');
      throw Exception('Failed to delete movie: $e');
    }
  }
}
