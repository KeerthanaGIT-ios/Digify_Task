import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie.dart';
import 'popular_movies_provider.dart';

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  // Obtain the stream's future to stay reactively updated
  final movies = await ref.watch(firestoreMoviesStreamProvider.future);
  return movies.take(6).toList();
});
