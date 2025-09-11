import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/Record/PreviewLayout.dart';
import 'package:glacier/components/Record/VerticalStackLayout.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';

class RecordingStep extends StatelessWidget {
  final BetterPlayerController? betterPlayerController;
  final CameraController? cameraController;
  final ReactionVideoOrientation? orientation;
  final String layout;
  final bool isLoading;
  final bool showControls;
  final Timer? realtimeTimer;
  final DateTime? timerStartTime;
  final bool isPlaying;
  final bool isVideoFinished;
  final int numberRefresh;
  final String? uuid;
  final VoidCallback onControlsVisibility;
  final VoidCallback onFinishReaction;
  final VoidCallback? onRefreshReaction;
  final Function() onBackPressed;

  final Function(bool) onPlayingStateChanged;
  final Function(Duration) onDelayVideoChanged;

  const RecordingStep({
    super.key,
    required this.betterPlayerController,
    required this.cameraController,
    required this.orientation,
    required this.layout,
    required this.isLoading,
    required this.showControls,
    required this.realtimeTimer,
    required this.timerStartTime,
    required this.isPlaying,
    required this.isVideoFinished,
    required this.numberRefresh,
    required this.uuid,
    required this.onControlsVisibility,
    required this.onFinishReaction,
    required this.onRefreshReaction,
    required this.onBackPressed,
    required this.onPlayingStateChanged,
    required this.onDelayVideoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ValueNotifier(isLoading),
      builder: (context, value, child) {
        return GestureDetector(
          onTap: onControlsVisibility,
          child: Stack(
            children: [
              if (layout == 'vertical')
                VerticalStackLayout(
                  controllerVideo: betterPlayerController,
                  controllerCamera: cameraController,
                  orientation: orientation,
                )
              else
                PreviewLayout(
                  controllerVideo: betterPlayerController,
                  controllerCamera: cameraController,
                  orientation: orientation,
                ),

              Visibility(
                visible: showControls,
                child: Positioned(
                  bottom: 20,
                  left: 50,
                  right: 50,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left side - Timer display
                        Expanded(
                          flex: 1,
                          child: StreamBuilder<DateTime>(
                            stream:
                                realtimeTimer != null
                                    ? Stream.periodic(
                                      Duration(milliseconds: 100),
                                      (_) => DateTime.now(),
                                    )
                                    : null,
                            builder: (context, snapshot) {
                              final duration =
                                  timerStartTime != null
                                      ? DateTime.now().difference(
                                        timerStartTime!,
                                      )
                                      : Duration.zero;
                              return Text(
                                '${duration.inSeconds.toString()}s',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),

                        // Center - Play/Pause/Stop button
                        Expanded(
                          flex: 1,
                          child:
                              betterPlayerController != null
                                  ? ValueListenableBuilder<VideoPlayerValue>(
                                    valueListenable:
                                        betterPlayerController!
                                            .videoPlayerController!,
                                    builder: (context, videoValue, child) {
                                      return IconButton(
                                        style: ButtonStyle(
                                          padding: WidgetStateProperty.all(
                                            EdgeInsets.all(2),
                                          ),
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                Colors.black54,
                                              ),
                                        ),
                                        icon: Icon(
                                          size: 20,
                                          isVideoFinished
                                              ? Icons.stop
                                              : videoValue.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color:
                                              isVideoFinished
                                                  ? Colors.red
                                                  : Colors.white,
                                        ),
                                        onPressed:
                                            () => _handlePlayPause(videoValue),
                                      );
                                    },
                                  )
                                  : SizedBox(),
                        ),

                        // Right side - Refresh button or empty space
                        Expanded(
                          flex: 1,
                          child:
                              isVideoFinished && !isPlaying
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        onPressed:
                                            () =>
                                                numberRefresh > 0 &&
                                                        onRefreshReaction !=
                                                            null
                                                    ? onRefreshReaction!()
                                                    : null,
                                        icon: Icon(
                                          Icons.refresh_sharp,
                                          color:
                                              numberRefresh > 0
                                                  ? Colors.blue
                                                  : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        numberRefresh.toString(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              numberRefresh > 0
                                                  ? Colors.blue
                                                  : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  )
                                  : SizedBox(), // Empty space when not showing refresh
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePlayPause(VideoPlayerValue videoValue) async {
    if (isVideoFinished && !videoValue.isPlaying) {
      betterPlayerController!.pause();
      onFinishReaction();
    } else {
      if (videoValue.isPlaying) {
        betterPlayerController!.pause();
        onControlsVisibility();
        onPlayingStateChanged(false);
      } else {
        await betterPlayerController!.seekTo(Duration.zero);
        betterPlayerController!.play();

        // Calculate delay based on current recording duration
        final currentTime = DateTime.now();
        final recordingDuration =
            timerStartTime != null
                ? currentTime.difference(timerStartTime!)
                : Duration.zero;
        onDelayVideoChanged(recordingDuration);

        onControlsVisibility();
        onPlayingStateChanged(true);
      }
    }
  }
}
