import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/movie.dart';
import '../../../services/firestore_service.dart';

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

final firestoreMoviesStreamProvider = StreamProvider<List<Movie>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchMovies();
});

class PopularMoviesNotifier extends StateNotifier<PaginatedMoviesState> {
  final Ref _ref;
  StreamSubscription? _subscription;

  PopularMoviesNotifier(this._ref) : super(const PaginatedMoviesState()) {
    loadMovies();
  }

  Future<void> loadMovies({bool isRefresh = false}) async {
    // If we already have a subscription and we aren't refreshing, do nothing
    if (_subscription != null && !isRefresh) return;

    _subscription?.cancel();

    if (isRefresh || state.movies.isEmpty) {
      state = state.copyWith(isLoading: true, page: 1, movies: [], errorMessage: null, hasMore: true);
    } else {
      state = state.copyWith(isLoadMore: true, errorMessage: null);
    }

    _subscription = _ref.read(firestoreServiceProvider).watchMovies().listen(
      (movies) {
        state = state.copyWith(
          movies: movies,
          isLoading: false,
          isLoadMore: false,
          hasMore: false, // Streams handle all movies in real-time, no need for pagination limits
          errorMessage: null,
        );
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          isLoadMore: false,
          errorMessage: err.toString().replaceAll('Exception: ', ''),
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final popularMoviesProvider =
    StateNotifierProvider<PopularMoviesNotifier, PaginatedMoviesState>((ref) {
  return PopularMoviesNotifier(ref);
});
