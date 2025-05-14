import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:glacier/components/CameraPreviewWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class RecordPage extends StatefulWidget {
  final String? uuid;

  const RecordPage({super.key, this.uuid});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool isRecording = false;
  int countdown = 3;
  bool startCountdown = false;
  bool showCamera = false;

  String? videoPath;

  VideoPlayerController? _controllerRecording;
  VideoPlayerController? _controllerVideo;

  Map<String, dynamic>? currentReaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controllerVideo != null && _controllerVideo!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controllerVideo!.value.aspectRatio,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controllerVideo!.value.size.width,
                    height: _controllerVideo!.value.size.height,
                    child: VideoPlayer(_controllerVideo!),
                  ),
                ),
              ),
            )
          else
            Center(child: CircularProgressIndicator()),

          // Camera preview in bottom right
          Visibility(
            visible: showCamera,
            child: Positioned(
              bottom: 20,
              right: 20,
              child: CameraPreviewWidget(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadReactionByUuid();
  }

  Future<bool> _initializeVideo() async {
    if (currentReaction == null) {
      print('No reaction data available');
      return false;
    }
    // 'https://cdn.pixabay.com/video/2023/07/12/171272-845168271_large.mp4'
    final videoUrl = currentReaction?['url']?.toString().trim();
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

    _controllerVideo!.addListener(() async {
      final bool isFinished =
          _controllerVideo!.value.position >= _controllerVideo!.value.duration;
      if (isFinished && !_controllerVideo!.value.isPlaying) {
        String res = await FlutterScreenRecording.stopRecordScreen;

        setState(() {
          isRecording = false;
          videoPath = res;
          _showRecoredVideoDialog();
        });
      }
    });
    _showCountdownDialog();

    setState(() {});
    return true;
  }

  // Initialize video recording
  Future<void> _initializeVideoRecording() async {
    print('Video path: $videoPath');
    _controllerRecording?.dispose();
    _controllerRecording = VideoPlayerController.file(File(videoPath!));
    await _controllerRecording!.initialize();
    _controllerRecording!.play();
  }

  // Load reaction by UUID
  Future<bool> _loadReactionByUuid() async {
    final prefs = await SharedPreferences.getInstance();

    final reactionsString = prefs.getString('reactions');
    if (reactionsString == null) {
      return false;
    }
    final List<dynamic> reactionsList = jsonDecode(reactionsString);

    final reaction = reactionsList.firstWhere(
      (item) => item['uuid'] == widget.uuid,
      orElse: () => null,
    );
    if (reaction != null) {
      setState(() {
        currentReaction = Map<String, dynamic>.from(reaction);
      });
      await _initializeVideo();

      return true;
    }
    return false; // Return false if no reaction is found
  }

  // Show countdown dialog
  void _showCountdownDialog() {
    late StateSetter dialogState;

    if (isRecording) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogState = setState;
            return AlertDialog(
              title: Text('Recording Countdown'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!startCountdown)
                    Column(
                      children: [
                        Text(
                          'Click and get ready!',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              startCountdown = true;
                            });
                            dialogState(() {});
                            _startCountdown(dialogState);
                          },
                          child: Text('Start Recording'),
                        ),
                      ],
                    ),

                  if (startCountdown)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Recording will start in...'),
                          SizedBox(height: 20),
                          Text('$countdown', style: TextStyle(fontSize: 48)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show recorded video dialog
  void _showRecoredVideoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder(
                  future: _initializeVideoRecording(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Center(
                        child: AspectRatio(
                          aspectRatio: _controllerRecording!.value.aspectRatio,
                          child: VideoPlayer(_controllerRecording!),
                        ),
                      );
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _controllerRecording!.value.isPlaying
                            ? _controllerRecording?.pause()
                            : _controllerRecording?.play();
                      },
                      icon: Icon(
                        _controllerRecording!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        _controllerRecording!.value.isPlaying
                            ? 'Pause'
                            : 'Play',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _controllerRecording?.pause();
                        Navigator.of(context).pop();
                        startCountdown = false;
                        countdown = 3;
                        _showCountdownDialog();
                      },
                      icon: Icon(Icons.replay, color: Colors.white),
                      label: Text(
                        'Rewatch',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _controllerRecording?.pause();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'Send',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Start countdown and recording
  void _startCountdown(StateSetter dialogState) async {
    for (int i = countdown - 1; i >= 0; i--) {
      await Future.delayed(Duration(seconds: 1));
      dialogState(() => countdown = i);
    }

    setState(() {
      isRecording = true;
      showCamera = true;
    });

    Navigator.of(context).pop();

    await FlutterScreenRecording.startRecordScreen(
      currentReaction?['title'] ?? 'Video Title',
    );
    _controllerVideo!.play(); // Start video without reinitializing
  }
}
