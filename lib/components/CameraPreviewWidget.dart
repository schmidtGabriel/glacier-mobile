import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraPreviewWidget extends StatefulWidget {
  final bool isFinished;

  const CameraPreviewWidget({super.key, required this.isFinished});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 150,
        height: 220,
        child: CameraPreview(_controller!),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFinished && !oldWidget.isFinished) {
      if (_controller != null && _controller!.value.isRecordingVideo) {
        _controller!.stopVideoRecording().then((file) async {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('selfiePath', file.path);
          prefs.setString('selfieName', file.name);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> initCamera() async {
    try {
      _cameras = await availableCameras();
      print('Available cameras: $_cameras');
      if (_cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first, // fallback to first if no front cam
        );

        _controller = CameraController(frontCamera, ResolutionPreset.high);
        await _controller!.initialize();
        await _controller!.startVideoRecording();
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
      } else {
        print('No cameras found');
      }
    } catch (e) {
      print('Camera error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }
}
