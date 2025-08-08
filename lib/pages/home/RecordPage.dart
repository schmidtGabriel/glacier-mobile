import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/getReaction.dart';
import 'package:glacier/services/reactions/updateReaction.dart';
import 'package:video_player/video_player.dart';

class RecordPage extends StatefulWidget {
  final String? uuid;

  const RecordPage({super.key, this.uuid});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int countdown = 3;
  bool startCountdown = false;
  bool showCamera = false;
  String progressMessage = 'Loading, please wait...';

  VideoPlayerController? _controllerVideo;
  bool isPlaying = false;
  bool isVideoFinished = false;
  CameraController? _controllerCamera;
  List<CameraDescription>? _cameras;
  bool showControls = true; // Track if controls are hidden

  ReactionResource? currentReaction;

  bool _isLoading = false; // Track loading state

  // Timer variables
  DateTime? _timerStartTime;
  Duration _delayVideo = Duration.zero;
  Duration _currentRecordingDuration = Duration.zero;
  Timer? _realtimeTimer;

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
                Text(progressMessage, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        )
        : Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: ValueNotifier(_isLoading),
            builder: (context, value, child) {
              if (!_isLoading &&
                  (_controllerVideo == null ||
                      !_controllerVideo!.value.isInitialized)) {
                return Center(
                  child: Text('Video not available ${(widget.uuid)}'),
                );
              }
              return GestureDetector(
                onTap: () {
                  _handleControlsVisibility();
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Video Player section (70% height)
                        Expanded(
                          flex: 6,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controllerVideo!.value.size.width,
                              height: _controllerVideo!.value.size.height,
                              child: VideoPlayer(_controllerVideo!),
                            ),
                          ),
                        ),

                        // Camera Preview section (30% height)
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            width: double.infinity,
                            child: CameraPreview(_controllerCamera!),
                          ),
                        ),
                      ],
                    ),

                    Visibility(
                      visible: showControls,
                      child: Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 20,
                          ),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Timer duration display
                              Expanded(
                                child: Center(
                                  child:
                                      _timerStartTime != null
                                          ? Text(
                                            '${_currentRecordingDuration.inSeconds}s',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : SizedBox(),
                                ),
                              ),
                              IconButton(
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all(
                                    EdgeInsets.all(2),
                                  ),
                                  backgroundColor: WidgetStateProperty.all(
                                    Colors.black54,
                                  ),
                                ),
                                icon: Icon(
                                  size: 20,
                                  isVideoFinished
                                      ? Icons.stop
                                      : !isVideoFinished && isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color:
                                      isVideoFinished
                                          ? Colors.red
                                          : Colors.white,
                                ),
                                onPressed: () {
                                  if (isVideoFinished && !isPlaying) {
                                    _controllerVideo!.pause();
                                    if (_controllerVideo!.value.isCompleted) {
                                      _realtimeTimer?.cancel();
                                      finishReation();
                                    }
                                  } else {
                                    if (isPlaying) {
                                      _controllerVideo!.pause();
                                      _handleControlsVisibility();
                                      setState(() {
                                        isPlaying = false;
                                      });
                                    } else {
                                      _controllerVideo!.play();
                                      _delayVideo = _currentRecordingDuration;

                                      _handleControlsVisibility();

                                      setState(() {
                                        isPlaying = true;
                                      });

                                      print(
                                        'Timer stopped. Duration: ${_delayVideo.inSeconds} seconds',
                                      );
                                    }
                                  }
                                },
                              ),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
  }

  @override
  void dispose() {
    _controllerVideo?.dispose();
    _controllerCamera?.dispose();
    _realtimeTimer?.cancel();
    resetTimer();
    super.dispose();
  }

  void finishReation() {
    setState(() {
      progressMessage = 'Submitting reaction...';
      _isLoading = true; // Show loading indicator
    });
    // This function can be used to handle any finalization logic after the reaction is completed
    print('Reaction finished for UUID: ${widget.uuid}');
    print('Video delay: ${_delayVideo.inSeconds} seconds');
    print(
      'Current recording duration: ${_currentRecordingDuration.inSeconds} seconds',
    );

    if (_controllerCamera!.value.isRecordingVideo) {
      _controllerCamera!.stopVideoRecording().then((file) async {
        // Handle the recorded video file
        print('Video recorded: ${file.path}');
        print('Video name: ${file.name}');

        try {
          var service = FirebaseStorageService();
          await service.uploadReaction(
            file.path,
            '${currentReaction?.uuid}',
            onProgress: (progress, total) {
              // print('Upload progress: $progress / $total');
            },
          );

          await updateReaction({
            'uuid': currentReaction?.uuid,
            'selfie_video': 'reactions/${currentReaction?.uuid}.mp4',
            'record_duration': _currentRecordingDuration.inSeconds,
            'delay_duration': _delayVideo.inSeconds,
            'status': '1',
          });
        } catch (e) {
          print('Error uploading reaction: $e');
        }

        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        resetTimer();
        if (mounted) {
          Navigator.pop(context); // Close the current page
        } else {
          print('Navigator context is not mounted, cannot navigate.');
        }
      });
    }
    // You can add any additional logic here, such as updating the UI or navigating to another
  }

  @override
  void initState() {
    super.initState();
    _loadReactionByUuid();
  }

  void resetTimer() {
    _realtimeTimer?.cancel();
    _timerStartTime = null;
    _delayVideo = Duration.zero;
    _currentRecordingDuration = Duration.zero;
  }

  void _handleControlsVisibility() {
    setState(() {
      showControls = true;
    });
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        showControls = false;
      });
    });
  }

  Future<void> _initializeCamera() async {
    try {
      print('Initializing camera...');
      _cameras = await availableCameras();
      print('Available cameras: $_cameras');
      if (_cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first, // fallback to first if no front cam
        );

        _controllerCamera = CameraController(frontCamera, ResolutionPreset.max);
        await _controllerCamera!.initialize();
      } else {
        print('No cameras found');
      }
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<bool> _initializeVideo() async {
    if (currentReaction == null) {
      print('No reaction data available');
      return false;
    }
    final videoUrl = currentReaction?.videoUrl.toString().trim();
    if (videoUrl == null || videoUrl.isEmpty) {
      print('Invalid or missing video URL');
      return false;
    }

    if (_controllerVideo != null) {
      await _controllerVideo!.dispose();
    }

    _controllerVideo = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      viewType: VideoViewType.textureView,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    await _controllerVideo!.initialize();
    _controllerVideo!.setLooping(false);

    _controllerVideo!.addListener(() async {
      final bool isFinished =
          _controllerVideo!.value.position >= _controllerVideo!.value.duration;

      if (isFinished && !_controllerVideo!.value.isPlaying) {
        setState(() {
          isPlaying = false;
          isVideoFinished = true;
          _handleControlsVisibility();
        });
      }
    });

    _showCountdownDialog();

    setState(() {});
    return true;
  }

  // Load reaction by UUID
  Future<void> _loadReactionByUuid() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    currentReaction = await getReaction(widget.uuid ?? '');

    if (currentReaction == null) {
      print('No reaction found for UUID: ${widget.uuid}');
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }

    _initializeCamera();
    await _initializeVideo();

    setState(() {
      _isLoading = false; // Show loading indicator
    });
  }

  // Show countdown dialog
  void _showCountdownDialog() {
    late StateSetter dialogState;
    late BuildContext dialogContext;

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
                            // Reset timer for new recording cycle
                            resetTimer();

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
    Navigator.pop(dialogContext); // Close the dialog

    if (_controllerCamera != null && _controllerCamera!.value.isInitialized) {
      try {
        await _controllerCamera!.startVideoRecording();

        _startRealtimeTimer();
      } catch (e) {
        print('Error starting video recording: $e');
      }
    } else {
      print('Camera controller is not initialized or null');
    }
  }

  void _startRealtimeTimer() {
    _timerStartTime = DateTime.now();
    _realtimeTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentRecordingDuration = DateTime.now().difference(_timerStartTime!);
      });
      // print('Timer started at: $_timerStartTime');
    });
  }
}
