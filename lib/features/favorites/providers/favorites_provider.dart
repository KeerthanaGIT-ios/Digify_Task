import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../models/movie.dart';

class FavoritesNotifier extends StateNotifier<List<Movie>> {
  final HiveService _hiveService;

  FavoritesNotifier(this._hiveService) : super([]) {
    _loadFavorites();
  }

  /// Load initial favorited list from Hive local box
  void _loadFavorites() {
    try {
      final list = _hiveService.getFavorites();
      state = list.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading favorites from Hive: $e');
      state = [];
    }
  }

  /// Check if a movie is favorited
  bool isFavorite(int id) {
    return state.any((movie) => movie.id == id);
  }

  /// Toggle favorited status
  Future<void> toggleFavorite(Movie movie) async {
    final isAlreadyFav = isFavorite(movie.id);
    try {
      if (isAlreadyFav) {
        await _hiveService.removeFavorite(movie.id);
        state = state.where((m) => m.id != movie.id).toList();
      } else {
        await _hiveService.addFavorite(movie.id, movie.toJson());
        state = [...state, movie];
      }
    } catch (e) {
      debugPrint('Error toggling favorite in Hive: $e');
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<Movie>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return FavoritesNotifier(hiveService);
});
