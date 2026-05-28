import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/api_constants.dart';
import '../core/theme/app_colors.dart';

/// A reusable media banner widget for the Movie Details screen.
///
/// - If [videoUrl] is present and valid, shows the backdrop image with a
///   premium play‑trailer overlay. Tapping play initialises the video player.
/// - If [videoUrl] is null/empty, renders the static backdrop image only.
/// - Handles video loading errors gracefully by reverting to the backdrop.
class MovieMediaBanner extends StatefulWidget {
  /// HTTPS URL to a streamable video (MP4, etc.). May be null.
  final String? videoUrl;

  /// Poster/backdrop path or full URL used for the static image fallback.
  final String? backdropPath;

  /// Optional poster path used as a secondary fallback image.
  final String? posterPath;

  const MovieMediaBanner({
    super.key,
    this.videoUrl,
    this.backdropPath,
    this.posterPath,
  });

  @override
  State<MovieMediaBanner> createState() => _MovieMediaBannerState();
}

class _MovieMediaBannerState extends State<MovieMediaBanner>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;

  /// Tracks the current visual state of the banner.
  _BannerMode _mode = _BannerMode.image;

  /// Whether the controls overlay is visible (auto‑hides after a delay).
  bool _showControls = false;

  /// Whether the video audio is muted.
  bool _isMuted = false;

  /// Late animation controller for the play‑button pulse effect.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MovieMediaBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.backdropPath != widget.backdropPath ||
        oldWidget.posterPath != widget.posterPath) {
      _disposeVideoController();
      _showControls = false;
      _mode = _BannerMode.image;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Video helpers
  // ──────────────────────────────────────────────────────────────────────────

  bool get _hasVideo => _validVideoUri != null;

  Uri? get _validVideoUri {
    final rawUrl = widget.videoUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }

  String get _resolvedBackdropUrl =>
      ApiConstants.getBackdropUrl(widget.backdropPath);

  void _disposeVideoController() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
  }

  void _videoListener() {
    if (!mounted) return;

    // If the controller has an error, fall back to image.
    if (_controller != null && _controller!.value.hasError) {
      debugPrint(
        'MovieMediaBanner: video error – ${_controller!.value.errorDescription}',
      );
      _fallbackToImage(showSnackbar: true);
      return;
    }

    // Refresh the UI so the progress / play‑state stays in sync.
    if (mounted) setState(() {});
  }

  /// Initialise the video player from the network URL.
  Future<void> _initVideo() async {
    final videoUri = _validVideoUri;
    if (videoUri == null) return;

    setState(() => _mode = _BannerMode.loading);

    try {
      final controller = VideoPlayerController.networkUrl(videoUri);

      _controller = controller;
      controller.addListener(_videoListener);

      await controller.initialize();

      if (!mounted) {
        _disposeVideoController();
        return;
      }

      controller.setVolume(_isMuted ? 0.0 : 1.0);
      await controller.setLooping(false);
      await controller.play();

      setState(() {
        _mode = _BannerMode.playing;
        _showControls = true;
      });

      // Auto‑hide controls after 3 seconds.
      _scheduleControlsHide();
    } catch (e) {
      debugPrint('MovieMediaBanner: failed to init video – $e');
      _fallbackToImage(showSnackbar: true);
    }
  }

  void _fallbackToImage({bool showSnackbar = false}) {
    _disposeVideoController();
    if (!mounted) return;
    setState(() => _mode = _BannerMode.image);

    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video could not be loaded. Showing poster image.'),
          backgroundColor: AppColors.cardBackground,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() => _showControls = true);
    _scheduleControlsHide();
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    _isMuted = !_isMuted;
    c.setVolume(_isMuted ? 0.0 : 1.0);
    setState(() {});
  }

  void _stopVideo() {
    _disposeVideoController();
    if (mounted) setState(() => _mode = _BannerMode.image);
  }

  void _onTapControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          _mode == _BannerMode.playing &&
          _controller != null &&
          _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1 – backdrop image (always behind; visible when mode == image)
        _buildBackdropImage(),

        // Layer 2 – video player (only when mode == playing)
        if (_mode == _BannerMode.playing && _controller != null)
          _buildVideoPlayer(),

        // Layer 3 – loading spinner
        if (_mode == _BannerMode.loading) _buildLoadingOverlay(),

        // Layer 3b – buffering spinner while an initialized stream catches up
        if (_mode == _BannerMode.playing &&
            _controller != null &&
            _controller!.value.isBuffering)
          _buildBufferingOverlay(),

        // Layer 4 – gradient scrim
        _buildGradientScrim(),

        // Layer 5 – play button overlay (image mode, video available)
        if (_mode == _BannerMode.image && _hasVideo) _buildPlayOverlay(),

        // Layer 6 – playback controls (playing mode)
        if (_mode == _BannerMode.playing && _controller != null)
          _buildPlaybackControls(),
      ],
    );
  }

  // ──── Sub‑builders ─────────────────────────────────────────────────────────

  Widget _buildBackdropImage() {
    final url = _resolvedBackdropUrl;
    return Image.network(
      url.trim().isNotEmpty ? url.trim() : 'https://picsum.photos/800/500',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black12,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'https://picsum.photos/800/500',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _controller!.value.isInitialized ? 1.0 : 0.0,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryRed),
            SizedBox(height: 12),
            Text(
              'Loading trailer…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: 1,
          child: Container(
            color: Colors.black.withValues(alpha: 0.25),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientScrim() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                AppColors.background,
              ],
              stops: const [0.5, 0.8, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _initVideo,
        child: Container(
          color: Colors.black.withValues(alpha: 0.25),
          child: Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryRed.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onTapControls,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showControls ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Stack(
                children: [
                  // Centre – Play / Pause
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Bottom‑right – Mute & Stop controls
                  Positioned(
                    bottom: 48,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _controlButton(
                          icon: _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          onTap: _toggleMute,
                        ),
                        const SizedBox(width: 8),
                        _controlButton(
                          icon: Icons.close_rounded,
                          onTap: _stopVideo,
                        ),
                      ],
                    ),
                  ),

                  // Bottom – progress bar
                  if (_controller!.value.isInitialized)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 36,
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        colors: const VideoProgressColors(
                          playedColor: AppColors.primaryRed,
                          bufferedColor: AppColors.border,
                          backgroundColor: AppColors.shimmerBase,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.55),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Internal state tracker for the banner widget.
enum _BannerMode { image, loading, playing }
