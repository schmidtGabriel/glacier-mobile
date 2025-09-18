import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double? aspectRatio;
  final VoidCallback? onTap;
  final Function(double aspectRatio, bool isPortrait)? onOrientationDetected;

  const VideoThumbnailWidget({
    super.key,
    required this.videoPath,
    this.aspectRatio,
    this.onTap,
    this.onOrientationDetected,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

// Static cache for thumbnails to avoid regenerating them
class _ThumbnailCache {
  static final Map<String, Uint8List> _cache = {};
  static const int maxCacheSize =
      50; // Limit cache size to prevent memory bloat

  static void clear() => _cache.clear();

  static Uint8List? get(String key) => _cache[key];

  static void put(String key, Uint8List data) {
    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry when cache is full
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[key] = data;
  }
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  int _retryKey = 0;
  Completer<List<dynamic>>? _thumbnailCompleter;
  VideoPlayerController? _controller;

  @override
  Widget build(BuildContext context) {
    bool isPortrait = true;

    Widget thumbnail = Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_retryKey), // Add key to force rebuild on retry
          future: _loadThumbnailData(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              final defaultAspectRatio = widget.aspectRatio ?? 16 / 9;
              return Container(
                width: 200,
                height: defaultAspectRatio == 9 / 16 ? 355 : 112,
                color: Colors.grey,
                child:
                    snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : const Icon(
                          Icons.video_library,
                          size: 40,
                          color: Colors.white,
                        ),
              );
            }

            final thumb = snapshot.data![0] as Uint8List?;
            final detectedAspectRatio = snapshot.data![1] as double;

            // Notify parent about detected orientation
            isPortrait = detectedAspectRatio < 1.0;
            if (widget.onOrientationDetected != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onOrientationDetected!(detectedAspectRatio, isPortrait);
              });
            }

            if (thumb == null) {
              return GestureDetector(
                onTap: _retryLoading,
                child: Container(
                  width: 200,
                  height: detectedAspectRatio == 9 / 16 ? 355 : 112,
                  color: Colors.grey,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 40, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Tap to retry',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget thumbnailContent = SizedBox(
              height: isPortrait ? 355 : 150,
              child: AspectRatio(
                aspectRatio: detectedAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      thumb,
                      fit: BoxFit.cover,
                      cacheWidth: 400, // Limit cache width to reduce memory
                      cacheHeight:
                          (400 / detectedAspectRatio)
                              .round(), // Proportional height
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Icon(Icons.error, color: Colors.white),
                        );
                      },
                    ),
                    const Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (widget.onTap != null) {
              return GestureDetector(
                onTap: widget.onTap,
                child: thumbnailContent,
              );
            }

            return thumbnailContent;
          },
        ),
      ),
    );

    return thumbnail;
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    _thumbnailCompleter = null;
    // Dispose controller if still active
    _controller?.dispose();
    super.dispose();
  }

  /// Method to generate thumbnail from video path (URL or local file) with caching
  Future<Uint8List?> _generateThumbnail(String videoPath) async {
    // Check cache first
    final cachedThumbnail = _ThumbnailCache.get(videoPath);
    if (cachedThumbnail != null) {
      return cachedThumbnail;
    }

    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat:
            ImageFormat.JPEG, // Use JPEG instead of PNG for smaller size
        maxWidth: 400, // Limit width to reduce memory usage
        maxHeight: 400, // Limit height to reduce memory usage
        quality: 75, // Reduced quality for smaller file size
      );

      // Cache the thumbnail if generation was successful
      if (thumbnailData != null) {
        _ThumbnailCache.put(videoPath, thumbnailData);
      }

      return thumbnailData;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Get video orientation and calculate aspect ratio with proper disposal
  Future<double> _getVideoAspectRatio() async {
    if (widget.aspectRatio != null) {
      return widget.aspectRatio!;
    }

    VideoPlayerController? controller;
    try {
      if (_isUrl(widget.videoPath)) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
        );
      } else {
        controller = VideoPlayerController.file(File(widget.videoPath));
      }

      // Store reference for disposal
      _controller = controller;

      await controller.initialize();

      final size = controller.value.size;

      if (size.width > 0 && size.height > 0) {
        return size.width / size.height;
      }

      return 16 / 9; // Default fallback
    } catch (e) {
      print('Error getting video orientation: $e');
      return 16 / 9; // Default fallback
    } finally {
      // Always dispose controller after getting aspect ratio
      controller?.dispose();
      _controller = null;
    }
  }

  /// Check if the path is a URL or local file
  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Load thumbnail data with caching and proper disposal
  Future<List<dynamic>> _loadThumbnailData() async {
    final completer = Completer<List<dynamic>>();
    _thumbnailCompleter = completer;

    try {
      final results = await Future.wait([
        _generateThumbnail(widget.videoPath),
        _getVideoAspectRatio(),
      ]);

      // Check if widget is still mounted and completer is still active
      if (mounted && _thumbnailCompleter == completer) {
        completer.complete(results);
      }
    } catch (e) {
      if (mounted && _thumbnailCompleter == completer) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  void _retryLoading() {
    setState(() {
      _retryKey++;
    });
  }
}
