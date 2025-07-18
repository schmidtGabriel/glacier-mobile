import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoGridView extends StatefulWidget {
  final videos;
  final Function(AssetEntity) previewVideo;

  const VideoGridView({
    super.key,
    required this.videos,
    required this.previewVideo,
  });

  @override
  State<VideoGridView> createState() => _VideoGridViewState();
}

class _VideoGridViewState extends State<VideoGridView> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: widget.videos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            return FutureBuilder<Uint8List?>(
              future: video.thumbnailDataWithSize(ThumbnailSize(200, 200)),
              builder: (_, snapshot) {
                final thumb = snapshot.data;
                if (thumb == null) return Container(color: Colors.grey);
                return GestureDetector(
                  onTap: () async {
                    // You can navigate or do something with the selected video
                    // print("Selected video: ${video.id}");
                    // print('video $video ');

                    widget.previewVideo(video);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(thumb, fit: BoxFit.cover),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                        ),
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
                            _formatDuration(video.duration),
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
