import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glacier/enums/ReactionVideoOrientation.dart';
import 'package:video_player/video_player.dart';

class VerticalStackLayout extends StatefulWidget {
  final VideoPlayerController? controllerVideo;
  final CameraController? controllerCamera;
  final ReactionVideoOrientation? orientation;

  const VerticalStackLayout({
    super.key,
    this.controllerVideo,
    this.controllerCamera,
    this.orientation,
  });

  @override
  State<VerticalStackLayout> createState() => _VerticalStackLayoutState();
}

class _VerticalStackLayoutState extends State<VerticalStackLayout> {
  @override
  Widget build(BuildContext context) {
    // final screenSize = MediaQuery.of(context).size;
    final isScreenPortrait =
        widget.orientation == ReactionVideoOrientation.portrait ? true : false;

    return !widget.controllerVideo!.value.isInitialized ||
            !widget.controllerCamera!.value.isInitialized
        ? const Scaffold(
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
          body: Column(
            children: [
              // Video Player section
              Expanded(
                flex: isScreenPortrait ? 7 : 4,
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: widget.controllerVideo!.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: VideoPlayer(widget.controllerVideo!),
                      ),
                    ),
                  ),
                ),
              ),

              // Visual separator
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              // Camera Preview section
              Expanded(
                flex: isScreenPortrait ? 3 : 6,
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
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
