import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoGridView extends StatefulWidget {
  final List<AssetEntity> videos;
  final Function(AssetEntity) previewVideo;

  const VideoGridView({
    super.key,
    required this.videos,
    required this.previewVideo,
  });

  @override
  State<VideoGridView> createState() => _VideoGridViewState();
}

class _VideoData {
  final AssetEntity video;
  final Uint8List? thumbnailData;
  final String formattedDuration;

  _VideoData({
    required this.video,
    this.thumbnailData,
    required this.formattedDuration,
  });
}

class _VideoGridViewState extends State<VideoGridView> {
  bool isLoading = false;
  List<_VideoData> videoDataList = [];
  final Map<String, Uint8List> _thumbnailCache = {};

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: videoDataList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final videoData = videoDataList[index];
            final video = videoData.video;

            return GestureDetector(
              onTap: () async {
                widget.previewVideo(video);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  videoData.thumbnailData != null
                      ? Image.memory(
                        videoData.thumbnailData!,
                        fit: BoxFit.cover,
                      )
                      : Container(color: Colors.grey),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(Icons.play_circle_fill, color: Colors.white70),
                  ),
                  // Duration on bottom-left
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        videoData.formattedDuration,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  @override
  void dispose() {
    // Clear thumbnail cache to free memory
    _thumbnailCache.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadVideoData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<_VideoData> tempVideoData = [];

      for (final video in widget.videos) {
        // Cache thumbnail
        Uint8List? thumbnailData;
        if (_thumbnailCache.containsKey(video.id)) {
          thumbnailData = _thumbnailCache[video.id];
        } else {
          try {
            // Use smaller thumbnail size to reduce memory usage
            thumbnailData = await video.thumbnailDataWithSize(
              ThumbnailSize(150, 150), // Reduced from 200x200
            );
            if (thumbnailData != null) {
              _thumbnailCache[video.id] = thumbnailData;
            }
          } catch (e) {
            print('Error loading thumbnail for video ${video.id}: $e');
          }
        }

        // Pre-format duration to avoid repeated calculations
        final formattedDuration = _formatDuration(video.duration);

        tempVideoData.add(
          _VideoData(
            video: video,
            thumbnailData: thumbnailData,
            formattedDuration: formattedDuration,
          ),
        );
      }

      if (mounted) {
        setState(() {
          videoDataList = tempVideoData;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading video data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
