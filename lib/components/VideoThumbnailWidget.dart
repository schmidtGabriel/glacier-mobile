import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// A widget that displays a video thumbnail with automatic orientation detection.
///
/// Features:
/// - Automatically detects video orientation and sets appropriate aspect ratio
/// - Generates thumbnail from video URL or local file path
/// - Supports custom aspect ratio override
/// - Provides orientation detection callback
/// - Supports tap gestures
/// - Works with both network URLs and local file paths
///
/// Example usage:
/// ```dart
/// // With URL
/// VideoThumbnailWidget(
///   videoPath: 'https://example.com/video.mp4',
///   onTap: () => playVideo(),
///   onOrientationDetected: (aspectRatio, isPortrait) {
///     print('Video is ${isPortrait ? 'portrait' : 'landscape'}');
///   },
/// )
///
/// // With local file path
/// VideoThumbnailWidget(
///   videoPath: '/storage/emulated/0/DCIM/Camera/video.mp4',
///   onTap: () => playVideo(),
/// )
///
/// // With custom aspect ratio (overrides auto-detection)
/// VideoThumbnailWidget(
///   videoPath: 'path/to/video.mp4',
///   aspectRatio: 16 / 9,
/// )
/// ```
///
/// For getting video info without creating a widget:
/// ```dart
/// final videoInfo = await VideoThumbnailWidget.getVideoInfo(videoPath);
/// final isPortrait = videoInfo['isPortrait'];
/// final aspectRatio = videoInfo['aspectRatio'];
/// final duration = videoInfo['duration'];
/// ```
class VideoThumbnailWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    bool isPortrait = true;

    Widget thumbnail = Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _generateThumbnail(videoPath),
            _getVideoAspectRatio(),
          ]),
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              final defaultAspectRatio = aspectRatio ?? 16 / 9;
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
            if (onOrientationDetected != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onOrientationDetected!(detectedAspectRatio, isPortrait);
              });
            }

            if (thumb == null) {
              return Container(
                width: 200,
                height: detectedAspectRatio == 9 / 16 ? 355 : 112,
                color: Colors.grey,
                child: const Icon(
                  Icons.video_library,
                  size: 40,
                  color: Colors.white,
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
                    Image.memory(thumb, fit: BoxFit.cover),
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

            if (onTap != null) {
              return GestureDetector(onTap: onTap, child: thumbnailContent);
            }

            return thumbnailContent;
          },
        ),
      ),
    );

    return thumbnail;
  }

  /// Method to generate thumbnail from video path (URL or local file)
  Future<Uint8List?> _generateThumbnail(String videoPath) async {
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: 0,
        maxHeight: 0,
        quality: 75,
      );
      return thumbnailData;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Get video orientation and calculate aspect ratio
  Future<double> _getVideoAspectRatio() async {
    if (aspectRatio != null) {
      return aspectRatio!;
    }

    try {
      final VideoPlayerController controller;

      if (_isUrl(videoPath)) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        controller = VideoPlayerController.file(File(videoPath));
      }

      await controller.initialize();

      final size = controller.value.size;
      controller.dispose();

      if (size.width > 0 && size.height > 0) {
        return size.width / size.height;
      }

      return 16 / 9; // Default fallback
    } catch (e) {
      print('Error getting video orientation: $e');
      return 16 / 9; // Default fallback
    }
  }

  /// Check if the path is a URL or local file
  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Static method to get video orientation without creating a widget
  static Future<Map<String, dynamic>> getVideoInfo(String videoPath) async {
    try {
      final VideoPlayerController controller;

      if (_isUrlStatic(videoPath)) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        controller = VideoPlayerController.file(File(videoPath));
      }

      await controller.initialize();

      final size = controller.value.size;
      final duration = controller.value.duration;
      controller.dispose();

      if (size.width > 0 && size.height > 0) {
        final aspectRatio = size.width / size.height;
        final isPortrait = aspectRatio < 1.0;
        final isLandscape = aspectRatio > 1.0;
        final isSquare = aspectRatio == 1.0;

        return {
          'aspectRatio': aspectRatio,
          'isPortrait': isPortrait,
          'isLandscape': isLandscape,
          'isSquare': isSquare,
          'width': size.width,
          'height': size.height,
          'duration': duration,
        };
      }

      return {
        'aspectRatio': 16 / 9,
        'isPortrait': false,
        'isLandscape': true,
        'isSquare': false,
        'width': 0.0,
        'height': 0.0,
        'duration': Duration.zero,
      };
    } catch (e) {
      print('Error getting video info: $e');
      return {
        'aspectRatio': 16 / 9,
        'isPortrait': false,
        'isLandscape': true,
        'isSquare': false,
        'width': 0.0,
        'height': 0.0,
        'duration': Duration.zero,
        'error': e.toString(),
      };
    }
  }

  /// Static helper method to check if path is URL
  static bool _isUrlStatic(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
