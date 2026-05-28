import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final double width;
  final double height;
  final bool showRating;
  final String? heroTag;

  const MovieCard({
    super.key,
    required this.movie,
    this.width = 130,
    this.height = 195,
    this.showRating = true,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeroTag = heroTag ?? 'movie-poster-${movie.id}';
    // ignore: avoid_print
    print(movie.posterUrl);
    debugPrint(
      'MovieCard.build: movieId=${movie.id} title="${movie.title}" heroTag="$effectiveHeroTag" posterUrl="${movie.posterUrl}"',
    );

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'details',
          pathParameters: {'id': movie.id.toString()},
          extra: movie,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero animation target linking to details page
              Positioned.fill(
                child: Hero(
                  tag: effectiveHeroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _MovieThumbnail(movie: movie),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.0, 0.68, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              if (showRating && movie.voteAverage > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.ratingYellow.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.ratingYellow,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Movie Title overlay (only shows fully at bottom)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieThumbnail extends StatefulWidget {
  final Movie movie;

  const _MovieThumbnail({required this.movie});

  @override
  State<_MovieThumbnail> createState() => _MovieThumbnailState();
}

class _MovieThumbnailState extends State<_MovieThumbnail> {
  static const Map<String, String> _imageHeaders = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
    'Accept':
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  };

  int _urlIndex = 0;

  @override
  void didUpdateWidget(covariant _MovieThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id) {
      _urlIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.movie.thumbnailUrls;
    final imageUrl = urls[_urlIndex].trim();

    return Image.network(
      imageUrl,
      headers: _imageHeaders,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 220,
          color: Colors.grey,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Movie image failed: $imageUrl $error');
        if (_urlIndex < urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _urlIndex += 1);
            }
          });
          return Container(height: 220, color: Colors.grey.shade800);
        }

        return Container(
          height: 220,
          padding: const EdgeInsets.all(10),
          color: AppColors.surface,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.movie, size: 42, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  widget.movie.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
