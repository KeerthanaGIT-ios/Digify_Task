import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/movie.dart';
import '../../../models/movie_details.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/movie_details_provider.dart';

class MovieDetailsScreen extends ConsumerWidget {
  final int movieId;
  final Movie? initialMovie;

  const MovieDetailsScreen({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(movieDetailsProvider(movieId));
    
    // Watch favorites state to dynamically update favorited UI
    final isFav = ref.watch(favoritesProvider).any((m) => m.id == movieId);

    return Scaffold(
      body: detailsAsync.when(
        data: (details) => _buildContent(context, ref, details, isFav),
        error: (err, stack) {
          // If we have initial movie, we can still build the basic page and show an inline error at the bottom
          if (initialMovie != null) {
            final fallbackDetails = MovieDetails(
              id: initialMovie!.id,
              title: initialMovie!.title,
              overview: initialMovie!.overview,
              posterPath: initialMovie!.posterPath,
              backdropPath: initialMovie!.backdropPath,
              voteAverage: initialMovie!.voteAverage,
              releaseDate: initialMovie!.releaseDate,
              genres: [],
            );
            return _buildContent(
              context,
              ref,
              fallbackDetails,
              isFav,
              errorMessage: err.toString().replaceAll('Exception: ', ''),
            );
          }
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: ErrorView(
              errorMessage: err.toString().replaceAll('Exception: ', ''),
              onRetry: () => ref.invalidate(movieDetailsProvider(movieId)),
            ),
          );
        },
        loading: () {
          // If we have initialMovie, show that immediately while loading details
          if (initialMovie != null) {
            final loadingDetails = MovieDetails(
              id: initialMovie!.id,
              title: initialMovie!.title,
              overview: initialMovie!.overview,
              posterPath: initialMovie!.posterPath,
              backdropPath: initialMovie!.backdropPath,
              voteAverage: initialMovie!.voteAverage,
              releaseDate: initialMovie!.releaseDate,
              genres: [],
            );
            return _buildContent(context, ref, loadingDetails, isFav, isDetailsLoading: true);
          }
          return Scaffold(
            body: SafeArea(child: LoadingSkeleton.details()),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MovieDetails details,
    bool isFav, {
    bool isDetailsLoading = false,
    String? errorMessage,
  }) {
    final backdropUrl = ApiConstants.getBackdropUrl(details.backdropPath);
    final posterUrl = ApiConstants.getPosterUrl(details.posterPath);
    debugPrint('MovieDetailsScreen._buildContent: movieId=${details.id} posterUrl="$posterUrl" backdropUrl="$backdropUrl"');
    final scaffoldBg = AppColors.background;

    // Convert details to Movie for favorites management
    final movieModel = details.toMovie();

    return CustomScrollView(
      slivers: [
        // SliverAppBar with Parallax Backdrop image
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          stretch: true,
          backgroundColor: scaffoldBg,
          actions: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppColors.primaryRed : AppColors.textPrimary,
              ),
              tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(movieModel);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFav
                          ? '${details.title} removed from Favorites'
                          : '${details.title} added to Favorites',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.cardBackground,
                  ),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  backdropUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.movie_creation_outlined,
                          color: AppColors.textSecondary, size: 64),
                    ),
                  ),
                ),
                // Gradient to fade details background into pure black scaffold body
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          scaffoldBg,
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Movie Info Content body
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with Poster Overlay, Title & Basic Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster thumbnail
                      Hero(
                        tag: 'movie-poster-${details.id}',
                        child: Container(
                          width: 100,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Shimmer.fromColors(
                                  baseColor: AppColors.shimmerBase,
                                  highlightColor: AppColors.shimmerHighlight,
                                  child: Container(color: Colors.white),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surface,
                                child: const Center(
                                  child: Icon(Icons.movie,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Title and Meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Tagline if available
                            if (details.tagline != null && details.tagline!.isNotEmpty) ...[
                              Text(
                                '"${details.tagline}"',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ] else if (isDetailsLoading) ...[
                              Shimmer.fromColors(
                                baseColor: AppColors.shimmerBase,
                                highlightColor: AppColors.shimmerHighlight,
                                child: Container(
                                  width: 120,
                                  height: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Release Year and Rating Row
                            Row(
                              children: [
                                // Release Year Badge
                                if (details.releaseYear.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      details.releaseYear,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                
                                // Rating
                                if (details.voteAverage > 0) ...[
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.ratingYellow,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    details.voteAverage.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    '/10',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Runtime and Status Info
                            if (isDetailsLoading)
                              Shimmer.fromColors(
                                baseColor: AppColors.shimmerBase,
                                highlightColor: AppColors.shimmerHighlight,
                                child: Container(
                                  width: 80,
                                  height: 14,
                                  color: Colors.white,
                                ),
                              )
                            else if (details.runtime != null && details.runtime! > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: AppColors.textSecondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    details.formattedRuntime,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (details.status != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${details.status}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Genres Wrap Section
                  const Text(
                    'Genres',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isDetailsLoading)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        3,
                        (index) => Shimmer.fromColors(
                          baseColor: AppColors.shimmerBase,
                          highlightColor: AppColors.shimmerHighlight,
                          child: Container(
                            width: 60,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (details.genres.isEmpty)
                    const Text(
                      'No genres available',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: details.genres.map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryRed.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            genre.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  
                  // Overview Section
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.overview.isNotEmpty
                        ? details.overview
                        : 'No overview available for this movie.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  
                  // Inline error notification if fetching details failed but we are displaying basic data
                  if (errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.primaryRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Could not load extra movie details: $errorMessage',
                              style: const TextStyle(
                                  color: AppColors.primaryRed, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(movieDetailsProvider(movieId)),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 60), // bottom spacing
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
