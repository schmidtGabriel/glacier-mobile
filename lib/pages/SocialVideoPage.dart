import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:glacier/components/CameraPreviewWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class SocialVideoPage extends StatefulWidget {
  final String? uuid;

  const SocialVideoPage({super.key, this.uuid});

  @override
  State<SocialVideoPage> createState() => _SocialVideoPageState();
}

class _SocialVideoPageState extends State<SocialVideoPage> {
  bool isRecording = false;

  int countdown = 3;
  bool startCountdown = false;
  bool showCamera = false;

  String? videoPath;
  String? selfiePath;

  VideoPlayerController? _controllerVideo;

  Map<String, dynamic>? currentReaction;

  final videoEmbed =
      'https://www.tiktok.com/@kbsviews/video/7498697625936366891';

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height + 100;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          if (currentReaction != null && videoPath != null)
            SizedBox.expand(
              child: HtmlWidget(
                '''
                        <iframe width="1" height="2"
                          src="$videoEmbed"
                          title=""
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                          referrerpolicy="strict-origin-when-cross-origin"
                          allowfullscreen></iframe>
                      ''',
                customStylesBuilder: (element) {
                  return {
                    'background-color': 'black',
                    'width': '${width}px',
                    'height': '${height}px',
                  };
                },
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
              child: CameraPreviewWidget(isFinished: !isRecording),
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
        videoPath = currentReaction?['url']?.toString().trim();
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
    }
    setState(() {
      isRecording = true;
      showCamera = true;
    });

    Navigator.of(context).pop();

    await FlutterScreenRecording.startRecordScreenAndAudio(
      currentReaction?['title'] ?? 'Video Title',
    );
  }
}
