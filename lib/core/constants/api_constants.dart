import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  
  // Replace with your real TMDB API Key
  static const String apiKey = 'YOUR_TMDB_API_KEY';
  
  // Image paths
  static const String imageBaseUrlW342 = 'https://image.tmdb.org/t/p/w342';
  static const String imageBaseUrlW780 = 'https://image.tmdb.org/t/p/w780';
  static const String imageBaseUrlOriginal = 'https://image.tmdb.org/t/p/original';

  // Reliable static placeholder images (picsum.photos is stable and fast)
  static const String defaultPosterUrl =
      'https://picsum.photos/seed/movieposter/342/513';
  static const String defaultBackdropUrl =
      'https://picsum.photos/seed/moviebackdrop/780/439';

  /// Returns true if [url] is a valid HTTPS image URL.
  static bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmedUrl = url.trim();
    final uri = Uri.tryParse(trimmedUrl);
    return uri != null && uri.hasScheme && uri.scheme == 'https';
  }

  // Helper method to get the poster image URL, always returns a valid URL.
  static String getPosterUrl(String? path) {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      debugPrint('ApiConstants.getPosterUrl: empty poster path, using default poster URL.');
      return defaultPosterUrl;
    }
    if (trimmedPath.startsWith('https://')) {
      final result = _isValidImageUrl(trimmedPath) ? trimmedPath : defaultPosterUrl;
      debugPrint('ApiConstants.getPosterUrl: https poster path="$trimmedPath" -> "$result"');
      return result;
    }
    if (trimmedPath.startsWith('http://')) {
      debugPrint('ApiConstants.getPosterUrl: insecure http poster path="$trimmedPath", using default poster URL.');
      return defaultPosterUrl;
    }
    final normalizedPath = trimmedPath.startsWith('/') ? trimmedPath : '/$trimmedPath';
    final result = '$imageBaseUrlW342$normalizedPath';
    debugPrint('ApiConstants.getPosterUrl: TMDB poster path="$trimmedPath" -> "$result"');
    return result;
  }

  // Helper method to get the backdrop image URL, always returns a valid URL.
  static String getBackdropUrl(String? path) {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      debugPrint('ApiConstants.getBackdropUrl: empty backdrop path, using default backdrop URL.');
      return defaultBackdropUrl;
    }
    if (trimmedPath.startsWith('https://')) {
      final result = _isValidImageUrl(trimmedPath) ? trimmedPath : defaultBackdropUrl;
      debugPrint('ApiConstants.getBackdropUrl: https backdrop path="$trimmedPath" -> "$result"');
      return result;
    }
    if (trimmedPath.startsWith('http://')) {
      debugPrint('ApiConstants.getBackdropUrl: insecure http backdrop path="$trimmedPath", using default backdrop URL.');
      return defaultBackdropUrl;
    }
    final normalizedPath = trimmedPath.startsWith('/') ? trimmedPath : '/$trimmedPath';
    final result = '$imageBaseUrlW780$normalizedPath';
    debugPrint('ApiConstants.getBackdropUrl: TMDB backdrop path="$trimmedPath" -> "$result"');
    return result;
  }

  static String getOriginalImageUrl(String? path) {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      debugPrint('ApiConstants.getOriginalImageUrl: empty path, using default poster URL.');
      return defaultPosterUrl;
    }
    if (trimmedPath.startsWith('https://')) {
      final result = _isValidImageUrl(trimmedPath) ? trimmedPath : defaultPosterUrl;
      debugPrint('ApiConstants.getOriginalImageUrl: https path="$trimmedPath" -> "$result"');
      return result;
    }
    if (trimmedPath.startsWith('http://')) {
      debugPrint('ApiConstants.getOriginalImageUrl: insecure http path="$trimmedPath", using default poster URL.');
      return defaultPosterUrl;
    }
    final normalizedPath = trimmedPath.startsWith('/') ? trimmedPath : '/$trimmedPath';
    final result = '$imageBaseUrlOriginal$normalizedPath';
    debugPrint('ApiConstants.getOriginalImageUrl: TMDB original path="$trimmedPath" -> "$result"');
    return result;
  }
}
