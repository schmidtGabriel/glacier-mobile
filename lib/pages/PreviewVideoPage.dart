import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class PreviewVideoPage extends StatefulWidget {
  final AssetEntity? localVideo;
  final String? videoPath;
  final bool hasConfirmButton;

  const PreviewVideoPage({
    super.key,
    this.localVideo,
    this.videoPath,
    this.hasConfirmButton = false,
  });

  @override
  State<PreviewVideoPage> createState() => _PreviewVideoPageState();
}

class _PreviewVideoPageState extends State<PreviewVideoPage> {
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
        : !_isLoading && widget.localVideo == null && widget.videoPath == null
        ? Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Video not found...', style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        )
        : Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.4),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (widget.hasConfirmButton)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controllerVideo != null) {
                        Navigator.of(context).pop({
                          'video': widget.localVideo,
                          'duration':
                              _controllerVideo?.value.duration.inSeconds ?? 0,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: ValueListenableBuilder<bool>(
            valueListenable: ValueNotifier(_isLoading),
            builder: (context, value, child) {
              if (_controllerVideo == null ||
                  !_controllerVideo!.value.isInitialized) {
                return Center(child: Text('Video not available'));
              }
              return Container(
                color: Colors.black.withOpacity(0.4),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      _controllerVideo!.value.aspectRatio,
                                  child: VideoPlayer(_controllerVideo!),
                                ),
                                if (_controllerVideo != null &&
                                    _controllerVideo!.value.isInitialized)
                                  ValueListenableBuilder<VideoPlayerValue>(
                                    valueListenable: _controllerVideo!,
                                    builder: (context, value, child) {
                                      if (value.isPlaying) {
                                        return GestureDetector(
                                          onTap: () {
                                            _controllerVideo!.pause();
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        );
                                      } else {
                                        return Center(
                                          child: GestureDetector(
                                            onTap: () {
                                              _controllerVideo!.play();
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.6,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 56,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Video controls at the bottom
                    Container(
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 5,
                        bottom: 30,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_controllerVideo != null) {
                                if (_controllerVideo!.value.isPlaying) {
                                  _controllerVideo!.pause();
                                } else {
                                  _controllerVideo!.play();
                                }
                              }
                            },
                            icon: ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _controllerVideo!,
                              builder: (context, value, child) {
                                return Icon(
                                  value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _controllerVideo?.seekTo(Duration.zero);
                            },
                            icon: Icon(
                              Icons.replay,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_controllerVideo != null) {
                                final currentVolume =
                                    _controllerVideo!.value.volume;
                                _controllerVideo!.setVolume(
                                  currentVolume > 0 ? 0.0 : 1.0,
                                );
                              }
                            },
                            icon: ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _controllerVideo!,
                              builder: (context, value, child) {
                                return Icon(
                                  value.volume > 0
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                  size: 28,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

    if (widget.videoPath == null && widget.localVideo == null) {
      setState(() {
        _isLoading = false; // Show loading indicator
      });
      return false; // No video source provided
    }

    if (widget.localVideo != null) {
      final file = await widget.localVideo?.file;
      if (file == null) return false;

      _controllerVideo = VideoPlayerController.file(file);
      await _controllerVideo!.initialize();
    } else if (widget.videoPath != null) {
      _controllerVideo = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoPath!),
      );
      await _controllerVideo!.initialize();
      _controllerVideo!.setLooping(false);
    }

    setState(() {
      _isLoading = false; // Show loading indicator
    });

    return true;
  }
}
