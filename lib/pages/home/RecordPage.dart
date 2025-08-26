import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glacier/components/Record/PreviewLayout.dart';
import 'package:glacier/components/Record/VerticalStackLayout.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/enums/ReactionVideoSegment.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReactionVideo.dart';
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
  double _uploadProgress = 0.0; // Track upload progress

  VideoPlayerController? _controllerVideo;
  bool isPlaying = false;
  bool isVideoFinished = false;
  CameraController? _controllerCamera;
  List<CameraDescription>? _cameras;
  bool showControls = true; // Track if controls are hidden

  ReactionResource? currentReaction;

  bool _isLoading = false; // Track loading state

  int _numberRefresh = 1;

  var uploadService = FirebaseStorageService();

  // Timer variables
  DateTime? _timerStartTime;
  Duration _delayVideo = Duration.zero;
  Duration _currentRecordingDuration = Duration.zero;
  Timer? _realtimeTimer;

  String layout = 'preview'; // Default layout is 'preview' | 'vertical'

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
                Text(
                  '${_uploadProgress > 1 ? '${(_uploadProgress * 100).toStringAsFixed(0)} %' : ''}  $progressMessage',
                  style: TextStyle(fontSize: 16),
                ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Video not available ${(widget.uuid)}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text('Back'),
                      ),
                    ],
                  ),
                );
              }
              return GestureDetector(
                onTap: () {
                  _handleControlsVisibility();
                },
                child: Stack(
                  children: [
                    if (layout == 'vertical')
                      VerticalStackLayout(
                        controllerVideo: _controllerVideo,
                        controllerCamera: _controllerCamera,
                        orientation: currentReaction?.videoOrientation,
                      )
                    else
                      PreviewLayout(
                        controllerVideo: _controllerVideo,
                        controllerCamera: _controllerCamera,
                        orientation: currentReaction?.videoOrientation,
                      ),

                    Visibility(
                      visible: showControls,
                      child: Positioned(
                        bottom: 20,
                        left: 50,
                        right: 50,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 5,
                          ),
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
                                      _realtimeTimer != null
                                          ? Stream.periodic(
                                            Duration(milliseconds: 100),
                                            (_) => DateTime.now(),
                                          )
                                          : null,
                                  builder: (context, snapshot) {
                                    final duration =
                                        _timerStartTime != null
                                            ? DateTime.now().difference(
                                              _timerStartTime!,
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
                                    _controllerVideo != null
                                        ? ValueListenableBuilder<
                                          VideoPlayerValue
                                        >(
                                          valueListenable: _controllerVideo!,
                                          builder: (
                                            context,
                                            videoValue,
                                            child,
                                          ) {
                                            return IconButton(
                                              style: ButtonStyle(
                                                padding:
                                                    WidgetStateProperty.all(
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
                                              onPressed: () async {
                                                if (isVideoFinished &&
                                                    !videoValue.isPlaying) {
                                                  _controllerVideo!.pause();
                                                  if (_controllerVideo!
                                                      .value
                                                      .isCompleted) {
                                                    _realtimeTimer?.cancel();
                                                    finishReation();
                                                  }
                                                } else {
                                                  if (videoValue.isPlaying) {
                                                    _controllerVideo!.pause();
                                                    _handleControlsVisibility();
                                                    setState(() {
                                                      isPlaying = false;
                                                    });
                                                  } else {
                                                    await _controllerVideo!
                                                        .seekTo(Duration.zero);
                                                    _controllerVideo!.play();
                                                    _delayVideo =
                                                        _currentRecordingDuration;

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
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              onPressed:
                                                  () =>
                                                      _numberRefresh > 0
                                                          ? _refreshReaction()
                                                          : null,
                                              icon: Icon(
                                                Icons.refresh_sharp,
                                                color:
                                                    _numberRefresh > 0
                                                        ? Colors.blue
                                                        : Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              _numberRefresh.toString(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    _numberRefresh > 0
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
    _realtimeTimer?.cancel();
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
          var uploadResult = await uploadService.uploadVideo(
            file.path,
            'reactions',
            '${currentReaction?.uuid}',
            onProgress: (progress, total) {
              if (total > 0 && progress.isFinite && total.isFinite) {
                _uploadProgress = (progress / total);
              }
            },
          );

          if (uploadResult == null) {
            ToastHelper.showError(
              context,
              description: 'Failed to upload reaction video. Please try again.',
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // var resultReaction = await convertReactionVideo(
          //   widget.uuid ?? '',
          //   'temp-reactions/${widget.uuid}.mp4',
          //   'reactions/${widget.uuid}.mp4',
          //   (progress, total) {
          //     _uploadProgress =
          //         (_uploadProgress + (progress / total) * 100) / 2;
          //   },
          //   {'resolution': '1080x1920'},
          // );

          // if (resultReaction == null) {
          //   ToastHelper.showError(
          //     context,
          //     description:
          //         'Failed to process the reaction video. Please try again.',
          //   );
          //   setState(() {
          //     _isLoading = false;
          //   });
          //   return;
          // }

          await updateReaction(currentReaction?.uuid, {
            'reaction_path': 'reactions/${currentReaction?.uuid}.mp4',
            'record_duration': _currentRecordingDuration.inSeconds,
            'delay_duration': _delayVideo.inSeconds,
            'layout': layout,
            'status': '1',
          });

          createReactionVideo({
            'reaction_id': currentReaction?.uuid,
            'reaction_path': 'reactions/${currentReaction?.uuid}.mp4',
            'video_duration': _currentRecordingDuration.inSeconds,
            'delay_duration': _delayVideo.inSeconds,
            'video_orientation': ReactionVideoOrientation.portrait.value,
            'segment': ReactionVideoSegment.reactionVideo.value,
            'video_name': file.name,
            'created_at': DateTime.now().toIso8601String(),
          });

          File(file.path).delete();
        } catch (e) {
          print('Error uploading reaction: $e');
        }

        setState(() {
          _isLoading = false; // Hide loading indicator
        });
        resetTimer();
        if (mounted) {
          Navigator.of(context).pop(true); // Close the current page
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

        _controllerCamera = CameraController(
          frontCamera,
          ResolutionPreset.veryHigh,
          enableAudio: true,
        );
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

  Future<void> _performRefresh() async {
    // Stop current recording if it's active
    if (_controllerCamera != null &&
        _controllerCamera!.value.isRecordingVideo) {
      try {
        await _controllerCamera!.stopVideoRecording();
      } catch (e) {
        print('Error stopping video recording: $e');
      }
    }

    if (_controllerVideo != null && _controllerVideo!.value.isInitialized) {
      _controllerVideo?.pause();
      _controllerVideo?.seekTo(Duration.zero);
    }

    setState(() {
      _realtimeTimer?.cancel();
      _timerStartTime = null;
      _delayVideo = Duration.zero;
      _currentRecordingDuration = Duration.zero;
      _numberRefresh--;
      isPlaying = false;
      isVideoFinished = false;
      countdown = 3;
      startCountdown = false;
    });

    try {
      _showCountdownDialog();
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _refreshReaction() async {
    if (_numberRefresh > 0) {
      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Restart Video Recording'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This will restart the video recording from the beginning.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Your current recording will be discarded and you will start fresh.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 10),
                Text(
                  'Refreshes remaining: $_numberRefresh',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );

      // If user confirmed, proceed with the refresh
      if (confirmed == true) {
        await _performRefresh();
      }
    }
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

                        DropdownButton<String>(
                          value: layout,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'preview',
                              child: Text('Preview Layout'),
                            ),
                            DropdownMenuItem(
                              value: 'vertical',
                              child: Text('Vertical Layout'),
                            ),
                          ],
                          style: TextStyle(fontSize: 16),

                          borderRadius: BorderRadius.circular(8),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              // Update the main widget's state
                              this.setState(() {
                                layout = newValue;
                              });
                              // Update the dialog's state
                              dialogState(() {});
                            }
                          },
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            'AND',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white30,
                            ),
                          ),
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
