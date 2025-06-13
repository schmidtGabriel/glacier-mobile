import 'dart:io';

import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      body:
          _isLoading || _controller == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder(
                          future: _initializeVideoPlayerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                _controller != null) {
                              return SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              );
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_controller != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller!,
                        builder: (context, value, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _controller?.pause();
                                    Navigator.of(context).pop(true);
                                  },
                                  icon: Icon(
                                    Icons.replay,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Try again',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: _controller!,
                                builder: (context, value, child) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(15),
                                      elevation: 5,
                                    ),
                                    onPressed: () {
                                      if (value.isPlaying) {
                                        _controller?.pause();
                                      } else {
                                        _controller?.play();
                                      }
                                    },
                                    child: Icon(
                                      value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : onSend,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                              strokeWidth: 2.0,
                                            ),
                                          )
                                          : Text(
                                            'Send Record',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
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
          _isLoading = false;
          setState(() {});
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
