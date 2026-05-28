import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie_details.dart';
import '../../../services/api_service.dart';

final movieDetailsProvider =
    FutureProvider.family<MovieDetails, int>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMovieDetails(id);
});
