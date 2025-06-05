import 'dart:io';

import 'package:flutter/material.dart';
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
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _controller.pause();
                        Navigator.of(context).pop(true);
                      },
                      icon: Icon(Icons.replay, color: Colors.white),
                      label: Text(
                        'Try again',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                      ),
                    ),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(10),
                          ),
                          onPressed: () {
                            value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          },
                          child: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 30,
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : onSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2.0,
                                ),
                              )
                              : Text(
                                'Send Record',
                                style: TextStyle(color: Colors.white),
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
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideoPlayerFuture = _initializeVideoRecording();
  }

  Future<void> onSend() async {
    var service = FirebaseStorageService();
    _isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    final selfiePath = prefs.getString('selfiePath');

    // Implement your send logic here
    service
        .uploadRecord(widget.videoPath, selfiePath!)
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
    await _controller.initialize();
    await _controller.play();
  }
}
