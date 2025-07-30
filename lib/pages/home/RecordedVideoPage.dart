import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glacier/helpers/editReactionVideo.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/updateReaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:video_player/video_player.dart';

class RecordedVideoPage extends StatefulWidget {
  final String videoPath;
  final String? uuid;
  final String? videoName;

  const RecordedVideoPage({
    super.key,
    required this.videoPath,
    required this.videoName,
    required this.uuid,
  });

  @override
  State<RecordedVideoPage> createState() => _RecordedVideoPageState();
}

class _RecordedVideoPageState extends State<RecordedVideoPage> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  String? editedVideo;
  String? selfiePath;
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading || _controller == null
        ? Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Processing your video...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        )
        : Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 4, // Give more space to video
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                          8,
                          8,
                          8,
                          4,
                        ), // Reduced margins
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            child: FutureBuilder(
                              future: _initializeVideoPlayerFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    _controller != null) {
                                  return Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: SizedBox(
                                            width:
                                                _controller!.value.size.width,
                                            height:
                                                _controller!.value.size.height,
                                            child: VideoPlayer(_controller!),
                                          ),
                                        ),
                                      ),
                                      // Video progress indicator
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: SizedBox(
                                          height: 4,
                                          child: ValueListenableBuilder<
                                            VideoPlayerValue
                                          >(
                                            valueListenable: _controller!,
                                            builder: (context, value, child) {
                                              return LinearProgressIndicator(
                                                value:
                                                    value
                                                                .duration
                                                                .inMilliseconds >
                                                            0
                                                        ? value
                                                                .position
                                                                .inMilliseconds /
                                                            value
                                                                .duration
                                                                .inMilliseconds
                                                        : 0.0,
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.3),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.blue.shade600),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Loading video...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_controller != null)
                      Card(
                        margin: EdgeInsets.fromLTRB(
                          8,
                          4,
                          8,
                          8,
                        ), // Reduced margins
                        child: Padding(
                          padding: const EdgeInsets.all(16), // Reduced padding
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Video duration info - more compact
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: _controller!,
                                builder: (context, value, child) {
                                  final position = value.position;
                                  final duration = value.duration;

                                  return Text(
                                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13, // Slightly smaller
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16), // Reduced spacing
                              // Control buttons
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _controller?.pause();
                                        Navigator.of(context).pop(true);
                                      },
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.white,
                                        size: 18, // Smaller icon
                                      ),
                                      label: Text(
                                        'Try Again',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14, // Smaller text
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade600,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12, // Reduced padding
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Play/Pause button
                                  ValueListenableBuilder<VideoPlayerValue>(
                                    valueListenable: _controller!,
                                    builder: (context, value, child) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade600,
                                            shape: CircleBorder(),
                                            padding: EdgeInsets.all(
                                              14,
                                            ), // Slightly smaller
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            if (value.isPlaying) {
                                              _controller?.pause();
                                            } else {
                                              _controller?.play();
                                            }
                                          },
                                          child: Icon(
                                            value.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 26, // Slightly smaller
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : () {
                                                HapticFeedback.mediumImpact();
                                                onSend();
                                              },
                                      icon:
                                          _isLoading
                                              ? SizedBox(
                                                width: 16, // Smaller loader
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                  strokeWidth: 2.0,
                                                ),
                                              )
                                              : Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 18, // Smaller icon
                                              ),
                                      label: Text(
                                        _isLoading ? 'Sending...' : 'Send',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14, // Smaller text
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _isLoading
                                                ? Colors.grey.shade400
                                                : Colors.green.shade600,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12, // Reduced padding
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                Positioned(
                  top: 8,
                  left: 8,
                  child: BackButton(
                    onPressed: () {
                      _controller?.pause();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
  }

  @override
  void dispose() {
    _isLoading = false;
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  handleVideoInit() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();

      // Retry logic to wait for selfiePath to be available
      String? tempSelfiePath;
      int retryCount = 0;
      const maxRetries = 10;

      while (retryCount < maxRetries) {
        tempSelfiePath = prefs.getString('selfiePath');

        if (tempSelfiePath != null && tempSelfiePath.isNotEmpty) {
          // Check if the file actually exists
          final file = File(tempSelfiePath);
          if (await file.exists()) {
            selfiePath = tempSelfiePath;
            break;
          }
        }

        print(
          'Waiting for selfie file... Attempt ${retryCount + 1}/$maxRetries',
        );
        await Future.delayed(Duration(milliseconds: 500));
        retryCount++;
      }

      print('Retrieved selfiePath from SharedPreferences: $selfiePath');
      print('Widget videoPath: ${widget.videoPath}');

      if (selfiePath == null || selfiePath!.isEmpty) {
        toastification.show(
          title: Text('Selfie not found'),
          description: Text(
            'The selfie recording was not found. Please try recording again.',
          ),
          autoCloseDuration: const Duration(seconds: 5),
          type: ToastificationType.error,
          alignment: Alignment.bottomCenter,
        );
        Navigator.of(context).pop();
        return;
      }
      print('Selfie path is valid: $selfiePath');
      editedVideo = await processVideo(
        widget.videoPath,
        selfiePath,
        widget.uuid!,
      );
      if (editedVideo != null) {
        _controller = VideoPlayerController.file(File(editedVideo!));
        _initializeVideoPlayerFuture = _initializeVideoRecording();
        prefs.remove('selfiePath');
        prefs.remove('selfieName');
        // File(selfiePath!).delete();
      } else {
        // Show error if video processing failed
        if (mounted) {
          toastification.show(
            title: Text('Video processing failed'),
            description: Text(
              'Unable to process the recorded video. Please try again.',
            ),
            autoCloseDuration: const Duration(seconds: 5),
            type: ToastificationType.error,
            alignment: Alignment.bottomCenter,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in handleVideoInit: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        toastification.show(
          title: Text('Video initialization failed'),
          description: Text('Error: ${e.toString()}'),
          autoCloseDuration: const Duration(seconds: 5),
          type: ToastificationType.error,
          alignment: Alignment.bottomCenter,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    handleVideoInit();
  }

  Future<void> onSend() async {
    if (editedVideo == null) {
      toastification.show(
        title: Text('Video processing failed'),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    var service = FirebaseStorageService();
    final prefs = await SharedPreferences.getInstance();

    // Implement your send logic here
    service
        .uploadRecord(editedVideo!, selfiePath!)
        .then((value) async {
          print('Video uploaded successfully: $value');

          await updateReaction(widget.videoName, widget.uuid);
          toastification.show(
            title: Text('Video uploaded successfully'),
            autoCloseDuration: const Duration(seconds: 5),
            type: ToastificationType.success,
            alignment: Alignment.bottomCenter,
          );
          prefs.remove('selfiePath');
          prefs.remove('selfieName');
          prefs.remove('videoPath');

          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).popUntil((route) => route.isFirst);
        })
        .catchError((error) {
          print('Error uploading video: $error');
          toastification.show(
            title: Text('Error uploading video'),
            autoCloseDuration: const Duration(seconds: 5),
            type: ToastificationType.error,
            alignment: Alignment.bottomCenter,
          );
          _isLoading = false;
          setState(() {});
        });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initializeVideoRecording() async {
    if (_controller != null) {
      await _controller!.initialize();

      // Add listener to detect when video finishes
      _controller!.addListener(() {
        if (_controller!.value.position >= _controller!.value.duration) {
          // Video has finished, pause it to reset the play button
          _controller!.pause();
          _controller!.seekTo(Duration.zero);
        }
      });

      await _controller!.play();
    }
  }
}
