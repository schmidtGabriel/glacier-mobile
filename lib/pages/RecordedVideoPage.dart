import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecordedVideoPage extends StatefulWidget {
  final String videoPath;

  const RecordedVideoPage({super.key, required this.videoPath});

  @override
  State<RecordedVideoPage> createState() => _RecordedVideoPageState();
}

class _RecordedVideoPageState extends State<RecordedVideoPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

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
                  return Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: Colors.black87,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      },
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(value.isPlaying ? 'Pause' : 'Play'),
                    ),
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
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onSend,
                      icon: Icon(Icons.send, color: Colors.white),
                      label: Text(
                        'Send',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideoPlayerFuture = _initializeVideoRecording();
  }

  void onSend() {
    // Implement your send logic here
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _initializeVideoRecording() async {
    await _controller.initialize();
    await _controller.play();
  }
}
