import 'package:better_player_plus/better_player_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';

class PreviewLayout extends StatefulWidget {
  final BetterPlayerController? controllerVideo;
  final CameraController? controllerCamera;
  final ReactionVideoOrientation? orientation;

  const PreviewLayout({
    super.key,
    this.controllerVideo,
    this.controllerCamera,
    this.orientation,
  });

  @override
  State<PreviewLayout> createState() => _PreviewLayoutState();
}

class _PreviewLayoutState extends State<PreviewLayout> {
  @override
  Widget build(BuildContext context) {
    return widget.controllerVideo == null ||
            widget.controllerCamera == null ||
            !(widget.controllerVideo?.isVideoInitialized() ?? false) ||
            !widget.controllerCamera!.value.isInitialized
        ? const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading video and camera...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        )
        : Scaffold(
          body: Stack(
            children: [
              // BetterPlayer section (full screen background)
              Center(
                child: AspectRatio(
                  aspectRatio:
                      widget.controllerVideo!.getAspectRatio() ?? 16 / 9,
                  child: BetterPlayer(controller: widget.controllerVideo!),
                ),
              ),
              // Camera Preview section (overlay at bottom-right)
              Positioned(
                bottom: 90,
                right: 16,
                child: Container(
                  width: 150,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CameraPreview(widget.controllerCamera!),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  @override
  void initState() {
    super.initState();
  }
}
