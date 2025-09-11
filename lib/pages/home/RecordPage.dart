import 'dart:async';
import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glacier/components/Record/steps/CameraReadyStep.dart';
import 'package:glacier/components/Record/steps/CountdownStep.dart';
import 'package:glacier/components/Record/steps/RecordingStep.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:glacier/enums/ReactionVideoSegment.dart';
import 'package:glacier/helpers/ToastHelper.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/services/FirebaseStorageService.dart';
import 'package:glacier/services/reactions/createReactionVideo.dart';
import 'package:glacier/services/reactions/getReaction.dart';
import 'package:glacier/services/reactions/updateReaction.dart';

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

  BetterPlayerController? _controllerVideo;
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

  // Step tracking: 1 = camera ready, 2 = countdown, 3 = recording
  int currentStep = 1;

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
        : Scaffold(body: _buildCurrentStep());
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

  Widget _buildCurrentStep() {
    // Check for video availability first
    if (!_isLoading && (_controllerVideo == null)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Video not available ${widget.uuid ?? ''}'),
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

    switch (currentStep) {
      case 1:
        return CameraReadyStep(
          cameraController: _controllerCamera,
          layout: layout,
          onLayoutChanged: (newLayout) {
            setState(() {
              layout = newLayout;
            });
          },
          onReadyPressed: () {
            setState(() {
              currentStep = 2;
              countdown = 3;
              startCountdown = true;
            });
            _startCountdown();
          },
        );
      case 2:
        return CountdownStep(countdown: countdown);
      case 3:
        return RecordingStep(
          betterPlayerController: _controllerVideo,
          cameraController: _controllerCamera,
          orientation: currentReaction?.videoOrientation,
          layout: layout,
          isLoading: _isLoading,
          showControls: showControls,
          realtimeTimer: _realtimeTimer,
          timerStartTime: _timerStartTime,
          isPlaying: isPlaying,
          isVideoFinished: isVideoFinished,
          numberRefresh: _numberRefresh,
          uuid: widget.uuid,
          onControlsVisibility: _handleControlsVisibility,
          onFinishReaction: () {
            _realtimeTimer?.cancel();
            finishReation();
          },
          onRefreshReaction: _numberRefresh > 0 ? _refreshReaction : null,
          onBackPressed: () {
            Navigator.of(context).pop(false);
          },
          onPlayingStateChanged: (playing) {
            setState(() {
              isPlaying = playing;
            });
          },
          onDelayVideoChanged: (delay) {
            setState(() {
              _delayVideo = delay;
            });
            print('Timer stopped. Duration: ${_delayVideo.inSeconds} seconds');
          },
        );
      default:
        return CameraReadyStep(
          cameraController: _controllerCamera,
          layout: layout,
          onLayoutChanged: (newLayout) {
            setState(() {
              layout = newLayout;
            });
          },
          onReadyPressed: () {
            setState(() {
              currentStep = 2;
              countdown = 3;
              startCountdown = true;
            });
            _startCountdown();
          },
        );
    }
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
        setState(() {});
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
      _controllerVideo!.dispose();
    }

    _controllerVideo = BetterPlayerController(
      BetterPlayerConfiguration(
        aspectRatio: 9 / 16,

        autoDetectFullscreenDeviceOrientation: true,

        deviceOrientationsOnFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Uri.parse(videoUrl).toString(),
      ),
    );

    _controllerVideo!.videoPlayerController!.addListener(() async {
      final bool isFinished =
          _controllerVideo!.videoPlayerController!.value.position >=
          _controllerVideo!.videoPlayerController!.value.duration!;

      if (isFinished &&
          !_controllerVideo!.videoPlayerController!.value.isPlaying) {
        setState(() {
          isPlaying = false;
          isVideoFinished = true;
          _handleControlsVisibility();
        });
      }
    });

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

    if (_controllerVideo != null &&
        _controllerVideo!.videoPlayerController!.value.initialized) {
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
      currentStep = 1; // Go back to step 1
    });
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

  // Start countdown and recording
  void _startCountdown() async {
    for (int i = countdown; i > 0; i--) {
      if (mounted) {
        setState(() {
          countdown = i;
        });
      }
      await Future.delayed(Duration(seconds: 1));
    }

    // Move to step 3 (recording screen)
    if (mounted) {
      setState(() {
        currentStep = 3;
        showCamera = true;
      });
    }

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
