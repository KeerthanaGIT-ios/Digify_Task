import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/movie.dart';
import '../../../services/firestore_service.dart';

class AddEditMovieScreen extends ConsumerStatefulWidget {
  final int? movieId;

  const AddEditMovieScreen({
    super.key,
    this.movieId,
  });

  @override
  ConsumerState<AddEditMovieScreen> createState() => _AddEditMovieScreenState();
}

class _AddEditMovieScreenState extends ConsumerState<AddEditMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _posterUrlController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _yearController;

  double _rating = 7.0;
  String _selectedCategory = 'Action';
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  String? _fetchError;

  final List<String> _categories = [
    'Action',
    'Comedy',
    'Drama',
    'Science Fiction',
    'Adventure',
    'Thriller',
    'Animation',
    'Family',
    'Romance',
    'Fantasy',
    'Music',
    'Crime'
  ];

  bool get isEditMode => widget.movieId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _posterUrlController = TextEditingController();
    _videoUrlController = TextEditingController();
    _descriptionController = TextEditingController();
    _yearController = TextEditingController();

    if (isEditMode) {
      _loadMovieDetails();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _posterUrlController.dispose();
    _videoUrlController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  /// Load details for editing
  Future<void> _loadMovieDetails() async {
    setState(() {
      _isFetchingDetails = true;
      _fetchError = null;
    });

    try {
      final details = await ref.read(firestoreServiceProvider).getMovieDetails(widget.movieId!);
      
      if (mounted) {
        setState(() {
          _titleController.text = details.title;
          _posterUrlController.text = details.posterPath ?? '';
          
          // Use standard movie cast/helper details to extract video url or categories
          final movieObj = details.toMovie();
          _videoUrlController.text = movieObj.videoUrl ?? '';
          _descriptionController.text = details.overview;
          _yearController.text = details.releaseYear;
          _rating = details.voteAverage;
          
          if (movieObj.category != null && _categories.contains(movieObj.category)) {
            _selectedCategory = movieObj.category!;
          } else if (details.genres.isNotEmpty) {
            final firstGenre = details.genres.first.name;
            if (_categories.contains(firstGenre)) {
              _selectedCategory = firstGenre;
            }
          }
          
          _isFetchingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString().replaceAll('Exception: ', '');
          _isFetchingDetails = false;
        });
      }
    }
  }

  /// Save form submission
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Prepare Movie parameters
    final int targetId = isEditMode ? widget.movieId! : DateTime.now().millisecondsSinceEpoch;
    final String posterUrl = _posterUrlController.text.trim();
    final String? videoUrl = _videoUrlController.text.trim().isEmpty ? null : _videoUrlController.text.trim();
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String yearStr = _yearController.text.trim();

    // Map Category to standard Genre IDs (Action: 28, Drama: 18, Comedy: 35, etc.)
    int mappedGenreId = 28;
    switch (_selectedCategory) {
      case 'Action': mappedGenreId = 28; break;
      case 'Adventure': mappedGenreId = 12; break;
      case 'Animation': mappedGenreId = 16; break;
      case 'Comedy': mappedGenreId = 35; break;
      case 'Crime': mappedGenreId = 80; break;
      case 'Drama': mappedGenreId = 18; break;
      case 'Family': mappedGenreId = 10751; break;
      case 'Fantasy': mappedGenreId = 14; break;
      case 'Music': mappedGenreId = 10402; break;
      case 'Romance': mappedGenreId = 10749; break;
      case 'Science Fiction': mappedGenreId = 878; break;
      case 'Thriller': mappedGenreId = 53; break;
    }

    final movie = Movie(
      id: targetId,
      title: title,
      overview: description,
      posterPath: posterUrl,
      backdropPath: posterUrl,
      voteAverage: _rating,
      releaseDate: '$yearStr-01-01',
      genreIds: [mappedGenreId],
      category: _selectedCategory,
      videoUrl: videoUrl,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      if (isEditMode) {
        await ref.read(firestoreServiceProvider).updateMovie(movie);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('"${movie.title}" updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ref.read(firestoreServiceProvider).addMovie(movie);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('"${movie.title}" added to movies list.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        context.go('/admin');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingDetails) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    if (_fetchError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Movie')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.primaryRed),
                const SizedBox(height: 16),
                Text('Error loading movie details: $_fetchError', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadMovieDetails,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'EDIT MOVIE' : 'ADD NEW MOVIE'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                const Text('Movie Title *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the movie title';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'e.g. Inception',
                  ),
                ),
                const SizedBox(height: 20),

                // Poster URL Field
                const Text('Poster Image URL *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _posterUrlController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a poster image URL';
                    }
                    if (!val.trim().startsWith('https://')) {
                      return 'Please enter a valid HTTPS URL';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/poster.jpg',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Video URL Field (Optional)
                const Text('Video/Trailer URL (Optional)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _videoUrlController,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty && !val.trim().startsWith('https://')) {
                      return 'Please enter a valid HTTPS URL';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/trailer.mp4',
                    prefixIcon: Icon(Icons.video_library_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Chips Selector
                const Text('Category / Genre *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: AppColors.cardBackground,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryRed : AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Release Year
                const Text('Release Year *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the release year';
                    }
                    final int? year = int.tryParse(val.trim());
                    if (year == null || year < 1880 || year > 2100) {
                      return 'Please enter a valid 4-digit year';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'e.g. 2010',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Rating Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rating *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.ratingYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.ratingYellow, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_rating.toStringAsFixed(1)} / 10.0',
                            style: const TextStyle(
                              color: AppColors.ratingYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryRed,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primaryRed,
                    overlayColor: AppColors.primaryRed.withValues(alpha: 0.2),
                    valueIndicatorColor: AppColors.primaryRed,
                  ),
                  child: Slider(
                    value: _rating,
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (val) => setState(() => _rating = val),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text('Description / Overview *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the movie overview/description';
                    }
                    if (val.trim().length < 10) {
                      return 'Description must be at least 10 characters long';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Enter movie synopsis...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 36),

                // Buttons Form Action Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : () => context.go('/admin'),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _saveForm,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Movie'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
