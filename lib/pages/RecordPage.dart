import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:glacier/components/CameraPreviewWidget.dart';
import 'package:glacier/pages/RecordedVideoPage.dart';
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
  String videoName = '';

  String? videoPath;

  VideoPlayerController? _controllerVideo;

  Map<String, dynamic>? currentReaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controllerVideo != null &&
                _controllerVideo!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controllerVideo!.value.aspectRatio,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
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

            if (_controllerVideo != null &&
                _controllerVideo!.value.isInitialized)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controllerVideo!,
                builder: (context, value, child) {
                  if (value.isPlaying) return SizedBox.shrink();
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
                },
              ),

            // Camera preview in bottom right
            Visibility(
              visible: showCamera,
              child: Positioned(
                bottom: 20,
                right: 20,
                child: CameraPreviewWidget(
                  isFinished:
                      _controllerVideo!.value.position >=
                      _controllerVideo!.value.duration,
                ),
              ),
            ),
          ],
        ),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RecordedVideoPage(
                    videoPath: res,
                    videoName: videoName,
                    uuid: widget.uuid,
                  ),
            ),
          ).then(
            (value) => {
              if (value == true)
                {
                  setState(() {
                    showCamera = false;
                    countdown = 3;
                    startCountdown = false;
                  }),
                  _initializeVideo(),
                },
            },
          );
        });
      }
    });
    _showCountdownDialog();

    setState(() {});
    return true;
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

  // Start countdown and recording
  void _startCountdown(StateSetter dialogState) async {
    for (int i = countdown - 1; i >= 0; i--) {
      await Future.delayed(Duration(seconds: 1));
      dialogState(() => countdown = i);
      setState(() {
        if (countdown == 1) {
          showCamera = true;
        }
      });
    }

    setState(() {
      isRecording = true;
    });

    Navigator.of(context).pop();

    await FlutterScreenRecording.startRecordScreenAndAudio(
      currentReaction != null
          ? "${currentReaction?['title']}-${currentReaction?['user']}"
              .replaceAll(' ', '-')
              .trim()
          : 'Video Title',
    );

    videoName =
        currentReaction != null
            ? "${currentReaction?['title']}-${currentReaction?['user']}.mp4"
                .replaceAll(' ', '-')
                .trim()
            : 'Video Title';
  }
}
