import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  late List<CameraDescription> _cameras;
  int _currentCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isSwitchingCamera = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.grey.shade400),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: double.infinity,
                child:
                    _isSwitchingCamera || _initializeControllerFuture == null
                        ? const Center(child: CircularProgressIndicator())
                        : FutureBuilder<void>(
                          future: _initializeControllerFuture!,
                          builder: (builderContext, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return ClipRect(
                                child: CameraPreview(_controller),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
              ),
            ),
          ),
          _buildCameraControls(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness:
            Brightness.dark, // Dark icons on light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.black),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Flash button
            GestureDetector(
              onTap: _isSwitchingCamera ? null : _toggleFlash,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isFlashOn
                          ? Colors.yellow
                          : (_isSwitchingCamera
                              ? Colors.grey.shade600
                              : Colors.grey.shade800),
                ),
                child: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color:
                      _isFlashOn
                          ? Colors.black
                          : (_isSwitchingCamera
                              ? Colors.grey.shade400
                              : Colors.white),
                  size: 24,
                ),
              ),
            ),
            // Take photo button
            GestureDetector(
              onTap: _isSwitchingCamera ? null : _takePictureAction,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isSwitchingCamera ? Colors.grey.shade400 : Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 3),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color:
                      _isSwitchingCamera ? Colors.grey.shade600 : Colors.black,
                  size: 32,
                ),
              ),
            ),
            // Camera switch button
            GestureDetector(
              onTap: _isSwitchingCamera ? null : _switchCamera,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isSwitchingCamera
                          ? Colors.grey.shade600
                          : Colors.grey.shade800,
                ),
                child:
                    _isSwitchingCamera
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(
                          Icons.switch_camera,
                          color: Colors.white,
                          size: 24,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeCameras() async {
    _cameras = await availableCameras();
    _currentCameraIndex = _cameras.indexWhere(
      (camera) => camera == widget.camera,
    );
    if (_currentCameraIndex == -1) _currentCameraIndex = 0;

    _controller = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      // Set initial flash mode
      _controller.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
    });
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length > 1 && !_isSwitchingCamera) {
      setState(() {
        _isSwitchingCamera = true;
      });

      try {
        await _controller.dispose();

        setState(() {
          _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
          _isFlashOn = false; // Reset flash state when switching cameras
        });

        _controller = CameraController(
          _cameras[_currentCameraIndex],
          ResolutionPreset.medium,
        );

        _initializeControllerFuture = _controller.initialize().then((_) {
          // Set flash mode after camera switch (it's already reset to false above)
          _controller.setFlashMode(FlashMode.off);
        });
        await _initializeControllerFuture!;

        setState(() {
          _isSwitchingCamera = false;
        });
      } catch (e) {
        print('Error switching camera: $e');
        setState(() {
          _isSwitchingCamera = false;
        });
      }
    }
  }

  Future<String> _takePicture() async {
    final directory = await getTemporaryDirectory();
    final imagePath = path.join(
      directory.path,
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final file = await _controller.takePicture();
    await file.saveTo(imagePath);
    return imagePath;
  }

  Future<void> _takePictureAction() async {
    if (_initializeControllerFuture == null || _isSwitchingCamera) return;

    try {
      final path = await _takePicture();
      if (mounted) {
        Navigator.of(context).pop(path);
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller.value.isInitialized && !_isSwitchingCamera) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller.setFlashMode(
        _isFlashOn ? FlashMode.always : FlashMode.off,
      );
    }
  }
}
