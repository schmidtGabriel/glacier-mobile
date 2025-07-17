import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:glacier/pages/home/PreviewVideoPage.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  _VideoPickerScreenState createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  List<AssetEntity> _videos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _videos.isEmpty
              ? Center(child: CircularProgressIndicator())
              : GridView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: _videos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return FutureBuilder<Uint8List?>(
                    future: video.thumbnailDataWithSize(
                      ThumbnailSize(200, 200),
                    ),
                    builder: (_, snapshot) {
                      final thumb = snapshot.data;
                      if (thumb == null) return Container(color: Colors.grey);
                      return GestureDetector(
                        onTap: () async {
                          // You can navigate or do something with the selected video
                          // print("Selected video: ${video.id}");
                          // print('video $video ');
                          final selectedVideo =
                              await Navigator.push<AssetEntity?>(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PreviewVideoPage(localVideo: video),
                                ),
                              );
                          if (selectedVideo != null) {
                            // var path = await selectedVideo.file;
                            Navigator.of(context).pop(selectedVideo);
                          }
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadVideos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      PhotoManager.openSetting();
      return;
    }

    // Get all albums/folders with videos
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    // Get all videos from all albums
    List<AssetEntity> videos = [];
    for (var album in albums) {
      final albumVideos = await album.getAssetListPaged(page: 0, size: 100);
      videos.addAll(albumVideos);
    }

    setState(() {
      _videos = videos;
    });
  }
}
