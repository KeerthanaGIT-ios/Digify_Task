import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie.dart';
import '../../../services/api_service.dart';

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTrendingMovies();
});
