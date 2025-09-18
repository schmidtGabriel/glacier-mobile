import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

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

  BetterPlayerController? betterPlayerController;

  bool _isLoading = false; // Track loading state
  bool showControls = true; // Track visibility of video controls

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
                  child: Text('Back'),
                ),
              ],
            ),
          ),
        )
        : Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.black,
            systemOverlayStyle: SystemUiOverlayStyle.light,
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
                      if (betterPlayerController
                              ?.videoPlayerController
                              ?.value
                              .initialized ==
                          true) {
                        Navigator.of(context).pop({
                          'video': widget.localVideo,
                          'duration':
                              betterPlayerController
                                  ?.videoPlayerController!
                                  .value
                                  .duration
                                  ?.inSeconds ??
                              0,
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
            valueListenable: ValueNotifier(!_isLoading),
            builder: (context, value, child) {
              return Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    Center(
                      child: BetterPlayer(controller: betterPlayerController!),
                    ),

                    // Video controls at the bottom
                    // Visibility(
                    //   visible: showControls,
                    //   child: Positioned(
                    //     bottom: 20,
                    //     left: 20,
                    //     right: 20,
                    //     child: Container(
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 10,
                    //         vertical: 5,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: Colors.black38,
                    //         borderRadius: BorderRadius.circular(40),
                    //       ),
                    //       child: Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //         children: [
                    //           IconButton(
                    //             onPressed: () {
                    //               _controllerVideo?.seekTo(Duration.zero);
                    //             },
                    //             icon: Icon(
                    //               Icons.replay,
                    //               color: Colors.white,
                    //               size: 28,
                    //             ),
                    //           ),
                    //           IconButton(
                    //             onPressed: () {
                    //               if (_controllerVideo != null) {
                    //                 if (_controllerVideo!.value.isPlaying) {
                    //                   _controllerVideo!.pause();
                    //                 } else {
                    //                   _controllerVideo!.play();
                    //                 }
                    //               }
                    //             },
                    //             icon:
                    //                 ValueListenableBuilder<VideoPlayerValue>(
                    //                   valueListenable: _controllerVideo!,
                    //                   builder: (context, value, child) {
                    //                     return Icon(
                    //                       value.isPlaying
                    //                           ? Icons.pause
                    //                           : Icons.play_arrow,
                    //                       color: Colors.white,
                    //                       size: 32,
                    //                     );
                    //                   },
                    //                 ),
                    //           ),

                    //           IconButton(
                    //             onPressed: () {
                    //               if (_controllerVideo != null) {
                    //                 final currentVolume =
                    //                     _controllerVideo!.value.volume;
                    //                 _controllerVideo!.setVolume(
                    //                   currentVolume > 0 ? 0.0 : 1.0,
                    //                 );
                    //               }
                    //             },
                    //             icon:
                    //                 ValueListenableBuilder<VideoPlayerValue>(
                    //                   valueListenable: _controllerVideo!,
                    //                   builder: (context, value, child) {
                    //                     return Icon(
                    //                       value.volume > 0
                    //                           ? Icons.volume_up
                    //                           : Icons.volume_off,
                    //                       color: Colors.white,
                    //                       size: 28,
                    //                     );
                    //                   },
                    //                 ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              );
            },
          ),
        );
  }

  @override
  void dispose() {
    betterPlayerController?.pause();
    betterPlayerController?.dispose();

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

      betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          aspectRatio: 9 / 16,

          autoDetectFullscreenDeviceOrientation: true,

          deviceOrientationsOnFullScreen: [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeRight,
          ],
          autoPlay: widget.hasConfirmButton ? false : true,
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
          fit: BoxFit.contain,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.file,
          file.path,
        ),
      );

      setState(() {});
    } else if (widget.videoPath != null) {
      betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          aspectRatio: 9 / 16,
          autoDetectFullscreenDeviceOrientation: true,

          deviceOrientationsOnFullScreen: [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeRight,
          ],
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
          autoPlay: widget.hasConfirmButton ? false : true,
          fit: BoxFit.contain,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          Uri.parse(widget.videoPath!).toString(),
        ),
      );

      setState(() {});
    }

    setState(() {
      _isLoading = false; // Show loading indicator
    });

    return true;
  }
}
