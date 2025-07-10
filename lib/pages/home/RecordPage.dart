import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:glacier/components/CameraPreviewWidget.dart';
import 'package:glacier/services/reactions/getReaction.dart';
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
  bool isVideoFinished = false; // Add this state variable
  String videoName = '';

  String? videoPath;

  VideoPlayerController? _controllerVideo;

  Map<String, dynamic>? currentReaction;

  final double _uploadProgress = 0.0; // Track upload progress
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
          body: ValueListenableBuilder<bool>(
            valueListenable: ValueNotifier(_isLoading),
            builder: (context, value, child) {
              if (_controllerVideo == null ||
                  !_controllerVideo!.value.isInitialized) {
                return Center(
                  child: Text('Video not available ${(widget.uuid)}'),
                );
              }
              return Column(
                children: [
                  // Video Player section (70% height)
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Video Player
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controllerVideo!.value.size.width,
                                height: _controllerVideo!.value.size.height,
                                child: VideoPlayer(_controllerVideo!),
                              ),
                            ),
                          ),

                          // Play button overlay if video is paused
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
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Camera Preview section (30% height)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      width: double.infinity,
                      child: CameraPreviewWidget(isFinished: isVideoFinished),
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
    if (isRecording) {
      FlutterScreenRecording.stopRecordScreen;
    }
    super.dispose();
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

    // Reset the video finished state when initializing a new video
    setState(() {
      isVideoFinished = false;
    });

    _controllerVideo = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await _controllerVideo!.initialize();
    _controllerVideo!.setLooping(false);

    _controllerVideo!.addListener(() async {
      final bool isFinished =
          _controllerVideo!.value.position >= _controllerVideo!.value.duration;

      if (isFinished && !_controllerVideo!.value.isPlaying) {
        // Update the state to trigger CameraPreviewWidget's didUpdateWidget
        setState(() {
          isVideoFinished = true;
        });

        videoPath = await FlutterScreenRecording.stopRecordScreen;

        //* Code below works to handle the video editing on Firebase Functions
        // setState(() {
        //   _isLoading = true; // Show loading indicator
        // });

        // Wait a moment for the camera recording to finish and be saved
        // await Future.delayed(Duration(seconds: 2));

        // var value = await sendReactionVideo(videoUrl, (progress, total) {
        //   // Handle progress updates if needed
        //   setState(() {
        //     print('Upload progress: $progress / $total');
        //     _uploadProgress = progress / total;

        //     if (progress == total) {
        //       print('Upload completed');
        //       _isLoading = false;
        //     }
        //   });
        // });

        // if (value == null || value.isEmpty) {
        //   print('Failed to send reaction video');
        //   setState(() {
        //     _isLoading = false; // Hide loading indicator
        //   });
        // }
        //* Code above works to handle the video editing on Firebase Functions
        print('Video recording finished $videoPath');
        setState(() {
          isRecording = false;
          Navigator.of(context, rootNavigator: true)
              .pushNamed(
                '/recorded-video',
                arguments: {
                  'videoPath': videoPath,
                  'videoName': videoName,
                  'uuid': widget.uuid,
                },
              )
              .then(
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
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    currentReaction = await getReaction(widget.uuid ?? '');

    if (currentReaction == null) {
      print('No reaction found for UUID: ${widget.uuid}');
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      return false;
    }

    await _initializeVideo();

    setState(() {
      _isLoading = false; // Show loading indicator
    });

    return true;
  }

  // Show countdown dialog
  void _showCountdownDialog() {
    late StateSetter dialogState;
    late BuildContext dialogContext;

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
            dialogContext = context;
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
                            _startCountdown(dialogState, dialogContext);
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
  void _startCountdown(
    StateSetter dialogState,
    BuildContext dialogContext,
  ) async {
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
    Navigator.pop(dialogContext); // Close the dialog
    Future.delayed(Duration(seconds: 3));
    FlutterScreenRecording.startRecordScreenAndAudio(
          currentReaction != null ? "${widget.uuid}.mp4" : 'Video Title',
        )
        .then((result) {
          videoName =
              currentReaction != null ? "${widget.uuid}.mp4" : 'Video Title';
        })
        .catchError((error) {
          print('Error starting screen recording');
          setState(() {
            isRecording = false;
          });
          FlutterScreenRecording.stopRecordScreen;
        });
  }
}
