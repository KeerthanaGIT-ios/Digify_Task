import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  static const String favoritesBoxName = 'favorites_box';

  // Initialize Hive and open the box
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(favoritesBoxName);
  }

  Box get _box => Hive.box(favoritesBoxName);

  // Add movie to favorites
  Future<void> addFavorite(int id, Map<String, dynamic> movieJson) async {
    await _box.put(id.toString(), movieJson);
  }

  // Remove movie from favorites
  Future<void> removeFavorite(int id) async {
    await _box.delete(id.toString());
  }

  // Check if movie is favorited
  bool isFavorite(int id) {
    return _box.containsKey(id.toString());
  }

  // Get all favorite movies
  List<Map<String, dynamic>> getFavorites() {
    final List<Map<String, dynamic>> list = [];
    for (var key in _box.keys) {
      final value = _box.get(key);
      if (value != null) {
        // Hive sometimes returns casted Map types (like Map<dynamic, dynamic>)
        // We cast it back to Map<String, dynamic> safely
        final map = Map<String, dynamic>.from(value as Map);
        list.add(map);
      }
    }
    return list;
  }

  // Get box stream for listening to database changes
  Stream<BoxEvent> get favoritesStream => _box.watch();
}
