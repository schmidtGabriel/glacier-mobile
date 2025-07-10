import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WatchVideoPage extends StatefulWidget {
  final String? url;

  const WatchVideoPage({super.key, this.url});

  @override
  State<WatchVideoPage> createState() => _WatchVideoPageState();
}

class _WatchVideoPageState extends State<WatchVideoPage> {
  String? videoPath;

  VideoPlayerController? _controllerVideo;

  bool _isLoading = false; // Track loading state

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading, please wait...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        )
        : Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: ValueListenableBuilder<bool>(
            valueListenable: ValueNotifier(_isLoading),
            builder: (context, value, child) {
              // Show full-screen loading indicator if loading

              if (_controllerVideo == null ||
                  !_controllerVideo!.value.isInitialized) {
                return Center(child: Text('Video not available'));
              }
              return Stack(
                children: [
                  // Video Player
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controllerVideo!.value.aspectRatio,
                      child: VideoPlayer(_controllerVideo!),
                    ),
                  ),

                  // Play button overlay if video is paused
                  if (_controllerVideo != null &&
                      _controllerVideo!.value.isInitialized)
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controllerVideo!,
                      builder: (context, value, child) {
                        if (value.isPlaying) {
                          return SizedBox.shrink();
                        } else {
                          return Center(
                            child: GestureDetector(
                              onTap: () {
                                _controllerVideo!.play();
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              );
            },
          ),
        );
  }

  @override
  void dispose() {
    _controllerVideo?.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<bool> _initializeVideo() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final videoUrl = widget.url?.toString().trim();
    if (videoUrl == null || videoUrl.isEmpty) {
      print('Invalid or missing video URL');
      return false;
    }

    if (_controllerVideo != null) {
      await _controllerVideo!.dispose();
    }

    _controllerVideo = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await _controllerVideo!.initialize();
    _controllerVideo!.setLooping(false);
    setState(() {
      _isLoading = false; // Show loading indicator
    });

    setState(() {});
    return true;
  }
}
