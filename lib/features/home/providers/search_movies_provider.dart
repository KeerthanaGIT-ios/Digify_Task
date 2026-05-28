import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_service.dart';
import 'popular_movies_provider.dart'; // Reuse PaginatedMoviesState

class SearchMoviesNotifier extends StateNotifier<PaginatedMoviesState> {
  final ApiService _apiService;
  String _currentQuery = '';
  Timer? _debounceTimer;

  SearchMoviesNotifier(this._apiService) : super(const PaginatedMoviesState());

  String get currentQuery => _currentQuery;

  /// Triggered whenever search input changes
  void onQueryChanged(String query) {
    if (query == _currentQuery) return;
    _currentQuery = query;
    
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      state = const PaginatedMoviesState();
      return;
    }

    // Debounce the search requests by 500 milliseconds
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search(isRefresh: true);
    });
  }

  /// Execute search query
  Future<void> search({bool isRefresh = false}) async {
    if (_currentQuery.trim().isEmpty) return;

    if (!isRefresh && (state.isLoading || state.isLoadMore || !state.hasMore)) {
      return;
    }

    if (isRefresh) {
      state = state.copyWith(
        isLoading: true,
        page: 1,
        movies: [],
        errorMessage: null,
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoadMore: true, errorMessage: null);
    }

    try {
      final nextPage = state.page;
      final results = await _apiService.searchMovies(_currentQuery, page: nextPage);

      if (results.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isLoadMore: false,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          movies: isRefresh ? results : [...state.movies, ...results],
          page: nextPage + 1,
          isLoading: false,
          isLoadMore: false,
          hasMore: results.length >= 20,
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchMoviesProvider =
    StateNotifierProvider<SearchMoviesNotifier, PaginatedMoviesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SearchMoviesNotifier(apiService);
});
