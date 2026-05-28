import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/movie_card.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/popular_movies_provider.dart';
import '../providers/search_movies_provider.dart';
import '../providers/trending_movies_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Handle scroll listener for infinite scroll pagination
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 300.0; // Trigger load before user hits the bottom

    if (maxScroll - currentScroll <= threshold) {
      final query = _searchController.text;
      if (query.trim().isEmpty) {
        ref.read(popularMoviesProvider.notifier).loadMovies();
      } else {
        ref.read(searchMoviesProvider.notifier).search();
      }
    }
  }

  /// Pull to Refresh execution
  Future<void> _onRefresh() async {
    final query = _searchController.text;
    if (query.trim().isEmpty) {
      ref.invalidate(trendingMoviesProvider);
      await ref.read(popularMoviesProvider.notifier).loadMovies(isRefresh: true);
    } else {
      await ref.read(searchMoviesProvider.notifier).search(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trendingState = ref.watch(trendingMoviesProvider);
    final popularState = ref.watch(popularMoviesProvider);
    final searchState = ref.watch(searchMoviesProvider);
    
    final isSearching = _searchController.text.trim().isNotEmpty;
    final activeMoviesState = isSearching ? searchState : popularState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MOVIE DISCOVERY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.primaryRed),
            tooltip: 'My Favorites',
            onPressed: () => _showFavoritesBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryRed,
        backgroundColor: AppColors.cardBackground,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search Bar header (sticky using SliverToBoxAdapter or regular container)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (val) {
                    ref.read(searchMoviesProvider.notifier).onQueryChanged(val);
                    // Force refresh to handle active movie list toggling
                    setState(() {});
                  },
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search movies by title...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchMoviesProvider.notifier).onQueryChanged('');
                              _searchFocusNode.unfocus();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            if (!isSearching) ...[
              // Trending Section
              SliverToBoxAdapter(
                child: trendingState.when(
                  data: (movies) {
                    if (movies.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Trending Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 210,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: movies.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemBuilder: (context, index) {
                              final movie = movies[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: MovieCard(
                                  movie: movie,
                                  width: 130,
                                  height: 195,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  error: (err, stack) => const SizedBox.shrink(), // Suppress error for trending, popular handles main error UI
                  loading: () => LoadingSkeleton.trendingSection(),
                ),
              ),

              // Title for Popular Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Popular Movies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],

            if (isSearching)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

            // Main Grid displaying popular or searched items
            if (activeMoviesState.isLoading && activeMoviesState.movies.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: LoadingSkeleton.movieGrid(count: 9, context: context),
                ),
              )
            else if (activeMoviesState.errorMessage != null &&
                activeMoviesState.movies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  errorMessage: activeMoviesState.errorMessage!,
                  onRetry: () {
                    if (isSearching) {
                      ref.read(searchMoviesProvider.notifier).search(isRefresh: true);
                    } else {
                      ref.read(popularMoviesProvider.notifier).loadMovies(isRefresh: true);
                    }
                  },
                ),
              )
            else if (activeMoviesState.movies.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_creation_outlined,
                          size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'No movies found.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Grid content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900
                        ? 5
                        : (MediaQuery.of(context).size.width > 600 ? 4 : 3),
                    childAspectRatio: 0.67,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movie = activeMoviesState.movies[index];
                      return MovieCard(movie: movie);
                    },
                    childCount: activeMoviesState.movies.length,
                  ),
                ),
              ),

              // Bottom loaders / Statuses for paginated loading
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: _buildPaginationStatusWidget(activeMoviesState, isSearching),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds pagination loader / error retry banner at the bottom of the list
  Widget _buildPaginationStatusWidget(PaginatedMoviesState state, bool isSearching) {
    if (state.isLoadMore) {
      return const Center(
        child: SpinKitThreeBounce(
          color: AppColors.primaryRed,
          size: 24,
        ),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Text(
              'Error loading more movies: ${state.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primaryRed, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                if (isSearching) {
                  ref.read(searchMoviesProvider.notifier).search();
                } else {
                  ref.read(popularMoviesProvider.notifier).loadMovies();
                }
              },
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.textPrimary),
              label: const Text('Retry Load', style: TextStyle(color: AppColors.textPrimary)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore) {
      return const Center(
        child: Text(
          'You have reached the end of the list.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Display favorited movies in a beautiful Bottom Sheet
  void _showFavoritesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final favorites = ref.watch(favoritesProvider);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Favorites',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${favorites.length} ${favorites.length == 1 ? 'movie' : 'movies'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: favorites.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_border_rounded,
                                      size: 64,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No favorites yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Save movies to access them offline.',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                controller: scrollController,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.67,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: favorites.length,
                                itemBuilder: (context, index) {
                                  final movie = favorites[index];
                                  return MovieCard(movie: movie);
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
