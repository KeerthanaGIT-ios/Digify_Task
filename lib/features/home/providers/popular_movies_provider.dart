import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie.dart';
import '../../../services/api_service.dart';

class PaginatedMoviesState {
  final List<Movie> movies;
  final int page;
  final bool isLoading;
  final bool isLoadMore;
  final String? errorMessage;
  final bool hasMore;

  const PaginatedMoviesState({
    this.movies = const [],
    this.page = 1,
    this.isLoading = false,
    this.isLoadMore = false,
    this.errorMessage,
    this.hasMore = true,
  });

  PaginatedMoviesState copyWith({
    List<Movie>? movies,
    int? page,
    bool? isLoading,
    bool? isLoadMore,
    String? errorMessage,
    bool? hasMore,
  }) {
    return PaginatedMoviesState(
      movies: movies ?? this.movies,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      errorMessage: errorMessage, // We pass null explicitly to reset the error
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PopularMoviesNotifier extends StateNotifier<PaginatedMoviesState> {
  final ApiService _apiService;

  PopularMoviesNotifier(this._apiService) : super(const PaginatedMoviesState()) {
    loadMovies();
  }

  Future<void> loadMovies({bool isRefresh = false}) async {
    // If already loading, or there's no more items (and it's not a refresh), do nothing
    if (!isRefresh && (state.isLoading || state.isLoadMore || !state.hasMore)) {
      return;
    }

    if (isRefresh) {
      state = state.copyWith(isLoading: true, page: 1, movies: [], errorMessage: null, hasMore: true);
    } else {
      if (state.movies.isEmpty) {
        state = state.copyWith(isLoading: true, errorMessage: null);
      } else {
        state = state.copyWith(isLoadMore: true, errorMessage: null);
      }
    }

    try {
      final nextPage = state.page;
      final newMovies = await _apiService.getPopularMovies(page: nextPage);

      if (newMovies.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isLoadMore: false,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          movies: isRefresh ? newMovies : [...state.movies, ...newMovies],
          page: nextPage + 1,
          isLoading: false,
          isLoadMore: false,
          hasMore: newMovies.length >= 20, // TMDB returns 20 results per page
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final popularMoviesProvider =
    StateNotifierProvider<PopularMoviesNotifier, PaginatedMoviesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PopularMoviesNotifier(apiService);
});
