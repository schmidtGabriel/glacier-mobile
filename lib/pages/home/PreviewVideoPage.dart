import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class PreviewVideoPage extends StatefulWidget {
  final AssetEntity localVideo;
  final bool hasConfirmButton;

  const PreviewVideoPage({
    super.key,
    required this.localVideo,
    this.hasConfirmButton = true,
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
        : Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              TextButton(
                onPressed: () {
                  if (_controllerVideo != null) {
                    Navigator.of(context).pop(widget.localVideo);
                  }
                },
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controllerVideo!.value.aspectRatio,
                            child: VideoPlayer(_controllerVideo!),
                          ),
                        ),
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
                                        color: Colors.black.withOpacity(0.3),
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
                    ),
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

    final file = await widget.localVideo.file;
    if (file == null) return false;

    _controllerVideo = VideoPlayerController.file(file);
    await _controllerVideo!.initialize();

    setState(() {
      _isLoading = false; // Show loading indicator
    });

    setState(() {});
    return true;
  }
}
