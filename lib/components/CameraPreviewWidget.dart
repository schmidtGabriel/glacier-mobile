import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewWidget({super.key, required this.controller});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  List<CameraDescription>? _cameras;
  final bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: widget.controller.value.previewSize!.height,
            height: widget.controller.value.previewSize!.width,
            child: CameraPreview(widget.controller),
          ),
        ),
      ),
    );
  }

  // @override
  // void didUpdateWidget(covariant CameraPreviewWidget oldWidget) {
  //   super.didUpdateWidget(oldWidget);

  //     if (widget.controller.value.isRecordingVideo) {
  //       widget.controller
  //           .stopVideoRecording()
  //           .then((file) async {
  //             final prefs = await SharedPreferences.getInstance();

  //             prefs.setString('selfiePath', file.path);
  //             prefs.setString('selfieName', file.name);
  //           })
  //           .catchError((error) {
  //             print('Error stopping camera recording: $error');
  //           });
  //     } else {
  //       print('Camera controller is null or not recording');
  //     }
  //   }
  // }

  // @override
  // void dispose() {
  //     _controller?.dispose();
  //   super.dispose();
  // }

  // Future<void> initCamera() async {
  //   try {
  //     print('Initializing camera...');
  //     _cameras = await availableCameras();
  //     print('Available cameras: $_cameras');
  //     if (_cameras!.isNotEmpty) {
  //       final frontCamera = _cameras!.firstWhere(
  //         (camera) => camera.lensDirection == CameraLensDirection.front,
  //         orElse: () => _cameras!.first, // fallback to first if no front cam
  //       );

  //       _controller = CameraController(frontCamera, ResolutionPreset.max);
  //       await _controller!.initialize();
  //       print('Camera initialized, starting video recording...');
  //       await _controller!.startVideoRecording();
  //       print('Camera video recording started');
  //       if (!mounted) return;
  //       setState(() {
  //         _isInitialized = true;
  //       });
  //     } else {
  //       print('No cameras found');
  //     }
  //   } catch (e) {
  //     print('Camera error: $e');
  //   }
  // }
}
